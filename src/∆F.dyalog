ⓄⓊⓉ← {ⓁⒻⓉ} ∆F ⓇⒼⓉ; ⎕TRAP 
⍝ ∆FC
  ⎕TRAP← 0 'C' '⎕SIGNAL ⊂⎕DMX.(''EM'' ''EN'' ''Message'' ,⍥⊂¨(''∆FC '',EM) EN Message)'
  
  :If 900⌶0
      ⍝      mode debug escCh extLib
      ⍝ (If escCh is a number, the default '`' is used)
        ⓁⒻⓉ← 1    0     '`'   1          
  :ElseIf 0=≢ⓁⒻⓉ
       ⓄⓊⓉ← 1 0⍴⍬ 
       :Return 
  :Elseif 'help'≡⎕C ⓁⒻⓉ
       ⓄⓊⓉ← { ⎕ML←1 ⋄ ⍬⊣⎕ED⍠ 'ReadOnly' 1⊢'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⍵ } ⎕XSI 
       :Return  
  :Else 
      ⍝             mode debug escCh extLib
        ⓁⒻⓉ← 4↑ⓁⒻⓉ, 1    0     '`'   1↑⍨ ¯4+ ≢ⓁⒻⓉ
  :EndIf 

  ⓄⓊⓉ← (⊃⎕RSI)⍎ ⓁⒻⓉ {   
      ⎕IO ⎕ML←0 1 
    ⍝ options and arguments to ∆FC 
      badEscE← 'DOMAIN ERROR: escape char not unicode scalar!' 11
      mode debug escCh extLib ← ⍺
      escCh← {0=⊃0⍴⍵: '`' ⋄ ⍵ }escCh 
  ×80| ⎕DR escCh: ⎕SIGNAL/ badEscE
  1≠ ≢escCh:      ⎕SIGNAL/ badEscE

    CheckLib← ⎕SE.{
      ⍵=0: ⍬ ⋄ 9=⎕NC '⍙F': ⍬
        _← '⍙F' ⎕NS ⍬
  ⍝  Define ∆FC utilities-- for use if extLib=1 (default).
  ⍝  Merge all the elements to the right, adjusting for height, without adding blank columns.
      ⍙F.M← {⎕ML←1 ⋄⍺←⊢⋄ ⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}
  ⍝  (%) Center field ⍺ above field ⍵. If ⍺ is omitted, a single-line field is assumed.
      ⍙F.A← {⎕ML←1 ⋄⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}
  ⍝  ($) Box item ⍵ 
      ⍙F.B←{⎕ML←1 ⋄1∘⎕SE.Dyalog.Utils.disp ,⍣(⊃0=⍴⍴⍵)⊢⍵}
  ⍝  (Modes ¯1 and ¯3) Displaying the entire formatted result
      ⍙F.D← ⎕SE.Dyalog.Utils.disp
        ⍬
    }  
    _← CheckLib extLib  

    ⍝ int fs_format(INT4 opts[4], CHAR4 fString[], INT4 fStringLen, CHAR4 outBuf[], INT4 *outPLen)
    ⍝ opts: (see below)
    ⍝ fString: the format string
    ⍝ outBuf:  the output buffer (on input: the output buffer size needed)
    ⍝ outPLen: the output buffer size (on input: the same number as for outBuf)
    ⍝ Returns:  rc outBuf outPLen
    ⍝   rc:     0 (ok), >0 (APL signal code [error]), ¯1: (outBuf too small)
    ⍝   outBuf: the actual output buffer in 4-byte chars. Chars beyond outPLen are junk.
    ⍝   outPLen: the actual length (in 4-byte chars) of code output
        _← debug ⎕SE.{ 
          _← ⎕EX⍣⍺⊢⍵  ⍝⍝⍝ Only TEST mode 
          ⍵ ⎕NA⍣(⊃0=⎕NC ⍵)⊢ 'I4 ∆F.dylib|fs_format  <I4[4] <C4[] I4  >C4[] =I4' 
        }'∆F_C'            ⍝ 'rc              opts   fStr  ≢fStr res   lenRes
 
        opts4← mode debug (⎕UCS escCh) extLib 
        outLen← 512⌈ 256+ 2× ≢fStr← ⊃,⊆⍵ 
        
        DOut← {debug=1: ⊢⎕←⍵ ⋄ ⍵}
        rc res lenRes← ⎕SE.∆F_C opts4 fStr (≢fStr) outLen outLen 

     0= rc:    DOut lenRes↑ res 
    ¯1= rc:    911 ⎕SIGNAL⍨ 'DOMAIN ERROR: Formatting buffer not big enough!'
               rc  ⎕SIGNAL⍨ (⎕EM rc),': ', lenRes↑res 
  } ⊃ⓇⒼⓉ← ,⊆ⓇⒼⓉ

⍝H <<< NO HELP AVAILABLE >>>

