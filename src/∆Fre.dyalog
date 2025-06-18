:namespace ⍙Fre
  fnVersion← '∆F'
⍝ === BEGINNING OF CODE ==========================================================================
⍝ === BEGINNING OF CODE ==========================================================================
  ∇ ⍙res← {⍙l} ∆F ⍙r  ; ⎕TRAP 
    ⎕TRAP← 990 'C' '⎕SIGNAL ⊂⎕DMX.(''EM'' ''EN'' ''Message'' ,⍥⊂¨(''∆F '',EM) EN Message)'
    :If 900⌶0 
        ⍙l← ⍬
    :ElseIf 0≠ ⊃0⍴⍙l
        ⍙res← ⎕THIS.Help ⍙l ⋄ :Return 
    :EndIf 

    :Select ⊃⍙l← 4↑⍙l
    :Case 1   ⍝ 1:  Generate Dfn from f-string ⊃⍙r. ⍙r is of the form '{{code}(⊂''f-string''),⍵}' 
        ⍙res← (⊃⎕RSI)⍎ ⍙l ⎕THIS.Main ⊃,⊆⍙r
    :Case 0   ⍝ 0:  Generate and evaluate code from f-string ⊃⍙r; ⍙r is of the form '{code}⍵'.
        ⍙res← ⍙l ((⊃⎕RSI){ ⍺⍺⍎ ⍺ ⎕THIS.Main ⊃⍵⊣ ⎕EX '⍙l' '⍙r'}) ,⊆⍙r
    :Case ¯1    ⍝ ¯1: Development/Testing ONLY 
        ⍙res← 0 ⎕THIS.Main ⊃,⊆⍙r 
    :EndSelect  
  ∇
  
⍝ ⍙Promote_∆F (used internally only)
⍝ ∘ Copy ∆F, obscuring its local names and hardwiring the location of ⎕THIS. 
⍝ ∘ Fix this copy in the parent namsspace.
  ∇ rc← ⍙Promote_∆F fnVersion; src; snk 
    src←   '⎕THIS' '⍙(\w+)' 
    snk←  (⍕⎕THIS) '⍙Ⓕ⍙\1øø'
    rc← ##.⎕FX src ⎕R snk⊣ ⎕NR fnVersion
  ∇
  ⍙Promote_∆F fnVersion


⍝ Top Level Routines...
  ⍝ Main: The "main" function for ∆Fre...
  ⍝ result← [4↑ options] Main f_string
    Main← {  
        (dfn dbg box inline) fStr← ⍺ ⍵ 
        omIx cr← 0 (dbg⊃ crCh crVis)                                ⍝ crCh: (⎕UCS 13), crVis: '␍' 
        DM← (⎕∘←)⍣dbg                                               ⍝ DM: Debug Msg
        extern← ⎕NS 'dbg' 'omIx' 'cr' 'inline'                      ⍝ omIx: r/w; dbg, cr, inline: r/o    
        flds← Split2Flds⍣(0≠≢fStr)⊢ fStr                             ⍝ If fStr is 0-length, don't bother splitting!
      0∧.= ≢ ¨flds: DM '(1 0⍴⍬)', dfn/'⍨'                           ⍝ If all fields are 0-length, return null pair.
        flds← OrderFlds extern∘ProcFlds¨ flds 
        code← '⍵',⍨ lb, rb,⍨ flds,⍨ box inline⊃ cM cD
      ~dfn: DM code                                                  ⍝ Not a dfn. Emit code ready to execute
        quoted← ',⍨ (⊂', ')',⍨ q, q,⍨ fStr/⍨ 1+ fStr= q             ⍝ dfn: add quoted fmt string.
        DM lb, code, quoted, rb                                      ⍝ emit dfn string ready to convert to dfn itself
    } 

  ⍝ Help: Provides help info when ∆F⍨'help[x]' (OR 'help[x]'∆F anything) is specified.
  ⍝ (1 0⍴⍬)← Help 'help' OR 'helpx'
    Help← { 
      'help'≢⎕C 4↑ ⍵: ⎕SIGNAL ⊂'EN' 11,⍥⊂ 'Message' 'Invalid option(s)'
        hP←  '(?i)^\s*⍝H', ('X?'↓⍨ -'x'∊ ⎕C⍵), '⍎?(.*)' 
        1 0⍴⍬⊣ ⎕ED ⍠'ReadOnly' 1⊢'h'⊣ h← hP ⎕S '\1'⊣ ⎕SRC ⎕THIS  
    }

