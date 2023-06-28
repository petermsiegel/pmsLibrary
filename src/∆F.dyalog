﻿∆F←{
  ⍺←1 0 '`'
  0=≢⍺: 1 0⍴''
 'help'≡⎕C⍺: ⎕ED⍠ 'ReadOnly' 1⊢ 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⎕XSI  
  (⊃⍺) ((⊃⎕RSI){
    0:: ⎕SIGNAL ⊂⎕DMX.(('EM' ('∆F ',EM))('EN' EN)('Message' Message))
      1=⍺:  ⍺⍺⍎ ⍵                                            ⍝ ⍵ string includes original ⍵ as ⍵⍵ 
     ¯2=⍺: ⎕SE.Dyalog.Utils.disp ⍪⍵
           ⍵    
      ∘∘unreachable∘∘ ⍵⍵ 
  }(⊆⍵))⍺{
  90:: ⎕SIGNAL ⊂⎕DMX.(('EM' ('∆F ',EM))('EN' EN)('Message' Message))
    (mo bo) esc←(2↑⍺)(⊃'`',⍨2↓⍺)
    fmtS←⊃⊆⍵
      _chn←     '{⊃,/⍵↑⍨¨⌈/≢¨⍵}⎕FMT¨'       '⍙ⒸⒽⓃ¨' ⊃⍨ mo<0    ⍝ ⍙ⒸⒽⓃ¨ aligns & catenates arrays 
      _box← bo/ '⎕SE.Dyalog.Utils.display¨' '⍙ⒷⓄⓍ¨' ⊃⍨ mo<0    ⍝ ⍙ⒷⓄⓍ¨ calls dfns.display 
    preCode← _chn, _box, '⌽'                                    
      _ovr← '{⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}⋄' ⍝ ⍙ⓄⓋⓇ aligns, centers, & catenates arrays
    runDefs← '⍙ⓄⓋⓇ←', _ovr '{...}⋄' ⊃⍨ mo<0                     ⍝ runtime defs, if required 

    omIx←0                                                     ⍝ See SplitOm
    inclRun←0

  ⍝ '  "  ⋄   ⍝  :   {  }  $   %   ⍵  ⍹                        ⍝ ⍹: omega underbar                              
    sq dq eos cm cln lb rb fmt ovr om omU← '''"⋄⍝:{}$%⍵⍹'  
    sp← ' '
    nl← ⎕UCS 13                                                ⍝ newline: carriage return [sic!]
    impCF←  sq dq cm cln lb rb fmt ovr om omU esc              ⍝ stuff you need to eval 1 by 1
    impTF←               lb rb                esc    

    Match←   ∊⍨   
    NMatch← ~∊⍨
    LenLB←  { +/∧\' '= ⍵ }
    SkipLB← { ⍵↓⍨  +/∧\ ' '= ⍵ }
    SkipTB← { ⍵↓⍨ -+/∧\⌽' '= ⍵ }
    SkipCm← ⊃∘⌽{ ⍝ For now, we're ignoring the comment itself.
      cm≠⊃⍵: '' ⍵ 
      cm{
        0=≢⍵: ⍺ ⍵ 
        ⍵ Case lb rb eos: ⍺ ⍵ 
        ⍵ NotCase esc: (⍺, ⊃⍵) ∇ 1↓⍵
          w1← 1↓⍵
        w1 Case lb rb eos: (⍺, 2↑⍵) ∇ 1↓w1
          (⍺, ⊃⍵)∇ w1 
      }1↓⍵
    }
    Trunc← { ⍺←50 ⋄ ⍺≥≢⍵: ⍵ ⋄ '...',⍨⍵↑⍨0⌈⍺-4 } 
    GetQt←{   
      ~sq dq∊⍨⊃⍵: '' ⍵
      qt← ⊃⍵
      ''{
        0=≢⍵: (Qt2Cod ⍺) (SkipLB ⍵ )
          w1← 1↓⍵
        qt∧.∊⍨ 2↑⍵: (⍺,qt) ∇ 1↓w1
        qt  Match  ⊃⍵:  (Qt2Cod ⍺) (SkipLB w1)
        esc NMatch ⊃⍵: (⍺, ⊃⍵)  ∇ 1↓⍵
        eos Match ⊃w1: (⍺, nl)  ∇ 1↓w1
        esc Match ⊃w1:  s ⍺ (∇ ProcEsc inQt) 1↓w1   
          (⍺,⊃⍵)∇ w1 
      }1↓⍵
    }
    SplitNot← { 0=p← +/∧\~⍵∊ ⍺: '' ⍵ ⋄ ( p↑⍵ ) (p↓⍵) }
    T2Q← sq∘{ ⍺, ⍺,⍨ ⍵/⍨ 1+⍺= ⍵ }                              ⍝ Text to Quote String 
    Qt2Cod←{ 
        Q← {⍵/⍨ 1+⍵=sq}
        sq sp←''' ' ⋄ useMix←0
        r← ⎕FMT Q ⍵
      1=≢r: sp,sq,(∊r),sq,sp 
      useMix: '(↑',(¯1↓∊sq,¨(SkipTB¨↓r),¨⊂sq sp),')'   
        '(',(sq,sq,⍨∊r),'⍴⍨',(⍕⍴r),')'
    }
    ProcEsc← { w1← 1↓⍵
      eos Match ⊃⍵:       (⍺, nl         )⍺⍺ w1
      esc Match ⊃⍵:       (⍺, ⊃⍵         )⍺⍺ w1
      lb rb Match ⊃⍵:     (⍺, e, ⊃⍵      )⍺⍺ w1 ⊣ e← esc/⍨ inQt=⍵⍵ 
      inCF≠⍵⍵:            (⍺, esc, ⊃⍵    )⍺⍺ w1 
      om omU NMatch ⊃⍵:   (⍺, esc, ⊃⍵    )⍺⍺ w1 
                          (⍺, '(', o, ')')⍺⍺ w  ⊣ o w← SplitOm w1                   
    } ⋄ inQt inTF inCF← 0 1 2
    SplitOm← {
      dig← ⍵↑⍨+/∧\⍵∊⎕D 
      0=≢dig: ('⍵⊃⍨⎕IO+',(⍕omIx)) (SkipLB ⍵     )  ⊣ omIx+← 1
              ('⍵⊃⍨⎕IO+',(⍕omIx)) (SkipLB ⍵↓⍨≢dig) ⊣ omIx⊢← ⊃⌽⎕VFI dig  
    }
  ⍝ Major Fns 
    TF←{
      0=≢⍵: ''
      tf w← ''{
        0=≢⍵:       ⍺ ⍵
        ×≢⊃t w← impTF SplitNot ⍵: (⍺, t) ∇ w                  ⍝ Fast skip of "unimportant" chars!
        sp Match ⊃⍵:  (⍺, p↑⍵)∇ p↓⍵ ⊣ p← LenLB ⍵
        lb Match ⊃⍵:   ⍺ ⍵
        esc Match ⊃⍵:  ⍺ (∇ ProcEsc inTF) 1↓⍵   
                    (⍺, ⊃⍵)  ∇ 1↓⍵
      } ⍵
      (Qt2Cod tf) w
    }
    CF←{
      0=≢⍵: '' ⍵ 
      lb NMatch ⊃⍵: '' ⍵
      brks← 0
      r w←''{
          0=≢⍵: ⍺ ⍵                                            ⍝ Terminate
          ×≢⊃t w← impCF SplitNot ⍵: (⍺, t) ∇ w                 ⍝ Fast skip of "unimportant" chars!
          sp Match ⊃⍵: (⍺, 1↑⍵)∇ ⍵↓⍨ p← LenLB ⍵
          lb Match ⊃⍵: (⍺, ⊃⍵) ∇ 1↓ ⍵⊣ brks+← 1 
          rb Match ⊃⍵: ⍺ ∇{ brks-← 1 ⋄ w1← 1↓⍵
            brks≤0: (⍺, ⊃⍵) w1                                 ⍝ Terminate! 
            (⍺, ⊃⍵) ⍺⍺ w1                      
          } ⍵
          sq dq Match ⊃⍵:   (⍺, q           ) ∇ w⊣ q w← GetQt ⍵
              w1← 1↓⍵ 
          fmt Match ⊃⍵:     (⍺, ' ⎕FMT '    ) ∇ SkipLB w1
          ovr Match ⊃⍵:     (⍺, ' ⍙ⓄⓋⓇ '    ) ∇ SkipLB w1 ⊣ inclRun∘← 1
          omU Match ⊃⍵:     (⍺, '(', o, ')' ) ∇ w ⊣ o w← SplitOm w1
          esc Match ⊃⍵:      ⍺ (∇ ProcEsc inCF) w1    
          cm Match ⊃⍵:       ⍺                ∇ SkipCm ⍵
                            (⍺, ⊃⍵          ) ∇ w1 
      } SkipLB 1↓⍵
      ('({', r, '⍵)') w 
    }
    SplitSF← {  
      lb NMatch ⊃⍵: 11 ⎕SIGNAL⍨ 'Logic error!' ⍝ 0 '' ⍵
        w← SkipCm ⍵↓⍨1+p← LenLB 1↓⍵
      cln rb NMatch ⊃w: 0 '' ⍵ 
      isRB← rb Match ⊃w
          w1← 1↓w 
      isRB∧ 0=p: 1 '' w1  
          sCod← '(''''⍴⍨'
      isRB:  1 (sCod,(⍕p),')')  w1
          Skip2EOS← { ⍵↓⍨ 1+ ⍵⍳ rb } 
      omU om Match ⊃w1:                     1 (sCod, o,')') (Skip2EOS w)  ⊣ o w← SplitOm w1     
      (esc Match ⊃w1) ∧ om omU Match ⊃1↓w1: 1 (sCod, o,')') (Skip2EOS w)  ⊣ o w← SplitOm 2↓w1      
         ok num← {⎕VFI ⍵↑⍨ ⍵(⌊/⍳) cln rb} w1
      1≢⍥, ok: 0 '' ⍵                                          ⍝ Fail if not exactly 1 valid number
      num=0:   1 '' (Skip2EOS w1)                              ⍝ If 0-length space field, field is null.
        1 (sCod,(⍕num),')')  (Skip2EOS w1) 
    }

    Main←{
      0=≢⍵: ⍺  
      lb NMatch ⊃⍵: w ∇⍨ ⍺, ⊂⍣(×≢tf)⊢ tf ⊣tf w← TF ⍵ 
        isSF sf w←SplitSF ⍵
      isSF: w ∇⍨ ⍺, ⊂⍣(×≢sf)⊢sf 
        cf w← CF ⍵ 
        w ∇⍨ ⍺, ⊂⍣(×≢cf)⊢cf 
    }
    code← ⌽⍬ Main fmtS

    pre←   preCode,⍨ runDefs/⍨ inclRun 
    1=mo: '{',  pre, (∊code), '}⍵⍵'
    0=mo: '{{', pre, (∊code), '}', (T2Q fmtS),',⊆⍵}'
        (⊂'{{', pre),  code, ⊂'}', (T2Q 25∘Trunc fmtS),',⊆⍵}⍵'
  }⍵
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
⍝H       [¯1], [¯2] pseudo-code for inspection (debugging or pedagogy).
⍝H             [¯1] each field a separate vector in a vector of vectors
⍝H             [¯2] Same as [¯1] but the vectors raveled (⍪) and boxed.
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
⍝H          $  $ is equiv. to ⎕FMT. For sanity, use with a left argument in double quotes:
⍝H ⍎               ∆F '{ "⎕<⎕,F7.5,⎕>⎕" $ ?0 0}'
⍝H ⎕           <0.47805>
⍝H ⎕           <0.46475>
⍝H          %  % prints object ⍺ centered over object ⍵ (itself centered, if the narrower obj.).
⍝H ⍎               ∆F '{ "Random Nums" % "⎕<⎕,F7.5,⎕>⎕" $ ?0 0}'
⍝H ⎕           Random Nums
⍝H ⎕            <0.43528> 
⍝H ⎕            <0.61564> 
⍝H          %  % may also be used monadically to insert a blank line above your output:
⍝H ⍎               ∆F '{⎕DL `⍵ }{%⎕DL `⍵ }{%%⎕DL `⍵ }' 0.1  0.2 0.3
⍝H ⎕           0.107371                          ⍝ ⎕DL 0.1                        
⍝H ⎕                   0.204216                  ⍝ ⎕DL 0.2   
⍝H ⎕                           0.300909          ⍝ ⎕DL 0.3
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
