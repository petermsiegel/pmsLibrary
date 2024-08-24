#include <stdio.h>
#define DEBUG         0  
/* Include defs for wide types (MacOs doesn't have the right header file) */    
#define char8_t       unsigned char 
#define char16_t      __CHAR16_TYPE__
#define char32_t      __CHAR32_TYPE__
#define wchar_t       __WCHAR_TYPE__
#define cNONE         0
#define cTEXT         1
#define cBRACE        2
#define cQUOTE        3
#define OMEGA_MAX     9999
#define OMEGA_DIGITS  4     /* Excludes terminating null */    

#if DEBUG 
   #define CR         L'␍'
#else 
   #define CR         '\r'
#endif 
#define DOLLAR        '$' 
#define DQ            '"'
#define EOS           L'⋄'
#define ESC           '`'
#define LBRACE        '{'
#define OMEGA         L'⍵'
#define SP            ' '
#define SQ            '\''
#define RBRACE        '}'
#define INCHECK()     if (inIx >= inLen) goto isDone 
#define NOSPACE()     ABEND(-1)
#define ABEND(rc)     { out[0]=0; return rc;}
#define PEEKCH()      ((inIx+1)>=inLen? 0 : in[inIx+1])
#define POSTAMBLE()   {PUTSTR("} ");  PUTCH(0);}
#define PREAMBLE()    PUTSTR(L"{⍺⍺ ")
#define PUTCH(ch)     if (outIx<outLen) out[outIx++]=ch
#define PUTSTR(str)   for (i=0; str[i] && outIx<outLen;) out[outIx++]=str[i++]
#define SPACECHECK()  if (outIx >= outLen) NOSPACE();
#define TEXTCHECK     if (class == cTEXT) PUTSTR("' ")
#define omOUTLEN     30 
#define omOUTLENPLUS omOUTLEN+2 
#define omPUTSTR(omOut, str) \
        for (strIx=0; str[strIx] && omOutIx< omOUTLEN;) \
             omOut[ omOutIx++ ] = str[ strIx++ ]
#define omPUTBUF(omOut, ch, max) if ( omOutIx < max ) omOut[ omOutIx++ ] = ch
#define omPUTCH(omOut, ch) omPUTBUF( omOut, ch, omOUTLEN)
 #define USWITCH(intType)   switch( (char16_t) intType )
int Omega4( 
         char32_t *omOut, char32_t *in, int inIx, int inLen, int *omSkipPtr, int omCount 
){ /* Returns updated omCount */ 
  int omOutIx=0; 
  int   strIx;
  int omNum=0;
  omPUTSTR( omOut, L"(⍵⊃⍨" ); 
  *omSkipPtr=0;
  for (; inIx< inLen && omOutIx < omOUTLEN; ++inIx) {
      int dig;
      dig= in[inIx];
      if (dig>='0' && dig<='9'){
          ++*omSkipPtr;
          omNum = (omNum*10)+ (dig-'0');
          if (omNum > OMEGA_MAX) 
              return -2;
          omPUTCH(omOut, dig);
       }else
          break;
  }
  if (*omSkipPtr) 
      omCount = omNum;  
  else{
      char tBuf[ OMEGA_DIGITS+1 ];
      ++omCount; 
      if (0 < snprintf( tBuf, sizeof(tBuf), "%d", omCount))
           omPUTSTR( omOut, tBuf );
  }
  omPUTBUF( omOut, ')', omOUTLENPLUS ); omPUTBUF(omOut, 0, omOUTLENPLUS);
  return omCount;
}

