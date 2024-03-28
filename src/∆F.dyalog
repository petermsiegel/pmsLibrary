∆F⍙ⓇⓇ← {∆F⍙Ⓛ} ∆F ∆F⍙Ⓡ ; ∆F⍙Ⓒ
⍝H 
⍝H ∆F: Simple formatting  function in APL "array" style, inspired by Python f-strings.
⍝H     [opts← 1 0 '`' ] ∆F fmt_str
⍝  ∆F⍙Ⓛ options,  ∆F⍙Ⓡ format string, ∆F⍙Ⓒ "compiled" code equivalent of ∆F⍙Ⓡ
⍝  ∆F⍙ⓇⓇ result returned from fn (string or dfn).
⍝ 
⍝ ∘ Uses outermost tradfn to allow for returning an active dfn, given option 0.
⍝ ∘ Be sure the outer tradfn is ⎕ML and ⎕IO independent (watch ⌷, ⊃) 
⍝   and has no visible local variables for (1=⊃⍺)
:IF 900⌶⍬                                ⍝ Default ⍺
    ∆F⍙Ⓛ← 1 0 '`'
:ELSEIF 0=≢∆F⍙Ⓛ                         ⍝ ⍬ ∆F... ==> fast return "nop"
    ∆F⍙ⓇⓇ← 1 0⍴'' 
    :RETURN 
:ELSEIF 'help'≡⎕C ∆F⍙Ⓛ                  ⍝ help...
    ∆F⍙ⓇⓇ← {⎕ML←1 ⋄ ⎕ED⍠ 'ReadOnly' 1⊢ 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⍵}⎕XSI  
    :RETURN
