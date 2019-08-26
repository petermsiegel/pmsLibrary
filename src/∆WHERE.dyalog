 ∆WHERE←{
   ⍝ Returns a reference to the namespace in which object(s) ⍵ are found, else ⎕NULL
   ⍝ ⍵@VVC: 'name1' ['name2' ['name3'...]]   OR ⍵@MC: 'name1' ['name2' [...]]
   ⍝     nameN:   the name of an APL object as a char. vector.
   ⍝     If ⍵ has rank 2 OR  (see ⍺ below) format ∊ 0j1 1j1 2j1
   ⍝          ∆WHERE searches caller namespace and path only (and no others).
   ⍝     If ⍵ is vec of strings and format ∊ 0 1 2
   ⍝          ∆WHERE searches all namespaces:
   ⍝                  caller's, path, and all (other) namespaces
   ⍝
   ⍝ ⍺: [call=(1⊃⎕RSI,#)] [format∊0 1 2=0 OR 0j1 1j1 2j1]]
   ⍝    DEFAULT: (1⊃⎕RSI,#) 0, i.e. caller namespace is actual from which ∆WHERE called
   ⍝                           and  return only the namespaces in which ⍵ is found.
   ⍝    call:  the active namespace (default: the namespace called from).
   ⍝           call.⎕PATH will be used to determine what namespaces are in the active ⎕PATH.
   ⍝    format*:     2 →  type is a long-form alphabetic description
   ⍝                 1 →  type is a short-form numeric descriptor (see below)
   ⍝       DEFAULT   0 →  type is ignored
   ⍝         * Real part...
   ⍝    returning for each nameN
   ⍝         nameN where typeAlph     (if format=2)
   ⍝         where typeNum            (if format=1)
   ⍝         where                    (if format=0)
   ⍝    where
   ⍝         name          the name we are looking for
   ⍝         where         a reference to the namespace where found, else ⎕NULL (if ⍵ not found or invalid)
   ⍝         type          If 1∊⍺, type1 (numeric) is used; if 2∊⍺, type2 (alphameric) is used.
   ⍝            typeNum typeAlph
   ⍝              1.1    caller       item found in caller's ns (actual or based on caller passed in ⍺)
   ⍝              1.2    path         item found in ⎕PATH, but not caller's NS
   ⍝              1.3    elsewhere    item found in ns outside caller NS and ⎕PATH
   ⍝              0      notFound     item not found anywhere
   ⍝             ¯1      invalid      item name is invalid (e.g. bare #, bare ⎕SE or ill-formed name)
   ⍝ Note: While all objects are searched for within ⎕PATH, only functions and operators are automatically
   ⍝       found by APL without a namespace prefix. I.e. not necc. useful for namespaces or variable names.
   ⍝
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
     data←callNs{
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
 }
