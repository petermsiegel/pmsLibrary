DirTree← { 
⍝ [count] DirTree dirName
⍝         dirName: string containing a single directory (or file) name.
⍝ Recursively prints the directory and its contents.
⍝ Returns: a shy count of the # of entries it has printed (dirs and files).
⍝ Modification: Shows empty directories. 
⍝   Here, testD is an empty dir, but Fun.dyalog is a file (no descendants)  
⍝       DirTree './testD'            DirTree './Fun.dyalog'  
⍝    └──testD                     └──Fun.dyalog
⍝       └──∅ (empty)
⍝ *** Based on unattributed Python or C original (print_tree.py, ~.c) ***

  ~⎕NEXISTS ⍕⍵: 11 ⎕SIGNAL⍨'DOMAIN ERROR: Invalid or non-existent file or directory'

    IsDir←  1= 1∘⎕NINFO                      ⍝ Is ⍵ a directory?
    Kids←   (⊂∘⍋⍤⌷⊢∘(⊃0⊢⎕NINFO⍠1) ,∘'/*'),  ⍝ List entries in dir ⍵ in sorted order
    MyPfx←  ⊃∘'├──'  '└──'                   ⍝ Pfx based on whether ⍵ is last on its branch.
    Nm←   ⊃ (,/ 1∘↓⍤ ⎕NPARTS)                ⍝ Name of ⍵ without any directory prefixes
    PaPfx←  ⊃∘'│  '  '   '                   ⍝ Pfx based on whether parent node is last on its branch.
    nullD←  '∅ (empty)',⍨ MyPfx 1            ⍝ Constant we show for empty dir contents   

  ⍝ Traverse the file system from <entry>, depth first, left to right, in sorted order,
  ⍝ printing a line for each entry showing its position in the tree.
  ⍝ Syntax: count← last (hdr Traverse) file 
  ⍝    last:  Is this dir/file <file> the last (1) entry in this branch or not (0)? 
  ⍝     hdr:  the cumulative header string at this depth
  ⍝     file:  string referring to a dir or file in relative or absolute form 
  ⍝ Returns: count, the # of entries seen (1 for "contents" of empty directory)

    Traverse← {  
        last hdr file← ⍺ ⍺⍺ ⍵                   ⍝ last (bool), hdr (str), file (dir/file str)
        ⎕← hdr, (MyPfx last), Nm⍣(×≢hdr)⊢ file  ⍝ Print my tree pos'n and short name (except at root)  
      ~IsDir file: 1                            ⍝ Not a dir? Return count of 1 (file)                     
        kids←  Kids file                        ⍝ Acquire and sort descendants in alph. order
        hdr,←  PaPfx last                      ⍝ Parent's tree pos'n for each descendant
      0=≢kids: 2⊣ ⎕← hdr, nullD                ⍝ No kids? Parent is an empty dir!
        lastV← 1↑⍨ -≢kids                      ⍝ vector of 0s, except 1 for last kid
        1+ +/ lastV (hdr ∇∇)¨ kids             ⍝ Visit (and count) each kid in turn
    } 
    1 (''Traverse) ⍵ 
 }
