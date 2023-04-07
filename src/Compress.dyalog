 Compress←{

     NL←⎕UCS 10

     opts←('IC' 1)('Mode' 'M')('DotAll' 1)('EOL' 'LF')  ⍝ \N=. dot

     txt←⊆⍵  ⍝ ⋄ (⊃⌽txt),←NL

     txt←'(\n)\h*(:\N*\n?)' '\n^\h+' '^\h*⍝\N*\n' '⍝\N*' '''[^'']*''' '\n'⎕R'\1\2' '' ' ' '' '\0' '⋄'⍠opts⊣txt
     txt
 }