/* char32_t, char32_t replaced by char8_t, char16_t, char32_t */
int FMT_C4( char32_t *in, int inLen, char32_t *out, int outLen){
  int outIx = 0;
  int inIx  = 0;
  int i; 
  int class; 
  int curQ;
  int nBraces=0;
  int inSpaces=0;
  int omSkip;
  int omegaCount=0;
  char32_t omOut[ omOUTLENPLUS ];
  INCHECK();
  PREAMBLE();
  if (inLen >= outLen || outLen<1) NOSPACE();
/*   Not in a field   */
/*   Not in a field   */
/*   Not in a field   */
isNone:
  class= cNONE;
  INCHECK();
  if ( in[inIx] == LBRACE ) goto isBrace;
/*    Text field    */
/*    Text field    */
/*    Text field    */
  class = cTEXT;
  PUTSTR(" '");
  for (; inIx<inLen;  ++inIx){
     USWITCH(in[inIx]){
        case SQ: 
           PUTSTR("''"); break;
        case ESC: 
              ++inIx; SPACECHECK();
              USWITCH(in[inIx]){
                case EOS: PUTCH(CR);  break;
                case ESC:  
                case LBRACE:  
                case RBRACE: 
                      PUTCH( in[inIx] ); break;
                default:
                      PUTCH( ESC );  
                      --inIx; break;
              }
              break;
       case LBRACE: 
            nBraces = 1;
            goto isBrace;
            break;
       default:  
           PUTCH( in[inIx] ); break;
       }      
  }
  TEXTCHECK; goto isDone;
  isBrace:
    TEXTCHECK;
    class=cBRACE;
 /* Space field: {   } */
 /* Space field: {   } */
 /* Space field: {   } */
    inSpaces=0; inIx++;
    for (i=inIx; i<inLen && in[i]==SP; ++i, ++inSpaces);
    if (inSpaces && i<inLen && in[i]==RBRACE ) {
       inIx+= inSpaces+1;
       PUTCH(SP); PUTCH(SQ); 
       for (i=0; i<inSpaces; ++i) PUTCH(SP);
       PUTCH(SQ); PUTCH(SP);
       goto isNone;
    }
 /*  Code field:  { code }  */
 /*  Code field:  { code }  */
 /*  Code field:  { code }  */
    nBraces = 1;
    PUTSTR( "({" );
    for ( ; inIx<inLen;  ++inIx){
         USWITCH(in[inIx]){
            case DOLLAR: 
                if (PEEKCH() == DOLLAR) {
                   PUTSTR(L" ⎕SE.Dyalog.Utils.display ");
                   ++inIx;
                }else
                   PUTSTR(L" ⎕FMT "); 
                break;
            case LBRACE: 
               nBraces++; PUTCH( LBRACE );  break;
            case RBRACE: 
               if (--nBraces<=0) {
                 ++inIx;
                 PUTSTR( L"}⍵)" );
                 goto isNone;
               }; 
               PUTCH(RBRACE);
               break;
             case SQ:   
             case DQ: 
               curQ= in[inIx];
               PUTCH( SQ );
               for (++inIx; inIx<inLen ; ++inIx) {
                  if (in[inIx] == curQ){
                     if (PEEKCH() == curQ ) { 
                        PUTCH(curQ); 
                        ++inIx;
                     }else{
                        PUTCH( SQ ); 
                        break; 
                     }
                  }else{
                     if (in[inIx]==ESC){
                       ++inIx; SPACECHECK();
                       USWITCH( in[inIx] ){
                         case EOS: 
                           PUTCH(CR); break;
                         case LBRACE:
                         case RBRACE:
                         case ESC:
                           PUTCH( in[inIx] ); break;
                         default:
                           PUTCH( ESC ); --inIx;
                        } 
                        break;
                     }else if (in[inIx] == SQ) {
                        PUTCH(SQ);PUTCH(SQ );
                     }else PUTCH( in[inIx] ); 
                  }
                } /* for */
                break;
             case ESC:   ++inIx; SPACECHECK();
                USWITCH( in[inIx] ){
                  case EOS: 
                    PUTCH(CR);
                    break;
                  case LBRACE:
                  case RBRACE:
                    PUTCH( in[inIx]);
                    break;
                  case OMEGA:
                    omegaCount = Omega4( 
                       omOut, in, inIx+1, inLen, &omSkip, omegaCount 
                    ); 
                    if (omegaCount < 0) ABEND(-2);
                    PUTSTR( omOut );
                    inIx+= omSkip;
                    break;
                 default:
                    PUTCH( ESC );
                    --inIx;
                  } 
                  break;
             default:    
                PUTCH( in[inIx] ); 
                break;
         }
    }
    goto isDone;
/*   Done! Tidy up...  */  
/*   Done! Tidy up...  */   
/*   Done! Tidy up...  */   
  isDone:
    POSTAMBLE();
    SPACECHECK();
    return 1;
} 
int Omega2( 
         char16_t *omOut, char16_t *in, int inIx, int inLen, int *omSkipPtr, int omCount 
){ /* Returns updated omCount */ 
  int omOutIx=0; 
  int   strIx;
  int omNum=0;
  omPUTSTR( omOut, L"(⍵⊃⍨" ); 
  *omSkipPtr=0;
  for (; inIx< inLen && omOutIx < omOUTLEN; ++inIx) {
      int dig;
      dig= in[inIx];
      if (dig>='0' && dig<='9'){
          ++*omSkipPtr;
          omNum = (omNum*10)+ (dig-'0');
          if (omNum > OMEGA_MAX) 
              return -2;
          omPUTCH(omOut, dig);
       }else
          break;
  }
  if (*omSkipPtr) 
      omCount = omNum;  
  else{
      char tBuf[ OMEGA_DIGITS+1 ];
      ++omCount; 
      if (0 < snprintf( tBuf, sizeof(tBuf), "%d", omCount))
           omPUTSTR( omOut, tBuf );
  }
  omPUTBUF( omOut, ')', omOUTLENPLUS ); omPUTBUF(omOut, 0, omOUTLENPLUS);
  return omCount;
}

