∆FC←{ 
      ⍺←1 0 '`'                      ⍝ mode box escCh
    0:: ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨EM EN Message)
      (⊃⎕RSI)⍎ ⍺{   
        0= ≢⍺: '1 0⍴⍬' 
            Help← { ⎕ML←1 ⋄ ⎕ED⍠ 'ReadOnly' 1⊢ 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⍵ } 
        'help'≡⎕C ⍺: '_←⍬'⊣ Help ⎕XSI  
            EnQ← {⍵/⍨1+⍵=''''}
            extraElem← 200               ⍝ # elem (chars) in header code passed by ∆FC.c 
          ⍝ options and arguments to ∆FC 
            mode box escCh← 3↑⍺, 1 0 '`'↑⍨ ¯3+ ≢⍺
            uniE← '∆FC DOMAIN ERROR: escape char not unicode scalar!' 11
          ×80| ⎕DR escCh: ⎕SIGNAL/ uniE
          1≠ ≢escCh:      ⎕SIGNAL/ uniE
            escU← ⎕UCS escCh             ⍝ numeric rep of escape character
            fstr← ⊃args← ,⊆⍵
            maxRes← 256⌈ extraElem+ 3× ≢fstr
        ⍝ lenRes: send in the maxRes, returns the actual length of the data!
           '∆FC' ⎕NA 'I4 ∆FC.dylib|fc  <I4[3] <C4[] I4  >C4[] =I4' 
          ⍝ '    rc            opts    fstr  ≢fstr res   lenRes'
            ⎕← 'rc res lenRes←' '∆FC' (mode box escU) fstr maxRes  
            ⎕← rc res lenRes← 0, {⍵ 19} '(⍳5)(⍪⍳2)(''cat''''s'')JUNK⌶⍒⍫⌶⍫⍒'
        0= rc: lenRes↑ res 
        ¯1= rc: 911 ⎕SIGNAL⍨ '∆FC ERROR: Formatting buffer not big enough!'
                rc  ⎕SIGNAL⍨ '∆FC ',(⎕EM rc),': ', lenRes↑res 
    } ⊃,⊆⍵
⍝H <<< NO HELP AVAILABLE >>>
}
