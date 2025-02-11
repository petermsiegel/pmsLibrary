// Specify code for library calls: merge, above, box, fmt, and display
//    internal: code for routine included in result;
//    external: calls a library in APL_LIB
// APL_LIB defined in ∆F.c
#define LIB_CALL(fn) u" " APL_LIB fn u" "
//       Join: pseudo-primitive, joins fields (possibly differently-shaped char
//       arrays) left-to-right
#define MERGECD_INT u"{⍺←⊢⋄⎕ML←1⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}"
#define MERGECD_EXT LIB_CALL(u"M")
//       Over: center field ⍺ over field ⍵
#define ABOVECD_INT u"{⍺←0⋄⎕ML←1⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}"
#define ABOVECD_EXT LIB_CALL(u"A")
//       Box: Box item to its right
#define BOXCD_INT u"{⍺←0⋄⎕ML←1⋄⍺⎕SE.Dyalog.Utils.disp⊂⍣(1≥≡⍵),⍣(0=≡⍵)⊢⍵}"
#define BOXCD_EXT LIB_CALL(u"B")
//       ⎕FMT: Formatting (dyadic)
#define FMTCD_INT u" ⎕FMT "
// dfn ¨disp¨, used as a prefix for LIST and TABLE modes and with BOX option.
#define DISPCD_INT u"0∘⎕SE.Dyalog.Utils.disp¯1∘↓"
#define DISPCD_EXT LIB_CALL(u"D")

#define ALPHA u'⍺'
#define CR u'\r'
#define CRVIS u'␍'
#define DMND u'⋄' // APL DIAMOND (⋄) ⎕UCS 8900
#define DNARO u'↓'
#define DOL u'$'
#define DQ u'"'
#define LBR u'{'
#define LPAR u'('
#define NULVIS u'␀'
#define OMG u'⍵'
#define OMG_US u'⍹'
#define PCT u'%'
#define RBR u'}'
#define QT u'\''
#define RPAR u')'
#define RTARO u'→'
#define SP u' '
#define SPVIS u'␠'
#define SQ u'\''
#define ZILDE u'⍬'

// Options fields: a bit each
typedef struct { // From most- to least-significant bit.
  unsigned int unused1: 1;    
  unsigned int unused2: 1;
  unsigned int extLib : 1;   // ('ExtLib' 1)
  unsigned int useNs  : 1;   // ('UseNs' 1)
  unsigned int debug  : 1;   // ('Debug' 1)
  unsigned int table  : 1;   // ('Mode' ¯2) or ('Mode' 0|1) ('Box' 2)
  unsigned int list   : 1;   // ('Mode' ¯1) or ('Mode' 0|1) ('Box' 1)
  unsigned int code   : 1;   // ('Mode'  0) ('Box' 0|1|2)
} optionsF;


// STATE MANAGEMENT
typedef enum  {
  None,     // not in a field
  TF,       // in a text field
  CF_START, // starting a cf
  CF        // in a code field or space field */
} stateE;
#define STATE(new)                                                             \
  {                                                                            \
    oldState = state;                                                          \
    state = new;                                                               \
  }
// End STATE MANAGEMENT

/* INPUT BUFFER ROUTINES */
/* SKIP: skip current char. */
#define SKIP (++in.cur)
#define SKIP_SP                                                                \
  while (PEEK == SP)                                                           \
  SKIP
/* CUR_AT(ix), CUR:  Return char at in.buf[ix], in.buf[in.cur], w/o checking
 * bounds */
#define CUR_AT(ix) in.buf[ix]
#define CUR CUR_AT(in.cur)
/* PEEK_AT(ix), PEEK: Always check that it's in range */
#define PEEK_AT(ix) ((ix < in.max) ? in.buf[ix] : -1)
/* PEEK... Return NEXT char, checking range bounds. If not, return -1 */
#define PEEK PEEK_AT(in.cur + 1)
/* END INPUT BUFFER ROUTINES */

// C-Dyalog Function Call Interface structure-- lpString: length prefixed
// string. Structure expected by Dyalog ⎕NA '<#C2', '>#C2', and equiv. C4
// formats. Structure for fStrIn and cStrOut objects
typedef struct {
  WIDE len, buf[];
} lpString;

// GENERIC OUTPUT BUFFER MANAGEMENT ROUTINES
// Structure for <out> and <code> buffer objects
typedef struct {
  uint32_t cur, max;
  WIDE *buf;
} buffer;

#define ADDBUF(str, strLen, buffer)                                            \
  {                                                                            \
    int len = strLen;                                                          \
    if (buffer.cur + len >= buffer.max)                                        \
      ERROR_SPACE;                                                             \
    for (int ix = 0; ix < len; (buffer.cur)++, ix++)                           \
      buffer.buf[buffer.cur] = (WIDE)str[ix];                                  \
  }

#define ADDCH(ch, buffer)                                                      \
  {                                                                            \
    if (buffer.cur + 1 >= buffer.max)                                          \
      ERROR_SPACE;                                                             \
    buffer.buf[buffer.cur++] = (WIDE)ch;                                       \
  }

#define C2Len(s) ((sizeof(s) - 1) / sizeof(WIDE2)) // See also S2Len()

