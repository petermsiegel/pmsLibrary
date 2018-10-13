:Namespace PMSCmds
⍝ Custom user command

    ⎕IO←0 ⋄ ⎕ML←1

    ∇ r←List
      r←⎕NS¨1⍴⊂⍬
    ⍝ Name, group, short description and parsing rules
      r.Name←⊂'require'
      r.Group←⊂'PMS'
      r[0].Desc←'Help text to appear for ] -?? and ]require -?'
      r.Parse←⊂'' ⍝ ENTER NUMBER OF ARGS AND OPTIONALLY -modifiers HERE
    ∇

    ∇ r←Run(cmd input);CALLER
      :Select cmd
      :Case 'require'
          r←⍬
          CALLER←⊃(4↓⎕RSI),#      ⍝ There are 4 levels of calls before Run!

          :IF 0=⎕SE.⎕NC 'require'
              ⎕SE.SALT.Load'pmsLibrary/src/require -target=⎕SE'
              r←⊂'Loaded fn "require" into ⎕SE'
          :ENDIF
          :IF  0=≢'(^|\h)⎕SE(\h|$)'⎕S 0⊣CALLER.⎕PATH
              CALLER.⎕PATH,⍨←'⎕SE '
              r←⊂'Adding ⎕SE to ',(⍕CALLER),'.⎕PATH'
          :ENDIF

          :IF 0≠≢input~' '
              r←((⍕CALLER),'.[LIB]') ⎕SE.require  (≠∘' '⊆⊢)input
              →0
          :ENDIF

          :IF 0=≢r
              r←⊂']require is active.'
          :ENDIF
          r←↑r
      :EndSelect
    ∇

    ∇ r←level Help cmd
      :Select cmd
      :Case 'require'
          r←⊂']require loads ⎕SE.require (as needed) and adds to ⎕PATH in current namespace (if needed).'
          r,←⊂' Useful to ensuring that current namespace can find function require.'
          r,←⊂' Function require:'
          r,←⊂'     Is used to verify that objects are in the current namespace or the ⎕PATH.'
          r,←⊂'     If not, loads them from requested workspace, directory, or file.'
          r,←⊂'     For HELP, type:'
          r,←⊂'         ]??require    OR  ]require -HELP'
          r,←⊂'     OR'
          r,←⊂'         require ''-HELP'' '
          r,←⊂']require (with no arguments)'
          r,←⊂'     executes:  ⎕SE.SALT.Load ''pmsLibrary/src/require -target=⎕SE'''
          r,←⊂']require  pkg1  pkg ...'
          r,←⊂'     executes:  require ''pkg1'' ''pkg2'' ...'
          r←↑r
      :EndSelect
       ⎕←level
      :IF level≥1
           ⎕SE.require '-HELP'
       :ENDIF
      ∇

:EndNamespace
