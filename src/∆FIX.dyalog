∆FIX←{⎕IO ⎕ML←0 1
  ⍝ ∆FIX:     Extension to ⎕FIX that supports here-strings of 3 sorts:
  ⍝ Syntax:   [Uses ⎕FIX syntax]
  ⍝ Enhancements: Recognizes and converts source lines passed or in object named to standard APL...
  ⍝        1] Triple             2] Simple        3] Here-string consisting of ::: terminated by end_token 
  ⍝        Double Quotes         Double Quotes    (APL name +  optl : prefix and/or suffix) on its own line
  ⍝        ------------------    --------------   ---------------------------------------------------------
  ⍝        abc←"""               def←"line1       a ← :::eNd_tok
  ⍝            lines...                 line2          lines...
  ⍝        """                        line3"      ·····eNd_tok:    ⍝ comment ok 
  ⍝ TRIM?  YES- leftmost indent  NO- as is        YES- # spaces before end_token (·····) determine trim.
  0::  ⎕SIGNAL ⊂⎕DMX.(('EN' EN) ('EM' EM)('Message' Message)('OSError' OSError))
  
  ⍝ Following ⎕FIX syntax, a single vector is the spec for a file whose lines are to be read.
    LoadLines←'file://'∘{1<|≡⍵: ⍵ ⋄ ⍺≡⍵↑⍨n←≢⍺: ⊃⎕NGET(n↓⍵)1 ⋄ ⎕FIX '∘err'}
  ⍝ Scan4Special: Search through a set of lines (@VS) for: 
  ⍝     double-quoted ("..."), triple-quoted("""..."""), and  ::: here-strings.
  ⍝ Return APL single-quoted equivalents, converted via Flatten above.
    Scan4Special←{⍺←0
        SQ DQ←'''"' ⋄ CR←⎕UCS 13 ⋄ CRcode←SQ,',(⎕UCS 13),',SQ
      ⍝ Flatten:  lines2 ← fVec (fTrim ∇) lines
      ⍝ fVec:   ⍺=1:  return vec of strings;   
      ⍝         ⍺=0:  (default) return single string w/ CR-separated lines
      ⍝ fTrim:  ⍺⍺=1: trim each line based on least indented line;
      ⍝         ⍺⍺<0: trim based on indent of closing line to :::
      ⍝         ⍺⍺=0: don't trim
        Flatten←{
            ⍺←0 ⋄ fVec fTrim←⍺ ⍺⍺
            VV←           {2=|≡⍵:⍵ ⋄ CR(≠⊆⊢)⊢⍵}
            TrimL← fTrim∘ { 0=⍺: ⍵ ⋄ 0=≢⍵: ⍵ ⋄ lb←+/∧\[1]' '=↑⍵ ⋄ ⍺>0: ⍵↓⍨¨lb⌊⌊/lb ⋄ ⍵↓⍨¨lb⌊-⍺}
            EnQ←          {⍵/⍨1+⍵=SQ}¨ 
            QFlat← fVec∘  {⍺:∊SQ,¨⍵,¨⊂SQ,' ' ⋄ SQ,SQ,⍨∊{⍺,CRcode,⍵}/⍵}
            '(',')',⍨ QFlat EnQ TrimL VV ⍵
        }
        DTB←{⍵↓⍨-+/∧\' '=⌽⍵}
        UnDQ←{DQ2←2⍴DQ ⋄ s/⍨1+SQ=s←s/⍨~DQ2⍷s←1↓¯1↓⍵}     ⍝ <"abc"" isn't"> ==> <abc" isn''t>, w/o '...'.
        pTriple pDouble pSingle pComments←'"{3}\R?(.*?)\R?"{3}' '(?:"[^"]*")+' '(?:''[^'']*'')+' '⍝\N*$'
        pHere←'(?ix) :{3} \h* ( [\w∆⍙_.#⎕]+ \:? ) \N* \R (.*?) \R (\h*) :? \1 (?![\w∆⍙_.#⎕] )\h*(?:⍝\N*)?$'
        iSkip iDQ iHere←(2 3)1 4
      ⍝ 0Triple 1Double 2Skip   3Skip     4Here
        pTriple pDouble pSingle pComments pHere ⎕R{
            ⋄ F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
            ⋄ CASE←⍵.PatternNum∘∊
          ⍝ iHere: F 1: VAR_NAME, F 2: options, F 3: END_TOKEN
            CASE iHere:  (endLM Flatten) F 2 ⊣ endLM←-≢F 3     ⍝ ::: Here-string   (endLM: -1×spaces before end_token)
            CASE iSkip: F 0                                    ⍝ Protect (skip) SQ and comment (⍝) sequences
            CASE iDQ: (0 Flatten)UnDQ F 0                      ⍝ Double - no :TRIM
            (1 Flatten)F 1                                     ⍝ Triple - w/ :TRIM
        }⍠('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)⊣DTB¨⊆⍵
    }
    ⍺←⊢
    ⍺(⊃⎕RSI).⎕FIX Scan4Special LoadLines ⍵
}
