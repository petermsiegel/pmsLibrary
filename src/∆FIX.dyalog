∆FIX←{⎕IO ⎕ML←0 1
  ⍝ ∆FIX: Extension to ⎕FIX that supports here-strings of 3 sorts:
  ⍝     Syntax: [Uses ⎕FIX syntax]
  ⍝     Triple Double Quotes    Double Quotes   :Here Directives with arbitrary end tokens.
  ⍝     abc←"""                 def←"line1      :Here ghi :VEC >>:ENDghi
  ⍝        lines...                  line2          lines...
  ⍝     """                          line3"     :ENDghi
  ⍝     :HERE var_name[,]    options  >>end_token  \n ... \n end_token
  ⍝           var_name: an APL var. name followed optionally by a comma (,) if adding to an existing var.
  ⍝           options:  [:VEC|:CR] [:NOTRIM|:TRIM]         defaults: :CR :TRIM
  ⍝           end_token: a string of the form of an APL var. name with an optional colon (:) prefix and/or suffix.
    0:: ⎕SIGNAL/⎕DMX.(EM EN)
    SQ DQ←'''"' ⋄ CR←⎕UCS 13
 
    Scan4Special←{⍺←0
    ⍝ Search through a set of lines (VS) for double-quoted ("..."), triple-quoted("""..."""), and :HERE strings.
    ⍝ Return APL single-quoted equivalents, converted via Flatten above.
      ⍝ Flatten:  lines2 ← useVV (useTrim ∇) lines
      Flatten←{
        ⍝ ⍺=1:  return vec of strings;   ⍺=0: (default) return single string w/ CR-separated lines
        ⍝ ⍺⍺=1: trim each line; else don't.
          ⍺←0 ⋄ useVV useTrim←⍺ ⍺⍺
          TrimL←{0=≢⍵:⍵ ⋄ ⍵↓⍨¨lb⌊⌊/lb←+/∧\[1]' '=↑⍵}
          lns←TrimL⍣useTrim⊣{2=|≡⍵:⍵ ⋄ CR(≠⊆⊢)⊢⍵}⍵
          CRcode←SQ,',(⎕UCS 13),',SQ
          '(',')',⍨useVV{⍺:∊SQ,¨⍵,¨⊂SQ,' ' ⋄ SQ,SQ,⍨∊{⍺,CRcode,⍵}/⍵}{⍵/⍨1+⍵=SQ}¨lns
      }
      DTB←{⍵↓⍨-+/∧\' '=⌽⍵}
      UnDQ←{DQ2←2⍴DQ ⋄ s/⍨1+SQ=s←s/⍨~DQ2⍷s←1↓¯1↓⍵}     ⍝ <"abc"" isn't"> ==> <abc" isn''t>, w/o '...'.
      pTriple pDouble pSingle pComments←'"{3}\R?(.*?)\R?"{3}' '(?:"[^"]*")+' '(?:''[^'']*'')+' '⍝\N*$'
      pHere←'(?ix) ^  \h* :HERE (?-i) \h+ ( [\w∆⍙_.#⎕]+ ,? )  ( [\w\h:]* ) '
      pHere,←'      << \h* ( \:? [\w∆⍙_.#⎕]+ \:? ) \N* \R (.*?) \R \h* \3 (?![\w∆⍙_.#⎕] )'
      iSkip iDQ iHere←(2 3)1 4
    ⍝ 0Triple 1Double 2Skip   3Skip     4Here
      pTriple pDouble pSingle pComments pHere ⎕R{
          ⋄ F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
          ⋄ CASE←⍵.PatternNum∘∊
      ⍝ iHere: F 1: VAR_NAME, F 2: options, F 3: END_TOKEN
          CASE iHere:(F 1){                    ⍝ Here-string - opt'l :TRIM
              v nt←1∊¨':vec' ':notrim'⍷¨⊂⍵
              ⍺,'←',v((~nt)Flatten)F 4   ⍝ Prepend a CR, if <VAR_NAME,>
          }⎕C F 2
          CASE iSkip:F 0
          CASE iDQ:(0 Flatten)UnDQ F 0        ⍝ Double - no :TRIM
          (1 Flatten)F 1                       ⍝ Triple - w/ :TRIM
      }⍠('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)⊣DTB¨⊆⍵
    }
⍝ Follow ing⎕FIX syntax, a single line must be a file reference.
  LoadLines←{DelPfx←'file://'∘{⍵↓⍨⍺≡⍵↑⍨≢⍺} ⋄ 1≥|≡⍵:⊃⎕NGET(DelPfx ⍵)1 ⋄ ⍵}

  ⍺←⊢
  ⍺(⊃⎕RSI).⎕FIX Scan4Special LoadLines ⍵
}
