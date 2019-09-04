 res←{alpha}∆VARIANT omega;EM;EN;NS;TRAP_ERRS

 ⍝
 ⍝   MONADIC ∆VARIANT:
 ⍝             Takes a complex object formed via:
 ⍝                fnV←{function}⍠opt1 opt2 ...,
 ⍝                strFnV←⎕NR ⎕OR 'fnV'
 ⍝             where optN is as defined for ⍠:
 ⍝                   (principal0)('name1' val1)('name2' val2)(principal3)...
 ⍝             and returns a simple argList defined for dyadic ∆VARIANT...
 ⍝             Handles: ONLY list of options (including a principle value).
 ⍝                      NOT YET: {function}⍠opt1⍠opt2...
 ⍝   argList ← ∆VARIANT ns⊣ns←⎕NR {function}⍠opt1 opt2 ...
 ⍝
 ⍝   DYADIC ∆VARIANT:
 ⍝             Process variants like those for ⍠,
 ⍝             returning a namespace with values set by user or those with defaults.
 ⍝
 ⍝   returnVal← parmList [principal | ⎕NULL] ∇  argList
 ⍝   0   1         2             3
 ⍝       1. parmList:   parameter [type [default]]
 ⍝                      list of all valid parameters (case Respected) in this form:
 ⍝          parameter: the name (string) of a variant.
 ⍝          type:      'B' a boolean: 1 or 0
 ⍝                     'I' an integer
 ⍝                     'N' a number (5.5 2J3 ¯1E¯22 etc)
 ⍝                     'C' a char ('X' or 'y')
 ⍝                     'S' a string ('X', 'YY', 'zzz', etc)
 ⍝                     'R' a namespace ref,  #,  ⎕SE (unquoted; not strings)
 ⍝                     '*' anything (default)
 ⍝          default:   if specified, any value. If omitted, no default.
 ⍝          1a. Special parmList variant:
 ⍝              '⎕TRAP' (type and default are ignored if present)
 ⍝                    On success, ∆VARIANT returns  (NS 0 '')
 ⍝                    Action: Trap any argList (errNum=911) errors and return (NS errNum 'errMsg')
 ⍝                    Note:   parmList and principal errors still cause errors to be ⎕SIGNAL'd.
 ⍝       2. principal: name of principal parameter or none, if omitted or ⎕NULL.
 ⍝                     Defines the principal parameter like those used with ⍠.
 ⍝                     Unlike ⍠, allows a principle to be of any type and shape...
 ⍝       3. argList:  variant args passed by user, including default.
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
 ⍝  Note: ∆VARIANT doesn't validate values beyond the right types
 ⍝
 ⍝  bool←'B' ⋄ int←'I' ⋄ num←'N' ⋄ char←'C' ⋄ str←'S' ⋄ ref←'R' ⋄ any←'*'
 ⍝
 ⍝  parmList←('IC' bool 0)('Mode' char 'L')('DotAll' bool 0)('EOL' str 'CRLF') ...
 ⍝  principal←'IC'
 ⍝  NS← parmList principal ∆VARIANT ⍵
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


 processVariants←{
     NS∘←⎕NS''
     err←NS∘{EM∘←∊⎕FMT'∆VARIANT DOMAIN ERROR: ',⊃⍵ ⋄ EN∘←⊃⌽⍵ ⋄ EM ⎕SIGNAL EN}

   ⍝ Is the type in parmList for <⍺> consistent with value <⍵>
     typeCheck←{
         p←(0⊃∘,¨parmList)⍳⊂⍺
         p≥≢parmList:err('User passed an unknown variant "',⍺,'"')901
         tp←1⊃p⊃parmList ⋄ nm←⍕⍺
         ~tp∊'*BINCSR':err('The type "',tp,'" specified for the variant ',vt,' "',nm,'" is invalid')(⍺⍺⊃901 911)⊣vt←⍺⍺⊃'parameter' 'argument'
         ∆IGNORE≡⍵:1                ⍝  Ignore: only possible for parameters...
         '*'=tp:2 9∊⍨⎕NC'⍵' ⋄ 'R'=tp:9=⎕NC'⍵'
         arg←{1=≢⍵:⍬⍴⍵ ⋄ ⍵}⍵ ⋄ 'B'=tp:arg∊0 1
         dr←80|⎕DR arg ⋄ 'I'=tp:3=dr ⋄ 'N'=tp:dr∊3 5 7
         dr≠0:0 ⋄ 'C'=tp:1=≢arg ⋄ 'S'=tp:1
         ∘UNREACHABLE∘
     }
   ⍝ Scan ⍺, function-defined parameter list of variants and (opt'l) principal variant
     scanParms←{
       ⍝ -- Special parameters (may not be arguments)
         '⎕TRAP'≡⊃⍵:⍵⊣TRAP_ERRS∘←1
         2=≢⍵:(0⊃⍵)(1⊃⍵)∆IGNORE
         1=≢⍵:(⊃⊆⍵)'*'∆IGNORE
         nm _ val←⍵
         ~nm(0 typeCheck)val:err('Default value for variant "',nm,'" of the wrong type')901
         _←NS{⍎'⍺.',nm,'←⍵'}val
         ⍵
     }¨
     scanPrincipal←{
         nm←⊃⍵ ⋄ 0=≢nm:⎕NULL 0 ⋄ ⎕NULL≡nm:⎕NULL 0
         (≢parmList)≤(⊃¨parmList)⍳⊂nm:err('Principal variant "',nm,'" is unknown')901
         nm 1
     }
     normalize←{⍺←⎕NULL                   ⍝ ⎕NULL if none
         ⍺∘{0 1∊⍨|≡⍵:⍺ ⍵ ⋄ ⍵}¨⊂⍣(2≥|≡⍵)⊣⍵
     }
   ⍝ Scan ⍵, user-defined variant argument list name-value pairs
     scanArgs←{
         nm val←⍵
         nm≡⎕NULL:err'User passed principal variant, but none was predefined' 911
         ~nm(1 typeCheck)val:err('User value for variant "',nm,'" of the wrong type')911
         NS{⍎'⍺.',nm,'←⍵'}val
     }¨
   ⍝ ----------------------
   ⍝ EXECUTIVE
   ⍝ ----------------------
     ⎕IO ⎕ML←0 1
   ⍝ namespace <NS> also flags parameters with no default value
     ∆IGNORE←NS
     ⍺←,⍬
     parmList principal←{4=|≡⍵:(,⊆¨⊃⍵)(1↓⍵) ⋄ (,⊆¨⍵)⎕NULL}⍺
   ⍝ Get the formal parameter list
     parmList←scanParms parmList
   ⍝ Validate the principal (if any)
     principal hasPrincipal←scanPrincipal principal
   ⍝ Scan the user args...
       ⍝ here...
     _←scanArgs principal normalize ⍵
       ⍝ For namespace <NS> returned, variants with no defaults that are not set are undefined.
       ⍝ If TRAP_ERRS, return NS, errnum (default 0), errmsg (default '')
     TRAP_ERRS:NS 0 ''
       ⍝ Otherwise, simply return the namespace <NS>
     NS
 }

 :If 900⌶0  ⍝ Process ⎕NR ⎕OR 'fn' where fn←{...}⍠[principal1](name1 val1)(name2 val2)...[principal2]
     res←⎕NR omega
     :If 3=≢res ⋄ :AndIf '⍠'≡1⊃res
         res←2⊃res
     :Else
         11 ⎕SIGNAL'∆VARIANT (1adic): Right argument must be ⎕OR of fn call of form: fn⍠opt1 opt2 ... optN'
     :EndIf
 :Else
     TRAP_ERRS←0        ⍝ If 1, return  (NS errnum errmsg)
     :Trap 911
         res←alpha processVariants omega
     :Else
         EM ⎕SIGNAL EN/⍨~TRAP_ERRS
         res←NS EN EM
     :EndTrap
 :EndIf
