#include "gmp/include/gmp.h" 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define BASE10 10
/* cc -O3 -shared -o Bignum.so  gmp/lib/libgmp.dylib Bignum.c    */
/* add: maxOut is (3 + str1 ⌈⍥≢ str2 )     Add 3 for sign, carry, terminating null */
/* sub: maxOut is (3 + str1 ⌈⍥≢ str2 )     Add 3 for sign, carry, terminating null */
/* mul: maxOut is (3 + str1 +⍥≢ str2 )     Add 3 for sign, carry, terminating null */
/* div: maxOut is (2 + ≢str1 )             Add 2 for sign, terminating null */
#define SELECT1 
#ifdef SELECT1 
int add( char *str3, int maxOut, char *str1, char *str2) {
#else  
int add( char str3[512], int maxOut, char *str1, char *str2) {
#endif 
  mpz_t op1, op2, op3;
  int rc, needed;
  mpz_init_set_str(op1, str1, BASE10);
  mpz_init_set_str(op2, str2, BASE10);
  str3[0]=0;
  mpz_add( op3, op1, op2 );  
  needed= mpz_sizeinbase(op3, BASE10) + 2;  
  /* printf("Space needed is %i bytes, avail %i\n", needed, maxOut); */
  if (maxOut >= needed){
    mpz_get_str( str3, 10, op3 );
    rc=0; /* rc=0: everything is ok */
  } else 
    rc=1; /* rc=1: Not enough space */
  mpz_clears( op1, op2, op3, 0 );
  return(rc);
}
/* 
int main( int argc, char **argv){
    int rc;
    char *str3;
    char *str1= "0111111111111111111111111111111111111111111111111111111111111111";
    char *str2= "2222222222222222222222222222222222222222222222222222222222222222";
    int  l1, l2, l3;
    l1= strlen(str1); l2= strlen(str2);
    l3= ((l1<l2)?l2:l1)+ 112;    / * 3: sign + carry + null * /
    str3= (char *) malloc( l3 * sizeof(char) );
    *str3= '\0';
    printf("Size of str1=%d, str2=%d, str3=%d\n", l1, l2, l3 );
    rc= add(str3, l3, str1, str2); 
    if (0==rc)
         printf("%s\n", str3);
    else 
         printf("rc=%d\n", rc);
    free(str3);
    return 0;
}
*/
 