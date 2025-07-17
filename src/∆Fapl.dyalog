:namespace ⍙Fapl
  ⎕IO ⎕ML←0 1 
  fnVersion← '∆F'
⍝ === BEGINNING OF CODE =====================================================================
⍝ === BEGINNING OF CODE =====================================================================
  ∇ ⍙res← {⍙l} ∆F ⍙r; ⎕TRAP 
    ⎕TRAP← 0 'C' '⎕SIGNAL ⊂⎕DMX.(''EM'' ''EN'' ''Message'' ,⍥⊂¨(''∆F '',EM) EN Message)'
    :If 900⌶0 
        ⍙l← ⍬
    :ElseIf 0≠ ⊃0⍴⍙l
        ⍙res← ⎕THIS.Help ⍙l ⋄ :Return 
    :EndIf 
    :If 1= ⊃⍙l← 4↑⍙l      ⍝ Handle any invalid options in FmtScan   
     ⍝  Returns executable dfn CODE generated from the f-string (if valid).
        ⍙res← (⊃⎕RSI)⍎ ⍙l ⎕THIS.FmtScan ,⊃,⊆⍙r
    :Else                 ⍝ Handle any invalid options in FmtScan            
     ⍝  Returns matrix RESULT of evaluating the f-string.
        ⍙res← ⍙l ((⊃⎕RSI){ ⍺⍺⍎ ⍺ ⎕THIS.FmtScan ,⊃⍵⊣ ⎕EX '⍙l' '⍙r'}) ,⊆⍙r
    :EndIf  
  ∇

