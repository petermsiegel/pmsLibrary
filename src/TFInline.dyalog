 TFInline←{

     NS_NM←'⍙ns'

     NL←⎕UCS 10 ⋄ SQ←''''

     tradfnP←'^(\h*)∇\h*(.*?)^\h*∇\h*$'

     ⋄ primitivesP←'⌶%⍺⍵.⍬⊢¥$£¢{}⊣⌷¨[/⌿\⍀<≤=≥>≠∨∧-+÷×?∊⍴~↑↓⍳○*⌈⌊∇∘(⊂⊃∩∪⊥⊤|;,⍱⍲⍒⍋⍉⌽⊖⍟⌹!⍕⍎⍫⍪≡≢óôöø"#&´@`∣¶:⍷¿¡⋄←→⍝)]§⍣'
     ⋄ balDfnP←'(?x) (?<P> (?<!\\) \{ ((?>  [^{}''⍝\\]+   | (?:\\.)+ | (?:''[^'']*'')+ | ⍝[^}⋄]* | (?&P)* )+)  \} )'

     dfnP←'(?x) ^ (\h*) ( [\w∆⍙_]+ ) ( \h*←\h*([⎕\w∆⍙_\Q',primitivesP,'\E]+\h*)?',balDfnP,')'

     nsStart←'(?xi) ^\h* :NameSpace \h*([\w∆⍙_]+)\N*$'

     nsEnd←'(?xi) ^\h* :EndNameSpace \N*$'


     tradfnP dfnP nsStart nsEnd ⎕R{
         Case←⍵.PatternNum∘=
         tradI dfnI nsStartI nsEndI←⍳4
         F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
         Case tradI:{
             pfx txt←F¨1 2
             txt←(1+SQ=txt)/txt
             pfx,'_←',NS_NM,'.⎕FX ',SQ,¯1↓'\n'⎕R(SQ,' ',SQ)⍠('Mode' 'M')('EOL' 'LF')⊣txt
         }⍵
         Case dfnI:{
             pfx nm sfx←F¨0 1 2
             '_'≡⍥,nm:F 0
             pfx,'⍙ns.',nm,sfx
         }⍵
         Case nsStartI:{
             fnNm←'(?i)ns'⎕R''⊣F 1
             fnNm,'←{',NL,'   ',NS_NM,'←(calr←⊃⎕RSI).⎕NS⍬  ⋄ _←d.⎕DF (⍕calr),''.[∆DICT]''',NL
         }⍵
         Case nsEndI:{
             '}',NL
         }⍵
         ∘∘error∘∘
     }⍠('Mode' 'M')('UCP' 1)('EOL' 'LF')('DotAll' 1)⊣⊆⍵

 }
