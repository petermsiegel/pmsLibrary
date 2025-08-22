:Namespace ⍙Fapl
  ⎕IO ⎕ML←0 1 
  DEBUG← 0                   ⍝ DEBUG←1 simply turns off top-level error trapping...
  helpHtml← '∆F_Help.html'   ⍝ Globally set here
⍝ The name of the utility function visible in the target directory.
⍝ === BEGINNING OF CODE =====================================================================
⍝ === BEGINNING OF CODE =====================================================================
  ∇ result← {opts} ∆F args 
    :Trap 0/⍨ ~⎕THIS.DEBUG        ⍝ Be sure this function is ⎕IO(etc.)-indep., since it will be promoted out of ⍙Fapl.
      :If 900⌶0 
          opts← ⍬
      :ElseIf ~11 3∊⍨ 80|⎕DR opts ⍝ Here, just verify opts is a simple int or boolean obj.
        ⍝ If opts aren't simple boolean, then Help will sort it out.
          result← ⎕THIS.Help opts ⍝ Help handles invalid options (opts)
         :Return          
      :EndIf 
      :Select ⊃opts← 4↑opts       ⍝ FmtScan handles invalid options (opts)  
        :Case 1                   ⍝ Returns executable dfn CODE generated from the f-string (if valid).
          result← (⊃⎕RSI)⍎ opts ⎕THIS.FmtScan ,⊃,⊆args
        :Case ¯1                  ⍝ Undoc. option-- returns dfn code in string form. 
        ⍝ Useful for benchmarking compile-only step using dfns.cmpx.
        ⍝ Also, useful for later execution from a text array or file. 
        ⍝    (⍎¯1... ∆F ...)args <===> (1... ∆F ...)args     
          result← (1, 1↓opts) ⎕THIS.FmtScan ,⊃,⊆args  
        :Else                     ⍝ Handle 0 (valid) and other (invalid) options in FmtScan  
        ⍝ Returns matrix RESULT of evaluating the f-string.
        ⍝ "Hides" local vars, ¨opts¨ and ¨args¨, from embedded ⎕NL, etc.
          result← opts ((⊃⎕RSI){ ⍺⍺⍎ ⍺ ⎕THIS.FmtScan ,⊃⍵⊣ ⎕EX 'opts' 'args'}) ,⊆args
      :EndSelect   
  :Else 
      ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨('∆F ',EM) EN Message)
  :EndTrap 
  ∇

