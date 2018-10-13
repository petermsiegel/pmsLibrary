### To have `require` available at startup of a Dyalog APL session.
1. Find directory `MyUcmdsInfo` supplied by dyalog. It's often in your home directory.
1. Add material below to `MyUCmdsInfo/Setup.dyalog` or see ___Setup.dyalog___.
This makes sure that `require` is loaded into `⎕SE` so it's available for the entire session.
(This can't apparently be used to set `⎕PATH`, hence step #2).
1. Create a new user command in MyUcmdsInfo, e.g. `MyUcmdsInfo/MyCmds.dyalog` or copy the file ___PMScmds.dyalog___ into MyUcmdsInfo.
We'll set this up to create a command called `]require`. When called with no args, `]require` does two things:
   - Ensures that function `require` is copied into the `⎕SE` namespace, if _not_ already there.
   - Ensures that `⎕PATH` in whatever is the __current__ namespace has `⎕SE` within the search order. It _won't_ add `⎕SE` if it's already there.
1. ]require may also be used with args. This simply runs ⎕SE.require _monadically_, splitting the right argument into 1 or more strings, and returning explicitly the (normally shy) output:<br>
   `]require pkg1 pkg2 ... pkgN`<br>
   Note: __]require__ creates the default library `⍙⍙.require` in the current namespace, _i.e._ from wherever it is called (by default `#`), and sets its local `⎕PATH`.  If you are in namespace `#.mynamespace`, then `#.mynamespace.⍙⍙.require` receives any newly loaded packages, and  `#.mynamespace.⎕PATH` is updated. However, if `⎕PATH` already points to other libraries containing the requested packages, no additional work is done.

### Material to enable easy use of `require` during a Dyalog APL session.
#### Add this fragment to `MyUCmdsInfo/Setup.dyalog`

```
⍝ BEGIN:   PMS 20181011
⍝ We load up require into ⎕SE.
⍝ Use ]require after launch to set ⎕PATH. Dyalog seems to clear ⎕PATH after this executes!
  ⎕SE.SALT.Load'pmsLibrary/src/require -target=⎕SE'    ⍝ Removed (no effect) #.⎕PATH←'⎕SE'
⍝ END:     PMS 20181011
```

#### Create a new user command in MyUCmdsInfo directory. 
- We call ours `MyUCmdsInfo/PMSCmds.dyalog`. Its _complete_ contents are below.

```
:Namespace PMScmds
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
              r←⊂'Loaded "require" into ⎕SE'
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
              r←⊂']require was already active'
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
          r,←⊂'         ]??require'
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
```
