 future←{
  ⍝    futureObj ← [⍺] ⍺⍺:future_fn ∇ ⍵
  ⍝       future_fn: a tradfn, dfn, or APL code sequence/train, e.g. (+/÷≢) for mean.
  ⍝       ⍺, ⍵:      args to future_fn.
  ⍝       future_obj:the future, returned immediately while ⍺ ⍺⍺ ⍵ executes.
  ⍝ "∘ Creates a futureObj and immediately returns it.
  ⍝  ∘ Simultaneously, calls <[⍺] future_fn ⍵>, whose value
  ⍝    will become the value of futureObj, when done.
  ⍝  ∘ If futureObj's value is requested, it will hang
  ⍝    until its value is available."
  ⍝
  ⍝ Minimal future magic gleaned from the isolate:isolate.yyns source code...
  ⍝ Requirements: a ns made magically via undocumented (700⌶),
  ⍝     two fns iSyntax, iEvaluate, and a magical use of ⎕DF as
  ⍝     (d)efining and returning a (f)uture.
  ⍝ To access objs in the caller namespace, use
  ⍝    (⊃⎕RSI), ##, etc.

     futNs←(⊃⎕RSI).⎕NS''      ⍝ Create NS in the caller's space
     futNs.iSyntax←{2 0}      ⍝ Copy in magical iSyntax: variable, no args


     ⍺←⊢ ⋄ futNs.alphaø←⍺     ⍝ Prep (opt'l) left and right args.
     futNs.omegaø←⍵

     futNs.userFnø←⍺⍺         ⍝ Copy in ⍺⍺ as userFnø, ⍺⍺ ∊ dfn, tradfn, etc.

                              ⍝ iEvaluate: automagically called at (3) below.
                              ⍝ For some reason, we have to force the ret. val via ⊢.
     futNs.iEvaluate←futNs.{  ⍝ Call [⍺] ⍺⍺ ⍵ via surrogate names
         ⊢alphaø userFnø omegaø
     }
                              ⍝ Issue 2 magical incantations to create a future.
     _←1(700⌶)futNs           ⍝ 1. Magic ⌶beam 700 sets things up in <futNs>.
     fut←futNs.⎕DF            ⍝ 2. Magical use of ⎕DF. In dfn, won't work unless assigned to a name(?).
     fut                      ⍝ 3. Return the var by name <fut>.

 }