⍝ FmtScan: top level routine...
⍝ FmtScan: The "main" function for ∆Fre...
⍝ result← [4↑ options] FmtScan f_string
  FmtScan← {  
  ⍝ Major Field Recursive Scanners: 
  ⍝    TF: text, CF: code fields, SF: space, CFStr: (code field) quoted strings
  ⍝ TF: Text Field Scan 
    TF← {  
        p← ⍵ Break tfBreakList
      p= ≢⍵: NNTF ⍺, ⍵                                 ⍝ No special chars in remaining input string...
        pfx← p↑⍵
      esc= p⌷⍵: (⍺, pfx, nlG TFEsc ⍵↓⍨ p+1)∇ ⍵↓⍨p+2    ⍝ char is esc
        '' CF ⍵↓⍨ p ⊣ NNTF ⍺, pfx                      ⍝ char is lb  
    } ⍝ End Text Field Scan 
  ⍝ NNTF: Add only a non-null text field to fldsG (placing in quotes).
  ⍝ Ensure adjacent fields are sep by ≥1 blank. 
    NNTF← {0= ≢⍵: ⍬ ⋄ ⍬⊣ fldsG,← ⊂sp sq, sq,⍨ ⍵/⍨ 1+ sq= ⍵}    

  ⍝ CF: Code Field Scan  
    CF← { 
      cfIn← 1↓⍵                                        ⍝ in: skip leading '{'
      ⊃isSF a w nSp← (SF cfIn): a TF w                 ⍝ If a space field, finish up CF, start TF scan.
        nBrakG cfLenG⊢← 1 nSp
        Scan← {  ⍝ Recursive CF scan  
            p← ⍵ Break cfBreakList
            cfLenG+← p+1
          p= ≢⍵:  ⎕SIGNAL brÊ                          ⍝ Omitted right brace "}" 
            pfx ch w← (⍺, p↑⍵) (p⌷⍵) (⍵↓⍨ p+1) 
          ch= sp:             (pfx, sp) ∇ w↓⍨ p⊣ cfLenG+← p← +/∧\w= sp  
          ch∊ sq dq:          (pfx, a) ∇ w⊣ cfLenG+← c⊣ a w c← nlG CFStr ch w   ⍝ qt nl
          ch= dol:            (pfx, cF) ∇ w            ⍝ $ => ⎕FMT
          ch= esc:            (pfx, a) ∇ w⊣ cfLenG+← c⊣ omIxG⊢← o⊣ a w c o← omIxG inlineG CFEsc w⊣ cfLenG+← 1  
         (ch= rb)∧ nBrakG≤ 1: (TrimR pfx) w  
          ch∊ lb rb:          (pfx, ch) ∇ w⊣ nBrakG+← -/ch= lb rb
          ch= omUs:           (pfx, cod) ∇ w⊣ cfLenG+← c⊣ omIxG⊢← o⊣ cod w c o← omIxG Omg w     
          ch(~∊) '→↓%':       (pfx, ch) ∇ w⊣ ⎕←'Logic error'
        ⍝ We have '→', '↓', or '%'. 
        ⍝ See if [A] literal char or [B] indicator of self-doc code field.
            p← +/∧\w= sp 
        ⍝ [A] Literal char: pseudo-function "above" '%' or APL fns '→' '↓' 
          (rb≠ p⌷w)∨ nBrakG> 1: (pfx, ch cA⊃⍨ ch= pct) ∇ w  
        ⍝ [B] Self-Doc Code Field. 
        ⍝     '→' places the code str to the left of the result (cM) after evaluating the code str; 
        ⍝     '↓' and its alias '%' puts it above (cA) the result.
            codeStr← AplQt cfIn↑⍨ cfLenG+ p  
            fldsG,← ⊂'(', lb, codeStr, (cA cM⊃⍨ ch='→'), pfx, rb, '⍵)' 
            '' (w↓⍨ p+1)
        }
        a w← a Scan w
      0= ≢a: '' TF w 
        '' TF w⊣ fldsG,← ⊂'(', lb, a, rb, '⍵)'  
    } ⍝ End Code Field Scan
  ⍝ SF: Space Field Scan  
    SF← { ⍝ sfFlag pfx sfx nSp
      (nullF← rb= ⊃⍵)∨ sp≠⊃⍵: nullF '' (nullF↓ ⍵) 0      ⍝ nullF: {}, not a space field => CF
        nSp← +/∧\ ⍵= sp 
      nSp= ≢⍵: ⎕SIGNAL brÊ                               ⍝ Omitted right brace       
      rb≠ nSp⌷⍵: 0 '' (nSp↓⍵) nSp                        ⍝ Not a SF:    { sp sp code...}
        fldsG,← ⊂'(','⍴'''')',⍨ ⍕nSp                     ⍝ Non-null SF: { }, etc.
        1 '' (⍵↓⍨ 1+ nSp) nSp 
    } ⍝ End Space Field     

⍝ ===========================================================================
  ⍝ FmtScan Executive begins here
⍝ ===========================================================================  
  0∊ ⍺∊ 0 1: ⎕SIGNAL ⊂'EN' 11 ,⍥⊂ 'Message' 'Invalid option(s) in left argument'
    (dfn dbg box inlineG) fStr← ⍺ ⍵ 
    DM← (⎕∘←)⍣dbg                                      ⍝ DM: Debug Msg
    nlG← dbg⊃ ⎕UCS 13 9229                             ⍝ 9229: ␍ (visible carriage return)
    cA cB cD cF cM cT← inlineG⊃¨ cAll2 
  ⍝ Pseudo-globals 
  ⍝    fldsG-   global field list;
    fldsG← ⍬
  ⍝    omIxG-   omega shortcut (`⍵, ⍹) current index;  
  ⍝    nBrakG-  running count of braces '{' lb, '}' rb;
  ⍝    cfLenG-  code field running length  
    omIxG← nBrakG← cfLenG← 0 
  ⍝ Start the scan. We start with a (possibly null) text field.
    _← '' TF ⍵                                       
  0∧.= ≢ ¨fldsG: DM '(1 0⍴⍬)', dfn/'⍨'                 ⍝ If all fields are 0-length, return 1 by 0 matrix
     fldsG← OrderFlds fldsG                            
     code← '⍵',⍨ lb, rb,⍨ fldsG,⍨ box⊃ cM cD
  ~dfn: DM code                                        ⍝ Not a dfn. Emit code ready to execute
    quoted← ',⍨ ⊂', AplQt fStr                         ⍝ dfn: add quoted fmt string.
    DM lb, code, quoted, rb                            ⍝ emit dfn string ready to convert to dfn itself
  } ⍝ FmtScan 

⍝ Simple char constants
  om← '⍵'
  dia← '⋄'               ⍝ Sequence esc-dia "`⋄" used in text fields and quoted strings.
  cfBreakList← sp sq dq dol esc lb rb omUs ra da pct← ' ''"$`{}⍹→↓%'  
  tfBreakList← esc lb

⍝ Error constants  
    Ê← { ⊂'EN' 11,⍥⊂ 'Message' ⍵}
  brÊ←     Ê 'Unpaired brace'
  qtÊ←     Ê 'Unpaired quote (in code field)' 
  helpÊ←   Ê 'Invalid left argument. For help: ∆F⍨''help'''
  diaÊ←    Ê 'Escape sequence "`⋄" is invalid in a code field. Did you mean "⋄"?'

⍝ Other fns/ops for FmtScan above (no side effects). See also QSBreak
⍝ =========================================================================
⍝ These have NO side effects, so don't need to be in scope of FmtScan. 
⍝ =========================================================================
  Break←  ⌊/⍳ 
  TrimR←  { ⍵↓⍨ -+/∧\⌽⍵= sp}
⍝ IntOpt: Does ⍵ start with a valid integer? 
⍝ Returns len of integer or 0, the integer value or 0, ⍵ with the integer digits skipped.
  IntOpt← { wid (⊃⊃⌽⎕VFI wid↑⍵) (⍵↓⍨ wid← +/∧\⍵∊⎕D) }
⍝ AplQt:  Created an APL-style single-quoted string.
  AplQt←  { sq, sq,⍨ ⍵/⍨ 1+ sq= ⍵ }

⍝ Escape key Handlers: TFEsc CFEsc QSEsc  
⍝ *** No side effects ***
⍝ TFEsc: nl ∇ str, where 
⍝    nl is the current newline char and str starts with the char after the escape
⍝ Returns: the escape sequence.                      ⍝ *** No side effects ***
  TFEsc← { 0= ≢⍵: esc ⋄ ch← 0⌷⍵ ⋄ ch= dia: ⍺ ⋄ ch∊ esc, lb, rb: ch ⋄ esc, ch } 
  CFEsc← {  omIx inlineG← ⍺                          ⍝ *** No side effects ***
    0= ≢⍵:esc 
      ch← 0⌷⍵ ⋄ w← 1↓⍵
    ch∊ om omUs: omIx Omg w                          ⍝ Allow `⍹ as equiv to `⍵ and simple ⍹  
    ch∊ 'ABFT':  (('ABFT'⍳ ch) inlineG⊃ cABFT2) w omIx 0 ⍝ Escape pseudo-fns `[ABFT]
    ch∊ esc, lb, rb: ch w omIx 0                     ⍝ `` => `, `{ => {, `} => }  
    ch∊ dia:     ⎕SIGNAL diaÊ       
      (esc, ch) w omIx 0                             ⍝ Treat esc as literal
  } ⍝ End CFEsc 
  ⍝ QSEsc: [nl] ∇ str, where 
  ⍝         nl is the current newline char, and str startw with the char AFTER the escape char.
  ⍝ Returns the escape sequence.                     ⍝ *** No side effects ***
  QSEsc← { ch← ⍵ ⋄ ch= dia: ⍺ ⋄ esc, ch }     
  ⍝ CFStr: CF Quoted String Scan
  ⍝ val←  nl ∇ qt str 
  ⍝ Returns val← (the string at the start of ⍵) (the rest of ⍵) ⍝ *** No side effects ***
    CFStr← { nl← ⍺ ⋄ qt w← ⍵   
        wL← ¯1+ ≢w
        Scan← {   ⍝ Recursive CF String Scan. *** Modifies above-local wL ***  
          0= ≢⍵: ⍺ 
            p← ⍵ Break esc qt  
          p= ≢⍵: ⎕SIGNAL qtÊ
          esc= p⌷⍵: (⍺, (p↑ ⍵), nl QSEsc ⊃⍵↓⍨ p+1) ∇ ⍵↓⍨ wL-← p+2 
        ⍝ qt= p⌷⍵ 
          qt≠ ⊃⍵↓⍨ p+1:  ⍺, ⍵↑⍨ wL-← p 
            (⍺, ⍵↑⍨ p+1) ∇ ⍵↓⍨ wL-← p+2                ⍝ Use APL rules for ".."".."
        }
        qS← AplQt '' Scan w
        qS (w↑⍨ -wL) (wL -⍨ ≢ w )
    } ⍝ End CF Quoted String Scan
