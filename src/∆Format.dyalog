:Namespace ∆Format
⍝  ∆F Utility and associated namespace (∆Format).
⍝  Description: "A basic APL-savvy formatting function similar to Python F-Strings. 
⍝                but with native dfn-based handling of arrays and precise formats based on extended ⎕FMT."
⍝  For details, see HELP information at the bottom of ∆Format.dyalog (this file).
⍝  See ∆F⍨'help' for detailed Jupyter notebook output.
⍝  
∆F←{  
⍝ Note: ∆F is "promoted" below to ##.∆Format...
  0:: ⎕DMX.EN ⎕SIGNAL⍨ '∆F ',⎕DMX.EM 
  ⎕IO←0 ⋄ ⎕ML←1 
  ⍺←''         ⍝ ⍺ ≡ '': Same as ⍺ ≡ 'Default'
⍝ Verify 1st elem of ⍵ is a character vector (possible Format string).
  (0≠80|⎕DR ⊃⊆⍵)∨1<⍴⍴⊃⍵: 11 ⎕SIGNAL⍨ '∆F DOMAIN ERROR: Format string not a simple character vector.'
⍝ If ⍺ is an assertion (2|⎕DR ⍺: all numeric) with at least one 0, the assertion is false: 
⍝    return immediately with shy 0 (false).
  ⍺{⍵: 0∊⍺ ⋄ 0 } 2|⎕DR ⍺: _←0      ⍝ 2|⎕DR ≡≡ isNumeric
⍝ Otherwise, move us to a private namespace in the # domain.
  ⍺ (#.⎕NS ∆Format).{  
    ⍝ ************************************************⍝
    ⍝ SECTION ********* SUPPORT FUNCTION DEFINITIONS  ⍝
    ⍝ ************************************************⍝
    ⍝+---------------------------------+⍝
    ⍝ GENERAL FUNCTIONS          ...   +⍝
    ⍝+---------------------------------+⍝
    ⍝ ⍙FLD ⍵: ⍵ a regex field number. Returns the text in that field, if it exists; else ''.
      ⍙FLD←{O B L←⍺.(Offsets Block Lengths) ⋄ 0≠0(≢O)⍸⍵: '' ⋄ ¯1=O[⍵]: '' ⋄ B[O[⍵]+⍳L[⍵]] }
    ⍝ SetOptions: ∆F left arg (⍺) is passed as SetOptions right arg (⍵), which must be:
    ⍝   (a) an assertion (homogeneous numeric array) or 
    ⍝   (b) 0 or more option strings: 
    ⍝       DEBUG, COMPILE, HELP, DEFAULT  (case is ignored; abbreviations ok, matching L-to_R)
    ⍝ If omitted, it is treated as (b) '' ('default').
    ⍝ If an assertion, it must be TRUE, since FALSE assertions are captured above, to be very fast (and do nothing).
    ⍝ Returns: Four Booleans
    ⍝     ASSERT_TRUE DEBUG COMPILE HELP       (DEFAULT is implicitly TRUE iff these are NOT).
      SetOptions← { ⍺←'debug' 'compile' 'help' 'default'
        ⍝ RETURNS: ASSERT_TRUE DEBUG COMPILE HELP
          0=≢⍵:0 0 0 0 ⋄ 2|⎕DR ⍵: 1 0 0 0 
          p←⍺∘{(⎕C(≢⍵)↑¨⎕C ⊆⍺)⍳⊂,⍵}¨⎕C ⊆⍵      ⍝ Allow abbrev. Note: 'd' or 'de' matches 'debug', not 'default'!
          1(~∊)bad←p≥≢⊆⍺: 0,¯1↓1@p⊢0 0 0 0     ⍝ Signal if any option does not match
          Whoops←⎕SIGNAL∘11{'∆F DOMAIN ERROR: Invalid option(s): ',¯2↓∊(⊂'", '),⍨¨'"',¨⍺/⊆⍵} 
          bad Whoops ⍵                       
      }
      HelpCmd←{ ⍝ Help... Show HELP info and return ⍵
          0:: '∆F: Help information not found where expected!' ⎕SIGNAL 911
          Lib.∆HelpLibRef._HELP_ ⍵
      }
    ⍝+--------------------------------------------------------------------------------+⍝
    ⍝+ RESULT_Immed, RESULT_Compile, OMEGA_Pick                                       +⍝
    ⍝+   Manipulate these EXTERNs (globals): RESULT(RW), curOMEGA(RW), nOMEGA(W)      +⍝
    ⍝+--------------------------------------------------------------------------------+⍝
    ⍝ RESULT_Immed: Glue RESULT,←⍵. Return ⍺ or '' 
    ⍝ EXTERN: RESULT (RW) 
      RESULT_Immed←{ 
          ⍺←''  ⋄  0=≢⍵: ⍺ ⋄ lhs←RESULT   
          rhs← Lib.BBOX⍣DEBUG ⊢ USER_SPACE.⎕FMT ⍵
          lhs rhs↑⍨←lhs⌈⍥≢rhs 
          ⍺⊣ RESULT⊢←lhs,rhs
      }
    ⍝ RESULT_Compile: Emit code equiv of RESULT_Immed, returning ⍺. 
    ⍝ EXTERN: RESULT (RW) 
    ⍝ Strategy: Since immediate formatting (RESULT_Immed) proceeds L-to-R, we replicate that in code generation:
    ⍝     ∘ we append ⍵ on right with characters reversed to have more efficient catenation (~10% for typical formats).
    ⍝     ∘ we reverse the entire assembled string and return it as a code string to the caller (ready to execute via ⍎).  
      RESULT_Compile←{  
          ⍺←''  ⋄  0=≢⍵: ⍺  ⋄ lhs←'(',')',⍨('⍺.BB '/⍨DEBUG),⍵    
          ⍺⊣ RESULT,← ⌽lhs,'⍺.C'/⍨ ~0=≢RESULT     
      }
    ⍝ OMEGA_Pick: Resolve user indexing of ⍹ (next ⍹N), ⍹0, ..., ⍹N or aliases ⍵_, ⍵0, ... ⍵N.       
    ⍝ EXTERN: nOMEGA (R), curOMEGA (RW) 
      OMEGA_Pick←{  
          ok ix ← {0=1↑0⍴⍵: 1 ⍵ ⋄ ⎕VFI ⍵ } ⍵
          0∊ok:             3 ⎕SIGNAL⍨ '∆F LOGIC ERROR in ⍹ selection: ',' is not a number.',⍨⍕⍵
          (ix<0)∨ix≥nOMEGA: 3 ⎕SIGNAL⍨ '∆F INDEX ERROR: ⍹',' is out of range.',⍨⍕ix
          ('(⍵⊃⍨⎕IO+'∘,')',⍨⊢) ⍕curOMEGA∘←ix    ⍝ Select based on user's ⎕IO    
      }    
    ⍝ TFEsc (Escapes in Text fields)
    ⍝ TFEsc handles all and only these escapes:  \\   \⋄  \{  \}    Note: This means \\⋄ => \⋄ via Regex rules.
    ⍝                                    value:   \   CR   {   }    
    ⍝ Other sequences of backslash followed by any other character have their ordinary literal values.
      TFEsc←   '\\⋄'  '\\([{}\\])' ⎕R '\r' '\1'    ⍝ In a Text field
    ⍝ escDQ (Escapes in Double-quoted strings in Code fields)
    ⍝ escDQ handles all and only these escapes:  \\⋄  \⋄            Note: \\ otherwise has literal value \\
    ⍝                                    value:   \⋄  CR
    ⍝ Other sequences of backslash followed by any other character have their ordinary literal values.
      escDQ←   '\\⋄'  '\\(\\⋄)'    ⎕R '\r' '\1'    ⍝ In a DQ string in a Code field.
    ⍝ +----------------------------------------------------------------------------+
    ⍝ | String Conversion Functions...                                             |
    ⍝ +----------------------------------------------------------------------------+
    ⍝ DQ2SQ: Convert DQ delimiters to SQ, convert doubled "" to single, and handle escapes for DQ strings...
      DQ2SQ←    { SQ2Code (~DQ2⍷s)/s← escDQ 1↓¯1↓⍵ }
    ⍝ SQ2Code: Return code for one or more simple char strings
    ⍝          Double internal SQs per APL, then add SQ on either side!
      SQ2Code←  { 1↓∊ ' '∘,∘{ SQ,SQ,⍨⍵/⍨1+⍵=SQ }¨ ⊆⍵ }      ⍝ NB: ⍵ may have CRs in it. See CRStr2Code and TF2Code   
    ⍝ ------------------------------------------------------------------------------------------
    ⍝ TF2Code (Text field): 
    ⍝   Generate code for a simple char matrix given a simple char scalar or vector ⍵, possibly containing CRs.
    ⍝   Handle single-line case, as well as multiline cases: with scalars alone vs mixed scalars/vectors.
    ⍝   See note for CRStr2Code (below).
    ⍝   Result is a char matrix.
      TF2Code←   { ~CR∊⍵: (⍕1,≢⍵),'⍴',SQ2Code ⍵ ⋄ '↑', (',¨' /⍨ 1∧.=≢¨ø), SQ2Code⊢ ø←SplitCR ⍵ } 
      SplitCR←  { ¯1↓¨(1,0,⍨⍵=CR)⊂⍵,CR}                     ⍝ Break lines at CR boundaries simul'ng ⎕FMT (w/o padding each line)  
    ⍝ ------------------------------------------------------------------------------------------
    ⍝ CRStr2Code ⍵
    ⍝ For string ⍵ in SQ form (DQ2SQ already applied), handle internal CRs, 
    ⍝ converting to format that can be executed at runtime.
    ⍝    r@CV← CRStr2Code ⍵@CVcr
    ⍝    ⍵  - Standard APL char vector with optional CRs
    ⍝    r  - Expression  (char vector) that *evaluates* to a char vector with the same appearance as ⍵.
      CRStr2Code←{ ~CR∊⍵: ⍵ ⋄ '(',')',⍨∊(⊂SQ,',(⎕UCS 13),',SQ)@(CR∘=)⊢⍵ }
    ⍝ ------------------------------------------------------------------------------------------
    ⍝ SF2Code (Space field)
    ⍝   Generate code for # of spaces passed as a string.
      SF2Code←{ '1 ',⍵,'⍴',SQ2}∘⍕ 
    ⍝ SFChoices (see pattern SFp):  
    ⍝   Call: SFChoices f¨1 2.  
    ⍝   f 1: 0 or more space chars. f 2: a string of 0 or more valid digits. Per SFp.
    ⍝   Returns # of spaces (numeric): res ≥ 0
    ⍝   We limit lengths (# spaces) to 999 (rather more than ever needed) via curried ⍺.
      SFChoices←999∘{ ⍺≥len←{0=≢⍵: ≢⍺ ⋄ 10⊥⎕D⍳⍵}/⍵: len ⋄ ⎕SIGNAL/'∆F DOMAIN ERROR: Space Field Too Wide' 11 }     
    ⍝ +---------------------------------------------------+
    ⍝ | Constants for String Conversion Functions above   |
    ⍝ +---------------------------------------------------+
      SQ2← 2⍴SQ←'''' 
      DQ2← 2⍴DQ←'"' 
      CR←  ⎕UCS 13 
    ⍝ +----------------------------------------------------------------------------+
    ⍝ | ENDSECTION ***** SUPPORT FUNCTION DEFINITIONS                              |
    ⍝ +----------------------------------------------------------------------------+
    ⍝ ***************************************⍝
    ⍝ SECTION ****** Code field Scanning     ⍝
    ⍝ ***************************************⍝
    ⍝ CFScan: Once we have a Code (Dfn) field {...}, we decode the components within the braces. 
      CFScan←{
        patsCF←quoteP dollarP omIndxP omNextP comP selfDocP escDQP  
               quoteI dollarI omIndxI omNextI comI selfDocI escDQI ← ⍳≢patsCF
        selfDocFlag←0 
        dfn←patsCF ⎕R {CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD  
            CASE quoteI:   CRStr2Code⍣ COMPILE⊢ DQ2SQ f 0
            ⋄ invalidDollarE←'{''Invalid use of $''⎕SIGNAL 11}'
            CASE dollarI:  (1 2 3⍳≢f 0)⊃' ⍙Ⓕ.FMTX '   ' ⍙Ⓕ.BOX '  ' ⍙Ⓕ.QT '  invalidDollarE   ⍝ Valid: $, $$, $$$                       
            CASE omIndxI:  OMEGA_Pick f 1          
            CASE omNextI:  OMEGA_Pick curOMEGA+1  
            CASE comI:     ' '   ⍝ Comment → 1 space         
            CASE selfDocI: '}'⊣ selfDocFlag⊢←1
            CASE escDQI:   '"'
            '∆F LOGIC ERROR: UNREACHABLE STMT' ⎕SIGNAL 911
        }⍵
        res←{ 
            COMPILE:  '⍺', ⍵ ,'⍵'   
          ⍝ Eye candy ;-)))
            DEBUG/0:: ⎕SIGNAL/⎕DMX.{ 
                m0← 'DEBUG: ',(⊃DM),' while executing expression'
                m1 m2← { (6↑''),¯7↓31↓⍵ }¨↓↑1↓DM ⋄ m1← '⍵⊃⍨⎕IO\+' ⎕R '⍹'⊢m1
                ⎕←↑m0 m1 m2 ⋄ EM EN
            }⍬ 
          ⍝ Mirror current vals of key sys vars from user space into ⍙Ⓕ.Lib (Code Field arg: ⍺).
          ⍝ Useful in case you do  ⍺.MY_FN ← ○  (where ○ will be executed in the ⍺ namespace).
            ⍙Ⓕ.Lib.(⎕FR ⎕PP)← USER_SPACE.(⎕FR ⎕PP)           
          ⍝ Pass the main local namespace name ⍙Ⓕ  **library** into the user space as ⍙Ⓕ and as ⍺.  See dollarP, dollarI.
            ⍎'⍙Ⓕ.Lib USER_SPACE.{(⍙Ⓕ←⍺)', ⍵ ,'⍵ }OMEGA'
        }dfn 
      ⍝ Self-documented code field?  { code → }  or { code ➤ }, where 0 or more spaces around → or ➤ are reflected in output.
      ⍝ Prettyprint variant of → is '➤' U+10148
        selfDocFlag: res { 
            COMPILE: ⍺ RESULT_Compile TF2Code ⍵ 
                     ⍺ RESULT_Immed ⍵
        } '[→➤](\h*)$' ⎕R (SELF_DOC_ARROW,'\1')⊣1↓¯1↓⍵           
        res 
      }
    ⍝ *****************************************⍝
    ⍝ ENDSECTION  ***** Code field Scanning ** ⍝
    ⍝ *****************************************⍝

    ⍝ *******************************************⍝
    ⍝ SECTION  *****   Top Level Patterns        ⍝
    ⍝   TF   Text field                          ⍝
    ⍝   SF   Space field                         ⍝
    ⍝   CF   Code field                          ⍝
    ⍝   DQ   Double-quoted string in Code field  ⍝
    ⍝ *******************************************⍝
      TFp← '(\\.|[^{\\]+)+'               
    ⍝ SFp: We capture spaces or /:\d+:/ in CFs, {...}, ignoring comments.
    ⍝      Format:    { spaces [⍝com] }    OR   {  :digits[:]  [⍝com] }
    ⍝      SFChoices converts digits to (digits⍴' '), if set. Else returns <spaces> spaces.
    ⍝      We allow any # of digits, but disallow more than 3 in SFChoices.
      SFp← '(?x) \{  (\h* (?: : \h*(\d+)\h* :? \h*)? )  (?: ⍝[^}]* )?  \}'   
    ⍝ CFp: Don't try to understand this regex. 
    ⍝ OK, in brief, we match the pattern <P>: 
    ⍝  ¹「{」THEN  ²ᵃ ATOMICALLY AT LEAST ONE OF:  
    ⍝     ³「ANY chars BUT {}"⍝\」 OR ⁴「\ escapes」 OR ⁵「"DQ Strings"」 OR ⁶「⍝ comments」 OR ⁷「RECURSE <P> ≥0 TIMES」 
    ⍝  THEN: ⁸「}」 
    ⍝  I.e.              ¹  ²ᵃ   ³            ⁴          ⁵              ⁶         ⁷      ²ᵇ  ⁸
      CFp←   '(?x) (?<P> \{ (?>  [^{}"⍝\\]+ | (?:\\.)+ | (?:"[^"]*")+ | ⍝[^⋄}]* | (?&P)* )+  \} )' 
    ⍝ Code Field Patterns...
      escDQP←   '\\"'
      quoteP←   '(?<!\\)(?:"[^"]*")+'   ⍝ Should be RECURSIVE, handling backslash dq
      dollarP←  '(?<!\\)\${1,}'         ⍝ $ = FMTX, $$ = BOX, $$$ = QT  
    ⍝-- :BEGIN OMEGA_ALIAS LOGIC
      ⍝ Synonym of ⍹DD is ⍵DD. Synonym of bare ⍹ is ⍵_.   (DD: 1 or 2 digits).
      ⍝ If OMEGA_ALIAS is 0, ⍵ and ⍵_ are NOT synonyms for ⍹, omega underscore.
      OMEGA_ALIAS←1                       
      ⍝ ⍹0, ⍹1, ... ⍹99 or ⍵0... We arbitrarily limit to 2 digits (0..99).
      omIndxP← (OMEGA_ALIAS ⊃ '⍹'   '[⍹⍵]'), '(\d{1,2})'    
      ⍝ ⍹ or ⍵_.                        ⍝ NB: We don't bother clipping incremental indexing of ⍵ at 99.   
      omNextP←  OMEGA_ALIAS ⊃ '⍹'   '⍹|⍵_'    
    ⍝-- :END OMEGA_ALIAS LOGIC            
      comP←     '⍝(?|\\⋄|[^⋄}])*'     ⍝ ⍝..⋄ or ⍝..}. We allow escaping ⋄, but there are PCRE problems doing so with { or }.
    ⍝ Trailing → or ➤ in Code fields triggers self-documenting code.  Works like Python =.  
      selfDocP← '[→➤]\h*\}$'         
    ⍝ ***************************************⍝
    ⍝ ENDSECTION ***** Top Level Patterns ***⍝
    ⍝ ***************************************⍝

    ⍝**********************************⍝ 
    ⍝ SECTION *****  EXECUTIVE  ****** ⍝
    ⍝**********************************⍝  
    ⍝ Basic Initializations
      ASSERT_TRUE DEBUG COMPILE HELP← SetOptions ⍺
      SELF_DOC_ARROW←'➤'   ⍝ For Self-Documenting Code: use a printable char here, e.g. → or '➤'
    HELP: _←HelpCmd ⍬
      USER_SPACE←⊃⌽⎕RSI
      ⍙Ⓕ←⎕THIS⊣⎕DF  (⍕⎕THIS.##),'.[Format Namespace]'         
    ⍝ Globals (externals) used within utility functions.    
    ⍝ Save the right arg to ∆F (,⊆⍵), the format string (⍹0), and its right args (⍹1, ⍹2, etc.)
      OMEGA←     ⍵                       ⍝ Named to be visible at various scopes. 
      OMEGA0←    ⊃⍵                      ⍝ ⍹0 (0⊃⍵): the format string.
      nOMEGA←    COMPILE⊃ (≢OMEGA) 9999  ⍝ If we're compiling, we don't know ≢OMEGA until runtime, so treat as ~∞.
      curOMEGA←  0                       ⍝ "Next" ⍹ will always be ⍹1 or later. ⍹0 can only be accessed directly. 
      RESULT←    ' '⍴⍨COMPILE↓1 0        ⍝ Initialize global RESULT (If COMPILE, 0⍴' ', i.e. ''; ELSE, 1 0⍴' ')
      patsMain←TFp SFp CFp               ⍝ Fields: Text (TF), Space (SF), Code (CF)
               TFi SFi CFi← ⍳≢patsMain
    ⍝ COMPILE MODE: 
    ⍝ Build code string from: 
    ⍝   library ns [in case used], RESULT (format string encoded), and ⍵0 (format string literal)  
      COMPILE: {
          _←patsMain ⎕R{ CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD 
              CASE TFi:   RESULT_Compile TF2Code TFEsc f 0  
              CASE SFi:   RESULT_Compile SF2Code SFChoices f¨1 2
              CASE CFi:   RESULT_Compile CFScan        f 0  
              '∆F LOGIC ERROR: UNREACHABLE STMT' ⎕SIGNAL 911 
          }⊣OMEGA0  ⍝ Pass the format string only...
          0∊⍴RESULT: '{1 0⍴''''}'   ⍝ Null format string => Return code equiv. 
        ⍝ Embed OMEGA0 -- the format string -- in the "compiled" code (accessible as ⍵0 or 0⊃⍵)
            fmtStr←CRStr2Code SQ2Code ⊢ OMEGA0
        ⍝ Put RESULT in L-to-R order. See RESULT_Compile     
        ⍝ We require a dummy format string in ⊃⍵.
        ⍝ If (⊃⍵) is empty ('' or ⍬), ⍵0 will be original format string specified.
        ⍝ ⍙Ⓕ ← ⍎∆FormatLibName (see details at namespace ∆Format.Lib below)
            res←'(⎕NS ',Lib.∆FormatLibName,'){⍺←''''⋄0∊⍺:_←0⋄⍺ ⍺⍺.L ⍺⍺{ ',(⌽RESULT),' }⍵(⍙Ⓕ←⍺⍺).R',fmtStr,'}' 
            (⎕∘←)⍣DEBUG⊢res  
      }⍬ ⍝ END COMPILE
    ⍝ STANDARD MODE 
    ⍝ 1: {
          _←patsMain ⎕R{ CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD 
              CASE TFi:   RESULT_Immed TFEsc          f 0 
              CASE SFi:   RESULT_Immed ' '⍴⍨SFChoices f¨1 2  
              CASE CFi:   RESULT_Immed CFScan         f 0
              '∆F LOGIC ERROR: UNREACHABLE STMT' ⎕SIGNAL 911
          }⊣OMEGA0    ⍝ Pass the format string only...
          ASSERT_TRUE: _←1⊣   ⎕←RESULT    
                                RESULT    ⍝ default.   
    ⍝ }⍬ ⍝ END STANDARD MODE
    ⍝*************************************⍝ 
    ⍝ ENDSECTION ***** EXECUTIVE   ****** ⍝
    ⍝************************←←←**********⍝ 
  },⊆⍵
}
⍝ "Promote ∆F" to ##.∆Format
##.∆F←∆F

⍝ Lib: peer Library used internally (standard path) and externally (compile option path)
:Namespace Lib
⍝ +-------------------------------------------------------------------------------------------+
⍝ | SECTION ***** Library Routines (Local Use, Compile Mode, and User-Accessible)             |
⍝ | User Accessible: ⍺.FMTX, ⍺.CAT, ⍺.BOX, ⍺.BBOX, ⍺.QT    
⍝ | Internal Use:    ⍙Ⓕ.(L, R, C, BB)
⍝ +-------------------------------------------------------------------------------------------+   
  ⍝ ⎕THIS must be a named namespace for ∆FormatLibName to work... 
  ⍝    Extern ⍙Ⓕ←⍎∆FormatLibName, with 'COMPILE' option.
    ∆FormatLibName←⍕⎕THIS         
    ∆HelpLibRef←⎕THIS.##          ⍝  Used with HELP option
 
  ⍝ ⍺.FMTX: Extended ⎕FMT. See doc for $ in ∆Format.dyalog.
    FMTX←{ ⍺←⊢ ⋄ ⎕IO←0  ⋄ WIDTH_MAX←999
       ⍝ Bug: If ⎕FR is set LOCALLY in the code field (⎕FR←nnn), ∆FMT won't see it: it picks up whatever's in the caller.
        ∆FMT←  ⎕FMT                                   ⍝  Even with (⊃⌽⎕RSI), this still doesn't pick up >>local<< ⎕FR or ⎕PP set in a DFN. Dyalog bug???
        4 7::⎕SIGNAL/⎕DMX.(EM EN)                     ⍝ RANK ERROR, FORMAT ERROR
        1≡⍺ 1: ∆FMT ⍵
        srcP snkR←'^ *(?|([LCRlcr]) *(\d+)[ ,]*|()() *)(.*)$' '\1\n\2\n\3\n'
        xtra wReq std←srcP ⎕R snkR⊢⊆,⍺                ⍝ Grab extra (XO) and standard (SO) ⎕FMT opts...
        noColV xtra←('lcr'∊⍨⊃xtra)(1 ⎕C xtra)         ⍝ If xtra∊l|c|r, set as L|C|R and set noColV←1
      ⍝ If ⍺ is 0, treat simple vector as column vector. Else treat simple vector as 1-row matrix.
        CoerceV←noColV∘{~(1=|≡⍵)∧1=⍴⍴⍵: ⍵ ⋄ ⍺: ⍉⍪⍵ ⋄ ⍪⍵}         
        xtra≡'':⍺  ∆FMT CoerceV ⍵                     ⍝ 1.  SO only?  
        obj←std{
            ''≡⍺:   ∆FMT  ⍵                          ⍝ 2a. XO only?  
                  ⍺ ∆FMT ⍵                            ⍝ 2b. Both XO and SO? As in 1.
        }CoerceV ⍵   
        wReq← 10⊥⎕D⍳wReq ⋄ wObj← ⊃⌽⍴obj               ⍝ Faster than (⊃⌽⎕VFI wReq)  
        wReq>WIDTH_MAX: 11 ⎕SIGNAL⍨{
          'DOMAIN ERROR: Width in $ Spec Exceeds Maximum Allowed (',')',⍨⍕⍵
        }WIDTH_MAX   
        wReq ≤ wObj: obj                              ⍝ If required width ≤ object width, done! We won't truncate.
        pad1←↑⍤1
        xtra∊'LR': (¯1×⍣('R'=⊃xtra)⊢wReq)pad1 obj     ⍝ Left, Right 
        wCtr←wReq-⍨⌊2÷⍨wReq-wObj                      ⍝ Center 1
        wReq pad1 wCtr pad1 obj                       ⍝ ...    2
    } 

    ⍝ ⍺.CAT: CATENATE FIELDS
    ⍝ Return a matrix with ⍺ on left and ⍵ on right, first applying ⎕FMT to each and catenating left to right,
    ⍝ "padding" the shorter object with blank rows. See HELP info on library routines.
    ⍝ Monadic case: Treat ⍺ as null array...
      CAT← {0=≢⍺: ⎕FMT ⍵ ⋄ a w←⎕FMT¨⍺ ⍵ ⋄ a w↑⍨←a⌈⍥≢w ⋄ a,w }
    ⍝ ⍺.C, alias for CAT⍨: Reverse Catenate Fields [internal use only]
      C←   CAT⍨

    ⍝ ⍺.BOX: A boxing function with option ⍺. See $$
    ⍝ Experimental: We allow 1 BOX ⍵ to be same as BBOX. 0 BOX ⍵ is original BOX.
    ⍝    WAS: BOX← {⍺←0 ⋄  ('·'@(' '∘=))⍣(⊃⍺)⊣⎕SE.Dyalog.Utils.display ⍵}
    ⍝    NOW: 
      BOX← {⍺←0 ⋄  ('·'@(' '∘=))⍣(⊃⍺)⊣DfnsBox ⍕⍵}
    ⍝ BBOX  [user] and ⍺.B [internal]: 
    ⍝   BOX with blanks repl. by default by middle dot (·), ⎕UCS 183.
    ⍝   If ⍺ is specified, it is used instead to replace blanks. It must be a scalar.
      BB← BBOX← {⍺←'·' ⋄ ((⍕⍺)@(' '∘=))⊣DfnsBox ⍕⍵}

    ⍝ QT: Add quotes around each row of ⍵ formatted.
    ⍝     The default quotes are '"'. 
    ⍝     If the quotes are of length 2, the first is the opening quote and the 2nd the closing quote.
    ⍝     If numeric, the quotes will be the unicode characters with those numeric codes.
      QT←{  ⍺←'"' ⋄ 2|⎕DR ⍺: ⍵ ∇⍨ ⎕UCS ⍺  ⋄ ⎕IO←0 ⋄ B←+/(∧\' '∘=) 
            q⌽R,⍨w⌽⍨-q←B⌽w←(-p)⌽L,w⌽⍨p←B⊢w←⎕FMT ⍵  ⊣ L R←2⍴⍺
      }

    ⍝ L: Process Left Arg of Compiled ∆F @ Runtime. 
    ⍝    If ⍺ is numeric, print ⍵ and return shy 1. Else return non-shy ⍵.
      L←{2|⎕DR ⍺:_←1⊣⎕←⍵ ⋄ ⍵}    
    ⍝ R: Process Right Arg of Compiled ∆F @ Runtime.
    ⍝    Unless user format string is non-empty, insert actual format string from "compile" phase.
      R←{0=≢⊃⍺: (⊂⍵),1↓⍺ ⋄ ⍺} 

    ⍝ UNDER REVIEW: Here only for demonstrations...
    ⍝ TITLE: Converts words in ⍵ to Title case (1st letter capitalized. All else forced to lower case)
      TITLE←{
          2=⍴⍴⍵: ∇⍤1⊣⍵ ⋄ 2=|≡⍵: ∇¨⍵
          1↓∊' ',¨((1 ⎕C⊃∘⊢),(⎕C 1∘↓∘⊢))¨' '∘(≠⊆⊢),⍵
      } 

    ⍝ dfns.box.
    DfnsBox←{                           ⍝ Box the simple text array ⍵.
     (⎕IO ⎕ML)←1 3 ⋄ ⍺←⍬ ⍬ 0 ⋄ ar←{⍵,(⍴⍵)↓⍬ ⍬ 0}{2>≡⍵:,⊂,⍵ ⋄ ⍵}⍺  ⍝ controls

     ch←{⍵:'++++++++-|+' ⋄ '┌┐└┘┬┤├┴─│┼'}1=3⊃ar            ⍝ char set
     z←,[⍳⍴⍴⍵],[0.1] ⍵ ⋄ rh←⍴z                             ⍝ matricise
                                                           ⍝ simple boxing? ↓
     0∊⍴∊2↑ar:{q←ch[9]⍪(ch[10],⍵,10⊃ch)⍪9⊃ch ⋄ q[1,↑⍴q;1,2⊃⍴q]←2 2⍴ch ⋄ q}z

     (r c)←rh{∪⍺{(⍵∊0,⍳⍺)/⍵}⍵,(~¯1∊⍵)/0,⍺}¨2↑ar             ⍝ rows and columns
     (rw cl)←rh{{⍵[⍋⍵]}⍵∪0,⍺}¨r c

     (~(0,2⊃rh)∊c){                                         ⍝ draw left/right?
         (↑⍺)↓[2](-2⊃⍺)↓[2]⍵[;⍋(⍳2⊃rh),cl]                  ⍝ rearrange columns
     }(~(0,1⊃rh)∊r){                                        ⍝ draw top/bottom?
         (↑⍺)↓[1](-2⊃⍺)↓[1]⍵[⍋(⍳1⊃rh),rw;]                  ⍝ rearrange rows
     }{
         (h w)←(⍴rw),⍴cl ⋄ q←h w⍴11⊃ch                      ⍝ size; special,
         hz←(h,2⊃rh)⍴9⊃ch                                   ⍝  horizontal and
         vr←(rh[1],w)⍴10⊃ch                                 ⍝  vertical lines
         ∨/0∊¨⍴¨rw cl:(⍵⍪hz),vr⍪q                           ⍝ one direction only?
         q[1;]←5⊃ch ⋄ q[;w]←6⊃ch ⋄ q[;1]←7⊃ch ⋄ q[h;]←8⊃ch  ⍝ end marks
         q[1,h;1,w]←2 2⍴ch ⋄ (⍵⍪hz),vr⍪q                    ⍝ corners, add parts
     }z
   }
⍝ +----------------------------------------------------------------------------+
⍝ | ENDSECTION ***** Library Routines (Compile Mode and User-Accessible)       |
⍝ +----------------------------------------------------------------------------+
 
:EndNamespace

⍝ HELP FILE and UTILITY...  Choose html or pdf based on convenience...
⍝ NOTE: This is a hardwired kludge that should be fixed ;-)
HELP_FI←'./MyDyalogLibrary/pmsLibrary/src/∆FormatHelp.',0 ⊃  'html' 'pdf'
_HELP_←{
     0::⍵⊣{
       ⎕←'Showing limited HELP info...'
       ⎕ED 'help'⊣help←'^⍝H((?: .*)?)$' ⎕S '\1' ⊣⎕NR ⍵
     } 0⊃⎕XSI 
     { 0=⎕NEXISTS ⍵: ∘⊣⎕←'Help file "',⍵,'" does not exist.'
       0:: ∘⊣⎕←'Unable to display HELP file: ',⍵
       ⎕SH 'open ',⍵   ⍝ Mac-specific...
     } HELP_FI 
     
⍝**********************************************⍝ 
⍝ SECTION:   HELP INFORMATION (ABRIDGED)   ****⍝
⍝**********************************************⍝ 
⍝H ∆F Formatting Utility
⍝H ¯¯ ¯¯¯¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯
⍝H Descrption:
⍝H   "A basic APL-savvy formatting function reminiscent of Python F-Strings. 
⍝H    but with native dfn-based handling of arrays and output formats."
⍝H Syntax: 
⍝H   [assertion | options] ∆F format_string [arbitrary args]
⍝H     ⍺/assertion: 
⍝H       ⍺ must be a simple numeric array. "TRUE" unless there is a 0 in the left arg.
⍝H       If TRUE, prints formatted result returning shy 1. Otherwise, does nothing, returning shy 0.
⍝H     ⍺/options:
⍝H       DEBUG | COMPILE | HELP | DEFAULT*         
⍝H       ∘ DEBUG: displays each field separately using dfns "box"
⍝H       ∘ COMPILE: Returns a code string that can be converted to a dfn (executed via ⍎), 
⍝H         rather than scanned on each execution. 
⍝H         - The resulting dfn should have a dummy format ''. If a non-empty string, that
⍝H           is treated as if the format string ⍵0.  
⍝H         - If the resulting dfn is called with a left arg ⍺, it must be an assertion (numeric array) and handled as above.
⍝H       ∘ HELP: Displays HELP documentation (⍵ ignored):   ∆F⍨'HELP'
⍝H       ∘ DEFAULT: Returns a formatted 2-D array according to the format_string specified.
⍝H         ===========
⍝H         * DEFAULT is assumed if ⍺ is omitted or ''. Options may be in either case and abbreviated.
⍝H           The abbrev 'DE' or 'D' denotes DEBUG. 
⍝H     ⍵/format_string:
⍝H       Contains the simple format "fields" that include strings (text fields), code (code fields), and 
⍝H       2-D spacing (space fields). Code fields accommodate a shorthand using
⍝H         - $ to do numeric formatting (via ⎕FMT) and justification and centering, as well as
⍝H         - $$ to display fields or objects using dfns 'box'.
⍝H           If $$ has a left arg of 1, $$ replaces blanks with a middle dot (see ⍺.BOX and ⍺.BBOX).
⍝H
⍝H  Library routines: ⍺.CAT   catenate and top-align left (⍺) and right (⍵) args
⍝H                    ⍺.BOX   display right arg (⍵) in a box. 
⍝H                            If ⍺=1, same as monadic BBOX.
⍝H                    ⍺.BBOX  display right arg (⍵) in a box with char ⍺ replacing blanks. 
⍝H                            default ⍺: middle dot ('·')
⍝H                    ⍺.QT    put quotes around word sequences in each row of ⍵. 
⍝H                            ⍺: L/R quotes or unicode integers (default ⍺: '"')

⍝************************************⍝ 
⍝ ENDSECTION ***** HELP INFORMATION *⍝
⍝************************************⍝ 
}
:EndNamespace