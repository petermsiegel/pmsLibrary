:namespace demoBigInt
::DEFINE VERBOSE←1

⍝ ⎕FX '{ok}←note str'  (VERBOSE↓'⍝⎕←str') 'ok←1'
::IF VERBOSE
     ::define note←___←1#⊣⎕←
::Else
     ::define note←___←
::ENDIF
⍝
    ∇ {_}←loadHelp
      :Trap 0
          _←⎕SE.SALT.Load'-target=',(⍕⎕THIS.##),' pmsLibrary/src/bigIntHelp'
      :Else
          _←⎕←'Unable to load bigIntHelp'
      :EndTrap
    ∇
    loadHelp

    :Section PREAMBLE and Table of Contents
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
    :EndSection PREAMBLE and Table of Contents

    :Section BigInt Namespace and Utility BI - Initializations
  ⍝+------------------------------------------------------------------------------+⍝
  ⍝+-- BI INITIALIZATIONS                           BI INITIALIZATIONS          --+⍝
  ⍝-------------------------------------------------------------------------------+⍝
  ⍝+-- BI: BI Operator for calling a big integer function as the left operand.  --+⍝
  ⍝-------------------------------------------------------------------------------+⍝
::DEFINE  DEBUG←0                                     ⍝ Change to 1 to turn off signal trapping…

::IF ~DEBUG  
    ⎕TRAP←911 'E' '(''BigInt: '',⎕DMX.EM)⎕SIGNAL 11'
::ENDIF

    ⎕IO ⎕ML←0 1 ⋄  ⎕PP←34 ⋄ ⎕CT←⎕DCT←0 ⋄ ⎕CT←1E¯14 ⋄ ⎕DCT←1E¯28   ⍝ For ⎕FR,  see below
  ⍝ err: If dfns, use form "cond: err msg".
  ⍝      If trad, use form "cond  err msg".
    err←{⍺←1 ⋄ ⍺=1: ⍵ ⎕SIGNAL 911 ⋄ 1: _←⍵ }

  ⍝   INTERNAL-FORMAT BIs
  ⍝    BIi  -internal-format signed Big Integer numeric vector.
  ⍝          A BIV is a vector of radix <RX> numbers. The first (left-most) non-zero number carries the sign.
  ⍝          Other numbers may be signed, but it's ignored.
  ⍝          ∘ Leading zeros are removed in the canonical form. After imp/ort, zero is (0=≢⍵)
  ⍝          ∘ Some routines use (zro BIi) to make sure every BIi has at least one digit. See BIz.
  ⍝    BIu  -unsigned internal-format BIi (vector of integers):  (|BIi)
  ⍝    BIz  -signed internal-format BIi, but of form (zro ⍵), so that zero is return with exactly 1 digit 0.
  ⍝   EXTERNAL-FORMAT BIs
  ⍝    BIx  -an external-format Big Integer, i.e. a character string. When entered by the user,
  ⍝          several variants are accepted:
  ⍝          a BI has these characteristics:
  ⍝          ∘ char. vector or scalar   ∘ leading ¯ or - prefix for minus, and no prefix for plus.
  ⍝          ∘ otherwise, only the digits 0-9 plus optional use of _ to space digits.
  ⍝          ∘ If no digits (''), it represents 0.
  ⍝          ∘ spaces are disallowed, even leading or trailing.
  ⍝    BIc  -a canonical (normalized) external-format BI string has a guaranteed format:
  ⍝          ∘ char. vector     ∘ leading ¯ ONLY for minus.
  ⍝          ∘ otherwise, only the digits 0-9. No underscores, spaces, or hyphen - for minus.
  ⍝          ∘ leading 0's are removed.
  ⍝          ∘ 0 is represented by (,'0'), unsigned with no extra '0' digits.
  ⍝   OTHER TYPES
  ⍝    Int  -an APL-format single integer, often in range ⍵<RX.
  ⍝
  ⍝

  ⍝ RX:  Radix for internal BI integers. Ensure ⍵×⍵ doesn't overflow in 32-bit integer.
  ⍝ DRX: # Decimal digits that RX must hold.
  ⍝ BRX: # Binary  digits required to hold DRX digits. (See encode2Bits, decodeFromBits).
  ⍝ OFL: integer size in timesU beyond which digits must be split to prevent overflow.
  ⍝      OFL is a function of the # of guaranteed mantissa bits in the largest (float) number used
  ⍝      AND the radix RX, viz.   ⌊mantissa_bits ÷ RX*2, since it's the bits of ⍺×⍵.
  ⍝ ⎕FR: Whether floating rep is 64-bit float (53 mantissa bits, and fast)
  ⍝      or 128-bit decimal (93 mantissa bits and much slower).
    ⎕FR←645 ⍝ Choice determines DRX, RX, BRX, and OFL.
    BRX←⌈2⍟RX←10*DRX←(⎕FR=1287)⊃6 12
        OFL←{⌊(2*⍵)÷RX*2}(⎕FR=1287)⊃53 93

  ⍝ Data field (unsigned) constants
    ZEROd←,0         ⍝ data field ZERO, i.e. unsigned canonical ZERO
    ONEd←,1          ⍝ data field ONE, i.e. unsigned canonical ONE

  ⍝ Error messages. All will be used with fn <err> and ⎕SIGNAL 911: BigInt DOMAIN ERROR
    eBADBI←'Invalid BigInteger'
    eCANTDO1←'Monadic function not implemented as BI operand: '
    eCANTDO2←'Dyadic function not implemented as BI operand: '
    eINVALID←'Format of big integer is not valid: '
    eFACTOR←'Factorial (!) argument must be ≥ 0'
    eBADRAND←'Roll (?) argument must be >0'
    eSQRT←'sqrt: arg must be non-negative'
    eTIMES10←'times10/⌽: right arg (⍵) must be a small APL integer ⍵<',⍕RX
    eBIC←'BIC argument must be a fn name or one or more code strings.'
    eBITSIN←'BigInt: Importing bits requires arg to contain only boolean integers'

    :EndSection BigInt Namespace and BI Utility - Initializations

    :Section BI - Executive
    ⍝+------------------------------------------------------------------------------+⍝
    ⍝+------------------------------------------------------------------------------+⍝
    ⍝+      EXECUTIVE                 BI                     EXECUTIVE              +⍝
    ⍝+------------------------------------------------------------------------------+⍝
    ⍝+------------------------------------------------------------------------------+⍝

    ⍝ listMonadFns }  [0] single-char symbols [1] multi-char names
    ⍝ listDyadFns  }  ditto
    listMonadFns←'-+|×÷<>!?⊥⊤⍎→√' (⊂'SQRT') ⍝ Remove ←
    ⍝            reg. fns       boolean
    listDyadFns←('+-×*÷⌊⌈|∨∧⌽', '<≤=≥>≠') ('MUL10'  'TIMES10' 'DIV10'   'DIVREM' 'MOD')


    ⍝ BI: Basic utility operator for using APL functions in special BigInt meanings.
    ⍝     BIi ← ∇ ⍵:BIx
    ⍝     Returns BIi, an internal format BigInteger structure (sign and data, per above).
    ⍝     See below for exceptions ⊥ ⊤ ⍎
    ⍝ BIX:Basic utility operator built on BI.
    ⍝     BIx ← ∇ ⍵:BIx
    ⍝     Returns BIx, an external string-format BigInteger object ("[¯]\d+").


