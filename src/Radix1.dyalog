Radix1← {  
  ⍝ For efficiency, externs: place, base, inV, cntV, outV
    DIV← ⌊÷
    CSortByPlace←{ 
        IX← {base| ⍵ DIV place}   
        place← ⍵ 
        cntV[]←0 ⋄ n← ≢inV
        _← { ⍵≥n: cntV⊢← +\cntV 
                  cntV[ IX inV[⍵] ]+←1 
                  ∇ ⍵+ 1
        }0     
        { ⍵<0: inV⊢← outV ⋄ aw← inV[⍵] ⋄ sel← IX aw 
               outV[ cntV[ sel ]← cntV[ sel ]- 1 ]← aw 
               ∇ ⍵- 1 
        } ¯1+ ≢inV                    
    }   ⍝ End CSortByPlace  
    ⍺← 512
    cntV← 0⍴⍨ base← ⍺                                      ⍝ Base should be multiple of 256 
    max← ⌈/ |outV← inV←,⍵ 
    _← { CSortByPlace ⍵ }¨ base* ⍳⌈base⍟max 
    (lt0/ inV), inV/⍨ ~lt0← inV<0                   ⍝ One more pass for negative nums
} ⍝ End RadixSort