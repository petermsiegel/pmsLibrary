:Namespace ∆MYgrp
 ⍝ See HELP below for documentation

    ⎕IO←0 ⋄ qt←{'''',⍵,''''}
  ⍝ special namespace ⍙⍙ within the caller's namespace for all local fns with ∆MY namespaces...
  ⍝ We use ∆MY_ in place of ∆MY. since it's a bit faster w/ no loss of clarity and separation!
    STATIC_PREFIX←'⍙⍙.∆MY_'     

  ⍝ Special function names:
  ⍝    ANON   When the only function on the stack is an anonymous dfn
  ⍝    EMPTY   When called from calculator mode, with no named fns on the stack.
    ANON    ← '__ANON_DFN__'    '[ANON DFN]' 
    EMPTY   ← '__EMPTY_SI__'    '[EMPTY ⎕SI]'

  ⍝ STARTUP_ITEMS:  Copied into ∆MY namespaces...
  ⍝     User-level:  ∆FIRST, ∆RESET, ∆DESTROY, ∆NAME, ∆NS 
  ⍝     Internal:    ∆MY_DATA[0 1 2]←fn name, namespace, first flag 
    :Namespace STARTUP_ITEMS
        ⍝ ⍙MyData:             [0] ∆NAME   [1] ∆NS [2] ∆FIRST flag
        ⍙MyData←               '[dummy]'   ⎕NULL   1  
        ⎕FX '{now}←  ∆FIRST'   'now←⍙MyData[2] ⋄ ⍙MyData[2]←0 '
        ⎕FX '{was}←  ∆RESET'   'was←⍙MyData[2] ⋄ ⍙MyData[2]←1 '
      ⍝ ∆DESTROY: Expunges the current ns ⎕THIS and its contents, only if ⎕THIS≡myNs.
      ⍝           It won't actually disappear until last reference to it is gone (e.g. on fn return)
        ⎕FX '{ex}←   ∆DESTROY' 'ex←∆NS{⍺≡⍵:⎕EX ⍕⍺⊣⍺.⎕EX ⎕NL 2+⍳3 ⋄ ⎕SIGNAL 11}⎕THIS⊣⎕DF ⎕NULL ⍝ Delete our ∆MY namespace'
        ⎕FX 'myName← ∆NAME'    'myName← 0⊃⍙MyData'
        ⎕FX 'myNs←   ∆NS'      'myNs←   1⊃⍙MyData'
    :EndNamespace
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝     ∆MY, ∆MYX
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    inUseE  ←  '∆MY: static namespace not available:'
    inUseXE ← '∆MYX: static namespace not available: '
    callerXE← '∆MYX: Left Arg (caller''s ns) must be a namespace reference' 
    ∇ myNs←∆MY  
      ;auto;callerNs;myDF;myNm;myNsNm;si 
    ⍝ Optimized high-use equivalent of: ∆MYX 0 1
      callerNs←0⊃⎕RSI    
      :IF 2≤≢si←⎕SI 
          myNm myDF←⊂1⊃si                         ⍝ I. FAST PATH  
          :IF 0=≢myNm ⋄ myNm myDF←ANON ⋄ :Endif
      :Else ⋄ myNm myDF←EMPTY ⋄ :ENDIF 
      myNsNm←STATIC_PREFIX,myNm                   ⍝ II. FAST PATH 
      :Select callerNs.⎕NC⊂myNsNm 
          :Case 9.1                               ⍝ myNs exists; assumes ⎕DF updated on earlier ∆MY call.
              myNs←callerNs⍎myNsNm                ⍝ III. FAST PATH AND RETURN
          :Case 0
             :IF auto←1   ⍝ Automatically create if new...
                 myNs← callerNs myDF updateDF ⍎myNsNm callerNs.⎕NS STARTUP_ITEMS 
                 myNs.⍙MyData[0 1]←myNm myNs          
             :Else   ⍝ Return ⍬ if new...
                 myNs←⍬
             :EndIf 
          :Else 
             11 ⎕SIGNAL⍨inUseE,(⍕callerNs),'.',myNsNm
      :EndSelect     
     ∇

   ⍝ ACTIVE_updateDF ⍵: ⎕FIX-time option
   ⍝    ⍵=1: Use friendly display form (at cost of 20% of ∆MY call speed)
   ⍝         path.[∆MY].fn_name, where path might be #.ns1.ns2 and fn_name is the calling function for ∆MY.
   ⍝    ⍵=0: Use actual path name for ∆MY display form.
   ⍝ updateDF ⍵@R returns ⍵, ref for the namespace being updated.
     ∇  true←ACTIVATE_updateDF true
        :If true ⋄  updateDF←{ clr mydf←⍺ ⋄ ⍵⊣ ⍵.⎕DF (⍕clr),'.[∆MY].',mydf }
        :Else    ⋄  updateDF←⊢         
        :EndIf 
     ∇
     ACTIVATE_updateDF 1

     ∆MYX←{
    ⍝ myNs← [callerNs@R] ∆MYX args@(I B | S B)  
     ⍝ ;auto;callerNs;fnLvl;myNm;myNsNm;si;⎕IO
      ⍝ args: Either   fnLvl@I [auto=1]  OR  myNm@S [auto=1]
      ⍝ fnLvl:  An int n: get the n-th function on the stack after this one.
      ⍝         n=0: Get the function that called this one (1⊃⎕SI), in general ((1+n)⊃⎕SI).
      ⍝ myNm:   The simple name of the calling/queried function
      ⍝ auto:   1: If no ∆MYspace has been created for the fn, create and return its ref.
      ⍝         0: If no ∆MYspace has been created for the fn, don't create it; return ⍬. 
      ⍺←0⊃⎕RSI ⋄ callerNs←⍺  
      9≠⎕NC 'callerNs':  callerXE ⎕SIGNAL 11 
      (myNm myDF) auto←{  
          arg1 auto←2↑(⊆⍵),1   
          0=80|⎕DR arg1: ((0=≢myNm)⊃(myNm myNm) EMPTY) auto ⊣ myNm←arg1
          fnLvl←arg1 ⋄ si←2↓⎕SI 
          fnLvl≥≢si: EMPTY auto
          myNm←fnLvl⊃si  
          0≠≢myNm: (myNm myNm) auto
          ANON auto     
      }⍵
      myNsNm←STATIC_PREFIX,myNm                                       ⍝ FAST
      9.1=nc←callerNs.⎕NC⊂myNsNm: myNs←callerNs⍎myNsNm    ⍝ FAST
      0≠nc: 11 ⎕SIGNAL⍨inUseXE,(⍕callerNs),'.',myNsNm
      ~auto: ⍬
      myNs←callerNs myDF updateDF ⍎myNsNm callerNs.⎕NS STARTUP_ITEMS 
      myNs.⍙MyData[0 1]←myNm myNs  
      myNs            
    }

  ⍝ ∆OPTIM: See HELP below...
    ∆OPTIM←{⎕IO←0 ⋄ ⍺←1⊃⎕RSI 
      nm←⎕SI{0<≢⍵: ⍵ ⋄ 1⊃⍺}⍵
      qtd← '(''[^'']*'')+' ⋄ myNm←   '(?<!\.)∆MY\b'
      skip← '\0'           ⋄ myTrue← ⍕⍺ ∆MYX nm
      1: _←⍺.⎕FX qtd myNm ⎕R skip myTrue⍠'UCP' 1⊣⍺.⎕NR nm
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
  ⍝     function  ∆MYgrp.∆OPTIM
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
  ⍝  [caller_ns] ∆MYgrp.∆OPTIM  [fn | '']
  ⍝  Description: Takes the function name <fn> specified or ((1+⎕IO)⊃⎕SI) if 0-length
  ⍝  and replaces IN PLACE any use of the unprefixed name ∆MY  (i.e. ∆MY or ∆MY,anything) with
  ⍝  the name (string form) of the fn's ∆MY-space.  The caller_ns defaults to the calling fn's namespace.
  ⍝  Allows ∆MY functionality with minimal performance penalty.
  ⍝  Details: 
  ⍝    ∘ It initializes the ∆MY-space, leaving any initialization of ∆MY-space variables to 
  ⍝      the fn itself, e.g. via ∆MY.∆FIRST.
  ⍝    ∘ ∆MY prefixed in any way (##.∆MY or x∆MY) or followed by alphanumerics (∆MYx ∆MY2 etc) are ignored.
  ⍝      Put positively, ∆MY is replaced in:  ∆MY.∆FIRST, ∆MY.∆RESET, or ∆MY.someVariableName.
  ⍝    ∘ Any ∆MY within quotes like
  ⍝         '∆MY'   OR   'Oh, ∆MY!' 
  ⍝      is ignored. To check on the nameclass, etc., of ∆MY, 
  ⍝      Try:
  ⍝         my ← ∆MY ⋄  ⎕NC 'my'     OR    {⎕NC 'my'⊣ my←⍵} ∆MY
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
