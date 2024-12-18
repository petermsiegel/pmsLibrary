∆FC←{ 
      ⍺←1 0 0 '`'                       ⍝ mode box debug escCh 
    0:: ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨('∆FC: ',EM) EN Message)
    0=≢⍺: 1 0⍴⍬
    (,⊆⍵)(⊃⎕RSI).{
        0=⊃⍵: 0 

      ⍝ ⍙SH⍙ is like catenate (,), 
      ⍝    except that it combines formatted fields without spaces between.
        ⍙SH⍙← {⎕ML←1 ⋄ ⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍵}
   
        ⍙SH⍙ ⍬,⍥⊂(⎕←⍎⊃⌽⍵)⍺
    } ⍺{   
        0= ≢⍺: '1 0⍴⍬' 
            Help← { ⎕ML←1 ⋄ ⎕ED⍠ 'ReadOnly' 1⊢ 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⍵ } 
        'help'≡⎕C ⍺: '_←⍬'⊣ Help ⎕XSI  
          ⍝ options and arguments to ∆FC 
            mode box debug escCh ← 4↑⍺, 1 0 0 '`'↑⍨ ¯4+ ≢⍺
            uniE← '∆FC DOMAIN ERROR: escape char not unicode scalar!' 11
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
           }'∆F_C'            ⍝ 'rc               opts   fStr  ≢fStr res   lenRes
            opts4← mode box debug (⎕UCS escCh) 
            Trace← debug∘{ ⍺: ⊢⎕←⍵ ⋄ ⍵}
            outLen← 512⌈ 256+ 3× ≢fStr← ⊃,⊆⍵ 
            
            rc res lenRes← ⎕SE.∆F_C opts4 fStr (≢fStr) outLen outLen 
         0= rc: 1 box (Trace lenRes↑ res) 
        ¯1= rc: 911 ⎕SIGNAL⍨ '∆FC ERROR: Formatting buffer not big enough!'
                rc  ⎕SIGNAL⍨ '∆FC ',(⎕EM rc),': ', lenRes↑res 
   } ⊃,⊆⍵
⍝H <<< NO HELP AVAILABLE >>>
}
