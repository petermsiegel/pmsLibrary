:NAMESPACE BigInt
⍝  Built on dfns::nats, restructured for signed integers. Faster than dfns::big.
⍝  ∘ The operator BI is the most general utility. It returns big integers in an external (string) format.
⍝  ∘ The operator BII is the same as BI, except for returning big integers in a more efficient internal format. 
⍝  > Both allow arguments in either the external (string) or internal formats.
⍝  ∘ The terms <bi> and <bii> are used below:
⍝    bi:  a big integer in any external form (string, number, bii)
⍝    bii: a big integer in internal format (of depth ¯2, shape 2)
⍝ 
⍝  FOR HELP information, see :SECTION HELP or call BI_HELP.

:Section BI
  :Section PREAMBLE
  ⍝ Set DEBUG←1 to disable signal trapping.
    DEBUG←0                           
    ⎕IO ⎕ML ⎕PP ⎕CT ⎕DCT←  0 1 34 0 0  
  ⍝ ⎕FR as set here is used below to set constant OFL (overflow) used in multiplication.    
    ⎕FR←645                    
   :EndSection PREAMBLE

  :Section BI Initializations
  ⍝+------------------------------------------------------------------------------+⍝
  ⍝+-- BI INITIALIZATIONS                            BI INITIALIZATIONS         --+⍝
  ⍝-------------------------------------------------------------------------------+⍝

  ⍝ Key Bigint constants...
  ⍝ There's little reason to play with these; perhaps in the future different numbers will have performance impact.
    NRX2←         20                                     ⍝ Num bits in a "hand"
    NRX10←        ⌊10⍟2*NRX2                             ⍝ Max num of Dec digits in a hand
    NRX2BASE←     NRX2⍴2                                 ⍝ Encode/decode binary base
    RX10BASE←     NRX10⍴10                               ⍝ Encode/decode decimal base
    RX10←         10*NRX10                               ⍝ Actual base for each hand (each hand ⍵ < RX10)
    RX10div2←     RX10÷2                                 ⍝ (RX10÷2) For use in <Pow> (power).
    OFL←          ⌊(2*53 93⊃⍨1287=⎕FR)÷×⍨RX10            ⍝ Overflow bits; used in MulU (unsigned multiply)
                                                         ⍝ ... depends on integer bits avail in floats (i.e. ⎕FR)                          
  ⍝ --------------------------------------------------------------------------------------------------
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
  
  ⍝ Error messages. See dfn <∆ER11> above.
    eIMPORT←  'Object not a valid BigInt: '
    eDIVZERO← 'Division by zero'
    eBADRAND← 'Arg to Roll (?) must be integer >0'
    eFACTOR←  'Arg to factorial (!) must be ≥ 0'
    eBADRANGE←'BigInt outside dynamic range to be approximated in APL (exponent ≥ 1E6145)'
    eBIMDYAD← 'BIM Operator: only dyadic functions are supported'
    eLOG←     'Log of a non-positive BigInteger is undefined'
    eSMALLRT← 'Right argument must be a small APL integer ⍵<',⍕RX10
    eMUL10←    eSMALLRT
    eROOT←    'Base (⍺) for Root must be small non-zero integer: ⍺<',⍕RX10
    eSUB←     'SubU LOGIC: unsigned subtraction "⍺-⍵" requires ⍺≥⍵'

    Er1←  ⎕SIGNAL/{'Invalid or unimplemented monadic routine' 11 }
    Er2←  ⎕SIGNAL/{'Invalid or unimplemented dyadic routine'  11 }
    BI←{ ⍺←⊢  
    1006:: ⎕SIGNAL/ 'BI Interrupted' 1006
    0::    ⎕SIGNAL  ⊂⎕DMX.{'EM' 'EN' 'Message' ,⍥⊂¨ ('BI ',EM) EN Message}0
      ix← (1≢⍺1),(⍺⍺ DecodeCall map.op) 
      op← ⊃ ix⌷ map.fnRep 
         E← Export⍣ (⊃ix⌷map.export)
      ¯2= ≡res← ⍺ (op{⍺←⊢ ⋄ ⍺ ⍺⍺ ⍵}) ⍵: E res  
      E¨ res                     ⍝ DivRem, perhaps others...
    }
    BII←{ ⍺←⊢ 
    1006:: ⎕SIGNAL/ 'BII Interrupted' 1006
    0::    ⎕SIGNAL  ⊂⎕DMX.{'EM' 'EN' 'Message' ,⍥⊂¨ ('BII ',EM) EN Message}0 
      ix← (1≢⍺1),(⍺⍺ DecodeCall map.op) 
      op← ⊃ ix⌷ map.fnRep 
      ⍺ (op{⍺←⊢ ⋄ ⍺ ⍺⍺ ⍵}) ⍵
    }

    ⍝  BIM:   Perform BI divisor <Mod>.
    ⍝  BIM:   x (fn BIM Mod) y  ==>   Mod |BI x (fn BII) y, but 
    ⍝         More efficient for functions times (×) and exponent (*) and avoids some WS FULL.   
    BIM←{ 
      1006:: ⎕SIGNAL/ 'BIM Interrupted' 1006
      0::    ⎕SIGNAL  ⊂⎕DMX.{'EM' 'EN' 'Message' ,⍥⊂¨ ('BIM: ',EM) EN Message}0 
      1≡⍺1:  ⎕SIGNAL/ 'BIM: Mod must be of the form x (fn BIM mod) y' 11
          x y divisor←⍺ ⍵ ⍵⍵   
          i←  ⍺⍺ DecodeCall map.op 
          op← i⌷ map.op 
      op≡ '×':  Exp x (divisor ModMul) y 
      op≡ '*':  Exp x (divisor ModPow) y 
                Exp divisor |BII x(op BII) y 
    }
    :EndSection BI Initializations

    :Section Helper Utilities

    ⍝ DecodeCall:  offset← op DecodeCall opsL
    ⍝    op: APL_fn | 'string'. 
    ⍝        APL_fn: e.g. +, -, etc.
    ⍝        string: Any (quoted) string will be normalized to lower case...
    ⍝    opsL: a vector of ops, e.g. map.ops, searched for normalized <op>
    ⍝    Returns:
    ⍝        the integer offset to the string in opsL (or 1+ ≢opsL)
      DecodeCall←{ f←⍺⍺ 
        3=⎕NC 'f': ⍵⍳ ⎕NR'f' ⋄ str← ⎕C f 
        1=≢str:    ⍵⍳ str ⋄ ⍵⍳ ⊂str            ⍝ Treat single chars as scalars
      }
    :EndSection Helper Utilities

    :Section Operators BI and BII
    ∇ BI_HELP;⎕PW
     ⍝ extern: HELP_INFO
      :If 0=⎕NC'HELP_INFO' ⋄ HELP_INFO←'^\h*⍝H(.*)$'⎕S'\1'⎕SRC ⎕THIS ⋄ :EndIf
      ⎕PW←120 ⋄ (⎕ED⍠'ReadOnly' 1)&'HELP_INFO'
    ∇

    ⍝ BII: Basic utility operator for using APL functions in special BigInt meanings.
    ⍝     BIint←  ∇ ⍵:BIext
    ⍝     Returns BIint, an internal format BigInteger structure (sign and data, per above).
    ⍝     See below for exceptions.
    ⍝ BI: Basic utility operator built on BII.
    ⍝     BIext←  ∇ ⍵:BIext
    ⍝     Returns BIext, an external string-format BigInteger object ("[¯]\d+").
    ⍝     See below for exceptions.
   
