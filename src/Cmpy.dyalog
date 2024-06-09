Cmpy←{ 
⍝ Cmpy: Like cmpx but avoids some odd failures in May 2024
⍝ lines← [srtF←0 [lw← (80⌊⎕PW)]] Cmpy code1 [code2  [code3...]] 
⍝         srtF:  If  1, displays in ascending order by time.
⍝                If ¯1, displays in descending order by time.
⍝                If  0, displays in the order presented.
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
⍝ Note: Requires cmpx (if not present, copies it from dfns).

  1000:: ⎕←'Interrupt!'
  0:: ⎕SIGNAL ⊂'EM' 'EN' 'Message',⍥⊂¨⎕DMX.(EM EN Message)
    ⍺← ⍬  
    (srtF lw)← ⍺, (0 (80⌊ ⎕PW ))↓⍨≢⍺
    cod symbol minPW← (⊆⍵) '⎕' 10
  0=⎕NC 'cmpx': srtF lw ∇ cod ⊣ 'cmpx' ⎕CY 'dfns' 
 
  ⍝ CSrt: Conditionally sort ⍺ ⍵ by ⍵?   
    CSrt← srtF{ ×⍺⍺: ⍺⍵ ⌷⍨¨ ⊂⊂ ⍋⍣ (⍺⍺=1) ⍒⍣ (⍺⍺=¯1)⊢ ⍵ ⋄ ⍺⍵ }  
 
⍝ Main... 
  ⍝ Time each code fragment
    cod tim← cod CSrt 1 cmpx¨ cod   
  ⍝ Determine plot value for each timing, given maximum plot width (at least minPW)
    pv← ⌈(tim÷ ⌈/tim)× minPW⌈ lw- 13+ cw← ⌈/ ≢¨cod  
  ⍝ Format results nicely as 0 or more lines (char vecs)
  ⍝       code       →     timing       │⎕⎕⎕⎕⎕⎕
    ↑{ (cw↑ ⍵⊃cod),' →',(10 ¯3⍕ ⍵⊃tim),'│', symbol⍴⍨ ⍵⊃pv }¨ ⍳≢cod   
}