:Namespace ∆MYgrp
 ⍝ See HELP below for documentation
  
    STATIC_NS_NM←'⍙⍙.∆MY'                ⍝ special namespace for all local fns with ∆MY namespaces...

  ⍝ Special function names:
  ⍝    ANON   When the only function on the stack is an anonymous dfn
  ⍝    EMPTY   When called from calculator mode, with no named fns on the stack.
    ANON EMPTY←'__ANONYMOUS_DFN__' '__EMPTY_FN_STACK__'

  ⍝ STARTUP_ITEMS:  Copied into ∆MY namespaces...
  ⍝     User-level:  ∆FIRST, ∆RESET, ∆MYNAME, ∆MYNS 
  ⍝     Internal:    ∆MY_DATA[0 1 2]←fn name, namespace, first flag 
    :Namespace STARTUP_ITEMS
        ⍝ ⍙MY_DATA: [0] ∆MYNAME [1] ∆MYNS [2] ∆FIRST flag
        ⍙MY_DATA←             '[dummy]' ⎕NULL 1  
        ⎕FX 'now← ∆FIRST'     'now   (⍙MY_DATA[2])←⍙MY_DATA[2] 0'
        ⎕FX '{was}← ∆RESET'   'was   (⍙MY_DATA[2])←⍙MY_DATA[2] 1'
        ⎕FX 'myName←∆MYNAME'  'myName←⍙MY_DATA[0]'
        ⎕FX 'myNs←  ∆MYNS'    'myNs←  ⍙MY_DATA[1]'
    :EndNamespace
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝     ∆MY
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    ∇ myNs←∆MY  
      ;callerNs;myNm;myNsNm;auto;⎕IO
    ⍝ Optimized high-use equivalent of: ∆MYX 0 1
      ⎕IO←0  
      :IF 2≤≢⎕SI 
          :IF 0≠≢1⊃⎕SI ⋄ myNm←1⊃⎕SI                   ⍝ FAST
          :Else        ⋄ myNm←⎕THIS.ANON
          :Endif
      :Else ⋄ myNm←⎕THIS.EMPTY
      :ENDIF
      myNsNm←⎕THIS.STATIC_NS_NM,'.',myNm             ⍝ FAST
      callerNs←0⊃⎕RSI    
      :Select callerNs.⎕NC⊂myNsNm 
          :Case 9.1 
              myNs←callerNs⍎myNsNm                      ⍝ FAST
          :Case 0
             :IF auto←1   ⍝ Automatically create if new...
                 myNs←callerNs⍎myNsNm⊣myNsNm callerNs.⎕NS ⎕THIS.STARTUP_ITEMS 
                 myNs.⍙MY_DATA[0 1]←myNm myNs          
             :Else   ⍝ Return ⍬ if new...
                 myNs←⍬
             :EndIf 
          :Else 
             11 ⎕SIGNAL⍨'∆MY: static namespace not available: ',(⍕callerNs),'.',myNsNm
      :EndSelect     
    ∇
     ∇ myNs←{callerNs} ∆MYX args  
      ;callerNs;fnLvl;myNm;myNsNm;auto;⎕IO
      ⍝ args: Either   fnLvl [auto=0]  OR  myNm [auto=0]
      ⍝ fnLvl:  0: The function that called ∆MYX directly; 1: the one that called that one; etc.
      ⎕IO←0  
      :IF 0=⊃0⍴⊃args   
          fnLvl auto←(1+1↑args)(1↑1,⍨1↓args)
          :IF fnLvl<≢⎕SI 
              :IF 0≠≢fnLvl⊃⎕SI   ⍝ dfn ('')
                 myNm←fnLvl⊃⎕SI                      ⍝ FAST
              :Else        
                 myNm←⎕THIS.ANON
              :Endif
          :Else 
              myNm←⎕THIS.EMPTY
          :ENDIF
      :Else
          myNm auto←2↑(⊆args),1
          :IF 0=≢myNm
              myNm←⎕THIS.EMPTY
          :ENDIF
      :ENDIF 
 
      myNsNm←⎕THIS.STATIC_NS_NM,'.',myNm               ⍝ FAST
      :IF 0=⎕NC 'callerNs'  
         callerNs←0⊃⎕RSI  
      :ElseIf 9≠⎕NC 'callerNs'
        '∆MYX: Left Arg (callerNs) must be a namespace reference' ⎕SIGNAL 11 
      :ENDIF

      :Select callerNs.⎕NC⊂myNsNm 
          :Case 9.1 
              myNs←callerNs⍎myNsNm                      ⍝ FAST
          :Case 0
             :IF auto   ⍝ Automatically create if new...
                 myNs←callerNs⍎myNsNm⊣myNsNm callerNs.⎕NS ⎕THIS.STARTUP_ITEMS 
                 myNs.⍙MY_DATA[0 1]←myNm myNs          
             :Else   ⍝ Return ⍬ if new...
                 myNs←⍬
             :EndIf 
          :Else 
             11 ⎕SIGNAL⍨'∆MYX: static namespace not available: ',(⍕callerNs),'.',myNsNm
      :EndSelect     
    ∇
      ⍝ Copy ∆MY into the **PARENT** ns (# or ⎕SE), hardwiring in ⎕THIS directory name.
      _←##.⎕FX '⎕THIS' ⎕R (⍕⎕THIS)⊣⎕NR'∆MY'

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
  ⍝     function  ∆MY and ∆MYgrp.∆MY
  ⍝     function  ∆MYgrp.∆MYX
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
  ⍝       ⍙MY_DATA-contains the name of the function, its namespace, and the ∆FIRST setting (initially 1).
  ⍝                NOT USED DIRECTLY BY THE USER.
  ⍝       The user may create any object by setting via ∆MY, e.g. ∆MY.myobj←1 2 3
  ⍝   ∆MYX is a utility function for managing, setting objects ∆MY-space by name or stack position:
  ⍝       [caller_ns] ∆MYX stack_level [auto=1] 
  ⍝    OR     
  ⍝       [caller_ns] ∆MYX fn_name [auto=1]
  ⍝        caller_ns:   What namespace is the caller function in (default:this one)
  ⍝        stack_level: 0: the fn calling ∆MYX; 1: the one that called that one; etc.
  ⍝        fn_name:     The name of the function whose ∆MY-space is requested.
  ⍝        auto:        If 1, ∆MYX returns the namespace reference, creating it if the function doesn't exist
  ⍝                     or hasn't been called!
  ⍝                     If 0, ∆MYX returns ⍬ if the function does NOT exist or hasn't been called.
  ⍝  Useful actions:
  ⍝        ∆MYX 'fred' 0         See if 'fred' has a ∆MY-space created or not (⍬ returned).
  ⍝        (∆MYX 'fred').∆RESET  Ensure next call to <fred> will be treated as first call, i.e.
  ⍝                              ∆MY.∆FIRST will be 1.
  ⍝        (∆MYX 'fred').∆FIRST  Ensure next call to <fred> will NOT be treated as first call, i.e.
  ⍝                              ∆MY.∆FIRST will be 0. E.g. you've already initialized <fred>.
  ⍝  Note: ∆MY is equivalent to (∆MYX 1) but somewhat faster.
  ⍝ 
  ⍝  Simple example:
  ⍝  ∇ res←{reset}prompt message;my;⎕IO
  ⍝    my←∆MY ⋄ ⎕IO←0
  ⍝    :If 0≠⎕NC'reset'
  ⍝      my.∆RESET        ⍝ Allow user way to reset ∆MY.yourname
  ⍝    :EndIf
  ⍝    :With my
  ⍝      :If ∆FIRST                ⍝ First time ∆MY.∆FIRST has been called (perhaps since reset)!
  ⍝          yourname←⍞↓⍨≢⍞←'Enter your name: '
  ⍝          yourname←yourname'friend'⊃⍨0=≢yourname~' '
  ⍝      :EndIf
  ⍝    :EndWith
  ⍝    res←⍞↓⍨≢⍞←'Hello, ',my.yourname,'. 'message
  ⍝  ∇
    ∇
⍝ ALIASES for HELP:  Help, help
    ⎕FX¨ ('Help' 'HELP')('help' 'HELP')

⍝∇⍣§./PMSLibrary/∆MY.dyalog§0§ 2018 8 21 21 43 38 381 §åÊtÅZ§0
:EndNamespace
