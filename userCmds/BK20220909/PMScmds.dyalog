:Namespace PMScmds

 ⍝  Custom user commands
    ⎕IO←0 ⋄ ⎕ML←1

    ∇ r←List
      r←⎕NS¨2⍴⊂⍬
    ⍝ Name, group, short description and parsing rules
      r.Name←'require' 'dc'
      r.Group←⊂'PMScmds'
      r[0].Desc←']req(uire): manage packages, loading from workspaces or dyalog files as required.'
      r[1].Desc←']dc:        run a big integer desk calculator.'
      r.Parse←⊂''         ⍝ ENTER NUMBER OF ARGS AND OPTIONALLY -modifiers HERE
    ∇

    ∇ {r}←Run(cmd input);CALLER;LIB;ns;pat;defaultLib
      CALLER←##.THIS

      :Select  ⎕C cmd
      :Caselist 'require' 'req'
          r←⍬
          :IF checkRequire
              r,←⊂'Loaded user cmd ]require. Callable as  ⎕SE.∆REQ'
          :ENDIF
          :IF  0=≢' ⎕SE '⎕S 0⊣' ',CALLER.⎕PATH,' '
              CALLER.⎕PATH,⍨←'⎕SE '
              r,←⊂'Adding ⎕SE to ',(⍕CALLER),'.⎕PATH'
          :ENDIF
          :IF 0≠≢input~' '
            ⍝ Force the output into tabular (row) format (from a PAIR of simple vector of vectors)
            ⍝ Allow options: [-f|-force]   -lib=library   (-f or -force must be first)
              r←⎕SE.∆REQ input
              →0
          :ELSE
              r←⊂']require is active.'
          :ENDIF
      :Case  'dc' 
          checkRequire
          ⍝ Execute in # (if in ⎕SE, can create ⎕SE←→# problems for )saving).
          ⍝ Note: an HTML renderer in bi.dc has been modified to run in user # space.
	    (⎕SE.∆REQ 'BigInt').BigInt.BI_DC
            r←''
      :EndSelect
    ∇

    ∇ {r}←level Help cmd
      checkRequire
      :Select   ⎕C cmd
      :Caselist 'require' 'req'         ⍝ Be sure require is loaded.
         :IF level<1
            r←⊂']require loads ⎕SE.require (as needed) and adds to ⎕PATH in current namespace (if needed).'
            r,←⊂' Useful to ensuring that current namespace can find function require.'
            r,←⊂' Function  ⎕SE.∆REQ:'
            r,←⊂'     Is used to verify that objects are in the current namespace or the ⎕PATH.'
            r,←⊂'     If not, loads them from requested workspace, directory, or file.'
            r,←⊂'     For HELP, type:'
            r,←⊂'         ]??require'
            r,←⊂'     OR'
            r,←⊂'          ⎕SE.∆REQ ''-HELP''' 
            r,←⊂']require (with no arguments)'
            r,←⊂'     executes:  ⎕SE.SALT.Load ''pmsLibrary/src/∆REQ -target=⎕SE'''
            r,←⊂']require  pkg1  pkg ...'
            r,←⊂'     executes:   ⎕SE.∆REQ ''pkg1'' ''pkg2'' ...'
            r,←⊂']require [-force] [-session | -root | -local]  pkg1 pkg ...'
            r,←⊂'     executes:   require ''pkg1'' ''pkg2'' ...'
            r,←⊂' i.e. loads (new) packages into library ns, a namespace or root (# or ⎕SE)'
            r,←⊂'     -force      Forces packages to be loaded, even if present in caller NS or ⎕PATH.'
            r,←⊂'     -     Searches and loads packages into specified namespace.'
            r,←⊂'     -s[ession]  Puts results in library ⎕SE.⍙⍙.⍙'
            r,←⊂'     -r[oot]     Puts results in library #.⍙⍙.⍙'
	    r,←⊂'     -local     Puts results in library [caller].⍙⍙.⍙, where [caller] is the namespace ∆REQ was called from.  '
            r,←⊂'Returns the namespace(s) for the specified object(s).'
            r,←⊂'    '
            r,←⊂'Note: require searches disk directories specified in environment variables FSPATH and WSPATH.'
            r,←⊂'      See ]require -HELP for more information.'
         :Else
            {}⎕SE.∆REQ '-HELP'
            r←⊂']require -HELP launched in full screen.'
         :ENDIF
      :Case 'dc'  
            r←⊂']dc interactively executes APL mathematical'
            r,←⊂'  statements using arbitrary-precision (big) integers.'
            r,←⊂'  Numbers must be integers of 1 or more digits; either ¯ or - may be used'
            r,←⊂'  for minus signs; underscores (_) may be used to separate digits in numbers.'
            r,←⊂'  ⍵ represents the prior answer. variables may be assigned to and used.'
            r,←⊂']dc (no args)'
            r,←⊂'    enters interactive desk calculator mode.'
            r,←⊂'    A single period (.) terminates dc mode. Ctrl-c interrupts it.'
            r,←⊂'    For HELP at any time, enter a lone ? (question mark) after the prompt.'
            :IF level≥1
                r,←⊂'For more information, see the <bigInteger> package and BigInt.HELP.'
            :ENDIF
      :EndSelect
      r←↑r
      ∇

      ∇{checked}←checkRequire
        :IF checked←0=⎕SE.⎕NC '⎕SE.∆REQ' 
              ⎕SE.SALT.Load'pmsLibrary/src/require -target=⎕SE'
        :ENDIF
        :IF  0=≢' ⎕SE '⎕S 0⊣' ',#.⎕PATH,' '
              #.⎕PATH,⍨←'⎕SE '
        :ENDIF
      ∇
:EndNamespace
