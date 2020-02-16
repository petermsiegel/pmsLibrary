:namespace BigIntHelp
  ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯  D O C U M E N T A T I O N  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
  ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
  ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
  ⍝ ∘ NOTE: See bigIntHelp for details...
  ⍝
  ⍝ ∘ BigInt is a signed Big-Integer utility built around the unsigned big integer utility, dfns:nats.
  ⍝   <nats> seems to have the fastest general-purpose multiply and divide in dfns.
  ⍝ ∘ BIint: We've created an efficient BigInt Internal Data "structure" BIint (BI Internal) of this form:
  ⍝        BIint ← sign  data
  ⍝        where sign@I∊¯1 0 1, data@UV<10E6
  ⍝              The sign is an integer;
  ⍝              The data is an unsigned APL integer vector, whose elements are <RX (10E6).
  ⍝        In functions manipulating signed numbers, zero is ALWAYS (sign:0 data:(,0)) making tests for 0 FAST.
  ⍝        in unsigned functions, zero passed in and out is (,0).
  ⍝        NOTE: Nats functions are modified to always return valid sign and <data>.
  ⍝ ∘ BIext: The external format of BigIntegers, BIext, contains:
  ⍝        on input:   "[¯-]?\d[\d_]*"  (a sign ¯ or - followed by at least 1 digit, and ≥0 underscores as spacers)
  ⍝        on output:  "¯?[\d+]"
  ⍝        Note: BigInt fns returning BIext only return output-format strings, never (say) '-25' or '25_123'.
  ⍝ ∘ BIc: On occasion we'll mention BIc, a "character" string format string used as INPUT, as opposed to
  ⍝        BIint (internal-format sign/data structure) or Int (APL Integer).
  ⍝
  ⍝ ∘ Operators BII, BI:   For  [⍺] op BII* ⍵
  ⍝       Performs   ⍺ op ⍵ or op ⍵, where ⍺, ⍵ are bigIntegers (in external or internal form.)
  ⍝       BII  (returns BIint, internal form bigInt) and BI (returns BIext, external form).
  ⍝   Operator BIM:        For [⍺] op BIM ⍵⍵ ⊣ modulo
  ⍝       Performs  ⍺ op ⍵⍵ (MODULO ⍵)    or   op ⍵⍵ (MODULO ⍵)
  ⍝       Returns BIint (like BI)
  ⍝       Currently, only ×BIM is optimized for modular arithmetic (modMul)
  ⍝
  ⍝   We've added a range of monadic functions and extended the dyadic functions as well, all signed.
  ⍝   The key easy-use utilities are BII and BI, used (with '#.BigInt' in ⎕PATH) in this form:
  ⍝       dyadic:    r:BIint← ⍺ +BII ⍵       r:BIext← ⍺ +BI ⍵     with some exceptions (see below).
  ⍝       monadic:   r:BIint←   ×BII ⍵       r:BIext←   ×BI ⍵     ditto.
  ⍝   For character string operands of BI/BII, e.g. 'SQRT' or 'MOD',
  ⍝   parentheses are usually required (case is ignored):
  ⍝       dyadic: ⍺ ('MOD'BII)  ⍵      ←→   ⍺ mod ⍵     ⍝ Case matters for explicit function syntax!
  ⍝       monadic:  ('SQRT'BII) ⍵      ←⍀     sqrt ⍵
  ⍝   And ALL allow commutation directly, e.g.|⍨ (a synonym for modulo):
  ⍝               ⍺ |⍨BII ⍵     ←→  ⍺ |BII⍨ ⍵    ←→  ⍵ |BII ⍺
  ⍝   BII works fine with APL standard commutation, reduction, and scan as well:
  ⍝               +BII/⍵1 ⍵2 ⍵3...
  ⍝               ⍺ ÷BII⍨ ⍵    ←→ ⍵ ÷BII ⍺
  ⍝               +BII\⍵1 ⍵2 ⍵2...
  ⍝
  ⍝   BII doesn't return external BigInt strings, but ONLY internal format objects, for efficiency.
  ⍝        (To convert to external, use ⍕BII or simply use BI for the last computation in a series.)
  ⍝   BI returns BigInt strings wherever BII would return a BigInt-internal object.
  ⍝         c +BI x ×BII b +BII x ×BII a    ←→  ⍕BII c +BII x ×BII b +BII x ×BII a    ⍝ (a×x*2)+(b×x)+c
  ⍝   Both BI and BII return booleans with logical functions (< ≤ = ≥ > ≠). See below.
  ⍝
  ⍝   Given BI, why use BII at all?
  ⍝   ¯¯¯¯¯ ¯¯¯¯ ¯¯¯ ¯¯¯ ¯¯ ¯¯ ¯¯¯¯
  ⍝   ∘ It is a bit more efficient for algorithms built around BigIntegers, esp. those with a lot of math.
  ⍝     And... why not mix and match?
  ⍝   For "desk calculator" uses, BI is always a perfect choice.
  ⍝
  ⍝   Left operands (⍺⍺) to BI/BII include:
  ⍝       dyadic:  + - x ÷ *     | ⌈ ⌊ ≠ < ≤ = ≥ > ≠ ⌽  ∨ ∧
  ⍝       monadic: + - x ÷   ! ? | ⌈ ⌊   <       >      ⊥ ⊤ ⍎ ⍕ ←
  ⍝   (All return integer results).
  ⍝
  ⍝   Those with special meaning include:
  ⍝       dyadic:  ⌽ (shiftD), ∨ (gcd), ∧ (lcm)
  ⍝       monadic: ? (roll on ⍵>0),  ⍎ (convert to APL integer), ⍕ (convert to BI external string)
  ⍝                ← (return BII-internal format)
  ⍝                ⊥ (bits to bigint), ⊤ (bigInt to bits),
  ⍝                ≢ (sign×count of bits different from sign-bit in twos-complement)
  ⍝ ∘ Arguments to most functions are BigIntegers of any BIext form:
  ⍝       a single BigInteger string in quotes    '-2343_243422'
  ⍝       a single APL signed integer (whether stored as an integer or float)   ¯2343243422
  ⍝       a BI Internal-format vector, consisting of a scalar sign followed by a data vector of unsigned numbers;
  ⍝          See the internal format (above).     ¯1 (2343 243422)
  ⍝ ∘ Instead of using operand with BII (+BII), a set of BigInteger functions can be called directly:
  ⍝       dyadic:   ⍺ add ⍵ ⋄  ⍺ gcd ⍵ ⋄⋄⋄
  ⍝       monadic:  sig  ⍵   ⋄  roll '1',99⍴'0'
  ⍝   These all return a BIint (BigInteger internal format), with a few exceptions (exp/ort returns a BIext).
  ⍝   Many local functions have abbreviated synonyms. Local functions include:
  ⍝       add sub mul div  divrem pow res(idue)/rem(ainder) mod (res⍨)
  ⍝       shiftD times10Exp div10Exp shiftB times2Exp div2Exp
  ⍝       neg sig(num)  abs roll
  ⍝   Logical functions < ≤ = ≥ > ≠ return a single boolean, to make them easy to use
  ⍝   in program control. (gcd ∨ and lcm ∧ always return BI Internals, since their logical use is a subset).
  ⍝
  ⍝ ∘ Bit strings are passed to the user as two's-complement boolean vectors,
  ⍝   with the lowest-order bit last (so ⍵[¯1+≢⍵] is the LOB),
  ⍝   and the sign-bit first, i.e. as the leftmost- bit (i.e. ⊃⍵ is 1, if the # if negative).
  ⍝
  ⍝ Notable enhancements compared to dfns:nats:
  ⍝ ∘ Input BII strings may have ¯ or - prefixed for negative numbers and may include _ as spacers,
  ⍝   which are ignored:   e.g.  '-553_555_555'    '¯99999_12345_12345'    '00000_00000_00000'
  ⍝ ∘ ⌽BII is used to shift (not rotate) binary digits left and right,
  ⍝   i.e. to multiply and divide by 2**⍵ very quickly and efficiently.
  ⍝      ∘ Example: A million-digit string ⍵ can be multiplied by 10*10000 quickly via
  ⍝        10000 ⌽BII ⍵
  ⍝ ∘ We include ⊤BII and ⊥BII to convert BII's to and from APL bits, so that APL ⌽ ∧ ∨ = ≠ can be used for
  ⍝   various bit manipulations on BIext; a utility BIB (Big Integer Bits) has been provided as well.
  ⍝ ∘ We support an efficient (Newton's method) integer sqrt and general root:
  ⍝        ('SQRT' BII)⍵ or ('√' BII)⍵, as well as  BIC '√⍵', where ⍵ is a big integer.
  ⍝        Or use the special case of (⍺*BII 0.5) or (⍺*BII '0.5').:
  ⍝   We provide a mechanism to find any  integral root:
  ⍝           9 ('√'BI) 1000        ⍝ 9th root of 1000
  ⍝        2
  ⍝           bi.exp 9 bi.root 1000  ⍝ ditto
  ⍝        2
  ⍝           (9 ('√'BI) (1000⍴⎕d))≡bi.exp 9 bi.root 1000⍴⎕d
  ⍝        1
  ⍝   To find a root besides the square root, you must use root.
  ⍝
  ⍝   There are other useful string functions to BII or BI:
  ⍝       a shiftD n      shift Decimal (pos n multiplies by powers of 10; neg n divides by powers of 10)
  ⍝       a shiftB n      shift Binary (multiplies/divides by powers of 2)
  ⍝       ≢ b             popCount: If b is pos, returns # of 1s in binary equiv.
  ⍝                       If neg, returns -(# of 0s in twos-complement binary).
  ⍝       a ('OR'BII)b     Applies ∨ OR* to the bits of a, b lined up on the right
  ⍝       a ('AND'BII)b    ... ∧ AND* ...
  ⍝       a ('XOR'BII)b    ... ≠ XOR* ...
  ⍝                        * Uses 'OR' 'AND' 'XOR' to distinguish from logical ∨ ∧ ≠.
  ⍝         (~BII)b        Applies ~ NOT to the bits of b.
  ⍝
  ⍝ ∘ We include ?BII to allow for a random number of any number of digits and !BII to allow for
  ⍝   factorials on large integers.  (!BII does not use memoization, but the user could extend it.)
  ⍝
  ⍝ TABLE OF CONTENTS
  ⍝    Preamble for Namespace and Table of Contents
  ⍝    BigInt Namespace and Utility BII
  ⍝        BigInt and BII - Initializations
  ⍝        BII Utility - Monadic operands
  ⍝           Helpers
  ⍝        BII Utility - Dyadic operands
  ⍝           Helpers
  ⍝        BII Utility - Service Routines
  ⍝        BII Utility - Executive
  ⍝    Utilities BIB, BIC, BII∆HERE
  ⍝    Postamble for Namespace
  ⍝    Documentation   All HELP Documentation is in bigIntHelp
  ⍝

    ⍝ See HELP, BI_HELP, BIC_HELP, BIB_HELP below…
    ∇ HELP
      __HELP__
     ⍝  For HELP information, call  BI_HELP, BIC_HELP, BIB_HELP
     ⍝  Help        Fn/Op     Description
     ⍝  ¯¯¯¯¯¯¯¯    ¯¯¯¯¯¯¯   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
     ⍝  BI_HELP       BI/BII/M   ∘ big integer utility                            APL EQUIV
     ⍝                BII         a *BII '2343243'  Returns internal bigInt    ⍺ × ⍵, -⍺
     ⍝                BI          a *BI '234342'    Returns external bigInt    ⍺ × ⍵, -⍺
     ⍝                BIM         a *BIM '2345'⊣123 Returns external bigInt    ⍵ | ⍺ × ⍵⍵  (MODULO ⍵)
     ⍝  BIC_HELP      BIC      ∘ big integer code translator ( 2999999…99999992 + 33  →   '2999999…99999992' (+BII) '33)
     ⍝  BIB_HELP      BIB      ∘ big integer binary data op   a ≠BIB b     (exclusive or of bits of a and b)
     ⍝                           where a←'3244234324343423432423432342342' ⋄ b← ⌽a
     ⍝  BII∆HERE_HELP  BII∆HERE  ∘ allows compilation on the fly of a function with :BII …. :ENDBI code.
    ∇

    ∇ BI_HELP
      __HELP__
   ⍝ bigInt:  a big integer utility
   ⍝
   ⍝ Key operators:  BII, BI   ⍺ ×BII ⍵   or   ⍺ ×BI ⍵
   ⍝                           BII: returns internal bigInt object; 
   ⍝                           BI:  returns external bigInt string.
   ⍝                 BIM       ⍺ ×BIM ⍵⍵⊣⍵   calculates ⍺ × ⍵⍵ (MODULO ⍵))
   ⍝                           BIM: returns external bigInt string (like BI).
   ⍝ Key prefix:     bi        actually a function visible in ⎕PATH returning bigInt namespace).
   ⍝
   ⍝ The BII operator provides basic arithmetic functions on big integers stored externally as strings
   ⍝ and internally as a sign flag and a vector of (unsigned) integers.
   ⍝ Built around dfns:nat as its numerical core, but extended to handle signed numbers,
   ⍝ reduce and scan, factorial, roll(?), and logical and bit-manipulation functions.
   ⍝ To handle multiple objects in ⍺ or ⍵, do:   ⍺  ⍺⍺ BII¨ ⍵.
   ⍝
   ⍝ Syntax: Let × represent dyadic and monadic ×, standing in for all dyadic and monadic functions.
   ⍝      ⍺ ×    BII ⍵1 ⍵2 ...           Multiplies ⍺×⍵ for BIs ⍺ and ⍵.
   ⍝        ×    BII ⍵1 ⍵2 ...           Determines the signum of BIs ⍵.
   ⍝        ×BII\    ⍵1 ⍵2 ...           Performs ×-scan of ⍵, i.e. ⍵0 (⍵0×⍵1) … (⍵0×⍵1×…×⍵N)
   ⍝      ⍺ ×BII/    ⍵1 ⍵2 ...           Performs N-wise reduction (see above)
   ⍝ where
   ⍝      ⍺,⍵ are BIs (big integer strings or APL integers), each element of which is either
   ⍝      a) a character string of this form:   [¯|-]? [\d_]+
   ⍝         i.e. an optional negative sign (¯ always used on OUTPUT), followed by 1 or more
   ⍝         digits (0-9) optionally with underscores* as convenient separators (always removed from output):
   ⍝             VALID:  1 2 3 +BII '100_000' '_2' '¯_3'
   ⍝         * Blanks are not valid separators.
   ⍝             INVALID:  5 +BII '12 24'
   ⍝             VALID:    5 +BII¨ '12' '24'    ⍝ Note BII¨ and multiple args…
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
   ⍝ BII/BI/BIM OPERAND SUMMARY with BigInt FUNCTION SUMMARY
   ⍝ ----------------------------------------------------
   ⍝ ∘ For formats: ⍺ op BII ⍵, and equivalent: ⍺ fun ⍵.
   ⍝ ∘ All directly called functions return a
   ⍝   BIint (internal-format BigInteger with integer sign and data vector)
   ⍝   except where specified.
   ⍝  --------------------------------------------------------------------
   ⍝                 Directly-called function
   ⍝  BI/BII op (⍺⍺)        bi.___              APL Equiv    Notes
   ⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
   ⍝ MONADIC
   ⍝    -BII ⍵             neg ⍵               -⍵
   ⍝    +BII ⍵             [none]              ⍵ f        Simply validates BIext passed
   ⍝    |BII ⍵             abs ⍵               |⍵         Absolute value
   ⍝    ×BII ⍵             sig ⍵               ×
   ⍝    ÷BII ⍵             recip ⍵             ÷⍵         Very limited use
   ⍝    <BII ⍵             dec ⍵               ⍵-1        Extension
   ⍝    >BII ⍵             inc ⍵               ⍵+1        Extension
   ⍝    !BII ⍵             fact ⍵              !⍵         Useful for small ⍵ only (due to time taken)
   ⍝    ?BII ⍵             roll ⍵              ?⍵         ⍵≥1.
   ⍝    ⊥BII ⍵             bitsIn ⍵                       Converts bits to BigInt
   ⍝    ⊤BII ⍵             bitsOut ⍵                      Converts BigInt to bits, 2s' complement, sign-bit on left.
   ⍝    ⍎BII ⍵             ⍎export ⍵                      Converts ⍵ to APL integer (or error)
   ⍝    ←BII ⍵             ⍵                              Returns ⍵ in BigInt internal form, even from BI.
   ⍝    ⍕BII ⍵             export ⍵                       Returns an BigInt in external (string) form.
   ⍝    ('SQRT'BII) ⍵      sqrt ⍵              ⌊⍵*0.5     Also ⍵ *BII 0.5
   ⍝    ('√'BII)⍵          sqrt ⍵              ⌊⍵*0.5     ...
   ⍝  BIT-MANIPULATIONS (MONADIC)
   ⍝    ~BII ⍵             not ⍵                          Reverse each bit of ⍵, as if twos-complement integer
   ⍝    ≢BII ⍵             popCount ⍵                     Returns the number of bits of ⍵ that are different
   ⍝                                                     from the sign-bit (1s for pos nums, 0s for negatives),
   ⍝                                                     then signed (-res for negatives) (*)
   ⍝  ------------------------------
   ⍝  (*) popCount: If a pos. number has only 0 bits or a neg number has only 1 bits, result is 0.
   ⍝      Cf. Java's equivalent returns "MAXINT" (the largest integer) for negative numbers, since
   ⍝          it counts the number of 1-bits, assuming the sign-bit propagates forever.
   ⍝      The num. of bits in a number:   ≢⊤BII ⍵
   ⍝
   ⍝  DYADIC     -+x⌽ SHIFTD SHIFTB ÷ DIV2 * | |⍨ < etc ∨ ∧
   ⍝    ⍺ -BII ⍵           ⍺ sub ⍵          ⍺-⍵
   ⍝    ⍺ +BII ⍵           ⍺ add ⍵          ⍺+⍵
   ⍝    ⍺ ×BII ⍵           ⍺ mul ⍵          ⍺×⍵
   ⍝    ⍺ ('MODMUL'BII)⍵1 ⍵2
   ⍝                      ⍺ modMul ⍵1 ⍵2   ⍵2|⍺ modMul ⍵1 (MODULO ⍵2). See also (⍺ ×BIM ⍵⍵⊣⍵)
   ⍝    ⍺ ⌽BII ⍵           ⍺ shiftD ⍵       ⍺×10*⍵ Performs an efficient(**) shift by orders of 10.
   ⍝    ⍺ ('SHIFTD'BII)⍵   ↓                If ⍵>0, decimal shifts left; if ⍵<0, shifts right.
   ⍝    ⍺ ('SHIFTB'BII)⍵   ↓                If ⍵>0, binary shifts left; if ⍵<0, right.
   ⍝    ⍺ ÷BII ⍵           a div ⍵          ⍺÷⍵
   ⍝    ⍺ ('DIVREM'BII)⍵   ⍺ divRem ⍵      (⍺÷⍵)(⍵|⍺) Returns a pair of BigIntegers.
   ⍝    ⍺ *BII ⍵           ⍺ pow ⍵          ⍺*⍵
   ⍝    ⍺ |BII ⍵           ⍺ res ⍵          ⍺|⍵
   ⍝                      ⍺ rem ⍵          ⍺|⍵
   ⍝    ⍺ |⍨BII ⍵          ⍺ mod ⍵          ⍵|⍺
   ⍝                      ⍺ root ⍵         ⍺*÷⍵   ⍵ small pos. integers (default ⍺←2).
   ⍝    ⍺ ∨BII ⍵           ⍺ gcd ⍵          ⍺∨⍵    Returns a BigInteger. Not viewed as boolean.
   ⍝    ⍺ ∧BII ⍵           ⍺ lcm ⍵          ⍺∧⍵    Returns a BigInteger. Not viewed as boolean
   ⍝  BIT-MANIPULATIONS (DYADIC)
   ⍝    ⍺ ('AND'BII) ⍵     ⍺ ∧bi.bits ⍵            Apply ∧ to each bit of ⍺ and ⍵, and the sign (***).
   ⍝    ⍺ ('OR' BII) ⍵     ⍺ ∨bi.bits ⍵            Apply ∨ ...
   ⍝    ⍺ ('XOR'BII) ⍵     ⍺ ≠bi.bit ⍵             Apply ≠ ...
   ⍝                      ⍺ ⍱bi.bit ⍵             Apply ⍱, ⍲, or logical functions to each bit...
   ⍝  LOGICAL FUNCTIONS (DYADIC)
   ⍝    ⍺ <BII ⍵           ⍺ lt ⍵           ⍺<⍵    Returns 1 or 0, not a BigInteger
   ⍝    Also ≤ (le)  = (eq)
   ⍝         ≥ (ge)  > (gt)
   ⍝         ≠ (ne)
   ⍝
   ⍝  ------------
   ⍝  (*) First name is usually the APL standard name, except when that implies complex numbers:
   ⍝      e.g. we use sig(num) rather than direction for monadic ×; res and rem(ainder) for residue, dyadic |,
   ⍝      as well as mod(ulo) for |⍨, with the base on the right.
   ⍝      Calling:
   ⍝                  bi.exp   bi.neg 3             -BI 3
   ⍝              ¯3                            ¯3
   ⍝  (**) ⌽BII, shiftD are typically 20-30% faster than the equivalent ⍺ × 10*⍵ if 10*⍵ is precomputed.
   ⍝  (***) For dyadic bit-manipulations, operations are padded on the left with sign bits, simulating
   ⍝      two-complement binary numbers (i.e. pad with 0 for pos and 1s for negative bigInts).
   ⍝      For bit-function ⍺⍺, the resulting sign will be negative, iff  sign_bit(⍺) ⍺⍺ sign_bit(⍵).
   ⍝      I.e. for ∧, both ⍺ and ⍵ are neg; for ∨, at least one is; for ≠, only one is.
   ⍝      Always returns a bigInteger (BII: in internal form; BI: in external form).
   ⍝
   ⍝ DIRECTLY CALLED FUNCTION FAMILY.
   ⍝ For many functions directly called via bi, there are three options:
   ⍝     name        ret@BIint ←  [⍺:BIext] name ⍵:BIext    Imports args,             returns internal-format result
   ⍝     _name       ret@BIint ←  [⍺:BIint] name ⍵:BIint    Accepts internal bigInts, returns internal-format result
   ⍝     nameX       ret@BIext ←  [⍺:BIext] name ⍵:BIext    Imports args,             returns external-format bigInt
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
   ⍝         Always return APL (not BII) integers 1 or 0. See Returns, below.
   ⍝      Dyadic ⌽:   ⍺⌽⍵ multiplies BII ⍵ by 10*⍺ for ⍺>0
   ⍝                      divides BII ⍵ by 10*⍺ for ⍺<0
   ⍝         To replicate a "shift by 10s", with the amount on the right, use
   ⍝             ⌽BII⍨
   ⍝             '12345' ⌽BII⍨ 3            3 ⌽BII '12345'
   ⍝         12345000                  12345000
   ⍝             '54321' ⌽BII⍨¯2            ¯2 ⌽BII '54321'
   ⍝         543                       543
   ⍝
   ⍝         Multiply/Divide by Ten In Place: var (⌽BII⍨) ← nnn
   ⍝         ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯ ¯¯ ¯¯¯ ¯¯ ¯¯¯¯¯¯ ¯¯¯ ¯¯¯¯¯¯ ¯ ¯¯¯
   ⍝         OK:                             BAD:(Invalid modified assignment)
   ⍝             a←'123321' ⋄ a(⌽BII⍨)←¯3         a←'123321' ⋄ a⌽BII⍨←¯3
   ⍝         123
   ⍝      Dyadic 'SHIFTD' (⍺, decimal shifted ⍵ places)
   ⍝         Reverse-arg synonym of ⌽:
   ⍝              ⍺ ('SHIFTD' BII) ⍵
   ⍝         multiplies ⍺ by 10*⍵, if ⍵>0, or divides by 10*⍵,
   ⍝         i.e. adds 0's on the right or truncates from the right.
   ⍝         If all digits are truncated, returns (,'0'), canonical 'zero.'
   ⍝      Dyadic 'SHIFTB' (⍺, binary shift ⍵ places)
   ⍝              ⍺ ('SHIFTB' BII) ⍵
   ⍝         multiplies ⍺ by 2*⍵, if ⍵>0, or divides by 2*⍵,
   ⍝         i.e. adds 0's on the right or truncates from the right.
   ⍝         If all digits are truncated, returns (,'0'), canonical 'zero.'
   ⍝      Dyadic 'MODMUL'
   ⍝          ⍺ ('MODMUL' BII) ⍵1 ⍵2     performs    ⍺ × ⍵1 (MODULO ⍵2)
   ⍝          ⍺ bi.modMul ⍵1 ⍵2         performs    ⍺ × ⍵1 (MODULO ⍵2)
   ⍝
   ⍝   Monadic functions:
   ⍝      Standard Meaning:  - | !
   ⍝      Returns special:   ×  (returns integer ¯1 0 1)
   ⍝      Special Meaning:   + < > ? ⊥ ⊤ !  'SQRT'   ⍎   ←
   ⍝         + (canonical):   Returns ⍵ in canonical format (no complex #s)
   ⍝         < (dec):   <BII '10'  is 9.
   ⍝         > (inc):   >BII '10'  is 11.
   ⍝         ? (roll):
   ⍝           Calculates a random # < ⍵  [like APL ?⍵, where ⍵>0]
   ⍝           The result is between 0 and (≢ +BII |BII ⍵)⍴'9', i.e. as many digits as in canonical ⍵.
   ⍝           To compute a number between 0 and ⍵, do:
   ⍝              ⍵ |BII ?BII ⍵
   ⍝         ⊤ BII integer to boolean
   ⍝           Replace BII ⍵ by b, its binary representation, a vector of booleans.
   ⍝           b consists of (1 + multiple of BRX bits) bits that represent a
   ⍝           two's-complement integer.
   ⍝           ∘ The rightmost bit (⊃⌽b) is the sign-bit (1=negative);
   ⍝           ∘ The penultimate bit b[¯2+≢b] is the most-significant non-sign bit.
   ⍝           ∘ The leftmost bit b[0] is the least-significant bit is b[0];
   ⍝           ∘ The most significant bit
   ⍝         ⊥ boolean to BII integer
   ⍝           Converts ⍵, an array* of booleans, into its equivalent BII string.
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
   ⍝         ← Returns the internal BII numerical vector for BII integer ⍵. For inspection only.
   ⍝         → Takes an internal BII numerical vector ⍵ and returns a BII integer ⍵'. For inspection only.
   ⍝
   ⍝   >>> See also BigInt.BIB (BigInteger Boolean Helper Function)
   ⍝
   ⍝         Note 1: ⍵ =BII ⊥BII ⊤BII ⍵      for any valid ⍵.
   ⍝            ⍵' ≡  ⊥BII ⊤BII ⍵     if ⍵' is ⍵ canonicalized, e.g. ⍵' ← +BII ⍵.
   ⍝         Note 2: ×BII/⍵ must be used for scan. This is invalid: ×/BII ⍵.
   ⍝         Note 3: Internally, a BII is a vector of signed integers (see <RX> below>). The sign is carried
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
   ⍝   All functions return a valid BII array based on the shape of ⍺×⍵.
   ⍝   Each scalar element is stored as a canonical string
   ⍝        (¯ for negation, removing spacers _ and leading 0s)
   ⍝   If the arguments ⍺, ⍵ are both scalars, the returned value is disclosed (treated as a single BII scalar).
   ⍝           '2'×BII '3'
   ⍝       6             ⍝ scalar string.
   ⍝   ∨∧ are included as non-boolean here, because they are both GCD and LCM and Boolean.
   ⍝
   ⍝ ∘ ⊤⍵ takes a BII ⍵, returning a boolean vector.
   ⍝   ⊥⍵ takes a boolean ⍵, returning a BII.
   ⍝
   ⍝ ∘ If ⍺⍺ in (⍺⍺ BII) is a Boolean (logical) operand from
   ⍝         '<≤=≥>≠', used dyadically,  returns APL booleans 1 or 0
   ⍝         '×',      used monadically (signum), returns APL integers 1, 0, or ¯1.
   ⍝   E.g.  a←?BII BRX⍴'9'             ⍝ a: BRX-digit random number
   ⍝         :While 0 (<BII) a←<BII a   ⍝ Decrement a, terminate when 0
   ⍝              b←¯3 ⌽BII a          ⍝ b ← a ÷ 1000
   ⍝              c←(1+×BII b)⊃'bad' 'ok' 'good'    ⍝ ×BII b, i.e. signum b.
   ⍝              . . .
   ⍝         :EndWhile
   ⍝
   ⍝   This makes it easy to control loops etc. without resorting to ⍎:
   ⍝       :While i >BII '1_000_000'
   ⍝           …
   ⍝       :EndWhile
   ⍝   or used with guards in dfns:
   ⍝         ⍵ ≤BII 0: do_something_with ⍵
   ⍝   Comparisons with 0 are especially fast, because only the sign of the other argument is required.
   ⍝
   ⍝ ∘ For bit management functions ⊤ and ⊥, see above.
   ⍝                                                [PMS]
    ∇

    ∇ BIC_HELP
      __HELP__
   ⍝-------------------------------------------------------------------------------------------------------
   ⍝ BIC: BII Code translation…
   ⍝-------------------------------------------------------------------------------------------------------
   ⍝
   ⍝ ⍺:options ∇ ⍵:text|fnName
   ⍝ ∘ Takes APL code with 1adic and 2adic function and
   ⍝   replaces those available in BII with BII equivalents:
   ⍝   ¯1 + 2*31 →   '¯1' (+BII) '2' (*BII)'31'
   ⍝ ∘ Supported functions (all names are in upper case):
   ⍝        monadic: - + | × ÷ < > ! ? ⊥ ⊤ ⍎ ← → √   SQRT
   ⍝        dyadic:  - + × * ÷ ⌊ ⌈ | ∨ ∧ ⌽ < ≤ = ≥ > ≠  SHIFTD DIVREM MOD
   ⍝   All functions return a BigInt string, except as defined for BI, e.g. boolean ops < ≤ = ≥ > ≠ return 1 or 0.
   ⍝
   ⍝ ∘ Handles special BII operands (functions) SHIFTD, SQRT, and √
   ⍝   In BIC, these items are entered directly, not in (extra) quotes,
   ⍝   as if APL function names or symbols:
   ⍝      BIC '(SQRT 324932) SHIFTD 3'
   ⍝   These are converted in the appropriate BII quoted operands:
   ⍝      (('SQRT'#.BigInt.BII) '324932') ('SHIFTD'#.BigInt.BII) (,'3')
   ⍝      570000
   ⍝   Or…
   ⍝      BIC ' √√100000'         ⍝ Equivalent to  BIC 'SQRT SQRT 100000'
   ⍝   …into:
   ⍝      ('√'#.BigInt.BII)('√'#.BigInt.BII)'100000'
   ⍝      17
   ⍝ ∘ Leaves small APL unquoted numbers as is, allowing mixing with non-BII operands:
   ⍝       2 + 3 × ≢⍳123      →    2 +BII 3 ×BII ≢⍳123
   ⍝ ∘ Large APL numbers are quoted (and quoted numbers are left as is).
   ⍝
   ⍝ Features:
   ⍝   ∘ Converts common 1adic and 2adic functions to BII calls,
   ⍝     replacing e.g. +  with (+BII)
   ⍝                    -\ with (-BII)\
   ⍝   ∘ Handles simple reductions and scans:
   ⍝       +/ 111 222 333     -\ 111 222 333    3 ×/ 1111 2222 3333 4444
   ⍝   ∘ placing quotes around APL integers:
   ⍝       BIC '⊢ 23424423424323423423 | 2 + 23424423424323423423 * 5'
   ⍝     becomes executable:
   ⍝       ⊢ '23424423424323423423' (|BII) (,'2') (+BII) '23424423424323423423' (*BII) (,'5')
   ⍝     which, when executed (⍎…) has value:
   ⍝       2
   ⍝   ∘ leaving non-integers, complex #s, etc for APL to sort out.
   ⍝     Some are valid (e.g. 123E0 → 123; 12.3E1 → 123; 12.3E1J0 → 123)
   ⍝     If not, an error occurs!
   ⍝   ∘ Easily allows creating dfns, with ⍺⍺ ⍵⍵ assumed to be BII operands:
   ⍝         ⍎'opX←'BIC'{⍺  ⍺⍺ ⍵ SHIFTD 3}
   ⍝     This creates dfn op in the caller's namespace:
   ⍝         opX←{⍺ (⍺⍺BII) ⍵ ('SHIFTD'BII) '3'}
   ⍝     So that:
   ⍝         2 +opXX 5
   ⍝     via steps:
   ⍝         2 +op 5 →  2 (+BII) 5 ('SHIFTD'BII) 3 → 2 + 5000 →  5002
   ⍝     … equals:
   ⍝         5002
   ⍝   __________
   ⍝   EXTENSIONS
   ⍝   ¯¯¯¯¯¯¯¯¯¯
   ⍝   ∘ Extension 1: CODE or INTEGER ESCAPE feature:
   ⍝     Code within (: … :) inside otherwise BII-active code
   ⍝     if passed through unchanged as APL code.
   ⍝        ⍎⎕←BIC  '1 + (: (⍳10) :) * 5'
   ⍝     (,'1') (+BII) (⍳10) (*BII) (,'5')
   ⍝     1 2 33 244 1025 3126 7777 16808 32769 59050
   ⍝        :For i :in ⍳(:10:)
   ⍝         …
   ⍝        :EndFor
   ⍝   ∘ Extension 2 [for options 2 ¯2] :BII and :ENDBI Directives
   ⍝     For APL functions (option 2=|⍺), no code is automatically
   ⍝     assumed to consist of BII calls or integers. Code to be converted
   ⍝     must appear between ⍝:BII and ⍝:ENDBI statements*.
   ⍝         * The ⍝ symbol is optional. /⍝?\h*:BII.*$/ starts a BII code
   ⍝           sequence (and is otherwise ignored) and /⍝?\h*:ENDBI.*$/ ends it (ditto).
   ⍝
   ⍝
   ⍝ options:
   ⍝    ⍺ a string:   Treat as if  (⍺, 1 BIC ⍵). See dfns example above.
   ⍝    1 [default]:  compile ⍵, ≥1 char vectors with BII-ready code, returning compiled values.
   ⍝   ¯1          :  evaluate ⍵ into BII-ready code c, executing c and returning its value
   ⍝                  Note: ⍵ is executed in the BigInt namespace.
   ⍝    2          :  evaluate ⍵: the name of an APL function with BII-ready code between
   ⍝                  ⍝ :BII and ⍝ :ENDBI statements (case is ignored).
   ⍝                  Regular integer constants within :BII sequences will be treated as
   ⍝                  BII's and quoted. To force to APL, use (: … :)
   ⍝   ¯2          : like 2, except ⍵ is a char vec or vectors as if output of ⎕NR name.
   ⍝ ∇…
   ⍝ :FOR i :in ⍳count
   ⍝   item←items[i]
   ⍝   ⍝:BII
   ⍝      item←item*3
   ⍝      cum[i]+←item    ⍝ cum[i](+BII)←item
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
   ⍝ BIB: BII Binary helper function (treats BIs as APL bit vectors, with high-order and sign bit on RHS)
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

    ∇ BII∆HERE_HELP
      __HELP__
   ⍝-------------------------------------------------------------------------------------------------------
   ⍝ BII∆HERE: BII dynamic (on the fly) compiler…
   ⍝-------------------------------------------------------------------------------------------------------
   ⍝ I. To dynamically (on the fly) take a user function myFn, and have it "compiled"
   ⍝ with BIC "on the fly, place the following code early in the function myFn, outside
   ⍝ of any control structures (see below for workarounds):
   ⍝   A. If the user function myFn returns no result
   ⍝      ∇ myFn; local1; local2; ...
   ⍝        ⍎BII∆HERE
   ⍝        ⍝ Rest of lines will be interpreted as bigInt math per BIC rules.
   ⍝        ...
   ⍝      ∇
   ⍝   B. If the user function myFn returns a result, e.g. myResult
   ⍝      ∇ myResult←myFn; local1; local2; ...
   ⍝        ⍎BII∆HERE
   ⍝        ⍝ Rest of lines will be interpreted as bigInt math per BIC rules.
   ⍝        ⍝ Be sure that at least one sets myResult, as usual, before returning
   ⍝        ...
   ⍝        myResult←!50
   ⍝        ...
   ⍝      ∇
   ⍝ Notes: ----------------------------
   ⍝ ∘ In the cloned / compiled version of the caller function,
   ⍝   execution begins on the line right after the BII∆HERE.
   ⍝ ∘ If a control structure is required to determine whether to execute the function
   ⍝   as a bigInt function or not, it must be wholly contained on
   ⍝   the line containing the BII∆HERE, since BII∆HERE, if executed, starts at the next line:
   ⍝      OK:
   ⍝              :IF true ⋄ BII∆HERE ⋄ :ELSE ⋄ set a flag or something ⋄ :ENDIF
   ⍝       -->    Execution continues here whether prior IF is true or not!
   ⍝      BAD:
   ⍝              :IF true ⋄ BII∆HERE
   ⍝       -->    :ELSE ⋄ do something else      ⍝ Clone execution starts here! Ugh!
   ⍝              :ENDIF
   ⍝ ∘ If more than one BII∆HERE appears in a fn, only one is executed, since the caller
   ⍝   is terminated immediately (within the ⍎BII∆HERE) after the clone is complete.
   ⍝ ∘ For syntax, see BIC
   ⍝ ∘ The caller must not be locked, since ⎕NR is used to scan the function.
   ⍝ ∘ The clone is deleted as it begins execution. Name format: <myFn>__BigInteger_TEMP,
   ⍝   where myFn is the name of the user function..
    ∇


  ⍝ Utility function for HELP information!
    ∇ __HELP__;help
      ⎕ED&'help'⊣help←'^\h*⍝(?|\h(.*)|())'⎕S'\1'⎕NR((1+⎕IO)⊃⎕SI)
    ∇

    1
:endnamespace