⍝ --------------------------------------------------------------------------------------------------

    ##⍎'BIM←{⍺ (⍺⍺ ',(⍕⎕THIS),'.BIM ⍵⍵) ⍵}'  ⍝ Simulate (directly proscribed) ##.BIM← ⎕THIS.BIM 
    ##.BI←  ⎕THIS.BI 
    ##.BII← ⎕THIS.BII   

    ⎕←'Created: ',∊(⊂⍕##),¨'.',¨ 'BI ' 'BII ' 'BIM'

    :EndSection Operators BI and BII
    ⍝ ----------------------------------------------------------------------------------------

    :Section BigInt internal structure
      ⍝ =================================================
      ⍝ Import / Imp - Import to bii (internal) format...
      ⍝ =================================================
      ⍝  ⍺ Import ⍵  →→  (Import ⍺)(Import ⍵)
      ⍝  Import ⍵
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
          ¯2=≡⍵:    ⍵             ⍝ Fast: bii (depth: ¯2) are of form:  [1|0|¯1] [int vector]
          type←80|⎕DR ⍵
          type=3:   ImportAplInt ⍵  
          type=0:   ImportStr ⍵ 
          type∊5 7: ImportFloat ⍵
          ∆ER11 eIMPORT,⍕⍵
      }
      Imp←Import
     
      ⍝ ImportAplInt:    ∇ ⍵:I[1]
      ⍝ Import a small APL (native) integer into a bi.
      ⍝          ⍵ MUST Be an APL native (1-item) integer ⎕DR type 83 163 323.
      ImportAplInt←{
          1≠≢⍵:       ∆ER11 eIMPORT,⍕⍵       ⍝ singleton only...
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
          ∆ER11 eIMPORT,⍕⍵
      }
      ⍝ ImportStr: Convert a bi in string format into a bii
      ⍝  [nullStrOk←0]  ImportStr ⍵:S[≥1]   
      ⍝    nullStrOk=0: (⍵ must have at least one digit, possibly a 0).
      ⍝    nullStrOk=1: ⍵ has 0 digits? Return ZERO_BI.
      ⍝ Note: we don't allow spaces, since they might be understood as multiple bi's. 
      ⍝ Only _ can be used as a spacer.
      ImportStr←{ ⍺←0 
          s←1 ¯1⊃⍨'-¯'∊⍨1↑⍵            ⍝ Get sign, if any
          w←'_'~⍨⍵↓⍨s=¯1               ⍝ Remove initial sign and embedded _ (spacer: ignored).
          (0=≢⍵)∧⍺: ZERO_BI 
          (0=≢w)∨0∊w∊⎕D:∆ER11 eIMPORT,⍵  ⍝ w must include only chars in ⎕D (besides above) and at least one.
          d←rep ⎕D⍳w                   ⍝ d: data portion of BIint
          dlzNorm s d                  ⍝ Normalize (remove leading 0s). If d is zero, return ZERO_BI.
      }
      ⍝ ImportSmallAPLInt: Import ⍵ only if (when Imported) it is a single-hand integer
      ⍝          i.e. equivalent to a number (|⍵) < RX10.
      ⍝ Returns a small APL integer!
      ⍝ Usage: so far, we only use it in BI/BII where we are passing data to an APL fn (⍳).
      ImportSmallAPLInt←{
          s w←Imp ⍵ ⋄ 1≠≢w:∆ER11 eSMALLRT ⋄ s×,w
      }
    ⍝ ---------------------------------------------------------------------
    ⍝ Export/Exp: EXPORT a SCALAR bii to external canonical bi string.
    ⍝ ---------------------------------------------------------------------
    ⍝    r:BIc←  ∇ ⍵:BIint
    Export←{ ('¯'/⍨¯1=⊃⍵),⎕D[dlzRun,⍉RX10BASE⊤|⊃⌽⍵] }
    Exp←Export 

    ⍝ BI2Apl:    Convert valid bii ⍵ to APL integer, with error if Exponent too large.
    BI2Apl←{ 0:: ∆ER11 eBADRANGE ⋄ ⎕FR←1287 ⋄  ⍎Exp Imp ⍵}
   
  :EndSection BigInt internal structure
