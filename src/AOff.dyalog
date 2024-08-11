  AOff←{
    ⍝ offset_bytes← [library] AOff rank 
    ⍝ Find the offset in BYTES to the payload of any APL I4 (32-bit integer) array.
    ⍝ (Same as finding the length of the header in bytes).
    ⍝ ⍵:  A single integer:  
    ⍝     1: return offset in bytes for vector, 2: for matrix, 3: for 3-dim array
    ⍝ ⍺:  the dynamic library containing MEMCPY. You shouldn't need to set this.
    ⍝     What is the name of the dynamic library for utility MEMCPY?
    ⍝     We are assuming it's in dyalog64 with a possible extension:
    ⍝         Windows: (none); Mac: .dylib; Linux, AIX, Pi: .so
    ⍝     If this isn't correct, set ⍺ on your own!
    ⍝ Note: This can be extended by the reader to handle other ints, floats, char types, etc. 
    ⍝       We expect the header offsets will be identical given the same ranks.
    ⍝ Method:
    ⍝ ∘ Copy out a small number of integers (but bigger than the expected header size)
    ⍝   as a "raw" APL array (type 'A'), starting it with a unique "signature" integer value.
    ⍝ ∘ Read it back as an integer array. 
    ⍝ This will return the original header as part of the APL payload (integer array).
    ⍝ ∘ Search for the first instance of the signature, 
    ⍝   which will be the offset to the APL payload (just past the header).
    ⍝ Returns: the offset IN BYTES for the rank specified.
    ⍝ Note: Currently on the Mac, the offset is:
    ⍝       24+ 8× rank

      ⎕IO ⎕ML←0 1
      rank signature nelem← ⍵ ¯314159265 32  
      ⍺← 'dyalog64', '' '.dylib' '.so'⊃⍨ 'Win' 'Mac'⍳ ⊂3↑⊃'.'⎕WG'APLversion'
      library← ⍺ 
      ⋄ err1← 'AOff DOMAIN ERROR: rank ∉ 1 2 3  -OR- 1 ≠ ≢rank' 11  
      ⋄ err2← 'AOff UNKNOWN ERROR' 911
      ⋄ err2← 'AOff OBJECT FORMAT ERROR: unable to locate signature at start of payload' 912
    1≠ ≢rank: ⎕SIGNAL/err1 ⋄ (>∘3∨<∘1) rank: ⎕SIGNAL/err1 ⋄ 0:: ⎕SIGNAL/err2
    ⍝ Load utility memcpy as local fn MC2I4 (copy header and payload of 32-bit int array)
    ⍝ void* memcpy( void* dest, const void* src, std::size_t count );
      MC2I4← ⊢  ⋄ _←'MC2I4' ⎕NA library,'|MEMCPY >I4[] <A I4' 
    ⍝ * Object contains the signature, an integer unlikely to occur in the header,
    ⍝   padded with zeroes to length <nelem> and shaped as shown here to the rank <rank>.
      obj←  (nelem↑ signature)⍴⍨ nelem,⍨ 1⍴⍨ ¯1+ rank
      iOff← signature⍳⍨ MC2I4 nelem obj (4× nelem)
    iOff<nelem: 4× iOff ⋄ ⎕SIGNAL/err3 
}
