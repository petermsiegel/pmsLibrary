:Namespace PMScmds

 ⍝  Custom user commands
    ⎕IO←0 ⋄ ⎕ML←1

    ∇ r←List
      r←⎕NS¨2⍴⊂⍬
    ⍝ Name, group, short description and parsing rules
      r.Name←'require' 'dc'
      r.Group←⊂'PMScmds'
      r[0].Desc←']require: manage packages, loading from workspaces or dyalog files as required.'
      r[1].Desc←']dc:      run a big integer desk calculator.'
      r.Parse←⊂''         ⍝ ENTER NUMBER OF ARGS AND OPTIONALLY -modifiers HERE
    ∇

    ∇ r←Run(cmd input);CALLER;LIB;pat;defaultLib
      CALLER←##.THIS

      :Select cmd
      :Case 'require'
          r←⍬

          :IF checkRequire
              r,←⊂'Loaded fn "require" into ⎕SE'
          :ENDIF

          :IF  0=≢'(^|\h)⎕SE(\h|$)'⎕S 0⊣CALLER.⎕PATH
              CALLER.⎕PATH,⍨←'⎕SE '
              r,←⊂'Adding ⎕SE to ',(⍕CALLER),'.⎕PATH'
          :ENDIF

          :IF 0≠≢input~' '
            ⍝ Force the output into tabular (row) format (from a PAIR of simple vector of vectors)
            ⍝ Allow options: [-f|-force]   -lib=library   (-f or -force must be first)
              defaultLib←'-lib=[CALLER].[LIB]'
              pat←'-lib=([^ ]+)'
              LIB←,⊃pat ⎕S '\1'⊣input,' ',defaultLib
              opts←('CALLER' CALLER) LIB
              :IF force←1∊'-f'⍷input
                 input←'^\h*-f(orce)?' ⎕R ''⊣input
                 opts,⍨←⊂'-f'
              :ENDIF
              r←opts ⎕SE.require (≠∘' '⊆⊢)pat ⎕R ' '⊣input
              r←⍪⍪¨r
              →0
          :ENDIF

          :IF 0=≢r
              r←⊂']require is active.'
          :ENDIF
          r←↑r
      :Case 'dc'
          checkRequire
          ⍝ Execute in # (if in ⎕SE, can create ⎕SE←→# problems for )saving).
          ⍝ Note: an HTML renderer in bi.dc has been modified to run in user # space.
            {}('CALLER' CALLER)'#.[LIB]'⎕SE.require 'bigInt'
          ⎕←'For help, type ''?'' at any prompt.'
          bi.dc
          r←''
      :EndSelect
    ∇

    ∇ {r}←level Help cmd
      checkRequire
      :Select cmd
      :Case 'require'         ⍝ Be sure require is loaded.
         :IF level<1
            r←⊂']require loads ⎕SE.require (as needed) and adds to ⎕PATH in current namespace (if needed).'
            r,←⊂' Useful to ensuring that current namespace can find function require.'
            r,←⊂' Function require:'
            r,←⊂'     Is used to verify that objects are in the current namespace or the ⎕PATH.'
            r,←⊂'     If not, loads them from requested workspace, directory, or file.'
            r,←⊂'     For HELP, type:'
            r,←⊂'         ]??require'
            r,←⊂'     OR'
            r,←⊂'         require ''-HELP'' '
            r,←⊂']require (with no arguments)'
            r,←⊂'     executes:  ⎕SE.SALT.Load ''pmsLibrary/src/require -target=⎕SE'''
            r,←⊂']require  pkg1  pkg ...'
            r,←⊂'     executes:  require ''pkg1'' ''pkg2'' ...'
            r,←⊂']require [-f] -lib=ns pkg1 pkg ...'
            r,←⊂'     executes:  ns require ''pkg1'' ''pkg2'' ...'
            r,←⊂' i.e. loads (new) packages into library ns, a namespace or root (# or ⎕SE)'
            r,←⊂'     -f: forces packages to be loaded, even if present in caller NS or ⎕PATH.'
            r,←⊂'         For ]require, -f (variant: -force) must be first, to avoid conflict with files.'
            r,←⊂'     -lib=ns: searches and loads packages into specified namespace.'
         :Else
            {}⎕SE.require '-HELP'
            r←⊂']require -HELP launched in full screen.'
         :ENDIF
      :Case 'dc'
            r←⊂']dc interactively executes APL mathematical'
            r,←⊂'  statements using arbitrary-precision (big) integers.'
            r,←⊂'  Numbers must be integers of 1 or more digits; either ¯ or - may be used'
            r,←⊂'  for minus signs; underscores (_) may be used to separate digits in numbers.'
            r,←⊂'  ⍵ represents the prior answer. variables may be assigned to and used.'
            r,←⊂']dc (no args)'
            r,←⊂'    enters interactive desk calculator mode.'
            r,←⊂'    A single period (.) terminates dc mode. Ctrl-c interrupts it.'
            r,←⊂'    For HELP at any time, enter a lone ? (question mark) after the prompt.'
            :IF level≥1
                r,←⊂'For more information, see the <bigInteger> package and bi.HELP.'
            :ENDIF
      :EndSelect
      r←↑r
      ∇

      ∇{checked}←checkRequire
        :IF checked←0=⎕SE.⎕NC 'require'
              ⎕SE.SALT.Load'pmsLibrary/src/require -target=⎕SE'
        :ENDIF
        :IF  0=≢'(^|\h)⎕SE(\h|$)'⎕S 0⊣#.⎕PATH
              #.⎕PATH,⍨←'⎕SE '
        :ENDIF
      ∇
:EndNamespace