⍝ --------------------------------------------------------------------------------------------------


    :Section BI Monadic Operations/Functions
    ⍝ 
    ⍝  BI Monadic Internal Functions            
    ⍝     Neg                       
    ⍝     Sig                       
    ⍝     Abs                       
    ⍝     Inc                       
    ⍝     Dec                       
    ⍝     Fact                      
    ⍝     Roll                    
    ⍝     Root

    ⍝ Neg[ate]  
      Neg←{                                ⍝ -
          (sw w)← Imp   ⍵
          (-sw)w
      }
    ⍝ Sig[num] 
      Sig←{                                ⍝ ×
          (sw w)← Imp  ⍵
          sw(|sw)    ⍝ MINUSONE_BI, ZERO_BI, ONE_BI
      }
    ⍝ Abs: absolute value
      Abs←{                                ⍝ |
          (sw w)← Imp  ⍵
          (|sw)w
      }
    ⍝ Inc[rement]:                         ⍝ ⍵+1
      Inc←{
          (sw w)← Imp  ⍵
          sw=0: ONE_BI                     ⍝ ⍵=0? Return 1.
          sw=¯1:dlzNorm sw(⊃⌽Dec 1 w)     ⍝ ⍵<0? Inc ⍵ becomes -(Dec |⍵). dlzNorm handles 0.
          î←1+⊃⌽w                          ⍝ trial increment (most likely path)
          RX10>î:sw w⊣(⊃⌽w)←î              ⍝ No overflow? Increment and we're done!
          sw w Add ONE_BI                 ⍝ Otherwise, do long way.
      }
    ⍝ Dec[rement]:                         ⍝ ⍵-1
      Dec←{
          (sw w)← Imp  ⍵
          sw=0: MINUS1_BI                  ⍝ ⍵ is zero? Return ¯1
          sw=¯1:dlzNorm sw(⊃⌽Inc 1 w)     ⍝ ⍵<0? Dec ⍵  becomes  -(Inc |⍵). dlzNorm handles 0.
                                           ⍝ If the last digit of w>0, w-1 can't underflow.
          0≠⊃⌽w:dlzNorm sw w⊣(⊃⌽w)-←1      ⍝ No underflow?  Decrement and we're done!
          sw w Sub ONE_BI                 ⍝ Otherwise, do long way.
      }
   
    ⍝ Fact: compute BI factorials.
    ⍝       r:BIc←  Fact ⍵:BIext
    ⍝ We allow ⍵ to be of any size, but numbers larger than NRX10 are impractical.
    ⍝ We deal with 3 cases:
    ⍝    ⍵ ≤ 31:    We let APL calculate, with ⎕PP←34.   Fast.
    ⍝    ⍵ ≤ NRX10:   We calculate r as a BigInt, while counting down ⍵ as an APL integer. Moderately fast.
    ⍝    Otherwise: We calculate entirely using BigInts for r and ⍵. Slowwwwww.
      Fact←{                                ⍝ !⍵
          (sw w)← Imp  ⍵
          sw=0:ONE_BI                       ⍝ !0
          sw=¯1:∆ER11 eFACTOR                 ⍝ ⍵<0
          FactBig←{⍺←1
              1=≢⍵:⍺ FactSmall ⍵            ⍝ Skip to FactSmall when ≢⍵ is 1 hand.
              (⍺ MulU ⍵)∇⊃⌽Dec 1 ⍵
          }
          FactSmall←{
              ⍵≤1:1 ⍺
              (⍺ MulU ⍵)∇ ⍵-1
          }
          1 FactBig w
      }
    ⍝ Roll ⍵: Compute a random number between 0 and ⍵-1, given ⍵>0.
    ⍝    r:BIint←  ∇ ⍵:BIint   ⍵>0.
    ⍝ With inL the # of Dec digits in ⍵, excluding any leading '0' digits...
    ⍝ Proceed as shown here, where (Exp ⍵) is "Exported" BIext format; (Imp ⍵) is internal BIint format.
      Roll←{
          (sw w)← Imp  ⍵
        sw≠1: ∆ER11 eBADRAND
          ⎕PP←16 ⋄ ⎕FR←645                       ⍝ 16 digits per ?0 is optimal
          inDig←≢Exp sw w                        ⍝ ⍵: in Export form. in: ⍵ with leading 0's removed.
     
          outStr← inDig⍴ { ⍺←''                  ⍝ res is built up to ≥inL random digits...
              ⍵≤≢⍺: ⍺ ⋄ (⍺,2↓⍕?0)∇ ⍵-⎕PP         ⍝ ... ⎕PP digits at a time.
          }inDig                                 ⍝ res is then truncated to exactly inL digits
        '0'=⊃outStr:ImportStr outStr             ⍝ If leading 0, guaranteed (Imp res) < ⍵.
          ⍵ Rem ImportStr outStr                 ⍝ Otherwise, compute remainder Rem r: 0 ≤ r < ⍵.
      }

    ⍝ Pretty:   [0 [5]] Prettify a bigint 
    ⍝           See BI2Str. Identical, except ⍺[1] defaults to 5, not 0.
      Pretty←{ 
          ⍺←0 ⋄ (2↑⍺, 5) BI2Str ⍵ 
      } 

    ⍝ BI2Str: [0 [0]] BI2Str bigint 
    ⍝            Convert bigint ⍵ to string
    ⍝           ⍺[0]=1: replace ¯ by - .  ⍺=0 (default): don't.
    ⍝           ⍺[1]>0: place underscores every ⍺[1] digits starting at the right.
      BI2Str←{ 
          ⍺←0  ⋄ hi2lo sep← 2↑⍺   
        0:: ∆ER11 eIMPORT,⍕⍵
          str← sep{
            0=⍺: ⍵ ⋄ (⍺>0)∧⍺=⌊⍺: ('(\d)(?=(\d{',(⍕⍺),'})+$)') ⎕R '\1_'⊣ ⍵
            ∆ER11 'Invalid specification (⍺) to BI2Str (⍕)' 
          } Exp Imp  ⍵  
        0= hi2lo: str 
        '¯'≡⊃str: str⊣ (⊃str)←'-' ⋄ str  
      } 

    ⍝ NLimbs-- how many "limbs," i.e. integers in the data portion of the bignum
      NLimbs←{
        ≢ ⊃⌽Imp ⍵ 
      }
  
  ⍝ ExportNewBase: Base Output Conversion, including to bits.
  ⍝ Digits for base output conversation go up to base 62, using 0..9,a..z,A..Z
    ExportNewBase←{ alignBits←0  
        ⎕IO←0 ⋄ ⍺←16 ⋄ base←⍺ ⋄   
        (⍺<2)∨⍺>≢DIGITS_EXPANDED: 11 ⎕SIGNAL⍨'BI: ⊤/NEW_BASE base (⍺) must be between 2 and ',⍕≢DIGITS_EXPANDED
        (sw w)←Imp  ⍵
        dig←{ ⍺←''
            ZERO_D≡⍵: ⍺ '0'⊃⍨0=≢⍺   
            dec rem←⍵ DivU base
            dec ∇⍨ DIGITS_EXPANDED[rem],⍺
        }w
        base≠2: dig,⍨'¯'/⍨sw=¯1 
      ⍝ If alignBits, mantissa bits are multiples of NRX2 long, adding sign bit on left.
        (⍕sw=¯1),alignBits{~⍺: ⍵  ⋄ ⍵↑⍨-NRX2×⌈NRX2÷⍨≢⍵ }dig 
    }
  ⍝ See ExportNewBase
    DIGITS_EXPANDED←⎕D,(⎕C ⎕A),⎕A
    ⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

    ⍝ Root: A fast integer nth Root.
    ⍝ Syntax:    x@BIint←  nth@BIext<RX10 ∇ N@BIext
    ⍝            x←  nth Root N  ==>   x←  ⌊N *÷nth
    ⍝   nth: a small, positive integer (<RX10); default 2 (for Sqrt).
    ⍝   N:   any BIext
    ⍝   x:   the nth Root as an internal big integer.
    ⍝   ∘ Uses Fredrick Johanssen's algorithm with optimization for APL integers.
    ⍝   ∘ Estimator based on guesstimate for Sqrt N, no matter what Root.
    ⍝     (Better than using N).
    ⍝   ∘ As fast for Sqrt as a "custom" version.
    ⍝   ∘ If N is small, calculate directly via APL.
    ⍝ x:BIint←  nth:small_(BIint|BIext) ∇ N:(BIint|BIext)>0
      Root←{
        ⍝ Check radix in  N*÷radix
        ⍝ We work with bigInts here for convenience. Could be done unsigned...
          ⍺←TWO_BI                    ⍝ Sqrt by default... 
          sgn rdx← Imp ⍺
        sgn=0: ∆ER11 eROOT
        1<≢rdx: ∆ER11 eROOT                       
        sgn<0: 0                       ⍝  ⌊N*÷nth ≡ 0, if nth<0 (nth a small int)
        ⍝ Check ⍵ => N. Domain: non-negative integer
          sN N←Imp ⍵                
        0=sN: sN N                     ⍝ 0: Root(0) <=> 0
        ¯1=sN: ∆ER11 eROOT               ⍝ Negative: error
          rootU← *∘(÷rdx)
         ⍝ N small? Let APL calc value
          1=ndig←≢N: 1(,⌊rootU N)      
        ⍝ Initial estimate for N*÷nth must be ≥ the actual solution, else this will terminate prematurely.
        ⍝ Initial estimate (x):
        ⍝   DECIMAL est: ¯1+10*⌈num_dec_digits(N)÷2       <== We use this one.
          x←{ 
            0:: (⌈rootU⊃⍵),(RX10-1)⍴⍨⌈0.5×ndig-1  ⍝ Too big for APL est. Use DECIMAL est. above.
              ⎕FR←1287
              ⊃⌽Imp 1+⌈rootU⍎Exp 1 ⍵                 ⍝ Est via APL: works for ⍵ ≤ ⌊/⍬  (⍵≤1E6145) given ⎕FR=1287
          }N
        ⍝ Given unsigned x, y, N, rdx, refine x (aka ⍵), until y ≥ x, then return pos Root (1 (,x)).
          {   x←⍵
              y←(x AddU N QuotientU x)QuotientU rdx    ⍝ y is next guess: y←⌊((x+⌊(N÷x))÷nth)
              ≥cmp y mix x: 1(,x)                      ⍝ y ≥ x? Return x
              ∇ y                                      ⍝ y is smaller than ⍵. Set x←y and try another.
          }x
      }
    Sqrt←Root
 
  ⍝ Recip:  ÷⍵← → 1÷⍵. Effectively useless, since ÷⍵ is 0 unless ⍵ is 1 or ¯1.
    Recip←{{0=≢⍵: ÷0 ⋄ 1≠≢⍵:0 ⋄ 1=|⍵:⍵ ⋄ 0}dlzRun ⍵}

    :Endsection BI Monadic Functions/Operations
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Dyadic Functions/Operations

  ⍝ dyad:    compute all supported dyadic functions
      Add←{
          (sa a)(sw w)← ⍺ Imp  ⍵
          sa=0:sw w                           ⍝ optim: ⍺+0 → ⍺
          sw=0:sa a                           ⍝ optim: 0+⍵ → ⍵
          sa=sw:sa(ndnZ 0,+⌿a mix w)          ⍝ 5 + 10 or ¯5 + ¯10
          sa<0:sw w Sub 1 a                  ⍝ Use unsigned vals: ¯10 +   5 → 5 - 10
          sa a Sub 1 w                       ⍝ Use unsigned vals:   5 + ¯10 → 5 - 10
      }
      Sub←{
          (sa a)(sw w)← ⍺ Imp  ⍵
          sw=0:sa a                            ⍝ optim: ⍺-0 → ⍺
          sa=0:(-sw)w                          ⍝ optim: 0-⍵ → -⍵
          sa≠sw:sa(ndnZ 0,+⌿a mix w)           ⍝ 5-¯3 → 5+3 ; ¯5-3 → -(5+3)
          <cmp a mix w:(-sw)(nupZ-⌿dck w mix a)⍝ ⍺<⍵: 3-5 →  -(5-3)
          sa(nupZ-⌿dck a mix w)                ⍝ a≥w: exec     5-3
      }

    ⍝ Multiple10U: ⍵ is small (single APL int) multiple of 10
    ⍝   Returns (-log10 ⍵) if ⍵ is a multiple of 10, else 0.
    ⍝ See Mul, Div here.
      Multiple10U← {1≠≢⍵: 0 ⋄ 0≠sh10← 10|⍵: 0 ⋄ 10⍟⍵ }
      Mul←{
          (sa a)(sw w)← ⍺ Imp  ⍵
        0∊sa,sw: ZERO_BI
        TWO_D≡a: (sa×sw)(AddU⍨w) 
        TWO_D≡w: (sa×sw)(AddU⍨a)
        ONE_D≡a: (sa×sw)w        
        ONE_D≡w: (sa×sw)a
      ⍝ Minimal advantage of this optimization for small N, decreasing as N grows.
        ⍝   m10w m10a← Multiple10U¨w a 
        ⍝ 0≠ m10w:  Imp (Exp sa a), m10w⍴ '0' 
        ⍝ 0≠ m10a:  Imp (Exp sw w), m10a⍴ '0' 
          (sa×sw)(a MulU w)
      }
    ⍝ Div: For special cases (except ⍵ multiples of 10), see DivU.
      Div←{ 
          (sa a)(sw w)← ⍺ Imp  ⍵
        sw=0: ∆ER11 eDIVZERO              ⍝ Don't allow division by 0.
      ⍝ Some clear advantage to this optimization...
      ⍝ (1 ImportStr...) ensures empty string is allowed and returns 0.
        0≠m10n← -Multiple10U w: 1 ImportStr m10n↓ Exp (sa×sw) a 
          normFromSign(sa×sw)(⊃a DivU w)
      }
    ⍝ Since DivU returns both quotient and remainder, calling DivRem is faster than calling both Div and Mod calls  
    ⍝    (⍺ Div ⍵)  and (⍺ Mod ⍵)
    ⍝ For other special cases, see DivU.
      DivRem←{
          (sa a)(sw w)← ⍺ Imp  ⍵
        sw=0: ∆ERR11 eDIVZERO 
      ⍝ Some clear advantage to this optimization...
      ⍝ (1 ImportStr¨...) ensures empty strings are allowed and return 0.
        0≠m10n← -Multiple10U w: 1 ImportStr¨ m10n(↓,⍥⊂↑) Exp (sa×sw) a 
          quot rem←a DivU w
          (normFromSign(sa×sw)quot)(normFromSign sw rem)
      }
 
    ⍝ ⍺ Pow ⍵:
    ⍝   General case:  ⍺*⍵ where both are BIint
    ⍝   Special case:  (÷⍵) (or ÷⍎⍵) is an integer: (÷⍵) Root ⍺. Example:  ⍺*BI 0.5 is Sqrt; ⍺*BI (÷3) is cube Root; etc.
    ⍝                  (÷⍵) must be an integer to the limit of the current ⎕CT.
    ⍝ DecodeRoot (Pow utility): Allow special syntax ( ⍺ *BI ÷⍵ ) in place of  ( ⍵ Root ⍺ ).
    ⍝       ⍵ must be an integer such that 0<⍵<1 or a string representation of such an integer.
    ⍝       For 3 Root 27, use:
    ⍝             I.e. '27' *BI ÷3    '27' *BI '÷3'
    ⍝       The Root is truncated to an integer.
      DecodeRoot←{              
          0::0 ⋄ 0>≡⍵:0                ⍝ BI format? Can't be a Root. Skip (return 0)!      
        ⍝ See if ⍵ a Root spec...      ⍝ if not, skip!                  
          rec←{1≤⍵:0 ⋄ ⌊÷⍵} 
          0=1↑0⍴⍵: rec           ⍵   ⍝ ⍵ numeric?       Return ÷⍵ if fractional.**
          '÷'=1↑⍵: ⌊   ⊃⊃⌽⎕VFI 1↓⍵   ⍝ ⍵ of form '÷2'?  Return numeric 2.
                   rec ⊃⊃⌽⎕VFI   ⍵   ⍝ ⍵ of form '0.5'? Return numeric 2 (÷0.5) if fractional. **
      }                                ⍝ ** = Else skip (return 0).

      Pow←{
          0≠rt←DecodeRoot ⍵: rt Root ⍺
        ⍝ Not a Root, so decode as usual
        ⍝ Special cases ⍺*2, ⍺*1, ⍺*0 handled in PowU.
          (sa a)(sw w)← ⍺ Imp  ⍵
          sa sw∨.=0 ¯1:ZERO_BI     ⍝ r←⍺*¯⍵ is 0≤r<1, so truncates to 0.
          p←a PowU w
          sa= 1: 1 p               
          0=2|⊃⌽w:1 p ⋄ ¯1 p       ⍝ sa=¯1, so result is pos. if ⍵ is even.
      }
      Rem←{                        ⍝ Remainder/residue. APL'S DEF: ⍺=base.
          (sa a)(sw w)← ⍺ Imp  ⍵
          sw=0:ZERO_BI
          sa=0:sw w
          r←,a RemU w              ⍝ RemU is fast if a>w
          sa=sw:dlzNorm sa r       ⍝ sa=sw: return (R)        R←sa r
          ZERO_D≡r:ZERO_BI         ⍝ sa≠sw ∧ R≡0, return 0
          dlzNorm sa a Sub sa r   ⍝ sa≠sw: return (A - R')   A←sa a; R'←sa r
      }
  
    ⍝ Mul2Exp:  Shift ⍺:BIext left or right by ⍵:Int binary digits
    ⍝  r:BIint←  ⍺:BIint   ∇  ⍵:aplInt
    ⍝     Note: ⍵ must be an APL integer (<RX10).
    ⍝  -  If ⍵>0: Shift ⍺ left by ⍵ binary digits
    ⍝  -  If ⍵<0: Shift ⍺ rght by ⍵ binary digits
    ⍝  -  If ⍵=0: then ⍺ will be unchanged
    ⍝ Very slow!
      Mul2Exp←{
          (sa a)(sw w)← ⍺ Imp  ⍵
          1≠≢w:∆ER11 eMUL10                         ⍝ ⍵ must be small integer.
          sa=0:0 ZERO_D                           ⍝ ⍺ is zero: return 0.
          sw=0:sa a                               ⍝ ⍵ is zero: ⍺ stays as is.
          pow2←2*w
          sw>0:sa a Mul pow2
          sa a Div pow2
      }

    ⍝ Mul10Exp: Shift ⍺:BIext left or right by ⍵:Int decimal digits.
    ⍝      Converts ⍺ to BIc, since shifts are a matter of appending '0' or removing char digits from right.
    ⍝  r:BIint←  ⍺:BIint   ∇  ⍵:Int
    ⍝     Note: ⍵ must be an APL  big integer, BigIntA (<RX10).
    ⍝  -  If ⍵>0: Shift ⍺ left by ⍵-decimal digits
    ⍝  -  If ⍵<0: Shift ⍺ rght by ⍵ decimal digits
    ⍝  -  If ⍵=0: then ⍺ will be unchanged
    ⍝  WARNING: THIS APPEARS TO RUN ABOUT 80% SLOWER THAN A SIMPLE MULTIPLY FOR MEDIUM AND LONG ⍺, unless ⍵ is long, e.g. 1000 digits.
    ⍝           It is however much faster for ⍺ Div  10 or ⍺ DivRem 10, which use  ⍺ Mul10Exp ¯1
      Mul10Exp←{
          (sa a)(sw w)← ⍺ Imp  ⍵
          1≠≢w:∆ER11 eMUL10                          ⍝ ⍵ must be small integer.
          sa=0:ZERO_BI                             ⍝ ⍺ is zero: return 0.
          sw=0:sa a                                ⍝ ⍵ is zero: sa a returned.
          ustr←Exp 1 a                          ⍝ ⍺ as unsigned string.
          ss←'¯'/⍨sa=¯1                            ⍝ sign as string
          sw=1:Imp ss,ustr,w⍴'0'                   ⍝ sw= 1? Shift left by appending zeroes.
          ustr↓⍨←-w                                ⍝ sw=¯1? Shift right by Dec truncation
          0=≢ustr:ZERO_BI                          ⍝ No chars left? It's a zero
          Imp ss,ustr                              ⍝ Return in internal form...
      }
   
    ⍝ ∨ Greatest Common Divisor
      Gcd←{
          (sa a)(sw w)← ⍺ Imp  ⍵
          1(a GcdU w)
      }
    ⍝ ∧ Least/Lowest Common Multiple
      Lcm←{
          (sa a)(sw w)← ⍺ Imp  ⍵
          (sa×sw)(a LcmU w)
      }

  ⍝ Log10: L← Log10 N
  ⍝ Log:   L←  B Log N
  ⍝ Big Integer logarithm base <B> of big integer <N>. B defaults to (base) 10.
  ⍝ Returns <L> in BI internal format.
    Log10←{ 1, ⊂¯1+≢Exp Imp ⍵ } 
    Log←{
          ⍺←TEN_BI ⋄ B N←⍺ Imp ⍵
        0≥⊃N: ∆ER11 eLOG                     ⍝ N ≤ 0
        TEN_BI≡B: 1  (¯1+≢Exp N)
          ZERO_BI { ⍵ Le ONE_BI: ⍺ ⋄ (Inc ⍺)∇ ⍵ Div B } N  
    }

    Ident←{
      aNorm wNorm← ⍺ Imp ⍵
      aNorm≡ wNorm 
    }
    Differ←{
      aNorm wNorm← ⍺ Imp ⍵
      aNorm≢ wNorm 
    }
 
    :Section Boolean Operations
    ⍝ Bool: Execute a boolean operation.  ⍺ <Bool ⍵
      Bool←{
          (sa a)(sw w)← ⍺ Imp ⍵
        0∊sa sw:sa ⍺⍺ sw        ⍝ ⍺, ⍵, or both are 0
        sa≠sw:sa ⍺⍺ sw          ⍝ ⍺, ⍵ different signs
        sa=¯1: ⍺⍺ cmp w mix a    ⍝ ⍺, ⍵ both Neg
          ⍺⍺ cmp a mix w          ⍝ ⍺, ⍵ both pos
      }
      Lt← <Bool ⋄ Le← ≤Bool ⋄ Eq← =Bool ⋄ Ge← ≥Bool ⋄ Gt← >Bool ⋄ Ne← ≠Bool 
    :EndSection Boolean Operations  

    :EndSection BI Dyadic Operators/Functions

    :Section BI Special Functions/Operations (More than 2 Args)
    ⍝ ModMul:  modulo m of product a×b
    ⍝ A faster method than (m|a×b), when a, b are large and m is substantially smaller.
    ⍝ r←  a (m ModMul) b   →→→    r←  m | a × b
    ⍝ BIint←  ⍺:BIint ∇ ⍵:BIint m:BIint
    ⍝ Naive method: (m|a×b)
    ⍝      If a,b have 1000 digits each and m is smaller, the m| operates on 2000 digits.
    ⍝ Better method: (m | (m|a)×(m|b)).
    ⍝      Here, the multiply is on len(m) digits, and the final m operates on 2×len(m).
    ⍝ For large a b of length 5000 Dec digits or more, this alg can be 2ce the speed (13 sec vs 26).
    ⍝ It is nominally faster at lengths around 75 digits.
    ⍝ Only for smaller a and b, the cost of 3 modulos instead of 1 predominates.
      ModMul←{
          (a b)m←(⍺ Imp ⍵)(Imp ⍺⍺)
          m Rem(m Rem a)Mul(m Rem b)
      }
    ⍝ ModPow -- a (m ModPow) n -- from article by Roger Hui Aug 2020  
    ∇ z←a(m ModPow)n
      ;s;mmM
      ⍝ m|a*n  ==>   a (m ModPow) n  
      (a n)m←(a Imp n)(Imp m)
      z←ONE_BI ⋄ s←m Rem a
      mmM←m ModMul 
      :While ZERO_BI Lt n
          :If 1 Eq 2 Rem n ⋄ z←z mmM s ⋄ :EndIf    ⍝ z←m| z×s
          s←s mmM s                                ⍝ s←m| s×s
          n←n Div 2
      :EndWhile
    ∇
    :EndSection BI Special Functions/Operations (More than 2 Args)
⍝ --------------------------------------------------------------------------------------------------

    :Section BI Unsigned Utility Math Routines
    ⍝ These are the workhorses of bigInt; most are from dfns:nats (handling unsigned bigInts).
    ⍝ Note: ⍺ and ⍵ are guaranteed by BII and BI to be vectors, but not
    ⍝       by internal functions or if called directly.
    ⍝       So tests for 2, 1, 0 (TWO_D etc) use ravel:  (TWO_D≡,⍺)

    ⍝ AddU:   ⍺ + ⍵
      AddU←{
          dlzRun ndn 0,+⌿⍺ mix ⍵    ⍝ We use dlzRun in case ⍺ or ⍵ have multiple leading 0s. If not, use ndnZ
      }
    ⍝ SubU:  ⍺ - ⍵   Since unsigned, if ⍵>⍺, there are two options:
    ⍝        [1] Render as 0
    ⍝        [2] signal an error...
      SubU←{
          <cmp ⍺ mix ⍵:∆ER11 eSUB                   ⍝ [opt 2] 3-5 →  -(5-3)
          dlzRun nup-⌿dck ⍺ mix ⍵                 ⍝ a≥w: 5-3 → +(5-3). ⍺<⍵: 0 [opt 1]
      }
    ⍝ MulU:  multiply ⍺ × ⍵  for unsigned Big Integer (BigIntU) ⍺ and ⍵
    ⍝ r:BIint←  ⍺:BIint ∇ ⍵:BIint
    ⍝ This is dfns:nats Mul.
    ⍝ It is faster than dfns:xtimes (FFT-based algorithm)
    ⍝ even for larger numbers (up to xtimes smallish design limit)
    ⍝ We call ndnZ to remove extra zeros, esp. so zero is exactly ,0 and 1 is ,1.
      MulU←{
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
              p q←⍺∘∇¨(s↑⍵)(s↓⍵)                  ⍝ Sub-products (see notes).
              ndnZ 0,+⌿(p,s↓n⍴0)mix q             ⍝ sum of Sub-products.
          }⍵
      }
   ⍝ PowU: compute ⍺*⍵ for unsigned ⍺ and ⍵. (⍺ may not be omitted).
   ⍝       Note: ⍺ and ⍵ must be vectors!!!
   ⍝ RX10div2: (Defined above.)
      PowU←{CASE←(,⍵)∘≡
        ⍝ (1≠⍴⍴⍵)∨1≠⍴⍴⍺:  ∆ER11 'PowU: ⍺ and ⍵ must be vectors'
          CASE ZERO_D: ONE_D                       ⍝ =cmp ⍵ mix,0:,1 ⍝ ⍺*0 → 1
          CASE ONE_D:  ,⍺                          ⍝ =cmp ⍵ mix,1:⍺  ⍝ ⍺*1 → ⍺. Return "odd," i.e. use sa in caller.
          CASE TWO_D:  ⍺ MulU ⍺                    ⍝ ⍺×⍺
          hlf←{,ndn(⌊⍵÷2)+0,¯1↓RX10div2×2|⍵}       ⍝ quick ⌊⍵÷2.
          evn←ndnZ{⍵ MulU ⍵}ndn ⍺ ∇ hlf ⍵          ⍝ even power
          0=2|¯1↑⍵:evn ⋄ ndnZ ⍺ MulU evn           ⍝ even or odd power.
      }
   ⍝ DivU/: unsigned division
   ⍝  DivU:   Removes leading 0s from ⍺, ⍵ ...
   ⍝    Optimizations for ⍵÷⍵ handled here, as well as ⍵÷0, where ⍵≠0.
   ⍝ Returns:  (int. quotient) (remainder)
   ⍝           (⌊ua ÷ uw)      (ua | uw)
   ⍝   r:BIint[2]←  ⍺:BIint ∇ ⍵:BIint
      DivU←{     
          a w←dlzRun¨⍺ ⍵
          a≡w:  ONE_D ZERO_D                  ⍝ ⍺≡⍵: Quot=1, Rem=0. including ⍺÷⍵ is 0÷0.
          ZERO_D≡w: ∆ER11 eDIVZERO            ⍝ If ⍵=0 (exc. 0÷0), then ERROR!, for all ⍺, except ⍺=0.
          svec←(≢w)+⍳0⌈1+(≢a)-≢w              ⍝ shift vector.
          _divOver←{                          ⍝ fold along dividend.
              r p←⍵                           ⍝ result & dividend.
              q←⍺↑⍺⍺                          ⍝ shifted divisor.
              ppqq←RX10⊥⍉2 2↑p mix q          ⍝ 2 most signif. digits of p & q.
              cnvrg←{                         ⍝ next RX10-digit of result.
                  (p q)(lo hi)←⍺ ⍵            ⍝ Div and high-low test.
                  lo=hi-1:p{                  ⍝ convergence:
                    lo hi⊃⍨≥cmp ⍺ mix ⍵       ⍝ low or high.
                  }dLZ ndn 0,hi×q             ⍝ multiple.
                  mid←⌊0.5×lo+hi              ⍝ mid-point.
                  nxt←dLZ ndn 0,q×mid         ⍝ next multiplier.
                  gt←>cmp p mix nxt           ⍝ greater than:
                  ⍺ ∇ gt⊃2,/lo mid hi         ⍝ choose upper or lower interval.
              }
            ⍝ lower and upper bounds of ratio.
              r∆←p q cnvrg⌊0 1+↑÷/ppqq+(0 1)(1 0)        
              mpl←dLZ ndn 0,q×r∆              ⍝ multiple.
              p∆←dLZ nup-⌿p mix mpl           ⍝ remainder.
              (r,r∆)p∆                        ⍝ result & remainder.
          }
          dlzRun¨↑w _divOver/svec,⊂⍬ a        ⍝ fold-accumulated result.
    }
    QuotientU←⊃DivU
    GcdU←{ZERO_D≡,⍵:⍺ ⋄ ⍵ ∇⊃⌽⍺ DivU ⍵}        ⍝ greatest common divisor.
    LcmU←{⍺ MulU⊃⍵ DivU ⍺ GcdU ⍵}             ⍝ least common multiple.
    RemU←{                                    ⍝ RemU: ⍺, ⍵ unsigned; calcs and returns unsigned ⍺|⍵.
          TWO_D≡,⍺:2|⊃⌽⍵                      ⍝ fast (short-circuit) path for ⍺=2 (2|⍵). Check only last "hand".
          <cmp ⍵ mix ⍺:⍵                      ⍝ ⍵ < ⍺? remainder is ⍵
          ⊃⌽⍵ DivU ⍺                          ⍝ Otherwise, do full divide and return 2nd element, the remainder.
    }
    :Endsection BI Unsigned Utility Math Routines
