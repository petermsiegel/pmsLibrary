DirTree← { 
⍝ Python:
⍝  import sys
⍝  from pathlib import Path
⍝  def print_tree(p: Path, last=True, header=''):
⍝    elbow = "└──"
⍝    pipe = "│  "
⍝    tee = "├──"
⍝    blank = "   "
⍝    print(header + (elbow if last else tee) + p.name  )
⍝    if p.is_dir():
⍝        children = list(p.iterdir())
⍝        for i, c in enumerate(children):
⍝            print_tree(c, 
⍝                 header=header + (blank if last else pipe), 
⍝                 last=i == len(children) - 1
⍝            )

~⎕NEXISTS ⍵: 11 ⎕SIGNAL⍨'DOMAIN ERROR: Invalid or non-existent file or directory'

    GetKids←    { ⊃0 ⎕NINFO⍠1⊢ ⍵,'/*' }
    IsDir←      { ~⎕NEXISTS ⍵: 0 ⋄ 1=1 ⎕NINFO ⍵ }
    Name←       { ⊃,/1↓ ⎕NPARTS ⍵ }
    empty←      ⊂'∅ (empty)'           
    EmptyChk←   empty∘{ ⍵ ⍺ ⊃⍨ 0=≢⍵ }    ⍝ Empty Directory?
    Sort←       ⊂∘⍋⌷⊢
  ⍝ Prefix       not_last  last
    MyPfx←     ⊃∘'├──'    '└──' 
    ParentPfx← ⊃∘'│  '    '   '       

    Traverse← { path last hdr← ⍵  
        ⎕← hdr, (MyPfx last), Name path 
      ~IsDir path: _← 0  
        hdr,←  ParentPfx last 
        kids←  EmptyChk Sort GetKids path 
        lastV← 1↑⍨ -≢kids           ⍝ vector of 0s, except 1 for last kid
        lastV { Traverse ⍵ ⍺ hdr }¨ kids       
    } 
    Traverse ⍵ 1 '' 
}
