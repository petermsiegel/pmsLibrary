∆F← { 
  ⍺←1  
  (⊃⍺)∘( (⊃⎕RSI) { 

    0:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('Blobs ',EM) EN Message) 
      1=⍺: ⍺⍺⍎⍵                 ⍝ ⍵ contains an embedded ⍵⍵ with the original main fn right arg ⍵
      0=⍺: ⍵ 
      1:   ⍵            
      ⍵⍵                        ⍝ Declare 2-adic operator
 
  }⍵)⍺∘{                                      
 
    o e← 2↑⍺,'`'                         ⍝ o: option flag, e: escape char.
    fmt← ⊃⊆⍵
    omNxtg← 0
    chainFn← '⊃{⊃,/⍺⍵↑⍨¨⌈⍥≢/⍺⍵}⍥⎕FMT/⌽'
    chainTk← ⊂'⍁C/'

    nl← ⎕UCS 13
    sq dq← '''"' 
    dq2← dq dq 
  
    ee←   '\', e                         ⍝ ⎕R-ready (escaped) escape char. Used in many patterns bellow.
    es←   ee,  '[{}⋄⍵',ee,']'            ⍝ escape sequences
    escP← ee, '([{}⋄⍵',ee,'])'           ⍝ escape pattern
    nlP← ee, '⋄'                         ⍝ `⋄   
  
    sqP←     '(''[^'']*'')+'
    dqP←     '("[^"]*")+'
    fmtP←    '\$\s?'
    omP←     '(?|[⍵⍹](\d+)|',ee,'⍵()|⍹())'         ⍝ absolute: ⍵3, ⍹3; positional: `⍵, ⍹ 
    comP←    '⍝([^{}⋄',ee,']+|', es,')*'

    tP← '(([^{',ee,']+|', es,')+)'
    s1P← '(?x) \{ (\h*) \}'                                  ⍝ {     }, {}, etc.
    s2P← '(?x) \{  \h* :\h*   (\d+)   (\h*:)? \h* \}'        ⍝ { :3: }, etc.
    sOP← '(?x) \{  \h* :\h*',  omP, ' (\h*:)? \h* \}'        ⍝ { :⍵4: }, { :⍹4: }, { :`⍵: }, { :⍹: }, etc.
    cP←  '(?x) (?<P> \{ ((?>  [^{}"''⍝',ee,']+ | (?:', es,')+  | '
    cP,← '     (?:"[^"]*")+ | (?:''[^'']*'')+ | ⍝([^}⋄',ee,']* |', es,')* | (?&P)* )+)  \} )' 

    Dlb←  { ⍵↓⍨ +/∧\⍵= ' '}
    F←    {⍺.(⌷∘Lengths↑Block↓⍨⌷∘Offsets)⍵}
    EnQ←  { ⍺←sq ⋄ ⍺, ⍺,⍨ ⍵/⍨ 1+⍺=⍵ }
    Om←   { 0≠≢⍵: ⍵⊣ omNxtg⊢← ⊃⌽⎕VFI ⍵   ⋄ ⍕omNxtg⊣ omNxtg+← 1 }
    UnDQ← { t/⍨ ~dq2⍷t← 1↓¯1↓⍵ }

    Text←{
        qln← EnQ∊ ln← ⎕FMT nlP escP ⎕R nl '\1'⊣ ⍵  
        1= ≢∊ln: '(,',   qln, ')'    ⍝ scalar => 1-elem vector
        1= ≢ln:  '(',    qln, ')'    ⍝ vector
        '(', (⍕⍴ln),'⍴', qln, ')'    ⍝ array <= multiline
    }
    Code←{
      ⍝ extern: omNxtg, ...P 
        patV← sqP dqP fmtP omP comP
              sqI dqI fmtI omI comI← ⍳≢patV
        t←  patV ⎕R {
            C← ⍵.PatternNum∘= ⋄ F← ⍵∘F
            C sqI:  Text 1↓¯1↓ F 0 
            C dqI:  Text UnDQ  F 0  
            C fmtI: '⎕FMT '
            C omI:  '(⍵⊃⍨⎕IO+', f1, ')' ⊣ f1← Om F 1 
            C comI: ' '
        } ⍵ 
        '({', '}⍵)',⍨ t 
    }
    Spaces← { 
        1=⍺: '('' ''⍴⍨','⍵⊃⍨⎕IO+', ')',⍨ Om ⍵ 
        0=⍵: '('''')' 
        1=⍵: '('' '')'  
        '(',(⍕⍵),'⍴'' '')' 
    }

    patV← tP s1P s2P sOP cP 
          tI s1I s2I sOI cI←⍳≢ patV   
    code← patV  ⎕R {
         C←  ⍵.PatternNum∘=
         F←  ⍵∘F 
         E←  ,∘nl

         C tI:   E Text F 1 
         C s1I:  E 0 Spaces ≢F 1
         C s2I:  E 0 Spaces  F 1 
         C sOI:  E 1 Spaces  F 1 
         C cI:   E Code F 2                                ⍝ F 2 omits surrounding braces.
    } ⊆fmt 

    ¯1=o: chainTk, code,  ⊂'}(⊂', (EnQ fmt), '),⍥⊂⍵'       ⍝ ¯1: Each field a separate char vec L to R
        c← chainFn, '⍬',⍨∊⌽code
     0=o: '{{', c, '}(⊂',(EnQ fmt),'),⍵}'                  ⍝  0: Executable version displayed (R to L)
          '{',  c, '},⊆⍵⍵'                                 ⍝  1: Execute in caller env (R to L)
 
  } ⍵
}