∆FC←{ 
      ⍺←1 0 0 '`'                       ⍝ mode box debug escCh 
    0:: ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨EM EN Message)
    ⍝  (⊃⎕RSI)⍎ ⍺{   
        0= ≢⍺: '1 0⍴⍬' 
            Help← { ⎕ML←1 ⋄ ⎕ED⍠ 'ReadOnly' 1⊢ 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⍵ } 
        'help'≡⎕C ⍺: '_←⍬'⊣ Help ⎕XSI  
          ⍝ options and arguments to ∆FC 
            mode box debug escCh ← 4↑⍺, 1 0 0 '`'↑⍨ ¯4+ ≢⍺
            uniE← '∆FC DOMAIN ERROR: escape char not unicode scalar!' 11
          ×80| ⎕DR escCh: ⎕SIGNAL/ uniE
          1≠ ≢escCh:      ⎕SIGNAL/ uniE
            fStr← ⊃,⊆⍵
            outLen← 512⌈ 256+ 3× ≢fStr
        ⍝ lenRes: send in the maxRes, returns the actual length of the data!
        ⍝ int fc(INT4 opts[3], CHAR4 fString[], INT4 fStringLen, CHAR4 outBuf[], INT4 *outPLen){
           _← ⎕SE.⎕EX'∆F_C'⊣⎕←'reloading ∆F_C'
           _← '∆F_C' ⎕SE.⎕NA⍣(⊃0=⎕SE.⎕NC'∆F_C')⊢ 'I4 ∆FC.dylib|fc  <I4[4] <C4[] I4  >C4[] =I4' 
          ⍝ '    rc            opts    fStr  ≢fStr res   lenRes'
            opts4← mode box debug (⎕UCS escCh)  
            rc res lenRes← ⎕SE.∆F_C opts4 fStr (≢fStr) outLen outLen 
         0= rc: lenRes↑ res 
        ¯1= rc: 911 ⎕SIGNAL⍨ '∆FC ERROR: Formatting buffer not big enough!'
                rc  ⎕SIGNAL⍨ '∆FC ',(⎕EM rc),': ', lenRes↑res 
   ⍝ } ⊃,⊆⍵
⍝H <<< NO HELP AVAILABLE >>>
}
