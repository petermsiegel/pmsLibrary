 ∆VARIANT←{
 ⍝   ns← parmList [principal] ∇  argList
 ⍝   0   1         2             3
 ⍝       1. parmList: list of all valid parameters (case Respected) in this form:
 ⍝                     parameter type [default]
 ⍝          parameter: a string (case R)
 ⍝          type:      'B' a boolean: 1 or 0
 ⍝                     'I' an integer
 ⍝                     'N' a number
 ⍝                     'C' a char ('X' or 'y')
 ⍝                     'S' a string ('X' or 'XX')
 ⍝                     'R' a namespace ref or # of ⎕SE (unquoted)
 ⍝                     '*' anything (default)
 ⍝          default:   if specified, any value. If omitted, no default.
 ⍝       2. principal: name of principal parameter or none, if omitted or ⎕NULL.
 ⍝       3. argList:  variant args passed by user, including default.
 ⍝       0. ns: a namespace with names of all parameters either found in argList or having default values.
 ⍝              Those names not found in argList will be undefined, if they have no defaults.
 ⍝              To ensure every name is defined, simply specify a default.
 ⍝
 ⍝  Note: ∆VARIANT doesn't validate values beyond the right types
 ⍝
 ⍝  bool←'B' ⋄ int←'I' ⋄ num←'N' ⋄ char←'C' ⋄ str←'S' ⋄ ref←'R' ⋄ any←'*'
 ⍝
 ⍝  parmList←('IC' bool 0)('Mode' char 'L')('DotAll' bool 0)('EOL' str 'CRLF') ...
 ⍝  principal←'IC'
 ⍝  ns← parmList principal ∆VARIANT ⍵
 ⍝
 ⍝ Error numbers (901: parameter-related; 911: argument-related)
 ⍝      901:   User passed an unknown variant
 ⍝             The type for the variant is invalid (parameter)
 ⍝             Default value for variant of the wrong type
 ⍝             Principal variant is unknown
 ⍝      911:   The type for the variant is invalid (argument)
 ⍝             User passed principle variant arg, but none was defined
 ⍝             User value for variant of the wrong type

     ⎕IO ⎕ML←0 1
   ⍝ namespace <ns> also flags parameters with no default value
     ns←∆IGNORE←⎕NS''

   ⍝ Is the type in parmList for <⍺> consistent with value <⍵>
     typeCheck←{
         p←(0⊃¨parmList)⍳⊂⍺
         p≥≢parmList:⎕SIGNAL/('∆VARIANT: User passed an unknown variant "',⍺,'"')901
         tp←1⊃p⊃parmList
         ~tp∊'*BINCSR':⎕SIGNAL/('∆VARIANT: The type "',tp,'" given for the variant "',(⍕⍺),'" is invalid')(⍺⍺⊃901 911)
         ∆IGNORE≡⍵:1                ⍝  Ignore: only possible for parameters...
         '*'=tp:2 9∊⍨⎕NC'⍵' ⋄ 'R'=tp:9=⎕NC'⍵'
         arg←{1=≢⍵:⍬⍴⍵ ⋄ ⍵}⍵ ⋄ 'B'=tp:arg∊0 1
         dr←80|⎕DR arg ⋄ 'I'=tp:3=dr ⋄ 'N'=tp:dr∊3 5 7
         dr≠0:0 ⋄ 'C'=tp:1=≢arg ⋄ 'S'=tp:1
         ∘UNREACHABLE∘
     }

   ⍝ Scan ⍺, function-defined parameter list of variants and (opt'l) principal variant
     ⍺←,⍬
     scanParms←{
         2=≢⍵:(0⊃⍵)(1⊃⍵)∆IGNORE
         1=≢⍵:(⊃⊆⍵)'*'∆IGNORE
         nm _ val←⍵
         ~nm(0 typeCheck)val:⎕SIGNAL/('∆VARIANT: Default value for variant "',nm,'" of the wrong type')901
         _←ns{⍎'⍺.',nm,'←⍵'}val
         ⍵
     }¨
   ⍝ !!!
     parmList←scanParms⊆¨⊃⍺

     scanPrincipal←{
         0=≢⍵:⍬ 0 ⋄ ⎕NULL≡nm←⊃⍵:⍬ 0
         (≢parmList)≤(⊃¨parmList)⍳⊂nm:⎕SIGNAL/('∆VARIANT: Principal variant "',nm,'" is unknown')901
         nm 1
     }
   ⍝ !!!
     principal hasPrincipal←scanPrincipal 1↓⍺

   ⍝ Scan ⍵, user-defined variant argument list name-value pairs
     scanArgs1←{
         3=|≡⍵:,⍵
         2=|≡⍵:,⊂⍵
         hasPrincipal:,⊂principal ⍵
         ⎕SIGNAL/'∆VARIANT: User passed principle variant, but none was predefined' 911
     }
     scanArgs2←{
         2=|≡⍵:⍵
         hasPrincipal:principal ⍵
         ⎕SIGNAL/'∆VARIANT: User passed principle variant arg, but none was predefined' 911
     }¨
     scanArgs3←{
         nm val←⍵
         ~nm(1 typeCheck)val:⎕SIGNAL/('∆VARIANT: User value for variant "',nm,'" of the wrong type')911
         ns{⍎'⍺.',nm,'←⍵'}val
     }¨
   ⍝ !!!
     _←scanArgs3 scanArgs2 scanArgs1 ⍵

   ⍝ Return populated namespace. Variants with no defaults that are not set are undefined.
     ns
 }
