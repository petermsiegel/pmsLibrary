       set -x
       cc -O3 -c -o ∆F4.temp -D WIDTH=4 ∆F.c
       cc -O3 -c -o ∆F2.temp -D WIDTH=2 ∆F.c
       cc -dynamiclib -o ∆F.dylib ∆F4.temp ∆F2.temp
       rm ∆F4.temp ∆F2.temp 
       set +x 
       echo 'GENERATED ∆F.dylib with 2-byte and 4-byte utilities:'
       echo '          fs_format4 and fs_format2'