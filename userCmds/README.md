### To have `require` available at startup of a Dyalog APL session.
1. Find directory `MyUcmdsInfo` supplied by dyalog. It's often in your home directory.
1. Add material below to `MyUCmdsInfo/Setup.dyalog` or see ___Setup.dyalog___.
This makes sure that `require` is loaded into `⎕SE` so it's available for the entire session.
(This can't apparently be used to set `⎕PATH`, hence step #2).
1. Create a new user command in MyUcmdsInfo, e.g. `MyUcmdsInfo/MyCmds.dyalog` or copy the file ___PMScmds.dyalog___ into MyUcmdsInfo.
We'll set this up to create a command called `]require`. <br>

#### Arguments: Specifying objects to load
1. `]require`, when called with no args, does two things:
   - Ensures that function `require` is copied into the `⎕SE` namespace, if _not_ already there.
   - Ensures that `⎕PATH` in whatever is the __current__ namespace has `⎕SE` within the search order. It _won't_ add `⎕SE` if it's already there.
   
1. ]require may be used with args:
   `]require pkg1 pkg2 ... pkgN`<br>
   This calls `require 'pkg1'  'pkg2'` ... `'pkgN'` <br>
  
#### Options: Specifing library namespace; forcing objects to be reloaded.

1. If you would like to __override the standard library__, `-lib=ns` allows you to specify another named namespace, such as #, ⎕SE, etc. Here, we put packages `pkg1`...`pkgN` into the root namespace `#`.<br>
   `]require -lib=# pkg1 pkg2 ... pkgN`          <br>
   Note: __]require__ creates the default library `⍙⍙.require` in the current namespace, _i.e._ from wherever it is called (by default `#`), and sets its local `⎕PATH`.  If you are in namespace `#.mynamespace`, then `#.mynamespace.⍙⍙.require` receives any newly loaded packages, and  `#.mynamespace.⎕PATH` is updated. However, if `⎕PATH` already points to other libraries containing the requested packages, no additional work is done.
   `]require -force [-lib=...] pkg1 pgk2 ... pkgN` <br>
   
2. To __force__ an object to be loaded (or reloaded), even if it's either in the current (caller) namespace, in the ⎕PATH (e.g. loaded into a library via a previous `require` command), specify the __-force__ or __-f__ option first on the ]require command line.
   __-force__ must be first for ]require. The APL `require` function allows `'-force'` or `'-f'` to appear anywhere.

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

