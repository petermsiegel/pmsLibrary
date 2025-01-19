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
      :With ⎕SE 
        :If 0=⎕NC '⍙F' 
            '⍙F' ⎕NS⍬
        :Endif 
        '∆F4' ⍙F.⎕NA 'I4 ∆F.dylib|fs_format4 <I1[4] C4 <C4[] I4  >C4[]   =I4' 
        '∆F2' ⍙F.⎕NA 'I4 ∆F.dylib|fs_format2 <I1[4] C4 <C2[] I4  >C2[]   =I4' 
      :EndWith 
  :Endif  
  ∆FⓄ← ∆FⓄ {    
      ⎕IO ⎕ML ←0 1    
    ⍝ MAXOUT_INIT: Initial estimate of max # of (2- or 4-byte) chars needed in output. We keep it simple here.
    ⍝ MAXTRY: Max # to expand (double) MAXOUT_INIT, if not enough space for result.
      MAXOUT_INIT MAXTRY← 256 5 
      mode debug  escCh  useNs extLib force← {  
        ⍝       mode   debug   escCh   useNs   extLib   force   ⍝ <== option variables 
        ⍝      'Mode' 'Debug' 'EscCh' 'UseNs' 'ExtLib' 'Force'  ⍝ <== option names
          optV← 1      0       '`'     0       1        0       ⍝ <== option default values 
        0=≢⍵: optV 
        (1=≢⍵)∧ 1≥ |≡⍵: ⍵, 1↓optV 
        0:: 'Invalid option(s)' ⎕SIGNAL 11
          optN← 'Mode' 'Debug' 'EscCh' 'UseNs' 'ExtLib' 'Force'
          p← optN⍳ ⊃¨ new← ⊂⍣(2= |≡⍵)⊢ ⍵
        p∧.< ≢optN: optV⊣ optV[p]← ⊃∘⌽¨ new
          'Unknown option(s)' ⎕SIGNAL 11
      } ⍺
      badEscE← 'DOMAIN ERROR: escape char not unicode scalar!' 11
    ×80| ⎕DR escCh: ⎕SIGNAL/ badEscE
    1≠ ≢escCh:      ⎕SIGNAL/ badEscE

    ⍝ LoadLib: extLib force LoadLib lib: 
    ⍝    If extLib is set, then 
    ⍝       a) if utilities aren't defined in ⎕SE.<lib>, define them;
    ⍝       b) if force, define them anyway;
    ⍝    Otherwise,
    ⍝       Return ⍬
      LoadLib← extLib force {
        ~⊃⍺⍺: ⍬                            ⍝ Skip if ~extLib
        (9=⍵.⎕NC 'M')∧ ~⊃⌽⍺⍺: ⍬            ⍝ Skip if ⎕SE.<lib> contains (at least) M, unless force=1.  
          lib← ⍵ 
        ⍝ Merge all the elements to the right (usually all the defined fields), 
        ⍝ adjusting for height, without adding blank columns.
          lib.M← {⎕ML←1 ⋄⍺←⊢⋄ ⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}
        ⍝ (%) Center field ⍺ above field ⍵. If ⍺ is omitted, a single-line field is assumed.
          lib.A← {⎕ML←1 ⋄⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}
        ⍝ ($) Box item ⍵ 
          lib.B← {⎕ML←1⋄1∘⎕SE.Dyalog.Utils.disp ,⍣(⊃0=⍴⍴⍵)⊢⍵}
        ⍝ (Modes ¯1 and ¯2) Displaying the entire formatted result
          lib.D← ⎕SE.Dyalog.Utils.disp
          ⍬
      }              
      DOut← {debug=1: ⊢⎕←⍵ ⋄ ⍵}

      fStr←  ⊃⍵                                 
      _← LoadLib ⎕SE.⍙F 
    ⍝ Call the C Library (with retry if buffers aren't big enough)
    ⍝ We call the 2-byte version if fStr has 2- or 1-byte characters.
      Call∆F← (mode debug useNs extLib) escCh fStr (≢fStr) {  
        _← ⍵⍵ ⎕SE.⍙F.{ ⍺: ∆F4 ⍵ ⋄ ∆F2 ⍵ }⍺⍺, ⍵ ⍵  
        (⍺≤0) ∨ ¯1≠⊃_: _ ⍵ 
        _← DOut 'Retrying ∆F with maxOut',(2×⍵),' Was',⍵  
        (⍺-1) ∇ 2×⍵ 
      } (320= ⎕DR fStr) 
      (rc res lenRes) maxOut← MAXTRY Call∆F MAXOUT_INIT 
    ⍝ rc: 0 (success), >0 (signal an APL error with the message specified), ¯1 (format buffer too small)
    0= rc:  (mode≠0) (DOut lenRes↑ res)
   ¯1≠ rc:  rc  ⎕SIGNAL⍨ (⎕EM rc),': ', lenRes↑res 
      Err911← {⌽911,⍥⊂'DOMAIN ERROR: Formatting buffer not big enough (buf size: ',(⍕⍵),' elements)'}
      ⎕SIGNAL/ Err911 maxOut        
  } ∆FⒻ← ,⊆∆FⒻ  
  
  :IF ⊃∆FⓄ                                                  ⍝ mode≠0
      ∆FⓇ← (⊃⌽∆FⓄ){(⊃⎕RSI)⍎ ⍺⊣ ⎕EX '∆FⒻ' '∆FⓄ'}∆FⒻ          ⍝ Generate a char vec
  :Else      
      ∆FⓇ← (⊃⎕RSI)⍎ ⊃⌽∆FⓄ                                   ⍝ Generate a dfn
  :EndIf 

