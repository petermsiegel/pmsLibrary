DirTree← { 
⍝ DirTree dirName
⍝         dirName: string containing a single directory (or file) name.
⍝ Recursively prints the directory and its contents.
⍝ Returns: a shy counter of the # of items it has printed (dirs and files).
⍝ Modification: Shows empty directories. 
⍝   Here, testD is an empty dir, but Fun.dyalog is a file (no descendants)  
⍝       DirTree './testD'            DirTree './Fun.dyalog'  
⍝    └──testD                     └──Fun.dyalog
⍝       └──∅ (empty)
⍝ *** Based on unattributed Python or C original (print_tree.py, ~.c) ***

  ~⎕NEXISTS ⍕⍵: 11 ⎕SIGNAL⍨'DOMAIN ERROR: Invalid or non-existent file or directory'

    IsDir←  1= 1∘⎕NINFO                        ⍝ 1 if ⍵ is a file, else 0
    KidsOf← ⊂∘⍋⍤⌷⊢∘ ( ⊃0 ⊢ ⎕NINFO⍠1 ) ,∘'/*'   ⍝ List items in dir ⍵ in sorted order
    MyPfx←  ⊃∘'├──'  '└──'                     ⍝ Am I the last on my branch or not?
    Name←   ⊃ (,/ 1∘↓⍤ ⎕NPARTS)                ⍝ ⍵ without any directory prefixes
    ParPfx← ⊃∘'│  '  '   '                     ⍝ Is the parent dir the last or not?

    empty←  '∅ (empty)',⍨ MyPfx 1              ⍝ What we show for empty dirs   

  ⍝ Traverse the directory depth first, left to right, in sorted order.
  ⍝ count← Visit this last hdr
  ⍝    this: a dir/file string 
  ⍝    last: Is this dir/file, <this>, the last (1) item in the directory or not (0)? 
  ⍝    hdr:  the cumulative header string at this depth
  ⍝   ntop:  1, except for very top-most node
  ⍝    Returns count, the # of items seen (1 for "contents" of empty directory)
    Visit← { hdr last this ntop← ⍺⍺ ⍺ ⍵ ⍵⍵                
        ⎕← hdr, (MyPfx last), Name⍣ntop⊢ this     ⍝ Print my tree pos'n and name
      ~IsDir this: 1                              ⍝ Not a dir? Return 1 (for "1 file")                         
        kids←  KidsOf this                        ⍝ Sort descendants in alph. order
        hdr,←  ParPfx last                        ⍝ Parent's prefix for each descendant
      0=≢kids: 2⊣ ⎕← hdr, empty                   ⍝ Parent is an empty dir!
        kLast← 1↑⍨ -≢kids                         ⍝ vector of 0s, except 1 for last kid
      ⍝ Visit and count each child dir/file in turn, recursing dirs all the way down
        1+ +/ kLast (hdr ∇∇ 1)¨ kids   
    } 
  1: _← 1 ('' Visit 0) ,⍵   
}