⍝ --------------------------------------------------------------------------------------------------
      BIX←{⍺←⊢
          911::⎕SIGNAL/⎕DMX.(EM 11)
        ⍝ fn: If ⍺⍺ is a simple APL fn (+),            fn is a simple char scalar.
        ⍝     If       a sequence of APL symbols(|⍨),  fn is an enclosed char vector (⊂'|⍨').
        ⍝     If       a 1-char string ('√' or ,'√')   fn is a simple scalar char, uppercase.
        ⍝     If       a sequence of chars ('MUL10'),  fn is an enclosed string (⊂'MUL10'), uppercase.
        ⍝     In short, whatever ⍺⍺ input,             fn is a char scalar, simple if length 1 or an enclosed vector.

          fn←⊂⍺⍺{aa←⍺⍺ ⋄ 3=⎕NC'aa':atom⍕⎕CR'aa' ⋄ 1(819⌶)aa}⍵
          CASE←1∘∊fn∘≡∘⊆¨∘⊆       ⍝ CASE ⍵1 or CASE ⍵1 ⍵2..., where at least one ⍵N is @CV, others can be @CS.
          ⍝ Monadic...
          1≡⍺ 1:{                              ⍝ BIX: ∆exp∆: See Build BIX/BI below.
              CASE'-':∆exp∆ negate ⍵           ⍝     -⍵
              CASE'+':∆exp∆ ∆ ⍵                ⍝     nop, except makes sure obj is valid in BIi form.
              CASE'|':∆exp∆ magnitude ⍵        ⍝     |⍵
              CASE'×':∆exp∆⊃∆ ⍵                ⍝     ×⍵ signum:  Returns APL int (∊¯1 0 1), not BI.
              CASE'÷':∆exp∆ reciprocal ⍵       ⍝     ÷⍵:         Why bother?
              CASE'<':∆exp∆ decrement ⍵        ⍝     ⍵-1:        Optimized for constant in ⍵-1.
              CASE'>':∆exp∆ increment ⍵        ⍝     ⍵+1:        Optimized for constant in ⍵+1.
              CASE'!':∆exp∆ factorial ⍵        ⍝     !⍵          For integers ⍵≥0
              CASE'?':∆exp∆ roll ⍵             ⍝     ?⍵:         For int ⍵>0 (0 invalid)
              CASE'⊥':∆exp∆ bitsIn ⍵           ⍝     bits→BI:    Converts from bit vector (BIB) to BI internal
              CASE'⊤':bitsOut ∆ ⍵              ⍝     BI→bits:    Converts a BI ⍵ to its bit form, a BIB bit vector
              CASE'⍎':⍎exp ∆ ⍵                 ⍝     BIi→int:    If in range, returns a std APL number; else error
              CASE'←':∆ ⍵                      ⍝     BIi out:    Returns the BI internal form of ⍵: BRX-bit signed integers
              CASE'⍕':exp ∆ ⍵                  ⍝     BIi→BIx:    Takes a BI internal form vector of integers and returns a BI string
              CASE'SQRT' '√' '*∘ 0.5':exp sqrt ⍵   ⍝     ⌊⍵*0.5
              err eCANTDO1,,⎕FMT #.FN∘←fn
          }⍵
          ⍝ Dyadic...
          CASE'-':∆exp∆ ⍺ minus ⍵
          CASE'+':∆exp∆ ⍺ plus ⍵
          CASE'×':∆exp∆ ⍺ times ⍵
          CASE'⌽':∆exp∆ ⍵ times10 ⍺                 ⍝  ⍵×10*⍺:    Equiv. to a shift by powers of 10, but faster.
          CASE'MUL10' 'TIMES10':∆exp∆ ⍺ times10 ⍵   ⍝  ⍺×10*⍵:    ⍵ signed.
          CASE'DIV10':∆exp∆ ⍺ times10 negate ⍵    ⍝  ⍺×10*-⍵:   ⍵ signed.
          CASE'÷':∆exp∆ ⍺ divide ⍵                  ⍝  ⌊⍺÷⍵
          CASE'DIVIDEREM' 'DIVREM':∆exp∆¨⍺ divideRem ⍵    ⍝  (⌊⍺÷⍵)(⍵|⍺)
          CASE'*':∆exp∆ ⍺ power ⍵
          CASE'|':∆exp∆ ⍺ residue ⍵                 ⍝ |           APL residue
          CASE'|⍨' 'MOD':∆exp∆ ⍵ residue ⍺          ⍝ ⍺ ('MOD' BI)⍵ ←→ ⍵|BI ⍺
          CASE'<':⍺ lt ⍵                            ⍝ All logical fns <≤=≥>≠ return r∊1 0. ∨∧ are excluded.
          CASE'≤':⍺ le ⍵                            ⍝ ⍺≤⍵ etc.
          CASE'=':⍺ eq ⍵
          CASE'≥':⍺ ge ⍵
          CASE'>':⍺ gt ⍵
          CASE'≠':⍺ ne ⍵
          CASE'∨':∆exp∆ ⍺ gcd ⍵                     ⍝ ⍺∨⍵
          CASE'∧':∆exp∆ ⍺ lcm ⍵                     ⍝ ⍺∧⍵

          err eCANTDO2,,⎕FMT fn
      }
    ⍝ Build BIX/BI.
    ⍝ BIX: Change ∆exp∆ to string imp.
    ⍝ BI:  Change ∆exp∆ to null string. Use name BI in place of BIX.
    note'Created operator BI'⊣⎕FX 'BIX' '∆exp∆¨?'⎕R 'BI' ''⊣⎕NR 'BIX'
    note'Created operator BIX'⊣⎕FX '∆exp∆'⎕R 'exp'⊣⎕NR 'BIX'
    note'BI/BIX Operands:'
    note ⎕FMT(' Monadic:'listMonadFns),[¯0.1]' Dyadic: 'listDyadFns
    note 55⍴'¯'

    :Endsection BI Executive   --------------------------------------------------------------------
