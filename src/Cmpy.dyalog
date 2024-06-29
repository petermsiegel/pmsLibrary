Cmpy←{   
⍝ Cmpy: Like cmpx but avoids some odd failures in May 2024     
⍝ lines← 〚srtF←0 〚lw← 80⌊⎕PW 〚qSec←1 〚prechk←1 〛〛〛〛 Cmpy code1 〚code2 〚code3…〛〛
⍝      ⍺:
⍝         srtF:   If  1, displays in ascending order by time.
⍝                 If ¯1, displays in descending order by time.
⍝                 If  0, displays in the order presented.
⍝         lw:     width of each line, including the plot space. Max: 80
⍝         qSec:   "quantum," total measurement time per code seq in wallclock sec
⍝         prechk: If 1 (default), validate each code segment once before timing.
⍝      ⍵:
⍝         codeN:  A string containing an executable sequence returning some value.
⍝  
⍝ Returns: the list of lines showing for each code string codeN:
⍝         code_text → total_time  │<relative_plot[*]>
⍝ as in: 
⍝         ⎕DL 0.1   → 1.0E¯1      │⎕⎕⎕⎕⎕⎕⎕ 
⍝ where ⎕⎕⎕⎕⎕⎕ is a graph of the relative time used: 
⍝ [*] Min plot width for longest time: <minPlotW> (see below), no matter the pagewidth.
⍝ -------------------
⍝ Example: 
⍝        ¯1 Cmpy  '⎕DL 1' '⎕DL 0.1' '⎕DL 0.5'
⍝ ⎕DL 1   → 1.0E0   │⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
⍝ ⎕DL 0.5 → 5.1E¯1  │⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕                             
⍝ ⎕DL 0.1 → 1.0E¯1  │⎕⎕⎕⎕⎕⎕⎕ 
⍝       

1000:: ⎕←'Cmpy: Interrupt!'
0::    ⎕SIGNAL ⊂'EM' 'EN' 'Message',⍥⊂¨⎕DMX.(EM EN Message)  

⍝ Benchmark each code fragment  
  ⍝ ⎕AI[1] CPU (compute) time for the APL session in milliseconds.
  ⍝ ⎕AI[2] wallclock (connect) time for the APL session in milliseconds

  ⍺← ⍬  
⍝ ============ PLOT RESULTS ============= 
  ⍺ {                                 
    ⍝ Preamble with ⎕IO ⎕ML shadowed...
      ⍝ minLnW:   min line width (plot, text, etc.)
      ⍝ minPlotW: min plot width (just the <symbol>s)  
        ⎕IO ⎕ML←0 1 ⋄ minLW minPlotW symbol← (⌊0.95×⎕PW) 25 '⎕'  
        srtF lw← 2↑ ⍺, 0 minLW↓⍨ 2⌊ ≢⍺ 
        ⍝ lw⌊← minLW 
  
      ⍝ CSort: Split ⍵ (2=≢⍵) into ⍺ ⍵; sort (⊃⍵)(⊃⌽⍵) each by ⊃⌽⍵  
        CSort← ⊃srtF{ 0≠⍺⍺: ⍺⍵ ⌷⍨¨ ⊂⊂ ⍋⍣ (⍺⍺=1) ⍒⍣ (⍺⍺=¯1)⊢ ⍵ ⋄ ⍺⍵ }/ 
    ⍝ Main... 
        cod tim← CSort ⍵ 
      ⍝ Ave, Min, Max
        Ave← +/÷≢ ⋄ Min← ⌊/ ⋄ Max← ⌈/
      ⍝ Bar: Eye candy for determining each "bar" 
      ⍝   bar← s Bar tim 
      ⍝   s: Vertical bar choice for each <tim> is based on closeness to ...
      ⍝      s=1:  the ave time;   s=¯1:  the min time;   s=0: just use '│'
        Bar← {  
          ⍝ s=selection, t=time, b=bar characters, e=epsilon
            s t b e← ⍺ ⍵ '│¦⋮:·' 1E¯18 
          0=s: '│'⍴⍨ ≢t                         ⍝ No eye candy? 
          ⍝ Bin: bin weighted times by abs. magnitude (log10);
          ⍝      weights by ave (s=1) or min (¯1) 
            ⋄ W← Ave⍣(s=1)(Min⍣(s=¯1))
            ⋄ B← { |nz\ 10⍟ |w/⍨ nz← 0≠ w← ⍙÷⍨ ⍵- ⍙← e⌈ W ⍵ }  
            b[ (⍳≢b)⍸ B t ]    
        }
        bar← ¯1 Bar tim   
      ⍝ Determine plot value for each timing, given max plot width (minPlotW⌈ lw -...)
        pv← ⌈(tim÷ ⌈/tim)× minPlotW⌈ lw - 13+ cw← ⌈/ ≢¨cod  
      ⍝ Some stats 
        f← 10 ¯3∘⍕
        stats← {('¯'⍴⍨¯2+≢⍵),⍨⍥⊂⍵} ∊'Min=' ' Ave=' ' Max=',∘f¨ (Min, Ave, Max) tim  
      ⍝ Format results nicely as 0 or more rows of a char matrix
      ⍝       code       →     timing           │⎕⎕⎕⎕⎕⎕
        FN← { (cw↑ ⍵⊃cod), ' →', (f ⍵⊃tim), (⍵⊃bar), symbol⍴⍨ ⍵⊃pv }
        ↑stats, FN¨ ⍳≢cod 
  } (2↓⍺){                                           
⍝ Return CPU time for each code segment (in ms), testing each for (0⊃⍺) sec. 
  ⍝ options <o> exclude first 2 original args.
  ⍝ q: timing quantum (max test time in wallclock sec.) 
  ⍝ p: precheck flag (if true, validate each code seg before timing) (bool)
    o← 1 1 ⋄ (q p)← 2↑⍺, o↓⍨ ≢⍺                 ⍝ o: options => q p 
    qMs← ⌈1000× q                               ⍝ q (sec) => qMs (ms)

  ⍝ C2D: Ensure ⎕IO and ⎕ML are in scope of caller's ⎕IO ⎕ML.
    T2Dfn← (⊃⎕RSI)⍎ {'{_←',⍵,'⋄ 0}'}            ⍝ T2Dfn: Convert code text to a concise dfn
    Prechk← { p=0: ⍵ ⋄ ⍵⊣ (T2Dfn ⍵) 0 } 
    T← qMs {                                    ⍝ <qMs> T:  Time each code segment    
        ⎕IO ⎕ML←0 1                             
        TF← T2Dfn ⍺                             ⍝ TF <code>: target code fn to execute                                       
      ⍝ _TL: Timing loop                        ⍝ <Dfn> _TL 0: 
      ⍝   we: wallclock (connect) expiration time
      ⍝   cs: CPU startup time
      ⍝    ⍺: # times through loop
        _TL← { ⎕AI[2]<we: (⍺+1)∇ ⍺⍺ 0 ⋄ ⍺÷⍨ ⎕AI[1]-cs }  
      ⍝ ------ Begin critical section ↓↓↓↓↓↓
        we cs← ⎕AI[2 1]+ ⍺⍺ 0                 
        0 TF _TL ⍵                              ⍝ Loop until connect time expires
      ⍝ ------ End   critical section ↑↑↑↑↑↑
    }
  ⍝ Benchmark:   ( null code )   (user code). Then convert result in ms to seconds 
    Bench← { ⍵ ,⍥⊂ 0.001× |( '0'  T  0 )-⍨ { ⍵  T  0 }¨ ⊆⍵ }

  ⍝ EXECUTIVE
  ⍝ Prechk: Before benchmarking, cond'lly check once that each code fragment will run ok
    Bench Prechk¨ ⍵
   },⊆⍵                                  
}