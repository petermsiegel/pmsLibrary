Cmpy←{   
⍝ Cmpy: Like cmpx but avoids some odd failures in May 2024
⍝ lines← [srtF←0 [lw← (80⌊⎕PW)]] Cmpy code1 [code2  [code3...]] 
⍝         srtF:  If  1, displays in ascending order by time.
⍝                If ¯1, displays in descending order by time.
⍝                If  0, displays in the order presented.
⍝            lw: width of each line, including the plot space. Max: 80
⍝         codeN: A string containing an executable sequence returning some value.
⍝            lw: The line width to assume. 80 or ⎕PW, whichever is smaller.
⍝  
⍝ Returns: the list of lines showing for each code string codeN:
⍝         code_text → total_time  │<relative_plot[*]>
⍝ as in: 
⍝         ⎕DL 0.1   → 1.0E¯1      │⎕⎕⎕⎕⎕⎕⎕ 
⍝ where ⎕⎕⎕⎕⎕⎕ is a graph of the relative time used: 
⍝ [*] Min plot width for longest time: <minPW> (see below), no matter the pagewidth.
⍝ -------------------
⍝ Example: 
⍝        ¯1 Cmpy  '⎕DL 1' '⎕DL 0.1' '⎕DL 0.5'
⍝ ⎕DL 1   → 1.0E0   │⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
⍝ ⎕DL 0.5 → 5.1E¯1  │⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕                             
⍝ ⎕DL 0.1 → 1.0E¯1  │⎕⎕⎕⎕⎕⎕⎕ 
⍝       

1000:: ⎕←'Cmpy: Interrupt!'
0:: ⎕SIGNAL ⊂'EM' 'EN' 'Message',⍥⊂¨⎕DMX.(EM EN Message)  

⍝ Benchmark each code fragment  
  ⍝ ⎕AI[1] CPU (compute) time for the APL session in milliseconds.
  ⍝ ⎕AI[2] connect time for the APL session in milliseconds

  ⍺← ⍬  
⍝ ============ PLOT RESULTS ============= 
  ⍺ { 
    ⍝ Preamble with ⎕IO ⎕ML shadowed...
      ⍝ minPW: min plot width, maxLW: max line width  
        ⎕IO ⎕ML←0 1 ⋄ symbol minPW maxLW← '⎕' 25 80      
        (srtF lw)← ⍺, 0 ⎕PW↓⍨≢⍺ ⋄ lw⌊← maxLW
      ⍝ CSrt: Conditionally sort ⍺ ⍵ by ⍵.   
        CSrt← srtF{ 0≠⍺⍺: ⍺⍵ ⌷⍨¨ ⊂⊂ ⍋⍣ (⍺⍺=1) ⍒⍣ (⍺⍺=¯1)⊢ ⍵ ⋄ ⍺⍵ } 
    ⍝ Main... 
      ⍝ Conditional sort. Returns code strings and timings (sorted if srtF≠0)
        cod tim← ⊃CSrt/ ⍵ 
      ⍝ Determine plot value for each timing, given max plot width (minPW⌈ lw-...)
        pv← ⌈(tim÷ ⌈/tim)× minPW⌈ lw- 13+ cw← ⌈/ ≢¨cod  
      ⍝ Eye candy: Symbolically indicate times that are +/- 100% of ave time
      ⍝ Ensure ave never quite 0
        bar← '│¦⋮'⌷⍨⊂ 1E¯18 { 0 1 2 ⍸ |ave÷⍨ ⍵-ave←⍺⌈(+/÷≢) ⍵ } tim            
      ⍝ Format results nicely as 0 or more rows of a char matrix
      ⍝       code       →     timing           │⎕⎕⎕⎕⎕⎕
        ↑{ (cw↑ ⍵⊃cod),' →',(10 ¯3⍕ ⍵⊃tim),(⍵⊃bar), symbol⍴⍨ ⍵⊃pv }¨ ⍳≢cod 
  } {                                           
⍝ Return CPU time for each code segment (in ms), testing each for (0⊃⍺) sec. 
    opts← 1 1 ⋄ ⍺← opts ⋄ args← ⍺, opts↓⍨ ≢⍺    ⍝ quantum (in seconds), precheck (bool)
    q← ⌈1000× 0⊃args                            ⍝ q (in ms)
    p← 1⊃args                                   ⍝ p: see Prechk
  ⍝ _C2D: Ensure ⎕IO and ⎕ML are in scope of caller's ⎕IO ⎕ML.
    _C2D← (⊃⎕RSI)⍎ {'{_←',⍵,'⋄ 0}'}             ⍝ _C2D: Convert code text to a concise dfn
    Prechk←  p∘( _C2D { ~⍺: 0 ⋄ TF← ⍺⍺ ⍵ ⋄  0⊣ TF 0 } )
    T← q {                                      ⍝ T:  Time each code segment    
        ⎕IO ⎕ML←0 1                             
        TF← _C2D ⍺                              ⍝ TF: target code fn to execute                                       
      ⍝ we: wallclock (connect) expiration time
      ⍝ cs: CPU startup time
      ⍝  ⍺: # times through loop
        _TL← { ⎕AI[2]<we: (⍺+1)∇ ⍺⍺ 0 ⋄ ⍺÷⍨ ⎕AI[1]-cs }  ⍝ Timing loop: 
      ⍝ ------ Begin critical section ↓↓↓↓↓↓
        we cs← ⎕AI[2 1]+ ⍺⍺ 0                 
        0 TF _TL ⍵                              ⍝ Loop until connect time expires
      ⍝ ------ End   critical section ↑↑↑↑↑↑
    }
  ⍝ Benchmark:   ( null code )   (user code). Then convert result in ms to seconds 
    Bench← { ⍵ ,⍥⊂ 0.001× |( '0'  T  0 )-⍨ { ⍵  T  0 }¨ ⊆⍵ }

  ⍝ EXECUTIVE
  ⍝ Check (if pre=1) that each code fragment will run once before benchmarking
   _← Prechk¨ ⍵
   Bench ⍵
   },⊆⍵                                  
}