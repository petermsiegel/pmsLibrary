∆INCLUDE←{
⍝  lines@SV ← [spec=1] ∆INCLUDE files
⍝  Finds specified files fileN in directories named in FSPATH and WSPATH, starting with '.' and '..'.
⍝      files: file1 [file2 ... [fileN]]
⍝           - a single vector with files file1 ... fileN separated by blanks, or
⍝           - a vector of separate strings, file1 through fileN,
⍝      Each string must include any suffixes and appropriate prefixes (parent directories) to be prefixed
⍝      by (ie. found in) the parent directories per above.
⍝  spec=1 (default)
⍝      Returns lines found, as a vector of strings. Error if any not found.
⍝  spec=0
⍝      Returns full paths of files found. Error if any not found.
⍝  spec=¯1
⍝      Same as spec=0, but ⎕NULL for each file not found.
⍝  Errors
⍝    If files were not found, signals error number 22 and msg eNotFound below.
⍝    For other errors, signals 11 with various messages (below).
 
  ⍺←1
  ⎕IO ⎕ML←0 1
  
⍝ Get search path from FSPATH if present, else WSPATH. Always start with search path: '.' and '..'.
⍝ If pathss are repeated, only the first is used.
  setSearchPath←{⍺←,¨'.' '..'
      0=≢⍵: ⍺ ⋄ 0≠≢p←{2 ⎕NQ'.' 'GetEnvironment' ⍵}⊃⍵: ∪⍺,':'(≠⊆⊢)⊣p ⋄ ⍺ ∇ 1↓⍵
  } 
⍝ FindFirstFiles:  fullPaths ← searchPath FindFirstFiles files
⍝    Returns fullPaths where each file is found in searchPath, or ⎕NULL if not found.
  FindFirstFiles←{  ⍺←⍬
      0=≢⍺:  11 ⎕SIGNAL⍨ eNoPath
      0=≢⍵: ⎕NULL
      FindEach←⍺∘{0:: 11 ⎕SIGNAL⍨eUnexpected⊣⎕←'FindFirstFiles: ⍺' ⍺ ' ⍵' ⍵
          0=≢⍺: ⎕NULL                ⍝ Exhausted search
          full←(rel/'/',⍨⊃⍺),⍵ ⊣ rel←'/'≠1↑⍵  
          ⎕NEXISTS full: full 
        ⍝ Keep searching only if not absolute name      
          rel: (1↓⍺) ∇ ⍵ ⋄ ⎕NULL                  
      }
      FindEach¨⊆⍵
  }
  eNoPath←     '∆INCLUDE: No search directories were specified.'
  eUnexpected← '∆INCLUDE: Unexpected error evaluating filename.'
  eNoFiles←    '∆INCLUDE: No file(s) to include.'
  eNotFound←   '∆INCLUDE: At least one file to include was not found in search path:'

⍝ EXECUTIVE
  files←{1=≡⍵:  ' ' (≠⊆⊢)⍵ ⋄ ⍵ },⍵
       0=≢files:          11 ⎕SIGNAL⍨ eNoFiles
  searchPath←setSearchPath 'FSPATH' 'WSPATH'  
  filesFull←searchPath FindFirstFiles files   
⍺=¯1: filesFull
      ⎕NULL∊_←filesFull:  22 ⎕SIGNAL⍨ eNotFound,∊' ',¨files/⍨_∊⎕NULL

  ⍺=0: filesFull
⍝ Read each file, one APL char vector per line, and concatenate all vectors together
  1: _←⊃,/{⊃⎕NGET ⍵ 1}¨filesFull
}    