⍝ --------------------------------------------------------------------------------------------------

    :Section BigInt internal structure
    ⍝ An internal BI, BIi, is of this form:
    ⍝    sign data,
    ⍝       sign: a scalar integer in ¯1 0 1                     sign:IS∊¯1 0 1
    ⍝       data: an unsigned integer vector ⍵, where ⍵∧.<RX.    data:UV
    ⍝    Together sign and data define a big integer.
    ⍝    If sign=0, data≡,0 when returned from functions. Internally, extra leading 0's may appear.
    ⍝    If sign≠0, data may not be 0 (i.e. data∨.≠0).

      ⍝ ∆:   [BIi] BIi ← ⍺@BIx ∇ ⍵@BIx
      ⍝ ∆:   Returns an internal-format BI (BIi), given a BIi, an external string (BIstr) or APL signed integer.
      ⍝      Monadic: Returns for ⍵, (sign data) in the format above.
      ⍝      Dyadic:  Returns for ⍺ ⍵, (sign data)(sign data).
      ⍝
      ⍝ ∆: Convert any external-format BI (BIx) to a BIi, internal-format BI, sign data pair.

      ∆←{⍺←⊢
          0::⎕SIGNAL/⎕DMX.(EM EN)
          1≢⍺ 1:(∆ ⍺)(∆ ⍵)             ⍝ ⍺ ∆ ⍵

          ' '=1↑0⍴⍵:∆str ⍵             ⍝ ⍵ is a string
          1=≢⍵:∆Num ⍵                  ⍝ ⍵ is a single APL signed integer

          ~DEBUG:⍵                     ⍝ If not DEBUGging, don't verify BIi.
          ⋄ ∆sane←{(1 0 ¯1∊⍨⊃⍵)∧(¯2=≡⍵)∧2=≢⍵}     ⍝ Minimal check for sane  BIi.
          ∆sane ⍵:⍵                    ⍝ ∆sane: for debugging
          err eBADBI
      }
      ⍝ ∆Num: Convert an APL integer into a BIi
      ⍝ ∆Num and ∆BigNum merged-- ∆Num was inaccurate.
      ⍝
      ⍝ Converts simple APL native numbers, as well as those with large exponents, e.g. of form:
      ⍝     1.23E100 into a string '123000...000', ¯1.234E1000 → '¯1234000...000'
      ⍝ These must be in the range of decimal integers (up to +/- 1E6145)
      ⍝ Usage:   ?BIX ∆Num 1E100   ←→   ?BIX '1',100⍴'0'
      ∆Num←{⎕FR←1287
          ⍵≠⌊⍵:err eBADBI
          (×⍵)(zro RX⊥⍣¯1⊣|⍵)
      }

      ⍝ ∆str: Convert a BIstr (BI string) into a BIi
      ∆str←{
          s←1 ¯1⊃⍨'-¯'∊⍨1↑⍵     ⍝ Get sign, if any
          w←'_'~⍨⍵↓⍨s=¯1        ⍝ Remove initial sign and embedded _ (spacer).
          (0=≢w)∨0∊w∊⎕D:err eBADBI     ⍝ w must include only ⎕D and at least one.
          d←dlzs rep ⎕D⍳w       ⍝ d: data portion of BIi
          ∆z s d                ⍝ If d is zero, return zero. Else (s d)
      }

    ⍝ exp: EXPORT a SCALAR BI
    ⍝    r:BIc ← ∇ ⍵:BIi
      export←{ ⍝ exp: internal to external (output string) format'
          sw w←⍵
          sgn←(sw=¯1)/'¯'
          sgn,⎕D[dlzs,⍉(DRX⍴10)⊤|w]
      }
    exp←export

    ⍝ ∆z:  r:BIi ←∇ ⍵:BIi
    ⍝      If ⍵:BIi has data≡ZEROD, then return (0 ZEROd). Else return ⍵ w/ leading zero deleted.
    ∆z←{ (⊃⍵)(zro dlz ⊃⌽⍵)}

    :EndSection BigInt internal structure
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Monadic Operands/Functions
    ⍝ The first name will be the APL std name (exceptions noted), followed by
    ⍝ abbreviations and common alternatives.  E.g. monadic | is called  magnitude, but we also call it abs.

      negate←{
          (sw w)←∆ ⍵
          (-sw)w
      }
    neg←negate
      direction←{
          (sw w)←∆ ⍵
          sw(|sw)
      }
    signum←direction
    sig←direction
      magnitude←{
          (sw w)←∆ ⍵
          (|sw)w
      }
    abs←magnitude

    ⍝ increment: BIi ← ∇ BI.  r← ⍵ + 1. ⍵ signed.
      increment←{
          (sw w)←∆ ⍵                    ⍝  If ⍵<0, increment is towards 0.
          sw=0:1 ONEd
          sw=¯1:∆z sw(⊃⌽decrement 1 w)  ⍝ inc ¯5: Do -(dec 5)
          î←1+⊃⌽w
          RX>î:sw w⊣(⊃⌽w)←î             ⍝ If î won't overflow, increment and we're done!
          sw w plus 1 ONEd              ⍝ Overflow? Do long way
      }
    inc←increment
    ⍝ decrement: BIi ← ∇ BI.  r← ⍵ - 1. ⍵ signed.
      decrement←{
          (sw w)←∆ ⍵                    ⍝ If ⍵<0, decrement is away from 0.
          sw=0:¯1 ONEd
          sw=¯1:∆z sw(⊃⌽increment 1 w) ⍝ dec ¯5: Do -(inc 5)

          0≠⊃⌽w:∆z sw w⊣(⊃⌽w)-←1           ⍝ If won't underflow, decrement and we're done!
          sw w minus 1 ONEd             ⍝ Underflow? Do long way.
      }
    dec←decrement

    ⍝ fact: compute BI factorials.
    ⍝       r:BIc ← fact ⍵:BIx
    ⍝ We allow ⍵ to be of any size, but numbers larger than DRX are impractical.
    ⍝ We deal with 3 cases:
    ⍝    ⍵ ≤ 31:    We let APL calculate, with ⎕PP←34.   Fast.
    ⍝    ⍵ ≤ DRX:   We calculate r as a BigInt, while counting down ⍵ as an APL integer. Moderately fast.
    ⍝    Otherwise: We calculate entirely using BigInts for r and ⍵. Slowwwwww.
      factorial←{
          aw w←∆ ⍵
          aw=0:0 ZEROd
          aw=¯1:err eFACTOR
          factBig←{
              1=≢⍵:⍺ factSmall ⍵            ⍝ Skip to factSmall when ⍵ is small enough...
              (⍺ mulU ⍵)∇⊃⌽decrement 1 ⍵
          }
          factSmall←{
              ⍵≤1:1 ⍺
              (⍺ mulU ⍵)∇ ⍵-1
          }
          1 factBig w
      }
    fact←factorial

    ⍝ rand ⍵: Compute a random number between 0 and ⍵-1, given ⍵>0.
    ⍝    r:BIc ← ∇ ⍵:BIc   ⍵>0.
    ⍝ First computes a random # r with between 0 and ⍵', where ⍵' is a decimal number
    ⍝ with the same # of digits as ⍵ canonicalized (remove sign, leading zeros, etc.).
    ⍝ Uses ⎕PP←34 and ?0 to collect 34 random digits per call, up to number needed.
    ⍝ Then,
    ⍝     [fast] If r canonicalized has fewer decimal digits than ⍵', return r.
    ⍝     [slow] If the same number of decimal digits, compute r'←(⍵ | r) to return r' in range.
      roll←{
          aw w←∆ ⍵
          aw≠1:err eBADRAND
          ⎕PP←16 ⋄ ⎕FR←645                       ⍝ 16 digits per ?0
          inL←≢exp aw w                          ⍝ ⍵: in exp form. in: ⍵ with leading 0's removed.

          out←∆T←inL⍴{                           ⍝ out: BIi
              ⍺←''                               ⍝ ?0 of form 0.nnn...nnn with 34 digits after dec pt.
              ⍵≤≢⍺:⍺ ⋄ (⍺,2↓⍕#.?0)∇ ⍵-⎕PP        ⍝ Generate 16-digit numbers at a time. Generate in # to avoid ? quirk.
          }inL                                   ⍝ Get the length of the BI string!
          inL>≢out:out                           ⍝ exp? Yes. ← If out already has fewer digits than ⍵, we're done.
          ⍵ residue out                          ⍝ exp? Yes. ← Compute out' ← in | out.
      }


  ⍝ bitsOut, bitsIn: Manage one or more BRX-bit integers (e.g. 20 etc.) stored in APL 32-bit integers.
  ⍝     bitsOut:   r:boolean array ←  ∇ ⍵:BIi
  ⍝     bitsIn:    r:BIc           ←  ∇ ⍵:BIi
  ⍝
  ⍝ The resulting bitstring will always have the lowest-order bit as bit [0]. The highest is
  ⍝ the sign-bit on the right hand side: 1=negative, 0=positive. Bitstrings are bit representations
  ⍝ of standard signed numbers, twos complement, with a single sign bit as above.
  ⍝
  ⍝ bitsOut will always put out a vector of bits of length l, where 1=BRX|l, i.e. 21, 42, etc.
  ⍝
  ⍝ bitsIn will accommodate an external bit-string of any length. It will import as a series
  ⍝ of signed BRX-bit integers, padding on the right with 0s, followed by a single sign-bit.
  ⍝
      bitsOut←{
          aw w←∆ ⍵                   ⍝ sg: ¯1 for neg, or 0.
          b←,⍉1↓[0](0,BRX⍴2)⊤aw×|w   ⍝ make sure all ints are signed, so all fit 2s complement bit string.
          b,¯1=aw
      }
      bitsIn←{
          b←,⍵
          0∊b∊0 1:err eBITSIN
          sg←0 ¯1⊃⍨⊃⌽b               ⍝ sg: either ¯1 for neg, or 0. For use in ⊥
          n←⌈BRX÷⍨¯1+≢b
          b←sg,n BRX⍴(n×BRX)↑¯1↓b    ⍝ Allows non-std bits-- we pad to next BRX, but treating
          (×sg)(|2⊥⍉b)               ⍝ high-order bit (right-most) as the sign bit (1=negative).
      }

    ∇ x←sqrt N;ndig;sign;y
    ⍝ intSqrt: A fast integer square root: Fredrick Johanssen's algorithm with optimization for APL integers.
    ⍝ x:BIi ← ∇ N:(BIi|BIx)>0
      N←∆ N
      :If 0=⊃N ⋄ x←N ⋄ :EndIf
      :If ¯1=⊃N ⋄ err eSQRT ⋄ :EndIf

    ⍝ If the # N is small, calculate via APL
      ndig←≢⊃⌽N
      :If 1=ndig ⋄ x←1(⌊0.5*⍨⊃⌽N) ⋄ :Return ⋄ :EndIf

    ⍝ Initial estimate for N*0.5 must be ≥ the actual solution, else this will terminate prematurely.
    ⍝ Initial x: ¯1+10*⌈(# dec digits in N)÷2 <== DECIMAL.     2*⌈(numbits(N)÷2) <=== BINARY.

      x←{
          0::1((⌈0.5*⍨⊃⊃⌽N),(RX-1)⍴⍨⌈0.5×ndig-1)   ⍝ Alt: Estimate from # of Base-RX digits in <data>.
          ⎕FR←1287
        ⍝ Alternative: ∆ '9'⍴⍨ ⌈0.5÷⍨≢exp ⍵        ⍝ Est from decimal:  works for all ⍵
          ∆ 1+⌈0.5*⍨⍎exp ⍵                         ⍝ Est from APL: works for ⍵ ≤ ⌊/⍬
      }N

      :While 1
          y←(x plus N divide x)divide 2       ⍝ y is next guess: y←⌊((x+⌊(N÷x))÷2)
          :If y ge x ⋄ :Leave             ⍝ Is y not smaller than x? Done
          :EndIf
          x←y                            ⍝ y is smaller than x. Make x ← y and try another.
      :EndWhile
    ∇
  ⍝ oneDiv:  ÷⍵ ←→ 1÷⍵ Almost useless, since ÷⍵ is 0 unless ⍵ is 1 or ¯1.
    oneDiv←{{0=≢⍵: ÷0 ⋄ 1≠≢⍵:0 ⋄ 1=|⍵:⍵ ⋄ 0}dlzs ⍵}

    :Endsection BI Monadic Functions/Operands
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Dyadic Functions/Operations
  ⍝ dyad:    compute all supported dyadic functions
  ⍝ The first name will be the APL std name (exceptions noted), followed by
  ⍝ abbreviations and common alternatives.
  ⍝ E.g. dyadic | is called  residue, but we also define mod/ulo as residue⍨.

      plus←{
          (sa a)(sw w)←⍺ ∆ ⍵
          sa=0:sw w                           ⍝ optim: ⍺+0 → ⍺
          sw=0:sa a                           ⍝ optim: 0+⍵ → ⍵
          sa=sw:sa(ndnZ 0,+⌿a mix w)       ⍝ 5 + 10 or ¯5 + ¯10
          sa<0:sw w minus 1 a              ⍝ Use unsigned vals: ¯10 +   5 → 5 - 10
          sa a minus 1 w                   ⍝ Use unsigned vals:   5 + ¯10 → 5 - 10
      }
    add←plus
      minus←{
          (sa a)(sw w)←⍺ ∆ ⍵
          sw=0:sa a                            ⍝ optim: ⍺-0 → ⍺
          sa=0:(-sw)w                          ⍝ optim: 0-⍵ → -⍵

          sa≠sw:sa(ndnZ 0,+⌿a mix w)          ⍝ 5-¯3 → 5+3 ; ¯5-3 → -(5+3)
          a ltU w:(-sw)(nupZ-⌿dck w mix a)      ⍝ 3-5 →  -(5-3)
          sa(nupZ-⌿dck a mix w)                ⍝ a≥w: 5-3 → +(5-3)
      }
    subtract←minus
    sub←minus

      times←{
          (sa a)(sw w)←⍺ ∆ ⍵
          0∊sa,sw:0 ZEROd
          ONEd≡a:(sa×sw)w
          ONEd≡w:(sa×sw)a
          (sa×sw)(a mulU w)
      }
    mul←times
      divide←{
          (sa a)(sw w)←⍺ ∆ ⍵
          (sa×sw)(⊃a divU w)
      }
    div←divide
      divideRem←{
          (sa a)(sw w)←⍺ ∆ ⍵
          div rem←a divU w
          ((sa×sw)(div))(1 rem)
      }
    divRem←divideRem
      power←{
          (sa a)(sw w)←⍺ ∆ ⍵
          sw=¯1:0 ZEROd            ⍝ ⍺*¯⍵ is <1, so truncates to 0.
          p←a powU w
          sa≠¯1:1 p                ⍝ sa= 1 (can't be 0).
          0=2|⊃⌽w:1 p              ⍝ ⍺ is neg, so result is pos. if ⍵ is even.
          ¯1 p
      }
    pow←power
      residue←{                    ⍝ residue. THIS FOLLOWS APL'S DEFINITION…
          (sa a)(sw w)←⍺ ∆ ⍵
          sw=0:ZEROd
          sa=0:sw w
          r←a remU w               ⍝ r: remainder
          sa=sw:sa r               ⍝ sa=sw: return r       (r: signed)
          sa a minus sa r          ⍝ sa≠sw: return (a - r) (r: signed)
      }
    modulo←{⍵ residue ⍺}
    mod←modulo

    ⍝ times10: Shift ⍺:BIx left or right by ⍵:Int decimal digits.
    ⍝      Converts ⍺ to BIc, since shifts are a matter of appending '0' or removing char digits from right.
    ⍝  r:BIx ← ⍺:BIi   ∇  ⍵:Int
    ⍝     Note: ⍵ must be an APL integer (<RX).
    ⍝  -  If ⍵>0: shift ⍺ left by ⍵-decimal digits
    ⍝  -  If ⍵<0: shift ⍺ rght by ⍵ decimal digits
    ⍝  -  If ⍵=0: then ⍺ will be unchanged
      times10←{
          (sa a)(sw w)←⍺ ∆ ⍵
          1≠≢w:err eTIMES10                        ⍝ ⍵ must be small integer.
          sa=0:0 ZEROd                             ⍝ ⍺ is zero: return 0.
          sw=0:sa a                                ⍝ ⍵ is zero: ⍺ stays as is.
          ustr←export 1 a                          ⍝ ⍺ as unsigned string
          ss←'¯'/⍨sa=¯1                            ⍝ sign as string
          sw=1:∆ ss,ustr,w⍴'0'
          ∆{0=≢⍵:,'0' ⋄ ⍵}(w×sw)↓ustr
      }
    mul10←times10

    ⍝ ∨ Greatest Common Divisor
      gcd←{
          (sa a)(sw w)←⍺ ∆ ⍵
          1(a gcdU w)
      }
    ⍝ ∧ Lowest Common Multiple
      lcm←{
          (sa a)(sw w)←⍺ ∆ ⍵
          (sa×sw)(a lcmU w)
      }

    ⍝ fxBool-- generate Boolean functions lt <, le ≤, eq =, ge ≥, gt >, ne ≠
    ∇ {r}←fxBool(NAME SYM);model;∆NAME
      ∆NAME←{
        ⍝ ⍺ ∆NAME ⍵: emulates (⍺ ∆SYM ⍵)
        ⍝ ⍺, ⍵: Both are external-format BigIntegers (BIx)
          (sa a)(sw w)←⍺ ∆ ⍵
          0∊sa sw:sa ∆SYM sw        ⍝ ⍺, ⍵, or both are 0
          sa≠sw:sa ∆SYM sw          ⍝ ⍺, ⍵ different signs
          sa=¯1:∆SYM cmp w mix a    ⍝ ⍺, ⍵ both neg
          ∆SYM cmp a mix w          ⍝ ⍺, ⍵ both pos
      }
      :If 0=1↑0⍴r←⎕THIS.⎕FX'∆NAME' '∆SYM'⎕R NAME SYM⊣⎕NR'∆NAME'
          ⎕←'LOGIC ERROR: unable to create boolean function: ',NAME,' (',SYM,')'
      :EndIf
    ∇
    fxBool¨ ('lt' '<')('le' '≤')('eq' '=')('ge' '≥')('gt' '>')('ne' '≠')
    ⎕EX 'fxBool'

    :EndSection BI Dyadic Operands/Functions
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Unsigned Utility Math Routines

    ⍝ mulU:  multiply ⍺ × ⍵  for unsigned BIi ⍺ and ⍵
    ⍝ r:BIi ← ⍺:BIi ∇ ⍵:BIi
    ⍝ This is dfns:nats mul.
    ⍝ It is faster than dfns:xtimes (FFT-based algorithm)
    ⍝ even for larger numbers (up to xtimes smallish design limit)
    ⍝ We call ndnZ to remove extra zeros, esp. so zero is exactly ,0 and 1 is ,1.
      mulU←{
          ⍺{                                      ⍝ product.
              ndnZ 0,↑⍵{                       ⍝ canonicalised vector.
                  digit take←⍺                    ⍝ next digit and shift.
                  +⌿⍵ mix digit×take↑⍺⍺           ⍝ accumulated product.
              }/(⍺,¨(≢⍵)+⌽⍳≢⍺),⊂,0                ⍝ digit-shift pairs.
          }{                                      ⍝ guard against overflow:
              m n←,↑≢¨⍺ ⍵                         ⍝ numbers of RX-digits in each arg.
              m>n:⍺ ∇⍨⍵                           ⍝ quicker if larger number on right.
              n<OFL:⍺ ⍺⍺ ⍵                       ⍝ ⍵ won't overflow: proceed.
              s←⌊n÷2                              ⍝ digit-split for large ⍵.
              p q←⍺∘∇¨(s↑⍵)(s↓⍵)                  ⍝ sub-products (see notes).
              ndnZ 0,+⌿(p,s↓n⍴0)mix q          ⍝ sum of sub-products.
          }⍵
      }
   ⍝ powU: compute ⍺*⍵ for unsigned ⍺ and ⍵. (⍺ may not be omitted).
   ⍝       Returns 1 (a*⍵) if even power, else 0(⍺*⍵).
   ⍝       For ⍺*1, returns 0 ⍺, which indicates to caller to use sign sa of left operand ⍺'.
   ⍝
      powU←{                                  ⍝ exponent.
          ⍵≡ZEROd:ONEd                        ⍝ =cmp ⍵ mix,0:,1 ⍝ ⍺*0 → 1
          ⍵≡ONEd:,⍺                           ⍝ =cmp ⍵ mix,1:⍺  ⍝ ⍺*1 → ⍺. Return "odd," i.e. use sa in caller.
          hlf←{,ndn(⌊⍵÷2)+0,¯1↓(RX÷2)×2|⍵}    ⍝ quick ⌊⍵÷2.
          evn←ndnZ{⍵ mulU ⍵}ndn ⍺ ∇ hlf ⍵     ⍝ even power
          0=2|¯1↑⍵:evn ⋄ ndnZ ⍺ mulU evn      ⍝ even or odd power.
      }
   ⍝ divU: unsigned division:
   ⍝ Returns:  (int. quotient) (remainder)
   ⍝           (⌊ua ÷ uw)      (ua | uw)
   ⍝   r:BIi[2] ← ⍺:BIi ∇ ⍵:BIi
      divU←{
          ZEROd≡⍵:⍺{                          ⍝ ⍺÷0
              ZEROd≡⍺:ONEd                    ⍝ 0÷0 → 1 remainder 0
              1÷0                             ⍝ Error message
          }⍵
          svec←(≢⍵)+⍳0⌈1+(≢⍺)-≢⍵              ⍝ shift vector.
          zro∘dlz¨↑⍵{                         ⍝ fold along dividend.
              r p←⍵                           ⍝ result & dividend.
              q←⍺↑⍺⍺                          ⍝ shifted divisor.
              ppqq←RX⊥⍉2 2↑p mix q            ⍝ 2 most signif. digits of p & q.
              r∆←p q{                         ⍝ next RX-digit of result.
                  (p q)(lo hi)←⍺ ⍵            ⍝ div and high-low test.
                  lo=hi-1:p{                  ⍝ convergence:
                      (≥cmp ⍺ mix ⍵)⊃lo hi    ⍝ low or high.
                  }dlz ndn 0,hi×q             ⍝ multiple.
                  mid←⌊0.5×lo+hi              ⍝ mid-point.
                  nxt←dlz ndn 0,q×mid             ⍝ next multiplier.
                  gt←>cmp p mix nxt           ⍝ greater than:
                  ⍺ ∇ gt⊃2,/lo mid hi         ⍝ choose upper or lower interval.
              }⌊0 1+↑÷/ppqq+(0 1)(1 0)        ⍝ lower and upper bounds of ratio.
              mpl←dlz ndn 0,q×r∆              ⍝ multiple.
              p∆←dlz nup-⌿p mix mpl           ⍝ remainder.
              (r,r∆)p∆                        ⍝ result & remainder.
          }/svec,⊂⍬ ⍺                         ⍝ fold-accumulated reslt.
      }

    gcdU←{⍵=,0:⍺ ⋄ ⍵ ∇⊃⌽⍺ divU ⍵}            ⍝ greatest common divisor.
    lcmU←{⍺ mulU⊃⍵ divU ⍺ gcdU ⍵}               ⍝ least common multiple.

    remU←{⊃⌽⍵ divU ⍺}                      ⍝ BIu remainder



    :Endsection BI Unsigned Utility Math Routines
⍝ --------------------------------------------------------------------------------------------------

    :Section BI - Service Routines

    atom←{1=≢⍵:⍬⍴⍵ ⋄ ⍵}                    ⍝ If ⍵ is length 1, treat as a scalar (atom).

  ⍝ …    routines operate on unsigned BIi data unless documented…
    dlz←{(0=⊃⍵)↓⍵}                          ⍝ drop FIRST leading zero.
    zro←{0≠≢⍵:,⍵ ⋄ ,0}                      ⍝ ⍬ → ,0. Converts BIi to BIz, so even 0 has one digit (,0).
    dlzs←{zro(∨\⍵≠0)/⍵}                     ⍝ drop RUN of leading zeros, but [PMS] make sure at least one 0
        ndn←{ +⌿1 0⌽0 RX⊤⍵}⍣≡                   ⍝ normalise down: 3 21 → 5 1 (RH).
    ndnZ←dlz ndn                            ⍝ ndn, then remove (earlier added) leading zero, if still 0.
        nup←{⍵++⌿0 1⌽RX ¯1∘.×⍵<0}⍣≡             ⍝ normalise up:   3 ¯1 → 2 9
    nupZ←dlz nup                            ⍝ PMS
    mix←{↑(-(≢⍺)⌈≢⍵)↑¨⍺ ⍵}                  ⍝ right-aligned mix.
    ltU←{<cmp ⍺ mix ⍵}                      ⍝ unsigned ⍺ < ⍵                 [pms]
    dck←{(2 1+(≥cmp ⍵)⌽0 ¯1)⌿⍵}             ⍝ difference check.
    rep←{10⊥⍵{⍉⍵⍴(-×/⍵)↑⍺}(⌈(≢⍵)÷DRX),DRX}  ⍝ radix RX rep of number.

  ⍝ exp: See BI internal structure
    cmp←{⍺⍺/,(<\≠⌿⍵)/⍵}                       ⍝ compare first different digit.

    :Endsection BI Service Routines
⍝ --------------------------------------------------------------------------------------------------


    :Section Utilities: bi BIB, BIC, BI∆HERE
   ⍝ bi      - simple niladic fn, returns this bigint namespace #.BigInt
   ⍝ bi.dc   - desk calculator
   ⍝ BIB     - Utility to manipulate BIs as arbitrary signed binary numbers
   ⍝ BIC     - Utility to compile code strings or functions with BI arithmetic
   ⍝ BI∆HERE - Utility to compile and run embedded code (stored as comments) on the fly

   ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
   ⍝ Utilities…

  ⍝ bi:  Returns ⎕THIS
    ⎕FX 'ns←bi' 'ns←⎕THIS'

    ⍝ RE∆GET-- ⎕R/⎕S Regex utility-- returns field #n or ''
      RE∆GET←{ ⍝ Returns Regex field ⍵N in ⎕R ⍵⍵ dfn. Format:  f2 f3←⍵ RE∆GET¨2 3
          ⍵=0:⍺.Match ⋄ ⍵≥≢⍺.Offsets:'' ⋄ ¯1=⍺.Offsets[⍵]:'' ⋄ ⍺.(Lengths[⍵]↑Offsets[⍵]↓Block)
      }
   ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
    ∇ {r}←_LoadPats;actBiCallNoQ;actBiCallQ;actKeep;actKeepParen;actQuoted;lD;lM;p2Fancy;p2Funs1;p2Funs2;p2Ints;p2Plain;p2Vars;pAplInt;pCom;pFancy;pFunsBig;pFunsNoQ;pFunsQ;pFunsSmall;pIntExp;pIntOnly;pLongInt;pNonBiCode;pQot;pVar;t1;t2;tD1;tDM;tM1;tMM
   ⍝ fnRep pattern: Match 0 or more lines
   ⍝ between :BI … :EndBI keywords or  ⍝:BI … ⍝:ENDBI keywords
   ⍝ Match   ⍝:BI \n <BI code> … ⍝:EndBI. No spaces between ⍝ and :BI (bad: ⍝ :BI).
   ⍝ \R: any linend.  \N: any char but linend
      pFnRep←'(?i:) ^ (?: \h* ⍝?:BI \b \N*$) (.*?) (?: \R \h* ⍝?:ENDBI \b \N*$)'
   ⍝ Field:    #1                              #2    #3
   ⍝ #1: :BI; #2: text in :BI scope;  #3: text :ENDBI
   ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
   ⍝ actionFnRep: fnRep Action
      actionFnRep←{match←⍵ RE∆GET 1 ⋄ pBiCalls ⎕R actBiCalls⊣match}
   ⍝ fnRep options for ⎕R
      optsFnRep←('Mode' 'M')('EOL' 'LF')('IC' 1)('UCP' 1)('DotAll' 1)
   ⍝ fnRep call - expects string vector(s) as from ⎕NR name
      matchFnRep←{pFnRep ⎕R actionFnRep⍠optsFnRep⊣⍵}
   ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
   ⍝ BI (Big Integer) patterns
   ⍝ …p2: Pattern building blocks
      p2Vars←'\p{L}_∆⍙'
       ⍝ Decode list…Fns.
       ⍝ [0] are single char fns   '+-⌽?'      → [+\-⌽\?]
       ⍝ [1] are multiple char fns 'aaa' 'bbb' → ('aaa' | 'bbb') etc.
       ⋄ tD1 tDM←listDyadFns
       ⋄ tM1 tMM←listMonadFns
       ⋄ t1←tD1{'[\-\?]'⎕R'\\\0'⊣∪⍺,⍵}tM1      ⍝ Escape expected length-1 special symbols
       ⋄ t2←¯1↓∊(tDM,tMM),¨'|'
      p2Funs1←'(?:⍺⍺|⍵⍵)'                      ⍝ See pFunsSmall.
      p2Funs2←'(?:[',t1,']|\b(?:',t2,')\b)'    ⍝ See pFunsBig. Case is respected for MUL10, SQRT…

      ⍝ …P:  Patterns. Most have a field#1
      pCom←'(⍝.*?)$'                           ⍝ Keep comments as is
      pVar←'([',p2Vars,'][',p2Vars,'\d]*)'     ⍝ Keep variable names as is, except MUL10 and SQRT
      pQot←'((?:''[^'']*'')+)'                 ⍝ Keep quoted numbers as is and anything else quoted
      pFunsNoQ←'(',p2Funs1,'(?!\h*BI))'        ⍝ ⍺⍺, ⍵⍵ operands NOT quoted. → (⍺⍺ BI) (⍵⍵ BI)
      pFunsQ←'(',p2Funs2,'(?!\h*BI))'          ⍝ All fns: APL or named are quoted. Simpler/faster.
                                               ⍝ SQRT → ('SQRT'BI), + → ('+' BI), ditto √ → '√'
      pNonBiCode←'\(:(.*?):\)'                 ⍝ Anything in (: … :) treated as APL

      pIntExp←'([\-¯]?[\d.]+[eE]¯?\d+)'        ⍝ [-¯]4.4E55 will be padded out. Underscores invalid.
      pIntOnly←'([\-¯]?[\d_.]+)'               ⍝ Put other valid BI-format integers in quotes
   ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
   ⍝ BI Actions
   ⍝ …AB: BI (Big Integer) action building-blocks
      actBiCallNoQ←'(\1',(⍕⎕THIS),'.BIX)'       ⍝ See pFunsNoQ above
      actBiCallQ←'(''\1''',(⍕⎕THIS),'.BIX)'     ⍝ See pFunsQ above
      actKeep actKeepParen actQuoted←'\1' '(\1)' '''\1'''
   ⍝ EXTERN pBiCalls:     Full BI (Big Integer) pattern
   ⍝    pFunsBig must precede pVar, so that MUL10 and SQRT will be treated as BI operands…
   ⍝ pAplInt replaced by pFancy-- see NOTE 20181016 below
      pBiCalls←pCom pFunsQ pVar pQot pFunsNoQ pNonBiCode pIntExp pIntOnly
   ⍝ EXTERN actBiCalls:   BI (Big Integer) action
   ⍝ In this version, we quote all APL integers unless they have exponents...
      actBiCalls←actKeep actBiCallQ actKeep actKeep actBiCallNoQ actKeep actKeepParen actQuoted
   ⍝ EXTERN matchBiCalls: BI (Big Integer) matching calls…
      matchBiCalls←{⊃⍣(1=≢res)⊣res←pBiCalls ⎕R actBiCalls⍠('UCP' 1)⊣⊆⍵}
      r←'OK'
    ∇
    _LoadPats


   ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
      BIC←{
          ⍺←1
          DEBUG×99::⎕SIGNAL/⎕DMX.(('BIC: ',EM)EN)
          0=1↑0⍴∊⍵:err eBIC
        ⍝ ⍺ a string, treat as: ⍺,1 BIC ⍵
          0≠1↑0⍴⍺:⍺,matchBiCalls ⍵           ⍝ ⍺ is catenated: as if ⍺,1 BIC ⍵

          ⍺=2:matchFnRep ⎕NR ⍵       ⍝ Compile function named ⍵
          ⍺=¯2:matchFnRep ⍵          ⍝ Compile function whose ⎕NR is ⍵
          ⍺=0:matchBiCalls ⍵         ⍝ Compile string ⍵ and return compiled string
          ⍺=1:((1+⎕IO)⊃⎕RSI,#)⍎matchBiCalls ⍵       ⍝ Compile and execute string ⍵ in CALLER space, returning value of execution
      }

    ∇ dc;caller;code;dc_LAST;dc_in;exec;msg;shy
      msg←⊂'bi.dc - APL format arbitrary precision integer desk calculator'
      msg,←⊂'Type dc_in an APL arithmetic expression containing scalars only.'
      msg,←⊂'   item          where       description'
      msg,←⊂'     ⍵           anywhere    The result of the dc_LAST successful expression (initially 0)'
      msg,←⊂'     ^C          note 1      Exit calculator'
      msg,←⊂'     .           note 1      Exit calculator'
      msg,←⊂'     empty line              Do nothing  '
      msg,←⊂'     ?           note 1      Get help (nothing else on line)'
      msg,←⊂' --------------------------'
      msg,←⊂' note 1: only thing on line (adjacent spaces are ignored).'
      msg,←⊂''
      alert↑msg
      dc_LAST←'0'
      :While 1
          :Trap 1000
              dc_in←⍞↓⍨≢⍞←'> '
              :If 0=≢dc_in~' ' ⋄ :Continue ⋄ :EndIf
              :If ×≢'^\h*(\^[cC]|\.)\h*$'⎕S 0⊣dc_in
                  :Return
              :ElseIf (,'?')≡dc_in~' '  ⍝ ? alone → help...
                  BIC_HELP ⋄ :Continue
              :EndIf
              :Trap 0
                  caller←(1+⎕IO)⊃⎕RSI,#
                  code←0 BIC dc_in                                 ⍝ ('\w'⎕S'\0')
                  exec←{⍵⍵:⍺⍎⍺⍺ ⋄ ⊢⎕←⍺⍎⍺⍺}                         ⍝ ⍎ sees ⍵←dc_LAST
                  shy←×≢('^\(?(\w+(\[[^]]*\])?)+\)?←'⎕S 1⍠'UCP' 1)⊣code~' ' ⍝ Kludge to see if code has an explicit result.
                  dc_LAST←caller(code exec shy)dc_LAST
              :Else
                  ⎕←{
                      dm0 dm1 dm2←⍵.DM
                      p←1+dm1⍳']' ⋄ (p↑dm1)←' '
                      ↑dm0 dm1(' ',dm2)
                  }⎕DMX
              :EndTrap

          :Else
     interrupt:
              l←≢⍞←'Interrupted. Exit? Y/N [Yes] '
              :If ~1∊'nN'∊l↓⍞ ⋄ :Return ⋄ :EndIf
          :EndTrap
      :EndWhile
    ∇

    ∇ {html}←{fmt}alert msg;FMTjs

      html←'<!DOCTYPE HTML><html><body><p></p><script>'
      html,←'alert(''⍞ALERT⍞'');</script><p></p></body></html>'   ⍝ ⍞ALERT⍞ replaced by string modified from <msg>
      FMTjs←{⍺←⊢ ⋄ ⎕IO←0
          hexD←⎕D,'ABCDEF'
          avoid←'%''"&\'                               ⍝ We encode via \x, noting in theory % can be encoded as \%, etc.
          safe←(⎕UCS 32+⍳256-32)~avoid                 ⍝ safe: (⎕UCS 32-255) avoiding % ' " & and \
          c2hjs←{                                      ⍝ encode hex in js format as compactly as possible
              2≥≢⍵:'\\x',¯2↑'00',⍵
              4≥≢⍵:'\\u',¯4↑'0000',⍵
              '\\u{',⍵,'}'                             ⍝ 6 digits max, e.g. 5 for '💩' poo(p)
          }∘{hexD[16⊥⍣¯1⊣⎕UCS ⍵]}¨                     ⍝ returns minimal hex digits for each char passed.
                                                  ⍝ ⍵: an APL object in the domain of ⎕FMT.
          msg←¯1↓,(⍺ ⎕FMT ⍵),⎕UCS 13                   ⍝ msg: map ⍵ to a flat char. vector with line separators.

          unsafe←~msg∊safe                             ⍝ unsafe: 0 or more chars to be encoded.
          av←msg∊avoid
          (unsafe/msg)←c2hjs unsafe/msg                ⍝ msg: map unsafe char scalars to enclosed strings.
          ∊msg                                         ⍝ msg: flattened down again
      }

      :If 0=⎕NC'fmt' ⋄ fmt←⊢ ⋄ :EndIf

      html←'⍞ALERT⍞'⎕R(fmt FMTjs msg)⊣html
                                                  ⍝ Run in own thread so alert window stays open after fn exit.
      ns←#.⎕NS''                                 ⍝ Run renderer in anonymous namespace in user space-- don't clutter user space...
      ns.{'ignored'⎕WC'HTMLRenderer'⍵('Size'(0 0))}&html  ⍝ Size (0 0): makes extra renderer window invisible
    ∇

      BIB←{
          DEBUG×99::⎕SIGNAL/⎕DMX.(EM EN)
          ⍺←⊢
          1≡⍺ 1:⊥BI ⍺⍺⊤BI ⍵
          ⊥BI ⍺⍺⌿↑⊤BI¨⍺ ⍵   ⍝ Padding on right (High order bits)
      }

    eBIHFAILED←'BI∆HERE failed: unable to run compiled BI code'
    eBIHBADCALL←'BI∆HERE not called from active traditional fn'
    ∇ callback←BI∆HERE;callerCode;callerNm;cloneNm;opt;pat;RE∆GET;⎕TRAP
      ⍝ See BI∆HERE_HELP
      ⎕TRAP←0 'C' '⎕SIGNAL/⎕DMX.(EM EN)'
      (2>≢⎕SI)err eBIHBADCALL
      RE∆GET←{ ⍝ Returns Regex field ⍵N in ⎕R ⍵⍵ dfn. Format:  f2 f3←⍵ RE∆GET¨2 3
          ⍵=0:⍺.Match ⋄ ⍵≥≢⍺.Offsets:'' ⋄ ¯1=⍺.Offsets[⍵]:'' ⋄ ⍺.(Lengths[⍵]↑Offsets[⍵]↓Block)
      }

      opt←('Mode' 'M')('EOL' 'LF')('IC' 1)('UCP' 1)('DotAll' 1)
      pat←'^ (?: \h* ⍝?:BI \b \N*$) (.*?) (?: \R ⍝?:ENDBI \b \N*$)'~' '
      callerCode←(1+⎕LC⊃⍨1+⎕IO)↓⎕NR callerNm←⎕SI⊃⍨1+⎕IO

      cloneNm←callerNm,'__BigInteger_TEMP'
      callback←cloneNm,' ⋄ →0'
    ⍝ The callback will call the caller function (cloned) starting after the BI∆HERE,
    ⍝ starting with a statement to erase the clone
      :Trap 0
          :If 0=1↑0⍴⎕FX(⊂cloneNm),(⊂'⎕EX ''',cloneNm,''''),(¯1 BIC callerCode)
              err eBIHFAILED
          :EndIf
      :Else
          err eBIHFAILED
      :EndTrap
    ∇
    :Endsection BIC, BIB, and BI∆HERE  Routines  -----------------------------------------------------------
    :Section Documentation
    ⍝ See bigIntHelp
    ∇ HELP
      ##.bigIntHelp.HELP
    ∇
    ∇ help
      ##.bigIntHelp.HELP
    ∇
    ∇ Help
      ##.bigIntHelp.HELP
    ∇
    ∇ BI_HELP
      ##.bigIntHelp.BI_HELP
    ∇
    ∇ BIB_HELP
      ##.bigIntHelp.BIB_HELP
    ∇
    ∇ BIC_HELP
      ##.bigIntHelp.BIC_HELP
    ∇
    ∇ BI∆HERE_HELP
      ##.bigIntHelp.BI∆HERE_HELP
    ∇

    :EndSection Documentation   -------------------------------------------------------------------------

    :Section Bigint Namespace - Postamble
        ssplit←{⍵[⍋↑⍵]}{⍵⊆⍨' '≠⍵}     ⍝ ssplit: split and sort space-separated words...
    _←0 ⎕EXPORT ⎕NL 3 4
    _←1 ⎕EXPORT ssplit 'bi BI BIB BIX BIB_HELP BIC BI∆HERE BIC_HELP BI_HELP BI∆HERE_HELP HELP RE∆GET'

    ⎕PATH←⎕THIS{0=≢⎕PATH:⍕⍺⊣⎕← '⎕PATH was null. Setting to ''',(⍕⍺),''''⋄ ⍵}⎕PATH

    note 'For help, type bi.HELP'
    note '¯¯¯ ¯¯¯¯¯ ¯¯¯¯ ¯¯¯¯¯¯¯'
    note 'To access bigInt functions directly, use bi (lower-case)  as shortcut to bigInt namespace:'
    note '    10 bi.plus 3 bi.times 9'
    note '    bi.dc    - big integer desk calculator'

    fns1←ssplit 'bitsIn bitsOut direction signum sig export exp factorial fact negate neg reciprocal roll'
    fns2←'divide div divide2 div2 gcd lcm magnitude abs minus subtract sub plus'
    fns2←ssplit fns2,' add times mul power pow residue modulo mod times10 mul10 divide10 div10'

    note 50⍴'-'⋄ note'  MONADIC FUNCTIONS' ⋄ note 50⍴'¯' ⋄ note ↑fns1
    note 50⍴'-'⋄ note'  DYADIC FUNCTIONS ' ⋄ note 50⍴'¯' ⋄ note ↑fns2
    note 50⍴'-'
    note'Exporting…'⊣⎕EX '_' 'ssplit'
    note{(⎕EXPORT ⍵)⌿⍵}⎕NL 3 4
    note'*** ',(⍕⎕THIS),' initialized. See ',(⍕⎕THIS),'.HELP'
    note 50⍴'-'

    :EndSection Bigint Namespace - Postamble

:EndNamespace
