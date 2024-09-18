Cmpy←{   
⍝H Cmpy: Like cmpx but avoids some odd failures in May 2024. Unlike cmpx, by default
⍝H       Cmpy returns CPU seconds measured, after timing for the specified or default (=1) wallclock seconds.  
⍝H lines← 〚 srtO←0 〚 lWidO←⌊0.8×⎕PW 〚 qSecO←1 〚 checkO←1 〛〛〛〛 Cmpy code1 〚 code2 〚 code3… 〛〛
⍝H      ⍺:
⍝H         srtO:   If  ...,   displays in    ……     order by total CPU time.
⍝H                      1                 ascending
⍝H                     ¯1                 descending  
⍝H                      0            the order presented (default)
⍝H         lWidO:   width of each line, including the plot space (default: 80% of ⎕PW).
⍝H         qSec:   "quantum," total measurement time per code seq in wallclock sec (default: 1)
⍝H         checkO: If 1 (true), validate each code segment once before timing (default: 1)
⍝H                 Otherwise, errors (if any) may take 1 or more wallclock seconds to surface!
⍝H      ⍵: 
⍝H         code1 〚 code2〚 code3… 〛〛, where
⍝H         ∘ codeN is a string containing an executable sequence returning a value.
⍝H           Each such string is executed in the (user's) calling environment.
⍝H  
⍝H Returns: the list of lines showing for each code string codeN:
⍝H          code_text → total_time  │<relative_plot[*]>
⍝H as in: 
⍝H         ⎕DL 0.1   → 1.0E¯1      │⎕⎕⎕⎕⎕⎕⎕ 
⍝H where ⎕⎕⎕⎕⎕⎕ is a graph of the relative time used: 
⍝H [*] Min plot width for longest time: <minPlotW> (see below), no matter the pagewidth.
⍝H     │ may be replaced by ¦, ⋮, :, or ·, depending on performance relative to the fastest code segment.
⍝H     By default, code distance from fastest code segment is as follows:
⍝H            '‖' < '|' < '¦' < '⋮' < ':' < '·', where < means "is for code closer than".
⍝H -------------------
⍝H Example: 
⍝H       ¯1 Cmpy  '⎕DL 1' '⎕DL 0.1' '⎕DL 0.5' '1.123'
⍝H  Min= 6.94E¯8   Ave= 4.48E¯4   Max= 9.98E¯4                                                          
⍝H  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯                                                          
⍝H  ⎕DL 1   → 9.98E¯4  ·⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
⍝H  ⎕DL 0.5 → 4.98E¯4  :⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕                                        
⍝H  ⎕DL 0.1 → 2.98E¯4  :⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕                                                        
⍝H  1.123   → 6.94E¯8  │⎕                                                                                    
⍝H  
⍝H For help, enter:
⍝H     Cmpy ⍬
⍝H      

1000:: ⎕←'Cmpy: Interrupt!'
0::    ⎕SIGNAL ⊂'EN' 'Message' 'EM' ,⍥⊂¨⎕DMX.( EN Message, ⊂'Cmpx: ',EM )  
0=≢⍵:  { help←'^ *⍝H ?(.*?) *$' ⎕S ' \1'⊣⎕NR ⍵ ⋄ ⎕ED 'help' }⊃⎕XSI  

⍝ Benchmark each code fragment  
  ⍺← ⍬  
  (2↑⍺) { 
  ⍝* Phase II- process Phase II options; sort, format, and plot results ready to display  
  ⍝* Decodes and uses the first 2 elements of ⍺ (if present) as (srtO lWidO).                             
    ⍝ Preamble with ⎕IO ⎕ML shadowed...
      ⍝ minLW:    min line width (plot and text, etc.)
      ⍝ minPlotW: min plot width (just the plot section)
      ⍝ plotS:    plot symbol 
        ⎕IO ⎕ML← 0 1 ⋄ minLW minPlotW plotS← (⌊⎕PW×0.8) 25 '⎕' 
      ⍝ ⍺ options: srtO (default: 0, ∊ ¯1 0 1), lWidO (default (if lWidO=0): minLW) 
        srtO lWidO← ⍺ ⋄ lWidO+← minLW× lWidO=0 

      ⍝ CSort: Split ⍵ (2=≢⍵) into ⍺ ⍵; srtO each of these acc. to ⍵ and return them.
        CSort← ⊃srtO{ ⍺⍺∊¯1 1: ⍺⍵⌷⍨¨⊂⊂ ⍋⍣(⍺⍺=1) ⍒⍣(⍺⍺=¯1)⊢ ⍵ ⋄ ⍺⍵ }/ 
      ⍝ Ave, Min, Max
        Ave← +/÷≢ ⋄ Min← ⌊/ ⋄ Max← ⌈/
      ⍝ Bar: Select a separator bar for each time (default: distance from min time)
      ⍝   bar← s Bar tim min2max 
      ⍝   0=≢s: just use '│' as separator bar for each time.
      ⍝   s∊¯1 0 1: sep bar for each time based on log10 of distance of each time from 
      ⍝     min time (s=¯1), ave time (s=0), or max time (s=1).
        Bar← {  
            ⍺← ¯1 ⋄ s (t min2max) e b← ⍺ ⍵ 1E¯18 '‖|¦⋮:·' 
          0=≢s: '│'⍴⍨ ≢t 
            b⌷⍨ ⊂(⍳≢b)⍸ |nz\ 10⍟ |w/⍨ nz← 0≠ w← ⍙÷⍨ t- ⍙← e⌈ min2max⌷⍨ 1+ s
        }
        F← 10 ¯3∘⍕
      ⍝ Phase II Executive
      ⍝ a. Sort code strings and CPU time based on CPU time
        cod tim← CSort ⍵ 
        min2max← ((⌊/),(+/÷≢),(⌈/)) tim                 ⍝ (min, ave, max) of tim
        bar←  Bar tim min2max
      ⍝ b. Determine plot value for each timing, given max plot width (minPlotW⌈ lWidO -...)
        pv← ⌈(tim÷ ⌈/tim)× minPlotW⌈ lWidO - 13+ cw← ⌈/ ≢¨cod  
      ⍝ c. Generate some stats 
        m2mTxt← 'Min' 'Ave' 'Max',¨ '='
        stats← { ('¯'⍴⍨¯2+≢⍵),⍨⍥⊂⍵ } ∊ m2mTxt ,∘F¨ min2max 
      ⍝ d. Format results nicely as 0 or more rows of a char matrix and return...
      ⍝       code       →     timing           │⎕⎕⎕⎕⎕⎕
        FmtR← { (cw↑ ⍵⊃cod), ' →', (F ⍵⊃tim), (⍵⊃bar), plotS⍴⍨ ⍵⊃pv }
        ↑stats, FmtR¨ ⍳≢cod 
  } (2↓⍺) {   
⍝* Phase I- process Phase 1 args; time each code segment passed by the user 
⍝* Decodes and uses the 3rd and 4th elements of (the user's) ⍺ as (qSecO checkO); see 2↓⍺ above.                                           
⍝* Return CPU time for each code segment (in ms), testing each for (0⊃⍺) sec. 
  ⍝ ⍺ options: exclude first 2 original options.
  ⍝ qSecO:   "Quantum", timing interval for each code segment in wallclock sec (float) 
  ⍝ checkO:  If true (default), validate all code segs before any timing begins) (bool)
    o← 1 1 ⋄ (qSecO checkO)← 2↑⍺, o↓⍨ ≢⍺         ⍝ o: options => qSecO checkO 
  qSecO≤ 0:       11 ⎕SIGNAL⍨ 'DOMAIN ERROR: timing interval (3rd Option) must be a positive number'
  checkO(~∊) 0 1: 11 ⎕SIGNAL⍨ 'DOMAIN ERROR: precheck (4th option) must be 0 or 1'
 
  ⍝ C2D: Ensure ⎕IO and ⎕ML are in scope of caller's ⎕IO ⎕ML.
    T2Dfn← (⊃⎕RSI)⍎ {'{_←',⍵,'⋄ 0}'}            ⍝ T2Dfn: Convert code text to a concise dfn
    CCheck← { ⍵⊣ (T2Dfn ⍵) 0 }¨⍣ checkO         ⍝ CCheck: Execute below, if checkO=1
    T← (⌈qSecO×1000) {                          ⍝ T: Time each code seg for ⍺ ms.   
        ⎕IO ⎕ML← 0 1                            ⍝ Only now allow ⎕IO ⎕ML localization
        TF← T2Dfn ⍺                             ⍝ TF <code>: target code fn to execute                                       
      ⍝ _TL: Timing loop                        ⍝ <Dfn> _TL 0: 
      ⍝   we: wallclock (connect) expiration time
      ⍝   cs: CPU startup time
      ⍝    ⍺: # times through loop
        _TL← { ⎕AI[2]<we: (⍺+1)∇ ⍺⍺ 0 ⋄ ⍺÷⍨ ⎕AI[1]-cs }   ⍝ ⎕AI[2]: wallclock, [1]: CPU
      ⍝ ------ Begin critical section ↓↓↓↓↓↓
        we cs← ⎕AI[2 1]+ ⍺⍺ 0                 
        0 TF _TL ⍵                              ⍝ Loop until connect time expires
      ⍝ ------ End   critical section ↑↑↑↑↑↑
    }
  ⍝ Benchmark: ( null code @scalar ) -⍨ ( user code @vec ) in ms => seconds 
    Bench← { ⍵ ,⍥⊂ 0.001× |( '0'  T  0 )-⍨ { ⍵  T  0 }¨ ⊆⍵ }

  ⍝ Phase I Executive
  ⍝ Conditionally check that each code string (⍵) runs, then Benchmark ⍵
    Bench CCheck ⍵
   },⊆⍵                                  
}