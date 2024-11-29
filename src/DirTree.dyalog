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
    GetKids←    (⊃0⊢⎕NINFO⍠1),∘'/*'               ⍝ List items in dir ⍵
    IsDir←      1= 1∘⎕NINFO                       ⍝ 1 if ⍵ is a file, else 0
    MyPfx←      ⊃∘'├──'  '└──'                    ⍝ Am I last or not?
    Name←       ⊃ (,/ 1∘↓⍤ ⎕NPARTS)               ⍝ ⍵ without any directory prefixes
    TheirPfx←   ⊃∘'│  '  '   '                    ⍝ Is the parent dir last or not?
    Sort←       ⊂∘⍋ ⌷⊢                            ⍝ Sort list of dirs/files
    empty←      '∅ (empty)',⍨ MyPfx 1             ⍝ What we show for empty dirs   

  ⍝ Traverse the directory depth first, left to right, in sorted order.
  ⍝ count← Traverse item last hdr
  ⍝    item: a dir or file string 
  ⍝    last: is <item> last (1) or not (0) element in the directory? 
  ⍝    hdr:  the cumulative header string at this depth
  ⍝    Returns count, the # of items seen (1 for contents of empty directory)
    Traverse← { item last hdr← ⍵                  
        ⎕← hdr, (MyPfx last), Name item           ⍝ Print my tree pos'n and name
      ~IsDir item: 1                              ⍝ Not a dir? Return 1 (for "1 file")                         
        kids←  Sort GetKids item                  ⍝ Sort descendants in alph. order
        hdr,←  TheirPfx last                      ⍝ Prefix for each descendant
      0=≢kids: 2⊣ ⎕← hdr, empty                   ⍝ Parent is empty dir!
        lastV← 1↑⍨ -≢kids                         ⍝ vector of 0s, except 1 for last kid
      ⍝ Visit each child dir or file in turn, recursing dirs all the way down
      ⍝ Dir: Return 1 (for this dir) + recursively, 1 for each dir/file this dir contains
        1+ +/ lastV { Traverse ⍵ ⍺ hdr }¨ kids   
    } 
  1: _← Traverse ⍵ 1 '' 
}
