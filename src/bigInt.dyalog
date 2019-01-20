:namespace bigInt
  ⍝ ∘ NOTE: See bigIntHelp for details...
  ⍝ ∘ Call bigInt.help or ⎕EDIT 'bigIntHelp'

  ⍝ Table of Contents
  ⍝   Preamble
  ⍝      Preamble Utilities
  ⍝      Preamble Variables
  ⍝   BI
  ⍝      BigInt Namespace and Utility Initializations
  ⍝      Executive
  ⍝      BigInt internal structure
  ⍝      Monadic Operands/Functions
  ⍝      Dyadic Operands/Functions
  ⍝      BI Special Functions/Operations (More than 2 Args)
  ⍝      Unsigned Utility Math Routines
  ⍝      Service Routines
  ⍝  Utilities
  ⍝      bi
  ⍝      dc (desk calculator)
  ⍝      BIB (bit manipulation)
  ⍝      BIC (BI math "compiler")
  ⍝      BI∆HERE (self-declared BI math function)
  ⍝  Postamble
  ⍝      Exported and non-exported Utilities


⍝ --------------------------------------------------------------------------------------------------
    :Section BI

    :Section PREAMBLE
    DEBUG←0    ⍝ Set DEBUG here only.

    :Section PREAMBLE -  Utilities
    ∇ trigger_DEBUG args
      :Implements Trigger DEBUG
    ⍝ Sets VERBOSE, ⎕TRAP, and ∇note∇ dynamically when DEBUG is set or reset.
      :If 1≡args.NewValue ⋄ args.Name,' set to',args.NewValue ⋄ :EndIf
      VERBOSE←VERBOSE_INITIAL∨DEBUG≠0                     ⍝ Force to 1 if DEBUG set.
      :If DEBUG ⋄ ∆ERR←⍬
      :Else ⋄ ∆ERR←0 1000
      :EndIf
      err←{⍺←1 ⋄ ⍺=0:_←⍵ ⋄ m←⍵ ⎕DMX.EM⊃⍨0=≢⍵ ⋄ ⎕SIGNAL/('bigInt: ',m)⎕DMX.EN}
      ⎕FX'{ok}←note str'('ok←1',VERBOSE/'⊣⎕←str')
    ∇
    ∇ {r}←loadHelp
      :Trap 0 ⋄ r←⎕SE.SALT.Load'-target=',(⍕⎕THIS.##),' pmsLibrary/src/bigIntHelp'
      :Else ⋄ r←⎕←'Unable to load bigIntHelp'
      :EndTrap
    ∇
    :EndSection PREAMBLE - Utilities
    :Section PREAMBLE - Variables
    VERBOSE_INITIAL←0          ⍝ Set VERBOSE initial value; reset if DEBUG changed...
    DEBUG←DEBUG                ⍝ Set DEBUG here or on the fly
    loadHelp                   ⍝ Load help at ⎕FIX (compile) time.
    ⎕IO ⎕ML←0 1 ⋄  ⎕PP←34 ⋄ ⎕CT←⎕DCT←0 ⋄ ⎕CT←1E¯14 ⋄ ⎕DCT←1E¯28   ⍝ For ⎕FR,  see below
    :EndSection PREAMBLE - Variables
    :EndSection PREAMBLE

    :Section Namespace and Utility Initializations
  ⍝+------------------------------------------------------------------------------+⍝
  ⍝+-- BI INITIALIZATIONS                            BI INITIALIZATIONS         --+⍝
  ⍝-------------------------------------------------------------------------------+⍝
  ⍝   ----------------------------------
  ⍝   INTERNAL-FORMAT BIs (BigInts)
  ⍝   ----------------------------------
  ⍝    BIi  -internal-format signed Big Integer numeric vector.
  ⍝          A BIV is a vector of radix <RX> numbers. The first (left-most) non-zero number carries the sign.
  ⍝          Other numbers may be signed, but it's ignored.
  ⍝          ∘ Leading zeros are removed in the canonical form. After imp/ort, zero is (0=≢⍵)
  ⍝          ∘ Some routines use (zro BIi) to make sure every BIi has at least one digit. See BIz.
  ⍝    BIu  -unsigned internal-format BIi (vector of integers):  (|BIi)
  ⍝    BIz  -signed internal-format BIi, but of form (zro ⍵), so that zero is return with exactly 1 digit 0.
  ⍝
  ⍝   EXTERNAL-FORMAT BIs (BigInts)
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
  ⍝    Int  -an APL-format single integer ⍵, often specified to be in range ⍵<RX.

  ⍝ ==================
  ⍝ setHandSizeInBits
  ⍝ ==================
  ⍝ {ok=1}←setHandSizeInBits ⍵:[nn | frType | 0]
  ⍝      nn:      number of bits per hand, ⍵ is between 2 and 45
  ⍝      frType:  either 645 or 1287, corresponding to the largest # of bits
  ⍝               for either ⎕FR=645 or 1287. ⍵ must be 645 or 1287
  ⍝      0:       choose best value, currently 20.  See brxBest below...
  ⍝
  ⍝   This function is available to test performance with different
  ⍝   "hand" sizes in bits (see below). The data field of each big integer consists
  ⍝   of zero or more APL integers, each a non-negative number of <nn> or fewer bits.
  ⍝   Each integer-- as stored-- is 32 or fewer bits; they are sized and ⎕FR is
  ⍝   adjusted so that any intermediate which overflows still fits in the mantissa
  ⍝   of the largest storage format, either a 64-bit binary real (mantissa: 53 bits) or
  ⍝   as 128-bit decimal float (mantissa: 93-bits). While floats won't be seen unless there is
  ⍝   overflow, there is a balance between handling large numbers of hands (vectors)
  ⍝   and integer vs float math (notably with decimal floats, which are very slow).
  ⍝
  ⍝   >>> From initial tests, 20-bits (⍵=0 → the default) works well everywhere.
  ⍝   >>> Why not 26, which still fits in Float 64 during overflow?
  ⍝   >>> Possibly because OFL (overflow threshold for mult.) becomes
  ⍝       smaller than optimal with 26 bits than with 20.
  ⍝---------------------
  ⍝   setHandSizeInBits: sets all the key constants:
  ⍝       RX, DRX, BRX, OFL, and ⎕FR.
  ⍝
  ⍝   Good Values for BRX (radix, i.e. hand size, in bits)
  ⍝     20     Fastest for all functions, except multiplication, where 40 is faster..
  ⍝     40     Slightly faster for multiplication, but slower than 20 for other operations.
  ⍝
  ⍝     BRX   Stored    Overflow   Overflow    Max Poss
  ⍝     Bits  Type      Bits (×)   Type          Bits (Types are always Signed in APL)
  ⍝     20    32-bit    40         Float 64       53
  ⍝     26    32-bit    52         Float 64       53
  ⍝     30    32-bit    60         Dec Flt 128    93
  ⍝     45    32-bit    90         Dec Flt 128    93
  ⍝
  ⍝ =====================================================================================
  ⍝ RX:  Radix for internal BI integers.
  ⍝ DRX: # Decimal digits that RX must hold.
  ⍝ BRX: # Binary  digits required to hold DRX digits. (See encode2Bits, decodeFromBits).
  ⍝ OFL: For multiplies (mulU) of unsigned big integers ⍺ × ⍵,
  ⍝      the length (in # of hands, i.e. base RX digits) of the larger of ⍺ and ⍵,
  ⍝      beyond which digits must be split to prevent overflow.
  ⍝      OFL is a function of the # of guaranteed mantissa bits in the largest (float) number used
  ⍝      AND the radix RX, viz.   ⌊mantissa_bits ÷ RX×2, since it's the potential accumulated bits of ⍺×⍵.
  ⍝ ⎕FR: Whether floating rep is 64-bit float (53 mantissa bits, and fast)
  ⍝      or 128-bit decimal (93 mantissa bits and much slower)..
    ∇ {ok}←{verbose}setHandSizeInBits brx;brxBest;brxMax;brxMid;eBAD
    ⍝ Set key constants/initial values...
      verbose←1='verbose'{0=⎕NC ⍺:⍵ ⋄ ⎕OR ⍺}0
      brxBest←20                    ⍝ "Ideal" default for BRX
      brxMid brxMax←⌊53 93÷2        ⍝ Max bits to fit in Binary(645) and Dec Float (1287) resp.
    ⍝ Handle frType and 0; ensure brx in proper range...
       ⋄ eBAD←'bigInt: invalid max bits for big integer base'
      eBAD ⎕SIGNAL 11/⍨(0≠1↑0⍴brx)∨(1≠≢brx)
      brx←(∊brxMax brxMid brxBest brx)[1287 645 0⍳brx]  ⍝ frType or 0 → BRX equivalents
      :If brx>brxMax ⋄ :OrIf brx<2
           ⋄ eBAD←'bigInt: bits for internal base must be integer in range 2..',⍕brxMax
          11 ⎕SIGNAL⍨eBAD
      :EndIf
    ⍝ Set key bigInt constants...
      ⎕FR←645 1287⊃⍨brx>brxMid
      BRX←brx
      DRX←⌊10⍟2*BRX
      RX←10*DRX ⋄ RXdiv2←RX÷2  ⍝ RXdiv2: see ∇powU∇
      OFL←{⌊(2*⍵)÷RX×RX}(⎕FR=1287)⊃53 93
    ⍝ Report...
      :If verbose
          ⎕←'nbits in radix(*)  BRX   ',BRX
          ⎕←'Floating rep       ⎕FR   ',⎕FR,' in namespace ',⍕⎕THIS
          ⎕←'ndigits in radix   DRX   ',DRX
          ⎕←'Radix (10*DRX)     RX    ',¯3⍕RX
          ⎕←'max ⍵ for ⍵×⍵ (**) OFL   ',OFL
          ⎕←'*   Radix: Each bigInt is composed of 0 or more integers (hands),'
          ⎕←'    each between 0 and RX-1, and a sign'
          ⎕←'**  OFL: maximum # of "hands" in bigInt ⍵ allowed before splitting ⍵'
          ⎕←'    into smaller numbers to avoid multiplication overflow.'
          ⎕←'*** ⎕FR 645: 53 bits avail;  1287: 93 bits available'
      :EndIf
      ok←1
    ∇
    0 setHandSizeInBits 0

  ⍝ Data field (unsigned) constants
    zeroUD←,0         ⍝ data field ZERO, i.e. unsigned canonical ZERO
    oneUD←,1          ⍝ data field ONE, i.e. unsigned canonical ONE
    twoUD←,2          ⍝ data field TWO

  ⍝ Error messages. All will be used with fn <err> and ⎕SIGNAL 911: BigInt DOMAIN ERROR
    eBADBI   ←'Invalid BigInteger'
    eNONINT  ←'Invalid BigInteger: APL number not a single integer: '
    eSMALLRT ←'Right argument must be a small APL integer ⍵<',⍕RX
    eCANTDO1 ←'Monadic function not implemented as BI operand: '
    eCANTDO2 ←'Dyadic function not implemented as BI operand: '
    eINVALID ←'Format of big integer is not valid: '
    eFACTOR  ←'Factorial (!) argument must be ≥ 0'
    eBADRAND ←'Roll (?) argument must be >0'
    eSQRT    ←'sqrt: arg must be non-negative'
    eTIMES2  ← eSMALLRT
    eTIMES10 ← eSMALLRT
    eBIC     ←'BIC argument must be a fn name or one or more code strings.'
    eBITSIN  ←'BigInt: Importing bits requires arg to contain only boolean integers'

    :EndSection Namespace and Utility Initializations

    :Section Executive
    ⍝ --------------------------------------------------------------------------------------------------

    ⍝ listMonadFns   [0] single-char symbols [1] multi-char names
    ⍝ listDyadFns    ditto
    listMonadFns←'-+|×÷<>!?⊥⊤⍎→√⍳~'('SQRT' 'NOT')
    ⍝            reg. fns       boolean  names
    listDyadFns←('+-×*÷⌊⌈|∨∧⌽√','<≤=≥>≠')('SHIFTD' 'SHIFTB' 'DIVIDEREM' 'DIVREM' 'MOD' 'MODMUL' 'MMUL' 'AND' 'OR' 'XOR')


    ⍝ BI: Basic utility operator for using APL functions in special BigInt meanings.
    ⍝     BIi ← ∇ ⍵:BIx
    ⍝     Returns BIi, an internal format BigInteger structure (sign and data, per above).
    ⍝     See below for exceptions ⊥ ⊤ ⍎
    ⍝ BIX:Basic utility operator built on BI.
    ⍝     BIx ← ∇ ⍵:BIx
    ⍝     Returns BIx, an external string-format BigInteger object ("[¯]\d+").


⍝ --------------------------------------------------------------------------------------------------
      _BI_src←{⍺←⊢
          ∆ERR::⎕SIGNAL/⎕DMX.(('bigInt: ',EM)EN)
        ⍝ _BI_src is a template for ops BI and BIX.
        ⍝ ⍺⍺ → fn
        ⍝ fn is always a scalar (either simple or otherwise);
        ⍝ If ⍺⍺ has a ⍨ suffix (⍺⍺ may be an APL primitive/s or a string),
        ⍝ then fn←¯1↓fn and inv (inverse) is set:
        ⍝      to 1, if BI/X was called 2-adically;
        ⍝      to 2, if called 1-adically (   ×⍨BI 3 ==> 3 ×BI 3).
          fn monad inv←(1≡⍺ 1){'⍨'=¯1↑⍵:(¯1↓⍵)0(1+⍺) ⋄ ⍵ ⍺ 0
          }⍺⍺{aa←⍺⍺ ⋄ 3=⎕NC'aa':⍕⎕CR'aa' ⋄ 1(819⌶)aa}⍵
          CASE←1∘∊(atom fn)∘≡∘⊆¨∘⊆       ⍝ CASE ⍵1 or CASE ⍵1 ⍵2..., where at least one ⍵N is @CV, others can be @CS.
     
          ⍝ Monadic...
          monad:{                              ⍝ BIX: ∆exp∆: See Build BIX/BI below.
              CASE'-':∆exp∆ negate ⍵           ⍝     -⍵
              CASE'+':∆exp∆ ∆ ⍵                ⍝     nop, except makes sure obj is valid in BIi form.
              CASE'|':∆exp∆ magnitude ⍵        ⍝     |⍵
              CASE'×':∆exp∆⊃∆ ⍵                ⍝     ×⍵ signum:  Returns APL int (∊¯1 0 1), not BI.
              CASE'÷':∆exp∆ reciprocal ⍵       ⍝     ÷⍵:         Why bother?
              CASE'<':∆exp∆ decrement ⍵        ⍝     ⍵-1:        Optimized for constant in ⍵-1.
              CASE'>':∆exp∆ increment ⍵        ⍝     ⍵+1:        Optimized for constant in ⍵+1.
              CASE'!':∆exp∆ factorial ⍵        ⍝     !⍵          For smallish integers ⍵≥0
              CASE'?':∆exp∆ roll ⍵             ⍝     ?⍵:         For int ⍵>0 (0 invalid)
              CASE'⊥':∆exp∆ bitsIn ⍵           ⍝     bits→BI:    Converts from bit vector (BIB) to BI internal
              CASE'⊤':bitsOut ∆ ⍵              ⍝     BI→bits:    Converts a BI ⍵ to its bit form, a BIB bit vector
              CASE'~' 'NOT':not ⍵    ⍝
              CASE'⍎':⍎exp ∆ ⍵                 ⍝     BIi→int:    If in range, returns a std APL number; else error
              CASE'←':∆ ⍵                      ⍝     BIi out:    Returns the BI internal form of ⍵: BRX-bit signed integers
              CASE'⍕':exp ∆ ⍵                  ⍝     BIi→BIx:    Takes a BI internal form vector of integers and returns a BI string
              CASE'SQRT' '√':exp sqrt ⍵        ⍝     ⌊⍵*0.5:     See dyadic *
              CASE'⍳':⍳∆2Small ⍵               ⍝     ⍳: Special case: Allow only small integers... Returns an APL # only.
              0::err eCANTDO1,,⎕FMT #.FN∘←fn  ⍝ Didn't recognize it. Assume it's an APL-only fn
          }⍵
        ⍝ Dyadic...
          ⍝ See discussion of ⍨ above...
          ⍺{
              ⍝ High Use: [Return BigInt]
              CASE'+':∆exp∆ ⍺ plus ⍵
              CASE'-':∆exp∆ ⍺ minus ⍵
              CASE'×':∆exp∆ ⍺ times ⍵
              CASE'⌽':∆exp∆ ⍵ times2Exp ⍺               ⍝  ⍵×2*⍺,  where ±⍵. Binary shift.
              CASE'÷':∆exp∆ ⍺ divide ⍵                  ⍝  ⌊⍺÷⍵
              CASE'*':∆exp∆ ⍺ power ⍵                   ⍝ Handles ⍺*BI 0.5 and ⍺*BI '0.5' as special cases.
              CASE'|':∆exp∆ ⍺ residue ⍵                 ⍝ residue: |   (⍺ | ⍵) <==> (⍵ modulo a)
          ⍝ Logical: [Return single binary]
              CASE'<':⍺ lt ⍵
              CASE'≤':⍺ le ⍵
              CASE'=':⍺ eq ⍵
              CASE'≥':⍺ ge ⍵
              CASE'>':⍺ gt ⍵
              CASE'≠':⍺ ne ⍵
          ⍝ bits
              CASE'AND':∆exp∆ ⍺ and ⍵
              CASE'OR':∆exp∆ ⍺ or ⍵
              CASE'XOR':∆exp∆ ⍺ xor ⍵
          ⍝ gcd/lcm: [Return BigInt]                    ⍝ ∨, ∧ return bigInt.
              CASE'∨':∆exp∆ ⍺ gcd ⍵                     ⍝ ⍺∨⍵ as gcd.
              CASE'∧':∆exp∆ ⍺ lcm ⍵                     ⍝ ⍺∧⍵ as lcm.
          ⍝
              CASE'√' 'ROOT':∆exp∆ ⍺ root ⍵             ⍝ See ∇root.
              CASE'MOD':∆exp∆ ⍵ residue ⍺               ⍝ modulo:  Same as |⍨
              CASE'SHIFTB':∆exp∆ ⍺ times2Exp ⍵          ⍝  ⍺×2*⍵,  where ±⍵. Binary shift.
              CASE'SHIFTD':∆exp∆ ⍺ times10Exp ⍵         ⍝  ⍺×10*⍵, where ±⍵. Decimal shift
              CASE'DIVIDEREM' 'DIVREM':∆exp∆¨⍺ divideRem ⍵ ⍝ Returns pair:  (⌊⍺÷⍵) (⍵|⍺)
              CASE'MODMUL' 'MMUL':∆exp∆ ⍺ modMul ⍵      ⍝ ⍺ modMul ⍵0 ⍵1 ==> ⍵1 | ⍺ × ⍵0.
              err eCANTDO2,,⎕FMT #.FN∘←fn               ⍝ Not found!
          }{0=inv:⍺ ⍺⍺ ⍵ ⋄ 1=inv:⍵ ⍺⍺ ⍺ ⋄ ⍵ ⍺⍺ ⍵}⍵      ⍝ Handle ⍨
      }
    ⍝ Build BIX/BI.
    ⍝ BIX: Change ∆exp∆ to string imp.
    ⍝ BI:  Change ∆exp∆ to null string. Use name BI in place of BIX.
    note'Created operator BI' ⊣⎕FX'_BI_src' '∆exp∆¨?'⎕R'BI' ''⊣⎕NR'_BI_src'
    note'Created operator BIX'⊣⎕FX'_BI_src' '∆exp∆'  ⎕R 'BIX' 'exp'⊣⎕NR'_BI_src'
    _←⎕EX '_BI_src'
    note'BI/BIX Operands:'
    note ⎕FMT(' Monadic:'listMonadFns),[¯0.1]' Dyadic: 'listDyadFns
    note 55⍴'¯'
    :EndSection BI Executive
    ⍝ ----------------------------------------------------------------------------------------

    :Section BigInt internal structure
    ⍝ An internal BI, BIi, is of this form:
    ⍝    sign data,
    ⍝       sign: a scalar integer in ¯1 0 1                     sign:IS∊¯1 0 1
    ⍝       data: an unsigned integer vector ⍵, where ⍵∧.<RX.    data:UV
    ⍝    Together sign and data define a big integer.
    ⍝    If sign=0, data≡,0 when returned from functions. Internally, extra leading 0's may appear.
    ⍝    If sign≠0, data may not be 0 (i.e. data∨.≠0).

      ⍝ ============================================
      ⍝ import / imp / ∆ - Import to internal bigInteger
      ⍝ ============================================
      ⍝ ∆  - internal alias for import
      ⍝    from: external-format (BIc) (⍺ and) ⍵--
      ⍝          each either a BigInteger string or an APL integer--
      ⍝    to:   internal format (BIi) BigIntegers (⍺' and) ⍵',
      ⍝          each of the form sign (data), where data is an integer vector.
      ⍝ ∆: [BIi] BIi ← [⍺@BIx] ∇ ⍵@BIx
      ⍝    Monadic: Returns for ⍵, (sign data)_of_⍵ in the format above.
      ⍝    Dyadic:  Returns for ⍺ ⍵, (sign data)_of_⍺ (sign data)_of_⍵.
      ⍝
      ⍝ To be fast, we have these tests and assumed types...
      ⍝ If   80|⎕DR ⍵       assume...                    ⎕DR
      ⍝ ---------------+--------------------------------------
      ⍝       0             ∆str                         80, 160, 320
      ⍝       3             ∆int (integer)               83...
      ⍝       5, 7          ∆aplNum (integer @ float)    645, 1287
      ⍝       6             BIi (internal)               326
      ⍝ Output: BIi, i.e.  (sign (,ints)), where ints∧.<RX
      ⍝
      import←{⍺←⊢ ⋄ em←'bigInt: Importing invalid object: '
          0::11 ⎕SIGNAL⍨em,⍕⍵
          1≢⍺ 1:(import ⍺)(import ⍵)
          ⋄ type←80|⎕DR ⍵ ⋄ dep←≡⍵
          (dep=¯2)∧6=type:⍵                 ⍝ BIi
          1<|dep:∘                          ⍝ Not 1-elem.
          3=type:∆int ⍵                     ⍝ int (small or otherwise)
          0=type:∆str ⍵                     ⍝ String
          5 7∊⍨type:∆aplNum ⍵                  ⍝ Float-format integer (e.g. 3E45)
          ∘
      }
    ∆←import ⋄ imp←import
  ⍝ importU, impU:
  ⍝     import ⍵ as unsigned bigInt (data portion only)
    importU←{⊃⌽imp ⍵} ⋄ impU←importU

      ⍝ ∆aplNum: Convert an APL integer into a BIi
      ⍝ Converts simple APL native numbers, as well as those with large exponents, e.g. of form:
      ⍝     1.23E100 into a string '123000...000', ¯1.234E1000 → '¯1234000...000'
      ⍝ These must be in the range of decimal integers (up to +/- 1E6145).
      ⍝ (If not, use big integer strings of any length, without exponents).
      ⍝ Normally, ∆aplNum is not called by the user, since BI and BIX call it automatically.
      ⍝ Usage:
      ⍝    ?BIX 1E100 calls (bigInt.∆aplNum 1E100), equivalent to   ?BIX '1',100⍴'0'
      ∆int←{
          1≠≢⍵:err eNONINT,⍕⍵            ⍝ scalar only...
          RX>u←,|⍵:(×⍵)(u)               ⍝ Small integer
          (×⍵)(zro RX⊥⍣¯1⊣u)             ⍝ Integer
      }
      ∆aplNum←{⎕FR←1287 ⍝ 1287: to handle large exponents
          (1=≢⍵)∧(⍵=⌊⍵):(×⍵)(zro RX⊥⍣¯1⊣|⍵)
          err eNONINT,⍕⍵
      }
      ⍝ ∆str: Convert a BIstr (BI string) into a BIi
      ∆str←{
          s←1 ¯1⊃⍨'-¯'∊⍨1↑⍵     ⍝ Get sign, if any
          w←'_'~⍨⍵↓⍨s=¯1        ⍝ Remove initial sign and embedded _ (spacer).
          (0=≢w)∨0∊w∊⎕D:err eBADBI  ⍝ w must include only ⎕D and at least one.
          d←dlzs rep ⎕D⍳w       ⍝ d: data portion of BIi
          ∆z s d                ⍝ If d is zero, return zero. Else (s d)
      }
      ⍝ ∆2Small: Import ⍵ only if it is a small integer. Returns an integer!
      ∆2Small←{
          s w←∆ ⍵ ⋄ 1≠≢w:err eSMALLRT
          s×,w
      }
    ⍝ ---------------------------------------------------------------------
    ⍝ export / exp: EXPORT a SCALAR BI to external "standard" bigInteger
    ⍝ ---------------------------------------------------------------------
    ⍝    r:BIc ← ∇ ⍵:BIi
      export←{
          sw w←⍵
          sgn←(sw=¯1)/'¯'
          sgn,⎕D[dlzs,⍉(DRX⍴10)⊤|w]
      }
    exp←export
    ⍝ ∆z:  r:BIi ←∇ ⍵:BIi
    ⍝      If ⍵:BIi has data≡zeroUD, then return (0 zeroUD).
    ⍝      Else return ⍵ w/ leading zero deleted.
    ∆z←{ zeroUD≡zro dlz⊃⌽⍵: 0 zeroUD ⋄ ⍵}
    ⍝
    ⍝ ∆zU2I: If ⍵:BIu IS zeroUD, then return (zeroUD ⍵); else ⍺ ⍵
    ∆zU2I←{zeroUD≡⍵:zeroUD ⍵ ⋄ ⍺ ⍵}

    :EndSection BigInt internal structure
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Monadic Operands/Functions
    ⍝ function / _function -- a family of related math functions.
    ⍝ function:  Takes its args and imports them (fast if already an internal bigInt).
    ⍝ _function: Requires its arguments already to be internal bigInts (or error).
    ⍝
    ⍝ function + alias1 + ...
    ⍝ The first name will be the APL std name (exceptions noted), followed by
    ⍝ abbreviations and common alternatives.  E.g. monadic | is called  magnitude, but we also call it abs.
    ⍝ Each name (negate, etc.) has a version (_negate) that assumes data already imported...
    ∇ {__name}←genVariants __name;__in;__out
      __in←__name'←∆ +⍵' '←⍺ +∆ +⍵'
      __out←('_',__name)'←⍵' '←⍺ ⍵'
      :If ' '≠1↑0⍴⎕FX(__in ⎕R __out⊣⎕NR __name)
          'Unable to create function _',__name
      :EndIf
    ∇

    ⍝ negate / _negate
      negate←{                          ⍝ -
          (sw w)←∆ ⍵
          (-sw)w
      }
    neg←negate
    ⍝ direction / _direction
      direction←{                       ⍝ ×
          (sw w)←∆ ⍵
          sw(|sw)
      }
    signum←direction
    sig←direction
      magnitude←{                       ⍝ |
          (sw w)←∆ ⍵
          (|sw)w
      }
    abs←magnitude

    ⍝ increment:                        ⍝ ⍵+1
      increment←{
          (sw w)←∆ ⍵
          sw=0:1 oneUD                     ⍝ ⍵=0? Return 1.
          sw=¯1:∆z sw(⊃⌽decrement 1 w)     ⍝ ⍵<0? inc ⍵ becomes -(dec |⍵). ∆x handles 0.
          î←1+⊃⌽w                          ⍝ trial increment (most likely path)
          RX>î:sw w⊣(⊃⌽w)←î                ⍝ No overflow? Increment and we're done!
          sw w plus 1 oneUD                ⍝ Otherwise, do long way.
      }
    inc←increment
    ⍝ decrement:                        ⍝ ⍵-1
      decrement←{
          (sw w)←∆ ⍵
          sw=0:¯1 oneUD                    ⍝ ⍵ is zero? Return ¯1
          sw=¯1:∆z sw(⊃⌽increment 1 w)     ⍝ ⍵<0? dec ⍵  becomes  -(inc |⍵). ∆z handles 0.
                                           ⍝ If the last digit of w>0, w-1 can't underflow.
          0≠⊃⌽w:∆z sw w⊣(⊃⌽w)-←1           ⍝ No underflow?  Decrement and we're done!
          sw w minus 1 oneUD               ⍝ Otherwise, do long way.
      }
    dec←decrement

      not←{
          sw bw←bitsView ⍵
          sw bitsInUS~bw
      }

    ⍝ fact: compute BI factorials.
    ⍝       r:BIc ← fact ⍵:BIx
    ⍝ We allow ⍵ to be of any size, but numbers larger than DRX are impractical.
    ⍝ We deal with 3 cases:
    ⍝    ⍵ ≤ 31:    We let APL calculate, with ⎕PP←34.   Fast.
    ⍝    ⍵ ≤ DRX:   We calculate r as a BigInt, while counting down ⍵ as an APL integer. Moderately fast.
    ⍝    Otherwise: We calculate entirely using BigInts for r and ⍵. Slowwwwww.
      factorial←{                           ⍝ !⍵
          aw w←∆ ⍵
          aw=0:0 zeroUD                     ⍝ !0
          aw=¯1:err eFACTOR                 ⍝ ⍵<0
          factBig←{
              1=≢⍵:⍺ factSmall ⍵            ⍝ Skip to factSmall when ≢⍵ is 1 hand.
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
    ⍝    r:BIi ← ∇ ⍵:BIi   ⍵>0.
    ⍝ With inL the # of dec digits in ⍵, excluding any leading '0' digits...
    ⍝ Proceed as shown here, where (exp ⍵) is "exported" BI format; (∆ ⍵) is internal BI format.
      roll←{
          aw w←∆ ⍵
          aw≠1:err eBADRAND
          ⎕PP←16 ⋄ ⎕FR←645                       ⍝ 16 digits per ?0 is optimal
          inL←≢exp aw w                          ⍝ ⍵: in exp form. in: ⍵ with leading 0's removed.
     
          res←inL⍴{                              ⍝ res is built up to ≥inL random digits...
              ⍺←''                               ⍝ ...
              ⍵≤≢⍺:⍺ ⋄ (⍺,2↓⍕?0)∇ ⍵-⎕PP          ⍝ ... ⎕PP digits at a time.
          }inL                                   ⍝ res is then truncated to exactly inL digits
          '0'=⊃res:∆ res                         ⍝ If leading 0, guaranteed (∆ res) < ⍵.
          ⍵ residue ∆ res                        ⍝ Otherwise, compute residue r: 0 ≤ r < ⍵.
      }

  ⍝ bitsOut, bitsIn: Manage one or more BRX-bit integers (e.g. 20 etc.) stored in APL 32-bit integers.
  ⍝     bitsOut:   r:boolean array ←  ∇ ⍵:BIi
  ⍝     bitsIn:    r:BIc           ←  ∇ ⍵:BIi
  ⍝'
  ⍝ The resulting bitstring will always have the lowest-order bit
  ⍝ as the rightmost bit (as in APL).
  ⍝ Bitstrings are bit representations
  ⍝ of standard signed numbers, twos complement
  ⍝
  ⍝ bitsOut will always put out a vector of bits of length l, where 1=BRX|l, i.e. 21, 42, etc.
  ⍝
  ⍝ bitsIn will accommodate an external bit-string of any length. It will import as a series
  ⍝ of signed BRX-bit integers, padding on the right with 0s.
  ⍝
      bitsOut←{ ⍝ ⍵:bigInt
          aw w←∆ ⍵                   ⍝ sg: ¯1 for neg, or 0.
          ,⍉1↓[0](0,BRX⍴2)⊤aw×|w     ⍝ make sure all ints are signed, so all fit 2s complement bit string.
      }
      bitsView←{
          ⍝ From bigInt, returns (sign)(bitInt-as-bits)
          aw w←∆ ⍵
          aw(,⍉1↓[0](0,BRX⍴2)⊤aw×|w)
      }
      bitsView2←{
          sa ba←bitsView ⍺ ⋄ sw bw←bitsView ⍵
          m←(≢ba)⌈≢bw
          pad←{⍺≥0:⍺(⍵↑⍨-m) ⋄ ⍺(⍵,⍨1⍴⍨m-≢⍵)}
          (sa pad ba)(sw pad bw)
      }

  ⍝ bitsOutU: Convert unsigned BIu to bits
    ⍝ bitsOutU: Take an unsigned bigInt, return bits
      bitsOutU←{
          ,⍉1↓[0](0,BRX⍴2)⊤⍵
      }
      bitsIn←{ ⍝ ⍵:bits
          b←,⍵
          0∊b∊0 1:err eBITSIN        ⍝ Validate
        ⍝ sign comes from the first, leftmost bit...
          sg←0 ¯1⊃⍨⊃b                ⍝ sg: either ¯1 for neg, or 0. For use in ⊥
          n←⌈BRX÷⍨¯1+≢b
          i←|2⊥⍉sg,n BRX⍴(-n×BRX)↑b  ⍝
          (×sg)i
      }

    ⍝ bitsInUS: Takes a set of bits (no sign bit) and return a signed integer.
    ⍝ Unsigned bitsInUS (bits no sign bit → |BIi) and bitsOutU (BIu → bits)
    ⍝ ⍺: Take sign bit from external routine...
    ⍝    Used internally, so no validation that ⍵ is only bits
      bitsInUS←{⍺←1
          n←⌈BRX÷⍨¯1+≢b←,⍵
          i←|2⊥⍉n BRX⍴(-n×BRX)↑b
          (⍺×1∊b)i                 ⍝ sign is 0 if b has only 0 bits
      }
    ⍝ (int)root: A fast integer nth root.
    ⍝ x ← nth root N  ==>  x ← N *÷nth
    ⍝   nth: a small, positive integer (<RX); default 2 (for sqrt).
    ⍝   N:   any BIx
    ⍝   x:   the nth root as an internal big integer.
    ⍝   ∘ Uses Fredrick Johanssen's algorithm with optimization for APL integers.
    ⍝   ∘ Estimator based on guesstimate for sqrt N, no matter what root.
    ⍝     (Better than using N).
    ⍝   ∘ As fast for sqrt as a "custom" version.
    ⍝   ∘ If N is small, calculate directly via APL.
    ⍝ x:BIi ← nth:small_(BIi|BIx) ∇ N:(BIi|BIx)>0
      root←{
        ⍝ Check nth in  N*÷nth
          ⍺←2 ⍝ sqrt...
          sgn invNth nth←⍺{
              ⍵:1 0.5 2
              sgn nth←bi.imp ⍺
              sgn=0:eROOT ⎕SIGNAL 11
              1<≢nth:eROOT ⎕SIGNAL 11
              nth←⊃nth
              sgn(÷nth)nth
          }900⌶⍬
          sgn<0:0    ⍝  ⌊N*÷nth ≡ 0, if nth<0 (nth a small int)
        ⍝ Check N
          N←imp ⍵
          0=⊃N:N                        ⍝  0=×N?   0
          ¯1=⊃N:eROOT ⎕SIGNAL 11        ⍝ ¯1=×N?   error
          1=ndig←≢⊃⌽N:1(⌊invNth*⍨⊃⌽N)   ⍝ N small? Let APL calc value
        ⍝ Initial estimate for N*÷nth must be ≥ the actual solution, else this will terminate prematurely.
        ⍝ Initial estimate (x):
        ⍝   DECIMAL est: ¯1+10*⌈(# dec digits in N)÷2
        ⍝   BINARY  est:  2*⌈(numbits(N)÷2)
          x←{ ⍝ We use est(sqrt N) as initial estimate for ANY root. Not ideal, but safe.
              0::1((⌈invNth*⍨⊃⊃⌽N),(RX-1)⍴⍨⌈0.5×ndig-1) ⍝ Too big for APL est. Use DECIMAL est. ↑
              ⎕FR←1287
              imp 1+⌈invNth*⍨⍎exp ⍵               ⍝ Est from APL: works for ⍵ ≤ ⌊/⍬
          }N
        ⍝ Refine x, i.e. ⍵, until y > x
          {
              y←(⍵ _plus N _divide ⍵)_divide nth  ⍝ y is next guess: y←⌊((x+⌊(N÷x))÷nth)
              y _ge ⍵:⍵
              ∇ y                              ⍝ y is smaller than ⍵. Make x ← y and try another.
          }x
      }
    eROOT←'bigInt.root: root (⍺) must be small non-zero integer ((|⍺)<',(⍕RX),')'
    sqrt←root

  ⍝ oneDiv:  ÷⍵ ←→ 1÷⍵ Almost useless, since ÷⍵ is 0 unless ⍵ is 1 or ¯1.
    oneDiv←{{0=≢⍵: ÷0 ⋄ 1≠≢⍵:0 ⋄ 1=|⍵:⍵ ⋄ 0}dlzs ⍵}

  ⍝ genVariants: For negate, create related _negate, such that
  ⍝        _negate import ⍵   <==> negate ⍵
  ⍝ etc.
    genVariants¨ 'negate' 'neg' 'direction' 'signum' 'sig' 'abs' 'increment' 'inc'
    genVariants¨ 'decrement' 'dec' 'factorial' 'fact' 'roll' 'bitsOut'

    :Endsection BI Monadic Functions/Operands
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Dyadic Functions/Operations
  ⍝ dyad:    compute all supported dyadic functions
  ⍝ The first name will be the APL std name (exceptions noted), followed by
  ⍝ abbreviations and common alternatives.
  ⍝ E.g. dyadic | is called  residue, but we also define mod/ulo as residue⍨.
  ⍝ Each name (minus, etc.) has a version (_minus) that assumes data already imported...

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
     
          sa≠sw:sa(ndnZ 0,+⌿a mix w)           ⍝ 5-¯3 → 5+3 ; ¯5-3 → -(5+3)
          <cmp a mix w:(-sw)(nupZ-⌿dck w mix a)    ⍝ 3-5 →  -(5-3)
          sa(nupZ-⌿dck a mix w)                ⍝ a≥w: 5-3 → +(5-3)
      }
    subtract←minus
    sub←minus
      times←{
          (sa a)(sw w)←⍺ ∆ ⍵
          0∊sa,sw:0 zeroUD
          oneUD≡a:(sa×sw)w
          oneUD≡w:(sa×sw)a
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
          ((sa×sw)∆zU2I div)(sw ∆zU2I rem)
      }
    divRem←divideRem
    ⍝ ⍺ power ⍵: Handles ⍵≡0.5 or '0.5'. The string must match EXACTLY ('00.5' will fail)
      power←{
          (⊂⍵)∊0.5 '0.5':sqrt ⍺    ⍝  ⍺ power 0.5 → sqrt ⍺
          (sa a)(sw w)←⍺ ∆ ⍵
          sa sw∨.=0 ¯1:0 zeroUD    ⍝ r←⍺*¯⍵ is 0≤r<1, so truncates to 0.
          p←a powU w
          sa≠¯1:1 p                ⍝ sa= 1 (can't be 0).
          0=2|⊃⌽w:1 p              ⍝ ⍺ is neg, so result is pos. if ⍵ is even.
          ¯1 p
      }
    pow←power
      residue←{                    ⍝ residue. THIS FOLLOWS APL'S DEFINITION (base on left)
          (sa a)(sw w)←⍺ ∆ ⍵
          sw=0:0 zeroUD
          sa=0:sw w
          r←,a remU w              ⍝ remU is fast if a>w
          sa=sw:∆z sa r            ⍝ sa=sw: return (R)        R←sa r
          zeroUD≡r:0 zeroUD        ⍝ sa≠sw ∧ R≡0, return 0
          ∆z sa a minus sa r       ⍝ sa≠sw: return (A - R')   A←sa a; R'←sa r
      }
    modulo←{⍵ residue ⍺}           ⍝ modulo←residue⍨
    mod←modulo

    ⍝ times2Exp:  Shift ⍺:BIx left or right by ⍵:Int binary digits
    ⍝  r:BIi ← ⍺:BIi   ∇  ⍵:aplInt
    ⍝     Note: ⍵ must be an APL integer (<RX).
    ⍝  -  If ⍵>0: shift ⍺ left by ⍵-decimal digits
    ⍝  -  If ⍵<0: shift ⍺ rght by ⍵ decimal digits
    ⍝  -  If ⍵=0: then ⍺ will be unchanged
    ⍝ GMP: mul_2exp
      times2Exp←{
          shiftU←{⍵<0:0,⍵↓⍺ ⋄ ⍺,⍵⍴0}             ⍝ <bits> shift <degree> (left=pos.)
          (sa a)(sw w)←⍺ ∆ ⍵
          1≠≢w:err eTIMES10                       ⍝ ⍵ must be small integer.
          sa=0:0 zeroUD                           ⍝ ⍺ is zero: return 0.
          sw=0:sa a                               ⍝ ⍵ is zero: ⍺ stays as is.
          sa bitsInUS(bitsOutU a)shiftU sw×w
      }
    mul2Exp←times2Exp
      div2Exp←{
          ⍺ times2Exp negate ⍵
      }
    shiftBinary←times2Exp
    shiftB←times2Exp

    ⍝ times10Exp: Shift ⍺:BIx left or right by ⍵:Int decimal digits.
    ⍝      Converts ⍺ to BIc, since shifts are a matter of appending '0' or removing char digits from right.
    ⍝  r:BIi ← ⍺:BIi   ∇  ⍵:Int
    ⍝     Note: ⍵ must be an APL integer (<RX).
    ⍝  -  If ⍵>0: shift ⍺ left by ⍵-decimal digits
    ⍝  -  If ⍵<0: shift ⍺ rght by ⍵ decimal digits
    ⍝  -  If ⍵=0: then ⍺ will be unchanged
      times10Exp←{
          (sa a)(sw w)←⍺ ∆ ⍵
          1≠≢w:err eTIMES10                        ⍝ ⍵ must be small integer.
          sa=0:0 zeroUD                            ⍝ ⍺ is zero: return 0.
          sw=0:sa a                                ⍝ ⍵ is zero: ⍺ stays as is.
          ustr←export 1 a                          ⍝ ⍺ as unsigned string
          ss←'¯'/⍨sa=¯1                            ⍝ sign as string
          sw=1:∆ ss,ustr,w⍴'0'                     ⍝ sw =1
          {0=≢⍵:zeroUD ⋄ ∆ ⍵}(w×sw)↓ustr           ⍝ sw=¯1. Return a BIi
      }
    mul10Exp←times10Exp
    shiftDecimal←times10Exp                        ⍝ positive/left
    shiftD←times10Exp

  ⍝ (bi.exp 3000 bi.div10 2)  ≡ 30  ≡  (bi.exp 3000 bi.mul10Exp ¯2)
    div10Exp←{⍺ times10Exp negate ⍵}

      and←{⍺ ∧logical ⍵}

      or←{⍺ ∨logical ⍵}
 
      xor←{⍺ ≠logical ⍵}

    ⍝ a (logop logical) w
      logical←{
          (sa ba)(sw bw)←⍺ bitsView2 ⍵
          (sa=¯1)⍺⍺(sw=¯1):¯1 bitsInUS(ba ⍺⍺ bw)
          1 bitsInUS(ba ⍺⍺ bw)
      }

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
    ∇ {r}←fxBool(NAME SYM);model;∆NAME;in;out
      ∆NAME←{
        ⍝ ⍺ ∆NAME ⍵: emulates (⍺ ∆SYM ⍵)
        ⍝ ⍺, ⍵: Both are external-format BigIntegers (BIx)
          (sa a)(sw w)←⍺ ∆ ⍵
          0∊sa sw:sa ∆SYM sw        ⍝ ⍺, ⍵, or both are 0
          sa≠sw:sa ∆SYM sw          ⍝ ⍺, ⍵ different signs
          sa=¯1:∆SYM cmp w mix a    ⍝ ⍺, ⍵ both neg
          ∆SYM cmp a mix w          ⍝ ⍺, ⍵ both pos
      }
       ⋄ in←'∆NAME' '∆SYM' ⋄ out←NAME SYM
      :If ' '=1↑0⍴r←⎕THIS.⎕FX in ⎕R out⊣⎕NR'∆NAME'
          in,←⊂'←⍺ ∆ ⍵' ⋄ out←('_',NAME)SYM'←⍺ ⍵'
      :AndIf ' '=1↑0⍴r←⎕THIS.⎕FX in ⎕R out⊣⎕NR'∆NAME'
      :Else
          ⎕←'LOGIC ERROR: unable to create boolean function: ',NAME,' (',SYM,')'
      :EndIf
    ∇
    fxBool¨ ('lt' '<')('le' '≤')('eq' '=')('ge' '≥')('gt' '>')('ne' '≠')
    ⎕EX 'fxBool'

  ⍝ genVariants: For negate, create related _negate, such that
  ⍝        (import ⍺) _plus import ⍵   <==> ⍺ plus ⍵
    genVariants¨'plus' 'add' 'minus' 'subtract' 'sub' 'times' 'mul' 'divide'
    genVariants¨'divideRem' 'divRem' 'power' 'pow' 'residue' 'modulo' 'mod'
    genVariants¨'times2Exp' 'mul2Exp' 'div2Exp' 'shiftBinary' 'shiftB'
    genVariants¨'times10Exp' 'mul10Exp' 'shiftDecimal' 'shiftD' 'gcd' 'lcm'

    :EndSection BI Dyadic Operands/Functions

    :Section BI Special Functions/Operations (More than 2 Args)
    ⍝ modMul:  modulo m of product a×b
    ⍝ A faster method than (m|a×b), when a, b are large and m is substantially smaller.
    ⍝ r ← a modMul b m    →→→    r ← m | a × b
    ⍝ BIi ← ⍺:BIi ∇ ⍵:BIi m:BIi
    ⍝ Naive method: (m|a×b)
    ⍝      If a,b have 1000 digits each and m is smaller, the m| operates on 2000 digits.
    ⍝ Better method: (m | (m|a)×(m|b)).
    ⍝      Here, the multiply is on len(m) digits, and the final m operates on 2×len(m).
    ⍝ For large a b of length 5000 dec digits or more, this alg can be 2ce the speed (13 sec vs 26).
    ⍝ It is nominally faster at lengths around 75 digits.
    ⍝ Only for smaller (and faster) a and b, the cost of 3 modulos instead of 1 predominates.
      modMul←{
          a(b m)←(∆ ⍺)(⊃∆/⍵)
          m residue(m residue a)times(m residue b)
      }
    :EndSection BI Special Functions/Operations (More than 2 Args)
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Unsigned Utility Math Routines
    ⍝ These are the workhorses of bigInt; most are from dfns:nats (handling unsigned bigInts).
    ⍝ Note: ⍺ and ⍵ are guaranteed by BI and BIX to be vectors, but not
    ⍝       by internal functions or if called directly.
    ⍝       So tests for 2, 1, 0 (twoUD etc) use ravel:  (twoUD≡,⍺)
    ⍝ mulU:  multiply ⍺ × ⍵  for unsigned BIi ⍺ and ⍵
    ⍝ r:BIi ← ⍺:BIi ∇ ⍵:BIi
    ⍝ This is dfns:nats mul.
    ⍝ It is faster than dfns:xtimes (FFT-based algorithm)
    ⍝ even for larger numbers (up to xtimes smallish design limit)
    ⍝ We call ndnZ to remove extra zeros, esp. so zero is exactly ,0 and 1 is ,1.
      mulU←{
          ⍺{                                      ⍝ product.
              ndnZ 0,↑⍵{                          ⍝ canonicalised vector.
                  digit take←⍺                    ⍝ next digit and shift.
                  +⌿⍵ mix digit×take↑⍺⍺           ⍝ accumulated product.
              }/(⍺,¨(≢⍵)+⌽⍳≢⍺),⊂,0                ⍝ digit-shift pairs.
          }{                                      ⍝ guard against overflow:
              m n←,↑≢¨⍺ ⍵                         ⍝ numbers of RX-digits in each arg.
              m>n:⍺ ∇⍨⍵                           ⍝ quicker if larger number on right.
              n<OFL:⍺ ⍺⍺ ⍵                        ⍝ ⍵ won't overflow: proceed.
              s←⌊n÷2                              ⍝ digit-split for large ⍵.
              p q←⍺∘∇¨(s↑⍵)(s↓⍵)                  ⍝ sub-products (see notes).
              ndnZ 0,+⌿(p,s↓n⍴0)mix q             ⍝ sum of sub-products.
          }⍵
      }
   ⍝ powU: compute ⍺*⍵ for unsigned ⍺ and ⍵. (⍺ may not be omitted).
   ⍝       Returns 1 (a*⍵) if even power, else 0(⍺*⍵).
   ⍝       For ⍺*1, returns 0 ⍺, which indicates to caller to use sign sa of left operand ⍺'.
   ⍝ RXdiv2: (Defined above.)
      powU←{                                  ⍝ exponent.
          zeroUD≡,⍵:oneUD                     ⍝ =cmp ⍵ mix,0:,1 ⍝ ⍺*0 → 1
          oneUD≡,⍵:,⍺                         ⍝ =cmp ⍵ mix,1:⍺  ⍝ ⍺*1 → ⍺. Return "odd," i.e. use sa in caller.
          hlf←{,ndn(⌊⍵÷2)+0,¯1↓RXdiv2×2|⍵}    ⍝ quick ⌊⍵÷2.
          evn←ndnZ{⍵ mulU ⍵}ndn ⍺ ∇ hlf ⍵     ⍝ even power
          0=2|¯1↑⍵:evn ⋄ ndnZ ⍺ mulU evn      ⍝ even or odd power.
      }
   ⍝ divU: unsigned division:
   ⍝ Returns:  (int. quotient) (remainder)
   ⍝           (⌊ua ÷ uw)      (ua | uw)
   ⍝   r:BIi[2] ← ⍺:BIi ∇ ⍵:BIi
      divU←{
          zeroUD≡,⍵:⍺{                        ⍝ ⍺÷0
              zeroUD≡,⍺:oneUD                 ⍝ 0÷0 → 1 remainder 0
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
                  nxt←dlz ndn 0,q×mid         ⍝ next multiplier.
                  gt←>cmp p mix nxt           ⍝ greater than:
                  ⍺ ∇ gt⊃2,/lo mid hi         ⍝ choose upper or lower interval.
              }⌊0 1+↑÷/ppqq+(0 1)(1 0)        ⍝ lower and upper bounds of ratio.
              mpl←dlz ndn 0,q×r∆              ⍝ multiple.
              p∆←dlz nup-⌿p mix mpl           ⍝ remainder.
              (r,r∆)p∆                        ⍝ result & remainder.
          }/svec,⊂⍬ ⍺                         ⍝ fold-accumulated reslt.
      }

    gcdU←{zeroUD≡,⍵:⍺ ⋄ ⍵ ∇⊃⌽⍺ divU ⍵}        ⍝ greatest common divisor.
    lcmU←{⍺ mulU⊃⍵ divU ⍺ gcdU ⍵}             ⍝ least common multiple.
      remU←{                                  ⍝ BIu remainder
          twoUD≡,⍺:2|⊃⌽⍵                     ⍝ fast path for modulo 2
          <cmp ⍵ mix ⍺:⍵                     ⍝ ⍵ < ⍺? remainder is ⍵
          ⊃⌽⍵ divU ⍺                         ⍝ Otherwise, do full divide
      }



    :Endsection BI Unsigned Utility Math Routines
⍝ --------------------------------------------------------------------------------------------------

    :Section Service Routines

    atom←{1=≢⍵:⍬⍴⍵ ⋄ ⊂⍵}                    ⍝ If ⍵ is length 1, treat as a scalar (atom).

  ⍝ These routines operate on unsigned BIu data unless documented…
    dlz←{(0=⊃⍵)↓⍵}                          ⍝ drop FIRST leading zero.
    zro←{0≠≢⍵:,⍵ ⋄ ,0}                      ⍝ ⍬ → ,0. Converts BIi to BIz, so even 0 has one digit (,0).
    dlzs←{zro(∨\⍵≠0)/⍵}                     ⍝ drop RUN of leading zeros, but [PMS] make sure at least one 0
        ndn←{ +⌿1 0⌽0 RX⊤⍵}⍣≡               ⍝ normalise down: 3 21 → 5 1 (RH).
    ndnZ←dlz ndn                            ⍝ ndn, then remove (earlier added) leading zero, if still 0.
        nup←{⍵++⌿0 1⌽RX ¯1∘.×⍵<0}⍣≡         ⍝ normalise up:   3 ¯1 → 2 9
    nupZ←dlz nup                            ⍝ PMS
    mix←{↑(-(≢⍺)⌈≢⍵)↑¨⍺ ⍵}                  ⍝ right-aligned mix.
    dck←{(2 1+(≥cmp ⍵)⌽0 ¯1)⌿⍵}             ⍝ difference check.
    rep←{10⊥⍵{⍉⍵⍴(-×/⍵)↑⍺}(⌈(≢⍵)÷DRX),DRX}  ⍝ radix RX rep of number.
    cmp←{⍺⍺/,(<\≠⌿⍵)/⍵}                     ⍝ compare first different digit of ⍺ and ⍵.

    :Endsection Service Routines
⍝ --------------------------------------------------------------------------------------------------
    :Endsection Big Integers

    :Section Utilities: bi, dc (desk calc), BIB, BIC, BI∆HERE
   ⍝ bi      - simple niladic fn, returns this bigint namespace #.BigInt
   ⍝           If ⎕PATH points to bigInt namespace, bi will be found without typing explicit path.
   ⍝ bi.dc   - desk calculator (self-documenting)
   ⍝ BIB     - Utility (add on) to manipulate BIs as arbitrary signed binary numbers
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
          ∆ERR::⎕SIGNAL/⎕DMX.(('bigInt: ',EM)EN)
          0=1↑0⍴∊⍵:err eBIC
        ⍝ ⍺ a string, treat as: ⍺,1 BIC ⍵
          0≠1↑0⍴⍺:⍺,matchBiCalls ⍵              ⍝ ⍺ is catenated: as if ⍺,1 BIC ⍵
          ⍺=2:matchFnRep ⎕NR ⍵                  ⍝ Compile function named ⍵
          ⍺=¯2:matchFnRep ⍵                     ⍝ Compile function whose ⎕NR is ⍵
          ⍺=0:matchBiCalls ⍵                    ⍝ Compile string ⍵ and return compiled string
          ⍺=1:((1+⎕IO)⊃⎕RSI,#)⍎matchBiCalls ⍵   ⍝ Compile and execute string ⍵ in CALLER space, returning value of execution
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
      msg,←⊂' note 1: only thing on line, besides leading or trailing spaces.'
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
          avoid←'%''"&\'                        ⍝ We encode via \x, noting in theory % can be encoded as \%, etc.
          safe←(⎕UCS 32+⍳256-32)~avoid          ⍝ safe: (⎕UCS 32-255) avoiding % ' " & and \
          c2hjs←{                               ⍝ encode hex in js format as compactly as possible
              2≥≢⍵:'\\x',¯2↑'00',⍵
              4≥≢⍵:'\\u',¯4↑'0000',⍵
              '\\u{',⍵,'}'                      ⍝ 6 digits max, e.g. 5 for '💩' poo(p)
          }∘{hexD[16⊥⍣¯1⊣⎕UCS ⍵]}¨              ⍝ returns minimal hex digits for each char passed.
                                                ⍝ ⍵: an APL object in the domain of ⎕FMT.
          msg←¯1↓,(⍺ ⎕FMT ⍵),⎕UCS 13            ⍝ msg: map ⍵ to a flat char. vector with line separators.
     
          unsafe←~msg∊safe                      ⍝ unsafe: 0 or more chars to be encoded.
          av←msg∊avoid
          (unsafe/msg)←c2hjs unsafe/msg         ⍝ msg: map unsafe char scalars to enclosed strings.
          ∊msg                                  ⍝ msg: flattened down again
      }
     
      :If 0=⎕NC'fmt' ⋄ fmt←⊢ ⋄ :EndIf
      html←'⍞ALERT⍞'⎕R(fmt FMTjs msg)⊣html
                                               ⍝ Run in own thread so alert window stays open after fn exit.
      ns←#.⎕NS''                               ⍝ Run renderer in anonymous namespace in user space-- don't clutter user space...
      ns.{'ignored'⎕WC'HTMLRenderer'⍵('Size'(0 0))}&html  ⍝ Size (0 0): makes extra renderer window invisible
    ∇

      BIB←{
          ∆ERR::⎕SIGNAL/⎕DMX.(('bigInt: ',EM)EN)
          ⍺←⊢
          1≡⍺ 1:⊥BI ⍺⍺⊤BI ⍵
          ⊥BI ⍺⍺⌿↑⊤BI¨⍺ ⍵   ⍝ Padding on right (High order bits)
      }

    eBIHFAILED←'BI∆HERE failed: unable to run compiled BI code'
    eBIHBADCALL←'BI∆HERE not called from active traditional fn'
    ∇ {callback}←BI∆HERE;callerCode;callerNm;cloneNm;callerNs;opt;pat;RE∆GET;⎕TRAP
      ⍝ See BI∆HERE_HELP
      ⎕TRAP←0 'C' '⎕SIGNAL/⎕DMX.(EM EN)'
      (2>≢⎕SI)err eBIHBADCALL
      RE∆GET←{ ⍝ Returns Regex field ⍵N in ⎕R ⍵⍵ dfn. Format:  f2 f3←⍵ RE∆GET¨2 3
          ⍵=0:⍺.Match ⋄ ⍵≥≢⍺.Offsets:'' ⋄ ¯1=⍺.Offsets[⍵]:'' ⋄ ⍺.(Lengths[⍵]↑Offsets[⍵]↓Block)
      }
      opt←('Mode' 'M')('EOL' 'LF')('IC' 1)('UCP' 1)('DotAll' 1)
      pat←'^ (?: \h* ⍝?:BI \b \N*$) (.*?) (?: \R ⍝?:ENDBI \b \N*$)'~' '
      callerNs←(⊃⎕RSI)
      callerCode←(1+⎕LC⊃⍨1+⎕IO)↓callerNs.⎕NR callerNm←⎕SI⊃⍨1+⎕IO
      cloneNm←callerNm,'__BigInteger_TEMP'
      callback←cloneNm,' ⋄ →0'
    ⍝ The callback will call the caller function (cloned) starting after the BI∆HERE,
    ⍝ starting with a statement to erase the clone
      :Trap 0
          :If 0=1↑0⍴callerNs.⎕FX(⊂cloneNm),(⊂'⎕EX ''',cloneNm,''''),(⊆0 BIC callerCode)
              err eBIHFAILED
          :EndIf
          ⍝ Success!
      :Else
          err eBIHFAILED
      :EndTrap
      :If DEBUG
          ⎕←'Executing...'
          ⎕←callerNs.⎕VR cloneNm
      :EndIf
    ∇
    :Endsection Utilities: bi, dc (desk calc), BIB, BIC, BI∆HERE

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
    fns2←ssplit fns2,' add times mul power pow residue modulo mod times10Exp mul10Exp divide10 div10'

    note 50⍴'-'⋄ note'  MONADIC FUNCTIONS' ⋄ note 50⍴'¯' ⋄ note ↑fns1
    note 50⍴'-'⋄ note'  DYADIC FUNCTIONS ' ⋄ note 50⍴'¯' ⋄ note ↑fns2
    note 50⍴'-'
    note'Exporting…'⊣⎕EX '_' 'ssplit'
    note{(⎕EXPORT ⍵)⌿⍵}⎕NL 3 4
    note'*** ',(⍕⎕THIS),' initialized. See ',(⍕⎕THIS),'.HELP'
    note 50⍴'-'
    :EndSection Bigint Namespace - Postamble

:EndNamespace
