 ∆WHERE←{
   ⍝ Returns a reference to the namespace in which object(s) ⍵ are found, else ⎕NULL
   ⍝ ⍺: [caller [longForm∊0 1=0]]
   ⍝    caller:  the active namespace (default: the caller namespace).
   ⍝             caller.⎕PATH will be used to determine what namespaces are in the active ⎕PATH.
   ⍝    longForm:     1 if type is a long-form alphabetic description
   ⍝                  0 if type is a short-form numeric descriptor (see below)
   ⍝    returning
   ⍝         name where type1     (if longForm=1)
   ⍝         where type2          (if longForm=0)
   ⍝    where
   ⍝         name          the name we are looking for
   ⍝         where         a reference to the namespace where found, else ⎕NULL (if ⍵ not found or invalid)
   ⍝         type1         either a number (type1) or string (type2), depending on longForm (0 or 1)
   ⍝              type1 type2
   ⍝              1.1   caller       item in caller (or other reference) NS (default: caller ns)
   ⍝              1.2   path         item in ⎕PATH, but not current NS
   ⍝              1.3   elsewhere    item found outside current NS and ⎕PATH
   ⍝              0     notFound     item not found
   ⍝             ¯1     invalid       name is invalid
   ⍝ While all objects are searched within ⎕PATH, only functions and operators are automatically
   ⍝ found by APL without a namespace prefix.
   ⍝
     ⎕IO←0 ⋄ ⍺←0
   ⍝ caller namespace; longform flag (∊ 1 0)
     callerNs longFormF←{L R←⍵ ⋄ l r←9=⎕NC¨'LR' ⋄ l:L R ⋄ r:R L ⋄ (0⊃⎕RSI),L}2↑⍺,0
     types←(1.1 'caller')(1.2 'path')(1.3 'elsewhere')(0 'not found')(¯1 'invalid')
     callerT pathT elsewhereT notFoundT invalidT←longFormF⊃¨types

     names←⊆⍵

   ⍝ Utils...
     ns2Refs←{9.1=⍺.⎕NC⊂,⍵:⍺⍎⍵ ⋄ '⎕SE' '#'∊⍨⊂⍵:⍎⍵ ⋄ ⎕NULL}¨
     scan4Objs←{pathType←⍺⍺
         0=≢⍺:⎕NULL notFoundT
         nc←(ns←0⊃,⍺).⎕NC ⍵       ⍝ ,⍺ to handle scalar, e.g. <⍺: callerNs>
         0>nc:⎕NULL invalidT
         0<nc:ns pathType
         (1↓⍺)∇ ⍵
     }
   ⍝ refs: from dfns, Returns refs to all namespaces in the ws except those in ⍺:skip
     refs←{                              ⍝ Vector of sub-space references for ⍵.
         ⍺←⍬ ⋄ (≢⍺)↓⍺{                   ⍝ default exclusion list.
             ⍵∊⍺:⍺                       ⍝ already been here: quit.
             ⍵.(↑∇∘⍎⍨/⌽(⊂⍺∪⍵),↓⎕NL 9)    ⍝ recursively traverse any sub-spaces.
         }⍵                              ⍝ for given starting ref.
     }

   ⍝ Ignore elements of ⎕PATH that aren't namespaces, ⎕SE or ⍵!
     pathNs←{⍵/⍨⎕NULL≠⍵}callerNs ns2Refs(callerNs.⎕PATH≠' ')⊆callerNs.⎕PATH
   ⍝ elseNs: Gather all other namespaces. To allow the children 
   ⍝         of #, ⎕SE, callerNs, and pathNs, these ns's are not suppressed here.
     elseNs←∊refs¨# ⎕SE

   ⍝ Gather data on each name in ⍵
     data←callerNs{
         ⎕NULL≠⊃val2←callerNs(callerT scan4Objs)⍵:val2   ⍝ the caller
         ⎕NULL≠⊃val2←pathNs(pathT scan4Objs)⍵:val2       ⍝ the path
         ⎕NULL≠⊃val2←elseNs(elsewhereT scan4Objs)⍵:val2  ⍝ all other namespaces
         ⎕NULL notFoundT
     }¨names
     ~longFormF:data
     data,⍨∘⊂¨names

⍝∇⍣§./∆WHERE.dyalog§0§ 2019 6 21 16 3 45 650 §ôûHuw§0
 }