// OUTPUT BUFFER MANAGEMENT ROUTINES
#define DOUBLE_SQ 1
#define OutBuf(str, len) ADDBUF(str, len, out)
#define OutS(str)                                                              \
  {                                                                            \
    WIDE2 *s = str;                                                            \
    OutBuf(s, S2Len(s));                                                       \
  }                                        // Any null-term. WIDE2 str.
#define OutSC(str) OutBuf(str, C2Len(str)) // (WIDE2) str constants only
#define OutCh(ch) ADDCH(ch, out)           // char. const only
// END OUTPUT BUFFER MANAGEMENT ROUTINES

// CODE BUFFER MANAGEMENT ROUTINES
// Handle special code buffer.
// To transfer codeBuf to outBuf (and then "clear" it):
//    CodeOut
#define CodeInit code.cur = 0
// CodeS: str must be a null-terminated WIDE2 str.
#define CodeS(str)                                                             \
  {                                                                            \
    WIDE2 *s = str;                                                            \
    ADDBUF(s, S2Len(s), code);                                                 \
  } 
#define CodeSC(str)                                                            \
  ADDBUF(str, C2Len(str), code) // (WIDE2) str constants only
#define CodeCh(ch) ADDCH(ch, code) // char. const only
#define CodeOut                                                                \
  {                                                                            \
    OutBuf(code.buf, code.cur);                                                \
    CodeInit;                                                                  \
  }
// END CODE BUFFER MANAGEMENT ROUTINES

// Any attempt to add a number bigger than 99999* will result in an APL Domain
// Error. Used in routines to decode omegas: `⍵nnn, and so on.            * An
// aburdly large number here.
#define IX_ERR u"Omega index or space field width absurdly large (>99999)"
#define IX_MAX 99999
#define IX_MAXDIG 5
#define Ix2CodeBuf(num)                                                        \
  {                                                                            \
    char nstr[IX_MAXDIG + 1];                                                  \
    int tnum = num;                                                            \
    if (tnum > IX_MAX) {                                                       \
      ERROR(IX_ERR, 11);                                                       \
      tnum = IX_MAX;                                                           \
    }                                                                          \
    snprintf(nstr, IX_MAXDIG + 1, "%d", tnum);                                 \
    for (int i = 0; i < IX_MAXDIG && nstr[i]; ++i) {                           \
      CodeCh((WIDE2)nstr[i]);                                                  \
    }                                                                          \
  }

// Termination Code
#if USE_VLA
#define RETURN(rc)                                                             \
    cStrOut->len = out.cur;                                                     \
    if (rc) longjmp(jmpbuf, rc);                                                \
    return (0)    
#else /* we had to malloc(), so we need to free code.buf */
  #define RETURN(rc)                                                           \
    cStrOut->len = out.cur;                                                     \
    if (code.buf)                                                               \
      free(code.buf);                                                           \
    code.buf = NULL;                                                            \
    if (rc) longjmp( jmpbuf, rc);                                               \
    return 0 
#endif

// Error handling-- must be called within scope of main function below!
#define ERROR(str, errno)                                                     \
  {                                                                            \
    out.cur = 0;                                                               \
    OutS(str);                                                                 \
    RETURN(errno);                                                             \
  }
/* ERROR_SPACE: Ran out of space. Error msg generated in ∆F.dyalog */
#define ERROR_SPACE                                                           \
  {                                                                            \
    out.cur = 0;                                                               \
    RETURN(-1);                                                                \
  }
// End Error Handling

// Self-documenting Code Handler
// Be sure <type> has any internal quotes doubled, as needed.
// if IsCodeDoc() { ProcCodeDoc(marker, codeStr) ;}...
#define IsCodeDoc() bracketDepth == 1 && RBR == CharAfterBlanks(&in, in.cur + 1)
#define ProcCodeDoc(marker, codeStr)                                          \
  {                                                                            \
    int m;                                                                     \
    OutCh(QT);                                                                 \
    for (int i = cfStart; i < in.cur; ++i) {                                   \
      OutCh(in.buf[i]);                                                        \
      if (in.buf[i] == SQ)                                                     \
        OutCh(SQ);                                                             \
    }                                                                          \
    OutS(marker);                                                              \
    m = S2Len(marker);                                                         \
    for (int i = in.cur + 1; in.buf[i] == SP; ++i) {                           \
      if (--m <= 0)                                                            \
        OutCh(SP);                                                             \
    }                                                                          \
    OutCh(QT);                                                                 \
    OutCh(SP);                                                                 \
    OutS(codeStr);                                                             \
    OutCh(SP);                                                                 \
    CodeOut;                                                                   \
  }
// END Self-documenting Code Handler

// Scan4Ix(destVar):
//    Scanning input for digits, producing value for the name passed as destVar.
//    At the same time, writes the digits to the code buffer.
#define Scan4Ix(destVar)                                                      \
  CodeCh(CUR);                                                                 \
  if (!isdigit(CUR))                                                           \
    ERROR(u"Logic Error: Expected digit after esc-omega (`⍵) not found", 911); \
  destVar = CUR - '0';                                                         \
  for (SKIP; in.cur < in.max && isdigit(CUR); SKIP) {                          \
    destVar = destVar * 10 + CUR - '0';                                        \
    CodeCh(CUR);                                                               \
  }                                                                            \
  if (destVar > IX_MAX)                                                        \
    ERROR(IX_ERR, 11);                                                         \
  --in.cur;

static inline int S2Len(WIDE2 *str);
static inline WIDE CharAfterBlanks(buffer *pIn, int cur);
