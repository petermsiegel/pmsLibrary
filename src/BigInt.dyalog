:NAMESPACE BigInt
⍝  Built on dfns::nats, restructured for signed integers. Faster than dfns::big.
⍝  ∘ The operator BI is the most general utility. It returns big integers in an external (string) format.
⍝  ∘ The operator BII is the same as BI, except for returning big integers in a more efficient internal format. 
⍝  > Both allow arguments in either the external (string) or internal formats.
⍝  ∘ The niladic function BI_DC is a desk calculator for big integers.
⍝
⍝  FOR HELP information, see :SECTION HELP or call BI_HELP.

:Section BI
  :Section PREAMBLE
  ⍝ Set DEBUG←1 to disable signal trapping.
    DEBUG←0                           
    ⎕IO ⎕ML ⎕PP ⎕CT ⎕DCT←  0 1 34 0 0  
  ⍝ ⎕FR as set here is used below to set constant OFL (overflow) used in multiplication.    
    ⎕FR←645                    
  ⍝ Err:  [1∊⍺] Err msg => Signals 'BI msg'; else NOP.
    Err←⎕SIGNAL/{⍺←1 ⋄ Clip←(⎕PW-13)∘{⍺>≢⍵: ⍵ ⋄ (⍺↑⍵),'...',⍵↑⍨¯8} ⋄ 1∊⍺: (Clip 'BI DOMAIN ERROR: ',⍵) 11 ⋄ ⍬ ⍬ }   
  :EndSection PREAMBLE

  :Section BI Initializations
  ⍝+------------------------------------------------------------------------------+⍝
  ⍝+-- BI INITIALIZATIONS                            BI INITIALIZATIONS         --+⍝
  ⍝-------------------------------------------------------------------------------+⍝

  ⍝ Key Bigint constants...
  ⍝ There's little reason to play with these; perhaps in the future different numbers will have performance impact.
    NRX2←            20                                  ⍝ Num bits in a "hand"
    NRX10←           ⌊10⍟RX2←2*NRX2                      ⍝ Max num of dec digits in a hand
    NRX2BASE←        NRX2⍴2                              ⍝ Encode/decode binary base
    RX10BASE←        NRX10⍴10                            ⍝ Encode/decode decimal base
    RX10←            10*NRX10                            ⍝ Actual base for each hand (each hand ⍵ < RX10)
    RX10div2←        RX10÷2                              ⍝ (RX10÷2) For use in <pow> (power).
    OFL←             ⌊(2*53 93⊃⍨1287=⎕FR)÷×⍨RX10         ⍝ Overflow bits; used in mulU (unsigned multiply)
                                                         ⍝ ... depends on integer bits avail in floats (i.e. ⎕FR)                          
  ⍝ --------------------------------------------------------------------------------------------------
  ⍝ FNS_MONADIC, FNS_DYADIC - these constants are required for BIC to function, so keep them complete!
  ⍝ The first vector in each constant has single-char symbols; the 2nd has multi-char symbols...
  ⍝             ↓single-char symbols     ↓multi-char names in upper case
    FNS_MONADIC←'-+|×÷<>≤≥!?⊥⊤⍎→√~⍳≢'   ('SQRT' '⎕AT') 
  ⍝             ↓reg. fns           ↓boolean   ↓multi-symbol ↓<use upper case here>
    FNS_DYADIC←('+-×*÷⌊⌈|∨∧⌽↑↓√~⍟⍴','<≤=≥>≠') ('*∘÷' '*⊢÷'   'ROOT' 'SHIFTD' 'SHIFTB'  'DIVREM' 'MOD' 'GCD' 'LCM')
 
  ⍝ Data field (unsigned) constants for internal unsigned utilities only
    ZERO_D←   ,0                                         ⍝ data field ZERO, i.e. unsigned canonical ZERO
    ONE_D←    ,1                                         ⍝ data field ONE,  i.e. unsigned canonical ONE
    TWO_D←    ,2                                         ⍝ data field TWO
    TEN_D←   ,10                                         ⍝ data field TEN

  ⍝ BigInt signed CONSTANTS for users and internal utilities.
    ZERO_BI←      0 ZERO_D                               ⍝  0
    ONE_BI←       1  ONE_D                               ⍝  1
    TWO_BI←       1  TWO_D                               ⍝  2
    MINUS1_BI←   ¯1  ONE_D                               ⍝ ¯1
    TEN_BI←       1  TEN_D                               ⍝ 10
  
  ⍝ Error messages. See dfn <Err> above.
    eIMPORT←  'Object not a valid BigInt: '
    eBADRAND← 'Arg to roll (?) must be integer >0.'
    eFACTOR←  'Arg to factorial (!) must be ≥ 0'
    eBADRANGE←'BigInt too large to be approximated in APL: outside dynamic range (±1E6145)'
    eBIC←     'BIC: arg must be a fn name or one or more code strings.'
    eBOOL←    'Importing bits: boolean arg (1s or 0s) expected.'
    eCANTDO1← 'Monadic function not implemented: '
    eCANTDO2← 'Dyadic function not implemented: '
    eBIMDYAD← 'BIM Operator: only dyadic functions are supported.'
    eLOG←     'Log of a non-positive BigInteger is undefined'
    eSMALLRT← 'Right argument must be a small APL integer ⍵<',⍕RX10
    eMUL10←    eSMALLRT
    eROOT←    'Base (⍺) for root must be small non-zero integer: ⍺<',⍕RX10
    eSUB←     'subU LOGIC: unsigned subtraction may not become negative'

    :EndSection BI Initializations

    :Section Operators BI and BII
    ∇ BI_HELP;⎕PW
     ⍝ extern: HELP_INFO
      :If 0=⎕NC'HELP_INFO' ⋄ HELP_INFO←'^\h*⍝H(.*)$'⎕S'\1'⎕SRC ⎕THIS ⋄ :EndIf
      ⎕PW←120 ⋄ (⎕ED⍠'ReadOnly' 1)&'HELP_INFO'
    ∇


    ⍝ BII: Basic utility operator for using APL functions in special BigInt meanings.
    ⍝     BIint←  ∇ ⍵:BIext
    ⍝     Returns BIint, an internal format BigInteger structure (sign and data, per above).
    ⍝     See below for exceptions ⊥ ⊤ ⍎
    ⍝ BI: Basic utility operator built on BII.
    ⍝     BIext←  ∇ ⍵:BIext
    ⍝     Returns BIext, an external string-format BigInteger object ("[¯]\d+").
    ⍝ Note: _BIX_ is a "template" operator to be replaced, after substitutions, by operators BI and BII.
    ⍝ Note: _EXP_     is a  conditional "template" fn to be replaced by name "Export" in BI and null (no function) in BII.

