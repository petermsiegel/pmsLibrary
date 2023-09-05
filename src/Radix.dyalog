∇ Radix data
  ; title; sorted; ctl
⍝ Does demo and exports <RadixSort>
⍝ Python alg:  https://www.programiz.com/dsa/radix-sort#google_vignette
  ⎕←'>>> Exporting RadixSort'
  RadixSort←{
      CountingSort←{
           AccumulateV← { size← ⍵  
            where← place SELECTV ⍳size
            +\cntA ⊣ {cntA[ ⍵ ] +← 1}¨where
           }
         SortByPlace← {  
              { ix← ⍵ ⋄ ⍵<0: outA  
                sel← inA SELECT ix place
                outA[ cntA[ sel ]- 1 ]← inA[ ix ]
                cntA[ sel ]-← 1
                 ∇ ix- 1
              }⍵-1
          }
          place←   ⍵
          inA←   ⍺ 
          outA←  size⍴0
          cntA←  base⍴0 
          cntA←  AccumulateV size
                 SortByPlace size  
      } ⍝ End CountingSort
      
      CountingByPlace←{ ⍝ ⍵= place (start with 1s and move up a base at a time (⍵×base))
        0≥ max_element IDIV ⍵: ⍺
          (⍺ CountingSort ⍵) ∇ ⍵× base
      }
      IDIV← ⌊÷
      SELECT← { in← ⍺ ⋄ ix pl← ⍵ ⋄ base| in[ix] IDIV pl }
      SELECTV← { place ixx←⍺ ⍵ ⋄ base| inputA[ ixx ] IDIV place }
      base← 2048  ⍝ 256 ⍝ 2048
      ⎕← 'base' base 
    
  ⍝ Go!
    3 11(~∊⍨) 80|⎕DR ⍵: ⎕SIGNAL ⊂('EN' 11)('Message' 'Radix only sorts integers.')
      inputA← ⍵ 
      size← ≢inputA
      max_element← ⌈/inputA
      sorted← inputA CountingByPlace 1
  ⍝ If any neg numbers, one more pass
      lo← sorted<0
    1∊lo: (sorted/⍨ lo), sorted/⍨ ~lo ⋄ sorted
  } ⍝ End RadixSort

    :IF 0=≢data
       data←  121 ¯232 432 564 ¯233 23 1 233 45 788
    :EndIf
    title←  ↑'Data' 'Sorted',¨ ':'
    :TRAP 11
        sorted← RadixSort data 
    :ELSE 
        ⎕SIGNAL ⊂⎕DMX.(('EM' EM) ('EN' EN) ('Message' Message))
    :ENDTRAP 
    ctl←    data[ ⍋data ]
    ⎕←title, ↑data sorted 
    :IF sorted≢ ctl
       ⎕←'Whoops. Data sorted incorrectly'
    :ENDIF 