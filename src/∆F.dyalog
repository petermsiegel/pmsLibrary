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

  (⊃⍺)∘( (⊃⎕RSI) { ⍝ No variable pollution allowed (at least until after ⍎)
    0:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message) 
    1=⍺: ⍺⍺⍎⍵ ⋄ 0=⍺: ⍵ ⋄ 1: ⍵                         ⍝ ⍵ contains a ⍵⍵, with the original (input) format string  
    ⍵⍵                                                                                
  }⍵)⍺∘{        

    0:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message) 
  
        (m b)e←(2↑⍺)(⊃⌽'`',2↓⍺)                       ⍝ m: mode flag, b: box flag, e: escape char.
        fmt← ⊃⊆⍵

        omegaIx← 0                                    ⍝ supports absolute and positional ⍵ feature: ⍵3, ⍹3; `⍵, ⍹ 
        preamble← b {                                 ⍝ set preamble code based on options <b> and <m>
              chnC← '⊃{⊃,/⍺⍵↑⍨¨⌈⍥≢/⍺⍵}⍥⎕FMT/⌽'  '⍁C/' ⊃⍨ ⍵    ⍝ full and symbolic chain code per <m>
          ~⍺: chnC                                            ⍝ ~⍺: return simple horizontal chain code
              boxC← '⎕SE.Dyalog.Utils.display¨' '⍁B¨' ⊃⍨ ⍵    ⍝ full and symbolic box code per <m>
              chnC, boxC                                      ⍝ ⍺:  return horizontal chain code and "box" (display) code                  
        } m<0
    
        nl← ⎕UCS 13
        sq← '''' 
        dq2← dq dq←'"'
      
        ee←   '\', e                                  ⍝ ⎕R-ready (escaped) escape char. Used in many patterns bellow.
        es←   ee,  '[{}⋄⍵',ee,']'                     ⍝ escape sequences
        escP← ee, '([{}⋄⍵',ee,'])'                    ⍝ escape pattern
        nlP← ee, '⋄'                                  ⍝ newline pattern (→ nl)
      
        sqP←     '(''[^'']*'')+'
        dqP←     '("[^"]*")+'
        fmtP←    '\$\s?'
        omP←     '(?|[⍵⍹](\d+)|',ee,'⍵()|⍹())'        ⍝ absolute: ⍵3, ⍹3; positional: `⍵, ⍹ 
        comP←    '⍝([^{}⋄',ee,']+|', es,')*'

        tP← '((', es,'?|[^{',ee,']+)+)'
        s0P← '\{(\h*:\h*0*\h*(:\h*)?)?\}'                        ⍝ Null space field: {} or { :0: }
        s1P← '(?x) \{ (\h*) \}'                                  ⍝ {     }, {}, etc.
        s2P← '(?x) \{  \h* :\h*   (\d+)   (\h*:)? \h* \}'        ⍝ { :3: }, etc.
        sOmP← '(?x) \{  \h* :\h*',  omP, ' (\h*:)? \h* \}'       ⍝ { :⍵4: }, { :⍹4: }, { :`⍵: }, { :⍹: }, etc.
        cP←  '(?x) (?<P> \{ ((?>  [^{}"''⍝',ee,']+ | (?:', es,')+  | '
        cP,← '     (?:"[^"]*")+ | (?:''[^'']*'')+ | ⍝([^}⋄',ee,']* |', es,')* | (?&P)* )+)  \} )' 

        P←    '('∘,,∘')'                                         ⍝ Parenthesize
        E←    nl,⍨P                                              ⍝ envelope for ∆F fields
        F←    {⍺.(⌷∘Lengths↑Block↓⍨⌷∘Offsets)⍵}                  ⍝ ⎕R fields
        EnQ←  { ⍺←sq ⋄ ⍺, ⍺,⍨ ⍵/⍨ 1+⍺=⍵ }                        ⍝ Convert generic string to sq string
        UnDQ← { t/⍨ ~dq2⍷ t← 1↓¯1↓ ⍵ }                           ⍝ Unconvert dq string to generic string
        Dtb←{⍵↓⍨-+/∧\⌽⍵=' '}
        S2Cod← {                                                 ⍝ poss. multiline string to executable code
            res← 1↓ ∊ ' '∘,∘EnQ⍤Dtb¨↓ ⍵
            1=≢⍵: res ⋄ P '↑',res                                ⍝ vec or scalar? output as is. Otherwise, mix!
        } ⎕FMT  
        Om← { 0≠≢⍵: ⍵⊣ omegaIx⊢← ⊃⌽⎕VFI ⍵                        ⍝ ⍵-feature, including positional vars.
              ⍕omegaIx⊣ omegaIx+← 1 
        } 
 

        Text←  S2Cod nlP escP ⎕R nl '\1'                         ⍝ Process Text fields
        Code←{                                                   ⍝ Process Code fields
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
        Space← {                                                 ⍝ Process Space fields (which look like degenerate code fields)
            1=⍺: '''''⍴⍨','⍵⊃⍨⎕IO+', Om ⍵                        ⍝ Handle { :⍵dd: }, { :⍹: }, etc.
            0=⍵: ''''''  ⋄ (⍕⍵),'⍴'''''                          ⍝ Handle {...} and { :dd: }
        }
                                                                 ⍝ Perform main scan of format string
        patV← tP s0P s1P s2P sOmP cP 
              tI s0I s1I s2I sOmI cI←⍳≢ patV   
        code← patV  ⎕R {
            C← ⍵.PatternNum∘= ⋄ F←  ⍵∘F 
            C tI:   E   Text   F 1                               ⍝ Text field
            C s0I:  ''                                           ⍝ Null space fields emit nothing!
            C s1I:  E 0 Space ≢F 1                               ⍝ Space field  {      }
            C s2I:  E 0 Space  F 1                               ⍝ ...          { :25: }
            C sOmI: E 1 Space  F 1                               ⍝ ...          { :⍵5: } or { :⍹: }
            C cI:   E   Code   F 2                               ⍝ Code field
        } ⊆fmt 

    ¯1=m: (⊂preamble),   code,  ⊂'}(⊂', (EnQ fmt), '),⍥⊂⍵'       ⍝ ¯1: Each field a separate char vec L to R
       c←   preamble, (∊⌽code), '⍬'/⍨1≥≢code                     ⍝ '⍬': Ensure at least 2 fields needed for preamble
    0=m: '{{', c, '}(⊂',(EnQ fmt),'),⍵}'                         ⍝  0: Generate code executable ⍎ as string (R to L)
      '{',  c, '},⊆⍵⍵'                                           ⍝  1: Execute code in caller env (R to L)
    
  } ⍵
}