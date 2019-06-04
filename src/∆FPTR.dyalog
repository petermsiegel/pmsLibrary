 ∆FPTR←{
⍝    ptrs@ns ← [⍺:alpha] ⍺⍺:user_fn@{}  ∆FPTR ⍵:omega
⍝    Create  function "pointer"  or array of function pointers (function namespaces)
⍝      ptrs← [alpha] {fn1} ∆FPTR {fn2} ∆FPTR ... ∆FPTR omega
⍝    If there is one fn (⍺⍺), then <arr> is a scalar. This makes it easy to call directly:
⍝           ptrs← {fn1} ∆FPTR 0 ⋄ 1 2 3 arr.fn 10
⍝    If there are more, then <arr> is a vector. This allows you to distribute arguments to functions easily:
⍝           ptrs ← {fn1} ∆FPTR {fn2} ∆FPTR {fn3} ∆FPTR 0   ⍝ 3 fn ptrs
⍝           1 2 3 ptrs.∆fn 100 200 300                      ⍝ calls 1 fn1 100, 2 fn2 200, 3 fn3 300
⍝
⍝    Each namespace in <ptrs> will have
⍝      ∆ALPHA -- ⍺ from the ∆FPTR call, if defined, else ⎕NULL
⍝      ∆OMEGA -- ⍵ from the ∆FPTR call, i.e. rightmost ⍵, whose first item must not be a namespace
⍝      ∆NARGS -- 2 if ⍺ (∆ALPHA) is defined, else 1
⍝      ∆ID    -- which ∆FPTR in the sequence, from left to right,
⍝                with the left-most having ∆ID=⎕IO, incrementing by 1.
⍝      ∆fn    -- the function passed as ⍺⍺.  You can call it with your own args ⍺ (optional) and ⍵,
⍝                and it can refer to ∆ALPHA, ∆OMEGA, ∆NARGS, and ∆NID
⍝    Note: Each namespace will have (overriding any earlier values set)
⍝          the SAME ∆ALPHA as passed by the left-most ∆FPTR and
⍝          the SAME ∆OMEGA as passed by the right-most ∆FPTR
     ⍺←⊢ ⋄ monad←1≡⍺ 1
     ns←⎕NS'' ⋄ ns.∆fn←⍺⍺
   ⍝ For each ns for ∆fn ⍺⍺, we set a simple display form, if ⍵=0, else we grab the first line of ⍺⍺.
     _←ns.⎕DF{⍵:∊⎕FMT⊃ns.⎕NR'∆fn' ⋄ '[∆FPTR]'}1
   ⍝ Pick up omega from: [a] ⍵, if ⊃⍵ isn't a namespace, OR [b] (⊃⍵).∆OMEGA
     (nsList omega)←ns{9.1=⎕NC⊂'w1'⊣w1←⊃⍵:(⍺,⍵)(w1.∆OMEGA) ⋄ (,⍺)⍵}⍵
   ⍝ Set the local vars of all fn ns's we've seen so far-- we never know if there are more calls to the left.
     nsList.(∆NARGS ∆ALPHA ∆OMEGA)←⊂⍺{⍵:1 ⎕NULL omega ⋄ 2 ⍺ omega}monad
   ⍝ IDs are set left-to-right from ⎕IO. Could be right-to-left if desired.
     nsList.∆ID←⍳≢nsList
   ⍝ Return our list of namespaces. All local vars are properly set up on (each) return!
     ⍬⍴⍣(1=≢nsList)⊣nsList   ⍝ If just one, treat as scalar
⍝∇⍣§./∆FPTR.dyalog§0§ 2019 6 3 22 25 29 209 §wsWQp§0
 }