/* char16_t, char16_t replaced by char8_t, char16_t, char32_t */
int FMT_C2( char16_t *in, int inLen, char16_t *out, int outLen){
  int outIx = 0;
  int inIx  = 0;
  int i; 
  int class; 
  int curQ;
  int nBraces=0;
  int inSpaces=0;
  int omSkip;
  int omegaCount=0;
  char16_t omOut[ omOUTLENPLUS ];
  INCHECK();
  PREAMBLE();
  if (inLen >= outLen || outLen<1) NOSPACE();
/*   Not in a field   */
/*   Not in a field   */
/*   Not in a field   */
isNone:
  class= cNONE;
  INCHECK();
  if ( in[inIx] == LBRACE ) goto isBrace;
/*    Text field    */
/*    Text field    */
/*    Text field    */
  class = cTEXT;
  PUTSTR(" '");
  for (; inIx<inLen;  ++inIx){
     USWITCH(in[inIx]){
        case SQ: 
           PUTSTR("''"); break;
        case ESC: 
              ++inIx; SPACECHECK();
              USWITCH(in[inIx]){
                case EOS: PUTCH(CR);  break;
                case ESC:  
                case LBRACE:  
                case RBRACE: 
                      PUTCH( in[inIx] ); break;
                default:
                      PUTCH( ESC );  
                      --inIx; break;
              }
              break;
       case LBRACE: 
            nBraces = 1;
            goto isBrace;
            break;
       default:  
           PUTCH( in[inIx] ); break;
       }      
  }
  TEXTCHECK; goto isDone;
  isBrace:
    TEXTCHECK;
    class=cBRACE;
 /* Space field: {   } */
 /* Space field: {   } */
 /* Space field: {   } */
    inSpaces=0; inIx++;
    for (i=inIx; i<inLen && in[i]==SP; ++i, ++inSpaces);
    if (inSpaces && i<inLen && in[i]==RBRACE ) {
       inIx+= inSpaces+1;
       PUTCH(SP); PUTCH(SQ); 
       for (i=0; i<inSpaces; ++i) PUTCH(SP);
       PUTCH(SQ); PUTCH(SP);
       goto isNone;
    }
 /*  Code field:  { code }  */
 /*  Code field:  { code }  */
 /*  Code field:  { code }  */
    nBraces = 1;
    PUTSTR( "({" );
    for ( ; inIx<inLen;  ++inIx){
         USWITCH(in[inIx]){
            case DOLLAR: 
                if (PEEKCH() == DOLLAR) {
                   PUTSTR(L" ⎕SE.Dyalog.Utils.display ");
                   ++inIx;
                }else
                   PUTSTR(L" ⎕FMT "); 
                break;
            case LBRACE: 
               nBraces++; PUTCH( LBRACE );  break;
            case RBRACE: 
               if (--nBraces<=0) {
                 ++inIx;
                 PUTSTR( L"}⍵)" );
                 goto isNone;
               }; 
               PUTCH(RBRACE);
               break;
             case SQ:   
             case DQ: 
               curQ= in[inIx];
               PUTCH( SQ );
               for (++inIx; inIx<inLen ; ++inIx) {
                  if (in[inIx] == curQ){
                     if (PEEKCH() == curQ ) { 
                        PUTCH(curQ); 
                        ++inIx;
                     }else{
                        PUTCH( SQ ); 
                        break; 
                     }
                  }else{
                     if (in[inIx]==ESC){
                       ++inIx; SPACECHECK();
                       USWITCH( in[inIx] ){
                         case EOS: 
                           PUTCH(CR); break;
                         case LBRACE:
                         case RBRACE:
                         case ESC:
                           PUTCH( in[inIx] ); break;
                         default:
                           PUTCH( ESC ); --inIx;
                        } 
                        break;
                     }else if (in[inIx] == SQ) {
                        PUTCH(SQ);PUTCH(SQ );
                     }else PUTCH( in[inIx] ); 
                  }
                } /* for */
                break;
             case ESC:   ++inIx; SPACECHECK();
                USWITCH( in[inIx] ){
                  case EOS: 
                    PUTCH(CR);
                    break;
                  case LBRACE:
                  case RBRACE:
                    PUTCH( in[inIx]);
                    break;
                  case OMEGA:
                    omegaCount = Omega2( 
                       omOut, in, inIx+1, inLen, &omSkip, omegaCount 
                    ); 
                    if (omegaCount < 0) ABEND(-2);
                    PUTSTR( omOut );
                    inIx+= omSkip;
                    break;
                 default:
                    PUTCH( ESC );
                    --inIx;
                  } 
                  break;
             default:    
                PUTCH( in[inIx] ); 
                break;
         }
    }
    goto isDone;
/*   Done! Tidy up...  */  
/*   Done! Tidy up...  */   
/*   Done! Tidy up...  */   
  isDone:
    POSTAMBLE();
    SPACECHECK();
    return 1;
} 
int Omega1( 
         char16_t *omOut, char8_t *in, int inIx, int inLen, int *omSkipPtr, int omCount 
){ /* Returns updated omCount */ 
  int omOutIx=0; 
  int   strIx;
  int omNum=0;
  omPUTSTR( omOut, L"(⍵⊃⍨" ); 
  *omSkipPtr=0;
  for (; inIx< inLen && omOutIx < omOUTLEN; ++inIx) {
      int dig;
      dig= in[inIx];
      if (dig>='0' && dig<='9'){
          ++*omSkipPtr;
          omNum = (omNum*10)+ (dig-'0');
          if (omNum > OMEGA_MAX) 
              return -2;
          omPUTCH(omOut, dig);
       }else
          break;
  }
  if (*omSkipPtr) 
      omCount = omNum;  
  else{
      char tBuf[ OMEGA_DIGITS+1 ];
      ++omCount; 
      if (0 < snprintf( tBuf, sizeof(tBuf), "%d", omCount))
           omPUTSTR( omOut, tBuf );
  }
  omPUTBUF( omOut, ')', omOUTLENPLUS ); omPUTBUF(omOut, 0, omOUTLENPLUS);
  return omCount;
}

