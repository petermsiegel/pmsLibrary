:namespace ⍙F 
  ∇ ⍙⍙RES← {⍙⍙L} ∆F ⍙⍙R  ; ⎕TRAP 
    ⎕TRAP← 0 'C' '⎕SIGNAL ⊂⎕DMX.(''EM'' ''EN'' ''Message'' ,⍥⊂¨(''∆F '',EM) EN Message)'
    :If 900⌶0 
        ⍙⍙L← ⍬
    :ElseIf 0≠ ⊃0⍴⍙⍙L
        ⍙⍙RES← ⎕THIS.Help ⍙⍙L ⋄ :Return 
    :EndIf 
    :If ⊃⍙⍙L← 4↑⍙⍙L   ⍝ Generate Dfn from f-string ⊃⍙⍙R. ⍙⍙R is of the form '{{code}(⊂''f-string''),⍵}' 
        ⍙⍙RES← (⊃⎕RSI)⍎ ⍙⍙L ⎕THIS.Main ⊃,⊆⍙⍙R
    :Else              ⍝ Generate and evaluate code from f-string ⊃⍙⍙R. The code string ⍙⍙R is of the form '{code}⍵'.
        ⍙⍙RES← (⊃⎕RSI){⍺⍎ (⎕EX '⍙⍙L' '⍙⍙R')⊢⍙⍙L ⎕THIS.Main ⊃⍙⍙R} ⍙⍙R← ,⊆⍙⍙R
    :Endif 
  ∇
    ##.⎕FX '⎕THIS'  ⎕R (⍕⎕THIS)⊢ ⎕NR '∆F'
  

  ⍝ Performance of <∆F x> is comparable to C language version of ∆F
  ⍝    F-string                            This version vs C-version
  ⍝    ⎕A                                  ~1:1
  ⍝    'one`⋄two{ }{$$⍳2 2}{} one`⋄ two'    ~1:1 

⍝ Top Level Routines...
  ⍝ Main: The "main" function for ∆Fre...
  ⍝ result← [4↑ options] Main f_string
    Main← {  
        (dfn dbg box inline) fStr← ⍺ ⍵ 
        omIx cr← 0 (dbg⊃ crCh crVis) ⍝ crCh: (⎕UCS 13), crVis: '␍' 
        DM← (⎕∘←)⍣dbg                                               ⍝ DM: Debug Msg
      0=≢fStr:  DM '(1 0⍴⍬)', dfn/'⍨'                               ⍝ f-string (⍵) is '' or ⍬
        extern← ⎕NS 'dbg' 'omIx' 'cr' 'inline'                      ⍝ omIx: r/w; dbg, cr, inline: r/o
        flds← OrderFlds extern∘ProcFlds¨ SplitFlds fStr  
        code← '⍵',⍨ lb, rb,⍨ flds,⍨ box inline⊃ cM cD
      ~dfn: DM code                                                  ⍝ Not a dfn. Emit code ready to execute
        quoted← ',⍨ (⊂', ')',⍨ q, q,⍨ fStr/⍨ 1+ fStr= q             ⍝ dfn: add quoted fmt string.
        DM lb, code, quoted, rb                                      ⍝ emit dfn string ready to convert to dfn itself
    } 
  ⍝ Help: Provides help info when ∆F⍨'help[x]' (OR 'help[x]'∆F anything) is specified.
  ⍝ (1 0⍴⍬)← Help 'help' OR 'helpx'
    Help← { 
      'help'≢⎕C4↑ ⍵: ⎕SIGNAL ⊂'EN' 11,⍥⊂ 'Message' 'Invalid option(s)'
        hP← ('^\s*⍝HX?'↓⍨ 'xX'(-∨/⍤∊) ⍵), '(.*)' 
        1 0⍴⍬⊣ ⎕ED ⍠'ReadOnly' 1⊢'h'⊣ h← hP ⎕S '\1'⊣ ⎕SRC ⎕THIS  
    }

