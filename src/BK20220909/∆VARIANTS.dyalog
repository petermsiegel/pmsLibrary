∇ RES←ALPHA ∆VARIANTS OMEGA
⍝ See documentation at bottom...
  ;err;normalize;parmList;principal;scanArgs;scanParms;setVars
  ;DEBUG;EM;EN;MISSING;NS;opts;SYS;TRAP_ERRS
  ;⎕IO;⎕ML;⎕TRAP
 
  err←{EN⊢←⊃⌽⍵  ⋄ EM⊢←∊⎕FMT'∆VARIANT DOMAIN ERROR: ',⊃⍵ ⋄  RES⊢←NS EN EM  ⋄  EM ⎕SIGNAL EN }
⍝ normalize name-value pairs and depth.
⍝ When pair is defective (one member), it is padded on right (⍺⍺=1) or left (⍺⍺=0).
⍝ Simple scalars ('a' 5) or ('a' 'b') are treated as if (invalid or valid) names...
  normalize←{aa←⍺⍺ ⋄ ⍺∘{0 1∊⍨|≡⍵:⌽⍣aa⊣⍺ ⍵ ⋄ ⍵}¨⊂⍣(2≥|≡⍵)⊣⍵}
⍝ _ ← ⍺:0 setVar ⍵
⍝ ⍵ of form  (name value)
⍝ If value is MISSING, then
⍝    If ⍺=1, then replace MISSING by ⎕NULL and 
⍝        Set the variable.
⍝    Otherwise, don't set variables with MISSING values.
⍝ Otherwise (⍺=0)
⍝    Set the variable.
  setVar←{
    ⍺←0  ⋄ assumeNull←⍺ ⋄ 
    nm←⊃⍵  ⋄ val←{⊃⍣(1=≢⍵)⊣⍵}∘(1∘↓)⍵ 
    val←val ⎕NULL ⊃⍨ assumeNull∧val≡MISSING 
    val≡MISSING: 0 ⋄ ⍎'NS.',nm,'←val'
  }
⍝ _scanPrinc:
⍝   If we have 1 active principal variant, return it, sans special symbols.
⍝   parms are updated (removing *) in fn <_scanAbbrev> below. 
  _scanPrinc←{missing parms←⍺ ⍵
      isPrinc←∊'*'=1↑¨nms←,∘⊃¨parms 
      active←isPrinc/nms    
      0=≢active: missing
      1=≢active: '*()'~⍨⊃active                 
      err('Principal variant is set more than once:',∊' ',¨active)901
  }
⍝ _scanAbbrev:  parms dict ← ∇ parms 
⍝   Find abbrevns ⍺1,⍺2... for (⍺ in parms) and construct a dict mapping ⍺1,⍺2,...→⍺
⍝   Minor tidying: Remove () and * from parm-names. 
⍝   Returns parms dict
  _scanAbbrev←{⍺←~1∊'('∘∊∘⊃¨parms←⍵    ⍝ ⍺=1: No abbrev found...
      ⍺: parms (↓⍉↑{⍵ ⍵}∘⊃¨parms)⊣(⊃¨parms)~←'*'   ⍝ Fastpath out
      dict←⍬ ⍬
      _←{                              ⍝ 1st iter    2nd iter
          cur←⍵~'*'   ⍝ Ignore *       ⍝ !!          !!
          min← (1⌈cur⍳'(')             ⍝ !! min←≢⍵   !!
          min{                         ⍝ !!          !!
              ⍺>≢⍵:⍬                   ⍝ !! fails    succeeds and exits
              abbr←⍺↑⍵                 ⍝ !! 
              (⊂abbr)∊⊃dict:err('An abbrev for ',⍵,' already in use "',abbr,'"')901
              dict,¨←⊂¨abbr ⍵          ⍝ !! Only (⍵ ⍵) added to dict
              (⍺+1)∇ ⍵                 ⍝ !! Now (⍺+1) larger than ≢⍵
          }cur~'()'        ⍝ Ignore ()
      }∘⊃¨parms
      (⊃¨parms)~←⊂'*()'   ⍝ Remove () for abbrev, and * from parm names
      parms dict 
  }