⍝ Ns Debugging Flag 
  ⍝ See top of function       
⍝ Constants (For variables, see namespace ¨extern¨ in main)
    ⎕IO ⎕ML←0 1 
  ⍝ Constant char values 
    esc← '`'  
    crCh crVis← ⎕UCS 13 9229                                     ⍝ crVis: Choose 8629 ↵ 9229 ␍
    s lb rb q dmd← ' {}''⋄' 
    sfTok← ⎕UCS 0  ⍝ See ⍙splitSF. sfTok encodes space fields
    cfTok← lb      
    escEsc escLb escRb escDmd← esc,¨ esc lb rb dmd 
    qq sQ qS← (q q) (s q) (q s)    
    arrows← '↓→'                                                 ⍝  Used in SelfDocCode and for % Above shortcut.
  ⍝ Const patterns 
      scP← '(?|`([BTFA])|([$%]))'                                ⍝ Shortcuts `B etc, and $, % 
      omP←  '(?:`⍵|⍹)(\d*)'  
      qtP←  '(?:"[^"]*")+|(?:''[^'']*'')+' 
    cfPats←  scP omP qtP 
    scI omI qtI← ⍳≢ cfPats 
    ⍝ See Split2Flds...
    ⍝ ⍙splitTF: 
    ⍝ We match text fields and do nothing with them *yet*, to ensure that 
    ⍝ single and multiple escapes before left braces (`{ and ``{) are handled properly.
    ⍝ ∘ The first means a literal left brace (part of TF); 
    ⍝ ∘ The second, a literal escape followed by code (only the esc is part of TF).
    ⍙splitTF←  '([^{`]+|`.)+'
    ⍝ ⍙splitSFZ: Match 0-length space fields as null fields (''). 
    ⍝ Replace them with a new, empty, field (a 'nop').
    ⍙splitSFZ← '(?:\{\})+'
    ⍝ ⍙splitSF: Match space fields (0-length handled above) per SpaceFld below. 
    ⍝ Signaled by pattern left brace + null char.
    ⍙splitSF←  '\{(\h*)\}'
    ⍝ ⍙splitCF: Match code fields, i.e. recursively balanced braces {} and contents, 
    ⍝           handling quotes "..." ''...'' and escapes `.  
    ⍝ Signaled by pattern: left brace, not followed by null char.
    ⍝ It's easy to understand. Honest!
    ⍙splitCF←  '(?x) (?<CF> \{ ((?> [^{}"''`]+ | (?:`.)+ | (?:"[^"]*")+ | (?:''[^'']*'')+ | (?&CF)* )+) \} )' 
  ⍝ splitPats matches each field type. "Text fields" are left as is.
    splitPats←  ⍙splitTF ⍙splitSFZ  ⍙splitSF      ⍙splitCF 
    splitRepl← '\0'      '\n\n'      '\n\x{0}\1\n' '\n\0\n'
 
⍝ "Options" Operator for ⎕R. Only LF is an EOL. CR is specifically a literal in text fields and quoted strings.
    _Opts← ⍠'EOL' 'LF' 

⍝ Utility to be executed at ⎕FIX (aka ]load ) time
  ⍝ LoadRuntime: At ⎕FIX time, load the run-time library names and code.  
    ⍝ For A, B, D, F, M; all like A example shown here:
    ⍝     A← an executable dfn in this namespace (⎕THIS).
    ⍝     cA← name codeString, where
    ⍝         name is (⍕⎕THIS),'.A'
    ⍝         codeString is the executable dfn in string form.
    ∇ {ok}← LoadRuntime 
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
      T← XR cT← HT  '⎕THIS.T'  '{⍺←''YYYY-MM-DD hh:mm:ss''⋄∊⍣(1=≡⍵)⊢⍺(1200⌶)⊢1⎕DT⊆⍵}'  ⍝ T:  ⍺ date-time ⍵ (1- or 2-adic)
      shortCodes← cA  cA  cB  cF  cF  cT  
      shortSyms← 'A'  '%' 'B' 'F' '$' 'T'
      ok← 1 
    ∇
    LoadRuntime

