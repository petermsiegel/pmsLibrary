 ∆WHERE←{
   ⍝ See documentation below.
     ⎕IO←0
     ⍺←0
     alphaE←'∆WHERE DOMAIN ERROR: '
     alphaE,←'⍺ may contain a ns ref and an int ∊ 0 1 2 0j1 1j1 2j1)'
     omegaE←'∆WHERE DOMAIN ERROR: ⍵ must contain 0 or more char vectors'

   ⍝  Collect options in any order. callNs is option in class 9, else the caller Ns.
     callNs format←{l r←9=⎕NC¨'LR'⊣L R←⍵ ⋄ l:L R ⋄ r:R L ⋄ (1⊃⎕RSI,#)L}2↑⍺,0
     names pathOnly format←format{
         2=⍴⍴⍵:(' '~⍨¨↓⍵)1(9○⍺)     ⍝ pathOnly is 1 if <⍵> is a matrix.
         (⊆⍵)(×11○⍺)(9○⍺)           ⍝ pathOnly is 1 if (11○format)>0
     }⍵
     ~callNs{0::0 ⋄ (9=⎕NC'⍺')∧⍵∊0 1 2}format:alphaE ⎕SIGNAL 11
     ~{0::0 ⋄ 1⊣⎕NC ⍵}names:omegaE ⎕SIGNAL 11

     _t1←1.1 1.2 1.3 0 ¯1
     _t2←'caller' 'path' 'elsewhere' 'not found' 'invalid'
     callT pathT elsewhereT notFoundT invalidT←(2=format)⊃_t1 _t2

   ⍝ Utils...
     ns2Refs←{top←,'#' ⋄ 9.1=⎕NC⊂,⍵:⍺⍎⍵ ⋄ ⎕SE # ⎕NULL⊃⍨'⎕SE'top⍳⊂⍵}¨
     scan4Objs←{
         pathType←⍺⍺
         0=≢⍺:⍬                   ⍝ exhausted search: not found (so far)
         nc←(ns←0⊃,⍺).⎕NC ⍵       ⍝ ,⍺ to handle scalar, e.g. <⍺: callNs>
         0>nc:⎕NULL invalidT      ⍝ terminate search!
         0<nc:ns pathType
         (1↓⍺)∇ ⍵
     }
   ⍝ refs: from dfns, Returns refs to all namespaces in the ws except skip those in ⍺
     refs←{⍺←⍬ ⋄ (≢⍺)↓⍺{⍵∊⍺:⍺ ⋄ ⍵.(↑∇∘⍎⍨/⌽(⊂⍺∪⍵),↓⎕NL 9)}⍵}

   ⍝ Ignore elements of ⎕PATH that aren't namespaces, ⎕SE or ⍵!
     pathNs←{⍵/⍨⎕NULL≠⍵}callNs ns2Refs(callNs.⎕PATH≠' ')⊆callNs.⎕PATH
   ⍝ elseNs: See scan4Objs. We calculate once only for names that need it...
     elseNs←⍬

   ⍝ Gather data on each name in ⍵
     data←{
       ⍝ Found in the caller?
         0≠≢val←callNs(callT scan4Objs)⍵:val
       ⍝ Found on the path?
         0≠≢val←pathNs(pathT scan4Objs)⍵:val
         pathOnly:⎕NULL notFoundT                    ⍝ Don't continue, if pathOnly set
       ⍝ Found in some othe namespace?
         elseNs⊢←{∊refs¨# ⎕SE}⍣(0=≢elseNs)⊣elseNs    ⍝ (refs is expensive. Calculate once only.)
         0≠≢val←elseNs(elsewhereT scan4Objs)⍵:val
       ⍝ Not found.
         ⎕NULL notFoundT
     }¨names
     format=0:⊃¨data
     format=1:data
     data,⍨∘⊂¨names

   ⍝H ∆WHERE:
   ⍝H
   ⍝H Returns a reference to the namespace in which object(s) ⍵ are found, else ⎕NULL
   ⍝H ⍵@VVC: 'name1' ['name2' ['name3'...]]   OR ⍵@MC: 'name1' ['name2' [...]]
   ⍝H     nameN:   the name of an APL object as a char. vector.
   ⍝H     If ⍵ has rank 2 OR  (see ⍺ below) format ∊ 0j1 1j1 2j1
   ⍝H          ∆WHERE searches caller namespace and path only (and no others).
   ⍝H     If ⍵ is vec of strings and format ∊ 0 1 2
   ⍝H          ∆WHERE searches all namespaces:
   ⍝H                  caller's, path, and all (other) namespaces
   ⍝H
   ⍝H ⍺: [call=(1⊃⎕RSI,#)] [format∊0 1 2=0 OR 0j1 1j1 2j1]]
   ⍝H    DEFAULT: (1⊃⎕RSI,#) 0, i.e. caller namespace is actual from which ∆WHERE called
   ⍝H                           and  return only the namespaces in which ⍵ is found.
   ⍝H    call:  the active namespace (default: the namespace called from).
   ⍝H           call.⎕PATH will be used to determine what namespaces are in the active ⎕PATH.
   ⍝H    format*:     2 →  type is a long-form alphabetic description
   ⍝H                 1 →  type is a short-form numeric descriptor (see below)
   ⍝H       DEFAULT   0 →  type is ignored
   ⍝H         * Real part...
   ⍝H    returning for each nameN
   ⍝H         nameN where typeAlph     (if format=2)
   ⍝H         where typeNum            (if format=1)
   ⍝H         where                    (if format=0)
   ⍝H    where
   ⍝H         name          the name we are looking for
   ⍝H         where         a reference to the namespace where found, else ⎕NULL (if ⍵ not found or invalid)
   ⍝H         type          If 1∊⍺, type1 (numeric) is used; if 2∊⍺, type2 (alphameric) is used.
   ⍝H            typeNum typeAlph
   ⍝H              1.1    caller       item found in caller's ns (actual or based on caller passed in ⍺)
   ⍝H              1.2    path         item found in ⎕PATH, but not caller's NS
   ⍝H              1.3    elsewhere    item found in ns outside caller NS and ⎕PATH
   ⍝H              0      notFound     item not found anywhere
   ⍝H             ¯1      invalid      item name is invalid (e.g. bare #, bare ⎕SE or ill-formed name)
   ⍝H Note: While all objects are searched for within ⎕PATH, only functions and operators are automatically
   ⍝H       found by APL without a namespace prefix. I.e. not necc. useful for namespaces or variable names.
 }
