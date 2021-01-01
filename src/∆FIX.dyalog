∆FIX←{
    ⍺←⊢
    0:: ⎕SIGNAL/⎕DMX.(EM EN)

    SpecialQuote←{⍺←0
        SQ DQ←'''"'                             
        DTB← {⍵↓⍨-+/∧\' '=⌽⍵} 
        UnDQ←{DQ2←2⍴DQ ⋄ s/⍨1+SQ=s←s/⍨~DQ2⍷s←1↓¯1↓⍵}     ⍝ <"abc"" isn't"> ==> <abc" isn''t>, w/o '...'.
        AddSQ←{⍺←0   ⍝ ⍺=1: return vec of strings;   ⍺=0: return single string w/ CR-separated lines
            ⋄ CR←⎕UCS 13 ⋄ CRcode←⊂SQ,',(⎕UCS 13),',SQ ⋄ SQSP←⊂SQ,' '
            '(',')',⍨⍺{ 
                ⍺: ∊SQ,¨SQSP,⍨¨ CR(≠⊆⊢)⊢⍵  ⋄ SQ,SQ,⍨∊CRcode@(CR∘=)⊢⍵
            }{⍵/⍨1+⍵=SQ}⍵
        }
      ⍝ 0      1=DQ    2∊Skip  3∊Skip      4=pHere
      ⍝ Matches 
      ⍝    [Double] "multi \n lines"  
      ⍝    [Triple] """multi \n lines"""   
      ⍝             If the starting """ ends a line or the ending """ begins one, an extra newline is NOT generated.
      ⍝    [Here]   :HERE var_name[,] <<end_token[:]\n multi \n lines end_token[:] 
      ⍝ We skip past (ie. match and re-emit) 
      ⍝    [Single]  'single line'  
      ⍝    [Comment] ⍝ rest of one line...    
      ⍝ Note: VAR_NAME has 1 or more chars in  [\w∆⍙_.#⎕] followed by an optional ','.
      ⍝ Note: \N is any char but newline, while . is any char here.   (?![\w∆⍙_]) means \b INCLUDING chars in APL names. 
        pTriple pDouble pSingle pComments←'"{3}\R?(.*?)\R?"{3}' '(?:"[^"]*")+' '(?:''[^'']*'')+' '⍝\N*$'
      ⍝ :HERE format:
      ⍝     :HERE var_name[,]  [[:CR | :STD]] << [:]end_token[:] 
      ⍝ which is terminated a token of the form:  [:]end_token[:]
      ⍝ e.g. I_am_done or :ENDHERE or MOVE_ON:   
      ⍝ Case is significant for var_name and end_token.
        pHere← '(?ix) ^  \h* :HERE \h+ ([\w∆⍙_.#⎕]+,?) \h* (:STD|:CR|) \h*'
        pHere,←'(?-i) << \h* ( :?[\w∆⍙_.#⎕]+:? ) \N* \R (.*?) \R \h* \3 (?![\w∆⍙_.#⎕])'
        iSkip iDQ iHere←(2 3) 1 4
        pTriple pDouble pSingle pComments pHere ⎕R{ 
            ⋄ F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
            ⋄ CASE←⍵.PatternNum∘∊
            CASE iHere:(F 1),'←',(F 4)AddSQ⍨':std'≡⎕C F 2    ⍝ 1: var_name; 4: end_token (with optional closing :)
            CASE iSkip:F 0 
            CASE iDQ:AddSQ UnDQ F 0
            AddSQ F 1                ⍝  """..."""
        }⍠('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)⊣DTB¨ ⊆⍵
    }

    ⍺ (⊃⎕RSI).⎕FIX SpecialQuote {
        DelPfx←'file://'∘{⍵↓⍨⍺≡⍵↑⍨≢⍺}
        1≥|≡⍵: ⊃⎕NGET (DelPfx ⍵) 1 ⋄ ⍵
    }⍵
}
