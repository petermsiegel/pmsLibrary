__RR__← {__L__} ∆FC __R__; __R∆__ 
  :If 900⌶0
      __L__← 1 0 0 '`'          ⍝ mode box debug escCh 
  :ElseIf 0=≢__L__
    __RR__← 1 0⍴⍬
    :Return 
  :Elseif 'help'≡⎕C __L__
      __RR__← ⍬⊣ { ⎕ML←1 ⋄ ⎕ED⍠ 'ReadOnly' 1⊢ 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⍵ } ⎕XSI  
  :Else 
    __L__← 4↑__L__, 1 0 0 '`'↑⍨ ¯4+ ≢__L__
  :EndIf 
  __R__← ,⊆__R__ 

  :Trap 0
    __R∆__← __L__ (⊃⎕RSI).{  ⍝ Returns: mode box(not implemented) debug code
        1=⊃⍺:  {⎕ML←1 ⋄ ⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍵},⊆ ⍎ ⍵,'__R__'
        0=⊃⍺:  '{⎕ML←1 ⋄ ⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍵},⊆',⍵
       ¯1=⊃⍺:  ⎕SE.Dyalog.Utils.disp{⎕ML←1 ⋄ ⍪((⌈/≢¨)↑¨⊢)⎕FMT¨⍵},⊆ ⍎ ⍵,'__R__'
       ¯2=⊃⍺:  ⎕SE.Dyalog.Utils.disp{⎕ML←1 ⋄ ((⌈/≢¨)↑¨⊢)⎕FMT¨⍵},⊆ ⍎ ⍵,'__R__'
    }(__R__)⊢ __L__{   
    ⍝ options and arguments to ∆FC 
      uniE← '∆FC DOMAIN ERROR: escape char not unicode scalar!' 11
      mode box debug escCh ← ⍺
    ×80| ⎕DR escCh: ⎕SIGNAL/ uniE
    1≠ ≢escCh:      ⎕SIGNAL/ uniE

    ⍝ int fc(INT4 opts[4], CHAR4 fString[], INT4 fStringLen, CHAR4 outBuf[], INT4 *outPLen)
    ⍝ fString: the format string
    ⍝ outBuf:  the output buffer (on input: the output buffer size needed)
    ⍝ outPLen: the output buffer size (on input: the same number as for outBuf)
    ⍝ Returns:  rc outBuf outPLen
    ⍝   rc:     0 (ok), >0 (APL signal code [error]), ¯1: (outBuf too small)
    ⍝   outBuf: the actual output buffer in 4-byte chars. Chars beyond outPLen are junk.
    ⍝   outPLen: the actual length (in 4-byte chars) of code output
      _← debug ⎕SE.{ 
        _← ⎕EX⍣⍺⊢⍵
        ⍵ ⎕NA⍣(⊃0=⎕NC ⍵)⊢ 'I4 ∆FC.dylib|fc  <I4[4] <C4[] I4  >C4[] =I4' 
      }'∆F_C'            ⍝ 'rc              opts   fStr  ≢fStr res   lenRes
      opts4← mode box debug (⎕UCS escCh) 
      Trace← debug∘{ ⍺: ⊢⎕←⍵ ⋄ ⍵}
      outLen← 512⌈ 256+ __est__← 3× ≢fStr← ⊃,⊆⍵ 
      
      rc res lenRes← ⎕SE.∆F_C opts4 fStr (≢fStr) outLen outLen 
      ⎕← 'Estimated input length',__est__,' actual output length',lenRes 

    0= rc:    Trace lenRes↑ res 
   ¯1= rc:    911 ⎕SIGNAL⍨ '∆FC ERROR: Formatting buffer not big enough!'
              rc  ⎕SIGNAL⍨ '∆FC ',(⎕EM rc),': ', lenRes↑res 
   } ⊃__R__
   :If 0≠⊃__L__  
       __RR__← __R∆__
   :Else 
       __RR__← (⊃⎕RSI)⍎'{',__R∆__, '⍵,⍨⊂', '}',⍨ ''''{⍺,⍺,⍨⍵/⍨+/1+⍵=⍺}⊃__R__
   :EndIf 
:Else 
    ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨('∆FC: ',EM) EN Message)
:EndTrap 
⍝H <<< NO HELP AVAILABLE >>>

