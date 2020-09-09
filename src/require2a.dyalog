 rc←{opts}require2 specs
 ;Err;ScanTokens         ⍝ Fns, Ops
 ;DEBUG;SEP              ⍝ Constants
 ;matchP;tokens          ⍝ Vars
 ;⎕IO;⎕TRAP              ⍝ Sys


 ⍝ specs:         spec1 [ ⋄ spec2  [ ⋄ spec3 ... ] ]
 ⍝   specN:       name options
 ⍝     name:      name of APL object-- may include ⎕SE or #
 ⍝     options:   from dir | as objName
 ⍝                - Up to two options may appear in any order, case is ignored.
 ⍝ ------
 ⍝ Note 1: Each item must be a valid name w/o blanks or be placed in quotes (single or double).
 ⍝         - Names, directories, and (as) objects (name, dir, objName) need not be quoted
 ⍝           unless they include blanks
 ⍝ Note 2: An APL statement separator ⋄ must separate each specification from the next.
 ⍝         It may not appear in identifiers, even if quoted...

 ⎕IO←0 ⋄ DEBUG←1 ⋄ SEP←'⋄'
 ⎕TRAP←(~DEBUG)⍴⊂0 'C' 'Err ⎕DMX.(EM EN)'

⍝ ∆F:  Find a pcre field by name or field number
 ∆F←{
     N O B L←⍺.(Names Offsets Block Lengths)
     def←'' ⋄ isN←0≠⍬⍴0⍴⍵
     p←N⍳∘⊂⍣isN⊣⍵ ⋄ 0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def
     B[O[p]+⍳L[p]]
 }
 ⍝ ∆R: Replace names of the form ⍎XXX in a string with its executed value in the calling context (in string form)...
 ∆R←{⍺←10                                          ⍝ Recurse a max of <⍺> times.
    ⍺≤0:⍵                                         ⍝ Done?
    S←'⍎[\w∆⍙#⎕\.]+'⎕R{
      f0←⍵ ∆F 0 
      0:: 11 ⎕SIGNAL⍨ '∆R: Error evaluating ''',f0,'''' 
      ⍕(⍬⍴⎕RSI).⍎1↓f0}⍠('UCP' 1)⊣⍵
    ⍵≡S: S  ⋄ ~'⍎'∊S: S                           ⍝ No change or no ⍎? Done.
    (⍺-1)∇ S                                      ⍝ Possibly more.
 }

 Err←⎕SIGNAL/
 ScanTokens←{
     0=≢⍵:⍬
     RemQts←{'"'''∊⍨⊃⍵:1↓¯1↓⍵ ⋄ ⍵}
     0⍴⍨~DEBUG::Err ⎕DMX.(EM EN)
     getOpts←'from' 'as'∘{
         FROM AS←⍺
         f←a←⍬
         0=≢⍵:f a
         tokens←{  ⍝ Scan for up to 2 option pairs (consuming them)...
             2>≢⍵:⍵
             f∆ a∆←0≠≢¨f a ⋄ isF isA←FROM AS≡¨⊂⎕C 0⊃⍵
             isF⍱isA:Err('require: option "',(0⊃⍵),'" unknown.')11
             isF∧f∆:Err'require: option "from" duplicated.' 11
             isA∧a∆:Err'require: option "as" duplicated.' 11
             isF:(2↓⍵)⊣f⊢←FROM(RemQts 1⊃⍵)
             isA:(2↓⍵)⊣a⊢←AS(RemQts 1⊃⍵)
             ⍵
         }⍣(≢⍺)⊣⍵
         0≠≢tokens:Err('require: extra tokens found: "','".',⍨,1↓¯1↓,⎕FMT tokens)11
         f a
     }
     ⊂(⊃⍵)(getOpts 1↓⍵)  ⍝ Consume the object name and then pass options
 }

 tokP←'  ("[^"]+")+ | (?:''[^'']+'')+ | [^\h]+ '  ⍝ tok   (sub)pattern
 matchP←∆R'(?xxi) \h* (?<match> ⍎tokP) \h*'

⍝ Split on ⋄ as if separate <require> calls.
 tokens←{matchP ⎕R'\<match>\n'⊣⊆⍵}¨SEP(≠⊆⊢)specs
 rc←⊃,/ScanTokens¨⊆tokens
