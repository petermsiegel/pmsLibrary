:namespace BigIntHelp
  ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯  D O C U M E N T A T I O N  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
  ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
  ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
  ⍝ ∘ NOTE: See bigIntHelp for details...
  ⍝
  ⍝ ∘ BigInt is a signed Big-Integer utility built around the unsigned big integer utility, dfns:nats.
  ⍝   <nats> seems to have the fastest general-purpose multiply and divide in dfns.
  ⍝ ∘ BIi: We've created an efficient BigInt Internal Data "structure" BIi (BI Internal) of this form:
  ⍝        BIi ← sign  data
  ⍝        where sign@I∊¯1 0 1, data@UV<10E6
  ⍝              The sign is an integer;
  ⍝              The data is an unsigned APL integer vector, whose elements are <RX (10E6).
  ⍝        In functions manipulating signed numbers, zero is ALWAYS (sign:0 data:(,0)) making tests for 0 FAST.
  ⍝        in unsigned functions, zero passed in and out is (,0).
  ⍝        NOTE: Nats functions are modified to always return valid sign and <data>.
  ⍝ ∘ BIx: The external format of BigIntegers, BIx, contains:
  ⍝        on input:   "[¯-]?\d[\d_]*"  (a sign ¯ or - followed by at least 1 digit, and ≥0 underscores as spacers)
  ⍝        on output:  "¯?[\d+]"
  ⍝        Note: BigInt fns returning BIx only return output-format strings, never (say) '-25' or '25_123'.
  ⍝ ∘ BIc: On occasion we'll mention BIc, a "character" string format string used as INPUT, as opposed to
  ⍝        BIi (internal-format sign/data structure) or Int (APL Integer).
  ⍝
  ⍝ ∘ Operators BI, BIX:   For  [⍺] op BI* ⍵
  ⍝       Performs   ⍺ op ⍵ or op ⍵, where ⍺, ⍵ are bigIntegers (in external or internal form.)
  ⍝       BI  (returns BIi, internal form bigInt) and BIX (returns BIx, external form).
  ⍝   Operator BIM:        For [⍺] op BIM ⍵⍵ ⊣ modulo
  ⍝       Performs  ⍺ op ⍵⍵ (MODULO ⍵)    or   op ⍵⍵ (MODULO ⍵)
  ⍝       Returns BIi (like BIX)
  ⍝       Currently, only ×BIM is optimized for modular arithmetic (modMul)
  ⍝
  ⍝   We've added a range of monadic functions and extended the dyadic functions as well, all signed.
  ⍝   The key easy-use utilities are BI and BIX, used (with '#.BigInt' in ⎕PATH) in this form:
  ⍝       dyadic:    r:BIi← ⍺ +BI ⍵       r:BIx← ⍺ +BIX ⍵     with some exceptions (see below).
  ⍝       monadic:   r:BIi←   ×BI ⍵       r:BIx←   ×BIX ⍵     ditto.
  ⍝   For character string operands of BI/X, e.g. 'SQRT' or 'MOD',
  ⍝   parentheses are usually required (case is ignored):
  ⍝       dyadic: ⍺ ('MOD'BI)  ⍵      ←→   ⍺ mod ⍵     ⍝ Case matters for explicit function syntax!
  ⍝       monadic:  ('SQRT'BI) ⍵      ←⍀     sqrt ⍵
  ⍝   And ALL allow commutation directly, e.g.|⍨ (a synonym for modulo):
  ⍝               ⍺ |⍨BI ⍵     ←→  ⍺ |BI⍨ ⍵    ←→  ⍵ |BI ⍺
  ⍝   BI works fine with APL standard commutation, reduction, and scan as well:
  ⍝               +BI/⍵1 ⍵2 ⍵3...
  ⍝               ⍺ ÷BI⍨ ⍵    ←→ ⍵ ÷BI ⍺
  ⍝               +BI\⍵1 ⍵2 ⍵2...
  ⍝
  ⍝   BI doesn't return external BigInt strings, but ONLY internal format objects, for efficiency.
  ⍝        (To convert to external, use ⍕BI or simply use BIX for the last computation in a series.)
  ⍝   BIX returns BigInt strings wherever BI would return a BigInt-internal object.
  ⍝         c +BIX x ×BI b +BI x ×BI a    ←→  ⍕BI c +BI x ×BI b +BI x ×BI a    ⍝ (a×x*2)+(b×x)+c
  ⍝   Both BIX and BI return booleans with logical functions (< ≤ = ≥ > ≠). See below.
  ⍝
  ⍝   Given BIX, why use BI at all?
  ⍝   ¯¯¯¯¯ ¯¯¯¯ ¯¯¯ ¯¯¯ ¯¯ ¯¯ ¯¯¯¯
  ⍝   ∘ It is a bit more efficient for algorithms built around BigIntegers, esp. those with a lot of math.
  ⍝     And... why not mix and match?
  ⍝   For "desk calculator" uses, BIX is always a perfect choice.
  ⍝
  ⍝   Left operands (⍺⍺) to BI/X include:
  ⍝       dyadic:  + - x ÷ *     | ⌈ ⌊ ≠ < ≤ = ≥ > ≠ ⌽  ∨ ∧
  ⍝       monadic: + - x ÷   ! ? | ⌈ ⌊   <       >      ⊥ ⊤ ⍎ ⍕ ←
  ⍝   (All return integer results).
  ⍝
  ⍝   Those with special meaning include:
  ⍝       dyadic:  ⌽ (shiftD), ∨ (gcd), ∧ (lcm)
  ⍝       monadic: ? (roll on ⍵>0),  ⍎ (convert to APL int), ⍕ (convert to BI string)
  ⍝                ← (return BI-internal format)
  ⍝                ⊥ (bits to bigint), ⊤ (bigInt to bits),
  ⍝                ≢ (sign×count of bits different from sign-bit in twos-complement)
  ⍝ ∘ Arguments to most functions are BigIntegers of any BIx form:
  ⍝       a single BigInteger string in quotes    '-2343_243422'
  ⍝       a single APL signed integer (whether stored as an integer or float)   ¯2343243422
  ⍝       a BI internal-format vector, consisting of a scalar sign followed by a data vector of unsigned numbers;
  ⍝          See the internal format (above).     ¯1 (2343 243422)
  ⍝ ∘ Instead of using operand with BI (+BI), a set of BigInteger functions can be called directly:
  ⍝       dyadic:   ⍺ add ⍵ ⋄  ⍺ gcd ⍵ ⋄⋄⋄
  ⍝       monadic:  sig  ⍵   ⋄  roll '1',99⍴'0'
  ⍝   These all return a BIi (BigInteger internal format), with a few exceptions (exp/ort returns a BIx).
  ⍝   Many local functions have abbreviated synonyms. Local functions include:
  ⍝       add sub mul div  divrem pow res(idue)/rem(ainder) mod (res⍨)
  ⍝       shiftD times10Exp div10Exp shiftB times2Exp div2Exp
  ⍝       neg sig(num)  abs roll
  ⍝   Logical functions < ≤ = ≥ > ≠ return a single boolean, to make them easy to use
  ⍝   in program control. (gcd ∨ and lcm ∧ always return BI internals, since their logical use is a subset).
  ⍝
  ⍝ ∘ Bit strings are passed to the user as two's-complement boolean vectors,
  ⍝   with the lowest-order bit last (so ⍵[¯1+≢⍵] is the LOB),
  ⍝   and the sign-bit first, i.e. as the leftmost- bit (i.e. ⊃⍵ is 1, if the # if negative).
  ⍝
  ⍝ Notable enhancements compared to dfns:nats:
  ⍝ ∘ Input BI strings may have ¯ or - prefixed for negative numbers and may include _ as spacers,
  ⍝   which are ignored:   e.g.  '-553_555_555'    '¯99999_12345_12345'    '00000_00000_00000'
  ⍝ ∘ ⌽BI is used to shift (not rotate) binary digits left and right,
  ⍝   i.e. to multiply and divide by 2**⍵ very quickly and efficiently.
  ⍝      ∘ Example: A million-digit string ⍵ can be multiplied by 10*10000 quickly via
  ⍝        10000 ⌽BI ⍵
  ⍝ ∘ We include ⊤BI and ⊥BI to convert BI's to and from APL bits, so that APL ⌽ ∧ ∨ = ≠ can be used for
  ⍝   various bit manipulations on BIx; a utility BIB (Big Integer Bits) has been provided as well.
  ⍝ ∘ We support an efficient (Newton's method) integer sqrt and general root:
  ⍝        ('SQRT' BI)⍵ or ('√' BI)⍵, as well as  BIC '√⍵', where ⍵ is a big integer.
  ⍝        Or use the special case of (⍺*BI 0.5) or (⍺*BI '0.5').:
  ⍝   We provide a mechanism to find any  integral root:
  ⍝           9 ('√'BIX) 1000        ⍝ 9th root of 1000
  ⍝        2
  ⍝           bi.exp 9 bi.root 1000  ⍝ ditto
  ⍝        2
  ⍝           (9 ('√'BIX) (1000⍴⎕d))≡bi.exp 9 bi.root 1000⍴⎕d
  ⍝        1
  ⍝   To find a root besides the square root, you must use root.
  ⍝
  ⍝   There are other useful string functions to BI or BIX:
  ⍝       a shiftD n      shift Decimal (pos n multiplies by powers of 10; neg n divides by powers of 10)
  ⍝       a shiftB n      shift Binary (multiplies/divides by powers of 2)
  ⍝       ≢ b             popCount: If b is pos, returns # of 1s in binary equiv.
  ⍝                       If neg, returns -(# of 0s in twos-complement binary).
  ⍝       a ('OR'BI)b     Applies ∨ OR* to the bits of a, b lined up on the right
  ⍝       a ('AND'BI)b    ... ∧ AND* ...
  ⍝       a ('XOR'BI)b    ... ≠ XOR* ...
  ⍝                        * Uses 'OR' 'AND' 'XOR' to distinguish from logical ∨ ∧ ≠.
  ⍝         (~BI)b        Applies ~ NOT to the bits of b.
  ⍝
  ⍝ ∘ We include ?BI to allow for a random number of any number of digits and !BI to allow for
  ⍝   factorials on large integers.  (!BI does not use memoization, but the user could extend it.)
  ⍝
  ⍝ TABLE OF CONTENTS
  ⍝    Preamble for Namespace and Table of Contents
  ⍝    BigInt Namespace and Utility BI
  ⍝        BigInt and BI - Initializations
  ⍝        BI Utility - Monadic operands
  ⍝           Helpers
  ⍝        BI Utility - Dyadic operands
  ⍝           Helpers
  ⍝        BI Utility - Service Routines
  ⍝        BI Utility - Executive
  ⍝    Utilities BIB, BIC, BI∆HERE
  ⍝    Postamble for Namespace
  ⍝    Documentation   All HELP Documentation is in bigIntHelp
  ⍝

    ⍝ See HELP, BI_HELP, BIC_HELP, BIB_HELP below…
    ∇ HELP
      __HELP__
     ⍝  For HELP information, call  BI_HELP, BIC_HELP, BIB_HELP
     ⍝  Help        Fn/Op     Description
     ⍝  ¯¯¯¯¯¯¯¯    ¯¯¯¯¯¯¯   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
     ⍝  BI_HELP       BI/X/M   ∘ big integer utility                            APL EQUIV
     ⍝                BI           a *BI '2343243'   Returns internal bigInt    ⍺ × ⍵, -⍺
     ⍝                BIX          a *BIX '234342'   Returns external bigInt    ⍺ × ⍵, -⍺
     ⍝                BIM          a *BIM '2345'⊣123 Returns external bigInt    ⍵ | ⍺ × ⍵⍵  (MODULO ⍵)
     ⍝  BIC_HELP      BIC      ∘ big integer code translator ( 2999999…99999992 + 33  →   '2999999…99999992' (+BI) '33)
     ⍝  BIB_HELP      BIB      ∘ big integer binary data op   a ≠BIB b     (exclusive or of bits of a and b)
     ⍝                           where a←'3244234324343423432423432342342' ⋄ b← ⌽a
     ⍝  BI∆HERE_HELP  BI∆HERE  ∘ allows compilation on the fly of a function with :BI …. :ENDBI code.
    ∇

    ∇ BI_HELP
      __HELP__
   ⍝ bigInt:  a big integer utility
   ⍝
   ⍝ Key operators:  BI, BIX   ⍺ ×BI ⍵   or   ⍺ ×BIX ⍵
   ⍝                           BI: returns internal bigInt object; BIX: returns external bigInt string.
   ⍝                 BIM       ⍺ ×BIM ⍵⍵⊣⍵   calculates ⍺ × ⍵⍵ (MODULO ⍵))
   ⍝                           BIM: returns external bigInt string (like BIX).
   ⍝ Key prefix:     bi        actually a function visible in ⎕PATH returning bigInt namespace).
   ⍝
   ⍝ The BI operator provides basic arithmetic functions on big integers stored externally as strings
   ⍝ and internally as a sign flag and a vector of (unsigned) integers.
   ⍝ Built around dfns:nat as its numerical core, but extended to handle signed numbers,
   ⍝ reduce and scan, factorial, roll(?), and logical and bit-manipulation functions.
   ⍝ To handle multiple objects in ⍺ or ⍵, do:   ⍺  ⍺⍺ BI¨ ⍵.
   ⍝
   ⍝ Syntax: Let × represent dyadic and monadic ×, standing in for all dyadic and monadic functions.
   ⍝      ⍺ ×    BI ⍵1 ⍵2 ...           Multiplies ⍺×⍵ for BIs ⍺ and ⍵.
   ⍝        ×    BI ⍵1 ⍵2 ...           Determines the signum of BIs ⍵.
   ⍝        ×BI\    ⍵1 ⍵2 ...           Performs ×-scan of ⍵, i.e. ⍵0 (⍵0×⍵1) … (⍵0×⍵1×…×⍵N)
   ⍝      ⍺ ×BI/    ⍵1 ⍵2 ...           Performs N-wise reduction (see above)
   ⍝ where
   ⍝      ⍺,⍵ are BIs (big integer strings or APL integers), each element of which is either
   ⍝      a) a character string of this form:   [¯|-]? [\d_]+
   ⍝         i.e. an optional negative sign (¯ always used on OUTPUT), followed by 1 or more
   ⍝         digits (0-9) optionally with underscores* as convenient separators (always removed from output):
   ⍝             VALID:  1 2 3 +BI '100_000' '_2' '¯_3'
   ⍝         * Blanks are not valid separators.
   ⍝             INVALID:  5 +BI '12 24'
   ⍝             VALID:    5 +BI¨ '12' '24'    ⍝ Note BI¨ and multiple args…
   ⍝      b) an valid APL signed integers, as long as each integer i: i=⌊i.
   ⍝         BigInt can handle exponents, e.g. 2E1000, but beware of exponents out of range or
   ⍝         non-integer numbers     1.24324343242423434E5 is invalid.
   ⍝      c) a null (zero-length) string '', which is the same as zero: (,'0').
   ⍝
   ⍝      VALID:                              INVALID:
   ⍝      1 55 '-455'  '¯432423' '123_456'    1.2 5E¯5 '+455' '¯432 44'  '2J3'
   ⍝      299E5 *                              '299E5'
   ⍝      ''  '0' '-0' '¯0_00_0'              '00¯00' '00 12 34'
   ⍝      -------------
   ⍝         *APL sees  299E5 as valid 29900000
   ⍝
   ⍝ ----------------------------------------------------
   ⍝ BI/BIX/BIM OPERAND SUMMARY with BigInt FUNCTION SUMMARY
   ⍝ ----------------------------------------------------
   ⍝ ∘ For formats: ⍺ op BI ⍵, and equivalent: ⍺ fun ⍵.
   ⍝ ∘ All directly called functions return a
   ⍝   BIi (internal-format BigInteger with integer sign and data vector)
   ⍝   except where specified.
   ⍝  --------------------------------------------------------------------
   ⍝                 Directly-called function
   ⍝  BI/X op (⍺⍺)        bi.___              APL Equiv    Notes
   ⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
   ⍝ MONADIC
   ⍝    -BI ⍵             neg ⍵               -⍵
   ⍝    +BI ⍵             [none]              ⍵ f        Simply validates BIx passed
   ⍝    |BI ⍵             abs ⍵               |⍵         Absolute value
   ⍝    ×BI ⍵             sig ⍵               ×
   ⍝    ÷BI ⍵             recip ⍵             ÷⍵         Very limited use
   ⍝    <BI ⍵             dec ⍵               ⍵-1        Extension
   ⍝    >BI ⍵             inc ⍵               ⍵+1        Extension
   ⍝    !BI ⍵             fact ⍵              !⍵         Useful for small ⍵ only (due to time taken)
   ⍝    ?BI ⍵             roll ⍵              ?⍵         ⍵≥1.
   ⍝    ⊥BI ⍵             bitsIn ⍵                       Converts bits to BigInt
   ⍝    ⊤BI ⍵             bitsOut ⍵                      Converts BigInt to bits, 2s' complement, sign-bit on left.
   ⍝    ⍎BI ⍵             ⍎export ⍵                      Converts ⍵ to APL integer (or error)
   ⍝    ←BI ⍵             ⍵                              Returns ⍵ in BigInt internal form, even from BIX.
   ⍝    ⍕BI ⍵             export ⍵                       Returns an BigInt in external (string) form.
   ⍝    ('SQRT'BI) ⍵      sqrt ⍵              ⌊⍵*0.5     Also ⍵ *BI 0.5
   ⍝    ('√'BI)⍵          sqrt ⍵              ⌊⍵*0.5     ...
   ⍝  BIT-MANIPULATIONS (MONADIC)
   ⍝    ~BI ⍵             not ⍵                          Reverse each bit of ⍵, as if twos-complement integer
   ⍝    ≢BI ⍵             popCount ⍵                     Returns the number of bits of ⍵ that are different
   ⍝                                                     from the sign-bit (1s for pos nums, 0s for negatives),
   ⍝                                                     then signed (-res for negatives) (*)
   ⍝  ------------------------------
   ⍝  (*) popCount: If a pos. number has only 0 bits or a neg number has only 1 bits, result is 0.
   ⍝      Cf. Java's equivalent returns "MAXINT" (the largest integer) for negative numbers, since
   ⍝          it counts the number of 1-bits, assuming the sign-bit propagates forever.
   ⍝      The num. of bits in a number:   ≢⊤BI ⍵
   ⍝
   ⍝  DYADIC     -+x⌽ SHIFTD SHIFTB ÷ DIV2 * | |⍨ < etc ∨ ∧
   ⍝    ⍺ -BI ⍵           ⍺ sub ⍵          ⍺-⍵
   ⍝    ⍺ +BI ⍵           ⍺ add ⍵          ⍺+⍵
   ⍝    ⍺ ×BI ⍵           ⍺ mul ⍵          ⍺×⍵
   ⍝    ⍺ ('MODMUL'BI)⍵1 ⍵2
   ⍝                      ⍺ modMul ⍵1 ⍵2   ⍵2|⍺ modMul ⍵1 (MODULO ⍵2). See also (⍺ ×BIM ⍵⍵⊣⍵)
   ⍝    ⍺ ⌽BI ⍵           ⍺ shiftD ⍵       ⍺×10*⍵ Performs an efficient(**) shift by orders of 10.
   ⍝    ⍺ ('SHIFTD'BI)⍵   ↓                If ⍵>0, decimal shifts left; if ⍵<0, shifts right.
   ⍝    ⍺ ('SHIFTB'BI)⍵   ↓                If ⍵>0, binary shifts left; if ⍵<0, right.
   ⍝    ⍺ ÷BI ⍵           a div ⍵          ⍺÷⍵
   ⍝    ⍺ ('DIVREM'BI)⍵   ⍺ divRem ⍵      (⍺÷⍵)(⍵|⍺) Returns a pair of BigIntegers.
   ⍝    ⍺ *BI ⍵           ⍺ pow ⍵          ⍺*⍵
   ⍝    ⍺ |BI ⍵           ⍺ res ⍵          ⍺|⍵
   ⍝                      ⍺ rem ⍵          ⍺|⍵
   ⍝    ⍺ |⍨BI ⍵          ⍺ mod ⍵          ⍵|⍺
   ⍝                      ⍺ root ⍵         ⍺*÷⍵   ⍵ small pos. integers (default ⍺←2).
   ⍝    ⍺ ∨BI ⍵           ⍺ gcd ⍵          ⍺∨⍵    Returns a BigInteger. Not viewed as boolean.
   ⍝    ⍺ ∧BI ⍵           ⍺ lcm ⍵          ⍺∧⍵    Returns a BigInteger. Not viewed as boolean
   ⍝  BIT-MANIPULATIONS (DYADIC)
   ⍝    ⍺ ('AND'BI) ⍵     ⍺ ∧bi.bits ⍵            Apply ∧ to each bit of ⍺ and ⍵, and the sign (***).
   ⍝    ⍺ ('OR' BI) ⍵     ⍺ ∨bi.bits ⍵            Apply ∨ ...
   ⍝    ⍺ ('XOR'BI) ⍵     ⍺ ≠bi.bit ⍵             Apply ≠ ...
   ⍝                      ⍺ ⍱bi.bit ⍵             Apply ⍱, ⍲, or logical functions to each bit...
   ⍝  LOGICAL FUNCTIONS (DYADIC)
   ⍝    ⍺ <BI ⍵           ⍺ lt ⍵           ⍺<⍵    Returns 1 or 0, not a BigInteger
   ⍝    Also ≤ (le)  = (eq)
   ⍝         ≥ (ge)  > (gt)
   ⍝         ≠ (ne)
   ⍝
   ⍝  ------------
   ⍝  (*) First name is usually the APL standard name, except when that implies complex numbers:
   ⍝      e.g. we use sig(num) rather than direction for monadic ×; res and rem(ainder) for residue, dyadic |,
   ⍝      as well as mod(ulo) for |⍨, with the base on the right.
   ⍝      Calling:
   ⍝                  bi.exp   bi.neg 3             -BIX 3
   ⍝              ¯3                            ¯3
   ⍝  (**) ⌽BI, shiftD are typically 20-30% faster than the equivalent ⍺ × 10*⍵ if 10*⍵ is precomputed.
   ⍝  (***) For dyadic bit-manipulations, operations are padded on the left with sign bits, simulating
   ⍝      two-complement binary numbers (i.e. pad with 0 for pos and 1s for negative bigInts).
   ⍝      For bit-function ⍺⍺, the resulting sign will be negative, iff  sign_bit(⍺) ⍺⍺ sign_bit(⍵).
   ⍝      I.e. for ∧, both ⍺ and ⍵ are neg; for ∨, at least one is; for ≠, only one is.
   ⍝      Always returns a bigInteger (BI: in internal form; BIX: in external form).
   ⍝
   ⍝ DIRECTLY CALLED FUNCTION FAMILY.
   ⍝ For many functions directly called via bi, there are three options:
   ⍝     name        ret@BIi ←  [⍺:BIx] name ⍵:BIx    Imports args,             returns internal-format result
   ⍝     _name       ret@BIi ←  [⍺:BIi] name ⍵:BIi    Accepts internal bigInts, returns internal-format result
   ⍝     nameX       ret@BIx ←  [⍺:BIx] name ⍵:BIx    Imports args,             returns external-format bigInt
   ⍝  e.g.
   ⍝     neg, _neg, negX
   ⍝  ⍝ example
   ⍝     a←'100' ⋄ ai←bi.import a 
   ⍝       bi.neg a
   ⍝ ¯1  100 
   ⍝       bi._neg ai
   ⍝ ¯1  100 
   ⍝       bi.negX a
   ⍝ ¯100
   ⍝       bi.negX ai
   ⍝ ¯100
   ⍝ ------------------------------------------------------------------------------------
   ⍝
   ⍝ Functions Available:
   ⍝   Dyadic functions:
   ⍝      Standard Meaning: +-×*÷<≤=≥>≠⌊⌈|∨∧
   ⍝      Special Meaning:  ⌽  'SHIFTD' 'SHIFTB' 'MODMUL'
   ⍝      Returns special value: <≤=≥>≠
   ⍝
   ⍝      Dyadic <≤=≥>≠
   ⍝         Always return APL (not BI) integers 1 or 0. See Returns, below.
   ⍝      Dyadic ⌽:   ⍺⌽⍵ multiplies BI ⍵ by 10*⍺ for ⍺>0
   ⍝                      divides BI ⍵ by 10*⍺ for ⍺<0
   ⍝         To replicate a "shift by 10s", with the amount on the right, use
   ⍝             ⌽BI⍨
   ⍝             '12345' ⌽BI⍨ 3            3 ⌽BI '12345'
   ⍝         12345000                  12345000
   ⍝             '54321' ⌽BI⍨¯2            ¯2 ⌽BI '54321'
   ⍝         543                       543
   ⍝
   ⍝         Multiply/Divide by Ten In Place: var (⌽BI⍨) ← nnn
   ⍝         ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯ ¯¯ ¯¯¯ ¯¯ ¯¯¯¯¯¯ ¯¯¯ ¯¯¯¯¯¯ ¯ ¯¯¯
   ⍝         OK:                             BAD:(Invalid modified assignment)
   ⍝             a←'123321' ⋄ a(⌽BI⍨)←¯3         a←'123321' ⋄ a⌽BI⍨←¯3
   ⍝         123
   ⍝      Dyadic 'SHIFTD' (⍺, decimal shifted ⍵ places)
   ⍝         Reverse-arg synonym of ⌽:
   ⍝              ⍺ ('SHIFTD' BI) ⍵
   ⍝         multiplies ⍺ by 10*⍵, if ⍵>0, or divides by 10*⍵,
   ⍝         i.e. adds 0's on the right or truncates from the right.
   ⍝         If all digits are truncated, returns (,'0'), canonical 'zero.'
   ⍝      Dyadic 'SHIFTB' (⍺, binary shift ⍵ places)
   ⍝              ⍺ ('SHIFTB' BI) ⍵
   ⍝         multiplies ⍺ by 2*⍵, if ⍵>0, or divides by 2*⍵,
   ⍝         i.e. adds 0's on the right or truncates from the right.
   ⍝         If all digits are truncated, returns (,'0'), canonical 'zero.'
   ⍝      Dyadic 'MODMUL'
   ⍝          ⍺ ('MODMUL' BI) ⍵1 ⍵2     performs    ⍺ × ⍵1 (MODULO ⍵2)
   ⍝          ⍺ bi.modMul ⍵1 ⍵2         performs    ⍺ × ⍵1 (MODULO ⍵2)
   ⍝
   ⍝   Monadic functions:
   ⍝      Standard Meaning:  - | !
   ⍝      Returns special:   ×  (returns integer ¯1 0 1)
   ⍝      Special Meaning:   + < > ? ⊥ ⊤ !  'SQRT'   ⍎   ←
   ⍝         + (canonical):   Returns ⍵ in canonical format (no complex #s)
   ⍝         < (dec):   <BI '10'  is 9.
   ⍝         > (inc):   >BI '10'  is 11.
   ⍝         ? (roll):
   ⍝           Calculates a random # < ⍵  [like APL ?⍵, where ⍵>0]
   ⍝           The result is between 0 and (≢ +BI |BI ⍵)⍴'9', i.e. as many digits as in canonical ⍵.
   ⍝           To compute a number between 0 and ⍵, do:
   ⍝              ⍵ |BI ?BI ⍵
   ⍝         ⊤ BI integer to boolean
   ⍝           Replace BI ⍵ by b, its binary representation, a vector of booleans.
   ⍝           b consists of (1 + multiple of BRX bits) bits that represent a
   ⍝           two's-complement integer.
   ⍝           ∘ The rightmost bit (⊃⌽b) is the sign-bit (1=negative);
   ⍝           ∘ The penultimate bit b[¯2+≢b] is the most-significant non-sign bit.
   ⍝           ∘ The leftmost bit b[0] is the least-significant bit is b[0];
   ⍝           ∘ The most significant bit
   ⍝         ⊥ boolean to BI integer
   ⍝           Converts ⍵, an array* of booleans, into its equivalent BI string.
   ⍝           If (,⍵) is not of length such that (1=BRX|≢⍵), it is padded as follows:
   ⍝              ⍵' ← {((BRX×⌈BRX÷⍨≢⍵)⍴¯1↓⍵),⊃⌽⍵},⍵
   ⍝           -----------------
   ⍝           * ⍵ is treated as (,⍵), its ravel.
   ⍝         ! fact(orial)
   ⍝           ⍵ typically is a non-neg APL integer. Anything larger will take
   ⍝           too long to compute.
   ⍝    'SQRT' integer square root
   ⍝           Calculates equiv. to ⌊⍵*0.5 using a simple binary search.
   ⍝         ⍎ Returns the APL numerical equiv. of ⍵, if it can be represented (with loss of precision)
   ⍝         ← Returns the internal BI numerical vector for BI integer ⍵. For inspection only.
   ⍝         → Takes an internal BI numerical vector ⍵ and returns a BI integer ⍵'. For inspection only.
   ⍝
   ⍝   >>> See also BigInt.BIB (BigInteger Boolean Helper Function)
   ⍝
   ⍝         Note 1: ⍵ =BI ⊥BI ⊤BI ⍵      for any valid ⍵.
   ⍝            ⍵' ≡  ⊥BI ⊤BI ⍵     if ⍵' is ⍵ canonicalized, e.g. ⍵' ← +BI ⍵.
   ⍝         Note 2: ×BI/⍵ must be used for scan. This is invalid: ×/BI ⍵.
   ⍝         Note 3: Internally, a BI is a vector of signed integers (see <RX> below>). The sign is carried
   ⍝                 on the left-most non-zero number in a vector, to make conversion easy to nat-format in
   ⍝                 the dfn library, which forms the core (now modified) for monad and dyad routines.
   ⍝
   ⍝   ∘ These logical functions return a boolean integer result:
   ⍝          <≤=≥>≠
   ⍝     They are optimized for comparisons with zero. See below.
   ⍝
   ⍝ ------------------------------------------------------------------------------------
   ⍝
   ⍝ Returns:
   ⍝ ¯¯¯¯¯¯¯¯
   ⍝ ∘ For non-Boolean dyadic functions +-×*÷< ⌊⌈|∨∧:
   ⍝   All functions return a valid BI array based on the shape of ⍺×⍵.
   ⍝   Each scalar element is stored as a canonical string
   ⍝        (¯ for negation, removing spacers _ and leading 0s)
   ⍝   If the arguments ⍺, ⍵ are both scalars, the returned value is disclosed (treated as a single BI scalar).
   ⍝           '2'×BI '3'
   ⍝       6             ⍝ scalar string.
   ⍝   ∨∧ are included as non-boolean here, because they are both GCD and LCM and Boolean.
   ⍝
   ⍝ ∘ ⊤⍵ takes a BI ⍵, returning a boolean vector.
   ⍝   ⊥⍵ takes a boolean ⍵, returning a BI.
   ⍝
   ⍝ ∘ If ⍺⍺ in (⍺⍺ BI) is a Boolean (logical) operand from
   ⍝         '<≤=≥>≠', used dyadically,  returns APL booleans 1 or 0
   ⍝         '×',      used monadically (signum), returns APL integers 1, 0, or ¯1.
   ⍝   E.g.  a←?BI BRX⍴'9'             ⍝ a: BRX-digit random number
   ⍝         :While 0 (<BI) a←<BI a   ⍝ Decrement a, terminate when 0
   ⍝              b←¯3 ⌽BI a          ⍝ b ← a ÷ 1000
   ⍝              c←(1+×BI b)⊃'bad' 'ok' 'good'    ⍝ ×BI b, i.e. signum b.
   ⍝              . . .
   ⍝         :EndWhile
   ⍝
   ⍝   This makes it easy to control loops etc. without resorting to ⍎:
   ⍝       :While i >BI '1_000_000'
   ⍝           …
   ⍝       :EndWhile
   ⍝   or used with guards in dfns:
   ⍝         ⍵ ≤BI 0: do_something_with ⍵
   ⍝   Comparisons with 0 are especially fast, because only the sign of the other argument is required.
   ⍝
   ⍝ ∘ For bit management functions ⊤ and ⊥, see above.
   ⍝                                                [PMS]
    ∇

    ∇ BIC_HELP
      __HELP__
   ⍝-------------------------------------------------------------------------------------------------------
   ⍝ BIC: BI Code translation…
   ⍝-------------------------------------------------------------------------------------------------------
   ⍝
   ⍝ ⍺:options ∇ ⍵:text|fnName
   ⍝ ∘ Takes APL code with 1adic and 2adic function and
   ⍝   replaces those available in BI with BI equivalents:
   ⍝   ¯1 + 2*31 →   '¯1' (+BI) '2' (*BI)'31'
   ⍝ ∘ Supported functions (all names are in upper case):
   ⍝        monadic: - + | × ÷ < > ! ? ⊥ ⊤ ⍎ ← → √   SQRT
   ⍝        dyadic:  - + × * ÷ ⌊ ⌈ | ∨ ∧ ⌽ < ≤ = ≥ > ≠  SHIFTD DIVREM MOD
   ⍝   All functions return a BigInt string, except as defined for BIX, e.g. boolean ops < ≤ = ≥ > ≠ return 1 or 0.
   ⍝
   ⍝ ∘ Handles special BI operands (functions) SHIFTD, SQRT, and √
   ⍝   In BIC, these items are entered directly, not in (extra) quotes,
   ⍝   as if APL function names or symbols:
   ⍝      BIC '(SQRT 324932) SHIFTD 3'
   ⍝   These are converted in the appropriate BI quoted operands:
   ⍝      (('SQRT'#.BigInt.BI) '324932') ('SHIFTD'#.BigInt.BI) (,'3')
   ⍝      570000
   ⍝   Or…
   ⍝      BIC ' √√100000'         ⍝ Equivalent to  BIC 'SQRT SQRT 100000'
   ⍝   …into:
   ⍝      ('√'#.BigInt.BI)('√'#.BigInt.BI)'100000'
   ⍝      17
   ⍝ ∘ Leaves small APL unquoted numbers as is, allowing mixing with non-BI operands:
   ⍝       2 + 3 × ≢⍳123      →    2 +BI 3 ×BI ≢⍳123
   ⍝ ∘ Large APL numbers are quoted (and quoted numbers are left as is).
   ⍝
   ⍝ Features:
   ⍝   ∘ Converts common 1adic and 2adic functions to BI calls,
   ⍝     replacing e.g. +  with (+BI)
   ⍝                    -\ with (-BI)\
   ⍝   ∘ Handles simple reductions and scans:
   ⍝       +/ 111 222 333     -\ 111 222 333    3 ×/ 1111 2222 3333 4444
   ⍝   ∘ placing quotes around APL integers:
   ⍝       BIC '⊢ 23424423424323423423 | 2 + 23424423424323423423 * 5'
   ⍝     becomes executable:
   ⍝       ⊢ '23424423424323423423' (|BI) (,'2') (+BI) '23424423424323423423' (*BI) (,'5')
   ⍝     which, when executed (⍎…) has value:
   ⍝       2
   ⍝   ∘ leaving non-integers, complex #s, etc for APL to sort out.
   ⍝     Some are valid (e.g. 123E0 → 123; 12.3E1 → 123; 12.3E1J0 → 123)
   ⍝     If not, an error occurs!
   ⍝   ∘ Easily allows creating dfns, with ⍺⍺ ⍵⍵ assumed to be BI operands:
   ⍝         ⍎'opX←'BIC'{⍺  ⍺⍺ ⍵ SHIFTD 3}
   ⍝     This creates dfn op in the caller's namespace:
   ⍝         opX←{⍺ (⍺⍺BI) ⍵ ('SHIFTD'BI) '3'}
   ⍝     So that:
   ⍝         2 +opXX 5
   ⍝     via steps:
   ⍝         2 +op 5 →  2 (+BI) 5 ('SHIFTD'BI) 3 → 2 + 5000 →  5002
   ⍝     … equals:
   ⍝         5002
   ⍝   __________
   ⍝   EXTENSIONS
   ⍝   ¯¯¯¯¯¯¯¯¯¯
   ⍝   ∘ Extension 1: CODE or INTEGER ESCAPE feature:
   ⍝     Code within (: … :) inside otherwise BI-active code
   ⍝     if passed through unchanged as APL code.
   ⍝        ⍎⎕←BIC  '1 + (: (⍳10) :) * 5'
   ⍝     (,'1') (+BI) (⍳10) (*BI) (,'5')
   ⍝     1 2 33 244 1025 3126 7777 16808 32769 59050
   ⍝        :For i :in ⍳(:10:)
   ⍝         …
   ⍝        :EndFor
   ⍝   ∘ Extension 2 [for options 2 ¯2] :BI and :ENDBI Directives
   ⍝     For APL functions (option 2=|⍺), no code is automatically
   ⍝     assumed to consist of BI calls or integers. Code to be converted
   ⍝     must appear between ⍝:BI and ⍝:ENDBI statements*.
   ⍝         * The ⍝ symbol is optional. /⍝?\h*:BI.*$/ starts a BI code
   ⍝           sequence (and is otherwise ignored) and /⍝?\h*:ENDBI.*$/ ends it (ditto).
   ⍝
   ⍝
   ⍝ options:
   ⍝    ⍺ a string:   Treat as if  (⍺, 1 BIC ⍵). See dfns example above.
   ⍝    1 [default]:  compile ⍵, ≥1 char vectors with BI-ready code, returning compiled values.
   ⍝   ¯1          :  evaluate ⍵ into BI-ready code c, executing c and returning its value
   ⍝                  Note: ⍵ is executed in the BigInt namespace.
   ⍝    2          :  evaluate ⍵: the name of an APL function with BI-ready code between
   ⍝                  ⍝ :BI and ⍝ :ENDBI statements (case is ignored).
   ⍝                  Regular integer constants within :BI sequences will be treated as
   ⍝                  BI's and quoted. To force to APL, use (: … :)
   ⍝   ¯2          : like 2, except ⍵ is a char vec or vectors as if output of ⎕NR name.
   ⍝ ∇…
   ⍝ :FOR i :in ⍳count
   ⍝   item←items[i]
   ⍝   ⍝:BI
   ⍝      item←item*3
   ⍝      cum[i]+←item    ⍝ cum[i](+BI)←item
   ⍝   ⍝:EndBI
   ⍝ :EndFor
   ⍝
   ⍝ Returns: processed text. (Does not affect any function passed by name)
   ⍝    If ⍺=0 and text is on a single line, it is returned disclosed.
   ⍝    else it is returned as a vector of vectors.
   ⍝
    ∇

    ∇ BIB_HELP
      __HELP__
    ⍝-------------------------------------------------------------------------------------------------------
   ⍝ BIB: BI Binary helper function (treats BIs as APL bit vectors, with high-order and sign bit on RHS)
   ⍝-------------------------------------------------------------------------------------------------------
   ⍝ Given ⍺, ⍵ - bigInteger external or internal format numbers
   ⍝ And ⍺⍺ an APL dyadic scalar function that operates on bits:
   ⍝     ⍺ ⍺⍺ BIB ⍵    is the same as     bi.export ⍺ ⍺⍺ bi.bits ⍵
   ⍝ Strategy:
   ⍝    Perform bitwise  and sign comparisons of bigInts ⍺, ⍵ according to ⍺⍺
   ⍝       1. View ⍺, ⍵ as bits
   ⍝       2. Pad the shorter of ⍺, ⍵ to the length of the longer:
   ⍝          Pad by replicating the sign-bit (1=neg, 0=otherwise)
   ⍝          of the shorter operand's bit view on the left.
   ⍝          If ⍵ is
   ⍝             ¯1 → ¯1 (1) → ¯1 (20⍴1)
   ⍝          and ⍺ has 40 bits, then pad ⍵ with 1 (neg sign-bit):
   ⍝             ¯1 ((20⍴1),20⍴1)
   ⍝       3. Perform ⍺⍺ pairwise on each element of ⍺, ⍵: ⍺ ⍺⍺ ⍵
   ⍝       4. Perform ⍺⍺ on the signs, this way:
   ⍝             If   (sign_⍵=¯1)⍺⍺(sign_⍺=¯1)
   ⍝             then sign_result ← ¯1 else 1 (or 0)
   ⍝          That way, relationals like < or > will work properly,
   ⍝          (or user relationals), within the domain of 0 1,
   ⍝          per the definition of twos-complement numbers.
   ⍝          Example:
   ⍝             Let sign_⍺←¯1, but sign_⍵←1:
   ⍝             so  (sign_⍵=¯1)<(sign_⍺=¯1)
   ⍝             so           0 < 1
   ⍝             so the resulting sign is ¯1.
   ⍝       5. View the result as a signed bigInt.
   ⍝ While ⍺⍺ can be any APL function, useful ones include:
   ⍝    ∧ (and), ∨ (or), ≠ (xor); ~ (not)
   ⍝
    ∇

    ∇ BI∆HERE_HELP
      __HELP__
   ⍝-------------------------------------------------------------------------------------------------------
   ⍝ BI∆HERE: BI dynamic (on the fly) compiler…
   ⍝-------------------------------------------------------------------------------------------------------
   ⍝ I. To dynamically (on the fly) take a user function myFn, and have it "compiled"
   ⍝ with BIC "on the fly, place the following code early in the function myFn, outside
   ⍝ of any control structures (see below for workarounds):
   ⍝   A. If the user function myFn returns no result
   ⍝      ∇ myFn; local1; local2; ...
   ⍝        ⍎BI∆HERE
   ⍝        ⍝ Rest of lines will be interpreted as bigInt math per BIC rules.
   ⍝        ...
   ⍝      ∇
   ⍝   B. If the user function myFn returns a result, e.g. myResult
   ⍝      ∇ myResult←myFn; local1; local2; ...
   ⍝        ⍎BI∆HERE
   ⍝        ⍝ Rest of lines will be interpreted as bigInt math per BIC rules.
   ⍝        ⍝ Be sure that at least one sets myResult, as usual, before returning
   ⍝        ...
   ⍝        myResult←!50
   ⍝        ...
   ⍝      ∇
   ⍝ Notes: ----------------------------
   ⍝ ∘ In the cloned / compiled version of the caller function,
   ⍝   execution begins on the line right after the BI∆HERE.
   ⍝ ∘ If a control structure is required to determine whether to execute the function
   ⍝   as a bigInt function or not, it must be wholly contained on
   ⍝   the line containing the BI∆HERE, since BI∆HERE, if executed, starts at the next line:
   ⍝      OK:
   ⍝              :IF true ⋄ BI∆HERE ⋄ :ELSE ⋄ set a flag or something ⋄ :ENDIF
   ⍝       -->    Execution continues here whether prior IF is true or not!
   ⍝      BAD:
   ⍝              :IF true ⋄ BI∆HERE
   ⍝       -->    :ELSE ⋄ do something else      ⍝ Clone execution starts here! Ugh!
   ⍝              :ENDIF
   ⍝ ∘ If more than one BI∆HERE appears in a fn, only one is executed, since the caller
   ⍝   is terminated immediately (within the ⍎BI∆HERE) after the clone is complete.
   ⍝ ∘ For syntax, see BIC
   ⍝ ∘ The caller must not be locked, since ⎕NR is used to scan the function.
   ⍝ ∘ The clone is deleted as it begins execution. Name format: <myFn>__BigInteger_TEMP,
   ⍝   where myFn is the name of the user function..
    ∇


  ⍝ Utility function for HELP information!
    ∇ __HELP__;help
      ⎕ED'help'⊣help←'^\h*⍝(?|\h(.*)|())'⎕S'\1'⎕NR((1+⎕IO)⊃⎕SI)
    ∇

    1
:endnamespace