⍝ --------------------------------------------------------------------------------------------------

  :Section Service Functions
    ⍝-----------------------------------------------------------------------------------+
    ⍝ Note: These Service Functions are                                                 +
    ⍝       ∘ directly from (or tweaks of) dfns::nats,                                  +
    ⍝       ∘ in lower camel case, per the originals                                    +
    ⍝-----------------------------------------------------------------------------------+
    ⍝ dlzNorm ⍵:BIint  If ⊃⌽⍵ is zero after removing leading 0's,
    ⍝                  return canonical BigInt ZERO_BI: (0 (,0)).
    ⍝                  Otherwise return ⍵ w/o leading zeroes.
    ⍝ normFromSign ⍵:BIint  If ⊃⌽⍵ is zero, ensure sign is 0. Otherwise, pass ⍵ as is.
      dlzNorm←{ZERO_D≡w←dlzRun⊃⌽⍵: ZERO_BI ⋄ (⊃⍵) w}
      normFromSign←{ZERO_D≡⊃⌽⍵:ZERO_BI ⋄ ⍵}
    ⍝ These routines operate on unsigned BIu data unless documented…  
      dLZ←{⍵↓⍨0=⊃⍵}                           ⍝ drop FIRST leading zero.
      dlzRun←{chkZ ⍵↓⍨+/∧\⍵=0}                ⍝ drop RUN of leading zeros, but [PMS extension] make sure at least one 0
      chkZ←{0≠≢⍵:,⍵ ⋄ ,0}                     ⍝ ⍬ → ,0. Ensure canonical Bii, so even 0 has one digit (,0).
      ndn←{ +⌿1 0⌽0 RX10⊤⍵}⍣≡                 ⍝ normalise down: 3 21 → 5 1 (RH).
      ndnZ←dLZ ndn                            ⍝ ndn, then remove (earlier added) leading zero, if still 0.
      nup←{⍵++⌿0 1⌽RX10 ¯1∘.×⍵<0}⍣≡           ⍝ normalise up:   3 ¯1 → 2 9
      nupZ←dLZ nup                            ⍝ PMS extension of nup
      mix←{↑(-⍺⌈⍥≢⍵)↑¨⍺ ⍵}                    ⍝ right-aligned mix.
      dck←{⍵⌿⍨2 1+0 ¯1⌽⍨≥cmp ⍵}               ⍝ difference check (equiv.)
      rep←{10⊥⍵{⍉⍵⍴⍺↑⍨-×/⍵}NRX10,⍨⌈NRX10÷⍨≢⍵} ⍝ radix RX10 rep of number.
      cmp←{⍺⍺/,(<\≠⌿⍵)/⍵}                     ⍝ compare first different digit of ⍺ and ⍵.
    :Endsection Service Functions
