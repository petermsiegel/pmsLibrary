// Specify code for library calls (internal: code included in result; external: calls a library in APL_LIB)
#define EOS            u"⋄"
#define LIB_CALL(fn)  u" " APL_LIB fn u" "
//       Join: pseudo-primitive, joins fields (possibly differently-shaped char arrays) left-to-right
#define MERGECD_INT    u"{⎕ML←1⋄⍺←⊢⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}"
#define MERGECD_EXT    LIB_CALL( u"M" )
//       Over: center field ⍺ over field ⍵
#define ABOVECD_INT    u"{⎕ML←1⋄⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}"
#define ABOVECD_EXT    LIB_CALL( u"A" )
// Box
#define DISPCD         u"0∘⎕SE.Dyalog.Utils.disp"
//       Box: Box item to its right
#define BOXCD_INT      u"{⎕ML←1" EOS DISPCD u",⍣(⊃0=⍴⍴⍵)⊢⍵}"
#define BOXCD_EXT      LIB_CALL( u"B" )
//       ⎕FMT: Formatting (dyadic)
#define FMTCD_INT      u" ⎕FMT "
// dfn ¨disp¨, used as a prefix for LIST and TABLE modes and with BOX option. 
#define DISPCD_INT     DISPCD u"¯1∘↓" 
#define DISPCD_EXT     LIB_CALL( u"D" )

#define ALPHA  u'⍺'
#define CR     u'\r'
#define CRVIS  u'␍' 
#define DMND   u'⋄'   //APL DIAMOND (⋄) ⎕UCS 8900 
#define DNARO  u'↓'
#define DOL    u'$'
#define DQ     u'"' 
#define LBR    u'{'
#define LPAR   u'('
#define OMG    u'⍵'
#define OMG_US u'⍹'
#define PCT    u'%'
#define RBR    u'}'
#define QT     u'\''
#define RPAR   u')'
#define RTARO  u'→'
#define SP     u' '
#define SQ     u'\''
#define ZILDE  u'⍬'

// MODES 
enum mode {
    modeStd=1,
    modeCode=0,
    modeList=-1,
    modeTable=-2
};

// STATE MANAGEMENT 
enum state {      
   None,      // not in a field 
   TF,        // in a text field 
   CF_START,  // starting a cf
   CF         // in a code field or space field */
};
#define STATE(new)  { oldState=state; state=new;}
// End STATE MANAGEMENT 

/* INPUT BUFFER ROUTINES */
/* CUR... Return current char, w/o checking bounds */
#define CUR_AT(ix)    in.buf[ix]
#define CUR           CUR_AT(in.cur)
#define PEEK_AT(ix)   (((ix) < in.max)? in.buf[ix]: -1)
/* PEEK... Return NEXT char, checking range bounds. If not, return -1 */
#define PEEK          PEEK_AT(in.cur+1)
/* END INPUT BUFFER ROUTINES */

// C-Dyalog Function Call Interface structure-- lpString: length prefixed string. 
// Structure expected by Dyalog ⎕NA '<#C2', '>#C2', and equiv. C4 formats.
// Structure for fStrIn and cStrOut objects
typedef struct {
    WIDE len, buf[];
} lpString;

// GENERIC OUTPUT BUFFER MANAGEMENT ROUTINES 
// Structure for <out> and <code> buffer objects
typedef struct {
    uint32_t   cur, max;
    WIDE *buf;
} buffer ;

#define ADDBUF(str, strLen, buffer, doubleSq)  {\
    int len=strLen;\
    if (buffer.cur+len >= buffer.max)\
        ERROR_SPACE;\
    if (doubleSq) /* SQ doubling: Slower path. */\
        for(int ix = 0; ix < len; (buffer.cur)++, ix++){\
            buffer.buf[buffer.cur]= (WIDE) str[ix];\
            if (buffer.buf[buffer.cur] == SQ) {\
                if (buffer.cur+1 >= buffer.max)\
                    ERROR_SPACE;\
                buffer.buf[++(buffer.cur)]= (WIDE) SQ;\
            }\
        }\
    else /* No SQ doubling: Faster path. */\
        for(int ix = 0; ix < len; (buffer.cur)++, ix++)\
            buffer.buf[buffer.cur]= (WIDE) str[ix];\
}
#define ADDCH(ch, buffer) {\
    if (buffer.cur+1 >= buffer.max)\
        ERROR_SPACE;\
    buffer.buf[(buffer.cur)++]= (WIDE) ch;\
} 
#define C2Len(s) ((sizeof(s)-1) / sizeof(WIDE2) ) // See also S2Len()