⍝ Functions
  ⍝ TextFld
    ⍝ ⍺: namespace of external (global) vars
    TextFld← { 
        TFR← escDmd escEsc escLb escRb q ⎕R ⍺.cr esc lb rb qq _Opts                          
        sQ, qS,⍨ TFR ⍵
    }
    
  ⍝ SpaceFld: A variant of a code field. 
    ⍝ A space field consists solely of a null-char and 0 or more spaces (within the originally surrounding braces).
    ⍝ SpaceFld ⍵, returns: ((≢⍵)⍴'') as a char. string.
    ⍝ Null (0-length) space fields are handled separately, but will work fine here.
    SpaceFld← { '(', '⍴'''')',⍨ ⍕¯1+ ≢⍵ }
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
        dStr← q, q,⍨ dStr/⍨ 1+q= dStr  
        (p↑⍵) (dTyp ⍺.inline⊃ cA cM) dStr           ⍝ Return code in str form, display fn code in str form, the doc str
    }
  ⍝ CodeFld:  
    ⍝ Process escapes within code fields, including omegas, newlines; and quoted strings.
    ⍝ ⍺: namespace of external (global) vars.
    ⍝ ⍵: Code field text including leading and trailing braces {}
    CodeFld← { ex←⍺                                         ⍝ external ns 
        cStr dFun dStr← ex SelfDocCode 1↓¯1↓⍵               ⍝ Is CodeFld Self-documenting?  
        Sink← {  ⍝  scI omI qtI← ⍳≢ cfPats 
              p← ⍵.PatternNum 
            p= qtI:  q, q,⍨ q escEsc escDmd ⎕R qq esc ex.cr _Opts⊢ 1↓¯1↓ ⍵.Match ⍝ Quoted strings 
              f1← ⍵.(Lengths[1]↑ Offsets[1]↓ Block) 
            p= scI: (shortSyms⍳ f1) ex.inline⊃ shortCodes          
            p= omI: '(⍵⊃⍨⎕IO+', ')',⍨ ⍕ex.omIx← ex {        ⍝ `⍵[nnn] and ⍹[nnn]  
              0=≢⍵: ⍺.omIx+1 ⋄ ⊃⌽⎕VFI ⍵
           } f1           
        }
        cStr← cfPats ⎕R Sink cStr  
        '({', dStr, dFun, cStr, '}⍵)'
    }

  ⍝ OrderFlds
    ⍝ ∘ User flds are effectively executed L-to-R and displayed in L-to-R order 
    ⍝   by reversing their order, evaluating all of them (via APL ⍎) R-to-L, then reversing again when executed in caller. 
    OrderFlds← '⌽',(∊∘⌽,∘'⍬')           ⍝  ensure at least 2 and reverse, emitting code to re-reverse
  ⍝ ProcFlds: Process each Code (or Space) and Text field. 
    ⍝ ⍺: namespace of external (global) vars
    ProcFlds← { 
      0=≢⍵: ''                           ⍝ 0-length input => output null str *
      sfTok=⊃⍵: SpaceFld ⍵               ⍝ sfTok, usu (⎕UCS 0) signals a space field *
      cfTok=⊃⍵: ⍺ CodeFld ⍵              ⍝ cfTok, usu '{',  signals a code field *
        ⍺ TextFld ⍵                      ⍝ Otherwise, a text field.
    }                                    ⍝                          [*] encoded via Split2Flds
  ⍝ Split2Flds: Split f-string into 0 or more fields, removing any null fields generated (after they serve their purpose).
  ⍝             Trailing 0-length space fields are ignored.  { }{}{}{} ==> { } . {}{}{} ==> {}.
    Split2Flds← splitPats ⎕R splitRepl _Opts ⊆
⍝ === END OF CODE ================================================================================
⍝ === END OF CODE ================================================================================

⍝ === BEGINNING OF HELP INFO =====================================================================
⍝ === BEGINNING OF HELP INFO =====================================================================
⍝H -------------
⍝H  ∆F IN BRIEF
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H ∆F is a function that makes it easy to format strings that dynamically display text, variables, and 
⍝H the value of code expressions in an APL-friendly multi-line (matrix) style. 
⍝H   ∘ Text expressions can generate multi-line Unicode strings 
⍝H   ∘ Each code expression follows ordinary dfn conventions, with a few extensions, such as
⍝H     the availability of double-quoted strings, escape chars, and simple formatting shortcuts for APL arrays (which see). 
⍝H   ∘ All variables and code are evaluated (and, if desired, updated) in the user's calling environment,
⍝H     following dfn conventions for local and external variables.
⍝H   ∘ ∆F is inspired by Python F-strings, but designed for APL.
⍝H 
⍝H ∆F: Calling Information
⍝H ¯¯¯ ¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
⍝H result←              ∆F f-string [arg1 arg2 ... ]   Format an ∆F String given args and simply display  
⍝H          [{options}] ∆F f-string [arg1 arg2 ... ]   Format an ∆F String given args; cnt'l result with opt'ns.
⍝H                      ∆F⍨'help[x]'                   Display help (example) information
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
⍝H Left arg (⍺) to ∆F:   [ [ options← 0 [ 0 [ 0 [ 0 ] ] ] ] | 'help[x]' ]   
⍝H    If there is no left arg, 
⍝H         the default options (4⍴ 0) are assumed per below;
⍝H    If the left arg ⍺ is 0 to 4 digits,
⍝H         the options are taken as (4↑⍺);
⍝H    If the left arg is 'help' or 'helpx', 
⍝H         ⍵ is ignored, ∆F shows all help info or just help examples and returns (1 0⍴⍬);
⍝H    Otherwise,
⍝H         an error is signaled.
⍝H    Option Name:     [ DFN  DBG  BOX  INLINE ]
⍝H    Default Values:    0    0    0    0    
⍝H    Value Type         bool bool bool bool
⍝H    All options are positional (i.e. DFN is positioned first, DBG second, etc.)
⍝H    The options are:
⍝H       DFN: If 0, returns a formatted matrix object based on the f-string (0⊃⍵) and any other "args" referred to.
⍝H            If 1, returns a dfn that, when executed, returned a formatted matrix object, as above.
⍝H       DBG: If 0, returns the value as above.
⍝H            If 1, displays the code generated based on the f-string, befure returning a value.
⍝H       BOX: If 0, returns the value as above.
⍝H            If 1, returns each field generated within a box (dfns "display"). 
⍝H    INLINE: If 0, ⍙F0 library routines A, B, D, F, and M will be used.
⍝H            If 1, the CODE of A, B, D, F, and M are used "inline" to make the resulting runtime code 
⍝H            independent of the ⍙F0 namespace.
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
⍝H   If ⍺ is 'help' (case ignored)
⍝H     ∘ ∆F displays help information. 
⍝H   If ⍺ is 'helpx' (case ignored)
⍝H     ∘ only examples are shown.
⍝H 
⍝H --------------
⍝H  ∆F IN DETAIL
⍝H --------------
⍝H 
⍝H The first element in the right arg to ∆F is a character vector, an "∆F string", 
⍝H which contains simple text, along with run-time evaluated expressions delimited by 
⍝H (unescaped) curly braces {}. 
⍝H Each ∆F string is viewed as containing one or more "fields," catenated left to right*,
⍝H each of which will display as a logically separate character matrix. 
⍝H            * ∆F adds no automatic spaces like those APL adds to denote object rank, etc.
⍝H              ∆F assumes the user wants to control spacing of objects.
⍝H 
⍝H ∆F-string text fields (expressions) may include:
⍝H   ∘ escape characters representing newlines, escape characters per se and braces as text. 
⍝H        actual newline: "`⋄",  escape character: "``", left brace "`{", right brace "`}". 
⍝H     Otherwise, { and } delineate the start and end of a Code Field or Space Field.
⍝H ∆F-string code fields (expressions) may include: 
⍝H   ∘ escape characters (e.g. prefixing newlines, escape characters, and braces as text);
⍝H   ∘ dyadic ⎕FMT control codes for concisely formatting integers, floats, and the like into tables ($);
⍝H   ∘ the ability to display an arbitrary object centered above another (%);
⍝H   ∘ shortcuts for displaying boxed output (`B); finally,
⍝H   ∘ self-documenting code fields, concise expressions for displaying both a code 
⍝H     expression (possible a simple name to be evaluated) and its value (→, ↓/%).   
⍝H     (Note: Only code fields may be self-documenting!)
⍝H ∆F-strings include space fields:
⍝H   ∘ which appear as "degenerate" code fields, i.e. braces separated by nothing but 0 or more spaces.
⍝H     ∘ space fields separate other fields, often with extra spaces (columns of rectangular spaces)
⍝H       required by the user.
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
⍝H   Box               ::=   "`B" Code 
⍝H                           Box the result from executing code (uses ⎕SE.Dyalog.disp).
⍝H   Self_Documenting  ::=   (" ")* ("→" | "↓" | "%" ) (" ")*, where % is a synonym for ↓.
⍝H   Code                    See examples.
⍝H  
⍝H   ------- -- -------- -------
⍝H   Summary of Shortcut Symbols
⍝H   ------- -- -------- -------
⍝H      Format
⍝H         $       APL ⎕FMT, formats simple numeric arrays.  [dyadic, monadic]
⍝H        `F       Alias for $
⍝H      Box 
⍝H        `B       A Box routine (⎕SE.Dyalog.disp), displays components of an APL object.  [monadic, dyadic-- see]
⍝H      Above 
⍝H         %       A formatting routine, displaying the object to its left ('', if none) centered over the object to its right.
⍝H        `A       Alias for %
⍝H      Omega/Omega Underbar*      
⍝H        `⍵n, ⍹n  With an explicit index n, where n is a number between 0 and t-1, given 
⍝H                 t, the # of elements of ∆F's right argument ⍵. 
⍝H                 Equivalent to (⍵⊃⍨ n+⎕IO), where ⍵ is the right-hand argument (list of elements)
⍝H                 passed to ∆F, including the format-string itself.
⍝H        `⍵, ⍹    With an implicit index. 
⍝H                 Evaluates to (⍵⊃⍨ m+⎕IO), where m is set to n+1, based on n, the index of the 
⍝H                 most recent omega expression to the left, whether one with an explicit index 
⍝H                 (like ⍹n) or an implicit one (like ⍹).
⍝H                 The first use of an implicit index (from the left) is assigned an index of 1
⍝H                 (i.e. m is set to 1). 
⍝H                 Note: ∆F keeps track of the implicit index for you.
⍝H        `⍵0, ⍹0 The format string itself.  A simple `⍵ can never select the format string 
⍝H                 (since the implicit index starts at `⍵1).
⍝H                 * All omega expressions are evaluated left to right and are ⎕IO-independent (as if ⎕IO←0).
⍝H                   ⍹ is a synonym for `⍵ in code fields.
⍝H 
⍝H New Code Field Shortcut Under Evaluation
⍝H ¯¯¯¯¯¯ ¯¯¯¯ ¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯ ¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯
⍝H         `T     Date-Time  {... [⍺] `T ⍵...} displays each date-time in Dyalog timestamp (⎕TS) format.
⍝H                ⍵: one or more APL timestamps (⎕TS)
⍝H                ⍺: Code for displaying timestamps based on Dyalog (1200⌶).
⍝H                   Default code/⍺: 'YYYY-MM-DD hh:mm:ss'
⍝H                The `T (Date-Time) helper function uses ⎕DT and (1200⌶):
⍝H                   [⍺] {⍺← 'YYYY-MM-DD hh:mm:ss' ⋄ ∊⍣(1=≡⍵)⊢⍺(1200⌶)⊢1 ⎕DT⊆⍵} ⍵  
⍝H                See examples below.   
⍝H 
⍝HX Examples
⍝HX ¯¯¯¯¯¯¯¯
⍝HX⍎⍝ Simple variable expressions
⍝HX⍎  name← 'Fred' ⋄ age← ?100
⍝HX⍎  ∆F 'The patient''s name is {name}. {name} is {age} years old.'
⍝HXThe patient's name is Fred. Fred is 32 years old.
⍝HX 
⍝HX⍎⍝ Variable and code expressions
⍝HX⍎  names← 'Mary' 'Jack' 'Tony' ⋄ prize← 100
⍝HX⍎  ∆F 'Customer {names⊃⍨ ?≢names} wins £{prize}!'
⍝HXCustomer Mary wins £12! 
⍝HX 
⍝HX⍎⍝ Some multi-line text fields separated by non-null space fields
⍝HX⍎  ∆F 'This`⋄is`⋄an`⋄example{ }Of`⋄multi-line{ }Text`⋄Fields'
⍝HXThis    Of         Text  
⍝HXis      multi-line Fields
⍝HXan                       
⍝HXexample 
⍝HX 
⍝HX⍎⍝ A similar example with strings in code fields
⍝HX⍎  ∆F '{"This`⋄is`⋄an`⋄example"}  {"Of`⋄Multi-line"}  {"Strings`⋄in`⋄Code`⋄Fields"}'
⍝HXThis     Of          Strings
⍝HXis       Multi-line  in     
⍝HXan                   Code   
⍝HXexample              Fields 
⍝HX   
⍝HX⍎⍝ Like the example above, with useful data
⍝HX⍎  fn←   'John'           'Mary'         'Bill'
⍝HX⍎  ln←   'Smith'          'Jones'        'Templeton'
⍝HX⍎  addr← '24 Mulberry Ln' '22 Smith St'  '12 High St'
⍝HX⍎  ∆F '{↑fn} {↑ln} {↑addr}'
⍝HXJohn Smith     24 Mulberry Ln
⍝HXMary Jones     22 Smith St   
⍝HXBill Templeton 12 High St 
⍝HX     
⍝HX⍎⍝ A slightly more interesting code expression, using the shorthand $ (⎕FMT).
⍝HX⍎  C← 11 30 60
⍝HX⍎  ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ 32+9×C÷5}°F'
⍝HXThe temperature is 11°C or  51.8°F
⍝HX                   30       86.0  
⍝HX                   60      140.0 
⍝HX  
⍝HX⍎⍝ Generating boxes using the shorthand `B (box).
⍝HX⍎  ∆F'`⋄The temperature is {`B⊂"I2" $ C}`⋄°C or {`B⊂"F5.1" $ 32+9×C÷5}`⋄°F'
⍝HX                   ┌──┐      ┌─────┐
⍝HXThe temperature is │11│°C or │ 51.8│°F
⍝HX                   │30│      │ 86.0│ 
⍝HX                   │60│      │140.0│ 
⍝HX                   └──┘      └─────┘    
⍝HX            
⍝HX⍎⍝ Referencing external expressions
⍝HX⍎  C← 11 30 60
⍝HX⍎  C2F← 32+9×5÷⍨⊢
⍝HX⍎  ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ C2F C}°F'
⍝HXThe temperature is 11°C or  51.8°F
⍝HX                   30       86.0  
⍝HX                   60      140.0 
⍝HX 
⍝HX⍎⍝ Referencing ∆F additional arguments using omega shorthand expressions.
⍝HX⍎  ∆F'The temperature is {"I2" $ `⍵1}°C or {"F5.1" $ C2F `⍵1}°F' (11 15 20)
⍝HXThe temperature is 11°C or  51.8°F
⍝HX                   15       59.0  
⍝HX                   20       68.0 
⍝HX
⍝HX⍎⍝ Use argument `⍵1 (i.e. 1⊃⍵) in a calculation.      Note: 'π²' is (⎕UCS 960 178) 
⍝HX⍎  ∆F 'π²={`⍵1*2}, π={`⍵1}' (○1)   
⍝HX π²=9.869604401, π=3.141592654
⍝HX 
⍝HX⍎⍝ "Horizontal" self-documenting code fields (source code shown to the left of the evaluated result).
⍝HX⍎  name←'John Smith' ⋄ age← 34
⍝HX⍎  ∆F 'Current employee: {name→}, {age→}.'
⍝HXCurrent employee: name→John Smith, age→34.
⍝HX
⍝HX⍎⍝ Note that spaces adjacent to self-documenting code symbols (→ or ↓ [alias %]) are mirrored in the output:
⍝HX⍎  name←'John Smith' ⋄ age← 34
⍝HX⍎  ∆F 'Current employee: {name → }, {age→   }.'
⍝HXCurrent employee: name → John Smith, age→   34.
⍝HX 
⍝HX⍎⍝ "Vertical" self-documenting code fields (the source code centered above the evaluated result)
⍝HX⍎  name←'John Smith' ⋄ age← 34
⍝HX⍎  ∆F 'Current employee: {name↓} {age↓}.'
⍝HXCurrent employee:   name↓    age↓.
⍝HX                  John Smith  34 
⍝HX 
⍝HX⍎⍝  Using the shorthand % (above) to display one expression centered above another 
⍝HX⍎  ∆F '{"Current Employee" % ⍪`⍵1}   {"Current Age" % ⍪`⍵2}' ('John Smith' 'Mary Jones')(29 23)
⍝HXCurrent Employee   Current Age
⍝HX   John Smith          29     
⍝HX   Mary Jones          23 
⍝HX 
⍝HX⍎⍝ Display arbitrary expressions one above the other.  
⍝HX⍎⍝ (See Shorthand Expressions for details on % and `⍵).
⍝HX⍎  ∆F'{(⍳2⍴`⍵) % (⍳2⍴`⍵) % (⍳2⍴`⍵)}' 1 2 3 
⍝HX    0 0      
⍝HX  0 0  0 1    
⍝HX  1 0  1 1    
⍝HX0 0  0 1  0 2 
⍝HX1 0  1 1  1 2 
⍝HX2 0  2 1  2 2  
⍝HX
⍝HX⍎⍝ Use of ∆F's box option (⍺[2+⎕IO]=1), which boxes each element in the formatted f-string.
⍝HX⍎  C← 11 30 60
⍝HX⍎  0 0 1 ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝HX┌───────────────────┬──┬──────┬─────┬──┐
⍝HX│                   │11│      │ 51.8│  │
⍝HX│The temperature is │30│°C or │ 86.0│°F│
⍝HX│                   │60│      │140.0│  │
⍝HX└───────────────────┴──┴──────┴─────┴──┘
⍝HX
⍝HX⍎⍝ Getting the best performance for a heavily used ∆F string.
⍝HX⍎⍝ Using the DFN option (⍺[0+⎕IO]=1).
⍝HX⍎⍝ Performance of an ∆F-string evaluated on the fly via (∆F ...) and precomputed via (1 ∆F ...): 
⍝HX⍎  'cmpx' ⎕CY 'dfns'
⍝HX⍎  C← 11 30 60
⍝HX⍎⍝ Here's our ∆F String <t>
⍝HX⍎  t←'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝HX⍎⍝ Precompute a dfn T given ∆F String <t>.
⍝HX⍎  T←1 ∆F t      ⍝ T← Generate a dfn w/o having to recompile (analyse) <t>. 
⍝HX⍎⍝ Compare the performance of the two formats: the precomputed version is over 4 times faster here.
⍝HX⍎  cmpx '∆F t' 'T ⍬'
⍝HX∆F t → 5.7E¯5 |   0% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
⍝HXT ⍬  → 1.4E¯5 | -76% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕   
⍝HX
⍝HX⍎⍝ Use of `T (Date-time) shortcut to show the current time (now).
⍝HX⍎     ∆F'It is now {"t:mm pp" `T ⎕TS}.'
⍝HX   It is now 8:08 am. 
⍝X 
⍝HX⍎⍝ Use of `T (Date-time) shortcut (see above for definition).
⍝HX⍎⍝ (Right arg "hardwired" into F-string)
⍝HX⍎  ∆F'{ "D MMM YYYY ''was a'' Dddd." `T 2025 01 01}'
⍝HX   1 JAN 2025 was a Wednesday.
⍝HX 
⍝HX⍎⍝ (Right argument via omega expression: `⍵1).
⍝HX⍎    ∆F'{ "D Mmm YYYY ''was a'' Dddd." `T `⍵1}' (2025 1 21)
⍝HX   21 Jan 2025 was a Tuesday.
⍝HX 
⍝HX⍎⍝ (Right args via omega expressions: `⍵ `⍵ `⍵).
⍝HX⍎    ∆F'{ "D Mmm YYYY ''was a'' Dddd." `T `⍵ `⍵ `⍵}' 1925 1 21
⍝HX   21 Jan 1925 was a Wednesday.
⍝HX   
⍝HX   
:EndNamespace 
