∆F_BIG←{ 
⍝ Simple formatting  function in APL style, inspired by Python f-strings.
⍝ Syntax: [opts] ∆F f-string  args 
⍝        f-string: char vector with formatting specifications
⍝        args: arguments visible to f-string code expressions 
⍝              ⍹1=1st arg after f-string (⎕IO independent)
⍝        opts: [MODE BOX NS EXECNS←[1 [0 [0 [0]]]] | 'help'* | ⍬]  
⍝ For help, execute                                             *=Any case
⍝   ∆F⍨'help' ... or see ⍝H "HELP" comments at the bottom of this function.
⍝ See help PDF at:
⍝   https://drive.google.com/file/d/1x82YiNDTHlw0uMFgcElIRSFfK_PnLeOq/view
⍝ For internal error handling, 
⍝   See I. F-string Processing Function (I.A. Setup), below.

⍝ Metaconventions Used Here...
⍝   Name Templates: FnName; varName; _tempVar; _TempFn; CONSTANT_PARAMETER; ...
⍝   Class Suffixes: _P=regexp pattern; _R=regexp result; _G=Global (within this fn); _I=small int const.; 
⍝                   _C=code str; _Opt=option; _OptS=option spec; _Nm=obj namestring;
⍝   Other Abbrev:   TF=Text Field; CF=Code Field; SF=Space Field; CSF=Code or Space Field;
⍝                   DQ=double quotes or DQ strings; SQ=single quotes...

    ⍺←1 0 0 0
  ⍬≡⍺: _←1 0⍴'' 
⍝ HELP:   Use 1) External URL and Ride for HELP vs 2) Basic Help generated internally
 'help' 'help!'∊⍨⍥⊆⎕C ⍺: 1 0⍴''⊣  (HELP_RIDE←1∧'help!'≢⎕C ⍺) {   ⍝ Don't change this line AT ALL!!!
      { ~⍺: 0 
    ⍝ HELP.RIDE=1: Send helpfile URL to Dyalog Ride.  <meta...> displays the requested URL immediately... 
        helpUrl← '"https://drive.google.com/file/d/', '/view?usp=sharing"',⍨ '1x82YiNDTHlw0uMFgcElIRSFfK_PnLeOq'
        0='∆F HELP'(3500⌶)'<meta http-equiv="Refresh" content=''0; url=',helpUrl,''' />'
        }⍨⍺: 0 
    ⍝ HELP_RIDE=0:  Gather help info in this function (marked '⍝H') 
        ⎕ED 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⍵ 
    } ⊃⎕XSI 

  ⍝ Phase II. F-string Code Execution Operator: 
  ⍝    MODE
  ⍝    1   Execute executable immediately,  then return formatted matrix result.
  ⍝    0   Package executable code string,  then return it.
  ⍝   ¯1   Package pseudocode string,       then return it.
  ⍝    Syntax: ⍺ (⍺⍺ ∇∇ ⍵⍵) ⍵
  ⍝      ⍺:   MODE  (orig. ⊃⍺)    ⍺⍺:  execution namespace ref (default 0 means the caller ns)
  ⍝      ⍵⍵:  orig. ⍵              ⍵:  executable based on input f-string

    (⊃⍺)((⊃3↓⍺){    ⍝ ⍺⍺ ← (3⊃⍺) if (4=≢⍺), else 0.  [⎕IO←0]
    0 1000:: ⎕SIGNAL⊂⎕DMX.('EN' 'EM' 'Message',⍥⊂¨(999⌊EN)('∆F ',EM)Message) 
    ⍝ MODE=1  (immediate execution: execute)  
      (1=⍺) ∧ 0=⍺⍺:      (⊃⎕RSI) ⍎⍵,'⍵⍵' ⊣⍵⍵           ⍝ Default namespace 
      (1=⍺) ∧ 9.1 9.2∊⍨⎕NC⊂'⍺⍺': ⍺⍺   ⍎⍵,'⍵⍵' ⊣⍵⍵      ⍝ 9.1: user-specified namespace; 9.2 for ⎕SE or # via quirk of ⍺⍺ 
       1=⍺:              ⎕SIGNAL/'∆F DOMAIN ERROR: Invalid execution namespace' 11  
    ⍝ MODE∊0 ¯1  (prepend error code to executable code; wrap executable or pseudocode in fn call)
        errC← '0 1000:: ⎕SIGNAL⊂⎕DMX.(''EN'' ''EM'' ''Message'',⍥⊂¨(999⌊EN)(''∆F '',EM)Message)⋄' 
        WrapSQ← '''','''',⍨⊢(/⍨)1+''''∘=
        '{', (errC/⍨ 0≤⍺), ⍵, (WrapSQ ⊃⍵⍵),',⍥⊆⍵}'  
    }(,⊆⍵))⍺{ 

  ⍝ Phase I.  F-string Processing ("Compilation") Function
  ⍝      Returns executable based on input f-string to anon dfn "I. (F-string Exec. Operator)"
  ⍝      Syntax:  ⍺ ∇ ⍵   (⍺ as from caller; ⍵ is ⊆⍵ from caller).
  ⍝   I.A. Setup
  ⍝   I.B. Processing Tokenized Fields
  ⍝   I.C. Tokenizing F-string to Fields
  ⍝   I.D. Executive
  
  ⍝ I.A. Fn Setup: Error Handling, Option Flags, Shortcut/Option Code Strings
        ⎕IO ⎕ML←  0 1
      ⍝ CONSTANT FLAGS... 
      ⍝ UCS_ESC_ENABLED: Unicode Escape String 
      ⍝    Supports DQ-string \u{ddd} OR \U{ddd} and \u{ddd-eee} or \U{ddd-eee}, 
      ⍝    where ddd, eee are 1 or more decimal digits.
        UCS_ESC_ENABLED← 1                             ⍝ Experimental. May be 1 or 0. See dfn DQStrEsc below.
  
        cOS1←1+cOS←≢dOS← (¯1 0 1)(1 0)(1 0)            ⍝ Option (⍺) specifications. We don't validate 3⊃⍺ here.
        Err← ⎕SIGNAL⍤⊂'EN' 'EM' 'Message',⍥⊂¨⊢         ⍝ Error Handling...
      ((cOS1<≢)∨(1<⍴∘⍴)∨(1<|∘≡))⍺:    Err 11 '∆F DOMAIN ERROR' 'Invalid option'            
      ~∧/dOS∊⍨¨⍺↑⍨cOS:                Err 11 '∆F DOMAIN ERROR' 'Invalid option'            
      ((1<⍴∘⍴)∨(×80|⎕DR))⊃⍵:          Err 11 '∆F DOMAIN ERROR' 'Invalid f-string'
                                                       ⍝ ↓ Unexpected Errors...
      0:: Err 911 '∆F INTERNAL ERROR', {⍺,⍵,⍨': '/⍨0≠≢⍵}/ ⎕DMX.(EM Message)  
   
        modeOpt boxOpt nsOpt← 3↑⍺                      ⍝ Option Flags (⍺)   
        isPseudo← ⍬⍴modeOpt<0                          ⍝ isPseudo: PSEUDO-CODE Mode   

        SetCodeVars←{ isPs bxFnNm← ⍵
          ⍝ codeVars6←  ∇ isPseudo bxFnNm 
          ⍝ Note required padding with blanks, where code not otherwise prefixed or suffixed with non-alph sep chars
          ⍝ ⍁... means a pseudo-system fn. Just for show.
          isPs:  ' ⎕FMT '   '  ⍁BOX '    ' ⍁BOXM '  ' ⍁OVER ' ' ⍁CHAIN ' '⊃⍁CHAIN/'
            3≠⎕NC bxFnNm: 6 ⎕SIGNAL⍨'∆F VALUE ERROR: Utility "',bxFnNm,'" not found.'
              _← ⊂  ' ⎕FMT '                                ⍝ ⎕FMT:     Format obj ⍵
              _,←⊂ ' ',bxFnNm,' '                           ⍝ ⍁BOX:     Box obj ⍵
              _,←⊂ '(''·''@('' ''=⊢))',bxFnNm,' '           ⍝ ⍁BOXM:    Box obj ⍵ and replace spaces with middle dots
                _oC←'(⊃⍪/)⍤{T←↑⍤¯1⋄m←⌈/w←⍺,⍥(⊃⌽⍤⍴)⍵⋄w{⍺=m:⍵⋄m T⍵T⍨-⌊⍺+2÷⍨m-⍺}¨⍺⍵}⍥⎕FMT '
              _,←⊂ _oC                                      ⍝ ⍁OVER:    Place matrix-⍺ over matrix-⍵
              _,←⊂  '{⊃,/⍺⍵↑⍨¨⌈⍥≢/⍺⍵}⍥⎕FMT '                ⍝ ⍁CHAIN:   Chain matrix-⍺ to left of matrix ⍵
              _,←⊂ '⊃{⊃,/⍺⍵↑⍨¨⌈⍥≢/⍺⍵}⍥⎕FMT/⌽'               ⍝ ⊃⍁CHAIN/: Chain together list of matrices-⍵ left to right
              _
        } 
        fmtC boxFnC boxModeC overC chainC chainFoldC← SetCodeVars isPseudo '⎕SE.Dyalog.Utils.display' 
  
  ⍝ I.B. Process Tokenized Fields
  ⍝   I.B.0. Setup / Shared Defs, e.g. define IsCSF (what's a code or space field), IsSF (what's a space field)
  ⍝   I.B.1. ProcTF       - Process Text Fields
  ⍝   I.B.2.              - Process Code and Space Fields
  ⍝      I.B.2a. DQStrEsc    - Process Code Field DQ String Escapes 
  ⍝      I.B.2b: ProcCSf     - Process Code/Space Fields
  ⍝   I.B.3. ProcFlds     - Process All Fields    
        
      ⍝ I.B.0 (Setup / Shared Defs)
        ⍝ Miscellany
          WrapSQ←  '''','''',⍨⊢(/⍨)1+''''∘=                 ⍝ Double the SQs in ⍵ and wrap ⍵ in SQs.
          WrapParen← '(',')',⍨⊢                             ⍝ Wrap ⍵ in parens.
        ⍝ Field Tests: Test for combined CSF (Code/Space Fields) and SF (Space Fields)  
          IsCSF←(∊∘(⎕UCS 1 0))⊃  ⍝   \x{0} or \x{1}         ⍝ See TagTF/SF/CF and Tok2Flds below.
          IsSF← (∊∘(⎕UCS 1))⊃    ⍝   \x{1}   
        ⍝ Fields Tags: Tag (⎕R result) field string ⍵ and append with field boundaries... 
        ⍝ ... as a Text (TF), Space (SF), or Code Field (CF).    
          CR X0 X1← ⎕UCS 13 0 1           
          TagTF←  CR,    CR,⍨⊢                              ⍝ TF: empty tag
          TagSF← (CR,X1),CR,⍨⊢                              ⍝ SF: ⎕UCS 1
          TagCF← (CR,X0),CR,⍨⊢                              ⍝ CF: ⎕UCS 0

        ⍝ CR on output (APL text)
          ⋄ CRout←   isPseudo⊃ CR '␍'
  
      ⍝ I.B.1. Process Text Fields
      ⍝   ProcTF                            
      ⍝        \ is special if and only if:
      ⍝           just before ⋄.               \⋄  => CR
      ⍝           just before {, }, or \.      \{  => }      \} => },  \\ => \
          ProcTF← (' ',⊢)WrapSQ⍤ ( '\\([{}])' '\\{2}(?=[{}⋄])' '\\⋄'  ⎕R '\1' '\\' CRout )           

      ⍝ I.B.2. Process Code and Space Fields
   
        ⍝ I.B.2a. Process Code Field Double-Quoted String Escapes[see "Case dqStrI"]  
        ⍝   DQStrEsc 
        ⍝ Note: UCS_ESC_ENABLED set at "I.A. Fn Setup" near top... (Experimental)
        ⍝       If 0, unicode escapes are simply ignored (left as is).
        ⍝       If 1, they are converted to unicode vectors "\{aaa-bbb}" or scalars "\{aaa}" as indicated.
          dq_dq2P←    '"{2}'                                      ⍝ ""  => "
          dq_escDmdP← '(\\{1,2})⋄'                                ⍝ \\⋄ => ⋄,  \⋄  =>  CRout
          dq_escUCSP← '\\[uU]\{\h*(\d+)(?|\h*-\h*(\d+)|())\h*\}'  ⍝ \U{ddd-eee}, \U{ddd}, \\U{anything else}; \u...
          dq_esc2P←   '\\{2}'                                     ⍝ \\  =>  \\   (no change)
          dq_Pats← dq_dq2P dq_escDmdP dq_escUCSP dq_esc2P 
                   dq_dq2I dq_escDmdI dq_escUCSI dq_esc2I← ⍳≢dq_Pats  
          dq_PatsAlt← dq_Pats↓⍨ -~UCS_ESC_ENABLED
          DQStrEsc←  dq_PatsAlt  ⎕R {
              ⋄ Case← ⍵.PatternNum∘∊
              ⋄ Fld←  ⍵.(⌷∘Lengths↑Block↓⍨⌷∘Offsets)
              Case dq_dq2I:     '"'
              Case dq_escDmdI:  CRout '\⋄' ⊃⍨ 2=≢Fld 1
              Case dq_esc2I:    Fld 0 
            ⍝ Should never be reached unless UCS_ESC_ENABLED
            ~UCS_ESC_ENABLED: ''⊣⎕←'∆F LOGIC ERROR [UCS_ESC_ENABLED=0]' 
            ⍝ Case dq_escUCSI    
              beg end← ⊃∘⌽∘⎕VFI∘Fld¨1 2
            0=≢end: ⎕UCS beg ⋄ ⎕UCS beg+(×∆)×⍳1+|∆←end-beg
          } 
        ⍝ I.B.2b. Process Code and Space Fields
        ⍝   ProcCSf
        ⍝   - Returns executable code
          csf_dqStrP←   '(?:"[^"]*")+'                     ⍝ "...". Escapes honored.
          csf_sqStrP←   '(?:''[^'']*'')+'                  ⍝ '...'. Escapes ignored (not honored).
          csf_comP←     '⍝[^}⋄]*'                          ⍝ Comments: (limited pattern)                         
          csf_dolP←     '\h*(\${1,2})\h*'                  ⍝ $ and $$ shortcuts.   
          ⋄ dolCodeV← fmtC boxFnC
          csf_pctP←     '\h*(\%{1,2})\h*'                  ⍝ % and %% shortcuts
          ⋄ pctCodeV←  overC chainC
          csf_omegaNP←  '[⍵⍹](\d+)'                        ⍝ ⍹N, ⍵N        
          csf_omega0P←  '⍵_|⍹_?'                           ⍝ ⍹ ⍵_
          csf_Pats← csf_dqStrP csf_sqStrP csf_comP csf_dolP csf_pctP csf_omegaNP csf_omega0P   
                   csf_dqStrI csf_sqStrI csf_comI csf_dolI csf_pctI csf_omegaNI csf_omega0I← ⍳≢csf_Pats  
          omegaG←0
        ProcCSf←  WrapParen {                             ⍝ Parens around each result!
            parensOnly←⍺
            code← csf_Pats ⎕R {  
                ⋄ Case← ⍵.PatternNum∘∊
                ⋄ Fld←  ⍵.(⌷∘Lengths↑Block↓⍨⌷∘Offsets)
              Case csf_dqStrI: ' ',WrapSQ DQStrEsc 1↓¯1↓Fld 0  ⍝ DQ String: Escapes applied
              Case csf_sqStrI: ' ',Fld 0                   ⍝ SQ String: No Escapes applied. Not: WrapSQ 1↓¯1↓Fld 0        
              Case csf_comI:   ''                          ⍝ Ignore comments...
              Case csf_dolI:   dolCodeV⊃⍨ 2=≢Fld 1         ⍝ $/$$: ⎕FMT/BOX
              Case csf_pctI:   pctCodeV⊃⍨ 2=≢Fld 1         ⍝ %,%%: OVER/CHAIN
              Case csf_omegaNI: '(⍵⊃⍨⎕IO+',')',⍨f1       ⊣  omegaG⊢← ⊃⌽⎕VFI f1←Fld 1              
              Case csf_omega0I: '(⍵⊃⍨⎕IO+',')',⍨⍕omegaG  ⊣  omegaG+← 1   
              ○○ LOGIC ERROR: NOT REACHABLE ○○
            } ⍵                                          
          parensOnly: code                               ⍝ Return a code str with no refs to ⍺, ⍵, ...
            _Decor←('⍺'/⍨nsOpt)∘,'{',,∘'}⍵'              ⍝ Code str decorations: ⍺{...}⍵
            _Trim← ' ⋄'∘{⍵↓⍨-+/∧\⍺∊⍨⌽⍵}                  ⍝ _Trim:       Remove trailing ' ⋄'
            sfx←¯1↑trm← _Trim code                       ⍝ sfx:         Last (non-trailing) char
            notSD← ~sfx∊'→↓'                             ⍝ sfx ∊ '→↓'?  we have self-documenting code.                         
          notSD: _Decor code                             ⍝    If NO:    Return the code
            jDC← chainC overC⊃⍨ sfx='↓'                  ⍝    If YES:   Join doc+code via CHAIN or OVER.
            (WrapSQ ⍵), jDC, _Decor ¯1↓trm               ⍝              with quoted doc and trimmed code 
        }
          
      ⍝ I.B.3. Process all fields by type, set by Tok2Flds below.  
      ⍝   ProcFlds                  
      ⍝   - Returns at least 2 fields (Pad2Flds), as required by CHAINdef (which see).
          Pad2Flds←  ⊢,⍨ '⍬'⍴⍨ 0⌈ 2-≢  
          CondBox← (WrapParen boxModeC,⊢)⍣boxOpt        ⍝ If boxmode, put ⍵ in a box!
          CondSV←  (WrapParen (','/⍨1=≢⍤⊣),1↓⊢)⍣boxOpt  ⍝ If boxmode, treat scalar ⍵ as vector for boxing
        ProcFlds← Pad2Flds CondBox∘{ 
            IsCSF ⍵: (IsSF ⍵) ProcCSf 1↓⍵ ⋄ ⍵ CondSV ProcTF ⍵  ⍝ IsCSF: Is it a CF or SF?  IsSF: Is it a SF?
        }¨

  ⍝ I.C. Tokenizing F-String to Fields (space fields [3 subtypes]; code fields; all else as text fields)
  ⍝      Tok2Flds    
  ⍝      - Returns: A set of fields, each as a char vec.  
          tf_TFP←  '(?x)  (?> [^\\{}]+ | \\{2}+ | \\{1}[⋄{}]? )+ '                        ⍝ Text Fields                                      
          tf_SF0P← '(?x) \{ (?: \h* : 0* :? \h* )? (?:⍝[^}]*)? \}'                        ⍝ Space Fields {}  
          tf_SF1P← '(?x) \{ ( \h* ) (?:⍝[^}]*)? \}'                                       ⍝ Space Fields {  }
          tf_SF2P← '(?x) \{ \h* : ( \d+ | ⍹ \d*  | ⍵ (?:\d+|_)? ) :? \h* (?:⍝[^}]*)? \}'  ⍝ Space Fields {:5:} {:⍵2:}    
          tf_CFP←  '(?x) (?<P> \{ ((?>  [^{}"''⍝\\]+ | (?:\\.)+ | '                       ⍝ Code Fields  
          tf_CFP,←      '(?:"[^"]*")+ | (?:''[^'']*'')+ | ⍝[^}⋄]* | (?&P)* )+)  \} )' 
  
          tf_PV←  tf_TFP tf_SF0P tf_SF1P tf_SF2P tf_CFP 
                  tf_TFI tf_SF0I tf_SF1I tf_SF2I tf_CFI← ⍳≢tf_PV
          ⋄ RemoveNullF←  ⊢(/⍨)0∘≠⍤≢¨                
        Tok2Flds← RemoveNullF tf_PV ⎕R {
            ⋄ Case← ⍵.PatternNum∘∊
            ⋄ Fld←  ⍵.(⌷∘Lengths↑Block↓⍨⌷∘Offsets)
            Case tf_TFI:  Fld 0
            Case tf_SF0I: TagTF ''
            Case tf_SF1I: TagTF Fld 1
            Case tf_SF2I: TagSF '(', f1, '⍴'''')' ⊣ f1← Fld 1
            Case tf_CFI:  TagCF Fld 2
        }
  ⍝+-------------------------------------+⍝
  ⍝+ I.D. Executive: Put it all together +⍝
  ⍝+-------------------------------------+⍝
        ⋄ AddPreamble← (nsOpt/'(⎕NS⍬)') ,'{','}',⍨ chainFoldC,(∊⌽⍣ (~isPseudo))
        AddPreamble ProcFlds Tok2Flds ⊆⊃⍵
    }⊆⍵  

  ⍝………………………………………………………………… INTERNAL HELP DOCUMENTATION STARTS HERE ……………………………………………………………………………
  ⍝H+---------------------+
  ⍝H+        ∆F           +
  ⍝H+---------------------+
  ⍝H
  ⍝H ∆F: Simple format string function in an APL style based on 2D text, variables and code, 
  ⍝H     and space fields, with shortcuts for numeric formatting, titles, and more. 
  ⍝H     Inspired by, but divergent from, F Strings in Python.
  ⍝H …………………………………………………………………………………………………………………………………………………………………………………………………………
  ⍝H Syntax:  options ∆F f-string args
  ⍝H      f-string:      A string containing variables, code, text and formatting  
  ⍝H                     specifications to display a mixture of APL objects easily.
  ⍝H      args:          O or more "arguments" that can be easily used to incorporate 
  ⍝H                     on-the-fly values into the format string.
  ⍝H      options:       [ [MODE=1|0|¯1] [ [BOX=0|1] [ [NS=0|1]  [ [EXECNS=callerNs|nsRef] ]]] | 'help' | ⍬ ]
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨↑¨¨¨¨¨¨¨¨¨¨¨¨¨¨↑¨¨¨¨¨¨¨¨¨¨↑¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨↑¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H   options      ∆F Returns 
  ⍝H > MODE=1       [IMMEDIATE] A char matrix based on the format string and subsequent values of ⍵. 
  ⍝H                (Default mode). In this mode, 2D fields are "chained" together 
  ⍝H   MODE=0       [CODE GEN] A char vector, representing an executable dfn in string form
  ⍝H                (which can be established via MyFmtDfn← ⍎0 ∆F myFmtStr)
  ⍝H   MODE=¯1      [PSEUDO-CODE]A char vector representing the formatting as a pseudo-code string,  
  ⍝H                suitable for inspection, debugging, etc.
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H > BOX=0        Each field is displayed normally (and returned per MODE). (Default).
  ⍝H   BOX=1        Each field  will be displayed in a 2D box (and returned per MODE). 
  ⍝H                Blanks will be replaced by a center dot (·) in the output. 0-width fields are omitted.
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H > NS=0         Code fields have no private NS passed as ⍺. (Default).
  ⍝H   NS=1         A private NS shared among all Code Fields will be passed as ⍺.
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H > EXECNS=callerNs  Code Fields are executed in the ns from which ∆F was called (0 may be used to signify it).
  ⍝H   EXECNS=nsref     Code fields are executed in namespace <nsref>, which must be a valid namespace reference.
  ⍝H                    This option is IGNORED if MODE≠1, since execution is left to the user (for Mode=0).
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H   ⍺≡'help'     An empty char vec (''). See HELP.
  ⍝H   ⍺≡⍬          A shy char matrix (1 0⍴' '). Right arg ⍵ is ignored. No formatting is done.
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H EXAMPLES
  ⍝H ¨¨¨¨¨¨¨¨
  ⍝H Example 1a:  Text Fields and Code Fields {…} with simple variables.
  ⍝H        names←  ↑'John Jones'  'Mary Smith'
  ⍝H        addr←   ↑'1214 Maiden Ln'  '24 Hersham Rd'
  ⍝H …      ∆F 'Name: { names }  Addr: { addr }'
  ⍝H     Name: John Jones  Addr: 1214 Maiden Ln
  ⍝H           Mary Smith        24 Hersham Rd 
  ⍝H 
  ⍝H Example 1b: Self-documenting code expressions {…→} in Code Fields.
  ⍝H     ⍝ Same definitions as above. 
  ⍝H …      ∆F '{names→}  {addr→}'
  ⍝H     names→John Jones   addr→1214 Maiden Ln  
  ⍝H           Mary Smith        24 Hersham Rd 
  ⍝H
  ⍝H Example 1c: Titles (using the OVER shortcut %)
  ⍝H     ⍝ Same definitions as above. Char strings in {code} use double quotes like "this!". 
  ⍝H …      ∆F '{"Name" % names}  {"Address" % addr}'
  ⍝H        Name        Address    
  ⍝H     John Jones  1214 Maiden Ln
  ⍝H     Mary Smith  24 Hersham Rd 
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H Example 2: Calculations and Formatting ($, short for ⎕FMT) in Code Fields.
  ⍝H       c←  100 20 12 23 ¯2
  ⍝H       F←  32+1.8∘×
  ⍝H     ⍝ 2a: Format specification as an argument ⍵1, i.e. (1+⎕IO)⊃⍵. (Degree sign (°): ⎕UCS 176)
  ⍝H …     ∆F '{ ⍵1 $ c }C = { ⍵1 $ F c }F' 'I3,⊂°⊃'   ⍝ Result is a 5-row 15-col char matrix.
  ⍝H  100°C =  212°F
  ⍝H   20°      68°              
  ⍝H   12°      54°              
  ⍝H   23°      73°              
  ⍝H   ¯2°      28°  
  ⍝H
  ⍝H     ⍝ 2b: Format specification hard-wired in Code Field. 
  ⍝H     ⍝     Note alternative way to enter '°' as unicode 176 (decimal).
  ⍝H …     ∆F '{ "I3,⊂°⊃" $ c }C = { "F5.1,⊂\u{176}⊃" $ (32+1.8∘×) c }F'  
  ⍝H  100°C = 212.0°F
  ⍝H   20°     68.0° 
  ⍝H   12°     53.6° 
  ⍝H   23°     73.4° 
  ⍝H   ¯2°     28.4° 
  ⍝H 
  ⍝H     ⍝ 2c: Variant on (2b) with a header for each Code field using the % (OVER) shortcut.
  ⍝H …     ∆F'{"Celsius" % "I3,⊂°⊃" $ c }  { "Fahren." % "F5.1,⊂°⊃" $ (32+1.8∘×) c }'
  ⍝H  Celsius  Fahren.
  ⍝H   100°    212.0° 
  ⍝H    20°     68.0° 
  ⍝H    12°     53.6° 
  ⍝H    23°     73.4° 
  ⍝H    ¯2°     28.4° 
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H Example 3: BOX display option (1=⊃⌽⍺)
  ⍝H     ⍝ Displays each field in its own "box" (ignoring null (0-width) fields)
  ⍝H     ⍝ Field:  1..⍬ ⍬  2 3…  4..   ⍬   5 6….
  ⍝H …     1 1 ∆F 'one{}{}{ }two {"two"}{:0}{ }three'  
  ⍝H   ┌→──┐┌→┐┌→───┐┌→──┐┌→┐┌→────┐
  ⍝H   │one││ ││two ││two││ ││three│
  ⍝H   └───┘└─┘└────┘└───┘└─┘└─────┘
  ⍝H     ⍝ Without BOX option.
  ⍝H …     ∆F 'one{}{}{ }two {"two"}{:0}{ }three'   ⍝ Or: 1 0 ∆F …
  ⍝H   one two two three
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H HELP
  ⍝H ¨¨¨¨
  ⍝H For help, enter  
  ⍝H   ∆F⍨'help'   OR  'help' ∆F ''  
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H A. The ∆F Format String (⍹0)
  ⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  ⍝H The f-string is a character vector defining 0 or more 2-D (char matrix) "fields," 
  ⍝H which are executed like separate statements-- left to right-- and assembled into a single matrix 
  ⍝H (with fields top-aligned). Its contents are in "shortcut" variable ⍹0.
  ⍝H
  ⍝H There are 3 types of fields generated: 
  ⍝H    1. Code Fields, 2. Space Fields, and 3. Text Fields.
  ⍝H
  ⍝H A1. Code Fields: 
  ⍝H        radii← 12 2.3 19
  ⍝H …      ∆F ' { Area_Cir←{○⍵×⍵} ⋄ "F8.2" $ radii,⍤¯1⊣ (Area_Cir radii) }' 
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H    Code Fields are dfns and may contain any dfn code, including error handling. 
  ⍝H    Internally, each code field is executed right-to-left, as in APL.
  ⍝H    Each Code field has implicit right arguments, namely everything passed to ∆F as ⍵ when executed.
  ⍝H 
  ⍝H    Special Variables ⍹0,⍹, etc., used in Code Fields*
  ⍝H    ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨  * Alias ⍵0, ⍵_, etc. See also usage in Space Fields.
  ⍝H       ⍹0, ⍹1, … ⍵N, denote the scalars in the right arg (⍵) passed to ∆F. 
  ⍝H       ⍹ is the glyph ⎕UCS 9081.
  ⍝H       ⍹0: (0⊃⍵) the format string itself (⎕IO=0).  
  ⍝H       ⍹1: (1⊃⍵) the first scalar after the format string. 
  ⍝H       ⍹N: (N⊃⍵) the Nth scalar after the format string, N one or more digits.
  ⍝H       ⍹:  [⍹ with no digits immed following]
  ⍝H           selects the "next" scalar to the right, starting AFTER the format string with ⍹1.
  ⍝H        ∘  The counter for ⍹ is incremented by 1 just before each use. 
  ⍝H        ∘  The counter for ⍹ is set after each use of ⍹N from left to right in Code Fields in the format string:  
  ⍝H           * If  ⍹N is used in a Code Field, the next ⍹ is ⍹N+1;
  ⍝H           * If more than one  expression ⍹N, ⍹P, ⍹Q appears in any Code Field, 
  ⍝H             the one just before the ⍹ on the left determines its next value (here ⍹Q+1).
  ⍝H        ∘  NB: the initial value of ⍹ is ⍹1, never ⍹0. (⍹0 may only be referenced explicitly).
  ⍝H        ∘  ⍹'s index is set at "compile" time, scanning LEFT to RIGHT (not RIGHT to LEFT as for stmt execution):
  ⍝H           Thus 
  ⍝H              ∆F '{⍹ ⍹ ⍹} and {⍹ ⍹ ⍹}' 1 2 'three' 4 'five' 6 
  ⍝H           returns 
  ⍝H              1 2 three and 4 five 6
  ⍝H        ∘  There are easy to type alternatives to using the glyph '⍹' :
  ⍝H           IN PLACE OF            USE
  ⍝H           ⍹0, ⍹1, … ⍹N         ⍵0, ⍵1, … ⍵N     e.g. ⍹5×⍹6 ≡ ⍵5×⍵6
  ⍝H           bare ⍹                 ⍵_                 e.g. ⍹+1   ≡ ⍵_+1
  ⍝H        ⍵  What about ⍵ (without any numeric suffix or _)?
  ⍝H           ⍵ by itself is not special, indicating the entire right arg to ∆F (when executed);
  ⍝H           it consists of the scalars ⍹0 ⍹1 … ⍹N.
  ⍝H 
  ⍝H    {ccc} Code Field Syntax and Quoted Strings
  ⍝H    ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨  
  ⍝H     ccc  any dfn code, including multiple stmts, guards, and error guards.
  ⍝H        ∘ A left brace '{' begins a code field, which is terminated by a balancing right brace '}'.
  ⍝H        ∘ Code ccc is executed and the result is formatted via ⎕FMT.
  ⍝H        ∘ \{ and \}, i.e. braces escaped with backslash (\), do NOT start a code field. 
  ⍝H          They are simple '{' and '}'.
  ⍝H        ∘ To enter quoted strings in Code Fields, use double quotes "like these":
  ⍝H          - {⎕NC "fred"} is easier than {⎕NC ''fred''}
  ⍝H          - In a code field, there are a few escape sequences within double-quoted strings ONLY. 
  ⍝H            Outside of these cases, backslashes (\) are, as in std APL, not special.
  ⍝H               \⋄         indicates a carriage return (⎕UCS 13). It is returned as a visible CR (␍) if MODE=¯1.
  ⍝H               \\⋄        indicates chars '\⋄'
  ⍝H               \u{ddd}     indicates* (⎕UCS ddd), where ddd consists of 1 or more digits 
  ⍝H                                     (*) W/o a 2nd preceding backslash; leading/trailing spaces ok. 
  ⍝H               \u{ddd-eee} indicates* unicode chars from ddd to eee
  ⍝H                          inclusive, where ddd, eee are 1 or more digits  
  ⍝H                                     (*) W/o a 2nd preceding backslash; leading/trailing spaces ok. 
  ⍝H               \\u{ddd}  OR  \\u{ddd-eee}
  ⍝H                     indicates literal string  \u{ddd} OR \u{ddd-eee}, i.e. APL text with the extra \ removed.
  ⍝H               Any other variant of \u{…} or backslash within strings is kept as ordinary tet:               
  ⍝H                           "\u{123+⍳5}" ==> "\u{123+⍳5}"   -- unchanged, including backslash (\).
  ⍝H                           "abc\def"    ==> "abc\def"      -- unchanged, including backslash (\).
  ⍝H             Examples
  ⍝H             ¨¨¨¨¨¨¨¨
  ⍝H …                ∆F '"{"\u{97-109}…\u{57-48}"}"' 
  ⍝H              "abcdefghijklm…9876543210"
  ⍝H                ⍝ In DQ strings, "\⋄" is the same as "\u{13}".
  ⍝H …                ∆F '{"Dogs\⋄Cats"} same as {"Dogs\u{13}Cats"}'
  ⍝H              Dogs same as Dogs
  ⍝H              Cats         Cats 
  ⍝H        ∘ To include a double quote (") within a double-quoted string, double it the APL way:
  ⍝H             "abc""def""ghi"  ==>   abc"def"ghi
  ⍝H        In a code field (outside strings)
  ⍝H        ∘ $ is a special symbol for ⎕FMT to allow easy formatting (using the dyadic variant):
  ⍝H             {"F8.2" $ MyCode…}       ⍝ Same as {"F8.2" ⎕FMT MyCode…}
  ⍝H        ∘ $$ (BOX) is a special symbol for the display function (see the DFNS ws), which 
  ⍝H          formats objects in a box:
  ⍝H             { $$ MyCode…} 
  ⍝H        ∘ $$ and Dyadic $ used together may be useful:
  ⍝H             { $$ "F8.2" $ MyCode}    ⍝ $ Formats MyCode then $$ puts in a box.
  ⍝H        ∘ % (OVER) is a special symbol for placing one ⎕FMT-able object "over" another, each centered/padded.
  ⍝H          - Each object is converted to a char. array (if not already), padding if necessary, 
  ⍝H            then the left (⍺) is catenated OVER the right (⍵).
  ⍝H          - The % (OVER) option is useful for titles or for building hierarchical displays without
  ⍝H            doing all the gluing yourself.
  ⍝H          - See the example(s) above.
  ⍝H        ∘ %% (CHAIN) is a special symbol for placing one ⎕FMT-able object to the left of another.
  ⍝H          The objects are not centered, but simply catenated (CHAINed) together.
  ⍝H          CHAIN is also used to build the ∆F formatted object from all the fields (see MODE=¯1). 
  ⍝H        ∘ A Code Field may include limited comments (even though on a single line), 
  ⍝H          beginning with a '⍝' and terminated just before the next '⋄' or '}' on the same line.
  ⍝H          Braces {} (escaped or not), statement ends (⋄) and (double) quotes are 
  ⍝H          not allowed in Code Field comments.
  ⍝H     Self-Documenting Code Fields
  ⍝H       a. HORIZONTAL →
  ⍝H       {ccc →} A Self-documenting Horizontal Code Field
  ⍝H          A Code Field with a trailing right arrow (→) will generate two fields:
  ⍝H          ∘ the code itself in literal form (incl. spaces and [limited] comments), 
  ⍝H            followed by its evaluated value:
  ⍝H              ∆F'A: {⍪⍳⍵1 → },  B: {⍪⍵2+⍳⍵1 → }' 2 3
  ⍝H            A: ⍪⍳⍵1 → 0,  B: ⍪⍵2+⍳⍵1 → 3
  ⍝H                      1                4
  ⍝H       b. VERTICAL ↓ (EXPERIMENTAL OPTION)
  ⍝H       {ccc ↑} A Self-documenting Vertical Code Field
  ⍝H          A Code Field with a trailing down arrow (↓) will generate a field with…
  ⍝H          ∘ the code itself in literal form (incl. spaces and [limited] comments), 
  ⍝H            OVER its evaluated value (as if the %% shortcut was used):
  ⍝H               Name←↑'John' 'Mary'
  ⍝H               Age← ⍪ 34     27
  ⍝H               ∆F'{Name↓} {Age↓}'
  ⍝H            Name↓ Age↓
  ⍝H            John   34 
  ⍝H            Mary   27 
  ⍝H        ∘ Extra blanks and comments are allowed within a Self-documenting Code Field and
  ⍝H          will appear in the output.
  ⍝H …           ∆F'⎕IO={⎕IO}. {⍪⍳⍵1 → ⍝ SIMPLE }  {⍪⍵2+⍳⍵1 → ⍝ FANCY }' 2 3
  ⍝H          ⎕IO=0. ⍪⍳⍵1 → ⍝ SIMPLE 0  ⍪⍵2+⍳⍵1 → ⍝ FANCY 3
  ⍝H                                 1                    4
  ⍝H
  ⍝H A2. Space Fields: 
  ⍝H     {  }  OR { :10: } OR { :⍹9: }
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H    Space fields look like Code Fields, except they contain  
  ⍝H         ∘ only 0 or more spaces, or
  ⍝H         ∘ :nn:, i.e. a colon, 0 or more digits, followed by a colon
  ⍝H         ∘ :⍹[N]: or :⍵[N_]:, i.e. a colon, ⍹ or ⍵, followed by digits/underscore, followed by a colon.
  ⍝H    or all together:
  ⍝H         ∘ { [sss] | :[nn]: | :[⍹⍵][N_]: } 
  ⍝H     sss      0 or more spaces               inserts spaces indicated
  ⍝H     nn       zero or more digits            inserts nn spaces. 
  ⍝H     ⍹N etc.  A single special variable      inserts ⍹N at execution time.
  ⍝H              ⍹1, ⍹9, ⍹, ⍵_, ⍵1, ⍵9, etc.    
  ⍝H
  ⍝H     For Numeric or Special Variable Space Fields
  ⍝H     ∘ The colon prefix is required;  the colon suffix is optional.
  ⍝H     ∘ An ill-formed Space Field will be treated as a Code Field, likely triggering an error.
  ⍝H     ∘ Only one special variable is allowed here (i.e. ⍹5 or ⍹, but not ⍹4+⍹5, etc.).
  ⍝H       If you want to do a calculation, simply use a code field: {" "⍴⍨⍹4+⍹5}.
  ⍝H
  ⍝H     A 0-width Space Field {} is handy as a separator between multiline Text Fields (q.v.).
  ⍝H
  ⍝H A3. Text Fields:  
  ⍝H     ∆F 'Any\⋄multiline\⋄text{}Next field!' 
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H    Everything else is a Text Field. Variable names, etc., in text field are just text.
  ⍝H    ∘ Text fields may contain newlines entered as \⋄. Simple ⋄ is not special.
  ⍝H    ∘ To show literal \⋄, enter \\⋄.  
  ⍝H    ∘ To show { or } as text, enter \{ or \}. 
  ⍝H    ∘ In all other cases, simple \ is not special: +\ is simply +\, \d is simply \d.
  ⍝H    ∘ You can use {} to separate Text Fields.
  ⍝H      {} is a 0-width Space Field (see 2. Space Fields above).
  ⍝H      EXAMPLE: 
  ⍝H        Compare these two cases, the first with {} separating 2 multiline Text Fields:
  ⍝H …         ∆F 'One\⋄two{}-Three\⋄-four'  vs    ∆F 'One\⋄two-Three\⋄-four' 
  ⍝H        One-Three                           One
  ⍝H        two-four                            two-Three
  ⍝H                                            -four
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H Differences from Python
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H    ∆F APL-style                             Python
  ⍝H    ¨¨¨¨¨¨¨¨¨¨¨¨                             ¨¨¨¨¨¨    
  ⍝H    ⍝ Build fields all at once L to R        # Build annotations row by row
  ⍝H      RGB←  123 145 255                      R = 123 ; G = 145 ; B = 255
  ⍝H …    ∆F 'R:\⋄G:\⋄B:{ }{⍪RGB}'               print((f'R: {R}\nG: {G}\nB: {B}'))
  ⍝H    R: 123                                   R: 123
  ⍝H    G: 145                                   G: 145
  ⍝H    B: 255                                   B: 255
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨                            ¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H    ⍝ Use APL for base conversions         # Base conversions are built in
  ⍝H …    ∆F '"{"01"[2⊥⍣¯1⊢⍵1]}"' 7              f'{7:b}'
  ⍝H    "111"                                    '111'
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨                            ¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H    ⍝ Formatting Floats old-fashioned?     # Similar approach, different conventions
  ⍝H      x← 20.123                              x = 20.123
  ⍝H …    ∆F'{"F8.5"$x}' ⍝ User calcs width      print(f'{x:0<8}')   # User calcs width
  ⍝H    20.12300                                 20.12300
  ⍝H …    ∆F '{5⍕x}'     ⍝ APL calcs width       print(f'{x:.5f}')   # Python calcs width
  ⍝H    20.12300                                 20.12300
  ⍝H
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H B. ∆F Options:  ⍺[0] (default ⍺[0]=1)  MODE Option
  ⍝H                 ⍺[1] (default ⍺[1]=0)  BOX Option
  ⍝H                 ⍺=⍬                    ∆F FORMATTING SKIPPED
  ⍝H                 ⍺='help'               Show HELP information
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H B1. ∆F has three modes[*], determined by ⍺[0]= 1, 0, or ¯1.
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨       * Ignored if ⍺=⍬ or ⍺='help'
  ⍝H ⍺[0]  MODE Option
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H [1]   ∆F IMMEDIATE MODE
  ⍝H ⍺[0]=1     1 ∆F fs ⍵1 ⍵2 … ⍵N          ⍝ ⍺=1 is the default
  ⍝H     ∘ Executes the format string fs, implicitly passing any scalars ⍵1…⍵N to 
  ⍝H       the right as arguments.
  ⍝H     ∘ Note: Variables and settings seen are those of the CALLING environment 
  ⍝H       where ∆F is executed.
  ⍝H     ∘ Returns: a char matrix consisting of the fields built per the format and scalars passed.
  ⍝H
  ⍝H [0]   ∆F CODE GENERATION MODE
  ⍝H ⍺[0]=0     0 ∆F fs
  ⍝H     ∘ Generates a code string CS that can be executed (without repeatedly calling ∆F 
  ⍝H       to reparse fs) as 
  ⍝H         (⍎CS) ⍵1 ⍵2 … ⍵N   or     Dfn←⍎C                ⍝ (⍎CS) or Dfn is an executable dfn…
  ⍝H                                   Dfn ⍵1 ⍵2 … ⍵N
  ⍝H       where the args ⍵1…⍵n will be combined at EXECUTION time with fs as (fs,⍥⊆⍵1…⍵N), 
  ⍝H       where fs, the format string text originally passed to ∆F, is automatically 
  ⍝H       assigned to ⍹0, as expected.
  ⍝H     ∘ Note: Variable and fn names in Code Fields are resolved in the calling environment 
  ⍝H         when (⍎C) is executed; a different namespace "ns" may be specified via (ns⍎C), 
  ⍝H         a standard feature of execute (⍎).
  ⍝H     ∘ Returns: a char vector representing an executable dfn with results identical to 
  ⍝H         1 ∆F fs ⍹1 ⍹2 … ⍹N
  ⍝H
  ⍝H [¯1]  ∆F PSEUDOCODE MODE
  ⍝H ⍺[0]=¯1    ¯1 ∆F fs
  ⍝H     ∘ Generates a pseudo-executable P, which is identical to X, except
  ⍝H       - the internally used catenation function is abbreviated to the symbolic function name ⍙CHAIN,
  ⍝H       - newline escapes \⋄ are maintained as \⋄, suppressing
  ⍝H         multiline output, so the pseudocode can be easily inspected.
  ⍝H     ∘ Returns: a char vector of pseudocode.
  ⍝H
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H B2. ∆F has a BOX Option that puts each field into a display box
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H ⍺[1]  BOX Option
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H ⍺[1]=0 DEFAULT (NOBOX) Setting
  ⍝H     ∘ Output displayed normally, without extra boxing.
  ⍝H 
  ⍝H ⍺[1]=1 BOX Setting
  ⍝H     ∘ Output is displayed with each field shown within its own box, 
  ⍝H       whether a text, space, or code field.
  ⍝H     ∘ Any null fields generated (0-width) are suppressed, i.e. 
  ⍝H       not shown at all in the output.
  ⍝H     ∘ BOX mode is useful for verifying the expected output format
  ⍝H       is achieved for each input field. 
  ⍝H
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨ 
  ⍝H B3. Simple Options for ⍺
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H ⍺:   ∆F FORMATTING SUPPRESSED
  ⍝H ⍺≡⍬      ⍬ ∆F fs
  ⍝H      Immediately return a shy result of (1 0⍴' '), ignoring right argument.
  ⍝H      Useful when a format stmt ∆F is to be ignored (esp. useful in a Tradfn).
  ⍝H            VOLTAGE CURRENT FREQ← Initialize ⍬
  ⍝H            :FOR STEP :IN 1+⍳ITERATIONS  ⍝ ⎕IO=0
  ⍝H               VOLTAGE CURRENT FREQ← CalcNextStep VOLTAGE CURRENT FREQ 
  ⍝H             ⍝ Show results on STEP 100 200 etc.
  ⍝H …             (1/⍨0=100|STEP) ∆F '[{STEP}] Key Vars: {VOLTAGE→}V, {CURRENT→}A, {FREQ→}Hz.'
  ⍝H            :ENDFOR
  ⍝H         [100] Key Vars: VOLTAGE→240V, CURRENT→20A, FREQ→50Hz.
  ⍝H -----------------------------
  ⍝H ⍺:   Show HELP information
  ⍝H …        'help' ∆F ''  OR ∆F⍨'help'
  ⍝H      Show this HELP information in an ⎕ED editor session, then return ''.
  ⍝H 
  ⍝H PERFORMANCE
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨
  ⍝H As a prototype, ∆F is relatively slow compared to building formatted objects "by hand"
  ⍝H but serviceable enough. Where important, e.g. in loops, you may wish to
  ⍝H scan (compile) the format string before the loop and then run the resulting dfn (here: Fmt1):
  ⍝H
  ⍝H EXAMPLE OF CODE GEN MODE (0 ∆F …)
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H      ⍝ In a TRADFN                      ⍝ In a DFN
  ⍝H …      Fmt1← ⍎0 ∆F '{…}…{}…{}'            Fmt1← ⍎0 ∆F '{…}…{}…{}' 
  ⍝H        :FOR i :IN ⍳Whatever               _←{ 0=⍵: _←⍺
  ⍝H             … do stuff …                    … do stuff …
  ⍝H             Fmt1 arg1 arg2 …                ⎕←Fmt1 arg1 arg2 ⋄ ⍺ ∇ ⍵-1
  ⍝H        :ENDFOR                            }⍨ Whatever
  ⍝H
  ⍝H Tentative Relative ∆F Timings* of Immediate Mode vs Code Gen (Compiled) Mode
  ⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
  ⍝H                                 COMPILE → CODE STR → DFN → RUN    Rel. Timings
  ⍝H      ∆F fmt ⍵1 ⍵2 …    100%    |<==========================>|    ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
  ⍝H CS←  0 ∆F fmt           85.7%  |<==============>|                ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
  ⍝H DFN← ⍎CS                 4.3%                   |<=>|            ⎕
  ⍝H DFN ⍵1 ⍵2 …             10.0%                       |<=====>|    ⎕⎕⎕
  ⍝H -----------
  ⍝H [*] Test had six fields, exhibiting a range of field types. 
  ⍝H     ∆F strings are typically small in size and number.
  ⍝H
}