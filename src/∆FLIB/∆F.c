#include <stdio.h>
#include <stdint.h>
#include <string.h> 
#include <ctype.h>

#define CHAR4  uint32_t
#define CHAR2  uint16_t  
#define  INT4   int32_t 

#define STRLEN_MAX  512  
// Str2Len(str)
//   <str> is a null-terminated CHARW string.
//   Returns the length of the string, sans the final null.
//   If there is no final null, we will either abnormally terminate or 
//   return a length of STRLEN_MAX.
static inline int Str2Len(CHAR2 *str) {
    int len;
    for (len=0; len<STRLEN_MAX && str[len]; ++len)
        ;
    return len;
} 

static inline INT4 afterBlanks4(CHAR4 fString[], INT4 fStringLen, int inPos){
    for (; inPos < fStringLen && ' ' == fString[inPos]; ++inPos)
           ;
    if (inPos>=fStringLen) 
        return -1;
    return fString[inPos];  // -1 if beyond end  
}
static inline INT4 afterBlanks2(CHAR2 fString[], INT4 fStringLen, int inPos){
    for (; inPos < fStringLen && ' ' == fString[inPos]; ++inPos)
           ;
    if (inPos>=fStringLen) 
        return -1;
    return fString[inPos];  // -1 if beyond end  
}


#define USE_CHAR4  1
#include "∆F_PROTO.c"

#undef USE_CHAR4
#define USE_CHAR4  0
#include "∆F_PROTO.c"