⍝ --------------------------------------------------------------------------------------------------

    :Section Miscellaneous Utilities
  ⍝ ∆ER11:  [1∊⍺] ∆ER11 msg => Signals 'msg'; else NOP.
  ⍝       Since we append args to many msgs, we clip each msg at ⎕PW⌊80...
    ∆ER11←⎕SIGNAL/{⍺←1 ⋄ 1∊⍺: (0.7 Clip 'DOMAIN ERROR: ',⍵) 11 ⋄ ⍬ ⍬ }   
  ⍝ ⍺ Clip ⍵:  ⍺=<ratio of ⍵=<msg string> which should be from left> with rest from right
    Clip←{p←⎕PW⋄ p≥≢⍵:⍵ ⋄ (⍵↑⍨p-∆),'…',⍵↑⍨1-∆←⌊p×1-⍺} 
  ⍝¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯⍝
  :EndSection Miscellaneous Utilities

  :Namespace map 
        m← ¯1   ⍝ missing value for fn1, fn2, exp1, exp2 
  ⍝ FNS_MONADIC LEFT TO DO←'=≠⊥⊤→~⍳≢' 
  ⍝ FNS_DYADIC LEFT TO DO ←('⌊⌈|∨∧⌽↑↓~⍟⍴') 
  ⍝ op: op code, fn1: 1adic fns, fn2: 2adic fns, 
  ⍝ exp1: should we export results for 1adic?, exp2: ditto 2adic?
  ⍝ fn1, fn2: Use unquoted m for missing function for 1adic or 2adic op codes (op),
  ⍝ fnRep: ⎕OR (obj rep) of the functions in fn1, fn2.
        op←    '+'   '-'   '×'   '÷'     '*'   '|'     '∨'    '∧'   '⍟'
        fn1←   'Imp' 'Neg' 'Sig' 'Recip'  m    'Abs'    m      m    'Log'   
        fn2←   'Add' 'Sub' 'Mul' 'Div'   'Pow' 'Rem'   'Gcd'  'Lcm' 'Log'       
        exp1←   1     1     1     1       m     1       m      m     1        
        exp2←   1     1     1     1       1     1       1      1     1         

        op,←    '⍕'      '⍎'      '≡'     '≢'
        fn1,←   'BI2Str' 'BI2Apl'  m      'NLimbs'
        fn2,←   'BI2Str'  m       'Ident' 'Differ'
        exp1,←   0        0        m       0
        exp2,←   0        m        0       0

        op,←   '<'   '≤'   '='   '≥'   '>'   '≠'  '!'    '?'    '√'      
        fn1,←  'Dec' 'Dec'  m    'Inc' 'Inc'  m   'Fact' 'Roll' 'Root'    
        fn2,←  'Lt'  'Le'  'Eq'  'Ge'  'Gt'  'Ne'   m      m    'Root'           
        exp1,←  1     1     m     1     1     m     1      1      1            
        exp2,←  0     0     0     0     0     0     m      m      1              

        op,←     'Root' 'Sqrt' 'Log10' 'DivRem'
        fn1,←    'Root' 'Root' 'Log10'  m
        fn2,←    'Root'  m      m      'DivRem'
        exp1,←    1      1      1       m
        exp2,←    1      m      m       1

      ⍝ "Normalise" <op> to lower case for easy searching. Equivalent: 'log10' 'Log10' 'lOG10'
        op←     ⎕C op           
      ⍝ Do NOT change case of entries in <fn>. 
      ⍝ Replace placeholder 0 with appropriate error function Er1 or Er2
        fn←     ↑ 'Er1' 'Er2' {(⊂⍺)@(m∘≡¨)⊢⍵}¨ fn1 fn2,¨m  
        export← ↑ exp1 exp2,∘⊂¨ m m            ⍝ ... to Er1, Er2, m, m 
      ⍝ See <map.fnRep> defined below:
        ⎕EX 'fn1' 'fn2' 'exp1' 'exp2'
    :EndNamespace 
        map.fnRep←  { 0:: ⎕←'map missing fn: "',⍵,'"' ⋄ ⎕OR ⍵}¨ map.fn  

    :Section Bigint Namespace - Postamble 
      __←1 ⎕EXPORT 'BI' 'BII' 'BIM' 'BI_HELP'⊣ 0 ⎕EXPORT ⎕NL 3 4
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
⍝H       BIM    ⍺  ×BIM ⍵ ⊣ divisor 
⍝H              Does operation  m | ⍺ × ⍵ for big integers ⍺, ⍵, and integer m. 
⍝H              Returns: An external format BigIntE.
⍝H              Specifically:
⍝H                     ⍺ ×BIM m ⊣ ⍵   is the same as    m |BI ⍺ ×BII ⍵   (except faster and less likely to trigger a WS FULL)
⍝H              BIM is optimized for ops: × (Mul) and * (Pow) so far.  
⍝H              For other operations, calls modulo after performing <op>.
⍝H       BIC    Takes a standard APL-format mathematical expression without BI or BIC and inserts the BI calls.
⍝H              E.g.      BIC  '!500' is the same as  !BI 500
⍝H       BI_DC  A Big Integer Desk Calculator...
⍝H              To execute, call BI_DC (no args, no return value).
⍝H       BI_HEX Converts a BigInteger (any format) into a hexadecimal string of abitrary length.
⍝H              See also 'HEX' operand:  ('HEX' BI) 
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
⍝H          ∘ char. vector     
⍝H          ∘ leading ¯ ONLY for minus.
⍝H          ∘ otherwise, only the digits 0-9. No spaces, or hyphen - for minus.
⍝H          ∘ leading 0's are removed.
⍝H          ∘ 0 is represented by (,'0'), unsigned, with no extra '0' digits.
⍝H          ∘ See ⍕BI for production of underscores on output 
⍝H            and for using std minus - on negative numbers.

