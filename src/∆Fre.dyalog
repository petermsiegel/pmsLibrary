:namespace ⍙F 
  ∇ ⍙⍙RES← {⍙⍙L} ∆F ⍙⍙R  ; ⎕TRAP 
  ⍝ Performance of <∆F x> relative to C language version of ∆F
  ⍝    F-string                            This version vs C-version
  ⍝    ⎕A                                  ~1:1
  ⍝    'one`⋄two{ }{$$⍳2 2}{} one`⋄ two'    ~20-25% slower
    ⎕TRAP← 0 'C' '⎕SIGNAL ⊂⎕DMX.(''EM'' ''EN'' ''Message'' ,⍥⊂¨(''∆F '',EM) EN Message)'
    :If 900⌶0 
        ⍙⍙L← ⍬
    :ElseIf 0=≢ ⍙⍙L 
        ⍙⍙RES← 1 0⍴'' ⋄ :Return 
    :ElseIf ' '=⊃ 0⍴⍙⍙L
        ⍙⍙RES← ⎕THIS.Help ⍙⍙L ⋄ :Return 
    :EndIf 
    :If ⊃⍙⍙L← 4↑ ⍙⍙L   ⍝ Generate Dfn from f-string ⊃⍙⍙R 
        ⍙⍙RES← (⊃⎕RSI)⍎ ⍙⍙L ⎕THIS.ParseFString ⊃⍙⍙R← ,⊆⍙⍙R
    :Else              ⍝ Generate and evaluate code from f-string ⊃⍙⍙R (⍙⍙R contains an ⍵)
        ⍙⍙RES← (⊃⎕RSI){⍺⍎ ⍙⍙L ⎕THIS.ParseFString ⊃⍙⍙R} ⍙⍙R← ,⊆⍙⍙R
    :Endif 
  ∇
    ##.⎕FX   '⎕THIS'  ⎕R (⍕⎕THIS)⊢ ⎕NR '∆F'

⍝ Constants 
    ⎕IO ⎕ML←0 1 
  ⍝ Run-time library routines ⎕SE.⍙F.
  ⍝ If ⍺
  ∇ {standalone}← Library standalone ;QS; this1; this2  
     ⎕SHADOW '_',¨'ABDMF' 
    _A← '{⍺←⍬⋄⎕ML←1⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}'  ⍝ [⍺]above ⍵    (1- or 2-adic)
    _B← '{⍺←0⋄⎕ML←1⋄⍺⎕SE.Dyalog.Utils.disp⊂⍣(1≥≡⍵),⍣(0=≡⍵)⊢⍵}'   ⍝ box ⍵         (1- or 2-adic)
    _D← '0∘⎕SE.Dyalog.Utils.disp¯1∘↓'                            ⍝ display ⍵     (1-adic)
    _M← '{⍺←⊢⋄⎕ML←1⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}'                     ⍝ merge[⍺] ⍵    (1- or 2-adic)
    _F← ' ⎕FMT '                                                 ⍝ ⎕FMT ⍵        (1- or 2-adic) 
    QS← ''' '∘,,∘' ''' ⋄ this1← '⎕THIS.' ⋄ this2←  '.',⍨ ⍕⎕THIS
    {_← ⍎ this1, ⍵, '←⍎_', ⍵ ⋄ ⍎ 'c', ⍵,' ←',(QS this2, ⍵),' _',⍵}¨ 'ABDMF'
  ∇
    Library 0

  ⍝ Constant char values
    esc← '`'   
    crCh crVis← ⎕UCS 13 9229                                     ⍝ crVis: Choose 8629 ↵ 9229 ␍
    sp lb rb q dmd← ' {}''⋄' 
    escEsc escLb escRb escDmd ← esc,¨ esc lb rb dmd  
    qq spQ qSp← (q q) (sp q) (q sp)  
    arrows← '▼▶'                                                 ⍝ See SelfDocCode
  ⍝ Const patterns 
    cfPats←  '\$\$' '\$' '%' '(?:`⍵|⍹)(\d*)' '(?:"[^"]*")+|(?:''[^'']*'')+'
    ⍝ splitPat matches recursively balanced braces {}, skipping quotes "..." ''...'' and escapes `.  
    splitPat← '(?x) (?<P> (?<!`) \{ ((?>  [^{}"''`]+ | (?:`.)+ | (?:"[^"]*")+ | (?:''[^'']*'')+ | (?&P)* )+)  \} )' 
 