⍝H -------------
⍝H  ∆F IN BRIEF
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H ∆F is a function that uses simple input string expressions, f-strings, to dynamically build 
⍝H 2-dimensional output from variables and dfn-style code, shortcuts for numerical formatting, 
⍝H titles, and Main. To support an idiomatic APL style, ∆F uses the concept of fields to organize the
⍝H display of vector and multidimensional objects using building blocks like ⎕FMT that already exist
⍝H in the Dyalog implementation. (∆F is reminiscent of f-string support in Python, but in an APL style.
⍝H 
⍝H ∆F: Calling Information
⍝H ¯¯  ¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
⍝H ∆FⓇ← {∆FⓄ} ∆F ∆FⒻ
⍝H   ∆FⓄ- options    
⍝H   ∆FⒻ- f-string and args 
⍝H   ∆FⓇ- return value (string or dfn) 
⍝H 
⍝H ∆FⒻ:  f-string and args
⍝H        first element: an f-string (see documentation) [required].
⍝H        args:         each element of <args> can be accessed via `⍵1, `⍵2, etc. `⍵0 is the f-string itself.
⍝H        
⍝H ∆FⓄ:  options for ∆F 
⍝H    Options:    ('Mode' [1*|0|¯1|¯2])('Debug' [1|0*]) ('EscCh' '`'*|'char')
⍝H                ('UseNs' [1|0*]) ('ExtLib' [1*|0]) ('Force' [1|0*])
⍝H    OR  ⍬:      ignores right argument, immediately returning 1 0⍴''
⍝H    OR  'help': provides HELP information and returns ⍬
⍝H 
⍝H    Default:   ()'Mode' n) if only a number n is presented.
⍝H       Mode: 1 ("std"); 0 ("code"), ¯1 ("list"), ¯2 ("table")
⍝H           std:   format and return the object generated.
⍝H           code:  create a dfn to format and generate an object; useful when
⍝H                  the function is going to be called repeatedly on different data.
⍝H           list:  format and return the object generated, boxing each field of the object 
⍝H                  separately left-to-right, using dfn ¨disp¨.
⍝H           table: format and return the object generated, boxing each field of the object 
⍝H                  separately in a "table", one field above the other, using dfns ¨disp¨.
⍝H       Debug (0): If 1, carriage returns (via '`⋄' or directly) are replaced by a visible rep: ␍
⍝H                In addition, the intended executable is displayed before execution.
⍝H       EscCh ('`'): a single "escape" character. May be any Unicode char.
⍝H       UseNs (0):
⍝H          ∘ If 1, a shared anonymous namespace will be passed to each code field.
⍝H          ∘ Since code fields are executed R-to-L, the first one to see the namespace
⍝H            will be the rightmost one.
⍝H       ExtLib (1): 
⍝H          ∘ If 1, we use a namespace (library) ⍙F to hold key ∆F utilities
⍝H            referenced in the code generated by The APL fn, ∆F. ∆F generates ⍙F utilities.
⍝H            Generates a more compact code string than if extLib=0.
⍝H          ∘ If 0, the utilities are included in the code created by the associated 
⍝H            C routine called here. Any resulting dfn (mode 0) will be self-contained.
⍝H      Force  (0):
⍝H          ∘ For debugging only. 
⍝H            Forces the external library (see extLib) and the runtime C-based dfn to be reinstalled;
⍝H          ∘ Normally, these actions take place on the first call to ∆F, w/o user action.
⍝H 
⍝H Syntax: opts ∆F f_string [ obj1 ... ]
⍝H         f_string: a single string containing text, formatting information, and executable code.
⍝H         obj1 ...: zero or more objects interpolated into the output as defined in the f-string.
⍝H         opts:     mode[1*|0]    box[0*|1]   escapeChar['`'*]                 
⍝H                   * points to the default value for each option
⍝H For help: 
⍝H         ∆F⍨'help' 

