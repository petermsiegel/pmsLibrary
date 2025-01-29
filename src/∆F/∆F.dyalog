∆FⓇ← {∆FⓄ} ∆F ∆FⒻ; ⎕TRAP 
⍝ ∆F: Calling Information and Help Documentation is at the bottom of this function 
  ⎕TRAP← 0 'C' '⎕SIGNAL ⊂⎕DMX.(''EM'' ''EN'' ''Message'' ,⍥⊂¨(''∆F '',EM) EN Message)'
  :If 900⌶0                      ⍝ Options omitted. Processed below.
        ∆FⓄ← ⍬
  :ElseIf 0=≢∆FⓄ               ⍝ Quick exit if user specifies: ⍬ ∆F <anything>
        ∆FⓇ← 1 0⍴⍬ 
        :Return 
  :Elseif 'help'≡⎕C ∆FⓄ        ⍝ Help and exit...
        ∆FⓇ← { ⎕ML←1 ⋄ ⍬⊣⎕ED⍠ 'ReadOnly' 1⊢'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⍵ } ⎕XSI 
        :Return  
  :EndIf 
  :If 0=⎕SE.⎕NC '⍙F.∆F4'
      :With '⍙F' ⎕SE.⎕NS ⍬
          ⍝ Load C F-string routines (two versions, for 4-byte chars and 2-byte chars)
          ⍝ At 16 bits, the <#C2 and >#C2 ⎕NA format allows strings up to 64K bytes.
            '∆F4' ⎕NA 'I4 ∆F/∆F.dylib|fs_format4 <I1[5] C4 <#C4[] >#C4[] I4' 
            '∆F2' ⎕NA 'I4 ∆F/∆F.dylib|fs_format2 <I1[5] C4 <#C2[] >#C2[] I4'
          ⍝ Load the source code for the run-time library routines: A, B, D, M
          ⍝ GetLib bufSize, where bufSize must be at least 170.
            ⍎GetLib 200⊣ 'GetLib' ⎕NA '∆F/∆F.dylib|get2lib >0C2' 
      :EndWith 
  :Endif  
  ∆FⓄ← ∆FⓄ {    
      ⎕IO ⎕ML ←0 1    
    ⍝ maxOut0: Initial estimate of max # of (2- or 4-byte) chars needed in output. We keep it simple here.
    ⍝ maxTries: Max # of times to expand (double) maxOut0, if not enough space for result.
      maxOut0 maxTries← 256 5 

    ⍝ Options (⍺)
      GetOpts← {  
          optK← 'Mode' 'Debug' 'Box' 'EscCh' 'UseNs' 'ExtLib' 
          optV←  1      0       0     '`'     0       1         ⍝ <== option default values 
        0=≢⍵: optV ⋄ (1=≢⍵)∧ 1≥ |≡⍵: ⍵, 1↓optV 
        0:: 'Invalid option(s)' ⎕SIGNAL 11
          nK nV← ↓⍉↑ ,⊂⍣(2= |≡⍵)⊢ ⍵ 
          p← optK⍳ nK 
        p∧.< ≢optK: nV@p⊣ optV 
          11 ⎕SIGNAL⍨ 'Unknown option(s):',∊' ',¨ nK/⍨ p≥≢optK 
      }
      mode debug box escCh useNs extLib← GetOpts ⍺
      escCh← ⎕UCS⍣ (0=⊃0⍴escCh)⊢ escCh       ⍝ Allow escCh as a Unicode numeric code

      DebugNote← {debug=0: ⍵ ⋄ ⊢⎕←⍵} 
      ⍝ If the format string has 32-bit chars, use 32-bit mode; else, use 16-bit mode. See note at ⎕NA...
      Exec← (320= ⎕DR⊃⍵) ⎕SE.⍙F.{ ⍺⍺: ∆F4 ⍵⍵, ⍵ ⍵ ⋄ ∆F2 ⍵⍵, ⍵ ⍵} (mode debug box useNs extLib) escCh (⊃⍵) 
      Call∆F←  { max← ⍵
        res← Exec max     
        ¯1≠⊃res: res max ⋄ ⍺≤0: res max ⋄ max2← 2×max
        (⍺-1) ∇ max2⊣ DebugNote 'Retrying ∆F with maxOut',max2,' Was',max   
      }  
    
    ⍝ rc: 0 (success), >0 (signal an APL error with the message specified), ¯1 (format buffer too small)
      (rc res) maxOut← maxTries Call∆F maxOut0 
      
    0= rc:  (mode≠0) (DebugNote res)
   ¯1≠ rc:  rc  ⎕SIGNAL⍨ (⎕EM rc),': ', res 
      Err911← {⌽911,⍥⊂'RUNTIME ERROR: Formatting buffer not big enough (buf size: ',(⍕⍵),' elements)'}
      ⎕SIGNAL/ Err911 maxOut        
  } ∆FⒻ← ,⊆∆FⒻ  
  
  :IF ⊃∆FⓄ                                                  ⍝ mode≠0
      ∆FⓇ← (⊃⌽∆FⓄ)((⊃⎕RSI){⍺⍺⍎ ⍺⊣ ⎕EX '∆FⒻ' '∆FⓄ'})∆FⒻ    ⍝ Generate a char vec
  :Else      
      ∆FⓇ← (⊃⎕RSI)⍎ ⊃⌽∆FⓄ                                   ⍝ Generate a dfn
  :EndIf 

⍝H -------------
⍝H  ∆F IN BRIEF
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H ∆F is a function that makes it easy to format strings that dynamically display text, variables, and 
⍝H (executed) code expressions in an APL-friendly multi-line (matrix) style. 
⍝H   ∘ Text expressions can generate multi-line Unicode strings 
⍝H   ∘ Each code expression is an ordinary dfn, with a few extensions (like double-quoted strings 
⍝H     and some simple formatting shortcuts for APL arrays). 
⍝H   ∘ All variables and code are evaluated (and possibly updated) in the user's calling environment. 
⍝H   ∘ ∆F is inspired by Python F-strings, but designed for APL.
⍝H 
⍝H ∆F: Calling Information
⍝H ¯¯  ¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
⍝H Result← [{options}] ∆F f-string [arg1 arg2 ... ]    Format an ∆F String with args (if any)
⍝H                 ⍬ ∆F ignored                        Do nothing, ignoring any args
⍝H            'help' ∆F ignored                        Display help information
⍝H 
⍝H F-string and args:
⍝H       first element: an f-string, a single character vector (see "∆F in Detail" below) 
⍝H       args:          (optional) elements, each of which can be accessed via 
⍝H                      `⍵1 (i.e. 1⊃⍵), `⍵2 (2⊃⍵), etc. 
⍝H                      `⍵ is the "next" argument. 
⍝H                      `⍵0 is the f-string itself.
⍝H        
⍝H Options:
⍝H    Options:     ( numeric | keyword )
⍝H      numeric:   
⍝H        ( 1* | 0 | ¯1 | ¯2 ) 
⍝H      keyword:   
⍝H        ('Mode' [1*|0|¯1|¯2])  ('Debug' [1|0*])  ('Box' [1|0*])   
⍝H        ('UseNs' [1|0*])       ('ExtLib' [1*|0]) ('Force' [1|0*])
⍝H        ('EscCh' '`'*|'char') 
⍝H    The default, if no options are presented, is: ('Mode' 1).           <== Use this in production!!!
⍝H    The default, if a single integer n is presented, is: ('Mode' n)       
⍝H    * An asterisk indicates the default for each option.
⍝H 
⍝H    Options:
⍝H       Mode: 1* ("std"); 0 ("code"), ¯1 ("list"), ¯2 ("table")
⍝H           std:   format and return the object generated as is.
⍝H           code:  create a dfn to format and generate an object later; useful when
⍝H                  the function is going to be called repeatedly on different data.
⍝H           list:  format and return the object generated, boxing each field of the object 
⍝H                  separately left-to-right, using dfn ¨disp¨.
⍝H           table: format and return the object generated, boxing each field of the object 
⍝H                  separately in a "table", one field above the other, using dfns ¨disp¨.
⍝H       Debug: If 1*, carriage returns (via '`⋄' or directly) are replaced by a visible rep: ␍
⍝H                In addition, the intended executable is displayed before execution.
⍝H       Box:   If 0*, display all fields as is.
⍝H              If 1,  display each field* of the result in a simple box.
⍝H                     * Null (0-width) space fields are omitted from the Box display.
⍝H              Using $$ (BELOW), you can box an individual code field (but not a text or space field).  
⍝H       EscCh  A single "escape" character or its Unicode equivalent. See "escape characters" below.
⍝H              Defaults to '`' (or, equivalently, 96).  
⍝H              Best NEVER to use a quote or brace as the escape character.
⍝H       UseNs:
⍝H          ∘ If 1, a common anonymous namespace will be passed to every code field as ⍺.
⍝H          ∘ Since code fields are executed R-to-L, the first one to see the namespace
⍝H            will be the rightmost one.
⍝H          ∘ Allows shared state across code fields without cluttering the calling namespace.
⍝H          ∘ If ('UseNs' 0), ⍺ is undefined.
⍝H       ExtLib: 
⍝H          ∘ If 1(*), we use a namespace (library) ⎕SE.⍙F to hold key run-time utilities (A, B, D, M)
⍝H            referenced in the code generated by ∆F. Generates a more compact code string than for ('ExtLib' 0).
⍝H          ∘ If 0, the utilities are included "stand alone" in the code created by the associated 
⍝H            C routine called here.  In particular, a dfn ('Mode' 0) generated by ∆F will require
⍝H            no external run-time library (namespace ⎕SE.⍙F may be absent). 
⍝H 
⍝H For help (this information) 
⍝H         ∆F⍨'help'      ⍝ Same as   'help ∆F 'anything'   ⍝ Right arg ignored, when ⍺ is 'help'
⍝H
⍝H Result: 
⍝H   ∘ If the left argument to ∆F (⍺) is omitted ('Mode' 1) or a mode is specified,
⍝H     If the ∆F-string is evaluated successfully,
⍝H     ∘ For modes 1 (default), ¯1, and ¯2, returns the output after executing the code and formatting
⍝H       the code and text output, including any values from the environment or right argument.
⍝H       Normally, this is displayed as output to the terminal.
⍝H     ∘ For mode 0, a function that, when executed with the same environment and arguments,
⍝H       generates identical output.
⍝H     If an error occurs, 
⍝H     ∘ ∆F generates a standard, trappable Dyalog ⎕SIGNAL.
⍝H   Otherwise,
⍝H   ∘ If ⍺ is ⍬, generates a single 0-width line as output:  1 0⍴⍬.
⍝H   ∘ If ⍺ is 'help', returns a result of ⍬, after displaying help information.
⍝H 
⍝H 
⍝H --------------
⍝H  ∆F IN DETAIL
⍝H --------------
⍝H 
⍝H The first argument to ∆F is a character vector (or scalar), an "∆F string", which contains simple text, 
⍝H along with run-time evaluated expressions delimited by curly braces {}. Each ∆F string is viewed
⍝H as containing one or more "fields," catenated left to right (without assumed spaces),
⍝H each of which will display as a logically separate character matrix. 
⍝H 
⍝H ∆F-string text fields (expressions) may include:
⍝H   ∘ escape characters (e.g. representing newlines,escape characters and braces as text).
⍝H ∆F-string code fields (expressions) may include: 
⍝H   ∘ escape characters (e.g. representing newlines,escape characters and braces as text);
⍝H   ∘ dyadic ⎕FMT control codes for concisely formatting integers, floats, and the like into tables;
⍝H   ∘ the ability to display arbitrary objects, one above another;
⍝H   ∘ shortcuts for displaying boxed output; finally,
⍝H   ∘ self-documenting code fields are concise expressions for displaying both a code 
⍝H     expression (possible a simple name to be evaluated) and its value.   
⍝H     (Only code fields may be self-documenting!).
⍝H ∆F-strings include space fields:
⍝H   ∘ which separate other fields with rectangular elements that are 0 or more spaces wide. 
⍝H 
⍝H The syntax of ∆F Strings is as follows, where ` represents the escape character:
⍝H   ∆F_String         ::=  (Text_Field | Code_Field | Space_Field)*
⍝H   Text_Field        ::=  (literal_char | "`⋄" | "``" | "`{" | "`}" )
⍝H   Code_Field        ::=  "{" (Fmt | Above | Box | Code )+ (Self_Documenting) "}"
⍝H   Space_Field       ::=  "{"  <0 or more spaces> "}"
⍝H 
⍝H   Code              ::=   A Dyalog dfn, each passed the arguments to ∆F as ⍵: 
⍝H                           `⍵ (or ⍹) selects the next object in ⍵ (starting with (1⊃⍵), ⎕IO←0); 
⍝H                           `⍵N (or ⍹N) selects the Nth object in ⍵ (⎕IO←0), where N is 1-3 digits;
⍝H                           `⍵0 (or ⍹0) selects the text of the ∆F_String itself;
⍝H                           quoted strings: "..." or ''...'', where ... may include 
⍝H                                    `⋄ to represent a newline, 
⍝H                                    `` to represent the escape char itself.
⍝H   Fmt               ::=   [ ("⎕FMT Control Expressions") "$" Code] 
⍝H   Above              ::=  (Code<Generating any APL Object>) "%" (Code<Generating Any APL Object)>
⍝H   Box               ::=   "$$" Code 
⍝H   Self_Documenting  ::=   (" ")* ("→" | "↓" | "%" ) (" ")*, where % is a synonym for ↓.
⍝H 
⍝H Examples:
⍝H ⍝ Simple variable expression
⍝H     name← 'Fred'
⍝H     ∆F "His name is {name}."
⍝H     His name is Fred.
⍝H 
⍝H ⍝ Some multi-line text fields separated by non-null space fields
⍝H     ∆F 'This`⋄is`⋄an`⋄example{ }Of`⋄multi-line{ }Text`⋄Fields'
⍝H This    Of         Text  
⍝H is      multi-line Fields
⍝H an                       
⍝H example 
⍝H 
⍝H ⍝ A similar example with strings in code fields
⍝H       ∆F '{"This`⋄is`⋄an`⋄example"} {"Of`⋄Multi-line"} {"Strings`⋄in`⋄Code`⋄Fields"}'
⍝H This    Of         Strings
⍝H is      Multi-line in     
⍝H an                 Code   
⍝H example            Fields 
⍝H   
⍝H ⍝ Like the example above, in a more traditional APL stype
⍝H      ∆F '{↑"This" "is"} { ↑"a"  "more"} {↑"trad''l" "example"}'
⍝H This a    trad'l 
⍝H is   more example
⍝H     
⍝H ⍝ A slightly more interesting code expression
⍝H     C← 10 30 60
⍝H     ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝H The temperature is 10°C or  50.0°F
⍝H                    30       86.0  
⍝H                    60      140.0 
⍝H                     
⍝H ⍝ Using an outside expression
⍝H     C← 10 30 60
⍝H     C2F← { 32+9×⍵÷5}
⍝H     ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ C2F C}°F'
⍝H The temperature is 10°C or  50.0°F
⍝H                    30       86.0  
⍝H                    60      140.0 
⍝H 
⍝H ⍝ Using ∆F additional arguments (`⍵1 ==> (1⊃⍵), given ⎕IO←0)
⍝H     ∆F'The temperature is {"I2" $ `⍵1}°C or {"F5.1" $ C2F `⍵1}°F' (10 15 20)
⍝H The temperature is 10°C or  50.0°F
⍝H                    15       59.0  
⍝H                    20       68.0 
⍝H 
⍝H ⍝ "Horizontal" self-documenting code fields (each field to the left of the next).
⍝H     name←'John Smith' ⋄ age← 34
⍝H     ∆F 'Current employee: {name→} {age→}.'
⍝H Current employee: name▶John Smith age▶34.
⍝H
⍝H ⍝ Note that spaces next to self-documenting codes (→ or ↓) are honoured in the output:
⍝H     ∆F 'Current employee: {name → } {age → }.'
⍝H Current employee: name ▶ John Smith age ▶ 34.
⍝H 
⍝H ⍝ "Vertical" self-documenting code fields (one centered over the other)
⍝H     ∆F 'Current employee: {name↓} {age↓}.'
⍝H Current employee:   name▼    age▼.
⍝H                   John Smith  34 
⍝H 
⍝H ⍝ Displaying one expression above another 
⍝H      ∆F '{"Current Employee" % ⍪`⍵1} {"Current Age" % ⍪`⍵2}' ('John Smith' 'Mary Jones')(29 23)
⍝H Current Employee Current Age
⍝H    John Smith        29     
⍝H    Mary Jones        23 
⍝H 
⍝H ⍝ Display more complex expressions one above the other.
⍝H ⍝ Here we use `⍵, which selects the "next" item from ⍵, moving left to right, starting with (1⊃⍵).
⍝H ⍝ I.e. in the code below, we have select (⍳2⍴1⊃⍵), then (⍳2⍴2⊃⍵), then (⍳2⍴3⊃⍵).
⍝H ⍝ We don't select (0⊃⍵) as the initial (`⍵), since that is the ∆F-String itself. 
⍝H       ∆F'{(⍳2⍴`⍵) % (⍳2⍴`⍵) % (⍳2⍴`⍵)}' 1 2 3 
⍝H     0 0      
⍝H   0 0  0 1    
⍝H   1 0  1 1    
⍝H 0 0  0 1  0 2 
⍝H 1 0  1 1  1 2 
⍝H 2 0  2 1  2 2 
⍝H
⍝H ⍝ Use of ¯1 or ('Mode' ¯1) option: shows and demarcates each field (boxed) left to right.
⍝H      ¯1 ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝H ┌───────────────────┬──┬──────┬─────┬──┐
⍝H │                   │10│      │ 50.0│  │
⍝H │The temperature is │30│°C or │ 86.0│°F│
⍝H │                   │60│      │140.0│  │
⍝H └───────────────────┴──┴──────┴─────┴──┘
⍝H
⍝H ⍝ Use of ¯2 or ('Mode' ¯2) option: shows and demarcates each field (boxed) in tabular form.
⍝H      ¯2 ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝H ┌───────────────────┐
⍝H │The temperature is │
⍝H ├───────────────────┤
⍝H │         10        │
⍝H │         30        │
⍝H │         60        │
⍝H ├───────────────────┤
⍝H │      °C or        │
⍝H ├───────────────────┤
⍝H │        50.0       │
⍝H │        86.0       │
⍝H │       140.0       │
⍝H ├───────────────────┤
⍝H │        °F         │
⍝H └───────────────────┘
⍝H
⍝H ⍝ Performance of an ∆F-string evaluated on the fly via (1 ∆F ...) and precomputed via (0 ∆F ...): 
⍝H   ⍝ Here's our ∆F String <t>
⍝H     t←'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝H   ⍝ Precompute a dfn T for ∆F String <t>.
⍝H     T←0 ∆F t
⍝H   ⍝ Compare the performance of the two formats: the precomputed version is over 4 times faster here.
⍝H     cmpx '∆F t' 'T ⍬'
⍝H  ∆F t → 4.7E¯5 |   0% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
⍝H  T ⍬  → 1.1E¯5 | -77% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕ 
⍝H


