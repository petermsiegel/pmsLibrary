∆INCLUDE←{ ⍝ ::INCLUDE '∆INCLUDE.dyalog'
  ⍝  lines@SV ← [spec=1] ∆INCLUDE files
  ⍝  Finds specified files fileN in directories named in FSPATH and WSPATH, starting with '.' and '..'.
  ⍝      files: file1 [file2 ... [fileN]]
  ⍝           - a single vector with files file1 ... fileN separated by blanks, or
  ⍝           - a vector of separate strings, file1 through fileN,
  ⍝      Each string must include any suffixes and appropriate prefixes (parent directories) to be prefixed
  ⍝      by (ie. found in) the parent directories per above.
  ⍝  spec=¯1
  ⍝      Same as spec=0, but ⎕NULL for each file not found.
  ⍝  spec=0
  ⍝      Returns full paths of files found. Error if any file not found.
  ⍝  spec=1 (default)
  ⍝      Returns lines from files as a vector of string vectors (no LFs or CRs). Error if any file not found.
  ⍝  spec='N' <Newlines, i.e. linefeeds> 
  ⍝      Returns lines from files found as a vector of strings separated by LFs (⎕UCS 10). Error if any file not found.
  ⍝  spec='R' <carriage Returns>
  ⍝      Returns lines from files found as a vector of strings separated by CRs (⎕UCS 13). Error if any file not found.
  ⍝  Errors
  ⍝    If files were not found and spec≠¯1, signals error number 22 and msg eNotFound below.
  ⍝    For other errors, signals 11 with various messages (below).
    ⍺←1
    ⎕IO ⎕ML←0 1 ⋄ CR LF←⎕UCS 13 10
    FIRST_DIRS←'.' '..'
  ⍝ Get search path from FSPATH if present, else WSPATH. Always start with search path: '.' and '..'.
  ⍝ If paths are repeated, only the first is used.
    setSearchPath←{⍺←FIRST_DIRS ⋄ first←,¨⊆⍺ 
        0=≢⍵: first ⋄ 0≠≢p←{2 ⎕NQ'.' 'GetEnvironment' ⍵}⊃⍵: ∪first,':'(≠⊆⊢)⊣p ⋄ first∇ 1↓⍵
    } 
  ⍝ FindFirstFiles:  fullPaths ← searchPath FindFirstFiles files
  ⍝    Returns fullPaths where each file is found in searchPath, or ⎕NULL if not found.
    FindFirstFiles←{ ⍺←⍬
        0=≢⍺:  11 ⎕SIGNAL⍨ eNoPath
        0=≢⍵: ⎕NULL
        FindEach←⍺∘{0:: 11 ⎕SIGNAL⍨eUnexpected⊣⎕←'FindFirstFiles: ⍺' ⍺ ' ⍵' ⍵
            0=≢⍺: ⎕NULL                                 ⍝ Exhausted search
            full←(rel/'/',⍨⊃⍺),⍵ ⊣ rel←'/'≠1↑⍵  
            ⎕NEXISTS full: full 
            rel: (1↓⍺) ∇ ⍵ ⋄ ⎕NULL                      ⍝ Keep searching only if not absolute name                    
        }
        FindEach¨⊆⍵
    }
    eBadSpecs←   '∆INCLUDE: Specification (⍺) must be ∊ ¯1 0 1 ''N'' ''R''; default: 1'
    eNoPath←     '∆INCLUDE: No search directories were specified [LOGIC ERROR].'
    eUnexpected← '∆INCLUDE: Unexpected error evaluating filename.'
    eNoFiles←    '∆INCLUDE: No file(s) to include.'
    eNotFound←   '∆INCLUDE: At least one file to include was not found in search path:'
  ⍝ ∆INCLUDE EXECUTIVE
    1≠≢⍺: 11 ⎕SIGNAL⍨eBadSpecs
    'N' 'R' ¯1 0 1(~∊⍨),⍺: 11 ⎕SIGNAL⍨eBadSpecs
    files←{1=≡⍵:  ' ' (≠⊆⊢)⍵ ⋄ ⍵ },⍵
    0=≢files:          11 ⎕SIGNAL⍨ eNoFiles
    searchPath←setSearchPath 'FSPATH' 'WSPATH'  
    filesFull←searchPath FindFirstFiles files 
  ⍝ ¯1: Return full paths of files found. Missing => ⎕NULL  
    ⍺=¯1: filesFull
    ⎕NULL∊_←filesFull:  22 ⎕SIGNAL⍨ eNotFound,∊' ',¨files/⍨_∊⎕NULL
  ⍝ 0: Return full paths for each file. Missing => Err
    ⍺=0:  filesFull
  ⍝ 1: Return contents of all file s found as a continuous vector of string vectors,  Missing => Err.
    ⍺=1:  lines←⊃,/{⊃⎕NGET ⍵ 1}¨filesFull
  ⍝ Read each file as a single string with NLs as linends, concatenating all strings together. Missing => Err
    lines←⊃,/{⊃⎕NGET ⍵ 0}¨filesFull
  ⍝ 'N': Return single string with NLs as linends. Missing => Err
    ⍺='N': _←lines
  ⍝ 'R': Like ⍺='N', but convert LFs to CRs.
    ⍺='R': _←CR@(LF∘=)⊢lines
} 
