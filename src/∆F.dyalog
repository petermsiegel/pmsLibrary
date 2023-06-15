﻿∆F← { 
⍝H ∆F: Simple formatting  function in APL "array" style, inspired by Python f-strings.
⍝! For documentation, see ⍝H comments below.
  ⎕IO ⎕ML←0 1
⍝ Main options (⍺): <mo mode, bo box, eo escape char OR ⍬ OR 'help'>                                    
  ⍺←1  0  '`'                                                    
  ⍬≡⍺: _←1 0⍴'' 
  'help'≡⎕C⍺: ⎕ED⍠ 'ReadOnly' 1⊢ 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⎕XSI  
⍝ Stage II - Given mode (⊃⍺) etc., execute, return, or display code string from Stage I  
  (⊃⍺)∘( (⊃⎕RSI) {  
    0:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message) 
    1=⍺: ⍺⍺⍎⍵  ⋄   0=⍺: ∊⍵                                                 
   ¯1=⍺: ⍵     ⋄  ¯2=⍺: ⎕SE.Dyalog.Utils.disp ⍪ ⍵  ⋄ ∘∘∘ declare ⍵⍵ ∘∘∘                                                                                
  }(⊆⍵))⍺∘{        
⍝ Stage I - Process format string to code string and pass to Stage II
    0:: ⎕SIGNAL ⊂ ⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message) 
    ⍝ Option specs
      fmtS← ⊃⊆⍵                                                  ⍝ fmtS: our format string
      (mo bo)eo←(2↑⍺)(⊃⌽'`',2↓⍺)                                 ⍝ mo: mode option, bo: box option, eo: user escape char (not escaped for pcre/⎕R)
      omIx← 0                                                    ⍝ omIx: "global" counter for positional omega ⍹ (see)
    ⍝ Basic preamble (actual code / symbolic)
    ⍝ ⍙ⒸⒽⓃ aligns and catenates arrays ⍺ and ⍵, left to right
      _chn←    '⊃{⊃,/⍺⍵↑⍨¨⌈⍥≢/⍺⍵}⍥⎕FMT/'   '⍙ⒸⒽⓃ/' ⊃⍨ mo<0       ⍝ Core preamble     (actual / symbolic: mo<0)
      _box←    '⎕SE.Dyalog.Utils.display¨' '⍙ⒷⓄⓍ¨'   ⊃⍨ mo<0     ⍝ Opt'l definitions (actual / symbolic: mo<0)
      preCode←  _chn, bo/ _box                                   ⍝ Full preamble, w/ defs if bo=1
    ⍝ Shortcut pseudofns: $ → ⎕FMT, % → ⍙ÔVR ("display over")    ⍝  
      scSyms←   ,¨'$' '%'                                        ⍝ scSyms:  shortcut symbols
    ⍝ ⍙ⓄⓋⓇ aligns, centers, and catenates array ⍺ over ⍵
      scCode←   '⎕FMT ' '⍙ⓄⓋⓇ '                                  ⍝ scCode: code for each symbol $ and %
    ⍝  _ovr←   '⍙ⓄⓋⓇ←{⍺←⍬⋄⊃⍪/⍺{m←⌈/w←⍺,⍥(⊃⌽⍤⍴)⍵⋄'                 ⍝ scDefs: Definitions for shortcut(s) required 
    ⍝  _ovr,←  'w{⍺=m:⍵⋄m↑⍤¯1⊢⍵↑⍤¯1⍨-⌊⍺+2÷⍨m-⍺}¨⍺ ⍵}⍥⎕FMT⍵}'      ⍝ ⎕FMT: APL, ⍙ⓄⓋⓇ: included here.
      _o← '{⍺←⍬⋄⊃⍪/(-⌊2÷⍨m-w)⌽¨∆↑⍤¯1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨∆←⎕FMT¨⍺⍵}'    ⍝ ⍙ⓄⓋⓇ: See %
      scDefs← '⍙ⓄⓋⓇ←', _o '{...}' ⊃⍨ mo<0                        ⍝ scDefs: Definition for ∆F-defined fn ⍙ⓄⓋⓇ
      scDefsOut← 0                                               ⍝ Only if 1, will definitions will be output.
    ⍝ (Regular Expression) Pattern Building Blocks
      nl← ⎕UCS 13
      lb rb← '{}'    
      sq2← sq,sq← '''' 
      dq2← dq,dq← '"'
      e←  '\', eo                                                ⍝ e:  ⎕R-ready e̲scape c̲har.  
      eT← e,'[{}⋄',  e,']'                                       ⍝ eT: e̲scape sequence in T̲ext fields, incl. quotes  
      eC← e,'[{}⋄⍵⍹',e,']'                                       ⍝ eC: e̲scape sequence in Ⓒode (cP) and Comments (cmP) 
    ⍝ Common Patterns
      qP←  '(?:''[^'']*'')+|(?:"[^"]*")+' 
      scP←  '([%$])\s*'                                          ⍝ scP:  match a shortcut "fn": $ or %. 
      omP←  '(?:',e,'⍵|',e,'?[⍹])(\d*)'                          ⍝ omP:  ⍵ (omega) patterns: ⍵3, ⍹3; `⍵, ⍹ (see SF)
      cmP←  '⍝(?:[^{}⋄',e,']+|', eC,'?)*'                        ⍝ cmP:  Comments end with any of '⋄{}'
    ⍝ Major Patterns for Text Fields and Quoted Strings (in Code Fields)                                 
      tP←   '((',eT,'?|[^{',e,']+)+)'                            ⍝ tP: Text Field pattern                                            
      tenP←  e,'⋄'                                               ⍝ tenP: [text] escape + newline
      tecP←  e,'([{}⋄',e,'])'                                    ⍝ teeP: [text] escape + char
    ⍝ Major Patterns for Space Fields                            ⍝ s1P...: Space Field patterns                                 
      s1P← '\{(\h*)\}' 
      s2P← '\{',_l,'(\d*)',_r,'\}' ⊣ _l _r← '\h*:\h*' '(?:\h*:)?\h*'  
      s3P← '\{',_l,omP,_r,'\}'
    ⍝ Major Patterns for Code Fields                             ⍝ cP: Code Field pattern
      cP←  '(?x) (?<P> \{ ((?>  [^{}"''⍝',e,']+ | (?:',eC,'?)+ |',qP,' | ',cmP,' | (?&P)* )+)  \} )' 
      cQP← '(?x: \{ \h* (',qP,') \h* \} )'                       ⍝ Fast match for {"dq string" or 'sq string'}
    ⍝ Actions
      ANl← ,∘nl                                                  ⍝ ANl  Append a N̲ewline
      F←   {⍵≥≢⍺.Lengths: '' ⋄ ⍺.(⌷∘Lengths↑Block↓⍨⌷∘Offsets)⍵}  ⍝ F    Select a ⎕R pat match F̲ield
      Ome← {0≠≢⍵: ⍵⊣ omIx⊢← ⊃⌽⎕VFI ⍵ ⋄ ⍕omIx⊣ omIx+← 1}          ⍝ Ome  O̲mega ⍵-feature, including positional vars.
      Par← '(', ,∘')'                                            ⍝ Par  P̲arenthesize
      ÇPad← ⊢,('⍬'/⍨((0=≢⍤⊃)+(1∘≥≢)))                            ⍝ ÇPad Cond'lly pad fields (to ≥2)  
      Pre← { (preCode,'⌽'),⍨ scDefsOut/scDefs,'⋄' }              ⍝ Pre  G̲enerate preamble from header & shortcut code  
      Q2T← ⊢{ dq≠⊃⍺: ⍵ ⋄ ⍵/⍨ ~dq2⍷ ⍵ }1↓¯1↓⊢                     ⍝ Q2T  Single- or Double-Q̲uoted string to generic T̲ext
      ScC← scCode∘{ ⍵⊃⍺ }scSyms⍳⊂                                ⍝ ScC  S̲hortcut to C̲ode value: '$' or '%'
      STE← tenP tecP ⎕R nl '\1'                                  ⍝ STE  In quoted S̲trings and T̲ext Fields, process Ⓔscapes 
      STF← {1=≢⍵: ' ',⍨ T2Q ∊⍵ ⋄ Par(⍕⍴⍵),'⍴',T2Q ∊⍵}∘⎕FMT       ⍝ STF  In quoted S̲trings and T̲ext Fields, F̲ormat (poss. multiline) text
      ÇTru← 25∘{ ⍺≥≢⍵: ⍵ ⋄ '...',⍨⍵↑⍨⍺-3 }⍣ (mo<0)               ⍝ ÇTru Cond'lly trunc. str >⍺ chars, adding '...'
      T2Q← sq∘{ ⍺, ⍺,⍨ ⍵/⍨ 1+⍺= ⍵ }                              ⍝ T2Q  Convert generic T̲ext to sq-Q̲uoted string
    ⍝ Processing Fields of text TF, code CF, and space SF
      TF← ANl STF⍤STE                                     ⍝ TF   ⍝ Process Text fields (adding newline)
      CF← ANl Par⍤{                                       ⍝ CF   ⍝ Process Code fields (adding parens and newline)
          patV← qP scP omP cmP
                qI scI omI cmI← ⍳≢patV
          tx← patV ⎕R {
              C← ⍵.PatternNum∘= ⋄ F← ⍵∘F   
              C qI:   STF STE Q2T F 0                            ⍝ Proc escapes, format text   
              C scI:  ScC f1 ⊣ scDefsOut∨← '%'=f1←F 1            ⍝ $ => ⎕FMT, % => ⍙ÔVR (display ⍺ over ⍵)
              C omI:  Par '⍵⊃⍨⎕IO+', Ome F 1                     ⍝ Handle ⍹dd, ⍹, etc. in code field expressions
              C cmI: ' '                                         ⍝ Limited comments in code fields
          } ⍵ 
          '{', tx, '}⍵'
      }               
      SF← {nullF←''                                      ⍝ SF    ⍝ Process Space fields 
           C← ⍺∘=                                         
           C 3:           ANl Par sq2,'⍴⍨⍵⊃⍨⎕IO+',Ome ⍵  ⍝ ⍺=3   ⍝ { :⍵3: } etc.    
          (C 1)∧0=≢⍵:     nullF                          ⍝ ⍺=1   ⍝ {}                      
           C 1:           ANl Par (⍕≢⍵),'⍴',sq2          ⍝ ⍺=1   ⍝ {  }
           '0'∧.=⍵:       nullF                          ⍝ ⍺=2   ⍝ { :0: }, { :00: }, etc., AND { :: } 
                          ANl Par ⍵,'⍴',sq2              ⍝ ⍺=2   ⍝ { :5: }            
      }  
    ⍝ Stage I Master Process: input format string => code string, passed to Stage II                                                     
      patV← tP s1P s2P s3P cQP cP                                
            tI _   _   _   cQI cI←⍳≢ patV  
      MatchTCS←patV ⎕R {                                            
          C← (sn← ⍵.PatternNum)∘∊ ⋄ F← ⍵∘F  
          C tI:      TF F 1                                      ⍝ Text  field
          C cQI:     TF Q2T F 1                                  ⍝ Code Field Simple Quote Fast match {"Like this"}
          C cI:      CF F 2                                      ⍝ General Code  field
                  sn SF F 1                                      ⍝ Space field (sn∊1 2 3)                             
      }⊆⍤,                               
      cs← (⊂(lb/⍨1+1≠mo), Pre⍬), ⌽ÇPad MatchTCS fmtS             ⍝ Prepare code str for execution or display
      1=mo:  ∊cs,  rb, ',⍵⍵'                                     ⍝ 1: Execute code in caller env: ⍵⍵ contains <orig ⍵>  
              cs, ⊂rb, '⍵,⍨', ('⊂', T2Q ÇTru fmtS), rb           ⍝ 0,¯1,¯2: Pass back code and <fmtS> as fields               
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
⍝H               0= emit code you can execute or convert to a dfn via ⍎, e.g. dfn←⍎0 ∆F '...'. 
⍝H                  Note that fields are emitted right-to-left, then assembled in reverse order (ending up l-to-r).
⍝H              ¯1= generate pseudo code right-to-left with each field a separate character vector.
⍝H                  (For pedagogical or debugging purposes).
⍝H              ¯2= same as for mode=¯1, except displaying fields boxed in table (⍪) form.
⍝H                  (For pedagogical or debugging purposes).
⍝H                  Tip: Use ¯2 ∆F "..." to see the code generated for the fields you specify.
⍝H                       Note that (L-to-R) code fields appear in reverse order (Bottom-to-Top)!
⍝H        -------
⍝H        box:   1= display each field in a box ("display" from dfns).
⍝H               0= display each field as is [default].
⍝H        -------
⍝H        escCh: escape character, used to ensure or suppress special behavior.
⍝H               ∘ default is '`'. A common alternative is '\'.
⍝H               ∘ suppresses special behavior of {, }, `.
⍝H               ∘ enables special behavior of `⋄ and `⍵.
⍝H        -------
⍝H        ⍬:     causes ∆F to do absolutely nothing, returning shy
⍝H                  1 0⍴''
⍝H               To display and execute {⎕DL toggle}, only if toggle<10 (otherwise, skip entirely):
⍝H ⍎                (1/⍨toggle<10) ∆F 'Delay of {toggle} seconds: {⎕DL `⍵1}'(toggle←?15)
⍝H ⎕              Delay of 5 seconds: 5.109345
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
⍝H and assembled into a single matrix (with fields displayed left-to-right, top-aligned, 
⍝H and padded with blank rows as required). 
⍝H It is available to Code Fields (below) verbatim as the shortcut" variable ⍹0. See Omega Expressions below.
⍝H
⍝H There are 3 types of fields generated: 
⍝H    1. Code Fields, 2. Space Fields, and 3. Text Fields.
⍝H 
⍝H 1. Code fields:   { any APL code }
⍝H    Additions:
⍝H     a. Omega Expressions:  ⍹[ddd] or its escape-based equivalent, `⍵[ddd]. ddd is any non-neg integer.
⍝H        These index into the "arguments" passed to ∆F as elements of ⍵, 
⍝H        including the f-string itself as the 0-th element of ⍵ (⍹0), independent of the user-space ⎕IO.
⍝H        The elements referred to MUST exist at run-time, else an error is signalled.
⍝H             ∘ ⍹1:   1st arg after f-string, 
⍝H               ⍹2:   2nd,
⍝H               ⍹99:  the 99th arg after the f-string;
⍝H               ⍹0:   the f-string itself.
⍝H               ⍹:    (⍹ alone) the "next" arg left to right in ⍵, indexed after a (bare) ⍹ or a numeric ⍹1, etc.
⍝H                     If ⍹5 is the first ⍹-expression to its left, then ⍹ refers to ⍹6.
⍝H                     If there is no ⍹-expression to its left, ⍹ refers to ⍹1. Simple ⍹ never refers to ⍹0.
⍝H             ∘ `⍵ is a synonym to ⍹ in code fields (outside strings)
⍝H               `⍵ is equivalent to ⍹; `⍵2 is the same as ⍹2, etc.:
⍝H ⍎                    ∆F'{ `⍵2⍴ `⍵1  ⍝  same as ⍹2⍴ ⍹1 }' 'hello ' 11
⍝H ⎕                hello hello             ⍝ ⍝== Length is 11!
⍝H             ∘ In text fields or quotes, ⍹ and ⍵ have no special significance.
⍝H             ∘ ⍹ is the unicode char ⎕UCS 9081.
⍝H     b. Double quote strings in Code Fields. Like APL single-quoted strings '...' (also supported),
⍝H        ∆F allows strings of the form "..." in Code Fields. 
⍝H        To include a double quote itself, simply double a double quote, as you would for single-quoted strings.
⍝H ⍎               ∆F '<{"John ""is"" here"}>'    
⍝H ⎕          <John "is" here>             
⍝H        A newline may be indicated in a double-quoted string, as in a Text Field (below), using `⋄
⍝H ⍎               ∆F '{ "This is`⋄ a cat`⋄ ¯ ¯¯¯" }'
⍝H ⎕           This is
⍝H ⎕            a cat 
⍝H ⎕            ¯ ¯¯¯ 
⍝H        This has the same output as the following, using % ("Over", shown in pseudo/code as ⍙ⓄⓋⓇ)
⍝H ⍎               ∆F '{ "This is" % " a cat" % " ¯ ¯¯¯" }'
⍝H     c. Shortcuts (aliases): 
⍝H          $  Equivalent to ⎕FMT. For sanity, use with a left argument in double quotes:
⍝H ⍎               ∆F '{ "⎕<⎕,F7.5,⎕>⎕" $ ?0 0}'
⍝H ⎕           <0.47805>
⍝H ⎕           <0.46475>
⍝H          %  Internal function ⍺ ⍙ⓄⓋⓇ ⍵, which prints object ⍺ centered over object ⍵.
⍝H ⍎               ∆F '{ "Random Nums" % "⎕<⎕,F7.5,⎕>⎕" $ ?0 0}'
⍝H ⎕           Random Nums
⍝H ⎕           <0.43528> 
⍝H ⎕           <0.61564> 
⍝H      d. Limited comments: 
⍝H         ∘ Comments in code fields may consist of any characters besides (unescaped)
⍝H            }, ⋄, and {.
⍝H         ∘ Escaped `}, `⋄, `{, ``, `⍵, and `⍹ are allowed (and safely ignored).
⍝H         ∘ A comment field is terminated just before these (unescaped) characters:
⍝H            }, ⋄, and {. 
⍝H         ∘ A simple escape character is ok in  comment clause (see 2 prior bullets).
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
⍝H 3. Text fields: any APL characters at all, except to represent {} and ` (or the current escape char).
⍝H    (If you change the escape character, e.g. to '\', make the appropriate changes in the narrative below).
⍝H    `{ is a literal {
⍝H    `} is a literal }
⍝H     } by itself starts a new code field
⍝H     } by itself ends a code field
⍝H    `⋄ stands for a newline character (⎕UCS 13).
⍝H     ⋄ has no special meaning, unless preceded by the current escape character (`).
⍝H     ` before {, }, or ⋄ must be doubled to have its literal meaning (`` ==> `)
⍝H     ` before other characters has no special meaning (i.e. appears as a literal character, unless escaped).
⍝H    Single quotes must be doubled as usual when typing in APL strings to be evaluated in code or via ⍎. 
⍝H    Double quotes have no special status in a text field (but see Code Fields).
⍝H    ⍹ and `⍵ have no special status in text fields (they are left as is).
⍝H
⍝H For help, execute                                             
⍝H   ∆F⍨'help' ... or see ⍝H "HELP" comments at the bottom of function ∆F.
⍝H 
⍝H Note: fields are not actually evaluated separately, but within a single code string.
⍝H   In practice, this means fields are generated right to left, formatted individually, and then
⍝H   "glued" together in reverse order, so the results appears left-to-right as expected!
⍝H   Try ¯2 ∆F ... to see pseudocode showing how your code is structured. Runtime defs are shown abridged.
⍝H   0 ∆F ... shows the actual code to be executed, with all runtime definitions spelled out in full!
⍝H
}