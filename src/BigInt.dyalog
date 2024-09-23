:NAMESPACE BigInt
⍝  ∘ Built on dfns::nats, restructured for signed integers. 
⍝  ∘ Much faster than dfns::big, esp. as N (integer sizes) grows.
⍝  ∘ Slower than nats for smaller N, with rough parity at N×N for N=1000.
⍝  ∘ The operator BI is the most general utility. It returns big integers in an external (string) format.
⍝  ∘ The operator BII is the same as BI, except for returning big integers in a more efficient internal format. 
⍝    > Both allow arguments in either the external (string) or internal formats.
⍝  ∘ The terms <bi> and <bii> are used below:
⍝    > bi:  a big integer in any external form (string, number, bii)
⍝    > bii: a big integer in internal format (of depth ¯2, shape 2: 
⍝      (sign:<scalar ¯1 0 1> data:<int vector>)
⍝ 
⍝  FOR HELP information, see :SECTION HELP or call BigInt.BI_HELP.

:Section PREAMBLE
  ⍝ Set PROMOTE←1 to allow BI, BII, BIM to be promoted one namespace above BigInt
    PROMOTE← 1 
  ⍝ Set DEBUG←1 to disable signal trapping.
    DEBUG←0                          
    ⎕IO ⎕ML ⎕PP ⎕CT ⎕DCT←  0 1 34 0 0  
  ⍝ ⎕FR as set here is used below to set constant OFL (overflow) used in multiplication.  
  ⍝ It can be either 645 or 1287, but is typically ~20% faster with 645.  
    ⎕FR← 645                
:EndSection PREAMBLE

:Section Constants 
  ⍝+------------------------------------------------------------------------------+⍝
  ⍝+-- BI INITIALIZATIONS                            BI INITIALIZATIONS         --+⍝
  ⍝-------------------------------------------------------------------------------+⍝

  ⍝ Key Bigint constants...
  ⍝ There's little reason to play with these; perhaps in the future different numbers will have performance impact.
    NRX2←         20                                     ⍝ Num bits in a "limb"
    NRX10←        ⌊10⍟2*NRX2                             ⍝ Max num of Dec digits in a limb
    NRX2BASE←     NRX2⍴2                                 ⍝ Encode/decode binary base
    RX10BASE←     NRX10⍴10                               ⍝ Encode/decode decimal base
    RX10←         10*NRX10                               ⍝ Actual base for each limb (each limb ⍵ < RX10)
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
  
  ⍝ Error messages. See dfn <Er11> above.
    eIMPORT←  'Object not a valid BigInt: '
    eDIVZERO← 'Division by zero'
    eBADRAND← 'Arg to Roll (?) must be integer >0'
    eFACTOR←  'Arg to factorial (!) must be ≥ 0'
    eBADRANGE←'BigInt outside dynamic range to be approximated in APL (exponent ≥ 1E6145)'
    eLOG←     'Log of a non-positive BigInteger is undefined'
    eMUL10←   'Right argument must be a small APL integer ⍵<',⍕RX10
    eROOT←    'Base (⍺) for Root must be small non-zero integer: ⍺<',⍕RX10
    eSUB←     'SubU LOGIC: unsigned subtraction "⍺-⍵" requires ⍺≥⍵'
:EndSection Constants 

:Section Main Fns 
  ⍝ BI:   res@bi←  [⍺@bi] op BI ⍵@bi
  ⍝  Args: One (for monadic op codes) or two (dyadic) bi's.
  ⍝  Returns a bi for most op codes.
  ⍝  Returns a pair of bi's for op code 'DivRem'.
  ⍝  Returns a boolean for boolean ops dyadic <≤=≥> and ≢
  ⍝  Returns an integer for monadic ≢.
    BI← { ⍺←⊢ ⋄ dyad←2=⎕NC'⍺'  
    1000:: ⎕SIGNAL/ 'BI Interrupted' 1006
    0/⍨ ~DEBUG::    ⎕SIGNAL  ⊂⎕DMX.{'EM' 'EN' 'Message' ,⍥⊂¨ ('BI ',EM) EN Message}0  
        oper im ex← ⍺⍺ map.Sel dyad     
        r← ⍺ (oper {dyad: ⍺ ⍺⍺⍥(Import⍣im)⊢ ⍵ ⋄ ⍺⍺ Import⍣im⊢ ⍵} ) ⍵
        ex=1: Export r ⋄ ex=0: r ⋄ Export¨ r      ⍝ DivRem returns 2 biis 
    }
  ⍝ BII:   res@bii←  [⍺@bi] op BI ⍵@bi 
  ⍝  Like BI above, but leaves bigint results in internal bii form, rather than bi form.
  ⍝  Other results are as described above.
    BII←{ ⍺←⊢ ⋄ dyad←2=⎕NC'⍺'   
    1000:: ⎕SIGNAL/ 'BII Interrupted' 1006
    0/⍨ ~DEBUG:    ⎕SIGNAL  ⊂⎕DMX.{'EM' 'EN' 'Message' ,⍥⊂¨ ('BII ',EM) EN Message}0 
      oper im ex← ⍺⍺ map.Sel dyad            
      ⍺ (oper{ dyad: ⍺ ⍺⍺⍥(Import⍣im) ⍵ ⋄ ⍺⍺ Import⍣im⊢ ⍵}) ⍵
    }

  ⍝  BIM:   res@bi← x@bi (op BIM mod@bi) y@bi, equiv. to: Mod |BI x (fn BII) y.
  ⍝    Perform operation (x op y) modulo <mod> as efficiently as possible, returning the result.
  ⍝    More efficient for functions times (×) and exponent (*) and avoids some WS FULL.
  ⍝    Otherwise, identical to the multi-call version.  
  ⍝    BIM is dyadic only. 
    BIM←{ 
      1006:: ⎕SIGNAL/ 'BIM Interrupted' 1006
      0/⍨ ~DEBUG::    ⎕SIGNAL  ⊂⎕DMX.{'EM' 'EN' 'Message' ,⍥⊂¨ ('BIM: ',EM) EN Message}0 
          x y divisor← Import¨ ⍺ ⍵ ⍵⍵ 
          opc← ⍺⍺ map.GetOpCode ⍬
      opc≡ '×': Export x (divisor ModMul) y 
      opc≡ '*': Export x (divisor ModPow) y 
                Export divisor |BII x (opc BII) y 
    }

  ⍝ Help:  Shows help documentation for BigInt calls.
  ⍝    null← BigInt.Help
    ∇ {null}← Help; h; ⎕PW
      ⎕PW←120 
      null← (⎕ED⍠'ReadOnly' 1) 'h'⊣ h← '^\h*⍝H(.*)$'  ⎕S '\1' ⊢ ⎕SRC ⎕THIS 
    ∇ 
    ⎕FX 'Help' ⎕R 'HELP'⊣⎕NR 'Help'
    ⎕←'For help: ',(⍕⎕THIS),'.Help' 
 
   ∇ proFlg← PromoteIf proFlg ;where; bim  
    :IF proFlg 
        where← ##
      ⍝ Workaround Dyalog syntactic folly for operators...
        bim← 'BIM←{ 0/⍨~⎕THIS.DEBUG:: ⎕SIGNAL/⎕DMX.(EM EN) ⋄ ⍺←⊢ ⋄ ⍺ (⍺⍺ ⎕THIS.BIM ⍵⍵) ⍵}' 
        where⍎bim '⎕THIS' ⎕R (⍕⎕THIS)⊢ bim 
        where.BI←  ⎕THIS.BI 
        where.BII← ⎕THIS.BII
    :Else 
        where← ⎕THIS   
    :EndIf  
    ⎕←'Created: ',∊' ',¨ (⊂⍕where),¨'.',¨ 'BI' 'BII' 'BIM' 
    ∇
    PromoteIf PROMOTE=1
:EndSection Main Fns 

:Section Importing and Exporting 
    ⍝ =================================================
    ⍝ Import - Import to bii (internal) format...
    ⍝ =================================================
    ⍝  Import ⍵
    ⍝      from: 1) a BigInteger string,
    ⍝            2) a small APL integer, or
    ⍝            3) an internal-format BigInteger (depth ¯2), passed through unchanged.
    ⍝      to:   internal format (bii) BigIntegers  ⍵'
    ⍝            of the form sign (data), where sign is a scalar 1, 0, ¯1; data is an integer vector.
    ⍝ Let Type=80|⎕DR ⍵  and Depth=|⍵          
    ⍝  Evaluate       Class     Action: Import as    Notes                
    ⍝ ---------------+----------------------------------------------------------------------- 
    ⍝  Depth ¯2       bii         (no change)       Internal format. Fast.                                  
    ⍝  Type   0       numeric str  ImpStr ⍵         Typical user input '¯12345'
    ⍝  Type   3       APL integer  ImpAplInt ⍵      ¯12345   
    ⍝  Type   5, 7    APL Float    ImpFloat ⍵       Floats representing: 
    ⍝                                  i)  very large ints 123E100 (123+50 zeroes), ⍵ ≤ 1E6144     
    ⍝                                  ii) for *BI only, root exponents: ÷2 (sqrt), ÷3 (cube root), etc. 
    ⍝  Returns an internal bigint (type bii):
    ⍝     sgn (int vector), where
    ⍝         ∘ sgn∊ ¯1 (neg) 0 (zero) 1 (pos) number.
    ⍝         ∘ int vector: a vector of 1 or more unsigned integers <RX10 (,0 if sgn=0).
    Import←{                    
        ¯2=≡⍵:    ⍵             ⍝ Fast: bii (depth: ¯2) are of form:  [1|0|¯1] [int vector]
        type←80|⎕DR ⍵
        type=0:   ImpStr ⍵    ⋄ type=3: ImpAplInt ⍵ ⋄ 
        type∊5 7: ImpFloat  ⍵ ⋄ Er11 eIMPORT,⍕⍵
    }
    Imp← Import 
    ⍝ ImpAplInt:    ∇ ⍵:I[1]
    ⍝ Import a small APL (native) integer into a bi.
    ⍝          ⍵ MUST Be an APL native (1-item) integer ⎕DR type 83 163 323.
    ImpAplInt←{
        1≠≢⍵:  Er11 eIMPORT,⍕⍵           ⍝ singleton only...
        RX10> u←,|⍵: (×⍵)u               ⍝ Small integer
        (×⍵)(chkZ RX10⊥⍣¯1⊣u)            ⍝ Integer
    }
    ⍝ ImpFloat: Convert an APL integer into a bi
    ⍝ Converts simple APL native numbers, as well as those with large exponents, e.g. of form:
    ⍝     1.23E100 into a string '123000...000' (100 0's), ¯1.234E1000 → '¯1234000...000'
    ⍝ These must be in the range of decimal integers (up to +/- 1E6144).
    ⍝ If not, you must use big integer strings of any length (exponents are disallowed in BigInt strings).
    ⍝ Used in BII, BI automatically, but ImpFloat can be called by the user as well.
      ImpFloat←{⎕FR←1287                 ⍝ 1287: to handle large exponents
        (1=≢⍵)∧(⍵=⌊⍵): (×⍵)(chkZ RX10⊥⍣¯1⊣|⍵)
        Er11 eIMPORT,⍕⍵
    }
    ⍝ ImpStr: Convert a bi in string format into a bii
    ⍝  [nullStrOk←0]  ImpStr ⍵:S[≥1]   
    ⍝    nullStrOk=0: (⍵ must have at least one digit, possibly a 0).
    ⍝    nullStrOk=1: ⍵ has 0 digits? Return ZERO_BI.
    ⍝ Note: by default, we don't allow spaces, to avoid confusion with multiple BIs. 
    ⍝ By default, _ is used as a spacer on input and in "pretty" mode (1⍕...).
    NEG_SIGNS SPACERS← '-¯' '_' 
    ImpStr←{ ⍺←0 
        sgn← NEG_SIGNS∊⍨ 1↑⍵                 ⍝ Remove opt'l negative sign(s)
        str← SPACERS~⍨ ⍵↓⍨ sgn               ⍝ Remove "spacer" char(s)
      0= ≢str:   {Er11 eIMPORT,'[null string]'}⍣(⍺=0)⊢ ZERO_BI 
      10∊ dig← ⎕D⍳ str: Er11 eIMPORT,⍵       ⍝ str must include only chars in ⎕D and at least one.
        ZRunChk (sgn⊃1 ¯1),⊂ rep dig         ⍝ Normalize (remove leading 0s). If d is zero, return ZERO_BI.
    } 
  ⍝ ---------------------------------------------------------------------
  ⍝ Export/Exp: EXPORT a SCALAR bii to external canonical bi string.
  ⍝ ---------------------------------------------------------------------
  ⍝    r:BIc←  ∇ ⍵:bii
    Export←{ 
        ('¯'/⍨ ¯1= ⊃⍵), ⎕D[ dlzRun, ⍉RX10BASE⊤| ⊃⌽⍵ ] 
    }
    Exp←Export 
  ⍝ BI2Apl:    Convert valid bii ⍵ to APL integer, with error if Exponent too large.
    BI2Apl←{ 0:: Er11 eBADRANGE ⋄ ⎕FR←1287 ⋄  ⍎Exp Imp ⍵}
   
:EndSection Importing and Exporting
⍝ --------------------------------------------------------------------------------------------------


:Section Monadic Operations/Functions
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
          (sw w)← ⍵
          (-sw)w
      }
    ⍝ Sig[num] 
      Sig←{                                ⍝ ×
          (sw w)←⍵
          sw(|sw)                          ⍝ ==> bii: ¯1 0 1
      }
    ⍝ Abs: absolute value
      Abs←{                                ⍝ |
          (sw w)←⍵
          (|sw)w
      }
    ⍝ Inc[rement]:                         ⍝ ⍵+1
      Inc←{
          (sw w)←⍵
        sw=0: ONE_BI                       ⍝ ⍵=0? Return 1.
        sw=¯1: ZRunChk sw(⊃⌽Dec 1 w)       ⍝ ⍵<0? Inc ⍵ becomes -(Dec |⍵). ZRunChk handles 0.
          î←1+⊃⌽w                          ⍝ trial increment (most likely path)
        RX10>î: sw w⊣(⊃⌽w)←î               ⍝ No overflow? Increment and we're done!
          sw w Add ONE_BI                  ⍝ Otherwise, do long way.
      }
    ⍝ Dec[rement]:                         ⍝ ⍵-1
      Dec←{
          (sw w)←⍵
        sw=0: MINUS1_BI                    ⍝ ⍵ is zero? Return ¯1
        sw=¯1: ZRunChk sw(⊃⌽Inc 1 w)       ⍝ ⍵<0? Dec ⍵  becomes  -(Inc |⍵). ZRunChk handles 0.
                                           ⍝ If the last digit of w>0, w-1 can't underflow.
        0≠⊃⌽w: ZRunChk sw w⊣(⊃⌽w)-←1       ⍝ No underflow?  Decrement and we're done!
          sw w Sub ONE_BI                  ⍝ Otherwise, do long way.
      }
   
    ⍝ Fact: compute factorial
    ⍝       r@bi←  Fact ⍵@bi
    ⍝ We allow ⍵ to be of any size, but numbers larger than NRX10 are impractical.
    ⍝ We deal with 3 cases:
    ⍝    ⍵ ≤ 31:    We let APL calculate, with ⎕PP←34.   Fast.
    ⍝    ⍵ ≤ NRX10:   We calculate r as a BigInt, while counting down ⍵ as an APL integer. Moderately fast.
    ⍝    Otherwise: We calculate entirely using BigInts for r and ⍵. Slowwwwww.
      Fact←{                                ⍝ !⍵
          (sw w)←⍵
        sw=0: ONE_BI                       ⍝ !0
        sw=¯1: Er11 eFACTOR                ⍝ ⍵<0
          FactBig←{⍺←1
            1=≢⍵: ⍺ FactSmall ⍵            ⍝ Skip to FactSmall when ≢⍵ is 1 limb.
              (⍺ MulU ⍵)∇ ⊃⌽Dec 1 ⍵
          }
          FactSmall←{
            ⍵≤1:1 ⍺
              (⍺ MulU ⍵)∇ ⍵-1
          }
          1 FactBig w
      }
    ⍝ Roll ⍵: Compute a random number between 0 and ⍵-1, given ⍵>0.
    ⍝    r:bii←  ∇ ⍵:bii   ⍵>0.
    ⍝ Roll 0 is the same as Roll 1E100.
      Roll←{
          (sw w)←⍵
          ⎕FR ⎕PP← 645 34                          
        sw=0: ∇ Import 1E100 
        sw≠1: Er11 eBADRAND
          rand← len⍴ ⊃,/¯17↑∘⍕¨?1E17⍴⍨ ⌈17÷⍨ len← ≢Exp sw w  
          rand← '0'@(=∘' ')⊢ rand  
          i← ImpStr rand                          ⍝ result is then truncated to exactly count digits   
        '0'=⊃rand: i                              ⍝ If leading 0, guaranteed (ImpStr r) < ⍵.
          ⍵ Rem i                                 ⍝ Otherwise, compute remainder Rem r: 0 ≤ r < ⍵.
      }

    ⍝ BI2Str: [0 [0] [0]] BI2Str bii 
    ⍝    Convert bi to string. ⍺ defaults to 0 0 0
    ⍝      ⍺[0]=1: replace ¯ by - .  ⍺=0 (default): don't.
    ⍝      ⍺[1]>0: place underscores every ⍺[1] digits starting at the right.
    ⍝      ⍺[3]>0: Convert the number to base ⍺[3]. (Default is 10).
      BI2Str←{ 
          ⍺←0 0 10 ⋄ hi2lo sep base← 3↑⍺   
          base← base 10⊃⍨ base=0
          arg← base ExportNewBase⊢ Import⍣ (base≠10)⊢ ⍵
        0:: Er11 eIMPORT,⍕⍵
          str← sep{
            0=⍺: ⍵ ⋄ (⍺>0)∧⍺=⌊⍺: ('(\w)(?=(\w{',(⍕⍺),'})+$)') ⎕R '\1_'⊣ ⍵
              Er11 'Invalid specification (⍺) to BI2Str (⍕)' 
          } (Exp Imp)⍣(' '≠⊃0⍴arg)⊢ arg  
        0= hi2lo: str 
        '¯'≡⊃str: str⊣ (⊃str)←'-' ⋄ str  
      } 
    ⍝ NLimbs-- how many "limbs," i.e. integers in the data portion of the bignum
      NLimbs←{
        ≢ ⊃⌽ ⍵ 
      }
  
  ⍝ ExportNewBase: Base Output Conversion, including to bits.
  ⍝ Digits for base output conversation go up to base 62, using 0..9,a..z,A..Z
    ExportNewBase←{ alignBits←0  
        ⎕IO←0 ⋄ ⍺←16 ⋄ base←⍺   
        10= base: ⍵ 
        (⍺<2)∨⍺>≢DIGITS_EXPANDED: 11 ⎕SIGNAL⍨'BI ⍕: base (⍺) must be between 2 and ',⍕≢DIGITS_EXPANDED
        (sw w)← ⍵
        dig←{ ⍺←''
            ZERO_D≡⍵: ⍺ '0'⊃⍨0=≢⍺   
            dec rem←⍵ DivU base
            dec ∇⍨ DIGITS_EXPANDED[rem],⍺
        }w
        2≠ base: dig,⍨'¯'/⍨ sw=¯1 
      ⍝ If alignBits, mantissa bits are multiples of NRX2 long, adding sign bit on left.
        (⍕sw=¯1),alignBits{~⍺: ⍵  ⋄ ⍵↑⍨-NRX2×⌈NRX2÷⍨≢⍵ }dig 
    }
  ⍝ See ExportNewBase
    DIGITS_EXPANDED←⎕D,(⎕C ⎕A),⎕A 
    ⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

    ⍝ Root: A fast integer nth Root.
    ⍝ Syntax:    x@bii←  nth@BIext<RX10 ∇ N@BIext
    ⍝            x←  nth Root N  ==>   x←  ⌊N *÷nth
    ⍝   nth: a small, positive integer (<RX10); default 2 (for Sqrt).
    ⍝   N:   any BIext
    ⍝   x:   the nth Root as an internal big integer.
    ⍝   ∘ Uses Fredrick Johanssen's algorithm with optimization for APL integers.
    ⍝   ∘ Estimator based on guesstimate for Sqrt N, no matter what Root.
    ⍝     (Better than using N).
    ⍝   ∘ As fast for Sqrt as a "custom" version.
    ⍝   ∘ If N is small, calculate directly via APL.
    ⍝ x:bii←  nth:small_(bii|BIext) ∇ N:(bii|BIext)>0
      Root←{
        ⍝ Check radix in  N*÷radix
        ⍝ We work with bigInts here for convenience. Could be done unsigned...
          ⍺←TWO_BI                     ⍝ Sqrt by default... 
          sgn rdx←  ⍺
        sgn=0: Er11 eROOT              ⍝ 0th root undefined
        1<≢rdx: Er11 eROOT             ⍝ require a small, single limb, radix                  
        sgn<0: 0                       ⍝  ⌊N*÷nth ≡ 0, if nth<0 (nth a small int)
        ⍝ Check ⍵ => N. Domain: non-negative integer
          sN N← ⍵                
        0=sN: sN N                     ⍝ 0: Root(0) <=> 0
        ¯1=sN: Er11 eROOT              ⍝ Negative: error
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

:EndSection Monadic Functions/Operations
⍝ --------------------------------------------------------------------------------------------------

:Section Dyadic Functions/Operations

  ⍝ dyad:    compute all supported dyadic functions
      Add←{
          (sa a)(sw w)← ⍺ ⍵
        sa=0: sw w                             ⍝ optim: ⍺+0 → ⍺
        sw=0: sa a                             ⍝ optim: 0+⍵ → ⍵
        sa=sw: sa(ndnZ 0,+⌿a mix w)            ⍝ 5 + 10 or ¯5 + ¯10
        sa<0:sw w Sub 1 a                      ⍝ Use unsigned vals: ¯10 +   5 → 5 - 10
          sa a Sub 1 w                         ⍝ Use unsigned vals:   5 + ¯10 → 5 - 10
      }
      Sub←{
          (sa a)(sw w)← ⍺ ⍵
        sw=0: sa a                             ⍝ optim: ⍺-0 → ⍺
        sa=0: (-sw)w                           ⍝ optim: 0-⍵ → -⍵
        sa≠sw: sa(ndnZ 0,+⌿a mix w)            ⍝ 5-¯3 → 5+3 ; ¯5-3 → -(5+3)
        <cmp a mix w: (-sw)(nupZ-⌿dck w mix a) ⍝ ⍺<⍵: 3-5 →  -(5-3)
          sa(nupZ-⌿dck a mix w)                ⍝ a≥w: exec     5-3
      }

    ⍝ See Mul, Div here.
      Mul←{
          (sa a)(sw w)←  ⍺ ⍵
        0∊sa,sw: ZERO_BI
        TWO_D≡a: (sa×sw)(AddU⍨w) 
        TWO_D≡w: (sa×sw)(AddU⍨a)
        ONE_D≡a: (sa×sw)w        
        ONE_D≡w: (sa×sw)a
          (sa×sw)(a MulU w)
      }
    ⍝ ExactPow10U: Helper Fn in Div. (Not enabled in Mul)
    ⍝   ⍵ is 10 or multiples of 10. 
    ⍝   Returns # of decimal digits to shift to achieve a multiply or divide by ⍵.
        ExactPow10U← {1≠≢⍵: 0 ⋄ 0≠ 10|⍵: 0 ⋄ 10⍟⍵ }
    ⍝ Div: For special cases (except ⍵ multiples of 10), see DivU.
      Div←{ 
          (sa a)(sw w)← ⍺ ⍵
        sw=0: Er11 eDIVZERO              ⍝ Don't allow division by 0.
      ⍝ Some clear advantage to this optimization...
      ⍝ (1 ImpStr...) ensures empty string is allowed and returns 0.
        0≠p10← -ExactPow10U w: 1 ImpStr p10↓ Exp (sa×sw) a 
          ZChk(sa×sw)(⊃a DivU w)
      }
    ⍝ DivRem: Divide, returning both quotient and remainder.
    ⍝ Faster when both quotient and remainder are needed. 
    ⍝ (⍺ DivRem ⍵) equivalent to: 
    ⍝    (⍺ Div ⍵) (⍺ Mod ⍵)
    ⍝ For other special cases, see DivU.
      DivRem←{
          (sa a)(sw w)←  ⍺ ⍵
        sw=0: Er11 eDIVZERO 
      ⍝ Some clear advantage to this optimization...
      ⍝ (1 ImpStr¨...) ensures empty strings are allowed and return 0.
        0≠p10← -ExactPow10U w: 1 ImpStr¨ p10(↓,⍥⊂↑) Exp (sa×sw) a 
          ZChk¨ (sa 1× sw),¨ a DivU w     ⍝ return: (quotient remainder)
      }
 
    ⍝ ⍺ Pow ⍵:
    ⍝   I. General case, i.e. ⍵ not a special case as in II below  
    ⍝   ∘ ⍵ not a special case                          Calc  ⍺ * ⍵.
    ⍝   II. Special cases to handle integral roots (2: sqrt, 3: cube root, etc.)
    ⍝   ∘ ⍵ a number n in 0< n < 1.                     Calc. (⌊÷n) Root ⍺
    ⍝   ∘ ⍵ a string representing a number n in 0<n<1.  Calc. (⌊÷n) Root ⍺
    ⍝   ∘ ⍵ a string of form                            Calc.    n  Root ⍺
    ⍝     ∘ '÷NN', where n←⍎NN a valid int n≥1          
    ⍝     where nn is an APL (single limb) integer).
    ⍝   ∘ Otherwise, Pow will generate an error.
    ⍝
    ⍝ RootZ: Returns 0 unless it sees a special case right arg (see II above).
      RootZ←{  
          FZ←{ (⍵>0)∧ ⍵≤1: ⌊÷⍵ ⋄ 0} ⋄ IZ←{⍵=⌊⍵: ⍵ ⋄ 0} ⋄ S2N← ⊃⊃∘⌽⍤⎕VFI  
          0> ≡⍵:0 ⋄ 0= ⊃0⍴⍵: FZ ⍵ ⋄ '÷'≠ 1↑⍵: FZ S2N ⍵ ⋄ IZ S2N 1↓⍵ 
      } 
      Pow←{                                  
        0≠rt←RootZ ⍵: rt Root Imp ⍺ ⍝ Root? Handle here.
        (sa a)(sw w)← Imp¨ ⍺ ⍵
        ∨/sa sw=0 ¯1: ZERO_BI      ⍝ r←⍺*¯⍵ is 0≤r<1, so truncates to 0.
          p←a PowU w               ⍝ Special cases ⍺*2, ⍺*1, ⍺*0 handled in PowU.
        sa= 1: 1 p               
        0=2|⊃⌽w:1 p ⋄ ¯1 p         ⍝ sa=¯1, so result is pos. if ⍵ is even.
      }
    ⍝ Rem: Remainder/residue.      ⍝ Use APL's definition.
      Rem←{                        
          (sa a)(sw w)← ⍺ ⍵
        sw=0:ZERO_BI
        sa=0:sw w
          r←,a RemU w              ⍝ RemU is fast if a>w
        sa=sw: ZRunChk sa r        ⍝ sa=sw:       return (R)       R←sa r
        ZERO_D≡r: ZERO_BI          ⍝ sa≠sw ∧ R≡0: return 0
          ZRunChk sa a Sub sa r    ⍝ sa≠sw:       return (A - R')  A←sa a; R'←sa r
      }
    ⍝ Mul2Exp:  Shift ⍺:BIext left or right by ⍵:Int binary digits
    ⍝ Very slow! *** NOT USED ***
    ⍝  r:bii←  ⍺:bii   ∇  ⍵:aplInt
    ⍝     Note: ⍵ must be an APL integer (<RX10).
    ⍝  -  If ⍵>0: Shift ⍺ left by ⍵ binary digits
    ⍝  -  If ⍵<0: Shift ⍺ rght by ⍵ binary digits
    ⍝  -  If ⍵=0: then ⍺ will be unchanged
    ⍝ Mul2Exp←{
    ⍝     (sa a)(sw w)← ⍺ ⍵
    ⍝   1≠≢w: Er11 eMUL10                         ⍝ ⍵ must be small integer.
    ⍝   sa=0: 0 ZERO_D                            ⍝ ⍺ is zero: return 0.
    ⍝   sw=0: sa a                                ⍝ ⍵ is zero: ⍺ stays as is.
    ⍝     pow2←1 (,2*w)
    ⍝   sw>0: sa a Mul pow2 ⋄ sa a Div pow2
    ⍝ }

  ⍝ Mul10Exp: Shift ⍺:BIext left or right by ⍵:Int decimal digits.
  ⍝      Converts ⍺ to BIc, since shifts are a matter of appending '0' or removing char digits from right.
  ⍝ *** SLOW: NOT USED!
  ⍝  r:bii←  ⍺:bii   ∇  ⍵:Int
  ⍝     Note: ⍵ must be an APL  big integer, BigIntA (<RX10).
  ⍝  -  If ⍵>0: Shift ⍺ left by ⍵-decimal digits
  ⍝  -  If ⍵<0: Shift ⍺ rght by ⍵ decimal digits
  ⍝  -  If ⍵=0: then ⍺ will be unchanged
  ⍝  WARNING: THIS APPEARS TO RUN ABOUT 80% SLOWER THAN A SIMPLE MULTIPLY FOR MEDIUM AND LONG ⍺, unless ⍵ is long, e.g. 1000 digits.
  ⍝           Div uses the "better" algorithm ExactPow10U
  ⍝ Mul10Exp←{
  ⍝     (sa a)(sw w)← ⍺ ⍵
  ⍝     1≠≢w:Er11 eMUL10                         ⍝ ⍵ must be small integer.
  ⍝     sa=0:ZERO_BI                             ⍝ ⍺ is zero: return 0.
  ⍝     sw=0:sa a                                ⍝ ⍵ is zero: sa a returned.
  ⍝     ustr←Exp 1 a                             ⍝ ⍺ as unsigned string.
  ⍝     ss←'¯'/⍨sa=¯1                            ⍝ sign as string
  ⍝     sw=1: ImpStr ss,ustr,w⍴'0'               ⍝ sw= 1? Shift left by appending zeroes.
  ⍝     ustr↓⍨←-w                                ⍝ sw=¯1? Shift right by Dec truncation
  ⍝     0=≢ustr:ZERO_BI                          ⍝ No chars left? It's a zero
  ⍝     ImpStr ss,ustr                           ⍝ Return in internal form...
  ⍝ }
  
  ⍝ ∨ Greatest Common Divisor
    Gcd←{
      (sa a)(sw w)← ⍺ ⍵
      1(a GcdU w)
    }
  ⍝ ∧ Least/Lowest Common Multiple
    Lcm←{
      (sa a)(sw w)← ⍺ ⍵
      (sa×sw)(a LcmU w)
    }
  ⍝ ⌈ Max 
    Max← { a w← ⍺ ⍵ 
      w ≥Bool a: w ⋄ a 
    }
  ⍝ ⌊ Min 
    Min← { a w← ⍺ ⍵ 
      w ≥Bool a: a ⋄ w 
    }

  ⍝ Log10: L← Log10 N
  ⍝ Log:   L←  B Log N
  ⍝ Big Integer logarithm base <B> of big integer <N>. B defaults to (base) 10.
  ⍝ Returns <L> in BI internal format.
    Log10←{ 1, ⊂¯1+≢Exp ⍵ } 
    Log←{
        ⍺←TEN_BI ⋄ B N← ⍺ ⍵
      0≥⊃N: Er11 eLOG                     ⍝ N ≤ 0
      TEN_BI≡B: 1, ⊂¯1+≢Exp N
        ZERO_BI { ⍵ Le ONE_BI: ⍺ ⋄ (Inc ⍺)∇ ⍵ Div B } N  
    }
  ⍝ ≡ This is the same as =, except that Import doesn't force normalisation 
  ⍝   of arguments (to be presented to Ident) that are already big integers...
  ⍝   Import will of course force any non-bii arg on input to a normalised form.
    Ident←{
      ⍺≡ ⍵
    }
  ⍝ ≢ This is the same as ≠, except that Import doesn't force normalisation 
  ⍝   of arguments (to be presented to Differ) that are already big integers...
  ⍝   Import will of course force any non-bii arg on input to a normalised form.
    Differ←{
      ⍺≢ ⍵ 
    }
  :Section Boolean Operations
    ⍝ Bool: Execute a boolean operation.  ⍺ <Bool ⍵
    ⍝       Note: Bool assumes ⍺ and ⍵ are already in bii format.
    ⍝       This is for use in other fns like ⌈ Max and ⌊ Min. 
      Bool←{
          (sa a)(sw w)← ⍺ ⍵  
        0∊sa sw: sa ⍺⍺ sw         ⍝ ⍺, ⍵, or both are 0
        sa≠sw: sa ⍺⍺ sw           ⍝ ⍺, ⍵ different signs
        sa=¯1: ⍺⍺ cmp w mix a     ⍝ ⍺, ⍵ both Neg
          ⍺⍺ cmp a mix w          ⍝ ⍺, ⍵ both Pos
      }
      Lt← <Bool ⋄ Le← ≤Bool ⋄ Eq← =Bool 
      Gt← >Bool ⋄ Ge← ≥Bool ⋄ Ne← ≠Bool 
  :EndSection Boolean Operations  
:EndSection Dyadic Operators/Functions

:Section Special Functions/Operations (More than 2 Args)
  ⍝ ModMul:  modulo m of product a×b
  ⍝ A faster method than (m|a×b), when a, b are large and m is substantially smaller.
  ⍝ r←  a (m ModMul) b   →→→    r←  m | a × b
  ⍝ bii←  ⍺:bii ∇ ⍵:bii m:bii
  ⍝ Naive method: (m|a×b)
  ⍝      If a,b have 1000 digits each and m is smaller, the m| operates on 2000 digits.
  ⍝ Better method: (m | (m|a)×(m|b)).
  ⍝      Here, the multiply is on len(m) digits, and the final m operates on 2×len(m).
  ⍝ For large a b of length 5000 Dec digits or more, this alg can be 2ce the speed (13 sec vs 26).
  ⍝ It is nominally faster at lengths around 75 digits.
  ⍝ Only for smaller a and b, the cost of 3 modulos instead of 1 predominates.
    ModMul←{
        a b m←⍺ ⍵ ⍺⍺  
        m Rem(m Rem a)Mul(m Rem b)
    }
  ⍝ ModPow: a (m ModPow) n, a faster m|a*n (from article by Roger Hui Aug 2020 ) 
    ∇ r←a(m ModPow)n
      ;s ;mModMul 
      a n m← a n m  
      r←ONE_BI ⋄ s←m Rem a
      mModMul←m ModMul 
      :While ZERO_BI Lt n
          :If ONE_BI Eq TWO_BI Rem n               ⍝ r←m| r×s
            r mModMul← s 
          :EndIf   
          s mModMul← s                             ⍝ s←m| s×s
          n Div← TWO_BI
      :EndWhile
    ∇
:EndSection Special Functions/Operations (More than 2 Args)

:Section Unsigned Utility Math Routines
  ⍝ These are the workhorses of bigInt; most are from dfns:nats (handling unsigned bigInts).
  ⍝ Note: ⍺ and ⍵ are guaranteed by BII and BI to be vectors, but not
  ⍝       by internal functions or if called directly.
  ⍝       So tests for 2, 1, 0 (TWO_D etc) use ravel:  (TWO_D≡,⍺)

  ⍝ AddU:   ⍺ + ⍵
  ⍝ We use dlzRun in case ⍺ or ⍵ have multiple leading 0s. If not, use ndnZ
    AddU←{
        dlzRun ndn 0,+⌿⍺ mix ⍵    
    }
  ⍝ SubU:  ⍺ - ⍵   Since unsigned, if ⍵>⍺, there are two options:
  ⍝        [1] Render as 0
  ⍝        [2] signal an error...
    SubU←{
        <cmp ⍺ mix ⍵:Er11 eSUB                  ⍝ [opt 2] 3-5 →  -(5-3)
        dlzRun nup-⌿dck ⍺ mix ⍵                 ⍝ a≥w: 5-3 → +(5-3). ⍺<⍵: 0 [opt 1]
    }
  ⍝ MulU:  multiply ⍺ × ⍵  for unsigned Big Integer (BigIntU) ⍺ and ⍵
  ⍝ r:bii←  ⍺:bii ∇ ⍵:bii
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
            m n←,↑≢¨⍺ ⍵                         ⍝ numbers of limbs (RX10-digits) in each arg.
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
      ⍝ (1≠⍴⍴⍵)∨1≠⍴⍴⍺:  Er11 'PowU: ⍺ and ⍵ must be vectors'
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
  ⍝   r:bii[2]←  ⍺:bii ∇ ⍵:bii
    DivU←{     
        a w←dlzRun¨⍺ ⍵
        a≡w:  ONE_D ZERO_D                  ⍝ ⍺≡⍵: Quot=1, Rem=0. including ⍺÷⍵ is 0÷0.
        ZERO_D≡w: Er11 eDIVZERO            ⍝ If ⍵=0 (exc. 0÷0), then ERROR!, for all ⍺, except ⍺=0.
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
        TWO_D≡,⍺:2|⊃⌽⍵                      ⍝ fast (short-circuit) path for ⍺=2 (2|⍵). Check only last "limb".
        <cmp ⍵ mix ⍺:⍵                      ⍝ ⍵ < ⍺? remainder is ⍵
        ⊃⌽⍵ DivU ⍺                          ⍝ Otherwise, do full divide and return 2nd element, the remainder.
  }
:Endsection Unsigned Utility Math Routines

:Section Service Functions
⍝ ZChk ⍵:bii  If ⊃⌽⍵ is zero, ensure sign is 0. Otherwise, pass ⍵ as is.
  ZChk←{ZERO_D≡ ⊃⌽⍵: ZERO_BI ⋄ ⍵}
⍝ ZRunChk ⍵:bi  
⍝    If ⊃⌽⍵ is zero after removing leading 0's, return ZERO_BI;
⍝    Otherwise return ⍵ w/o leading zeroes.
  ZRunChk←{ZERO_D≡ w← dlzRun ⊃⌽⍵: ZERO_BI ⋄ (⊃⍵) w}

⍝-----------------------------------------------------------------------------------+
⍝ Note: These Service Functions are                                                 +
⍝       ∘ directly from (or tweaks of) dfns::nats,                                  +
⍝       ∘ in lower camel case, per the originals                                    +
⍝-----------------------------------------------------------------------------------+
⍝ These routines operate on unsigned big int data unless documented…  
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

:Section Error Handling 
  Er1←  ⎕SIGNAL/{ 'Invalid or unimplemented monadic routine' 11 }
  Er2←  ⎕SIGNAL/{ 'Invalid or unimplemented dyadic routine'  11}
  Er11← ⎕SIGNAL/{ (0.7 Clip 'DOMAIN ERROR: ',⍵) 11 }   
  ⍝ ⍺ Clip ⍵:  ⍺=<ratio of ⍵=<msg string> which should be from left> with rest from right
    Clip←{p←⎕PW⋄ p≥≢⍵:⍵ ⋄ (⍵↑⍨p-∆),'…',⍵↑⍨1-∆←⌊p×1-⍺} 
:EndSection Error Handling 

:Section Opcode Mapping
  :Namespace map 
    DEBUG← ##.DEBUG 
    miss← ¯1   ⍝ missing value for fNm1, fNm2, exp1, exp2 
  ⍝ FNS_MONADIC LEFT TO DO←'=≠⊥⊤→~⍳≢' 
  ⍝ FNS_DYADIC LEFT TO DO ←('⌊⌈|∨∧⌽↑↓~⍟⍴') 
  ⍝ op: op code, fNm1: 1adic fns, fNm2: 2adic fns, 
  ⍝ exp1: should we export results for 1adic?, exp2: ditto 2adic?
  ⍝ fNm1, fNm2: Use unquoted m for missing function for 1adic or 2adic op codes (opc),
      opc←    '+'   '-'   '×'   '÷'     '*'   '|'     '∨'    '∧'   '⍟'   '⌈'    '⌊'
      fNm1←  'Imp' 'Neg' 'Sig' 'Recip'  miss 'Abs'    miss   miss 'Log'  miss   miss
      fNm2←  'Add' 'Sub' 'Mul' 'Div'   'Pow' 'Rem'   'Gcd'  'Lcm' 'Log' 'Max'  'Min'    
      exp1←   1     1     1     1       miss  1       miss   miss  1     miss   miss
      exp2←   1     1     1     1       1     1       1      1     1     1      1   

      opc,←    '⍕'      '⍎'      '≡'     '≢'       '→'
      fNm1,←  'BI2Str' 'BI2Apl'  miss   'NLimbs'  'Imp'
      fNm2,←  'BI2Str'  miss    'Ident' 'Differ'   miss
      exp1,←   0        0        miss    0         0
      exp2,←   0        miss     0       0         miss

      opc,←    '<'   '≤'   '='   '≥'   '>'   '≠'   '!'    '?'    '√'      
      fNm1,←  'Dec' 'Dec'  miss 'Inc' 'Inc'  miss 'Fact' 'Roll' 'Root'    
      fNm2,←  'Lt'  'Le'  'Eq'  'Ge'  'Gt'  'Ne'   miss   miss  'Root'           
      exp1,←   1     1     miss  1     1     miss  1       1      1            
      exp2,←   0     0     0     0     0     0     miss    miss   1              

      opc,←   'Root' 'Sqrt' 'Log10' 'DivRem'   
      fNm1,←  'Root' 'Root' 'Log10'  miss      
      fNm2,←  'Root'  miss   miss   'DivRem'   
      exp1,←   1      1      1       miss     
      exp2,←   1      miss   miss    2         

    ⍝ Index: Search op codes, ignoring case. Equivalent: 'log10' 'Log10' 'lOG10'
      Index← (⎕C opc)∘⍳                             
      GetOpCode← { opc⊃⍨ ⍺⍺ Call ⍬ }
    ⍝ 1. To both fNm1 (monadic list) and fNm2 (dyadic list), append the placeholder m (¯1);
    ⍝ 2. Then, in fNm1 and fNm2, replace placeholder m with respective error function: 
    ⍝    Er1 (for fNm1) and  Er2 (for fNm2)
    ⍝ 3. Create fNm. See map.entries below.
      fNm←     ↑ 'Er1' 'Er2' {(⊂⍺)@(miss∘≡¨)⊢⍵}¨ fNm1 fNm2,¨miss
      expOk← ↑ exp1 exp2,∘⊂¨ miss miss        ⍝ mis: Use as placeholders for op codes not found 
    ⍝ ⍕ (BI2Str [1-, 2-adic]), * (power [2-adic]) do their own operand decoding.          
      impOk← 0@ (1 0 1,¨Index'*⍕⍕')⊢ 1⍴⍨ ⍴expOk          

    ⍝ Mapping Utilities
      ⍝ Index (see above)
      ⍝ map.Call:  offset← opc map.Call opsL
      ⍝    opc: APL_fn | 'string'. 
      ⍝        APL_fn: e.g. +, -, etc.
      ⍝        string: Any (quoted) string will-- for searching-- be normalized to lower case...
      ⍝    opsL: a vector of ops, e.g. map.ops, searched for normalized <opc>
      ⍝    Returns:
      ⍝        the integer offset to the string in opsL (or 1+ ≢opsL, if not found)
      Call←{ f←⍺⍺ ⋄ 3=⎕NC '⍺⍺': ⊂⍵, Index ⎕NR'f' ⋄ ⊂⍵, Index ⊂⎕C ⍺⍺ } 

    ⍝ Combine (⎕OR fn), import, export into a list of entries (database), one per opc code.
    ⍝ Each database entry has 3 elements:  
    ⍝    "operand"         "import OK" "export OK"
    ⍝    (⊂##.⎕OR fNm[i])   impOk[i]    expOk[i], for all i in ⍳≢fNm
    ⍝    *** fNm[i] must be a valid function in ##.
      eLogic← 'LOGIC ERR: Missing fn '∘,'"'∘(,,,⍨) 
      GenDB← {0:: ⎕←eLogic ⍺ ⋄ ⍵,⍨ ⊂##.⎕OR ⍺ }¨  
      entries← fNm GenDB impOk,¨ expOk    
      Sel← { entries⊃⍨ ⍺⍺ Call ⍵}
      
    ⍝ Keep only the list on the left for runtime...
      ⎕EX⍣(~DEBUG)⊢  'entries' 'opc' 'Sel' 'Index' 'GetOpCode' 'Call' ~⍨ ⎕NL -2 3 4 
  :EndNamespace 
  
  :EndSection Opcode Mapping
      _←1 ⎕EXPORT 'BI' 'BII' 'BIM' 'HELP'⊣ 0 ⎕EXPORT ⎕NL 3 4

:Section Help Documentation
⍝H The BigInt Library
⍝H ¯¯¯ ¯¯¯¯¯¯ ¯¯¯¯¯¯¯
⍝H  Big Integer (big number) routines built on dfns::nats restructured for signed integers. 
⍝H  Significantly faster than dfns::big and less amenable to WS FULL.
⍝H 
⍝H  BigInt Routines: BI, BII, BIM, and BigInt.BI_HELP.
⍝H  ¨¨¨¨¨¨ ¨¨¨¨¨¨¨¨¨ ¨¨¨ ¨¨¨¨ ¨¨¨¨ ¨¨¨ ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
⍝H  BI:  ∘ Returns big integers in a string (external) format, except for logical/boolean operands.
⍝H       ∘ Syntax: bi← [bi] (opcode BI) bi
⍝H       ∘ Example: bi← '12345' +BI '54321'
⍝H       ∘ Example: [0|1]← '12345' =BI '54321'
⍝H  BII: ∘ Returns big integers in a more efficient internal format (signum_scalar integer_vector). 
⍝H         Most useful for a series of calculations, such as a factorial, etc.
⍝H       ∘ Syntax: bii← [bi] (opcode BI) bi
⍝H       ∘ Example: bii← '12345' +BII '54321'
⍝H       ∘ Example: [0|1]← '12345' =BI '54321'
⍝H  BIM: ∘ BI with modulo argument; efficient and compact for multiplication and exponentiation.
⍝H       ∘ Syntax: bi← bi (opcode BIM modulo) bi  [dyadic only]
⍝H       ∘ Example: bi← '12345' (×BIM '12')⊢'54321' is equiv. to
⍝H       ∘ Example: bi← '12'|BI '12345' ×BI '54321', where × represents any dyadic op.
⍝H  BigInt.BI_HELP
⍝H       ∘ Display this "help" information.
⍝H       ∘ Syntax:  BigInt.BI_HELP
⍝H 
⍝H  Operands to BI, BII, BIM
⍝H  ¨¨¨¨¨¨¨¨ ¨¨ ¨¨¨ ¨¨¨¨ ¨¨¨
⍝H  Monadic operands: -+|×÷<>!?⍎⍕ '√' '≢' '→'
⍝H  Dyadic  operands: +-×÷*⍟|⌈⌊∨∧<≤=≥>≡≢  '√' 'DivRem'
⍝H  
⍝H  INPUT ARGUMENTS TO BI, BII, BIM
⍝H  ¨¨¨¨¨ ¨¨¨¨¨¨¨¨¨ ¨¨ ¨¨¨ ¨¨¨¨ ¨¨¨
⍝H  ∘ All arguments to BigInt routines may be in either the external bi or internal bii formats,
⍝H    ∘ a char string ('¯123', '-23_456', (1000⍴⎕D)), 
⍝H      ∘ on input, strings may have underscores to separate runs of digits; 
⍝H        negative numbers may be prefixed by either ¯ or -,
⍝H      ∘ for output, strings won't have underscores and will use ¯ for negative numbers,
⍝H        but see dyadic ⍕ for alternatives.
⍝H    ∘ an integer (123456), 
⍝H    ∘ a float to be treated as an integer may have a large pos. exponent (123E145),
⍝H        ∘ While precision here is limited to APL's precision, the exponent will be
⍝H          honored as an appropriate number of trailing 0s.
⍝H             2.3E33  ==>  '2300000000000000000000000000000000'
⍝H    ∘ a few special cases for (square, cube, etc.) roots: 0.5, '÷2', etc.
⍝H    See below for further details on bi and bii formats.
⍝H 
⍝H    RETURN VALUES FROM BI, BIM (not BII): bi
⍝H    ¨¨¨¨¨¨ ¨¨¨¨¨¨ ¨¨¨¨ ¨¨¨ ¨¨¨ ¨¨¨¨ ¨¨¨¨¨ ¨¨
⍝H    With BI or BIM, most routines return a big integer in ¨bi¨ format:
⍝H          a canonical (normalized) bi has a guaranteed format:
⍝H          ∘ char. vector     
⍝H          ∘ leading ¯ ONLY for minus, except as returned from (1⍕BI ⍵)
⍝H          ∘ otherwise, only the digits 0-9. Underscores only if ([1|0] 5⍕BI ⍵) or equiv.
⍝H          ∘ leading 0's are removed.
⍝H          ∘ 0 is represented by (,'0'), unsigned, with no extra '0' digits.
⍝H          ∘ See ⍕BI for more on hyphen (-) and underscores (_) on output
⍝H    Logical routines and some others return booleans or APL integers.
⍝H 
⍝H    RETURN VALUES FROM BII: bii
⍝H    ¨¨¨¨¨¨ ¨¨¨¨¨¨ ¨¨¨¨ ¨¨¨¨ ¨¨¨  
⍝H    With BII, most routines return a big integer in ¨bii¨ format:
⍝H    bii   -internal-format signed Big Integer numeric vector:
⍝H          sign (data) ==>  sign (¯1 0 1)   data (a vector of integers)
⍝H          ∘ sign: If data is zero, sign is 0 by definition.
⍝H          ∘ data: Always 1 or more integers (if 0, it must be data is ,0).
⍝H                  Each element is a positive number <RX10 (10E6)
⍝H          ∘ depth: ¯2    shape: 2
⍝H          Given the canonical requirement, 
⍝H               a bii of 0 is (0 (,0)), 1 is (1 (,1)) and ¯1 is (¯1 (,1)).
⍝H    Logical routines and some others return booleans or APL integers.
⍝H
⍝H   BI     bi← [⍺]  +BI ⍵
⍝H          Does all the basic monadic and dyadic math operations: + - * etc.
⍝H          ⍺, ⍵:  any "scalar" big integer in internal (BigIntI) or external (BigIntE) formats.   
⍝H          Returns for most operands: a normalized bi. See below.
⍝H   BII    bii← [⍺]  +BII ⍵
⍝H          Does all the operations, just like BI, except for return type.
⍝H          ⍺, ⍵:  Same as for BI.
⍝H          Returns for most operands an "internal" bii integer. See below.
⍝H   BIM    bi← ⍺ ×BIM ⍵⍵ ⊣ ⍵
⍝H          Does operation  ⍵⍵ | ⍺ × ⍵ for big integers ⍺, ⍵, and integer ⍵⍵. 
⍝H          Returns: An external format BigIntE.
⍝H          Specifically:
⍝H                 ⍺ ×BIM m ⊣ ⍵   is the same as    m |BI ⍺ ×BII ⍵   (except faster and less likely to trigger a WS FULL)
⍝H          BIM is optimized for functions × (Mul) and * (Pow: integer ⍵≥0) so far.  
⍝H          For other operations, calls modulo after performing <op>.
⍝H
⍝H
⍝H  MONADIC OPERANDS: +BI ⍵
⍝H  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H  Monadic operands: -+|×÷<>!?⍎⍕ '√' '≢' '→'
⍝H        Right argument: ⍵ in BigInt internal or external formats (BigIntI or BigIntE).
⍝H        Operators: BI or BII only. BIM is only used dyadically.
⍝H           -BI  ⍵             Negate
⍝H           +BI  ⍵             canonical (returns ⍵ in standard bi form, however entered)
⍝H           |BI  ⍵             absolute value
⍝H           ×BI  ⍵             signum in APL format: ¯1, 0, 1
⍝H           ÷BI  ⍵             reciprocal (basically useless)
⍝H           <BI  ⍵             decrement (alternate ≤). Optimized except when overflow/underflow occur.
⍝H           >BI  ⍵             increment (alternate ≥). Optimized (ditto).
⍝H           !BI  ⍵             factorial
⍝H           ?BI  ⍵             Roll.  ⍵>0. Returns number between 0 and ⍵-1
⍝H                              ⍵=0: Returns a 100-digit number between 0 and 100⍴'1'
⍝H           ('√'BI)  ⍵         Sqrt (alternate 'SQRT'). Use ⍺*BI 0.5 (optimized special case).
⍝H        Miscellaneous:        ≢, ⍎, →, ⍕
⍝H           ≢BI  ⍵             number of limbs in bii format as an APL integer.
⍝H           ⍎BI ⍵              an APL integer, only if it can be represented; else error.
⍝H           →BI ⍵              an internal format bii big integer, as if BII had been used.
⍝H           ⍕BII               string format (returns ⍵ in standard bi form, however entered)
⍝H
⍝H  DYADIC OPERANDS: ⍺ ×BI ⍵, ⍺ ×BII ⍵, ⍺ ×BIM ⍵⍵ ⊣ divisor
⍝H  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H  Dyadic  operands: +-×÷*⍟|⌈⌊∨∧<≤=≥>≡≢  '√' 'DivRem'
⍝H        BI, BII: Arguments ⍺ and ⍵ are Big Integer internal (bii) or external formats (bi).
⍝H        BIM:     ⍺ (fn BIM divisor)⍵  <==>   divisor | ⍺ fn BI ⍵, except × and * are calculated efficiently within range <divisor>.
⍝H           ⍺ + BI  ⍵          Add
⍝H           ⍺ - BI  ⍵          subtract
⍝H           ⍺ × BI  ⍵          multiply; optimizes ⍺×2, 2×⍵ as adds, etc.
⍝H           ⍺ ÷ BI  ⍵          divide, optimizes ⍵∊ powers of 10 (10, 100, ...)
⍝H           ⍺ * BI  ⍵          power 
⍝H                              If ⍵ is a non-negative integer, computes the signed power
⍝H                              efficiently. ⍵ may NOT be fractional except as described here:
⍝H                              If 0<⍵<1, ⍺ *BI ⍵ is used to compute a root of ⍺:
⍝H                                Sqrt ⍺:      0.5   or ÷2 or '÷2' . Also ('√'BI)  ⍺ 
⍝H                                Cube root:   0.333 or ÷3 or '÷3'.  Also (3'√'BI) ⍺
⍝H                                Fourth root: 0.25  or ÷4 or '÷4'.  Also (4'√'BI) ⍺
⍝H                                etc.
⍝H                              If ⍵ is any negative integer, the result is trivially 0.
⍝H           ⍺ ('√' BI)  ⍵      BI  ⍵th Root ⍺. Same as ⍵ *BI ('÷⍺')                                                    cube Root: 3 ('√' BI) BI  ⍵
⍝H           ⍺ ⍟ BI  ⍵          ⌊(Log of ⍵ in integral base ⍺). Optimized for powers of 10 only.
⍝H           ⍺ | BI  ⍵          remainder ⍺ | BI  ⍵
⍝H           ⍺ ⌈ BI  ⍵          max
⍝H           ⍺ ⌊ BI  ⍵          min
⍝H           ⍺ ∨ BI  ⍵          Gcd (not used for: or).  Returns bi.
⍝H           ⍺ ∧ BI  ⍵          Lcm (not used for: and). Returns bi.
⍝H           ⍺ 'DIVREM' BI  ⍵   returns two BigInts: ⌊⍺÷BI  ⍵ and  BI  ⍵|⍺
⍝H           ⍺1 [⍺2[⍺3]] ⍕BI ⍵  string format. See also ⍕BI ⍵.
⍝H                              ⍺1=1: replace initial ¯ with -; 
⍝H                              ⍺2=nn: place '_' separator every nn digits
⍝H                              ⍺3=base: (first) convert to base <base>, 2≤base≤62.
⍝H                     Example: 1 5 ⍕BI ¯00424141413414    => '-42_41414_13414'
⍝H                              1 5 16 ⍕BI ¯00424141413414 => "-62c0c_c5c26"
⍝H                              1 5 2 ⍕BI ¯00424141413414  => 
⍝H                                    "11100_01011_00000_01100_11000_10111_00001_00110"
⍝H                                     ↑_ sign bit!
⍝H                              String format numbers output are always valid as input.
⍝H           ⍺ = ⍵              ⍺ is numerically equal to ⍵
⍝H           ⍺ ≠ ⍵              ⍺ is numerically not equal to ⍵
⍝H           ⍺ ≡ ⍵              ⍺ is identical to ⍵ (see ⍺=⍵)
⍝H           ⍺ ≢ ⍵              ⍺ is not identical to ⍵ (see ⍺≠⍵)
⍝H        Logical Ops:          < ≤ = ≥ > ≠  
⍝H           ⍺ < BI  ⍵          ⍺ < ⍵, where < is any logical op, ⍺ and ⍵ are bigints.  
⍝H           Return:            APL Boolean: 1 if true, else 0 (not: '1' or '0') 
⍝H
:EndSection Help Documentation

:ENDNAMESPACE
