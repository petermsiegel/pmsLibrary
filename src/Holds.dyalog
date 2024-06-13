 Holds

⍝ A :Hold on the same name will succeed only once in the workspace at one time.
⍝ Subsequent attempts (without the prior being released) should fail.
⍝ To wit:

 ⎕←':Hold ''test1'' #1'
 :Hold 'test1'
     ⎕←'   OK on hold ''test1'' #1'

     ⎕←'      :Hold ''test2'''
     :Hold 'test2'
         ⎕←'         OK on hold ''test2'''
         ⎕←'      Releasing ''test2'''
     :Else
         ⎕←'   Fail on hold ''test2'''
     :EndHold

     ⎕←'     :Hold ''test1'' #2'
     :Hold 'test1'
         ⎕←'         OK on hold ''test1 #2'
         ⎕←'      Releasing test1 #2'
     :Else
         ⎕←'      Fail on hold ''test1'' #2'
     :EndHold
     ⎕←'   Releasing ''test1'' #1'
 :Else
     ⎕←'   Fail on hold ''test1'''
 :EndHold
 'Done'
