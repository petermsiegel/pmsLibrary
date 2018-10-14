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

    ∇ r←Run(cmd input);CALLER
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
              r←((⍕CALLER),'.[LIB]') ⎕SE.require  (≠∘' '⊆⊢)input
              →0
          :ENDIF

          :IF 0=≢r
              r←⊂']require is active.'
          :ENDIF
          r←↑r
      :Case 'dc'
            {}'⎕SE.[LIB]'⎕SE.require 'bigInteger'    ⍝ We'll execute from session
          ⎕←'For help, type ''?'' at any prompt.'
          bi.dc
          r←''
      :EndSelect
    ∇

    ∇ r←level Help cmd

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
            r←↑r
         :Else
            r←']require -HELP launched in full screen.'
            ⎕SE.require '-HELP'
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
            r←↑r
      :EndSelect
      ∇

      ∇{checked}←checkRequire
        :IF checked←0=⎕SE.⎕NC 'require'
              ⎕SE.SALT.Load'pmsLibrary/src/require -target=⎕SE'
        :ENDIF
      ∇
:EndNamespace
