∇ RES←ALPHA ∆VARIANTS OMEGA
  ;err;normalize;parmList;principal;scanArgs;scanParms;setVars
  ;DEBUG;MISSING;NS;SYS;TRAP_ERRS
  ;⎕IO;⎕ML

⍝ See documentation at bottom...

  err←{⎕SIGNAL/1↓RES⊢←NS(SYS.EM⊢←∊⎕FMT'∆VARIANT DOMAIN ERROR: ',⊃⍵)(SYS.EN⊢←⊃⌽⍵)}
⍝ normalize key-value pairs and depth.
⍝ When pair is defective (one member), it is padded on right (⍺⍺=1) or left (⍺⍺=0).
  normalize←{aa←⍺⍺ ⋄ ⍺∘{0 1∊⍨|≡⍵:⌽⍣aa⊣⍺ ⍵ ⋄ ⍵}¨⊂⍣(2≥|≡⍵)⊣⍵}
  setVars←{NS⍎(⊃⍵),'←⊃⌽⍵'}
⍝ Scan parameters ⍺, function-defined parameter list of variants and (opt'l) principal variant
  scanParms←{
      parms←MISSING(1 normalize)⍵
      ⋄ 0∊1 2∊⍨≢¨parms:err'Parameter definitions must be of form: name [value]' 901
      princ←nms/⍨isPrinc←∊'*'=1↑¨nms←,∘⊃¨⍵
      ⋄ 1<np←+/isPrinc:err('Principal variant is set more than once:',∊' ',¨princ)901
      princ←princ{1=np:1↓⊃⍺⊣(0⊃(⍸isPrinc)⊃parms)↓⍨←1 ⋄ ⍵}MISSING
      ⋄ notOpt←'⎕'≠⊃∘⊃¨parms
      ⋄ hasVal←MISSING≢∘⊃∘⌽¨parms  
      ⋄ SYS.OPTS←⊃¨parms/⍨~notOpt   ⍝ options by convention start with ⎕ 
      TRAP_ERRS∨←SYS.OPTS∊⍨⊂'⎕TRAP'
    ⍝ Set variables whose names aren't ⎕TRAP and whose values aren't MISSING.
      _←setVars¨parms/⍨notOpt∧hasVal
      SYS.(PARMS PRINC)←(⊃¨parms)(princ)
      parms princ
  }
⍝ Scan arguments ⍵, user-defined variant argument list name-value pairs
  scanArgs←{plist princ←⍺
      args←princ(0 normalize)⍵
      nms←⊃¨args
      0≠≢unk←nms~⊃¨plist:err('User-specified variant(s) unknown:',∊' ',¨unk)911
      MISSING∊nms:err'User specified a value for the principal variant, but none was predefined' 911
      SYS.ARGS←⊃¨args
      setVars¨args
  }

⍝ ----------------------
⍝ EXECUTIVE
⍝ ----------------------
  DEBUG←1
  RES←MISSING←NS←⎕NS''
  NS.__SYS←SYS←NS.⎕NS''
  SYS.(EM EN) TRAP_ERRS ⎕IO ⎕ML←('' 0) 0 0 1
  SYS.(ALPHA OMEGA)←ALPHA OMEGA
  :Trap DEBUG⊃0 999
      parmList principal←scanParms ALPHA
      parmList principal scanArgs OMEGA
      RES←TRAP_ERRS⊃RES(NS SYS.EN SYS.EM)
  :Case 911
      ⎕DMX.EM ⎕SIGNAL ⎕DMX.EN/⍨~TRAP_ERRS
  :Else
      ⎕DMX.EM ⎕SIGNAL ⎕DMX.EN
  :EndTrap
∇

∇ ∆VAR_DEMO trapMode;cmd;_
   ⋄ cmd←'BOX',3↓⎕SE.UCMD'BOX ON -fns=on'
  'trapMode is ',trapMode⊃'OFF' 'ON'
  'options:'
  options←⎕←(trapMode/⊂'⎕TRAP'),('*IC' 0)('Mode' 'L')('DotAll' 0)('EOL' 'CRLF')('NEOL' 0)('ML' 0)('Greedy' 1)('OM' 0)
  options,←⎕←('UCP' 0)('InEnc' 'UTF8')('OutEnc' 'Implied')('Enc' 'Implied')('_Augmented')
  'args:'
  args←⎕←1('Mode' 'M')('EOL' 'LF')('UCP' 1)('_Augmented'('YES' 'NO'⊃⍨?2))
   ⋄ _←⎕SE.UCMD cmd
  ⎕←'Calling: ns en em←options ∆VARIANTS args'
  ns en em←options ∆VARIANTS args
  30⍴'-' ⋄ 'Variants set' ⋄ 30⍴'¯'
  _←{0⍴⎕←ns.⍵,' = ',(⍕ns⍎⍵)}¨↓ns.⎕NL 2
  30⍴'-' ⋄ 'System variables (ns.__SYS)' ⋄ 30⍴'¯'
  _←{0⍴⎕←ns.__SYS.⍵,' = ',(⍕ns.__SYS⍎⍵)}¨↓ns.__SYS.⎕NL 2
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
 ⍝                     Otherwise
 ⍝          NS: a namespace with names of all parameters either found in argList or having default values from parmList.
 ⍝              Those names not found in argList will be undefined, if they have no defaults.
 ⍝              To ensure every name is defined, simply specify a default.
 ⍝              Also saves internal variables in NS.__SYS
 ⍝                   ALPHA- parameters in left arg    OMEGA- args in right arg
 ⍝                   PARMS- parameter names           ARGS-  argument names
 ⍝                   PRINC- principle parameter
 ⍝                   EN EM- errNum (0) and errMsg (''), if any.
 ⍝                   OPTS-  any options specified (e.g. ⎕TRAP)
 ⍝             
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