⍝ Scan parameters ⍺, function-defined parameter list of variants and (opt'l) principal variant
  scanParms←{
      parms←MISSING(1 normalize)⍵
      princ←MISSING _scanPrinc parms
   ⍝ options by convention start with ⎕
      opts←⊃¨parms/⍨~notOpt←'⎕'≠⊃∘⊃¨parms      
      TRAP_ERRS∨←opts∊⍨⊂'⎕TRAP'  ⍝ global: TRAP_ERRS
    ⍝ Scan for abbrev (if any); fast if none.
      parms dict←_scanAbbrev parms
    ⍝ If we have option ⎕NULL, then missing items have default value ⎕NULL (rather than none)  
    ⍝ Set variables whose names aren't options (⎕TRAP) and whose values aren't MISSING, 
    ⍝ unless ⎕NULL option is set (then MISSING→⎕NULL)
      _←(opts∊⍨⊂'⎕NULL')setVar¨notOpt/parms 
      parms princ dict
  }
⍝ Scan arguments ⍵, user-defined variant argument list name-value pairs
  scanArgs←{parms princ dict←⍺
      args←princ(0 normalize)⍵
      argNms←,∘⊃¨args
      0≠≢unk←argNms~⊃dict:err('User-specified variant(s) unknown:',∊' ',¨unk)911
      MISSING∊argNms:err'User specified a value for the principal variant, but none was predefined' 911
      (⊃¨args)←(⊃⌽dict)[argNms⍳⍨⊃dict]
      setVar¨args
  }
⍝ ----------------------
⍝ EXECUTIVE
⍝ ----------------------
  DEBUG←1
  RES←MISSING←NS←⎕NS''
  (EM EN) TRAP_ERRS ⎕IO ⎕ML←('' 0) 0 0 1
  ⎕TRAP←(~DEBUG)/(911 'C' '→DO_SIGNAL 0⊃⍨TRAP_ERRS') (0 'C' '→DO_SIGNAL')
  (scanParms ALPHA) scanArgs OMEGA
  RES←TRAP_ERRS⊃RES(NS EN EM)
  :RETURN
DO_SIGNAL:
   ⎕DMX.EM ⎕SIGNAL ⎕DMX.EN
∇

∇ ∆VAR_DEMO trapMode;cmd;_
   ⋄ cmd←'BOX',3↓⎕SE.UCMD'BOX ON -fns=on'
  'trapMode is ',trapMode⊃'OFF' 'ON'
  'options:'
      ⎕←options←(trapMode/⊂'⎕TRAP'),('*IC' 0)('Mode' 'L')('Dot(All)' 0)('EOL' 'CRLF')('NEOL' 0)('ML' 0)('Greedy' 1)('OM' 0)
      ⎕←options,←('UCP' 0)('InEnc' 'UTF8')('OutEnc' 'Implied')('Enc' 'Implied')('_Augmented')
  'args:'
     ⎕←args←1('Mode' 'M')('EOL' 'LF')('UCP' 1)('_Augmented'('YES' 'NO'⊃⍨?2))
     _←⎕SE.UCMD cmd
  'Calling: ns en em←options ∆VARIANTS args'
      ns en em←options ∆VARIANTS args
  18⍴'-' ⋄ '   ns (namespace)'⋄ 18⍴'-'
  (⎕JSON⍠'Compact' 0)ns
∇

 ⍝   ∆VARIANTS:
 ⍝   "Process variants like those for ⍠,
 ⍝    returning a namespace with values set by user or those with defaults."
 ⍝
 ⍝   returnVal← parmList ∇  argList
 ⍝      0          1           2
 ⍝       1. parmList:   ([*]parameter [default]])([*]parameter [default])...
 ⍝          parameter: the name (string) of a variant.
 ⍝                     [*] See (1a) principal variant, below.
 ⍝              Abbreviations are supported using parentheses:
 ⍝                Long(Name) allows Long LongN longNa longNam longName
 ⍝                LongName   allows LongName only
 ⍝                Abbrev may be 1 char or more, but
 ⍝                  1-char abbrev should generally be ravelled, unless the variant value
 ⍝                  is non-scalar.
 ⍝                  For  ('Name' 'John')
 ⍝                  use  ('Na'   'John')
 ⍝                  or   ('N'    'John')
 ⍝                  but ((,'N')     'J') not ('N' 'J')
 ⍝                If two names have the same abbreviation(s), an error is flagged.
 ⍝          default:   if specified, any value. If omitted, no default.
 ⍝
 ⍝          1a. Principal variant
 ⍝              The (only) variant with a * prefix will be the principal variant. The * is otherwise ignored.
 ⍝          1b. Special parmList variant:
 ⍝              '⎕TRAP' (type and default are ignored if present)
 ⍝                    On success, ∆VARIANT returns  (NS 0 '')
 ⍝                    Action: Trap any argList (errNum=911) errors and return (NS errNum 'errMsg')
 ⍝                    Note:   parmList and principal errors still cause errors to be ⎕SIGNAL'd.
 ⍝       2. argList:  variant args passed by user, including default.
 ⍝       0. returnVal:
 ⍝          NS         Unless parameter '⎕TRAP' is specified.
 ⍝          NS errNum errMsg
 ⍝       where...     
 ⍝          NS: a namespace with names of all parameters either found in argList or having default values from parmList.
 ⍝              Those names not found in argList will be undefined, if they have no defaults.
 ⍝              To ensure every name is defined, simply specify a default.
 ⍝          errNum:   911 (integer), error with variant argument.
 ⍝          errMsg:   A description of the error (string).
 ⍝
 ⍝  NS← parmList ∆VARIANTS ⍵
 ⍝
 ⍝ Error numbers (901: parameter-related; 911: argument-related)
 ⍝      901:   User passed an unknown variant
 ⍝             The type specified for the variant parameter is invalid
 ⍝             Default value for variant of the wrong type
 ⍝             Principal variant is unknown
 ⍝      911:   The type specified for the variant argument is invalid
 ⍝             User passed principal variant arg, but none was defined
 ⍝             User value for variant of the wrong type
 ⍝
 ⍝ Example: Like ⎕R/⎕S
 ⍝ Note: We allow more options than the Dyalog documention, which specifies:
 ⍝    For the operand function with right argument Y and optional left argument X,
 ⍝    the right operand B specifies the values of one or more options that are applicable
 ⍝    to that function. B may be a scalar, a 2-element vector, or a vector of 2-element
 ⍝    vectors which specifies values for one or more options as follows:
 ⍝    ∘  If B is a 2-element vector and the first element is a character vector,
 ⍝       it specifies an option name in the first element and the option value
 ⍝       (which may be any suitable array) in the second element.
 ⍝    ∘  If B is a vector of 2-element vectors, each item of B is interpreted as above.
 ⍝    ∘  If B is a scalar (a rank-0 array of any depth), it specifies the value of the
 ⍝       Principal option.   [Dyalog APL Reference Guide, 195]
