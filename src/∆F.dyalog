∆F← { 
⍝ Simple formatting  function in APL style, inspired by Python f-strings.
⍝ Syntax: [opts] ∆F f-string  args 
⍝        f-string: char vector with formatting specifications
⍝        args: arguments visible to f-string code expressions 
⍝              ⍹1=1st arg after f-string (⎕IO independent)
⍝        opts: [MODE←1 BOX←0 ESCAPE_CH←'`'] | 'help' | ⍬]  
⍝ For help, execute                                             *=Any case
⍝   ∆F⍨'help' ... or see ⍝H "HELP" comments at the bottom of this function.
⍝ See help PDF at:
⍝   https://drive.google.com/file/d/1x82YiNDTHlw0uMFgcElIRSFfK_PnLeOq/view

  ⎕IO ⎕ML←0 1
  ⍺←1 0 '`' ⋄ ⍬≡⍺: _←1 0⍴'' ⋄ 'help'≡⍥⎕C⍺: ⎕←'No help available yet'

  (⊃⍺)∘( (⊃⎕RSI) {                                               ⍝ No variable pollution allowed (at least until after ⍎)
      0:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message) 
      1=⍺: ⍺⍺⍎⍵ ⋄ 0=⍺: ⍵ ⋄ 1: ⍵                                  ⍝ ⍵ contains a ⍵⍵, with the original (input) format string  
      ⍵⍵                                                                                
  }⍵)⍺∘{        

    0:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message) 
  
        (m b)e←(2↑⍺)(⊃⌽'`',2↓⍺)                                  ⍝ m: mode flag, b: box flag, e: escape char (unescaped)
        fmt← ⊃⊆⍵

        omegaIx← 0                                               ⍝ supports absolute and positional ⍵ feature: ⍵3, ⍹3; `⍵, ⍹ 
        preamble← b {                                            ⍝ set preamble code based on options <b> and <m>
              chnC← '⊃{⊃,/⍺⍵↑⍨¨⌈⍥≢/⍺⍵}⍥⎕FMT/⌽'  '⍁C/' ⊃⍨ ⍵       ⍝ full and symbolic chain code per <m>
          ~⍺: chnC                                               ⍝ ~⍺: return simple horizontal chain code
              boxC← '⎕SE.Dyalog.Utils.display¨' '⍁B¨' ⊃⍨ ⍵       ⍝ full and symbolic box code per <m>
              chnC, boxC                                         ⍝ ⍺:  return horizontal chain code and "box" (display) code                  
        } m<0
    
        nl← ⎕UCS 13
        sq← '''' 
        dq2← dq dq←'"'
      
        ee←   '\', e                                             ⍝ ee: ⎕R-ready escaped escape char.  
        es←   ee,  '[{}⋄⍵',ee,']'                                ⍝ es: escape sequences
        eP←   ee, '([{}⋄⍵',ee,'])'                               ⍝ eP: escape pattern. F1 is the escaped char.
        nP←   ee, '⋄'                                            ⍝ nP: newline pattern (→ nl)
      
        sqP←     '(''[^'']*'')+'                    
        dqP←     '("[^"]*")+'
        fmtP←    '\$\s?'                                         ⍝ fmtP: match $ as alias to ⎕FMT
        omP←     '(?|[⍵⍹](\d+)|',ee,'⍵()|⍹())'                   ⍝ omP: ⍵ (omega) patterns: ⍵3, ⍹3; `⍵, ⍹ 
        cmP←     '⍝([^{}⋄',ee,']+|', es,')*'                     ⍝ cmP: limited comment pattern

        tP← '((', es,'?|[^{',ee,']+)+)'                          ⍝ tP: text field pattern
                                                                 ⍝ s0P, etc: space field patterns
        s0P← '\{(\h*:\h*0*\h*(:\h*)?)?\}'                        ⍝   null space field: {} or { :0: }
        sEP← '(?x) \{ (\h*) \}'                                  ⍝   space by example: {     }, {}, etc.
        sNP← '(?x) \{  \h* :\h*   (\d+)   (\h*:)? \h* \}'        ⍝   space by number { :3: }, etc.
        sOmP← '(?x) \{  \h* :\h*',  omP, ' (\h*:)? \h* \}'       ⍝   space by ⍵ argument (see omP above)
                                                                 ⍝ cP: code field pattern
        cP←  '(?x) (?<P> \{ ((?>  [^{}"''⍝',ee,']+ | (?:', es,')+  | ' 
        cP,← '     (?:"[^"]*")+ | (?:''[^'']*'')+ | ⍝([^}⋄',ee,']* |', es,')* | (?&P)* )+)  \} )' 

        P←    '('∘,,∘')'                                         ⍝ Parenthesize
        N←    ,∘nl                                               ⍝ Append a newline
        S←    ,∘' '                                              ⍝ Append a space
        F←    {⍺.(⌷∘Lengths↑Block↓⍨⌷∘Offsets)⍵}                  ⍝ ⎕R fields
        EnQ←  { ⍺←sq ⋄ ⍺, ⍺,⍨ ⍵/⍨ 1+⍺=⍵ }                        ⍝ Convert generic string to sq string
        UnDQ← { t/⍨ ~dq2⍷ t← 1↓¯1↓ ⍵ }                           ⍝ Unconvert dq string to generic string
        Dtb←{⍵↓⍨-+/∧\⌽⍵=' '}
        Om← { 0≠≢⍵: ⍵⊣ omegaIx⊢← ⊃⌽⎕VFI ⍵                        ⍝ ⍵-feature, including positional vars.
              ⍕omegaIx⊣ omegaIx+← 1 
        }  

        Text← {                                                  ⍝ Process Text fields
            1=≢⍵:   S      EnQ ∊⍵                                ⍝ vec or scalar? Output as is. Otherwise, mix!
            1=⊃⌽⍴⍵: P '⍪', EnQ ∊⍵                                ⍝ 1 col matrix
                    P (⍕⍴⍵),'⍴', EnQ ∊⍵                          ⍝ General case: ⎕ML-independent version!
                  ⍝ P '↑', 1↓ ∊ ' '∘,∘EnQ⍤Dtb¨↓ ⍵                ⍝ General case: ⎕ML∊0 1 in calling env!...  
        } (⎕FMT nP eP ⎕R nl '\1')
        Code←{                                                   ⍝ Process Code fields
          ⍝ :extern omegaIx, ...P 
            patV← sqP dqP fmtP omP cmP
                  sqI dqI fmtI omI comI← ⍳≢patV
            t←  patV ⎕R {
                C← ⍵.PatternNum∘= ⋄ F← ⍵∘F
                C sqI:  Text 1↓¯1↓ F 0 
                C dqI:  Text UnDQ  F 0  
                C fmtI: '⎕FMT '                                  ⍝ "..." $ ... ==> '...' ⎕FMT ...
                C omI:  P '⍵⊃⍨⎕IO+', f1 ⊣ f1← Om F 1             ⍝ Handle ⍵dd, ⍹, etc. in code expressions
                C comI: ' '                                      ⍝ Limited comments in code fields
            } ⍵ 
            '{', '}⍵',⍨ t 
        }                                                        
        Space← { s←''''''                                        ⍝ Process Space fields (which look like degenerate code fields)
            1=⍺: s, '⍴⍨⍵⊃⍨⎕IO+', Om ⍵                            ⍝ Handle { :⍵dd: }, { :⍹: }, etc.
            0=⍵: s  ⋄ (⍕⍵),'⍴',s                                 ⍝ Handle {...} and { :dd: }
        }
                                                                 ⍝ Perform main scan of format string
        patV← tP s0P sEP sNP sOmP cP 
              tI s0I s1I s2I sOmI cI←⍳≢ patV   
        code← patV  ⎕R {
            C← ⍵.PatternNum∘= ⋄ F←  ⍵∘F 
            C tI:   N     Text   F 1                             ⍝ Text field
            C s0I:  ''                                           ⍝ Null space fields emit nothing!
            C s1I:  N P 0∘Space ≢F 1                             ⍝ Space field  {      }
            C s2I:  N P 0∘Space  F 1                             ⍝ ...          { :25: }
            C sOmI: N P 1∘Space  F 1                             ⍝ ...          { :⍵5: } or { :⍹: }
            C cI:   N P   Code   F 2                             ⍝ Code field
        } ⊆fmt 

    ¯1=m: '{',(⊂preamble), code,  ⊂'}(⊂', (EnQ fmt), '),⍥⊂⍵'     ⍝ ¯1: Each field a separate char vec L to R
       c←  preamble, (∊⌽code), '⍬'/⍨ 1≥≢code                     ⍝ '⍬': Ensure at least 2 fields; needed for preamble
     0=m: '{{', c, '}(⊂',(EnQ fmt),'),⍵}'                        ⍝  0: Generate code executable ⍎ as string (R to L)
      '{',  c, '},⊆⍵⍵'                                           ⍝  1: Execute code in caller env (R to L)
    
    } ⍵
}