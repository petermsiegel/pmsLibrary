DirTree← { 
⍝ DirTree dirName
⍝         dirName: string containing a single directory (or file) name.
⍝ Recursively prints the directory and its contents.
⍝ Returns: a shy counter of the # of items it has printed (dirs and files).
⍝ *** Based on unattributed Python original (often: print_tree.py) ***

~⎕NEXISTS ⍕⍵: 11 ⎕SIGNAL⍨'DOMAIN ERROR: Invalid or non-existent file or directory'

    ø←          '∅ (empty)'                       ⍝ What we show for empty dirs    
    GetKids←    { ⊃0 ⎕NINFO⍠1⊢ ⍵,'/*' }           ⍝ List items in dir ⍵
    IsDir←      1= 1∘⎕NINFO                       ⍝ 1 if ⍵ is a file, else 0
    MyPfx←      ⊃∘'├──'  '└──'                    ⍝ Sel rt string if I'm last, else left
    Name←       ⊃ (,/ 1∘↓⍤ ⎕NPARTS)               ⍝ ⍵ without any directory prefixes
    ParentPfx←  ⊃∘'│  '  '   '                    ⍝ Sel rt string if parent is last, else left.        
    Sort←       ⊂∘⍋ ⌷⊢                            ⍝ Sort list of dirs/files

    Traverse← { item last hdr← ⍵                  ⍝ item: A dir or file
        ⎕← hdr, (MyPfx last), Name item           ⍝ Print my tree pos'n and name
      ~IsDir item: 1                              ⍝ Not a dir? Return 1 (for "1 file")                         
        kids←  Sort GetKids item                  ⍝ Sort kids in alph. order
        hdr,←  ParentPfx last                     ⍝ Prefix to hdr for ALL descendants
      0=≢kids: 2⊣ ⎕← hdr, ø,⍨ MyPfx 1             ⍝ Empty dir!
        lastV← 1↑⍨ -≢kids                         ⍝ vector of 0s, except 1 for last kid
      ⍝ Visit each child dir or file in turn, recursing dirs all the way down
      ⍝ Dir: Return 1 (for this dir) + recursively, 1 for each dir/file this dir contains
        1+ +/ lastV { Traverse ⍵ ⍺ hdr }¨ kids   
    } 
    1: _← Traverse ⍵ 1 '' 
}