⍝H --------------
⍝H  ∆F IN DETAIL
⍝H --------------
⍝H ∘ By default, the escape char. is '`'.
⍝H ∘ Escape sequences, used in text fields and strings within code fields:
⍝H    `⋄   newline (replaced with a carriage return, ⎕UCS 13)
⍝H    `{  literal left brace 
⍝H    `}  literal right brace; 
⍝H        a simple right brace is also valid when no simple left brace precedes it
⍝H    ``  the escape itself, useful just before a non-escaped left brace.
⍝H ∘ Escape sequences used in code fields, outside strings:
⍝H    `⍵  or equivalently ⍹: a fast way to select components of ∆F's right arg 
⍝H        `⍵5 (or: ⍹5) selects (5⌷⍵) with implicit ⎕IO=0, 
⍝H        `⍵0 (or: ⍹0) selects (0⌷⍵), i.e. the format string itself.
⍝H        `⍵ (or: ⍹) selects the NEXT component of the argument. 
⍝H        If no `⍵/⍹ has been used, `⍵ selects `⍵1 (not `⍵0). 
⍝H    ``  the escape itself, useful just before a non-escaped left brace.
⍝H ∘ The escape represents itself in all other cases.
⍝H
⍝H ---------------------------------------------------------------------------------------
⍝H Quick example (before explaining f-string formatting):
⍝H ⍎      ∆F 'The current temp is{1⍕⍪1↓⍵}°C or{1⍕⍪32+(9÷5)×1↓⍵}°F.' 20 30 40 50
⍝H ⎕   The current temp is 20.0°C or  68.0°F.
⍝H ⎕                       30.0       86.0   
⍝H ⎕                       40.0      104.0   
⍝H ⎕                       50.0      122.0   
⍝H Syntax: 
⍝H     [mode←1 box←0 escCh←'`' | ⍬ | 'help'] ∆F f-string  [obj1 ...] 
⍝H 
⍝H     ⍵← f-string [[⍵1 ⍵2...]]
⍝H        f-string: char vector with formatting specifications.
⍝H               See below.
⍝H        obj1 ...:  
⍝H               arguments visible to all f-string code expressions (0⌷⍵ is the f-string itself). 
⍝H     ⍺← 1 0 '`'   = mode box escCh
⍝H        mode:  1= generate code, execute, and display result [default].
⍝H                  Fields are executed left to right, as if APL statements separated by ⋄.
⍝H               0= emit a dfn that will format output identical to mode=1, 
⍝H                  "precompiled" based on the f-string presented;
⍝H                  fields will be executed from left to right to fit ∆F syntax; 
⍝H              ¯1= generate pseudo code right-to-left with each field a separate character vector.
⍝H                  (For pedagogical or debugging purposes).
⍝H              ¯2= same as for mode=¯1, except displaying fields boxed in table (⍪) form.
⍝H                  (For pedagogical or debugging purposes).
⍝H                  Tip: Use ¯2 ∆F "..." to see the code generated for the fields you specify.
⍝H              Note: For mode=0, the fields will be generated and executed in reverse order,
⍝H                 but displayed in left-to-right order consistent with ∆F syntax
⍝H                 as if separate fields were statements of a Dyalog dfn separated by ⋄.
⍝H        -------
⍝H        box:   1= display each field in a box ("disp" from dfns).
⍝H               0= display each field as is [default].
⍝H        -------
⍝H        escCh: escape character, used to ensure or suppress special behavior.
⍝H               ∘ default is '`'. A common alternative is '\'.
⍝H               ∘ suppresses special behavior of {, }, `.
⍝H               ∘ enables special behavior of `⋄ and `⍵.
⍝H        -------
⍝H        ⍬:     causes ∆F to do absolutely nothing, but quickly, returning shy
⍝H                  1 0⍴''
⍝H               E.g. To execute & display {⎕DL toggle}, ONLY if toggle<10:
⍝H ⍎                (1/⍨toggle<10) ∆F 'Delay of {toggle} seconds: {⎕DL `⍵1}'(toggle←?15)
⍝H ⎕              Delay of 5 seconds: 5.109345
⍝H        -------
⍝H         'help': shows this help information.
⍝H        -------
⍝H    Returns: Per mode above (see mode)
⍝H       [ 1]  A (possibly one-line or 0-line) matrix.
⍝H       [ 0]  A dfn expecting a right argument of 0 or more objects. 
⍝H       [¯1]  vector of char. vectors
⍝H       [¯2]  A matrix (raveled, box vector of char. vectors)
⍝H    or, if ⍺≡⍬, returns:
⍝H       1 0⍴''
⍝H
⍝H The f-string
⍝H ○ The f-string is a character vector defining 0 or more 2-D (char matrix) "fields," 
⍝H   which are executed as if separate statements (the left-most field "executed" first)
⍝H   and assembled into a single matrix (with fields displayed left-to-right, top-aligned, 
⍝H   and padded with blank rows as required). 
⍝H ○ The f-string is available to Code Fields (below) 
⍝H   or the shortcut" variable ⍹0 or, equivalently, `⍵0. See Omega Expressions below.
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
⍝H     c. Self-Documenting Code Expressions
⍝H      1.Horizontal Self-Documenting Expressions
⍝H        { code → }      ==>     'code' ▶ executed_code
⍝H             If a code expression {...} ends with a right arrow (→),
⍝H             possibly followed by spaces, it is treated as a horizontal 
⍝H             self-documenting code expression. 
⍝H             ∘ All spaces before and after the right arrow are significant!
⍝H             That is, its value (on execution) will be preceded by the text of the code
⍝H             expression. That text will be followed by a special right arrow (▶) and spaces
⍝H             as input:
⍝H ⍎               ∆F '1. {⍪⍳2→}, 2. {⍪⍳2 → }.'
⍝H ⎕           1. ⍪⍳2▶0, 2. ⍪⍳2 ▶ 0. 
⍝H ⎕                  1           1 
⍝H        2.Vertical Self-Documenting Expressions
⍝H          { code % }    OR   { code ↓ }    ==>   'code'  ▼
⍝H                                                executed_code
⍝H             If a code expression {...} ends with a pct sign (%) or down arrow (↓)
⍝H             (possibly followed by spaces), it is treated as a vertical 
⍝H             self-documenting code expression.
⍝H           ∘ All spaces before and after the right arrow are significant!
⍝H             That is, the text of the code expression will be placed above the value of the
⍝H             executed code as a "title". A special down arrow (▼) is used within
⍝H             the self-documenting expression on output.    
⍝H ⍎              ∆F '1. {⍪⍳2%}, 2. {⍪⍳2 % }.'
⍝H ⎕           1. ⍪⍳2▼, 2. ⍪⍳2 ▼ .
⍝H ⎕               0         0    
⍝H ⎕               1         1 
⍝H         Compare Python self-documenting expressions {...=}
⍝H     d. Shortcuts (prefixes or infixes [monadic or dyadic pseudo-fns]): 
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
⍝H         ∘ See also the use of → and % as suffixes for Self-Documenting Code (above)> 
⍝H     d. Available local namespace
⍝H        If ⍺ is referred to in (the top level of) any code field, then
⍝H        a local namespace is created and passed as the top-level left argument (⍺)
⍝H        to the field. If, for example, a field to the left sets a variable in ⍺:
⍝H             {"⊂The cost is ⊃,P⊂$⊃F6.2"$ ⍺.Cost← 25.12}
⍝H        then all fields to that field's right can access it:
⍝H             {⍺.Cost≥ 25: "That''s too expensive!" ⋄ "That''s priced just fine."}
⍝H      ⍝ Putting it all together:
⍝H ⍎      ∆F'{"⊂The cost is ⊃,P⊂$⊃F6.2"$ ⍺.Cost← 25.12}. {⍺.Cost≥ 25: "That''s too expensive!" ⋄ "That''s priced just fine."}'
⍝H ⎕    The cost is $25.12. That's too expensive! 
⍝H 
⍝H 2. Space Fields (SF)  
⍝H                {}, {   } 
⍝H     # spaces   0     3       
⍝H    Space fields consist of a left brace, 0 or more spaces, followed by a right brace.
⍝H    The number of spaces will be displayed on output.
⍝H    ∘ Space fields have the intended side effect of ending any prior text field.
⍝H    ∘ A null field, a space field with no included spaces, is used to end a prior text 
⍝H      field w/o introducing any spaces into the output. 
⍝H       a1. Braces with 1 or more blanks separate other fields.
⍝H           1 blank: { }, 2 blanks: {  }, etc.
⍝H       a2. Null Fields: brace with 0 blanks is a Null Space Field, useful for separating OTHER fields.
⍝H       ∘ Examples of space fields (with multiline text fields-- see below):
⍝H ⍎           ∆F 'a`⋄cow{}a`⋄bell'            ∆F 'a`⋄cow{ }a`⋄bell'
⍝H ⎕        a  a                            a   a
⍝H ⎕        cowbell                         cow bell
⍝H     ∘ Self-documenting Space Fields do NOT exist.
⍝H 
⍝H 3. Text fields: These contain any APL characters at all, except requiring escape
⍝H    characters to "escape" a left brace, a diamond (⋄), or escape character, and 
⍝H    allowing an escape character to "escape" a right brace: 
⍝H    If your exape character is '`' (the default):
⍝H    `{ is a literal {
⍝H    `} is a literal }
⍝H     { by itself starts a new code field
⍝H     } by itself ends a code field
⍝H    `⋄ stands for a newline character (we use ⎕UCS 13).
⍝H     ⋄ has no special meaning, unless preceded by the current escape character (`).
⍝H     ` before {, }, or ⋄ (diamond) must be doubled to have its literal meaning (`` ==> `)
⍝H     ` before other characters has no special meaning (i.e. appears as a literal character, unless escaped).
⍝H    Single quotes must be doubled as usual when typing in APL strings to be evaluated in code or via ⍎. 
⍝H    Double quotes have no special status in a text field (but see Code Fields).
⍝H    ⍹ and `⍵ have no special status in text fields (they are left as is).
⍝H
⍝H For help, execute                                             
⍝H   ∆F⍨'help' ... or see ⍝H "HELP" comments at the bottom of function ∆F.
⍝H 

