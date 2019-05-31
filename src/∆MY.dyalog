:Namespace ∆MYgrp
  ⍝ >>> ∆MY.dyalog → creates namespce ∆MYgrp and object ##.∆MY  (utility ∆THEIR is avail in ∆MYgrp).
  ⍝ Description: ∆MY and associated functions support a reasonably lightweight way of supporting STATIC_NS_NM objects within
  ⍝   APL functions. When ∆MYgrp is created (⎕FIXed), ∆MY is copied into the parent namespace.
  ⍝ ∘ For an overview, see ∆MYgrp.help
  ⍝ ∘ We create files in namespaces within various user namespaces based on
  ⍝   1) the name of the calling (or referenced) function and 2) the namespace in which it resides.
  ⍝   This class uses a "private" namespace, ⍙⍙.∆MY, inside a namespace ⍙⍙, which supports a "family" of services.
  ⍝ ∘ While many ⍙⍙ services are only in the top-level spaces # or ⎕SE, ∆MYgrp places its namespace(s) in the
  ⍝   same namespace that the calling function uses.
  ⍝ ∘ The namespace should not otherwise be used, or at least select a service name that is associated
  ⍝   with your own functions or classes, e.g. ⍙⍙.SparseArrays, etc.

    STATIC_NS_NM←'⍙⍙.∆MY'                ⍝ special namespace for all local fns with ∆MY namespaces...

  ⍝ Special function names:
  ⍝    ANON   When the function is an anonymous dfn
  ⍝    NULL   When called from calculator mode with no fns on the stack.
    ANON NULL←'__unnamed_dfn__' '__empty_stack__'

  ⍝ START_UP_ITEMS:  Copied into ∆MY namespaces...
  ⍝     Static:     (vars) ∆RESET ∆CALLS, (fn) ∆FIRST
  ⍝     On the fly: (vars) ∆MYNAME ∆MYNS must be set dynamically when the static ns is created.
    :Namespace START_UP_ITEMS
        ∆RESET ∆CALLS←1 0
        ∇ r←∆FIRST
          r ∆RESET←∆RESET 0
        ∇
    :EndNamespace

⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝     ∆MYX, ∆MY
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    ∇ myStat←∆MY
      myStat←⎕THIS.∆MYX 1    ⍝ ⎕THIS is hardwired below so ∆MY can be relocated.
    ∇
 ⍝ Copy ∆MY into the **PARENT** ns (# or ⎕SE), hardwiring in this directory name.
    _←##.⎕FX'⎕THIS'⎕R (⍕⎕THIS)⊣⎕NR'∆MY'

    ∇ myOwnNs←∆MYX callerLvl
      ;myCallerNs;myName;myOwnNs;⍙;⎕IO
    ⍝ For function documentation, see below.
      ⎕IO←0
    ⍝ Determine myName (the user function, or if none, either 'ANON' or 'NULL').
      myName←⎕THIS{(≢⍵)>cl1←1+callerLvl:⍺{⍵≢'':⍵ ⋄ ⍺.ANON}cl1⊃⍵ ⋄ ⍺.NULL}⎕SI
      myCallerNs←callerLvl⊃⎕RSI          ⍝ where caller lives  (ref)...
      myOwnNs←myCallerNs getStaticNs myName
      myOwnNs.∆CALLS+←1
    ∇

    ⍝ [internal utility] getStaticNs
    ⍝ To ⍺:parent@nsRef, add ⍵:ns@nsNm and create the combined ns, returning the full nsRef
    ⍝ >>> Works even if ⍺ is anonymous (which has no unique string rep)
        getStaticNs←{
            nc←⍺.⎕NC⊂mystat←STATIC_NS_NM,'.',⍵
            9.1=nc:⍺⍎mystat
            0≠nc:11 ⎕SIGNAL⍨'∆MY/∆THEIR: static namespace name not available: ',(⍕⍺),'.',mystat
            ns←⍺⍎mystat⊣mystat ⍺.⎕NS START_UP_ITEMS       ⍝ Use ⍺⍎⍵ to get ref, in case anon ns
            ns.(∆MYNAME ∆MYNS)←⍵ ns
            ns
        }

⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝  ∆MYgrp.∆THEIR
⍝     If uninitialized, initialize the ∆MY static namespace for the function named in ⍵.
⍝     Get the current value of a static variable ∆RESET, ∆CALLS, or user variables.
⍝     Set a new value for a static variable.
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    ∇ result←{theirNs}∆THEIR argList;thatFnNm;obj;newVal;was
      ;∆HERE;nc;theirStatNm;theirRef;⎕IO
      ⎕IO←0
      ∆HERE←0⊃⎕RSI            ⍝ ∆HERE-- ns (ref) where I was called.

      :Select ≢⊆argList
           ⋄ :Case 1 ⋄ setGet←⍬ ⋄ thatFnNm←argList
           ⋄ :Case 2 ⋄ setGet←'GET' ⋄ thatFnNm obj←argList
           ⋄ :Case 3 ⋄ setGet←'SET' ⋄ thatFnNm obj newVal←argList
           ⋄ :Else ⋄ 11 ⎕SIGNAL⍨'∆THEIR expects 1-3 objects in the right argument, not ',⍕≢⊆argList
      :EndSelect

      theirNs←'theirNs'{900⌶⍬:⍵ ⋄ ⍎⍺}∆HERE  ⍝ theirRef: defaults to ∆HERE

      :If ~3 4∊⍨theirNs.⎕NC thatFnNm            ⍝ valid (or special) function?
          :If ~(⊂thatFnNm)∊⎕THIS.(NULL ANON)
              ('∆THEIR: Object not a defined function or operator: ',thatFnNm)⎕SIGNAL 11
          :EndIf
      :EndIf

      theirStatNs←theirNs getStaticNs thatFnNm


      :Select setGet
      :Case 'GET' ⍝ Return current obj value.
          :Trap 0
              :If obj≡'∆FIRST' ⋄ obj←'∆RESET' ⋄ :EndIf
              result←theirStatNs obj(theirStatNs⍎obj)
          :Else
              11 ⎕SIGNAL⍨'VALUE ERROR getting ∆MY.',thatFnNm,'.',obj
          :EndTrap
      :Case 'SET' ⍝ Return old obj value, while setting to new.
          :If obj≡'∆FIRST' ⋄ obj←'∆RESET' ⋄ :EndIf
          :Trap 0
              was←theirStatNs⍎obj
              _←{theirStatNs⍎obj,'∘←⍵'}newVal
              result←theirStatNs obj was
          :Else
              11 ⎕SIGNAL⍨'VALUE ERROR setting ∆MY.',thatFnNm,'.',obj,' to ',⍕newVal
          :EndTrap
      :Else
          result←theirStatNs   ⍝ Just return their ∆MY namespace!
      :EndSelect
    ∇


⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝  ∆MYgrp.HELP, Help, help
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
⍝           ∆RESET←0             ⍝ If set to 1, ∆MY.∆FIRST will be 1 on the NEXT call.
⍝           ∆CALLS←1             ⍝ Set to 1 first time ∆MY is called (initialized).
⍝       and the niladic function ∆FIRST, if called, responds:
⍝           ∆FIRST returns 1     ⍝ This was the first time ∆MY.∆FIRST was called for this function.
⍝    b. Iff that space is not new, sets "pseudo-system" variables:
⍝           ∆CALLS +←1           ⍝ How many times ∆MY was called
⍝       and the niladic function ∆FIRST, if called, responds:
⍝           ∆FIRST will return 0 ⍝ This was not the first time ∆MY.∆FIRST was called for this function.
⍝    c. To reset ∆FIRST, so it returns 1 on the next call, do
⍝           ∆MY.∆RESET←1
⍝        or do
⍝           ∆THEIR 'funcName'  '∆RESET' 1
⍝     NOTE: ∆FIRST returns 0 on every call after the first call to ∆FIRST (unless ∆RESET).
⍝           ∆CALLS, which counts calls to ∆MY, not (∆MY.)∆FIRST, will increment forever (unless reset via ∆THEIR '∆CALLS' 1)
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
⍝ ∆THEIR:  theirStat                  ← {their} ∆THEIR them
⍝          theirStat variable curVal  ← {their} ∆THEIR them variable
⍝          theirStat variable oldVal  ← {their} ∆THEIR them variable value
⍝       them:      the name (string-form) of a function or operator;
⍝       their:     the name (string-form) of the namespace in which <them> resides, else the namespace called from (current).
⍝       variable:  ∆MY "special" variables--  starting with ∆ -- or arbitrary use variables
⍝           ∆RESET      1 if the next call to ∆FIRST should return 1. Values: 1 or 0.
⍝           ∆MYNAME     the name of this specific function; do not reset.
⍝           ∆MYNS       the namespace this function uses for ∆MY variables; do not reset.
⍝           ∆CALLS      the number of times ∆MY has been called; 1 after first call.
⍝           ∆FIRST      ∆FIRST is actually a function, but if it is queried or set via ∆THEIR, ∆RESET is quietly used.
⍝
⍝   Returns:
⍝   I. theirStat: a namespace reference; the namespace is a "static" (permanent if ⎕SAVEd)
⍝         namespace for objects associated with the function or operator specified via <them>/<their>.
⍝         If <theirStat> does not exist, it is created and local variables initialized.
⍝   II. If variable is included (e.g. ∆RESET),
⍝       checks current value of theirStat.variable,
⍝       returns:
⍝           theirStat variable (current [i.e. old] value of variable)
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
    ∇ Help
      HELP
    ∇
    ∇ help
      HELP
    ∇

⍝∇⍣§./PMSLibrary/∆MY.dyalog§0§ 2018 8 21 21 43 38 381 §åÊtÅZ§0

:EndNamespace