⍝ Constants (For variables, see namespace ¨extern¨ in main)
    ⎕IO ⎕ML←0 1 
  ⍝ Constant char values
    esc← '`'   
    crCh crVis← ⎕UCS 13 9229                                     ⍝ crVis: Choose 8629 ↵ 9229 ␍
    s lb rb q dmd← ' {}''⋄' 
    escEsc escLb escRb escDmd ← esc,¨ esc lb rb dmd  
    qq sQ qS sLb← (q q) (s q) (q s) (s lb)      
    arrows← '▼▶'                                                 ⍝ See SelfDocCode
  ⍝ Const patterns 
    cfPats←  '\$\$' '\$' '%' '(?:`⍵|⍹)(\d*)' '(?:"[^"]*")+|(?:''[^'']*'')+'
    ⍝ See SplitFlds...
    ⍝ ⍙splitSF0: Match 0-length space fields as null fields ('')
    ⍙splitSF0← '(?:\{\})+'
    ⍝ ⍙splitSF:  Match space fields (0-length handled above) per SpaceFld below. Signaled by pattern ' {'.
    ⍙splitSF←  '\{\h*\}'
    ⍝ ⍙splitCF: Match code fields, i.e. recursively balanced braces {} and contents, 
    ⍝           handling quotes "..." ''...'' and escapes `.  
    ⍙splitDFn← '(?x) (?<P> (?<!`) \{ ((?> [^{}"''`]+ | (?:`.)+ | (?:"[^"]*")+ | (?:''[^'']*'')+ | (?&P)* )+) \} )' 
    splitPats←  ⍙splitSF0 ⍙splitSF  ⍙splitCF 
    splitRepl← '\n\n'     '\n \0\n' '\n\1\n'
 
⍝ "Options" Operator for ⎕R. Only LF is an EOL. CR is specifically a literal in text fields and quoted strings.
    _Opts← ⍠'EOL' 'LF' 

⍝ Utility to be executed at ⎕FIX (aka ]load ) time
  ⍝ LoadRTL: At ⎕FIX time, load the run-time library names and code.  
    ⍝ For A, B, D, F, M; all like A example shown here:
    ⍝     A← an executable dfn in this namespace (⎕THIS).
    ⍝     cA← name codeString, where
    ⍝         name is (⍕⎕THIS),'.A'
    ⍝         codeString is the executable dfn in string form.
    ∇ {ok}← LoadRTL 
     ;XR ;HT 
        XR← ⎕THIS.⍎⊃∘⌽                                                 ⍝ Execute the right-hand expression
        HT← '⎕THIS' ⎕R (⍕⎕THIS)                                        ⍝ "Hardwire" absolute ⎕THIS.  
    ⍝ A (etc): a dfn
    ⍝ cA (etc): [0] local absolute name of dfn (with spaces), [1] its code        
      A← XR cA← HT ' ⎕THIS.A ' '{⍺←⍬⋄⎕ML←1⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}'  ⍝ A: [⍺]above ⍵    (1- or 2-adic)
      B← XR cB← HT ' ⎕THIS.B ' '{⍺←0⋄⎕ML←1⋄⍺⎕SE.Dyalog.Utils.disp⊂⍣(1≥≡⍵),⍣(0=≡⍵)⊢⍵}'   ⍝ B: box ⍵         (1- or 2-adic)
      D← XR cD← HT ' ⎕THIS.D ' '0∘⎕SE.Dyalog.Utils.disp¯1∘↓'                            ⍝ D: display ⍵     (1-adic)
      F← XR cF←    ' ⎕FMT '    ' ⎕FMT '                                                 ⍝ F: [⍺] format ⍵   (1- or 2-adic)
      M← XR cM← HT ' ⎕THIS.M ' '{⍺←⊢⋄⎕ML←1⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}'                      ⍝ M: merge[⍺] ⍵    (1- or 2-adic)
      ok← 1 
    ∇
    LoadRTL

