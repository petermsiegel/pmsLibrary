:namespace demoBigInt
::DEFINE VERBOSE←1

::IFDEF VERBOSE
     ::DEFINEL note←___←1⊣⎕←
::ELSE
     ::DEFINEL note←___
::END 
 
 note 'abc'
 
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
