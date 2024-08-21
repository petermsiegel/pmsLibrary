#include <stdio.h>
/* Not found on macos 
   #include <uchar.h> 
*/
#define char8_t       unsigned char 
#define char16_t      __CHAR16_TYPE__
#define char32_t      __CHAR32_TYPE__
#define wchar_t       __WCHAR_TYPE__
#define cNONE         0
#define cTEXT         1
#define cBRACE        2
#define cQUOTE        3
#define SP            ' '
#define SQ            '\''
#define DQ            '"'
#define LBRACE        '{'
#define RBRACE        '}'
#define EOS           L'⋄'
#define ESC           L'`'
#define CR            '\r'
#define FAUXCR        L'␍'
#define PUTCH(ch)     if (outIx<outLen) out[outIx++]=ch
#define PUTSTR(str)   for (i=0; str[i] && outIx<outLen;) out[outIx++]=str[i++]
#define NOSPACE()     { out[0]=0; return -1;}
#define PREAMBLE()    PUTSTR(L"{⍺⍺ ")
#define POSTAMBLE()   {PUTSTR("} ");  PUTCH(0);}
#define SPACECHECK()  if (outIx >= outLen) NOSPACE();
#define INCHECK()     if (inIx >= inLen) goto isDone 
#define TEXTCHECK     if (class == cTEXT) PUTSTR("' ")

/* IN_CHAR, OUT_CHAR replaced by char8_t, char16_t, char32_t */
int FMT_C4( char32_t *in, int inLen, char32_t *out, int outLen){
  int outIx = 0;
  int inIx  = 0;
  int i; 
  int class; 
  int nBraces=0;
  int inSpaces=0;
  INCHECK();
  PREAMBLE();
  if (inLen >= outLen || outLen<1) NOSPACE();
isNone:
  class= cNONE;
  INCHECK();
  if ( in[inIx] == LBRACE ) goto isBrace;
  class = cTEXT;
  PUTSTR(" '");
  for (; inIx<inLen;  ++inIx){
        switch(in[inIx]){
           case SQ:     PUTSTR("''"); break;
           case ESC: 
                 ++inIx; SPACECHECK();
                 switch(in[inIx]){
                   case EOS: PUTCH(FAUXCR);  break;
                   case ESC:  
                   case LBRACE:  
                   case RBRACE: 
                             PUTCH( in[inIx] ); break;
                   default:
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
    inSpaces=0;
    for (i=inIx+1; i<inLen && in[i]==SP; ++i, ++inSpaces);
    if (inSpaces && i<inLen && in[i]==RBRACE ) {
       inIx+= inSpaces+2;
       PUTCH(SP); PUTCH(SQ); 
       for (i=0; i<inSpaces; ++i) PUTCH(SP);
       PUTCH(SQ); PUTCH(SP);
       goto isNone;
    }
 /* Code field:  { code } */
    nBraces = 1;
    PUTSTR( "({" );
    for ( ++inIx; inIx<inLen;  ++inIx){
         switch(in[inIx]){
            case LBRACE: nBraces++; PUTCH( LBRACE ); break;
            case RBRACE: 
                         if (--nBraces<=0) {
                           ++inIx;
                           PUTSTR( L"}⍵)" );
                           goto isNone;
                         }; 
                         PUTCH(RBRACE);
                         break;
             default:    PUTCH( in[inIx] ); break;
         }
    }
    goto isDone;
    
  isDone:
    POSTAMBLE();
    SPACECHECK();
    return 1;
} 
int FMT_C2( char16_t *in, int inLen, char16_t *out, int outLen){
  int outIx = 0;
  int inIx  = 0;
  int i; 
  int class; 
  int nBraces=0;
  int inSpaces=0;
  INCHECK();
  PREAMBLE();
  if (inLen >= outLen || outLen<1) NOSPACE();
isNone:
  class= cNONE;
  INCHECK();
  if ( in[inIx] == LBRACE ) goto isBrace;
  class = cTEXT;
  PUTSTR(" '");
  for (; inIx<inLen;  ++inIx){
        switch(in[inIx]){
           case SQ:     PUTSTR("''"); break;
           case ESC: 
                 ++inIx; SPACECHECK();
                 switch(in[inIx]){
                   case EOS: PUTCH(FAUXCR);  break;
                   case ESC:  
                   case LBRACE:  
                   case RBRACE: 
                             PUTCH( in[inIx] ); break;
                   default:
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
    inSpaces=0;
    for (i=inIx+1; i<inLen && in[i]==SP; ++i, ++inSpaces);
    if (inSpaces && i<inLen && in[i]==RBRACE ) {
       inIx+= inSpaces+2;
       PUTCH(SP); PUTCH(SQ); 
       for (i=0; i<inSpaces; ++i) PUTCH(SP);
       PUTCH(SQ); PUTCH(SP);
       goto isNone;
    }
 /* Code field:  { code } */
    nBraces = 1;
    PUTSTR( "({" );
    for ( ++inIx; inIx<inLen;  ++inIx){
         switch(in[inIx]){
            case LBRACE: nBraces++; PUTCH( LBRACE ); break;
            case RBRACE: 
                         if (--nBraces<=0) {
                           ++inIx;
                           PUTSTR( L"}⍵)" );
                           goto isNone;
                         }; 
                         PUTCH(RBRACE);
                         break;
             default:    PUTCH( in[inIx] ); break;
         }
    }
    goto isDone;
    
  isDone:
    POSTAMBLE();
    SPACECHECK();
    return 1;
} 
int FMT_C1( char8_t *in, int inLen, char16_t *out, int outLen){
  int outIx = 0;
  int inIx  = 0;
  int i; 
  int class; 
  int nBraces=0;
  int inSpaces=0;
  INCHECK();
  PREAMBLE();
  if (inLen >= outLen || outLen<1) NOSPACE();
isNone:
  class= cNONE;
  INCHECK();
  if ( in[inIx] == LBRACE ) goto isBrace;
  class = cTEXT;
  PUTSTR(" '");
  for (; inIx<inLen;  ++inIx){
        switch(in[inIx]){
           case SQ:     PUTSTR("''"); break;
           case ESC: 
                 ++inIx; SPACECHECK();
                 switch(in[inIx]){
                   case EOS: PUTCH(FAUXCR);  break;
                   case ESC:  
                   case LBRACE:  
                   case RBRACE: 
                             PUTCH( in[inIx] ); break;
                   default:
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
    inSpaces=0;
    for (i=inIx+1; i<inLen && in[i]==SP; ++i, ++inSpaces);
    if (inSpaces && i<inLen && in[i]==RBRACE ) {
       inIx+= inSpaces+2;
       PUTCH(SP); PUTCH(SQ); 
       for (i=0; i<inSpaces; ++i) PUTCH(SP);
       PUTCH(SQ); PUTCH(SP);
       goto isNone;
    }
 /* Code field:  { code } */
    nBraces = 1;
    PUTSTR( "({" );
    for ( ++inIx; inIx<inLen;  ++inIx){
         switch(in[inIx]){
            case LBRACE: nBraces++; PUTCH( LBRACE ); break;
            case RBRACE: 
                         if (--nBraces<=0) {
                           ++inIx;
                           PUTSTR( L"}⍵)" );
                           goto isNone;
                         }; 
                         PUTCH(RBRACE);
                         break;
             default:    PUTCH( in[inIx] ); break;
         }
    }
    goto isDone;
    
  isDone:
    POSTAMBLE();
    SPACECHECK();
    return 1;
} 
