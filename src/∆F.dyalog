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

    0:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message) 
  
      fmt← ⊃⊆⍵                                                   ⍝ fmt: our format string
      (mo bo)eo←(2↑⍺)(⊃⌽'`',2↓⍺)                                 ⍝ mo: mode option, bo: box option, eo: escape char (unescaped)
      omIx← 0                                                    ⍝ omIx: "global" counter for positional omega ⍹ (see)
    ⍝ Basic header
      hdrCode←     '⊃{⊃,/⍺⍵↑⍨¨⌈⍥≢/⍺⍵}⍥⎕FMT/⌽'  '⍙ⒸⒽⒶⒾⓃ/' ⊃⍨ mo<0 ⍝ hdrCode set preamble code based on options mo and bo
      hdrCode,← bo/'⎕SE.Dyalog.Utils.display¨' '⍙ⒷⓄⓍ¨'   ⊃⍨ mo<0 ⍝ Use symbolic def if mode is ¯1 (show pseudocode)
    ⍝ Shortcuts...$ => ⎕FMT, % => ⍙ÔVR (display ⍺ over ⍵)        ⍝ sc__ shortcut items. 
      scSyms←  ,¨'$' '%'                                         ⍝ See scP below    ⍝ scSyms  shortcut symbols
      scCode←   '⎕FMT ' '⍙ⓄⓋⓇ '                                  ⍝ scCode code for each symbol
      scInUse←  0
      scDefs← '⍙ⓄⓋⓇ←{⍺←⍬⋄⊃⍪/⍺{m←⌈/w←⍺,⍥(⊃⌽⍤⍴)⍵⋄'                 ⍝ scDefs Definitions for shortcut(s) required 
      scDefs,←   'w{⍺=m:⍵⋄m↑⍤¯1⊢⍵↑⍤¯1⍨-⌊⍺+2÷⍨m-⍺}¨⍺ ⍵}⍥⎕FMT⍵}'   ⍝ ⎕FMT: APL, ⍙ⓄⓋⓇ: included here.
      scDefs← scDefs '⍙ⓄⓋⓇ←{...}' ⊃⍨ mo<0                        ⍝ "placeholder" def(s)
   
      nl← ⎕UCS 13
      lb rb← '{}' 
      sq2← sq,sq← '''' 
      dq←  '"'
      ec←  '\', eo                                               ⍝ ec:   ⎕R-ready e̲scape c̲har.  
      esT←  ec,'[{}⋄',  ec,']'                                   ⍝ esT:  e̲scape s̲equence in T̲ext fields, incl. quotes  
      esCC← ec,'[{}⋄⍵⍹',ec,']'                                   ⍝ esCC: e̲scape s̲equence in Ⓒode (cP) and Ⓒomments (cmP) 

    ⍝ ......                                                     ⍝ Basic patterns (for ⎕R)
      mapPV← ec ,¨⍥⊆ '⋄'  ('([{}⋄',ec,'])')                      ⍝ In text: `⋄ => nl, `{ => {, etc. 
      mapRV←          nl  '\1'

      sqP←  '(''[^'']*'')+'                    
      dqP←  '("[^"]*")+'
      scP←  '([%$])\s?'                                          ⍝ scP:  match one $ or %. See scSyms/scCode above.
      omP←  '(?:',ec,'⍵|',ec,'?[⍹])(\d*)'                        ⍝ omP:   ⍵ (omega) patterns: ⍵3, ⍹3; `⍵, ⍹ (see SF)
      cmP←  '⍝(?:[^{}⋄',ec,']+|', esCC,'?)*'                     ⍝ cmP:  limited comment pattern

     ⍝ ......                                                    ⍝ tP: text field pattern
      tP←   '((', esT,'?|[^{',ec,']+)+)'                          

     ⍝ ......                                                    ⍝ s0P, etc: space field patterns
      hb he← '\h*:\h*' '(?:\h*:)?\h*'                                                                   
      s1P← '\{(\h*)\}' 
      s2P← '\{',hb,'(\d*)',he,'\}'
      s3P← '\{',hb, omP, he,'\}'
     
    ⍝ ......                                                     ⍝ cP: code field pattern
      cP←  '(?x) (?<P> \{ ((?>  [^{}"''⍝',ec,']+ | (?:', esCC,'?)+  | ' 
      cP,← '     (?:"[^"]*")+ | (?:''[^'']*'')+ | ',cmP,' | (?&P)* )+)  \} )' 
   
      F←  {⍵≥≢⍺.Lengths: '' ⋄ ⍺.(⌷∘Lengths↑Block↓⍨⌷∘Offsets)⍵}   ⍝ F  Select a ⎕R F̲ield
      G← { hdrCode,⍨ scInUse/scDefs,'⋄'}                         ⍝ G  G̲enerate the full preamble    
      N←  ,∘nl                                                   ⍝ N  Append a N̲ewline
      O←  {0≠≢⍵: ⍵⊣ omIx⊢← ⊃⌽⎕VFI ⍵ ⋄ ⍕omIx⊣ omIx+← 1}           ⍝ O  O̲mega ⍵-feature, including positional vars.
      P←  '('∘,,∘')'                                             ⍝ P  P̲arenthesize
      Q←  sq∘{ ⍺, ⍺,⍨ ⍵/⍨ 1+⍺= ⍵ }                               ⍝ Q  Convert generic string to sq-Q̲uoted string
      S←  ,∘' '                                                  ⍝ S  Append a S̲pace 
      T← { q← Q ∊⍵                                               ⍝ T  Process T̲ext in strings and text fields
           1=≢⍵:              S q                                ⍝    vec or scalar? Output as is. Otherwise, mix!
           1=⊃⌽⍴⍵:       P '⍪', q                                ⍝    1 col matrix
                   P (⍕⍴⍵),'⍴', q                                ⍝    General case: ⎕ML-independent version!
      }⍤(⎕FMT mapPV ⎕R mapRV)                                    ⍝    Preprocess `⋄, `⍵, `{, `}, etc.
      U←  dq∘{ ⍵/⍨ ~⍵⍷⍨ ⍺,⍺ }1↓¯1↓⊢                              ⍝ U  U̲nconvert dq string to generic string
      V← scCode∘{ ⍵⊃⍺ }scSyms⍳⊂                                  ⍝ V  Get V̲alue for shortcut '$' or '%'
 
                                                          ⍝ ***  ⍝   Process fields: TF, CF, SF 
      TF← N T        ⍝ ......                             ⍝ TF   ⍝   Process Text fields (adding newline)
      CF← N P⍤ {     ⍝ ......                             ⍝ CF   ⍝   Process Code fields (adding parens and newline)
          patV← sqP dqP scP omP cmP
                sqI dqI scI omI cmI← ⍳≢patV
          t←  patV ⎕R {
              C← ⍵.PatternNum∘= ⋄ F← ⍵∘F
              C sqI:  T 1↓¯1↓ F 0 
              C dqI:  T U  F 0          
              C scI:  V f1 ⊣ scInUse⊢← '%'=f1←F 1                ⍝   $ => ⎕FMT, % => ⍙ÔVR (display over)
              C omI:  P '⍵⊃⍨⎕IO+', f1 ⊣ f1← O F 1                ⍝   Handle ⍹dd, ⍹, etc. in code field expressions
              C cmI: ' '       ⍝ Or '⋄'?                         ⍝   Limited comments in code fields
          } ⍵ 
          '{', t, '}⍵'
      }               
      SF← { nullField←''                                 ⍝ SF  ⍝   Process Space fields 
           C← ⍺∘=                                        ⍝ Case   
           C 3:           N P sq2,'⍴⍨⍵⊃⍨⎕IO+',O ⍵        ⍝ ⍺=3   ⍝   { :⍵3: } etc.    
          (C 1)∧0=≢⍵:     nullField                      ⍝ ⍺=1   ⍝   {}                      
           C 1:           N P (⍕≢⍵),'⍴',sq2              ⍝ ⍺=1   ⍝   {  }
           '0'∧.=⍵:       nullField                      ⍝ ⍺=2   ⍝   { :0: }, { :: }, etc.   
                          N P ⍵,'⍴',sq2                  ⍝ ⍺=2   ⍝   { :5: }            
      }
    ⍝ ......                                                     ⍝ Perform main scan of format string
      patV← tP s1P s2P s3P cP 
            tI _   _   _   cI←⍳≢ patV  
      code← patV  ⎕R {
          C← (sn← ⍵.PatternNum)∘∊ ⋄ F← ⍵∘F  
          C tI:      TF F 1                                      ⍝   Text  field
          C cI:      CF F 2                                      ⍝   Code  field
          ⋄ 1∊(eo,'⍹')⍷ f0←F 0:  11  ⎕SIGNAL⍨  'Invalid sequence in space field: ',f0
                  sn SF F 1                                      ⍝   Space field (sn∊1 2 3)
      } ⊆fmt 
 
            p← G⍬                                                ⍝ Generate preamble from header def and ⍙ÔVR def (if used)
    ¯1=mo: (⊂lb,p), code,  ⊂rb,'(⊂', (Q fmt), '),⍥⊂⍵'            ⍝ ¯1: Each field a separate char vec L to R
            c← (∊⌽code), '⍬'/⍨ 1≥ ≢code                          ⍝  ⍬: Ensure at least 2 fields; 2 needed for Chain
     0=mo: lb,lb, p, c, rb,'(⊂',(Q fmt),'),⍵',rb                 ⍝  0: Generate code executable ⍎ as string (R to L)
              lb, p, c, rb,',⊆⍵⍵'                                ⍝  1: Execute code in caller env (R to L)
    } ⍵

⍝H Syntax: 
⍝H     [mode←1 box←0 escCh←'`' | ⍬ | 'help'] ∆F f-string  args 
⍝H 
⍝H     ⍵← f-string [[⍵1 ⍵2...]]
⍝H        f-string: char vector with formatting specifications.
⍝H               See below.
⍝H        args:  arguments visible to all f-string code expressions 
⍝H     ⍺← 1 0 '`' 
⍝H        mode:  1= generate code, execute, and display result [default]
⍝H               0= emit code you can execute via ⍎ . The format string is available as ⍹0.
⍝H              ¯1= generate pseudo code with each field a separate character vector.
⍝H               Tip: Use ]box on and ⍪¯1 ∆F ... to see how fields are assembled and executed.
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
⍝H       [1]  formatted output (shown below in examples) 
⍝H       [0]  code which will create that output, or
⍝H       [¯1] pseudo-code for inspection (debugging or pedagogy).
⍝H    or, if ⍺≡⍬:
⍝H       1 0⍴''
⍝H
⍝H The f-string is a character vector defining 0 or more 2-D (char matrix) "fields," 
⍝H which are executed as if separate statements-- left to right[*]-- and assembled into a single matrix 
⍝H (with fields top-aligned). Its contents are in "shortcut" variable ⍹0.
⍝H                _____________
⍝H                * Internally, the code is assembled right to left and executed as one expression, 
⍝H                  then the output complex scalars are concatenated in reverse order!
⍝H                  To see the output "fields" in sequence, try: 
⍝H                      ]box on
⍝H                      ⍪¯1 ∆F ...
⍝H
⍝H There are 3 types of fields generated: 
⍝H    1. Code Fields, 2. Space Fields, and 3. Text Fields.
⍝H 
⍝H 1. Code fields:   { any APL code }
⍝H    Additions:
⍝H     a. Omega-expressions:   ⍹[ddd], `⍵[ddd]
⍝H             ∘ ⍹1: 1st arg after f-string, ⍹2: 2nd, ...; ⍹0 is the f-string itself.
⍝H               ⍹ alone: is the "next" arg left to right (default is ⍹1 or 1+ last explicit ⍹NN reference).
⍝H             ∘ `⍵ is a synonym to ⍹ in code fields (outside strings)
⍝H               `⍵ is equivalent to ⍹; `⍵2 is the same as ⍹2, etc.:
⍝H ⍎                    ∆F'{ `⍵2⍴ `⍵1  ⍝  same as ⍹2⍴ ⍹1 }' 'hello ' 11
⍝H ⎕                hello hello
⍝H             ∘ In text fields or quotes, ⍹ and ⍵ have no special significance.
⍝H             ∘ ⍹ is the unicode char ⎕UCS 9081.
⍝H     b. Double quote strings. Like APL single-quote strings '...' (also supported),
⍝H        ∆F allows strings of the form "...". To include a double quote itself, simply include
⍝H        by doubling:   "John ""is"" here"   =>>   'John "is" here'
⍝H        A newline may be indicated in a double-quoted string using `⋄
⍝H ⍎               ∆F '{ "This is`⋄ a cat`⋄ ¯ ¯¯¯" }'
⍝H ⎕          This is
⍝H ⎕           a cat 
⍝H ⎕           ¯ ¯¯¯ 
⍝H        This has the same output as
⍝H ⍎              ∆F '{ "This is" % " a cat" % " ¯ ¯¯¯" }'
⍝H     c. Shortcuts (aliases): 
⍝H          $  Equivalent to ⎕FMT. Use with left argument in double quotes:
⍝H ⍎                  ∆F '{ "⎕<⎕,F7.5,⎕>⎕" $ ?0 0}'
⍝H ⎕            <0.47805>
⍝H ⎕            <0.46475>
⍝H          %  Internal function ⍺ ⍙ⓄⓋⓇ ⍵, which prints ⍺ centered over ⍵.
⍝H ⍎                 ∆F '{ "Random Nums" % "⎕<⎕,F7.5,⎕>⎕" $ ?0 0}'
⍝H ⎕            Random Nums
⍝H ⎕            <0.43528> 
⍝H ⎕            <0.61564> 
⍝H      d. Limited comments: 
⍝H         ∘ Comments in code fields may consist of any characters besides (unescaped)
⍝H            {, ⋄ or `
⍝H         ∘ Escaped `{, `}, `⋄, ``, `⍵, and `⍹ are allowed (and safely ignored).
⍝H         ∘ A comment field is terminated just before these characters:
⍝H            }, ⋄, and {. 
⍝H         Example:
⍝H ⍎             ∆F '{ ⍹1 × ○2 ⍝ ⍹1 is r in 2×pi×r }' 5
⍝H ⎕        31.41592654       
⍝H 
⍝H 2. Space fields:  {}, {   }, { :5: }  { :⍹: } { :⍹1: } { :`⍵: } { :`⍵1: }  
⍝H    a. By example: a brace with 0 or more blanks, representing the # of blanks on output.
⍝H       a1. Null Fields: brace with 0 blanks is a Null Space Field, useful for separating OTHER fields.
⍝H    b. By number: a number between colons (the trailing colon is optional) indicates the # of blanks on output.
⍝H          { :5: }    <== 5 blanks on output!
⍝H    c. By ⍹-expression: an expression ⍹2 between colons (:⍹2:) means
⍝H          take the value of (⎕IO+2⊃⍵) as the # of blanks on output.
⍝H       An expression of simple ⍹ between colons (:⍹:) means: 
⍝H          increase the index of the last ⍵ expression to the left (or (⎕IO+1⊃⍨⍵) as the # of blanks on output.
⍝H       These parenthesized expressions are the same in this context:
⍝H ⍎            a b c← (∆F'{:5:}') (∆F'{:⍹1:}' 5) (∆F'{:`⍵1:}' 5)
⍝H ⍎            (a≡b)∧(b≡c)
⍝H ⎕         1
⍝H     ∘ Comments are NOT allowed in space fields.
⍝H 
⍝H 3. Text fields: any APL text at all, with 
⍝H       `{ for {, `} for }, `⋄ for newlines. 
⍝H    single quotes must be doubled as usual for APL strings. Double quotes have no special status.
⍝H    ⍹ and `⍵ have no special status in text fields (they are left as is).
⍝H
⍝H For help, execute                                             
⍝H   ∆F⍨'help' ... or see ⍝H "HELP" comments at the bottom of function ∆F.
⍝H 
}