// OUTPUT BUFFER MANAGEMENT ROUTINES 
#define DOUBLE_SQ   1 
#define OutBuf(str, len)    ADDBUF(str, len, out, !DOUBLE_SQ)
#define OutBufSq(str, len)  ADDBUF(str, len, out,  DOUBLE_SQ)
#define OutS(str)           {WIDE2 *s=str; OutBuf(s, S2Len(s));}     // Any null-term. WIDE2 str.
#define OutSC(str)          OutBuf(str, C2Len( str ))                // (WIDE2) str constants only 
#define OutCh(ch)           ADDCH(ch, out)                            // char. const only 
// END OUTPUT BUFFER MANAGEMENT ROUTINES 

// CODE BUFFER MANAGEMENT ROUTINES  
// Handle special code buffer. 
// To transfer codeBuf to outBuf (and then "clear" it):
//    CodeOut
#define CodeInit             code.cur=0
#define CodeS(str)           {WIDE2 *s=str; ADDBUF(s, S2Len(  s ), code, 0);}   // Any null-term. WIDE2 str.
#define CodeSC(str)          ADDBUF(str, C2Len(str), code, 0)                   // (WIDE2) str constants only 
#define CodeCh(ch)           ADDCH(ch, code)                                    // char. const only 
#define CodeOut              {OutBuf(code.buf, code.cur); CodeInit;} 
// END CODE BUFFER MANAGEMENT ROUTINES  

// Any attempt to add a number bigger than 99999* will result in an APL Domain Error.  
// Used in routines to decode omegas: `⍵nnn, and so on.            * An aburdly large number here.
#define IX_ERR u"Omega index or space field width too large (>99999)"
#define IX_MAX    99999
#define IX_MAXDIG     5
#define Ix2CodeBuf(num) {\
    char nstr[IX_MAXDIG+1];\
    int  tnum=num;\
    if (tnum > IX_MAX){\
        ERROR(IX_ERR, 11);\
        tnum=IX_MAX;\
    }\
    snprintf(nstr, IX_MAXDIG+1, "%d", tnum);\
    for (int i=0;  i < IX_MAXDIG && nstr[i]; ++i){\
        CodeCh((WIDE2)nstr[i]);\
    }\
}

// Termination Code
#if USE_VLA
   #define RETURN(rc)  cStrOut->len = out.cur;\
                      return(rc)
#else /* we had to malloc(), so we need to free code.buf */ 
   #define RETURN(rc)  cStrOut->len = out.cur;\
                      if (code.buf) free(code.buf);\
                      code.buf = NULL;\
                      return(rc)
#endif 

// Error handling-- must be called within scope of main function below!
#define ERROR(str, errno) { out.cur=0;  OutS(str); RETURN(errno); } 
/* ERROR_SPACE: Ran out of space. Error msg generated in ∆F.dyalog */ 
#define ERROR_SPACE     { out.cur=0; RETURN(-1); }
// End Error Handling  

// Self-documenting Code Handler  
// Be sure <type> has any internal quotes doubled, as needed.
// if IsCodeDoc() { ProcCodeDoc(marker, codeStr) ;}...
# define IsCodeDoc() \
      bracketDepth == 1 && RBR == CharAfterBlanks( &in, in.cur+1 )
# define ProcCodeDoc(marker, codeStr){\
      int m;\
      OutCh(QT);\
      for (int i=cfStart; i< in.cur; ++i) {\
        OutCh( in.buf[i] );\
        if (in.buf[i] == SQ)\
            OutCh(SQ);\
      }\
      OutS(marker);\
      m = S2Len(marker);\
      for (int i=in.cur+1; in.buf[i] == SP; ++i){\
          if (--m <= 0)\
             OutCh(SP);\
      }\
      OutCh(QT); OutCh(SP);\
      OutS(codeStr);\
      OutCh(SP);\
      CodeOut;\
    } 
// END Self-documenting Code Handler  


// Scan4Ix(destVar): 
//    Scanning input for digits, producing value for the name passed as destVar. 
//    At the same time, writes the digits to the code buffer.
#define Scan4Ix(destVar)\
       CodeCh(CUR);\
       if (!isdigit(CUR))\
          ERROR(u"Logic Error: Expected digit after esc-omega (`⍵) not found", 911);\
       destVar=CUR-'0';\
       for (++in.cur; in.cur< in.max && isdigit(CUR); ++in.cur) {\
          destVar = destVar * 10 + CUR-'0';\
          CodeCh(CUR);\
       }\
       if (destVar > IX_MAX)\
           ERROR(IX_ERR, 11);\
       --in.cur;

static inline int S2Len(WIDE2 *str);
static inline WIDE CharAfterBlanks( buffer *pIn, int cur );
