:Namespace ∆DTest 
⎕←'Run:   RUN 1000   ⍝ Choose the dictionary size'

⍝ Local equiv. to d.RESTORE SAVE...
∇ {data}← LOCAL_RESTORE data
  KEYS VALS←data
∇

∇ TITLE text
  TT←'>>> ',text 
∇ 
∇ NL 
  ⎕←''
∇ 
∇ {res}←{dbg} RUN size
  ; d_IGNORE; half; BOXSAVE; t  
  ; CHOICES; KEYS; VALS; NEWKEYS; NEWVALS 
  ; GenKeys; GenUKeys 
  ; cmpx 

  :IF '#.∆DTest.∆DClass'≢⍕UCMD 'load ∆D'
       ⎕←'*** Couldn''t load ∆D'
   :EndIF  
  :IF 2=⎕NC 'dbg' 
      cmpx← {'0'}
      ⎕←'Debug mode'
  :Else 
     'cmpx' ⎕CY 'dfns'
     ⎕SHADOW '⎕TRAP'
     ⎕TRAP← 1000 'C' '⎕←''Interrupt!''⋄→'
  :ENDIF 

⍝ GenUKeys
⍝ ¯¯¯¯¯¯¯¯
⍝ l← GenUKeys count    
⍝    Generate <count> 8-character keys, all unique!
⍝    Keys are 7 chars in length and of the form:  
⍝          ACCCCCCC, where A∊⎕A and C∊⎕A,⎕D.
⍝    Note: If count ≥ approx. 2E12 keys, an infinite loop on GenUKeys becomes certain.
⍝          That said, a WS Full will happen long before!
⍝ GenKeys
⍝ ¯¯¯¯¯¯¯
⍝ l← {unique←total} GenKeys total 
⍝    Generate unique 8-char keys and distribute randomly
⍝    in a list of total keys, where unique and total are numbers:
⍝      ∘ unique ≤ total. If omitted, unique← total. 
⍝    If unique=total, there are no duplicate keys!
GenUKeys←{ ⍺←⍬ ⋄ 0≥∆← ⍵-≢⍺: ⍵↑⍺ ⋄ ⍵∇⍨ ∪⍺, (⎕A,⎕D)∘{ ⎕A[?≢⎕A], ⍺[?7⍴≢⍺] }¨⍳∆ }
GenKeys←{ ⍺←⍵ ⋄ ⍺=⍵: GenUKeys ⍵ ⋄ (⍵⍴GenUKeys ⍺)[?⍨⍵] }

⍝ Header 
⎕←(¯9↑'CPU in µs'),' ','Code Snippet'
⎕←(¯9↑'¯¯¯¯¯¯¯¯¯'),' ','¯¯¯¯¯¯¯¯¯¯¯¯'
⍝ End Header

LAST_TT←⎕NULL 
Try← { cod←'"' ⎕R ''''⊣⍵ ⋄ ⎕←cod ⋄ 85:: _←⍬ ⋄ 1: ⎕←1(85⌶)cod}
TryT← { 
  cod←'"' ⎕R ''''⊣⍵ 
  keep← TT≢LAST_TT  ⋄ LAST_TT∘← TT 
  ⎕← (,'CI9'⎕FMT 1E6×⍎cmpx cod),' ',(40↑cod), keep/TT 
  85:: _←⍬ ⋄ ⎕←1(85⌶)cod 
}
 
half←⌈size×0.5 
KEYS← half GenKeys size 
VALS← ⍳≢KEYS 
NEWKEYS←  (half↑KEYS),GenKeys half
NEWVALS←  VALS⍴⍨ ≢NEWKEYS 

BOXSAVE← 4↓UCMD 'box on -fns=on'

TITLE 'Create dict of ',size,'items'
TryT 'd← ∆DL KEYS VALS'

TITLE 'Add',size,'items, half old half new'
TryT 'd[NEWKEYS]←NEWVALS'
SAVE←d.(Keys Vals)
NL

CHOICES← 1 2 
:IF 1∊CHOICES 
  :For count :IN 1 250 500 1000 5000 10000 50000
      iN← ?count⍴d.Tally 
      TITLE 'Retrieve iN←',(⍕count),' items'
      TryT '_←d.ItemsNaive[iN]'
      TryT '_←d.Items[iN]' 
      TryT '_←↓⍉↑(d.Keys[iN])(d.Vals[iN])'
      TryT '_←d.(↓⍉↑Keys Vals)[iN]'
      TryT '_←{d.Keys[⍵], d.Vals[⍵]}¨iN'
      NL 
   :EndFor 
:EndIf 

:IF 2∊CHOICES  
  TITLE 'Delete 1000 items by randomly distributed keys'
  keys1000← d.Keys[?1000⍴d.Tally]
  :IF 1000≠≢keys1000 ⋄ ⎕←' keys1000 wrong size ' ⋄ :ENDIF 
  ⍝ ⎕←¯10↑keys1000 
  TryT '_←d.Del keys1000⊣d.RESTORE SAVE'
  d.RESTORE SAVE ⋄ keep← ~KEYS∊keys1000 ⋄ ⎕EX 'keys1000'
  TryT 'KEYS VALS/⍨← ⊂keep⊣ (KEYS VALS∘←SAVE)'
  TITLE 'Delete the last 1000 items'
  last1000← ¯1000↑d.Keys 
  :IF 1000≠≢last1000 ⋄ ⎕←' last1000 wrong size ' ⋄ :ENDIF 
  ⍝ ⎕←¯10↑last1000 
  TryT '_←d.Del last1000⊣d.RESTORE SAVE'
  TryT 'KEYS VALS ↓⍨←¯1000⊣(LOCAL_RESTORE SAVE)'
  d.RESTORE SAVE  ⋄ ⎕EX 'last1000'
  TITLE 'Clear (delete) all items'
  TryT '_←d.Clear⊣d.RESTORE SAVE' 
  NL
:EndIF 

t← UCMD 'box ',BOXSAVE 
res←0
∇

##.RUN← ⍎ '⍙me' ⎕R (⍕⎕THIS)⊣'{⍺←⊢ ⋄ ⍺ ⍙me.RUN ⍵}' 
⎕PATH←'# ⎕SE'
:EndNamespace 
