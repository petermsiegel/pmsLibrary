 BibHeb←{
 BH←⎕NS ''
 BH.{
    Hdr∘←'' 'Qatal' 'Veqatal' 'Yiqtol' 'Vayyiqtol' 'Veyiqtol'
    HT∘← { ⎕←'' ⋄ (⊃Hdr)←20↑⍵ ⋄ Hdr }
    Count∘←⍬
    Count,←⊂'Past' 10830 484  774 14202  71
    Count,←⊂'Present' 2454 545 3376  308 195
    Count,←⊂'Future' 255 2932 5451   30 438
    Count,←⊂'Non-past Modal' 56 405 1200  12 285
    Count,←⊂'Past Modal' 115  63  423  18  51
    Count,←⊂'Imperative' 17 1647 2133   0  22
    Count,←⊂'Do [yiqtol]! Let''s' 38  70  789  35 239
    Count,←⊂'Non-verbal' 109 232  153   367  34
    Count∘←↑Count
    Total∘← 'Total' 13874 6378 14299 14972 1335
    TotalTrue← (⊂'Total (true)'),+/[0]1↓[1]Count
    Show∘← 'All Categories'∘{(HT ⍺),[0]Count,[0]Total}

    Data← 1 2 3 4 5
    
    Pct∘← Count
    Pct[; Data]←  ⌊0.5+100×Count[; Data]÷[1]Total[ Data]
    ShowPct∘← 'Pct All Categories'∘{ T←Total ⋄ (1↓T)← 100 ⋄ (HT ⍺),[0]Pct,[0] T}

    (1↓TotalTrue)≢1↓Total: 11 ⎕SIGNAL⍨'Count doesn''t add up to Total!'

    Time∘←⍬
    with←  { (⊂⍺),⍵}
    Time,←⊂'Past only' with  10830 484  774 14202  71  ⍝ +115  63  423  18  51
    Time,←⊂'Present'  2454 545 3376  308 195
    Time,←⊂'Fut only' with 255 2932 5451   30 438      ⍝ + 56 405 1200  12 285
      ⍝ Count,←⊂'Non-past Modal' 56 405 1200  12 285
      ⍝ Count,←⊂'Past Modal' 115  63  423  18  51
   ⍝ Time,←⊂'Imper+' with 17 1647 2133   0  22          ⍝ + 38  70  789  35 239  
     ⍝ Count,←⊂'Juss.-Cohort.' 38  70  789  35 239
   ⍝ Time,←⊂'Non-verbal' 109 232  153   367  34
    Time∘←↑Time
    TimeTotal∘← 'Total' with +/[0]1↓[1]Time 
    ShowTime∘← 'Temporal Only'∘{(HT ⍺),[0]Time,[0] TimeTotal}
    
    PctTime∘← Time
    PctTime[; Data]←  ⌊0.5+100×Time[; Data]÷[1]TimeTotal[ Data]
    ShowPctTime∘← 'Pct Temporal Only'∘{T←TimeTotal ⋄ (1↓T)← 100 ⋄ (HT ⍺),[0]PctTime,[0] T}
    
    ShowAll∘← {⎕←Show⍬ ⋄ ⎕←ShowPct⍬ ⋄ ⎕←ShowTime⍬ ⋄ ⎕←ShowPctTime⍬ ⋄ 1: _←''}

    ⎕THIS
 } ⍬
 }
