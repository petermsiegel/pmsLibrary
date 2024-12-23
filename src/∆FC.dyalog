ⓄⓊⓉ← {ⓁⒻⓉ} ∆FC ⓇⒼⓉ; ⒸⓄⒹ; ⎕TRAP 
⍝ ∆FC
  ⎕TRAP← 0 'C' '⎕SIGNAL ⊂⎕DMX.(''EM'' ''EN'' ''Message'' ,⍥⊂¨(''∆FC '',EM) EN Message)'
  
  :If 900⌶0
        ⓁⒻⓉ← 1 0 '`'          ⍝ mode debug escCh 
  :ElseIf 0=≢ⓁⒻⓉ
       ⓄⓊⓉ← 1 0⍴⍬ 
       :Return 
  :Elseif 'help'≡⎕C ⓁⒻⓉ
       ⓄⓊⓉ← { ⎕ML←1 ⋄ ⍬⊣⎕ED⍠ 'ReadOnly' 1⊢'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⍵ } ⎕XSI 
       :Return  
  :Else 
       ⓁⒻⓉ← 3↑ⓁⒻⓉ, 1 0 '`'↑⍨ ¯3+ ≢ⓁⒻⓉ
  :EndIf 
  ⓇⒼⓉ← ,⊆ⓇⒼⓉ  

  ⒸⓄⒹ← ⓁⒻⓉ ((⊃⎕RSI) {  ⍝ Returns: mode debug code
    ⍝ Hide outer vars ⓁⒻⓉ and ⓇⒼⓉ, so invis. to ⎕NL etc.
      ~⊃⎕EX 'ⓁⒻⓉ' 'ⓇⒼⓉ'⊣ ⓁⒻⓉ← ⓇⒼⓉ←0:   
      1=⊃⍺:  ⍺⍺⍎ ⍵                                ⍝ STD   mode: default
      0=⊃⍺:  ,⍵                                   ⍝ FN    mode :  we'll create a dfn below
     ¯1=⊃⍺:  0∘⎕SE.Dyalog.Utils.disp  ¯1↓⍺⍺⍎ ⍵    ⍝ LIST  mode
     ¯2=⊃⍺:  0∘⎕SE.Dyalog.Utils.disp ⍪ ¯1↓⍺⍺⍎ ⍵   ⍝ TABLE mode
        ⎕SIGNAL 11 ⋄ ⍵⍵  ⍝ Enable ⍵⍵ 
  }ⓇⒼⓉ)⊢ ⓁⒻⓉ{   
    ⍝ options and arguments to ∆FC 
        badEscE← 'DOMAIN ERROR: escape char not unicode scalar!' 11
        mode debug escCh ← ⍺
    ×80| ⎕DR escCh: ⎕SIGNAL/ badEscE
    1≠ ≢escCh:      ⎕SIGNAL/ badEscE

    ⍝ int fc(INT4 opts[3], CHAR4 fString[], INT4 fStringLen, CHAR4 UTBuf[], INT4 *outPLen)
    ⍝ fString: the format string
    ⍝ outBuf:  the output buffer (on input: the output buffer size needed)
    ⍝ outPLen: the output buffer size (on input: the same number as for outBuf)
    ⍝ Returns:  rc outBuf outPLen
    ⍝   rc:     0 (ok), >0 (APL signal code [error]), ¯1: (outBuf too small)
    ⍝   outBuf: the actual output buffer in 4-byte chars. Chars beyond outPLen are junk.
    ⍝   outPLen: the actual length (in 4-byte chars) of code output
        _← debug ⎕SE.{ 
          _← ⎕EX⍣⍺⊢⍵  ⍝⍝⍝ Only TEST mode 
          ⍵ ⎕NA⍣(⊃0=⎕NC ⍵)⊢ 'I4 ∆FC.dylib|fc  <I4[3] <C4[] I4  >C4[] =I4' 
        }'∆F_C'            ⍝ 'rc              opts   fStr  ≢fStr res   lenRes
 
        opts3← mode debug (⎕UCS escCh) 
        outLen← 512⌈ est← 256+ 2× ≢fStr← ⊃,⊆⍵ 
        
        DOut← {debug=1: ⊢⎕←⍵ ⋄ ⍵}
        rc res lenRes← ⎕SE.∆F_C opts3 fStr (≢fStr) outLen outLen 
      ⍝ _← DOut 'Estimated input length',est,' actual output length',lenRes 

     0= rc:    DOut lenRes↑ res 
    ¯1= rc:    911 ⎕SIGNAL⍨ 'DOMAIN ERROR: Formatting buffer not big enough!'
               rc  ⎕SIGNAL⍨ (⎕EM rc),': ', lenRes↑res 
  } ⊃ⓇⒼⓉ

  ⓄⓊⓉ← (⊃⎕RSI)⍎⍣(0=⊃ⓁⒻⓉ)⊢ ⒸⓄⒹ
⍝H <<< NO HELP AVAILABLE >>>