:ENDIF 
:TRAP 0 /⍨ 0     
⍝ ---------------------------
  ∆F⍙Ⓒ← (⍬⍴∆F⍙Ⓛ) { ⎕IO ⎕ML←0 1       
⍝ STAGE II: Execute/Display code from Stage I  (Stage II is a dyadic operator)
⍝     ⍺    is the first (default) option shared by the user
⍝     0⊃⍵  is the global boxO flag.
⍝     1⊃⍵  is the fstring passed by the user (0-th elem of user's ⍵) 
⍝     2⊃⍵  is the "compiled" formatted fields in L-to-R order, a vector of char vectors (strings)   
       boxO fStr outFF←⍵ 
      0>⍺:  ⎕SE.Dyalog.Utils.disp∘⍪⍣ (¯2=⍺)⊢ '⍙ⒷⓄⓍ ',¨⍥⊆⍣ boxO⊣ ¯1↓ outFF
      ⍝ Inject a namespace shared across all code fields. 
        showCd← '{⍺←#.⎕NS⍬⋄⎕ML←1⊣⍺.⎕DF''#.[∆F ns]''⋄{⊃,/((⌈/≢¨)↑¨⊢)⎕FMT','¨⌽⍵}',⍨ boxO/'∘⎕SE.Dyalog.Utils.display' 
      1=⍺:  showCd, '}⍵',⍨ ∊⌽ outFF   
        errCd←  '0:: ⎕SIGNAL ⊂(''Message'' ''EN'' ''EM'',⍥⊂¨⎕DMX.(Message EN (''∆F Runtime '',EM)))⋄'
        fQt← ''''{ ⍺, ⍺,⍨ ⍵/⍨ 1+ ⍵= ⍺} fStr
      0=⍺: '{', errCd, showCd, (∊⌽ outFF), '}', fQt, ',⍥⊆⍵}'
        'LOGIC ERROR' ⎕SIGNAL 911          
⍝ ---------------------------
  }∆F⍙Ⓛ{                                                     ⍝ ⊆⍵: original f-string
⍝ STAGE I: Analyse fmt string, pass code equivalent to Stage II above to execute or display
⍝ --------------------------- 
⍝ CONSTANTS     
⍝               
    ⎕io ⎕ml←0 1                  
  ⍝ ...Ê: Error messages/dfn. See Ê below.
    opt0Ê← ('Message' 'Invalid option (mode)')       ('EN' 11) 
    opt1Ê← ('Message' 'Invalid option (box)')        ('EN' 11) 
    opt2Ê← ('Message' 'Invalid option (escape char)')('EN' 11) 
    fStrÊ← ('Message' 'Invalid right arg (f-string)')('EN' 11) 
    qStrÊ← ('Message' 'No closing quote found for string')('EN' 11)
    brcÊ←  ('Message' 'No closing brace "}" found for code field')('EN' 11)
    logÊ←  ('EM'      'LOGIC ERROR: UNREACHABLE')    ('EN' 99) 
      
  ⍝ ..C: Constants.
  ⍝ ␠   '   "   ⋄     ⍝  :                                     ⍝1 Constants. See also escO option.
    spC sqC dqC eosC cmC clnC← ' ''"⋄⍝:'                     
  ⍝ {   }   $    %    ↓   ⍵   ⍹    →                           ⍝2 Constants.
    lbC rbC lpC rpC fmtC ovrC dnC omC omUC raC← '{}()$%↓⍵⍹→'                  
    crlfC← crC lfC← ⎕UCS 13 10                                 ⍝3 For "generic" newline, we use ⎕UCS 13!
    visCrC← '␍'                                                ⍝  For modeO<0, we show a visible CR.
    sdArrows← '▶' '▼'                                          ⍝4 for self-documenting strings
⍝ SUPPORT FNS
    Ê← {⍎'⎕SIGNAL⊂⍵' }                                         ⍝ Error signalled in its own "capsule"    
    Span←  +/∧\⍤∊      ⍝ { +/∧\⍺∊ ⍵}                           ⍝ How many leading ⍵ in ⍺?
    Break← +/∧\⍤(~∊)   ⍝ { +/∧\⍺(~∊) ⍵}
    EnQt←  { sqC,sqC,⍨ ⍵/⍨ 1+ sqC= ⍵ }                         ⍝ Put str in quotes by APL rules
    QtSp←  ''''∘,,∘''' '
    QtMultiLn← { ⍺: QtSp ⍵ ⋄ QtSp visCrC@ (∊∘crlfC)⊢ ⍵ }
⍝   _ScanEsc_:    [ TF_Next | CF_Next | CFStr_Next ] ∇∇ [0 | 1 | 0] ⍵
    _ScanEsc_← { 
      ch← ⊃⍵ ⋄ isCF←⍵⍵  
      isCF< eosC= ch: ⍺⍺ 1↓⍵ ⊣ isCF CatAny crC                  ⍝ `⋄ is NOT special in a CF
      escO lbC rbC∊⍨ ch: ⍺⍺ 1↓⍵ ⊣ isCF CatAny ch 
      isCF∧ omC omUC∊⍨ ch: ⍺⍺ _Omega 1↓⍵                        ⍝ ⍵⍵=1: Only valid with ⍺⍺ <=> CFStr_Next 
        ⍺⍺ 1↓⍵⊣ isCF CatAny escO, ch  
    }  
  ⍝ _Omega: operator:   [XX_Next] _Omega ⍵ 
  ⍝        ⍵: just past any `⍵ or ⍹ character (before optional trailing digits)
  ⍝  XX_Next: any of TF_Next, SF_Next, etc. 
  ⍝ Handle omega expressions:  `⍵, ⍹ with or w/o trailing digits
    omCtr← 0 
    _Omega←{ wx← '⍵⌷⍨⎕IO+'
        nDig← ⍵ Span ⎕D 
      0<nDig: ⍺⍺ nDig↓⍵⊣ CatCode '(',wx,pW,')'⊣ omCtr⊢← ⊃⌽⎕VFI pW← nDig↑⍵
        omCtr+← 1 ⋄ ⍺⍺ ⍵⊣ CatCode '(',wx,')',⍨ ⍕omCtr        
    }

  ⍝ allFlds etc.: "Global" accumulators for output fields
    (allFlds theFld theStr theSelfD)  strActive← (⍬ '' '' '') 1   
  ⍝ CatText: Catenate text ⍵ to theStr 
    CatText← { ⍺←⍵ ⋄ theStr,← ⍵ ⋄  strActive⊢← 1 ⋄ ⍬  }
  ⍝ CatCode: Catenate code ⍵ to theFld, and literal (unprocessed) code to theSelfD.
    CatCode← { ⍺←⍵ ⋄ theSelfD,← ⍺ ⋄  theFld,← ⍵ ⋄ ⍬  }
  ⍝ CatAny:  type of catenation based on ⍺ (1=code, 0=text).
    CatAny←     { ⍺: CatCode ⍵ ⋄ CatText ⍵ }
  ⍝ Code Field has ended. Ensure any string has been processed, then process the active field to the field buffer.
    CF_End←  { _← Str_End 0 ⋄ 0=≢ theFld: ⍬ ⋄ allFlds,← ⊂'(⍺{',theFld, '⍵)' ⋄ ⍬⊣ Fld_Clr⍬ }
  ⍝ Text Field has ended. Ensure any string theStr has been processed, then process theFld to allFlds.
    TF_End←  { _← Str_End⍬ ⋄ 0=≢ theFld: ⍬ ⋄ allFlds,← ⊂ theFld ⋄ ⍬⊣ Fld_Clr⍬ }
  ⍝ Space Field Ending: Same as TF_End 
    SF_End← TF_End 
  ⍝ Str_End: A string (possibly empty), either a TF or a string in a CF, is now complete. 
  ⍝          Catenate to theFld after adding quotes and possibly mapping CRs and LFs. 
  ⍝ mode01:   See QtMultiLn
  ⍝  1:  "ab`⋄cd" => "('ab\rcd') ⍝ Where \r is an actual (⎕UCS 13) char.
  ⍝  0:  "ab`⋄cd" => "(↑'ab␍cd') ⍝ Where ␍ is the Unicode symbol '␍'.
    Str_End←{  
        ~strActive: ⍬ ⋄ strActive⊢← 0 ⋄ 0=≢ theStr: ⍬
        theFld,← mode01 QtMultiLn theStr ⋄ ⊢theStr⊢← ⍬
    }
  ⍝ Fld_Clr: objects (theFld theStr theSelfD) are cleared. allFlds is NOT changed.
    Fld_Clr← { theFld theStr theSelfD⊢← ⊂'' ⋄ ⍬ }
⍝ ++++++++++++++++++++++++++++++++
⍝ +++ Main Field Processing... +++
⍝ ++++++++++++++++++++++++++++++++
  ⍝ T_: Text Fields (default):   '...'
  ⍝ ∘ Recursively process the next text fields char, 
  ⍝   starting a CF or SF if bare left brace { is seen. 
    TF_Next←{
      0=≢⍵: boxO fStr (allFlds,⊂'⍬') ⊣ TF_End⍬    ⍝ <== RETURN from EXECUTIVE
    ⍝ Escapes within text sequences:  `⋄ ``  `{ `} 
      ×p← ⍵ Break escO lbC: TF_Next p↓ ⍵⊣ CatText p↑⍵ 
        ch← ⊃⍵ 
      escO= ch: (TF_Next _ScanEsc_ 0) 1↓⍵
      lbC = ch: CF_SF_Start 1↓⍵⊣ TF_End⍬ 
      TF_Next 1↓⍵⊣ CatText ch 
    }
    Executive← TF_Next 
  ⍝ CF_SF_: Code or Space fields  { code }  or {  } 
  ⍝   If a space field, process in its entirety at SF_Cod
  ⍝   If a code field, head off to CF_Start.
    CF_SF_Start←{
        isSpF← rbC= 1↑ ⍵↓⍨ nSp←⍵ Span ' '                                            
      isSpF: TF_Next ⍵↓⍨ 1+nSp ⊣  SF_Cod nSp                      ⍝ {} and {  }
        1 CF_Start ⍵                                              ⍝ { code }
    }
  ⍝ SF_Cod: Space Field code gen; see CF_SF_Start (above)
    SF_Cod← SF_End∘CatCode { ⍵=0: ⍬ ⋄ ⍵>5: ⍺⍺ '(', '⍴'''')',⍨ ⍕⍵ ⋄ ⍺⍺ QtSp ⍵⍴spC }
  ⍝ CF_: Code Fields { code }
  ⍝ ∘ Recursively process a code field, 
  ⍝   jumping to CF string subfield processing as required.
    CF_Start←{
      ⍝ CFStr_Start: Code String Subfields  { ... "xxx" ...} or { ... '...' ...}
        CFStr_Start←{   
            CFStr_Next← ⍺∘{  
                  CFStr_MyQt← { ch← ⊃⍵
                    ch≠ myQt: CF_Next ⍵⊣ Str_End⍬
                      CFStr_Next 1↓⍵⊣ CatText ch⍴⍨1+ch=sqC 
                  }
                  0= ≢⍵: Ê qStrÊ
                ×p←  ⍵ Break ⍺ sqC escO: CFStr_Next p↓ ⍵⊣ CatText p↑⍵ 
                  myQt← ⍺ ⋄ ch← ⊃⍵   
                ch= myQt: CFStr_MyQt 1↓⍵
                ch= sqC:  CFStr_Next 1↓⍵⊣ CatText 2⍴ ch 
                      ⍝   Escapes within code strings `⋄ `` `{ `}
                ch=escO:  (CFStr_Next _ScanEsc_ 0) 1↓⍵ 
                  Ê logÊ    ⍝ CFStr_Next 1↓⍵⊣ CatText ch 
            } ⍝ CFStr_Next
          1 0≡⍺=2↑⍵: CF_Next 1↓⍵⊣ CatCode ''''' ' ⋄ CFStr_Next ⍵
        } ⍝ CFStr_Start
      ⍝ CF_SelfDoc: Code Self-documenting expressions; { ... →} and { ... %} plus { ... ↓}.
        CF_SelfDoc← { brLvl ch←⍺ 
            isInfx← (1=brLvl)⍲ rbC= ⊃⍵↓⍨ nSp← ⍵ Span ' '
            o← ch≠ raC  
          isInfx: CF_Next ⍵⊣ ch CatCode (ch OVRcod⊃⍨ ch= ovrC) 
            _← Str_End 0 
            theSelfD,←  (nSp↑⍵),⍨ sdArrows⊃⍨ o  
            f← ⊂'(',(o⊃ CHNcod ''),(EnQt theSelfD),(o⊃'' OVRcod ),'(⍺{',theFld,'}⍵))' 
            TF_Next ⍵↓⍨ nSp+1⊣ allFlds,← f⊣ Fld_Clr ⍬ 
        }

      ⍝ CF_Start Executive  
        CF_Next← ⍺∘CF_Start 
      ⍺≤0: TF_Next ⍵⊣ CF_End⍬
      0= ≢⍵: Ê brcÊ  
    ⍝             breakCFChars← lbC rbC lpC sqC dqC spC escO omUC fmtC raC ovrC dnC
        p← ⍵ Break breakCFChars
      ×p: CF_Next p↓ ⍵⊣ CatCode p↑⍵          
        ch← ⊃⍵  
      lbC rbC∊⍨ ch: (⍺+-/ch= lbC rbC) CF_Start 1↓⍵ ⊣ CatCode ch 
      lpC=  ch: ch { 
                  rpC≠ ⊃⍵↓⍨ nSp← ⍵ Span ' ': CF_Next ⍵⊣ CatCode ⍺ 
                  CF_Next ⍵↓⍨ nSp+1⊣ CatCode '(⎕NS⍬)' 
                } 1↓⍵
      sqC dqC∊⍨ ch: ch CFStr_Start 1↓⍵   ⍝  Str_End 0 
      spC=  ch:     CF_Next nSp↓⍵⊣ (nSp↑⍵) CatCode spC⊣ nSp← ⍵ Span ' '
                 ⍝  Code Escape Sequence    `` `{ `} `⍵[ddd]? `⍹[ddd]?
      escO= ch:     (CF_Next _ScanEsc_ 1) 1↓⍵ 
      omUC= ch:     (CF_Next _Omega)  1↓⍵                   ⍝ ⍹[ddd]?
      fmtC∧.= 2↑⍵:  CF_Next 2↓⍵ ⊣ ch ch CatCode BOXcod
      fmtC= ch:     CF_Next 1↓⍵ ⊣ ch    CatCode FMTcod
      raC ovrC dnC∊⍨ ch: ⍺ ch CF_SelfDoc 1↓⍵                 ⍝ → % ↓
                    Ê logÊ  ⍝ CF_Next 1↓⍵ ⊣ CatCode ch 
    } ⍝ End CF_Start
    
⍝ ---------------------------
⍝ ---------------------------
⍝⍝⍝ MAIN: Options and Variables (non-constants)
      (modO boxO) escO←(2↑⍺)(⊃'`',⍨2↓⍺)                        ⍝ Set/validate options 
      fStr←⊃⊆⍵                                                 ⍝ fStr: The format string (⍹0)
    ((2>⍴∘⍴)⍱(0=80|⎕DR))fStr: Ê fStrÊ                          ⍝       Must be simple char vec/scalars 
    modO(~∊) ¯2 ¯1 0 1:       Ê opt0Ê                               
    boxO(~∊) 0 1:             Ê opt1Ê   
    escO∊ lbC spC cmC:        Ê opt2Ê                          ⍝ Invalid escape char?  
⍝ ---------------------------
⍝⍝⍝ MAIN: Run STAGE I: Process format string and pass resulting string/s to STAGE II
    oC← ' ⍙ⓄⓋⓇ ' '{⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}'
    cC← ' ⍙ⒸⒽⓃ ' '{⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍵}' 
    bC← ' ⍙ⒷⓄⓍ ' ' ⎕SE.Dyalog.Utils.disp '
    mode01← 0≤ ⊃⍺   ⍝ 1 for mode∊0 1; literal CR chars (⎕UCS 13) to be used in place of `⋄ escapes.
    OVRcod CHNcod BOXcod← mode01⊃¨ oC cC bC 
    FMTcod← ' ⎕FMT '
    breakCFChars← lbC rbC lpC sqC dqC spC escO omUC fmtC raC ovrC dnC
    Executive fStr                      
  } ∆F⍙Ⓡ 
  
  :SELECT ⍬⍴ ∆F⍙Ⓛ  
    :CASE 1   
      ⍝ ○ We delete (or shadow) the local names (after retrieving their values) 
      ⍝   so ⎕NL in the caller namespace won't include them (if it happens to contain ∆F also).
        ∆F⍙ⓇⓇ← ∆F⍙Ⓒ{ ⍺⍎⍨ ⍬⍴ ¯1↑⎕RSI⊣ ⎕EX 'ⓁⓇⒸ',⍨¨ ⊂'∆F⍙' }∆F⍙Ⓡ    ⍝ Execute and format
    :CASE 0    
        ∆F⍙ⓇⓇ← ∆F⍙Ⓒ⍎⍨ ⍬⍴ ¯1↑⎕RSI                                  ⍝ Generate a formatting dfn!
    :ELSE 
        ∆F⍙ⓇⓇ← ∆F⍙Ⓒ  
  :ENDSELECT
:ELSE 
   ⎕SIGNAL ⎕DMX.{ ⊂ 'EM' 'EN' 'Message',⍥⊆¨ ('∆F ',EM) (EN 999⌷⍨ ⎕IO+1000≤EN) Message }⍬
:ENDTRAP 
:Return 

⍝ Additional help information follows (⍝H prefix)
⍝H ⍺ OPTIONS:   modeO boxO escO 
⍝H      modeO←1   1: generate and execute F-string formatting on argument ⍵
⍝H                0: generate and return a "precompiled" F-string function ready
⍝H                   for execution with user arguments. Useful where the F-string
⍝H                   may be called repeatedly. 
⍝H               ¯1: return a pseudo-code version of the formatted f-string, 
⍝H                   with each field a separate (APL) string.
⍝H               ¯2: as for modeO=¯1, returns a pseudo-code version, except 
⍝H                   boxed (using dfn "disp") and with fields in table (⍪) form.
⍝H      boxO←0    0: don't box each field, 
⍝H                1: box each field on output 
⍝H      escO←'`'  escape char; by default '`'.
⍝H                Escape sequences include 
⍝H                      `⋄ (newline), 
⍝H                      `{ (literal left brace), 
⍝H                      `⍵ (equiv. to ⍹): `⍵5 (or: ⍹5) selects (5⌷⍵) with implicit ⎕IO=0, and 
⍝H                      `` (escape itself, useful just before a non-escaped left brace.
⍝H                The escape represents itself when used otherwise.
⍝H
⍝H ---------------------------------------------------------------------------------------
⍝H ∆F Utility Function
⍝H -------------------
⍝H    ∆F is a function that uses simple input string expressions, f-strings, to dynamically build 
⍝H    2-dimensional output from variables and dfn-style code, shortcuts for numerical formatting, 
⍝H    titles, and Main. To support an idiomatic APL style, ∆F uses the concept of fields to organize the
⍝H    display of vector and multidimensional objects using building blocks (like ⎕FMT) that already exist
⍝H    in the Dyalog implementation. (∆F is reminiscent of f-string support in Python, but in an APL style.)
⍝H Quick example:
⍝H ⍎      ∆F 'The current temp is{1⍕⍪1↓⍵}°C or{1⍕⍪32+(9÷5)×1↓⍵}°F.' 20 30 40 50
⍝H ⎕   The current temp is 20.0°C or  68.0°F.
⍝H ⎕                       30.0       86.0   
⍝H ⎕                       40.0      104.0   
⍝H ⎕                       50.0      122.0   
⍝H Syntax: 
⍝H     [mode←1 box←0 escCh←'`' | ⍬ | 'help'] ∆F f-string  args 
⍝H 
⍝H     ⍵← f-string [[⍵1 ⍵2...]]
⍝H        f-string: char vector with formatting specifications.
⍝H               See below.
⍝H        args:  arguments visible to all f-string code expressions (0⌷⍵ is the f-string itself). 
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
⍝∆                                                executed_code
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
⍝H 3. Text fields: any APL characters at all, except to represent {} and ` (or the current escape char).
⍝H    (If you change the escape character, e.g. to '\', make the appropriate changes in the narrative below).
⍝H    `{ is a literal {
⍝H    `} is a literal }
⍝H     { by itself starts a new code field
⍝H     } by itself ends a code field
⍝H    `⋄ stands for a newline character (⎕UCS 13).
⍝H     ⋄ has no special meaning, unless preceded by the current escape character (`).
⍝H     ` before {, }, or ⋄ must be doubled to have its literal meaning (`` ==> `)
⍝H     ` before other characters has no special meaning (i.e. appears as a literal character, unless escaped).
⍝H    Single quotes must be doubled as usual when typing in APL strings to be evaluated in code or via ⍎. 
⍝H    Double quotes have no special status in a text field (but see Code Fields).
⍝H    ⍹ and `⍵ have no special status in text fields (they are left as is).
⍝H
⍝H For help, execute                                             
⍝H   ∆F⍨'help' ... or see ⍝H "HELP" comments at the bottom of function ∆F.
⍝H 
 
