DirTree← { 
⍝ DirTree dirName
⍝         dirName: string containing a single directory (or file) name.
⍝ Recursively prints the directory and its contents.
⍝ Returns: a shy counter of the # of entries it has printed (dirs and files).
⍝ Modification: Shows empty directories. 
⍝   Here, testD is an empty dir, but Fun.dyalog is a file (no descendants)  
⍝       DirTree './testD'            DirTree './Fun.dyalog'  
⍝    └──testD                     └──Fun.dyalog
⍝       └──∅ (empty)
⍝ *** Based on unattributed Python or C original (print_tree.py, ~.c) ***

  ~⎕NEXISTS ⍕⍵: 11 ⎕SIGNAL⍨'DOMAIN ERROR: Invalid or non-existent file or directory'

    IsDir←  1= 1∘⎕NINFO                        ⍝ 1 if ⍵ is a file, else 0
    KidsOf← ⊂∘⍋⍤⌷⊢∘ ( ⊃0 ⊢ ⎕NINFO⍠1 ) ,∘'/*'  ⍝ List entries in dir ⍵ in sorted order
    MyPos←  ⊃∘'├──'  '└──'                     ⍝ Pfx based on whether I'm last on my branch.
    Name←   ⊃ (,/ 1∘↓⍤ ⎕NPARTS)                ⍝ ⍵ without any directory prefixes
    ParPos← ⊃∘'│  '  '   '                     ⍝ Pfx based on whether parent is last on its branch.
    empty←  '∅ (empty)',⍨ MyPos 1              ⍝ Constant we show for empty dir contents   

  ⍝ Traverse the file system from <entry>, depth first, left to right, in sorted order,
  ⍝ printing a line for each entry showing its position in the tree.
  ⍝ Syntax: count← last (hdr Traverse) entry  
  ⍝    last:  Is this dir/file, <entry>, the last (1) entry in this branch or not (0)? 
  ⍝     hdr:  the cumulative header string at this depth
  ⍝   entry:  string referring to a dir or file in relative or absolute form 
  ⍝ Returns: count, the # of entries seen (1 for "contents" of empty directory)
    Traverse← { last hdr entry← ⍺ ⍺⍺ ⍵ 
        ⎕← hdr, (MyPos last), Name⍣(×≢hdr)⊢ entry  ⍝ Print my tree pos'n and name
      ~IsDir entry: 1                              ⍝ Not a dir? Return 1 (for "1 file")                         
        kids←  KidsOf entry                        ⍝ Sort descendants in alph. order
        hdr,←  ParPos last                         ⍝ Parent's tree pos'n for each descendant
      0=≢kids: 2⊣ ⎕← hdr, empty                    ⍝ No kids? Parent is an empty dir!
        kLast← 1↑⍨ -≢kids                          ⍝ vector of 0s, except 1 for last kid
        1+ +/ kLast (hdr ∇∇)¨ kids                 ⍝ Visit (and count) each kid in turn
    } 
  1: 1 ('' Traverse) ,⍵   
}
