:Namespace ∆MYgrp

    STATIC←'⍙⍙.∆MY'                ⍝ special namespace for all local fns with ∆MY namespaces...
  ⍝ Special function names:
  ⍝    __anon__  When the function is an anonymous dfn
  ⍝    __null__  When called from calculator mode with no fns on the stack.
    ANON NULL←'__anon__' '__null__'

⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝     ∆MYX, ∆MY
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    ∇ myStat←∆MYX callLvl
      ;me;my;myPfx;myStatNm;⎕IO
    ⍝ For function documentation, see below.
      ⎕IO←0
     
    ⍝ Use ⎕THIS for items set in surrounding namespace. See ** below.
    ⍝  ≢⍵ ≥3  ≢⍵ > 2
      me←⎕THIS{(≢⍵)>cl1←1+callLvl:⍺{⍵≢'':⍵ ⋄ ⍺.ANON}cl1⊃⍵ ⋄ ⍺.NULL}⎕SI
      my←callLvl⊃⎕NSI          ⍝ where caller lives (fully qualified)...
     
      :If ~9.1 0∊⍨⎕NC⊂myPfx←my,'.',⎕THIS.STATIC
          11 ⎕SIGNAL⍨'∆MY static namespace name in use: ',myPfx
      :EndIf
      :If 9.1=⎕NC⊂myStatNm←myPfx,'.',me
          myStat←⍎myStatNm
          myStat.((∆RESET ∆FIRST)←0 ∆RESET)
      :Else            ⍝ If sub-ns not new, overwrite it!
          myStat←⍎myStatNm ⎕NS''
          myStat.(∆RESET ∆FIRST ∆MYNAME ∆MYNS)←0 1 me my
      :EndIf
    ∇
    ∇ myStat←∆MY
      myStat←⎕THIS.∆MYX 1
    ∇
  ⍝ Copy ∆MY into the top-level ns (# or ⎕SE), hardwiring in this directory name.
    _topNs←{'#'=1↑⍕⍵:# ⋄ ⎕SE}⎕THIS
    _←_topNs.⎕FX'⎕THIS'⎕R (⍕⎕THIS)⊣⎕NR'∆MY'
    ⎕EX '_' '_topNs'


⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝  ∆MYgrp.∆THEIR
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    ∇ theirStat←{their}∆THEIR them;obj;val
      ;∆HERE;monadic;nc;theirStatNm;theirNm;⎕IO
      ⎕IO←0
      monadic ∆HERE←((900⌶)⍬)(0⊃⎕RSI)        ⍝ ∆HERE-- ns (ref) where I was called.
     
      :Select ≢⊆them
           ⋄ :Case 1 ⋄ setGet←0
           ⋄ :Case 2 ⋄ setGet←1 ⋄ them obj←them
           ⋄ :Case 3 ⋄ setGet←2 ⋄ them obj val←them
           ⋄ :Else
          ⎕SIGNAL 11
      :EndSelect
     
      their←monadic{⍺:⍕⍵ ⋄ ⍕their}∆HERE      ⍝ their: defaults to ∆HERE
     
      theirNm←their,'.',them
      :If ~3 4∊⍨∆HERE.⎕NC theirNm            ⍝ valid (or special) function?
          :If ~(⊂them)∊⎕THIS.(NULL ANON)
              ('∆THEIR: Object not a defined function or operator: ',theirNm)⎕SIGNAL 11
          :EndIf
      :EndIf
     
      theirStatNm←their,'.',⎕THIS.STATIC,'.',them
     
    ⍝ *** Note carefully the items that must referenced w.r.t ∆HERE.
      :If 9.1=nc←∆HERE.⎕NC⊂theirStatNm       ⍝ ***
          theirStat←∆HERE⍎theirStatNm        ⍝ ***
      :ElseIf nc≠0
          ('∆THEIR static namespace name in use: ',theirStatNm)⎕SIGNAL 11
      :Else
          theirStat←⍎theirStatNm ∆HERE.⎕NS'' ⍝ ***
          theirStat.(∆RESET ∆FIRST ∆MYNAME ∆MYNS)←0 1 them their
      :EndIf
     
      :Select setGet
           ⋄ :Case 1 ⋄ theirStat←theirStat obj(theirStat{0::'VALUE ERROR' ⋄ ⍺⍎⍵}obj)
           ⋄ :Case 2 ⋄ theirStat←theirStat obj(theirStat{0::'VALUE ERROR' ⋄ ⍺⍎obj,'∘←⍵'}val)
      :EndSelect
    ∇
    ⍝ ∆THEIR only called via namespace: ∆MYgrp.∆THEIR


⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝  ∆MYgrp.HELP
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯
    ∇ HELP;H
      ⎕ED'H'⊣H←↑2↓¨2↓⎕NR ⎕IO⊃⎕SI
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝      Documentation - ∆MY, ∆MYgrp.∆MYX, ∆MYgrp.∆THEIR
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝ ∆MY:  myStat ← ∆MY
⍝       myStat: a namespace reference; the namespace is a "static" (permanent if ⎕SAVEd)
⍝               namespace for objects associated with the function immediately calling ∆MY.
⍝ ∆MY:
⍝   "A function returning a local namespace for static variables for the function calling ∆MY,
⍝    creating it if required. Initializes special "pseudo-system" variables as well.
⍝   ∘ In this approach, the namespace containing the calling function will have a special
⍝     namespace <static> added, defined as '⍙⍙' below, which will contain static info for all such functions.
⍝     Thus if a variable 'MATH.BASIC.COS' is copied from workspace BIGINTEGER,
⍝     and requires its static data, this is what's needed:
⍝       'MATH.BASIC.COS' 'MATH.BASIC.⍙⍙.COS' ⎕CY 'BIGINTEGER',
⍝     since MATH.BASIC.⍙⍙.COS is the name of the namespace containing static data
⍝     associated with MATH.BASIC.COS."
⍝ Method used:
⍝  1. If it does not exist, creates a namespace <static> in the namespace, <my>, in which
⍝     ∆MY's caller <me> lives, i.e. <my>.<static>.
⍝     For <static> a special string is defined below: ⍙⍙
⍝  2. If it does not exist, creates a namespace <me> within <static>, where
⍝     <me> is the unqualified (simple) name of the caller.
⍝    a. Iff that space is new, sets "pseudo-system" variables:
⍝           ∆MYNAME←me           ⍝ Simple name of the caller
⍝           ∆MYNS←my             ⍝ Fully qualified name (string) of the namespace the caller lives in.
⍝           ∆FIRST←1             ⍝ This was the first time ∆MY was called for this function.
⍝    b. Iff that space is not new, sets "pseudo-system" variables:
⍝           ∆FIRST← 0            ⍝ This was not the first time ∆MY was called for this function.
⍝  3. Returns a reference, <myStat>, to a static namespace for the caller:
⍝     <static>.<me> in namespace <my>, i.e. <my>.<static><.me>
⍝     ∘ If called from an unnamed function, that function's caller is used if named,
⍝       else the name '__anon__' is used.
⍝     ∘ If called from outside any function, '__null__' is also used.
⍝
⍝  Oddities: If called from a named dfn inside a tradfn, ∆MY accepts and uses the name of
⍝     the dfn. This could wreak havoc if there is a "global" dfn with the same name.
⍝     The solution is to assign ∆MY directly to a var within the caller and then pass around the var.
⍝         ∇ MYTRADFN; stat; myFn
⍝           stat←∆MY
⍝           :IF stat.∆FIRST ⋄ ... set up stat.MYDATA ⋄ :ENDIF
⍝           myFn←{ stat.MYDATA ...} ⋄ myFn 1 2 3
⍝         ∇
⍝
⍝ ∆THEIR:  theirStat ← {their} ∆THEIR them
⍝          theirStat ← {their} ∆THEIR them variable
⍝          theirStat ← {their} ∆THEIR them variable value
⍝       them:      the name (string-form) of a function or operator;
⍝       their:     the name (string-form) of the namespace in which <them> resides, else the current directory.
⍝   Returns:
⍝   I. theirStat: a shy namespace reference; the namespace is a "static" (permanent if ⎕SAVEd)
⍝         namespace for objects associated with the function or operator specified via <them>/<their>.
⍝         If <theirStat> does not exist, it is created and local variables initialized.
⍝   II. If variable is included (e.g. ∆RESET),
⍝       checks current value of theirStat.variable,
⍝       returns:
⍝           theirStat variable (current value of variable)
⍝   III. If variable and value are included,
⍝        sets theirStat.variable←value, then
⍝        returns:
⍝           theirStat variable (new value of variable)
⍝ ∆THEIR:  "Returns the "static" namespace for function/operator, <them>, of the same form as ∆MY, except
⍝      that here the function need not be active, though it must be defined. ∆THEIR creates, but does not update,
⍝      required local variables. (See ∆MY)."
⍝
⍝ ∆MYX:  theirStat ← ∆MYX callLvl
⍝      callLvl: how far into stack to find the caller. 0 means
⍝      callerNS is at 0⊃⎕NSI, caller function name at (0+1)⊃⎕STACK.
⍝      ∘ From ∆MY, it's ∆MYX 1.
⍝      ∘ If called directly, it's ∆MYX 0.
⍝ ∆MYX: "∆MY utility. Returns the static namespace for the caller level specified."
⍝
    ∇
⍝∇⍣§./PMSLibrary/∆MY.dyalog§0§ 2018 8 21 21 43 38 381 §åÊtÅZ§0

:EndNamespace
