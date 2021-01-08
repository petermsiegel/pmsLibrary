∆FIX←{⎕IO ⎕ML←0 1
  ⍝ ∆FIX:     Extension to ⎕FIX that supports special quoted strings/here-strings:
  ⍝              1] TQs:  Triple Quotes """...""", supporting a limited, multiline here-string. 
  ⍝                (Only double quotes (") are recognized).
  ⍝              2] DQs:  Double Quotes "...", like standard single-quote strings, over 1 or more lines.
  ⍝              3] HERE: Here-strings, using a triple colon syntax, and allowing several options.
  ⍝           Not all 3 options make sense, but they're provided to allow experimentation.
  ⍝ Syntax:   Uses ⎕FIX syntax, with enhancements:
  ⍝           Recognizes and converts source lines passed or in object named to standard APL...
  ⍝              1] TQs                   2]  DQs               3] Here-strings
  ⍝              ------------------       --------------         ----------------------
  ⍝ Specs:       s1← """\h*\n...\n\h*"""  s2← "l1\nl\nl3"       s3← ::: endToken [[:CR|:MX|:VV|:SP]] [.\n]* endToken
  ⍝              Opening and closing                            For <endToken> of form '[\w∆⍙_.#⎕]+:?', 
  ⍝              """ must appear on                                collects all lines up to (but not incl.) 
  ⍝              their own lines                                '\R?\h*:?\<endToken>:?'
  ⍝              Otherwise """x""" treated 
  ⍝              as equiv to '"x"'
  ⍝ Escaping?    Nothing escaped.         Double " to include.  Any text protected, as long as not matching endToken.
  ⍝              Internal """ invalid. 
  ⍝ Format:      s1← """                  s2← "Text on line 1   s3← ::: end_s3
  ⍝                line 1                   text on line 2...       text on line 1
  ⍝                line 2 ...               text on line 3"         more on line 2
  ⍝              """                                         end_s3: 
  ⍝ Must opening / closing quote or token be the last / first thing on separate line?
  ⍝              YES, BOTH                NO                    NO
  ⍝ Trim LHS?    YES                      NO                    YES
  ⍝ ...based on: spaces preceding         --                    spaces preceding endToken on same line. 
  ⍝              closing """
  ⍝ Options?     NONE                     NONE                  :CR (use CR as linend), :VV (use vector of vectors),
  ⍝                                                             :MX (create char matrix)            
  ⍝ Output:      APL quoted strings       APL quoted strings    APL quoted strings
  ⍝ Linesep:     (⎕UCS 13)                (⎕UCS 13)             [:CR]: (⎕UCS 13)
  ⍝ Other formats:                                              [:VV]: as APL Vector of Vectors
  ⍝                                                             [:MX]: as ↑(APL Vector of Vectors)
  ⍝                                                             [:SP]: with each CRsreplaced by a space.
  
  0::  ⎕SIGNAL ⊂⎕DMX.(('EN' EN) ('EM' EM)('Message' Message)('OSError' OSError)) 
  ⍝ Following ⎕FIX syntax, a single vector is the spec for a file whose lines are to be read.
    LoadLines←'file://'∘{1<|≡⍵: ⍵ ⋄ ⍺≡⍵↑⍨n←≢⍺: ⊃⎕NGET(n↓⍵)1 ⋄ ⎕FIX '∘err'}
  ⍝ Scan4Special: Search through a set of lines (@VS) for: 
  ⍝     double-quoted ("..."), triple-quoted("""..."""), and  ::: here-strings.
  ⍝ Return APL single-quoted equivalents, converted via Flatten above.
    Scan4Special←{⍺←0
        SQ DQ←'''"' ⋄ CR←⎕UCS 13 ⋄ CRcode←SQ,',(⎕UCS 13),',SQ
      ⍝ Flatten:  lines2 ← fVec (fTrim ∇) lines
      ⍝ fType:     ⍺= 1:  :v  return vec of strings (char vectors)
      ⍝            ⍺= 2:  :m  return matrix of strings  
      ⍝            ⍺=¯1: :s  return single string with spaces where linends would be.
      ⍝            ⍺= 0:  :cr (default) return single string w/ CR-separated lines
      ⍝ fIndent:   ⍺⍺=1:  trim each line based on least indented line;
      ⍝            ⍺⍺<0:  trim based on indent of closing line to iHere: '::: endToken [options] ... \r? (\h*) :?endToken:?
      ⍝                   or TQ closing quotes: (\h*)"""
      ⍝            ⍺⍺=0:  don't trim
        Flatten←{
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
            CASE iTrpQ: ((≢F 2) Flatten) F 1   ⍝ Triple - w/ :TRIM
            CASE iDblQ:   0 Flatten UnDQ F 0       ⍝ Double - no :TRIM
            CASE iSkip:                  F 0       ⍝ SKIP: Protect (skip) SQ and comment (⍝) sequences
          ⍝ CASE iHere:  F 2: options :m[atrix], :v[ectors], :cr (string w/ CRs); F 4: spaces preceding end_token
            type←⊃⌽0,1 2 ¯1/⍨1∊¨':v' ':m' ':s'⍷¨⊂⎕C F 2  ⍝ type? :m → 2, :v → 1, :s → ¯1, else 0.
                  type( (≢F 4 ) Flatten) F 3     
       }⍠('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)⊣DTB¨⊆⍵
    }
    ⍺←⊢
    ⍺(⊃⎕RSI).⎕FIX Scan4Special LoadLines ⍵
}
