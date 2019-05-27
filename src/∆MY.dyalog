:Namespace ∆MYgrp
  ⍝ >>> ∆MY.dyalog → creates namespce ∆MYgrp and objects ##.∆MY and ##.∆THEIR
  ⍝ Description: ∆MY and associated functions support a reasonably lightweight way of supporting STATIC_NS_NM objects within
  ⍝   APL functions. When ∆MYgrp is created (⎕FIXed), ∆MY is copied into the parent namespace.
  ⍝ ∘ For an overview, see ∆MYgrp.help
  ⍝ ∘ We create files in namespaces within various user namespaces.
  ⍝   This class uses a "private" namespace, ⍙⍙.∆MY, inside a namespace ⍙⍙, which supports a "family" of services.
  ⍝ ∘ While many ⍙⍙ services are only in the top-level spaces # or ⎕SE, ∆MYgrp places its namespace(s) in the
  ⍝   same namespace that the calling function uses.
  ⍝ ∘ The namespace should not otherwise be used, or at least select a service name that is associated
  ⍝   with your own functions or classes, e.g. ⍙⍙.SparseArrays, etc.

    STATIC_NS_NM←'⍙⍙.∆MY'                ⍝ special namespace for all local fns with ∆MY namespaces...
    STATIC_NS_RE←'\Q','\E',⍨STATIC_NS_NM
  ⍝ Special function names:
  ⍝    ANON   When the function is an anonymous dfn
  ⍝    NULL   When called from calculator mode with no fns on the stack.
    ANON NULL←'__unnamed_dfn__' '__empty_stack__'

⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝     ∆MYX, ∆MY
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

    ∇ myStat←∆MY
      myStat←⎕THIS.∆MYX 1
    ∇

  ⍝ appendNs: To ⍺:parent@nsRef, add ⍵:ns@nsNm and create the combined ns, returning the full nsRef
  ⍝ If ⍺⍺=1, sets the display form.
  ⍝ Works even if ⍺ is anonymous (no string rep)
      FAST←0
      appendNs←{
         dfOpt←{ ⍝ A kludge! While in principle slow, doesn't affect cmpx timings.
           FAST∨~⍺⍺: ⍺
           ⍺⊣ ⍺.⎕DF STATIC_NS_RE ⎕R ⍵⊣⍕⍺
         }
         nc←⍺.⎕NC⊂,⍵
         9.1=nc: ⍺⍎⍵
         0≠nc: 11 ⎕SIGNAL⍨'∆MY/∆THEIR: static namespace name in use: ',(⍕⍺),'.',⍵
      ⍝  Create combined namespace... Set display form if ⍺⍺=1
         0:: (⍺⍎⍵)         (⍺⍺ dfOpt) '[ANONYMOUS STATIC]'
             (⍎⍵ ⍺.⎕NS '') (⍺⍺ dfOpt) '[STATIC]'
     }

  ⍝ Copy ∆MY into the **PARENT** ns (# or ⎕SE), hardwiring in this directory name.
    _←##.⎕FX'⎕THIS'⎕R (⍕⎕THIS)⊣⎕NR'∆MY'

    ∇ myOwnNs←∆MYX callerLvl
      ;myCallerNs;myOwnNs;⎕IO
    ⍝ For function documentation, see below.
      ⎕IO←0
    ⍝ Determine myName (the user function, or if none, either 'ANON' or 'NULL').
      myName←⎕THIS{(≢⍵)>cl1←1+callerLvl:⍺{⍵≢'':⍵ ⋄ ⍺.ANON}cl1⊃⍵ ⋄ ⍺.NULL}⎕SI
      myCallerNs←callerLvl⊃⎕RSI          ⍝ where caller lives  (ref)...
    ⍝ Build <myCallerNs>.<STATIC_NS_NM>.me
       myOwnNs←(myCallerNs (0 appendNs) STATIC_NS_NM) (1 appendNs) myName
       :IF 0≠myOwnNs.⎕NC '∆MYNS'               ⍝ Not first call to ∆MY.
             myOwnNs.(∆FIRST ∆RESET←∆RESET 0)  ⍝ Update ∆FIRST←∆RESET and clear ∆RESET
       :Else                                   ⍝ First call to ∆MY. Set state.
             myOwnNs.(∆RESET ∆FIRST ∆MYNAME ∆MYNS )←0 1 myName myOwnNs
       :EndIF
    ∇


⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝  ∆MYgrp.∆THEIR
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    ∇ theirStatNs←{theirNs}∆THEIR argList;thatFnNm;obj;newVal
      ;∆HERE;nc;theirStatNm;theirRef;⎕IO
      ⎕IO←0
      ∆HERE← 0⊃⎕RSI            ⍝ ∆HERE-- ns (ref) where I was called.

      :Select ≢⊆argList
           ⋄ :Case 1 ⋄ setGet←0 ⋄ thatFnNm←argList
           ⋄ :Case 2 ⋄ setGet←1 ⋄ thatFnNm obj←argList
           ⋄ :Case 3 ⋄ setGet←2 ⋄ thatFnNm obj newVal←argList
           ⋄ :Else
          ⎕SIGNAL 11
      :EndSelect

       theirNs←'theirNs'{900⌶⍬: ⍵ ⋄ ⎕OR ⍺}∆HERE  ⍝ theirRef: defaults to ∆HERE

       :If ~3 4∊⍨theirNs.⎕NC thatFnNm            ⍝ valid (or special) function?
          :If ~(⊂thatFnNm)∊⎕THIS.(NULL ANON)
              ('∆THEIR: Object not a defined function or operator: ',theirNm)⎕SIGNAL 11
          :EndIf
      :EndIf

      theirStatNs←theirNs (1 appendNs) ⎕THIS.STATIC_NS_NM,'.',thatFnNm

    ⍝ If local state vars aren't defined, set them...
      :If 0=theirStatNs.⎕NC '∆MYNS'
          theirStatNs.(∆RESET ∆FIRST ∆MYNAME ∆MYNS)←0 1 thatFnNm their
      :EndIf

      :Select setGet
           ⋄ :Case 0 ⋄ result←theirStatNs
           ⋄ :Case 1 ⋄ result←theirStatNs obj(theirStat{o←⍵
                          0::'VALUE ERROR retrieving ',o ⋄ ⍺⍎o
                       }obj)
           ⋄ :Case 2 ⋄ result←theirStatNs obj(theirStat{o _←⍵
                          0::'VALUE ERROR setting ',o ⋄ ⍺⍎o,'∘←⊃⌽⍵'
                       }obj newVal)
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
⍝     namespace <static> added, defined as '⍙⍙.∆MY' below, which will contain static info for all such functions.
⍝     Thus if a variable 'MATH.BASIC.COS' is copied from workspace BIGINTEGER,
⍝     and requires its static data, this is what's needed:
⍝       'MATH.BASIC.COS' 'MATH.BASIC.⍙⍙.∆MY.COS' ⎕CY 'BIGINTEGER',
⍝     since MATH.BASIC.⍙⍙.∆MY.COS is the name of the namespace containing static data
⍝     associated with MATH.BASIC.COS."
⍝ Method used:
⍝  1. If it does not exist, creates a namespace <static> in the namespace, <my>, in which
⍝     ∆MY's caller <me> lives, i.e. <my>.<static>.
⍝     For <static> a special string is defined below: ⍙⍙.∆MY
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
⍝     ∘ If called from an unnamed function (must be a dfn), that function's caller is used if named,
⍝       else the name '__anon_dfn__' is used.
⍝     ∘ If called when the function stack is empty, '__empty_stack__' is used
⍝       (e.g. not called from any active function).
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
⍝ ∆THEIR: "-Retrieves or sets information about ∆MY services for a function
⍝           passed by (relative or fully-specified) name, rather than the caller.
⍝          -Returns the "static" namespace for function/operator, <them>, of the same form as ∆MY, except
⍝           that here the function need not be active, though it must be defined. ∆THEIR creates, but does not update,
⍝           required local variables. (See ∆MY)."
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
