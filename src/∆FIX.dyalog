∆FIX←{⎕IO ⎕ML←0 1   
⍝ See ∆FIX.help for documentation.
  DEBUG←0
  0/⍨~DEBUG::  ⎕SIGNAL ⊂⎕DMX.(('EN' EN) ('EM' EM)('Message' Message)('OSError' OSError)) 

⍝ Following ⎕FIX syntax, a single vector is the spec for a file whose lines are to be read.
  LoadLines←'file://'∘{ 1<|≡⍵: ⍵
      ⍺≡⍵↑⍨n←≢⍺: ⊃⎕NGET(n↓⍵)1 ⋄ ⎕FIX '∘err'
  }
⍝ Scan4Special: Search through lines (vector of vectors) for: 
⍝     "double-quoted strings", triple-quoted ("""\n...\n"""), and  ::: here-strings.
⍝     Return executable APL single-quoted equivalents, encoded into various format via _Encode below.
  Scan4Special←{⍺←0
      SQ DQ←'''"' ⋄ CR←⎕UCS 13  
    ⍝ ⍺:  vector   ':c' CR for linends (def); ':l' LF for linends; ':s' spaces replace linends 
    ⍝     v of v   ':v' vector of vectors;    ':m' APL matrix 
    ⍝ indent: >0, use as is for indent of lines; <0, use indent of left-most line for indent; 0, as is.
      _Encode←{ ⍺←0 ⋄ indent←⍺⍺  
        ⍝ Accept 1st valid option. Default: C←1. Error if unknown first ':\w' sequence.
          C L S V M X←(⍳6)=1↑':c' ':l' ':s' ':v' ':m' ':\w' ⎕S 3 ⍠1 ⍠'ML' 1⊣⎕C ⍺  
          X: 11 ⎕SIGNAL⍨'∆FIX: Invalid option: "',⍺,'"'
          S2Vv←   { 2=|≡⍵:⍵ ⋄ CR(≠⊆⊢)⊢⍵}                        
          TrimL←  { 0=⍺: ⍵ ⋄ 0=≢⍵: ⍵ 
                    lb←+/∧\' '=↑⍵ 
                    ⍺<0: ⍵↓⍨¨lb⌊⌊/lb ⋄ ⍵↓⍨¨lb⌊⍺
          }
          DblSQ←  { ⍵/⍨1+⍵=SQ}¨    
          ReForm← { AddSQ←SQ∘,∘⊢,∘SQ 
                    V∨M: ∊ ' ',⍨∘AddSQ¨ ⍵ ⋄ S: AddSQ 1↓∊' ',¨⍵ 
                    AddSQ ∊{⍺,nlc,⍵}/⍵ ⊣ nlc←SQ,',(⎕UCS ',(⍕C⊃10 13 ),'),',SQ 
          }
          AddPar← '('∘,∘⊢,∘')' 
          AddPar (M/'↑'),ReForm DblSQ indent∘TrimL S2Vv ⍵
      }
      ∆DTB←{⍵↓⍨-+/∧\' '=⌽⍵}¨
      CutDQ←{s/⍨1+SQ=s←s/⍨~(2⍴DQ)⍷s←1↓¯1↓⍵}     ⍝ <"abc"" isn't"> ==> <abc" isn''t>, w/o '...'.
      pTriple ←  '"""\h*\R(.*?)\R(\h*)"""'  ⋄  pDouble ←  '(?:"[^"]*")+'
      pSingle ←  '(?:''[^'']*'')+'          ⋄  pComments← '⍝\N*$'
    ⍝ pHere:       :::     1=end_token             2=opts    3=doc    4=indent :  \1                 :  5=trailing...
      pHere←'(?ix) ::: \h* ( [\w∆⍙_.#⎕]+ \:? ) \h* (\N* ) \R (.*?) \R (\h*   ) :? \1 (?![\w∆⍙_.#⎕] ) :? (\N*)$'
      iTrpQ iDblQ iSkip iHere←0 1 (2 3) 4
    ⍝ 0 Triple 1 Double 2 Skip  3 Skip    4 Here
        pTriple  pDouble  pSingle pComments pHere ⎕R{  
          ⋄ F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
          ⋄ CASE←⍵.PatternNum∘∊                  ⍝ Format           Type    Trim?  Linend Type 
          CASE iTrpQ: ((≢F 2) _Encode) F 1       ⍝ """\r...\r"""    Triple    Y      CR     ←  APL carriage return
          CASE iDblQ:  0 _Encode CutDQ F 0       ⍝ "..\r.."         Double    N      CR  
          CASE iSkip:                  F 0       ⍝ '...' ⍝...       Skip      N      N/A
        ⍝ CASE iHere:   ↓ ↓ ↓                    ⍝ ::: ENDH...ENDH  Here-doc  Y   Via Opts   ← :c :l :v :m :s
            h←(F 2) ((≢F 4 ) _Encode)  F 3       ⍝    F 2: options, 3: body of here-doc, 4: spaces before end_token 
            h {0=≢⍵~' ':⍺ ⋄ ⍺, CR, ⍵}  F 5       ⍝ trailing text after closing end_token goes on its own line...  
      }⍠('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)⊣∆DTB⊆⍵
  }  
  ⍺←⊢
  ⍺(⊃⎕RSI).⎕FIX Scan4Special LoadLines ⍵
}
