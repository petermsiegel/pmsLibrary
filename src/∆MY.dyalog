:Namespace ∆MYgrp
 ⍝ See HELP below for documentation
    ⎕IO←0
    STATIC_NS_NM←'⍙⍙.∆MY'                ⍝ special namespace for all local fns with ∆MY namespaces...

  ⍝ Special function names:
  ⍝    ANON   When the only function on the stack is an anonymous dfn
  ⍝    EMPTY   When called from calculator mode, with no named fns on the stack.
    ANON EMPTY←'__ANONYMOUS_DFN__' '__EMPTY_FN_STACK__'

  ⍝ STARTUP_ITEMS:  Copied into ∆MY namespaces...
  ⍝     User-level:  ∆FIRST, ∆RESET, ∆DESTROY, ∆MYNAME, ∆MYNS 
  ⍝     Internal:    ∆MY_DATA[0 1 2]←fn name, namespace, first flag 
    :Namespace STARTUP_ITEMS
        ⍝ ⍙MyData: [0] ∆MYNAME [1] ∆MYNS [2] ∆FIRST flag
        ⍙MyData←              '[dummy]' ⎕NULL 1  
        ⎕FX 'now←    ∆FIRST'   'now    (⍙MyData[2])← ⍙MyData[2] 0'
        ⎕FX '{was}←  ∆RESET'   'was    (⍙MyData[2])← ⍙MyData[2] 1'
        ⎕FX 'ex←     ∆DESTROY' 'ex←⎕EX ⍕⎕THIS ⍝ Delete our ∆MY namespace'
        ⎕FX 'myName← ∆MYNAME'  'myName← ⍙MyData[0]'
        ⎕FX 'myNs←   ∆MYNS'    'myNs←   ⍙MyData[1]'
    :EndNamespace
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝     ∆MY
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    ∇ myNs←∆MY  
      ;auto;callerNs;myNm;myNsNm;si;⎕IO
    ⍝ Optimized high-use equivalent of: ∆MYX 0 1
      ⎕IO←0  
      :IF 2≤≢si←⎕SI 
          myNm←1⊃si
          :IF 0=≢myNm ⋄ myNm←⎕THIS.ANON                 ⍝ FAST (alt: myNm is anon dfn)
          :Endif
      :Else 
           myNm←⎕THIS.EMPTY
      :ENDIF 
      myNsNm←⎕THIS.STATIC_NS_NM,'.',myNm                ⍝ FAST
      callerNs←0⊃⎕RSI    
      :Select callerNs.⎕NC⊂myNsNm 
          :Case 9.1 
              myNs←callerNs⍎myNsNm                      ⍝ FAST
          :Case 0
             :IF auto←1   ⍝ Automatically create if new...
                 myNs←callerNs⍎myNsNm⊣myNsNm callerNs.⎕NS ⎕THIS.STARTUP_ITEMS 
                 myNs.⍙MyData[0 1]←myNm myNs          
             :Else   ⍝ Return ⍬ if new...
                 myNs←⍬
             :EndIf 
          :Else 
             11 ⎕SIGNAL⍨'∆MY: static namespace not available: ',(⍕callerNs),'.',myNsNm
      :EndSelect     
     ∇
    ⍝ Copy ∆MY into the **PARENT** ns (# or ⎕SE), hardwiring in ⎕THIS directory name.
      _←##.⎕FX '⎕THIS' ⎕R (⍕⎕THIS)⊣⎕NR'∆MY'

    ∆MYX←{
    ⍝ myNs←{callerNs} ∆MYX args  
     ⍝ ;auto;callerNs;fnLvl;myNm;myNsNm;si;⎕IO
      ⍝ args: Either   fnLvl [auto=1]  OR  myNm [auto=1]
      ⍝ fnLvl:  An int n: get the n-th function on the stack after this one.
      ⍝         n=0: Get the function that called this one (1⊃⎕SI), in general ((1+n)⊃⎕SI).
      ⍝ myNm:   The simple name of the calling/queried function
      ⍝ auto:   1: If no ∆MYspace has been created for the fn, create and return its ref.
      ⍝         0: If no ∆MYspace has been created for the fn, don't create it; return ⍬. 
      ⍺←0⊃⎕RSI   
      9≠⎕NC '⍺': '∆MYX: Left Arg (caller''s ns) must be a namespace reference' ⎕SIGNAL 11 
      myNm auto←{  
          arg1 auto←2↑(⊆⍵),1   
          0=80|⎕DR arg1: myNm auto⊣myNm←arg1 ⎕THIS.EMPTY⊃⍨0=≢arg1 
          fnLvl←1+arg1  
          fnLvl≥≢⎕SI: ⎕THIS.EMPTY auto
          myNm←fnLvl⊃⎕SI  
          0≠≢myNm: myNm auto
          ⎕THIS.ANON auto     
      }⍵
      myNsNm←⎕THIS.STATIC_NS_NM,'.',myNm                            ⍝ FAST
      9.1=nc←⍺.⎕NC⊂myNsNm: ⍺⍎myNsNm                                 ⍝ FAST
      0≠nc: 11 ⎕SIGNAL⍨'∆MYX: static namespace not available: ',(⍕⍺),'.',myNsNm
      ~auto: ⍬
      myNs←⍺⍎myNsNm⊣myNsNm ⍺.⎕NS ⎕THIS.STARTUP_ITEMS 
      myNs.⍙MyData[0 1]←myNm myNs  
      myNs            
    }

  ⍝ ∆OPT: See HELP below...
    ∆OPT←{⎕IO←0 ⋄ ⍺←0⊃⎕RSI
      1: _←⍺.⎕FX '(''[^'']*'')+' '(?<!\.)∆MY\b(?!\.)'⎕R '\0' (⍕⍺ ∆MYX ⍵)⍠'UCP' 1⊣⍺.⎕NR ⍵
    }

⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝  ∆MYgrp.HELP, Help, help
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯
    ∇ HELP;H;_
      ⎕ED&'H'⊣H←↑3↓¨3↓⎕NR ⎕IO⊃⎕SI 
      _←⍞⊣⍞←'Hit RETURN when done with HELP'
  ⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  ⍝      Documentation - ∆MY 
  ⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  ⍝ >>> ∆MY.dyalog → creates 
  ⍝     namespace ∆MYgrp
  ⍝     function  ∆MY and ∆MYgrp.∆MY     (∆MY is copied from ∆MYgrp to ##.∆MYgrp)
  ⍝     function  ∆MYgrp.∆MYX
  ⍝     function  ∆MYgrp.∆OPT
  ⍝ Description: 
  ⍝   ∆MY and associated functions support a reasonably lightweight way of supporting "static" objects
  ⍝   (objects that persist across function calls) within APL functions. 
  ⍝   ∆MY returns a namespace associated with the named, calling function. Best used with TRADFNS or
  ⍝   DFNS visible in the stack )FNS. If used within an anonymous dfn, the surrounding tradfn or dfn's
  ⍝   static namespace will be shared. If used with no active functions on the stack, a special
  ⍝   ∆MY-space namespace is created with a dummy function name.
  ⍝   
  ⍝   The static namespace  created for function <test> is 
  ⍝       ⍙⍙.∆MY.test in the same namespace as <test> itself.
  ⍝   ∆MY actually looks at the stack for the calling function's name and its namespace.
  ⍝   ∆MY has within it these functions:
  ⍝       ∆FIRST-- returns 1 the first time ∆FIRST is called; else 0.
  ⍝       ∆RESET-- ensures that ∆FIRST will be 1 the next time it is called; returns ∆FIRST's current setting.
  ⍝       ∆DESTROY-delete (erase) the ∆MY namespace for the associated fn:  {⍵.∆DESTROY}∆MYX 'some_fn' 
  ⍝                (Data will actually be erased when all references are removed.)
  ⍝       ⍙MyData- a 3-element variable with:
  ⍝                the name of the function, its namespace ref, and the ∆FIRST flag (initially 1).
  ⍝                NOT USED DIRECTLY BY THE USER. Use ∆RESET/∆FIRST to set the flag to 1/0.
  ⍝       The user may create any object by setting via ∆MY, e.g. ∆MY.myobj←1 2 3
  ⍝   ∆MYX is a utility function for managing, setting objects ∆MY-space by name or stack position:
  ⍝       [caller_ns] ∆MYgrp.∆MYX stack_level [auto=1] 
  ⍝    OR     
  ⍝       [caller_ns] ∆MYgrp.∆MYX fn_name [auto=1]
  ⍝        caller_ns:   What namespace is the caller function in (default:this one)
  ⍝        stack_level: 0: the fn calling ∆MYX; 1: the one that called that one; etc.
  ⍝        fn_name:     The name of the function whose ∆MY-space is requested.
  ⍝        auto:        If 1, ∆MYX returns the namespace reference, creating it if the function doesn't exist
  ⍝                     or hasn't been called!
  ⍝                     If 0, ∆MYX returns ⍬ if the function does NOT exist or hasn't been called.
  ⍝  Useful actions:
  ⍝        ∆MYX 'fred' [1]       See if 'fred' has a ∆MY-space:
  ⍝                              Create it if it doesn't exist. Return the namespace reference.
  ⍝        ∆MYX 'fred' 0         See if 'fred' has a ∆MY-space created:
  ⍝                              If so, return the ns ref. If not, do NOT create it; return ⍬.
  ⍝        (∆MYX 'fred').∆RESET  Ensure next call to <fred> will be treated as first call, i.e.
  ⍝                              ∆MY.∆FIRST will return 1.
  ⍝        (∆MYX 'fred').∆FIRST  Ensure next call to <fred> will NOT be treated as first call, i.e.
  ⍝                              ∆MY.∆FIRST will be 0. E.g. you've already initialized <fred>.
  ⍝
  ⍝  Note: ∆MY is an optimized equivalent to (∆MYX 1). It's about 30% faster.
  ⍝ 
  ⍝  [caller_ns] ∆MYgrp.∆OPT fn
  ⍝  Description: takes the function name <fn> specified and replaces IN PLACE any use of ∆MY with the 
  ⍝  namespace for the fn's ∆MY-space. Allows ∆MY functionality with minimal performance penalty.
  ⍝  Details: 
  ⍝    ∘ It initializes the ∆MY-space, leaving any initialization of ∆MY-space variables to 
  ⍝      the fn itself, e.g. via ∆MY.∆FIRST.
  ⍝    ∘ Only ∆MY not surrounded by dots or alphanumeric characters are replaced.
  ⍝    ∘ Those in quotes are ignored. To check on the nameclass, etc., of ∆MY, do:
  ⍝            my ← ∆MY ⋄  ⎕NC 'my'
  ⍝      since '∆MY' is honored as a quoted string.
  ⍝ 
  ⍝ ------------------------------------------------
  ⍝  Simple example:
  ⍝  res←{reset}prompt message;my;⎕IO
  ⍝  my←∆MY ⋄ ⎕IO←0
  ⍝  :If 0≠⎕NC'reset' ⋄ my.∆RESET ⋄ :EndIf         ⍝ Way to "reset" the user name <yourname>
  ⍝  :If my.∆FIRST                                 ⍝ On first use...
  ⍝      my.yourname←⍞↓⍨≢⍞←'Enter your name: '
  ⍝      :If 0=≢my.yourname~' ' ⋄ my.yourname←'friend' ⋄ :EndIf
  ⍝  :EndIf
  ⍝  res←⍞↓⍨≢⍞←'Hello, ',my.yourname,'. ',message,' '
  ⍝
    ∇
⍝ ALIASES for HELP:  Help, help
    ⎕FX¨ ('Help' 'HELP')('help' 'HELP')

⍝∇⍣§./PMSLibrary/∆MY.dyalog§0§ 2018 8 21 21 43 38 381 §åÊtÅZ§0
:EndNamespace
