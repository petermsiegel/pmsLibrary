 f32a←{                              ⍝ Conversion to 32-bit floats as ⎕DR 83.
     nbytes←4×≢flatObj←∊⍵             ⍝ bytes count
     ptr←⍕{2×⎕SIZE'⍵'}⍬               ⍝ '32' or '64'
     MEMCPY←⊢                        ⍝ local name for ⎕NA'd function
     _←⎕NA'dyalog64.dylib|MEMCPY  >I1[] <F4[] I4'    ⍝ link to library fn
     MEMCPY nbytes flatObj nbytes
 }
