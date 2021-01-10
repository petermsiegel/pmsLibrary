∆FIX←{⎕IO ⎕ML←0 1 
  DEBUG←0
  0/⍨~DEBUG::  ⎕SIGNAL ⊂⎕DMX.(('EN' EN) ('EM' EM)('Message' Message)('OSError' OSError)) 

  ⍝ Following ⎕FIX syntax, a single vector is the spec for a file whose lines are to be read.
    LoadLines←'file://'∘{1<|≡⍵: ⍵ ⋄ ⍺≡⍵↑⍨n←≢⍺: ⊃⎕NGET(n↓⍵)1 ⋄ ⎕FIX '∘err'}
  ⍝ Scan4Special: Search through lines (vector of vectors) for: 
  ⍝     double-quoted ("..."), triple-quoted("""..."""), and  ::: here-strings.
  ⍝     Return executable APL single-quoted equivalents, encoded into various format via _Encode below.
    Scan4Special←{⍺←0
        SQ DQ←'''"' ⋄ CR←⎕UCS 13 ⋄ CRcode←SQ,',(⎕UCS 13),',SQ
      ⍝  ⍺ has ':c' CR for linends (def); ':v' vector of vectors; ':m' APL matrix, ':s' spaces replace linends 
      ⍝ indent: >0, use as is for indent of lines; <0, use indent of left-most line for indent; 0, as is.
        _Encode←{ ⍺←0 ⋄ indent←⍺⍺  
            C V M S←(⍳4)=1↑':c' ':v' ':m' ':s' ⎕S 3 ⍠1 ⍠'ML' 1⊣⎕C ⍺  ⍝ Accept 1st valid option. Default/Errors: C←1
            ⋄ S2VV←   { 2=|≡⍵:⍵ ⋄ CR(≠⊆⊢)⊢⍵}                         ⍝ Single str w/ CRs → vector of char vectors
            ⋄ TrimL←  { 0=⍺: ⍵ ⋄ 0=≢⍵: ⍵ ⋄ lb←+/∧\' '=↑⍵ ⋄ ⍺<0: ⍵↓⍨¨lb⌊⌊/lb ⋄ ⍵↓⍨¨lb⌊⍺}
            ⋄ DblSQ←  { ⍵/⍨1+⍵=SQ}¨  ⋄  AddPar← '('∘,∘⊢,∘')' ⋄  AddSQ←SQ∘,∘⊢,∘SQ 
            ⋄ ReForm← { V∨M: ∊ ' ',⍨∘AddSQ¨ ⍵ ⋄ S: AddSQ 1↓∊' ',¨⍵ ⋄ AddSQ ∊{⍺,CRcode,⍵}/⍵}
            AddPar (M/'↑'),ReForm DblSQ indent∘TrimL S2VV ⍵
        }
        DTB←{⍵↓⍨-+/∧\' '=⌽⍵}¨
        UnDQ←{DQ2←2⍴DQ ⋄ s/⍨1+SQ=s←s/⍨~DQ2⍷s←1↓¯1↓⍵}     ⍝ <"abc"" isn't"> ==> <abc" isn''t>, w/o '...'.
        pTriple pDouble pSingle pComments←'"""\h*\R(.*?)\R(\h*)"""' '(?:"[^"]*")+' '(?:''[^'']*'')+' '⍝\N*$'
      ⍝ pHere:                 1=end_token         2=opts   3=doc    4=indent :\1                     user code...
        pHere←'(?ix) :{3} \h*  ( [\w∆⍙_.#⎕]+ \:? ) (\N*) \R (.*?) \R (\h*) :?  \1 (?![\w∆⍙_.#⎕] ) :?'
        iTrpQ iDblQ iSkip iHere←0 1 (2 3) 4
      ⍝ 0 Triple  1 Double  2 Skip  3 Skip      4 Here
        pTriple  pDouble  pSingle pComments    pHere ⎕R{  
            ⋄ F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
            ⋄ CASE←⍵.PatternNum∘∊                  ⍝ type    TRIM?  Linend 
            CASE iTrpQ: ((≢F 2) _Encode) F 1       ⍝ Triple    Y      CR     ←  APL carriage return
            CASE iDblQ:   0 _Encode UnDQ F 0       ⍝ Double    N      CR  
            CASE iSkip:                  F 0       ⍝ Skip      N      N/A
          ⍝ CASE iHere:   ↓ ↓ ↓                    ⍝ Here-doc  Y   Via Opts   ← :c[r] :v[v]:m[x] :s[p]
                (F 2) ((≢F 4 ) _Encode)  F 3       ⍝    F 2: options, 3: body of here-doc, 4: spaces before end_token      
       }⍠('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)⊣DTB⊆⍵
    }  
    ⍺←⊢
    ⍺(⊃⎕RSI).⎕FIX Scan4Special LoadLines ⍵
}
