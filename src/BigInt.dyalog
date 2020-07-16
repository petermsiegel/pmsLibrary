:namespace BigInt
  ⍝   Based on dfns::nats, restructured for signed integers. Faster than dfns::big.
  ⍝   See older BigInt_BIG, with more customization.
  ⍝   This version is tighter, smaller, and decreases visible local_fns like bi.add.
  ⍝   I.e. it assumes users will use the BI and BIX operators: 
  ⍝        YES:   3 +BI 2         NO:  3 bi.add 2
  ⍝   Binary routines were removed. APL intrinsically handles large bit arrays better...
  ⍝
  ⍝ ∘ NOTE: See BigIntHelp for details..
  ⍝         Call BigInt.help or edit 'BigIntHelp'

  ⍝ Table of Contents
  ⍝   Preamble
  ⍝      Preamble Utilities 
  ⍝      Preamble Variables
  ⍝   BI/BII
  ⍝      BigInt Namespace and Utility Initializations
  ⍝      Executive: BI, BII, BIM, bi
  ⍝               Syntax               Returning                 Non-BI Equivalent   Comment
  ⍝         BI:   [l] ×BI r            external-format BigInt    l × r   ?r
  ⍝         BII:  [l] ×BII r           internal-format BigInt    l × r   ?r
  ⍝         BIM:  [l] ×BIM r⊣ m        external-format           m | l × r           Modulo
  ⍝         BIC:  BIC 'a×b+c*2'        external-format           a×b+c*2             APL Math -> BigInt
  ⍝      BigInt internal structure
  ⍝      Monadic Operands/Functions for BII, BI, BIM
  ⍝      Dyadic Operands/Functions for BII, BI, BIM
  ⍝      Directly-callable Functions ⍵⍵ via bi.⍵⍵.
  ⍝      BI Special Functions/Operations (More than 2 Args)
  ⍝      Unsigned Utility Math Routines
  ⍝      Service Routines
  ⍝  Utilities
  ⍝      bi (returns the BigInt namespace, as long as <bi> itself is in ⎕PATH)
  ⍝      bi.dc (desk calculator)
  ⍝      BIB (bit manipulation) - under construction...
  ⍝      BIC (BI math "compiler")
  ⍝      BI∆HERE (self-declared BI math function)-- allows comment lines for code lines to be passed through BIC.
  ⍝  Postamble
  ⍝      Exported and non-exported Utilities
  ⍝   ----------------------------------
  ⍝   INTERNAL-FORMAT BIs (BigInts)
  ⍝   ----------------------------------
  ⍝    BIint  -internal-format signed Big Integer numeric vector:
  ⍝          sign (data) ==>  sign (¯1 0 1)   data (a vector of integers)
  ⍝          ∘ sign: If data is zero, sign is 0 by definition.
  ⍝          ∘ data: Always 1 or more integers (if 0, it must be data is ,0).
  ⍝                  Each element is a positive number <RX10 (10E6)
  ⍝    Given the canonical requirement, a BIint of 0 is (0 (,0)), 1 is (1 (,1)) and ¯1 is (¯1 (,1)).
  ⍝
  ⍝    BIu  -unsigned internal-format BIint (vector of integers):
  ⍝          ∘ Consists solely of the data vector (2nd element) defined for BIint.
  ⍝
  ⍝   EXTERNAL-FORMAT BIs (BigInts)
  ⍝    BIext  -ON INPUT
  ⍝          an external-format Big Integer on input, i.e. a character string as entered by the user.
  ⍝          a BIext has these characteristics:
  ⍝          ∘ char. vector or scalar   ∘ leading ¯ or - prefix for minus, and no prefix for plus.
  ⍝          ∘ otherwise, only the digits 0-9 plus optional use of _ to space digits.
  ⍝          ∘ If no digits (''), it represents 0.
  ⍝          ∘ spaces are disallowed, even leading or trailing.
  ⍝    BIc  -ON OUTPUT
  ⍝          a canonical (normalized) external-format BIext string returned has a guaranteed format:
  ⍝          ∘ char. vector     ∘ leading ¯ ONLY for minus.
  ⍝          ∘ otherwise, only the digits 0-9. No underscores, spaces, or hyphen - for minus.
  ⍝          ∘ leading 0's are removed.
  ⍝          ∘ 0 is represented by (,'0'), unsigned with no extra '0' digits.
  ⍝   OTHER TYPES
  ⍝    Int   -an APL-format single small integer ⍵, often specified to be in range ⍵<RX10 (the internal radix).  
  ⍝ --------------------------------------------------------------------------------------------------

    :Section BI
    :Section PREAMBLE
    HELP_FILES_SRC←'/Users/petermsiegel/MyDyalogLibrary/pmsLibrary/src/BigIntHelp'   ⍝ Where are help files?
    DEBUG←0              ⍝ Set DEBUG here.
    VERBOSE←DEBUG        ⍝ Set VERBOSE here.
    ∆ERR←DEBUG↓0         ⍝ Trap ALL only if DEBUG...

⍝   -----
    ⎕IO ⎕ML←0 1 ⋄  ⎕PP←34 ⋄ ⎕CT←⎕DCT←0 ⋄ ⎕CT←1E¯14 ⋄ ⎕DCT←1E¯28
    ⎕FR←645          ⍝ For ⎕FR,  see below
  
    err←11∘(⎕SIGNAL⍨)

    :EndSection PREAMBLE

    :Section Namespace and Utility Initializations
  ⍝+------------------------------------------------------------------------------+⍝
  ⍝+-- BI INITIALIZATIONS                            BI INITIALIZATIONS         --+⍝
  ⍝-------------------------------------------------------------------------------+⍝
 
  ⍝ Set key bigInt constants...
    ⎕FR←             645
    NRX2←            20                                  ⍝ Num bits in a "hand"
    NRX10←           ⌊10⍟RX2←2*NRX2                      ⍝ Max num of dec digits in a hand
    NRX2BASE←        NRX2⍴2                              ⍝ Encode/decode binary base
    RX10BASE←        NRX10⍴10                            ⍝ Encode/decode decimal base    
    RX10←            10*NRX10                            ⍝ Actual base for each hand (each hand ⍵ < RX10)
    RX10div2←        RX10÷2                              ⍝ Sqrt of each hand's base, for use in <pow> (power).
    OFL←             {⌊(2*⍵)÷RX10×RX10}(⎕FR=1287)⊃53 93  ⍝ Overflow bits for use in mulU (unsigned multiply)
 
  ⍝ Data field (unsigned) constants
    zero_D ← ,0                                          ⍝ data field ZERO, i.e. unsigned canonical ZERO
    one_D ←  ,1                                          ⍝ data field ONE, i.e. unsigned canonical ONE
    two_D ←  ,2                                          ⍝ data field TWO
    ten_D ← ,10

  ⍝ BigInt Internal CONSTANTS for users and utilities.
    zero_BI←     0 zero_D                                ⍝  0
    one_BI←      1 one_D                                 ⍝  1
    two_BI←      1 two_D                                 ⍝  2
    minus1_BI←  ¯1 one_D                                 ⍝ ¯1
    ten_BI←      1 ten_D                                 ⍝ 10

  ⍝ Error messages. All will be used with fn <err> and ⎕SIGNAL 911: BigInt DOMAIN ERROR
    eBADBI   ←'Importing Invalid BigInteger'
    eNONINT  ←'Importing Invalid BigInteger: APL number not a single integer: '
    eSMALLRT ←'Right argument must be a small APL integer ⍵<',⍕RX10
    eCANTDO1 ←'Monadic function not implemented as BI operand: '
    eCANTDO2 ←'Dyadic function not implemented as BI operand: '
    eIMPORT  ←'Importing invalid object'
    eINVALID ←'Format of big integer is not valid: '
    eFACTOR  ←'Factorial (!) argument must be ≥ 0'
    eBADRAND ←'Roll (?) argument must be integer >0'
    eSQRT    ←'sqrt: arg must be non-negative'
    eMUL2    ← eSMALLRT
    eMUL10   ← eSMALLRT
    eBIC     ←'BIC argument must be a fn name or one or more code strings.'
    eBADRANGE←'Big integer exponent too large to be represented in APL (±1E6145)'
    eBOOL    ←'Boolean arg imported (⊥) must be ∊ 1 0 ''1'' ''0'''
  

    :EndSection Namespace and Utility Initializations

    :Section Executive
    ⍝ --------------------------------------------------------------------------------------------------

    ⍝ monadFnsList   [0] single-char symbols [1] multi-char names
    ⍝ dyadFnsList    ditto
    ⍝ Both required for BIC to function, so keep the lists complete!
    monadFnsList←'-+|×÷<>≤≥!?⊥⊤⍎→√~⍳'('SQRT' 'NOT')
    ⍝            reg. fns       boolean  names   [use Upper case here]
    dyadFnsList←('+-×*÷⌊⌈|∨∧⌽↑↓√≢~','<≤=≥>≠⍴')('*∘÷' '*⊢÷' 'ROOT' 'SHIFTD' 'SHIFTB'  'DIVREM' 'MOD' 'MODMUL' 'MMUL')

    ⍝ BII: Basic utility operator for using APL functions in special BigInt meanings.
    ⍝     BIint ← ∇ ⍵:BIext
    ⍝     Returns BIint, an internal format BigInteger structure (sign and data, per above).
    ⍝     See below for exceptions ⊥ ⊤ ⍎
    ⍝ BI:Basic utility operator built on BII.
    ⍝     BIext ← ∇ ⍵:BIext
    ⍝     Returns BIext, an external string-format BigInteger object ("[¯]\d+").

    ⍝ Note: __BI_SOURCE__ is placeholder text to be replaced by cover function names BI or BII.
    ⍝ Note: __EXP__ is placeholder text (a pseudo-macro) to be replaced by export or null for BI and BII cover functions.

