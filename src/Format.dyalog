:namespace Format
  ⍝ Set to 1 to suppress error trapping...
    DEBUG←0
    ⎕FX '{msg}←_CSAY msg' ':IF DEBUG ⋄ ⎕←''>>> '',msg ⋄ :ENDIF'
    _CSAY 'DEBUG is active'

    :Section For Documentation, see Section "Documentation"
⍝  ∆FMT - a modest Python-like APL Array-Oriented Format Function
⍝
⍝  Generate and Return a 1 or 2D Formatted String
⍝      string←  [⍺0 [⍺1 ...]] ∆FMT specification [⍵0 [⍵1 ... [⍵99]]]]
⍝
⍝  Displays Format Help info!
⍝               ∆FMT ⍬
    :EndSection

    ⎕IO←0
    CR←⎕UCS 13  ⋄ DQ SQ←'"'''

⍝ ------ PMSLIB "STANDARD" UTILITIES
    :Section PMSLIB
     ⍝ ∆F:  Find a pcre field by name or field number
      ∆F←{N O B L←⍺.(Names Offsets Block Lengths)
          def←'' ⋄ isN←0≠⍬⍴0⍴⍵
          p←N⍳∘⊂⍣isN⊣⍵ ⋄ 0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def
          B[O[p]+⍳L[p]]
      }

    ⍝ GenBalanced: generates a pattern that matches balanced parens or equivalent,
    ⍝  P ← GenBalanced '()'
    ⍝  (Default) Recursive, matches balanced delimiters, skipping embedded single-quoted or double-quoted strings.
    ⍝         skipping embedded SQ strings, DQ strings.
    ⍝         fails on unbalanced braces, e.g. a single left or right brace.
      GenBalanced←{L R←'\',¨⍵
          Nm←'bal',⍕bpCount_ ⋄ bpCount_+←1     ⍝ local N- unique pattern-internal name.
          _p←'(?x)(?<'Nm'> 'L,CR
          _p,←'      (?>    (?: \\['L''R'])+ | [^'L''R'\\"'']+      ',CR
          _p,←'           | (?: "[^"]*"   )+ | (?: ''[^''\r\n]*'')+ ',CR
          _p,←'           | (?&'Nm')*',CR
          _p,←'      )+',CR
          _p,←R'  )'
          ∊_p
      }
    bpCount_←1    ⍝ Use the ctr to generate a unique name balNNN for referencing inside the pattern.

  ⍝ ∆XR: Execute and Replace
  ⍝      Replace names of the form ⍎XXX in a string with its executed value in the calling context (in string form)...
  ⍝      XXX: An APL name, possibly preceded by any of ',∊'
  ⍝      ⍺: caller_NS[=⊃⎕RSI]  [err=1] [count=25]
  ⍝         caller_NS: Where to execute each expression found.  Default is caller env.
  ⍝         error:     If 1 (default), signals an error if it can't make the requisite replacements.
  ⍝                    If 0, - if ⍎'my_str' failed, the vector 'my_str' is returned.
  ⍝                          - results of more than one line will be raveled.
  ⍝                          - if it exceeds count, returns current replacement (If a b c d e f←'⍎',¨'bcdefa', try with count of 5).
  ⍝         count:     How many times to scan the ENTIRE string for replacements. Default is 25.
    XRCallE←'∆XR: 1st element of ⍺ (caller) must be a namespace.'  ⋄  XRLoopE←'∆XR: looping on runaway replacement strings.'
    XRExecE←{'∆XR: An error occurred executing ⍎"',⍵,'".'}         ⋄  XRFormE←{'∆XR: Result not a single line in ⍎"',⍵,'".'}
      ∆XR←{⍺←⊃⎕RSI
          caller err cnt←3↑⍺,1 25↑⍨¯3+≢⍺           ⍝ Declaring caller, err, cnt
          9≠⎕NC'caller':⎕SIGNAL∘11 XRCallE
          CondErr←{cnt∘←0 ⋄ ~err:⍺ ⋄ ⎕SIGNAL∘11 ⍵}
          cnt{cnt←⍺
              cnt≤0:⍵ CondErr XRLoopE
              S←'⍎([,∊]?[\w∆⍙#⎕]+(?:\.[\w∆⍙#⎕]+)*)'⎕R{f1←⍵ ∆F 1
                  0::f1 CondErr XRExecE f1
                  1=≢r←⎕FMT caller.⍎f1:,r
                  (∊r,' ')CondErr XRFormE f1
              }⍠('UCP' 1)⊣⍵
              ⍵≡S:S ⋄ '⍎'(~∊)S:S ⋄ (cnt-1)∇ S
          }⍵
      }
  ⍝ ∆XRL: Execute and Replace Locally
    ∆XRL←⎕THIS∘∆XR

    ⍝ ⍺ Join ⍵:  Treat ⍺, ⍵ each as a matrix and attach ⍺ to the LEFT of ⍵, adding ROWS to ⍺ or ⍵ as needed..
      Join←{
          RH RW←⍴right←⎕FMT ⍵ ⋄ 0=≢⍺:right
          LH LW←⍴left←⎕FMT ⍺ ⋄ CH←LH⌈RH
          (CH LW↑left),(CH RW↑right)
      }
    ⍝ ⍺ Over ⍵:  Treat ⍺, ⍵ each as a matrix and attach ⍺ OVER (ON TOP OF) ⍵, adding COLUMNS to ⍺ or ⍵ as needed..
      Over←{
          UH UW←⍴upper←⎕FMT ⍺ ⋄ 0=≢⍵:upper
          LH LW←⍴lower←⎕FMT ⍵ ⋄ CW←UW⌈LW
          UW<LW:(ctr⌽UH LW↑upper)⍪lower⊣ctr←⌈0.5×UW-LW
          upper⍪(ctr⌽LH UW↑lower)⊣ctr←⌈0.5×LW-UW
      }
    ⍝ res ← [char] (pad Pad how) strM
    ⍝ char: a single pad char
    ⍝ pad:  non-negative number
    ⍝ how:  L|C|R - left (pad right), center, right (pad left). Do not truncate.
    ⍝       l|c|r - ditto, but truncate if pad is < current width.
    ⍝       Default (' '): Center.
    ⍝ strM: a string in matrix form
      Pad←{
          ⍺←' ' ⋄ char pad how strM←⍺ ⍺⍺ ⍵⍵ ⍵
          1≠≢char:11 ⎕SIGNAL⍨'The padding must be exactly one character.'
          wid←⊃⌽⍴strM←⎕FMT strM
          (how∊'LRC ')∧pad≤wid:strM
          strM pad←pad{
              how∊'Ll':(⍺↑[1]⍵)(wid-⍺)
              how∊'Rr':((-⍺)↑[1]⍵)(⍺-wid)
              (⍺↑[1]p↑[1]⍵)(0.5×wid-⍺)⊣p←-⌊0.5×wid+⍺
          }strM
          ' '=char:strM
          pad{
              how∊'Ll':strM⊣(⍺↑[1]strM)←char ⋄ how∊'Rr':strM⊣(⍺↑[1]strM)←char
              ((0⌊⌊⍺)↑[1]strM)←char ⋄ ((0⌈⌊-⍺)↑[1]strM)←char
              strM
          }strM
      }
    :EndSection PMSLIB

  ⍝ Pseudo-format strings specs:
  ⍝     Strings of the form {specs: expression}
  ⍝ In place of APL  ('specs' ⎕FMT expression), we have shorthand
  ⍝       {specs:   expression}.
  ⍝ E.g.  {I5,F4.2: ivec fvec}
  ⍝ fmtP matches the specs and following colon.
  ⍝ Fmt Patterns: < >, ⊂ ⊃, ⎕ ⎕ or ¨ ¨ by APL ⎕FMT rules (no embedded matching delims).
  ⍝
  ⍝ Special pseudo-format spec extensions
  ⍝    Lnn, Cnn, Rnn, as in
  ⍝    {C15,I5,F4.2: ivec fvec}, which centers the result of ('I5,F4.2' ⎕FMT ivec fvec)
  ⍝ Must be first (or only) specification given, with optional comma following.
  ⍝    Lnn: obj on left, padded on right to width nn. Ignored if the object is ≥nn in width.
  ⍝    Rnn: obj on right, padded on left to with nn.   Ditto.
  ⍝    Cnn: obj centered.                              Ditto.
    _fmtQts←'⍞' '<>'  '⊂⊃' '⎕' '¨'
    fmtQS← '(?x)(?:',')',⍨¯3↓∊{L R←⍵ ⋄ L,' [^',R,']* ',R,' | '}¨_fmtQts
    _fmtNotQts←'[^ : ⍎∊_fmtQts ]'~' '            ⍝ quotes are valid only within _fmtQuoters above.
    _f←'(?ix) ^ (?|   ( (?: [^":]++   | :{1} | "[^"]*+"  )*?    )  ( :{2}      )  (.*+)  '     ⍝ Date-time code
    _f,←'         |   ( (?: ⍎fmtQS | ⍎_fmtNotQts++ )*+)  ( :{1} (?!:))  (.*+)  '     ⍝ ⎕FMT code
    _f,←'         |   (                                         )  (           )  (.*+)  '     ⍝ Simple code
    _f,←'       ) $'
    fmtP←∆XRL _f

  ⍝ padP:   L<*>25 or L25<*> The entire sequence is followed by a comma or the terminating single colon.
    _p1←'(?ix) ^ (?<type> [LCR]) (?<wid> \d+)        (?<char> ⍎fmtQS?) ,?'
    _p2←'(?ix) ^ (?<type> [LCR]) (?<char> ⍎fmtQS?)  (?<wid> \d+)       ,?'
    padP←∆XRL¨_p1 _p2
    ⍝ Special:   \⍎ \{  \n==>  ⍎ { \r (=CR).  (CR works as newline with APL ⎕FMT).
      ProcEscapes←{
          '\\(\{)' '\\\\n' '\\n' '\\⋄'⎕R'\1' '\\n' '\r' '⋄'⊣⍵
      }

    ⍝ omega type ScanCode format_string
    ⍝ Handle strings of the form <⍵NN, ⍺NN, ⍺⍺, ⍵⍵> in format specs, strings within code, and code outside strings:
    ⍝   type=0:  In format specs:  The value of (⍕NN⊃⍵) will be immediately interpolated into the spec (⎕IO=0).
    ⍝   type=1:  In code outside strings:  The code (⍵⊃⍨NN+⎕IO) will replace ⍵NN (⎕IO-independent).
    ⍝ If index N is out of range of alpha or omega, signals an index error.
      ScanCode←{0=≢⍵:⍵
          env isCode←⍺ ⍺⍺     ⍝ env fields: env.(caller alpha omega index)
          '("[^"]*")+|(''[^'']*'')+' '\\([⍵⍺])' '([⍵⍺])(\d{1,2}|\1)'⎕R{  ⍝ ⍵00 to ⍵99 | ⍵⍵ | ⍺⍺
              case←⍵.PatternNum∘=
              case 0:CanonQuotes ⍵ ∆F 0     ⍝ Convert double quote sequences to single quote sequences...
              case 1:⍵ ∆F 1                 ⍝ \⍵ is treated as char ⍵
            ⍝ case 2:                       ⍝ ⍵3, ⍺3, ⍵⍵, ⍺⍺
              isW←'⍵'=f1←⍵ ∆F 1
              f2←{(⊃⍵)∊'⍺⍵':⍕1+env.index[isW] ⋄ ⍵}⍵ ∆F 2   ⍝ If ⍵NN, return NN; if ⍵⍵, return 1+env.index<⍺ or ⍵>
              ix←env.index[isW]←⍎f2 ⋄ alom←isW⊃env.(alpha omega)
     
              ix≥≢alom:3 ⎕SIGNAL⍨(⍵ ∆F 0),' out of range'
              isCode:'(',f1,'⊃⍨',f2,'+⎕IO)'
              ⍕ix⊃alom
          }⍵
      }

  ⍝ CanonQuotes str:   "..." has " removed, handling internal DQs and SQs.
      CanonQuotes←{
          DQ≠1↑⍵:⍵ ⋄ SQ,SQ,⍨{⍵/⍨1+SQ=⍵}{⍵/⍨~(DQ,DQ)⍷⍵}1↓¯1↓⍵
      }

      ExecCode←{
          env cod←⍺ ⍵     ⍝ env fields: env.(caller alpha omega index)
          6⍴⍨~DEBUG::⎕SIGNAL/⎕DMX.(EM EN)⊣⎕←'Error executing code: ',cod
        ⍝ Handle omegas
        ⍝ Find formatting prefix, if any
          (pfx colons cod)←{   ⍝ Speeds up ⎕R when no : exists at all!
              ':'(~∊)cod:'' ''⍵ ⋄ fmtP ⎕R'\1\n\2\n\3'⊣⊆⍵
          }cod
     
        ⍝ KLUDGE: treat \{ and \} as { } in ⊂...⊃-style ⎕FMT expressions.
          pfx←fmtQS ⎕R{
              f0←⍵ ∆F 0
              f0/⍨~⊃∨/'\{' '\}'⍷¨⊂f0
          }⊣pfx
     
          pfx←env(0 ScanCode)pfx              ⍝ 0: ~isCode
          cod←env(1 ScanCode)cod              ⍝ 1:  isCode
     
        ⍝ Spacing / Justification Pseudo-⎕FMT specs:
        ⍝    pattern: [LCRlcr] (ddd⎕c⎕ | ⎕c⎕ddd) ,?
        ⍝ Set locals: pfx; padTYpe, padWid, padChar
          padType padWid padChar←' ' 0 ' '
          pfx←padP ⎕R{t w c←⍵ ∆F¨'type' 'wid' 'char'
              padType padWid padChar∘←t(⍎w)' '
              0=≢c:'' ⋄ padChar∘←1↓¯1↓c ⋄ ''
          }pfx
     
        ⍝ Format codestring <cod> executed according to three formatting options...
        ⍝ 1] If prefix <pfx> is null or all blanks
        ⍝    and there is one colon,   call:   ⎕FMT cod
        ⍝    and there are two colons, call: '%ISO%' (1200)⌶)cod  ⍝ Format cod in the ISO std date-time format.
        ⍝ 2] If there is one colon,   call: pfx ⎕FMT cod
        ⍝ 3] If there are two colons, call: ⎕FMT pfx (1200⌶)cod...
          val←pfx(2=≢colons){pfx isDT←⍺
              pfx←pfx{0≠≢⍵:⍺ ⋄ isDT:'%ISO%' ⋄ ⍵}pfx↓⍨+/∧\' '=pfx
              0=≢pfx:⎕FMT ⍵ ⋄ isDT:0 1↓0 ¯1↓⎕FMT pfx(1200⌶)⍵ ⋄ pfx ⎕FMT ⍵
          }{
              0=≢⍵:'' ⋄ env⍎'alpha caller.{',(ProcEscapes ⍵),'}omega'
          }cod
     
        ⍝ Process L|C|R|l|c|r.  See Pad for details...
          padType∊'lcrLCR':padChar(padWid Pad padType)val
          val
      }

      ⍝ ========= MAIN ∆FMT Formatting Function
      ⍝ ∆FMT - Major formatting patterns:
      ⍝    ...P the pattern, ...C the pattern number
      ⍝ Braces: Embedded balanced braces are allowed, as are quoted strings (extended to double-quoted strings).
    addPat←{_patNum+←1 ⋄ fmtPats,←⊂⍵ ⋄ 1: fmtNums,←⍎⍺,'∘←_patNum' }
    fmtPats←fmtNums←⍬ ⋄ _patNum←¯1
    'nextFC' addPat '\{\h*\}'                     ⍝ Next Omega.
    'endFC'  addPat  '⋄|\{\h*[⍬:]\h*\}'           ⍝ End of Field.
    'codeFC' addPat GenBalanced '{}'              ⍝ Code field.
    'textFC' addPat '(?x) (?: \\. | [^{\\⋄]+ )+'  ⍝ Text Field

    ⍝ Main user function ∆FMT
    ∇ text←{leftArgs}∆FMT rightArgs;env;_
      :Trap 0⍴⍨~DEBUG
          :If rightArgs≡⍬ ⋄ FORMAT_HELP ⋄ :Return ⋄ :EndIf
     
          text←''
          env←⎕NS''   ⍝ fields: env.(caller alpha omega index)
           ⋄ env.caller←0⊃⎕RSI ⋄ isNum←{16::0 ⋄ ⍬⍴0⍴⍵}  ⍝ 16:: Handles namespace NONCE ERROR
           ⋄ env.alpha←,{⍵:⍬ ⋄ ⍺←leftArgs ⋄ 1<⍴⍴⍺:,⊂⍺ ⋄ ' '≡isNum ⍺:⊆⍺ ⋄ ⍺}900⌶⍬
           ⋄ env.omega←1↓rightArgs←⊆rightArgs
           ⋄ env.index←2⍴¯1    ⍝ "Next" element of alpha ([0]: ⍺, ⍺⍺) and omega ([1]: ⍵, ⍵⍵) to read in ExecCode is index+1.
     
          _←fmtPats ⎕S{
              case←⍵.PatternNum∘= ⋄ f0←⍵ ∆F 0
              case textFC:0⍴text∘←text Join ProcEscapes f0          ⍝ Any text except {...} or ⋄
              case codeFC:0⍴text∘←text Join env ExecCode 1↓¯1↓f0    ⍝ {[fmt:] code}
              case nextFC:0⍴text∘←text Join env ExecCode'⍵⍵'        ⍝ {}    - Shortcut for '{⍵⍵}'
              case endFC:⍬                                          ⍝ ⋄     - End of Field (ends preceding field). Syn: {⍬} {:}
              11 ⎕SIGNAL⍨'∆FMT: Unreachable stmt: ⍵.PatternNum=',⍕⍵.PatternNum
          }⊣⊃rightArgs
          text←,⍣(1=≢text)⊣text     ⍝ 1 row matrix quietly converted to a vector...
      :Else
          ⎕SIGNAL/⎕DMX.(EM EN)
      :EndTrap
    ∇

    ∇ FORMAT_HELP;h
      h←'_HELP'
      :If 0=⎕NC h ⋄ _HELP←(⊂'  '),¨3↓¨{⍵/⍨(⊂'⍝H')≡¨2↑¨⍵}⎕SRC ⎕THIS ⋄ :EndIf
      ⎕ED⍠('ReadOnly' 1)&h
    ∇

  ⍝ Add ⎕THIS to ⎕PATH cleanly and exactly once (if not already present).
    ##.⎕PATH← 1↓∊' ',¨∪(' ' (≠⊆⊢) ##.⎕PATH),⊂⍕⎕THIS
    _CSAY (⍕##),'.⎕PATH now ''',##.⎕PATH,''''
  ⍝ Delete underscore-prefixed vars (those not used at runtime)
    _←' '~⍨¨↓'_' ⎕NL 2 3 4
    _CSAY 'Deleting temp objects:',∊' ',¨_
    _CSAY 'Format namespace being fixed as ',⍕⎕THIS
    _←0 ⎕EXPORT ⎕NL 3 4
    _←1 ⎕EXPORT ↑'∆FMT' '∆XR' 'Join' 'Over'
    _CSAY 'Exporting fns/ops:',∊' ',¨' '~⍨¨↓{(0≠⎕EXPORT ⍵)⌿⍵}⎕NL 3 4
    ⎕EX '_' ⎕NL 2 3 4

    :Section Documentation
⍝H ∆FMT - a modest Python-like APL Array-Oriented Format Function
⍝H        formatting multi-dimensional objects, ⎕FMT-compatible numerical fields,
⍝H        and I-Beam 1200-compatible Date-Time objects.
⍝H
⍝H Syntax:
⍝H    string← [⍺0 [⍺1 ... [⍺99]]] ∆FMT specification [⍵0 [⍵1 ... [⍵99]]]]
⍝H
⍝H    Preview!
⍝H          what←'rain' ⋄ where←'Spain' ⋄ does←'falls' ⋄ locn←'plain'
⍝H          ∆FMT 'The {what} in {where} {does} mainly on the {locn}.'
⍝H    The rain in Spain falls mainly on the plain.
⍝H        'you' 'know'  ∆FMT 'The {} in {} {} mainly on the {}, {⍺⍺} {⍺⍺}.' 'rain' 'Spain' 'falls' 'plain'
⍝H    The rain in Spain falls mainly on the plain, you know.
⍝H
⍝H    Specification: a string containing text, variable names, code, and ⎕FMT specifications, in a single vector string.
⍝H    ∘ In addition to ⍺ or ⍵ (each entire array) or selections therefrom,
⍝H      special variable names within code include
⍝H         ⍺0 (short for (0⊃⍺)), ⍺⍺ (for the next element of ⍺), and
⍝H         ⍵0 (short for (0⊃⍵)), ⍵⍵ (for the next element of ⍵), ... ⍺99 and ⍵99.
⍝H      These may appear one or more times within a Code field and are processed left to right.
⍝H
⍝H  Types of Fields:
⍝H  type:    |    TEXT   |  SIMPLE |    ⎕FMT     |  DATE-TIME   | BLANK  |  END OF  |   NEXT ARG
⍝H           |           |  CODEa  |    CODEb    |     CODEc    | CODEd  |  FIELD   |     CODEf
⍝H  format:  | any\ntext | {code}  | {fmt:code}  |  {fmt::code} | {Lnn:} |    ⋄     | {}  {⍵⍵}  {⍺⍺}
⍝H
⍝H  Special chars in format specifications outside quoted strings:
⍝H    Escaped chars:  \{  \\ \⋄   - Represented in output as { (left brace), \ (backslash) and ⋄ (lozenge).
⍝H    Newlines        \n          - In TEXT fields or inside quotes within CODE fields.
⍝H                                  \n is actually a CR char (Unicode 13), forcing a new APL line in ⎕FMT.
⍝H    In ⎕FMT field quotes ⎕...⎕, ⊂...⊃, etc., an unbalanced brace { or } must be backslashed, due to limitations
⍝H    in the parsing algorithm. No other characters should be backslashed.
⍝H    Example:
⍝H    ⍝ Good                             ⍝ Bad!
⍝H         ∆FMT'#1: {⊂\{⊃,I1,⎕\}⎕:⍳3}'     ∆FMT'#1: {⊂{⊃,I1,⎕\}⎕:⍳3}'
⍝H    #1: {0}                            SYNTAX ERROR
⍝H        {1}                              ∆FMT'#1: {⊂{⊃,I1,⎕\}⎕:⍳3}' 
⍝H        {2}                              ∧
⍝H
⍝H Fields:
⍝H  1.  TEXT field: Arbitrary text, requiring escaped chars \{ \⍎ and \\ for {⍎\ and \n for newline.
⍝H
⍝H  2.  CODE field
⍝H   a. SIMPLE CODE: {code}   returns the value of the code executed as a 2-d object.
⍝H      ⍵0..⍵99, ⍵⍵, ⍵, ⍺0..⍺99, ⍺⍺, ⍺ may be used anywhere in a CODE field.
⍝H                  ⍵0 refers to (0⊃⍵); ⍺99 to (99⊃⍺) in ⎕IO=0;
⍝H                  ⍵⍵ refers to the next element of ⍵. If the last (to the left) was ⍵5, then ⍵⍵ is ⍵6.
⍝H                  ⍺⍺ refers to the next element of ⍺. If the last (to the left) was ⍺9, then ⍺⍺ is ⍺10.
⍝H             If used in a format specification, ⍵NN and ⍺NN vars must refer to simple vectors or scalars.
⍝H
⍝H   b. ⎕FMT CODE field: {[LCR Spec,]prefix: code}      See also c. TIME CODE field.
⍝H      executes <code> and then formats it as (prefix ⎕FMT value).
⍝H      prefix: any valid ⎕FMT specification (null or blank specifications are quietly ignored).
⍝H
⍝H      LCR Spec: An LCR specification may be the first (foll. by comma) or only specification.
⍝H         It is of the form  "[LCR]nn⎕c⎕," or "[LCR]nn⎕c⎕"
⍝H            LCR: Any of L, C, R, l, c, r.  See below for details.
⍝H            nn:  A non-negative integer indicating the total padding length.
⍝H            ⎕c⎕: Using ⎕FMT quotes (⎕c⎕, ⊂c⊃, etc.) specify <c> a single padding char, if not a blank.
⍝H                 If multiple characters are specified <char>, an error occurs
⍝H
⍝H         Note: {C10⎕⊂⎕,I1: ⍳3} and {C10,⎕⊂⎕,I1: ⍳3} differ!
⍝H              ∆FMT'{C10⎕⊂⎕,I1: ⍳3}'         ∆FMT'{C10,⎕⊂⎕,I1: ⍳3}'
⍝H         ⊂⊂⊂⊂1⊂⊂⊂⊂⊂                            ⊂1
⍝H         ⊂⊂⊂⊂2⊂⊂⊂⊂⊂                            ⊂2
⍝H         ⊂⊂⊂⊂3⊂⊂⊂⊂⊂                            ⊂3
⍝H
⍝H         1. LCR specification:
⍝H             The first "field" may be [no truncate] Lnn, Rnn, or Cnn; or
⍝H                                      [truncate ok] lnn, rnn, or cnn.
⍝H             L, C, or R may pad the associated field, but will NEVER truncate,
⍝H                    even if the field is wider than <nn> characters.
⍝H             l, c, or r will either pad or truncate, depending
⍝H                    on whether the calculated field is wider or narrower than <nn> characters.
⍝H             L/l- object on left side, padded on right.
⍝H               L20: Pad a left-anchored object on right to 20 chars. Do not truncate.
⍝H               l20: Ditto. Truncate as required.
⍝H             C/c- centered.
⍝H               C15: Pad  a field with 8 chars on left and 7 on right. Do not truncate.
⍝H               c15: Ditto. Truncate as required.
⍝H             R/r- right side.
⍝H               R5:  Pad a right-anchored object on left to 5 chars. Do not truncate.
⍝H               r5:  Ditto. Truncate as required.
⍝H
⍝H             Example:
⍝H             ⍝  Delay five seconds, truncating  the result (LEFT) or displaying the result (RIGHT).
⍝H                ∆FMT '<{l0:⎕DL 0.2}>'                 ∆FMT '<{L0:⎕DL 0.2}>'  ⍝ Equiv to {⎕DL 0.2}, w/o superfluous L0.
⍝H             <>                                    <0.202345>
⍝H             Examples:                               12345678901234567890
⍝H             #1  ∆FMT '<{C20,I3: 1 5⍴⍳5}>'   ==>    <    0  1  2  3  4   >
⍝H             #2  ∆FMT '<{C2,I5:  1 5 ⍴⍳5}>'  ==>    <    0    1    2    3    4>
⍝H             #3  ∆FMT '<{C5:"1234567890"}>'  ==>    <1234567890>
⍝H                 ∆FMT '<{R5:"1234567890"}>'  ==>    <1234567890>
⍝H                 ∆FMT '<{c5:"1234567890"}>'  ==>    <45678>
⍝H         2.  A field spec may include special ⍵NN- or ⍺NN-positional variables (above), wherever variables are allowed:
⍝H
⍝H         Example:
⍝H             ∆FMT 'Random: {C⍵0,⊂< ⊃,F⍵1,⎕ >⎕: ?3⍴0}' 8 4.2  (or '8' '4.2')
⍝H         Random: < 0.30 >
⍝H                 < 1.00 >
⍝H                 < 0.64 >
⍝H         If a standard format specification is used, APL ⎕FMT rules are followed, treating
⍝H         vectors as 1-column matrices:
⍝H         Example:
⍝H             ∆FMT 'a: {3↑⎕TS} b: {I4: 3↑⎕TS} c: {ZI2,⊂/⊃,ZI2,⊂/⊃,I4: ⍉⍪1⌽3↑⎕TS}'
⍝H         a: 2020 9 6 b: 2020 c: 09/06/2020
⍝H                           9
⍝H                           6
⍝H
⍝H      Code fields  may also contain double-quoted strings "like this" or single-quoted strings
⍝H      entered ''like this'' which appears 'like this'. Valid: "A cat named ""Felix"" is ok!"
⍝H      Quotes entered into other fields like TEXT fields are treated as ordinary text 
⍝H      and not processed in this way.
⍝H
⍝H      Example:
⍝H         ∆FMT '{⍪6⍴"|"} {↑"one\ntwo" "three\nfour" "five\nsix"}'
⍝H      | one
⍝H      | two
⍝H      | three
⍝H      | four
⍝H      | five
⍝H      | six
⍝H
⍝H      Code fields may be arbitrarily complicated. Only the first "prefix:" specification
⍝H      is special:
⍝H      Example (see DATE-TIME CODE fields for a better approach):
⍝H         ∆FMT 'Today is {now←1 ⎕DT ⊂⎕TS ⋄ spec←"__en__Dddd, DDoo Mmmm YYYY hh:mm:ss"⋄ ∊spec(1200⌶)now}.'
⍝H      Today is Sunday, 06th September 2020 17:25:21.
⍝H
⍝H   c. DATE-TIME CODE field: {time_spec:: timestamp}  OR  { [LCR-spec,]time_spec:: timestamp}
⍝H      If time_spec is a specification for formatting dates and times via I-Beam (1200⌶)
⍝H      and timestamp is 1 or more timestamps of the form  (1 ⎕DT ⊂⎕TS) or (1 ⎕DT TS1 TS2 ...)
⍝H      then this returns the timestamp formatted according to the time_spec.
⍝H      - If a single timestamp is passed, a single string is returned by I-Beam 1200 in enclosed form;
⍝H        it is disclosed automatically (i.e. is treated as a regular string).
⍝H      - If the time_spec is blank, it is treated as '%ISO' and not ignored (See ⎕FMT Code fields, which differ).
⍝H      - Restriction: Because of how ∆FMT parses, two or more contiguous colons within a specificatin
⍝H        must be double-quoted "::". A single colon will be interpreted correctly, whether quoted or not.
⍝H           Good: {tt"::"mm:ss:: now}     Bad: {tt::mm:ss:: now}
⍝H
⍝H      Examples
⍝H          now← 1 ⎕DT  ⊂⎕TS
⍝H          ∆FMT '<{%ISO%::now}>'
⍝H      <2020-09-10T15:34:48>
⍝H          ∆FMT '{tt:mm:ss:: now} {F12.6:now}'
⍝H      03:50:51 44083.660324
⍝H          ∆FMT '{tt"::"mm:ss:: now} {F12.6:now}'
⍝H      03::50:51 44083.660324
⍝H          ∆FMT '{tt::mm:ss:: now} {F12.6:now}'
⍝H      VALUE ERROR: Undefined name: mm
⍝H          t1 t2 t3←{⎕TS⊣⎕DL 1+?0}¨1 2 3
⍝H      More Examples
⍝H          ∆FMT'{I1,⊂. ⊃:⍵⍵}{%ISO%::1 ⎕DT ⍪⍵ }' (1 2 3) t1 t2 t3    ⍝ Explicit ISO-formatted DATE-TIME
⍝H      1. 2020-09-10T18:30:18
⍝H      2. 2020-09-10T18:30:19
⍝H      3. 2020-09-10T18:30:21
⍝H      ⍝  Presenting a null DATE-TIME specification {::tt}          ⍝ Default ISO-formatted DATE-TIME
⍝H          tt← ⍪0 0.111+1 ⎕DT ⊂ 2020 9 11 23 13 36 136
⍝H          ∆FMT '{::tt}'
⍝H      2020-09-11T23:13:36
⍝H      2020-09-12T01:53:26
⍝H
⍝H   d. BLANK field: {Lnn:}
⍝H      Create a field nn blanks wide, with no other text, where nn is a non-negative integer.
⍝H      Only these cases are allowed: {Lnn:} | {Cnn:} | {Rnn:}. All are equivalent.
⍝H      E.g. to insert 10 blanks between fields:  {L10:}.
⍝H
⍝H   e: END OF FIELD (EOF): ⋄
⍝H      An unescaped lozenge ⋄ terminates the preceding field (if any).
⍝H      Equivalents: Since {⍬} or {:} evaluates to an empty (0-width) field, they are synonyms for EOF.
⍝H      Example:
⍝H          ∆FMT 'The cat ⋄is\nisn''t{⍬}here {:}and\nAND {"It isn''t here either"}'
⍝H      The cat is   here and It isn't here either
⍝H              isn't     AND
⍝H
⍝H   f. NEXT ARG field:  {} is equiv to {⍵⍵}, i.e. the next element in ⍵.
⍝H    - if no explicit {⍵NN} is specified, {} is {⍵0} {⍵1} ....
⍝H    - if {⍵10} is specified, {} to its right selects {⍵11};
⍝H      i.e. after {⍵N},  {} or {⍵⍵} refers to ⍵M, M=N+1.
⍝H    - There is no short-cut for the next alpha field (⍺⍺); it is useful as is.
⍝H    Example:
⍝H      ⍝ 1. A long line.
⍝H         ∆FMT '{} {} lives at {} in {}, {} in {}' 'John' 'Smith' '424 Main St.' 'Milwaukee' 'WI' 'the USA'
⍝H      John Smith lives at 424 Main St. in Milwaukee, WI in the USA
⍝H      ⍝ 2. A bit of magic to pass format specs and args as peer strings (vectors).
⍝H         info←'John' 'Smith' '424 Main St.' 'Milwaukee' 'WI' 'the USA'
⍝H         ∆FMT '{} {} lives at {} in {}, {} in {}' {⍵,⍨⊂⍺} info
⍝H      John Smith lives at 424 Main St. in Milwaukee, WI in the USA
⍝H      ⍝ 3. Using ⍺ on the left to pass a list of strings is simple.
⍝H         info  ∆FMT '{⍺⍺} {⍺⍺} lives at {⍺⍺} in {⍺⍺}, {⍺⍺} in {⍺⍺}'
⍝H      John Smith lives at 424 Main St. in Milwaukee, WI in the USA
⍝H
⍝H Returns: a matrix-format string if 2 or more lines are generated.
⍝H If 1 line, returns it as a vector.
⍝H
⍝H ∆FMT ⍬  -- Displays Format Help info!
    :EndSection Documentation

:EndNamespace
