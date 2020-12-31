  SpecialQuote←{⍺←0
      SQ DQ←'''"'  
      DTB← {⍵↓⍨-+/∧\' '=⌽⍵}¨                           ⍝ Delete trailing blanks from each line
      UnDQ←{DQ2←2⍴DQ ⋄ s/⍨1+SQ=s←s/⍨~DQ2⍷s←1↓¯1↓⍵}     ⍝ <"abc"" isn't"> ==> <abc" isn''t>, w/o '...'.
      AddSQ←{
          ⋄ CR←⎕UCS 13 ⋄ CRcode←⊂SQ,',(⎕UCS 13),',SQ
          str←∊CRcode@(CR∘=)⊢{⍵/⍨1+⍵=SQ}⍵
          '(',SQ,str,SQ,')'
      }

    ⍝ 0      1=DQ    2∊Skip  3∊Skip      4=pHere
      pTriple pDouble pSingle pComments←'"{3}(.*?)"{3}?' '((?:"[^"]*")+)' '((?:''[^'']*'')+)' '(⍝\N*$)'
      pHere←'(?x) ^\h* :(?i)HERE(?-i) \h+ ([\w∆⍙_]+,?) \h* << \h* ([\w∆⍙_]+) \N* \R (.*?) \R \h* \2 (?![\w∆⍙_])'
      iSkip iDQ iHere←(2 3) 1 4
      pTriple pDouble pSingle pComments pHere ⎕R{ 
          ⋄ F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
          ⋄ CASE←⍵.PatternNum∘∊
          CASE iHere:(F 1),'←',AddSQ F 3
          CASE iSkip:F 1 
          CASE iDQ:AddSQ UnDQ F 1
          AddSQ F 1
      }⍠('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)⊢DTB⊆ ⍵
  }