⍝ --------------------------------------------------------------------------------------------------
    getOpName←{aa←⍺⍺ ⋄ 3=⎕NC'aa':⍕⎕CR'aa' ⋄ 1(819⌶)aa}
    ⍝ __BI_SOURCE__ is a template for ops BII and BI.
      __BI_SOURCE__←{⍺←⊢
          ∆ERR::⎕SIGNAL/⎕DMX.(EM EN)
          ∆QT←{q←'''' ⋄ q,q,⍨⍵}
          fn monad inv←(1≡⍺ 1){'⍨'=¯1↑⍵:(¯1↓⍵)0(1+⍺) ⋄ ⍵ ⍺ 0}⍺⍺ getOpName ⍵
        ⍝ CASE←1∘∊(atom fn)∘≡∘⊆¨∘⊆       ⍝ CASE ⍵1 or CASE ⍵1 ⍵2...
          CASE←(atom fn)∘∊∘⊆  
        ⍝ Monadic...
          monad:{                                      ⍝ BI: __EXP__: See Build BI/BII below.
              CASE'-':__EXP__       neg ⍵              ⍝     -⍵
              CASE'+':__EXP__       ∆ ⍵                ⍝     canon: ensures ⍵ is valid. Returns in canonical form.
              CASE'|':__EXP__       abs ⍵              ⍝     |⍵
              CASE'×':__EXP__       ⊃∆ ⍵               ⍝     signum      Returns APL int (∊¯1 0 1), not BII.
              CASE'÷':__EXP__       recip ⍵            ⍝     inverse     Why bother? Mostly 0!
              CASE'<':__EXP__       dec ⍵              ⍝     decrement   Optimized for constant in ⍵-1. 
              CASE'≤':__EXP__       dec ⍵              ⍝     decrement   I prefer <, but J prefers ≤
              CASE'>':__EXP__       inc ⍵              ⍝     increment   Optimized for constant in ⍵+1. I
              CASE'≥':__EXP__       inc ⍵              ⍝     increment   I prefer >, but J prefers ≥
              CASE'!':__EXP__       fact ⍵             ⍝     factorial   For smallish integers ⍵≥0
              CASE'?':__EXP__       roll ⍵             ⍝     roll        For int ⍵>0 (0 invalid: result would always truncate to 0)
              CASE'≢':              +/1=bitsExport ⍵   ⍝     popcount:   # 1 bits in the bigint in bits format, including the sign bit (1=neg)
              CASE'⍎':              ∆2Apl ⍵            ⍝     aplint      If in range, returns a std APL number; else error               
              CASE'⍕':              prettify exp ∆ ⍵   ⍝     pretty      Returns a pretty BII string: - for ¯, and _ separator every 5 digits.
              CASE'SQRT' '√':       exp  qrt ⍵         ⍝     sqrt        See dyadic *0.5
              CASE'⍳':              ⍳importSmallInt ⍵  ⍝     iota ⍵      Allow only small integers... Returns a set of APL integers
              CASE'→':              ∆ ⍵                ⍝     internal    Return ⍵ in internal form. 
              CASE'⊥':__EXP__       bitsImport ⍵       ⍝     bitsImport  Convert bits to bigint
              CASE'⊤':              bitsExport ⍵       ⍝     bitsExport  Convert bigint ⍵ to bits: sign bit followed by unsigned bit equiv to ⍵
              CASE '~':__EXP__      bitsImport ~ bitsExport ⍵  ⍝  Reverses all the bits in a bigint (why?)
              err eCANTDO1,∆QT fn                      ⍝     Not found.
          }⍵
      ⍝ Dyadic...
        ⍝ See discussion of ⍨ above...
          ⍺{
            ⍝ High Use: [Return BigInt]
              CASE'+':__EXP__        ⍺ add ⍵
              CASE'-':__EXP__        ⍺ sub ⍵
              CASE'×':__EXP__        ⍺ mul ⍵
              CASE'÷':__EXP__        ⍺ div ⍵            ⍝ Integer divide: ⌊⍺÷⍵
              CASE'*':__EXP__        ⍺ pow ⍵            ⍝ Power / Roots I.    num *BI  ÷r
              CASE'*∘÷' '*⊢÷':__EXP__ ⍵ root ⍺          ⍝         Roots II.   num *∘÷BI r
              CASE'√' 'ROOT':__EXP__ ⍺ root ⍵           ⍝         Roots III.  r ('ROOT'BI) num
     
        ⍝ ↑ ↓ Decimal shift (mul, div by 10*⍵)
        ⍝ ⌽   Binary shift  (mul, div by 2*⍵)
              CASE'↑':__EXP__        ⍵ mul10Exp ⍺               ⍝  ⍵×10*⍺,   where ±⍺. Decimal shift.
              CASE'↓':__EXP__        ⍵ mul10Exp-⍺               ⍝  ⍵×10*-⍺   where ±⍺. Decimal shift right (+) or left (-).
              CASE'⌽':__EXP__        ⍵ mul2Exp ⍺                ⍝  ⍵×2*⍺     where ±⍺. Binary shift left (+) or right (-).
     
              CASE'|':__EXP__        ⍺ rem ⍵                    ⍝ remainder: |   (⍺ | ⍵) <==> (⍵ modulo a)
        ⍝ Logical: [Return single boolean, 1∨0]
              CASE'<':               ⍺ lt ⍵
              CASE'≤':               ⍺ le ⍵
              CASE'=':               ⍺ eq ⍵
              CASE'≥':               ⍺ ge ⍵
              CASE'>':               ⍺ gt ⍵
              CASE'≠':               ⍺ ne ⍵     
        ⍝ gcd/lcm: [Return BigInt]                             ⍝ ∨, ∧ return bigInt.
              CASE'∨' 'GCD':__EXP__  ⍺ gcd ⍵                   ⍝ ⍺∨⍵ as gcd.
              CASE'∧' 'LCM':__EXP__  ⍺ lcm ⍵                   ⍝ ⍺∧⍵ as lcm.
     
              CASE'MOD':__EXP__      ⍵ rem ⍺                   ⍝ modulo:  Same as |⍨
              CASE'SHIFTB':__EXP__   ⍺ mul2Exp ⍵               ⍝ Binary shift:  ⍺×2*⍵,  where ±⍵.   See also ⌽
              CASE'SHIFTD':__EXP__   ⍺ mul10Exp ⍵              ⍝ Decimal shift: ⍺×10*⍵, where ±⍵.   See also ↑ and ↓.
              CASE'DIVREM':__EXP__   ¨⍺ divRem ⍵               ⍝ Returns pair:  (⌊⍺÷⍵) (⍵|⍺)
              CASE'MODMUL' 'MMUL':__EXP__ ⍺ modMul ⍵           ⍝ ⍺ modMul ⍵0 ⍵1 ==> ⍵1 | ⍺ × ⍵0.
              CASE'⍴':               (importSmallInt ⍺)⍴⍵      ⍝ Standard ⍴: Requires ⍺ in ⍺ ⍴ ⍵ to be in range of APL int.
              err eCANTDO2,∆QT fn                              ⍝ Not found!
          }{2=inv:⍵ ⍺⍺ ⍵ ⋄ inv:⍵ ⍺⍺ ⍺ ⋄ ⍺ ⍺⍺ ⍵}⍵               ⍝ Handle ⍨.   inv ∊ 0 1 2 (0: not inv, 1: inv, s2: elfie)
      }

    ⍝ BIM:     Biginteger modulo operation:  x ×BIM y ⊣ mod.
    ⍝          Multiply × handled as special case:   x modMul (y mod)
    ⍝          Otherwise (naively):                  mod |BI x ⍺⍺ BII y
    ⍝ BIM:     res ← [LA:⍺] OP:⍺⍺ BIM RA:⍵⍵ ⊣ MOD:⍵   ==>    MOD:⍵ |BI [LA:⍺] OP:⍺⍺ BII RA:⍵⍵
    ⍝ Perform  res ← LA OP RA (Modulo ⍵)  <==>  ⍺ ⍺⍺ BI ⍵ (Modulo ⍵⍵)
 
      BIM←{
          ⍺←⊢ ⋄ fn←atom ⍺⍺ getOpName ⍬ ⋄ fn≡'×':export ⍺ modMul(⍵⍵ ⍵) ⋄ ⍵|BI ⍺(⍺⍺ BII)⍵⍵
      }

    ⍝ Build BI/BII.
    ⍝ BI: Change __EXP__ to string imp.
    ⍝ BII:  Change __EXP__ to null string. Use name BII in place of BI.
      ⎕FX'__BI_SOURCE__' '__EXP__¨?'⎕R'BII' ''      ⊣⎕NR'__BI_SOURCE__'
      ⎕FX'__BI_SOURCE__' '__EXP__'  ⎕R 'BI' 'export'⊣⎕NR'__BI_SOURCE__'
      ___←⎕EX '__BI_SOURCE__'
    :EndSection BI Executive
    ⍝ ----------------------------------------------------------------------------------------

    :Section BigInt internal structure
      ⍝ ============================================
      ⍝ import / imp / ∆ - Import to internal bigInteger
      ⍝ ============================================
      ⍝ ∆  - internal alias for import w/o error handling and sanity check...
      ⍝    from: external-format* (BIc) (⍺ and) ⍵--
      ⍝          each either a BigInteger string or an APL integer--
      ⍝          * Or an internal-format (BIint) BigInteger, passed through unchanged.
      ⍝    to:   internal format (BIint) BigIntegers (⍺' and) ⍵',
      ⍝          each of the form sign (data), where data is an integer vector.
      ⍝ ∆: [BIint] BIint ← [⍺@BIext] ∇ ⍵@BIext
      ⍝    Monadic: Returns for ⍵, (sign data)_of_⍵ in the format above.
      ⍝    Dyadic:  Returns for ⍺ ⍵, (sign data)_of_⍺ (sign data)_of_⍵.
      ⍝
      ⍝ To be fast, we have these tests and assumed types...
      ⍝ If   80|⎕DR ⍵       assume...                        ⎕DR
      ⍝ ---------------+-------------------------------------------------------
      ⍝       0             importStr                        80, 160, 320 char
      ⍝       3             importInt (integer)              83...        int
      ⍝       5, 7          importFloat (integer as float)   645, 1287    float
      ⍝       6             BIint (internal)                 326          ptr objects
      ⍝ Output: BIint, i.e.  (sign (,ints)), where ints∧.<RX10
      ⍝
      ⍝ Keep for import: {I: ...}
      import←{⍺←⊢
          0::⎕SIGNAL/⎕DMX.(EM EN)
          1≢⍺ 1:(∇ ⍺)(∇ ⍵)
          type←80|⎕DR ⍵ ⋄ dep←≡⍵
          (¯2=dep)∧type=6:⍵
          1<|dep:err eIMPORT
          type=3:importInt ⍵
          type=0:importStr ⍵
          type∊5 7:importFloat ⍵
          err eIMPORT
      }
      ⍝ [⍺] importFast ⍵ 
      ⍝ [⍺] ∆ ⍵
      ⍝ Like <import>, but w/o sanity check and error handling. See discussion above.)
      importFast←{⍺←⊢
          1≢⍺ 1:(∇ ⍺)(∇ ⍵)
          type←80|⎕DR ⍵
          type=6:⍵
          type=3:importInt ⍵
          type=0:importStr ⍵
          type∊5 7:importFloat ⍵
          err eIMPORT
      }
      ∆←importFast
      imp←import  ⍝ external alias...

      ⍝ importInt:    ∇ ⍵:I[1]
      ⍝          ⍵ MUST Be an APL native (1-item) integer ⎕DR type 83 163 323.
      importInt←{
          1≠≢⍵:err eNONINT,⍕⍵              ⍝ scalar only...
          RX10>u←,|⍵:(×⍵)(u)               ⍝ Small integer
          (×⍵)(chkZ RX10⊥⍣¯1⊣u)            ⍝ Integer
      }
      ⍝ importFloat: Convert an APL integer into a BIint
      ⍝ Converts simple APL native numbers, as well as those with large exponents, e.g. of form:
      ⍝     1.23E100 into a string '123000...000', ¯1.234E1000 → '¯1234000...000'
      ⍝ These must be in the range of decimal integers (up to +/- 1E6145).
      ⍝ If not, you must use big integer strings of any length (exponents are disallowed in BigInt strings).
      ⍝ Normally, importFloat is not called by the user, since BII and BI call it automatically.
      ⍝ Usage:
      ⍝    (bigInt.∆  1E100)  ≡  bigInt.∆ '1',100⍴'0'   <==>  1
      ⍝    ⍝ calls importFloat   ⍝ calls importStr
      importFloat←{⎕FR←1287 ⍝ 1287: to handle large exponents
          (1=≢⍵)∧(⍵=⌊⍵):(×⍵)(chkZ RX10⊥⍣¯1⊣|⍵)
          err eNONINT,⍕⍵
      }
      ⍝ importStr: Convert a BigInt in string format into an internal BigInt
      ⍝       importStr ⍵:S[≥1]   (⍵ must have at least one digit, possibly a 0)
      importStr←{
          s←1 ¯1⊃⍨'-¯'∊⍨1↑⍵            ⍝ Get sign, if any
          w←'_'~⍨⍵↓⍨s=¯1               ⍝ Remove initial sign and embedded _ (spacer: ignored).
          (0=≢w)∨0∊w∊⎕D:err eBADBI     ⍝ w must include only ⎕D and at least one.
          d←dlzRun rep ⎕D⍳w            ⍝ d: data portion of BIint
          ∆dlzNorm s d                 ⍝ If d is zero, return zero. Else (s d)
      }
      ⍝ importSmallInt: Import ⍵ only if (when imported) it is a single-hand integer
      ⍝          i.e. equivalent to a number (|⍵) < RX10.
      ⍝ Returns a small integer!
      ⍝ Usage: so far, we only use it in BI/BII where we are passing data to an APL fn (⍳).
      importSmallInt←{
          s w←∆ ⍵ ⋄ 1≠≢w:err eSMALLRT
          s×,w
      }
    ⍝ ---------------------------------------------------------------------
    ⍝ export / exp: EXPORT a SCALAR BigInt to external "standard" bigInteger
    ⍝ ---------------------------------------------------------------------
    ⍝    r:BIc ← ∇ ⍵:BIint
    export←{ ('¯'/⍨¯1=⊃⍵),⎕D[dlzRun,⍉RX10BASE⊤|⊃⌽⍵]}
    exp←export
    ⍝ ∆dlzNorm ⍵:BIint  If ⊃⌽⍵ is zero after removing leading 0's,
    ⍝                   return canonical 0 (0 (,0)).
    ⍝                   Otherwise return ⍵ w/o leading zeroes.
    ⍝ ∆norm ⍵:BIint  If ⊃⌽⍵ is zero, ensure sign is 0. Otherwise, pass ⍵ as is.
    ∆dlzNorm←{zero_D≡w←dlzRun⊃⌽⍵: zero_BI ⋄ (⊃⍵) w}
    ∆norm←{zero_D≡⊃⌽⍵:zero_BI ⋄ ⍵}

    :EndSection BigInt internal structure
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Monadic Operations/Functions

    ⍝ neg[ate] / _neg[ate]
      neg←{                                ⍝ -
          (sw w)←∆ ⍵
          (-sw)w
      }
    ⍝ sig[num], _signum
      sig←{                                ⍝ ×
          (sw w)←∆ ⍵
          sw(|sw)
      }
      abs←{                                ⍝ |
          (sw w)←∆ ⍵
          (|sw)w
      }
    ⍝ inc[rement]:                         ⍝ ⍵+1
      inc←{
          (sw w)←∆ ⍵
          sw=0:1 one_D                     ⍝ ⍵=0? Return 1.
          sw=¯1:∆dlzNorm sw(⊃⌽_dec 1 w)          ⍝ ⍵<0? inc ⍵ becomes -(dec |⍵). ∆dlzNorm handles 0.
          î←1+⊃⌽w                          ⍝ trial increment (most likely path)
          RX10>î:sw w⊣(⊃⌽w)←î                ⍝ No overflow? Increment and we're done!
          sw w add 1 one_D                 ⍝ Otherwise, do long way.
      }
    ⍝ dec[rement]:                         ⍝ ⍵-1
      dec←{
          (sw w)←∆ ⍵
          sw=0:¯1 one_D                    ⍝ ⍵ is zero? Return ¯1
          sw=¯1:∆dlzNorm sw(⊃⌽_inc 1 w)           ⍝ ⍵<0? dec ⍵  becomes  -(inc |⍵). ∆dlzNorm handles 0.
                                           ⍝ If the last digit of w>0, w-1 can't underflow.
          0≠⊃⌽w:∆dlzNorm sw w⊣(⊃⌽w)-←1           ⍝ No underflow?  Decrement and we're done!
          sw w _sub 1 one_D                 ⍝ Otherwise, do long way.
      }
    ⍝ fact: compute BI factorials.
    ⍝       r:BIc ← fact ⍵:BIext
    ⍝ We allow ⍵ to be of any size, but numbers larger than NRX10 are impractical.
    ⍝ We deal with 3 cases:
    ⍝    ⍵ ≤ 31:    We let APL calculate, with ⎕PP←34.   Fast.
    ⍝    ⍵ ≤ NRX10:   We calculate r as a BigInt, while counting down ⍵ as an APL integer. Moderately fast.
    ⍝    Otherwise: We calculate entirely using BigInts for r and ⍵. Slowwwwww.
      fact←{                                ⍝ !⍵
          sw w←∆ ⍵
          sw=0:one_BI                          ⍝ !0
          sw=¯1:err eFACTOR                 ⍝ ⍵<0
          factBig←{
              1=≢⍵:⍺ factSmall ⍵            ⍝ Skip to factSmall when ≢⍵ is 1 hand.
              (⍺ mulU ⍵)∇⊃⌽_dec 1 ⍵
          }
          factSmall←{
              ⍵≤1:1 ⍺
              (⍺ mulU ⍵)∇ ⍵-1
          }
          1 factBig w
      }
    ⍝ roll ⍵: Compute a random number between 0 and ⍵-1, given ⍵>0.
    ⍝    r:BIint ← ∇ ⍵:BIint   ⍵>0.
    ⍝ With inL the # of dec digits in ⍵, excluding any leading '0' digits...
    ⍝ Proceed as shown here, where (exp ⍵) is "exported" BIext format; (∆ ⍵) is internal BIint format.
      roll←{
          sw w←∆ ⍵
          sw≠1:err eBADRAND
          ⎕PP←16 ⋄ ⎕FR←645                       ⍝ 16 digits per ?0 is optimal
          inL←≢exp sw w                          ⍝ ⍵: in exp form. in: ⍵ with leading 0's removed.
     
          res←inL⍴{                              ⍝ res is built up to ≥inL random digits...
              ⍺←''                               ⍝ ...
              ⍵≤≢⍺:⍺ ⋄ (⍺,2↓⍕?0)∇ ⍵-⎕PP          ⍝ ... ⎕PP digits at a time.
          }inL                                   ⍝ res is then truncated to exactly inL digits
          '0'=⊃res:∆ res                         ⍝ If leading 0, guaranteed (∆ res) < ⍵.
          ⍵ rem ∆ res                            ⍝ Otherwise, compute rem r: 0 ≤ r < ⍵.
      }
  ⍝⍝  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  ⍝⍝  Bit Management Utilities
  ⍝⍝  ⊥    bits→bi
  ⍝⍝  ⊤    bi→bits, 
  ⍝⍝  ~    reverses bits of bi ⍵, i.e.   (⊥ ~ ⊤ ⍵) 
  ⍝⍝  We allow 
  ⍝⍝      1. Importing from a simple bit array ⍵ ravelled to: bits←,⍵
  ⍝⍝          [sign] bits
  ⍝⍝           sign: 1 for negative, 0 for positive.
  ⍝⍝           bits: 1 or more bits 
  ⍝⍝         Returns a bigint in internal format, normalized as required.
  ⍝⍝         If <bits> are not multiple of 20 (NRX2), the non-sign <bits> are padded on the left with 0s (unsigned)
  ⍝⍝      2. Exporting from a signed bigint object to a vector:
  ⍝⍝          [sign] bits
  ⍝⍝          sign, bits: as above    
  ⍝⍝  For bit array manipulation, perform entirely using APL's more powerful intrinsics, then convert to a bigint. 
  ⍝⍝  ~ included in BI(I) calls for demonstration purposes.  
  ⍝⍝    
  ⍝⍝  Bugs: Except for the overall sign bit, the bigint data is handled as unsigned in every case,
  ⍝⍝        not in a  2s-complement representation.
  ⍝⍝        That is, ¯1 is stored as (sign bit: 1) plus (data: 0 0 0 ... 0 1), not as all 1s (as expected for 2s-complement).
  ⍝⍝            ¯1 can be represented as   1 1    OR    1 0 1    OR    1 0 0 0 ... 0 1, etc.
  ⍝⍝  See  ⊥BI ⍵ OR 'BITSIN' BI ⍵ and  ⊤BI ⍵ OR 'BITSOUT' BI ⍵
      bitsImport←{
          ' '=1↑0⍴⍵: ∇ '1'=b ⊣   eBOOL ⎕SIGNAL 11/⍨0∊'01'∊⍨b←⍵~' '     ⍝ Allow quoted args, since will be presented by bi.dc desk calculator
          0∊⍵∊0 1: eBOOL ⎕SIGNAL 11
          bits←,⍵             
          sgn←(⊃bits)⊃1 ¯1 ⋄ bits←1↓bits    ⍝ 1st bit is sign bit.
          nhands←⌈exact←NRX2÷⍨≢bits         ⍝ Process remaining bits into hands of <nbits> each
          bits←nhands NRX2⍴{
              nhands=exact: ⍵
              (-nhands×NRX2)↑⍵              ⍝ Padding first hand on left with 0s (unsigned)
          }bits   
          ∆dlzNorm sgn (2 ⊥⍉ bits )         ⍝ Convert to bigint:  (sign) (integer array)
      }
      bitsExport←{
          sw w←∆ ⍵
          sw=0:   0,NRX2⍴0
          (sw=¯1),,⍉NRX2BASE⊤w 
      }
     
    ⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

    ⍝ (int) root: A fast integer nth root.
    ⍝ Syntax:    x@BIint ← nth@BIext<RX10 ∇ N@BIext     ==>  x ← N *÷nth
    ⍝   nth: a small, positive integer (<RX10); default 2 (for sqrt).
    ⍝   N:   any BIext
    ⍝   x:   the nth root as an internal big integer.
    ⍝   ∘ Uses Fredrick Johanssen's algorithm with optimization for APL integers.
    ⍝   ∘ Estimator based on guesstimate for sqrt N, no matter what root.
    ⍝     (Better than using N).
    ⍝   ∘ As fast for sqrt as a "custom" version.
    ⍝   ∘ If N is small, calculate directly via APL.
    ⍝ x:BIint ← nth:small_(BIint|BIext) ∇ N:(BIint|BIext)>0
      root←{
        ⍝ Check radix in  N*÷radix
        ⍝ We work with bigInts here for convenience. Could be done unsigned...
          ⍺←2 ⍝ sqrt by default...
          sgn rdx←⍺{   ⍝ Get the sign, (÷radix), radix based on ⍺.
              ⍵:1 2
              sgn rdx←import ⍺
              sgn=0:eROOT ⎕SIGNAL 11
              1<≢rdx:eROOT ⎕SIGNAL 11
              sgn rdx
          }900⌶⍬
          sgn<0:0    ⍝  ⌊N*÷nth ≡ 0, if nth<0 (nth a small int)
        ⍝ Check N
          sN N←import ⍵
          0=sN:sN N                    ⍝  0=×N?   0
          ¯1=sN:eROOT ⎕SIGNAL 11        ⍝ ¯1=×N?   error
          rootU←*∘(÷rdx)
     
          1=ndig←≢N:1(,⌊rootU N)    ⍝ N small? Let APL calc value
        ⍝ Initial estimate for N*÷nth must be ≥ the actual solution, else this will terminate prematurely.
        ⍝ Initial estimate (x):
        ⍝   DECIMAL est: ¯1+10*⌈num_dec_digits(N)÷2   ←-- We use this one.
        ⍝   BINARY  est:  2*⌈numbits(N)÷2
          x←{ ⍝ We use est(sqrt N) as initial estimate for ANY root. Not ideal, but safe.
              0::1((⌈rootU⊃⍵),(RX10-1)⍴⍨⌈0.5×ndig-1) ⍝ Too big for APL est. Use DECIMAL est. above.
              ⎕FR←1287
              ⊃⌽import 1+⌈rootU⍎export 1 ⍵     ⍝ Est from APL: works for ⍵ ≤ ⌊/⍬ 1E6145
          }N
        ⍝ Refine x, aka ⍵, until y > x
         ⍝ All unsigned here
          { ⋄ x←⍵
              y←(x addU N quotientU x)quotientU rdx    ⍝ y is next guess: y←⌊((x+⌊(N÷x))÷nth)
              ≥cmp y mix x:1(,x)
              ∇ y                              ⍝ y is smaller than ⍵. Make x ← y and try another.
          }x
      }
    eROOT←'bigInt.root: root (⍺) must be small non-zero integer ((|⍺)<',(⍕RX10),')'
    sqrt←root
    rootX←{⍺←⊢ ⋄ export ⍺ root ⍵}

  ⍝ recip:  ÷⍵ ←→ 1÷⍵ Almost useless, since ÷⍵ is 0 unless ⍵ is 1 or ¯1.
    recip←{{0=≢⍵: ÷0 ⋄ 1≠≢⍵:0 ⋄ 1=|⍵:⍵ ⋄ 0}dlzRun ⍵}

    :Endsection BI Monadic Functions/Operations
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Dyadic Functions/Operations
  ⍝ dyad:    compute all supported dyadic functions
     ⍝ genFast_InternalFormat_Fns: 
     ⍝    for specific functions, e.g. sub, we generate a fast version, _sub, which assumes internal-format args ⍺ and ⍵
       ∇{fn}←genFast_InternalFormat_Fns fn;un
        un←'_',fn
        fn←⎕FX fn '⍺ ∆ ⍵' ⎕R un '⍺ ⍵'⊣⎕NR fn
      ∇
      add←{
          (sa a)(sw w)←⍺ ∆ ⍵
          sa=0:sw w                           ⍝ optim: ⍺+0 → ⍺
          sw=0:sa a                           ⍝ optim: 0+⍵ → ⍵
          sa=sw:sa(ndnZ 0,+⌿a mix w)          ⍝ 5 + 10 or ¯5 + ¯10
          sa<0:sw w _sub 1 a                  ⍝ Use unsigned vals: ¯10 +   5 → 5 - 10
          sa a _sub 1 w                       ⍝ Use unsigned vals:   5 + ¯10 → 5 - 10
      }
      sub←{
          (sa a)(sw w)←⍺ ∆ ⍵
          sw=0:sa a                            ⍝ optim: ⍺-0 → ⍺
          sa=0:(-sw)w                          ⍝ optim: 0-⍵ → -⍵
          sa≠sw:sa(ndnZ 0,+⌿a mix w)           ⍝ 5-¯3 → 5+3 ; ¯5-3 → -(5+3)
          <cmp a mix w:(-sw)(nupZ-⌿dck w mix a)    ⍝ 3-5 →  -(5-3)
          sa(nupZ-⌿dck a mix w)                ⍝ a≥w: 5-3 → +(5-3)
      }
      genFast_InternalFormat_Fns 'sub'

      mul←{
          (sa a)(sw w)←⍺ ∆ ⍵
          0∊sa,sw:zero_BI
          two_D≡a:(sa×sw)(addU⍨w) ⋄ two_D≡w:(sa×sw)(addU⍨a)
          one_D≡a:(sa×sw)w ⋄ one_D≡w:(sa×sw)a
          (sa×sw)(a mulU w)
      }
      genFast_InternalFormat_Fns 'mul'

      div←{
          (sa a)(sw w)←⍺ ∆ ⍵
          ∆norm(sa×sw)(⊃a divU w)
      }
      divRem←{
          (sa a)(sw w)←⍺ ∆ ⍵
          quot rem←a divU w
          (∆norm(sa×sw)quot)(∆norm sw rem)
      }
    ⍝ ⍺ pow ⍵:
    ⍝   General case:  ⍺*⍵ where both are BIint
    ⍝   Special case:  (÷⍵) (or ÷⍎⍵) is an integer: (÷⍵) root ⍺. Example:  ⍺*BI 0.5 is sqrt; ⍺*BI (÷3) is cube root; etc.
    ⍝                  (÷⍵) must be an integer to the limit of the current ⎕CT.
    ⍝ decodeRoot (pow utility): Allow special syntax ( ⍺ *BI ÷⍵ ) in place of  ( ⍵ root ⍺ ).
    ⍝       ⍵ must be an integer such that 0<⍵<1 or a string representation of such an integer.
    ⍝       For 3 root 27, use:
    ⍝             I.e. '27' *BI ÷3    '27' *BI '÷3'
    ⍝       The root is truncated to an integer.
      decodeRoot←{              ⍝ If not a root, return 0 to signify skip. Otherwise, return the radix (small positive number).
          0::0 ⋄ 0>≡⍵:0         ⍝ Bigint internal format? Skip
            ⍝             skip   ÷3   ←integer                 '÷3'                            '0.33'
          ⌊{extract←{1≤⍵:0 ⋄ ÷⍵} ⋄ 0=1↑0⍴⍵:extract ⍵ ⋄ '÷'=1↑⍵:⊃⊃⌽⎕VFI 1↓⍵ ⋄ extract⊃⊃⌽⎕VFI ⍵}⍵
      }
      pow←{
          0≠rt←decodeRoot ⍵:rt root ⍺
        ⍝ Not a root, so decode as usual
        ⍝ Special cases ⍺*2, ⍺*1, ⍺*0 handled in powU.
          (sa a)(sw w)←⍺ ∆ ⍵
          sa sw∨.=0 ¯1:zero_BI     ⍝ r←⍺*¯⍵ is 0≤r<1, so truncates to 0.
          p←a powU w
          sa≠¯1:1 p                ⍝ sa= 1 (can't be 0).
          0=2|⊃⌽w:1 p ⋄ ¯1 p       ⍝ ⍺ is neg, so result is pos. if ⍵ is even.
      }
      rem←{                        ⍝ remainder/residue. APL'S DEF: ⍺=base.
          (sa a)(sw w)←⍺ ∆ ⍵
          sw=0:zero_BI
          sa=0:sw w
          r←,a remU w              ⍝ remU is fast if a>w
          sa=sw:∆dlzNorm sa r      ⍝ sa=sw: return (R)        R←sa r
          zero_D≡r:zero_BI         ⍝ sa≠sw ∧ R≡0, return 0
          ∆dlzNorm sa a _sub sa r  ⍝ sa≠sw: return (A - R')   A←sa a; R'←sa r
      }
      genFast_InternalFormat_Fns 'rem'

    res←rem                        ⍝ residue (APL name)
    mod←{⍵ rem ⍺}                  ⍝ modulo←rem[ainder]⍨

    ⍝ mul2Exp:  Shift ⍺:BIext left or right by ⍵:Int binary digits
    ⍝  r:BIint ← ⍺:BIint   ∇  ⍵:aplInt
    ⍝     Note: ⍵ must be an APL integer (<RX10).
    ⍝  -  If ⍵>0: shift ⍺ left by ⍵ binary digits
    ⍝  -  If ⍵<0: shift ⍺ rght by ⍵ binary digits
    ⍝  -  If ⍵=0: then ⍺ will be unchanged
    ⍝ Very slow!
      mul2Exp←{
          (sa a)(sw w)←⍺ ∆ ⍵
          1≠≢w:err eMUL10                         ⍝ ⍵ must be small integer.
          sa=0:0 zero_D                           ⍝ ⍺ is zero: return 0.
          sw=0:sa a                               ⍝ ⍵ is zero: ⍺ stays as is.
          pow2←2*w 
          sw>0: sa a mul pow2
          sa a div pow2    
      }
      div2Exp←{
          ⍺ mul2Exp negate ⍵
      }
    shiftBinary←mul2Exp
    shiftB←mul2Exp

    ⍝ mul10Exp: Shift ⍺:BIext left or right by ⍵:Int decimal digits.
    ⍝      Converts ⍺ to BIc, since shifts are a matter of appending '0' or removing char digits from right.
    ⍝  r:BIint ← ⍺:BIint   ∇  ⍵:Int
    ⍝     Note: ⍵ must be an APL integer (<RX10).
    ⍝  -  If ⍵>0: shift ⍺ left by ⍵-decimal digits
    ⍝  -  If ⍵<0: shift ⍺ rght by ⍵ decimal digits
    ⍝  -  If ⍵=0: then ⍺ will be unchanged
      mul10Exp←{
          (sa a)(sw w)←⍺ ∆ ⍵
          1≠≢w:err eMUL10                          ⍝ ⍵ must be small integer.
          sa=0:zero_BI                             ⍝ ⍺ is zero: return 0.
          sw=0:sa a                                ⍝ ⍵ is zero: sa a returned.
          ustr←export 1 a                          ⍝ ⍺ as unsigned string.
          ss←'¯'/⍨sa=¯1                            ⍝ sign as string
          sw=1:∆ ss,ustr,w⍴'0'                     ⍝ sw= 1? shift right by appending zeroes.
          ustr↓⍨←-w                                ⍝ sw=¯1? shift right by dec truncation
          0=≢ustr:zero_BI                          ⍝ No chars left? It's a zero
          ∆ ss,ustr                                ⍝ Return in internal form...
      }
    shiftDecimal←mul10Exp                          ⍝ positive/left
    shiftD←mul10Exp

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

    ⍝ genBooleanFn-- generate Boolean functions lt <, le ≤, eq =, ge ≥, gt >, ne ≠
    ∇ {r}←genBooleanFn(NAME SYM);model;∆TEMPLATE;in;out
      ∆TEMPLATE←{
        ⍝ ⍺ ∆TEMPLATE ⍵: emulates (⍺ ∆SYM ⍵)
        ⍝ ⍺, ⍵: BigIntegers
          (sa a)(sw w)←⍺ ∆ ⍵
          0∊sa sw:sa ∆SYM sw        ⍝ ⍺, ⍵, or both are 0
          sa≠sw:sa ∆SYM sw          ⍝ ⍺, ⍵ different signs
          sa=¯1:∆SYM cmp w mix a    ⍝ ⍺, ⍵ both neg
          ∆SYM cmp a mix w          ⍝ ⍺, ⍵ both pos
      }
      in←'∆TEMPLATE' '∆SYM' ⋄ out←NAME SYM
      :If ' '≠1↑0⍴r←⎕THIS.⎕FX in ⎕R out⊣⎕NR'∆TEMPLATE'
          ⎕←'LOGIC ERROR: unable to create boolean function: ',NAME,' (',SYM,')'
      :EndIf
    ∇
    genBooleanFn¨ ('lt' '<')('le' '≤')('eq' '=')('ge' '≥')('gt' '>')('ne' '≠')
    ⎕EX 'genBooleanFn'

    :EndSection BI Dyadic Operators/Functions

    :Section BI Special Functions/Operations (More than 2 Args)
    ⍝ modMul:  modulo m of product a×b
    ⍝ A faster method than (m|a×b), when a, b are large and m is substantially smaller.
    ⍝ r ← a modMul b m    →→→    r ← m | a × b
    ⍝ BIint ← ⍺:BIint ∇ ⍵:BIint m:BIint
    ⍝ Naive method: (m|a×b)
    ⍝      If a,b have 1000 digits each and m is smaller, the m| operates on 2000 digits.
    ⍝ Better method: (m | (m|a)×(m|b)).
    ⍝      Here, the multiply is on len(m) digits, and the final m operates on 2×len(m).
    ⍝ For large a b of length 5000 dec digits or more, this alg can be 2ce the speed (13 sec vs 26).
    ⍝ It is nominally faster at lengths around 75 digits.
    ⍝ Only for smaller (and faster) a and b, the cost of 3 modulos instead of 1 predominates.
      modMul←{
          2≠≢⍵:eModMul ⎕SIGNAL 11
          a(b m)←(∆ ⍺)(⊃∆/⍵)
          m _rem(m _rem a)_mul(m _rem b)
      }

      eModMul←'modMul syntax: ⍺ ∇ ⍵1 ⍵2',⎕UCS 10
      eModMul,←'               ⍺: multiplicand, ⍵1: multiplier, ⍵2: base for modulo'

    :EndSection BI Special Functions/Operations (More than 2 Args)
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Unsigned Utility Math Routines
    ⍝ These are the workhorses of bigInt; most are from dfns:nats (handling unsigned bigInts).
    ⍝ Note: ⍺ and ⍵ are guaranteed by BII and BI to be vectors, but not
    ⍝       by internal functions or if called directly.
    ⍝       So tests for 2, 1, 0 (two_D etc) use ravel:  (two_D≡,⍺)

    ⍝ addU:   ⍺ + ⍵
      addU←{
          dlzRun ndn 0,+⌿⍺ mix ⍵    ⍝ We use dlzRun in case ⍺ or ⍵ have multiple leading 0s. If not, use ndnZ
      }
    ⍝ subU:  ⍺ - ⍵   Since unsigned, if ⍵>⍺, there are two options:
    ⍝        [1] Render as 0
    ⍝        [2] signal an error...
      subU←{
          <cmp ⍺ mix ⍵:eSUB ⎕SIGNAL 11          ⍝ [opt 2] 3-5 →  -(5-3)
          dlzRun nup-⌿dck ⍺ mix ⍵                 ⍝ a≥w: 5-3 → +(5-3). ⍺<⍵: 0 [opt 1]
      }
      eSUB←'bigInt subU: unsigned subtraction may not become negative'
    ⍝ mulU:  multiply ⍺ × ⍵  for unsigned BIint ⍺ and ⍵
    ⍝ r:BIint ← ⍺:BIint ∇ ⍵:BIint
    ⍝ This is dfns:nats mul.
    ⍝ It is faster than dfns:xtimes (FFT-based algorithm)
    ⍝ even for larger numbers (up to xtimes smallish design limit)
    ⍝ We call ndnZ to remove extra zeros, esp. so zero is exactly ,0 and 1 is ,1.
      mulU←{
          dlzRun ⍺{                                 ⍝ product.
              ndnZ 0,↑⍵{                          ⍝ canonicalised vector.
                  digit take←⍺                    ⍝ next digit and shift.
                  +⌿⍵ mix digit×take↑⍺⍺           ⍝ accumulated product.
              }/(⍺,¨(≢⍵)+⌽⍳≢⍺),⊂,0                ⍝ digit-shift pairs.
          }{                                      ⍝ guard against overflow:
              m n←,↑≢¨⍺ ⍵                         ⍝ numbers of RX10-digits in each arg.
              m>n:⍺ ∇⍨⍵                           ⍝ quicker if larger number on right.
              n<OFL:⍺ ⍺⍺ ⍵                        ⍝ ⍵ won't overflow: proceed.
              s←⌊n÷2                              ⍝ digit-split for large ⍵.
              p q←⍺∘∇¨(s↑⍵)(s↓⍵)                  ⍝ sub-products (see notes).
              ndnZ 0,+⌿(p,s↓n⍴0)mix q             ⍝ sum of sub-products.
          }⍵
      }
   ⍝ powU: compute ⍺*⍵ for unsigned ⍺ and ⍵. (⍺ may not be omitted).
   ⍝ RX10div2: (Defined above.)
      powU←{                                  ⍝ exponent.
          zero_D≡,⍵:one_D                     ⍝ =cmp ⍵ mix,0:,1 ⍝ ⍺*0 → 1
          one_D≡,⍵:,⍺                        ⍝ =cmp ⍵ mix,1:⍺  ⍝ ⍺*1 → ⍺. Return "odd," i.e. use sa in caller.
          two_D≡,⍵:⍺ mulU ⍺                 ⍝ ⍺×⍺
          hlf←{,ndn(⌊⍵÷2)+0,¯1↓RX10div2×2|⍵}    ⍝ quick ⌊⍵÷2.
          evn←ndnZ{⍵ mulU ⍵}ndn ⍺ ∇ hlf ⍵     ⍝ even power
          0=2|¯1↑⍵:evn ⋄ ndnZ ⍺ mulU evn      ⍝ even or odd power.
      }
   ⍝ divU/: unsigned division
   ⍝  divU:   Removes leading 0s from ⍺, ⍵ then calls _divU
   ⍝ Returns:  (int. quotient) (remainder)
   ⍝           (⌊ua ÷ uw)      (ua | uw)
   ⍝   r:BIint[2] ← ⍺:BIint ∇ ⍵:BIint
      divU←{
          a w←dlzRun¨⍺ ⍵
          zero_D≡,⍵:a{                        ⍝ ⍺÷0
              zero_D≡,⍺:one_D                 ⍝ 0÷0 → 1 remainder 0
              1÷0                             ⍝ Error message
          }w
          svec←(≢w)+⍳0⌈1+(≢a)-≢w              ⍝ shift vector.
          dlzRun¨↑w{                            ⍝ fold along dividend.
              r p←⍵                           ⍝ result & dividend.
              q←⍺↑⍺⍺                          ⍝ shifted divisor.
              ppqq←RX10⊥⍉2 2↑p mix q            ⍝ 2 most signif. digits of p & q.
              r∆←p q{                         ⍝ next RX10-digit of result.
                  (p q)(lo hi)←⍺ ⍵            ⍝ div and high-low test.
                  lo=hi-1:p{                  ⍝ convergence:
                      (≥cmp ⍺ mix ⍵)⊃lo hi    ⍝ low or high.
                  }dLZ ndn 0,hi×q             ⍝ multiple.
                  mid←⌊0.5×lo+hi              ⍝ mid-point.
                  nxt←dLZ ndn 0,q×mid         ⍝ next multiplier.
                  gt←>cmp p mix nxt           ⍝ greater than:
                  ⍺ ∇ gt⊃2,/lo mid hi         ⍝ choose upper or lower interval.
              }⌊0 1+↑÷/ppqq+(0 1)(1 0)        ⍝ lower and upper bounds of ratio.
              mpl←dLZ ndn 0,q×r∆              ⍝ multiple.
              p∆←dLZ nup-⌿p mix mpl           ⍝ remainder.
              (r,r∆)p∆                        ⍝ result & remainder.
          }/svec,⊂⍬ a                         ⍝ fold-accumulated reslt.
      }
    quotientU←⊃divU
    gcdU←{zero_D≡,⍵:⍺ ⋄ ⍵ ∇⊃⌽⍺ divU ⍵}        ⍝ greatest common divisor.
    lcmU←{⍺ mulU⊃⍵ divU ⍺ gcdU ⍵}             ⍝ least common multiple.
      remU←{                                  ⍝ BIu remainder
          two_D≡,⍺:2|⊃⌽⍵                     ⍝ fast (short-circuit) path for modulo 2
          <cmp ⍵ mix ⍺:⍵                     ⍝ ⍵ < ⍺? remainder is ⍵
          ⊃⌽⍵ divU ⍺                         ⍝ Otherwise, do full divide
      }
    :Endsection BI Unsigned Utility Math Routines
⍝ --------------------------------------------------------------------------------------------------

    :Section Service Routines

    atom←{1=≢⍵:⍬⍴⍵ ⋄ ⊂⍵}                    ⍝ atom:     Simple scalar if ⍵ of length 1; else enclosed obj.
                                            ⍝ prettify: Add underscores every 5 digits; ⍺=0 (default): replace ¯ by - .
    prettify←  {0:: ⍵ ⋄ ⍺←0 ⋄ n← '(\d)(?=(\d{5})+$)' ⎕R '\1_'⊣⍵  ⋄  ⍺=0: n ⋄ '-'@('¯'∘=) n}    
                                            ⍝ ∆2Apl:    Convert valid bigint ⍵ to APL, with error if exponent too large.
    ∆2Apl←{  0:: eBADRANGE ⎕SIGNAL 11  ⋄  ⍎exp ∆ ⍵}   

  ⍝ These routines operate on unsigned BIu data unless documented… (Mostly from dfn utilities)
    dLZ←{(0=⊃⍵)↓⍵}                          ⍝ drop FIRST leading zero.
    dlzRun←{0≠≢v←(∨\⍵≠0)/⍵:v ⋄ ,0}          ⍝ drop RUN of leading zeros, but [PMS] make sure at least one 0
    chkZ←{0≠≢⍵:,⍵ ⋄ ,0}                     ⍝ ⍬ → ,0. Ensure canonical Bii, so even 0 has one digit (,0).

    ndn←{ +⌿1 0⌽0 RX10⊤⍵}⍣≡                 ⍝ normalise down: 3 21 → 5 1 (RH).
    ndnZ←dLZ ndn                            ⍝ ndn, then remove (earlier added) leading zero, if still 0.
    nup←{⍵++⌿0 1⌽RX10 ¯1∘.×⍵<0}⍣≡           ⍝ normalise up:   3 ¯1 → 2 9
    nupZ←dLZ nup                            ⍝ PMS

    mix←{↑(-(≢⍺)⌈≢⍵)↑¨⍺ ⍵}                  ⍝ right-aligned mix.
    dck←{(2 1+(≥cmp ⍵)⌽0 ¯1)⌿⍵}             ⍝ difference check.
    rep←{10⊥⍵{⍉⍵⍴(-×/⍵)↑⍺}(⌈(≢⍵)÷NRX10),NRX10}  ⍝ radix RX10 rep of number.
    cmp←{⍺⍺/,(<\≠⌿⍵)/⍵}                     ⍝ compare first different digit of ⍺ and ⍵.

   
    :Endsection Service Routines
⍝ --------------------------------------------------------------------------------------------------
    :Endsection Big Integers

    :Section Utilities: bi, dc (desk calc), BIB, BIC
   ⍝ bi      - simple niladic fn, returns this bigint namespace #.BigInt
   ⍝           If ⎕PATH points to bigInt namespace, bi will be found without typing explicit path.
   ⍝ bi.dc   - desk calculator (self-documenting)
   ⍝ BIB     - Shortcut to manipulate BIs as arbitrary signed binary numbers
   ⍝ BIC     - Utility to compile code strings or functions with BI arithmetic
 
   ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
   ⍝ Utilities…

  ⍝ bi:  Returns ⎕THIS namespace
      ⎕FX 'ns←bi' 'ns←⎕THIS'          ⍝ Simple user-friendly name...
      ⎕FX 'ns←BI_LIB' 'ns←⎕THIS'    ⍝ A more unique name for use by utilities...

    ⍝ RE∆GET-- ⎕R/⎕S Regex utility-- returns field #n or ''
      RE∆GET←{ ⍝ Returns Regex field ⍵N in ⎕R ⍵⍵ dfn. Format:  f2 f3←⍵ RE∆GET¨2 3
          ⍵=0:⍺.Match ⋄ ⍵≥≢⍺.Offsets:'' ⋄ ¯1=⍺.Offsets[⍵]:'' ⋄ ⍺.(Lengths[⍵]↑Offsets[⍵]↓Block)
      }
   ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
    ∇ {r}←_LoadPats
      ;actBiCallNoQ;actBiCallQ;actKeep;actKeepParen;actQuoted;lD;lM;p2Fancy;p2Funs1;p2Funs2
      ;p2Ints;p2Plain;p2Vars;pAplInt;pCom;pFancy;pFunsBig;pFunsNoQ;pFunsQ;pFunsSmall;pIntExp
      ;pIntOnly;pLongInt;pNonBiCode;pQot;pVar;t1;t2;tD1;tDM;tM1;tMM;_Q;_E
   ⍝ fnRep pattern: Match 0 or more lines
   ⍝ between :BIX… :EndBI keywords or  ⍝:BI … ⍝:ENDBI keywords
   ⍝ Match   ⍝:BI \n <BI code> … ⍝:EndBI. No spaces between ⍝ and :BI (bad: ⍝ :BI).
   ⍝ \R: any linend.  \N: any char but linend
      pFnRep←'(?i:) ^ (?: \h* ⍝?:BI \b \N*$) (.*?) (?: \R \h* ⍝?:ENDBI \b \N*$)'
   ⍝ Field:    #1                              #2    #3
   ⍝ #1: :BII; #2: text in :BII scope;  #3: text :ENDBI
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
       ⋄ tD1 tDM←dyadFnsList
       ⋄ tM1 tMM←monadFnsList
       ⋄ t1←tD1{'[\-\?\*]'⎕R'\\\0'⊣∪⍺,⍵}tM1      ⍝ Escape expected length-1 special symbols
      _Q _E←⊂¨'\Q' '\E'
      t2←¯1↓∊(_Q,¨_E,⍨¨tDM,tMM),¨'|'
      p2Funs1←'(?:⍺⍺|⍵⍵)'                      ⍝ See pFunsSmall.
      p2Funs2←'(?:',t2,')|(?:[',t1,'])'        ⍝ See pFunsBig. Case is respected for MUL10, SQRT…
     
      ⍝ …P:  Patterns. Most have a field#1
      pCom←'(⍝.*?)$'                           ⍝ Keep comments as is
      pVar←'([',p2Vars,'][',p2Vars,'\d]*)'     ⍝ Keep variable names as is, except MUL10 and SQRT
      pQot←'((?:''[^'']*'')+)'                 ⍝ Keep quoted numbers as is and anything else quoted
      pFunsNoQ←'(',p2Funs1,'(?!\h*BII))'       ⍝ ⍺⍺, ⍵⍵ operands NOT quoted. → (⍺⍺ BII) (⍵⍵ BII)
      pFunsQ←'((?:',p2Funs2,')⍨?(?!\h*BII))'   ⍝ All fns: APL or named are quoted. Simpler/faster.
                                               ⍝ SQRT → ('SQRT'BII), + → ('+' BII), √ 100 → ('√' BI '100')
      pNonBiCode←'\(:(.*?):\)'                 ⍝ Anything in (: … :) treated as APL
     
      pIntExp←'([\-¯]?[\d.]+[eE]¯?\d+)'        ⍝ [-¯]4.4E55 will be padded out. Underscores invalid.
      pIntOnly←'([\-¯]?[\d_.]+)'               ⍝ Put other valid BII-format integers in quotes
   ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
   ⍝ BII Actions
   ⍝ …AB: BII (Big Integer) action building-blocks
      actBiCallNoQ←'(\1',(⍕⎕THIS),'.BI)'       ⍝ See pFunsNoQ above
      actBiCallQ←'(''\1''',(⍕⎕THIS),'.BI)'     ⍝ See pFunsQ above
      actKeep actKeepParen actQuoted actBool←'\1' '(\1)' '''\1'''   '⊥BI \1'
   ⍝ EXTERN pBiCalls:     Full BI (Big Integer) pattern
   ⍝    pFunsBig must precede pVar, so that MUL10 and SQRT will be treated as BI operands…
   ⍝ pAplInt replaced by pFancy-- see NOTE 20181016 below
      pBiCalls←pCom pFunsQ pVar pQot pFunsNoQ pNonBiCode  pIntExp pIntOnly
   ⍝ EXTERN actBiCalls:   BI (Big Integer) action
   ⍝ In this version, we quote all APL integers unless they have exponents...
      actBiCalls←actKeep actBiCallQ actKeep actKeep actBiCallNoQ actKeep  actKeepParen actQuoted
   ⍝ EXTERN matchBiCalls: BI (Big Integer) matching calls…
      matchBiCalls←{⍺←1
          res←⊃⍣(1=≢res)⊣res←pBiCalls ⎕R actBiCalls⍠('UCP' 1)⊣⊆⍵
          ⍺=1:res
          prefix←'\Q','.\E',⍨⍕⎕THIS   ⍝ remove the prefixes!
          prefix ⎕R' '⊣res
      }
      r←'OK'
    ∇
    _LoadPats


   ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
   ⍝  BIC: Compile a function ⍵ with BII directives...
      BIC←{
          ⍺←1
          ∆ERR::⎕SIGNAL/⎕DMX.(('bigInt: ',EM)EN)
          0=1↑0⍴∊⍵:err eBIC
        ⍝ ⍺ a string, treat as: ⍺,1 BIC ⍵
          0≠1↑0⍴⍺: ⍺,matchBiCalls ⍵              ⍝ ⍺ is catenated: as if ⍺,1 BIC ⍵
          ⍺=2:     matchFnRep ⎕NR ⍵                  ⍝ Compile function named ⍵
          ⍺=¯2:    matchFnRep ⍵                     ⍝ Compile function whose ⎕NR is ⍵
          ⍺=0:     matchBiCalls ⍵                    ⍝ Compile string ⍵ and return compiled string
          ⍺=¯1:    0 matchBiCalls ⍵                 ⍝ Compile string ⍵ and return compiled string w/o BI namespace prefixes (for ease of viewing)
          ⍺=1:((1+⎕IO)⊃⎕RSI,#)⍎matchBiCalls ⍵   ⍝ Compile and execute string ⍵ in CALLER space, returning value of execution
      }

      dc_HELP←⊂'bi.dc'
      dc_HELP,←⊂'desk calculator'
      dc_HELP,←⊂'¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯'
      dc_HELP,←⊂'User command:     APL expression:  '
      dc_HELP,←⊂'   ]dc               bi.dc'
      dc_HELP,←⊂''
      dc_HELP,←⊂'○  Enter APL arithmetic expressions containing arbitrary integer scalars:'
      dc_HELP,←⊂'      2*3100'
      dc_HELP,←⊂'   15595042345474685813045672264607686080812712147276542043334539529...'
      dc_HELP,←⊂'   ...329802184437989484872233686480420850069400034198779281...26085376'
      dc_HELP,←⊂'○  ⍵ refers to the result of the previous expression:'
      dc_HELP,←⊂'      ⍵=(2*3000)×2*100        ⍝ Is (2*3100) the same as (2*3000)×(2*100)'
      dc_HELP,←⊂'   1                          ⍝ YES!'
      dc_HELP,←⊂'○  Empty lines? Exit the desk calculator.'
      dc_HELP,←⊂'   (Lines consisting of 1 or more blanks are ignored).'
      dc_HELP,←⊂'○  To request dc_HELP info, enter a lone ? after the prompt:'
      dc_HELP,←⊂'      ?'
      dc_HELP,←⊂'○  ? is the usual random # function, when followed by a number:'
      dc_HELP,←⊂'      ? 12343224324342344342391095446'
      dc_HELP,←⊂'○  Functions:'
      dc_HELP,←⊂'   MONADIC*:   - + | × ÷ < > ! ? ⊥ ⊤ ⍎ ⍳ SQRT(√) NOT(~)'
      dc_HELP,←⊂'   DYADIC*:    + - × * ÷ ⌊ ⌈ | ∨ ∧ ⌽ √ ≢ SHIFTD SHIFTB DIVREM MOD MODMUL(MMUL)'
      dc_HELP,←⊂'   DYADIC*:    + - × * ÷ ⌊ ⌈ | ∨ ∧ ⌽ √ ≢ SHIFTD SHIFTB DIVREM MOD MODMUL(MMUL)'
      dc_HELP,←⊂'   SPECIAL:    →BI nnn:    Return nnn in internal format.'
      dc_HELP,←⊂'               ⍎BI nnn:    Return nnn in APL format. Error if exponent not in range for decimal float'
      dc_HELP,←⊂'               ⍕BI nnn:    Return nnn in external string format, with _ separator every 5 digits'
      dc_HELP,←⊂''
      dc_HELP,←⊂'     Return boolean: < ≤ = ≥ > ≠        Return integer: ⍴(length)'
      dc_HELP,←⊂'-------------------'
      dc_HELP,←⊂'  *All functions return integer strings (BIext) or internal-format BigInts (BIint), unless specified'
      dc_HELP,←⊂' **AND, OR, XOR, ~(FLIP) simulate bit-level logical operations as if arbitrary-length integers'
      dc_HELP,←⊂'--------------------------------------------'
      dc_HELP,←⊂'Press escape key to exit this screen'
      dc_HELP←↑dc_HELP

    ∇ dc;caller;code;lastResult;exprIn;exec;help;isShy;exprHelp
    ⍝ extern:  BigInt.dc_HELP (help information)
      help←{⎕PW←120  ⋄ (⎕THIS.⎕ED⍠'ReadOnly' 1)&'dc_HELP'}
      ⎕←'dc: big integer desk calculator.'
      ⎕←'To see brief HELP information, enter "?" at prompt.'
      ⎕←'To terminate dc mode, enter an empty line.'
      lastResult←'0' ⋄ exprHelp←,'?'
      :While 1
          :Trap 1000
              exprIn←⍞↓⍨≢⍞←'> '
              :If 0=≢exprIn ⋄ :Leave                     ⍝ Empty line:  Done
              :ElseIf 0=≢exprIn~' '                      ⍝ Blank line:  ignored
                 :Continue         
              :ElseIf exprHelp≡exprIn~' '                ⍝ Lone '?':    HELP
                  help 0 ⋄ :Continue
              :EndIf
              :Trap 0
                  caller←(1+⎕IO)⊃⎕RSI,#
                  code←0 BIC exprIn                      ⍝ ('\w'⎕S'\0')
                  exec←{⍵⍵:⍺⍎⍺⍺ ⋄ ⊢⎕←1∘prettify ⍺⍎⍺⍺}               ⍝ ⍎ sees ⍵←lastResult
                  isShy←×≢('^\(?(\w+(\[[^]]*\])?)+\)?←'⎕S 1⍠'UCP' 1)⊣code~' ' ⍝ Kludge to see if code has an explicit result.
                  lastResult←caller(code exec isShy)lastResult
              :Else
                  ⎕←{ dm0 dm1 dm2←⍵.DM ⋄ p←1+dm1⍳']' ⋄ (p↑dm1)←' ' ⋄ ↑dm0 dm1(' ',dm2) }⎕DMX
              :EndTrap
          :Else
              interrupt:
              :If ~1∊'nN'∊⍞↓⍨≢⍞←'Interrupted. Exit? Y/N [Yes] '
                  :Return 
              :EndIf
          :EndTrap  
      :EndWhile
    ∇
    :Endsection Utilities: bi, dc (desk calc), BIB, BIC 

    :Section Bigint Namespace - Postamble
        _namelist_←'BI_LIB bi bix BI BII BIB BIM BI BIB_HELP BIC BI∆HERE BIC_HELP BI_HELP BI∆HERE_HELP HELP RE∆GET'
        ___←0 ⎕EXPORT ⎕NL 3 4
        ___←1 ⎕EXPORT {⍵[⍋↑⍵]}{⍵⊆⍨' '≠⍵}  _namelist_
        ⎕PATH←⎕THIS{0=≢⎕PATH:⍕⍺⊣⎕← '⎕PATH was null. Setting to ''',(⍕⍺),''''⋄ ⍵}⎕PATH
        ⎕EX '___'
    :EndSection Bigint Namespace - Postamble

:EndNamespace
