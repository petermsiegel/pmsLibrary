∆F← { 
⍝H ∆F: Simple formatting  function in APL style, inspired by Python f-strings.
⍝! For documentation, see ⍝H comments below.

  ⎕IO ⎕ML←0 1

  ⍺←1 0 '`' ⋄ ⍬≡⍺: _←1 0⍴'' ⋄ 'help'≡⍥⎕C⍺: ⎕ED⍠ 'ReadOnly' 1⊢ 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⎕XSI  

  (⊃⍺)∘( (⊃⎕RSI) {                                               ⍝ No variable pollution allowed (at least until after ⍎)
    0:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message) 
    1=⍺: ⍺⍺⍎⍵ ⋄ 0=⍺: ⍵ ⋄ 1: ⍵                                    ⍝ ⍵ contains a ⍵⍵, with the original (input) format string  
      ⍵⍵                                                                                
  }⍵)⍺∘{        

    90:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message) 
  
      (mo bo)eo←(2↑⍺)(⊃⌽'`',2↓⍺)                                 ⍝ mo  mode option, bo: box option, eo: escape char (unescaped)
      fmt← ⊃⊆⍵
      omIx← 0                                                    ⍝ omIx   supports absolute and positional ⍵ feature: ⍵3, ⍹3; `⍵, ⍹ 

      hdrDef←     '⊃{⊃,/⍺⍵↑⍨¨⌈⍥≢/⍺⍵}⍥⎕FMT/⌽'  '⍙ⒸⒽⒶⒾⓃ/' ⊃⍨ mo<0  ⍝ hdrDef set preamble code based on options mo and bo
      hdrDef,← bo/'⎕SE.Dyalog.Utils.display¨' '⍙ⒷⓄⓍ¨'   ⊃⍨ mo<0  ⍝ Use symbolic def if mode is ¯1 (show pseudocode)
                                                                 ⍝ Aliases: $ => ⎕FMT, % => ⍙ÔVR (display ⍺ over ⍵)
      aKeys←  ,¨'$' '%'                                          ⍝ aKeys Alias input (k̲eys)  
      aVals←   '⎕FMT ' '⍙ⓄⓋⓇ '                                   ⍝ aVals Alias v̲alue for each key
      ovrDef← '⍙ⓄⓋⓇ←(⊃⍪/)⍤{T←↑⍤¯1⋄m←⌈/w←⍺,⍥(⊃⌽⍤⍴)⍵⋄w{⍺=m:⍵⋄'     ⍝ ⍙ⓄⓋⓇ code def
      ovrDef,←                   'm T⍵T⍨-⌊⍺+2÷⍨m-⍺}¨⍺⍵}⍥⎕FMT⋄ ' 
      ovrF←   0                                                  ⍝ ovrF: 1 to emit ovrDef (see Set preamble) 
   
      nl← ⎕UCS 13
      sq2← sq,sq← '''' 
      dq←  '"'
      ec←  '\', eo                                               ⍝ ec  ⎕R-ready e̲scape c̲har.  
      es←  ec,  '[{}⋄⍵⍹',ec,']'                                  ⍝ es  e̲scape s̲equence
      esc← ec, '([{}⋄⍵⍹',ec,'])'                                 ⍝ esc e̲scape s̲equence c̲aptured

    ⍝ ......                                                     ⍝ Basic patterns (for ⎕R)
      eP←   esc                                                  ⍝ eP   e̲scape pattern. F1 is the escaped char.
      nP←   ec, '⋄'                                              ⍝ nP   newline pattern (→ nl)
      oP←   ec, '⍵'                                              ⍝ oP   esc ⍵ → ⍹
      sqP←  '(''[^'']*'')+'                    
      dqP←  '("[^"]*")+'
      aliasP← '([%$])\s?'                                        ⍝ aliasP  match $ (alias to ⎕FMT) or % ("over")
      omP←   ec,'?[⍵⍹](\d*)'                                     ⍝ omP   ⍵ (omega) patterns: ⍵3, ⍹3; `⍵, ⍹ (permissive)
      cmP←  '⍝([^{}⋄',ec,']+|', es,')*'                          ⍝ cmP   limited comment pattern

     ⍝ ......                                                    ⍝ tP: text field pattern
      tP←   '((', es,'?|[^{',ec,']+)+)'                          

     ⍝ ......                                                    ⍝ s0P, etc: space field patterns
      hb he← '\h*:\h*' '(?:\h*:)?\h*'                                                                   
      s1P← '\{(\h*)\}' 
      s2P← '\{',hb,'(\d*)',he,'\}'
      s3P← '\{',hb,omP,,he,'\}'
     
    ⍝ ......                                                     ⍝ cP: code field pattern
      cP←  '(?x) (?<P> \{ ((?>  [^{}"''⍝',ec,']+ | (?:', es,')+  | ' 
      cP,← '     (?:"[^"]*")+ | (?:''[^'']*'')+ | ⍝([^}⋄',ec,']* |', es,')* | (?&P)* )+)  \} )' 
   
      AG← aVals∘{ ~⍵: 0⊃⍺ ⋄ mo<0: 1⊃⍺ ⋄ 1⊃⍺⊣ ovrF⊢← 1 }aKeys⍳⊂   ⍝ AG: Get value for alias key '$' or '%'
      F←  {⍵≥≢⍺.Lengths: '' ⋄ ⍺.(⌷∘Lengths↑Block↓⍨⌷∘Offsets)⍵}   ⍝ F Select a ⎕R F̲ield
      N←  ,∘nl                                                   ⍝ N Append a N̲ewline
      O←  {0≠≢⍵: ⍵⊣ omIx⊢← ⊃⌽⎕VFI ⍵ ⋄ ⍕omIx⊣ omIx+← 1}           ⍝ O O̲mega ⍵-feature, including positional vars.
      P←  '('∘,,∘')'                                             ⍝ P P̲arenthesize
      Q←  sq∘{ ⍺, ⍺,⍨ ⍵/⍨ 1+⍺= ⍵ }                               ⍝ Q Convert generic string to sq Q̲uoted string
      S←  ,∘' '                                                  ⍝ S Append a S̲pace 
      T← { q← Q ∊⍵                                               ⍝ T Process T̲ext in strings and text fields
           1=≢⍵:              S q                                ⍝   vec or scalar? Output as is. Otherwise, mix!
           1=⊃⌽⍴⍵:       P '⍪', q                                ⍝   1 col matrix
                   P (⍕⍴⍵),'⍴', q                                ⍝   General case: ⎕ML-independent version!
      }⍤(⎕FMT nP oP eP ⎕R nl '⍹' '\1')                           ⍝   Preprocess `⋄, `⍵, `{, `}, etc.
      U←  dq∘{ ⍵/⍨ ~⍵⍷⍨ ⍺,⍺ }1↓¯1↓⊢                              ⍝ U U̲nconvert dq string to generic string

                                                          ⍝ ***  ⍝   Process fields: TF, CF, SF 
      TF← N T        ⍝ ......                                    ⍝   Process Text fields (adding newline)
      CF← N P⍤ {     ⍝ ......                                    ⍝   Process Code fields (adding parens and newline)
          patV← sqP dqP aliasP omP cmP
                sqI dqI aliasI omI comI← ⍳≢patV
          t←  patV ⎕R {
              C← ⍵.PatternNum∘= ⋄ F← ⍵∘F
              C sqI:  T 1↓¯1↓ F 0 
              C dqI:  T U  F 0          
              C aliasI: AG F 1                                   ⍝   $ => ⎕FMT, % => ⍙ÔVR (display over)
              C omI:  P '⍵⊃⍨⎕IO+', f1 ⊣ f1← O F 1                ⍝   Handle ⍵dd, ⍹, etc. in code field expressions
              C comI: ' '                                        ⍝   Limited comments in code fields
          } ⍵ 
          '{', '}⍵',⍨ t 
      }               
      SF← {          ⍝ ......                                    ⍝   Process Space fields 
           C← ⍺∘=                              ⍝ Case   
           C 3:           N P sq2,'⍴⍨⍵⊃⍨⎕IO+',O ⍵        ⍝ ⍺=3   ⍝   { :⍵3: } etc.    
          (C 1)∧0=≢⍵:     ''                             ⍝ ⍺=1   ⍝   {}                     => Null field
           C 1:           N P (⍕≢⍵),'⍴',sq2              ⍝ ⍺=1   ⍝   {  }
           '0'∧.=⍵:       ''                             ⍝ ⍺=2   ⍝   { :0: }, { :: }, etc.  => Null field
                          N P ⍵,'⍴',sq2                  ⍝ ⍺=2   ⍝   { :5: }            
      }
    ⍝ ......                                                     ⍝ Perform main scan of format string
      patV← tP s1P s2P s3P cP 
            tI _ _ _ cI←⍳≢ patV  
      code← patV  ⎕R {
          C← (sn← ⍵.PatternNum)∘∊ ⋄ F← ⍵∘F  
          C tI:      TF F 1                                      ⍝   Text  field
          C cI:      CF F 2                                      ⍝   Code  field
                  sn SF F 1                                      ⍝   Space field (sn∊1 2 3)
      } ⊆fmt 
 
            p← hdrDef,⍨ ovrF/ ovrDef                             ⍝ Set preamble from header def and ⍙ÔVR def (if used)
    ¯1=mo: (⊂'{',p), code,  ⊂'}(⊂', (Q fmt), '),⍥⊂⍵'             ⍝ ¯1: Each field a separate char vec L to R
            p,← (∊⌽code), '⍬'/⍨ 1≥≢code                          ⍝  ⍬: Ensure at least 2 fields; 2 needed for Chain
     0=mo: '{{', p, '}(⊂',(Q fmt),'),⍵}'                         ⍝  0: Generate code executable ⍎ as string (R to L)
           '{',  p, '},⊆⍵⍵'                                      ⍝  1: Execute code in caller env (R to L)
  
    } ⍵

