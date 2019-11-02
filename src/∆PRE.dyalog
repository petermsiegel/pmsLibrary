:namespace ∆PREns
⍝ ∆PRE - For all documentation, see ∆PRE.help in (github) Docs.
  ∆PRE←{⍺←''
    __DEBUG__←1
    999×__DEBUG__:: ⎕SIGNAL/⎕DMX.(('∆PRE ',EM) EN)
  ⍝ Syntax:  I.  ⍺ ∆PRE line1 « line2 ... »
  ⍝         II.  ⍺ ∆PRE « function_name | ⎕NULL »
  ⍝  I. ⍺ ∆PRE line1 line2 ...
  ⍝  Syntax:  [1 | 0 | ¯1 ] ∆PRE line1 line2 ...
  ⍝  ⍺=0,1: Evaluate ⍵: vector of strings, returning processed strings.
  ⍝      0: Removes all comments, including generated preprocessor comments.
  ⍝         Use:  ⍎¨0 ∆PRE line1 line2 ...
  ⍝         Executes each executable line lineN in turn.
  ⍝      1: Generates preprocessor comments and keeps user comments.
  ⍝         Use: ↑1 ∆PRE line1 line2 ...
  ⍝         Displays all output lines, comments or executable...
  ⍝     ¯1: Same as ↑1 ∆PRE line1 line2 ...
  ⍝
  ⍝  II. ⍺ ∆PRE « function_name | ⎕NULL »
  ⍝  String options:  ⍺ a single string vector, with any of the options below,
  ⍝         case is ignored and all options can be abbreviated or prefixed with "no".
  ⍝
  ⍝     Option     Default   Min     Variable      Info
  ⍝     -Verbose   -NoV      -V      __VERBOSE__   Provide preproc. info in output file
  ⍝     -Debug     -NoD      -D      __DEBUG__     Share additional debugging info on terminal!
  ⍝     -NoComment -Com      -C      NOCOM         Delete Comments
  ⍝     -NoBlanks  -Blanks   -B      NOBLANK       Remove Blank output lines
  ⍝     -Edit      -NoEdit   -E      EDIT          If 1, edit the intermediate file (for viewing only)
  ⍝     -Quiet     -NOQuiet  -Q      QUIET         1 if neither DEBUG nor VERBOSE
  ⍝     -Fix       -NOFix    -F      FIX           If 1, create an output function via ⎕FIX.
  ⍝     -Help      -NOHelp   -H      HELP          If 1, share HELP info rather than preprocessing.   
  
    0≡⍺:'  -noFix -noVerbose -noComments'∇ ⍵    
    1≡⍺:'  -noFix   -Verbose' ∇ ⍵ 
    ¯1≡⍺:↑'-noFix   -Verbose' ∇ ⍵ 

  ⍝ Syntax: [ '-v' ] ∆PRE ⎕NULL                
  ⍝     Prompt user for lines, ending prompt with null (not blank) line:
  ⍝     After execution, you are placed in the editor to view the processed lines...
  ⍝     Use -v to see helpful preprocessor comments; omit -v to see only executables (user comments preserved).

    ⍝ Move execution into a private NS so we don't worry about name conflicts.
    ⍝ We'll explicitly save objects in ∆CALLR ns or ∆MY ns (see ⎕MY macro)
      (⊃⊆,⍺)(⎕NS'').{
        ⎕IO ⎕ML ⎕PP ⎕FR←0 1 34 1287
      ⍝ isSpecialMacro ⍵: Special macros include dunder (__) vars defined here.
      ⍝ When a user DEFs these macros (read or write), ∆PRE will see them
      ⍝ as their corresponding local variables of the same name
      ⍝ See Executive (below) for meanings.
      ⍝ Note: Don't define any vars starting with '_' here or above!
      ⍝  ::EXTERN (Variables global to ∆PRE, but not above)
      ⍝ -------------------------------------------------------------------
        __DEBUG__←__VERBOSE__←__INCLUDE_LIMITS__←¯1    ⍝ ¯1 simply declare the scope of these items.
        __MAX_EXPAND__←__MAX_PROGRESSION__←¯1
        isSpecialMacro←(∊∘(' '~⍨¨↓'_'⎕NL 2))∘⊂
      ⍝ Use NL   for all newlines to be included in the ∆PRE output.
      ⍝ Use CR   in error msgs going to ⎕ (APL (mis)treats NL as a typewriter newline)
      ⍝ Use NULL internally for special code lines (NULLs are removed at end)
        NL CR NULL←⎕UCS 10 13 0
        SQ SQ2 DQ SQDQ←'''' '''''' '"' '''"' ⋄ NUMFIRST←⎕D,'-¯'
        ∆CALLR←1⊃⎕RSI,#            ⍝ The caller is the 2nd arg of ⎕RSI
        TRANSLATE←⎕NS ''
        TRANSLATE.(in←out←⍬)

      ⍝ General utilities...
        lc←819⌶ ⋄ uc←1∘(819⌶)
        opt←(lc,⍺)∘{w←'-',lc ⍵ ⋄ 1∊w⍷⍺}                  ⍝ ⍺: options passed by user
        trimLR←{⍺←' ' ⋄ ⍵/⍨(∧\b)⍱⌽∧\⌽b←⍵∊⍺}              ⍝ delete ending (leading/trailing) blanks
      ⍝ OPTIONS-- see documentation.
      ⍝ Default (for string ⍺)
      ⍝ - VERBOSE   unless -NOVERBOSE  
      ⍝  -NODEBUG   unless -DEBUG     o 
      ⍝  -COM, -BLANK, FIX  
      ⍝  -NOEDIT (unless ⎕NULL is right arg),
      ⍝  -NOHELP, QUIET 
        __VERBOSE__←(~opt'noV')                          ⍝ Default 1;  
        __DEBUG__←(opt'D')                               ⍝ Default 0 
        NOCOM NOBLANK HELP←opt¨'noC' 'noB' 'H'           ⍝ Default 1 1 1
        EDIT←(~opt'noE' )∧(⎕NULL≡⍬⍴⍵)∨opt'E'             ⍝ Default 0; 1 if ⍵≡∊⎕NULL
        QUIET←__VERBOSE__⍱__DEBUG__                      ⍝ Default 1
        FIX←~opt'noF'                                    ⍝ Default 1
        _←{ ⍝ Option information
            ⍺←0 ⋄ ~__DEBUG__∨⍺:0 
            ⍙←4⍴' '
            ⎕←⍙,'Options: "','"',⍨lc ⍵
            ⎕←⍙,'Verbose: ',__VERBOSE__ ⋄ ⎕←⍙,'Debug:   ',__DEBUG__
            ⎕←⍙,'NoCom:   ',NOCOM       ⋄ ⎕←⍙,'NoBlanks:',NOBLANK
            ⎕←⍙,'Edit:    ',EDIT        ⋄ ⎕←⍙,'Quiet:   ',QUIET
            ⎕←⍙,'Help:    ',HELP        ⋄ ⎕←⍙,'Fix:     ',FIX
            0
        }⍺
      ⍝ HELP PATH; currently an external file...
        HELP:{⎕ED'___'⊣___←↑⊃⎕NGET ⍵}&'pmsLibrary/docs/∆PRE.help'
      ⍝  HELP:{⎕ED'___'⊣___←↑(⊂'  '),¨3↓¨⍵/⍨(↑2↑¨⍵)∧.='⍝H'}2↓¨⎕NR⊃⎕XSI
      ⍝ -------------------------------------------------------------------
      (1↓⊆,⍺){
          preamble←⍺
          fnAtomCtr←¯1
        ⍝ ∆GENERAL ∆UTILITY ∆FUNCTIONS
        ⍝
        ⍝ annotate [preprocessor (output) code]
        ⍝ If __VERBOSE__,
        ⍝     write to preprocessor output:
        ⍝         (b⍴' '),⍵
        ⍝     where
        ⍝         b is # of leading blanks in string ⍺, if ⍺ is specified.
        ⍝         b is # of leading blanks in string ⍵, otherwise.
        ⍝     ⍵ is typically a preprocessor directive, potentially w/ leading blanks,
        ⍝     Where ⍵ is modified, ⍺ is the original or model directive w/ leading blanks.
        ⍝ else
        ⍝     write the token EMPTY (a NULL char with special meaning).
          annotate←{
              ~__VERBOSE__:EMPTY
              ⍺←⍬ ⋄ 0≠≢⍺:'⍝',⍵,⍨⍺↑⍨0⌈¯1++/∧\' '=⍺ ⋄ '⍝',(' '⍴⍨0⌈p-1),⍵↓⍨p←+/∧\' '=⍵
          }

        ⍝ print family - informing user, rather than annotating output code.
        ⍝
        ⍝ print- print ⍵ as a line ⍵' on output, converting NL to CR (so APL prints properly)
        ⍝ printQ-same as print, but using ⍞←⍵' rather than ⎕←⍵.
        ⍝ Both return: ⍵, not the translated ⍵'.
        ⍝ DO NOT USE CR in program code lines.
          print←{⍵⊣⎕←CR@(NL∘=)⊣⍵}
          printQ←{⍵⊣⍞←CR@(NL∘=)⊣⍵}
        ⍝ dPrint/Q -- DEBUGGER OUTPUT
        ⍝ dPrint- same as print,  but only if __DEBUG__=1.
        ⍝ dPrintQ-same as printQ, but only if __DEBUG__=1.
        ⍝ Returns ⍵.
          dPrint←{__DEBUG__:print ⍵ ⋄ ⍵}
          dPrintQ←{__DEBUG__:printQ ⍵ ⋄ ⍵}
        ⍝ ∆FLD: ⎕R helper.
        ⍝  Returns the contents of ⍺ regexp field ⍵, a number or name or ''
        ⍝ val ← ns  ∆FLD [fld number | name]
        ⍝    ns- active ⎕R namespace (passed by ⎕R as ⍵)
        ⍝    fld number or name: a single field number or name.
        ⍝ Returns <val> the value of the field or ''
          ∆FLD←{
            ns←⍺
            ' '=1↑0⍴⍵:ns ∇ ns.Names⍳⊂⍵
            ⍵=0:ns.Match                          ⍝ Fast way to get whole match
            ⍵≥≢ns.Lengths:''                      ⍝ Field not defined AT ALL → ''
            ns.Lengths[⍵]=¯1:''                   ⍝ Defined field, but not used HERE (within this submatch) → ''
            ns.(Lengths[⍵]↑Offsets[⍵]↓Block)      ⍝ Simple match
          }
        ⍝ ∆MAP: replaces elements of string ⍵ of form ⍎name with value of name.
        ⍝       recursive (within limits <⍺>) whenever ⍵' changes:  ⍵≢⍵'←∆MAP ⍵
        ⍝ ∆QT:  Add quotes (default ⍺: single)
        ⍝ ∆DQT: Add double quotes. See ∆QTX if you want to fix any internal double quotes.
        ⍝ ∆UNQ: Remove one level of s/d quotes from around a string, addressing internal quotes.
        ⍝       If ⍵ doesn't begin with a quote in ⍺ (default: s/d quotes), does nothing.
        ⍝ ∆QT0: Double internal quotes (default ⍺: single quotes)
        ⍝ ∆QTX: Add external quotes (default ⍺: single), first doubling internal quotes (if any).
          ∆MAP←{⍺←15 ⋄ ∆←'⍎[\w_∆⍙⎕]+'⎕R{⍎1↓⍵ ∆FLD 0}⍠'UCP' 1⊣⍵ ⋄ (⍺>0)∧∆≢⍵:(⍺-1)∇ ∆ ⋄ ∆}
          ∆QT←{⍺←SQ ⋄ ⍺,⍵,⍺}
          ∆DQT←{DQ ∆QT ⍵}
          ∆UNQ←{⍺←SQDQ ⋄ ~⍺∊⍨q←1↑⍵:⍵ ⋄ s←1↓¯1↓⍵ ⋄ s/⍨~s⍷⍨2⍴q}
          ∆QT0←{⍺←SQ ⋄ ⍵/⍨1+⍵∊⍺}
          ∆QTX←{⍺←SQ ⋄ ⍺ ∆QT ⍺ ∆QT0 ⍵}
        ⍝ ∆PARENS: ⍵  →   '(⍵)'
          ∆PARENS←{'(',')',⍨⍵}
        ⍝ ∆H2D: Converts hex to decimal, silently ignoring chars not in 0-9a-fA-F, including
        ⍝       blanks or trailing X symbols. (You don't need to remove X or blanks first.)
          ∆H2D←{   ⍝ Decimal from hexadecimal
              11::'∆PRE hex number (0..X) too large'⎕SIGNAL 11
              16⊥16|a⍳⍵∩a←'0123456789abcdef0123456789ABCDEF'
          }
        ⍝ ∆TRUE ⍵:
        ⍝ "Python-like" sense of truth, useful in ::IFDEF and ::IF statements.
        ⍝ ⍵ (a string) is 1 (true) unless
        ⍝    a) ⍵ is 0-length or contains only spaces, or
        ⍝    b) its val, v such that v←∊∆CALLR⍎⍵ is of length 0 or v≡(,0) or v≡⎕NULL, or
        ⍝    c) it cannot be evaluated,
        ⍝       in which case a warning is given (debug mode) before returning 0.
          ∆TRUE←{
            0::0⊣dPrint'∆PRE Warning: Unable to evaluate truth of {',⍵,'}, returning 0'
            0=≢⍵~' ':0 ⋄ 0=≢val←∊∆CALLR⍎⍵:0 ⋄ (,0)≡val:0 ⋄ (,⎕NULL)≡val:0
            1
          }
        ⍝ GENERAL CONSTANTS. Useful in annotate etc.
        ⍝ Annotations (see annotate).
        ⍝   YESch - path taken.
        ⍝   NOch  - path not taken (false conditional).
        ⍝   SKIPch- skipped because it is governed by a conditional that was false.
        ⍝   INFOch- added information.
          YESch NOch SKIPch INFOch WARNch ERRch←' ✓' ' 😞' ' 🚫' ' 💡' '⚠️' '💩'
        ⍝ EMPTY: Marks (empty) ∆PRE-generated lines to be deleted before ⎕FIXing
          EMPTY←,NULL
        ⍝ Process double quotes based on double-quoted string suffixes "..."sfx
        ⍝ Where suffixes are [vsm]? and  [r]? with default 'v' and (cooked).
        ⍝ If suffix is (case ignored):
        ⍝  type  suffix      set of lines in double quotes ends up as...
        ⍝  VEC   v or none:  ... a vector of (string) vectors
        ⍝ SING   s:          ... a single string with newlines (⎕UCS 10)
        ⍝  MX    m:          ... a single matrix
        ⍝  RAW   r:          blanks at the start of each line*** are preserved.
        ⍝ COOKD  none:       blanks at the start of each line*** are removed.
        ⍝ *** Leading blanks on the first line are maintained in either case.
          processDQ←{⍺←0       ⍝ If 1, create a single string. If 0, create char vectors.
            str type←(⊃⍵)(lc⊃⌽⍵)      
          ⍝ type: 'v' (cooked) is nothing else specified.
          ⍝       which sets raw←0, sing←0, cMx←''
            isRaw isStr isMx←'rsm'∊type  
            hasMany←NL∊str
            toMx←{⍺:'↑',⍵ ⋄ '↑,⊆',⍵}       ⍝ Forces simple vec or scalar → matrix
            Q_CR_Q←''',(⎕UCS 13),'''       ⍝ APL expects a CR, not NL.
            opts←('Mode' 'M')('EOL' 'LF')
            str2←∆QT0 ∆UNQ str
            isStr:∆PARENS⍣hasMany⊣∆QT{
              isRaw:'\n'⎕R Q_CR_Q⍠opts⊢⍵
              '\A\h+' '\n\h*'⎕R'&'Q_CR_Q⍠opts⊢⍵
            }str2
            hasMany toMx⍣isMx⊣∆QT{
              isRaw:'\n'⎕R''' '''⍠opts⊢⍵
              '\A\h+' '\n\h*'⎕R'&' ''' '''⍠opts⊢⍵
            }str2
            '∆PRE: processDQ logic error'⎕SIGNAL 911
          }

        ⍝ getDataIn object:⍵
        ⍝ ⍵:
        ⍝    a vector of vectors: lines of APL code in 2∘FIX format.
        ⍝    ⎕NULL:               prompts user for lines of APL code in 2∘FIX format.
        ⍝    char vector:         name of function with lines of APL code.
        ⍝          If the name ⍵ has no file extension, then we'll try ⍵.dyapp and ⍵.dyalog.
        ⍝          ⍵ may have a prefix (test/ in test/myfi.dyapp).
        ⍝          Searches , .. .. and directories in env FSPATH and WSPATH in turn.
        ⍝
        ⍝ Returns ⍵:the object name, the full file name found, (the lines of the file)
        ⍝ If the obj ⍵ is ⎕NULL, the object is prompted from the user.
        ⍝ (See promptForData) for returned value.
          getDataIn←{∆∆←∇
            19::'∆PRE: Invalid or missing file'⎕SIGNAL 19
            ⎕NULL≡⍬⍴⍵:promptForData ⍬
            2=|≡⍵:'__TERM__' '[function line]'(,¨⍵)     ⍝ In case last line is '∇' → (,'∇')
            ⍺←{∪{(':'≠⍵)⊆⍵}'.:..',∊':',¨{⊢2 ⎕NQ'.' 'GetEnvironment'⍵}¨⍵}'FSPATH' 'WSPATH'
            0=≢⍺:11 ⎕SIGNAL⍨'∆PRE: Unable to find or load source file ',∆DQT ⍵
            dir dirs←(⊃⍺)⍺
          ⍝ Check for file extention <ext>
            pfx nm ext←⎕NPARTS ⍵
            _←{
                0 3 4∊⍨∆CALLR.⎕NC ⍵:''
                ⎕←'∆PRE Warning. Existing incompatible object "',⍵,'" may prevent ⎕FIXing'
            }nm
          ⍝ Extension?    Use it as our <types>
          ⍝ No extension? Try types '.dyapp' [our own] and '.dyalog' [std].
            types←{×≢⍵:⊂⍵ ⋄ '.dyapp' '.dyalog'}ext
          ⍝ Return whatever you find.
            types{
              0=≢⍺:(1↓dirs)∆∆ ⍵
              filenm←(2×dir≡,'.')↓dir,'/',⍵,⊃⍺
              ⎕NEXISTS filenm:⍵ filenm(⊃⎕NGET filenm 1)
              (1↓⍺)∇ ⍵
            }pfx,nm
          }
        ⍝ prompt User for data to preprocess. Useful for testing...
        ⍝ Creates object __TERM__, its full filename is '/dev/null', and lines as specified.
          promptForData←{
            _←print'Enter lines. Empty line to terminate.'
            lines←{⍺←⊂'__TERM__' ⋄ 0=≢l←⍞↓⍨≢⍞←⍵:⍺ ⋄ (⍺,⊂l)∇ ⍵}'> '
            '__TERM__' '[user input]'lines
          }
        ⍝ MACRO (NAME) PROCESSING
        ⍝ mPut, mGet, mHideAll, mDel, mHasDef
        ⍝ Extern function (isSpecialMacro n) returns 1 if <n> is a special Macro.
        ⍝ Includes a feature for preventing recursive matching of the same names
        ⍝ in a single recursive (repeated) scan.
        ⍝ Uses EXTERNAL vars: mNames, mVals, mNameVis
          mPut←{⍺←__DEBUG__ ⋄ verbose←⍺
            n v←⍵      ⍝ add (name, val) to macro list
            ⍝ case is 1 only for system-style names of form /⎕\w+/
            c←⍬⍴'⎕:'∊⍨1↑n
            n~←' ' ⋄ mNames,⍨←⊂lc⍣c⊣n ⋄ mVals,⍨←⊂v ⋄ mNameVis,⍨←1
            ~isSpecialMacro n:⍵           ⍝ Not in domain of [fast] isSpecialMacro function
          ⍝ Special macros: if looks like number (as string), convert to numeric form.
            processSpecialM←{
              0::⍵⊣print'∆PRE: Logic error in mPut'  ⍝ Error? Move on.
              v←{0∊⊃V←⎕VFI ⍵:⍵ ⋄ ⊃⌽V}⍕v              ⍝ Numbers vs Text
              _←⍎n,'∘←⍬⍴⍣(1=≢v)⊣v'                   ⍝ Execute in ∆PRE space, not user space.
              ⍵⊣{⍵:print'Set special variable ',n,' ← ',(⍕v),' [EMPTY]'/⍨0=≢v ⋄ ⍬}verbose
            }
            n processSpecialM ⍵
          }
        ⍝ mPutMagic: allow special executed cases...
        ⍝    ⍺: Execution Environment
        ⍝    0, 1, 2: See mGet below
          mPutMagic←{
            ⍺←0 ⋄ n v←⍵  
            mPut n (⍺,v)
          }
        ⍝ mGet  ⍵: 
        ⍝  ⍺=0 (default)  retrieves value for ⍵, if any; (or ⍵, if none)
        ⍝  ⍺=1            ditto, but only if mNameVis flag is 1
        ⍝ mHideAll ⊆⍵: sets mNameVis flag to (scalar) ⍺←0 for each name in ⍵, returning ⍺
        ⍝ 
        ⍝ Magic Values: 
        ⍝ if mPutMagic [internal use only] is used, it will change ⍵, a string,
        ⍝ to    n,⍵   where n is a single digit (0, 1, 2). See below.
        ⍝ If we see a magic digit prefix, we remove it, and execute the resulting
        ⍝ string in the environment required. The string is not macro substituted first,
        ⍝ so do that "manually" or not at all.
        ⍝ Magic prefix may be
        ⍝     0: execute in ∆PRE space (local vars, etc.)
        ⍝     1: execute in ∆MY space, the ::STATIC run-time environment
        ⍝     2: execute in ∆CALLR environment
          mGet←{⍺←0   ⍝ If ⍺=1, i.e. treat as not found if inactive (mActive)
            n←⍵~' ' ⋄ c←⍬⍴'⎕:'∊⍨1↑n
            p←mNames⍳⊂lc⍣c⊣n 
            p≥≢mNames:n  ⋄ ⍺∧~p⊃mNameVis:n  
            v←p⊃mVals
            0≠1↑0⍴v: v    ⍝ Not magic: return as is!            
            p v←(1↑v)(1↓v)
            0:: ⎕SIGNAL/{
              _←'∆PRE Logic error: eval of magic macro failed: ',CR
              _,←'> name="',n,'" val="',(⍕v),'" ns="',(⍕p),'"'
              _ ⍵
            }11
            0=p: ∊⍕⍎v          ⍝ ∆PRE space
            1=p: ∊⍕∆MYR⍎v      ⍝ ∆MY space
            2=p: ∊⍕∆CALLR⍎v    ⍝ ∆CALLR space
            ∘ 'logic error: unknown environment' ∘
          }
        ⍝ mTrue ⍵: Returns 1 if name ⍵ exists and its value is true per ∆TRUE
          mTrue←{ ~mHasDef ⍵:0 ⋄  ∆TRUE mGet ⍵}    
          mHideAll←{⍺←0
            ⍺⊣⍺{n←⍵~' ' ⋄ c←⍬⍴'⎕:'∊⍨1↑n
              p←mNames⍳⊂lc⍣c⊣n ⋄ p≥≢mNames:_←¯1 ⋄ 1:_←(p⊃mNameVis)∘←⍺
            }¨⍵
          }
          mDel←{n←⍵~' ' ⋄ c←⍬⍴'⎕:'∊⍨1↑n
            p←mNames⍳⊂lc⍣c⊣n ⋄ p≥≢mNames:n
            mNames mVals mNameVis⊢←(⊂p≠⍳≢mNames)/¨mNames mVals mNameVis ⋄ n
          }
        ⍝ Return 1 if name (⍵ ignoring ' ~') is a defined name as is.
        ⍝ If name has a ~ at its start, return 1 if it has NOch def.
        ⍝ Case is respected, unless the name begins with ⎕ or :
          mHasDef←{rev←'~'=1↑⍵~' ' ⋄ ic←⍬⍴'⎕:'∊⍨1↑nm←⍵~' ~'
            has←(≢mNames)>mNames⍳⊂lc⍣ic⊣nm 
            rev: ~has ⋄ has
          }
        tempVarCounter←¯1
        tempVarName←'T⍙' 
        getTempName←tempVarName∘{
          ⍵=0: ⍺,⍕tempVarCounter+tempVarCounter<0 
          ⍺,⍕tempVarCounter⊢tempVarCounter∘←100|tempVarCounter+⍵ 
        }
      ⍝ sName ← name setStaticConst value
      ⍝   Creates (niladic fn) name <name> in ∆MYR,
      ⍝   returning SHY value <⍎value>
      ⍝   stored in ∆MYR.∆CONST.
      ⍝   sName: full name in static namespace
      ⍝   name:  simple name
      ⍝   value: code string indicating value 
      ⍝ Requires that ns ∆MYR.∆CONST exist
      ⍝ Example:
      ⍝   piName← 'pi' setStaticConst '○1'
      ⍝   Creates: #.⍙⍙.__TERM__.∆MY.pi
      ⍝   A function returning variable:
      ⍝            #.⍙⍙.__TERM__.∆MY.∆CONST.pi   
        setStaticConst←{
          me←∆MY,'.',⍺ ⋄ _←mPut ⍺ me
          _←∆MYR.⎕FX ('{_}←',⍺)('_←∆CONST.',⍺)
          _←⍎∆MY,'.∆CONST.',⍺,'←',⍵
          me
        } 
      ⍝-----------------------------------------------------------------------
      ⍝ macroExpand (macro expansion, including special predefined expansion)
      ⍝     …                     for continuation (at end of (possbily commented) lines)
      ⍝     …                     for numerical sequences of form n1 [n2] … n3
      ⍝     25X                   for hexadecimal constants
      ⍝     25I                   for big integer constants
      ⍝     name → value          for implicit quoted (name) strings and numbers on left
      ⍝     `atom1 atom2...       for implicit quoted (name) strings and numbers on right
      ⍝     ` {fn} (fn)(arb_code) creates a list of namespaces ns, each with fn ns.fn
      ⍝
      ⍝-----------------------------------------------------------------------
        macroExpand←{
          ⍺←__MAX_EXPAND__      ⍝ If 0, macros including hex, bigInt, etc. are NOT expanded!!!
        ⍝ ∆TO: Concise variant on dfns:to, allowing start [incr] to end
        ⍝     1 1.5 ∆TO 5     →   1 1.5 2 2.5 3 3.5 4 4.5 5
        ⍝ expanded to allow (homogenous) Unicode chars
        ⍝     'a' ∆TO 'f' → 'abcdef'  ⋄   'ac' ∆TO 'g'    →   'aceg'
        ⍝ We use ⎕FR=1287 internally, but the exported version will use the ambient value.
        ⍝ This impacts only floating ranges...
          ∆TO←{⎕IO←0 ⋄ 0=80|⎕DR ⍬⍴⍺:⎕UCS⊃∇/⎕UCS¨⍺ ⍵ ⋄ f s←1 ¯1×-\2↑⍺,⍺+×⍵-⍺ ⋄ ,f+s×⍳0⌈1+⌊(⍵-f)÷s+s=0}
          ∆TOcode←{(2+≢⍵)↓⊃⎕NR ⍵}'∆TO'
        ⍝ Multi-item translation input option. See ::TRANS
          str←TRANSLATE{0=≢⍺.in:⍵  
            ⍺.(in out){
              (tr_in tr_out) str←⍺ ⍵ ⋄ 0=≢tr_in:⍵
              i o←⊃¨tr_in tr_out ⋄ tr_in tr_out←1↓¨tr_in tr_out
              (tr_in tr_out) ∇ o@(i∘=)⊣str
            } ⍵
          }⍵
          
          mNameVis[]∘←1      ⍝ Make all macros visible until next call to macroExpand
          str←⍺{
            strIn←str←⍵
            0≥⍺:⍵
            nmsFnd←⍬
          ⍝ Match/macroExpand...
          ⍝ NOTE: Should handle double quotes here, namely those
          ⍝       added via macros...
          ⍝ [1] pLongNmE: long names,
            cUser cDQ cSkip cLong←0 1 2 3
            
            str←{
              e1←'∆PRE: Value is too complex to represent statically:'
              4::4 ⎕SIGNAL⍨e1,CR,'   ⍝     In macro code: "',⍵,'"'
              pUserE pDQe pSkipE pLongNmE ⎕R{
                f0←⍵ ∆FLD 0 ⋄ case←⍵.PatternNum∘∊
                case cDQ cSkip: f0  ⍝ Just skip double quotes until [3] below
                case cLong:⍕1 mGet f0⊣nmsFnd,←⊂f0          ⍝ Let multilines fail
                case cUser:'⎕SE.UCMD ',∆QT ⍵ ∆FLD 1          ⍝ ]etc → ⎕SE.UCMD 'etc'
                ∘Unreachable∘                               ⍝ else: comments
              }⍠'UCP' 1⊣⍵
            }str
            
          ⍝ [2] pShortNmE: short names (even within found long names)
          ⍝     pSpecialIntE: Hexadecimals and bigInts
            cDQ cSkip cShortNm cSpecialInt←0 1 2 3
            str←pDQe pSkipE pShortNmE pSpecialIntE ⎕R{
              f0←⍵ ∆FLD 0 ⋄ case←⍵.PatternNum∘∊
              case cDQ cSkip: f0   ⍝ Just skip double quotes until after macros
              case cSpecialInt:{
                ⍵∊'xX':⍕∆H2D f1
                0=≢f2:∆QT f1                ⍝ No exponent
                ∆QT f1,('0'⍴⍨⍎f2)           ⍝ Explicit exponent-- append 0s.
              }¯1↑f0⊣f1 f2←⍵ ∆FLD¨1 2
              case cShortNm:⍕1 mGet f0⊣nmsFnd,←⊂f0
              ∘Unreachable∘
            }⍠'UCP' 1⊣str
          
          ⍝  [3] Handle any double quotes introduced in macros (mGet) above.
          ⍝  NO MORE DOUBLE-QUOTED STRINGS SHOULD APPEAR AFTER THIS POINT...
            str←pDQe pSkipE  ⎕R{
              f0←⍵ ∆FLD 0 ⋄ case←⍵.PatternNum∘∊
              case 0:processDQ ⍵ ∆FLD¨1 2  
              case 1:f0
              ∘Unreachable∘                               ⍝ else: comments
            }⍠'UCP' 1⊣str
          
          ⍝  Ellipses - constants (pDot1e) and variable (pDot2e)
          ⍝  pDot1e must precede pSQe, so that char. progressions 'a'..'z' are found before simple 'a' 'z'
          ⍝  Check only after all substitutions (above), so ellipses with macros that resolve to
          ⍝  numeric or char. constants are optimized.
          ⍝  See __MAX_PROGRESSION__ below
            pFormatStringE←'(?ix) ∆FORMAT\h* ( (?: ''[^'']*'' )+ )'
            cDot1E cSkipE cDot2E cFormatStringE←0 1 2 3
            str←pDot1e pSkipE pDot2e pFormatStringE ⎕R{
              case←⍵.PatternNum∘∊
              case cSkipE:⍵ ∆FLD 0
              case cFormatStringE:{
                0::⍵ ∆FLD 0
                0 ∆format ∆UNQ ⍵ ∆FLD 1  ⍝ (Remove extra quoting added above).
              }⍵
              case cDot2E:∆TOcode
            ⍝ case cDot1E:
              ⋄ f1 f2←⍵ ∆FLD¨1 2
              ⋄ progr←∆QTX⍣(SQ=⊃f1)⊣⍎f1,' ∆TO ',f2   ⍝ Calculate constant progression
              __MAX_PROGRESSION__<≢progr:f1,' ',∆TOcode,' ',f2
              {0=≢⍵:'⍬' ⋄ 1=≢⍵:'(,',')',⍨⍕⍵ ⋄ ⍕⍵}progr
            }⍠'UCP' 1⊣str

          ⍝ Enumerations
          ⍝    name0 ← ::ENUM { name1 [: [value1]], name2 [: [value2]], ...} 
          ⍝ OR 
          ⍝    [name0 ←]: :ENUM [typeName [←]]{ name1 [: [value1]], name2 [: [value2]], ...} 
          ⍝ Expanded form:
          ⍝    name0 ← ::ENUM  {...}{...} ... {...}
          ⍝    name0 ← ::ENUM  typeName {...}{...} ... {...}
          ⍝      typeName: Optional name of the enum type (a ← may optionally follow).
          ⍝            If set, [1] the typeName and value are set as ::STATICs
          ⍝                    [2] the display form of the object is [ENUM:typeName].
          ⍝                    [3] name0← may be omitted. The ::ENUM returns a shy result.
          ⍝      name0:    Any APL assignment expression at all...
          ⍝      nameN:    APL-format name (short or long, no quotes)
          ⍝      valueN:   [int | atom | "string" | *]
          ⍝        num:      An APL-format number extended: - is treated as ¯
          ⍝                  -25 => ¯25,  2.4E-55 => 2.4E¯55, 2J-1 => 2J¯1  
          ⍝        atoms:    APL format names outside quotes converted to atoms...
          ⍝                  {color:dark pink} same as {color: "dark" "pink"}
          ⍝        string:   A string or strings within quotes
          ⍝                  {color:"dark pink"} is    {color: "dark pink"}
          ⍝                  {color:"dark" "pink"} is  {color" "dark" "pink"}
          ⍝        * or +    indicates 1 more than the previous number or 0, if none.
          ⍝                  Non-numeric values are ignored as predecessors
          ⍝                  Note: The colon may be omitted before * or +
          ⍝                     ::ENUM {red+,  orange+,  yellow+ }
          ⍝                  => ::ENUM {red:0, orange:1, yellow:2}
          ⍝       value omitted:
          ⍝                  i.e. format:  'nameN:,' OR  'nameN,'    
          ⍝                  nameN will have value "nameN", i.e. itself. 
          ⍝ color ← ::ENUM {red: *, orange: *, yellow: *, green,         rouge: 0}
          ⍝ OR      ::ENUM {red: +, orange: +, yellow: +, green,         rouge: 0}
          ⍝ OR      ::ENUM {red  +, orange  +, yellow  +, green,         rouge: 0}
          ⍝    i.e. ::ENUM {red: 0, orange: 1, yellow: 2, green:"green", rouge: 0}
          ⍝ color ← ::ENUM {red,orange,yellow,green,rouge:red}
          ⍝    i.e. ::ENUM {red:"red", orange:"orange", ..., rouge:"red"}
          ⍝  -----
          ⍝  Now allows multiple enumerations:
          ⍝       schemes←::ENUM{red,orange,yellow}{green,blue,indigo,violet}
          ⍝       schemes.∆NAMES
          ⍝    red  orange  yellow     green  blue  indigo  violet 
            badName←{1∊' []'∊⍵:1 ⋄ (1↑⍵)∊⎕D,'¯'}   ⍝ Reject "names" with brackets or multiple names
            str ← pSkipE pEnumE  ⎕R {
              case←⍵.PatternNum∘∊
              case 0:⍵ ∆FLD 0 
              typeNm enums←⍵ ∆FLD¨1 2   
            ⍝ If a name appears to the right of ::ENUM (with opt'l arrow)
            ⍝ it will be assigned a constant value statically.
             11+(988×__DEBUG__):: (⍵ ∆FLD 0),'∘∘∘ ∆PRE ERROR: invalid enumeration∘∘∘'
              err nEnum←0
              canonNum←'¯'@('-'∘=)⊣
              enumCode←∆PARENS⍣(nEnum>1)⊣∊pEnumEach ⎕R { 
                nEnum+←1 
                curV curInc←¯1 1
                names←vals←'' ⋄ nNames←0
                _←∆QTX pEnumSub ⎕R {
                  0:: err∘←1
                  f0 name val←⍵ ∆FLD ¨0 1 2 ⋄ name val←trimLR¨ name val   
                   ⎕←'f0="',f0,'" name="',name,'" val="',val,'"' 
                  nNames+←1                ⍝ Ensure each scalar name 'a' → ,'a'    
                  badName name: ('∆PRE: INVALID NAME IN ENUMERATION: ',⍵ ∆FLD 0) ⎕SIGNAL 11
                  names,←' ',⍨name←∆QT name
                  0=≢val: 0⍴vals,←' ',⍨name                         ⍝ name:,   
                  isNum isStar←(⊃val)∊¨NUMFIRST '+'
                ⍝ isNum: scalar/vector of numbers; isStar: scalar/vector increments, else 1
                  isNum: 0⍴vals,←' ',⍨∆PARENS⍣(1<≢curV)⊣⍕curV∘←val⊣val←⍎canonNum val  
                  isStar:0⍴vals,←' ',⍨∆PARENS⍣(1<≢curV)⊣⍕curV∘←curV+curInc∘←curInc{f n←⎕VFI ⍵ ⋄ 1∊f:f/n ⋄ ⍺}1↓val     
                ⍝ string atoms (names or quoted strings or the former mixed w/ APL numbers)
                  atoms←pListAtoms ⎕S '&'⊣val
                  pfx←{⍺:',¨',⍵ ⋄ ⍵}
                  1: 0⍴vals,←' ',⍨∆PARENS (1<≢atoms)pfx 1↓∊{
                    SQ=1↑⍵: ' ',∆QTX ∆UNQ ⍵
                    NUMFIRST∊⍨1↑⍵: ' ',⍵  
                    ' ',∆QTX ⍵
                  }¨atoms           
                }⍠'UCP' 1⊣⍵ ∆FLD 1  
                err∨0=≢names:  ('∆PRE: INVALID ENUMERATION: ',⍵ ∆FLD 0) ⎕SIGNAL 11
                ∆PARENS names,'(',(∆QT typeNm~' '),'⎕SE.⍙enum ',(⍕nNames>1),')',¯1↓vals
              }enums
              0=≢typeNm: enumCode
              typeNm∘setStaticConst enumCode
            }⍠'UCP' 1⊣ str

          ⍝ Deal with ATOMS of two types:
          ⍝ Simple atoms: names or numbers,zilde (⍬),⎕NULL
          ⍝     `  name 123.45 nam2 123j45 etc.
          ⍝ Code atoms:
          ⍝     `  ({dfn}|\(apl fn\))+
          ⍝ Code atoms return a namespace ns such that
          ⍝     ([⍺] ns.fn ⍵) calls  [⍺] {dfn} ⍵
          
          ⍝ We'll allow either a list of simple atoms (names or numbers) 
          ⍝ or a list of fns (dfns or parenthesized expressions), but not 
          ⍝ the two types mixed together.
          ⍝ pAtomTokens←∆MAP¨(⊂'(?xi)'),¨_pBrace _pParen pSQe '⎕NULL\b' _pName _pNum '⍬'
          ⍝  type:                       0       1       2    3      4     5       6        7    8      
          ⍝ SINK       
          ⍝     ← value     treated as   T⍙1 ← value (etc.)
          ⍝ Allow bare left arrows to function as "sink", i.e. assigning to ignored temp.
          ⍝ Vars will be named T⍙1, T⍙2, up to T⍙99, then recycled quietly
          ⍝    {←⎕DL 2 ⋄ do something}  →→ {_←⎕DL 2 ⋄ do something}
          ⍝ Generalize to the start of lines and:
          ⍝    (←here; ←here; ⎕TS[←here≢]) ⋄ ←here 
          ⍝ and 
          ⍝    {i≤10:←here} ⍝ Useful for shy output, avoiding an explicit temp.
          ⍝ ======================
          ⍝ MISSING MAP ELEMENT       
          ⍝    item →     treated as   item → ⎕NULL
          ⍝ Allow right arrow in Atoms to default to missing/default (⎕NULL):
          ⍝    (name→'John'; address→; phone→) →→ 
          ⍝    (name→'John'; address→⎕NULL; phone→⎕NULL)
          ⍝ Set missing value here:
            pNullRightArrowE←'(?x) → (\h*) (?= [][{}):;⋄] | $ )'
            missingValueToken←'⎕NULL'
    
            pNullLeftArrowE←'(?x) (?<= [[(:;⋄]  | ^) (\h*)  ←'
          ⍝ see getTempName←{...}
            str←pSkipE pNullLeftArrowE pNullRightArrowE ⎕R {
              case←⍵.PatternNum∘∊ ⋄ f0 f1←⍵ ∆FLD¨ 0 1
              case 0: f0
              case 1: f1,temp,'←'⊣temp←getTempName 1
              case 2: '→',missingValueToken,f1↓⍨≢missingValueToken
            }⍠('UCP' 1)⊣str
        
            tBrace tParen tQt tNull tName tNum tZilde←⍳7
            atomize←{
              fnAtom←valAtom←0
              tok←pAtomTokens ⎕S  { 
                case←⍵.PatternNum∘∊
                f0←⍵ ∆FLD 0
                case tBrace tParen: {
                fnAtomCtr+←1 ⋄ fnAtom∘←1
                '(',')',⍨f0,'⎕SE.⍙fnAtom ',⍕ fnAtomCtr
                }⍵
                valAtom∘←1
                case tQt:{1=¯2+≢⍺:'(,',⍵,')' ⋄ ' ',⍵}⍨f0
                case tNull: f0,' '
                case tName: f0{1=≢⍺:'(,',⍵,')' ⋄ ' ',⍵}∆QT f0
                case tNum tZilde: ' ',f0,' '
              }⍠('UCP' 1)('Mode' 'M')⊣⍵
              tok fnAtom valAtom
            }
            str←pSkipE pAtomListL pAtomListR ⎕R {
              case←⍵.PatternNum∘∊ ⋄ f0←⍵ ∆FLD 0
              case 0:f0 
              atoms←⍵ ∆FLD 'atoms'
              case 1:{ ⍝ LEFT: Atom list on left:   atoms → [→] anything 
                nPunct←≢' '~⍨punct←⍵ ∆FLD 'punct'
                ~nPunct∊1 2:atoms,' ∘err∘' ,punct,'⍝ Error: invalid atom punctuation'
                atomTokens fnAtom valAtom←atomize atoms      
              ⍝ If there's a fnAtom, treat → and → as if →→
                pfx←(fnAtom∨nPunct=2)⊃'⊆' ''
              ⍝ Currently function atoms are NOT allowed to left of →
                _←fnAtom{
                  ⍺:⎕←'Warning: Function atom(s) used in atom map to left of arrow (→):',CR,f0 
                  ⍵:⎕←'Warning: Function atoms and value atoms mixed in the same map (→) expression:',CR,f0
                  ''
                }fnAtom∧valAtom
                '(',pfx,(∊atomTokens),'){⍺⍵}'
              }⍵
              case 2:{ ⍝ RIGHT: Atom list on right:  ` [`] atoms... 
                nPunct←≢' '~⍨punct←⍵ ∆FLD 'punct'
                ~nPunct∊1 2:punct,' ∘err∘ ',atoms,'⍝ Error: invalid atom punctuation'
                atomTokens fnAtom valAtom←atomize atoms
              ⍝ if there's a fnAtom, treat ` and `` as if `` 
                pfx←(fnAtom∨nPunct=2)⊃'⊆' ''
                _←{
                  ⍵:⎕←'Warning: Mixing function- and value-atoms in the same list (`) expression:',CR,f0
                  ''
                }fnAtom∧valAtom
                '(',pfx,(∊atomTokens),')'
              }⍵
            }⍠('UCP' 1)⊣str

          ⍝ STRING / NAME CATENATION: *** EXPERIMENTAL ***
          ⍝ So far, we ONLY allow scanning here for String / Name catenation:
          ⍝     IN                           OUT
          ⍝     name1 ∘∘ name                name1name2
          ⍝     "str1" ∘∘ "str1"             'str1str2' (per processDQ)
          ⍝     'str1' ∘∘ 'str1'             'str1str2'
          ⍝     Note: SQ and DQ strings may be mixed and matched:
          ⍝      'str1' ∘∘ "str2" ∘∘ 'str3'  'str1str2str3'
          ⍝     any other /\h*∘∘\h*/         *** ERROR ***
          ⍝ Allows recursion:
          ⍝      deb ∘∘ 45 ∘∘ jx             deb45jx
          ⍝      'one '∘∘'dark '∘∘'night'    'one dark night'
            str← pSQcatE pSkipE pCatNamesE  ⎕R  {
              cSQcat cSkip cNmCat←0 1 2 
              case←⍵.PatternNum∘∊
              case cSkip: ⍵ ∆FLD 0       ⍝ SKIP comments, sq fields, dq fields
              case cNmCat:''      ⍝ Join the names
              ⋄ f1f2←(¯1↓⍵ ∆FLD 1),1↓⍵ ∆FLD 2
              case cSQcat:f1f2
            }str

          ⍝ ::UNQ(string) : dequotes strings (and adjusts) internal squotes, returning string'.
          ⍝ To ensure parens: ::UNQ(("str1" "str2"))
          ⍝ Alias: ::DEQ
            pUNQe←'::(?:UN|DE)Q\h*(',pMatchParens,')'
            str←pSkipE pUNQe ⎕R {
              0=⍵.PatternNum: ⍵ ∆FLD 0
            ⍝ Removes any balanced (single) quote patterns
            ⍝ and adjusts internal quotes...
              pSQe ⎕R {∆UNQ ⍵ ∆FLD 0}⊣1↓¯1↓⍵ ∆FLD 1  ⍝ Omit outermost parens
            }str
          ⍝ Do we scan the string again?
          ⍝ It might be preferable to recursively scan code segments
          ⍝ that might have macros or special elements, 
          ⍝ but for naive simplicity, we simply
          ⍝ rescan the entire string every time it changes.
          ⍝ In case there is some kind of runaway replacements 
          ⍝ (e.g. ::DEF A←B and ::DEF B←A), we won't rescan more than
          ⍝ __MAX__EXPAND__ times. 
            str≡strIn:str
            _←nmsFnd← ⍬ ⊣ mHideAll nmsFnd
            (⍺-1)∇ str
          }str
          str
        }

      ⍝ -------------------------------------------------------------------------
      ⍝ PATTERNS
      ⍝ [1] DEFINITIONS -
      ⍝ [2] PATTERN PROCESSING
      ⍝ -------------------------------------------------------------------------

      ⍝ -------------------------------------------------------------------------
      ⍝ [1] DEFINITIONS
      ⍝ -------------------------------------------------------------------------
        _CTR_←0 ⋄ patternList←patternName←⍬
      ⍝ PREFIX: Sets the prefix string for ∆PRE directives.
      ⍝      Default '::' or ∆CALLR.∆PRE_PREFIX, if set.
      ⍝      Must be a char scalar or vector; treated as a regexp literal.
        PREFIX←'∆PRE_PREFIX'{0≠∆CALLR.⎕NC ⍺:∆CALLR.⎕OR ⍺ ⋄ ⍵}'::'     

      ⍝ regDirective:    name [isD:1] ∇ pattern
      ⍝ ⍺: name [isDirctv]. 
      ⍝    name:  name of pattern. 
      ⍝    isD:   1 (default) "pattern is a directive"; else "is not...".
      ⍝           If 1, prefix pattern with _pDirectivePfx, '::' etc.
      ⍝ Updates externals: patternList, patternName.
      ⍝ Returns the current pattern number (0 is first).
        regDirective←{  
          (nm isD)←2↑1,⍨⊆⍺  
          p←'(?xi)',isD/_pDirectivePfx
          patternList,←pat←⊂∆MAP p,⍵
          '⍎'∊pat:11 ⎕SIGNAL⍨'∆PRE Internal Error: ⍎var in pattern not replaced: "',pat,'"' 
          patternName,←⊂nm 
          (_CTR_+←1)⊢_CTR_
        }
        ⋄ _pDirectivePfx←'^\h* \Q',PREFIX,'\E \h*'
        ⋄ _pTarg←' [^ ←]+ '
        ⍝ _pSetVal:  /← value/, NOT optional (optl add ?): f[N+0]=arrow, f[N+1] value
        ⋄ _pSetVal←' (?:(←)\h*(.*))'    
        ⋄ _pFiSpec←'  (?: "[^"]+")+ | (?:''[^'']+'')+ | ⍎_pName '
      ⍝ Note that we allow a null \0 to be the initial char. of a name.
      ⍝ This can be used to suppress finding a name in a replacement,
      ⍝ and \0 will be removed at the end of processing.
      ⍝ This is mostly obsolete given we suppress macro definitions on recursion
      ⍝ so pats like  ::DEF fred← (⎕SE.fred) will work, rather than run away.
      ⍝ Names may be of form 
      ⍝     fred123,  ⎕fred123 (same as ⎕FRED123), 
      ⍝     :fred123 (same as :FRED123)
      ⍝ and ::fred123 (same as ::FRED123)
      ⍝ Note that dfn sequences like 1: :FRED123 can be confused
      ⍝      with 1 ::FRED123 if spacing isn't right...
        ⋄ _pShortNm←'  [\0]?(?::{1,2}|⎕)?[\pL∆⍙_\#] [\pL∆⍙_\#0-9]*'
        ⋄ _pShortNmPfx←' (?<!\.) ⍎_pShortNm '
        ⋄ _pLongNmOnly←' ⍎_pShortNm (?: \. ⍎_pShortNm )+'      ⍝ Note: Forcing Longnames to have at least one .
        ⋄ _pName←'(?:    ⍎_pShortNm (?: \. ⍎_pShortNm )* )'         ⍝ _pName - long OR short
      ⍝ patterns mostly  for the ∇macroExpand∇ fn
      ⍝ User cmds: ]... (See also ⎕UCMD)
        pUserE←'^\h*\]\h*(.*)$'
      ⍝ Triple-double quote strings are multiline comments (never quotes), replaced by blanks!
      ⍝      """... multiline ok """    ==> ' '
        pDQ3e←'(?sx)  "{3} .*? "{3}'
      ⍝ Double quote suffixes:   [R/r] plus [S/s] or [M/m] or [V/v]
      ⍝ R/r, Raw: don't remove leading blanks. Else, do.
      ⍝ S/s, return single string with embedded newlines.
      ⍝ V/v, return vector of strings, split at newlines.
      ⍝ M/m  returns a matrix (padded with blanks).
        pDQe←'(?ix) (    (?: " [^"]*     "  )+ )   ([VSMR]{0,2}) '
        _pSQe←'(?: ''[^'']*'' )+ '
        pSQe←'(?x)  (    (?: ''[^'']*'' )+  )'          ⍝ Allows multiline sq strings- prevented elsewhere.
        pCommentE←'(?x)      ⍝ .*  $'
      ⍝ Use pSkipE when you are scanning SQs or Comments merely to skip them
        pSkipE←'(?x)  (?: (?: ''[^'']*'' )+  |  ⍝ .*  $)'
      ⍝ _pNum: A non-complex signed APL number (float or dec)
        ⋄ _pNum←' (?: ¯?  (?: \d+ (?: \.\d* )? | \.\d+ ) (?: [eE]¯?\d+ )?  )'~' '
        ⋄ _pDot←'(?:  … | \.{2,} )'
        ⋄ _pCh1←' ''(?: [^''] | ''{2} ) '' ' ⋄ _pCh2←' '' (?: [^''] | ''{2} ){2} '' '
        ⋄ _pDot1e←'  (?| ( ⍎_pNum (?: \h+ ⍎_pNum)*          ) \h* ⍎_pDot \h* (⍎_pNum) '
        ⋄ _pDot1e,←'   | ( ⍎_pCh1 (?: \h+ ⍎_pCh1)* | ⍎_pCh2 ) \h* ⍎_pDot \h* (⍎_pCh1) ) '
        pDot1e←∆MAP'(?x)   ⍎_pDot1e'
        pDot2e←∆MAP'(?x)   ⍎_pDot'
      ⍝ Special Integer Constants: Hex (ends in X), Big Integer (ends in I)
        ⋄ _pHex←'   ¯? (\d  [\dA-F]*)             X'
      ⍝ Big Integer: f1: bigint digits, f2: exponent... We'll allow non-negative exponents but not periods
        ⋄ _pBigInt←'¯? (\d+) (?: E (\d+) )? I'
      ⍝ pSpecialIntE: Allows both bigInt format and hex format
      ⍝ This is permissive (allows illegal options to be handled by APL),
      ⍝ but also VALID bigInts like 12.34E10 which is equiv to 123400000000
      ⍝ Exponents are invalid for hexadecimals, because the exponential range
      ⍝ is not defined/allowed.
        pSpecialIntE←∆MAP'(?xi)  (?<![\dA-F\.]) (?| ⍎_pHex | ⍎_pBigInt ) '

      ⍝ For MACRO purposes, names include user variables, as well as those with ⎕ or : prefixes (like ⎕WA, :IF)
      ⍝ pLongNmE Long names are of the form #.a or a.b.c
      ⍝ pShortNmE Short names are of the form a or b or c in a.b.c
        pLongNmE←∆MAP'(?x)  ⍎_pLongNmOnly'
        pShortNmE←∆MAP'(?x) ⍎_pShortNmPfx'       ⍝ Can be part of a longer name as a pfx. To allow ⎕XX→∆XX
      ⍝ Convert multiline quoted strings "..." to single lines ('...',CR,'...')
        pContE←'(?x) \h* \.{2,} \h* (   ⍝ .*)? \n \h*'
        pEOLe←'\n'
      ⍝ Pre-treat valid input ⍬⍬ or ⍬123 as APL-normalized ⍬ ⍬ and ⍬ 123 -- makes Atom processing simpler.
        pZildeE←'\h* (?: ⍬ | \(\) ) \h*'~' '

      ⍝ Simple atoms: names and numbers (and zilde)
      ⍝ Syntax:
      ⍝       (atom1 [atom2...] → ...) and (` atom1 [atom2])
      ⍝                                and (``atom1 [atom2])
      ⍝ where 
      ⍝        atom1 is either of the format of an APL name or number or zilde
      ⍝           a_name, a.qualified.name, #.another.one
      ⍝           125,  34J55, 1.2432423E¯55, ⍬
        ⋄ _pNum←'(?: ¯?\.?\d[¯\dEJ.]* )'       ⍝ Overgeneral, letting APL complain of errors
        ⋄ _pNums←'(?: ⍎_pNum (?: \h+ ⍎_pNum )*)'    ⍝ Ditto
        ⋄ _pAtom←'(?: ⍎_pName | ⍎_pNum | ⍬ )'
        ⋄ _pAtoms←' ⍎_pAtom (?: \h+ ⍎_pAtom )*'
        
      ⍝ Function atoms: dfns, parenthesized code
      ⍝ Syntax:   
      ⍝    ` fn1 [ fn2 [ fn3 ] ... ]
      ⍝      where fnN  must be in braces (a dfn) or parentheses (a fork or APL fn name)
      ⍝        {⍺⍳⍵}, (+.×) (sum ÷ tally)  (ave)   
      ⍝      where sum and tally might be defined as
      ⍝        sum←+/ ⋄ tally←≢                         
      ⍝      and ave perhaps a tradfn name, a dfn name, or a named fork or other code
      ⍝        ave←(+/÷≢)  or   ⎕FX 'r←ave v' 'r←(+/v)÷≢v' et cetera.
      ⍝ Function atoms are not used to the left of a right arrow (see atom → value above)
      ⍝ Note: a 2nd ` is not allowed for function atoms.
        _←'(?: (?J) (?<Brace⍎_BRN> \⍎_BRL (?> [^⍎_BRL⍎_BRR''⍝]+ | ⍝.*\R | (?: "[^"]*")+ '
        _,←'        | (?:''[^'']*'')+ | (?&Brace⍎_BRN)*     )+ \⍎_BRR)'
        _,←') '
        (_BRL _BRR _BRN)←'{}1' 
        ⋄ pMatchBraces←'(?xi)',_pBrace←∆MAP _ 
        ⋄ _pBraceX←_pBrace,'(?:\h*&)?'
        (_BRL _BRR _BRN)←'()2' 
        ⋄ pMatchParens←'(?xi)',_pParen←∆MAP _
        _L←_R←'(?xi) ',CR
      ⍝ allowFnAtomsInMap OPTION: 
      ⍝ Select whether function atoms 
      ⍝    {...} (...) 
      ⍝ are allowed to left of an (atom) map: ... → ... 
      ⍝ Right now a dfn {...} or (code) expression to the left of an arrow → 
      ⍝ is rejected as an atom: 
      ⍝   only names, numbers, zilde or quoted strings are allowed.
      ⍝ To allow, enable here:
        allowFnAtomsInMap←1/' ⍎_pBraceX | ⍎_pParen | '
        _L,←'(?(DEFINE) (?<atomL>   ⍎allowFnAtomsInMap    ⍎pSQe | ⍎_pName | ⍎_pNum | ⍬))',CR
      ⍝                                              incl. ⎕NULL
        _R,←'(?(DEFINE) (?<atomR>   ⍎_pBraceX | ⍎_pParen | ⍎pSQe | ⍎_pName | ⍎_pNum | ⍬))',CR
      ⍝                                              incl. ⎕NULL   
        _L,←'(?(DEFINE) (?<atomsL>  (?&atomL) (?: \h* (?&atomL) )* ))',CR
        _R,←'(?(DEFINE) (?<atomsR>  (?&atomR) (?: \h* (?&atomR) )* ))',CR
        _L _R←∆MAP¨ _L _R
        pAtomListR←_R,' (?<punct>`[` ]*)         (?<atoms>(?&atomsR))',CR
        pAtomListL←_L,' (?<atoms>(?&atomsL)) \h* (?<punct>→[→ ]*) ',CR 
        pAtomTokens←∆MAP¨(⊂'(?xi)'),¨_pBraceX  _pParen pSQe '⎕NULL\b' _pName _pNum '⍬'
      ⍝ pExpression - matches \(anything\) or an_apl_long_name
        pExpression←∆MAP'⍎_pParen|⍎_pName'
      ⍝ ::ENUM patterns
        pEnumE←∆MAP '(?xi) ',PREFIX,'ENUM  (?: \h+ ( ⍎_pName ) \h*←?)* \h* ((?: ⍎pMatchBraces \h*)+)'
        pEnumEach←∆MAP '(?xi) (⍎pMatchBraces)'
      ⍝ Items may be terminated by commas or semicolons... 
      ⍝ No parens are allowed in enumerations, so we don't need to go recursive. Disallowed: (this;that;more)
        _Beg _End ←'(?<=[{,;])' '(?=\h*[,;}])'  
        _Var←'(?: ⎕?[∆⍙\[\]\w¯\s]+ )'  ⍝ Grab even invalid var. names, so ;:ENUM can report errors.
        _Atoms←'(?: (⍎pSQe | ⍎_pName | ⍎_pNum) \h* )+'
      ⍝ colon: [:→]  increment: [+] ONLY.
        _ColOpt _ColSP _Incr← '(?: \h* (?: [:→] \h*)?) ' '\h* [:→] \h*' '[+]\h* ⍎_pNums?'
        pEnumSub←∆MAP '(?xi) ⍎_Beg \h* (⍎_Var) (?| ⍎_ColOpt (⍎_Incr) | ⍎_ColSP (⍎_pNums | ⍎_Atoms) )?? ⍎_End'  
      ⍝                                 ↑ F1:name      ↑ F2:val  
        pListAtoms←∆MAP'(?xi)(?: ⍎_pSQe | ⍎_pName | ⍎_pNum  )'      
      ⍝ String/Name catenation variables:  n1∘∘n2 "s1"∘∘"s2"
        pSQcatE←'(?x) ( (?: '' [^'']* '' )+) \h* ∘∘ \h* ((?1))'
        pCatNamesE←'(?<=[\w⎕⍙∆])\h*∘∘\h*(?=[\w⎕⍙∆])'      
      ⍝ static pattern: \]?  ( name? [ ← code]  |  code_or_APL_user_fn )
      ⍝                 1      2      3 4         4      
      ⍝  We allow name to be optional to allow for "sinks" (q.v.).           
        _pStatBody←'(\]?) \h* (?|(⍎_pName)? \h* ⍎_pSetVal? | ()() (.*) )'
      ⍝              2            3:name        4:← 5:val     3 4  5:code
      ⍝ For statics,   If an assignment, 2 is opt'l; 3, 4, and 5 are present.
      ⍝                If code, 2 may be present, as well as just 5.
      ⍝                Note that _pName's don't include bare '⎕', just ⎕names.
      ⍝ For constants, must be an assignment:
      ⍝                2 must be null; 3, 4, and 5 must be present.
      ⍝                This is validated in cCONST code so the diagnostics are helpful.
      ⍝ Directive Patterns
      ⍝ For simplicity, these all now follow all basic intra-pattern definitions
        cIFDEF←'ifdef'regDirective'   IF(N?)DEF     \h+(~?.*)                            $'
        cIF←'if'regDirective'         IF            \h+(.*)                              $'
        cELSEIF←'elseif'regDirective' EL(?:SE)?IF \b\h+(.*)                              $'
        cELSE←'else'regDirective'     ELSE        \b                          .*         $'
        cEND←'end'regDirective'       END                                     .*         $'
        cDEF←'def'regDirective'       DEF(?:INE)?(Q)?  \h* (⍎_pTarg)    \h* ⍎_pSetVal?   $'
        cVAL←'val'regDirective'       E?VAL(Q)?        \h* (⍎_pTarg)    \h* ⍎_pSetVal?   $'
        cSTAT←'stat'regDirective'     (STATIC)         \h* ⍎_pStatBody                   $'
        cCONST←'const'regDirective'   (CONST)          \h* ⍎_pStatBody                   $'
        cINCL←'include'regDirective'  INCL(?:UDE)?     \h* (⍎_pFiSpec)           .*      $'
        cIMPORT←'import'regDirective' IMPORT           \h* (⍎_pName)  (?:\h+ (⍎_pName))? $'
        cCDEF←'cond'regDirective'     CDEF(Q)?         \h* (⍎_pTarg)     \h*   ⍎_pSetVal?$'
        cWHEN←'do if'regDirective'    (WHEN|UNLESS)    \h+ (~?)(⍎pExpression) \h(.*)     $'
        cUNDEF←'undef'regDirective'   UNDEF            \h* (⍎_pName )            .*      $'
        cTRANS←'trans'regDirective'   TR(?:ANS)?       \h+  ([^ ]+) \h+ ([^ ]+)  .*      $'
        cWARN←'warn'regDirective'     (WARN(?:ING)?|ERR(?:OR)?|MSG|MESSAGE) \b\h*  (.*)  $'
        cMAGIC←'magic'regDirective'   MAGIC \h* (\d+)? \h+ (⍎_pName) \h* ← \h*  (.*)     $'
        cOTHER←'other' 0 regDirective' ^                                         .*      $'
      ⍝              ↑___ 0: 0 means "not a directive; no prefix added."
      ⍝ -------------------------------⌈------------------------------------------
      ⍝ [2] PATTERN PROCESSING
      ⍝ -------------------------------------------------------------------------
        processDirectives←{
          T F S←1 0 ¯1       ⍝ true, false, skip
          __LINE__+←1
        
          f0 f1 f2 f3 f4←⍵ ∆FLD¨0 1 2 3 4
          
          case←⍵.PatternNum∘∊
          TOP←⊃⌽stack     ⍝ TOP can be T(true) F(false) or S(skip)...

        ⍝ Any non-directive, i.e. APL statement, comment, or blank line...
        ⍝ We scan APL lines statement-by-statement
        ⍝ E.g.  ' stmt1 ⋄ stmt2 ⋄ stmt3 ' 
          case cOTHER:{
            T≠TOP:annotate f0,SKIPch             ⍝ See annotate, QUIET
            stmts←pSkipE '⋄' ⎕R '\0' '⋄\n'⊣⊆f0   ⍝ Find APL stmts (⋄)
            str←∊macroExpand¨ stmts              ⍝ Expand macros by stmt and reassemble
            QUIET:str ⋄ str≡f0:str
            '⍝',f0,YESch,NL,' ',str
          }⍵

        ⍝ ::IFDEF/IFNDEF name
          case cIFDEF:{
            T≠TOP:annotate f0,SKIPch⊣stack,←S
            stack,←c←~⍣(1∊'nN'∊f1)⊣mHasDef f2 
            annotate f0,' ➡ ',(⍕c),(c⊃NOch YESch)
          }⍵

        ⍝ ::IF cond
          case cIF:{
            T≠TOP:annotate f0,SKIPch⊣stack,←S
            stack,←c←∆TRUE(e←macroExpand f1)
            annotate f0,' ➡ ',(⍕e),' ➡ ',(⍕c),(c⊃NOch YESch)
          }⍵

        ⍝  ::ELSEIF
          case cELSEIF:{
          ⍝ was: S=TOP:annotate f0,SKIPch⊣stack,←S
            S=TOP:annotate f0,SKIPch⊣(⊃⌽stack)←S
            T=TOP:annotate f0,NOch⊣(⊃⌽stack)←S
            (⊃⌽stack)←c←∆TRUE(e←macroExpand f1)
            annotate f0,' ➡ ',(⍕e),' ➡ ',(⍕c),(c⊃NOch YESch)
          }⍵

        ⍝ ::ELSE
          case cELSE:{
          ⍝ was:  S=TOP:annotate f0,SKIPch⊣stack,←S
            S=TOP:annotate f0,SKIPch⊣(⊃⌽stack)←S
            T=TOP:annotate f0,NOch⊣(⊃⌽stack)←S
            (⊃⌽stack)←T
            annotate f0,' ➡ 1',YESch
          }⍵

        ⍝ ::END(IF(N)(DEF))
          case cEND:{
            stack↓⍨←¯1
            c←S≠TOP
            0=≢stack:annotate'   ⍝??? ',f0,NOch⊣stack←,0⊣print'INVALID ::END statement at line [',__LINE__,']'
            annotate f0
          }⍵

        ⍝ Shared code for
        ⍝   ::DEF(Q) and ::(E)VALQ
          procDefVal←{
            isVal←⍺
            T≠TOP:annotate f0,(SKIPch NOch⊃⍨F=TOP)
            ' '∊f2:annotate f0,'    ⍝ ',print'IGNORING INVALID MACRO NAME: "',f2,'" ',NOch
            qtFlag arrFlag←0≠≢¨f1 f3
            val note←f2{
              (~arrFlag)∧0=≢⍵:(∆QTX ⍺)''
              0=≢⍵:'' '  [EMPTY]'
              exp←macroExpand ⍵
              isVal:{                   ⍝ ::EVAL | ::VAL
                m←'WARNING: INVALID EXPRESSION DURING PREPROCESSING'
                0::(⍵,' ∘∘INVALID∘∘')(m⊣print m,': ',⍵)
                qtFlag:(∆QTX⍕⍎⍵)''
                (⍕⍎⍵)''
              }exp
              qtFlag:(∆QTX exp)''       ⍝ ::DEFQ ...
              exp''                     ⍝ ::DEF  ...
            }f4
            _←mPut f2 val
            nm←PREFIX,(isVal⊃'DEF' 'VAL'),qtFlag/'Q'
            f0 annotate nm,' ',f2,' ',f3,' ',f4,' ➡ ',val,note,' ',YESch
          }

        ⍝ ::DEF family: Definitions after macro processing.
        ⍝ ::DEF | ::DEFQ
        ⍝ ::DEF name ← val    ==>  name ← 'val'
        ⍝ ::DEF name          ==>  name ← 'name'
        ⍝ ::DEF name ← ⊢      ==>  name ← '⊢'     Make name a NOP
        ⍝ ::DEF name ←    ⍝...      ==>  name ← '   ⍝...'
        ⍝   Define name as val, unconditionally.
        ⍝ ::DEFQ ...
        ⍝   Same as ::DEF, except put the resulting value in single-quotes.
          case cDEF:0 procDefVal ⍵

        ⍝  ::VAL family: Definitions from evaluating after macro processing
        ⍝  ::EVAL | ::EVALQ
        ⍝  ::VAL  | ::VALQ   [aliases for EVAL/Q]
        ⍝  ::[E]VAL name ← val    ==>  name ← ⍎'val' etc.
        ⍝  ::[E]VAL i5   ← (⍳5)         i5 set to '(0 1 2 3 4)' (depending on ⎕IO)
        ⍝    Returns <val> executed in the caller namespace...
        ⍝  ::EVALQ: like EVAL, but returns the value in single quotes.
        ⍝    Experimental preprocessor-time evaluation
          case cVAL:1 procDefVal ⍵

        ⍝ ::CDEF family: Conditional Definitions
        ⍝ ::CDEF name ← val      ==>  name ← 'val'
        ⍝ ::CDEF name            ==>  name ← 'name'
        ⍝ Set name to val only if name NOT already defined.
        ⍝ ::CDEFQ ...
        ⍝ Like ::CDEF, but returns the value in single quotes.
          case cCDEF:{
            T≠TOP:annotate f0,(SKIPch NOch⊃⍨F=TOP)
            mHasDef f2:annotate f0,NOch      ⍝ If <name> defined, don't ::DEF...
            qtFlag arrFlag←0≠≢¨f1 f3
            val←f2{(~arrFlag)∧0=≢⍵:∆QTX ⍺ ⋄ 0=≢⍵:''
              exp←macroExpand ⍵
              qtFlag:∆QTX exp
              exp
            }f4
            _←mPut f2 val
            f0 annotate PREFIX,'CDEF ',f2,' ← ',f4,' ➡ ',val,(' [EMPTY] '/⍨0=≢val),' ',YESch
          }⍵

        ⍝  ::MAGIC \h* [digits] name ← apl_code 
        ⍝      digits: ∊0, 1, 2; the required environment (namespace); see mPutMagic.
        ⍝              defaults to 0.
        ⍝      name:   macro name being defined
        ⍝      apl_code: code to be executed in the specified environment.
        ⍝  Does an internal mPutMagic call...
        ⍝  There is no reason for this to be exposed except to test perhaps.
          case cMAGIC:{
            T≠TOP:annotate f0,(SKIPch NOch⊃⍨F=TOP)
            type←1↑⊃⌽⎕VFI f1 ⋄ name code←f2 f3  
            ~type∊0 1 2:annotate f0,NOch
            _←type mPutMagic name code
            f0 annotate '::MAGIC ',(⍕type),' ',name,' ← ',code,' ',YESch
          }⍵

        ⍝ ::WHEN / ::UNLESS
        ⍝ ::WHEN  [~]expression arbitrary_code
        ⍝         "If the expression is true, execute the arbitrary code"
        ⍝   0=≢f1  f2 f3         f5          (expression also sets f3)
        ⍝ ::UNLESS   expression arbitrary_code
        ⍝          "If the expression is false, execute the arbitrary code"
        ⍝   0≠≢f1  f2 f3        f5
        ⍝   The inverse of ::WHEN, i.e. true when ::WHEN would be false and vv.
        ⍝
        ⍝ expression: Preprocessor expression, 
        ⍝        either  \( anything \) or arbitrary_apl_name
        ⍝                (A + B)           COLOR.BROWN
        ⍝    If e is invalid or undefined, its value as an expression is FALSE.
        ⍝    Thus ~e is then TRUE.
        ⍝        If name FRED is undefined,  JACK is 1, and MARY is 0
        ⍝          Expression         Value
        ⍝             FRED            FALSE
        ⍝            ~FRED            TRUE
        ⍝             JACK            TRUE
        ⍝            ~JACK            FALSE
        ⍝             MARY            FALSE
        ⍝            ~MARY            TRUE
        ⍝           ~(FRED)           TRUE     ~ outside expression flips FALSE to TRUE.
        ⍝           (~FRED)           FALSE    Can't eval ~FRED
        ⍝ arbitrary_code: Any APL code, whose variable names are defined via ::DEF.
        ⍝ ------------------
        ⍝ ::WHEN or ::UNLESS
          case cWHEN:{
            T≠TOP:annotate f0,(SKIPch NOch⊃⍨F=TOP) 
            flip←('u'=lc 1↑f1)+1=≢f2          ⍝ f1 is WHEN or UNLESS [any case]           
            isTrue←2|flip+∆TRUE (f3a←macroExpand f3) 
            isTrue:(annotate f0,' ➡ ',f3a,' ➡ true',YESch),NL,macroExpand ⍵ ∆FLD 5    
            annotate f0,' ➡ false',NOch   
          }⍵

        ⍝ ::UNDEF - undefines a name set via ::DEF, ::VAL, ::STATIC, etc.
        ⍝ ::UNDEF name
        ⍝ Warns if <name> was not set!
          case cUNDEF:{
            T≠TOP:annotate f0,(SKIPch NOch⊃⍨F=TOP)
            _←mDel f1⊣{mHasDef ⍵:'' ⋄ warningCount+←1 ⋄ print INFOch,' WARNING: UNDEFining an undefined name: ',⍵}f1
            annotate f0,YESch
          }0

        ⍝ ::CONST  - declares persistent name (only) and value, which
        ⍝            may NOT be changed in ::STATIC time or runtime.
        ⍝            Its value may depend on local or external variables
        ⍝            visible at ::STATIC time.
        ⍝ ::CONST name ← value
        ⍝ - - - - - - - - - - 
        ⍝ ::STATIC - declares persistent names, defines their values,
        ⍝            or executes code @ preproc time.
        ⍝   1) declare names that exist between function calls. See ⎕MY/∆MY
        ⍝   2) create preproc-time static values,
        ⍝   3) execute code at preproc time
        ⍝ ∘ Note: expressions of the form
        ⍝     ::STATIC name   or   ::STATIC ⎕NAME 
        ⍝   are interpreted as type (1), name declarations.
        ⍝   To ensure they are interpreted as type (3), code to execute at preproc time,
        ⍝   prefix the code with a ⊢, so the expression is unambiguous. E.g.
        ⍝     ::STATIC ⊢myFunction 'data'
        ⍝     ::STATIC ⊢⎕TS
        ⍝ ∘ Dyalog user commands are of the form:  ]user_cmd or ]name ← user_cmd
          case cSTAT cCONST:{
            T≠TOP:annotate f0,(SKIPch NOch⊃⍨F=TOP)
            type usr nm arrow←f1 f2 f3 f4      ⍝  f1: ]user_cmd, f2 f3: name ←
            valIn←⍵ ∆FLD 5  
            isConst←'c'=lc⊃type             ⍝ ::CONST
            isSink←0 0 1∧.=×≢¨usr nm arrow  ⍝ ::STATIC ← value
          ⍝ ::CONST expressions must have explicit assignments.  
            isConst∧0=≢nm: annotate f0,ERRch,' ⍝ ::CONST ERROR: Left-most expression must be of form "simple_name ←"'     
          ⍝ If we have a sink expression ::STATIC ← value, acquire a name.   
            nm←{⍵=0: nm ⋄ getTempName 1}isSink 
          ⍝ Get expansion of expression <valIn>
            val←{
            ⍝ [1a] Not a user command: expand and scan for (;;;)
              0=≢usr:∊scan4Semi macroExpand ⍵     ⍝ User command?
            ⍝ [1b] ]USER COMMANDS
            ⍝      Accept also ]name← USER COMMANDS and assign result to name.
            ⍝      Call ⎕SE.UCMD.
              usr←∆MY,' ⎕SE.UCMD ',∆QTX nm,arrow,⍵    ⍝ ]name ← val or  ]val
              usr⊣nm∘←arrow∘←''
            }valIn
          ⍝ If the expansion to <val> changed <valIn>, note in output comment
            expMsg←''  ( ' ➡ ',val )⊃⍨ val≢valIn
          ⍝ [2] A STATIC code stmt, not an assignment or declaration.
          ⍝     Evaluate at compile time and return the result as a string.
            0=≢nm:(annotate f0,expMsg,okMsg),more⊣(okMsg more)←{
              0::NOch res ⊣ res←{
                invalidE←'∆PRE ::',type,' WARNING: Unable to execute expression'
                _←NL,'⍝>  '
                _,←print invalidE,NL,'⍝>  ',⎕DMX.EM,' (',⎕DMX.Message,')',NL
                warningCount+←1
                _,'∘[1] static err∘'
              }0
              YESch''⊣∆MYR⍎val,'⋄1'
            }0

          ⍝ CONTINUE? Only if a declaration or assignment.
          ⍝  [3a] Process ::STATIC name          - declaration
          ⍝  [3b] Process ::STATIC name ← value  - declaration and assignment
          ⍝       Process ::CONST  name ← value  - decl. and assign (only CONST option)
          
          ⍝ isFirstDef: See ⎕EX below.
            isNew←~mHasDef nm ⋄ isFirstDef←⍬⍴isNew∧~'#⎕'∊⍨1↑nm
          ⍝  Warn if <nm> has already been declared this session.
            _←{ isNew∨0=≢val:''
              _←dPrint'Note: ',type,' "',nm,': has been redeclared'
              dPrint'>     Value now "',val,'"'  
            }0

          ⍝ Evaluate STATIC and CONST assignments. Skip if not an assignment.
            okMsg errMsg←{
              0=≢arrow:YESch''     ⍝ If no assignment, ignore...
            ⍝  ::STATIC error handling...
              staticErrors←{
                warningCount+←1
                invalidE←'∆PRE ',PREFIX,type,' WARNING: Unable to execute expression'
                _←NL,'⍝>  '
                _,←print(invalidE,NL,'⍝>  ',⎕DMX.EM,' (',⎕DMX.Message,')'),NL
                _,'∘[2]',type,' err∘'
              }
            ⍝ Erase nm's value iff it's the first declaration of the object.
              _←∆MYR.⎕EX⍣isFirstDef⊣nm
            ⍝ ::CONST name←val 
              isConst:{ 
                _←nm setStaticConst val   ⍝ handles errors...
                YESch'' 
              }0 
              0::NOch(staticErrors 0)
            ⍝ ::STATIC name←val 
              _←mPut nm(∆MY,'.',nm) ⋄  _←∆MYR⍎nm,'←',val,'⋄1'
              YESch''
            }0
          ⍝ If a "sinking" construction,  ::STATIC ← value,
          ⍝ let the user know the generated temporary name.
            sinkMsg←{   
              isSink: NL,f0 annotate PREFIX,type,' ',nm,'←',val,okMsg ⋄ ''
            }0
            (annotate f0,expMsg,okMsg),sinkMsg,errMsg
          }⍵

        ⍝ ::INCLUDE - inserts a named file into the code here.
        ⍝ ::INCLUDE file or "file with spaces" or 'file with spaces'
        ⍝ If file has no type, .dyapp [dyalog preprocessor] or .dyalog are assumed
          case cINCL:{
            T≠TOP:annotate f0,(SKIPch NOch⊃⍨F=TOP)
            __FILE__←∆UNQ f1
            _←dPrintQ INFOch,2↓(bl←+/∧\f0=' ')↓f0
            (_ fullNm dataIn)←getDataIn __FILE__
            _←dPrintQ',',msg←' file "',fullNm,'", ',(⍕≢dataIn),' lines',NL
            _←fullNm{
              includedFiles,←⊂⍺
              ~⍵∊⍨⊂⍺:⍬
            ⍝ See ::extern __INCLUDE_LIMITS__
              count←+/includedFiles≡¨⊂⍺
              warn err←(⊂INFOch,PREFIX,'INCLUDE '),¨'WARNING: ' 'ERROR: '
              count≤1↑__INCLUDE_LIMITS__:⍬
              count≤¯1↑__INCLUDE_LIMITS__:print warn,'File "',⍺,'" included ',(⍕count),' times'
              11 ⎕SIGNAL⍨err,'File "',⍺,'" included too many times (',(⍕count),')'
            }includedFiles
            includeLines∘←dataIn
            annotate f0,' ',INFOch,msg
          }⍵

        ⍝ ::IMPORT name [extern_name]
        ⍝ Imports name (or, if extern_name specified: imports extern_name as name)
        ⍝ Reads in the value of a variable, then converts it to a ⍕value.
        ⍝ If its format is unusable (e.g. in a macro), that's up to the user.
          case cIMPORT:{
            f2←f2 f1⊃⍨0=≢f2
            T≠TOP:annotate f0,(SKIPch NOch⊃⍨F=TOP)
            info←' ','[',']',⍨{
              0::'UNDEFINED. ',(∆DQT f2),' NOT FOUND OR NOT CONVERTIBLE',NOch⊣mDel f1
              val←{
              ⍝ Not a single-line object? Return original!
                1≠⊃⍴v←⎕FMT ⍵:∘∘        
                0=80|⎕DR⍵:∆QT ∊v      ⍝ Char. strings  quoted
                ∊v                    ⍝ Otherwise, not.
              }∆CALLR.⎕OR f2
              'IMPORTED'⊣mPut f1 val
            }⍬
            annotate f0,info
          }⍬

        ⍝ ::TRANS / ::TR - translate a single character on input.
        ⍝ ::TRANS ⍺ ⍵    Translate char ⍺ to ⍵
        ⍝ Affects only user code ('macro' scanning)
          case cTRANS:{
            T≠TOP:annotate f0,(SKIPch NOch⊃⍨F=TOP)
            info←''
            f1 f2←{ ⍝ bad code: ¯1, else a character...
              0::¯1
              0=≢⍵:¯1 ⋄ info,←' →'/⍨0≠≢info
              (1=≢⍵)∧⍵≡,'\':' '⊣info,←' " " U+32'             ⍝ \ch2    (ch2=' ')
              1=≢⍵:⍵⊣info,←' U+',⍕⎕UCS ⍵                      ⍝ ch1
              c←⍵↓⍨esc←'\'=⊃⍵
              ⋄ escC←esc∧(~⎕D∊⍨⊃c)∧1=≢c
              escC:c⊣info,←' U+',⍕⎕UCS c                      ⍝ \c, ~(c∊⎕D)
              ⋄ hex←1∊'xX'∊⍵
              c←⎕UCS u←hex{⍺:∆H2D ⍵ ⋄ ⍎⍵}c                    ⍝ \dd or dd
              info,←hex/' U+',⍕u
              u≥32:c⊣info,←' "',c,'"'                ⍝ digits  (from hex/dec)
              c⊣info,←' [ctl]'                       ⍝ digits  (ctl char)
            }¨f1 f2
            ¯1∊f1 f2:(annotate f0),NL,'∘',(print f0,NL)⊢print'∆PRE ',PREFIX,'TRANS ERROR'
          ⍝ UPDATE TRANSLATION tables...   
          ⍝ Remove f1, if already in TRANSLATE.in. We may add back below.
            _←(f1=TRANSLATE.in){
              1∊⍺: ⍵.(in out)←(⊂~⍺)/¨⍵.(in out) ⋄ ⍵
            }TRANSLATE
          ⍝ ::TR ch1 ch2    (ch1=ch2) turns off (if on) the translation for that char.
            f1=f2: annotate f0,' ⍝ [OFF] ',info
          ⍝ ::TR ch1 ch2    (ch1 ≠ ch2) turns on the translation for that char.   
            TRANSLATE.in,←f1 ⋄ TRANSLATE.out,←f2
            ⎕←'IN  "',TRANSLATE.in,'"'
            ⎕←'OUT "',TRANSLATE.out,'"'
            annotate f0,' ⍝ [ON]  ',info
          }⍵

          ⍝ ::MSG  msg   💡
          ⍝ ::WARN msg   ⚠️
          ⍝ ::ERR  msg   💩
          case cWARN:{
            T≠TOP:annotate f0,(SKIPch NOch⊃⍨F=TOP)
            f1←∊(msg warn err←'MWE'∊1↑uc f1)/'MESSAGE' 'WARNING' 'ERROR'
            f2←(0=≢f2)⊃f2 ('This is an unspecified user ',f1) 
            annotate PREFIX,f1,' ',f2,YESch,NL, {
              ln←{⍺←2 ⋄ ch←'[',']',⍨⍵ ⋄ ⍺>≢⍵: (-2+⍺)↑ch ⋄ ch}⍕__LINE__
            ⍝ Dyalog bug: takes 6 WARNch to have 3 print out! Sigh.
              _←(3⍴'*'),' ',ln,' ',f1,': ',⍵
              warn: print WARNch, _ ⊣ warningCount+←1 
              err:  print ERRch,  _ ⊣ errorCount+←1
                    print (INFOch~' '), _
            }f2
          }⍵
        }  ⍝ ProcessDirectives

      ⍝ --------------------------------------------------------------------------------
      ⍝ EXECUTIVE
      ⍝ --------------------------------------------------------------------------------
      ⍝ User-settable options
      ⍝ See HELP info above
      ⍝ See below
      ⍝ Set prepopulated macros
        mNames←mVals←mNameVis←⍬
        _←0 mPut'__DEBUG__'__DEBUG__            ⍝ Debug: set in options or caller env.
        _←0 mPut'__VERBOSE__'__VERBOSE__
        _←0 mPut'__MAX_EXPAND__' 10             ⍝ Allow macros to be expanded n times (if any changes were detected).
        ⍝                                       ⍝ Avoids runaway recursion...
        _←0 mPut'__MAX_PROGRESSION__' 500       ⍝ ≤500 expands at preproc time.
        _←0 mPut'__INCLUDE_LIMITS__'(5 10)      ⍝ [0] warn limit [1] error limit
      ⍝ Other user-oriented macros
        _←0 mPut'⎕UCMD' '⎕SE.UCMD'              ⍝ ⎕UCMD 'box on -fns=on' ≡≡ ']box on -fns=on'
        _←0 mPut'⎕DICT' 'SimpleDict '           ⍝ d← {default←''} ⎕DICT entries
                                              ⍝ entries: (key-val pairs | ⍬)
        _←0 mPut'⎕FORMAT' '∆format'             ⍝ Requires ∆format in ⎕PATH...
        _←0 mPut'⎕F' '∆format'                  ⍝ ⎕F → ⎕FORMAT → ∆format
        _←0 mPut'⎕EVAL' '⍎¨0∘∆PRE '
      ⍝ Add ⎕DFNS call - to provide access to common dfns
        _←0 mPut '⎕DFNS' '⎕SE.dfns'
        _←0 mPut '⎕PLOT'  '{⎕SE.UCMD ''Plot '',⍵}'

      ⍝ Write out utility function(s) to ⎕SE
      ⍝ ----
      ⍝ ⍙enum:  Handle quasi-⎕JSON-style enumerations
      ⍝     names (typeName ⍙enum plural)⊣values
      ⍝       names:    one or more names (strings)
      ⍝       typeName: the name of the enumeration type. Used in ⎕DF and often the static type variable name
      ⍝                 Used for elegance (?): to avoid having (,¨typeName) in the preprocessor output.
      ⍝       plural:   1 if more than one name, vs 0 if exactly 1.
      ⍝       values:   one value for each name in <names>
      ⍝       
      ⍝ If ⍺ is specified as a vector of names (string vectors), 
      ⍝ it usually contains the names of nm in original entry order.
      ⍝ That way, ∆ENUMS items etc are navigated as entered.
      ⍝ We don't use ⎕JSON any more. More efficient and compact not to.
      ⍝ ⍺⍺: Annotation from ::ENUM [name1 [etc.] ←]
        ⎕SE.⍙enum←{⎕IO←0
        0:: ('∆PRE: Invalid Enumeration with names "',⍺,'"') ⎕SIGNAL 11
          type←'#.[ENUM',']',⍨('.',⍺⍺) ''⊃⍨0=≢⍺⍺  
        0:: ('∆PRE: Invalid Enumeration with type "',type,'"') ⎕SIGNAL 11 
          ns←#.⎕NS'' ⋄ _←ns.⎕DF type 
          names←⍵⍵{⍺: ,¨⍵ ⋄ ,⊂⍵}⍺   ⍝ If more than one name (⍵⍵), ensure each is a vector.
          vals← ⍵⍵{⍺: ,¨⍵ ⋄ ,⊂⍵}⍵
          _ ←names{ns⍎⍺,'←⍵'
          }¨vals
          ns⊣names{  ns⍎'∆ENUMS←∪⍵ ⋄ ∆NAMES ∆VALS ∆KEYS←⍺ ⍵ (⍺[⍵⍳∆ENUMS])' }vals 
        }
      ⍝ ⍙fnAtom: converts APL function to a function atom (namespace "ptr")
        ⎕SE.⍙fnAtom←{(ns←#.⎕NS⍬).fn←fn←⍺⍺⋄∆←⍕∊⎕NR'fn'⋄0=≢∆:ns⊣ns.⎕DF ⍕fn⋄ns⊣ns.⎕DF ∊∆}
      ⍝ Copy utility functions from dfns to ⎕SE.dfns
        dfnsList←'pco' ⋄ _←'dfns'⎕SE.⎕NS ''
        _← dfnsList ⎕SE.dfns.⎕CY'dfns'
      ⍝ Read in data file...
        __FILE__ fullNm dataIn←getDataIn(⊆⍣(~FIX))⍵
        tmpNm←'__',__FILE__,'__'

      ⍝ Set up ⎕MY("static") namespace, local to the family of objects in <__FILE__>
      ⍝ Then set up FIRST, which is 1 the first time ANY function in <__FILE__> is called.
      ⍝ And set up ∆CONST (for enums and other constants) within ∆MY.
        ∆MY←(⍕∆CALLR),'.⍙⍙.',__FILE__,'.∆MY' 
        ∆MYR←⍎∆MY ⎕NS '' ⊣⎕EX ∆MY  
        _←'∆CONST' ∆MYR.⎕NS ''             ⍝ (Static) constant namespace.
        ∆MYR._FIRST_←1    
        _←∆MYR.⎕FX'F←FIRST' '(F _FIRST_)←_FIRST_ 0'
        _←∆MYR.⎕FX'{F}←RESET' '(F _FIRST_)←~_FIRST_ 0'
        _←mPut        '⎕MY'              ∆MY                     ⍝ ⎕MY    → a private 'static' namespace
        _←mPut        '⎕FIRST'           (∆MY,'.FIRST')          ⍝ ⎕FIRST → ∆MY.FIRST. 1 on 1st call, else 0
        _←mPut        '⎕ME'              '(⊃⎕SI)'                ⍝ Simple name of active function
        _←mPut        '⎕XME'             '(⊃⎕XSI)'               ⍝ Full name of active function
      ⍝  mPutMagic: Declare macros evaluated at ∆PRE time via ⍎.
        _←0 mPutMagic '__LINE__'         '__LINE__'  
        _←0 mPutMagic '__FILE__'         '__FILE__' 
        _←0 mPutMagic '__TS__'           '⎕TS'        
        _←1 mPutMagic '__STATIC__'       '⎕THIS'
        _←2 mPutMagic '__CALLER__'       '⎕THIS'
        _←0 mPutMagic '__TIME__'         '(∆QT ''G⊂ZZ:ZZ:ZZ⊃''   ⎕FMT +/10000 100 1×⎕TS[3 4 5])'
        _←0 mPutMagic '__DATE__'         '(∆QT ''G⊂ZZZZ/ZZ/ZZ⊃'' ⎕FMT +/10000 100 1×⎕TS[0 1 2])'
        _←mPut        '__DATE__TIME__'   '__DATE__ ∘∘ "T" ∘∘ __TIME__'
      ⍝ ⎕T retrieves the most-recently (compile-time) generated temporary name, usually
      ⍝    via a fence:    [left margin | ⋄ etc.] ← val
        _←0 mPutMagic'⎕T' 'getTempName 0'
    
      ⍝ Other Initializations
        stack←,1 ⋄ (__LINE__ warningCount errorCount)←0
        includedFiles←⊂fullNm
        NLINES←≢dataIn ⋄ NWIDTH←⌈10⍟NLINES
        _←dPrint'Processing input object ',(∆DQT __FILE__),' from file ',∆DQT fullNm
        _←dPrint'Object has ',NLINES,' lines'
        dataFinal←⍬
        includeLines←⍬
        comment←⍬

      ⍝ --------------------------------------------------------------------------------
      ⍝ Executive: Phase I
      ⍝ --------------------------------------------------------------------------------
      ⍝ Kludge: We remove comments from all directives up front...
      ⍝ Not ideal, but...
        pInDirectiveE←'^\h*\Q',PREFIX,'\E'
        inDirective←0
      ⍝ Process double quotes and continuation lines that may cross lines
        pNotInSetE←'(?ix) (?: ',(⎕UCS 8713),' | ⎕NOTIN)'

        _pI←pInDirectiveE pDQ3e pDQe pSQe pCommentE pContE
        _pI,←pZildeE pEOLe pNotInSetE 
        cInDirective cDQ3 cDQ cSQ cCm cCn cZilde cEOL cNotInSet ←⍳9
        dataOut← _pI ⎕R{
          f0 f1 f2←⍵ ∆FLD¨0 1 2 ⋄ case←⍵.PatternNum∘∊
        ⍝ spec←⍵.PatternNum⊃'Spec' 'Std' 'DQ' 'SQ' 'CM' 'CONT' 'EOL'
        ⍝ print (¯4↑spec),': f0="',f0,'" inDirective="',inDirective,'"'
          case cInDirective:f0⊣inDirective⊢←1
          case cDQ3:' '                             ⍝ """..."""
          case cDQ:processDQ f1 f2                   ⍝ DQ, w/ possible newlines...
          case cSQ:{                                 ⍝ SQ  - passthru, unless newlines...
            ~NL∊⍵:⍵
            warningCount+←1
            _←print'WARNING: Newlines in single-quoted string are invalid: treated as blanks!'
            _←print'String: ','⤶'@(NL∘=)⍵
            ' '@(NL∘=)⍵
          }f0
          case cCm:f0/⍨~inDirective                  ⍝ COM - passthru, unless in std directive
          case cCn:' '⊣comment,←(' '/⍨0≠≢f1),f1      ⍝ Continuation
          case cZilde:' ⍬ '                          ⍝ Normalize as APL would...
          case cNotInSet:'{~⍺∊⍵}'
        ⍝ When matching abbreviated arrow schemes, try to keep any extra spacing,
        ⍝ so things line up...
          ~case cEOL:⎕SIGNAL/'∆PRE: Logic error' 911
        ⍝ case cEOL triggers comment processing from above
          inDirective⊢←0                                ⍝ Reset  flag after each NL
          0=≢comment:f0
          ln←comment,' ',f1,NL ⋄ comment⊢←⍬
          ⍝ If the commment is more than (⎕PW÷2), put on newline
          (' 'NL⊃⍨(⎕PW×0.5)<≢ln),1↓ln
        }⍠('Mode' 'M')('EOL' 'LF')('NEOL' 1)⊣preamble,dataIn
      ⍝ Process macros... one line at a time, so state is dependent only on lines before...
      ⍝ It may be slow, but it works!
        dataOut←{⍺←⍬
          0=≢⍵:⍺
          line←⊃⍵
          line←patternList ⎕R processDirectives⍠'UCP' 1⊣line
          (⍺,⊂line)∇(includeLines∘←⍬)⊢includeLines,1↓⍵
        }dataOut
      
      ⍝ --------------------------------------------------------------------------------
      ⍝ Executive: PhaseII
      ⍝ --------------------------------------------------------------------------------
      ⍝ condSave ⍵:code
      ⍝    ⍺=1: Keep __name__ (on error path or if __DEBUG__=1)
      ⍝    ⍺=0: Delete __name__ unless error (not error and __DEBUG__=0)
      ⍝ Returns ⍵ with NULLs removed...
        condSave←{⍺←EDIT∨__DEBUG__
          _←⎕EX tmpNm
          ⍺:⍎'∆CALLR.',tmpNm,'←⍵~¨NULL'
          ⍵
        }
      ⍝ ERROR PATH
        999×__DEBUG__::11 ⎕SIGNAL⍨{
          _←1 condSave ⍵
          _←'Preprocessor error. Generated object for input "',__FILE__,'" is invalid.',⎕TC[2]
          _,'See preprocessor output: "',tmpNm,'"'
        }dataOut
        dataOut←condSave dataOut 
      ⍝  ∘ Lines starting with a NULL will be deleted (ignored) on output.
      ⍝    These are generated in 1st phase of deleting comment lines or null lines. 
      ⍝  ∘ Other NULLs anywhere are deleted (ignored) as well.
        dataOut←{NULL~⍨¨⍵/⍨NULL≠⊃¨⍵}{
          ⋄ opts←('Mode' 'M')('EOL' 'LF')
        ⍝ We have embedded newlines for lines with macros expanded: see annotate
        ⍝ [a] ⎕R handles them (per EOL LF). See [b]
          NOCOM:'^\h*(?:⍝.*)?$'⎕R NULL⍠opts⊣⍵    ⍝ Remove blank lines and comments.
          NOBLANK:'^\h*$'⎕R NULL⍠opts⊣⍵          ⍝ Remove blank lines
        ⍝ [b] Explicitly handle embedded NLs
          {⊃,/NL(≠⊆⊢)¨⍵}⍵
        }dataOut
      ⍝ if FIX=1, we may have a tradfn w/o a leading ∇ whose first line needs to be skipped
      ⍝ to avoid treating header semicolons as list separators.
      ⍝ Whether ⍺ is set or not, we'll skip any line with leading ∇.
        dataOut←FIX scan4Semi dataOut
      ⍝ Edit (for review) if EDIT=1
        _←{∆CALLR⍎tmpNm,'←↑⍵'}dataOut  
        _←∆CALLR.⎕ED⍣EDIT⊣tmpNm ⋄ _←∆CALLR.⎕EX⍣(EDIT∧~__DEBUG__)⊣tmpNm
        note←{ 0<⍵: ⎕←'*** There were ',(⍕⍵),' ',⍺ ⋄ ⍬}
        _←'warnings' 'errors'note¨ warningCount errorCount 
        0<errorCount: '∆PRE: Fatal errors occurred' ⎕SIGNAL 911
        FIX:_←2 ∆CALLR.⎕FIX dataOut
        dataOut
      }⍵          ⍝ (1↓⊆,⍺)
    }⍵         ⍝ (⊃⊆,⍺)(⎕NS'').
  }         ⍝ ∆PRE←...
  ##.∆PRE←∆PRE

∇linesOut←{isFn}scan4Semi lines
  ⍝ Look for sequences of sort
  ⍝        (anything1; anything2; ...; anythingN)
  ⍝ and replace with
  ⍝        ( (anything) (anything) ... (anythingN) )
  ⍝ If anythingN is 0 or more blanks, as in
  ⍝        ( anything1; ; and more ;;)
  ⍝ it is replaced by ⍬:
  ⍝        ( (anything1) ⍬ (and more) ⍬)
  ⍝ In general, () is equivalent to ⍬.
    ;LAST;LBRK;LPAR;QUOT;RBRK;RPAR;SEMI;COM
    ;cur_tok;cur_gov;deQ;enQ;inCom;inQt;lineOut;pBareParens;pComment;pSQ;prefix;stack
    ;⎕IO;⎕ML
  ⍝ Look for semicolons in parentheses() and outside of brackets[]
    isFn←'isFn'{0=⎕NC ⍺:⍵ ⋄ ⎕OR ⍺}0
    lines←,,¨⊆lines
    ⎕IO ⎕ML←0 1
    QUOT←'''' ⋄ SEMI←';'
    LPAR RPAR LBRK RBRK COM←'()[]⍝'
    stack←⎕NS ⍬
    deQ←{stack.(govern lparIx sawSemi↓⍨←-⍵)}     ⍝ deQ 1|0
    enQ←{stack.((govern lparIx)sawSemi,←⍵ 0)}    ⍝ enQ gNew lNew
    :If isFn
      prefix lines←(⊂⊃lines)(1↓lines)
    :Else
      prefix←⍬
    :EndIf
    linesOut←⍬
    :For line :In lines
      :If '∇'=1↑line↓⍨+/∧\line=' '
        lineOut←line       ⍝ Skip function headers or footers...
      :Else
        stack.(govern lparIx sawSemi)←,¨' ' 0 0   ⍝ stacks
        lineOut←⍬ ⋄ inCom←0
        :For cur_tok :In line
          cur_gov←⊃⌽stack.govern
          inQt inCom←QUOT COM=cur_gov  
          :If inQt
              deQ QUOT=cur_tok
          :Elseif inCom
              ⋄   
          :Else
            :Select cur_tok
            :Case COM  ⋄ enQ cur_tok(≢lineOut)
            :Case LPAR ⋄ enQ cur_tok(≢lineOut)
            :Case LBRK ⋄ enQ cur_tok(≢lineOut)
            :Case RPAR ⋄ cur_tok←(1+⊃⌽stack.sawSemi)/RPAR ⋄ deQ 1
            :Case RBRK ⋄ deQ 1
            :Case QUOT ⋄ enQ cur_tok ¯1
            :Case SEMI
              :Select cur_gov
              :Case LPAR ⋄ cur_tok←')(' ⋄ lineOut[⊃⌽stack.lparIx]←⊂2/LPAR ⋄ (⊃⌽stack.sawSemi)←1
              :Case LBRK
              :Else ⋄ cur_tok←')(' ⋄ (⊃stack.sawSemi)←1
              :EndSelect
            :EndSelect
          :EndIf
          lineOut,←cur_tok
        :EndFor
        :If (⊃stack.sawSemi)     ⍝ semicolon(s) seen at top level (outside parens and brackets)
          lineOut←'((',lineOut,'))'
        :EndIf
      :Endif
      linesOut,←⊂∊lineOut
    :EndFor

    pSQ←'(?:''[^'']*'')+'
    pComment←'⍝.*$'
    pBareParens←'\(\h*\)'
    :IF 0≠≢∊linesOut  
      linesOut←pSQ pComment pBareParens ⎕R'\0' '\0' (,'⍬')⍠('Mode' 'M')⊣linesOut
    :ENDIF
    linesOut←prefix,linesOut
∇
:endnamespace
