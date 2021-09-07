:NAMESPACE BigInt
:Section HELP_INTRO
⍝H For help information
⍝H      ]require bigint
⍝H Then
⍝H      BI_HELP
 
:EndSection HELP_INTRO
:Section BI
  :Section PREAMBLE
    DEBUG←0               
    ⎕IO ⎕ML ⎕PP ⎕CT ⎕DCT ⎕FR ← 0 1 34 0 0 645            
    Err←⎕SIGNAL/{⍺←1  ⋄ ⍺: ('BI ',⍵) 11 ⋄ 0}
  :EndSection PREAMBLE
  :Section Namespace and Utility Initializations
    NRX2←            20                                  
    NRX10←           ⌊10⍟RX2←2*NRX2                      
    NRX2BASE←        NRX2⍴2                              
    RX10BASE←        NRX10⍴10                            
    RX10←            10*NRX10                            
    RX10div2←        RX10÷2                              
    OFL←             {⌊(2*⍵)÷RX10×RX10}(⎕FR=1287)⊃53 93  
    ZERO_D ←  ,0                                         
    ONE_D  ←  ,1                                         
    TWO_D  ←  ,2                                         
    TEN_D  ← ,10                                         
    ZERO_BI   ←   0 ZERO_D                               
    ONE_BI    ←   1  ONE_D                               
    TWO_BI    ←   1  TWO_D                               
    MINUS1_BI ←  ¯1  ONE_D                               
    TEN_BI    ←   1  TEN_D                               
    eIMPORT  ←'Object not a valid BigInt: '
    eBADRAND ←'Arg to roll (?) must be integer >0.'
    eFACTOR  ←'Arg to factorial (!) must be ≥ 0'
    eBADRANGE←'BigInt too large to be approximated in APL: outside dynamic range (±1E6145)'
    eBIC     ←'BIC: arg must be a fn name or one or more code strings.'
    eBOOL    ←'Importing bits: boolean arg (1s or 0s) expected.'
    eCANTDO1 ←'Monadic function (operand) not implemented: '
    eCANTDO2 ←'Dyadic function (operand) not implemented: '
    eBIMDYAD ←'BIM Operator: only dyadic functions are supported.'
    eLOG     ←'Log of a non-positive BigInteger is undefined'
    eSMALLRT ←'Right argument must be a small APL integer ⍵<',⍕RX10
    eMUL10   ← eSMALLRT
    eROOT    ←'Base (⍺) for root must be small non-zero integer: ⍺<',⍕RX10
    eSUB     ←'subU LOGIC: unsigned subtraction may not become negative'
    :EndSection Namespace and Utility Initializations
    :Section Executive
    ∇ BI_HELP;⎕PW
      :If 0=⎕NC'HELP_INFO' ⋄ HELP_INFO←'^\h*      ⎕PW←120 ⋄ (⎕ED⍠'ReadOnly' 1)&'HELP_INFO'
    ∇
    monadFnsList←'-+|×÷<>≤≥!?⊥⊤⍎→√~⍳'('SQRT' 'NOT' '⎕AT')
    dyadFnsList←('+-×*÷⌊⌈|∨∧⌽↑↓√≢~⍟','<≤=≥>≠⍴')('*∘÷' '*⊢÷' 'ROOT' 'SHIFTD' 'SHIFTB'  'DIVREM' 'MOD')
      DecodeCall←{⍺←⊢
          getOpName←{aa←⍺⍺ ⋄ 3=⎕NC'aa':∊⍕⎕CR'aa' ⋄ 1 ⎕C aa}
          decode←{
              atom←{1=≢⍵:⍬⍴⍵ ⋄ ⊂⍵}
              monad name←⍺(atom ⍵~'⍨ ')
              '⍨'∊⍵:name 0(1+monad)
              name monad 0
          }
          (1≡⍺ 1)decode ⍺⍺ getOpName ⍵
      }
      __SOURCE__←{⍺←⊢
          DEBUG↓0::⎕SIGNAL/⎕DMX.(EM EN)
          QT←''''
          fn monad inv←⍺(⍺⍺ DecodeCall)⍵
          CASE←fn∘∊∘⊆
          monad:{                                       
              CASE'-':__EXPORT__ neg ⍵              
              CASE'+':__EXPORT__ Import ⍵           
              CASE'|':__EXPORT__ abs ⍵              
              CASE'×':__EXPORT__⊃Import ⍵       
              CASE'÷':__EXPORT__ recip ⍵            
              CASE'<':__EXPORT__ dec ⍵              
              CASE'≤':__EXPORT__ dec ⍵              
              CASE'>':__EXPORT__ inc ⍵              
              CASE'≥':__EXPORT__ inc ⍵              
              CASE'!':__EXPORT__ fact ⍵             
              CASE'?':__EXPORT__ roll ⍵             
              CASE'⍎':ExportApl ⍵                   
              CASE'⍕':Prettify Export ∆ ⍵           
              CASE'SQRT' '√':__EXPORT__ sqrt ⍵      
              CASE'⍳':⍳ReturnSmallAPLInt ⍵          
              CASE'→':Import ⍵                      
              CASE'⊥':__EXPORT__ BitsImport ⍵       
              CASE'⊤':BitsExport ⍵                  
              CASE'~':__EXPORT__ BitsImport~BitsExport ⍵  
              CASE'⎕AT':GetBIAttribs ⍵              
              Err eCANTDO1,QT,QT,⍨fn                
          }⍵
          ⍺{
              CASE'+':__EXPORT__ ⍺ add ⍵
              CASE'-':__EXPORT__ ⍺ sub ⍵
              CASE'×':__EXPORT__ ⍺ mul ⍵
              CASE'÷':__EXPORT__ ⍺ div ⍵                  
              CASE'*':__EXPORT__ ⍺ pow ⍵                  
              CASE'*∘÷' '*⊢÷':__EXPORT__ ⍵ root ⍺         
              CASE'√' 'ROOT':__EXPORT__ ⍺ root ⍵          
              CASE'↑':__EXPORT__ ⍵ mul10Exp ⍺             
              CASE'↓':__EXPORT__ ⍵ mul10Exp-⍺             
              CASE'⌽':__EXPORT__ ⍵ mul2Exp ⍺              
              CASE'|':__EXPORT__ ⍺ rem ⍵                  
              CASE'<':⍺ lt ⍵
              CASE'≤':⍺ le ⍵
              CASE'=':⍺ eq ⍵
              CASE'≥':⍺ ge ⍵
              CASE'>':⍺ gt ⍵
              CASE'≠':⍺ ne ⍵
              CASE'⌈':__EXPORT__(∆ ⍺){⍺ ge ⍵:⍺ ⋄ ⍵}∆ ⍵     
              CASE'⌊':__EXPORT__(∆ ⍺){⍺ le ⍵:⍺ ⋄ ⍵}∆ ⍵     
              CASE'∨' 'GCD':__EXPORT__ ⍺ gcd ⍵             
              CASE'∧' 'LCM':__EXPORT__ ⍺ lcm ⍵             
              CASE'⍟':__EXPORT__ ⍺ log ⍵                   
              CASE'MOD':__EXPORT__ ⍵ rem ⍺                 
              CASE'SHIFTB':__EXPORT__ ⍺ mul2Exp ⍵          
              CASE'SHIFTD':__EXPORT__ ⍺ mul10Exp ⍵         
              CASE'DIVREM':__EXPORT__¨⍺ divRem ⍵           
              CASE'⍴':(ReturnSmallAPLInt ⍺)⍴⍵              
              Err eCANTDO2,QT,QT,⍨fn                       
          }{2=inv:⍵ ⍺⍺ ⍵ ⋄ inv:⍵ ⍺⍺ ⍺ ⋄ ⍺ ⍺⍺ ⍵}⍵           
      }
                                                                  BIM←{
          ⍺←⎕NULL ⋄  x y modulo←⍺ ⍵ ⍵⍵  
          fn←⊃x ⍺⍺ DecodeCall modulo
          ⍺≡⎕NULL:Err eBIMDYAD
          fn≡'×':Export x (modulo modMul) y 
          fn≡'*':Export x (modulo modPow) y
          ⋄ mod|BI x(fn BII)y
      }
    ⎕FX'__SOURCE__' '__EXPORT__'  ⎕R 'BI'  'Export'⊣⎕NR'__SOURCE__'
    ⎕FX'__SOURCE__' '__EXPORT__¨?'⎕R 'BII' ''      ⊣⎕NR'__SOURCE__'
    ___←⎕EX '__SOURCE__'
    :EndSection BI Executive
    :Section BigInt internal structure
      Import←{⍺←⊢
          1≢⍺ 1:(∇ ⍺)(∇ ⍵)
          ¯2=≡⍵:   ⍵             
          type←80|⎕DR ⍵
          type=3:ImportInt ⍵  ⋄ type=0:ImportStr ⍵ ⋄ type∊5 7:ImportFloat ⍵
          Err eIMPORT
      }
      ∆←Import
      ImportInt←{
          1≠≢⍵:       Err eIMPORT,⍕⍵       
          RX10>u←,|⍵: (×⍵)u                
          (×⍵)(chkZ RX10⊥⍣¯1⊣u)            
      }
      ImportFloat←{⎕FR←1287 
          (1=≢⍵)∧(⍵=⌊⍵):(×⍵)(chkZ RX10⊥⍣¯1⊣|⍵)
          Err eIMPORT,⍕⍵
      }
      ImportStr←{
          s←1 ¯1⊃⍨'-¯'∊⍨1↑⍵            
          w←'_'~⍨⍵↓⍨s=¯1               
          (0=≢w)∨0∊w∊⎕D:Err eIMPORT     
          d←rep ⎕D⍳w                   
          dlzNorm s d                 
      }
      ReturnSmallAPLInt←{
          s w←∆ ⍵ ⋄ 1≠≢w:Err eSMALLRT ⋄ s×,w
      }
    Export←{ ('¯'/⍨¯1=⊃⍵),⎕D[dlzRun,⍉RX10BASE⊤|⊃⌽⍵]}
    :EndSection BigInt internal structure
    ∇ {fnNmOut}←rawCall fnNm
        ;fnInP;fnOutA;inP;outA
      fnInP fnOutA←('\b',fnNm,'\b')('_',fnNm)
      inP outA←(fnInP '←⍺ ∆ ⍵'  '←∆ ⍵' )(fnOutA '←⍺ ⍵'  '←⍵')
      fnNmOut←⎕FX inP ⎕R outA ⍠('UCP' 1)⊣⎕NR fnNm
      :IF 0=1↑0⍴fnNmOut 
          Err 'rawCall: Error ⎕FXing variant of ',fnNm
      :ENDIF 
    ∇
    :Section BI Monadic Operations/Functions
      neg←{                                
          (sw w)←∆ ⍵
          (-sw)w
      }
      sig←{                                
          (sw w)←∆ ⍵
          sw(|sw)
      }
      abs←{                                
          (sw w)←∆ ⍵
          (|sw)w
      }
      inc←{
          (sw w)←∆ ⍵
          sw=0:1 ONE_D                     
          sw=¯1:dlzNorm sw(⊃⌽_dec 1 w)    
          î←1+⊃⌽w                          
          RX10>î:sw w⊣(⊃⌽w)←î              
          sw w _add 1 ONE_D                
      }
      dec←{
          (sw w)←∆ ⍵
          sw=0:¯1 ONE_D                    
          sw=¯1:dlzNorm sw(⊃⌽_inc 1 w)    
          0≠⊃⌽w:dlzNorm sw w⊣(⊃⌽w)-←1     
          sw w _sub 1 ONE_D                
      }
    rawCall¨'neg' 'sig' 'abs'  'inc' 'dec'
      fact←{                                
          sw w←∆ ⍵
          sw=0:ONE_BI                       
          sw=¯1:Err eFACTOR                 
          factBig←{
              1=≢⍵:⍺ factSmall ⍵            
              (⍺ mulU ⍵)∇⊃⌽_dec 1 ⍵
          }
          factSmall←{
              ⍵≤1:1 ⍺
              (⍺ mulU ⍵)∇ ⍵-1
          }
          1 factBig w
      }
      roll←{
          sw w←∆ ⍵
          sw≠1:Err eBADRAND
          ⎕PP←16 ⋄ ⎕FR←645                       
          inL←≢Export sw w                          
          res←inL⍴{                              
              ⍺←''                               
              ⍵≤≢⍺:⍺ ⋄ (⍺,2↓⍕?0)∇ ⍵-⎕PP          
          }inL                                   
          '0'=⊃res:∆ res                         
          ⍵ rem ∆ res                            
      }
      BitsImport←{
          ' '=1↑0⍴⍵:∇{ ~0∊⍵∊'01': ⍺⍺ '1'=⍵  ⋄ Err eBOOL }⍵~' ' 
          0∊⍵∊0 1:Err eBOOL
          bits←,⍵
          sgn←(⊃bits)⊃1 ¯1 ⋄ bits←1↓bits    
          nhands←⌈exact←NRX2÷⍨≢bits         
          bits←nhands NRX2⍴{
              nhands=exact:⍵
              (-nhands×NRX2)↑⍵              
          }bits
          dlzNorm sgn(2⊥⍉bits)         
      }
      BitsExport←{
          sw w←∆ ⍵
          sw=0:0,NRX2⍴0
          (sw=¯1),,⍉NRX2BASE⊤w
      }
    GetBIAttribs←{hands←≢⊃⌽w←∆ ⍵ ⋄ bits←BitsExport w ⋄ hands (≢bits) (+/1=bits) }
      root←{
          ⍺←2 
          sgn rdx←⍺{   
              ⍵:1 2
              sgn rdx←Import ⍺
              sgn=0:Err eROOT 
              1<≢rdx:Err eROOT 
              sgn rdx
          }900⌶⍬
          sgn<0:0    
          sN N←Import ⍵
          0=sN:sN N                    
          ¯1=sN:Err eROOT        
          rootU←*∘(÷rdx)
          1=ndig←≢N:1(,⌊rootU N)    
          x←{ 
              0::1((⌈rootU⊃⍵),(RX10-1)⍴⍨⌈0.5×ndig-1) 
              ⎕FR←1287
              ⊃⌽Import 1+⌈rootU⍎Export 1 ⍵     
          }N
          {x←⍵
              y←(x addU N quotientU x)quotientU rdx    
              ≥cmp y mix x:1(,x)
              ∇ y                              
          }x
      }
    sqrt←root
    rootX←{⍺←⊢ ⋄ Export ⍺ root ⍵}
    recip←{{0=≢⍵: ÷0 ⋄ 1≠≢⍵:0 ⋄ 1=|⍵:⍵ ⋄ 0}dlzRun ⍵}
    :Endsection BI Monadic Functions/Operations
    :Section BI Dyadic Functions/Operations
      add←{
          (sa a)(sw w)←⍺ ∆ ⍵
          sa=0:sw w                           
          sw=0:sa a                           
          sa=sw:sa(ndnZ 0,+⌿a mix w)          
          sa<0:sw w _sub 1 a                  
          sa a _sub 1 w                       
      }
      sub←{
          (sa a)(sw w)←⍺ ∆ ⍵
          sw=0:sa a                            
          sa=0:(-sw)w                          
          sa≠sw:sa(ndnZ 0,+⌿a mix w)           
          <cmp a mix w:(-sw)(nupZ-⌿dck w mix a)  
          sa(nupZ-⌿dck a mix w)                
      }
      mul←{
          (sa a)(sw w)←⍺ ∆ ⍵
          0∊sa,sw:ZERO_BI
          TWO_D≡a:(sa×sw)(addU⍨w) ⋄ TWO_D≡w:(sa×sw)(addU⍨a)
          ONE_D≡a:(sa×sw)w ⋄ ONE_D≡w:(sa×sw)a
          (sa×sw)(a mulU w)
      }
      div←{ 
          (sa a)(sw w)←⍺ ∆ ⍵
          TEN_D≡w:  (sa×sw)a mul10Exp MINUS1_BI       
          normFromSign(sa×sw)(⊃a divU w)
      }
      divRem←{
          (sa a)(sw w)←⍺ ∆ ⍵
          quot rem←a divU w
          (normFromSign(sa×sw)quot)(normFromSign sw rem)
      }
    rawCall¨'add' 'sub' 'mul'  'div' 'divRem'
      decodeRoot←{              
          0::0 ⋄ 0>≡⍵:0         
          ⌊{extract←{1≤⍵:0 ⋄ ÷⍵} ⋄ 0=1↑0⍴⍵:extract ⍵ ⋄ '÷'=1↑⍵:⊃⊃⌽⎕VFI 1↓⍵ ⋄ extract⊃⊃⌽⎕VFI ⍵}⍵
      }
      pow←{
          0≠rt←decodeRoot ⍵:rt root ⍺
          (sa a)(sw w)←⍺ ∆ ⍵
          sa sw∨.=0 ¯1:ZERO_BI     
          p←a powU w
          sa≠¯1:1 p                
          0=2|⊃⌽w:1 p ⋄ ¯1 p       
      }
      rem←{                        
          (sa a)(sw w)←⍺ ∆ ⍵
          sw=0:ZERO_BI
          sa=0:sw w
          r←,a remU w              
          sa=sw:dlzNorm sa r      
          ZERO_D≡r:ZERO_BI         
          dlzNorm sa a _sub sa r  
      }
    res←rem                        
    rawCall¨ 'pow' 'rem'
    mod←rem⍨  ⋄  _mod←_rem⍨        
      mul2Exp←{
          (sa a)(sw w)←⍺ ∆ ⍵
          1≠≢w:Err eMUL10                         
          sa=0:0 ZERO_D                           
          sw=0:sa a                               
          pow2←2*w
          sw>0:sa a mul pow2
          sa a div pow2
      }
      div2Exp←{
          ⍺ mul2Exp negate ⍵
      }
    shiftBinary←mul2Exp
    shiftB←mul2Exp
      mul10Exp←{
          (sa a)(sw w)←⍺ ∆ ⍵
          1≠≢w:Err eMUL10                          
          sa=0:ZERO_BI                             
          sw=0:sa a                                
          ustr←Export 1 a                          
          ss←'¯'/⍨sa=¯1                            
          sw=1:∆ ss,ustr,w⍴'0'                     
          ustr↓⍨←-w                                
          0=≢ustr:ZERO_BI                          
          ∆ ss,ustr                                
      }
    shiftDecimal←mul10Exp                          
    shiftD←mul10Exp
    rawCall¨ 'mul10Exp' 'shiftD' 'mul2Exp'  'shiftB'
      gcd←{
          (sa a)(sw w)←⍺ ∆ ⍵
          1(a gcdU w)
      }
      lcm←{
          (sa a)(sw w)←⍺ ∆ ⍵
          (sa×sw)(a lcmU w)
      }
    rawCall¨ 'gcd' 'lcm'
    ∇ {r}←genBooleanFn(NAME SYM);model;∆TEMPLATE;in;out
      ∆TEMPLATE←{
          (sa a)(sw w)←⍺ ∆ ⍵
          0∊sa sw:sa ∆SYM sw        
          sa≠sw:sa ∆SYM sw          
          sa=¯1:∆SYM cmp w mix a    
          ∆SYM cmp a mix w          
      }
      in←'∆TEMPLATE' '∆SYM' ⋄ out←NAME SYM
      :If ' '≠1↑0⍴r←⎕THIS.⎕FX in ⎕R out⊣⎕NR'∆TEMPLATE'
          ∘∘∘⊣⎕←'⎕FIX-time LOGIC ERROR: unable to create boolean function: ',NAME,' (',SYM,')'
      :EndIf
    ∇
    genBooleanFn¨ ('lt' '<')('le' '≤')('eq' '=')('ge' '≥')('gt' '>')('ne' '≠')
    rawCall¨ 'lt' 'le'  'eq' 'ge' 'gt' 'ne'
    ⎕EX 'genBooleanFn'
    log2_10←(2⍟10)
      log←{
        log10←{¯1+≢Export ⍵}
        log2←{⌊log2_10×log10 ⍵}      
        ⍺←TEN_BI ⋄ B N←⍺ ∆ ⍵
        MINUS1_BI≡B:ZERO_BI{⍵ le ONE_BI:⍺ ⋄ (inc ⍺)∇ ⍵ _div B}N⊣B←TWO_BI
        0≥⊃N:Err eLOG        
        TEN_BI≡B:∆ log10 N
        TWO_BI≡B:∆ log2 N    
        ZERO_BI{⍵ _le ONE_BI:⍺ ⋄ (_inc ⍺)∇ ⍵ _div B}N   
      }
    :EndSection BI Dyadic Operators/Functions
    :Section BI Special Functions/Operations (More than 2 Args)
      modMul←{
          (a b)m←(⍺ ∆ ⍵)(∆ ⍺⍺)
          m _rem(m _rem a)_mul(m _rem b)
      }
    ∇ z←a(m modPow)n;s;mmM
      (a n)m←(a ∆ n)(∆ m)
      z←ONE_BI ⋄ s←m rem a
      mmM←m modMul 
      :While ZERO_BI lt n
          :If 1 eq 2 rem n ⋄ z←z mmM s ⋄ :EndIf    
          s←s mmM s                                
          n←n div 2
      :EndWhile
    ∇
    :EndSection BI Special Functions/Operations (More than 2 Args)
    :Section BI Unsigned Utility Math Routines
      addU←{
          dlzRun ndn 0,+⌿⍺ mix ⍵    
      }
      subU←{
          <cmp ⍺ mix ⍵:Err eSUB                   
          dlzRun nup-⌿dck ⍺ mix ⍵                 
      }
      mulU←{
          dlzRun ⍺{                               
              ndnZ 0,↑⍵{                          
                  digit take←⍺                    
                  +⌿⍵ mix digit×take↑⍺⍺           
              }/(⍺,¨(≢⍵)+⌽⍳≢⍺),⊂,0                
          }{                                      
              m n←,↑≢¨⍺ ⍵                         
              m>n:⍺ ∇⍨⍵                           
              n<OFL:⍺ ⍺⍺ ⍵                        
              s←⌊n÷2                              
              p q←⍺∘∇¨(s↑⍵)(s↓⍵)                  
              ndnZ 0,+⌿(p,s↓n⍴0)mix q             
          }⍵
      }
      powU←{powCase←(,⍵)∘≡
          powCase ZERO_D:ONE_D                     
          powCase ONE_D:,⍺                         
          powCase TWO_D:⍺ mulU ⍺                   
          hlf←{,ndn(⌊⍵÷2)+0,¯1↓RX10div2×2|⍵}       
          evn←ndnZ{⍵ mulU ⍵}ndn ⍺ ∇ hlf ⍵          
          0=2|¯1↑⍵:evn ⋄ ndnZ ⍺ mulU evn           
      }
      divU←{
          a w←dlzRun¨⍺ ⍵
          a≡w:  ONE_D ZERO_D                  
          ZERO_D≡w: 1÷0                       
          svec←(≢w)+⍳0⌈1+(≢a)-≢w              
          dlzRun¨↑w{                          
              r p←⍵                           
              q←⍺↑⍺⍺                          
              ppqq←RX10⊥⍉2 2↑p mix q          
              r∆←p q{                         
                  (p q)(lo hi)←⍺ ⍵            
                  lo=hi-1:p{                  
                      (≥cmp ⍺ mix ⍵)⊃lo hi    
                  }dLZ ndn 0,hi×q             
                  mid←⌊0.5×lo+hi              
                  nxt←dLZ ndn 0,q×mid         
                  gt←>cmp p mix nxt           
                  ⍺ ∇ gt⊃2,/lo mid hi         
              }⌊0 1+↑÷/ppqq+(0 1)(1 0)        
              mpl←dLZ ndn 0,q×r∆              
              p∆←dLZ nup-⌿p mix mpl           
              (r,r∆)p∆                        
          }/svec,⊂⍬ a                         
      }
    quotientU←⊃divU
    gcdU←{ZERO_D≡,⍵:⍺ ⋄ ⍵ ∇⊃⌽⍺ divU ⍵}        
    lcmU←{⍺ mulU⊃⍵ divU ⍺ gcdU ⍵}             
      remU←{                                  
          TWO_D≡,⍺:2|⊃⌽⍵                      
          <cmp ⍵ mix ⍺:⍵                      
          ⊃⌽⍵ divU ⍺                          
      }
    :Endsection BI Unsigned Utility Math Routines
    :Section Service Routines
    Prettify←  {0:: ⍵ ⋄ ⍺←0 ⋄ n← '(\d)(?=(\d{5})+$)' ⎕R '\1_'⊣⍵  ⋄  ⍺=0: n ⋄ '-'@('¯'∘=) n}
    ExportApl←{ 0:: Err eBADRANGE ⋄  ⍎Export ∆ ⍵}
    dlzNorm←{ZERO_D≡w←dlzRun⊃⌽⍵: ZERO_BI ⋄ (⊃⍵) w}
    normFromSign←{ZERO_D≡⊃⌽⍵:ZERO_BI ⋄ ⍵}
    dLZ←{(0=⊃⍵)↓⍵}                          
    dlzRun←{0≠≢v←(∨\⍵≠0)/⍵:v ⋄ ,0}          
    chkZ←{0≠≢⍵:,⍵ ⋄ ,0}                     
    ndn←{ +⌿1 0⌽0 RX10⊤⍵}⍣≡                 
    ndnZ←dLZ ndn                            
    nup←{⍵++⌿0 1⌽RX10 ¯1∘.×⍵<0}⍣≡           
    nupZ←dLZ nup                            
    mix←{↑(-(≢⍺)⌈≢⍵)↑¨⍺ ⍵}                  
    dck←{(2 1+(≥cmp ⍵)⌽0 ¯1)⌿⍵}             
    rep←{10⊥⍵{⍉⍵⍴(-×/⍵)↑⍺}(⌈(≢⍵)÷NRX10),NRX10}  
    cmp←{⍺⍺/,(<\≠⌿⍵)/⍵}                     
    :Endsection Service Routines
    :Endsection Big Integers
    :Section Utilities: BI_LIB, BI_DC (desk calc), BIB, BIC
    ⎕FX 'ns←BI_LIB' 'ns←⎕THIS'    
    ∆F←{ 
        ⍵=0:⍺.Match ⋄ ⍵≥≢⍺.Offsets:'' ⋄ ¯1=⍺.Offsets[⍵]:'' ⋄ ⍺.(Lengths[⍵]↑Offsets[⍵]↓Block)
    }
    ∇ {r}←loadPats
      ;actBiCallNoQ;actBiCallQ;actKeep;actKeepParen;actQuoted;lD;lM;p2Fancy;p2Funs1;p2Funs2
      ;p2Ints;p2Plain;p2Vars;pAplInt;pCom;pFancy;pFunsBig;pFunsNoQ;pFunsQ;pFunsSmall;pIntExp
      ;pIntOnly;pLongInt;pNonBiCode;pQot;pVar;t1;t2;tD1;tDM;tM1;tMM;_Q;_E
      pFnRep←'(?ix)   ^ \h* 
      actionFnRep←{match←⍵ ∆F 1 ⋄ pBiCalls ⎕R actBiCalls⊣match}
      optsFnRep←('Mode' 'M')('EOL' 'LF')('NEOL' 1)('IC' 1)('UCP' 1)('DotAll' 1)
      matchFnRep←{pFnRep ⎕R actionFnRep⍠optsFnRep⊣⍵}
      p2Vars←'\p{L}_∆⍙'
       ⋄ tD1 tDM←dyadFnsList
       ⋄ tM1 tMM←monadFnsList
       ⋄ t1←tD1{'[\-\?\*]'⎕R'\\\0'⊣∪⍺,⍵}tM1    
      _Q _E←⊂¨'\Q' '\E'
      t2←¯1↓∊(_Q,¨_E,⍨¨tDM,tMM),¨'|'
      p2Funs1←'(?:⍺⍺|⍵⍵)'                      
      p2Funs2←'(?:',t2,')|(?:[',t1,'])'        
      pCom←'(
      pVar←'([',p2Vars,'][',p2Vars,'\d]*)'     
      pQot←'((?:''[^'']*'')+)'                 
      pFunsNoQ←'(',p2Funs1,'(?!\h*BII))'       
      pFunsQ←'((?:',p2Funs2,')⍨?(?!\h*BII))'   
      pNonBiCode←'\(:(.*?):\)'                 
      pIntExp←'([\-¯]?[\d.]+[eE]¯?\d+)'        
      pIntOnly←'([\-¯]?[\d_.]+)'               
      actBiCallNoQ←'(\1',(⍕⎕THIS),'.BI)'       
      actBiCallQ←'(''\1''',(⍕⎕THIS),'.BI)'     
      actKeep actKeepParen actQuoted actBool←'\1' '(\1)' '''\1''' '⊥BI \1'
      pBiCalls←pCom pFunsQ pVar pQot pFunsNoQ pNonBiCode pIntExp pIntOnly
      actBiCalls←actKeep actBiCallQ actKeep actKeep actBiCallNoQ actKeepParen actKeepParen actKeep
      matchBiCalls←{⍺←1
          res←⊃⍣(1=≢res)⊣res←pBiCalls ⎕R actBiCalls⍠('UCP' 1)⊣⊆⍵
          ⍺=1:res
          prefix←'\Q','.\E',⍨⍕⎕THIS   
          prefix ⎕R' '⊣res
      }
      r←'OK'
    ∇
    loadPats
      BIC←{
          ⍺←0
          compileFixLines←{
              fx←((1+⎕IO)⊃⎕RSI,#).⎕FX matchFnRep ⍵
              0≠1↑0⍴fx:fx ⋄ 11 ⎕SIGNAL⍨'BIC: Unable to ⎕FX lines into fn'
          }
          DEBUG↓0::⎕SIGNAL/⎕DMX.(('bigInt: ',EM)EN)
          ⍺=0:((0+⎕IO)⊃⎕RSI,#)⍎matchBiCalls ⍵        
          ⍺=1:matchBiCalls ⍵                         
          ⍺=¯1:0 matchBiCalls ⍵                      
          ⍺=2:compileFixLines ⍵                      
          Err eBIC
      }
    ∇ {ok}←BI_DC
      ;caller;code;lastResult;exprIn;exec;isShy;HelpInfo;help1Cmd;help2Cmd;offon;pretty;prettyCmd;verbose;verboseCmd
      ;⎕PW
      ⎕PW←132
      verbose pretty offon lastResult←0 1('OFF' 'ON')'0'
      help1Cmd help2Cmd verboseCmd prettyCmd←,¨'?' '??' '!' '⍕'
      HelpInfo←{
          ⎕←'BI_DC:       Big integer desk calculator.'
          ⎕←'In any expression you type:'
          ⎕←'             ⍵     refers to the most recent calculated value (or 0)'
          ⎕←'At the prompt only (followed by return ⏎):'
          ⎕←'             !     toggles VERBOSE mode; currently VERBOSE ',verbose⊃offon
          ⎕←'             ⍕     toggles PRETTY  mode; currently PRETTY  ',pretty⊃offon
          ⎕←'Need help?'
          ⎕←'             ?     shows this basic HELP information.'
          ⎕←'             ??    shows more detailed HELP information.'
          ⎕←'Finished?'
          ⎕←'             ⏎     entering a completely empty line (just a return char ⏎) terminates BI_DC mode'
          ⎕←'                   a non-empty line with only blanks is ignored.'
      }
      HelpInfo ⍬
      :While ok←1
          :Trap 1000
              exprIn←⍞↓⍨≢⍞←'> '
              :If 0=≢exprIn 
                  :Return                                                    
              :Else
                  :Select exprIn~' '
                    :Case '' 
                    :Case help1Cmd 
                        HelpInfo ⍬
                    :Case help2Cmd 
                        BI_HELP
                    :Case verboseCmd 
                        verbose←~verbose ⋄ ⎕←'>>> VERBOSE ',verbose⊃offon
                    :Case prettyCmd 
                        pretty←~pretty ⋄ ⎕←'>>> PRETTY ',pretty⊃offon
                    :Else 
                        :GoTo IS_CODE                                           
                  :EndSelect
              :EndIf
              :Continue
     IS_CODE:
              :Trap 0
                  caller←(1+⎕IO)⊃⎕RSI,#
                  code←1 BIC exprIn
                  :If verbose 
                      ⎕←'> ',code  
                  :EndIf
                  isShy←×≢('^\(?(\w+(\[[^]]*\])?)+\)?←'⎕S 1⍠'UCP' 1)⊣code~' '   
                  run←{⍵⍵:⍺⍎⍺⍺ ⋄ ⊢⎕←1∘Prettify⍣pretty⊣⍺⍎⍺⍺}                     
                  lastResult←caller (code run isShy) lastResult
              :Else
                  :If ~verbose 
                       ⎕←'> ',code 
                  :EndIf
                  :Select ⎕EN
                    :Case 2
                        ⎕←'SYNTAX ERROR'
                    :Else
                        ⎕←{dm0 dm1 dm2←⍵.DM ⋄ p←1+dm1⍳']' ⋄ (p↑dm1)←' ' ⋄ ↑dm0 dm1(' ',dm2)}⎕DMX
                  :EndSelect
              :EndTrap
          :Else
              :If ~1∊'nN'∊⍞↓⍨≢⍞←'Interrupted. Exit? Y/N [Yes] '
                  :Return
              :EndIf
          :EndTrap
      :EndWhile
    ∇
    :Endsection Utilities: BI_LIB, BI_DC (desk calc), BIC
    :Section Bigint Namespace - Postamble
   _namelist_←'BI_LIB BI BII BIM BI_DC BIC BI_HELP' 
    ___←0 ⎕EXPORT ⎕NL 3 4
    ___←1 ⎕EXPORT {⍵[⍋↑⍵]}{⍵⊆⍨' '≠⍵}  _namelist_
    ⎕PATH←⎕THIS{0=≢⎕PATH:⍕⍺⊣⎕← '⎕PATH was "". Setting to "',(⍕⍺),'"'⋄ ⍵}⎕PATH
    ⎕EX '___'
    :EndSection Bigint Namespace - Postamble
:ENDNAMESPACE
