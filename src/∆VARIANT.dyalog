 ∆VARIANT←{
   ⍝ See documentation at bottom
     911::NS EN EM⊣EM ⎕SIGNAL EN/⍨1≠TRAP_ERRS⊣⎕←'NS EN EM TRAP_ERRS'
     NS EN EM TRAP_ERRS←(⎕NS'')0 '' 0

   ⍝ EXTERNAL:  NS EN EM TRAP_ERRS
     err←⎕SIGNAL/{(EM∘←∊⎕FMT'∆VARIANT DOMAIN ERROR: ',⊃⍵)(EN∘←⊃⌽⍵)}
     find←{(≢⍺)>(⊃¨⍺)⍳⊂⍵}
   ⍝ Scan ⍺, function-defined parameter list of variants and (opt'l) principal variant
     scanParms←{
         princ←⎕NULL
         getPrinc←{
             '*'≠1↑⍵:⍵
             princ≡⎕NULL:⊢princ∘←1↓⍵
             err'Principal parameter set multiple times.' 901
         }
         parms←{
       ⍝ -- Special parameters (may not be arguments)
             '⎕TRAP'≡⊃⍵:⍬⊣TRAP_ERRS∘←1
             1=≢⍵:(getPrinc⊃⊆⍵)∆NO_VALUE
             2≠≢⍵:err'Parameter definitions must be of form: name [value]' 901
             nm val←⍵ ⋄ nm←getPrinc nm
             _←NS{⍎'⍺.',nm,'←⍵'}val
             nm val
         }¨⍵
         parms princ
     }
   ⍝ Scan ⍵, user-defined variant argument list name-value pairs
     normalize←{⍺←⎕NULL
         ⍺∘{0 1∊⍨|≡⍵:⍺ ⍵ ⋄ ⍵}¨⊂⍣(2≥|≡⍵)⊣⍵
     }
     scanArgs←{
         nm val←⍵
         nm≡⎕NULL:err'User passed principal variant, but none was predefined' 911
         ~parmList find nm:err('User-specified variant "',nm,'" is unknown')911
         NS{⍎'⍺.',nm,'←⍵'}val
     }¨
   ⍝ ----------------------
   ⍝ SUB-EXECUTIVE
   ⍝ ----------------------
     ⎕IO ⎕ML←0 1
   ⍝ namespace <NS> also flags parameters with no default value
     ∆NO_VALUE←NS
     ⍺←,⍬
   ⍝ Get the formal parameter list and principal (or ⎕NULL, if none)
     parmList principal←scanParms,⊆¨⍺
   ⍝ Scan the user args
     _←scanArgs principal normalize ⍵
     TRAP_ERRS:NS EN EM
     NS

 ⍝   ∆VARIANT:
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
 ⍝          errNum:   911 (integer), error with variant argument.
 ⍝          errMsg:   A description of the error (string).
 ⍝
 ⍝  NS← parmList ∆VARIANT ⍵
 ⍝
 ⍝ Error numbers (901: parameter-related; 911: argument-related)
 ⍝      901:   User passed an unknown variant
 ⍝             The type specified for the variant parameter is invalid
 ⍝             Default value for variant of the wrong type
 ⍝             Principal variant is unknown
 ⍝      911:   The type specified for the variant argument is invalid
 ⍝             User passed principal variant arg, but none was defined
 ⍝             User value for variant of the wrong type

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
 }
