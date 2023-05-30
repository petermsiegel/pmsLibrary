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
  
      (mo bo)eo←(2↑⍺)(⊃⌽'`',2↓⍺)                                 ⍝   mo: mode option, bo: box option, eo: escape char (unescaped)
      fmt← ⊃⊆⍵

      omIx← 0                                                    ⍝   supports absolute and positional ⍵ feature: ⍵3, ⍹3; `⍵, ⍹ 
      pre←     '⊃{⊃,/⍺⍵↑⍨¨⌈⍥≢/⍺⍵}⍥⎕FMT/⌽'  '⍁CHAIN/' ⊃⍨ mo<0     ⍝   set preamble code based on options mo and bo
      pre,← bo/'⎕SE.Dyalog.Utils.display¨' '⍁BOX¨'   ⊃⍨ mo<0
  
      nl← ⎕UCS 13
      sq← '''' 
      dq2← dq dq←'"'
      ee←   '\', eo                                              ⍝   ee: ⎕R-ready escaped escape char.  
      es←   ee,  '[{}⋄⍵',ee,']'                                  ⍝   es: escape sequences

    ⍝ ......                                                     ⍝ Basic patterns (for ⎕R)
      eP←   ee, '([{}⋄⍵',ee,'])'                                 ⍝   eP: escape pattern. F1 is the escaped char.
      nP←   ee, '⋄'                                              ⍝   nP: newline pattern (→ nl)
      sqP←  '(''[^'']*'')+'                    
      dqP←  '("[^"]*")+'
      fmtP← '\$\s?'                                              ⍝   fmtP: match $ as alias to ⎕FMT
      omP←  '(?|',ee,'?[⍵⍹](\d+)|',ee,'⍵()|',ee,'?⍹())'                 ⍝   omP: ⍵ (omega) patterns: ⍵3, ⍹3; `⍵, ⍹ 
      cmP←  '⍝([^{}⋄',ee,']+|', es,')*'                          ⍝   cmP: limited comment pattern

     ⍝ ......                                                    ⍝ tP: text field pattern
      tP←   '((', es,'?|[^{',ee,']+)+)'                          

     ⍝ ......                                                    ⍝ s0P, etc: space field patterns
      hb he← '\h*:\h*' '(?:\h*:)?\h*'                                                                   
      s1P← '\{(\h*)\}' 
      s2P← '\{',hb,'(\d*)',he,'\}'
      s3P← '\{',hb,omP,,he,'\}'
     
    ⍝ ......                                                     ⍝ cP: code field pattern
      cP←  '(?x) (?<P> \{ ((?>  [^{}"''⍝',ee,']+ | (?:', es,')+  | ' 
      cP,← '     (?:"[^"]*")+ | (?:''[^'']*'')+ | ⍝([^}⋄',ee,']* |', es,')* | (?&P)* )+)  \} )' 
   
      E←  { ⍺←sq ⋄ ⍺, ⍺,⍨ ⍵/⍨ 1+⍺=⍵ }                            ⍝   Convert generic string to sq string
      F←  {⍵≥≢⍺.Lengths: '' ⋄ ⍺.(⌷∘Lengths↑Block↓⍨⌷∘Offsets)⍵}   ⍝   Select a ⎕R field
      N←  ,∘nl                                                   ⍝   Append a newline
      O←  {0≠≢⍵: ⍵⊣ omIx⊢← ⊃⌽⎕VFI ⍵ ⋄ ⍕omIx⊣ omIx+← 1}           ⍝   Omega ⍵-feature, including positional vars.
      P←  '('∘,,∘')'                                             ⍝   Parenthesize
      S←  ,∘' '                                                  ⍝   Append a space 
      T← { qt← E ∊⍵                                              ⍝   Process text in strings and text fields
           1=≢⍵:   S            qt                               ⍝     vec or scalar? Output as is. Otherwise, mix!
           1=⊃⌽⍴⍵: P '⍪',       qt                               ⍝     1 col matrix
                   P (⍕⍴⍵),'⍴', qt                               ⍝     General case: ⎕ML-independent version!
      }⍤(⎕FMT nP eP ⎕R nl '\1')                                  ⍝     preprocess `⋄, `{, `}, etc.
      U←  { t/⍨ ~dq2⍷ t← 1↓¯1↓ ⍵ }                               ⍝   Unconvert dq string to generic string

    
      TF← N T                                                    ⍝   Process TF fields (adding newline)
      CF← N P⍤ {                                                 ⍝   Process Code fields (adding parens and newline)
          patV← sqP dqP fmtP omP cmP
                sqI dqI fmtI omI comI← ⍳≢patV
          t←  patV ⎕R {
              C← ⍵.PatternNum∘= ⋄ F← ⍵∘F
              C sqI:  T 1↓¯1↓ F 0 
              C dqI:  T U  F 0  
              C fmtI: '⎕FMT '                                    ⍝   "..." $ ... ==> '...' ⎕FMT ...
              C omI:  P '⍵⊃⍨⎕IO+', f1 ⊣ f1← O F 1                ⍝   Handle ⍵dd, ⍹, etc. in code field expressions
              C comI: ' '                                        ⍝   Limited comments in code fields
          } ⍵ 
          '{', '}⍵',⍨ t 
      }                                                        
      SF← { sq2← sq sq ⋄ C1 C3← ⍺=1 3                   ⍝ Case   ⍝   Process Space fields  
           C3:            N P sq2,'⍴⍨⍵⊃⍨⎕IO+',O ⍵       ⍝  C3   ⍝   { :⍵3: } etc.    
           C1∧0=≢⍵:       ''                            ⍝  C1   ⍝   {}                     => Null field
           C1:            N P (⍕≢⍵),'⍴',sq2             ⍝  C1   ⍝   {  }
           0=⊃⌽⎕VFI'0',⍵: ''                            ⍝  C2   ⍝   { :0: }, { :: }, etc.  => Null field
                          N P ⍵,'⍴',sq2                 ⍝  C2   ⍝   { :5: }            
      }
                                                                 ⍝ Perform main scan of format string
      patV← tP s1P s2P s3P cP 
            tI _ _ _ cI←⍳≢ patV  
      code← patV  ⎕R {
          C← (sn← ⍵.PatternNum)∘∊ ⋄ F← ⍵∘F  
          C tI:      TF F 1                                      ⍝   Text  field
          C cI:      CF F 2                                      ⍝   Code  field
                  sn SF F 1                                      ⍝   Space field (sn∊1 2 3)
      } ⊆fmt 

    ¯1=mo: '{',(⊂pre), code,  ⊂'}(⊂', (E fmt), '),⍥⊂⍵'           ⍝   ¯1: Each field a separate char vec L to R
      c←  pre, (∊⌽code), '⍬'/⍨ 1≥≢code                           ⍝   '⍬': Ensure at least 2 fields; 2 needed for pre
    0=mo: '{{', c, '}(⊂',(E fmt),'),⍵}'                          ⍝    0: Generate code executable ⍎ as string (R to L)
    '{',  c, '},⊆⍵⍵'                                             ⍝    1: Execute code in caller env (R to L)
  
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
⍝H 1. Code fields:   { any APL code }
⍝H 2. Space fields:  {   }, { :5: }  { :⍹: } { :⍹1: }
⍝H 3. Text fields:   any text, with `{ for {, `} for }, `⋄ for newlines, `⍵ for simple ⍹, `` for `.
⍝H
⍝H For help, execute                                             
⍝H   ∆F⍨'help' ... or see ⍝H "HELP" comments at the bottom of function ∆F.
⍝H 
}