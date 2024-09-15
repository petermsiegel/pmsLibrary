:namespace Bignum 

⍝ Bignum.dyalog
⍝ /usr/local/Cellar/gmp/6.3.0/lib  => 'gmp/lib/libgmp.dylib', 'gmp/include/gmp.h'

Compile←{
  ⎕SH 'cc -O3 -shared -o Bignum.so Bignum.c'
}
Load←{   
    ⎕NA 'I4 Bignum.so|add >0C I4 <0C <0C' 
} 

:EndNamespace
