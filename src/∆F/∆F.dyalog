∆FⓇ← {∆FⓄ} ∆F ∆FⒻ; ⎕TRAP 
⍝ ∆F: Calling Information and Help Documentation is at the bottom of this function 
  ⎕TRAP← 0 'C' '⎕SIGNAL ⊂⎕DMX.(''EM'' ''EN'' ''Message'' ,⍥⊂¨(''∆F '',EM) EN Message)'
  :If 900⌶0                      ⍝ Options omitted. TProcessed below.
        ∆FⓄ← ⍬                  ⍝ We distinguish omitted left arg and ∆FⓄ≡⍬
  :ElseIf 0=≢∆FⓄ                ⍝ ∆FⓄ≡⍬:  
        ∆FⓇ← 1 0⍴⍬              ⍝   This is a quick exit where user wants to skip ∆F processing altogether.
        :Return 
  :Elseif 'help'≡4↑⎕C ∆FⓄ       ⍝ 'help' (show help info & examples) or 'helpx' (show help examples)
        ∆FⓇ← ('x'∊⎕C ∆FⓄ){ ⎕ML←1 ⋄ ⍬⊣⎕ED⍠ 'ReadOnly' 1⊢'help'⊣help←↑(⎕←'^\h*⍝HX',⍺↓'?(.*)') ⎕S '\1'⊢⎕NR ⊃⍵ } ⎕XSI 
        :Return  
  :EndIf 
  :If 0=⎕SE.⎕NC '⍙F.∆F4'
      :With '⍙F' ⎕SE.⎕NS ⍬
          ⍝ Load C F-string routines (two versions, for 2-byte chars and 4-byte chars)
          ⍝ At 16 (/32) bits, the <#C2 and >#C2 ⎕NA format allows strings up to humongous 64K (/2*32) bytes.
            '∆F4' ⎕NA 'I4 ∆F/∆F.dylib|fs_format4 <I1[5] C4 <#C4[] >#C4[] I4' 
            '∆F2' ⎕NA 'I4 ∆F/∆F.dylib|fs_format2 <I1[5] C4 <#C2[] >#C2[] I4'
          ⍝ Load the UCS-2 source code for the run-time library routines from ∆F.dylib: A, B, D, M
          ⍝ GetLib bufSize, where bufSize must be >170.
            ⍎GetLib 200⊣ 'GetLib' ⎕NA '∆F/∆F.dylib|get2lib >0C2' 
            ⎕EX 'GetLib'  ⍝ No longer needed
      :EndWith 
  :Endif  
  ∆FⓄ← ∆FⓄ {    
      ⎕IO ⎕ML ←0 1    
    ⍝ maxOutInit: Initial estimate of max # of (2- or 4-byte) chars needed in output. We keep it simple here.
    ⍝ maxTries: Max # of times to expand (double) maxOutInit, if not enough space for result.
    ⍝ growthFactor:   How much to increase buffer storage estimate, if not adequate
      maxOutInit maxTries growthFactor← (256⌈3×≢⍵) 5 4 

    ⍝ Options (⍺). 
      GetOpts← {  
        nK← ≢optK← 'Mode' 'Debug' 'Box' 'EscCh' 'UseNs' 'ExtLib' 
             optV←  1      0       0     '`'     0       1         ⍝ <== option default values 
        0=≢⍵: optV ⋄ (1=≢⍵)∧ 1≥ |≡⍵: ⍵, 1↓optV 
        0:: 'Invalid option(s)' ⎕SIGNAL 11
          newK newV← ↓⍉↑ ,⊂⍣(2= |≡⍵)⊢ ⍵ ⋄ 
          nK ∧.> p← optK⍳ newK: newV@p⊣ optV 
          11 ⎕SIGNAL⍨ 'Unknown option(s):',∊' ',¨ newK/⍨ p≥ nK
      }
      mode debug box escCh useNs extLib← GetOpts ⍺
      escCh← ⎕UCS⍣ (0=⊃0⍴escCh)⊢ escCh       ⍝ escCh may be a Unicode char or numeric code

      DNote← debug {⍺⍺=0: ⍵ ⋄ ⊢⎕←⍵} 
    ⍝ If the format string has 32-bit chars, use 32-bit mode; else, use 16-bit mode. See note at ⎕NA...
      Exec← (320= ⎕DR⊃⍵) ⎕SE.⍙F.{ 
        ⍺⍺: ∆F4 ⍵⍵, ⍵ ⍵ ⋄ ∆F2 ⍵⍵, ⍵ ⍵
      } (mode debug box useNs extLib) escCh (⊃⍵) 
      Call∆F←  { curMax← ⍵
        res2← Exec curMax                       ⍝ Execute with current storage estimate
      ¯1≠⊃res2: res2, curMax                    ⍝ Success. return result: rc, code_buffer  
      ⍺≤0: res2, curMax                         ⍝ If we've tried too many times, return as is.
         nextMax← growthFactor× curMax          ⍝ Increase the storage estimate and retry...
        (⍺-1) ∇ nextMax⊣ DNote 'Retrying ∆F with maxOut',nextMax,' Was',curMax   
      }  
    
    ⍝ rc: 0 (success), >0 (signal an APL error with the message specified), ¯1 (format buffer too small)
      rc res maxActual← maxTries Call∆F maxOutInit 
      
    0= rc:  (mode≠0),⍥⊂ DNote res
   ¯1≠ rc:  rc  ⎕SIGNAL⍨ (⎕EM rc),': ', res 
      Err911← {⌽911,⍥⊂'RUNTIME ERROR: Formatting buffer not big enough (buf size: ',(⍕⍵),' elements)'}
      ⎕SIGNAL/ Err911 maxActual        
  } ∆FⒻ← ,⊆∆FⒻ  
  
  :IF ⊃∆FⓄ                                                   ⍝ mode≠0: Generate a char vec. 
      ∆FⓇ← (⊃⌽∆FⓄ)((⊃⎕RSI){⍺⍺⍎ ⍺⊣ ⎕EX '∆FⒻ' '∆FⓄ'})∆FⒻ    ⍝ NB: String ⍺ references ⍵ (∆FⒻ)
  :Else      
      ∆FⓇ← (⊃⎕RSI)⍎ ⊃⌽∆FⓄ                                   ⍝ mode=0: Generate a dfn.
  :EndIf 

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
⍝H ¯¯  ¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
⍝H Result←           ∆F f-string [arg1 arg2 ... ]   Format an ∆F String given args and simply display  
⍝H       [{options}] ∆F f-string [arg1 arg2 ... ]   Format an ∆F String given args; cnt'l result with opt'ns.
⍝H                 ⍬ ∆F ignored                     Do nothing, ignoring any args
⍝H            'help' ∆F ignored                     Display help information
⍝H           'helpx' ∆F ignored                     Display help examples only
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
⍝H       Mode: 1* (std mode); 0 (code mode), ¯1 (list mode), ¯2 (table mode)
⍝H          1   std    format and return the object generated as is.
⍝H          0   code   create a dfn to format and generate an object later; useful when
⍝H                     the function is going to be called repeatedly on different data.
⍝H         ¯1   list   format and return the object generated, boxing each field of the object 
⍝H                     separately left-to-right, using dfn ¨disp¨. Equiv. to ('Mode' 1)('Box' 1).
⍝H         ¯2   table  format and return the object generated, boxing each field of the object 
⍝H                     separately in a "table", one field above the other (via ⍪).
⍝H       Debug: If 1*, carriage returns entered via "`⋄" are replaced by a visible symbol "␍".
⍝H                     Space field spaces are shown via "␠" and null (empty) space fields via a single "␀".
⍝H                         'Debug' N                    'Debug' 0    'Debug' 1
⍝H                         CR via "`⋄"                   (⎕UCS 13)       ␍
⍝H                         spaces in space fields { }       ' '           ␠
⍝H                         a null space field {}           omitted        ␀           
⍝H                     In addition, the intended executable is displayed before execution.
⍝H       Box:   If 0*, display all fields as is.
⍝H              If 1,  display each non-simple field* of the result in a box.
⍝H                     * Null (0-width) space fields are omitted from the Box display unless Debug is 1.
⍝H              Using $$ (BELOW), you can box an individual code field (but not a text or space field).  
⍝H              ('Box' 1) can be used with code mode ('Mode' 0) to create such a box on each function call.
⍝H       EscCh  A single "escape" character or its Unicode equivalent. See "escape characters" below.
⍝H              Defaults to '`' (or, equivalently, 96).  
⍝H              Best NEVER to use a quote or brace as the escape character.
⍝H       UseNs:
⍝H          ∘ If 1, a single common anonymous namespace will be passed to every code field as ⍺.
⍝H          ∘ Since code fields are evaluated R-to-L, the first code field to see and use the namespace
⍝H            will be the rightmost one:
⍝H                ('UseNs' 1) ∆F 'π²={⍺.Pi*2}, π={⍺.Pi←○1}'   ⍝ Silly example!
⍝H            π²=9.869604401, π=3.141592654
⍝H          ∘ Allows shared state across code fields without cluttering the calling namespace.
⍝H          ∘ If ('UseNs' 0) is applied, then ⍺ seen by each code field is undefined (you can set via ⍺←...).
⍝H       ExtLib: 
⍝H          ∘ If 1(*), we load and use a namespace (library) ⎕SE.⍙F to hold key run-time utilities (A, B, D, M)
⍝H            referenced in the code generated by ∆F. Generates a more compact code string than for ('ExtLib' 0).
⍝H          ∘ If 0, the utilities are included "stand alone" in the code created by the associated 
⍝H            C routine called here.  In particular, a dfn ('Mode' 0) generated by ∆F will require
⍝H            no external run-time library at all (namespace ⎕SE.⍙F may be absent). 
⍝H       * shows default option values.
⍝H 
⍝H For help (this information) 
⍝H         ∆F⍨'help'  
⍝H        'help' ∆F 'anything'    ⍝ Right arg ignored, when ⍺ is 'help'
⍝H
⍝H Result Returned: 
⍝H   ∘ If the left argument to ∆F (⍺) is omitted ('Mode' 1) or a mode is specified, then...
⍝H     If the ∆F-string is evaluated successfully,
⍝H     ∘ For modes 1 (default), ¯1, and ¯2, returns the output after executing the code and formatting
⍝H       the code and text output, including any values from the environment or right argument.
⍝H       Normally, this is displayed as output to the terminal.
⍝H     ∘ For mode 0, a function that, when executed with the same environment and arguments,
⍝H       generates identical output.
⍝H     Else if an error occurs, 
⍝H     ∘ ∆F generates a standard, trappable Dyalog ⎕SIGNAL.
⍝H   ∘ Otherwise,
⍝H     If ⍺ is ⍬, the result is a single 0-width line as output:  
⍝H        1 0⍴⍬.
⍝H     If ⍺ is 'help', the result returned, after displaying help information, is: 
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
⍝H     Use option ('EscCh' char) or ('EscCh' code_point) to define an escape char besides "`".
⍝H       code_point: the equivalent numeric code for an APL character: for <ch>, ⎕UCS <ch>.
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
⍝HX ⍝ Like the example above, in a more traditional APL style
⍝HX   ∆F '{↑"This" "is"} {↑"a"  "more"} {↑"trad''l" "example"}'
⍝HX This a    trad'l 
⍝HX is   more example
⍝HX     
⍝HX ⍝ A slightly more interesting code expression
⍝HX   C← 11 30 60
⍝HX   ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝HX The temperature is 11°C or  51.8°F
⍝HX                    30       86.0  
⍝HX                    60      140.0 
⍝HX 
⍝HX ⍝ One way to create column separators...  
⍝HX   C← 11 30 60
⍝HX   S←⍪'│'⍴⍨ ≢C
⍝HX   ∆F'The temperature is {S}{"I2" $ C}°C{S} or {S}{"F5.1" $ F← 32+9×C÷5}°F{S}'
⍝HX The temperature is │11°C│ or │ 51.8°F│
⍝HX                    │30  │    │ 86.0  │
⍝HX                    │60  │    │140.0  │
⍝HX  
⍝HX ⍝ Using "boxes" via the $$ (box) pseudo-primitive
⍝HX   ∆F'`⋄The temperature is {$$⊂"I2" $ C}`⋄°C or {$$⊂"F5.1" $ F← 32+9×C÷5}`⋄°'
⍝HX                    ┌──┐      ┌─────┐
⍝HX The temperature is │11│°C or │ 51.8│°
⍝HX                    │30│      │ 86.0│ 
⍝HX                    │60│      │140.0│ 
⍝HX                    └──┘      └─────┘                
⍝HX ⍝ Using an outside expression
⍝HX   C← 11 30 60
⍝HX   C2F← 32+9×5÷⍨⊢
⍝HX   ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ C2F C}°F'
⍝HX The temperature is 11°C or  51.8°F
⍝HX                    30       86.0  
⍝HX                    60      140.0 
⍝HX 
⍝HX ⍝ Using ∆F additional arguments (`⍵1 ==> (1⊃⍵), given ⎕IO←0)
⍝HX   ∆F'The temperature is {"I2" $ `⍵1}°C or {"F5.1" $ C2F `⍵1}°F' (11 15 20)
⍝HX The temperature is 11°C or  51.8°F
⍝HX                    15       59.0  
⍝HX                    20       68.0 
⍝HX 
⍝HX ⍝ Use argument `⍵1 (1⊃⍵) in a calculation.  (Likewise:  ('UseNs' 1) ∆F 'π²={⍺.Pi*2} π={⍺.Pi←○1}') 
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
⍝HX
⍝HX ⍝ Use of ¯1 option, i.e. ('Mode' ¯1) [LIST MODE]: shows and demarcates each field (boxed) left to right.
⍝HX   C← 11 30 60
⍝HX   ¯1 ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝HX ┌───────────────────┬──┬──────┬─────┬──┐
⍝HX │                   │11│      │ 51.8│  │
⍝HX │The temperature is │30│°C or │ 86.0│°F│
⍝HX │                   │60│      │140.0│  │
⍝HX └───────────────────┴──┴──────┴─────┴──┘
⍝HX
⍝HX ⍝ Use of ¯2 option or ('Mode' ¯2) [TABLE MODE]: shows and demarcates each field (boxed) in tabular form.
⍝HX   C← 11 30 60
⍝HX   ¯2 ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝HX ┌───────────────────┐
⍝HX │The temperature is │
⍝HX ├───────────────────┤
⍝HX │         11        │
⍝HX │         30        │
⍝HX │         60        │
⍝HX ├───────────────────┤
⍝HX │      °C or        │
⍝HX ├───────────────────┤
⍝HX │        51.8       │
⍝HX │        86.0       │
⍝HX │       140.0       │
⍝HX ├───────────────────┤
⍝HX │        °F         │
⍝HX └───────────────────┘
⍝HX
⍝HX ⍝ Performance of an ∆F-string evaluated on the fly via (1 ∆F ...) and precomputed via (0 ∆F ...): 
⍝HX   C← 11 30 60
⍝HX ⍝ Here's our ∆F String <t>
⍝HX   t←'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝HX ⍝ Precompute a dfn T given ∆F String <t>.
⍝HX   T←0 ∆F t
⍝HX ⍝ Compare the performance of the two formats: the precomputed version is over 4 times faster here.
⍝HX   cmpx '∆F t' 'T ⍬'
⍝HX ∆F t → 4.7E¯5 |   0% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
⍝HX T ⍬  → 1.1E¯5 | -77% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕ 
⍝HX


