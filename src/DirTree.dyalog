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

    IsD←    1= 1∘⎕NINFO                        ⍝ Is ⍵ a directory?
    Kids←   (⊂∘⍋⍤⌷⊢∘(⊃0⊢⎕NINFO⍠1) ,∘'/*'),     ⍝ List entries in dir ⍵ in sorted order
    MyPfx←  ⊃∘'├──'  '└──'                     ⍝ Pfx based on whether I'm last on my branch.
    Nm←   ⊃ (,/ 1∘↓⍤ ⎕NPARTS)                  ⍝ Name of ⍵ without any directory prefixes
    PaPfx←  ⊃∘'│  '  '   '                     ⍝ Pfx based on whether parent is last on its branch.
    nullD←  '∅ (empty)',⍨ MyPfx 1              ⍝ Constant we show for empty dir contents   

  ⍝ Traverse the file system from <entry>, depth first, left to right, in sorted order,
  ⍝ printing a line for each entry showing its position in the tree.
  ⍝ Syntax: count← last (hdr Traverse) entry  
  ⍝    last:  Is this dir/file, <entry>, the last (1) entry in this branch or not (0)? 
  ⍝     hdr:  the cumulative header string at this depth
  ⍝   entry:  string referring to a dir or file in relative or absolute form 
  ⍝ Returns: count, the # of entries seen (1 for "contents" of empty directory)

    Traverse← {  
        l h e← ⍺ ⍺⍺ ⍵                    ⍝ last (flag), header (str), entry (dir/file)
        ⎕← h, (MyPfx l), Nm⍣(×≢h)⊢ e     ⍝ Print my tree pos'n and short name (except at root)  
      ~IsD e: 1                          ⍝ Not a dir? Return count of 1 (file)                     
        k←   Kids e                      ⍝ Sort descendants in alph. order
        h,←  PaPfx l                     ⍝ Parent's tree pos'n for each descendant
      0=≢k: 2⊣ ⎕← h, nullD               ⍝ No kids? Parent is an empty dir!
        kV← 1↑⍨ -≢k                      ⍝ vector of 0s, except 1 for l kid
        1+ +/ kV (h ∇∇)¨ k               ⍝ Visit (and count) each kid in turn
    } 

    1 (''Traverse) ⍵ 

 }
