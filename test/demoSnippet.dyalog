:namespace demoBigInt
::DEFINE VERBOSE←1

::IFDEF VERBOSE
     ::DEFINE note←___←1⊣⎕
::ELSE
     ::DEFINE note←___
::END 
 
 1 2 3
 ::MSG OK
 
    ∇ {_}←loadHelp
      :Trap 0
          _←⎕SE.SALT.Load'-target=',(⍕⎕THIS.##),' pmsLibrary/src/bigIntHelp'
      :Else
          _←⎕←'Unable to load bigIntHelp'
      :EndTrap
    ∇
    loadHelp
