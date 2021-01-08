∆FIX←{⎕IO ⎕ML←0 1
 
  0::  ⎕SIGNAL ⊂⎕DMX.(('EN' EN) ('EM' EM)('Message' Message)('OSError' OSError)) 
  ⍝ Following ⎕FIX syntax, a single vector is the spec for a file whose lines are to be read.
    LoadLines←'file://'∘{1<|≡⍵: ⍵ ⋄ ⍺≡⍵↑⍨n←≢⍺: ⊃⎕NGET(n↓⍵)1 ⋄ ⎕FIX '∘err'}
  ⍝ Scan4Special: Search through a set of lines (@VS) for: 
  ⍝     double-quoted ("..."), triple-quoted("""..."""), and  ::: here-strings.
  ⍝ Return APL single-quoted equivalents, converted via _Flatten above.
    Scan4Special←{⍺←0
        SQ DQ←'''"' ⋄ CR←⎕UCS 13 ⋄ CRcode←SQ,',(⎕UCS 13),',SQ
        ⍝ See Documentation for details...
        _Flatten←{
            ⍺←0 ⋄ fType fIndent←⍺ ⍺⍺
            VV←             {2=|≡⍵:⍵ ⋄ CR(≠⊆⊢)⊢⍵}
          ⍝ If fIndent<0, determine indent trim based on left-most line in ⍵. If >0, base on fIndent.
            TrimL← fIndent∘ { 0=⍺: ⍵ ⋄ 0=≢⍵: ⍵ ⋄ lb←+/∧\[1]' '=↑⍵ ⋄ ⍺<0: ⍵↓⍨¨lb⌊⌊/lb ⋄ ⍵↓⍨¨lb⌊⍺}
            EnQ←            {⍵/⍨1+⍵=SQ}¨ 
            QFlat← fType∘   {⍺>0:∊SQ,¨⍵,¨⊂SQ,' ' ⋄ ⍺=¯1: SQ,SQ,⍨1↓∊' ',¨⍵ ⋄ SQ,SQ,⍨∊{⍺,CRcode,⍵}/⍵}
            '(',')',⍨ ('↑'/⍨fType=2),QFlat EnQ TrimL VV ⍵
        }
        DTB←{⍵↓⍨-+/∧\' '=⌽⍵}
        UnDQ←{DQ2←2⍴DQ ⋄ s/⍨1+SQ=s←s/⍨~DQ2⍷s←1↓¯1↓⍵}     ⍝ <"abc"" isn't"> ==> <abc" isn''t>, w/o '...'.
        pTriple pDouble pSingle pComments←'"""\h*\R(.*?)\R(\h*)"""' '(?:"[^"]*")+' '(?:''[^'']*'')+' '⍝\N*$'
      ⍝                        1=end_token         2=opts    3=doc  4=indent :\1                     user code...
        pHere←'(?ix) :{3} \h*  ( [\w∆⍙_.#⎕]+ \:? ) (\N*) \R (.*?) \R (\h*) :? \1 (?![\w∆⍙_.#⎕] ) :?'
        iTrpQ iDblQ iSkip iHere←0 1 (2 3) 4
      ⍝  0 Triple 1 Double  2 Skip  3 Skip      4 Here
          pTriple  pDouble  pSingle pComments    pHere ⎕R{  
            ⋄ F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
            ⋄ CASE←⍵.PatternNum∘∊
            CASE iTrpQ: ((≢F 2) _Flatten) F 1   ⍝ Triple - w/ :TRIM
            CASE iDblQ:   0 _Flatten UnDQ F 0       ⍝ Double - no :TRIM
            CASE iSkip:                  F 0       ⍝ SKIP: Protect (skip) SQ and comment (⍝) sequences
          ⍝ CASE iHere:  F 2: options :m[atrix], :v[ectors], :cr (string w/ CRs); F 4: spaces preceding end_token
            type←⊃⌽0,1 2 ¯1/⍨1∊¨':v' ':m' ':s'⍷¨⊂⎕C F 2  ⍝ type? :m → 2, :v → 1, :s → ¯1, else 0.
                  type( (≢F 4 ) _Flatten) F 3     
       }⍠('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)⊣DTB¨⊆⍵
    }
    ⍺←⊢
    ⍺(⊃⎕RSI).⎕FIX Scan4Special LoadLines ⍵
}
