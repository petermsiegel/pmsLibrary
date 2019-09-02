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
     ⎕IO ⎕ML←0 1
     ns←∆IGNORE←⎕NS ''
     okType←{ ⍝ Is the type in parmList for <⍺> consistent with value <⍵>
         p←(0⊃¨parmList)⍳⊂⍺
         p≥≢parmList:⎕SIGNAL/('∆VARIANT: User passed a variant "',⍺,'" we don''t know')901
         tp←1⊃p⊃parmList
   ⍝      ⎕←'Found obj '(p⊃parmList)
         ~tp∊'*BINCSR':⎕SIGNAL/('∆VARIANT: The type of the variant "',⍺,'" is unknown')902
         ∆IGNORE≡⍵:1                ⍝  Ignore: only for parameters...
         '*'=tp:2 9∊⍨⎕NC'⍵'
         'R'=tp:9=⎕NC'⍵'
         arg←{1=≢⍵:⍬⍴⍵ ⋄ ⍵}⍵
         'B'=tp:arg∊0 1
         ⋄ dr←80|⎕DR arg
         'I'=tp:3=dr
         'N'=tp:dr∊3 5 7
         dr≠0:0
         'C'=tp:1=≢arg
         'S'=tp:1
         ∘UNREACHABLE∘
     }

     ⍺←,⍬
     parmList←⊆¨⊃⍺
     principal hasPrincipal←{0=≢⍵:⍬ 0 ⋄ (⊃⍵)1}1↓⍺
     argList←⊆⍵
   Ensure every parm has a type. Default '*'

     parmList←ns{
         2=≢⍵:(0⊃⍵)(1⊃⍵)∆IGNORE
         1=≢⍵:(⊃⊆⍵)'*'∆IGNORE
         nm _ val←⍵
         ~nm okType val:⎕SIGNAL/('∆VARIANT: Default value for variant ',nm,' of the wrong type')903
         _←⍺{⍎'⍺.',nm,'←⍵'}val
         ⍵
     }¨parmList

     argList←{2=≢⍵:⍵ ⋄ principal ⍵}¨argList
     (0∊2=≢¨⍵)∧~hasPrincipal:⎕SIGNAL/'∆VARIANT: User passed principle variant, but none was predefined' 904
     _←ns{
         nm val←⍵
         ~nm okType val:⎕SIGNAL/('∆VARIANT: User value for variant "',nm,'" of the wrong type')905
         ⍺{⍎'⍺.',nm,'←⍵'}val
     }¨argList
     ns
 }
