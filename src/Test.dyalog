 arrV←{base}Test arrV;top0;top1        ⍝ Comment
 ;was;wasee

 A B C D E F G H I J L K L M N O P Q R S T U V W X Y Z
 a b c d e f g h i j k l m n o p q r s
 ⎕IO
 _A _a _B _b ∆C ∆c ⍙C ⍙c

 :EXTERN J K L m n o IGNORE_ME ⋄ :Intern _THIS_IS _INTERNAL_  ⍝ Ignore all this
 ;hello

 ⎕IO ⎕ML←0 1
 IGNORE_ME←10
⍝ base: Could be 10, multiples/powers of 256 (1 byte), or even 1+⌈/|arrV (max)
 :If 900⌶0 ⋄ base←512 ⋄ :EndIf

 'Auto_Internal_NS'⎕NS ⍬
 ⎕DOG←3

 :With TestAlpha.beta
     :With fred
         :With mary
             gamma←⍳5
         :EndWith
     :End
 :EndWith
 :With '#.IGNORE_ME.beta'
     gamma←⍳5
 :EndWith

 :INTERN aTEST ATEST _TEST _test
 ⍝ :INTERN ∆D ∆ALPHA _C _ALPHA ⍙B ⍙ALPHA MONKEY ALPHA _test ⎕ML
 ⍝ :EXTERN myExternal; philately_external
 myExternal←philately_external←philately_internal←⍬

 outV←arrV←,arrV
 :For place :In ,base*⍳⌈base⍟⌈/|arrV    ⍝ Sort only as many places as needed
    ⍝ Map array elements into buckets by (the current) base
     mapV←base|arrV(⌊÷)place
    ⍝ Calculate count frequencies (f) across buckets, accumulating left to right
     cntV←¯1++\f@ix⊣base⍴0⊣ix f←↓⍉{⍺,≢⍵}⌸mapV
    ⍝ Put output elements in sorted order, building right to left
     arrV{outV[cntV[⍵]]←⍺ ⋄ cntV[⍵]-←1}¨⍥⌽mapV
    ⍝ Update arrV
     arrV←outV
 :EndFor
⍝ Any negative numbers? One more round for the sign.
 :If 1∊lt0←arrV<0
     arrV←(lt0/arrV),arrV/⍨~lt0
 :EndIf
