       set -x
       cc -O3 -c -o ∆F4.dylib -D WIDTH=4 ∆F.c
       cc -O3 -c -o ∆F2.dylib -D WIDTH=2 ∆F.c
       cc -dynamiclib -o ∆F.dylib ∆F4.dylib ∆F2.dylib
       rm ∆F4.dylib ∆F2.dylib 
       set +x 
       echo 'GENERATED ∆F2.dylib and ∆F4.dylib with 2-byte and 4-byte calls'