∆F← { 
  ⍺←1 0 '`'   
  (⊃⍺)∘( (⊃⎕RSI) { 

    0:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message) 
    1=⍺: ⍺⍺⍎⍵                                         ⍝ ⍵ contains an embedded ⍵⍵ <= main fn ⍵
    0=⍺: ⍵ 
    1:   ⍵            
        ⍵⍵                                            ⍝ Declare as 2-adic operator
 
  }⍵)⍺∘{        

    0:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message) 
  
        (o b)e←(2↑⍺)(⊃⌽'`',2↓⍺)                       ⍝ o: option flag, b: box flag, e: escape char.
        fmt← ⊃⊆⍵

        omegaIx← 0                                    ⍝ supports absolute and positional ⍵ enhancement: ⍵3, ⍹3; `⍵, ⍹ 
        preamble← b {                                 ⍝ set preamble code based on options <b> and <o>
              chnC← '⊃{⊃,/⍺⍵↑⍨¨⌈⍥≢/⍺⍵}⍥⎕FMT/⌽'  '⍁C/' ⊃⍨ ⍵    ⍝ full and symbolic chain code per <o>
          ~⍺: chnC                                            ⍝ ~⍺: return simple horizontal chain code
              boxC← '⎕SE.Dyalog.Utils.display¨' '⍁B¨' ⊃⍨ ⍵    ⍝ full and symbolic box code per <o>
              chnC, boxC                                      ⍝ ⍺:  return horizontal chain code and "box" (display) code                  
        } o<0
    
        nl← ⎕UCS 13
        sq dq← '''"' 
        dq2← dq dq 
      
        ee←   '\', e                                  ⍝ ⎕R-ready (escaped) escape char. Used in many patterns bellow.
        es←   ee,  '[{}⋄⍵',ee,']'                     ⍝ escape sequences
        escP← ee, '([{}⋄⍵',ee,'])'                    ⍝ escape pattern
        nlP← ee, '⋄'                                  ⍝ `⋄   
      
        sqP←     '(''[^'']*'')+'
        dqP←     '("[^"]*")+'
        fmtP←    '\$\s?'
        omP←     '(?|[⍵⍹](\d+)|',ee,'⍵()|⍹())'        ⍝ absolute: ⍵3, ⍹3; positional: `⍵, ⍹ 
        comP←    '⍝([^{}⋄',ee,']+|', es,')*'

        tP← '((', es,'?|[^{',ee,']+)+)'
        s1P← '(?x) \{ (\h*) \}'                                  ⍝ {     }, {}, etc.
        s2P← '(?x) \{  \h* :\h*   (\d+)   (\h*:)? \h* \}'        ⍝ { :3: }, etc.
        sOP← '(?x) \{  \h* :\h*',  omP, ' (\h*:)? \h* \}'        ⍝ { :⍵4: }, { :⍹4: }, { :`⍵: }, { :⍹: }, etc.
        cP←  '(?x) (?<P> \{ ((?>  [^{}"''⍝',ee,']+ | (?:', es,')+  | '
        cP,← '     (?:"[^"]*")+ | (?:''[^'']*'')+ | ⍝([^}⋄',ee,']* |', es,')* | (?&P)* )+)  \} )' 

        Dlb←  { ⍵↓⍨ +/∧\⍵= ' '}                                  ⍝ unused
        E←   '('∘,,∘(')',nl)                                     ⍝ envelope for ∆F fields
        F←    {⍺.(⌷∘Lengths↑Block↓⍨⌷∘Offsets)⍵}                  ⍝ ⎕R fields
        EnQ←  { ⍺←sq ⋄ ⍺, ⍺,⍨ ⍵/⍨ 1+⍺=⍵ }                        ⍝ Convert generic string to sq string
        Om←   { 0≠≢⍵: ⍵⊣ omegaIx⊢← ⊃⌽⎕VFI ⍵   ⋄ ⍕omegaIx⊣ omegaIx+← 1 } ⍝ ⍵-enhancement, including positional vars.
        UnDQ← { t/⍨ ~dq2⍷ t← 1↓¯1↓ ⍵ }                           ⍝ Unconvert dq string to generic string

        Text←{                                                   ⍝ Text fields
            qln← EnQ∊ ln← ⎕FMT nlP escP ⎕R nl '\1'⊣ ⍵  
            1= ≢∊ln: ',', qln                                    ⍝ scalar => 1-elem vector
            1= ≢ln:       qln                                    ⍝ vector
                          qln, '⍴⍨', ⍕⍴ln                        ⍝ array <= multiline
        }
        Code←{                                                   ⍝ Code fields
          ⍝ :extern omegaIx, ...P 
            patV← sqP dqP fmtP omP comP
                  sqI dqI fmtI omI comI← ⍳≢patV
            t←  patV ⎕R {
                C← ⍵.PatternNum∘= ⋄ F← ⍵∘F
                C sqI:  Text 1↓¯1↓ F 0 
                C dqI:  Text UnDQ  F 0  
                C fmtI: '⎕FMT '                                  ⍝ "..." $ ... ==> '...' ⎕FMT ...
                C omI:  '(⍵⊃⍨⎕IO+', f1, ')' ⊣ f1← Om F 1         ⍝ Handle ⍵dd, ⍹, etc. in code expressions
                C comI: ' '                                      ⍝ Limited comments in code fields
            } ⍵ 
            '{', '}⍵',⍨ t 
        }                                                        
        Space← {                                                 ⍝ Space fields (which look like degenerate code fields)
            1=⍺: '''''⍴⍨','⍵⊃⍨⎕IO+', Om ⍵                        ⍝ Handle { :⍵dd: }, { :⍹: }, etc.
            0=⍵: ''''''  ⋄ (⍕⍵),'⍴'''''                          ⍝ Handle {...} and { :dd: }
        }
                                                                 ⍝ Perform main scan of format string
        patV← tP s1P s2P sOP cP 
              tI s1I s2I sOI cI←⍳≢ patV   
        code← patV  ⎕R {
            C← ⍵.PatternNum∘= ⋄ F←  ⍵∘F 
            C tI:   E   Text   F 1                               ⍝ Text field
            C s1I:  E 0 Space ≢F 1                               ⍝ Space field  {      }
            C s2I:  E 0 Space  F 1                               ⍝ ...          { :25: }
            C sOI:  E 1 Space  F 1                               ⍝ ...          { :⍵5: } or { :⍹: }
            C cI:   E   Code   F 2                               ⍝ Code field
        } ⊆fmt 

    ¯1=o: (⊂preamble),   code,  ⊂'}(⊂', (EnQ fmt), '),⍥⊂⍵'       ⍝ ¯1: Each field a separate char vec L to R
       c←   preamble, (∊⌽code), '⍬'/⍨1≥≢code                     ⍝ '⍬': Ensure at least 2 fields needed for preamble
    0=o: '{{', c, '}(⊂',(EnQ fmt),'),⍵}'                         ⍝  0: Generate code executable ⍎ as string (R to L)
      '{',  c, '},⊆⍵⍵'                                           ⍝  1: Execute code in caller env (R to L)
    
  } ⍵
}