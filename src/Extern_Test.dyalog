 r←{optl}Trad fred;ignore1;ignore2       ⍝ Test comment
        ⍝ :EXTERN Outside ⎕ML   ⍝ Ensure 'Outside' and '⎕ML' not local
 ⎕IO ⎕ML←0 1
 #.⎕DIV←0
 three←Outside optl
 glop←Inside fred
 ⎕SE.XXX←3
 ⎕TRAP←⍬
 I←Inside fred
 ;Trad                  ⍝ Localize with "out of place" declaration
 Trad←⍳
 :If I=1
     Trad 3
 :EndIf
 ;A                       ⍝ Explicitly localize since 'A' in ⎕NS won't be identified as local
 ⍝ :INTERN B                 ⍝ Ditto B-- using :INTERN
 'A'⎕NS ⍬ ⋄ 'B'⎕NS ⍬ ⋄ 'C'⎕NS ⍬
 A.B←⍳2 ⋄ B.B←⍳2 ⋄ C.Help←⍳5
    ⍝ Local: Tidy; ignore a, b, c, d
 ⍝ :Intern showme ted
 Tidy←{
     a
     showme∘←5
     c,d
 }

 :Intern fred_intern
 :Extern fred_intern
 :Extern alpha
    ⍝ C.(...) ensures names inside parens treated as non-local
 C.(notLocal1 notLocal2←0 1)
 (local3 local4)←10 20    ⍝ These are local!
 ⎕←optl
