⍝ Bignum.dyalog
⍝ /usr/local/Cellar/gmp/6.3.0/lib  => 'gmp/lib/libgmp.dylib', 'gmp/include/gmp.h'
⍝ #include </usr/local/Cellar/gmp/6.3.0/include/gmp.h>
 decl← '<C',inType,'[] I4 >0C',outType,'[] I4 I4'
      (⍕⎕THIS),'.',('∆F',inType)⎕NA 'I4 ',LIB,'|FMT_C',inType, ' ',decl 
⍝      ⎕NA 'I4 gmp/lib/libgmp.dylib|add >C1024 <C0 <C0' 
⍝P #include <gmp/include/gmp.h> 
⍝P #DEFINE BASE10 10
⍝C int add( char str3[1024], char *str1, char *str2) {
⍝C   mpz_t op1, op2, op3;
⍝C   mpz_init_set_str(op1, str1, BASE10);
⍝C   mpz_init_set_str(op2, str2, BASE10);
⍝C   mpz_add( op3, op1, op2 );    
⍝C   if (sizeof(str3) >= mpz_sizeinbase(op3, BASE10) + 2){
⍝C     mpz_get_str( str3, 10, op3 );
⍝C     rc=0; 
⍝C   } else 
⍝C     rc=1; /* Not enough space */
⍝C   mpz_clears( op1, op2, op3, NULL );
⍝C   return(rc);
⍝C }
