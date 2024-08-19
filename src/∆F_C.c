#include <stdio.h>
/* Not found on macos 
   #include <uchar.h> 
*/
#define char8_t  unsigned char 
#define char16_t __CHAR16_TYPE__
#define char32_t __CHAR32_TYPE__
#define wchar_t  __WCHAR_TYPE__
/* IN_CHAR, OUT_CHAR replaced by char8_t, char16_t, char32_t */
int FMT_C4( char32_t *in, int inLen, char32_t *out, int outLen){
    int i;
    wchar_t *str = L"{⊢⎕←'The fmt str is ',⊃⍵}";
    if (inLen >= outLen || outLen<1)   /* we need 1 space for the null */
        goto bad;
    for (i=0; i< inLen && i<outLen; ++i)
         out[i]=in[i];
    for (i=0; str[i]; ++i)
         out[i]=str[i];  
    if ( i>= outLen )
        goto bad;
    out[i]=0; 
    return i;
 bad:
   out[0]=0;
   return 0;
} 
int FMT_C2( char16_t *in, int inLen, char16_t *out, int outLen){
    int i;
    wchar_t *str = L"{⊢⎕←'The fmt str is ',⊃⍵}";
    if (inLen >= outLen || outLen<1)   /* we need 1 space for the null */
        goto bad;
    for (i=0; i< inLen && i<outLen; ++i)
         out[i]=in[i];
    for (i=0; str[i]; ++i)
         out[i]=str[i];  
    if ( i>= outLen )
        goto bad;
    out[i]=0; 
    return i;
 bad:
   out[0]=0;
   return 0;
} 
int FMT_C1( char8_t *in, int inLen, char16_t *out, int outLen){
    int i;
    wchar_t *str = L"{⊢⎕←'The fmt str is ',⊃⍵}";
    if (inLen >= outLen || outLen<1)   /* we need 1 space for the null */
        goto bad;
    for (i=0; i< inLen && i<outLen; ++i)
         out[i]=in[i];
    for (i=0; str[i]; ++i)
         out[i]=str[i];  
    if ( i>= outLen )
        goto bad;
    out[i]=0; 
    return i;
 bad:
   out[0]=0;
   return 0;
} 