/* char8_t, char16_t replaced by char8_t, char16_t, char32_t */
int FMT_C1( char8_t *in, int inLen, char16_t *out, int outLen){
  int outIx = 0;
  int inIx  = 0;
  int i; 
  int class; 
  int curQ;
  int nBraces=0;
  int inSpaces=0;
  int omSkip;
  int omegaCount=0;
  char16_t omOut[ omOUTLENPLUS ];
  INCHECK();
  PREAMBLE();
  if (inLen >= outLen || outLen<1) NOSPACE();
/*   Not in a field   */
/*   Not in a field   */
/*   Not in a field   */
isNone:
  class= cNONE;
  INCHECK();
  if ( in[inIx] == LBRACE ) goto isBrace;
/*    Text field    */
/*    Text field    */
/*    Text field    */
  class = cTEXT;
  PUTSTR(" '");
  for (; inIx<inLen;  ++inIx){
     USWITCH(in[inIx]){
        case SQ: 
           PUTSTR("''"); break;
        case ESC: 
              ++inIx; SPACECHECK();
              USWITCH(in[inIx]){
                case EOS: PUTCH(CR);  break;
                case ESC:  
                case LBRACE:  
                case RBRACE: 
                      PUTCH( in[inIx] ); break;
                default:
                      PUTCH( ESC );  
                      --inIx; break;
              }
              break;
       case LBRACE: 
            nBraces = 1;
            goto isBrace;
            break;
       default:  
           PUTCH( in[inIx] ); break;
       }      
  }
  TEXTCHECK; goto isDone;
  isBrace:
    TEXTCHECK;
    class=cBRACE;
 /* Space field: {   } */
 /* Space field: {   } */
 /* Space field: {   } */
    inSpaces=0; inIx++;
    for (i=inIx; i<inLen && in[i]==SP; ++i, ++inSpaces);
    if (inSpaces && i<inLen && in[i]==RBRACE ) {
       inIx+= inSpaces+1;
       PUTCH(SP); PUTCH(SQ); 
       for (i=0; i<inSpaces; ++i) PUTCH(SP);
       PUTCH(SQ); PUTCH(SP);
       goto isNone;
    }
 /*  Code field:  { code }  */
 /*  Code field:  { code }  */
 /*  Code field:  { code }  */
    nBraces = 1;
    PUTSTR( "({" );
    for ( ; inIx<inLen;  ++inIx){
         USWITCH(in[inIx]){
            case DOLLAR: 
                if (PEEKCH() == DOLLAR) {
                   PUTSTR(L" ⎕SE.Dyalog.Utils.display ");
                   ++inIx;
                }else
                   PUTSTR(L" ⎕FMT "); 
                break;
            case LBRACE: 
               nBraces++; PUTCH( LBRACE );  break;
            case RBRACE: 
               if (--nBraces<=0) {
                 ++inIx;
                 PUTSTR( L"}⍵)" );
                 goto isNone;
               }; 
               PUTCH(RBRACE);
               break;
             case SQ:   
             case DQ: 
               curQ= in[inIx];
               PUTCH( SQ );
               for (++inIx; inIx<inLen ; ++inIx) {
                  if (in[inIx] == curQ){
                     if (PEEKCH() == curQ ) { 
                        PUTCH(curQ); 
                        ++inIx;
                     }else{
                        PUTCH( SQ ); 
                        break; 
                     }
                  }else{
                     if (in[inIx]==ESC){
                       ++inIx; SPACECHECK();
                       USWITCH( in[inIx] ){
                         case EOS: 
                           PUTCH(CR); break;
                         case LBRACE:
                         case RBRACE:
                         case ESC:
                           PUTCH( in[inIx] ); break;
                         default:
                           PUTCH( ESC ); --inIx;
                        } 
                        break;
                     }else if (in[inIx] == SQ) {
                        PUTCH(SQ);PUTCH(SQ );
                     }else PUTCH( in[inIx] ); 
                  }
                } /* for */
                break;
             case ESC:   ++inIx; SPACECHECK();
                USWITCH( in[inIx] ){
                  case EOS: 
                    PUTCH(CR);
                    break;
                  case LBRACE:
                  case RBRACE:
                    PUTCH( in[inIx]);
                    break;
                  case OMEGA:
                    omegaCount = Omega1( 
                       omOut, in, inIx+1, inLen, &omSkip, omegaCount 
                    ); 
                    if (omegaCount < 0) ABEND(-2);
                    PUTSTR( omOut );
                    inIx+= omSkip;
                    break;
                 default:
                    PUTCH( ESC );
                    --inIx;
                  } 
                  break;
             default:    
                PUTCH( in[inIx] ); 
                break;
         }
    }
    goto isDone;
/*   Done! Tidy up...  */  
/*   Done! Tidy up...  */   
/*   Done! Tidy up...  */   
  isDone:
    POSTAMBLE();
    SPACECHECK();
    return 1;
} 
