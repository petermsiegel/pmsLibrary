### To have `require` available at startup of a Dyalog APL session.
1. Find directory `MyUcmdsInfo` supplied by dyalog. It's often in your home directory.
1. Add material below to `MyUCmdsInfo/Setup.dyalog`.
This makes sure that `require` is loaded into `⎕SE` so it's available for the entire session.
(This can't apparently be used to set `⎕PATH`, hence step #2).
1. Create a new user command in MyUcmdsInfo, e.g. `MyUcmdsInfo/MyCmds.dyalog`.
We'll set this up to create a command called `]require`. When called, `]require` does two things:
   - Ensures that function `require` is copied into the `⎕SE` namespace, if _not_ already there.
   - Ensures that `⎕PATH` in whatever is the __current__ namespace has `⎕SE` within the search order. It _won't_ add `⎕SE` if it's already there.

### Material to enable easy use of `require` during a Dyalog APL session.
#### add this to `MyUCmdsInfo/Setup.dyalog`

```
⍝ BEGIN:   PMS 20181011
⍝ We load up require into ⎕SE.
⍝ Use ]require after launch to set ⎕PATH. Dyalog seems to clear ⎕PATH after this executes!
  ⎕SE.SALT.Load'pmsLibrary/src/require -target=⎕SE'    ⍝ Removed (no effect) #.⎕PATH←'⎕SE'
⍝ END:     PMS 20181011
```

#### Create a new user command in MyUCmdsInfo directory. 
- We call ours MyUCmdsInfo/PMSCmds.dyalog

```
:Namespace PMSCmds
⍝ Custom user command ](PMSCmds.)require

    ⎕IO←0 ⋄ ⎕ML←1

    ∇ r←List
      r←⎕NS¨1⍴⊂⍬
    ⍝ Name, group, short description and parsing rules
      r.Name←⊂'require'
      r.Group←⊂'PMS'
      r[0].Desc←'Help text to appear for ] -?? and ]MYCMDS -?'
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
          :IF  0=≢'(^| )⎕SE( |$)'⎕S 0⊣CALLER.⎕PATH
              CALLER.⎕PATH,⍨←'⎕SE '
              r←⊂'Adding ⎕SE to ',(⍕CALLER),'.⎕PATH'
          :ENDIF
          :IF 0=≢r
              r←⊂']require was already active'
                      :ENDIF
          :IF  0=≢'(^| )⎕SE( |$)'⎕S 0⊣CALLER.⎕PATH
              CALLER.⎕PATH,⍨←'⎕SE '
              r←⊂'Adding ⎕SE to ',(⍕CALLER),'.⎕PATH'
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
          r←⊂' Useful to ensuring that current namespace can find function require.'
          r←⊂' Function require:'
          r←⊂'     Used to verify that objects are in the current namespace or the ⎕PATH.'
          r←⊂'     If not, loads from requested workspace, directory, or file.'
          r←⊂'     See require.help'
          r,←⊂']require executes:'
          r,←⊂' ⎕SE.SALT.Load ''pmsLibrary/src/require -target=⎕SE'''
          r←↑r
      :EndSelect
    ∇

:EndNamespace
```
