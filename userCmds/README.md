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
   If you would like to override the standard library, `-lib ns` allows you to specify another named namespace, such as #, ⎕SE, etc.<br>
   `]require -lib # pkg1 pkg2 ... pkgN`          (Put pgks right in the top-level namespace)<br>
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
- We call ours `MyUCmdsInfo/PMScmds.dyalog`. See __pmsLibrary/userCmds/PMScmds.dyalog__.