⍝ FmtScan: top level routine; the "main" function called by ∆F above. See the Executive section below.
⍝ result← [4↑ options] FmtScan f_string
  FmtScan← {  
  ⍝ Major Field Recursive Scanners: 
  ⍝    TF: text, CF: code fields and space fields, CFStr: (code field) quoted strings
  ⍝ TF: Text Field Scan 
  ⍝     (accum|'') ∇ str
  ⍝ Returns: null. Appends APL code strings to fldsG
    TF← {  
        p← TFBrk ⍵                                     ⍝ esc or lb only. 
      p= ≢⍵: TFDone ⍺, ⍵                               ⍝ No special chars in ⍵. Process & return.
        pfx c w← (p↑⍵) (p⌷⍵) (⍵↓⍨ p+1) 
      c= esc: (⍺, pfx, nlG TFEsc w) ∇ 1↓ w             ⍝ char is esc. Process & continue.
    ⍝ c= cr:  (⍺, pfx, nlG) ∇ w                        ⍝ actual cr => nlG, mirroring esc+⋄ => nlG. 
        CSF w⊣ TFDone ⍺, pfx                           ⍝ char is lb. End TF; go to CSF.  
    } ⍝ End Text Field Scan 
  ⍝ TFDone: If a text field is not 0-length, place in quotes and add it to fldsG.
  ⍝ Ensure adjacent fields are sep by ≥1 blank.
    TFDone← {0≠ ≢⍵: 0⊣ fldsG,← ⊂sp_sq, sq,⍨ ⍵/⍨ 1+ sq= ⍵ ⋄ ⍬}    

  ⍝ CSF: Code / Space Field Scan (monadic only). 
  ⍝ Called by TF. Checks for a possible space field (SF), i.e. {} or { }, {  }, etc. 
  ⍝     res← ∇ str, where str already skips the leading '{' of the CF. 
  ⍝ Returns: null. Appends APL code strings to fldsG. Sets/modifies nBrakG, cfLenG.
    CSF← {                                              
        cfSaveË← w← ⍵                                  ⍝ Save the start of the CF (in case SDCF: self-doc CF)
      rb= ⊃w: '' TF 1↓ w                               ⍝ If {}, we have a null SF. No code gen'd. [FAST]
        w↓⍨← nSp← +/∧\' '= w                           ⍝ Count/skip over (≥0) leading spaces...
      rb= ⊃w: '' TF 1↓ w⊣ fldsG,← ⊂SFCodeGen ⍕nSp      ⍝ If we now see a '}', we have an SF. Done.
        nBrakG cfLenG⊢← 1 nSp                          ⍝ No, we have a true CF. Keep going.
        ⍙Scan← {                                       ⍝ Recursive CF scan. Modifies cfLenG, nBrakG.  
            p← CFBrk ⍵
            cfLenG+← p+1
          p= ≢⍵:  ⎕SIGNAL brÊ                          ⍝ Missing right brace "}"! 
            pfx c w← (⍺, p↑⍵) (p⌷⍵) (⍵↓⍨ p+1)          ⍝ Some cases below are ordered! 
          c= sp:             (pfx, sp) ∇ w↓⍨ cfLenG+← p← +/∧\' '=w ⍝ Idiom +/∧\' '= 
         (c= rb)∧ nBrakG≤ 1: (TrimR pfx) w             ⍝ Return... Scan complete! 
          c∊ lb_rb:          (pfx, c) ∇ w⊣ nBrakG+← -/c= lb_rb  ⍝ Inc/dec nBrakG as appropriate
          c∊ qtsL:          (pfx, a)  ∇ w⊣  cfLenG+← c⊣ a w c← CFStr c w    
          c= dol:            (pfx, cF) ∇ w             ⍝ $ => ⎕FMT (cF)
          c= esc:            (pfx, a)  ∇ w⊣ a w← CFEsc w          
          c= omUs:           (pfx, a)  ∇ w⊣ a w← CFOm w         ⍝ ⍹, alias to `⍵ (see CFEsc).
         ~c∊ '→↓%':          ⎕SIGNAL cfLogicÊ
        ⍝ We have one of '→', '↓', or '%'. 
        ⍝ See if [A] it's a pseudo-fn or [B] indicator of self-doc code field (SDCF).
        ⍝ [A] Pseudo-fn: "above" '%' or APL fns '→'¹ or '↓'. Keep scanning code field. 
            p← +/∧\' '=w                         ⍝ ¹However unlikely: In a dfn stmt, only a bare → is valid!
          (rb≠ ⊃p↓w)∨ nBrakG> 1: (pfx, c cA⊃⍨ c= pct) ∇ w  
        ⍝ [B] SDCF (char /→|↓|%/ is foll. by /\s*\}/ and /\}/ is code field final). 
        ⍝     '→' places the code str to the left of the result (cM) after evaluating the code str; 
        ⍝     '↓' and its alias '%' puts it above (cA) the result.
            codeStr← AplQt cfSaveË↑⍨ cfLenG+ p         ⍝ Grab literal CF as self-doc CF string. 
        ⍝ codeStr will be placed to left of (→) or above (↓ or %) evaluated code.
            (codeStr, (cA cM⊃⍨ c='→'), pfx) (w↓⍨ p+1)  ⍝ Return: Scan complete!  
        }
        a w← '' ⍙Scan w
        '' TF w⊣ fldsG,← ⊂'(', lb, a, rb, '⍵)'         ⍝ Process & back to TF
    } ⍝ End Code Field Scan
  ⍝ SFCodeGen: Generate a SF code string; ⍵ is non-null. (Used in CSF above)
    SFCodeGen← '(',⊢ ⊢,∘'⍴'''')'  

  ⍝ CFStr: CF Quoted String Scan
  ⍝        val←  (⍺=nl) ∇ qtL fstr 
  ⍝ ∘ Right now, qtL must be ', ", or «, and qtR must be ', ", or ». 
  ⍝ ∘ For quotes with different starting and ending chars, e.g. «» (⎕UCS 171 187).
  ⍝   If « is the left qt, then the right qt » can be doubled in the APL style, 
  ⍝   and a non-doubled » terminates as expected.
  ⍝ Returns val← (the string at the start of ⍵) (the rest of ⍵) ⍝  
    CFStr← { qtL w← ⍵ ⋄ qtR← qtsR⌷⍨ qtsL⍳ qtL
        CFSBrk← ⌊/⍳∘(esc qtR)                        ⍝ qtL can be ', ", or «. 
        lenW← ¯1+ ≢w                                  ⍝ lenW: length of w outside quoted str.
        ⍙Scan← {   ⍝ Recursive CF Quoted-String Scan. lenW converges on true length.
          0= ≢⍵: ⍺ 
            p← CFSBrk ⍵  
          p= ≢⍵: ⎕SIGNAL qtÊ ⋄ c← p⌷⍵
          c= esc: (⍺, (p↑ ⍵), nlG QSEsc ⊃⍵↓⍨ p+1) ∇ ⍵↓⍨ lenW-← p+2 
        ⍝ Now c= qtR:  Now see if c2, the next char, is a second qtR, 
        ⍝ i.e. an internal, literal qtR.
            c2← ⊃⍵↓⍨ p+1
          c2= qtR:  (⍺, ⍵↑⍨ p+1) ∇ ⍵↓⍨ lenW-← p+2    ⍝ Use APL rules for ".."".."
            ⍺, ⍵↑⍨ lenW-← p                            ⍝ Done... Return
        }
        qS← AplQt '' ⍙Scan w                           ⍝ Update lenW via ⍙Scan, then update w. 
        qS (w↑⍨ -lenW) (lenW-⍨ ≢ w)                    ⍝ w is returned sans CF quoted string 
    } ⍝ End CF Quoted-String Scan
  ⍝ CFEsc: Handle escapes  in Code Fields OUTSIDE of CF-Quotes.
  ⍝    res← ∇ fstr
  ⍝ Returns:  code w                                    ⍝ ** Side Effects: Sets cfLenG, omIxG **
    CFEsc← {                                    
      0= ≢⍵: esc 
        c w← (0⌷⍵) (1↓⍵) ⋄ cfLenG+← 1   
      c∊ om_omUs: CFOm w                               ⍝ Permissively allow `⍹ as equiv to  `⍵ OR ⍹  
      c∊ lb_rb: c w                                    ⍝ `{ => {, `} => }  
      nEPF> p← MapEPF c: (p⊃ epfCode) w                ⍝ EPF: Escape pseudo-fns `[ABFTD]. 
        ⎕SIGNAL SeqÊ c                                 ⍝ esc-c has no meaning in CF for char c.
    } ⍝ End CFEsc 
  ⍝ *** CFOm: handler for `⍵, `⍵NNN,  ⍹, ⍹NNN (NNN a non-negative integer) ***
  ⍝ Deal with `⍵,⍹ with opt'l integer following.  
  ⍝ Errors handled by IntOpt (which returns valid oLen=0 if there are no valid digits at start of ⍵.) 
  ⍝                                                    ⍝ ** Side Effects: cfLenG, omIxG **  
    CFOm← { oLen oVal w← IntOpt ⍵
      ×oLen: ('(⍵⊃⍨',')',⍨ '⎕IO+', ⍕omIxG⊢← oVal) w⊣ cfLenG+← oLen 
             ('(⍵⊃⍨',')',⍨ '⎕IO+', ⍕omIxG       ) w⊣ omIxG+← 1
    }
⍝ ===========================================================================
⍝ FmtScan Executive begins here
⍝ ===========================================================================  
  0∊ ⍺∊ 0 1: ⎕SIGNAL optÊ                              ⍝ Bad options (⍺)!
    (dfn dbg box inline) fStr← ⍺ ⍵ 
    DM← (⎕∘←)⍣dbg                                      ⍝ DM: Debug Msg
    nlG← dbg⊃ cr crVis                                 ⍝ A newline escape (`⋄) maps onto crVis if debug mode.
  ⍝ Pseudo-functions: A, B, Ð, F, M, T and D
    cA cB cC cÐ cF cM cT← inline⊃¨ codeList            ⍝ code fragments.
    epfCode← cA cB cC cF cT cT                         ⍝ A B F T T <== esc+ 'ABFTD'
  ⍝ `A => above, `B => box, `F => ⎕FMT, `T or `D => date-time.  
 
  ⍝ Pseudo-globals  camelCaseG 
  ⍝    fldsG-   global field list
    fldsG← ⍬
  ⍝    omIxG-   omega index counter: current index for omega shortcuts (`⍵, ⍹)  
  ⍝    nBrakG-  running count of braces '{' lb, '}' rb
  ⍝    cfLenG-  code field running length (used when a self-doc code field (q.v.) occurs)  
    omIxG← nBrakG← cfLenG← 0 
  
  ⍝ Start the scan                                     ⍝ We start with a (possibly null) text field, 
    _← '' TF ⍵                                         ⍝ recursively calling CSF and (from CSF) SF & TF itself, &
                                                       ⍝ ... setting fields ¨fldsG¨ as we go.
  0= ≢fldsG: DM '(1 0⍴⍬)', dfn/'⍨'                     ⍝ If there are no flds, return 1 by 0 matrix
    fldsG← OrderFlds fldsG                             ⍝ We will evaluate fields L-to-R
    code← '⍵',⍨ lb, rb,⍨ fldsG,⍨ box⊃ cM cÐ
  ~dfn: DM code                                        ⍝ Not a dfn. Emit code ready to execute
    quoted← ',⍨ ⊂', AplQt fStr                         ⍝ dfn: add quoted fmt string.
    DM lb, code, quoted, rb                            ⍝ emit dfn string ready to convert to dfn itself
  } ⍝ FmtScan 

⍝ Simple char constants
⍝ Note: we handle two kinds of quotes: 
⍝     std same-char quotes, 'this' and "this", with std APL-style doubling.
⍝     left- and right-quotes, «like this», where only the right-quote doubling is needed
⍝     (i.e. any number of literals « can be in a «» string.)
⍝ The use of double angle quotation marks is an amusement. So far, not documented...
  om← '⍵' ⋄ cr crVis← ⎕UCS 13 9229 
  dia← '⋄'               ⍝ Sequence esc-dia "`⋄" used in text fields and quoted strings for ⎕UCS 13.
⍝ lDAQ, rDAQ: LEFT- and RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK -- aka guillemets  
  lDAQ rDAQ← '«»'        ⍝ ⎕UCS 171 187 
⍝ Order brklist chars roughly by frequency, high to low.       
  cfBrkList← lDAQ,⍨ sp sq dq esc lb rb dol omUs ra da pct← ' ''"`{}$⍹→↓%'  
  tfBrkList← esc lb                
  lb_rb← lb rb ⋄ om_omUs← om omUs ⋄ sp_sq← sp sq ⋄   esc_lb_rb← esc lb rb  
  qtsL← sq dq lDAQ ⋄ qtsR← sq dq rDAQ 

⍝ Error constants / fns  
    Ê← { ⊂'EN' 11,⍥⊂ 'Message' ⍵ }
  brÊ←      Ê 'Unpaired brace "{"'
  qtÊ←      Ê 'Unpaired quote (''"'' or "''") in code field' 
  cfLogicÊ← Ê 'A logic error has occurred processing a code field'
  optÊ←     Ê 'Invalid option(s) in left argument. For help: ∆F⍨''help'''
  SeqÊ←     Ê {'Sequence "`',⍵,'" is not valid in code outside strings. Did you mean "',⍵,'"?'}

⍝ Other fns/ops for FmtScan above (no side effects). 
⍝ =========================================================================
⍝ These have NO side effects, so need not be in the scope of FmtScan. 
⍝ =========================================================================
⍝ See also CFSBrk
  TFBrk← ⌊/⍳∘tfBrkList
  CFBrk← ⌊/⍳∘cfBrkList

  TrimR←  ⊢↓⍨-∘(⊥⍨sp=⊢)                                ⍝ { ⍵↓⍨ -+/∧\⌽⍵= sp}
⍝ IntOpt: Does ⍵ start with a valid sequence of digits (a non-neg integer)? 
⍝ Returns 2 integers and a string: 
⍝   [0] len of sequence of digits (pos integer) or 0, 
⍝   [1] the integer value found or 0, 
⍝   [2] ⍵ after skipping the prefix of digits, if any.
⍝ If [0] is 0, then there was no prefix of digits. If there was, then it will be >0.
  IntOpt← { wid← +/∧\ ⍵∊⎕D ⋄ wid (⊃⊃⌽⎕VFI wid↑ ⍵) (wid↓ ⍵) }  ⍝ Idiom +/∧\
⍝ AplQt:  Created an APL-style single-quoted string.
  AplQt←  sq∘(⊣,⊣,⍨⊢⊢⍤/⍨1+=)                           ⍝ { sq, sq,⍨ ⍵/⍨ 1+ sq= ⍵ }

⍝ Escape key Handlers: TFEsc QSEsc   (CFEsc, with side effects, is within FmtScan)
⍝ *** No side effects *** 
⍝ TFEsc: nl ∇ fstr, where 
⍝    nl: current newline char;  fstr: starts with the char after the escape
⍝ Returns: the escape sequence.                        ⍝ *** No side effects ***
  TFEsc← { 0= ≢⍵: esc ⋄ c← 0⌷⍵ ⋄ c= dia: ⍺ ⋄ c∊ esc_lb_rb: c ⋄ esc, c } 
  ⍝ QSEsc: [nl] ∇ fstr, where 
  ⍝         nl is the current newline char, and fstr starts with the char AFTER the escape char.
  ⍝ Returns the escape sequence.                       ⍝ *** No side effects ***
  QSEsc← { c← ⍵ ⋄ c= dia: ⍺ ⋄ c=esc: c ⋄ esc, c }     

⍝ OrderFlds
⍝ ∘ User flds are effectively executed L-to-R AND displayed in L-to-R order 
⍝   by ensuring there are at least two fields (one null, as needed), 
⍝   reversing their order now (at evaluation time), evaluating each field 
⍝   via APL ⍎ in turn R-to-L, then reversing again at execution time. 
  OrderFlds← '⌽',(∊∘⌽,∘'⍬') 

⍝ Help: Provides help info when ∆F⍨'help[x]' (OR 'help[x]'∆F anything) is specified.'
⍝ (1 0⍴⍬)← Help 'help'
  Help← { 
    'help'≢ 4↑o←⎕C⍵: ⎕SIGNAL optÊ 
    HROpt← ('HTML'  (⊃⎕NGET helpHtml)) (900 900,⍨ ⊂'Size') (5 5,⍨ ⊂'Posn') ('Coord' 'ScaledPixel')
    _← 'htmlObj' ⎕THIS.⎕WC 'HTMLRenderer',⍥⊆ HROpt           ⍝ Run HTMLRenderer
    1 0⍴⍬
  }  

⍝ === FIX-time Routines ==========================================================================
⍝ === FIX-time Routines ==========================================================================
⍝ ⍙Promote_∆F (used internally only at FIX-time)
⍝ ∘ Copy ∆F, obscuring its local names and hardwiring the location of ⎕THIS. 
⍝ ∘ Fix this promoted copy in the parent namespace.
  ∇ rc← ⍙Promote_∆F ; src; snk; rOpt    
    src←    '⎕THIS'     'result'    'opts'    'args' 
    snk←   (⍕⎕THIS)  '⍙Ⓕrësült' '⍙Ⓕöpts' '⍙Ⓕärgs'
    rOpt←  'UCP' 1
    rc← ##.⎕FX src ⎕R snk ⍠ rOpt⊣ ⎕NR '∆F'
  ∇
⍝ ⍙LoadCode: At ⎕FIX time, load the run-time library names and code.  
⍝ For A, B, D, F, M; all like A example shown here:
⍝     A← an executable dfn in this namespace (⎕THIS).
⍝     cA2← name codeString, where
⍝          name is (⍕⎕THIS),'.A'
⍝          codeString is the executable dfn in string form.
⍝ At runtime, we'll generate cA, cB etc. based on flag ¨inline¨.
  ∇ {ok}← ⍙LoadCode 
          ;XR ;HT; cA2; cB2; cC2; cPre; cSrc; cSnk; cCda; cÐ2; cF2; cM2; cT2; epf   
    XR← ⎕THIS.⍎⊃∘⌽                                   ⍝ Execute the right-hand expression
    HT← '⎕THIS' ⎕R (⍕⎕THIS)                          ⍝ "Hardwire" absolute ⎕THIS.  
  ⍝ A (etc): a dfn
  ⍝ cA (etc): [0] local absolute name of dfn (with spaces), [1] its code              
  ⍝ Abbrev  Meaning         Valence     User Shortcuts   Notes
  ⍝ A       [⍺]above ⍵      ambi       `A, %
  ⍝ B       box ⍵           ambi       `B
  ⍝ C       commas          monadic     `C               Experimental...
  ⍝ Ð       display ⍵       dyadic                       Var Ð only used internally...
  ⍝ F       [⍺] format ⍵    ambi       `F, $
  ⍝ M       merge[⍺] ⍵      ambi                         Var M only used internally...
  ⍝ T       ⍺ date-time ⍵   ambi       `T, `D  
    A← XR cA2← HT   ' ⎕THIS.A ' '{⍺←⍬⋄⎕ML←1⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}' 
    B← XR cB2← HT   ' ⎕THIS.B ' '{⍺←0⋄⎕ML←1⋄⍺⎕SE.Dyalog.Utils.disp⊂⍣(1≥≡⍵),⍣(0=≡⍵)⊢⍵}' 
      cPre←  '{⎕FR ⎕PP← 1287 34⋄'
      cSrc←   't←''[.Ee].*$'' ''(?<=\d)(?=(\d{3})+([-¯.Ee]|$))''' 
      cSnk←   '⎕R''&'' '',&'''
      cCda←   '⍕¨⍵⋄1=≢⍵:⊃t⋄t}'
    C← XR cC2← HT   ' ⎕THIS.C '  ( cPre, cSrc, cSnk, cCda )
    Ð← XR cÐ2← HT   ' ⎕THIS.Ð ' ' 0∘⎕SE.Dyalog.Utils.disp¯1∘↓'                           
    F← XR cF2←      ' ⎕FMT '    ' ⎕FMT '                                                
    M← XR cM2← HT   ' ⎕THIS.M ' '{⍺←⊢⋄⎕ML←1⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}'                     
    T← XR cT2← HT   ' ⎕THIS.T ' '{⍺←''YYYY-MM-DD hh:mm:ss''⋄∊⍣(1=≡⍵)⊢⍺(1200⌶)⊢1⎕DT⊆⍵}'  
    codeList←        cA2 cB2 cC2 cÐ2 cF2 cM2 cT2    
    nEPF← ≢  epf← 'ABCFTD'                           ⍝ epf: Escape Pseudo-Fns (see) 
    MapEPF←  epf∘⍳ 
    ok← 1 
  ∇
⍝ Execute FIX-time routines
  ⍙Promote_∆F  
  ⍙LoadCode
 
⍝ === END OF CODE ================================================================================
⍝ === END OF CODE ================================================================================
:EndNamespace 
