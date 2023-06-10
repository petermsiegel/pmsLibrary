∆F← { 
⍝H ∆F: Simple formatting  function in APL "array" style, inspired by Python f-strings.
⍝! For documentation, see ⍝H comments below.

  ⎕IO ⎕ML←0 1
⍝   mo bo eo                                                     
  ⍺←1  0  '`'                                                    ⍝ ⍺: See "Option specs" below
  ⍬≡⍺: _←1 0⍴'' 
  'help'≡⎕C⍺: ⎕ED⍠ 'ReadOnly' 1⊢ 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⎕XSI  

  (⊃⍺)∘( (⊃⎕RSI) {                                               ⍝ No variable pollution allowed until '1=⍺:'
    0:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message) 
    1=⍺: ⍺⍺⍎⍵                                                    ⍝ 1=⍺: original (⊆⍵) is passed as ⍵⍵ in the code str
    0=⍺: ∊⍵                                             
   ¯1=⍺: ⍵    
   ¯2=⍺: ⎕SE.Dyalog.Utils.disp∘⍪ ⍵ 
    ⍵⍵ ∘∘∘ declare ⍵⍵ ∘∘∘                                                                                
  }(⊆⍵))⍺∘{        

      0:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message) 
    ⍝ Option specs
      fmt← ⊃⊆⍵                                                   ⍝ fmt: our format string
      (mo bo)eo←(2↑⍺)(⊃⌽'`',2↓⍺)                                 ⍝ mo: mode option, bo: box option, eo: user escape char (not escaped for pcre/⎕R)
      omIx← 0                                                    ⍝ omIx: "global" counter for positional omega ⍹ (see)
    ⍝ Basic preamble (actual code / symbolic)
      _pPre←    '⊃{⊃,/⍺⍵↑⍨¨⌈⍥≢/⍺⍵}⍥⎕FMT/'   '⍙ⒸⒽⒶⒾⓃ/' ⊃⍨ mo<0    ⍝ Core preamble     (actual / symbolic: mo<0)
      _pDef←    '⎕SE.Dyalog.Utils.display¨' '⍙ⒷⓄⓍ¨'   ⊃⍨ mo<0    ⍝ Opt'l definitions (actual / symbolic: mo<0)
      preCode←  _pPre, bo/ _pDef                                 ⍝ Full preamble, w/ defs if bo=1
    ⍝ Shortcuts...$ => ⎕FMT, % => ⍙ÔVR (display ⍺ over ⍵)        ⍝ sc__ shortcut items. 
      scSyms←   ,¨'$' '%'                                        ⍝ See scP below    ⍝ scSyms  shortcut symbols
      scCode←   '⎕FMT ' '⍙ⓄⓋⓇ '                                  ⍝ scCode code for each symbol
      _ovrD←   '⍙ⓄⓋⓇ←{⍺←⍬⋄⊃⍪/⍺{m←⌈/w←⍺,⍥(⊃⌽⍤⍴)⍵⋄'                ⍝ scDefs Definitions for shortcut(s) required 
      _ovrD,←  'w{⍺=m:⍵⋄m↑⍤¯1⊢⍵↑⍤¯1⍨-⌊⍺+2÷⍨m-⍺}¨⍺ ⍵}⍥⎕FMT⍵}⋄'    ⍝ ⎕FMT: APL, ⍙ⓄⓋⓇ: included here.
      scDefs←  _ovrD '⍙ⓄⓋⓇ←{...}⋄' ⊃⍨ mo<0                       ⍝ Select actual vs symbolic definition
      scDefsOut← 0
   
    ⍝ Pattern Building Blocks
      nl← ⎕UCS 13
      lb rb← '{}'    
      sq2← sq,sq← '''' 
      dq2← dq,dq← '"'
      _e←  '\', eo                                               ⍝ _e:  ⎕R-ready e̲scape c̲har.  
      _eT← _e,'[{}⋄',  _e,']'                                    ⍝ _eT: e̲scape s̲equence in T̲ext fields, incl. quotes  
      _eC← _e,'[{}⋄⍵⍹',_e,']'                                    ⍝ _eC: e̲scape s̲equence in Ⓒode (cP) and Ⓒomments (cmP) 

    ⍝ Basic Patterns                                             ⍝  
      txPV←  (_e,'⋄') (_e,'([{}⋄',_e,'])')                       ⍝ Escapes in Text Fields:
      txRV←  nl       '\1'                                       ⍝     `⋄ => nl, `{ => {, etc. 
    
      qP←  '(?:''[^'']*'')+|(?:"[^"]*")+' 
      scP←  '([%$])\s*'                                          ⍝ scP:  match one $ or %. See scSyms/scCode above.
      omP←  '(?:',_e,'⍵|',_e,'?[⍹])(\d*)'                        ⍝ omP:  ⍵ (omega) patterns: ⍵3, ⍹3; `⍵, ⍹ (see SF)
      cmP←  '⍝(?:[^{}⋄',_e,']+|', _eC,'?)*'                      ⍝ cmP:  Comments end with any of '⋄{}'

     ⍝ Patterns for Text Fields                                  ⍝ tP: Text Field pattern
      tP←   '((', _eT,'?|[^{',_e,']+)+)'                          

     ⍝ Patterns for Space Fields                                 ⍝ s[1-3]P: Space Field patterns                                 
      s1P← '\{(\h*)\}' 
      s2P← '\{',lc,'(\d*)',rc,'\}'  ⊣  lc rc← '\h*:\h*' '(?:\h*:)?\h*'  
      s3P← '\{',lc, omP, rc,'\}'
     
    ⍝ Patterns for Code Fields                                   ⍝ cP: Code Field pattern
      cP←  '(?x) (?<P> \{ ((?>  [^{}"''⍝',_e,']+ | (?:', _eC,'?)+ |', qP,' | ',cmP,' | (?&P)* )+)  \} )' 
      cFP← '(?x: \{ \h* (', qP, ') \h* \} )'                     ⍝ Fast match for {"dq string" or 'sq string'}

    ⍝ Actions
      F←   {⍵≥≢⍺.Lengths: '' ⋄ ⍺.(⌷∘Lengths↑Block↓⍨⌷∘Offsets)⍵}  ⍝ F   Select a ⎕R F̲ield
      Nl←  ,∘nl                                                  ⍝ N   Append a N̲ewline
      Om←  {0≠≢⍵: ⍵⊣ omIx⊢← ⊃⌽⎕VFI ⍵ ⋄ ⍕omIx⊣ omIx+← 1}          ⍝ O   O̲mega ⍵-feature, including positional vars.
      P←  '(', ,∘')'                                             ⍝ P   P̲arenthesize
      Pad← ⊢,('⍬'/⍨((0=≢⍤⊃)+(1∘≥≢)))                             ⍝ Pad Conditionally pad fields (to ≥2)  
      Pre← { (preCode,'⌽'),⍨ scDefsOut/scDefs }                  ⍝ Pre G̲enerate preamble from header & shortcut code  
      Q2T← {sq=⊃⍵: 1↓¯1↓⍵ ⋄ s/⍨ ~dq2⍷s←1↓¯1↓⍵ }                  ⍝ Q2T Single or double Q̲uoted string to generic T̲ext
      ScC← scCode∘{ ⍵⊃⍺ }scSyms⍳⊂                                ⍝ ScC S̲hortcut to C̲ode value: '$' or '%'
      Sp←  ,∘' '                                                 ⍝ Sp  Append a S̲pace                                                         
      Tx←  {1=≢⍵: Sp T2Q ∊⍵ ⋄ P(⍕⍴⍵),'⍴',T2Q ∊⍵}∘⎕FMT txPV ⎕R txRV ⍝ Tx  Process T̲ext in strings and text fields  
      Tr←  25∘{⍺≥≢⍵: ⍵ ⋄ '...',⍨⍵↑⍨⍺-3}                          ⍝ Tr  Trunc. str >⍺ chars, adding '...'
      T2Q←  sq∘{ ⍺, ⍺,⍨ ⍵/⍨ 1+⍺= ⍵ }                             ⍝ T2Q Convert generic T̲ext to sq-Q̲uoted string
   
    ⍝ Field Processing Fns: TF- text, CF- code, SF- space 
      TF← Nl Tx        ⍝ ......                           ⍝ TF   ⍝   Process Text fields (adding newline)
      CF← Nl P⍤ {     ⍝ ......                            ⍝ CF   ⍝   Process Code fields (adding parens and newline)
          patV← qP scP omP cmP
                qI scI omI cmI← ⍳≢patV
          tx← patV ⎕R {
              C← ⍵.PatternNum∘= ⋄ F← ⍵∘F
              C qI:   Tx Q2T F 0        
              C scI:  ScC f1 ⊣ scDefsOut⊢← '%'=f1←F 1            ⍝   $ => ⎕FMT, % => ⍙ÔVR (display ⍺ over ⍵)
              C omI:  P '⍵⊃⍨⎕IO+', Om F 1                        ⍝   Handle ⍹dd, ⍹, etc. in code field expressions
              C cmI: ' '                                         ⍝   Limited comments in code fields
          } ⍵ 
          '{', tx, '}⍵'
      }               
      SF← { nullF←''                                     ⍝ SF    ⍝   Process Space fields 
           C← ⍺∘=                                        ⍝ Case based on type (⍺)  
           C 3:           Nl P sq2,'⍴⍨⍵⊃⍨⎕IO+',Om ⍵      ⍝ ⍺=3   ⍝   { :⍵3: } etc.    
          (C 1)∧0=≢⍵:     nullF                          ⍝ ⍺=1   ⍝   {}                      
           C 1:           Nl P (⍕≢⍵),'⍴',sq2             ⍝ ⍺=1   ⍝   {  }
           '0'∧.=⍵:       nullF                          ⍝ ⍺=2   ⍝   { :0: }, { :00: }, etc., AND { :: } 
                          Nl P ⍵,'⍴',sq2                 ⍝ ⍺=2   ⍝   { :5: }            
      }
    ⍝ fmt => [TF | CF |SF]*                                      ⍝ Break format string into 3 field types!
      patV← tP s1P s2P s3P cFP cP 
            tI _   _   _   cFI cI←⍳≢ patV  
      code← patV  ⎕R {
          C← (sn← ⍵.PatternNum)∘∊ ⋄ F← ⍵∘F  
          C tI:      TF F 1                                      ⍝   Text  field
          C cFI:     TF Q2T F 1                                  ⍝   Code DQ/SQ Field: Fast match {"Like this"}
          C cI:      CF F 2                                      ⍝   Code  field
                 sn  SF F 1                                      ⍝   Space field (sn∊1 2 3)                             
      } ⊆,fmt 

              _c← (⊂(lb/⍨1+1≠mo), Pre⍬), (⌽Pad code)             ⍝  Executed R-to-L, then reassembled orig L-to-R
      1=mo:  ∊_c,  rb, ',⍵⍵'                                     ⍝  1: Execute code in caller env: ⍵⍵ contains <orig ⍵>  
              _c, ⊂rb, '⍵,⍨', ('⊂', T2Q fmt), rb                  ⍝  0,¯1,¯2: Pass back code and <fmt> as fields               
    } ⍵

⍝H ∆F Utility Function
⍝H     ∆F is a function that uses simple input string expressions, f-strings, to dynamically build 
⍝H     2-dimensional output from variables and dfn-style code, shortcuts for numerical formatting, 
⍝H     titles, and more. To support an idiomatic APL style, ∆F uses the concept of fields to organize 
⍝H     the display of vector and multidimensional objects using building blocks that already exist in 
⍝H     the Dyalog implementation. (∆F is reminiscent of f-string support in Python, but in an APL style.)
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
⍝H                  Note that fields are emitted right-to-left, then assembled in reverse order (ending up l-to-r).
⍝H              ¯1= generate pseudo code right-to-left with each field a separate character vector.
⍝H                  (For pedagogical or debugging purposes).
⍝H              ¯2= same as for mode=¯1, except displaying fields boxed in table (⍪) form.
⍝H              Tip: Use ¯2 ∆F ... to see the code generated for the fields you specify.
⍝H        -------
⍝H        box:   1= display each field in a box (display from dfns).
⍝H               0= display each field simply [default]
⍝H        -------
⍝H        escCh: used to ensure or suppress special behavior.
⍝H               default is '`'. Common alternative is '\'.
⍝H               Suppresses special behavior of {, }, `.
⍝H               Enables special behavior of `⋄ and `⍵.
⍝H        -------
⍝H        ⍬:     causes ∆F to do nothing, returning shy
⍝H                 1 0⍴''
⍝H        -------
⍝H         'help': shows this help information.
⍝H        -------
⍝H    Returns: Per mode above:
⍝H       [1]  formatted output (shown below in examples) 
⍝H       [0]  code which will create that output, or
⍝H       [¯1] pseudo-code for inspection (debugging or pedagogy).
⍝H    or, if ⍺≡⍬:
⍝H       1 0⍴''
⍝H
⍝H The f-string is a character vector defining 0 or more 2-D (char matrix) "fields," 
⍝H which are executed as if separate statements (the left-most field "executed" first)
⍝H and assembled into a single matrix (with fields top-aligned). 
⍝H Its contents are in "shortcut" variable ⍹0.
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
⍝H 2. Space fields:  {}, {   }, { :5: }  { :⍹1: } { :⍹: } { :`⍵: } { :`⍵1: }  
⍝H     # spaces      0     3       5       1⊃⍵    next ⍵    next ⍵    1⊃⍵
⍝H    a. By example: a brace with 0 or more blanks, representing the # of blanks on output.
⍝H       a1. Braces with 1 or more blanks separate other fields.
⍝H           1 blank: { }, 2 blanks: {  }, etc.
⍝H       a2. Null Fields: brace with 0 blanks is a Null Space Field, useful for separating OTHER fields.
⍝H       ∘ Examples of space fields (with multiline text fields-- see below):
⍝H ⍎           ∆F 'a`⋄cow{}a`⋄bell'            ∆F 'a`⋄cow{ }a`⋄bell'
⍝H ⎕        a  a                            a   a
⍝H ⎕        cowbell                         cow bell
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
⍝H 3. Text fields: any APL characters at all, except to represent {} and ` (or the current escape char):
⍝H    `{ is a literal {
⍝H    `} is a literal }
⍝H     } by itself starts a new code field
⍝H     } by itself ends a code field
⍝H    `⋄ stands for a newline character (⎕UCS 13).
⍝H     ⋄ has no special meaning, unless preceded by the current escape character (`).
⍝H     ` before {, }, or ⋄ must be doubled to have its literal meaning (`` ==> `)
⍝H     ` before other characters has no special meaning (i.e. no need to double it).
⍝H    Single quotes must be doubled as usual within APL strings. 
⍝H    Double quotes have no special status in a text field (but see Code Fields).
⍝H    ⍹ and `⍵ have no special status in text fields (they are left as is).
⍝H
⍝H For help, execute                                             
⍝H   ∆F⍨'help' ... or see ⍝H "HELP" comments at the bottom of function ∆F.
⍝H 
⍝H Note: fields are not actually evaluted separately, but within a single code string.
⍝H   In practice, this means fields are ordered right to left, formatted individually, and then
⍝H   "glued" together in reverse order, so the results appears left-to-right as expected!
⍝H   Try ¯2 ∆F ... to see pseudocode showing how your code is structured.
⍝H   0 ∆F ... shows the actual code to be executed, as a compact and efficient string.
⍝H
}