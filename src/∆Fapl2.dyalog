  ∇ result← {⍙F⍙opts} ∆F2 ⍙F⍙args ; ⍙Fapl2
  ⍝⍝⍝⍝ 10× slower than ∆F (q.v.). Abandon!
  ⍝⍝⍝⍝
  ⍝ The name of the utility function visible in the target directory.
  ⍝ === BEGINNING OF CODE =====================================================================
  ⍝ === BEGINNING OF CODE =====================================================================
     :With ⍙Fapl2←⎕NS '' 
        ⎕IO ⎕ML←0 1 
        DEBUG← 1 
         ⍝ A (etc): a dfn
        ⍝ cA (etc): [0] local absolute name of dfn (with spaces), [1] its code              
        ⍝ Abbrev  Meaning         Valence     User Shortcuts   Notes
        ⍝ A       [⍺]above ⍵      ambi       `A, %
        ⍝ B       box ⍵           ambi       `B
        ⍝ Ð       display ⍵       dyadic                       Var Ð only used internally...
        ⍝ F       [⍺] format ⍵    ambi       `F, $
        ⍝ M       merge[⍺] ⍵      ambi                         Var M only used internally...
        ⍝ T       ⍺ date-time ⍵   ambi       `T, `D  
          XR← ⎕THIS.⍎⊃∘⌽ 
          A← XR cA2← ' ⍙Fapl2.A ' '{⍺←⍬⋄⎕ML←1⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}' 
          B← XR cB2← ' ⍙Fapl2.B ' '{⍺←0⋄⎕ML←1⋄⍺⎕SE.Dyalog.Utils.disp⊂⍣(1≥≡⍵),⍣(0=≡⍵)⊢⍵}'  
          Ð← XR cÐ2← ' ⍙Fapl2.Ð ' ' 0∘⎕SE.Dyalog.Utils.disp¯1∘↓'                           
          F← XR cF2← ' ⎕FMT '    ' ⎕FMT '                                                
          M← XR cM2← ' ⍙Fapl2.M ' '{⍺←⊢⋄⎕ML←1⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}'                     
          T← XR cT2← ' ⍙Fapl2.T ' '{⍺←''YYYY-MM-DD hh:mm:ss''⋄∊⍣(1=≡⍵)⊢⍺(1200⌶)⊢1⎕DT⊆⍵}'  
          codeList←  cA2 cB2 cÐ2 cF2 cM2 cT2 
        ⍝ FmtScan: top level routine; the "main" function called by ∆F above. See the Executive section below.
        ⍝ result← [4↑ options] FmtScan f_string
          FmtScan← {  
          ⍝ Major Field Recursive Scanners: 
          ⍝    TF: text, CF: code fields and space fields, CFStr: (code field) quoted strings
          ⍝ TF: Text Field Scan 
          ⍝     (accum|'') ∇ str
          ⍝ Returns: null. Appends APL code strings to fldsG
            TF← {  
                p← TFBrk ⍵ 
              p= ≢⍵: TFDone ⍺, ⍵                               ⍝ No special chars in ⍵. Process & return.
                pfx← p↑⍵
              esc= p⌷⍵: (⍺, pfx, nlG TFEsc ⍵↓⍨ p+1)∇ ⍵↓⍨p+2    ⍝ char is esc. Process & continue.
                CSF ⍵↓⍨ p+1⊣ TFDone ⍺, pfx                     ⍝ char is lb. End TF; go to CSF.  
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
                    pfx c w← (⍺, p↑⍵) (p⌷⍵) (⍵↓⍨ p+1) 
                  c= sp:             (pfx, sp) ∇ w↓⍨ cfLenG+← p← +/∧\' '=w ⍝ Idiom +/∧\' '= 
                  c∊ sq_dq:          (pfx, a)  ∇ w⊣  cfLenG+← c⊣ a w c← CFStr c w    
                  c= dol:            (pfx, cF) ∇ w             ⍝ $ => ⎕FMT (cF)
                  c= esc:            (pfx, a)  ∇ w⊣ a w← CFEsc w
                (c= rb)∧ nBrakG≤ 1: (TrimR pfx) w             ⍝ Return... Scan complete!  
                  c∊ lb_rb:          (pfx, c) ∇ w⊣ nBrakG+← -/c= lb_rb  ⍝ Inc/dec nBrakG as appropriate
                  c= omUs:           (pfx, a)  ∇ w⊣ a w← CFOm w         ⍝ ⍹, alias to `⍵ (see CFEsc).
                ~c∊ '→↓%':          (pfx, c) ∇ w⊣ ⎕SIGNAL cfLogicÊ
                ⍝ We have one of '→', '↓', or '%'. 
                ⍝ See if [A] it's a pseudo-fn or [B] indicator of self-doc code field (SDCF).
                ⍝ [A] Pseudo-fn: "above" '%' or APL fns '→'¹ or '↓'. Keep scanning code field. 
                    p← +/∧\' '=w                         ⍝ ¹Note: In a dfn, only a bare → is valid!
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
          ⍝ val←  (⍺=nl) ∇ qt fstr 
          ⍝ Returns val← (the string at the start of ⍵) (the rest of ⍵) ⍝  
            CFStr← { qt w← ⍵   
                CFSBrk← ⌊/⍳∘(esc qt)                          ⍝ qt can be ' OR ".
                lenW← ¯1+ ≢w                                   ⍝ lenW: length of w outside quoted str.
                ⍙Scan← {   ⍝ Recursive CF Quoted-String Scan. lenW converges on true length.
                  0= ≢⍵: ⍺ 
                    p← CFSBrk ⍵  
                  p= ≢⍵: ⎕SIGNAL qtÊ
                  esc= p⌷⍵: (⍺, (p↑ ⍵), nlG QSEsc ⊃⍵↓⍨ p+1) ∇ ⍵↓⍨ lenW-← p+2 
                ⍝ qt= p⌷⍵, so now see if foll. char is a qt or not. 
                  qt= ⊃⍵↓⍨ p+1:  (⍺, ⍵↑⍨ p+1) ∇ ⍵↓⍨ lenW-← p+2   ⍝ Use APL rules for ".."".."
                    ⍺, ⍵↑⍨ lenW-← p                            ⍝ Done... Return
                }
                qS← AplQt '' ⍙Scan w                           ⍝ Update lenW via ⍙Scan, then update w. 
                qS (w↑⍨ -lenW) (lenW-⍨ ≢ w)                    ⍝ w is returned sans CF quoted string 
            } ⍝ End CF Quoted-String Scan
          ⍝ CFEsc:  
          ⍝    res← ∇ fstr
          ⍝ Returns:  code w                                   ⍝ ** Side Effects: Sets cfLenG, omIxG **
            CFEsc← {                                    
              0= ≢⍵:esc 
                c← 0⌷⍵ ⋄ w← 1↓⍵ ⋄ cfLenG+← 1   
              c∊ om_omUs: CFOm w                               ⍝ Permissively allow `⍹ as equiv to  `⍵ OR ⍹  
              c∊ 'ABFTD':  (codeABFTD⊃⍨ 'ABFTD'⍳ c) w          ⍝ Escape pseudo-fns `[ABFTD]. 
              c∊ lb_rb: c w                                    ⍝ `{ => {, `} => }  
                ⎕SIGNAL SeqÊ c                                 ⍝ esc-c has no meaning in CF for char c.
            } ⍝ End CFEsc 
          ⍝ *** CFOm: handler for `⍵, `⍵NNN,  ⍹, ⍹NNN (NNN a non-negative integer) ***
          ⍝ Deal with `⍵,⍹ with opt'l integer following.  
          ⍝ Errors handled by IntOpt (which returns valid oLen=0 if there are no valid digits at start of ⍵.) 
          ⍝                                                    ⍝ ** Side Effects: cfLenG, omIxG **  
            CFOm← {  oLen oVal w← IntOpt ⍵
              ×oLen: ('(⍵⊃⍨',')',⍨ '⎕IO+', ⍕omIxG⊢← oVal) w⊣ cfLenG+← oLen 
                    ('(⍵⊃⍨',')',⍨ '⎕IO+', ⍕omIxG       ) w⊣ omIxG+← 1
            }
        ⍝ ===========================================================================
        ⍝ FmtScan Executive begins here
        ⍝ ===========================================================================  
          0∊ ⍺∊ 0 1: ⎕SIGNAL optÊ                              ⍝ Bad options (⍺)!
            (dfn dbg box inline) fStr← ⍺ ⍵ 
            DM← (⎕∘←)⍣dbg                                      ⍝ DM: Debug Msg
            nlG← dbg⊃ ⎕UCS 13 9229                             ⍝ 9229 is ␍ (visible carriage return)
          ⍝ for meanings of A, B, Ð, F, M, T and D
            cA cB cÐ cF cM cT← inline⊃¨ codeList               ⍝ code fragments. 
            codeABFTD← cA cB cF cT cT                          ⍝ A: above, B: box, F: ⎕FMT, T or D: date-time. 
                                                              ⍝ `T is permissive alias to `D, date-time.
          ⍝ Pseudo-globals  camelCaseG 
          ⍝    fldsG-   global field list
            fldsG← ⍬
          ⍝    omIxG-   omega shortcut (`⍵, ⍹) current index  
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
          om← '⍵'
          dia← '⋄'               ⍝ Sequence esc-dia "`⋄" used in text fields and quoted strings for ⎕UCS 13.
          cfBrkList← sp sq dq dol esc lb rb omUs ra da pct← ' ''"$`{}⍹→↓%'  
          tfBrkList← esc lb
          sq_dq← sq dq ⋄ lb_rb← lb rb ⋄ om_omUs← om omUs ⋄ sp_sq← sp sq ⋄   esc_lb_rb← esc lb rb  

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

        ⍝ Help: Provides help info when ∆F⍨'help[x]' (OR 'help[x]'∆F anything) is specified.
        ⍝ (1 0⍴⍬)← Help 'help' OR 'helpx'
          Help← { 
            'help'≢⎕C 4↑ ⍵: ⎕SIGNAL optÊ 
              hP←  '(?ix) ^\s* ⍝H', ('X?'↓⍨ -'x'∊ ⎕C⍵), '(?| [⍎⎕]? (.*) | (⍝.*) )' 
              1 0⍴⍬⊣ ⎕ED ⍠'ReadOnly' 1⊢'h'⊣ h← hP ⎕S '\1'⊣ ⎕NR ⎕NSI 
          }
     :EndWith ⍝ ⍙Fapl2   
    :Trap 0/⍨ ⍙Fapl2.DEBUG        ⍝ Be sure this function is ⎕IO(etc.)-indep., since it will be promoted out of ⍙Fapl.
      :If 900⌶0 
          ⍙F⍙opts← ⍬
      :ElseIf 0≠ ⊃0⍴⍙F⍙opts          ⍝ If ⍙F⍙opts aren't all numeric, then Help will sort it out.
          result← ⍙Fapl2.Help ⍙F⍙opts ⍝ Help handles invalid options (⍙F⍙opts)
         :Return          
      :EndIf 
      ⍝(1+⊃⎕LC) ⎕STOP '#.∆F'
      :Select ⊃⍙F⍙opts← 4↑⍙F⍙opts       ⍝ FmtScan handles invalid options (⍙F⍙opts)  
        :Case 1                   ⍝ Returns executable dfn CODE generated from the f-string (if valid).
          result← (⊃⎕RSI)⍎ ⍙F⍙opts ⍙Fapl2.FmtScan ,⊃,⊆⍙F⍙args
        :Case ¯1                  ⍝ Undoc. option-- returns dfn code in string form. 
        ⍝ Useful for benchmarking compile-only step using dfns.cmpx.        
          result← (0,1↓⍙F⍙opts) ⍙Fapl2.FmtScan ,⊃,⊆⍙F⍙args  
        :Else                     ⍝ Handle 0 (valid) and other (invalid) options in FmtScan  
        ⍝ Returns matrix RESULT of evaluating the f-string.
        ⍝ "Hides" local vars, ¨⍙F⍙opts¨ and ¨⍙F⍙args¨, from embedded ⎕NL, etc.
          result← ⍙F⍙opts ((⊃⎕RSI){ ⍺⍺⍎ ⍺ ⍙Fapl2.FmtScan ,⊃⍵⊣ ⎕EX '⍙F⍙opts' '⍙F⍙args'}) ,⊆⍙F⍙args
      :EndSelect   
  :Else 
      ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨('∆F ',EM) EN Message)
  :EndTrap 
 
⍝ === END OF CODE ================================================================================
⍝ === END OF CODE ================================================================================

⍝ === BEGINNING OF HELP INFO =====================================================================
⍝ === BEGINNING OF HELP INFO =====================================================================
⍝H -------------
⍝H  ∆F IN BRIEF
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H ∆F is a function that makes it easy to format and display strings formatted from
⍝H text and code (from simple variables to arbitrary dfns) in an APL-friendly 
⍝H multi-line (matrix) style: 
⍝H   ∘ Text expressions can generate multi-line Unicode strings 
⍝H   ∘ Each code expression follows ordinary dfn conventions, with a few extensions, such as
⍝H     the availability of double-quoted strings, escaped chars, and simple formatting shortcuts for APL arrays. 
⍝H   ∘ All variables and code are evaluated (and, if desired, updated) in the user's calling environment,
⍝H     following dfn conventions for local and external variables.
⍝H   ∘ Formatting shortcuts for code include 
⍝H     - `B  boxing,                 
⍝H     -  $  concise control of numbers via a shortcut for ⎕FMT, 
⍝H     -  %  stacking one item of arbitrary shape above another, and 
⍝H     - `T  formatting of APL timestamps (⎕TS) via a shortcut combining ⎕DT and (1200⌶). 
⍝H +---------------------------------------------------------------------+
⍝H + ∘ ∆F is inspired by Python F-strings, but designed for APL arrays.  +
⍝H +---------------------------------------------------------------------+
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
⍝H       that starts with `⍵ or ⍹  
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
⍝H            If 1, returns a dfn that, when executed, returned a formatted matrix object, as for DFN=0.
⍝H       DBG: If 0, returns the value as above.
⍝H            If 1, displays the code generated from the f-string, before returning a value as above.
⍝H       BOX: If 0, returns the value as above.
⍝H            If 1, returns each field generated within a box (dfns "display"). 
⍝H    INLINE: If 0, ⍙F0 library routines A, B, D, F, and M will be used.
⍝H            If 1, the full code of A, B, D, F, and M are inserted "inline" to make the resulting runtime
⍝H            independent of the ⍙F0 namespace. This is mostly useful for returned dfns (DFN=1).
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
⍝H     ∘ ∆F displays f-string examples.
⍝H 
⍝H --------------
⍝H  ∆F IN DETAIL
⍝H --------------
⍝H 
⍝H The first element in the right arg to ∆F is a character vector, an "∆F string", 
⍝H which contains simple text, along with run-time evaluated expressions delimited by 
⍝H curly braces {} (unless preceded by an escape "`").
⍝H Each ∆F string is viewed as containing one or more "fields," catenated left to right,
⍝H each of which will display as a logically separate character matrix. 
⍝H ∘  ∆F adds no automatic spaces like those APL adds to denote object rank, etc.
⍝H ∘  ∆F assumes the user wants to control spacing of objects.
⍝H 
⍝H ∆F-string text fields (expressions) may include:
⍝H   ∘ escape sequences,  beginning with the escape character ("`"):
⍝H        "`⋄" => a newline;        "``" => "`"; 
⍝H        "`{" => "{"               "`}" => "}". 
⍝H     Otherwise, { and } delineate the start and end of a Code Field or Space Field,
⍝H     and other escape sequences will be treated literally, including the escape "`" prefix.
⍝H 
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
⍝H   ------- -- -------- -------
⍝H   Summary of Shortcut Symbols
⍝H   ------- -- -------- -------
⍝H      Format     Apply monadic or dyadic (⍺) ⎕FMT to ⍵
⍝H         $       APL ⎕FMT, formats simple numeric arrays.  [dyadic, monadic]
⍝H        `F       Alias for $   
⍝H      Box        Show ⍵ in a box.
⍝H        `B       A Box routine (⎕SE.Dyalog.disp), displays components of an APL object.  [monadic, dyadic]
⍝H      Above      Show ⍺ (or '') above ⍵
⍝H         %       A formatting routine, displaying the object to its left ('', if none) centered over the object to its right.
⍝H        `A       Alias for %
⍝H      Date-Time  Show APL timestamp as formatted date or time
⍝H        `T       Date-Time  {... [⍺] `T ⍵...} displays each date-time in Dyalog timestamp (⎕TS) format.
⍝H                 ⍵: one or more APL timestamps (⎕TS)
⍝H                 ⍺: Code for displaying timestamps based on Dyalog (1200⌶).
⍝H                    Default code/⍺: 'YYYY-MM-DD hh:mm:ss'
⍝H                 The `T (Date-Time) helper function uses ⎕DT and (1200⌶).
⍝H                 It is defined as: 
⍝H                    {⎕ML←1 ⋄ ⍺← 'YYYY-MM-DD hh:mm:ss' ⋄ ∊⍣(1=≡⍵)⊢⍺(1200⌶)⊢1 ⎕DT⊆⍵}   
⍝H                 See examples below.
⍝H        `D       Alias for `T (Date-Time)
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
⍝HX⍝ Set some values we'll need...
⍝HX⍎  ⎕RL ⎕IO ⎕ML←2342342 0 1
⍝HX⍝ Examples
⍝HX⍝ ¯¯¯¯¯¯¯¯
⍝HX⍝ Simple variable expressions
⍝HX⍎  name← 'Fred' ⋄ age← 43
⍝HX⍎  ∆F 'The patient''s name is {name}. {name} is {age} years old.'
⍝HX⎕The patient's name is Fred. Fred is 43 years old.
⍝HX 
⍝HX⍝ Variable and code expressions
⍝HX⍎  names← 'Mary' 'Jack' 'Tony' ⋄ prize← 1000
⍝HX⍎  ∆F 'Customer {names⊃⍨ ?≢names} wins £{?prize}!'
⍝HX⎕Customer Jack wins £80!   
⍝HX 
⍝HX⍝ Some multi-line text fields separated by non-null space fields
⍝HX⍎  ∆F 'This`⋄is`⋄an`⋄example{ }Of`⋄multi-line{ }Text`⋄Fields'
⍝HX⎕This    Of         Text  
⍝HX⎕is      multi-line Fields
⍝HX⎕an                       
⍝HX⎕example 
⍝HX 
⍝HX⍝ A similar example with strings in code fields
⍝HX⍎  ∆F '{"This`⋄is`⋄an`⋄example"}  {"Of`⋄Multi-line"}  {"Strings`⋄in`⋄Code`⋄Fields"}'
⍝HX⎕This     Of          Strings
⍝HX⎕is       Multi-line  in     
⍝HX⎕an                   Code   
⍝HX⎕example              Fields 
⍝HX   
⍝HX⍝ Like the example above, with useful data
⍝HX⍎  fn←   'John'           'Mary'         'Bill'
⍝HX⍎  ln←   'Smith'          'Jones'        'Templeton'
⍝HX⍎  addr← '24 Mulberry Ln' '22 Smith St'  '12 High St'
⍝HX⍎  ∆F '{↑fn} {↑ln} {↑addr}'
⍝HX⎕John Smith     24 Mulberry Ln
⍝HX⎕Mary Jones     22 Smith St   
⍝HX⎕Bill Templeton 12 High St 
⍝HX     
⍝HX⍝ A slightly more interesting code expression, using the shorthand $ (⎕FMT).
⍝HX⍎  C← 11 30 60
⍝HX⍎  ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ 32+9×C÷5}°F'
⍝HX⎕The temperature is 11°C or  51.8°F
⍝HX⎕                   30       86.0  
⍝HX⎕                   60      140.0 
⍝HX  
⍝HX⍝ Generating boxes using the shorthand `B (box).
⍝HX⍎  ∆F'`⋄The temperature is {`B⊂"I2" $ C}`⋄°C or {`B⊂"F5.1" $ 32+9×C÷5}`⋄°F'
⍝HX⎕                   ┌──┐      ┌─────┐
⍝HX⎕The temperature is │11│°C or │ 51.8│°F
⍝HX⎕                   │30│      │ 86.0│ 
⍝HX⎕                   │60│      │140.0│ 
⍝HX⎕                   └──┘      └─────┘    
⍝HX            
⍝HX⍝ Referencing external expressions
⍝HX⍎  C← 11 30 60
⍝HX⍎  C2F← 32+9×÷∘5    
⍝HX⍎  ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ C2F C}°F'
⍝HX⎕The temperature is 11°C or  51.8°F
⍝HX⎕                   30       86.0  
⍝HX⎕                   60      140.0 
⍝HX 
⍝HX⍝ Referencing ∆F additional arguments using omega shorthand expressions.
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
⍝HX⍝ "Horizontal" self-documenting code fields (source code shown to the left of the evaluated result).
⍝HX⍎  name←'John Smith' ⋄ age← 34
⍝HX⍎  ∆F 'Current employee: {name→}, {age→}.'
⍝HX⎕Current employee: name→John Smith, age→34.
⍝HX
⍝HX⍝ Note that spaces adjacent to self-documenting code symbols (→ or ↓ [alias %]) are mirrored in the output:
⍝HX⍎  name←'John Smith' ⋄ age← 34
⍝HX⍎  ∆F 'Current employee: {name → }, {age→   }.'
⍝HX⎕Current employee: name → John Smith, age→   34.
⍝HX 
⍝HX⍝ "Vertical" self-documenting code fields (the source code centered above the evaluated result)
⍝HX⍎  name←'John Smith' ⋄ age← 34
⍝HX⍎  ∆F 'Current employee: {name↓} {age↓}.'
⍝HX⎕Current employee:   name↓    age↓.
⍝HX⎕                  John Smith  34 
⍝HX⍝ ⍵[2]=1: Box all args (⎕IO=0).
⍝HX⍎  0 0 1 ∆F 'Current employee: {name↓} {age↓}.'
⍝HX⎕┌──────────────────┬──────────┬─┬────┬─┐
⍝HX⎕│Current employee: │  name↓   │ │age↓│.│
⍝HX⎕│                  │John Smith│ │ 34 │ │
⍝HX⎕└──────────────────┴──────────┴─┴────┴─┘
⍝HX 
⍝HX⍝ Using the shorthand % (above) to display one expression centered above another 
⍝HX⍎  ∆F '{"Current Employee" % ⍪`⍵1}   {"Current Age" % ⍪`⍵2}' ('John Smith' 'Mary Jones')(29 23)
⍝HX⎕Current Employee   Current Age
⍝HX⎕   John Smith          29     
⍝HX⎕   Mary Jones          23 
⍝HX 
⍝HX⍝ Display arbitrary expressions one above the other.  
⍝HX⍝ (See Shorthand Expressions for details on % and `⍵).
⍝HX⍎  ∆F'{(⍳2⍴`⍵) % (⍳2⍴`⍵) % (⍳2⍴`⍵)}' 1 2 3 
⍝HX⎕    0 0      
⍝HX⎕  0 0  0 1    
⍝HX⎕  1 0  1 1    
⍝HX⎕0 0  0 1  0 2 
⍝HX⎕1 0  1 1  1 2 
⍝HX⎕2 0  2 1  2 2  
⍝HX
⍝HX⍝ Use of ∆F's box option (⍺[2+⎕IO]=1), which boxes each element in the formatted f-string.
⍝HX⍎  C← 11 30 60
⍝HX⍎  0 0 1 ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝HX⎕┌───────────────────┬──┬──────┬─────┬──┐
⍝HX⎕│                   │11│      │ 51.8│  │
⍝HX⎕│The temperature is │30│°C or │ 86.0│°F│
⍝HX⎕│                   │60│      │140.0│  │
⍝HX⎕└───────────────────┴──┴──────┴─────┴──┘
⍝HX
⍝HX⍝ Getting the best performance for a heavily used ∆F string.
⍝HX⍝ Using the DFN option (initial option is 1 (in ⍺)), e.g. ¨1 ∆F ...¨
⍝HX⍝ > Let's look at the performance of an ∆F-string evaluated
⍝HX⍝   on the fly via ¨∆F ...¨ and precomputed via ¨1 ∆F ...¨: 
⍝HX⍎  'cmpx' ⎕CY 'dfns'
⍝HX⍎  C← 11 30 60
⍝HX⍝ Here's our ∆F String <t>
⍝HX⍎  t←'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝HX⍝ Precompute a dfn T given ∆F String <t>.
⍝HX⍎  T←1 ∆F t      ⍝ T← Generate a dfn w/o having to recompile (analyse) <t>. 
⍝HX⍝ Compare the performance of the two formats: the precomputed version is over ten times faster here.
⍝HX⍎  cmpx '∆F t' 'T ⍬'
⍝HX⎕  ∆F t → 1.7E¯4 |   0% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
⍝HX⎕  T ⍬  → 1.0E¯5 | -94% ⎕⎕ 
⍝HX
⍝HX⍝ Use of `T (Date-time) shortcut to show the current time (now).
⍝HX⍎  ∆F'It is now {"t:mm pp" `T ⎕TS}.'
⍝HX⎕It is now 8:08 am.      ⍝ <=== Time above will be different:  the actual time!
⍝HX 
⍝HX⍝ Use of `T (Date-time) shortcut (see above for definition).
⍝HX⍝ (Right arg "hardwired" into F-string)
⍝HX⍎  ∆F'{ "D MMM YYYY ''was a'' Dddd." `T 2025 01 01}'
⍝HX⎕1 JAN 2025 was a Wednesday.
⍝HX 
⍝HX⍝ (Right argument via omega expression: `⍵1).
⍝HX⍎  ∆F'{ "D Mmm YYYY ''was a'' Dddd." `T `⍵1}' (2025 1 21)
⍝HX⎕21 Jan 2025 was a Tuesday.
⍝HX 
⍝HX⍝ (Right args via omega expressions: `⍵ `⍵ `⍵).
⍝HX⍎  ∆F'{ "D Mmm YYYY ''was a'' Dddd." `T `⍵ `⍵ `⍵}' 1925 1 21
⍝HX⎕21 Jan 1925 was a Wednesday.
⍝HX   
⍝HX   