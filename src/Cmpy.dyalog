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

  ⍺← ⍬
1000:: ⎕←'Interrupt!'
0:: ⎕SIGNAL ⊂'EM' 'EN' 'Message',⍥⊂¨⎕DMX.(EM EN Message)  
⍝ ⎕AI[1] compute time for the APL session in milliseconds.
⍝ ⎕AI[2] connect time for the APL session in milliseconds
  CmpCpu←{                                    ⍝ returns CPU time for each code segment in ms 
    ⍺←1 ⋄ q←1000×⍺                            ⍝ q=wallclock quantum (test period) for each code seg. in ms 
    _C← ⍎ {'{_←',⍵,'⋄ 0}'}                    ⍝ Convert code text to a concise dfns
    T← {                                      ⍝ Time each code segment    
      ⎕IO ⎕ML←0 1                             ⍝ ⍺: how many times through loop
      we c← ⎕AI[2 1] ⋄ we+← q                 ⍝ we: when wallclock expires. c: startup CPU time
      _L← { ⎕AI[2]<we: (⍺+1)∇ ⍺⍺ 0 ⋄ ⍺÷⍨ ⎕AI[1]-c }  ⍝ Timing loop
      0 ⍺⍺ _L ⍵                               ⍝ Loop until wallclock time expires
    }
    NL← (_C '0') T                            ⍝ Time a "null" code fragment
    {                                         ⍝ For each user code fragment
      UL← (_C ⍵) T                            ⍝ ... Evaluate and time 
      0.001× (UL- NL) 0                       ⍝ ... Calculate result  
    }¨⊆⍵   
  }                  
  ⍺ {
  ⍝ Preamble with ⎕IO ⎕ML shadowed...
    ⍝ minPW: min plot width, maxLW: max line width  
      ⎕IO ⎕ML←0 1 ⋄ symbol minPW maxLW← '⎕' 25 80      
      (srtF lw)← ⍺, 0 ⎕PW↓⍨≢⍺ ⋄ lw⌊← maxLW
    ⍝ CSrt: Conditionally sort ⍺ ⍵ by ⍵.   
      CSrt← srtF{ ×⍺⍺: ⍺⍵ ⌷⍨¨ ⊂⊂ ⍋⍣ (⍺⍺=1) ⍒⍣ (⍺⍺=¯1)⊢ ⍵ ⋄ ⍺⍵ } 
  ⍝ Main... 
    ⍝ Conditional sort. Returns code strings and timings (sorted if srtF≠0)
      cod tim← ⊃CSrt/ ⍵ 
    ⍝ Determine plot value for each timing, given max plot width (minPW⌈ lw-...)
      pv← ⌈(tim÷ ⌈/tim)× minPW⌈ lw- 13+ cw← ⌈/ ≢¨cod  
    ⍝ Format results nicely as 0 or more rows of a char matrix
    ⍝       code       →     timing       │⎕⎕⎕⎕⎕⎕
      ↑{ (cw↑ ⍵⊃cod),' →',(10 ¯3⍕ ⍵⊃tim),'│', symbol⍴⍨ ⍵⊃pv }¨ ⍳≢cod 
  }{ ⍵ (1 CmpCpu ⍵) },⊆⍵           ⍝ Test each user code seq. for 1 sec.                   
}