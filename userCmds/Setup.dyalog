 Setup
 ⎕←'Setup routine is run at APL startup ...'

⍝ BEGIN:   PMS 20181011
⍝ We load up require into ⎕SE.
⍝ Use ]require after launch to set ⎕PATH. Dyalog seems to clear ⎕PATH after this executes!
  ⎕SE.SALT.Load'pmsLibrary/src/require -target=⎕SE'    ⍝ Removed (no effect) #.⎕PATH←'⎕SE'   
⍝ END:     PMS 20181011

  ⎕←'⎕SE.SALT.Save''Setup '',⎕SE.SALTUtils.USERDIR,''MyUcmds\ -makedir'''
⍝)(!Setup!petermsiegel!2018 3 28 19 24 50 0!0
