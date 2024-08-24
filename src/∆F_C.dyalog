:Namespace ∆F_C 
  ⍝ Generates functions ∆F4, ∆F2, ∆F1 that provide formatting strings
  ⍝ APL format:
  ⍝ outLen out← ∆Fn in (≢in) (≢outBuffer) (≢outBuffer) 
  ⍝ ∆F2:  n is 4, 2, 1 for ⎕DR 320, 160, 80 ==> ∆F4, ∆F2, ∆F1 respectively.
  ⍝   in:  the input string (⎕DR 80, 160, 320).
  ⍝   ≢in: the true APL length of the input string.
  ⍝   outBuffer: a buffer set aside by APL during the call. You only provide its length.
  ⍝              The length is provided twice; the 2nd time so the C routine has access to its
  ⍝              length. This MUST be the buffer size, including a terminal null. 
  ⍝   Note: 
  ⍝   ∘ If the input ¨in¨ is ⎕DR 80 or 160, outBuffer will be ⎕DR 160;
  ⍝     this is because typical APL characters (⎕, ⋄, ⍎, ↑) are typically found in the output
  ⍝     even if the input is ⎕DR 160.
  ⍝   ∘ If the input is ⎕DR 320, outBuffer will be ⎕DR 320.
  ⍝ Returns: outLen out:
  ⍝ ∘ If ∆Fnn succeeds, outLen is the ACTUAL output string's length, not the buffer size.
  ⍝    out will be the output string in APL format, without any trailing bytes of the outBuffer.
  ⍝ ∘ If ∆Fnn fails, outLen←0 and out←''.
  ⍝ Example:
  ⍝      in← 'input_string'
  ⍝ outLen out← ∆F16 in (≢in) 512 512
  ⍝ Usage: See ∆F below

⍝ DEBUG: If 1, uses DEBUG-mode everywhere, including in the C Program.
  DEBUG← 0
  SRC LIB← '∆F_C.c'  '∆F_C.so' 
⍝ FORCE_TO_4:  If 1, force all char. sizes to UCS-4 (4 bytes/char)
⍝              If 0, generate library with UCS-4, UCS-2 and UCS-1 char sizes
  FORCE_TO_4← 0    
  Make←{ 
    ⍝ Grab ⍝P (preamble) and ⍝B (body) code for C pgm below.
      pre bdy← 'PB'{⊂('^\h*⍝',⍺,'\h?(.*)') ⎕S '\1'⊣⍵}¨ ⊂⎕SRC ⎕THIS  
      GenPre← '<DEBUG>' ⎕R (⍕⎕THIS.DEBUG)
      GenCode←{
         inN← 8× ⍵ ⋄ outN← 8× 2 4⊃⍨ ⍵=4
         inC outC← ('char',(⍕inN),'_t')  ('char',(⍕outN),'_t')
        'IN_CHAR' 'OUT_CHAR' '<NN>'  ⎕R inC outC (⍕⍵) ⊣ ⍺
      }
      charSizes← FORCE_TO_4⊃ (4 2 1) 4
      libCode← ⊂(GenPre ⊃pre), ⊃,/bdy GenCode¨ charSizes
      count← libCode ⎕NPUT SRC 1
    0= ≢count: 11 ⎕SIGNAL⍨ 'Error writing source file "',cSrcName,'"' 
      {  
          cr← ⎕UCS 13 
        0:: 11 ⎕SIGNAL⍨ 'Error compiling "',SRC,'" to "',LIB,'"' 
          l1← 'Generating source C code:            ',SRC 
          _← ⎕SH cc←'cc -O3 -shared -o ',LIB,' ',SRC 
          l2← '*** ',cc
          l3← 'Compiled to private shared library: ',LIB
        1: ⎕← ↑l1 l2 l3 
      } ⍬ 
 }
 Declare←{ 
  ⍝ Associates (⎕NA) APL fns named ∆F4, ∆F2, ∆F1 with corresponding C fns FMT_C4, ...2, ...1
  ⍝ in the library <LIB>
    { inType ← ⍕⍵  ⋄ outType← ⍕2 4⊃⍨ ⍵=4   
      decl← '<C',inType,'[] I4 >0C',outType,'[] I4'
      (⍕⎕THIS),'.',('∆F',inType)⎕NA 'I4 ',LIB,'|FMT_C',inType, ' ',decl 
    }¨4 2 1
  } 

  Make ⍬
  ⎕←'To associate APL fns with routines in C library ',LIB,', execute:' 
  ⎕←'    ∆F_C.Declare ⍬'

  ∇res← {DEBUG2} ∆F stuff
    ;args; dr; fStr ;stuff; lenIn; lenOut; rc; out 
    ;⎕IO;⎕ML 

  ⍝ If DEBUG2 is omitted, uses the namespage ⎕THIS.DEBUG.

    ⎕IO ⎕ML←0 1 
    :If 900⌶⍬ ⋄ DEBUG2← ⎕THIS.DEBUG ⋄ :EndIf 
    :If 0= ⎕NC '∆F4' ⋄ {}Declare⍬ ⋄ :EndIf  

    :If 0< lenIn← ≢fStr← ⊃stuff← ,⊆stuff 
        lenOut← 512⌈ 4× lenIn 
        :If ⎕THIS.FORCE_TO_4 
          :Select dr← ⎕DR fStr
            :Case 320 ⋄ 
            :Caselist 160 80 ⋄ fStr← ⊃dr 320 ⎕DR fStr 
            :Else     ⋄ 11 ⎕SIGNAL⍨'∆F DOMAIN ERROR: Format string has improper type'
          :EndSelect
          rc out← ∆F4 fStr lenIn lenOut lenOut 
        :Else 
          args← fStr lenIn lenOut lenOut 
          :Select ⎕DR fStr
              :Case 320 ⋄ rc out← ∆F4 args 
              :Case 160 ⋄ rc out← ∆F2 args
              :Case  80 ⋄ rc out← ∆F1 args
              :Else     ⋄ 11 ⎕SIGNAL⍨'∆F DOMAIN ERROR: Format string has improper type'
          :EndSelect
        :EndIf 
        :Select rc  
           :Case ¯1 ⋄ 11 ⎕SIGNAL⍨'∆F LOGIC ERROR: Insufficient space for code output'
           :Case  0 ⋄ 11 ⎕SIGNAL⍨'∆F DOMAIN ERROR: Invalid format string'  
           :Case ¯2 ⋄ 11 ⎕SIGNAL⍨'∆F DOMAIN ERROR: `⍵ indexing may not exceed 9999'
        :EndSelect
        :Trap 90 
            :If DEBUG2
                res← out ⋄ :Return 
            :EndIf 
            res← ∆Fmt(out⍎⍨ ⊃⎕RSI) stuff 
        :Else 
            ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message )
        :EndTrap
    :Else  
        res← 1 0⍴''           ⍝ ⎕FMT ''
    :EndIf 
  ∇ 

  ∆Fmt← {⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍵}

 :Section Source
