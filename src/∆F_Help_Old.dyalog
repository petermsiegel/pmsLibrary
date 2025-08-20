:Namespace ∆F_Help_Old 
Help← { 
    'help'≢ 4↑o←⎕C⍵: ⎕SIGNAL optÊ 
      nx← 1∊'-x'⍷o
      hP← nx↓ '(?x) ^\s* ⍝HX (?| [⍎⎕]? (.*) | (⍝.*) )' '(?x) ^\s* ⍝H(?!X) (.*)' 
      hR← nx↓ ' | \1' '\1' 
      1 0⍴⍬⊣ ⎕ED ⍠'ReadOnly' 1⊢'h'⊣ h← hP ⎕S hR ⊣ ⎕SRC ⎕THIS 
}

⍝ === BEGINNING OF HELP INFO =====================================================================
⍝H +---------------------------------------------------------------------------------------+
⍝H +  ∆F IN BRIEF
⍝H +---------------------------------------------------------------------------------------+
⍝H 
⍝H ∆F is a function that interprets f-strings, short for "formatted string literals,"
⍝H a concise, yet powerful way to display complex text and multi-dimensional expressions
⍝H in an APL-friendly style:
⍝H 
⍝H ∘ Text expressions can generate multi-line Unicode text (using `⋄ to indicate a newline); 
⍝H ∘ Each code field allows full dfn logic, plus a few extensions, such as:
⍝H   -  double-quoted strings ("like this"), including multiline strings ("like`⋄this"); 
⍝H   -  simple shortcuts for 
⍝H      + formatting numeric arrays ($), 
⍝H      + putting a box around a specific field (`B), 
⍝H      + date and time expressions from APL timestamps (`T),
⍝H      and more
⍝H   as well as concisely inserting data from 
⍝H      +  active variables or arbitrary code 'Like {this} or {2 3⍴that}',  
⍝H      +  or via ∆F arguments that follow the format string (`⍵2, `⍵).
⍝H ∘ Multiline output is built up left-to-right from simple or multi-dimensional values;
⍝H ∘ All variables and code are evaluated (and, if desired, updated) in the user's calling environment,
⍝H   following dfn conventions for external variables and those within the ∆F specification;
⍝H ∘ ∆F is designed for debugging and casual user interaction, since APL has more powerful
⍝H   and higher-performing ways to build and display complex objects, when simplicity is
⍝H   not paramount.
⍝H 
⍝H        +--------------------------------------------------+
⍝H        +       ∆F is inspired by Python F-strings,        +
⍝H        +  but designed for APL multi-dimensional arrays.  +
⍝  DON'T CHANGE THE SPACING ON THE NEXT LINE!
⍝H        +                     ☞☞☞☞☞☞                   +
⍝H        +--------------------------------------------------+
⍝HX
⍝HX +---------------------------------------------------------------------------------------+
⍝HX +  ∆F EXAMPLES
⍝HX +---------------------------------------------------------------------------------------+
⍝HX
⍝HX Let's start with some examples, before sharing calling information and other details...
⍝HX 
⍝HX⍝ Set some values we'll need for our examples...
⍝HX⍎  ⎕RL ⎕IO ⎕ML←2342342 0 1             ⍝ ⎕ML: Ensure our random #s aren't random!
⍝HX 
⍝HX⍝ Examples
⍝HX⍝ ¯¯¯¯¯¯¯¯
⍝HX⍝ Simple variable expressions
⍝HX⍎  name← 'Fred' ⋄ age← 43
⍝HX⍎  ∆F 'The patient''s name is {name}. {name} is {age} years old.'
⍝HX⎕The patient's name is Fred. Fred is 43 years old.
⍝HX 
⍝HX⍝ Arbitrary code expressions
⍝HX⍎  names← 'Mary' 'Jack' 'Tony' ⋄ prize← 1000
⍝HX⍎  ∆F 'Customer {names⊃⍨ ?≢names} wins £{?prize}!'
⍝HX⎕Customer Jack wins £80!   
⍝HX 
⍝HX⍝ Some multi-line text fields separated by non-null space fields
⍝HX⍝ ∘ The backtick is our "escape" character. 
⍝HX⍝ ∘ Here each `⋄ displays a newline character in the left-most "field."
⍝HX⍝ ∘ { } is a Space Field with one space (because there's one space between the braces).
⍝HX⍝   A space field is useful here because each multi-line field is built in its own 
⍝HX⍝   rectangular space.
⍝HX⍎  ∆F 'This`⋄is`⋄an`⋄example{ }Of`⋄multi-line{ }Text`⋄Fields'
⍝HX⎕This    Of         Text  
⍝HX⎕is      multi-line Fields
⍝HX⎕an                       
⍝HX⎕example 
⍝HX
⍝HX⍝ Two adjacent text fields can be separated by a 0-length space field {}, for example
⍝HX⍝ to insert adjacent multiline input:
⍝HX⍎  ∆F 'Cat`⋄Elephant `⋄Mouse{}Felix`⋄Dumbo`⋄Mickey'
⍝HX⎕Cat      Felix 
⍝HX⎕Elephant Dumbo 
⍝HX⎕Mouse    Mickey
⍝HX⍝In the above example, we added an extra space after the longest animal name...
⍝HX
⍝HX⍝ But... 
⍝HX⍝ Surely you want the field to be guaranteed to have a space after EACH word
⍝HX⍝ without fiddling, so a space field with at least one space would be easier:
⍝HX⍎  ∆F 'Cat`⋄Elephant`⋄Mouse{ }Felix`⋄Dumbo`⋄Mickey'
⍝HX⎕Cat      Felix 
⍝HX⎕Elephant Dumbo 
⍝HX⎕Mouse    Mickey 
⍝HX 
⍝HX⍝ A similar example with double-quote-delimited strings in code fields with 
⍝HX⍝ the newline sequence (`⋄):
⍝HX⍎  ∆F '{"This`⋄is`⋄an`⋄example"}  {"Of`⋄Multi-line"}  {"Strings`⋄in`⋄Code`⋄Fields"}'
⍝HX⎕This     Of          Strings
⍝HX⎕is       Multi-line  in     
⍝HX⎕an                   Code   
⍝HX⎕example              Fields 
⍝HX   
⍝HX⍝ Here is some multiline data in code fields
⍝HX⍎  fn←   'John'           'Mary'         'Ted'
⍝HX⍎  ln←   'Smith'          'Jones'        'Templeton'
⍝HX⍎  addr← '24 Mulberry Ln' '22 Smith St'  '12 High St'
⍝HX⍎  ∆F '{↑fn} {↑ln} {↑addr}'
⍝HX⎕John Smith     24 Mulberry Ln
⍝HX⎕Mary Jones     22 Smith St   
⍝HX⎕Ted  Templeton 12 High St 
⍝HX     
⍝HX⍝ A slightly more interesting code expression, using the shortcut $ (⎕FMT) to round the
⍝HX⍝ calculated Fahrenheit numbers to the nearest tenth:
⍝HX⍎  C← 11 30 60
⍝HX⍎  ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ 32+9×C÷5}°F'
⍝HX⎕The temperature is 11°C or  51.8°F
⍝HX⎕                   30       86.0  
⍝HX⎕                   60      140.0 
⍝HX  
⍝HX⍝ Here we place boxes around key code fields using the shortcut `B (box).
⍝HX⍎ ∆F'`⋄The temperature is {`B "I2" $ C}`⋄°C or {`B "F5.1" $ 32+9×C÷5}`⋄°F'
⍝HX                    ┌──┐      ┌─────┐
⍝HX⎕The temperature is │11│°C or │ 51.8│°F
⍝HX⎕                   │30│      │ 86.0│ 
⍝HX⎕                   │60│      │140.0│ 
⍝HX⎕                   └──┘      └─────┘    
⍝HX   
⍝HX⍝ While we can't place boxes around text fields this way, we can place 
⍝HX⍝ a box around EACH of our fields using a ∆F global option:
⍝HX⍎  0 0 1 ∆F'`⋄The temperature is {"I2" $ C}`⋄°C or {"F5.1" $ 32+9×C÷5}`⋄°F'
⍝HX
⍝HX⎕┌───────────────────┬──┬──────┬─────┬──┐
⍝HX⎕│                   │11│      │ 51.8│  │
⍝HX⎕│The temperature is │30│°C or │ 86.0│°F│
⍝HX⎕│                   │60│      │140.0│  │
⍝HX⎕└───────────────────┴──┴──────┴─────┴──┘  
⍝HX            
⍝HX⍝ Referencing external expressions
⍝HX⍎  C← 11 30 60
⍝HX⍎  C2F← 32+9×÷∘5    
⍝HX⍎  ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ C2F C}°F'
⍝HX⎕The temperature is 11°C or  51.8°F
⍝HX⎕                   30       86.0  
⍝HX⎕                   60      140.0 
⍝HX 
⍝HX⍝ Referencing ∆F additional arguments using omega shortcut expressions.
⍝HX⍎  ∆F'The temperature is {"I2" $ `⍵1}°C or {"F5.1" $ C2F `⍵1}°F' (11 15 20)
⍝HX⎕The temperature is 11°C or  51.8°F
⍝HX⎕                   15       59.0  
⍝HX⎕                   20       68.0 
⍝HX
⍝HX⍝ The temperature of the sun at its core in degrees C.
⍝HX⍎  sun_core← 15E6
⍝HX⍝ Use format string specifier "C" with shortcut $ to add appropriate commas to the temperatures!
⍝HX⍎  ∆F'The sun''s core is at {"CI10"$sun_core}°C or {"CI10"$C2F sun_core}°F'
⍝HX⎕The sun's core is at 15,000,000°C or 27,000,032°F
⍝HX
⍝HX⍝ Use argument `⍵1 (i.e. 1⊃⍵) in a calculation.      Note: 'π²' is (⎕UCS 960 178) 
⍝HX⍎  ∆F 'π²={`⍵1*2}, π={`⍵1}' (○1)   
⍝HX⎕π²=9.869604401, π=3.141592654
⍝HX 
⍝HX⍝ Self-documenting code fields (SDCFs) are a useful debugging tool. 
⍝HX⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝HX⍝ SDCFs allow whatever source code is in a Code Field to be automatically displayed 
⍝HX⍝ ∘ [horizontal] to the left of the result of evaluating that code; or,
⍝HX⍝ ∘ [vertical]   centered above the result of evaluating that code.  
⍝HX⍝ All you have to do is place a → (horizontal) or a ↓ (vertical) as the last non-space
⍝HX⍝ in the code field, before the final right brace. 
⍝HX⍝ Any spaces just before or after the symbol are preserved.
⍝HX
⍝HX⍝ [Horizontal] SDCFs (source code shown to the left of the evaluated result).
⍝HX⍎  name←'John Smith' ⋄ age← 34
⍝HX⍎  ∆F 'Current employee: {name→}, {age→}.'
⍝HX⎕Current employee: name→John Smith, age→34.
⍝HX
⍝HX⍝ Note how the spaces adjacent to the symbol "→" are mirrored in the output:
⍝HX⍎  name←'John Smith' ⋄ age← 34
⍝HX⍎  ∆F 'Current employee: {name → }, {age→   }.'
⍝HX⎕Current employee: name → John Smith, age→   34.
⍝HX 
⍝HX⍝ [Vertical] SDCFs (source code centered above the evaluated result)
⍝HX⍎  name←'John Smith' ⋄ age← 34
⍝HX⍎  ∆F 'Current employee: {name↓} {age↓}.'
⍝HX⎕Current employee:   name↓    age↓.
⍝HX⎕                  John Smith  34
⍝HX  
⍝HX⍝ Here's the same result, but with a box around each field, to make it easy to see.
⍝HX⍝ ⍵[2]=1: Box all args (⎕IO=0).
⍝HX⍎  0 0 1 ∆F 'Current employee: {name↓} {age↓}.'
⍝HX⎕┌──────────────────┬──────────┬─┬────┬─┐
⍝HX⎕│Current employee: │  name↓   │ │age↓│.│
⍝HX⎕│                  │John Smith│ │ 34 │ │
⍝HX⎕└──────────────────┴──────────┴─┴────┴─┘
⍝HX 
⍝HX⍝ Let's use the shortcut % to display one expression centered above another;
⍝HX⍝ It's called "above" and can also be expressed as `A.
⍝HX⍝ Also, `⍵1 refers to the first argument after the f-string itself;
⍝HX⍝ And,  `⍵2 refers to the second.
⍝HX⍝ * Note that `⍵0 refers to the f-string itself.
⍝HX⍎  ∆F '{"Current Employee" % ⍪`⍵1}   {"Current Age" % ⍪`⍵2}' ('John Smith' 'Mary Jones')(29 23)
⍝HX⎕Current Employee   Current Age
⍝HX⎕   John Smith          29     
⍝HX⎕   Mary Jones          23 
⍝HX 
⍝HX⍝ Let's display arbitrary 2-dimensional expressions, one above the other. 
⍝HX⍝ `⍵ refers to the next argument in sequence, left to right, starting with `⍵1, the first.
⍝HX⍝ * See Shortcut Expressions for details on % and `⍵.
⍝HX⍎  ∆F'{(⍳2⍴`⍵) % (⍳2⍴`⍵) % (⍳2⍴`⍵)}' 1 2 3 
⍝HX⎕    0 0      
⍝HX⎕  0 0  0 1    
⍝HX⎕  1 0  1 1    
⍝HX⎕0 0  0 1  0 2 
⍝HX⎕1 0  1 1  1 2 
⍝HX⎕2 0  2 1  2 2  
⍝HX
⍝HX⍝ ∆F's box option (⍺[2]=1) boxes each field in the formatted f-string (⎕IO=0).
⍝HX⍎  C← 11 30 60
⍝HX⍎  0 0 1 ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝HX⎕┌───────────────────┬──┬──────┬─────┬──┐
⍝HX⎕│                   │11│      │ 51.8│  │
⍝HX⎕│The temperature is │30│°C or │ 86.0│°F│
⍝HX⎕│                   │60│      │140.0│  │
⍝HX⎕└───────────────────┴──┴──────┴─────┴──┘
⍝HX
⍝HX⍝ A simple Date-Time shortcut `T built from ⎕DT and 1200⌶.
⍝HX⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯ 
⍝HX⍝ Let's look at the use of the `T (Date-time) shortcut to show the current time (now).
⍝HX⍝ The right argument is always a ⎕TS or any non-empty prefix thereof.
⍝HX⍎  ∆F'It is now {"t:mm pp" `T ⎕TS}.'
⍝HX⎕It is now 8:08 am.      ⍝ <=== Time above will be the real actual time!
⍝HX 
⍝HX⍝ Here's a more powerful example (the power is in ⎕DT and 1200⌶).
⍝HX⍝ (Right arg "hardwired" into F-string)
⍝HX⍎  ∆F'{ "D MMM YYYY ''was a'' Dddd." `T 2025 01 01}'
⍝HX⎕1 JAN 2025 was a Wednesday.
⍝HX 
⍝HX⍝ If it bothers you to use `T for a date-only expression (like the one above),
⍝HX⍝ you can use `D, which means exactly the same thing. 
⍝HX⍎  ∆F'{ "D MMM YYYY ''was a'' Dddd." `D 2025 01 02}'
⍝HX⎕2 JAN 2025 was a Thursday.
⍝HX 
⍝HX⍝ (Right argument via omega expression: `⍵1).
⍝HX⍎  ∆F'{ "D Mmm YYYY ''was a'' Dddd." `T `⍵1}' (2025 1 21)
⍝HX⎕21 Jan 2025 was a Tuesday.
⍝HX 
⍝HX⍝ (Right args via omega expressions: `⍵ `⍵ `⍵).
⍝HX⍎  ∆F'{ "D Mmm YYYY ''was a'' Dddd." `T `⍵ `⍵ `⍵} That''s {`⍵1}.' 1925 1 21
⍝HX⎕21 Jan 1925 was a Wednesday. That's 1925.
⍝HX   
⍝HX⍝ +-------------------------------------+
⍝HX⍝ + Performance of ∆F (or 0 ∆F) vs 1 ∆F +
⍝HX⍝ +-------------------------------------+
⍝HX
⍝HX⍝ Finally, let's explore getting the best performance for a heavily used ∆F string.
⍝HX⍝ Using the DFN option (⍺[0]=1), we can generate a dfn that will display the formatted
⍝HX⍝ output, without having to reanalyze the f-string each time.
⍝HX⍝ We will compare the performance of an ∆F-string evaluated on the fly
⍝HX⍝    ∆F ...      ⍝ The same as 0 ∆F ...
⍝HX⍝ and precomputed and returned as a dfn:
⍝HX⍝    1 ∆F ...
⍝HX
⍝HX⍝ First, let's get cmpx, so we can compare the performance...
⍝HX⍎  'cmpx' ⎕CY 'dfns'
⍝HX⍎  C← 11 30 60
⍝HX⍝ Here's our ∆F String <t>
⍝HX⍎  t←'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝HX⍝ Precompute a dfn T given ∆F String <t>.
⍝HX⍎  T←1 ∆F t      ⍝ T← Generate a dfn w/o having to re-evaluate <t>. 
⍝HX⍝ Compare the performance of the two formats...
⍝HX⍝ The precomputed version is about 17 times faster, in this run.
⍝HX⍎  cmpx '∆F t' 'T ⍬'
⍝HX⎕ ∆F t → 1.7E¯4 |   0% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
⍝HX⎕ T ⍬  → 1.0E¯5 | -94% ⎕⎕ 
⍝HX
⍝HX⍝ We'll leave you with this variant, before reviewing calling information.
⍝HX⍎  t←'The temperature is {"I2" $ `⍵1}°C or {"F5.1" $ F← 32+9×`⍵1÷5}°F'
⍝HX⍎  T← 1 ∆F t 
⍝HX⍎  ∆F t 35
⍝HX⎕The temperature is 35°C or  95.0°F
⍝HX⍎  T 35
⍝HX⎕The temperature is 35°C or  95.0°F
⍝HX⍎  cmpx '∆F t 35' 'T 35'
⍝HX⎕ ∆F t 35 → 1.7E¯4 |   0% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
⍝HX⎕ T 35    → 8.9E¯6 | -95% ⎕⎕ 
⍝H 
⍝H +---------------------------------------------------------------------------------------+
⍝H + ∆F Calling Information
⍝H +---------------------------------------------------------------------------------------+
⍝H  
⍝H         ⎧            ∆F f-string [arg1 arg2 ...] ⎫  Display an ∆F String (default options)  
⍝H result← ⎨ [options]  ∆F f-string [arg1 arg2 ...] ⎬  Display an ∆F String; control result with options
⍝H         ⎨            ∆F⍨'help'                   ⎬  Display help information and examples for ∆F
⍝H         ⎩            ∆F⍨'help-x'                 ⎭  Display help info for ∆F WITHOUT examples.
⍝H 
⍝H Right argument to ∆F: f-string [arg1 [arg2...]]
⍝H ¯¯¯¯¯ ¯¯¯¯¯¯¯¯ ¯¯ ¯¯
⍝H   f-string (first element of right argument to ∆F): 
⍝H       an f-string, a single character vector (see "∆F IN DETAIL" below) 
⍝H   args (optional):          
⍝H       elements of  ⍵ after the f-string, each of which can be accessed, via a shortcut 
⍝H       that starts with `⍵ or ⍹ (see Omega_Shortcuts, below). 
⍝H   result: If (0=⊃options), the result is always a character matrix. 
⍝H           If (1=⊃options), the result is a dfn that, when executed, generates a character matrix.
⍝H 
⍝H Left arg (⍺) to ∆F:   [ [ options← 0 [ 0 [ 0 [ 0 ] ] ] ] | 'help[-x]' ]   
⍝H  - If the left argument is omitted,
⍝H         the default options (0 0 0 0) are assumed;
⍝H  - If the left arg ⍺ is a simple boolean vector or scalar (or an empty numeric vector),
⍝H         the options are (4↑⍺); subsequent elements are ignored;
⍝H  - If the left arg starts with 'help' (case ignored), help information is displayed:
⍝H      'help':   display all help info, including examples; 
⍝H      'help-x': display help info without examples; 
⍝H    and returns (1 0⍴⍬); the right argument (⍵) is not examined;
⍝H  - Otherwise,
⍝H         an error is signaled.
⍝H 
⍝H    Option Name:     [ DFN  DBG  BOX  INLINE ]
⍝H    Default Values:    0    0    0    0    
⍝H    Value Type         bool bool bool bool
⍝H    All options are positional (i.e. DFN is positioned first, DBG second, etc.)
⍝H    The options are:
⍝H       DFN: If 0, returns a formatted matrix object based on the f-string (0⊃⍵) and any other "args" referred to.
⍝H            If 1, returns a dfn that, when executed, returned a formatted matrix object, as for DFN=0.
⍝H       DBG: If 0, returns the value as above.
⍝H            If 1, displays the code generated from the f-string, before returning a value as above.
⍝H       BOX: If 0, returns the value as above.
⍝H            If 1, returns each field generated within a box (dfns "display"). 
⍝H    INLINE: If 0, ⍙F0 library routines A, B, D, F, and M will be used.
⍝H            In this case, the ⍙Fapl namespace must be present at runtime.
⍝H            If 1, the full code of A, B, D, F, and M is inserted "inline" to make the resulting runtime
⍝H            independent of the ⍙Fapl namespace. This is mostly relevant for returned dfns (DFN=1).
⍝H
⍝H Result Returned: 
⍝H   If (⊃⍺) is 0,  the default, then:
⍝H     ∘ the result is always a matrix, with at least one row and zero columns, unless an error occurs.
⍝H     ∘ If the f-string is null, returns (1 0⍴'').
⍝H   If (⊃⍺) is 1, then: 
⍝H     ∘ the result returned is a dfn (function) that, when executed with the same environment and arguments,
⍝H       generates the same matrix as above, unless an error occurs.
⍝H   If an error occurs, 
⍝H     ∘ ∆F generates a standard, trappable Dyalog ⎕SIGNAL.
⍝H   If ⍺ starts with 'help' (case ignored)
⍝H     ∘ ∆F displays help information as rescribed above.
⍝H     ∘ Returns (1 0⍴''). 
⍝H 
⍝H +---------------------------------------------------------------------------------------+
⍝H + ∆F IN DETAIL (TL;DR)
⍝H +---------------------------------------------------------------------------------------+
⍝H 
⍝H The first element in the right arg to ∆F is a character vector, an "∆F string", 
⍝H which contains simple text, along with run-time evaluated expressions enclosed within
⍝H unescaped curly braces {}, i.e. those not preceded by a back-tick, "`".
⍝H Each ∆F string is viewed as containing one or more "fields," catenated left to right,
⍝H each of which will display as a logically separate 2-D output space.. This allows
⍝H the expected display of multi-dimensional array values within each field.
⍝H ∘  ∆F adds no automatic spaces between fields like those APL adds to denote object rank, etc.
⍝H ∘  ∆F assumes the user wants to control spacing from one field to the next, but 
⍝H    handles spacing within each field according to APL rules.
⍝H 
⍝H ∆F-string text fields (expressions) may include:
⍝H   ∘ a small number of escape sequences, beginning with the escape character ( the backtick "`"):
⍝H        `⋄   =>   a newline         ``   =>   "`" 
⍝H        `{   =>   "{"               `}   =>   "}" 
⍝H     Other instances of the escape character in text fields will be treated literally, 
⍝H     as an ordinary backtick "`". 
⍝H   ∘ Simple { and } delineate the start and end of a Code Field, discussed now, or a Space field.
⍝H 
⍝H ∆F-string code fields (dfn expressions) may be used to display simple variables, 
⍝H arbitrary expressions in dfns, as well as various shortcuts. A shortcut is a 
⍝H punctuation mark ($ or %) or sequence of an escape character (a backtick) and one of a 
⍝H small number of capital letters.
⍝H Code fields look like ordinary single-line dfns, but must return a value. They may include:
⍝H   ∘ strings in double quotes ("...") or single quotes (''...''). 
⍝H     A quote may be included within a code field string by doubling it in the APL style, as here:
⍝H         "Birds ""are"" dinosaurs." 
⍝H     You can always use single quotes, but they can be a bit awkward, as in this example:
⍝H         ''Birds ''''are'''' dinosaurs.''
⍝H     Strings in quotes may have a limited set of escaped characters:
⍝H          `⋄   ==>   a carriage return        ``   ==>   a single escape.
⍝H     Any other use of an escape (backtick) inside a code field string is treated as an
⍝H     ordinary character, along of course with the character that follows it.
⍝H   ∘ dyadic ⎕FMT control codes for concisely formatting integers, floats, and the like 
⍝H     into tables ($);
⍝H   ∘ the ability to display one arbitrary array centered above another (% or `A);
⍝H   ∘ a shortcut for displaying boxed output (`B); finally,
⍝H   ∘ self-documenting code fields (SDCF), concise expressions useful for debugging.
⍝H     SDCFs displaying both a code expression (possible a simple name to be evaluated) 
⍝H     and its value:
⍝H          names← ↑'John' 'Mary'            names← ↑'John' 'Mary' 
⍝H          ∆F '{ names →}'                  ∆F '{ names ↓ }'
⍝H        names →John                      names ↓ 
⍝H               Mary                       John
⍝H                                          Mary
⍝H     (Note: Only code fields may be self-documenting!)
⍝H   ☞ There is no way to include comments in Code Fields, as for any single-line dfn.
⍝H 
⍝H Code fields may include arbitrary expressions, including function definitions:
⍝H          c← ⍪10 15 20
⍝H          ∆F '{c}°C is the same as {C2F← 32+9×÷∘5 ⋄ C2F c}°F'
⍝H        10°C is the same as 50°F
⍝H        15                  59  
⍝H        20                  68  
⍝H 
⍝H ∆F-strings also include space fields, which appear as "degenerate" code fields, i.e. 
⍝H i.e. as (unescaped) braces separated by nothing but 0 or more spaces.
⍝H ∘ space fields separate other fields, often with extra spaces (columns of rectangular spaces)
⍝H   required by the user. Here {  } inserts a 2-space wide field between two text fields.
⍝H          ∆F 'John`⋄Mary{  }241 Maple St`⋄ 15 Ogden Ln'
⍝H        John  241 Maple St
⍝H        Mary   15 Ogden Ln
⍝H 
⍝H The syntax of ∆F Strings is as follows, where ` represents the active escape character:
⍝H   ∆F_String         ::=  (Text_Field | Code_Field | Space_Field)*
⍝H   Text_Field        ::=  (literal_char | "`⋄" | "``" | "`{" | "`}" )
⍝H   Code_Field        ::=  "{" (Fmt | Above | Box | Code )+ (Self_Documenting) "}"
⍝H   Space_Field       ::=  "{"  <0 or more spaces> "}"
⍝H   Code              ::=   One or more dfn code expressions (Code_Expr below), 
⍝H                           along with Omega-Shortcuts, Quoted_Strings, 
⍝H                           appropriate dfn guards and statement separators.
⍝H                           Comments are not allowed.
⍝H   Omega_Shortcuts   ::=   Expressions of the following format:
⍝H                           `⍵ (or ⍹) selects the next object in ⍵ (starting with (1⊃⍵), ⎕IO←0); 
⍝H                           `⍵N (or ⍹N) selects the Nth object in ⍵ (⎕IO←0), where N is 1-3 digits;
⍝H                           `⍵0 (or ⍹0) selects the text of the ∆F_String itself;
⍝H   Quoted_Strings    ::=   Expressions of the following format: 
⍝H                           quoted strings: "..." or ''...'', where ... may include 
⍝H                           `⋄ to represent a newline, 
⍝H                           `` to represent the escape char itself.
⍝H                           ∘ `{, }, `{, `}, `", `" are treated literally (no special meaning)
⍝H                             with any escapes included.
⍝H                           ∘ Double " within a "..." quote to include a double quote.
⍝H                           ∘ Double ' within a '...' quote to include a single quote.
⍝H   Fmt               ::=   [ (Fmt_Expr) ("$" | "`F") Code_Expr] 
⍝H   Fmt_Expr          ::=   Any valid left argument to ⎕FMT
⍝H   Above             ::=   ("(" Code_Expr1 ")") ("%" | "`A") (Code_Expr2)>
⍝H                           ∘ Places Code_Expr1 above  Code_Expr2.
⍝H                           ∘ If Code_Expr1 is omitted, places a blank line above Code_Expr2.     
⍝H   Box               ::=   "`B" Code_Expr 
⍝H                           ∘ Box the result from executing Code_Expr (uses ⎕SE.Dyalog.disp).
⍝H   Self_Documenting  ::=   (" ")* ("→" | "↓" | "%" ) (" ")*, where % is a synonym for ↓.
⍝H   Code_Expr               Any string that evaluates to a valid APL expression returning a result.
⍝H  
⍝H +---------------------------------------------------------------------------------------+
⍝H + Summary of Shortcuts
⍝H +---------------------------------------------------------------------------------------+
⍝H      Format     Apply monadic or dyadic (⍺) ⎕FMT to ⍵
⍝H         $       APL ⎕FMT, formats simple numeric arrays.  [dyadic, monadic]
⍝H        `F       Alias for $   
⍝H      Box        Show ⍵ in a box.
⍝H        `B       A Box routine (⎕SE.Dyalog.disp), displays components of an APL object.  [monadic, dyadic]
⍝H      Above      Show ⍺ (or '') above ⍵
⍝H         %       A formatting routine, displaying the object to its left ('', if none) centered over the object to its right.
⍝H        `A       Alias for %
⍝H      Commas     Add commas every 3 digits in each scalar in the right argument (⍵).
⍝H        `C       ⍵: 1 or more integers or integer strings (or a mixture). 
⍝H                 Note: Floating-point numbers (including very large integers) will be ignored.
⍝H      Date-Time  Show APL timestamp as formatted date or time
⍝H        `T       Date-Time  {... [⍺] `T ⍵...} displays each date-time in Dyalog timestamp (⎕TS) format.
⍝H                 ⍵: one or more APL timestamps (⎕TS)
⍝H                 ⍺: Code for displaying timestamps based on Dyalog (1200⌶).
⍝H                    Default code/⍺: 'YYYY-MM-DD hh:mm:ss'
⍝H                 The `T (Date-Time) helper function uses ⎕DT and (1200⌶).
⍝H                 It is defined as: 
⍝H                    {⎕ML←1 ⋄ ⍺← 'YYYY-MM-DD hh:mm:ss' ⋄ ∊⍣(1=≡⍵)⊢⍺(1200⌶)⊢1 ⎕DT⊆⍵}   
⍝H                 See examples below.
⍝H        `D       Alias for `T (Date-Time). `D requires the same ⎕TS right arg as `T.
⍝H      Omega/Omega Underbar Shortcut*      
⍝H        `⍵n, ⍹n  With an explicit index n, where n is a non-negative integer between 0 and t-1,  
⍝H                 given t, the # of elements of ∆F's right argument ⍵. 
⍝H                 Equivalent to (⍵⊃⍨ n+⎕IO), where ⍵ is the right-hand argument (list of elements)
⍝H                 passed to ∆F, including the format-string itself. n may have any number of digits.
⍝H                 Sets the next implicit index (see below) to n+1.
⍝H        `⍵, ⍹    With an implicit index, which is incremented by one from the omega shortcut to its left. 
⍝H                 Evaluates to (⍵⊃⍨ m+⎕IO), where m is set to n+1, based on n, the index of the 
⍝H                 most recent omega expression to the left, whether one with an explicit index 
⍝H                 (like ⍹n) or an implicit one (like ⍹).
⍝H                 The first use of an implicit index (from the left) is assigned an index of 1
⍝H                 (i.e. m is set to 1). 
⍝H                 Note: ∆F keeps track of the implicit index for you.
⍝H        `⍵0, ⍹0 The format string itself.  A simple `⍵ can never select the format string 
⍝H                 (since the implicit index starts at `⍵1).
⍝H        --------------------------------------
⍝H        * All omega expressions are evaluated left to right and are ⎕IO-independent (as if ⎕IO←0).
⍝H          ⍹ is a synonym for `⍵ in code fields.
⍝H 
⍝H   
:EndNamespace ⍝ ∆F_Help_Old 