 ∆FOpts←{
⍝ Options:   ('Mode' [1|0|¯1|¯2])('Debug' [1|0]) ('EscCh' ['char'])
⍝            ('UseNs' [1|0]) ('ExtLib' [1|0])
⍝ Default:   'Mode' (if only a single number is presented)
  0::'Invalid option(s)'⎕SIGNAL 11
  (1=≢⍵)∧(1≥|≡⍵):⍵
    ns←⎕NS ⍬ ⋄ opts←⊂⍣(2=|≡⍵)⊢⍵
    defs←('Mode' 1)('Debug' 0)('EscCh' '`')('UseNs' 0)('ExtLib' 1)
  0∊∊/⊃¨¨opts defs:'Unknown option(s)'⎕SIGNAL 11
    _←ns.{⍎⍺,'←⍵'}/¨defs,opts
    ns.(Mode Debug EscCh UseNs ExtLib)
 }