⍝ "Options" Operator for ⎕R 
    _Opts← ⍠'EOL' 'LF' 

⍝ Functions
  ⍝ TextFld
    ⍝ ⍺: namespace of external (global) vars
    TextFld← { spQ, qSp,⍨ escDmd escEsc escLb escRb q ⎕R ⍺.cr esc lb rb qq _Opts ⍵ }
  ⍝ SpaceFld: A variant of a code field. 
    ⍝ A space field consists solely of 0 or more spaces (within the originally surrounding braces).
    ⍝ ⍺ SpaceFld ⍵ 
    ⍝    ∘ Returns (1 sfCod) if ⍵ is a space field.
    ⍝      sfCod is either '', if there are 0 spaces in ⍵, or (nn⍴''), if nn spaces (nn>0).
    ⍝    ∘ Returns 0 otherwise.
    ⍝ ⍺: namespace of external (global) vars
    SpaceFld← {  
        n← +/∧\' '= ⍵ ⋄ 0≠ ≢n↓ ⍵: 0   
        n= 0: 1 (⍺.dbg⊃ '' qq) ⋄ 1, ⊂'(','⍴'''')',⍨ ⍕n 
    }
  ⍝ SelfDocCode: Checks for document strings,
    ⍝   code field contents (inside braces) with a trailing ch ∊ '→%↓', possibly mixed with blanks.
    ⍝   Returns cStr dFun dStr  
    ⍝     cStr: code string removing appended ch∊ "↓%→" (orig. code string if not a doc str.)   
    ⍝     dFun: '' (if not a doc string); cAbove (if appended '↓' or '%'); cMerge ('→')
    ⍝     dStr: orig. literal doc string, but in quotes. Will be '' if NOT a document string..]
    ⍝ ⍺: namespace of external (global) vars
    SelfDocCode←{  
        ch← ⍵⌷⍨ p← (≢⍵)-1+ +/∧\' '= ⌽⍵ 
      ~'→↓%'∊⍨ ch: ⍵ '' ''  
        dStr← q, q,⍨ dStr/⍨ 1+q= dStr← (arrows⊃⍨ dTyp← ch='→')@p⊣ ⍵
        (p↑⍵) (dTyp ⍺.stndAlone⊃ cA cM) dStr  
    }
  ⍝ CodeFld:  
    ⍝ ⍺: namespace of external (global) vars
    CodeFld← { extern←⍺ 
        isSF sfCod← extern SpaceFld ⍵                         ⍝ Space field? 
      isSF: sfCod
        cStr dFun dStr ← extern SelfDocCode ⍵                 ⍝ Is CodeFld Self-documenting?  
        cStr← cfPats ⎕R {
            p← ⍵.PatternNum 
            p∊0 1 2: p extern.stndAlone⊃ cB cF cA                      ⍝ $$ $ % 
            p=4:  q, q,⍨ q escEsc escDmd ⎕R qq esc extern.cr _Opts⊢ 1↓¯1↓ ⍵.Match  ⍝ "..." or '...' 
              o← { 0=≢⍵: extern.omIx+1 ⋄ ⊃⌽⎕VFI ⍵ } ⍵.(Lengths[1]↑ Offsets[1]↓ Block)
            p=3: '(⍵⊃⍨⎕IO+', ')',⍨ ⍕extern.omIx← o            ⍝ `⍵[nnn] and ⍹[nnn] 
        }⊢ cStr  
        '({', dStr, dFun, cStr, '}⍵)'
    }
  ⍝ OrderFlds
    ⍝ ∘ User flds are effectively executed L-to-R and displayed in L-to-R order 
    ⍝   by reversing their order, evaluating R-to-L, then reversing again.
    ⍝ ∘ To select "older" style (execute fields R-to-L, display L-to-R): 
    ⍝   OrderFldsOld← ∊'⍬',⍨⊢ ⋄ OrderFlds← OrderFldsOld 
    OrderFlds← '⌽'∘,⍤ ∊'⍬'∘,⍤ ⌽
  ⍝ ProcFlds: Process each Code (or Space) and Text field. 
    ⍝ ⍺: namespace of external (global) vars
    ProcFlds← { 0=≢⍵: '' ⋄ lb=⊃⍵: ⍺ CodeFld 1↓¯1↓⍵ ⋄ ⍺ TextFld ⍵ }¨ 
  ⍝ SplitFlds: Split f-string into 0 or more fields, ignoring possible null fields generated.
    SplitFlds← splitPat ⎕R '\n\1\n' _Opts
  ⍝ ParseFString: The "main" function for ∆Fre...
    ParseFString← {  
        (dfn dbg box stndAlone) fStr← ⍺ ⍵ ⋄ omIx cr← 0 (dbg⊃ crCh crVis) ⍝ crCh: (⎕UCS 13), crVis: '␍' 
        extern← ⎕NS 'dbg' 'omIx' 'cr' 'stndAlone'                      ⍝ Only omIx is r/w
        flds← OrderFlds extern∘ProcFlds SplitFlds ⊂fStr 
        code← (⎕∘←)⍣dbg⊢ lb, (box extern.stndAlone⊃ cM cD), flds,  rb
      ~dfn: code, '⍵'                                              ⍝ Not a dfn. Emit code ready to execute
        quoted← '(⊂', ')',⍨ q, q,⍨ fStr/⍨ 1+ fStr= q               ⍝ dfn: add quoted fmt string.
        lb, code, quoted, ',⍵', rb                                 ⍝ emit dfn string ready to convert to dfn itself
    } 
    ∇ r← Help type ; h; t; hP   
      :IF 'help'≢⎕C 4↑type ⋄ ⎕SIGNAL ⊂'EN' 11,⍥⊂ 'Message' 'Invalid option(s)' ⋄ :EndIf 
      hP← ('^\s*⍝HX?'↓⍨ 'xX'(-∨/⍤∊) type), '(.*)' 
      r← 1 0⍴⍬⊣ ⎕ED ⍠'ReadOnly' 1⊢'h'⊣ h← hP ⎕S '\1'⊣ ⎕SRC ⎕THIS  
    ∇

⍝H 
⍝H -------------
⍝H  ∆F IN BRIEF
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H ∆F is a function that makes it easy to format strings that dynamically display text, variables, and 
⍝H (executed) code expressions in an APL-friendly multi-line (matrix) style. 
⍝H   ∘ Text expressions can generate multi-line Unicode strings 
⍝H   ∘ Each code expression is an ordinary dfn, with a few extensions:
⍝H          e.g. use of double-quoted strings, escape chars, and simple formatting shortcuts for APL arrays. 
⍝H   ∘ All variables and code are evaluated (and, if desired, updated) in the user's calling environment. 
⍝H   ∘ ∆F is inspired by Python F-strings, but designed for APL.
⍝H 
⍝H ∆F: Calling Information
⍝H ¯¯¯ ¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
⍝H Result←              ∆F f-string [arg1 arg2 ... ]   Format an ∆F String given args and simply display  
⍝H          [{options}] ∆F f-string [arg1 arg2 ... ]   Format an ∆F String given args; cnt'l result with opt'ns.
⍝H                    ⍬ ∆F ignored                     Do nothing, ignoring any args
⍝H                      ∆F⍨'help'                      Display help information
⍝H 
⍝H F-string and args:
⍝H   first element: 
⍝H       an f-string, a single character vector (see "∆F in Detail" below) 
⍝H   args:          
⍝H       elements of the right arg ⍵, each of which can be accessed,
⍝H       via shortcut starting with `⍵ or ⍹ (Table 1)
⍝H  
⍝H   Table 1:
⍝H       Escape (`) Shortcut   ⍹ Shortcut    Meaning
⍝H       ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯   ¯¯¯¯¯¯¯¯¯¯    ¯¯¯¯¯¯¯¯
⍝H      `⍵1, `⍵2              ⍹1, ⍹2        (⍵⊃⍨ ⎕IO+1), (⍵⊃⍨ ⎕IO+2)
⍝H      `⍵                    ⍹             the "next" arg*, starting with (⍵⊃⍨ ⎕IO+1)
⍝H      `⍵0                   ⍹0            the f-string itself, i.e. (⍵⊃⍨ ⎕IO)
⍝H  ---------------------------------
⍝H      [*] next, reading L-to-R across all code fields. `⍵N or ⍹N sets "next" to (⍵⊃⍨ ⎕IO+N+1)
⍝H 
⍝H Options:
⍝H    Options:     dfn dbg box
⍝H       dfn: If 0, returns a formatted matrix object based on the f-string (0⊃⍵) and any other "args" referred to.
⍝H            If 1, returns a dfn that, when executed, returned a formatted matrix object, as above.
⍝H       dbg: If 0, returns the value as above.
⍝H            If 1, displays the code generated based on the f-string, befure returning a value.
⍝H       box: If 0, returns the value as above.
⍝H            If 1, returns each field generated within a box (dfns "display"). 
⍝H stndAlone: If 0, references ⍙F library routines A, B, D, F, and M
⍝H            If 1, inserts the code of A, B, D, F, and M to make the resulting runtime code independent of the ⍙F namespace.
⍝H
⍝H Result Returned: 
⍝H   ∘ If (a) the left argument to ∆F (⍺) is omitted, or if ('Dfn' 1) or a number (1 or 0) specified, ...
⍝H     then if (b) the ∆F-string is evaluated successfully,
⍝H     ∘ For 'Dfn' 1 (default), ∆F returns the output after executing the code and formatting
⍝H       the code and text output, including any values from the environment or right argument.
⍝H       Normally, this is displayed as output to the terminal.
⍝H     ∘ For 'Dfn' 0, a function that, when executed with the same environment and arguments,
⍝H       generates identical output.
⍝H     Else (c) if an error occurs, 
⍝H     ∘ ∆F generates a standard, trappable Dyalog ⎕SIGNAL.
⍝H   ∘ Otherwise,
⍝H     (d) If ⍺ is ⍬, the result is a single 0-width line as output:  
⍝H        1 0⍴⍬.
⍝H     (e) If ⍺ is 'help', the result returned, after displaying help information, is: 
⍝H        ⍬
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
⍝H     newlines "`⋄", escape characters "``", braces "`{" or "`}". 
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
⍝H   Fmt               ::=   [ ("⎕FMT Control Expressions") "$" Code] 
⍝H   Above             ::=   ("(" Code<Generating any APL Object>")") "%" (Code<Generating Any APL Object)>
⍝H   Box               ::=   "$$" Code 
⍝H                           Box the result from executing code (uses ⎕SE.Dyalog.disp).
⍝H   Self_Documenting  ::=   (" ")* ("→" | "↓" | "%" ) (" ")*, where % is a synonym for ↓.
⍝H                           See examples.
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
⍝HX   ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝HX The temperature is 11°C or  51.8°F
⍝HX                    30       86.0  
⍝HX                    60      140.0 
⍝HX  
⍝HX ⍝ Using "boxes" via the $$ (box) pseudo-primitive
⍝HX   ∆F'`⋄The temperature is {$$⊂"I2" $ C}`⋄°C or {$$⊂"F5.1" $ F← 32+9×C÷5}`⋄°F'
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
⍝HX ⍝ Equivalent to:
⍝HX ∆F'{(⍳2⍴ (⍵⊃⍨1+⎕IO)) % (⍳2⍴ (⍵⊃⍨1+⎕IO)) % (⍳2⍴ (⍵⊃⍨3+⎕IO))}' 1 2 3 
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
⍝HX  ∆F t → 1.8E¯4 |   0% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
⍝HX  T ⍬  → 1.3E¯5 | -94% ⎕⎕⎕   
⍝HX
:EndNamespace 