⍝ *** Omg: handler for `⍵, `⍵NNN,  ⍹, ⍹NNN (NNN a non-negative integer) ***
⍝ Deal with `⍵,⍹ with opt'l integer following.   NO SIDE EFFECTS 
  Omg← {  omg← ⍺ ⋄ oLen oVal w← IntOpt ⍵
    ×oLen: ('(⍵⊃⍨',')',⍨ '⎕IO+',⍕oVal) w oLen oVal   
           ('(⍵⊃⍨',')',⍨ '⎕IO+',⍕oVal) w oLen (oVal← omg+ 1)  
  }
⍝ OrderFlds
⍝ ∘ User flds are effectively executed L-to-R AND displayed in L-to-R order 
⍝   by ensuring there are at least two fields (one null, as needed), 
⍝   reversing their order now (at evaluation time), evaluating each field 
⍝   via APL ⍎ in turn R-to-L, then reversing again at execution time. 
  OrderFlds← '⌽',(∊∘⌽,∘'⍬') 

⍝ Help: Provides help info when ∆F⍨'help[x]' (OR 'help[x]'∆F anything) is specified.
⍝ (1 0⍴⍬)← Help 'help' OR 'helpx'
  Help← { 
    'help'≢⎕C 4↑ ⍵: ⎕SIGNAL helpÊ 
      hP←  '(?i)^\s*⍝H', ('X?'↓⍨ -'x'∊ ⎕C⍵), '⍎?(.*)' 
      1 0⍴⍬⊣ ⎕ED ⍠'ReadOnly' 1⊢'h'⊣ h← hP ⎕S '\1'⊣ ⎕SRC ⎕THIS  
  }

⍝ === FIX-time Routines ==========================================================================
⍝ === FIX-time Routines ==========================================================================
⍝ ⍙Promote_∆F (used internally only at FIX-time)
⍝ ∘ Copy ∆F, obscuring its local names and hardwiring the location of ⎕THIS. 
⍝ ∘ Fix this copy in the parent namsspace.
  ∇ rc← ⍙Promote_∆F fnVersion; src; snk 
    src←   '⎕THIS' '⍙(\w+)' 
    snk←  (⍕⎕THIS) '⍙Ⓕ⍙\1øø'
    rc← ##.⎕FX src ⎕R snk⊣ ⎕NR fnVersion
  ∇
⍝ LoadCode: At ⎕FIX time, load the run-time library names and code.  
⍝ For A, B, D, F, M; all like A example shown here:
⍝     A← an executable dfn in this namespace (⎕THIS).
⍝     cA2← name codeString, where
⍝          name is (⍕⎕THIS),'.A'
⍝          codeString is the executable dfn in string form.
⍝ At runtime, we'll generate cA, cB etc. based on flag ¨inlineG¨.
  ∇ {ok}← LoadCode 
      ;XR ;HT 
      XR← ⎕THIS.⍎⊃∘⌽                                   ⍝ Execute the right-hand expression
      HT← '⎕THIS' ⎕R (⍕⎕THIS)                          ⍝ "Hardwire" absolute ⎕THIS.  
  ⍝ A (etc): a dfn
  ⍝ cA (etc): [0] local absolute name of dfn (with spaces), [1] its code              ⍝               1-adic or 2-adic
    A← XR cA2← HT ' ⎕THIS.A ' '{⍺←⍬⋄⎕ML←1⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}' ⍝ A: [⍺]above ⍵     1, 2
    B← XR cB2← HT ' ⎕THIS.B ' '{⍺←0⋄⎕ML←1⋄⍺⎕SE.Dyalog.Utils.disp⊂⍣(1≥≡⍵),⍣(0=≡⍵)⊢⍵}'  ⍝ B: box ⍵          1, 2
    D← XR cD2← HT ' ⎕THIS.D ' '0∘⎕SE.Dyalog.Utils.disp¯1∘↓'                           ⍝ D: display ⍵          2
    F← XR cF2←    ' ⎕FMT '    ' ⎕FMT '                                                 ⍝ F: [⍺] format ⍵    1, 2
    M← XR cM2← HT ' ⎕THIS.M ' '{⍺←⊢⋄⎕ML←1⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}'                     ⍝ M: merge[⍺] ⍵      1, 2
    T← XR cT2← HT '⎕THIS.T'   '{⍺←''YYYY-MM-DD hh:mm:ss''⋄∊⍣(1=≡⍵)⊢⍺(1200⌶)⊢1⎕DT⊆⍵}'  ⍝ T:  ⍺ date-time ⍵   1, 2
    cABFT2← cA2 cB2 cF2 cT2
    cAll2←  cA2 cB2 cD2 cF2 cM2 cT2 
    ok← 1 
  ∇
⍝ Execute FIX-time routines
  ⍙Promote_∆F fnVersion
  LoadCode
 
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
⍝H                      ∆F⍨'help'                      Display help information for ∆F.
⍝H                      ∆F⍨'helpx'                     Display examples for ∆F.
⍝H 
⍝H F-string and args:
⍝H   first element: 
⍝H       an f-string, a single character vector (see "∆F IN DETAIL" below) 
⍝H   args:          
⍝H       elements of  ⍵ after the f-string, each of which can be accessed, via a shortcut 
⍝H       that starts with `⍵ or ⍹ (Table 1)
⍝H   result: If (0=⊃options), the result is always a character matrix. 
⍝H           If (1=⊃options), the result is a dfn that, when executed, generates a character matrix.
⍝H 
⍝H Left arg (⍺) to ∆F:   [ [ options← 0 [ 0 [ 0 [ 0 ] ] ] ] | 'help[x]' ]   
⍝H    If there is no left arg, 
⍝H         the default options (4⍴ 0) are assumed per below;
⍝H    If the left arg ⍺ is 0 to 4 non-negative integers,
⍝H         the options are taken as (4↑⍺);
⍝H    If the left arg is 'help' or 'helpx', ⍵ is ignored:  
⍝H      'help': ∆F display all help info, or 
⍝H      'helpx': ∆F display  help examples only, 
⍝H    and returns (1 0⍴⍬);
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
⍝H    INLINE: In DFN mode: If 0, ⍙F0 library routines A, B, D, F, and M will be used.
⍝H                         If 1, the CODE of A, B, D, F, and M are used "inline" to 
⍝H                         make the resulting runtime code independent of the ⍙F0 namespace.
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
⍝HX⍝ Examples
⍝HX⍝ ¯¯¯¯¯¯¯¯
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
⍝HX∆F t → 5.7E¯5 |   0$ ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
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