⍝H Syntax: 
⍝H     [mode←1 box←0 escCh←'`' | ⍬ | 'help'] ∆F f-string  args 
⍝H 
⍝H     ⍵← f-string [[⍵1 ⍵2...]]
⍝H        f-string: char vector with formatting specifications.
⍝H               See below.
⍝H        args:  arguments visible to all f-string code expressions 
⍝H               ⍹1: 1st arg after f-string, ⍹2: 2nd, ...; ⍹0 is the f-string itself.
⍝H               ⍹ alone: is the "next" arg left to right (starts with ⍹1)
⍝H               In place of ⍹1, ⍵1 can be used. In place of simple ⍹, `⍵ can be used (` the escape char).
⍝H     ⍺← 1 0 '`' 
⍝H        mode:  1= generate code, execute, and display result [default]
⍝H               0= emit code you can execute via ⍎ . The format string is available as ⍹0.
⍝H              ¯1= generate pseudo code with each field a separate character vector.
⍝H        box:   1= display each field in a box (display from dfns).
⍝H               0= display each field simply [default]
⍝H        escCh: used to ensure or suppress special behavior.
⍝H               default is '`'. Common alternative is '\'.
⍝H               Suppresses special behavior of {, }, `.
⍝H               Enables special behavior of `⋄ and `⍵.
⍝H        ⍬:     causes ∆F to do nothing, returning shy
⍝H                 1 0⍴''
⍝H         'help': shows this help information.
⍝H    Returns: Per mode above:
⍝H       [1]  formatted output, 
⍝H       [0]  code which will create that output, or
⍝H       [¯1] pseudo-code for inspection (debugging or pedagogy).
⍝H    or, if ⍺≡⍬:
⍝H       1 0⍴''
⍝H
⍝H The f-string is a character vector defining 0 or more 2-D (char matrix) "fields," 
⍝H which are executed like separate statements-- left to right-- and assembled into a single matrix 
⍝H (with fields top-aligned). Its contents are in "shortcut" variable ⍹0.
⍝H
⍝H There are 3 types of fields generated: 
⍝H    1. Code Fields, 2. Space Fields, and 3. Text Fields.
⍝H 
⍝H 1. Code fields:   { any APL code }
⍝H 2. Space fields:  {   }, { :5: }  { :⍹: } { :⍹1: }
⍝H 3. Text fields:   any text, with `{ for {, `} for }, `⋄ for newlines, `⍵ for simple ⍹, `` for `.
⍝H
⍝H For help, execute                                             
⍝H   ∆F⍨'help' ... or see ⍝H "HELP" comments at the bottom of function ∆F.
⍝H 
}