⍝ Functions
  ⍝ TextFld
    ⍝ ⍺: namespace of external (global) vars
    TextFld← { 
        sQ, qS,⍨ escDmd escEsc escLb escRb q ⎕R ⍺.cr esc lb rb qq _Opts ⍵ 
    }
  ⍝ SpaceFld: A variant of a code field. 
    ⍝ A space field consists solely of 0 or more spaces (within the originally surrounding braces).
    ⍝ SpaceFld ⍵, returns: ((≢⍵)⍴'') as a char. string.
    SpaceFld← { 
        '(','⍴'''')',⍨ ⍕≢⍵ 
    }
  ⍝ SelfDocCode: Checks for self-documenting code (sdc) of form { ... ch [sp*] }, where ch ∊ '→%↓' [% is an alias for ↓].
    ⍝ Returns cStr dFun dStr  
    ⍝     cStr: orig code string removing appended ch∊ "↓%→" (orig. code string if not a doc str.)   
    ⍝     dFun: if sdc, cAbove (if appended '↓' or '%'), else cMerge ('→'); else ''.
    ⍝     dStr: orig. literal sdc string, but in quotes; else ''.
    ⍝ ⍺: namespace of external (global) vars
    SelfDocCode←{  
        ch← ⍵⌷⍨ p← (≢⍵)-1+ +/∧\ ⌽' '= ⍵             ⍝ Note pos of self-doc code char and its value
      ~'→↓%'∊⍨ ch: ⍵ '' ''                          ⍝ If none, return original input string and null char vecs.
        dTyp← ch='→'                                ⍝ dTyp: 1 for horizontal, 0 for vertical self doc code.
        dStr← (arrows⊃⍨ dTyp)@p⊣ ⍵                  ⍝ Generate the doc string
        dStr← q, q,⍨ dStr/⍨ 1+q= dstr  
        (p↑⍵) (dTyp ⍺.inline⊃ cA cM) dStr           ⍝ Return code in str form, display fn code in str form, the doc str
    }
  ⍝ CodeFld:  
    ⍝ Process escapes within code fields, including omegas, newlines; and quoted strings.
    ⍝ ⍺: namespace of external (global) vars
    CodeFld← { extern←⍺ 
        cStr dFun dStr ← extern SelfDocCode ⍵                    ⍝ Is CodeFld Self-documenting?  
        cStr← cfPats ⎕R {
              p← ⍵.PatternNum 
            p∊0 1 2: p extern.inline⊃ cB cF cA                   ⍝ $$ $ % 
            p=4:  q, q,⍨ q escEsc escDmd ⎕R qq esc extern.cr _Opts⊢ 1↓¯1↓ ⍵.Match  ⍝ "..." or '...' 
              o← { 
                0= ≢⍵: extern.omIx+1                             ⍝ `⍵ and ⍹. Grab, incr, and use existing omIx.
                ⊃⌽⎕VFI ⍵                                         ⍝ `⍵nnn and ⍹nnn. Decode and store nnn as omIx.
              } ⍵.(Lengths[1]↑ Offsets[1]↓ Block)
            p=3: '(⍵⊃⍨⎕IO+', ')',⍨ ⍕extern.omIx← o               ⍝ `⍵[nnn] and ⍹[nnn] 
        } cStr  
        '({', dStr, dFun, cStr, '}⍵)'
    }
  ⍝ OrderFlds
    ⍝ ∘ User flds are effectively executed L-to-R and displayed in L-to-R order 
    ⍝   by reversing their order, evaluating all of them (via APL ⍎) R-to-L, then reversing again when executed in caller.
    OrderFlds←  {                       ⍝  If at least one non-null field, 
      0∨.< ≢¨⍵: '⌽', ∊⌽⍵, '⍬'          ⍝  ensure at least 2 and reverse, emitting code to re-reverse
                '⍬⍬'                    ⍝  Only null fields. Return 2 of them (minimum required)
    }  
  ⍝ ProcFlds: Process each Code (or Space) and Text field. 
    ⍝ ⍺: namespace of external (global) vars
    ProcFlds← { 
      0=≢⍵: ''                      ⍝ 0-length input => output null str *
      sLb≡2↑⍵: SpaceFld 2↓¯1↓⍵      ⍝ ' {' means a space field *
      lb=⊃⍵: ⍺ CodeFld 1↓¯1↓⍵       ⍝ '{'  means a code field *
             ⍺ TextFld ⍵            ⍝ Otherwise, a text field.
    }                               ⍝                          [*] encoded via SplitFlds
  ⍝ SplitFlds: Split f-string into 0 or more fields, ignoring possible null fields generated.
  ⍝            Trailing 0-length space fields are ignored.  { }{}{}{} ==> { }.   {}{}{} ==> {}.
    SplitFlds← splitPats ⎕R splitRepl _Opts ⊆
⍝H 
⍝H -------------
⍝H  ∆F IN BRIEF
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H ∆F is a function that makes it easy to format strings that dynamically display text, variables, and 
⍝H the value of code expressions in an APL-friendly multi-line (matrix) style. 
⍝H   ∘ Text expressions can generate multi-line Unicode strings 
⍝H   ∘ Each code expression is an ordinary dfn, with a few extensions:
⍝H          e.g. use of double-quoted strings, escape chars, and simple formatting shortcuts for APL arrays. 
⍝H   ∘ All variables and code are evaluated (and, if desired, updated) in the user's calling environment. 
⍝H   ∘ ∆F is inspired by Python F-strings, but designed for APL.
⍝H 
⍝H ∆F: Calling Information
⍝H ¯¯¯ ¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
⍝H result←              ∆F f-string [arg1 arg2 ... ]   Format an ∆F String given args and simply display  
⍝H          [{options}] ∆F f-string [arg1 arg2 ... ]   Format an ∆F String given args; cnt'l result with opt'ns.
⍝H                      ∆F⍨'help'                      Display help information
⍝H 
⍝H F-string and args:
⍝H   first element: 
⍝H       an f-string, a single character vector (see "∆F in Detail" below) 
⍝H   args:          
⍝H       elements of  ⍵ after the f-string, each of which can be accessed, via a shortcut 
⍝H       that starts with `⍵ or ⍹ (Table 1)
⍝H   result: If (0=⊃options), the result is always a character matrix. 
⍝H           If (1=⊃options), the result is a dfn that, when executed, generates a character matrix.
⍝H  
⍝H   Table 1:
⍝H       Escape (`) Shortcut   ⍹ Shortcut    Meaning
⍝H       ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯   ¯¯¯¯¯¯¯¯¯¯    ¯¯¯¯¯¯¯¯
⍝H       `⍵1, `⍵2              ⍹1, ⍹2        (⍵⊃⍨ ⎕IO+1), (⍵⊃⍨ ⎕IO+2)
⍝H       `⍵                    ⍹             the "next" arg*, starting with the 1st: (⍵⊃⍨ ⎕IO+1)
⍝H       `⍵0                   ⍹0            the f-string itself, i.e. (⍵⊃⍨ ⎕IO)
⍝H  ---------------------------------
⍝H      [*] next, reading L-to-R across all code fields. `⍵N or ⍹N sets "next" to (⍵⊃⍨ ⎕IO+N+1)
⍝H 
⍝H Left arg (⍺) to ∆F:   [ [ options← 0 [ 0 [ 0 [ 0 ] ] ] ] | 'help[x]' ]   
⍝H    If there is no left arg, 
⍝H         the default options (4⍴ 0) are assumed per below;
⍝H    If the left arg ⍺ is 0 to 4 digits,
⍝H         the options are taken as (4↑⍺);
⍝H    If the left arg is 'help' or 'helpx', 
⍝H         ⍵ is ignored, ∆F shows help or example information and returns (1 0⍴⍬);
⍝H    Otherwise,
⍝H         an error is signaled.
⍝H    Options:  [ DFN DBG BOX INLINE ]
⍝H    Defaults:     0   0   0   0    
⍝H    The options are:
⍝H       DFN: If 0, returns a formatted matrix object based on the f-string (0⊃⍵) and any other "args" referred to.
⍝H            If 1, returns a dfn that, when executed, returned a formatted matrix object, as above.
⍝H       DBG: If 0, returns the value as above.
⍝H            If 1, displays the code generated based on the f-string, befure returning a value.
⍝H       BOX: If 0, returns the value as above.
⍝H            If 1, returns each field generated within a box (dfns "display"). 
⍝H    INLINE: If 0, ⍙F library routines A, B, D, F, and M will be used.
⍝H            If 1, the CODE of A, B, D, F, and M are used "in line" to make the resulting runtime code 
⍝H            independent of the ⍙F namespace.
⍝H
⍝H Result Returned: 
⍝H   If (⊃⍺) is 0,  the default, then:
⍝H     ∘ the result is always a matrix, with at least one row and zero columns, unless an error occurs.
⍝H     ∘ If the f-string is null, always returns a matrix of shape (1 0).
⍝H   If (⊃⍺) is 1, then: 
⍝H     ∘ the result returned is a dfn (function) that, when executed with the same environment and arguments,
⍝H       generates the same matrix as above, unless an error occurs.
⍝H   If an error occurs, 
⍝H     ∘ ∆F generates a standard, trappable Dyalog ⎕SIGNAL.
⍝H   If ⍺ starts with 'help' but does not contain 'x' 
⍝H     ∘ ∆F displays help information. 
⍝H   If ⍺ starts with 'help' followed by 'x', 
⍝H     ∘ only examples are shown.
⍝H 
⍝H --------------
⍝H  ∆F IN DETAIL
⍝H --------------
⍝H 
⍝H The first argument to ∆F is a character vector, an "∆F string", which contains simple text, 
⍝H along with run-time evaluated expressions delimited by (unescaped) curly braces {}. 
⍝H Each ∆F string is viewed as containing one or more "fields," catenated left to right*,
⍝H each of which will display as a logically separate character matrix. 
⍝H            * ∆F suppresses automatic spaces that would be added by APL to denote object rank, etc.
⍝H 
⍝H ∆F-string text fields (expressions) may include:
⍝H   ∘ escape characters representing newlines, escape characters and braces as text. 
⍝H     newlines "`⋄", escape character itself "``", actual braces "`{" or "`}". 
⍝H     Otherwise, { and } delineate the start and end of a Code Field or Space Field.
⍝H ∆F-string code fields (expressions) may include: 
⍝H   ∘ escape characters (e.g. representing newlines, escape characters, and braces as text);
⍝H   ∘ dyadic ⎕FMT control codes for concisely formatting integers, floats, and the like into tables ($);
⍝H   ∘ the ability to display an arbitrary object centered above another (%);
⍝H   ∘ shortcuts for displaying boxed output ($$); finally,
⍝H   ∘ self-documenting code fields are concise expressions for displaying both a code 
⍝H     expression (possible a simple name to be evaluated) and its value (→, ↓/%).   
⍝H     (Only code fields may be self-documenting!).
⍝H ∆F-strings include space fields:
⍝H   ∘ which appear as "degenerate" code fields (braces with 0 or more spaces between).
⍝H     ∘ space fields separate other fields, often with extra spaces (columns of rectangular spaces).
⍝H 
⍝H The syntax of ∆F Strings is as follows, where ` represents the active escape character:
⍝H   ∆F_String         ::=  (Text_Field | Code_Field | Space_Field)*
⍝H   Text_Field        ::=  (literal_char | "`⋄" | "``" | "`{" | "`}" )
⍝H   Code_Field        ::=  "{" (Fmt | Above | Box | Code )+ (Self_Documenting) "}"
⍝H   Space_Field       ::=  "{"  <0 or more spaces> "}"
⍝H   Code              ::=   A Dyalog dfn, each passed the arguments to ∆F as ⍵: 
⍝H                           `⍵ (or ⍹) selects the next object in ⍵ (starting with (1⊃⍵), ⎕IO←0); 
⍝H                           `⍵N (or ⍹N) selects the Nth object in ⍵ (⎕IO←0), where N is 1-3 digits;
⍝H                           `⍵0 (or ⍹0) selects the text of the ∆F_String itself;
⍝H                           quoted strings: "..." or ''...'', where ... may include 
⍝H                                    `⋄ to represent a newline, 
⍝H                                    `` to represent the escape char itself.
⍝H                                    Double " within a "..." quote to include a double quote.
⍝H                                    Double ' within a '...' quote to include a single quote.
⍝H   Fmt               ::=   [ ("⎕FMT Control Expressions") "$" Code] 
⍝H   Above             ::=   ("(" Code<Generating any APL Object>")") "%" (Code<Generating Any APL Object)>
⍝H                           % (Code<Generating an APL Object)>, with implicit left arg "".
⍝H   Box               ::=   "$$" Code 
⍝H                           Box the result from executing code (uses ⎕SE.Dyalog.disp).
⍝H   Self_Documenting  ::=   (" ")* ("→" | "↓" | "%" ) (" ")*, where % is a synonym for ↓.
⍝H   Code                    See examples.
⍝H 
⍝HX Examples:
⍝HX ⍝ Simple variable expression
⍝HX   name← 'Fred'
⍝HX   ∆F "His name is {name}."
⍝HX   His name is Fred.
⍝HX 
⍝HX ⍝ Some multi-line text fields separated by non-null space fields
⍝HX   ∆F 'This`⋄is`⋄an`⋄example{ }Of`⋄multi-line{ }Text`⋄Fields'
⍝HX This    Of         Text  
⍝HX is      multi-line Fields
⍝HX an                       
⍝HX example 
⍝HX 
⍝HX ⍝ A similar example with strings in code fields
⍝HX   ∆F '{"This`⋄is`⋄an`⋄example"}  {"Of`⋄Multi-line"}  {"Strings`⋄in`⋄Code`⋄Fields"}'
⍝HX This     Of          Strings
⍝HX is       Multi-line  in     
⍝HX an                   Code   
⍝HX example              Fields 
⍝HX   
⍝HX ⍝ Like the example above, with useful data
⍝HX   fn←   'John'           'Mary'         'Bill'
⍝HX   ln←   'Smith'          'Jones'        'Templeton'
⍝HX   addr← '24 Mulberry Ln' '22 Smith St'  '12 High St'
⍝HX   ∆F '{↑fn} {↑ln} {↑addr}'
⍝HX John Smith     24 Mulberry Ln
⍝HX Mary Jones     22 Smith St   
⍝HX Bill Templeton 12 High St 
⍝HX     
⍝HX ⍝ A slightly more interesting code expression
⍝HX   C← 11 30 60
⍝HX   ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ 32+9×C÷5}°F'
⍝HX The temperature is 11°C or  51.8°F
⍝HX                    30       86.0  
⍝HX                    60      140.0 
⍝HX  
⍝HX ⍝ Using "boxes" via the $$ (box) pseudo-primitive
⍝HX   ∆F'`⋄The temperature is {$$⊂"I2" $ C}`⋄°C or {$$⊂"F5.1" $ 32+9×C÷5}`⋄°F'
⍝HX                    ┌──┐      ┌─────┐
⍝HX The temperature is │11│°C or │ 51.8│°F
⍝HX                    │30│      │ 86.0│ 
⍝HX                    │60│      │140.0│ 
⍝HX                    └──┘      └─────┘    
⍝HX            
⍝HX ⍝ Using outside expressions
⍝HX   C← 11 30 60
⍝HX   C2F← 32+9×5÷⍨⊢
⍝HX   ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ C2F C}°F'
⍝HX The temperature is 11°C or  51.8°F
⍝HX                    30       86.0  
⍝HX                    60      140.0 
⍝HX 
⍝HX ⍝ Using ∆F additional arguments (`⍵1 ==> (1⊃⍵), where ⎕IO←0)
⍝HX   ∆F'The temperature is {"I2" $ `⍵1}°C or {"F5.1" $ C2F `⍵1}°F' (11 15 20)
⍝HX The temperature is 11°C or  51.8°F
⍝HX                    15       59.0  
⍝HX                    20       68.0 
⍝HX 
⍝HX ⍝ Use argument `⍵1 (i.e. 1⊃⍵) in a calculation.      'π²' is (⎕UCS 960 178) 
⍝HX   ∆F 'π²={`⍵1*2}, π={`⍵1}' (○1)   
⍝HX π²=9.869604401, π=3.141592654
⍝HX 
⍝HX ⍝ "Horizontal" self-documenting code fields (source code to the left of the evaluated result).
⍝HX   name←'John Smith' ⋄ age← 34
⍝HX   ∆F 'Current employee: {name→}, {age→}.'
⍝HX Current employee: name▶John Smith, age▶34.
⍝HX
⍝HX ⍝ Note that spaces adjacent to self-documenting code symbols (→ or ↓) are mirrored in the output:
⍝HX   name←'John Smith' ⋄ age← 34
⍝HX   ∆F 'Current employee: {name → }, {age→   }.'
⍝HX Current employee: name ▶ John Smith, age▶   34.
⍝HX 
⍝HX ⍝ "Vertical" self-documenting code fields (the source code centered over the evaluated result)
⍝HX   name←'John Smith' ⋄ age← 34
⍝HX   ∆F 'Current employee: {name↓} {age↓}.'
⍝HX Current employee:   name▼    age▼.
⍝HX                   John Smith  34 
⍝HX 
⍝HX ⍝  Displaying the expression on the left centered above the expression on the right (% pseudofunction) 
⍝HX   ∆F '{"Current Employee" % ⍪`⍵1}   {"Current Age" % ⍪`⍵2}' ('John Smith' 'Mary Jones')(29 23)
⍝HX Current Employee   Current Age
⍝HX    John Smith          29     
⍝HX    Mary Jones          23 
⍝HX 
⍝HX ⍝ Display more complex expressions one above the other.
⍝HX ⍝ Here we use `⍵, which selects the "next" item from ⍵, moving left to right, starting with (1⊃⍵).
⍝HX ⍝ I.e. in the code below, we have select (⍳2⍴1⊃⍵), then (⍳2⍴2⊃⍵), then (⍳2⍴3⊃⍵).
⍝HX ⍝ We don't select (0⊃⍵) as the initial (`⍵), since that is the ∆F-String itself. 
⍝HX   ∆F'{(⍳2⍴`⍵) % (⍳2⍴`⍵) % (⍳2⍴`⍵)}' 1 2 3 
⍝HX     0 0      
⍝HX   0 0  0 1    
⍝HX   1 0  1 1    
⍝HX 0 0  0 1  0 2 
⍝HX 1 0  1 1  1 2 
⍝HX 2 0  2 1  2 2 
⍝HX ⍝ Equivalent to (⎕IO←0):
⍝HX ∆F'{(⍳2⍴ (⍵⊃⍨1+⎕IO)) % (⍳2⍴ (⍵⊃⍨2+⎕IO)) % (⍳2⍴ (⍵⊃⍨3+⎕IO))}' 1 2 3 
⍝HX
⍝HX ⍝ Use of box option: shows and demarcates each field (boxed) left to right.
⍝HX   C← 11 30 60
⍝HX   0 0 1 ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝HX ┌───────────────────┬──┬──────┬─────┬──┐
⍝HX │                   │11│      │ 51.8│  │
⍝HX │The temperature is │30│°C or │ 86.0│°F│
⍝HX │                   │60│      │140.0│  │
⍝HX └───────────────────┴──┴──────┴─────┴──┘
⍝HX
⍝HX ⍝ Performance of an ∆F-string evaluated on the fly via (∆F ...) and precomputed via (1 ∆F ...): 
⍝HX   C← 11 30 60
⍝HX ⍝ Here's our ∆F String <t>
⍝HX   t←'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝HX ⍝ Precompute a dfn T given ∆F String <t>.
⍝HX   T←1 ∆F t      ⍝ T← Generate a dfn w/o having to recompile (analyse) <t>. Equiv. to: T←('Dfn' 1) ∆F t
⍝HX ⍝ Compare the performance of the two formats: the precomputed version is over 4 times faster here.
⍝HX   cmpx '∆F t' 'T ⍬'
⍝HX  ∆F t → 5.7E¯5 |   0% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
⍝HX  T ⍬  → 1.4E¯5 | -76% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕   
⍝HX
:EndNamespace 
