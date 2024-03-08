 Note←{
      ⍝ ¨fuzzy_bool Note text¨
      ⍝ fuzzy_bool defaults to 1.
      ⍝ It is "true" unless 0=≢fuzzy_bool OR 0 is the first item in fuzzy_bool.
      ⍝ So, it's "true" if fuzzy_bool is 'abc' OR 1 'abc', but not '' or 0 'abc'
      ⍝ - Use in guard of dfn (to left of colon)
     ⍺←1 ⋄ 0=≢⍺:_←0 ⋄ ⍺≡⍥⊃0:_←0 ⋄ _←1⊣⎕←⍵
 }
