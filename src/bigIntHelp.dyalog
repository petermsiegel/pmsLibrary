:namespace bigIntHelp
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
  ⍝ ∘ Operators BI (returns BIi) and BIX (returns BIx).
  ⍝   We've added a range of monadic functions and extended the dyadic functions as well, all signed.
  ⍝   The key easy-use utilities are BI and BIX, used (with '#.BigInt' in ⎕PATH) in this form:
  ⍝       dyadic:    r:BIi← ⍺ +BI ⍵       r:BIx← ⍺ +BIX ⍵     with some exceptions (see below).
  ⍝       monadic:   r:BIi←   ×BI ⍵       r:BIx←   ×BIX ⍵     ditto.
  ⍝   For character string operands of BI/X, e.g. 'SQRT' or 'MOD',
  ⍝   parentheses are usually required (case is ignored):
  ⍝       dyadic: ⍺ ('MOD'BI)  ⍵      ←→   ⍺ mod ⍵     ⍝ Case matters for explicit function syntax!
  ⍝       monadic:  ('SQRT'BI) ⍵      ←⍀     sqrt ⍵
  ⍝   And some allow commutation directly, like |⍨ (a synonym for modulo):
  ⍝               ⍺ |⍨BI ⍵     ←→  ⍺ |BI⍨ ⍵    ←→  ⍵ |BI ⍺
  ⍝   BI works fine with APL standard commutation, reduction, and scan:
  ⍝               +BI/⍵1 ⍵2 ⍵3...
  ⍝               ⍺ ÷BI⍨ ⍵    ←→ ⍵ ÷BI ⍺
  ⍝               +BI\⍵1 ⍵2 ⍵2...
  ⍝
  ⍝   BI doesn't return external BigInt strings, but ONLY internal format objects, for efficiency.
  ⍝        (To convert to external, use ⍕BI or simply use BIX for the last computation in a series.)
  ⍝   BIX is a variant of BI that returns BigInt strings wherever BI would return a BigInt-internal object.
  ⍝         c +BIX x ×BI b +BI x ×BI a    ←→  ⍕BI c +BI x ×BI b +BI x ×BI a    ⍝ (a×x*2)+(b×x)+c
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
  ⍝       dyadic:  ⌽ (mul10), ∨ (gcd), ∧ (lcm)
  ⍝       monadic: ? (roll on ⍵>0), ⊥ ⊤ (bit manipulation), ⍎ (convert to APL int), ⍕ (convert to BI string)
  ⍝                ← (return BI-internal format)
  ⍝ ∘ Arguments to most functions are BigIntegers of any BIx form:
  ⍝       a single BigInteger string in quotes    '-2343_243422'
  ⍝       a single APL signed integer (whether stored as an integer or float)   ¯2343243422
  ⍝       a BI internal-format vector, consisting of a scalar sign followed by a data vector of unsigned numbers;
  ⍝          See the internal format (above).     ¯1 (2343 243422)
  ⍝ ∘ Instead of using operand with BI (+BI), a set of BigInteger functions can be called directly:
  ⍝       dyadic:   ⍺ plus ⍵ ⋄  ⍺ gcd ⍵ ⋄⋄⋄
  ⍝       monadic:  sig  ⍵   ⋄  roll '1',99⍴'0'
  ⍝   These all return a BIi (BigInteger internal format), with a few exceptions (exp/ort returns a BIx).
  ⍝   Many local functions have abbreviated synonyms. Local functions include:
  ⍝       plus minus times (mul) div(ide) divrem power residue mod(ulo) mul10 times10 div(ide)10
  ⍝       neg(ate) sig(num) magnitude (abs) roll
  ⍝   Logical functions < ≤ = ≥ > ≠ return a single boolean, to make them easy to use
  ⍝   in program control. (gcd ∨ and lcm ∧ always return BI internals, since their logical use is a subset).
  ⍝
  ⍝ ∘ Bit strings are passed to the user as two's-complement boolean vectors,
  ⍝   with the lowest-order bit first (so ⍵[0] is the LOB),
  ⍝   and the sign-bit last, i.e. as the highest-order bit (i.e. ⊃⌽⍵ is 1, if the # if negative).
  ⍝
  ⍝ Notable enhancements compared to dfns:nats:
  ⍝ ∘ Input BI strings may have ¯ or - prefixed for negative numbers and may include _ as spacers,
  ⍝   which are ignored:   e.g.  '-553_555_555'    '¯99999_12345_12345'    '00000_00000_00000'
  ⍝ ∘ ⌽BI is used to shift (not rotate) decimal digits left and right,
  ⍝   i.e. to multiply and divide by 10**⍵ very quickly and efficiently.
  ⍝      ∘ Example: A million-digit string ⍵ can be multiplied by 10*10000 in 0.012 seconds via
  ⍝        10000 ⌽BI ⍵
  ⍝ ∘ We include ⊤BI and ⊥BI to convert BI's to and from APL bits, so that APL ⌽ ∧ ∨ = ≠ can be used for
  ⍝   various bit manipulations on BIx; a utility BIB (Big Integer Bits) has been provided as well.
  ⍝ ∘ We support an efficient (Newton's method) integer sqrt:
  ⍝        ('SQRT' BI)⍵ or ('√' BI)⍵, as well as  BIC '√⍵', where ⍵ is a big integer.
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
     ⍝  BI_HELP       BI       ∘ big integer utility         a *BI '2343243'
     ⍝  BIC_HELP      BIC      ∘ big integer code translator ( 2999999…99999992 + 33  →   '2999999…99999992' (+BI) '33)
     ⍝  BIB_HELP      BIB      ∘ big integer binary data op   a ≠BIB b     (exclusive or of bits of a and b)
     ⍝                           where a←'3244234324343423432423432342342' ⋄ b← ⌽a
     ⍝  BI∆HERE_HELP  BI∆HERE  ∘ allows compilation on the fly of a function with :BI …. :ENDBI code.
    ∇

    ∇ BI_HELP
      __HELP__
   ⍝ BI-- a big integer utility
   ⍝
   ⍝ The BI operator provides basic arithmetic functions on big integers stored externally as strings
   ⍝ and internally as a series of (signed) integers.
   ⍝ Built around dfns:nat as its numerical core, but extended to handle signed numbers,
   ⍝ reduce and scan, factorial, roll(?).
   ⍝ To handle multiple objects in ⍺ or ⍵, do:   ⍺  ⍺⍺ BI¨ ⍵.
   ⍝ This is as fast as providing internally, avoiding extra checks for multi-item single args for ⊥.
   ⍝
   ⍝ Syntax: [Let × represent dyadic and monadic ×, standing in for all dyadic and monadic functions.]
   ⍝      ⍺ ×    BI ⍵           Multiplies ⍺×⍵ for BIs ⍺ and ⍵.
   ⍝        ×    BI ⍵           Determines the signum of BIs ⍵.
   ⍝        ×BI\    ⍵           Performs ×-scan of ⍵, i.e. ⍵0 (⍵0×⍵1) … (⍵0×⍵1×…×⍵N)
   ⍝      ⍺ ×BI/    ⍵           Performs N-wise reduction (see above)
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
   ⍝ BI/BIX OPERAND SUMMARY with BigInt FUNCTION SUMMARY
   ⍝ ----------------------------------------------------
   ⍝ ∘ For formats: ⍺ op BI ⍵, and equivalent: ⍺ fun ⍵.
   ⍝ ∘ All directly called functions return a
   ⍝   BIi (internal-format BigInteger with integer sign and data vector)
   ⍝   except where specified.
   ⍝  --------------------------------------------------------------------
   ⍝                     directly-called
   ⍝  BI/X op (⍺⍺)       function*         description
   ⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
   ⍝ MONADIC
   ⍝    -BI ⍵             negate ⍵         -⍵
   ⍝    +BI ⍵             [none]           ⍵     Simply validates BIx passed
   ⍝    |BI ⍵             magnitude ⍵      |⍵    Absolute value
   ⍝                      abs ⍵
   ⍝    ×BI ⍵             direction ⍵      ×⍵
   ⍝                      signum
   ⍝                      sig ⍵
   ⍝    ÷BI ⍵             reciprocal ⍵     ÷⍵    Very limited use
   ⍝    <BI ⍵             decrement ⍵      ⍵-1   Extension
   ⍝    >BI ⍵             increment ⍵      ⍵+1   Extension
   ⍝    !BI ⍵             factorial ⍵      !⍵
   ⍝                      fact ⍵
   ⍝    ?BI ⍵             roll ⍵           ?⍵    ⍵>0
   ⍝    ⊥BI ⍵             bitsIn ⍵               Converts bits to BigInt
   ⍝    ⊤BI ⍵             bitsOut ⍵              Converts BigInt to bits, 2s' complement, sign on right
   ⍝    ⍎BI ⍵             ⍎export ⍵              Converts ⍵ to APL integer (or error)
   ⍝    ←BI ⍵             ⍵                      Returns ⍵ in BigInt internal form. More relevant with BIX.
   ⍝    ⍕BI ⍵             export ⍵               Returns an BigInt in external (string) form.
   ⍝    ('SQRT'BI) ⍵      sqrt ⍵           ⌊⍵*0.5
   ⍝    ('√'BI)⍵          ↓
   ⍝    (*∘0.5 BI)⍵       ↓
   ⍝
   ⍝  DYADIC     -+x⌽ MUL10 TIMES10 DIV10 ÷ DIV2 * | |⍨ < etc ∨ ∧
   ⍝    ⍺ -BI ⍵           ⍺ minus ⍵        ⍺-⍵
   ⍝                      ⍺ subtract ⍵
   ⍝                      ⍺ sub ⍵
   ⍝    ⍺ +BI ⍵           ⍺ plus ⍵         ⍺+⍵
   ⍝                      ⍺ add ⍵
   ⍝    ⍺ ×BI ⍵           ⍺ times ⍵        ⍺×⍵
   ⍝                      ⍺ mul ⍵
   ⍝    ⍺ ⌽BI ⍵           ⍺ mul10 ⍵        ⍺×10*⍵ Performs an efficient(**) shift by orders of 10.
   ⍝    ⍺ ('MUL10'BI)⍵    ↓                If ⍵>0, shifts left; if ⍵<0, shifts right.
   ⍝    ⍺ ('TIMES10'BI)⍵  ↓
   ⍝    ⍺ ('DIV10'BI)⍵    ⍺ div10 ⍵        ⍺×10*-⍵ Shifts right by ⍵ digits for positive ⍵.
   ⍝    ⍺ ÷BI ⍵           a divide ⍵       ⍺÷⍵
   ⍝                      ⍺ div ⍵
   ⍝    ⍺ ('DIVIDEREM'BI)⍵  ⍺ divideRem ⍵  (⍺÷⍵)(⍵|⍺) Returns a pair of BigIntegers.
   ⍝    ⍺ ('DIVREM'BI) ⍵  ⍺ divRem ⍵
   ⍝    ⍺ *BI ⍵           ⍺ power ⍵        ⍺*⍵
   ⍝                      ⍺ pow ⍵
   ⍝    ⍺ |BI ⍵           ⍺ residue ⍵      ⍺|⍵
   ⍝    ⍺ |⍨BI ⍵          ⍺ modulo ⍵       ⍵|⍺
   ⍝                      ⍺ mod ⍵          ⍵|⍺
   ⍝    ⍺ ∨BI ⍵           ⍺ gcd ⍵          ⍺∨⍵    Returns a BigInteger. Not viewed as boolean.
   ⍝    ⍺ ∧BI ⍵           ⍺ lcm ⍵          ⍺∧⍵    Returns a BigInteger. Not viewed as boolean
   ⍝  LOGICAL FUNCTIONS (DYADIC)
   ⍝    ⍺ <BI ⍵           ⍺ lt ⍵           ⍺<⍵    Returns 1 or 0, not a BigInteger
   ⍝    Also ≤ (le)  = (eq)
   ⍝         ≥ (ge)  > (gt)
   ⍝         ≠ (ne)
   ⍝
   ⍝  ------------
   ⍝  (*) First name is usually the APL standard name.
   ⍝  (**) ⌽BI, mul10 are typically 20-30% faster than the equivalent ⍺ × 10*⍵ if 10*⍵ is precomputed.
   ⍝  (↓) Function is same as above.
   ⍝
   ⍝ ------------------------------------------------------------------------------------
   ⍝
   ⍝ Functions Available:
   ⍝   Dyadic functions:
   ⍝      Standard Meaning: +-×*÷<≤=≥>≠⌊⌈|∨∧
   ⍝      Special Meaning:  ⌽  'MUL10'
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
   ⍝      Dyadic 'MUL10'
   ⍝         Reverse-arg synonym of ⌽:
   ⍝              ⍺ ('MUL10' BI) ⍵
   ⍝         multiplies ⍺ by 10*⍵, if ⍵>0, or divides by 10*⍵,
   ⍝         i.e. adds 0's on the right or truncates from the right.
   ⍝         If all digits are truncated, returns (,'0'), canonical 'zero.'
   ⍝
   ⍝   Monadic functions:
   ⍝      Standard Meaning:  - | !
   ⍝      Returns special:   ×  (returns integer ¯1 0 1)
   ⍝      Special Meaning:   + < > ? ⊥ ⊤ !  'SQRT'   ⍎   ←
   ⍝         + (canonical):   Returns ⍵ in canonical format (no complex #s)
   ⍝         < (decrement):   <BI '10'  is 9.
   ⍝         > (increment):   >BI '10'  is 11.
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
   ⍝         ! factorial
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
   ⍝        dyadic:  - + × * ÷ ⌊ ⌈ | ∨ ∧ ⌽ < ≤ = ≥ > ≠  MUL10 DIVREM MOD
   ⍝   All functions return a BigInt string, except as defined for BIX, e.g. boolean ops < ≤ = ≥ > ≠ return 1 or 0.
   ⍝
   ⍝ ∘ Handles special BI operands (functions) MUL10, SQRT, and √
   ⍝   In BIC, these items are entered directly, not in (extra) quotes,
   ⍝   as if APL function names or symbols:
   ⍝      BIC '(SQRT 324932) MUL10 3'
   ⍝   These are converted in the appropriate BI quoted operands:
   ⍝      (('SQRT'#.BigInt.BI) '324932') ('MUL10'#.BigInt.BI) (,'3')
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
   ⍝         ⍎'opX←'BIC'{⍺  ⍺⍺ ⍵ MUL10 3}
   ⍝     This creates dfn op in the caller's namespace:
   ⍝         opX←{⍺ (⍺⍺BI) ⍵ ('MUL10'BI) '3'}
   ⍝     So that:
   ⍝         2 +opXX 5
   ⍝     via steps:
   ⍝         2 +op 5 →  2 (+BI) 5 ('MUL10'BI) 3 → 2 + 5000 →  5002
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
   ⍝ BIB: BigInteger Binary helper function
   ⍝ BIB is a helper function that applies ⍺⍺ to boolean casts of ⍺ [if present] and ⍵.
   ⍝ Syntax: c:bi ← a:bi ⍺⍺ BIB b:bi  OR   c:bi ← ⍺⍺ BIB b:bi
   ⍝    ⍺, ⍵ must each be a single BI. (Use BIB¨ for multiple BIs)
   ⍝ While ⍺⍺ can be any APL function, useful ones include:
   ⍝    ∧ (and), ∨ (or), ≠ (xor); ~
    ∇

    ∇ BI∆HERE_HELP
      __HELP__
   ⍝-------------------------------------------------------------------------------------------------------
   ⍝ BI∆HERE: BI dynamic (on the fly) compiler…
   ⍝-------------------------------------------------------------------------------------------------------
   ⍝ To dynamically (on the fly) take a function fn, compile
   ⍝ it with BIC, and execute it, place
   ⍝    ⍎BI∆HERE           ⍝ no arguments
   ⍝ early in the function fn, outside of any control structures (otherwise,
   ⍝ a syntax error may be signalled).
   ⍝ ----------------------------------
   ⍝ ∘ In the cloned / compiled version of the caller function,
   ⍝   execution begins on the line right after the BI∆HERE.
   ⍝ ∘ If a control structure is required to determine whether to execute the function
   ⍝   as a bigInt function or not, it must be wholly contained on
   ⍝   the line containing the BI∆HERE:
   ⍝      OK:     :IF true ⋄ BI∆HERE ⋄ :ELSE ⋄ set a flag or something ⋄ :ENDIF
   ⍝       -->    Execution continues here whether prior IF is true or not!
   ⍝      BAD:    :IF true ⋄ BI∆HERE
   ⍝       -->    :ELSE ⋄ do something else      ⍝ Clone execution starts here! Ugh!
   ⍝              :ENDIF
   ⍝ ∘ If more than one BI∆HERE appears in a fn, only one is executed, since the caller
   ⍝   is terminated immediately (on the ⍎BI∆HERE) after the clone is complete.
   ⍝ ∘ For syntax, see BIC
   ⍝ ∘ The caller must not be locked, since ⎕NR is used to scan the function.
   ⍝ ∘ The clone is deleted as it begins execution. Name format: _TEMP_callerNm_,
   ⍝   where callerNm is the name of the caller.
    ∇


  ⍝ Utility function for HELP information!
    ∇ __HELP__;help
      ⎕ED'help'⊣help←'^\h*⍝(?|\h(.*)|())'⎕S'\1'⎕NR((1+⎕IO)⊃⎕SI)
    ∇

    1
:endnamespace