⍝P #include <stdio.h>
⍝P #define DEBUG         <DEBUG>  
⍝P /* Include defs for wide types (MacOs doesn't have the right header file) */    
⍝P #define char8_t       unsigned char 
⍝P #define char16_t      __CHAR16_TYPE__
⍝P #define char32_t      __CHAR32_TYPE__
⍝P #define wchar_t       __WCHAR_TYPE__
⍝P #define cNONE         0
⍝P #define cTEXT         1
⍝P #define cBRACE        2
⍝P #define cQUOTE        3
⍝P #define OMEGA_MAX     9999
⍝P #define OMEGA_DIGITS  4     /* Excludes terminating null */    
⍝P
⍝P #if DEBUG 
⍝P    #define CR         L'␍'
⍝P #else 
⍝P    #define CR         '\r'
⍝P #endif 
⍝P #define DOLLAR        '$' 
⍝P #define DQ            '"'
⍝P #define EOS           L'⋄'
⍝P #define ESC           '`'
⍝P #define LBRACE        '{'
⍝P #define OMEGA         L'⍵'
⍝P #define SP            ' '
⍝P #define SQ            '\''
⍝P #define RBRACE        '}'
⍝ 
⍝P #define INCHECK()     if (inIx >= inLen) goto isDone 
⍝P #define NOSPACE()     ABEND(-1)
⍝P #define ABEND(rc)     { out[0]=0; return rc;}
⍝P #define PEEKCH()      ((inIx+1)>=inLen? 0 : in[inIx+1])
⍝P #define POSTAMBLE()   {PUTSTR("} ");  PUTCH(0);}
⍝P #define PREAMBLE()    PUTSTR(L"{⍺⍺ ")
⍝P #define PUTCH(ch)     if (outIx<outLen) out[outIx++]=ch
⍝P #define PUTSTR(str)   for (i=0; str[i] && outIx<outLen;) out[outIx++]=str[i++]
⍝P #define SPACECHECK()  if (outIx >= outLen) NOSPACE();
⍝P #define TEXTCHECK     if (class == cTEXT) PUTSTR("' ")
⍝ 
⍝P #define omOUTLEN     30 
⍝P #define omOUTLENPLUS omOUTLEN+2 
⍝
⍝P #define omPUTSTR(omOut, str) \
⍝P         for (strIx=0; str[strIx] && omOutIx< omOUTLEN;) \
⍝P              omOut[ omOutIx++ ] = str[ strIx++ ]
⍝P #define omPUTBUF(omOut, ch, max) if ( omOutIx < max ) omOut[ omOutIx++ ] = ch
⍝P #define omPUTCH(omOut, ch) omPUTBUF( omOut, ch, omOUTLEN)
⍝
⍝B int Omega<NN>( 
⍝B          OUT_CHAR *omOut, IN_CHAR *in, int inIx, int inLen, int *omSkipPtr, int omCount 
⍝B ){ /* Returns updated omCount */ 
⍝B   int omOutIx=0; 
⍝B   int   strIx;
⍝B   int omNum=0;
⍝B   omPUTSTR( omOut, L"(⍵⊃⍨" ); 
⍝B   *omSkipPtr=0;
⍝B   for (; inIx< inLen && omOutIx < omOUTLEN; ++inIx) {
⍝B       int dig;
⍝B       dig= in[inIx];
⍝B       if (dig>='0' && dig<='9'){
⍝B           ++*omSkipPtr;
⍝B           omNum = (omNum*10)+ (dig-'0');
⍝B           if (omNum > OMEGA_MAX) 
⍝B               return -2;
⍝B           omPUTCH(omOut, dig);
⍝B        }else
⍝B           break;
⍝B   }
⍝B   if (*omSkipPtr) 
⍝B       omCount = omNum;  
⍝B   else{
⍝B       char tBuf[ OMEGA_DIGITS+1 ];
⍝B       ++omCount; 
⍝B       if (0 < snprintf( tBuf, sizeof(tBuf), "%d", omCount))
⍝B            omPUTSTR( omOut, tBuf );
⍝B   }
⍝B   omPUTBUF( omOut, ')', omOUTLENPLUS ); omPUTBUF(omOut, 0, omOUTLENPLUS);
⍝B   return omCount;
⍝B }
⍝B
⍝B /* IN_CHAR, OUT_CHAR replaced by char8_t, char16_t, char32_t */
⍝B int FMT_C<NN>( IN_CHAR *in, int inLen, OUT_CHAR *out, int outLen){
⍝B   int outIx = 0;
⍝B   int inIx  = 0;
⍝B   int i; 
⍝B   int class; 
⍝B   int curQ;
⍝B   int nBraces=0;
⍝B   int inSpaces=0;
⍝B   int omSkip;
⍝B   int omegaCount=0;
⍝B   OUT_CHAR omOut[ omOUTLENPLUS ];
⍝B   INCHECK();
⍝B   PREAMBLE();
⍝B   if (inLen >= outLen || outLen<1) NOSPACE();
⍝B /*   Not in a field   */
⍝B /*   Not in a field   */
⍝B /*   Not in a field   */
⍝B isNone:
⍝B   class= cNONE;
⍝B   INCHECK();
⍝B   if ( in[inIx] == LBRACE ) goto isBrace;
⍝B /*    Text field    */
⍝B /*    Text field    */
⍝B /*    Text field    */
⍝B   class = cTEXT;
⍝B   PUTSTR(" '");
⍝P  #define USWITCH(intType)   switch( (char16_t) intType )
⍝B   for (; inIx<inLen;  ++inIx){
⍝B      USWITCH(in[inIx]){
⍝B         case SQ: 
⍝B            PUTSTR("''"); break;
⍝B         case ESC: 
⍝B               ++inIx; SPACECHECK();
⍝B               USWITCH(in[inIx]){
⍝B                 case EOS: PUTCH(CR);  break;
⍝B                 case ESC:  
⍝B                 case LBRACE:  
⍝B                 case RBRACE: 
⍝B                       PUTCH( in[inIx] ); break;
⍝B                 default:
⍝B                       PUTCH( ESC );  
⍝B                       --inIx; break;
⍝B               }
⍝B               break;
⍝B        case LBRACE: 
⍝B             nBraces = 1;
⍝B             goto isBrace;
⍝B             break;
⍝B        default:  
⍝B            PUTCH( in[inIx] ); break;
⍝B        }      
⍝B   }
⍝B   TEXTCHECK; goto isDone;
⍝B   isBrace:
⍝B     TEXTCHECK;
⍝B     class=cBRACE;
⍝B  /* Space field: {   } */
⍝B  /* Space field: {   } */
⍝B  /* Space field: {   } */
⍝B     inSpaces=0; inIx++;
⍝B     for (i=inIx; i<inLen && in[i]==SP; ++i, ++inSpaces);
⍝B     if (inSpaces && i<inLen && in[i]==RBRACE ) {
⍝B        inIx+= inSpaces+1;
⍝B        PUTCH(SP); PUTCH(SQ); 
⍝B        for (i=0; i<inSpaces; ++i) PUTCH(SP);
⍝B        PUTCH(SQ); PUTCH(SP);
⍝B        goto isNone;
⍝B     }
⍝B  /*  Code field:  { code }  */
⍝B  /*  Code field:  { code }  */
⍝B  /*  Code field:  { code }  */
⍝B     nBraces = 1;
⍝B     PUTSTR( "({" );
⍝B     for ( ; inIx<inLen;  ++inIx){
⍝B          USWITCH(in[inIx]){
⍝B             case DOLLAR: 
⍝B                 if (PEEKCH() == DOLLAR) {
⍝B                    PUTSTR(L" ⎕SE.Dyalog.Utils.display ");
⍝B                    ++inIx;
⍝B                 }else
⍝B                    PUTSTR(L" ⎕FMT "); 
⍝B                 break;
⍝B             case LBRACE: 
⍝B                nBraces++; PUTCH( LBRACE );  break;
⍝B             case RBRACE: 
⍝B                if (--nBraces<=0) {
⍝B                  ++inIx;
⍝B                  PUTSTR( L"}⍵)" );
⍝B                  goto isNone;
⍝B                }; 
⍝B                PUTCH(RBRACE);
⍝B                break;
⍝B              case SQ:   
⍝B              case DQ: 
⍝B                curQ= in[inIx];
⍝B                PUTCH( SQ );
⍝B                for (++inIx; inIx<inLen ; ++inIx) {
⍝B                   if (in[inIx] == curQ){
⍝B                      if (PEEKCH() == curQ ) { 
⍝B                         PUTCH(curQ); 
⍝B                         ++inIx;
⍝B                      }else{
⍝B                         PUTCH( SQ ); 
⍝B                         break; 
⍝B                      }
⍝B                   }else{
⍝B                      if (in[inIx]==ESC){
⍝B                        ++inIx; SPACECHECK();
⍝B                        USWITCH( in[inIx] ){
⍝B                          case EOS: 
⍝B                            PUTCH(CR); break;
⍝B                          case LBRACE:
⍝B                          case RBRACE:
⍝B                          case ESC:
⍝B                            PUTCH( in[inIx] ); break;
⍝B                          default:
⍝B                            PUTCH( ESC ); --inIx;
⍝B                         } 
⍝B                         break;
⍝B                      }else if (in[inIx] == SQ) {
⍝B                         PUTCH(SQ);PUTCH(SQ );
⍝B                      }else PUTCH( in[inIx] ); 
⍝B                   }
⍝B                 } /* for */
⍝B                 break;
⍝B              case ESC:   ++inIx; SPACECHECK();
⍝B                 USWITCH( in[inIx] ){
⍝B                   case EOS: 
⍝B                     PUTCH(CR);
⍝B                     break;
⍝B                   case LBRACE:
⍝B                   case RBRACE:
⍝B                     PUTCH( in[inIx]);
⍝B                     break;
⍝B                   case OMEGA:
⍝B                     omegaCount = Omega<NN>( 
⍝B                        omOut, in, inIx+1, inLen, &omSkip, omegaCount 
⍝B                     ); 
⍝B                     if (omegaCount < 0) ABEND(-2);
⍝B                     PUTSTR( omOut );
⍝B                     inIx+= omSkip;
⍝B                     break;
⍝B                  default:
⍝B                     PUTCH( ESC );
⍝B                     --inIx;
⍝B                   } 
⍝B                   break;
⍝B              default:    
⍝B                 PUTCH( in[inIx] ); 
⍝B                 break;
⍝B          }
⍝B     }
⍝B     goto isDone;
⍝B /*   Done! Tidy up...  */  
⍝B /*   Done! Tidy up...  */   
⍝B /*   Done! Tidy up...  */   
⍝B   isDone:
⍝B     POSTAMBLE();
⍝B     SPACECHECK();
⍝B     return 1;
⍝B } 
 :EndSection 
:EndNamespace 