⍝H
⍝H   OTHER TYPES
⍝H    Int   -an APL-format single small integer ⍵, often specified to be in range ⍵<RX10 (the internal radix, 1E6).
⍝H --------------------------------------------------------------------------------------------------
⍝H  OPERANDS AND ARGUMENTS FOR BI, BII, and BIM
⍝H  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H        BI:  Usually returns a BigInt in External format. 
⍝H             In specific cases, returns integer scalars (see dyadic ∧, ∨; <, =, etc.) or APL arrays (see ⍳, DIVREM, ⎕AT)
⍝H        BII: Usually returns a BigInt in Internal format. In specific cases, like BI above.
⍝H        BIM: Requires ⍺ and ⍵ as for (fn BII) and m (divisor) as right operand ⍵⍵. 
⍝H           23456 (×BIM 16) '9999999999'  
⍝H  MONADIC OPERANDS: +BI ⍵
⍝H  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H        Right argument: ⍵ in BigInt internal or external formats (BigIntI or BigIntE).
⍝H        Operators: BI or BII only. BIM is only used dyadically.
⍝H           -BI  ⍵             Negate
⍝H           +BI  ⍵             canonical (returns BI  ⍵ in standard form, however entered)
⍝H           |BI  ⍵             absolute value
⍝H           ×BI  ⍵             signum in APL format: ¯1, 0, 1
⍝H           ÷BI  ⍵             reciprocal (mostly useless)
⍝H           <BI  ⍵             decrement (alternate ≤). Optimized (wherever overflow/underflow do NOT occur).
⍝H           >BI  ⍵             increment (alternate ≥). Optimized (ditto).
⍝H           !BI  ⍵             factorial
⍝H           ?BI  ⍵             Roll.  ⍵>0. Returns number between 0 and ⍵-1
⍝H           ⍎BI  ⍵             APL integer, if exponent in range. Else signals error.
⍝H           ⍕BI  ⍵             pretty format: returns canonical int with - for Neg and _ separator every 5 digits
⍝H           ('√'BI)  ⍵         Sqrt (alternate 'SQRT'). Use ⍺*0.5 (optimized special case).
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
⍝H           ('HEX'BI) ⍵        hexadecimal: converts BigInt ⍵ into a hexadecimal-format numeric string:
⍝H                                  ('HEX'BI)'4276993775' ==>  FEEDBEEF
⍝H                              Hex strings are generated from the digits 0-9 and A-F (upper case). No prefix is used.
⍝H           ⎕AT BI  ⍵          attributes: returns 3 integers: 
⍝H                                 <num hands> <num bits> <num 1 bits>
⍝H                                 hands: a BigInt consists of a sign num (¯1 0 1) and a vector of unsigned integers, 
⍝H                                        each such integer is called a hand.)
⍝H                                 num bits: We pretend each big integer consists of the ravel of a sign bit (1=Neg) 
⍝H                                        and a sequence of bits for each hand.)
⍝H                                 num 1 bits: Also known as a population count (popcount).)
⍝H  DYADIC OPERANDS: ⍺ ×BI ⍵, ⍺ ×BII ⍵, ⍺ ×BIM ⍵⍵ ⊣ divisor
⍝H  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H        BI, BII: Arguments ⍺ and ⍵ are Big Integer internal or external formats (BigIntI or BigIntE)
⍝H        BIM:     ⍺ (fn BIM divisor)⍵  <==>   divisor | ⍺ fn BI ⍵, except × and * are calculated efficiently within range <divisor>.
⍝H           ⍺ + BI  ⍵          Add
⍝H           ⍺ - BI  ⍵          subtract
⍝H           ⍺ × BI  ⍵          multiply
⍝H           ⍺ ÷ BI  ⍵          divide
⍝H           ⍺ * BI  ⍵          power.    BI  ⍵ may be fractional to express integral Root ÷BI  ⍵.    cube Root:    ⍵ *BI ÷3
⍝H           ⍺ *∘÷ BI  ⍵        BI  ⍵th Root ⍺                                                        cube Root: 3 *∘÷ BI  ⍵
⍝H           ⍺ ('√' BI)  ⍵      BI  ⍵th Root ⍺                                                    cube Root: 3 ('√' BI) BI  ⍵
⍝H           ⍺ ⍟ BI  ⍵          ⌊(Log of ⍵ in base ⍺).    Optimized for ⍺∊2 10 only.
⍝H           ⍺ ↑ BI  ⍵          decimal shift of ⍵ left  by ⍺ digits. Special code.    May be slower than [⍺ ×BI 10*BI  ⍵]
⍝H           ⍺ ↓ BI  ⍵          decimal shift of ⍵ right by ⍺ digits. Special code.    Ditto.
⍝H           ⍺ ⌽ BI  ⍵          binary shift of ⍵ to left (⍺≥0) or right (⍺≤0) by ⍺ digits [same as ⍺ ×BI 2*BII  ⍵]
⍝H           ⍺ | BI  ⍵          remainder ⍺ | BI  ⍵
⍝H                              ALIAS:  BI  ⍵ ('MOD' BI) ⍺  or   BI  ⍵ |⍨BI ⍺   (or its equiv:  BI  ⍵ |BI⍨ ⍺)
⍝H           ⍺ ⌈ BI  ⍵          max
⍝H           ⍺ ⌊ BI  ⍵          min
⍝H           ⍺ ∨ BI  ⍵          Gcd (not used for: or).  Returns Bigint.
⍝H           ⍺ ∧ BI  ⍵          Lcm (not used for: and). Returns Bigint.
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
