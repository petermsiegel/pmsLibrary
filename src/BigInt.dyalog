:namespace BigInt
  ⍝ ∘ NOTE: See BigIntHelp for details...
  ⍝ ∘ Call BigInt.help or ⎕EDIT 'BigIntHelp'

  ⍝ Table of Contents
  ⍝   Preamble
  ⍝      Preamble Utilities
  ⍝      Preamble Variables
  ⍝   BI
  ⍝      BigInt Namespace and Utility Initializations
  ⍝      Executive: BI, BIX, BIM, bi
  ⍝      BigInt internal structure
  ⍝      Monadic Operands/Functions for BI, BIX, BIM
  ⍝      Dyadic Operands/Functions for BI, BIX, BIM
  ⍝      Directly-callable Functions ⍵⍵ via bi.⍵⍵.
  ⍝      BI Special Functions/Operations (More than 2 Args)
  ⍝      Unsigned Utility Math Routines
  ⍝      Service Routines
  ⍝  Utilities
  ⍝      bi
  ⍝      bi.dc (desk calculator)
  ⍝      BIB (bit manipulation).
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
      err←{⍺←1 ⋄ ⍺=0:_←⍵ ⋄ m←⍵ ⎕DMX.EM⊃⍨0=≢⍵ ⋄ ⎕SIGNAL/('BigInt: ',m)⎕DMX.EN}
      ⎕FX'{ok}←note str'('ok←1',VERBOSE/'⊣⎕←str')
    ∇
    ∇ {r}←loadHelp
      :Trap 0 ⋄ r←⎕SE.SALT.Load'-target=',(⍕⎕THIS.##),' pmsLibrary/src/BigIntHelp'
      :Else ⋄ r←⎕←'Unable to load BigIntHelp'
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
  ⍝    BIi  -internal-format signed Big Integer numeric vector:
  ⍝              sign (data)
  ⍝                sign (¯1 0 1)   data (a vector of integers)
  ⍝          ∘ sign: If data is zero, sign is 0 by definition.
  ⍝          ∘ data: Always 1 or more integers (if 0, it must be data is ,0).
  ⍝                  Each element is a positive number <RX10 (10E6)
  ⍝    Given the canonical requirement, a BIi of 0 is (0 (,0)), 1 is (1 (,1)) and ¯1 is (¯1 (,1)).
  ⍝
  ⍝    BIu  -unsigned internal-format BIi (vector of integers):
  ⍝          ∘ Consists solely of a data vector as defined for BIi.
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
  ⍝    Int   -an APL-format single small integer ⍵, often specified to be in range ⍵<RX10.

  ⍝ ==================
  ⍝ setHandSizeIn[Bits]
  ⍝ ==================
  ⍝ {ok=1}←setHandSizeInBits ⍵:[nn | frType | 0]
  ⍝      nn:      number of bits per hand, ⍵ is between 2 and 45
  ⍝      frType:  either 645 or 1287, corresponding to the largest # of bits
  ⍝               for either ⎕FR=645 or 1287. ⍵ must be 645 or 1287
  ⍝      0:       choose best value, currently 20.  See nbitsBest below...
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
  ⍝       RX10, NRX10, NRX2, OFL, and ⎕FR.
  ⍝
  ⍝   Good Values for NRX2 (radix, i.e. hand size, in bits)
  ⍝     20     Fastest for all functions, except multiplication, where 40 is faster..
  ⍝     40     Slightly faster for multiplication, but slower than 20 for other operations.
  ⍝
  ⍝     NRX2   Stored    Overflow   Overflow    Max Poss
  ⍝     Bits  Type      Bits (×)   Type          Bits (Types are always Signed in APL)
  ⍝     20    32-bit    40         Float 64       53
  ⍝     26    32-bit    52         Float 64       53
  ⍝     30    32-bit    60         Dec Flt 128    93
  ⍝     45    32-bit    90         Dec Flt 128    93
  ⍝
  ⍝ =====================================================================================
  ⍝ RX10:  Radix for internal BI integers.
  ⍝ NRX10: # Decimal digits that RX10 must hold.
  ⍝ NRX2:  # Binary  digits required to hold NRX10 digits. (See encode2Bits, decodeFromBits).
  ⍝ NRX2∆: NRX2-1. We use 1 fewer bits than our integers can hold when converting to bits,
  ⍝        so that even after arbitrary user bit manipulations, we can't generate hands in decimal format
  ⍝        that are NRX2 bits, but ≥ RX10.
  ⍝        (E.g. if RX10 is 10*6 so NRX2 is 20 bits, it's easy with logical anding, oring, etc.
  ⍝        to have a number like 1000123, which is still 20 bits: 1 1 1 1 0 1 0 0 0 0 1 0 1 0 1 1 1 0 1 1
  ⍝        In this case, the largest 19-bit number still is < RX10.
  ⍝ RXBASE∆: NRX2∆⍴2 for use with decode
  ⍝ OFL: For multiplies (mulU) of unsigned big integers ⍺ × ⍵,
  ⍝      the length (in # of hands, i.e. base RX10 digits) of the larger of ⍺ and ⍵,
  ⍝      beyond which digits must be split to prevent overflow.
  ⍝      OFL is a function of the # of guaranteed mantissa bits in the largest (float) number used
  ⍝      AND the radix RX10, viz.   ⌊mantissa_bits ÷ RX10×2, since it's the potential accumulated bits of ⍺×⍵.
  ⍝ ⎕FR: Whether floating rep is 64-bit float (53 mantissa bits, and fast)
  ⍝      or 128-bit decimal (93 mantissa bits and much slower)..
    ∇ {ok}←{verbose}setHandSizeInBits nbits;nbitsBest;nbitsMax;nbitsMid;eBAD
    ⍝ Set key constants/initial values...
      verbose←1='verbose'{0=⎕NC ⍺:⍵ ⋄ ⎕OR ⍺}0
      nbitsBest←20                    ⍝ "Ideal" default for NRX2
      nbitsMid nbitsMax←⌊53 93÷2        ⍝ Max bits to fit in Binary(645) and Dec Float (1287) resp.
    ⍝ Handle frType and 0; ensure nbits in proper range...
       ⋄ eBAD←'bigInt: invalid max bits for big integer base'
      eBAD ⎕SIGNAL 11/⍨(0≠1↑0⍴nbits)∨(1≠≢nbits)
      nbits←(∊nbitsMax nbitsMid nbitsBest nbits)[1287 645 0⍳nbits]  ⍝ frType or 0 → NRX2 equivalents
      :If nbits>nbitsMax ⋄ :OrIf nbits<2
           ⋄ eBAD←'bigInt: bits for internal base must be integer in range 2..',⍕nbitsMax
          11 ⎕SIGNAL⍨eBAD
      :EndIf
    ⍝ Set key bigInt constants...
      ⎕FR←645 1287⊃⍨nbits>nbitsMid
      NRX2←nbits
      NRX2∆←nbits-1      ⍝ NRX2∆:   Experimental (see RXBASE∆). See comments above on NRX2∆.
      NRX10←⌊10⍟RX2←2*NRX2
      RXBASE∆←NRX2∆⍴2    ⍝ RXBASE∆: Experimental (see comments above on NRX2∆).
      RX10←10*NRX10 ⋄ RXdiv2←RX10÷2  ⍝ RXdiv2: see ∇powU∇
      OFL←{⌊(2*⍵)÷RX10×RX10}(⎕FR=1287)⊃53 93
    ⍝ Report...
      :If verbose
          ⎕←'nbits in radix(*)  NRX2   ',NRX2
          ⎕←'Floating rep       ⎕FR   ',⎕FR,' in namespace ',⍕⎕THIS
          ⎕←'ndigits in radix   NRX10   ',NRX10
          ⎕←'Radix (10*NRX10)     RX10    ',¯3⍕RX10
          ⎕←'max ⍵ for ⍵×⍵ (**) OFL   ',OFL
          ⎕←'*   Radix: Each bigInt is composed of 0 or more integers (hands),'
          ⎕←'    each between 0 and RX10-1, and a sign'
          ⎕←'**  OFL: maximum # of "hands" in bigInt ⍵ allowed before splitting ⍵'
          ⎕←'    into smaller numbers to avoid multiplication overflow.'
          ⎕←'*** ⎕FR 645: 53 bits avail;  1287: 93 bits available'
      :EndIf
      ok←1
    ∇
    0 setHandSizeInBits 0

  ⍝ Data field (unsigned) constants
    zero_D← ,0         ⍝ data field ZERO, i.e. unsigned canonical ZERO
    one_D←  ,1          ⍝ data field ONE, i.e. unsigned canonical ONE
    two_D←  ,2          ⍝ data field TWO
    ten_D←  ,10

  ⍝ bi CONSTANTS for users: zero, one, two, neg_one (¯1), 10
    zero←    0 zero_D
    one←     1 one_D
    two←     1 two_D
    neg_one←¯1 one_D    
    ten←     1 ten_D

  ⍝ Error messages. All will be used with fn <err> and ⎕SIGNAL 911: BigInt DOMAIN ERROR
    eBADBI   ←'Invalid BigInteger'
    eNONINT  ←'Invalid BigInteger: APL number not a single integer: '
    eSMALLRT ←'Right argument must be a small APL integer ⍵<',⍕RX10
    eCANTDO1 ←'Monadic function not implemented as BI operand: '
    eCANTDO2 ←'Dyadic function not implemented as BI operand: '
    eIMPORT←'bigInt: Importing invalid object: '
    eINVALID ←'Format of big integer is not valid: '
    eFACTOR  ←'Factorial (!) argument must be ≥ 0'
    eBADRAND ←'Roll (?) argument must be >0'
    eSQRT    ←'sqrt: arg must be non-negative'
    eMUL2  ← eSMALLRT
    eMUL10 ← eSMALLRT
    eBIC     ←'BIC argument must be a fn name or one or more code strings.'
    eBITSIN  ←'BigInt: Importing bits requires arg to contain only boolean integers'

    :EndSection Namespace and Utility Initializations

    :Section Executive
    ⍝ --------------------------------------------------------------------------------------------------

    ⍝ listMonadFns   [0] single-char symbols [1] multi-char names
    ⍝ listDyadFns    ditto
    listMonadFns←'-+|×÷<>!?⊥⊤⍎→√⍳~'('SQRT' 'NOT')
    ⍝            reg. fns       boolean  names   [use Upper case here]
    listDyadFns←('+-×*÷⌊⌈|∨∧⌽√≢⌷','<≤=≥>≠⍴')('SHIFTD' 'SHIFTB'  'DIVREM' 'MOD' 'MODMUL' 'MMUL' 'AND' 'OR' 'XOR')


    ⍝ BI: Basic utility operator for using APL functions in special BigInt meanings.
    ⍝     BIi ← ∇ ⍵:BIx
    ⍝     Returns BIi, an internal format BigInteger structure (sign and data, per above).
    ⍝     See below for exceptions ⊥ ⊤ ⍎
    ⍝ BIX:Basic utility operator built on BI.
    ⍝     BIx ← ∇ ⍵:BIx
    ⍝     Returns BIx, an external string-format BigInteger object ("[¯]\d+").


⍝ --------------------------------------------------------------------------------------------------
    getOpName←{aa←⍺⍺ ⋄ 3=⎕NC'aa':⍕⎕CR'aa' ⋄ 1(819⌶)aa}
      _BI_src←{⍺←⊢
          ∆ERR::⎕DMX.EM ⎕SIGNAL ⎕DMX.EN
        ⍝ _BI_src is a template for ops BI and BIX.
        ⍝ ⍺⍺ → fn
        ⍝ fn is always a scalar (either simple or otherwise);
        ⍝ If ⍺⍺ has a ⍨ suffix (⍺⍺ may be an APL primitive/s or a string),
        ⍝ then fn←¯1↓fn and inv (inverse) is set:
        ⍝      to 1, if BI/X was called 2-adically;
        ⍝      to 2, if called 1-adically, i.e. a "selfie":   ×⍨BI 3 ==> 3 ×BI 3
          fn monad inv←(1≡⍺ 1){'⍨'=¯1↑⍵:(¯1↓⍵)0(1+⍺) ⋄ ⍵ ⍺ 0}⍺⍺ getOpName ⍵
         ⍝ CASE←1∘∊(atom fn)∘≡∘⊆¨∘⊆       ⍝ CASE ⍵1 or CASE ⍵1 ⍵2...
           CASE←(atom fn)∘∊∘⊆
     
          ⍝ Monadic...
          monad:{                              ⍝ BIX: ∆exp∆: See Build BIX/BI below.
              CASE'-':∆exp∆ neg ⍵              ⍝     -⍵
              CASE'+':∆exp∆ ∆ ⍵                ⍝     nop, except makes sure obj is valid in BIi form.
              CASE'|':∆exp∆ abs ⍵              ⍝     |⍵
              CASE'×':∆exp∆⊃∆ ⍵                ⍝     ×⍵ signum:  Returns APL int (∊¯1 0 1), not BI.
              CASE'÷':∆exp∆ recip ⍵            ⍝     ÷⍵:         Why bother?
              CASE'<':∆exp∆ dec ⍵              ⍝     ⍵-1:        Optimized for constant in ⍵-1.
              CASE'>':∆exp∆ inc ⍵              ⍝     ⍵+1:        Optimized for constant in ⍵+1.
              CASE'!':∆exp∆ fact ⍵             ⍝     !⍵          For smallish integers ⍵≥0
              CASE'?':∆exp∆ roll ⍵             ⍝     ?⍵:         For int ⍵>0 (0 invalid)
              CASE'⊥':∆exp∆ 1 bits2BI ⍵        ⍝     bits→BI:    Converts from bit vector to internal
              CASE'⊤':BI2Bits ⍵                ⍝     BI→bits:    Converts a BI ⍵ to its bit form
              CASE'~' 'NOT':not ⍵    ⍝
              CASE'≢':∆exp∆ 1,⊂NRX2∆×≢⊃⌽∆ ⍵     ⍝     # actual bits in bigInt internal form...
              CASE'⍎':⍎exp ∆ ⍵                 ⍝     BIi→int:    If in range, returns a std APL number; else error
              CASE'←':∆ ⍵                      ⍝     BIi out:    Returns the BI internal form of ⍵: NRX2∆-bit signed integers
              CASE'⍕':exp ∆ ⍵                  ⍝     BIi→BIx:    Takes a BI internal form vector of integers and returns a BI string
              CASE'SQRT' '√':exp sqrt ⍵        ⍝     ⌊⍵*0.5:     See dyadic *
              CASE'⍳':⍳∆2Small ⍵               ⍝     ⍳: Special case: Allow only small integers... Returns an APL # only.
              0::err eCANTDO1,,⎕FMT #.FN∘←fn  ⍝ Didn't recognize it. Assume it's an APL-only fn
          }⍵
        ⍝ Dyadic...
          ⍝ See discussion of ⍨ above...
          ⍺{
              ⍝ High Use: [Return BigInt]
              CASE'+':∆exp∆ ⍺ add ⍵
              CASE'-':∆exp∆ ⍺ sub ⍵
              CASE'×':∆exp∆ ⍺ mul ⍵
              CASE'⌽':∆exp∆ ⍵ mul2Exp ⍺                 ⍝  ⍵×2*⍺,  where ±⍵. Decimal shift.
              CASE'÷':∆exp∆ ⍺ div ⍵                     ⍝  ⌊⍺÷⍵
              CASE'*':∆exp∆ ⍺ pow ⍵                     ⍝ Handles ⍵∊BI OR, as special case, ⍵∊0.5 '0.5' exactly.
              CASE'|':∆exp∆ ⍺ rem ⍵                     ⍝ remainder: |   (⍺ | ⍵) <==> (⍵ modulo a)
          ⍝ Logical: [Return single boolean, 1∨0]
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
              CASE'⌷':∆exp∆ ⍺ flipBits ⍵                ⍝ Special meaning: flip bits w/in BI
     
          ⍝ gcd/lcm: [Return BigInt]                    ⍝ ∨, ∧ return bigInt.
              CASE'∨':∆exp∆ ⍺ gcd ⍵                     ⍝ ⍺∨⍵ as gcd.
              CASE'∧':∆exp∆ ⍺ lcm ⍵                     ⍝ ⍺∧⍵ as lcm.
          ⍝
              CASE'√' 'ROOT':∆exp∆ ⍺ root ⍵             ⍝ See ∇root.
              CASE'MOD':∆exp∆ ⍵ rem ⍺                   ⍝ modulo:  Same as |⍨
              CASE'SHIFTB':∆exp∆ ⍺ mul2Exp ⍵            ⍝  ⍺×2*⍵,  where ±⍵. Binary shift.
              CASE'SHIFTD':∆exp∆ ⍺ mul10Exp ⍵           ⍝  ⍺×10*⍵, where ±⍵. Decimal shift
              CASE'DIVREM':∆exp∆¨⍺ divRem ⍵             ⍝ Returns pair:  (⌊⍺÷⍵) (⍵|⍺)
              CASE'MODMUL' 'MMUL':∆exp∆ ⍺ modMul ⍵      ⍝ ⍺ modMul ⍵0 ⍵1 ==> ⍵1 | ⍺ × ⍵0.
     
              CASE'⍴':(∆2Small ⍺)⍴⍵                     ⍝ Requires ⍺ in ⍺ ⍴ ⍵ to be in range of APL int.
              err eCANTDO2,,⎕FMT #.FN∘←fn               ⍝ Not found!
          }{2=inv:⍵ ⍺⍺ ⍵ ⋄ inv:⍵ ⍺⍺ ⍺ ⋄ ⍺ ⍺⍺ ⍵}⍵        ⍝ Handle ⍨.   inv ∊ 0 1 2 (not inv, inv, selfie)
      }

    ⍝ BIM:     Biginteger modulo operation:  x ×BIM y ⊣ mod. 
    ⍝          Multiply × handled as special case:   x modMul (y mod)   
    ⍝          Otherwise:                            mod |BIX x ⍺⍺ BI y
    ⍝ BIM:     res ← [LA:⍺] OP:⍺⍺ BIM RA:⍵⍵ ⊣ MOD:⍵   ==>    MOD:⍵ |BIX [LA:⍺] OP:⍺⍺ BI RA:⍵⍵
    ⍝ Perform  res ← LA OP RA (Modulo ⍵)  <==>  ⍺ ⍺⍺ BIX ⍵ (Modulo ⍵⍵)
    ⍝
    ⍝ ∇ r←a(AA BIM WW)W
    ⍝   r←a(AA _BIM WW)W
    ⍝ ∇
    BIM←{⍺←⊢ ⋄ fn←atom ⍺⍺ getOpName ⍬⋄ fn≡'×':export ⍺ modMul (⍵⍵ ⍵)⋄ ⍵|BIX ⍺ (⍺⍺ BI) ⍵⍵}

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
    ⍝       data: an unsigned integer vector ⍵, where ⍵∧.<RX10.    data:UV
    ⍝    Together sign and data define a big integer.
    ⍝    If sign=0, data≡,0 when returned from functions. Internally, extra leading 0's may appear.
    ⍝    If sign≠0, data may not be 0 (i.e. data∨.≠0).

      ⍝ ============================================
      ⍝ import / imp / ∆ - Import to internal bigInteger
      ⍝ ============================================
      ⍝ ∆  - internal alias for import
      ⍝    from: external-format* (BIc) (⍺ and) ⍵--
      ⍝          each either a BigInteger string or an APL integer--
      ⍝          * Or an internal-format (BIi) BigInteger, passed through unchanged.
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
      ⍝       5, 7          ∆aplNum (integer as float)   645, 1287
      ⍝       6             BIi (internal)               326
      ⍝ Output: BIi, i.e.  (sign (,ints)), where ints∧.<RX10
      ⍝
      import←{⍺←⊢
          0::11 ⎕SIGNAL⍨eIMPORT,⍕⍵
          1≢⍺ 1:(∇ ⍺)(∇ ⍵)
          ⋄ type←80|⎕DR ⍵ ⋄ dep←≡⍵          ⍝ Returned by likelihood [1]=highest.
          (dep=¯2)∧6=type:⍵                 ⍝ [1] BIi
          1<|dep:∘                          ⍝ Basic sanity check
          3=type:∆int ⍵                     ⍝ [2] int ([2a] small or [2b] otherwise)
          0=type:∆str ⍵                     ⍝ [3] String
          5 7∊⍨type:∆aplNum ⍵               ⍝ [4] Float-format integer (e.g. 3E45)
          ∘
      }
    ∆←import    ⍝ ∆ used internally
    imp←import  ⍝ external alias...
      ⍝ importU, impU:
      ⍝     import ⍵ as unsigned bigInt (data portion only)
      importU←{
          ⊃⌽import ⍵
      }
      ⍝ ∆int:    ∇ ⍵:I[1]
      ⍝          ⍵ MUST Be an APL native (1-item) integer ⎕DR type 83 163 323.
      ∆int←{
          1≠≢⍵:err eNONINT,⍕⍵              ⍝ scalar only...
          RX10>u←,|⍵:(×⍵)(u)               ⍝ Small integer
          (×⍵)(chkZ RX10⊥⍣¯1⊣u)            ⍝ Integer
      }
      ⍝ ∆aplNum: Convert an APL integer into a BIi
      ⍝ Converts simple APL native numbers, as well as those with large exponents, e.g. of form:
      ⍝     1.23E100 into a string '123000...000', ¯1.234E1000 → '¯1234000...000'
      ⍝ These must be in the range of decimal integers (up to +/- 1E6145).
      ⍝ If not, you must use big integer strings of any length. Exponents are disallowed.
      ⍝ Normally, ∆aplNum is not called by the user, since BI and BIX call it automatically.
      ⍝ Usage:
      ⍝    (bigInt.∆  1E100)  ≡  bigInt.∆ '1',100⍴'0'   <==>  1
      ⍝            *- calls ∆aplNum     *- calls ∆str

      ∆aplNum←{⎕FR←1287 ⍝ 1287: to handle large exponents
          (1=≢⍵)∧(⍵=⌊⍵):(×⍵)(chkZ RX10⊥⍣¯1⊣|⍵)
          err eNONINT,⍕⍵
      }
      ⍝ ∆str: Convert a BIstr (BI string) into a BIi.
      ⍝       ∆str ⍵:S[≥1]   (⍵ must have at least one digit, possibly a 0)
      ∆str←{
          s←1 ¯1⊃⍨'-¯'∊⍨1↑⍵     ⍝ Get sign, if any
          w←'_'~⍨⍵↓⍨s=¯1        ⍝ Remove initial sign and embedded _ (spacer: ignored).
          (0=≢w)∨0∊w∊⎕D:err eBADBI  ⍝ w must include only ⎕D and at least one.
          d←dLZs rep ⎕D⍳w       ⍝ d: data portion of BIi
          ∆z s d                ⍝ If d is zero, return zero. Else (s d)
      }
      ⍝ ∆2Small: Import ⍵ only if (when imported) it is a single-hand integer
      ⍝          i.e. equivalent to a number (|⍵) < RX10.
      ⍝ Returns a small integer!
      ⍝ Usage: so far, we only use it in BI/X where we are passing data to an APL fn (⍳).
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
          sgn,⎕D[dLZs,⍉(NRX10⍴10)⊤|w]
      }
    exp←export
    ⍝ ∆z:  r:BIi ←∇ ⍵:BIi
    ⍝      If ⍵:BIi has data≡zero_D, then return (0 zero_D).
    ⍝      Else return ⍵ w/ leading zero deleted.
    ∆z←{w←dLZs⊃⌽⍵ ⋄ zero_D≡chkZ w : 0 zero_D ⋄ (⊃⍵) w}
    ⍝
    ⍝ ∆zU2I: If ⍵:BIu IS zero_D, then return (zero_D ⍵); else ⍺ ⍵
    ∆zU2I←{zero_D≡⍵:zero_D ⍵ ⋄ ⍺ ⍵}

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
    ⍝ name → _name  (no import )
      __in←('\b',__name,'\b')'←∆ +⍵' '←⍺ +∆ +⍵'
      __out←('_',__name)'←⍵' '←⍺ ⍵'
      :If ' '≠1↑0⍴⎕FX(__in ⎕R __out⊣⎕NR __name)
          ⎕←'Unable to create function _',__name
      :EndIf
      ⍝ name → nameX  (export ⍺ name ⍵)
      ⍝ From e.g. root, create rootX, which is {export ⍺ root ⍵}
      :Trap 0
          ⍎__name,'X←{⍺←⊢ ⋄ export ⍺ ',__name,' ⍵}'
      :Else
          ⎕←'Unable to create function ',__name,'X'
      :EndTrap
    ∇

    ⍝ neg[ate] / _neg[ate]
      neg←{                               ⍝ -
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
          sw=¯1:∆z sw(⊃⌽dec 1 w)           ⍝ ⍵<0? inc ⍵ becomes -(dec |⍵). ∆x handles 0.
          î←1+⊃⌽w                          ⍝ trial increment (most likely path)
          RX10>î:sw w⊣(⊃⌽w)←î                ⍝ No overflow? Increment and we're done!
          sw w add 1 one_D                 ⍝ Otherwise, do long way.
      }
    ⍝ dec[rement]:                         ⍝ ⍵-1
      dec←{
          (sw w)←∆ ⍵
          sw=0:¯1 one_D                    ⍝ ⍵ is zero? Return ¯1
          sw=¯1:∆z sw(⊃⌽inc 1 w)           ⍝ ⍵<0? dec ⍵  becomes  -(inc |⍵). ∆z handles 0.
                                           ⍝ If the last digit of w>0, w-1 can't underflow.
          0≠⊃⌽w:∆z sw w⊣(⊃⌽w)-←1           ⍝ No underflow?  Decrement and we're done!
          sw w sub 1 one_D                 ⍝ Otherwise, do long way.
      }
      not←{
          sw bw←bitsView ⍵
          sw ubits2BI~bw
      }
    ⍝ popCount: # of bits in a bigInteger (2's-complement)
    ⍝   that DIFFER from the twos-complement sign-bit,
    ⍝   i.e. that are 1s for pos #s and 0s for negative...
      popCount←{
          sw bw←bitsView ⍵
          sw≥0:1,⊂+/bw    ⍝ non-neg:  (# of 1s)
          ¯1,⊂+/~bw     ⍝ neg:     -(# of 0s)
      }
    ⍝ fact: compute BI factorials.
    ⍝       r:BIc ← fact ⍵:BIx
    ⍝ We allow ⍵ to be of any size, but numbers larger than NRX10 are impractical.
    ⍝ We deal with 3 cases:
    ⍝    ⍵ ≤ 31:    We let APL calculate, with ⎕PP←34.   Fast.
    ⍝    ⍵ ≤ NRX10:   We calculate r as a BigInt, while counting down ⍵ as an APL integer. Moderately fast.
    ⍝    Otherwise: We calculate entirely using BigInts for r and ⍵. Slowwwwww.
      fact←{                                ⍝ !⍵
          sw w←∆ ⍵
          sw=0:one                          ⍝ !0
          sw=¯1:err eFACTOR                 ⍝ ⍵<0
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
    ⍝ roll ⍵: Compute a random number between 0 and ⍵-1, given ⍵>0.
    ⍝    r:BIi ← ∇ ⍵:BIi   ⍵>0.
    ⍝ With inL the # of dec digits in ⍵, excluding any leading '0' digits...
    ⍝ Proceed as shown here, where (exp ⍵) is "exported" BI format; (∆ ⍵) is internal BI format.
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
      ⍝ bits2BI <<<BEGIN>>>
      ⍝ bits2BI:     r@BI ← sign∊(¯1 0 1) ∇  bits@B[]
      ⍝ If object is not multiple of nbe bits, propagate the sign bit ⍺
      ⍝ (1=neg, 0=non-neg) on the left (padding what will be the leftmost,
      ⍝ high order, int in the resulting bigInt vector).
      ⍝ If sign is neg, add ¯1 prefix to each row to decode as twos-complement neg numbers.
      bits2BI←{
          sg←⍺                                  ⍝ sg: bigInt sign scalar ∊ ¯1 0 1
          0∊⍵∊0 1:err'Argument is not a vector of bits (1s and 0s)'
        ⍝ Break ⍵ into NRX2∆-bit chunk, propagating the sign bit specified if enabled...
          bits←NRX2∆(sg chunkBits)⍵
          dig←,|2⊥⍉sg preDecode bits
        ⍝ Experimental code...
        ⍝ 1∊RX10≤dig:sg,⊂ndnZ 0,dig⊣⎕←'bits2BI: normalizing down'
          ∆z sg,⊂dig
      }

    ∇ {yes}←UseTwosComplements yes;_chunkS;_chunkU;_preDecodeS;_preDecodeU
    ⍝ chunk---, decode...: see bits2BI
    ⍝ These determine whether bit routines encode twos-complement or keep bit strings positive...
      _chunkS←{c←(⌈⍺÷⍨≢⍵)⍺ ⋄ flipCond←~⍣(⍺⍺<0) ⋄ c⍴flipCond(-×/c)↑flipCond ⍵}  ⍝ Propagate sign  (1 if neg, 0 if pos)
      _chunkU←{c←(⌈⍺÷⍨≢⍵)⍺ ⋄ c⍴(-×/c)↑⍵ ⋄ ⍺⍺'ignored'}       ⍝ Treat bits as if positive #
      _preDecodeS←{⍺=¯1:⍺,⍵ ⋄ ⍵}
      _preDecodeU←⊢
      :If yes
          twosComplement←1
          chunkBits←_chunkS
          preDecode←_preDecodeS
      :Else
          twosComplement←0
          chunkBits←_chunkU
          preDecode←_preDecodeU
      :EndIf
    ∇
    UseTwosComplements 0
    ⍝ bits2BI <<<END>>>

      ⍝ BI2Bits:   r@B[]  ← ∇ BI
      ⍝ ⍵ must be a properly formed bigInt.
      ⍝ Returns: a twos-complement bit representation of ⍵.
      ⍝ While the sign-bit is included, bits2bi will include
      ⍝ the original sign-bit, meaning the sign bit can not be
      ⍝ altered by bit manipulation.
      BI2Bits←{
          sw w←∆ ⍵
          twosComplement:BIu2Bits w×sw    ⍝ Uses twos-complement if sw<0
          BIu2Bits w
      }
      BIu2Bits←{
          ,⍉RXBASE∆⊤⍵                      ⍝ Uses twos-complement if ⍵<0
      }

      ⍝ bitsView: Given a bigInt, returns (sign)(bigInt-as-bits)
      ⍝ Kludge: Gets bits unsigned (see bits2BI)
      bitsView←{
          sw w←∆ ⍵
          sw(BI2Bits ⍵)
      }
      ⍝ Given two bigInts ⍺, ⍵
      ⍝ Returns each converted to bits and
      ⍝ padded on the left to the length of the longest.
      ⍝ If the int is neg, pad with 1; else with 0.
      bitsView2←{
          (sa ba)(sw bw)←bitsView¨⍺ ⍵
          ⋄ m←(≢ba)⌈≢bw
          ⋄ chunkS←{flipCond←~⍣(⍺⍺<0) ⋄ ⍺⍺,⊂flipCond ⍺↑flipCond ⍵} ⍝ Pad as signed
          ⋄ chunkU←{⍺⍺,⊂⍺↑⍵}                          ⍝ Pad as signed
          twosComplement:(m(sa chunkS)ba)(m(sw chunkS)bw)
          (m(sa chunkU)ba)(m(sw chunkU)bw)
      }

    ⍝ ubits2BI: Takes a set of unsigned bits ⍵ and return a signed integer
    ⍝    based on the sign ⍺.
    ⍝    If ⍵ is not 0, ⍺ is used to set sign to ¯1 or 1.
    ⍝    Otherwise, returns bigInt 0.
    ⍝ Unsigned ubits2BI (bits no sign bit → |BIi) and BIu2Bits (BIu → bits)
    ⍝ ⍺: Take sign bit from external routine...
    ⍝    Used internally, so no validation that ⍵ is only bits
      ubits2BI←{⍺←1
          ⍺ bits2BI ⍵
      }
    ⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

    ⍝ (int)root: A fast integer nth root.
    ⍝ Syntax:    x@BIi ← nth@BIx<RX10 ∇ N@BIx     ==>  x ← N *÷nth
    ⍝   nth: a small, positive integer (<RX10); default 2 (for sqrt).
    ⍝   N:   any BIx
    ⍝   x:   the nth root as an internal big integer.
    ⍝   ∘ Uses Fredrick Johanssen's algorithm with optimization for APL integers.
    ⍝   ∘ Estimator based on guesstimate for sqrt N, no matter what root.
    ⍝     (Better than using N).
    ⍝   ∘ As fast for sqrt as a "custom" version.
    ⍝   ∘ If N is small, calculate directly via APL.
    ⍝ x:BIi ← nth:small_(BIi|BIx) ∇ N:(BIi|BIx)>0
      root←{
        ⍝ Check radix in  N*÷radix
        ⍝ We work with bigInts here for convenience. Could be done unsigned...
          ⍺←2 ⍝ sqrt...
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
    recip←{{0=≢⍵: ÷0 ⋄ 1≠≢⍵:0 ⋄ 1=|⍵:⍵ ⋄ 0}dLZs ⍵}

  ⍝ genVariants: For negate, create related _negate, such that
  ⍝        _negate import ⍵   <==> negate ⍵
  ⍝ etc.
    genVariants¨ 'neg'  'sig'   'abs'  'inc'
    genVariants¨ 'dec'  'fact'  'roll'

    :Endsection BI Monadic Functions/Operands
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Dyadic Functions/Operations
  ⍝ dyad:    compute all supported dyadic functions
  ⍝ The first name will be the APL std name (exceptions noted), followed by
  ⍝ abbreviations and common alternatives.
  ⍝ E.g. dyadic | is called  residue; we define res[idue] and mod[ulo], i.e.  res⍨.
  ⍝ Each name (sub, etc.) has a version (_sub) that assumes data already imported...

      add←{
          (sa a)(sw w)←⍺ ∆ ⍵
          sa=0:sw w                           ⍝ optim: ⍺+0 → ⍺
          sw=0:sa a                           ⍝ optim: 0+⍵ → ⍵
          sa=sw:sa(ndnZ 0,+⌿a mix w)       ⍝ 5 + 10 or ¯5 + ¯10
          sa<0:sw w sub 1 a              ⍝ Use unsigned vals: ¯10 +   5 → 5 - 10
          sa a sub 1 w                   ⍝ Use unsigned vals:   5 + ¯10 → 5 - 10
      }
      sub←{
          (sa a)(sw w)←⍺ ∆ ⍵
          sw=0:sa a                            ⍝ optim: ⍺-0 → ⍺
          sa=0:(-sw)w                          ⍝ optim: 0-⍵ → -⍵ 
          sa≠sw:sa(ndnZ 0,+⌿a mix w)           ⍝ 5-¯3 → 5+3 ; ¯5-3 → -(5+3)
          <cmp a mix w:(-sw)(nupZ-⌿dck w mix a)    ⍝ 3-5 →  -(5-3)
          sa(nupZ-⌿dck a mix w)                ⍝ a≥w: 5-3 → +(5-3)
      }
      mul←{
          (sa a)(sw w)←⍺ ∆ ⍵
          0∊sa,sw:zero
          two_D∊a w : {⍺←sa×sw ⋄ ⍵: ⍺(w _plus w) ⋄ ⍺(a _plus a)}two_D≡a
          one_D∊a w : {⍺←sa×sw ⋄ ⍵: ⍺ w ⋄ ⍺ a}one_D≡a 
          (sa×sw)(a mulU w)
      }
      div←{
          (sa a)(sw w)←⍺ ∆ ⍵
          (sa×sw)(⊃a divU w)
      }
      divRem←{
          (sa a)(sw w)←⍺ ∆ ⍵
          div rem←a divU w
          ((sa×sw)∆zU2I div)(sw ∆zU2I rem)
      }
    ⍝ ⍺ pow ⍵:
    ⍝   General case:  ⍺*⍵ where both are BIi
    ⍝   Special case:  ⍵≡0.5 or '0.5':    sqrt ⍵
    ⍝                  The string must match EXACTLY ('00.5' will fail)
      pow←{
          (⊂⍵)∊0.5 '0.5':sqrt ⍺    ⍝  ⍺ pow 0.5 → sqrt ⍺
          (sa a)(sw w)←⍺ ∆ ⍵
          sa sw∨.=0 ¯1:zero        ⍝ r←⍺*¯⍵ is 0≤r<1, so truncates to 0.
          w≡two_D:1 (a mulU a)     ⍝ ⍺*2   ==>   ⍺×⍺
          p←a powU w
          sa≠¯1:1 p                ⍝ sa= 1 (can't be 0).
          0=2|⊃⌽w:1 p              ⍝ ⍺ is neg, so result is pos. if ⍵ is even.
          ¯1 p
      }
      rem←{                        ⍝ remainder/residue. APL'S DEF: ⍺=base.
          (sa a)(sw w)←⍺ ∆ ⍵
          sw=0:zero
          sa=0:sw w
          r←,a remU w              ⍝ remU is fast if a>w
          sa=sw:∆z sa r            ⍝ sa=sw: return (R)        R←sa r
          zero_D≡r:zero            ⍝ sa≠sw ∧ R≡0, return 0
          ∆z sa a sub sa r         ⍝ sa≠sw: return (A - R')   A←sa a; R'←sa r
      }
    res←rem                        ⍝ residue (APL name)
    mod←{⍵ rem ⍺}                  ⍝ modulo←rem[ainder]⍨

    ⍝ mul2Exp:  Shift ⍺:BIx left or right by ⍵:Int binary digits
    ⍝  r:BIi ← ⍺:BIi   ∇  ⍵:aplInt
    ⍝     Note: ⍵ must be an APL integer (<RX10).
    ⍝  -  If ⍵>0: shift ⍺ left by ⍵-decimal digits
    ⍝  -  If ⍵<0: shift ⍺ rght by ⍵ decimal digits
    ⍝  -  If ⍵=0: then ⍺ will be unchanged
    ⍝ GMP: mul_2exp
      mul2Exp←{
          shiftU←{⍵<0:chkZ ⍵↓⍺ ⋄ ⍺,⍵⍴0}             ⍝ <bits> shift <degree> (left=pos.)
          (sa a)(sw w)←⍺ ∆ ⍵
          1≠≢w:err eMUL10                       ⍝ ⍵ must be small integer.
          sa=0:0 zero_D                           ⍝ ⍺ is zero: return 0.
          sw=0:sa a                               ⍝ ⍵ is zero: ⍺ stays as is.
        ⍝ Kludge- use unsigned ints... otherwise odd results with neg #s
          ∆z sa(⊃⌽1 ubits2BI(BI2Bits 1 a)shiftU sw×w)
      }
      div2Exp←{
          ⍺ mul2Exp negate ⍵
      }
    shiftBinary←mul2Exp
    shiftB←mul2Exp

    ⍝ mul10Exp: Shift ⍺:BIx left or right by ⍵:Int decimal digits.
    ⍝      Converts ⍺ to BIc, since shifts are a matter of appending '0' or removing char digits from right.
    ⍝  r:BIi ← ⍺:BIi   ∇  ⍵:Int
    ⍝     Note: ⍵ must be an APL integer (<RX10).
    ⍝  -  If ⍵>0: shift ⍺ left by ⍵-decimal digits
    ⍝  -  If ⍵<0: shift ⍺ rght by ⍵ decimal digits
    ⍝  -  If ⍵=0: then ⍺ will be unchanged
      mul10Exp←{
          (sa a)(sw w)←⍺ ∆ ⍵
          1≠≢w:err eMUL10                          ⍝ ⍵ must be small integer.
          sa=0:zero                                ⍝ ⍺ is zero: return 0.
          sw=0:sa a                                ⍝ ⍵ is zero: sa a returned.
          ustr←export 1 a                          ⍝ ⍺ as unsigned string.  
          ss←'¯'/⍨sa=¯1                            ⍝ sign as string
          sw=1: ∆ ss,ustr,w⍴'0'                    ⍝ sw= 1? shift right by appending zeroes.
          ustr↓⍨←-w                                ⍝ sw=¯1? shift right by dec truncation
          0=≢ustr:zero                             ⍝ No chars left? It's a zero
          ∆ ss,ustr                                ⍝ Return in internal form...
      }
    shiftDecimal←mul10Exp                          ⍝ positive/left
    shiftD←mul10Exp

  ⍝ (bi.exp 3000 bi.div10 2)  ≡ 30  ≡  (bi.exp 3000 bi.mul10Exp ¯2)
    div10Exp←{⍺ _mul10Exp neg ⍵}

    and←{⍺ ∧bits ⍵}
    or←{⍺ ∨bits ⍵}
    xor←{⍺ ≠bits ⍵}
    ⍝ a (logop bits) w
    ⍝ DYADIC...
    ⍝ bits: Perform bitwise  and signwise comparisons of bigInts ⍺, ⍵
    ⍝       1. View ⍺, ⍵ as bits
    ⍝       2. Pad the shorter of ⍺, ⍵ to the length of the longer:
    ⍝          Pad by replicating the sign-bit (1=neg, 0=otherwise)
    ⍝          on the left.
    ⍝          If ⍵ is
    ⍝             ¯1 → ¯1 (1) → ¯1 (20⍴1)
    ⍝          and ⍺ has 40 bits, then pad ⍵ with 1 (neg sign-bit):
    ⍝             ¯1 ((20⍴1),20⍴1)
    ⍝       3. Perform ⍺⍺ pairwise on each element of ⍺, ⍵
    ⍝       4. Perform ⍺⍺ on the signs, this way:
    ⍝             If   (sign_⍵=¯1)⍺⍺(sign_⍺=¯1)
    ⍝             then sign_result ← ¯1 else 0.
    ⍝          That way, relationals like < or > will work properly,
    ⍝          (or user relationals), within the domain of 0 1.
    ⍝          Let sign_⍺←¯1, but sign_⍵←1:
    ⍝          so  (sign_⍵=¯1)<(sign_⍺=¯1)
    ⍝          so           0 < 1
    ⍝          so the resulting sign is ¯1.
    ⍝       5. View the result as a signed bigInt.
    ⍝ MONADIC...
    ⍝  bits: Perform bitwise ⍺⍺ on bigInt ⍵ as sequence of bits and sign bit.
    ⍝ See BIB←{bi.export ⍺ bi.bits ⍵}
      bits←{⍺←⊢
          0≡⍺ 0:⍺ ⍺⍺{
              sw bw←bitsView ⍵
              ⍺⍺(sw=¯1):¯1 ubits2BI ⍺⍺ bw
              1 ubits2BI ⍺⍺ bw
          }⍵
          (sa ba)(sw bw)←⍺ bitsView2 ⍵
          (sw=¯1)⍺⍺(sa=¯1):¯1 ubits2BI(ba ⍺⍺ bw)
          1 ubits2BI(ba ⍺⍺ bw)
      }
    ⍝ flipBits:  r:BI ← ⍺:I[] ∇ ⍵:BI
    ⍝ Flips bits ⍺ of bigInteger ⍵ and returns it.
    ⍝ Bit 0 is the rightmost bit in ⍵...
      flipBits←{sw w←∆ ⍵
          b←BI2Bits ⍵
          i←(≢b)-⍺+1
          (i⌷b)←~i⌷b
          sw bits2BI b
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
  ⍝        (import ⍺) _add import ⍵   <==> ⍺ add ⍵
    genVariants¨ 'add'    'sub' 'mul' 'div'
    genVariants¨ 'divRem' 'pow' 'rem' 'res'  'mod'
    genVariants¨ 'mul2Exp'  'div2Exp'      'shiftBinary' 'shiftB'
    genVariants¨ 'mul10Exp' 'shiftDecimal' 'shiftD'      'gcd' 'lcm'

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
          2≠≢⍵:eModMul ⎕SIGNAL 11
          a(b m)←(∆ ⍺)(⊃∆/⍵)
          m _rem(m _rem a)_mul(m _rem b)
      }
    modMulX←{export ⍺ modMul ⍵}

    eModMul←'modMul syntax: ⍺ ∇ ⍵1 ⍵2',⎕UCS 10
    eModMul,←'               ⍺: multiplicand, ⍵1: multiplier, ⍵2: base for modulo'

    :EndSection BI Special Functions/Operations (More than 2 Args)
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Unsigned Utility Math Routines
    ⍝ These are the workhorses of bigInt; most are from dfns:nats (handling unsigned bigInts).
    ⍝ Note: ⍺ and ⍵ are guaranteed by BI and BIX to be vectors, but not
    ⍝       by internal functions or if called directly.
    ⍝       So tests for 2, 1, 0 (two_D etc) use ravel:  (two_D≡,⍺)

    ⍝ addU:   ⍺ + ⍵
      addU←{
          dLZs ndn 0,+⌿⍺ mix ⍵    ⍝ We use dLZs in case ⍺ or ⍵ have multiple leading 0s. If not, use ndnZ
      }
    ⍝ subU:  ⍺ - ⍵   Since unsigned, if ⍵>⍺, there are two options:
    ⍝        [1] Render as 0
    ⍝        [2] signal an error...
      subU←{
          <cmp ⍺ mix ⍵:eSUB ⎕SIGNAL 11          ⍝ [opt 2] 3-5 →  -(5-3)
          dLZs nup-⌿dck ⍺ mix ⍵                 ⍝ a≥w: 5-3 → +(5-3). ⍺<⍵: 0 [opt 1]
      }
    eSUB←'bigInt subU: unsigned subtraction may not become negative'
    ⍝ mulU:  multiply ⍺ × ⍵  for unsigned BIi ⍺ and ⍵
    ⍝ r:BIi ← ⍺:BIi ∇ ⍵:BIi
    ⍝ This is dfns:nats mul.
    ⍝ It is faster than dfns:xtimes (FFT-based algorithm)
    ⍝ even for larger numbers (up to xtimes smallish design limit)
    ⍝ We call ndnZ to remove extra zeros, esp. so zero is exactly ,0 and 1 is ,1.
      mulU←{
          dLZs ⍺{                                 ⍝ product.
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
   ⍝       Returns 1 (a*⍵) if even power, else 0(⍺*⍵).
   ⍝       For ⍺*1, returns 0 ⍺, which indicates to caller to use sign sa of left operand ⍺'.
   ⍝ RXdiv2: (Defined above.)
      powU←{                                  ⍝ exponent.
          zero_D≡,⍵:one_D                     ⍝ =cmp ⍵ mix,0:,1 ⍝ ⍺*0 → 1
          one_D≡,⍵:,⍺                         ⍝ =cmp ⍵ mix,1:⍺  ⍝ ⍺*1 → ⍺. Return "odd," i.e. use sa in caller.
          hlf←{,ndn(⌊⍵÷2)+0,¯1↓RXdiv2×2|⍵}    ⍝ quick ⌊⍵÷2.
          evn←ndnZ{⍵ mulU ⍵}ndn ⍺ ∇ hlf ⍵     ⍝ even power
          0=2|¯1↑⍵:evn ⋄ ndnZ ⍺ mulU evn      ⍝ even or odd power.
      }
   ⍝ divU/: unsigned division
   ⍝  divU:   Removes leading 0s from ⍺, ⍵ then calls _divU
   ⍝ Returns:  (int. quotient) (remainder)
   ⍝           (⌊ua ÷ uw)      (ua | uw)
   ⍝   r:BIi[2] ← ⍺:BIi ∇ ⍵:BIi
      divU←{
          a w←dLZs¨⍺ ⍵
          zero_D≡,⍵:a{                        ⍝ ⍺÷0
              zero_D≡,⍺:one_D                 ⍝ 0÷0 → 1 remainder 0
              1÷0                             ⍝ Error message
          }w
          svec←(≢w)+⍳0⌈1+(≢a)-≢w              ⍝ shift vector.
          dLZs¨↑w{                            ⍝ fold along dividend.
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

    atom←{1=≢⍵:⍬⍴⍵ ⋄ ⊂⍵}                    ⍝ If ⍵ is length 1, treat as a scalar (atom).

  ⍝ These routines operate on unsigned BIu data unless documented…
    dLZ←{(0=⊃⍵)↓⍵}                          ⍝ drop FIRST leading zero.
    dLZs←{chkZ(∨\⍵≠0)/⍵}                    ⍝ drop RUN of leading zeros, but [PMS] make sure at least one 0
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

    :Section Utilities: bi, dc (desk calc), BIB, BIC, BI∆HERE
   ⍝ bi      - simple niladic fn, returns this bigint namespace #.BigInt
   ⍝           If ⎕PATH points to bigInt namespace, bi will be found without typing explicit path.
   ⍝ bi.dc   - desk calculator (self-documenting)
   ⍝ BIB     - Shortcut to manipulate BIs as arbitrary signed binary numbers
   ⍝ BIC     - Utility to compile code strings or functions with BI arithmetic
   ⍝ BI∆HERE - Utility to compile and run embedded code (stored as comments) on the fly

   ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
   ⍝ Utilities…

  ⍝ bi:  Returns ⎕THIS
    ⎕FX 'ns←bi' 'ns←⎕THIS'
    ⎕FX 'ns←_bigInt_' 'ns←⎕THIS'    ⍝ A more unique name for use by utilities...

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
      msg←↑msg
      ⍝ This
      ⍝   ⎕ED&'msg'
      ⍝ Replaces:
      alert msg
     
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
          0::'bigInt BIB error'⎕SIGNAL ⎕EN
          ⍺←⊢
          bi.exp ⍺ ⍺⍺ bits ⍵
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
    ⍝ See BigIntHelp
    ∇ HELP
      ##.BigIntHelp.HELP
    ∇
    ∇ help
      ##.BigIntHelp.HELP
    ∇
    ∇ Help
      ##.BigIntHelp.HELP
    ∇
    ∇ BI_HELP
      ##.BigIntHelp.BI_HELP
    ∇
    ∇ BIB_HELP
      ##.BigIntHelp.BIB_HELP
    ∇
    ∇ BIC_HELP
      ##.BigIntHelp.BIC_HELP
    ∇
    ∇ BI∆HERE_HELP
      ##.BigIntHelp.BI∆HERE_HELP
    ∇

    :EndSection Documentation   -------------------------------------------------------------------------

    :Section Bigint Namespace - Postamble
        ssplit←{⍵[⍋↑⍵]}{⍵⊆⍨' '≠⍵}     ⍝ ssplit: split and sort space-separated words...
    _←0 ⎕EXPORT ⎕NL 3 4
    _←1 ⎕EXPORT ssplit '_bigInt_ bi bix BI BIB BIM BIX BIB_HELP BIC BI∆HERE BIC_HELP BI_HELP BI∆HERE_HELP HELP RE∆GET'

    ⎕PATH←⎕THIS{0=≢⎕PATH:⍕⍺⊣⎕← '⎕PATH was null. Setting to ''',(⍕⍺),''''⋄ ⍵}⎕PATH

    note 'For help, type bi.HELP'
    note '¯¯¯ ¯¯¯¯¯ ¯¯¯¯ ¯¯¯¯¯¯¯'
    note 'To access bigInt functions directly, use bi (lower-case)  as shortcut to bigInt namespace:'
    note '    10 bi.add 3 bi.mul 9'
    note '    bi.dc    - big integer desk calculator'

    fns1←ssplit 'sig export exp fact neg recip roll'
    fns2←'div divRem gcd lcm  abs sub'
    fns2←ssplit fns2,' add mul pow rem res mod mul10Exp div10Exp'

    note 50⍴'-'⋄ note'  MONADIC FUNCTIONS' ⋄ note 50⍴'¯' ⋄ note ↑fns1
    note 50⍴'-'⋄ note'  DYADIC FUNCTIONS ' ⋄ note 50⍴'¯' ⋄ note ↑fns2
    note 50⍴'-'
    note'Exporting…'⊣⎕EX '_' 'ssplit'
    note{(⎕EXPORT ⍵)⌿⍵}⎕NL 3 4
    note'*** ',(⍕⎕THIS),' initialized. See ',(⍕⎕THIS),'.HELP'
    note 50⍴'-'
    :EndSection Bigint Namespace - Postamble

:EndNamespace
