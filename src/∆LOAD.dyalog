∆LOAD←{

⍝H Loads a file, processing macro statements, which may emit code as part of the resulting object.  
⍝H Once the macros are processed, the object is fixed using 2 ⎕FIX.
⍝H
⍝H       objNames← [stmts] ∆LOAD [//FILE:fileName | fileLns]
⍝H                 stmts:    0 or more macros (w/o the ⍝MACRO prefix) to execute as if part of the file <fileName>.
⍝H                 fileName: A char vector containing a valid host filename. 
⍝H                           ∆LOAD first searches for fileName, then fileName.dyalog.
⍝H                 fileLns:  A vector of char. vectors containing the lines of an object to process.
⍝H Returns <objNames>, the name of the object(s) fixed, if successful. Otherwise an error is thrown.
⍝H 
⍝H Key variables are loaded in the left argument via macro statmeent 
⍝h     '::DEF fred' '::SET jack ⍳2' ...
⍝H The file loaded (via fileName) is scanned for directive stmts of the form
⍝H     ⍝   ::directive   
⍝H OR
⍝H    ::directive              
⍝H The leading comment symbol and/or spaces are ignored in execution.
⍝H
⍝H Directives include (case is ignored):
⍝H    ::IFDEF   nm    ⋄   stmts  - Executes stmts if nm is defined (the value is ignored).
⍝H    ::IF      value ⋄   stmts  - Executes stmts if value is true (scalar 1).
⍝H                               - If value causes an error, a msg is issued, but it is treated as false.
⍝H    ::IFNDEF  nm    ⋄   stmts  - Executes stmts if nm is undefined.
⍝H    ::DEF     nm               - Sets nm to the null string (not APL code '', ⍬, or ⎕NULL).
⍝H                                 Any <nm> in the program will effectively be removed.
⍝H    ::DEF     nm        value  - Sets nm to value <value>. Any <nm> in the program will be replaced by value.
⍝H                                 If correct execution requires parentheses, value must include them.
⍝H    ::DEF     nm        ::SKIP - If nm appears anywhere on a line of text, the ENTIRE line
⍝H                                 will be removed from output.
⍝H                                 To turn off ::SKIP behavior, reset nm, e.g. via ::DEF or ::UNDEF.
⍝H    ::DEFE    nm        value  - Sets nm to the result of EXECUTING ⍎value at "compile" time.
⍝H                                 That value is placed within parentheses: (⍳2) if value is ⍳2.
⍝H                                 If ⍎value causes an error, an error signal is generated. 
⍝H    ::DEFLE   nm        value  - Like ::DEFE, but does not add parentheses. Caveat programmer.
⍝H    ::UNDEF   nm               - Removes any value associated with nm during macro processing.
⍝H                               - If nm is seen in the text, it will remain as is (the literal string nm).
⍝H    ::INCLUDE [str | "str" | 'str']              
⍝H                               - Reads in the lines of the object specified in string (leading/trailing blanks omitted),
⍝H                                 and formatting in the current ∆LOAD context.
⍝H                               - str: [ //FILE:nm | nm ] 
⍝H                                   the first, interpreted either as <nm> or <nm.dyalog>.
⍝H                                   the second, the (possibly compound) name of an APL obj in the ws:
⍝H                                   ∘ a fn (whose def is to be copied in), or
⍝H                                   ∘ a char object: a vector of char vectors, or a char matrix. 
⍝H                                 E.g. //FILE:../test1, ##.MyFn, myCharMx.     
⍝H    ::ONCE                     - If anywhere inside an included object and executed, 
⍝H                                 the object will be included exactly once.
⍝H    ::SKIP                     - If ::SKIP appears anywhere on a line OUTSIDE quotes or (non-leading) comments,
⍝H                                 the entire line will be removed from output.
⍝H    ::COMMENTS [ON | OFF]      - If OFF, APL comments will be removed from subsequent statements.
⍝H                                 To remove from ALL statements on the fly, specify
⍝H                                 '::COMMENTS OFF' ∆LOAD ...
⍝H 
⍝H stmts: include APL expressions or directives:
⍝H      ∘ APL Expressions will be scanned, macros in expressions will be recursively scanned and 
⍝H        replaced with their values, and included in the output text (including ⋄ separators).
⍝H      ∘ Directives will be executed.
⍝H      ∘ Comments are allowed and ignored.
⍝H nm:    is a single simple APL variable name (no prefixes or dots).
⍝H Leading comments:
⍝H        A directivea may be preceded by a comment lamp (⍝). This is ignored on ∆LOAD processing.
⍝H        All other comment lamps are treated as ordinary comments (and either ignored or, 
⍝H        if part of an APL statement), passed through unchanged.
⍝H
⍝H Example 1
⍝H    In file <myfile> you have these statements.
⍝H      ⍝ ::IFDEF  N ⋄ ::DEF SELECT N↓      - SELECT will be the text 2↓
⍝H      ⍝ ::IFNDEF N ⋄ ::DEF SELECT         - Since N is defined, this statement is ignored.
⍝H Example 1a
⍝H    Here, N will be evaluated at "compile" time, e.g. as 2.
⍝H      '::DEFE  N (?5)' ∆LOAD myfile     
⍝H    So the above statements will produce:
⍝H      ::DEF SELECT 2↓
⍝H    So any statement wth <SELECT> will have SELECT replaced by 2↓.
⍝H    E.g.   
⍝H          ⎕← SELECT ⍳5
⍝H    will appear as
⍝H          ⎕← 2↓⍳5
⍝H    and will print (⎕IO=0)
⍝H          2 3 4 
⍝H Example 1b
⍝H    Here, we don't define N. 
⍝H       ∆LOAD myfile
⍝H    So the above statements (at Example 1) will produce
⍝H       ::DEF SELECT 
⍝H    I.e. SELECT is defined (not undefined) to be an empty string.
⍝H    So,
⍝H       ⎕← SELECT ⍳5
⍝H    will appear as:
⍝H       ⎕← ⍳5
⍝H    i.e. will print
⍝H       0 1 2 3 4
⍝H 
⍝H  Example 2
⍝H    Here we have lines of code we might want executed...
⍝H    So, we have DEBUG stmts, which execute ONLY if DEBUG is set.
⍝H       ::IFDEF DEBUG ⋄ EnsureValid←{ ... }   ⍝ We are checking that everything is ok!
⍝H       ::IFDEF DEBUG ⋄ ⎕← 'In debugging' ⋄ EnsureValid myargs 
⍝H    These statements will be omitted (ignored) if DEBUG is not set, but included as 
⍝H       EnsureValid←{ ... }   ⍝ We are checking that everything is ok!
⍝H       ⎕← 'In debugging' ⋄ EnsureValid myargs 
⍝H    if we call ∆LOAD this way:
⍝H       '::DEF DEBUG' ∆LOAD myfile
⍝H  Example 2a
⍝H    If we want EnsureValid to be defined over multiple lines, you could do:
⍝H      ::IFDEF DEBUG ⋄ EnsureValid←{ 
⍝H      ::IFDEF DEBUG ⋄     do something
⍝H      ::IFDEF DEBUG ⋄     some more
⍝H      ::IFDEF DEBUG ⋄ }
⍝H    Or even:
⍝H      ::IFNDEF DEBUG ⋄ ::DEF DC ::SKIP
⍝H      DC EnsureValid←{
⍝H      DC    do something
⍝H      DC    some more
⍝H      DC }  
⍝H  All lines containing the DC prefix will be skipped if DEBUG isn't set. 
⍝H  Otherwise (i.e. if DEBUG is defined), DC will be replaced by a null string.
   
   ⎕IO← 0 ⋄ ⎕ML← 1
⍝ "Globals"
  onmG←  ''                                       ⍝ name of current file/obj
  inG←   ⍬                                        ⍝ active input lines for current file/obj
  curG←  ⍬                                        ⍝ the current line being built
  utG←   ⍬                                        ⍝ output lines
  mdG←   ⎕NS '' ⋄ mdG.(k←v←⍬)                     ⍝ Macro dictionary
  odG←   ⎕NS '' ⋄ mdG.(k v←⍬)                     ⍝ Object-seen dictionary 
                                                  ⍝ v elem:  [0] have we seen it, 
                                                  ⍝          [1] does it have the ::ONCE pragma?
⍝ 
  sG←    ⍬                                        ⍝ The save stack (during recursive ::include's)
  
  HasPfx← { s← ⍺↓⍨ +/∧\' '=⍺ ⋄ l← ≢⍵ ⋄ (l↑s)≡⍵ }  ⍝ Returns 1 if ⍺ has the prefix ⍵ (ignoring leading blanks) 
  Err←   ⎕SIGNAL {⍺←11 ⋄ ⊂('EN' ⍺)('EM' ⍵)}

⍝ TinyDict
  TinyDict← {   
    ⍺← ⍬ ⋄ ⎕IO ⎕ML← 0 1 ⋄ ns← ⎕NS⍬ ⋄ ns.Default←⍺ ⋄ ns.(Keys Vals)← 2⍴⊆⍵ 
    ns.Get1←    { ⍺← Default ⋄ (≢Keys)> p← Keys⍳ ⊂⍵: p⊃ Vals ⋄ ⍺ }
    ns.Set1←    { ⍺←⊢ ⋄ k v← ⍺ ⍵ ⋄ (≢Keys)> p← Keys⍳ ⊂k: (p⊃ Vals)← v ⋄ (Keys Vals),∘⊂← k v}
    ns.HasKey←  { Keys∊⍨ ⊂⍵ }
    ns.Del1←    { ⍺← 0 ⋄ n← ≢Keys ⋄ n> p← Keys⍳ ⊂⍵:  _← 1⊣ (Keys Vals)/⍨← ⊂ 0@ p⊢ n⍴1 ⋄ ⍺: _←0 ⋄ ⎕SIGNAL 11 }
    ns.Do1←     { 0:: ⎕SIGNAL ⎕EN ⋄ 1: _←  ⍺ Set1 (Get1  ⍺)⍺⍺  ⍵ }
    ns.Cat1←    { 0:: ⎕SIGNAL ⎕EN ⋄ 1: _← ⍺⍺ Set1 (Get1 ⍺⍺),  ⊂⍵ }  
    _← ns.⎕FX¨ ('_←Clear' '_←0⊣ Keys←Vals←⍬')('_←Copy' '_←⎕NS ⎕THIS') 
    ns 
  }
   
  Stack←{
    ns← ⎕NS⍬ ⋄ ns.stack← ⍵
    ns.Push← { stack,← ⍵ }
    ns.Pop←  { (stack ↓⍨← -⍵)↑stack }
    ns
  }
  sG←        Stack ⍬
  sG.XPush←  {Push ⊂##.(objG inG curLG utG) }           ⍝ Pushes onto the stack sG: objG inG curLG utG 
  sG.XPop←   {##.(objG inG curLG utG)← Pop 1 }          ⍝ Pops  from  the stack sG: objG inG curLG utG 

  mdG←     TinyDict ⍬                             ⍝ Macro dictionary: default for a missing key k is k itself
  odG←  0 0∘TinyDict ⍬                            ⍝ Object-seen dictionary. Default is 0 0, where
                                                  ⍝   [0] 1= we've seen this object before.
                                                  ⍝   [1] 1= this obj has a ::ONCE pragma (i.e. don't reload it).

   LoadObj←{
     0::11 Err'Invalid object: ',⍵
     obj←⊆⍵
     1<≢obj:obj ⋄ nm←⊃obj
     nm HasPfx'//FILE:':...
     0≥nc←⎕NC nm:11 Err'Object not found: ',nm
     2=nc:{2=⍴⍴⍵:↓⍵ ⋄ 1=⍴⍴⍵:⍵ ⋄ ∘∘∘}⎕OR nm
     3=nc:⎕NR nm
     9=nc:⎕SRC⍎nm
     ∘∘∘
  }
  objG← ''
  inG←  LoadObj objG
}
