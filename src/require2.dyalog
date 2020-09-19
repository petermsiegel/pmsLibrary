 require2←{

 ⍝ specs:         spec1 [ ⋄ spec2  [ ⋄ spec3 ... ] ]
 ⍝   specN:       name options
 ⍝     name:      name of APL object-- may include ⎕SE or #
 ⍝     options:   from dir | fromws APLws | as objName
 ⍝                - Up to two options may appear in any order, case is ignored.
 ⍝                - If name is *, from or fromws MUST appear.
 ⍝                - fromws APLws  => from APLws:: (with :: suffix)
 ⍝ ------
 ⍝ Note 1: Each item must be a valid name w/o blanks or be placed in quotes (single or double).
 ⍝         - Names, directories, and (as) objects (name, dir, objName) need not be quoted
 ⍝           unless they include blanks
 ⍝ Note 2: An APL statement separator ⋄ will separate each specification from the next.
 ⍝         It may not appear in identifiers, even if quoted...
     DEBUG←1
     CALLER←⊃⎕RSI 
     ⎕IO←0
     Err←⎕SIGNAL∘11

⍝ ------ UTILITIES
⍝ ∆F:  Find a pcre field by name or field number
     ∆F←{⎕IO←0
         N O B L←⍺.(Names Offsets Block Lengths)
         def←'' ⋄ isN←0≠⍬⍴0⍴⍵
         p←N⍳∘⊂⍣isN⊣⍵ ⋄ 0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def
         B[O[p]+⍳L[p]]
     }
 ⍝ ∆R: Replace names of the form ⍎XXX in a string with its executed value in the calling context (in string form)...
     ∆R←{⍺←10                                          ⍝ Recurse a max of <⍺> times.
         ⍺≤0:⍵                                         ⍝ Done?
         S←'⍎[\w∆⍙#⎕\.]+'⎕R{
             f0←⍵ ∆F 0
             0::Err'∆R: Error evaluating ''',f0,''''
             ⍕(⍬⍴⎕RSI).⍎1↓f0}⍠('UCP' 1)⊣⍵
         ⍵≡S:S ⋄ ~'⍎'∊S:S                           ⍝ No change or no ⍎? Done.
         (⍺-1)∇ S                                      ⍝ Possibly more.
     }

  ⍝ ========= MAIN

     ScanTokens←{STAR COL2←'*' '::'
         fromStarE←'require2: Objectlist "*" (ALL) must have an explicit "from" spec.'
         badTokE←'require2 logic error: ScanTokens received invalid # of tokens'

         tok5←'\r'⎕R'\r'⊣⊆⍵    ⍝ Convert newline obj to vector of strings.
         5≠≢tok5:Err badTokE
         O F FF A AA←tok5
         F FF←F{
             ('fromws'≡⍺)∧COL2≢¯2↑⍵:'from'(⍵,COL2) ⋄ 'from'⍵
         }FF
         (O≡,STAR)∧0=≢FF:Err fromStarE
         O(⊂(F FF)(A AA))
     }¨

     ∆←'[\h⋄;]*'
     W←'  (?:(?:"[^"]+")+ | (?:''[^'']+'')+ | [^\h⋄;]+) '  ⍝ tok   (sub)pattern
     M1←∆R'(?xxi) ⍎∆ (⍎W)   \h+ FROM\h*(WS|) \h+ (⍎W) (?| \h+ AS ⍎∆ (⍎W)|()) '
     M2←∆R'(?xxi) ⍎∆ (⍎W)   \h+ AS ⍎∆ (⍎W)            (?| \h+ FROM\h*(WS|) \h+ (⍎W)|()()) '
     M3←∆R'(?xxi) ⍎∆ (⍎W)'
     A1 A2 A3←'\1\rfrom\l2\r\3\ras\r\4' '\1\rfrom\l3\r\4\ras\r\2' '\1\rfrom\r\ras\r'

  source←⍵
⍝ Capture options 
⍝    -f: force, -r: root (envR←#), -s :⎕SE (envR←⎕SE), -q: quiet
⍝    -e environment: envR, -l library: libS 
   force envR libS quiet testS skip←0 CALLER  '⍙'  0 '[none]' 0

   W WX←'([^\h]+)'  '((?:"[^"]*")+|(?:''[^'']*'')+|[^\h]+)'
   noQ←{w1←⊃⍵ ⋄  w1(~∊)'''"': ⍵ ⋄ w←1↓¯1↓⍵ ⋄  w1='"': w/⍨~'""'⍷w⋄ w }
⍝          0      1      2      3      4             5            6            7             8
   matchP←'-f\b' '-r\b' '-s\b' '-q\b' ('-e\h+',W)  ('-l\h+',W)  ('-t\h+',WX)  '-[a-zA-Z]+'  '--'
   source←matchP ⎕R {
   cF cR cS cQ cE cL cT cOther cSkip←⍳9
       skip: ⍵ ∆F 0
       case←⍵.PatternNum∘=
       case cF: ''⊣force∘←1       ⋄    case cR: ''⊣envR∘←#
       case cS: ''⊣envR∘←⎕SE      ⋄    case cQ: ''⊣quiet←1
       case cE: ''⊣envR∘←{envStr←⍵ 
            0:: 11 ⎕SIGNAL⍨'Unable to validate environment: "','"',⍨envStr
           ⎕← ns←CALLER.⎕NC envStr
            ns=9: ⍎envStr CALLER.⎕NS ''  
            ns=0: 11 ⎕SIGNAL⍨ 'Calling environment must already exist: "','"',⍨,envStr
            11 ⎕SIGNAL⍨'Calling environment in use or invalid: "','"',⍨envStr
       } ⍵ ∆F 1
       case cL: ''⊣libS∘←⍵ ∆F 1   
       case cT:''⊣testS∘←noQ ⍵ ∆F 1
       case cSkip: ''⊣skip∘←1
    ⍝  case cOther
       11 ⎕SIGNAL⍨'Invalid option: "','"',⍨⍵ ∆F 0    ⍝ 6 or fall-through
   }⍠('UCP' 1)⊣source

     ns←envR.⎕NC libS
     ~ns∊0 9: 11 ⎕SIGNAL⍨'Library name in use or invalid: ',(⍕envR),'.',libS
     libExists←9=ns 
   
   _←DEBUG{~⍺:⍬
     ⎕←'force=',⍕force ⋄ ⎕←'envR=',⍕envR
     ⎕←'quiet=',⍕quiet ⋄ ⎕←'libS=',⍕libS ⋄ ⎕←'libExists=',⍕libExists
     ⎕←'test string=¨',testS,'¨'
     ⍬
   }0
⍝ Decode each instruction "obj [from[ws] xxx[::]] [as yyy]" and process one by one.
     ScanTokens M1 M2 M3 ⎕S A1 A2 A3⊣⊆source
 }