⍝ --------------------------------------------------------------------------------------------------
⍝   DecodeCall: Handle operator name plus monadic vs dyadic plus operands like +⍨ (or silly expr. like +⍨⍨).
⍝   retVal← ⍺ ⍺⍺ DecodeCall ⍵
⍝   retVal: fnAtom monadFlag inverseFlag
⍝           inverseFlag: 0 - no inverse (⍺÷⍵ or +⍵), 1 - regular inverse (⍵+⍺), 2 - selfie ( ⍵ + ⍵)
      DecodeCall←{⍺←⊢
          GetOpName←{
            aa←⍺⍺ ⋄ 3≠⎕NC'aa': 1 ⎕C aa ⋄ ∊⍕⎕CR'aa'  
          }
          Decode←{
              fnAtom←  {1=≢⍵:⍬⍴⍵ ⋄ ⊂⍵}⍵~'⍨ ' 
              2|+/'⍨'=⍵:  fnAtom 0 (1+⍺)  ⋄ fnAtom ⍺ 0  
          }
          (1≡⍺ 1)Decode ⍺⍺ GetOpName ⍵
      }

    ⍝ _BIX_ is a template for ops BII and BI.
      _BIX_←{⍺←⊢
          DEBUG↓0::⎕SIGNAL/⎕DMX.(EM EN)
          QT←''''
          fn monad inv←⍺(⍺⍺ DecodeCall)⍵
          CASE←fn∘∊∘⊆
        ⍝ Monadic...
          monad:{                                
            ⍝ math                                   ACTION
              CASE'-':_EXP_ neg ⍵              ⍝     -⍵
              CASE'+':_EXP_ Import ⍵           ⍝     canon:  (Returns ⍵ in canon form, ensuring it is valid)
              CASE'|':_EXP_ abs ⍵              ⍝     |⍵
              CASE'×':_EXP_⊃Import ⍵           ⍝     ×⍵ (signum) Returns '1' '0' or '¯1'
              CASE'÷':_EXP_ recip ⍵            ⍝     inverse     Why bother?  ÷⍵ is 0 for all ⍵ but 1, ¯1, and 0.
            ⍝ Misc
              CASE'<':_EXP_ dec ⍵              ⍝     decrement   ⍵-1.  Fast unless about to overflow/underflow
              CASE'≤':_EXP_ dec ⍵              ⍝     decrement   ⍵-1.  Same as <, but J's symbol
              CASE'>':_EXP_ inc ⍵              ⍝     increment   ⍵+1.  Fast unless about to overflow/underflow
              CASE'≥':_EXP_ inc ⍵              ⍝     increment   ⍵+1.  Same as >, but J's symbol
              CASE'!':_EXP_ fact ⍵             ⍝     !⍵          Domain: small integers. Big ones will take forever.
              CASE'?':_EXP_ roll ⍵             ⍝     ?⍵        Domain: ⍵>0.  
              CASE'⍎':ExportApl ⍵              ⍝     aplint      If in range of valid APL number, returns it. Else error.
              CASE'⍕':Prettify Export Imp ⍵    ⍝     pretty      Returns a pretty BigInt string: - for ¯, and _ separator every 5 digits.
              CASE'SQRT' '√':_EXP_ sqrt ⍵      ⍝     ⍺*0.5       See also dyadic *.
            ⍝ Convenience non-Bigint operands for use in algorithms...
              CASE'⍳':⍳ReturnSmallAPLInt ⍵     ⍝     iota ⍵      Allow only small integers... Returns a set of APL integers
              CASE'≢':≢(Export Imp ⍵)~'_¯-'    ⍝     ≢⍵          Return # digits (ignoring '¯-_') in number as APL integer. 
            ⍝ "Export" the BI "Internal" Form, independent of whether a BI or BII call...
              CASE'→':Import ⍵                 ⍝     internal    Return ⍵ in internal form, whether called in BI or BII.
            ⍝ Bit manipulation - EXPERIMENTAL...
              CASE'⊥':_EXP_ BitsImport ⍵       ⍝     BitsImport  Convert bits to bigint
              CASE'⊤':BitsExport ⍵             ⍝     BitsExport  Convert bigint ⍵ to bits: sign bit followed by unsigned bit equiv to ⍵
              CASE'~':_EXP_ BitsImport~BitsExport ⍵  ⍝  Reverses all the bits in a bigint (why?)
              CASE'⎕AT':GetBIAttribs ⍵         ⍝     ⎕AT         Returns 3 integers based on internal form of Bigint ⍵:
                                               ⍝                      <num hands> <num bits> <num 1 bits>. See "hands".
            ⍝ NOT FOUND
              Err eCANTDO1,QT,QT,⍨fn          
          }⍵
      ⍝ Dyadic...
        ⍝ See discussion of ⍨ above...
          ⍺{
            ⍝ High Use: [Return BigInt]
              CASE'+':_EXP_ ⍺ add ⍵                  ⍝ ⍺ + ⍵
              CASE'-':_EXP_ ⍺ sub ⍵                  ⍝ ⍺ - ⍵
              CASE'×':_EXP_ ⍺ mul ⍵                  ⍝ ⍺ × ⍵
              CASE'÷':_EXP_ ⍺ div ⍵                  ⍝ ⌊⍺÷⍵   (integer division)
              CASE'*':_EXP_ ⍺ pow ⍵                  ⍝ a) Power b) Roots I.  a) ⍺ * ⍵ if ⍵ ≥ 1, b) (⌊÷⍵)th root of ⍺ if 0 < ⍵ < 1.
              CASE'*∘÷' '*⊢÷':_EXP_ ⍵ root ⍺         ⍝            Roots II.  ⍵th root of ⍺. E.g. x *∘÷ 2 is sqrt(x).
              CASE'√' 'ROOT':_EXP_ ⍺ root ⍵          ⍝           Roots III.  ⍺th root of ⍺  E.g. 2 ('√'BI) x is sqrt(x)
     
        ⍝ ↑ ↓ Decimal shift (mul, div by 10*⍵)
        ⍝ ⌽   Binary shift  (mul, div by 2*⍵)
              CASE'↑':_EXP_ ⍵ mul10Exp ⍺             ⍝  ⍵×10*⍺,   where ±⍺. Decimal shift.
              CASE'↓':_EXP_ ⍵ mul10Exp-⍺             ⍝  ⍵×10*-⍺   where ±⍺. Decimal shift right (+) or left (-).
              CASE'⌽':_EXP_ ⍵ mul2Exp ⍺              ⍝  ⍵×2*⍺     where ±⍺. Binary shift left (+) or right (-).
              CASE'|':_EXP_ ⍺ rem ⍵                  ⍝ remainder: |   (⍺ | ⍵) <==> (⍵ modulo a)
        ⍝ Logical: Return a single boolean, 1∨0, not '1' or '0'
              CASE'<':_BOOL_ ⍺ lt ⍵                  ⍝ ⍺ < ⍵ as per APL.
              CASE'≤':_BOOL_ ⍺ le ⍵                  ⍝ etc.
              CASE'=':_BOOL_ ⍺ eq ⍵                  ⍝ ⍺ = ⍵. ⍺ and ⍵ always compared in internal form
              CASE'≥':_BOOL_ ⍺ ge ⍵
              CASE'>':_BOOL_ ⍺ gt ⍵
              CASE'≠':_BOOL_ ⍺ ne ⍵                  ⍝ ⍺ ≠ ⍵. ⍺ and ⍵ always compared in internal form
        ⍝ Other fns
              CASE'⌈':_EXP_(Imp ⍺){⍺ ge ⍵:⍺ ⋄ ⍵}Imp ⍵ ⍝ ⍺ ⌈ ⍵   (signed)
              CASE'⌊':_EXP_(Imp ⍺){⍺ le ⍵:⍺ ⋄ ⍵}Imp ⍵ ⍝ ⍺ ⌊ ⍵   (signed)
              CASE'∨' 'GCD':_EXP_ ⍺ gcd ⍵             ⍝ ⍺∨⍵ as gcd.  NOT boolean or.
              CASE'∧' 'LCM':_EXP_ ⍺ lcm ⍵             ⍝ ⍺∧⍵ as lcm.  NOT boolean and.
              CASE'⍟':_EXP_ ⍺ log ⍵                   ⍝ ⍺ log ⍵
              CASE'MOD':_EXP_ ⍵ rem ⍺                 ⍝ modulo:  Same as |⍨
              CASE'SHIFTB':_EXP_ ⍺ mul2Exp ⍵          ⍝ Binary shift:  ⍺×2*⍵,  where ±⍵.   See also ⌽
              CASE'SHIFTD':_EXP_ ⍺ mul10Exp ⍵         ⍝ Decimal shift: ⍺×10*⍵, where ±⍵.   See also ↑ and ↓.
              CASE'DIVREM':_EXP_¨⍺ divRem ⍵           ⍝ Returns pair calculated together:  (⌊⍺÷⍵) (⍵|⍺)
            ⍝ Convenience non-Bigint operands for use in algorithms...
              CASE'⍴':(ReturnSmallAPLInt ⍺)⍴⍵         ⍝ USE??? Standard ⍴: Requires ⍺ in ⍺ ⍴ ⍵ to be in range of APL int.
            ⍝ NOT FOUND!
              Err eCANTDO2,QT,QT,⍨fn                  ⍝ Not found!
          }{2=inv:⍵ ⍺⍺ ⍵ ⋄ inv:⍵ ⍺⍺ ⍺ ⋄ ⍺ ⍺⍺ ⍵}⍵      ⍝ Handle ⍨.   inv ∊ 0 1 2 (0: not inv, 1: inv, 2: selfie)
      }
    ⍝ 
    ⍝  BIM:   Perform BI modulo <mod>.
    ⍝  BIM:   x (fn BIM mod) y  ==>   mod |BI x (fn BII) y, but 
    ⍝         More efficient for functions times (×) and exponent (*) and avoids some WS FULL.               
      BIM←{
          ⍺←⎕NULL ⋄  x y modulo←⍺ ⍵ ⍵⍵  
          fn←⊃x ⍺⍺ DecodeCall modulo
          ⍺≡⎕NULL: Err eBIMDYAD
          fn≡'×':  Export x (modulo modMul) y 
          fn≡'*':  Export x (modulo modPow) y
                   mod|BI x(fn BII)y
      }
    ⍝ Build BI and BII from _BIX_.
    ⍝ Input FN → Output FN   Symbol   Replaced by Comments
    ⍝ ¯¯¯¯¯¯¯¯   ¯¯¯¯¯¯¯¯¯   ¯¯¯¯¯¯   ¯¯¯¯¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    ⍝ _BIX_    →   BI       _EXP_¨     Export¨
    ⍝ _BIX_    →   BI       _EXP_      Export
    ⍝   "      →   BII      _EXP_¨     nop        BII returns internal format numbers
    ⍝   "      →   BII      _EXP_      nop        Ditto
    ⍝   "      →   both     _BOOL_     nop        _BOOL_ used solely to doc that bool fns return int 1 or 0
    
    ⎕FX'_BIX_' '_EXP_'   '_BOOL_'  ⎕R 'BI'  'Export' '' ⊣⎕NR'_BIX_'
    ⎕FX'_BIX_' '_EXP_¨?' '_BOOL_'  ⎕R 'BII' ''        '' ⊣⎕NR'_BIX_'
    ___←⎕EX '_BIX_'

    :EndSection Operators BI and BII
    ⍝ ----------------------------------------------------------------------------------------

    :Section BigInt internal structure
      ⍝ ============================================
      ⍝ Import / Imp - Import to internal bigInteger
      ⍝ ============================================
      ⍝  ⍺ Imp ⍵  →→  (Imp ⍺)(Imp ⍵)
      ⍝  Imp ⍵
      ⍝      from: 1) a BigInteger string,
      ⍝            2) a small APL integer, or
      ⍝            3) an internal-format BigInteger (depth ¯2), passed through unchanged.
      ⍝      to:   internal format (BIint) BigIntegers  ⍵'
      ⍝            of the form sign (data), where sign is a scalar 1, 0, ¯1; data is an integer vector.
      ⍝ Let Type=80|⎕DR ⍵  and Depth=|⍵          
      ⍝  Evaluate       Class       Action: Import as    Notes                
      ⍝ ---------------+----------------------------------------------------------------------- 
      ⍝  Depth ¯2       internal     ⍵ (no change)                                       
      ⍝  Type   0       num str      ImportStr ⍵              
      ⍝  Type   3       APL integer  ImportAplInt ⍵      Imports i) small ints w/o conversion and ii) larger ints  
      ⍝  Type   5, 7    APL Float    ImportFloat ⍵       Floats representing i) very large ints, ii) exponents up to 6145     
      ⍝ Output: BIint, i.e.  (sign (,ints)), where ints∧.<RX10
      ⍝
      ⍝ [⍺] Import ⍵
      ⍝ [⍺] Imp ⍵
      Import←{⍺←⊢
          1≢⍺ 1:   (∇ ⍺)(∇ ⍵)
          ¯2=≡⍵:    ⍵             ⍝ Fast: Internal BigInts (depth: ¯2) are of form:  [1|0|¯1] [int vector]
          type←80|⎕DR ⍵
          type=3:   ImportAplInt ⍵  
          type=0:   ImportStr ⍵ 
          type∊5 7: ImportFloat ⍵
          Err eIMPORT,⍕⍵
      }
      Imp←Import
      _Imp_←Import ⍝ Used solely in internal math fns used with DeclareInternalFn
 
      ⍝ ImportAplInt:    ∇ ⍵:I[1]
      ⍝ Import a small APL (native) integer into a BI.
      ⍝          ⍵ MUST Be an APL native (1-item) integer ⎕DR type 83 163 323.
      ImportAplInt←{
          1≠≢⍵:       Err eIMPORT,⍕⍵       ⍝ singleton only...
          RX10>u←,|⍵: (×⍵)u                ⍝ Small integer
          (×⍵)(chkZ RX10⊥⍣¯1⊣u)            ⍝ Integer
      }
      ⍝ ImportFloat: Convert an APL integer into a BIint
      ⍝ Converts simple APL native numbers, as well as those with large exponents, e.g. of form:
      ⍝     1.23E100 into a string '123000...000', ¯1.234E1000 → '¯1234000...000'
      ⍝ These must be in the range of decimal integers (up to +/- 1E6145).
      ⍝ If not, you must use big integer strings of any length (exponents are disallowed in BigInt strings).
      ⍝ Used in BII, BI automatically, but ImportFloat can be called by the user as well.
       ImportFloat←{⎕FR←1287 ⍝ 1287: to handle large exponents
          (1=≢⍵)∧(⍵=⌊⍵):(×⍵)(chkZ RX10⊥⍣¯1⊣|⍵)
          Err eIMPORT,⍕⍵
      }
      ⍝ ImportStr: Convert a BigInt in string format into an internal BigInt
      ⍝    ImportStr ⍵:S[≥1]   (⍵ must have at least one digit, possibly a 0).
      ⍝ Note: we don't allow spaces, since they might be understood as multiple bigints. 
      ⍝ Only _ can be used as a spacer.
      ImportStr←{
          s←1 ¯1⊃⍨'-¯'∊⍨1↑⍵            ⍝ Get sign, if any
          w←'_'~⍨⍵↓⍨s=¯1               ⍝ Remove initial sign and embedded _ (spacer: ignored).
          (0=≢w)∨0∊w∊⎕D:Err eIMPORT,⍵  ⍝ w must include only chars in ⎕D (besides above) and at least one.
          d←rep ⎕D⍳w                   ⍝ d: data portion of BIint
          dlzNorm s d                  ⍝ Normalize (remove leading 0s). If d is zero, return ZERO_BI.
      }
      ⍝ ReturnSmallAPLInt: Import ⍵ only if (when Imported) it is a single-hand integer
      ⍝          i.e. equivalent to a number (|⍵) < RX10.
      ⍝ Returns a small APL integer!
      ⍝ Usage: so far, we only use it in BI/BII where we are passing data to an APL fn (⍳).
      ReturnSmallAPLInt←{
          s w←Imp ⍵ ⋄ 1≠≢w:Err eSMALLRT ⋄ s×,w
      }
    ⍝ ---------------------------------------------------------------------
    ⍝ Export: EXPORT a SCALAR BigInt to external "standard" bigInteger
    ⍝ ---------------------------------------------------------------------
    ⍝    r:BIc←  ∇ ⍵:BIint
    Export←{ ('¯'/⍨¯1=⊃⍵),⎕D[dlzRun,⍉RX10BASE⊤|⊃⌽⍵] }

    ⍝ ExportApl:    Convert valid bigint ⍵ to APL, with error if exponent too large.
    ExportApl←{ 0:: Err eBADRANGE ⋄  ⍎Export Imp ⍵}
   
    :EndSection BigInt internal structure
⍝ --------------------------------------------------------------------------------------------------

     ⍝ DeclareInternalFn fn_name
     ⍝ Converts core numeric function named to lower-overhead version.
     ⍝ From routine "add", creates "_add" with conversion code 
     ⍝     (_Imp_ ⍵) and (⍺ _Imp_ ⍵)
     ⍝ removed. 
    ∇ {fnNmOut}←DeclareInternalFn fnNm
        ;fnInP;fnOutA;inP;outA
      fnInP fnOutA←('\b',fnNm,'\b')('_',fnNm)
      inP outA←(fnInP '_Imp_'  )(fnOutA ' ')
      fnNmOut←⎕FX inP ⎕R outA ⍠('UCP' 1)⊣⎕NR fnNm
      :IF 0=1↑0⍴fnNmOut 
          Err 'DeclareInternalFn: Error ⎕FXing variant of ',fnNm
      :ENDIF 
    ∇

    :Section BI Monadic Operations/Functions
    ⍝ 
    ⍝  BI Monadic Internal Functions            
    ⍝     neg                       
    ⍝     sig                       
    ⍝     abs                       
    ⍝     inc                       
    ⍝     dec                       
    ⍝     fact                      
    ⍝     roll                    
    ⍝     BitsExport 
    ⍝     root
    ⍝     GetBIAttribs
    ⍝     BitsImport (requires ⍵ boolean vector)

    ⍝ neg[ate] / _neg[ate]
      neg←{                                ⍝ -
          (sw w)← _Imp_  ⍵
          (-sw)w
      }
    ⍝ sig[num], _signum
      sig←{                                ⍝ ×
          (sw w)← _Imp_ ⍵
          sw(|sw)    ⍝ MINUSONE_BI, ZERO_BI, ONE_BI
      }
    ⍝ abs: absolute value
      abs←{                                ⍝ |
          (sw w)← _Imp_ ⍵
          (|sw)w
      }
    ⍝ inc[rement]:                         ⍝ ⍵+1
      inc←{
          (sw w)← _Imp_ ⍵
          sw=0: ONE_BI                     ⍝ ⍵=0? Return 1.
          sw=¯1:dlzNorm sw(⊃⌽_dec 1 w)     ⍝ ⍵<0? inc ⍵ becomes -(dec |⍵). dlzNorm handles 0.
          î←1+⊃⌽w                          ⍝ trial increment (most likely path)
          RX10>î:sw w⊣(⊃⌽w)←î              ⍝ No overflow? Increment and we're done!
          sw w _add ONE_BI                 ⍝ Otherwise, do long way.
      }
    ⍝ dec[rement]:                         ⍝ ⍵-1
      dec←{
          (sw w)← _Imp_ ⍵
          sw=0: MINUS1_BI                  ⍝ ⍵ is zero? Return ¯1
          sw=¯1:dlzNorm sw(⊃⌽_inc 1 w)     ⍝ ⍵<0? dec ⍵  becomes  -(inc |⍵). dlzNorm handles 0.
                                           ⍝ If the last digit of w>0, w-1 can't underflow.
          0≠⊃⌽w:dlzNorm sw w⊣(⊃⌽w)-←1      ⍝ No underflow?  Decrement and we're done!
          sw w _sub ONE_BI                 ⍝ Otherwise, do long way.
      }
    DeclareInternalFn¨'neg' 'sig' 'abs'  'inc' 'dec'

    ⍝ fact: compute BI factorials.
    ⍝       r:BIc←  fact ⍵:BIext
    ⍝ We allow ⍵ to be of any size, but numbers larger than NRX10 are impractical.
    ⍝ We deal with 3 cases:
    ⍝    ⍵ ≤ 31:    We let APL calculate, with ⎕PP←34.   Fast.
    ⍝    ⍵ ≤ NRX10:   We calculate r as a BigInt, while counting down ⍵ as an APL integer. Moderately fast.
    ⍝    Otherwise: We calculate entirely using BigInts for r and ⍵. Slowwwwww.
      fact←{                                ⍝ !⍵
          (sw w)← _Imp_ ⍵
          sw=0:ONE_BI                       ⍝ !0
          sw=¯1:Err eFACTOR                 ⍝ ⍵<0
          factBig←{⍺←1
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
    ⍝    r:BIint←  ∇ ⍵:BIint   ⍵>0.
    ⍝ With inL the # of dec digits in ⍵, excluding any leading '0' digits...
    ⍝ Proceed as shown here, where (Export ⍵) is "exported" BIext format; (Imp ⍵) is internal BIint format.
      roll←{
          (sw w)← _Imp_ ⍵
          sw≠1:Err eBADRAND
          ⎕PP←16 ⋄ ⎕FR←645                       ⍝ 16 digits per ?0 is optimal
          inL←≢Export sw w                          ⍝ ⍵: in Export form. in: ⍵ with leading 0's removed.
     
          res←inL⍴{                              ⍝ res is built up to ≥inL random digits...
              ⍺←''                               ⍝ ...
              ⍵≤≢⍺:⍺ ⋄ (⍺,2↓⍕?0)∇ ⍵-⎕PP          ⍝ ... ⎕PP digits at a time.
          }inL                                   ⍝ res is then truncated to exactly inL digits
          '0'=⊃res:Imp res                         ⍝ If leading 0, guaranteed (Imp res) < ⍵.
          ⍵ rem Imp res                            ⍝ Otherwise, compute rem r: 0 ≤ r < ⍵.
      }
  ⍝⍝  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  ⍝⍝  Bit Management Utilities
  ⍝⍝  ⊥    Bits→bi
  ⍝⍝  ⊤    bi→Bits,
  ⍝⍝  ~    reverses Bits of bi ⍵, i.e.   (⊥ ~ ⊤ ⍵)
  ⍝⍝  We allow
  ⍝⍝      1. Importing from a simple bit array ⍵ ravelled to: Bits←,⍵
  ⍝⍝          [sign] Bits
  ⍝⍝           sign: 1 for negative, 0 for positive.
  ⍝⍝           Bits: 1 or more Bits
  ⍝⍝         Returns a bigint in internal format, normalized as required.
  ⍝⍝         If <Bits> are not multiple of 20 (NRX2), the non-sign <Bits> are padded on the left with 0s (unsigned)
  ⍝⍝      2. Exporting from a signed bigint object to a vector:
  ⍝⍝          [sign] Bits
  ⍝⍝          sign, Bits: as above
  ⍝⍝  For bit array manipulation, perform entirely using APL's more powerful intrinsics, then convert to a bigint.
  ⍝⍝  ~ included in BI(I) calls for demonstration purposes.
  ⍝⍝
  ⍝⍝  Bugs: Except for the overall sign bit, the bigint data is handled as unsigned in every case,
  ⍝⍝        not in a  2s-complement representation.
  ⍝⍝        That is, ¯1 is stored as (sign bit: 1) plus (data: 0 0 0 ... 0 1), not as all 1s (as expected for 2s-complement).
  ⍝⍝            ¯1 can be represented as   1 1    OR    1 0 1    OR    1 0 0 0 ... 0 1, etc.
  ⍝⍝  See  ⊥BI ⍵ OR 'BITSIN' BI ⍵ and  ⊤BI ⍵ OR 'BITSOUT' BI ⍵
      BitsImport←{
        ⍝ Allow quoted args, as presented by BI_DC desk calculator
          ' '=1↑0⍴⍵:∇{ ~0∊⍵∊'01': ⍺⍺ '1'=⍵  ⋄ Err eBOOL }⍵~' ' 
          0∊⍵∊0 1:Err eBOOL
          bits←,⍵
          sgn←(⊃bits)⊃1 ¯1 ⋄ bits←1↓bits    ⍝ 1st bit is sign bit.
          nhands←⌈exact←NRX2÷⍨≢bits         ⍝ Process remaining bits into hands of <nbits> each
          bits←nhands NRX2⍴{
              nhands=exact:⍵
              (-nhands×NRX2)↑⍵              ⍝ Padding first hand on left with 0s (unsigned)
          }bits
          dlzNorm sgn(2⊥⍉bits)         ⍝ Convert to bigint:  (sign) (integer array)
      }
      BitsExport←{
          (sw w)← _Imp_ ⍵
          sw=0:0,NRX2⍴0
          (sw=¯1),,⍉NRX2BASE⊤w
      }

    ⍝ GetBIAttribs: Returns    #Hands   #Bits*   #1-bits*         *=(in bit representations)
    ⍝        ≢bits is also  1 + 20 × #hands
    GetBIAttribs←{hands←≢⊃⌽w←Imp ⍵ ⋄ bits←BitsExport w ⋄ hands (≢bits) (+/1=bits) }

    ⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

    ⍝ root: A fast integer nth root.
    ⍝ Syntax:    x@BIint←  nth@BIext<RX10 ∇ N@BIext
    ⍝            x←  nth root N  ==>   x←  ⌊N *÷nth
    ⍝   nth: a small, positive integer (<RX10); default 2 (for sqrt).
    ⍝   N:   any BIext
    ⍝   x:   the nth root as an internal big integer.
    ⍝   ∘ Uses Fredrick Johanssen's algorithm with optimization for APL integers.
    ⍝   ∘ Estimator based on guesstimate for sqrt N, no matter what root.
    ⍝     (Better than using N).
    ⍝   ∘ As fast for sqrt as a "custom" version.
    ⍝   ∘ If N is small, calculate directly via APL.
    ⍝ x:BIint←  nth:small_(BIint|BIext) ∇ N:(BIint|BIext)>0
      root←{
        ⍝ Check radix in  N*÷radix
        ⍝ We work with bigInts here for convenience. Could be done unsigned...
          ⍺←TWO_BI                ⍝ sqrt by default...  
          sgn rdx←⍺{              ⍝ Get the sign, (÷radix), radix based on ⍺.
              ⍵:TWO_BI            ⍝ No radix, so radix defaults to number 2.
              sgn rdx←Import ⍺    ⍝ Domain of rdx: Small pos. integer
              sgn=0:Err eROOT     ⍝ Not pos?
              1<≢rdx:Err eROOT    ⍝ Not small int?
              sgn rdx
          }900⌶⍬                  ⍝ Was BI called monadically?
          sgn<0:0                 ⍝  ⌊N*÷nth ≡ 0, if nth<0 (nth a small int)
        ⍝ Check N. Domain: non-negative integer
          sN N←Import ⍵                
          0=sN:sN N                    ⍝ 0: Root(0) <=> 0
          ¯1=sN:Err eROOT              ⍝ Negative: error
          rootU←*∘(÷rdx)
         ⍝ N small? Let APL calc value
          1=ndig←≢N:1(,⌊rootU N)      
        ⍝ Initial estimate for N*÷nth must be ≥ the actual solution, else this will terminate prematurely.
        ⍝ Initial estimate (x):
        ⍝   DECIMAL est: ¯1+10*⌈num_dec_digits(N)÷2       <== We use this one.
        ⍝   BINARY  est:  2*⌈numbits(N)÷2
          x←{ ⍝ We use DECIMAL est(sqrt N) as initial estimate for ANY root. Not ideal, but safe.
              0::1((⌈rootU⊃⍵),(RX10-1)⍴⍨⌈0.5×ndig-1) ⍝ Too big for APL est. Use DECIMAL est. above.
              ⎕FR←1287
              ⊃⌽Import 1+⌈rootU⍎Export 1 ⍵     ⍝ Est via APL: works for ⍵ ≤ ⌊/⍬  (⍵≤1E6145) given ⎕FR=1287
          }N
        ⍝ Given unsigned x, y, N, rdx, refine x (aka ⍵), until y ≥ x, then return pos root (1 (,x)).
          {x←⍵
              y←(x addU N quotientU x)quotientU rdx    ⍝ y is next guess: y←⌊((x+⌊(N÷x))÷nth)
              ≥cmp y mix x:1(,x)                       ⍝ y ≥ x? Return x
              ∇ y                                      ⍝ y is smaller than ⍵. Set x←y and try another.
          }x
      }
    sqrt←root
 
  ⍝ recip:  ÷⍵← → 1÷⍵ Almost useless, since ÷⍵ is 0 unless ⍵ is 1 or ¯1.
    recip←{{0=≢⍵: ÷0 ⋄ 1≠≢⍵:0 ⋄ 1=|⍵:⍵ ⋄ 0}dlzRun ⍵}

    :Endsection BI Monadic Functions/Operations
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Dyadic Functions/Operations
    ⍝     Does Arg Conversions   Requires BI-Internal Args   Details
    ⍝     For general use          For INTERNAL use and library routine development 
    ⍝        slower                     faster         
    ⍝          add                       _add
    ⍝          sub                       _sub
    ⍝          mul                       _mul
    ⍝          div                       _div
    ⍝          divRem                    _divRem
    ⍝          pow                       _pow
    ⍝          rem                       _rem                 ⍺ rem ⍵  ==  ⍺ | ⍵  (APL style)
    ⍝          mod                       _mod                 ⍺ mod ⍵  ==  ⍵ | ⍺  (CS style)
    ⍝          mul2Exp, shiftB           _mul2Exp             Shift ⍺ left or right by ⍵ binary digits (SLOW)
    ⍝          mul10Exp, shiftD          _mul10Exp            Shift ⍺ left or right by ⍵ decimal digits (FAST)
    ⍝          gcd                                            Greatest common divisor
    ⍝          lcm                                            Lowest common multiple
    ⍝ 
    ⍝  BI Boolean Functions (return 1 or 0)
    ⍝          lt <, le ≤, eq =, ge ≥, gt >, ne ≠

  ⍝ dyad:    compute all supported dyadic functions
      add←{
          (sa a)(sw w)← ⍺ _Imp_ ⍵
          sa=0:sw w                           ⍝ optim: ⍺+0 → ⍺
          sw=0:sa a                           ⍝ optim: 0+⍵ → ⍵
          sa=sw:sa(ndnZ 0,+⌿a mix w)          ⍝ 5 + 10 or ¯5 + ¯10
          sa<0:sw w _sub 1 a                  ⍝ Use unsigned vals: ¯10 +   5 → 5 - 10
          sa a _sub 1 w                       ⍝ Use unsigned vals:   5 + ¯10 → 5 - 10
      }
      sub←{
          (sa a)(sw w)← ⍺ _Imp_ ⍵
          sw=0:sa a                            ⍝ optim: ⍺-0 → ⍺
          sa=0:(-sw)w                          ⍝ optim: 0-⍵ → -⍵
          sa≠sw:sa(ndnZ 0,+⌿a mix w)           ⍝ 5-¯3 → 5+3 ; ¯5-3 → -(5+3)
          <cmp a mix w:(-sw)(nupZ-⌿dck w mix a)  ⍝ 3-5 →  -(5-3)
          sa(nupZ-⌿dck a mix w)                ⍝ a≥w: 5-3 → +(5-3)
      }
      mul←{
          (sa a)(sw w)← ⍺ _Imp_ ⍵
          0∊sa,sw:ZERO_BI
          TWO_D≡a:(sa×sw)(addU⍨w) ⋄ TWO_D≡w:(sa×sw)(addU⍨a)
          ONE_D≡a:(sa×sw)w ⋄ ONE_D≡w:(sa×sw)a
        ⍝ Performs more slowly:
        ⍝    TEN_D≡a: (sa×sw) w mul10Exp ONE_BI ⋄  TEN_D≡w: (sa×sw) a mul10Exp ONE_BI
          (sa×sw)(a mulU w)
      }
    ⍝ div: 
    ⍝ For special cases (except ⍺÷10), see divU.
      div←{ 
          (sa a)(sw w)← ⍺ _Imp_ ⍵
          TEN_D≡w:  (sa×sw)a mul10Exp MINUS1_BI       ⍝ This can be hundreds of times faster than using divU.
          normFromSign(sa×sw)(⊃a divU w)
      }
    ⍝ Since divU returns both quotient and remainder, calling divRem is preferred  over div and mod calls if you need both
    ⍝    (⍺ div ⍵)  and (⍺ mod ⍵)
    ⍝ For special cases, see divU.
      divRem←{
          (sa a)(sw w)← ⍺ _Imp_ ⍵
          quot rem←a divU w
          (normFromSign(sa×sw)quot)(normFromSign sw rem)
      }
    DeclareInternalFn¨'add' 'sub' 'mul'  'div' 'divRem'

    ⍝ ⍺ pow ⍵:
    ⍝   General case:  ⍺*⍵ where both are BIint
    ⍝   Special case:  (÷⍵) (or ÷⍎⍵) is an integer: (÷⍵) root ⍺. Example:  ⍺*BI 0.5 is sqrt; ⍺*BI (÷3) is cube root; etc.
    ⍝                  (÷⍵) must be an integer to the limit of the current ⎕CT.
    ⍝ decodeRoot (pow utility): Allow special syntax ( ⍺ *BI ÷⍵ ) in place of  ( ⍵ root ⍺ ).
    ⍝       ⍵ must be an integer such that 0<⍵<1 or a string representation of such an integer.
    ⍝       For 3 root 27, use:
    ⍝             I.e. '27' *BI ÷3    '27' *BI '÷3'
    ⍝       The root is truncated to an integer.
      decodeRoot←{              
          0::0 ⋄ 0>≡⍵:0                ⍝ BI format? Can't be a root. Skip (return 0)!      
        ⍝ See if ⍵ a root spec...      ⍝ if not, skip!                  
          recip←{1≤⍵:0 ⋄ ⌊÷⍵} 
          0=1↑0⍴⍵: recip           ⍵   ⍝ ⍵ numeric?       Return ÷⍵ if fractional.**
          '÷'=1↑⍵: ⌊     ⊃⊃⌽⎕VFI 1↓⍵   ⍝ ⍵ of form '÷2'?  Return numeric 2.
                   recip ⊃⊃⌽⎕VFI   ⍵   ⍝ ⍵ of form '0.5'? Return numeric 2 (÷0.5) if fractional. **
      }                                ⍝ ** = Else skip (return 0).
      pow←{
          0≠rt←decodeRoot ⍵:rt root ⍺
        ⍝ Not a root, so decode as usual
        ⍝ Special cases ⍺*2, ⍺*1, ⍺*0 handled in powU.
          (sa a)(sw w)← ⍺ _Imp_ ⍵
          sa sw∨.=0 ¯1:ZERO_BI     ⍝ r←⍺*¯⍵ is 0≤r<1, so truncates to 0.
          p←a powU w
          sa≠¯1:1 p                ⍝ sa= 1 (can't be 0).
          0=2|⊃⌽w:1 p ⋄ ¯1 p       ⍝ ⍺ is neg, so result is pos. if ⍵ is even.
      }
      rem←{                        ⍝ remainder/residue. APL'S DEF: ⍺=base.
          (sa a)(sw w)← ⍺ _Imp_ ⍵
          sw=0:ZERO_BI
          sa=0:sw w
          r←,a remU w              ⍝ remU is fast if a>w
          sa=sw:dlzNorm sa r       ⍝ sa=sw: return (R)        R←sa r
          ZERO_D≡r:ZERO_BI         ⍝ sa≠sw ∧ R≡0, return 0
          dlzNorm sa a _sub sa r   ⍝ sa≠sw: return (A - R')   A←sa a; R'←sa r
      }
    res←rem                        ⍝ residue (APL name)
    DeclareInternalFn¨ 'pow' 'rem'
    mod←rem⍨  ⋄  _mod←_rem⍨        ⍝ ⍺ mod ⍵  <== ⍵ rem ⍺

    ⍝ mul2Exp:  Shift ⍺:BIext left or right by ⍵:Int binary digits
    ⍝  r:BIint←  ⍺:BIint   ∇  ⍵:aplInt
    ⍝     Note: ⍵ must be an APL integer (<RX10).
    ⍝  -  If ⍵>0: shift ⍺ left by ⍵ binary digits
    ⍝  -  If ⍵<0: shift ⍺ rght by ⍵ binary digits
    ⍝  -  If ⍵=0: then ⍺ will be unchanged
    ⍝ Very slow!
      mul2Exp←{
          (sa a)(sw w)← ⍺ _Imp_ ⍵
          1≠≢w:Err eMUL10                         ⍝ ⍵ must be small integer.
          sa=0:0 ZERO_D                           ⍝ ⍺ is zero: return 0.
          sw=0:sa a                               ⍝ ⍵ is zero: ⍺ stays as is.
          pow2←2*w
          sw>0:sa a mul pow2
          sa a div pow2
      }
      div2Exp←{
          ⍺ mul2Exp negate ⍵
      }
    shiftBinary←mul2Exp
    shiftB←mul2Exp

    ⍝ mul10Exp: Shift ⍺:BIext left or right by ⍵:Int decimal digits.
    ⍝      Converts ⍺ to BIc, since shifts are a matter of appending '0' or removing char digits from right.
    ⍝  r:BIint←  ⍺:BIint   ∇  ⍵:Int
    ⍝     Note: ⍵ must be an APL  big integer, BigIntA (<RX10).
    ⍝  -  If ⍵>0: shift ⍺ left by ⍵-decimal digits
    ⍝  -  If ⍵<0: shift ⍺ rght by ⍵ decimal digits
    ⍝  -  If ⍵=0: then ⍺ will be unchanged
    ⍝  WARNING: THIS APPEARS TO RUN ABOUT 80% SLOWER THAN A SIMPLE MULTIPLY FOR MEDIUM AND LONG ⍺, unless ⍵ is long, e.g. 1000 digits.
    ⍝           It is however much faster for ⍺ div  10 or ⍺ divRem 10, which use  ⍺ mul10Exp ¯1
      mul10Exp←{
          (sa a)(sw w)← ⍺ _Imp_ ⍵
          1≠≢w:Err eMUL10                          ⍝ ⍵ must be small integer.
          sa=0:ZERO_BI                             ⍝ ⍺ is zero: return 0.
          sw=0:sa a                                ⍝ ⍵ is zero: sa a returned.
          ustr←Export 1 a                          ⍝ ⍺ as unsigned string.
          ss←'¯'/⍨sa=¯1                            ⍝ sign as string
          sw=1:Imp ss,ustr,w⍴'0'                   ⍝ sw= 1? shift left by appending zeroes.
          ustr↓⍨←-w                                ⍝ sw=¯1? shift right by dec truncation
          0=≢ustr:ZERO_BI                          ⍝ No chars left? It's a zero
          Imp ss,ustr                              ⍝ Return in internal form...
      }
    shiftDecimal←mul10Exp                          ⍝ positive/left
    shiftD←mul10Exp
    DeclareInternalFn¨ 'mul10Exp' 'shiftD' 'mul2Exp'  'shiftB'

    ⍝ ∨ Greatest Common Divisor
      gcd←{
          (sa a)(sw w)← ⍺ _Imp_ ⍵
          1(a gcdU w)
      }
    ⍝ ∧ Lowest Common Multiple
      lcm←{
          (sa a)(sw w)← ⍺ _Imp_ ⍵
          (sa×sw)(a lcmU w)
      }
    DeclareInternalFn¨ 'gcd' 'lcm'

    ⍝ DeclareBoolFn-- generate Boolean functions lt <, le ≤, eq =, ge ≥, gt >, ne ≠
    ∇ {r}←DeclareBoolFn(BOOL_NAME BOOL_SYMBOL);_FN_;in;out
      _FN_←{
        ⍝ ⍺ _FN_ ⍵: emulates (⍺ _BOOL_ ⍵)
        ⍝ ⍺, ⍵: BigIntegers
          (sa a)(sw w)← ⍺ _Imp_ ⍵
          0∊sa sw:sa _BOOL_ sw        ⍝ ⍺, ⍵, or both are 0
          sa≠sw:sa _BOOL_ sw          ⍝ ⍺, ⍵ different signs
          sa=¯1:_BOOL_ cmp w mix a    ⍝ ⍺, ⍵ both neg
          _BOOL_ cmp a mix w          ⍝ ⍺, ⍵ both pos
      }
      in←'_FN_' '_BOOL_' ⋄ out←BOOL_NAME BOOL_SYMBOL
      :If ' '≠1↑0⍴r←⎕THIS.⎕FX in ⎕R out⊣⎕NR'_FN_'
          ∘∘∘⊣⎕←'⎕FIX-time LOGIC ERROR: unable to create boolean function: ',BOOL_NAME,' (',BOOL_SYMBOL,')'
      :EndIf
    ∇
    DeclareBoolFn¨ ('lt' '<')('le' '≤')('eq' '=')('ge' '≥')('gt' '>')('ne' '≠')
    DeclareInternalFn¨ 'lt' 'le'  'eq' 'ge' 'gt' 'ne'
    ⎕EX 'DeclareBoolFn'

  ⍝ log:  L←  B log N
  ⍝  integer logarithm base <B> of big integer <N>. B defaults to (base) 10.
  ⍝ Returns <L> in BigIntI format.
    log2_10←(2⍟10)
      log←{
        log10←{¯1+≢Export ⍵}
        log2←{⌊log2_10×log10 ⍵}      ⍝ Verify.  FIX ME!!!
        ⍺←TEN_BI ⋄ B N←⍺ Imp ⍵
      ⍝ Hidden way to calculate  2 log N the slow mathematical way. VERY SLOW!
        MINUS1_BI≡B:ZERO_BI{⍵ le ONE_BI:⍺ ⋄ (inc ⍺)∇ ⍵ _div B}N⊣B←TWO_BI
        0≥⊃N:Err eLOG        ⍝ N ≤ 0
        TEN_BI≡B:Imp log10 N
        TWO_BI≡B:Imp log2 N    ⍝ Magical, but sometimes off by a digit (???)
        ZERO_BI{⍵ _le ONE_BI:⍺ ⋄ (_inc ⍺)∇ ⍵ _div B}N   ⍝  0 {⍵ ≤ 1: ⍺  ⋄ (>⍺) ∇ ⍵ ÷ B} ⍵}
      }

    :EndSection BI Dyadic Operators/Functions

    :Section BI Special Functions/Operations (More than 2 Args)
    ⍝ modMul:  modulo m of product a×b
    ⍝ A faster method than (m|a×b), when a, b are large and m is substantially smaller.
    ⍝ r←  a (m modMul) b   →→→    r←  m | a × b
    ⍝ BIint←  ⍺:BIint ∇ ⍵:BIint m:BIint
    ⍝ Naive method: (m|a×b)
    ⍝      If a,b have 1000 digits each and m is smaller, the m| operates on 2000 digits.
    ⍝ Better method: (m | (m|a)×(m|b)).
    ⍝      Here, the multiply is on len(m) digits, and the final m operates on 2×len(m).
    ⍝ For large a b of length 5000 dec digits or more, this alg can be 2ce the speed (13 sec vs 26).
    ⍝ It is nominally faster at lengths around 75 digits.
    ⍝ Only for smaller a and b, the cost of 3 modulos instead of 1 predominates.
      modMul←{
          (a b)m←(⍺ Imp ⍵)(Imp ⍺⍺)
          m _rem(m _rem a)_mul(m _rem b)
      }
    ⍝ modPow -- a (m modPow) n -- from article by Roger Hui Aug 2020  
    ∇ z←a(m modPow)n;s;mmM
      ⍝ m|a*n  ==>   a (m modPow) n  
      (a n)m←(a Imp n)(Imp m)
      z←ONE_BI ⋄ s←m rem a
      mmM←m modMul 
      :While ZERO_BI lt n
          :If 1 eq 2 rem n ⋄ z←z mmM s ⋄ :EndIf    ⍝ z←m| z×s
          s←s mmM s                                ⍝ s←m| s×s
          n←n div 2
      :EndWhile
    ∇
    :EndSection BI Special Functions/Operations (More than 2 Args)
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Unsigned Utility Math Routines
    ⍝ These are the workhorses of bigInt; most are from dfns:nats (handling unsigned bigInts).
    ⍝ Note: ⍺ and ⍵ are guaranteed by BII and BI to be vectors, but not
    ⍝       by internal functions or if called directly.
    ⍝       So tests for 2, 1, 0 (TWO_D etc) use ravel:  (TWO_D≡,⍺)

    ⍝ addU:   ⍺ + ⍵
      addU←{
          dlzRun ndn 0,+⌿⍺ mix ⍵    ⍝ We use dlzRun in case ⍺ or ⍵ have multiple leading 0s. If not, use ndnZ
      }
    ⍝ subU:  ⍺ - ⍵   Since unsigned, if ⍵>⍺, there are two options:
    ⍝        [1] Render as 0
    ⍝        [2] signal an error...
      subU←{
          <cmp ⍺ mix ⍵:Err eSUB                   ⍝ [opt 2] 3-5 →  -(5-3)
          dlzRun nup-⌿dck ⍺ mix ⍵                 ⍝ a≥w: 5-3 → +(5-3). ⍺<⍵: 0 [opt 1]
      }
    ⍝ mulU:  multiply ⍺ × ⍵  for unsigned Big Integer (BigIntU) ⍺ and ⍵
    ⍝ r:BIint←  ⍺:BIint ∇ ⍵:BIint
    ⍝ This is dfns:nats mul.
    ⍝ It is faster than dfns:xtimes (FFT-based algorithm)
    ⍝ even for larger numbers (up to xtimes smallish design limit)
    ⍝ We call ndnZ to remove extra zeros, esp. so zero is exactly ,0 and 1 is ,1.
      mulU←{
          dlzRun ⍺{                               ⍝ product.
              ndnZ 0,↑⍵{                          ⍝ canonicalised vector.
                  digit take←⍺                    ⍝ next digit and shift.
                  +⌿⍵ mix digit×take↑⍺⍺           ⍝ accumulated product.
              }/(⍺,¨(≢⍵)+⌽⍳≢⍺),⊂,0                ⍝ digit-shift pairs.
          }{                                      ⍝ guard against overflow:
              m n←,↑≢¨⍺ ⍵                         ⍝ numbers of hands (RX10-digits) in each arg.
              m>n:⍺ ∇⍨⍵                           ⍝ quicker if larger number on right.
              n<OFL:⍺ ⍺⍺ ⍵                        ⍝ ⍵ won't overflow: proceed.
              s←⌊n÷2                              ⍝ digit-split for large ⍵.
              p q←⍺∘∇¨(s↑⍵)(s↓⍵)                  ⍝ sub-products (see notes).
              ndnZ 0,+⌿(p,s↓n⍴0)mix q             ⍝ sum of sub-products.
          }⍵
      }
   ⍝ powU: compute ⍺*⍵ for unsigned ⍺ and ⍵. (⍺ may not be omitted).
   ⍝       Note: ⍺ and ⍵ must be vectors!!!
   ⍝ RX10div2: (Defined above.)
      powU←{CASE←(,⍵)∘≡
        ⍝ (1≠⍴⍴⍵)∨1≠⍴⍴⍺:  Err 'powU: ⍺ and ⍵ must be vectors'
          CASE ZERO_D: ONE_D                       ⍝ =cmp ⍵ mix,0:,1 ⍝ ⍺*0 → 1
          CASE ONE_D:  ,⍺                          ⍝ =cmp ⍵ mix,1:⍺  ⍝ ⍺*1 → ⍺. Return "odd," i.e. use sa in caller.
          CASE TWO_D:  ⍺ mulU ⍺                    ⍝ ⍺×⍺
          hlf←{,ndn(⌊⍵÷2)+0,¯1↓RX10div2×2|⍵}       ⍝ quick ⌊⍵÷2.
          evn←ndnZ{⍵ mulU ⍵}ndn ⍺ ∇ hlf ⍵          ⍝ even power
          0=2|¯1↑⍵:evn ⋄ ndnZ ⍺ mulU evn           ⍝ even or odd power.
      }
   ⍝ divU/: unsigned division
   ⍝  divU:   Removes leading 0s from ⍺, ⍵ ...
   ⍝    Optimizations for ⍵÷⍵ handled here, as well as ⍵÷0, where ⍵≠0.
   ⍝ Returns:  (int. quotient) (remainder)
   ⍝           (⌊ua ÷ uw)      (ua | uw)
   ⍝   r:BIint[2]←  ⍺:BIint ∇ ⍵:BIint
      divU←{
          a w←dlzRun¨⍺ ⍵
          a≡w:  ONE_D ZERO_D                  ⍝ ⍺÷⍵ => (,1)(,0), including 0÷0.
          ZERO_D≡w: 1÷0                       ⍝ ⍺÷⍵ => ERROR!, for all other ⍺÷0.
          svec←(≢w)+⍳0⌈1+(≢a)-≢w              ⍝ shift vector.
          dlzRun¨↑w{                          ⍝ fold along dividend.
              r p←⍵                           ⍝ result & dividend.
              q←⍺↑⍺⍺                          ⍝ shifted divisor.
              ppqq←RX10⊥⍉2 2↑p mix q          ⍝ 2 most signif. digits of p & q.
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
          }/svec,⊂⍬ a                         ⍝ fold-accumulated result.
      }
    quotientU←⊃divU
    gcdU←{ZERO_D≡,⍵:⍺ ⋄ ⍵ ∇⊃⌽⍺ divU ⍵}        ⍝ greatest common divisor.
    lcmU←{⍺ mulU⊃⍵ divU ⍺ gcdU ⍵}             ⍝ least common multiple.
    remU←{                                    ⍝ remU: ⍺, ⍵ unsigned; calcs and returns unsigned ⍺|⍵.
          TWO_D≡,⍺:2|⊃⌽⍵                      ⍝ fast (short-circuit) path for ⍺=2 (2|⍵). Check only last "hand".
          <cmp ⍵ mix ⍺:⍵                      ⍝ ⍵ < ⍺? remainder is ⍵
          ⊃⌽⍵ divU ⍺                          ⍝ Otherwise, do full divide and return 2nd element, the remainder.
    }
    :Endsection BI Unsigned Utility Math Routines
⍝ --------------------------------------------------------------------------------------------------

    :Section Service Functions
    ⍝ Prettify: Add underscores every 5 digits; ⍺=0 (default): replace ¯ by - .
      Prettify←  { ⍺←0 ⋄ 0:: ⍵ ⋄ n← '(\d)(?=(\d{5})+$)' ⎕R '\1_'⊣⍵  ⋄  ⍺=1: n ⋄ '-'@('¯'∘=) n} 
    ⍝-----------------------------------------------------------------------------------+
    ⍝ Note: These Service Functions are                                                 +
    ⍝       ∘ directly from (or tweaks of) dfns::nats,                                  +
    ⍝       ∘ in lower camel case.                                                      +
    ⍝-----------------------------------------------------------------------------------+
    ⍝ dlzNorm ⍵:BIint  If ⊃⌽⍵ is zero after removing leading 0's,
    ⍝                  return canonical BigInt ZERO_BI: (0 (,0)).
    ⍝                  Otherwise return ⍵ w/o leading zeroes.
    ⍝ normFromSign ⍵:BIint  If ⊃⌽⍵ is zero, ensure sign is 0. Otherwise, pass ⍵ as is.
      dlzNorm←{ZERO_D≡w←dlzRun⊃⌽⍵: ZERO_BI ⋄ (⊃⍵) w}
      normFromSign←{ZERO_D≡⊃⌽⍵:ZERO_BI ⋄ ⍵}
    ⍝ These routines operate on unsigned BIu data unless documented…  
      dLZ←{⍵↓⍨0=⊃⍵}                           ⍝ drop FIRST leading zero.
      dlzRun←{chkZ ⍵↓⍨+/∧\⍵=0}                ⍝ drop RUN of leading zeros, but [PMS] make sure at least one 0
      chkZ←{0≠≢⍵:,⍵ ⋄ ,0}                     ⍝ ⍬ → ,0. Ensure canonical Bii, so even 0 has one digit (,0).
      ndn←{ +⌿1 0⌽0 RX10⊤⍵}⍣≡                 ⍝ normalise down: 3 21 → 5 1 (RH).
      ndnZ←dLZ ndn                            ⍝ ndn, then remove (earlier added) leading zero, if still 0.
      nup←{⍵++⌿0 1⌽RX10 ¯1∘.×⍵<0}⍣≡           ⍝ normalise up:   3 ¯1 → 2 9
      nupZ←dLZ nup                            ⍝ PMS
      mix←{↑(-(≢⍺)⌈≢⍵)↑¨⍺ ⍵}                  ⍝ right-aligned mix.
      dck←{(2 1+(≥cmp ⍵)⌽0 ¯1)⌿⍵}             ⍝ difference check.
      rep←{10⊥⍵{⍉⍵⍴(-×/⍵)↑⍺}(⌈(≢⍵)÷NRX10),NRX10}  ⍝ radix RX10 rep of number.
      cmp←{⍺⍺/,(<\≠⌿⍵)/⍵}                     ⍝ compare first different digit of ⍺ and ⍵.
    :Endsection Service Functions
⍝ --------------------------------------------------------------------------------------------------
    :Endsection Big Integers

    :Section Utilities: BI_LIB, BI_DC (desk calc), BIB, BIC
   ⍝ BI_LIB      - simple niladic fn, returns this bigint namespace #.BigInt
   ⍝           If ⎕PATH points to bigInt namespace, BI_LIB will be found without typing explicit path.
   ⍝ BI_DC   - desk calculator (self-documenting)
   ⍝ BIC     - Utility to compile code strings or functions with BI arithmetic

   ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
   ⍝ Utilities…

  ⍝ BI_LIB:  Returns ⎕THIS namespace
    ⎕FX 'ns←BI_LIB' 'ns←⎕THIS'    ⍝ Appears in ⎕PATH, for use by user utilities...

  ⍝ ∆F-- ⎕R/⎕S Regex utility-- returns field #n or ''
  ⍝ Returns Regex field ⍵N in ⎕R ⍵⍵ dfn. Format:  f2 f3←⍵ ∆F¨2 3
    ∆F←{ ⍵=0:⍺.Match ⋄ ⍵≥≢⍺.Offsets:'' ⋄ ¯1=⍺.Offsets[⍵]:'' ⋄ ⍺.(Lengths[⍵]↑Offsets[⍵]↓Block) }
  ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
    ∇ {r}←BIC_LoadPats (fns_monad fns_dyad)
      ;actBiCallNoQ;actBiCallQ;actKeep;actKeepParen;actQuoted;lD;lM;p2Fancy;p2Funs1;p2Funs2
      ;p2Ints;p2Plain;p2Vars;pAplInt;pCom;pFancy;pFunsNoQ;pFunsQ;pIntExp
      ;pIntOnly;pLongInt;pNonBiCode;pQot;pVar;tP1;tP2;tD1;tDM;tM1;tMM;_Q;_E
    ⍝ fnRep pattern: Match 0 or more lines
    ⍝ between :BIX… :EndBI keywords or  ⍝:BI … ⍝:ENDBI keywords
    ⍝ Match   ⍝:BI \n <BI code> … ⍝:EndBI. No spaces between ⍝ and :BI (bad: ⍝ :BI).
    ⍝ \R: any linend.  \N: any char but linend
      FnRepPat←'(?ix)   ^ \h* ⍝?:BI \b \R* $ (.*?)  \R \h* ⍝?:ENDBI \b \R* '
    ⍝ Field:    #1                              #2    #3
    ⍝ #1: :BII; #2: text in :BII scope;  #3: text :ENDBI
    ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
    ⍝ EXTERN: FnRepAction.   
      FnRepAction←{match←⍵ ∆F 1 ⋄ BI_CALLS_pat ⎕R BI_CALLS_action⊣match}
    ⍝ EXTERN: FnRepOpts.  FnRep options for ⎕R.
      FnRepOpts←('Mode' 'M')('EOL' 'LF')('NEOL' 1)('IC' 1)('UCP' 1)('DotAll' 1)
    ⍝ EXTERN: FnRep. Expects string vector(s) as from ⎕NR name
      FnRep←{FnRepPat ⎕R FnRepAction⍠FnRepOpts⊣⍵}
    ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
    ⍝ BI (Big Integer) patterns
      ⍝ …p2: Pattern building blocks
        p2Vars←'\p{L}_∆⍙'
      ⍝ decode list…Fns.
      ⍝ [0] are single char fns   '+-⌽?'      → [+\-⌽\?]
      ⍝ [1] are multiple char fns 'aaa' 'bbb' → ('aaa' | 'bbb') etc.
        tM1 tMM← fns_monad                       ⍝ tM1: Monadic 1-char, tMM: Monadic multi-char
        tD1 tDM← fns_dyad                        ⍝ tD1: Dyadic 1-char, tDM: Dyadic multi-char
        tP1←{'[\-\?\*]'⎕R'\\\0'⊣∪⍵}tD1,tM1       ⍝ Escape expected length-1 special symbols
        _Q _E←⊂¨'\Q' '\E'
        tP2←¯1↓∊(_Q,¨_E,⍨¨tDM,tMM),¨'|'
        p2Funs1←'(?:⍺⍺|⍵⍵)'                      ⍝ See pFunsNoQ
        p2Funs2←'(?:',tP2,')|(?:[',tP1,'])'      ⍝ See pFunsQ. MUL10, SQRT -- upper-case only (CASE R).
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
      ⍝ BIC Actions
        actBiCallNoQ←'(\1',(⍕⎕THIS),'.BI)'       ⍝ See pFunsNoQ above
        actBiCallQ←'(''\1''',(⍕⎕THIS),'.BI)'     ⍝ See pFunsQ above
        actKeep actKeepParen actQuoted actBool←'\1' '(\1)' '''\1''' '⊥BI \1'
    ⍝ EXTERN: BI_CALLS_pat 
      BI_CALLS_pat←pCom pFunsQ pVar pQot pFunsNoQ pNonBiCode pIntExp pIntOnly
    ⍝ EXTERN: BI_CALLS_action 
    ⍝   Quote all APL integers unless they have exponents...
      BI_CALLS_action←actKeep actBiCallQ actKeep actKeep actBiCallNoQ actKeepParen actKeepParen actKeep
    ⍝ EXTERN MatchBiCalls: BI (Big Integer) matching calls…
      MatchBiCalls←{⍺←1
          res←⊃⍣(1=≢res)⊣res←BI_CALLS_pat ⎕R BI_CALLS_action⍠('UCP' 1)⊣⊆⍵
          ⍺=1:res
          prefix←'\Q',(⍕⎕THIS),'.\E'     ⍝ Prefix to the BI left operand (note trailing dot).
          prefix ⎕R' '⊣res               ⍝ ⍺=0? Remove the prefix
      }
      r←1
    ∇
    BIC_LoadPats FNS_MONADIC FNS_DYADIC


   ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
   ⍝ 
   ⍝  BIC: Compile a function ⍵ with BI directives...
   ⍝   opt=⍺ BIC command=⍵
   ⍝ 
   ⍝   opt DEFAULT  DESCRIPTION
   ⍝   ¯¯¯
   ⍝   0   YES      Compile and execute string ⍵ in CALLER space. Returns the value of execution
   ⍝   1            Compile string ⍵ and return compiled string with BI utility fn names fully specified. Returns the string.
   ⍝  ¯1            Compile string ⍵ and return compiled string w/o BI namespace prefixes (for ease of viewing). Returns the string.
   ⍝   2            Compile and ⎕FX function whose ⎕NR (code) is ⍵, containing :BI and :ENDBI statements as above. Returns result of ⎕FX
   ⍝                To replace a fn <myfn>  in place with its BI counterpart:    2 BIC 'myfn'
   ⍝   Examples:
   ⍝          !50
   ⍝  3.04140932E64
   ⍝          BIC '!50'    ⍝ Same as: 0 BIC '!50'
   ⍝  30414093201713378043612608166064768844377641568960512000000000000
   ⍝         1 BIC '!50'   ⍝ To execute, do: ⍎1 BIC '!50' . Equiv to 0 BIC '!50'
   ⍝  ('!'⎕SE.⍙⍙.⍙.BigInt.BI)50
   ⍝         2 BIC 'r←BigFact big'  ':bi'  'r←!big'  ':endbi'
   ⍝  BigFact
   ⍝         ⎕CR 'BigFact'     
   ⍝   ∇ r←BigFact big                                       
   ⍝     r←('!'⎕SE.⍙⍙.⍙.BigInt.BI)big
   ⍝   ∇
      BIC←{
          ⍺←0
          FixBiFn←{
              fx←((1+⎕IO)⊃⎕RSI,#).⎕FX FnRep ⍵
              0≠1↑0⍴fx:fx ⋄ 11 ⎕SIGNAL⍨'BIC: Unable to ⎕FX lines into fn'
          }
          DEBUG↓0::⎕SIGNAL/⎕DMX.(('bigInt: ',EM)EN)
          ⍺=0:((0+⎕IO)⊃⎕RSI,#)⍎MatchBiCalls ⍵        ⍝  1      Compile and execute string ⍵ in CALLER space, returning value of execution
          ⍺=1:    MatchBiCalls ⍵                     ⍝  0      Compile string ⍵ and return compiled string
          ⍺=¯1: 0 MatchBiCalls ⍵                     ⍝ ¯1      Compile string ⍵ and return compiled string w/o BI namespace prefixes
          ⍺=2:    FixBiFn ⍵                          ⍝ ¯2      Compile lines of function whose ⎕NR is ⍵, fixing (⎕FX) ⍵, and returning ⎕FX result
          Err eBIC
      }

    ∇ {ok}←BI_DC
      ;caller;code;lastResult;exprIn;exec;isShy;HelpInfo;help1Cmd;help2Cmd;offon;pretty;prettyCmd;verbose;verboseCmd
      ;⎕PW
      ⎕PW←132
    ⍝ extern:  BigInt.dc_HELP (help information)
      verbose pretty offon lastResult←0 1('OFF' 'ON')'0'
      help1Cmd help2Cmd verboseCmd prettyCmd←,¨'?' '??' '!' '⍕'
     
      HelpInfo←{
          ⎕←'BI_DC:       Big integer desk calculator.'
          ⎕←'In any expression you type:'
          ⎕←'             ⍵     refers to the most recently calculated value (or 0 initially)'
          ⎕←'At the prompt only (followed by return ⏎):'
          ⎕←'             !     toggles VERBOSE mode; currently VERBOSE mode is ','.',⍨verbose⊃offon
          ⎕←'             ⍕     toggles PRETTY  mode; currently PRETTY  mode is ','.',⍨pretty⊃offon
          ⎕←'Need help?'
          ⎕←'             ?     shows this basic HELP information.'
          ⎕←'             ??    shows more detailed HELP information.'
          ⎕←'Finished?'
          ⎕←'             ⏎     entering a completely empty line (just a return char ⏎) terminates BI_DC mode'
          ⎕←'                   a non-empty line (with only blanks) is ignored.'
      }
      HelpInfo ⍬
      :While ok←1
          :Trap 1000
              exprIn←⍞↓⍨≢⍞←'> '
              :If 0=≢exprIn 
                  :Return                                                    ⍝ Empty line:  Done
              :Else
                  :Select exprIn~' '
                    :Case '' 
                        ⍝ Blank line: ignore
                    :Case help1Cmd 
                        HelpInfo ⍬
                    :Case help2Cmd 
                        BI_HELP
                    :Case verboseCmd 
                        verbose←~verbose ⋄ ⎕←'>>> VERBOSE ',verbose⊃offon
                    :Case prettyCmd 
                        pretty←~pretty ⋄ ⎕←'>>> PRETTY ',pretty⊃offon
                    :Else 
                        BI_DC_CODE                                         
                  :EndSelect
              :EndIf
              :Continue
          :Else 
              :If ~1∊'nN'∊⍞↓⍨≢⍞←'Interrupted. Exit? Y/N [Yes] '
                  :Return
              :EndIf
          :EndTrap
      :EndWhile
    ∇
    ∇ BI_DC_CODE
    ⍝ Used in BI_DC
     :Trap 0
          caller←(1+⎕IO)⊃⎕RSI,#
          code←1 BIC exprIn
          :If verbose 
              ⎕←'> ',⎕THIS{p←'\Q','.\E',⍨⍕⍺ ⋄ p ⎕R ''⊢⍵}code  
          :EndIf
          isShy←×≢('^\(?(\w+(\[[^]]*\])?)+\)?←'⎕S 1⍠'UCP' 1)⊣code~' '   ⍝ Kludge to see if code has an explicit result.
          run←{ ⍝ ⍵ is set to lastResult, used in ⍺⍎⍺⍺
               res←⍺⍎⍺⍺ 
               2≠⎕NC 'res': 0⊣⎕←↑'VALUE ERROR' ('      ',exprIn) '      ∧ '   ⍝ Char str not returned!
               ⍵⍵: res ⋄ ⊢⎕←1∘Prettify⍣pretty⊣res     
          }                   
          lastResult←caller (code run isShy) lastResult
      :Else
           ⎕←{⎕IO←1
              dm0 dm1 dm2←⍵  
              dm0↓⍨←1 
              (p↑dm1)←' '⊣ p←dm1⍳']' 
              ↑ dm0 dm1 dm2
           }⎕DMX.DM
      :EndTrap
      ∇
    :Endsection Utilities: BI_LIB, BI_DC (desk calc), BIC

    :Section Bigint Namespace - Postamble
   _NAMELIST_←'BI_LIB BI BII BIM BI_DC BIC BI_HELP' 
    ___←0 ⎕EXPORT ⎕NL 3 4
    ___←1 ⎕EXPORT {⍵[⍋↑⍵]}{⍵⊆⍨' '≠⍵}  _NAMELIST_
    ⎕PATH←⎕THIS{0=≢⎕PATH:⍕⍺⊣⎕← '⎕PATH was "". Setting to "',(⍕⍺),'"'⋄ ⍵}⎕PATH
    ⎕EX '___'
    :EndSection Bigint Namespace - Postamble

    :Section Help
⍝H The BigInt Library
⍝H ¯¯¯ ¯¯¯¯¯¯ ¯¯¯¯¯¯¯
⍝H  Built on dfns::nats, restructured for signed integers. Faster than dfns::big and less amenable to WS FULL.
⍝H  Routine: BI, BII, BIM, BIC, BI_DC, and BI_HELP.
⍝H  BI:    For most uses, use operator BI. It returns big integers in a string (external) format.
⍝H  BII:   Operator BII returns big integers in a more efficient internal format (signum_scalar integer_vector). 
⍝H  BIM:   BI with modulo argument; efficient for multiplication and exponentiation.
⍝H  BIC:   See below.
⍝H  BI_DC: A big integer desk calculator. Includes HELP information.
⍝H  -----
⍝H  All arguments may be in either the external (string) or internal formats.
⍝H  Strings may have underscores to separate runs of digits; negative numbers are prefixed by either ¯ or -.
⍝H
⍝H   Basic routine for most uses:  BI
⍝H
⍝H       BI     [⍺]  +BI ⍵
⍝H              Does all the basic monadic and dyadic math operations: + - * etc.
⍝H              ⍺, ⍵:  any "scalar" big integer in internal (BigIntI) or external (BigIntE) formats.   
⍝H                   BigIntE:  A big integer string or (small) APL integer.
⍝H                      On input, BigIntE's may have embedded underscores (_) and '-' or '¯' as a negative prefix.
⍝H                   BigIntI:  A scalar result returned by most BII operations. See BII.
⍝H              Returns for most operands: a BigIntE normalized. See below.
⍝H                   When returned, a BigIntE is normalized, with a leading ¯ if negative.
⍝H                   ⍕BI nnn:  Returns a BigIntE with underscores after every five digits starting from the right.
⍝H       BII    [⍺]  +BII ⍵
⍝H              Does all the operations, just like BI, except for return type.
⍝H              ⍺, ⍵:  Same as for BI.
⍝H              Returns for most operands: 
⍝H                 A BigIntI for most, a "normalized" scalar consisting of a signum (-1, 0, 1) and an integer vector.
⍝H       BIM    ⍺  ×BIM ⍵ ⊣ modulo 
⍝H              Does operation  m | ⍺ × ⍵ for big integers ⍺, ⍵, and integer m. 
⍝H              Returns: An external format BigIntE.
⍝H              Specifically:
⍝H                     ⍺ ×BIM m ⊣ ⍵   is the same as    m |BI ⍺ ×BII ⍵   (except faster and less likely to trigger a WS FULL)
⍝H              BIM is optimized for ops: × (mul) and * (pow) so far.  
⍝H              For other operations, calls modulo after performing <op>.
⍝H       BIC    Takes a standard APL-format mathematical expression without BI or BIC and inserts the BI calls.
⍝H              E.g.      BIC  '!500' is the same as  !BI 500
⍝H       BI_DC  A Big Integer Desk Calculator...
⍝H              To execute, call BI_DC (no args, no return value).
⍝H
⍝H Table of Contents
⍝H   Preamble
⍝H      Preamble 
⍝H   BI/BII
⍝H      BigInt Initializations
⍝H      Executive: BI, BII, BIM, bi
⍝H      BigInt internal structure
⍝H      Monadic Operands/Functions for BII, BI, BIM
⍝H      Dyadic Operands/Functions for BII, BI, BIM
⍝H      Directly-callable Functions ⍵⍵ via BI_LIB.⍵⍵.
⍝H      BI Special Functions/Operations (More than 2 Args)
⍝H      Unsigned Utility Math Routines
⍝H      Service Routines
⍝H  Utilities
⍝H      BI_LIB   (returns the BigInt namespace).
⍝H      BI_DC    (desk calculator)
⍝H      BIC      (BI math "compiler")
⍝H  Postamble
⍝H      Exported and non-Exported Utilities
⍝H   ----------------------------------
⍝H   INTERNAL-FORMAT BIs (BigIntI)
⍝H   ----------------------------------
⍝H    BIint  -internal-format signed Big Integer numeric vector:
⍝H          sign (data) ==>  sign (¯1 0 1)   data (a vector of integers)
⍝H          ∘ sign: If data is zero, sign is 0 by definition.
⍝H          ∘ data: Always 1 or more integers (if 0, it must be data is ,0).
⍝H                  Each element is a positive number <RX10 (10E6)
⍝H          ∘ depth: ¯2    shape: 2
⍝H    Given the canonical requirement, a BIint of 0 is (0 (,0)), 1 is (1 (,1)) and ¯1 is (¯1 (,1)).
⍝H
⍝H    BIu  -unsigned internal-format BIint (vector of integers) used in unsigned routines internally.
⍝H          ∘ Consists solely of the data vector (2nd element of BIint).
⍝H
⍝H   ---------------------------------
⍝H   EXTERNAL-FORMAT BIs (BigIntE)
⍝H   ---------------------------------
⍝H     ON INPUT
⍝H          an external-format Big Integer on input, i.e. a character string as entered by the user.
⍝H          a BIext has these characteristics:
⍝H          ∘ char. vector or scalar   ∘ leading ¯ or - prefix for minus, and no prefix for plus.
⍝H          ∘ otherwise, only the digits 0-9 plus optional use of _ to space digits.
⍝H          ∘ If no digits (''), it represents 0.
⍝H          ∘ spaces are disallowed, even leading or trailing.
⍝H     ON OUTPUT
⍝H          a canonical (normalized) external-format BIext string returned has a guaranteed format:
⍝H          ∘ char. vector     ∘ leading ¯ ONLY for minus.
⍝H          ∘ otherwise, only the digits 0-9. No spaces, or hyphen - for minus.
⍝H          ∘ underscores are optional. BI/BII produce underscores in Prettify mode only (see ⍕BI).
⍝H          ∘ leading 0's are removed.
⍝H          ∘ 0 is represented by (,'0'), unsigned with no extra '0' digits.
⍝H
⍝H   OTHER TYPES
⍝H    Int   -an APL-format single small integer ⍵, often specified to be in range ⍵<RX10 (the internal radix, 1E6).
⍝H --------------------------------------------------------------------------------------------------
⍝H  OPERANDS AND ARGUMENTS FOR BI, BII, and BIM
⍝H  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H        BI:  Usually returns a BigInt in External format. 
⍝H             In specific cases, returns integer scalars (see dyadic ∧, ∨; <, =, etc.) or APL arrays (see ⍳, DIVREM, ⎕AT)
⍝H        BII: Usually returns a BigInt in Internal format. In specific cases, like BI above.
⍝H        BIM: Requires ⍺ and ⍵ as for (fn BII) and m (modulo) as right operand ⍵⍵. 
⍝H           23456 (×BIM 16) '9999999999'  
⍝H  MONADIC OPERANDS: +BI ⍵
⍝H  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H        Right argument: ⍵ in BigInt internal or external formats (BigIntI or BigIntE).
⍝H        Operators: BI or BII only. BIM is only used dyadically.
⍝H           -BI  ⍵             negate
⍝H           +BI  ⍵             canonical (returns BI  ⍵ in standard form, however entered)
⍝H           |BI  ⍵             absolute value
⍝H           ×BI  ⍵             signum ('-1', '0', '1') 
⍝H           ÷BI  ⍵             inverse (mostly useless)
⍝H           <BI  ⍵             decrement (alternate ≤). Optimized (wherever overflow/underflow do NOT occur).
⍝H           >BI  ⍵             increment (alternate ≥). Optimized (ditto).
⍝H           !BI  ⍵             factorial
⍝H           ?BI  ⍵             roll.  ⍵>0. Returns number between 0 and ⍵-1
⍝H           ⍎BI  ⍵             APL integer, if exponent in range. Else signals error.
⍝H           ⍕BI  ⍵             pretty format: returns canonical int with - for neg and _ separator every 5 digits
⍝H           ('√'BI)  ⍵         sqrt (alternate 'SQRT'). Use ⍺*0.5 (optimized special case).
⍝H           ⍳BI  ⍵             iota. Returns APL vector ⍳⍵ on APL-range integers only. Provided only for convenience.
⍝H           ≢BI  ⍵             number of digits. Returns APL integer, number of digits in ⍵, 
⍝H                              ignoring sign and spacing underscores.
⍝H                                 10 <==   ≢BI '¯12345_12345'
⍝H                                301 <==   ≢BI 2*BI 999        ⍝ from  5_35754_30359_..._28340_34688
⍝H                                301 <==   ≢BI ⍕BI ¯2*BI 999   ⍝ from ¯5_35754_30359_..._28340_34688
⍝H           →BI  ⍵             internal: returns BI  ⍵ in internal form:  signum_integer hand_numeric_vector
⍝H           ⊥BI  ⍵             bit-encode: converts bits to equivalent BI: 1 sign bit, 20 bits per unsigned "hand"
⍝H           ⊤BI  ⍵             bit-decode: converts BI to equivalent bits (returns boolean): see ⊥.
⍝H           ~BI  ⍵             flip: flip all the bits in big integer BI  ⍵, returning a big integer (not bits)
⍝H           ⎕AT BI  ⍵          attributes: returns 3 integers: 
⍝H                                 <num hands> <num bits> <num 1 bits>
⍝H                                 hands: a BigInt consists of a sign num (¯1 0 1) and a vector of unsigned integers, 
⍝H                                        each such integer is called a hand.)
⍝H                                 num bits: We pretend each big integer consists of the ravel of a sign bit (1=neg) 
⍝H                                        and a sequence of bits for each hand.)
⍝H                                 num 1 bits: Also known as a population count (popcount).)
⍝H  DYADIC OPERANDS: ⍺ ×BI ⍵, ⍺ ×BII ⍵, ⍺ ×BIM ⍵⍵ ⊣ modulo
⍝H  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H        BI, BII: Arguments ⍺ and ⍵ are Big Integer internal or external formats (BigIntI or BigIntE)
⍝H        BIM:     ⍺ (fn BIM modulo)⍵  <==>   modulo | ⍺ fn BI ⍵, except × and * are calculated efficiently within range <modulo>.
⍝H           ⍺ + BI  ⍵          add
⍝H           ⍺ - BI  ⍵          subtract
⍝H           ⍺ × BI  ⍵          multiply
⍝H           ⍺ ÷ BI  ⍵          divide
⍝H           ⍺ * BI  ⍵          power.    BI  ⍵ may be fractional to express integral root ÷BI  ⍵.    cube root:    ⍵ *BI ÷3
⍝H           ⍺ *∘÷ BI  ⍵        BI  ⍵th root ⍺                                                        cube root: 3 *∘÷ BI  ⍵
⍝H           ⍺ ('√' BI)  ⍵      BI  ⍵th root ⍺                                                    cube root: 3 ('√' BI) BI  ⍵
⍝H           ⍺ ⍟ BI  ⍵          ⌊(log of ⍵ in base ⍺).    Optimized for ⍺∊2 10 only.
⍝H           ⍺ ↑ BI  ⍵          decimal shift of ⍵ left  by ⍺ digits. Special code.    May be slower than [⍺ ×BI 10*BI  ⍵]
⍝H           ⍺ ↓ BI  ⍵          decimal shift of ⍵ right by ⍺ digits. Special code.    Ditto.
⍝H           ⍺ ⌽ BI  ⍵          binary shift of ⍵ to left (⍺≥0) or right (⍺≤0) by ⍺ digits [same as ⍺ ×BI 2*BII  ⍵]
⍝H           ⍺ | BI  ⍵          remainder ⍺ | BI  ⍵
⍝H                              ALIAS:  BI  ⍵ ('MOD' BI) ⍺  or   BI  ⍵ |⍨BI ⍺   (or its equiv:  BI  ⍵ |BI⍨ ⍺)
⍝H           ⍺ ⌈ BI  ⍵          max
⍝H           ⍺ ⌊ BI  ⍵          min
⍝H           ⍺ ∨ BI  ⍵          gcd (not used for: or).  Returns Bigint.
⍝H           ⍺ ∧ BI  ⍵          lcm (not used for: and). Returns Bigint.
⍝H           ⍺ 'DIVREM' BI  ⍵   returns two BigInts: ⌊⍺÷BI  ⍵ and  BI  ⍵|⍺
⍝H        Logical Ops:          < ≤ = ≥ > ≠  
⍝H           ⍺ < BI  ⍵          ⍺ < ⍵, where < is any logical op, ⍺ and ⍵ are bigints.  
⍝H           Return:            APL Boolean: 1 if true, else 0 (not: '1' or '0')
⍝H
⍝H        CONSTANTS (niladic functions findable by ⎕PATH)
⍝H           ZERO_BI← +BI  0    ONE_BI←     +BI  1
⍝H           TWO_BI←  +BI  2    MINUS1_BI←  +BI ¯1
⍝H           TEN_BI←  +BI 10
⍝H         INTERNAL CONSTANTS (fast arrays found via their full namespace specification:
⍝H           BI_LIB.( ZERO_BI ONE_BI TWO_BI MINUS1_BI TEN_BI)    
:EndSection
:ENDNAMESPACE
