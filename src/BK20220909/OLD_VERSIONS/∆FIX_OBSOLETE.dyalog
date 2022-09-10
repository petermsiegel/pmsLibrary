 result←{argL}∆FIX argR
 ;ALPH;Bêgin;Bêgin;CR;CTL;CalledFrom;DICT;DQ;LETTER_NS;ListScan;MActions;MBegin
 ;MEnd;MPats;MRegister;MacroScan1;MainScan1;Match;NL;NO;NOc;OPTSre;PRAGMA_FENCE
 ;Par;PreScan1;PreScan2;SEMICOLON_FAUX;SQ;TRAP;UTILS;YES;YESc;_
 ;_MATCHED_GENERICp;anyNumP;atomsP;box;braceCount;braceP;brackP;code;comment
 ;commentP;defMatch;defS;dict;dictNameP;directiveP;doScan;dqStringP;ellipsesP
 ;enQ;err;eval;filesIncluded;first;firstBuffer;firstP;fileName;funName;getenv;h2d;hdr
 ;ifTrue;infile;keys;letS;longNameP;macro;macroFn;macros;multiLineP;nameAttributeP;nameP;names
 ;obj;objects;opts;parenP;pfx;processFnHdr;readFile;register;setBrace;sfx
 ;showCodeSnip;showObjSnip;specialStringP;sqStringP;stringAction;stringP
 ;subMacro;tmpfile;ø;∆COM;∆DICT;∆FIELD;∆MYdefs;∆PFX;∆V2S;⎕IO;⎕ML;⎕PATH;⎕TRAP

 ⍝  A Dyalog  APL preprocessor   (rev. Dec 8)
 ⍝
 ⍝ result ← options    ∆FIX  [fileName | ⍬ ]
 ⍝          options:   ' [-out=OUTSPECS] [-com=0|1|2|3] [-debug]  [-showcompiled]'
 ⍝          defaults:  ' -out=name -com=3 -debug=0 -showcompiled=0'
 ⍝
 ⍝ Description:
 ⍝   Takes an input file <fileName> in 2 ⎕FIX format, preprocesses the file, then 2 ⎕FIX's it, and
 ⍝   returns the objects found or ⎕FIX error messages.
 ⍝   If <filename> is ⍬, ∆FIX prompts for input.
 ⍝   Like Dyalog's ⎕FIX, accepts either a mix of namespace-like objects
 ⍝   (namespaces, classes, interfaces) and functions (marked with ∇)
 ⍝   or a single function (whose first line must be its header, with a ∇-prefix optional).

 ⍝ fileName: the full file identifier; if no type is indicated, .dyalog is appended.
 ⍝
 ⍝ -out=n[ames]* | c[ode] | "n[ames] c[ode]" | ""
 ⍝  ∘ Indicates the return values* (rc cannot be suppressed):
 ⍝       1. -out=names         - returns*: rc names
 ⍝           default (omitted)
 ⍝       2. -out="names code"  - returns*: rc names code
 ⍝          -out
 ⍝       3. -out=code          - returns*: rc code
 ⍝       4. -out=""            - returns*: rc
 ⍝          -out=
 ⍝    where rc:    1 on success, 0 on failure
 ⍝       a. names: the list of objects created by a ⎕FIX.
 ⍝       b. code:  output (v of v) from the preprocessor.
 ⍝  ∘ If an error occurs, returns instead:
 ⍝      5. signalNum signalMsg (APL signal number and message string).
 ⍝ -com=0*|1|2|3
 ⍝ -com=0 (default)
 ⍝ -com denotes -com=3
 ⍝      Indicates how to handle preprocessor statements in output.
 ⍝            0: Keep all preprocessor statements, identified as comments with ⍝🅿️ (path taken), ⍝❌ (not taken)
 ⍝            1: Omit (⍝❌) paths not taken
 ⍝            2: Omit also (⍝🅿️) paths taken (leave other user comments)
 ⍝            3: Remove all comments of any type
 ⍝ -debug
 ⍝      If specified, signals won't be trapped; errors will cause execution to be suspended.
 ⍝ -showcompiled=0*|1
 ⍝            0: Don't view the preprocessed code when done. (It may be returned via -out=[n]c
 ⍝               Default if standard fileName was specified.
 ⍝            1: View the preprocessed code just before returning, via ⎕ED.
 ⍝               Default only if fileName≡⍬, i.e. when prompting input from user.
 ⍝-------------------------------------------------------------------------------------------
 :Section Initialization
     ⎕IO ⎕ML←0 1
     ⎕PATH←(⍕⎕THIS),' ',⎕PATH
     CalledFrom←⊃⎕RSI  ⍝ Get the caller's namespace

   ⍝ opts: See description above.
     ⎕TRAP←0 'C' '⎕SIGNAL/⎕DMX.(EM EN)'
     opts fileName←{
         0::⎕DMX.EN ⎕SIGNAL⍨'∆FIX: ',⎕DMX.EM
         dyad opts args←⍵
         parms←'-out[=] -com[=]0 1 2 3 -debug[=] -showcompiled[=]'
         opts←(⎕NEW ⎕SE.Parser parms).Parse opts
       ⍝ out: 2 bit flags:  [1] output names, [0] output code;
       ⍝      rc (return code) is ALWAYS output as if hidden flag [0] is 1.
         opts.(out←{⍵≡1:1 1 ⋄ ⍵≡0:1 0 ⋄ 'nc'∊⊃¨' '(≠⊆⊢)⍵}out)
         opts.(com←{⍵=1:3 ⋄ ⍵=0:0 ⋄ '012'⍳⍵}com)  ⍝ com ∊ 0 1 2 3
         opts.(debug←{⍵∊'1' 1}debug)
         opts.(showcompiled←{⍵∊'1' 1}showcompiled)
         dyad:opts args
         em1←'One or zero filenames must be specified:'
         fn←{                               ⍝ Cmdline has ...
             1<≢⍵:11 ⎕SIGNAL⍨em1,∊' ',¨⍵    ⍝ ... >1.      Error.
             0=≢⍵:⍬                         ⍝ ...  0.      Return ⍬ as filename.
             ⊃⍵                             ⍝ ...  1.      Return arg as filename.
         }opts.Arguments
         opts fn
     }'argL'{2=⎕NC ⍺:1(⎕OR ⍺)⍵ ⋄ 0 ⍵ ⍵}argR

     TRAP←opts.debug×999 ⋄ ⎕TRAP←TRAP'C' '⎕SIGNAL/⎕DMX.(EM EN)'
     CR NL←⎕UCS 13 10 ⋄ SQ DQ←'''' '"'
     YES NO←'🅿️ ' '❌ ' ⋄ YESc NOc←'⍝',¨YES NO
     OPTSre←('Mode' 'M')('EOL' 'LF')('NEOL' 1)('UCP' 1)('DotAll' 0)('IC' 1)
     CTL←⎕NS''  ⍝ See CTL services below
     PRAGMA_FENCE←'⍙F⍙'  ⍝ See ::PRAGMA
     firstBuffer←⍬       ⍝ See ::FIRST
     '∆MYdefs'⎕NS''
     ∆MYdefs.⎕FX'b←∆FIRST' '(b _FIRST_)←(_FIRST_ 0)'
     ∆MYdefs.⎕FX'b←∆RESET' 'b←_FIRST_←1'
     ∆MYdefs._FIRST_←1

   ⍝ Faux Semicolon used to distinguish tradfn header semicolons from others...
   ⍝ By default, use private use Unicode E000.
   ⍝ >> If opts.debug, it's a smiley face.
     SEMICOLON_FAUX←⎕UCS opts.debug⊃57344 128512
   ⍝ ALPH: First letter of valid APL names...
     ALPH←'abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüþß'
     ALPH,←'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÕÔÖØÙÚÛÜÝ'
     ALPH,←'_∆⍙'
     :Section Utilities
   ⍝ enQ: Add quotes around a string and adjust internal single quotes (if any)...
         enQ←{SQ,SQ,⍨⍵/⍨1+⍵=SQ}
   ⍝ getenv: Returns value of environment var.
         getenv←{⊢2 ⎕NQ'.' 'GetEnvironment'⍵}
       ⍝ ifTrue ⍵: Returns 1
       ⍝          iff ⍵ has length 0 (≢⍵) OR if (,⍵) is neither (,0) nor (,⎕NULL).
       ⍝       1: (1 2) ('0') (' ') ('XXX')
       ⍝       0:  (0 1 2⍴0) (,⎕NULL) (0)  (,0) ⍬  ('')
       ⍝ (See IF(N)DEF.)
         ifTrue←{0=≢⍵:0 ⋄ (,⎕NULL)≡,⍵:0 ⋄ (,0)≢,⍵}
       ⍝ box:   A simplified boxing for simple display purposes.
       ⍝ box:   hdr ← title ∇ lines
       ⍝        title: a single line (or omit)
       ⍝        lines: one or more lines as a vector of strings or str matrix
       ⍝ Result is shy...
         box←{⎕IO←0 ⋄ ⍺←'∆FIX ERROR MESSAGE!'
             (2=|≡⍵)∧1=⍴⍴⍵:⍺ ∇↑⍵          ⍝ ⍵@S[] → ↑⍵
             topL topR botL botR topM RM LM botM bot side sideM←'┌┐└┘┬┤├┴─│┼'
             fmt←⍺{(≢⍺)≤¯1↑⍴⍵:⍵ ⋄ (≢⍺)↑[1]⍵}⎕FMT ⍵
             fmt←side,side,⍨bot,[0]bot,[0]⍨fmt
             (⊃fmt)←topL ⋄ (⊃⌽fmt)←topR ⋄ (⊃⊖fmt)←botL ⋄ (⊃⌽⊖fmt)←botR
             ⍬≡⍺:fmt
             fmt←{⍵\[0]fmt}H⊣H[1 2]←0⊣H←1⍴⍨2+1↑⍴fmt
             ⋄ ctr←{l←(⍺-≢⍵)÷2 ⋄ (' '⍴⍨⌊l),⍵,' '⍴⍨⌈l}
             ⋄ W←¯2+¯1↑⍴fmt
             fmt[1;]←side,(W ctr ⍺),side
             fmt[2;]←LM,(W⍴bot),RM
             1:_←fmt
         }
       ⍝ showObjSnip, showCodeSnip-- used informationally to show part of a potentially large object.
       ⍝ Show just a bit of an obj of unknown size. (Used for display info)
       ⍝ [A] showObjSnip: assumes data values. Puts strings in quotes.
       ⍝ [B] showCodeSnip: Assumes APL code or names in string format.
         showObjSnip←{⍺←⎕PW-20 ⋄ maxW←⍺
             f←⎕FMT ⍵
             q←SQ/⍨0=80|⎕DR ⍵
             clip←1 maxW<⍴f
             (q,q,⍨(,f↑⍨1 maxW⌊⍴f)),∊clip/'⋮…'
         }
         showCodeSnip←{⍺←⎕PW-20 ⋄ maxW←⍺
             f←⎕FMT ⍵
             clip←1 maxW<⍴f
             ((,f↑⍨1 maxW⌊⍴f)),∊clip/'⋮…'
         }
       ⍝ funName:
       ⍝ Takes the first line of a dfn or tradfn and returns its name or ⍬ (if invalid).
       ⍝ Requires header line* of tradfn or 'name←{' prefix* of a dfn.
       ⍝ The header line may have a ∇ prefix (blanks are tolerated).
       ⍝ tradfn fred:    'abc←{xxx} fred b'
       ⍝ dfn    abc:     'abc←{xxx}'
       ⍝        -----------------------
       ⍝        * Must be in ⎕CR/⎕NR/⎕VR format; only the first line is checked.
       ⍝ Returns name of dfn/tradfn OR ⍬.
         funName←{
             2=⍴⍴⍵:∇↓⍵                                ⍝ Allow ⎕CR format or ⎕NR.
             f←⊃⊆⍵                                    ⍝ Consider only first line
             f←f↓⍨'∇'=⊃f←f↓⍨+/∧\' '=f                 ⍝ Remove leading spaces and optl ∇ prefix.
             nm←(⎕NS'').⎕FX f''             ⍝ Tradfn? ⍝ If can fix ok, is a tradfn or a complete dfn.
             0≠⊃nm:nm                                 ⍝ ... Yes. Return name.
                                    ⍝ Dfn?    ⍝ Do 2nd since res←{name1} is also a tradfn pfx.
             dP op←'^\h*([\w∆⍙]+)\h*←\h*\{'('UCP' 1)  ⍝ Matches dfn prefix?
             (¯1≠⎕NC nm)/nm←⊃dP ⎕S'\1'⍠op⊣f           ⍝ ... If yes, with valid name, return name. Else ⍬.
         }
       ⍝ processFnHdr:  r← ⍺ ∇ ⍵
       ⍝   ⍺: Line with fn header (if not ⍵), used for error msgs.
       ⍝   ⍵: Fn header itself (possible ⍵ altered)
       ⍝   r: Returns ⍺  GLARG
         processFnHdr←{⍺←⍵
             myName←funName';'@(SEMICOLON_FAUX∘=)⊣⍵   ⍝ Temp'ily treat faux semicolons as real ones.
             msg←'Expected fn/op def not found'
             0=≢myName:_←∆COM ⍺,NL,(enQ msg),'⎕SIGNAL 11',NL⊣⎕←msg box ⍺

             myNs←(⍕CalledFrom),'.⍙⍙.∆MY.',myName
             _←'⎕MY    'ALIAS myNs             ⍝ ⎕MY - namespace this fn is in
             _←'⎕FIRST 'ALIAS myNs,'.∆FIRST'
             _←'⎕RESET 'ALIAS myNs,'.∆RESET'

             firstBuffer,←'{}⍎',SQ,myNs,SQ,' ⎕NS ∆MYdefs',NL
             1:_←⍺
         }
       ⍝ h2d: Convert hexadecimal to decimal. Sign handled arbitrarily by carrying to dec. number.
       ⍝      ⍵: A string of the form ¯?\d[\da-fA-F]?[xX]. Case is ignored.
       ⍝ h2d assumes pattern matching ensures valid nums. We simply ignore invalid chars here.
         h2d←{ ⍝ Convert hex to decimal.
             ∆D←⎕D,'ABCDEF',⎕D,'abcdef'
             0::⍵⊣⎕←'∆FIX WARNING: Hexadecimal number invalid or  out of range: ',⍵
             (1 ¯1⊃⍨'¯'=1↑⍵)×16⊥∆D⍳⍵∩∆D
         }
       ⍝ CTL services: Handles recursive use of ::IF/ELSE and related control structures.
       ⍝ Includes: push ⍵, poke ⍵; ⍵←pop, ⍵←peek; flip; ⍵←skip
       ⍝           saveIf/restoreIf b;
       ⍝           global "stack": CTL.säve.
         :With CTL                               ⍝ Returns...
             ⎕FX's←pop' 's←⊃⌽stack' 'stack↓⍨←¯1' ⍝ ...  old last item, now deleted
             ⎕FX'b←stackEmpty' 'b←1≥≢stack'      ⍝ ...  1 if stack is "empty", has ≤1 item left
             ⎕FX's←peek' 's←⊃⌽stack'             ⍝ ... cur last
             ⎕FX's←flip' 's←(⊃⌽stack)←~⊃⌽stack'  ⍝ ... last, after flipping bit
             push←{stack,←⍵}                     ⍝ ... ⍵ as new last
             poke←{(⊃⌽stack)←⍵}                  ⍝ ... ⍵ as newly replaced last
             ⎕FX's←skip' 's←~⊃⌽stack'            ⍝ ... ~last
           ⍝ Saving/restoring the stack
             säve←⍬
             saveIf←{~⍵:0 ⋄ säve,←⊂stack ⋄ stack←1 ⋄ 1}
             restoreIf←{~⍵:0 ⋄ stack←⊃⌽säve ⋄ säve↓⍨←¯1 ⋄ 1}
         :EndWith
         :If opts.debug
             CTL.⎕FX'report args' ' :Implements Trigger *' 'args.Name,'': '',{0::⍎⍵.Name ⋄⍵.NewValue}args'
         :EndIf
       ⍝⍝⍝⍝ regexp related routines...
       ⍝ ∆PFX:  Returns set of lines ⍵, each prefixed with ⍺←'⍝ ' in a consistent VVS format.
       ⍝ ∆PFX:  ret@VVS ← pfx@S?'⍝ ' ∇ lines@VS|Snl
       ⍝    lines:   a single string w/ (≥0) newlines as line separators, OR
       ⍝             a vector of strings.
       ⍝    pfx:     a string prefix. Default '⍝ '
       ⍝    Returns: a prefixed vector of vectors, regardless of input form of ⍵.
       ⍝ See also NO, YES, NOc, YESc.
         ∆PFX←{⍺←'⍝ ' ⋄ 1=|≡⍵:⍺ ∇(NL∘≠⊆⊢)⍵ ⋄ (⊂⍺),¨⍵}
       ⍝ ∆V2S: Convert a vector of vectors to a string, using carriage returns
       ⍝       APL prints CRs nicely (starts next line in col 1).
       ⍝       We use this ONLY for pretty-printing comments.
         ∆V2S←{1↓∊CR,¨⊆⍵}
       ⍝ ∆COM: Convert a vector of vector strings to a set of comments, one per "line" generated.
       ⍝       If ⍺=1, use the "YESc" comment style; if ⍺=0, use to "NOc" style.
         ∆COM←{⍺←1 ⋄ ∆V2S(⍺⊃NOc YESc)∆PFX ⍵}
       ⍝ ∆FIELD: Return PCRE fields by numbers ⍵ or '' where missing.
         ∆FIELD←{
             0=≢⍵:'' ⋄ 1<≢⍵:⍺ ∇¨⍵ ⋄ 0=⍵:⍺.Match
             ⍵≥≢⍺.Lengths:'' ⋄ ¯1=⍺.Lengths[⍵]:''
             ⍺.(Lengths[⍵]↑Offsets[⍵]↓Block)
         }
       ⍝ dictionary routines
       ⍝ ∘ Use a private namespace so we can access recursively with ::IF etc.
       ⍝ ∘ Dictionaries put names created by ::DEF and ::LET/EVAL into the namespace,
       ⍝   but traps system names of the form ⎕ABC as ÐABC. When a system name is
       ⍝   set via ÐABC, we also assign ⎕ABC via a trigger, but only if it is writeable.
       ⍝   Otherwise, the trigger does nothing. This allows a user to create new system
       ⍝   variable macros (for new names or existing ones), while allowing APL to see
       ⍝   the side effects of those not reset. This is complicated, but allows arbitrarily
       ⍝   expressions in conditional expressions, e.g. in ::IF, ::ELSEIF, and ::COND statements.
       ⍝ ∘ Names used in DEF/LET etc may be complex, e.g. A.B.C.D. We'll automatically create
       ⍝   intermediate namespaces (A.B.C), but the user must take care not to use those
       ⍝   names ALSO for other purposes; e.g. this sequence won't work out, because
       ⍝   it treats mydir.util as both a namespace (1st) and a variable (2nd):
       ⍝         ::DEF mydir.util.file1←'SOMEDIR/SOMEFILE'
       ⍝         ::DEF mydir.util←'SOMEDIR'
       ⍝   This relates to proper usage of namespaces and is not special to ∆FIX.
       ⍝ ∘ Bugs: Unrelated names starting with or containing Ð will be messed with.
         ∆DICT←{
             dict←⎕NS''
             dict.ns←dict.⎕NS''
           ⍝  dict.(KEYS VALS LITERAL←⍬)
           ⍝ __foo__ (function/trigger)... Shadows internal names for re/defined system
           ⍝ names ÐABC and actual APL names ⎕ABC.
           ⍝ Crazy function to ensure that Ðname names are shadowed to ⎕name system vars,
           ⍝ when valid; and ignored otherwise.   E.g. setting ÐIO←1 will set ⎕IO←1 as well.
           ⍝ See Macro handling...
             _←⊂'__foo__ __args__'
             _,←⊂':Implements Trigger * '
             _,←⊂'→0/⍨ ''Ð''≠1↑__args__.Name'
             _,←⊂'(''⎕'',1↓__args__.Name){0::⋄⍎⍺,''←⍵''}⎕OR __args__.Name'
             _,←⊂opts.debug↓'⍝ ⎕←''debug: Updating name "⎕'',(1↓__args__.Name),''"'''
             _←dict.ns.⎕FX _
           ⍝ tweak: Map external names for :DEF/::LET into internal ones.
           ⍝ Treat names of the form ⎕XXX as if ÐXXX, so they can be defined or even
           ⍝ redefined as macros.
             dict.tweak←dict.{
                 map←'Ð'@('⎕'∘=)          ⍝ Map ⎕ → Ð (right now, we are passing ## through).
               ⍝ Map ⎕abc → ⎕ABC.
               ⍝ Bad idea: Also, map ⎕ABC.def or ⎕ABC.def.ghi → ⎕ABC.DEF or ⎕ABC.DEF.GHI
                 s←⍵
                 '⎕SE.'≡4↓s:(4↑s),map 4↓s ⍝ Keep ⎕SE
                 '#.'≡2↑s:(2↑s),map 2↓s   ⍝ Keep #.
                 ⍝ Bad idea! s←'⎕(\w+(?:\.\w+)*)'⎕R'⎕\u1'⍠##.OPTSre⊣s
                 map s
             }
             dict.(twIn twOut)←'Ðð' '⎕#'
          ⍝  untweak: See tweak.
             dict.(untweak←{twOut[twIn⍳⍵]}@(∊∘twIn))
             dict.validate←{
                 ⍺←ns ⋄ n k←⍺(tweak ⍵)
                 pfxCheck←{
                     ~'.'∊⍵:1
                     pfx←1⊃⎕NPARTS ⍵ ⋄ nc←⍺.⎕NC pfx
                     nc∊9 0:1 ⋄ nc=¯1:(⊂,pfx)∊'⎕SE'(,'#')
                     ⍺ ∇ pfx
                 }
                 ~'.'∊k:1                   ⍝ simple name? Done
                 n2←1⊃⎕NPARTS k             ⍝ n2: prefix a.b.c in name a.b.c.d
                 n pfxCheck k:1⊣n2 n.⎕NS''
                 err←'∆FIX: Object ',k,' invalid: prefix ',n2,' in use as non-namespace object.'
                 err ⎕SIGNAL 911
             }
             dict.set←{⍺←ns
                 ##.TRAP::⎕SIGNAL/⎕DMX.(EM EN)
                 n(k v)←⍺ ⍵ ⋄ k←tweak k
                 n validate k:n{⍺⍎k,'←⍵'}v
             }
           ⍝ Get the value of simple or complex name -- or ⍬ if none.
           ⍝ Assumes that ⍵ is a valid name (will report logic error otherwise).
           ⍝ Returns the value, not forced to a string.
           ⍝ See resolve for evaluating names with parts with (existing) values.
             dict.get←dict.{⍺←ns ⋄ n k←⍺(tweak ⍵)
                 0::⍬⊣⎕←'dict.get logic error on name: ',⍵⊣⎕←↑⎕DMX.DM
                 0≥n.⎕NC k:⍬
                 n.⎕OR k
             }
             dict.del←dict.{⍺←ns
                 n k←⍺(tweak ⍵)
                 1:n.⎕EX k
             }
             dict.defined←dict.{⍺←ns
                 n k←⍺(tweak ⍵)
                 2=n.⎕NC k
             }
             dict.hasValue←dict.{
                 0::0
                 ¯1≠⎕NC ⍵:0
                 n.⎕OR ⍵
             }
           ⍝ Resolve a possibly complex name like a.b.c.d
           ⍝ Leaves ⎕SE and #. as is, but tweaks invented names like ⎕name
             dict.resolve←dict.{⍺←ns
                 n k←⍺(tweak ⍵) ⋄ raw←⍵
                 ifNot←{0≠≢⍵:⍵ ⋄ ⍺}
                 genList←{
                     F←'.'(≠⊆⊢)⍵                ⍝ Split a.b.c into atoms: a |   b    |   c
                     p←⌽{⍺,'.',⍵}\F             ⍝ Compress prefix:   a.b.c  |  a.b   |   a
                     s←(⊂⍬),¯1↓{⍵,'.',⍺}\⌽F     ⍝ Expand suffix:       ⍬    |   c    |  b.c
                     ↓⍉↑p s                     ⍝ Merge             a.b.c ⍬ | a.b c  | a b.c
                 }
                 namePtr←{⍺←0 ⋄ 0::'' ⋄ 2≠n.⎕NC ⍵:''
                     v←n.⎕OR ⍵
                     ⍺:,⎕FMT v ⋄ 0=n.⎕NC'v':v ⋄ 2≠n.⎕NC'v':'' ⋄ ¯1=n.⎕NC v:'' ⋄ v
                 }
                 procList←{
                     0=≢⍵:⍺                 ⍝ Not found: Return original string (use ⍵, not k)
                     prefix rest←⊃⍵
                     2=n.⎕NC prefix:(prefix ifNot namePtr prefix),'.',rest
                   ⍝    :DEF ⎕MY←a.b.c.d
                   ⍝      i.j.⎕MY → i.j.a.b.c.d
                     2=n.⎕NC rest:prefix,'.',rest ifNot get rest
                     ⍺ ∇ 1↓⍵
                 }
                 0≠≢v←1 namePtr k:v  ⍝   Check fully-specified (or simple) name
                 ~'.'∊k:⍕raw            ⍝   Simple name, k, w/o namePtr value? Return orig ⍵
                 list←genList k      ⍝   Not found-- generate subitems
                 untweak raw procList 1↓list   ⍝   Already checked first item.
             }
             _←dict.⎕FX'k←keys' ':TRAP 0' 'k←untweak¨↓ns.⎕NL 2' '⋄:ELSE⋄''Whoops''⋄:ENDTrap'
             _←dict.⎕FX'v←values' ':TRAP 0' 'v←ns.⎕OR¨↓ns.⎕NL 2' '⋄:ELSE⋄''Whoops''⋄:ENDTrap'
             dict
         }
       ⍝ Pattern Building Routines...
       ⍝ User Fns:  MBegin, MEnd, register, eval
       ⍝ Utilities: MActions
       ⍝ See: Global Match.
         ⎕SHADOW'MScanName'
         ⎕FX'MBegin name' 'Match←⍬' 'MScanName←name'
         ⎕FX'm←MEnd' 'm←Match'
         ⍝  register-- adds a function and patterns to the current Match "database".
         ⍝    Returns the associated namespace.
         ⍝    Useful for excluding a namespace from a match sequence or re-using in
         ⍝    different sequences.
         ⍝     matchNs ← infoStr [skipFlag=0] (matchFn ∇) pattern
         ⍝     infoStr: useful comment for humans
         ⍝     skipFlag:
         ⍝       0 - <action> handles skips; call <action>, whether CTL.skip active or not.
         ⍝       1 - If CTL.skip: don't call <action>; return: 0 ∆COM  ⍵ ∆FIELD 0
         ⍝       2 - If CTL.skip: don't call <action>; return: ⍵ ∆FIELD 0
         ⍝     matchFn: the fn to call when <pattern> matches.
         ⍝        See Local Defs for objects copied into the namespace at registration
         ⍝     pattern: The Regex pattern to match. patterns are matched IN ORDER.
         register←{
             ⍺←('[',(⍕1+≢Match),']')0
         ⍝  Local Defs
             ns←⎕NS'SQ' 'DQ' 'TRAP' 'CR' 'NL' 'YES' 'YESc' 'NO' 'NOc' 'OPTSre'
             ns.⎕PATH←⎕PATH
             ns.MScanName←MScanName  ⍝ Global → local
             ns.CTL←CTL
             ns.DICT←DICT
             ns.(info skipFlag)←2⍴(⊆⍺),0  ⍝ Default skipFlag: 0
             ns.pRaw←⍵                    ⍝ For debugging
             ns.pats←eval ⍵
             ns.action←⍺⍺                 ⍝ a function OR a number (number → field[number]).
             1:Match,←ns
         }
       ⍝ MActions: Actions A may be char: replace match with A
       ⍝             or numeric: replace match  with ⍵ ∆FIELD A
       ⍝                or a fn: replace match with value from call:  ns A ⍵
         MActions←{
             TRAP::⎕SIGNAL/⎕DMX.(EM EN)
             match←,⍺⍺    ⍝ Ensure vector...
             pn←⍵.PatternNum
             pn≥≢match:⎕SIGNAL/'The matched pattern was not registered' 911
             ns←pn⊃match
           ⍝ If CTL.skip, i.e. we have code in an :IF / :THEN path not taken,
           ⍝ we can immediately take required action if skipFlag>0.
             CTL.skip∧×ns.skipFlag:ns.skipFlag{
                 ⍺=1:0 ∆COM ⍵ ∆FIELD 0
                 ⍺=2:⍵ ∆FIELD 0
                 ∘LOGIC ERROR:UNREACHABLE
             }⍵                                       ⍝ ↓ What is ns.action?
             3=ns.⎕NC'action':ns ns.action ⍵          ⍝ ... a fn, call it.
             ' '=1↑0⍴ns.action:∊ns.action             ⍝ ... text? Return as is...
             0=ns.action:⍵ ∆FIELD ns.action           ⍝ ... number 0: Just passthru, i.e. return as is.
             ⍵ ∆FIELD ns.action                       ⍝ Else... m.action is a PCRE field number to return.
         }
       ⍝ eval: Used in register-- replaces sequences of the form ⍎NAME  by the value of NAME in the local calling context.
       ⍝ If a NAME contains further ⍎NAMEX sequences, eval calls itself recursively.
       ⍝ Bugs: An infinite loop on (eval '⍎A') is poss if  A B←'⍎B' '⍎A' or A←'⍎A'. Don't do that.
       ⍝       eval will stop evaluating at 10 iterations, just to be nice, but will signal an error.
         eval←{⍺←öMAXEVAL←10                          ⍝ ö prefix to prevent name conflicts with user names.
             ⍺≤0:⎕SIGNAL'∆FIX Logic error: eval called recursively ≥10 times' 911
             öpfx←'(?xx)'                             ⍝ PCRE prefix -- required default!
             östr,⍨←öpfx/⍨~1↑öpfx⍷östr←⍵              ⍝ Add prefix if not already there...
             ~'⍎'∊östr:östr
             östr≢öres←'(?<!\\)⍎(\w+)'⎕R{             ⍝ Keep substituting until no more ⍎name
                 0::öf1
                 ⍎öf1←⍵ ∆FIELD 1
             }⍠('UCP' 1)⊣östr:(⍺-1)∇ öres
             ⍵
         }
         ⎕SHADOW'LEFT' 'RIGHT' 'ALL' 'NAME'
         braceCount←¯1
         setBrace←{
             braceCount+←1
             LEFT∘←∊(⊂'\'),¨∊⍺ ⋄ RIGHT∘←∊(⊂'\'),¨∊⍵ ⋄ ALL∘←LEFT,RIGHT
             NAME∘←'BR',⍕braceCount
           ⍝ Matches one field (in addition to any outside)
           ⍝ Note (?J) and use of unique names (via braceCount).
             pat←'(?: (?J) (?<⍎NAME> ⍎LEFT (?> [^⍎ALL"''⍝]+ | ⍝.*\R | (?: "[^"]*")+ '
             pat,←'                          | (?:''[^'']*'')+ | (?&⍎NAME)*     )+ ⍎RIGHT) )'
             eval pat~' '
         }
 ⍝-------------------------------------------------------------------------------------------
     :EndSection Utilities

 ⍝-------------------------------------------------------------------------------------------
     :Section Reused Pattern Actions
         stringAction←{
       ⍝ Manage single/multiline single-quoted strings and single/multiline double-quoted strings
       ⍝                SQ Strings                     DQ STRINGS
       ⍝    Forms       'abc \n def \n  ghi'          "abc \n def  \n  ghi"
       ⍝    Result      'abc def  ghi'                'abd\ndef\nghi'
       ⍝    Forms       'abc ...\n   def   ...\n'     "abc ...\n   def   ...\n"
       ⍝    Result      'abc ... def   ...'           'abc ...\ndef    ...'
       ⍝    Forms       'abc  \n   def'..L            "abc   \n   def"..L
       ⍝    Result      'abc       def'               'abc   \n   def'
       ⍝
       ⍝ In SQ strings, newlines and extra blanks are just ignored at EOL, Start of line.
       ⍝ In DQ strings, newlines are kept*, but such extra blanks are also ignored.
       ⍝ * Except with ellipses-- SQ and DQ strings treated the same.
       ⍝   See ellipses in strings below.
       ⍝ Note difference:
       ⍝     [1]                    [2]                [3]            [4]
       ⍝    'one two              "one two            'one cat..     "one cat..
       ⍝     three four            three four            alog cat      alog cat
       ⍝     five'                 five"                   alog'        alog"
       ⍝  [1] 'one two three four five'
       ⍝  [2] ('one two',(⎕UCS 10),'three four',(⎕UCS 10),'five')
       ⍝  [3] 'one catalog cat alog'
       ⍝  [4] ('one catalog cat',(⎕UCS 10),'alog')
             str sfx←⍵ ∆FIELD 1 2
             sfx←1↑sfx,q←⍬⍴1↑str   ⍝ Suffix is, by default, the quote itself. q is a scalar.
             ~sfx∊'L''"':11 ⎕SIGNAL⍨'∆FIX: Invalid string suffix: <',sfx,'> on ',⍵ ∆FIELD 0
             deQ←{⍺←SQ ⋄ ⍵/⍨~(⍺,⍺)⍷⍵}
             dq2sq←{enQ DQ deQ 1↓¯1↓⍵}
       ⍝ Here, we handle ellipses at linend within SQ or DQ quotes as special:
       ⍝ Any spaces BEFORE them are preserved. If none, the next line is juxtaposed w/o spaces.
       ⍝ Not clear this (identical) behavior is what we want for SQ and DQ quotes.
       ⍝ WARNING: Right now, by intention, the ellipses must be the rightmost characters--
       ⍝   trailing blanks will force the ellipses to be treated as ordinary characters.
       ⍝   I.e.   'anything ... $ has "ordinary" dots as characters ($=EOL).
       ⍝          'anything ...$  marks a continuation line.
             ellipsesP←'(?:\…|\.{2,})$\s*'
             str←ellipsesP ⎕R''⍠OPTSre⊣str
             str←dq2sq⍣(q=DQ)⊣str
             ~NL∊str:str
             sfx{
                 addP←{'(',⍵,')'}
                 nlCode←''',(⎕UCS 10),'''
                 ⍺=SQ:'\h*\n\h*'⎕R' '⍠OPTSre⊣⍵
                 ⍺=DQ:addP'\h*\n\h*'⎕R nlCode⍠OPTSre⊣⍵
                 ⍺='L':{
                     q=SQ:'\n'⎕R' '⍠OPTSre⊣⍵
                     addP'\n'⎕R nlCode⍠OPTSre⊣⍵
                 }⍵
                 ○LOGIC ERROR.UNREACHABLE
             }str
         }
     :EndSection Reused Pattern Actions
 :EndSection Initialization
 ⍝-------------------------------------------------------------------------------------------
 :Section Read in file or stdin
     readFile←{
         pfx obj sfx←{
             p o s←⎕NPARTS ⍵      ⍝
             s≡'.dyalog':p o s    ⍝  a/b/c.d.dyalog   →   a/b/   c.d  .dyalog
             s≡'':p o'.dyalog'    ⍝  a/b/c            →   a/b/   c    .dyalog
             p(o,s)'.dyalog'      ⍝  a/b/c.d          →   a/b/   c.d  .dyalog
         }⍵
         infile←pfx,obj,sfx
         code←{0::⎕NULL ⋄ ⊃⎕NGET ⍵ 1}infile
         code≡⎕NULL:22 ⎕SIGNAL⍨('∆FIX: File not found (⍵): ',infile)
         code
     }
     :If ⍬≡fileName
         opts.showcompiled←1
         ⎕SHADOW'counter' 'line' 'lines' 'more' 'tFun'
         lines counter tFun←⍬ 0 '_STDIN_'
         '> Enter input lines. Null line when done.'
         ⎕←'    ∇ ',tFun,'            ⍝ ∆FIX temporary function'
         :While 1
             _←≢⍞←'[',(⍕counter←counter+1),'] '
             :If 0≠≢line←_↓⍞ ⋄ lines,←⊂line ⋄ :Else ⋄ :Leave ⋄ :EndIf
         :EndWhile
         ⎕←'    ∇'
         fileName←(739⌶0),'/','#FIXstdin.dyalog'
         :Trap 0
             :If ×≢lines
                 1 ⎕NDELETE fileName ⋄ lines←(⊂'∇',tFun),lines,(⊂,'∇') ⋄ (⊂lines)⎕NPUT fileName
             :EndIf
             :If opts.debug ⋄ ⎕←↑⊃⎕NGET fileName 1 ⋄ :EndIf
         :Else
             ⎕SIGNAL/('∆FIX: Error creating temporary file: ',fileName)11
         :EndTrap
     :EndIf
     code←readFile fileName
 :EndSection Read In file or stdin

 :Section Setup:Scan Patterns and Actions
     DICT←∆DICT''                                                    ⍝ Define DICT
     _←⎕FX'{_}←name ALIAS value' '_←DICT.set (name~'' '') (⍕value)'  ⍝ Define ALIAS to DICT.set

     _←'⎕HERE    'ALIAS CalledFrom

   ⍝ ⎕LET.(UC, LC, ALPH): Define upper-case, lower-case and all valid initials letters
   ⍝ of APL names. (Add ⎕D for non-initials).
   ⍝ Bad idea: (Dict macros treat ⎕LET.UC, ⎕LET.uc, ⎕LET.Uc, ⎕LET.uC as synonyms, i.e. case is ignored for system extensions.)
   ⍝ Do by hand.
     '⎕LET      'ALIAS'LETTER_NS'⎕NS''
     '⎕LET.LC   'ALIAS _←enQ 56↑ALPH
     '⎕LET.lc   'ALIAS _
     '⎕LET.UC   'ALIAS _←enQ 55↑56↓ALPH
     '⎕LET.uc   'ALIAS _
     '⎕LET.ALPH 'ALIAS _←enQ ALPH
     '⎕LET.alph 'ALIAS _
   ⍝ Valid APL simple names
     nameP←eval'(?:   ⎕? [⍎ALPH] [⍎ALPH\d]* | \#{1,2} )'
   ⍝ Valid APL complex names
     longNameP←eval'(?: ⍎nameP (?: \. ⍎nameP )* )  '
   ⍝ anyNumP: If you see '3..', 3 is the number, .. treated elsewhere
     anyNumP←'¯?\d (?: [\dA-FJE¯_]+|\.(?!\.) )+ [XI]?'
   ⍝ Modified not to match numbers in names:  NAME001_23 etc.
     anyNumP←'(?![⍎ALPH\d¯_])¯?\d (?: [\dA-FJE¯_]+|\.(?!\.) )+ [XI]?'
    ⍝ Matches two fields: one field in addition to any additional surrounding field...
     parenP←'('setBrace')'
     brackP←'['setBrace']'
     braceP←'{'setBrace'}'
   ⍝ Simple strings:
     dqStringP←'(?:  "[^"]*"     )+'
     sqStringP←'(?: ''[^'']*'' )+'
     stringP←eval'(?: ⍎dqStringP | ⍎sqStringP )'
   ⍝ Special Strings:     'text'..L   OR   "text"..L
   ⍝ Currently, only L (upper case) is defined as a suffix. See stringAction (above).
   ⍝  field1 will be the quoted string, including quotes. f2 may be null or a single alphabetic char.
     specialStringP←eval' (⍎stringP)  (?: \.{2,2} ([A-Z]) )? '
   ⍝ Comment pat
     commentP←'(?: ⍝.* )'
   ⍝ Ellipses: either two or more dots (..) or the Unicode ellipses single character: '…'
     ellipsesP←'(?:  […•∙] | \.{2,} )'
   ⍝ name Attributes: .. or • separator between names:  name..DEF or name•DEF, etc.
   ⍝ In this version, we treat as  same def as ellipsesP, since they overlap.
   ⍝ (The attribute was originally two-dots as "like a dot", but bullet was added based on
   ⍝  a similarity to John Daintree's TOE (Theory of Everything) ideas).
     nameAttributeP←ellipsesP
   ⍝ A directive prefix
     directiveP←'^ \h* :: \h*'
   ⍝ Directives with code that spans lines.
   ⍝ ... Succeed only if {} () '' "" strings are balanced.
   ⍝ (Note: requires that RHS comments have already been removed.)
     multiLineP←'(?: (?: ⍎braceP | ⍎parenP | ⍎stringP  | [^{(''"\n]+ )* )'

     :Section Preprocess Tradfn Headers...
      ⍝  1st line of 2∘⎕FIX-compatible file must start with
      ⍝      :Namespace, :Class, or :Interface directive OR
      ⍝      a function header (with or without explicit ∇ fn prefix).
      ⍝   [A] :directives above OR explicit ∇function header. (See [B]).
      ⍝       There may be one or more of the objects listed above.
         :If ':⍝∇'∊⍨1↑' '~⍨⊃code
           ⍝ Tradfn header with leading ∇.
           ⍝ (To be treated as a header, it must have one alpha char after ∇.)
           ⍝ Could occur on any line...
           ⍝                 ∇     lets|{lets}|(lets) - minimal check for fn hdr
             code←'(?x)^ \h* ∇ \h* [\w\{\(] [^\n]* $   (?: \n  \h* ; [^\n]* $ )*'⎕R{
                 SEMICOLON_FAUX@(';'∘=)⊣⍵ ∆FIELD 0
             }⍠OPTSre⊣code
         :Else ⍝ [B] File starts with function headers sans ∇ prefix.
         ⍝ This means there is one object (the function) in the file.
           ⍝ Here, 1st line is assumed to be tradfn header without leading ∇: Process the header ONLY
             hdr←''
             code←'(?x)\A ([^\n]*) $   (?: \n \h* ; [^\n]* $ )*'⎕R{
                 hdr∘←⍵ ∆FIELD 1
                 SEMICOLON_FAUX@(';'∘=)⊣i←⍵ ∆FIELD 0
             }⍠OPTSre⊣code
             {}processFnHdr hdr
         :EndIf
     :EndSection Preprocess Tradfn Headers

     :Section Setup:Scans
         :Section PreScan1
             MBegin'PreScan1'
           ⍝ CONTINUATION LINES ARE HANDLED IN SEVERAL WAYS
           ⍝ 1) Within multiline strings, newlines are treated specially (q.v.);
           ⍝ 2) Ellipses-- Unicode … or .{2,}-- in code or strings,
           ⍝    are replaced by a single blank; any trailing comments or newlines or
           ⍝    leading blanks on the next line are ignored;
           ⍝ 3) When a semicolon appears at the end of a line (before opt'l comments),
           ⍝    the next line is appended after the semicolon.
           ⍝ ------------------------------------
           ⍝ Comments on their own line are kept, unless COM is 3
             :If opts.com≠3
                 'COMMENT FULL (KEEP)'(0 register)'^ \h* ⍝ .* $'
             :Else
                 'COMMENT FULL (OMIT)'(''register)'^ \h* ⍝ .* $'
             :EndIf
           ⍝ Multi-line strings:
           ⍝ Handles:
           ⍝  1. DQ strings (linends → newlines, ignoring trailing blanks)
           ⍝  2. SQ strings (linends → ' '
           ⍝  3. .. continuation symbols (at the end of the line) within strings.
           ⍝  4. ..L (and future) suffixes on strings:  "example"..L or 'test'..L
           ⍝ See stringAction above.
             'STRINGS'stringAction register specialStringP
           ⍝ Ellipses and .. (... etc) → space, with trailing and leading spaces ignored.
           ⍝ Warning: Ellipses in strings handled above via 'STRINGS' and stringAction.
             'CONT'(' 'register)'\h*  ⍎ellipsesP \h*  ⍎commentP?  $  \s*'
           ⍝ Skip names, including those that may contain numbers...
           ⍝ See 'NUM CONSTANTS'
           ⍝ Not needed? 'NAMES'(0 register)nameP
           ⍝ NUM CONSTANTS: ⍝ Remove _ from (extended) numbers-- APL and hexadecimal.
           ⍝    From here on in, numbers won't have underscores.
           ⍝    They may still have suffixes X (handled here) or I (for big integers-- future).
             'NUM CONSTANTS'{(⍵ ∆FIELD 0)~'_'}register anyNumP
           ⍝ Leading and trailing semicolons are forced onto the same line...
           ⍝ They may be converted to other forms (see ATOM processing).
           ⍝          ;   <==   2nd-line leading ;           1st-line trailing ;
             'SEMI1'(';'register)'\h* ⍎commentP? $ \s* ; \h* | \h* ; ⍎commentP? $ \s*'
            ⍝ ::DOC/::SKIP directive
            ⍝ ::DOC  \h* [pat]\n   ... lines ...  ::END(DOC)  \h* pat\n
            ⍝ ::SKIP \h* [pat]\n   ... lines ...  ::END(SKIP) \h* pat\n
            ⍝  Descr:
            ⍝    Lines between DOC or SKIP and END(DOC/SKIP) are ignored.
            ⍝    Typically such lines are documentation or comments and
            ⍝    may have HTML or other directives.
            ⍝    Using a unique pattern, e.g.
            ⍝          ::DOC <DOC>
            ⍝    allows another processor to convert self-documented code into
            ⍝    formal documentation.
            ⍝  Note: <pat> excludes leading/trailing blanks, but includes internal blanks.
             _←' ⍎directiveP (DOC|SKIP)\h* $\n (?: .*? \n)* ⍎directiveP END \1? \h*$\n'
             'DOC/SKIP DIRECTIVE 1'(''register)_
             _←' ⍎directiveP     (DOC|SKIP)  \h* ( .*? ) \h* $ \n (?: .*?\n )*'
             _,←'⍎directiveP      END \1?    \h*   \2    \h* $  '
             'DOC/SKIP DIRECTIVE 2'(''register)_
           ⍝ RHS Comments are ignored (removed)...
           ⍝  Not ideal, but makes further regexps simpler.
             'COMMENT RHS'(''register)'\h* ⍝ .* $'
             PreScan1←MEnd
         :EndSection
         :Section PreScan2
             MBegin'PreScan2'
           ⍝ A lot of processing to handle multi-line parens or brackets ...
             'STRINGS'(0 register)stringP                ⍝ Skip
             'COMMENTS FULL'(0 register)'^\h* ⍝ .* $'     ⍝ Skip
             'Multiline () or []' 0{
               ⍝ Remove newlines and associated spaces in (...) and [...]
               ⍝ UNLESS inside quotes or braces!
               ⍝ But newlines inside quotes and braces have already been eaten above.
               ⍝ >>> RETHINK the logic here.
                 ##.stringP ##.braceP'\h*\n\h*'⎕R'\0' '\0' ' '⍠OPTSre⊣⍵ ∆FIELD 0
             }register'(⍎brackP|⍎parenP)'
           ⍝ ::CALL item
           ⍝ SYNTAX: Take all lines between ::CALL\d* and ::END(CALL)\d* (see Note) and
           ⍝    execute in the calling environment:
           ⍝       ⍎'item lines'
           ⍝       item:  Whataver was specified on the ::CALL line.
           ⍝       lines: All lines in between are passed as a vector of char vectors, one per line.
           ⍝       Your function MUST return a vector of vectors, a char matrix, or a string with NLs.
           ⍝    Whatever you return will be inserted into the code stream AS IS.
           ⍝    ---------------
           ⍝    Note:
           ⍝      ::CALL\d* If digits dd are specified on the CALL, ∆FIX will search for
           ⍝      ::ENDdd or ::ENDCALLdd to balance-- all lines in between are assigned to var 'line'.
           ⍝ EXAMPLE:
           ⍝   This illustrative (if impractical) sequence:
           ⍝    |  ::CALL2 {⌽↑⍵}
           ⍝    |    line1
           ⍝    |    this is the 2nd
           ⍝    |    12345
           ⍝    | ::ENDCALL2    ⍝ or ::END2
           ⍝   yields this code in the ∆FIXed file:
           ⍝    | '          1enil'
           ⍝    | 'dn2 eht si siht'
           ⍝    | '          54321'
           ⍝   If the dfn above is named 'backwards" and is accessible from the calling environment,
           ⍝   e.g. via ⎕PATH, the ::CALL line may appear as:
           ⍝    |  ::CALL2 backwards
             'CALL/nn' 0{
                 f0 cmd lines←⍵ ∆FIELD 0 2 3
                 cmd{0::0 ∆COM msg,NL,f0⊣⎕←'Exec Err'box msg⊣msg←'⍝ CALL Compile Time Execution Error'
                     res←##.CalledFrom⍎⍺,' ⍵'          ⍝ CalledFrom-- calling namespace.
                     2=|≡res:1↓∊NL,¨res
                     2=⍴⍴res:1↓∊NL,res
                     res
                 }NL(≠⊆⊢)lines   ⍝ Convert to vector of char vectors
             }register'⍎directiveP CALL(\d*)\h* (.*) $ \n ((?:  .*? \n)*) ^ ⍎directiveP END(?:CALL)?\1.*$'
             PreScan2←MEnd
         :EndSection PreScan2

         :Section Macro Scan(no::directives):Part I
           ⍝ MacroScan1: Used in ::FIRST (q.v.), these exclude any ::directives.
             MacroScan1←⍬    ⍝ Augmented below...
         :EndSection Macro Scan(no::directives):Part I

         :Section MainScan1
             MBegin'MainScan1'
             :Section Register Directives
                ⍝ Comments
                 MacroScan1,←'COMMENTS FULL'(0 register)'^ \h* ⍝ .* $'
                ⍝ IFDEF/IFNDEF stmts
                 '::IFDEF~::IFNDEF' 1{
                     f0 not name←⍵ ∆FIELD 0 1 2
                     ifTrue←~⍣(≢not)⊣DICT.defined name
                     f0 ∆COM⍨CTL.push ifTrue
                 }register'⍎directiveP  IF (N?) DEF\b \h*(⍎longNameP) .* $'
                ⍝ IF stmts
                 '::IF' 1{
                     f0 code0←⍵ ∆FIELD¨0 1
                     TRAP::{
                         _←CTL.push 0            ⍝ Error-- option fails.
                         ⎕←'∆FIX ERROR'box'∆FIX VALUE ERROR: ',⍵
                         qw←⍵/⍨1+SQ=⍵
                         (0 ∆COM ⍵),NL,'911 ⎕SIGNAL⍨''∆FIX VALUE ERROR: ',qw,SQ,NL
                     }f0
                     vOut←DICT.ns{⍺⍎⍵}code1←(0 doScan)code0
                     show←⊂('::IF ',showCodeSnip code0)
                     show,←('➤    ',showCodeSnip code1)('➤    ',showObjSnip vOut)
                     show ∆COM⍨CTL.push ifTrue vOut
                 }register'⍎directiveP IF \b \h* (.*) $'
                ⍝ ELSEIFDEF/ELSEIFNDEF/ELIFDEF/ELIFNDEF  stmts
                 '::ELSEIFDEF~::ELSEIFNDEF' 1{
                     f0 not name←⍵ ∆FIELD¨0 1 2
                     ifTrue←~⍣(≢not)⊣DICT.defined name
                     f0 ∆COM⍨CTL.poke ifTrue
                 }register'⍎directiveP  EL (?:SE)? IF (N?) DEF \b \h* (.*) $'
                ⍝ ELSEIF/ELIF stmts
                 '::ELSEIF~::ELIF' 1{
                     f0 code0←⍵ ∆FIELD 0 1
                     0::{ ⍝ Elseif: poke, don't push
                         _←CTL.poke 1
                         ⎕←'∆FIX ERROR'box'∆FIX VALUE ERROR: ',⍵
                         qw←⍵/⍨1+⍵=SQ
                         (0 ∆COM ⍵),NL,'911 ⎕SIGNAL⍨''∆FIX VALUE ERROR: ',qw,SQ,NL
                     }f0
                     vOut←DICT.ns{⍺⍎⍵}code1←(0 doScan)code0
                     show←⊂('::ELSEIF ',showCodeSnip code0)
                     show,←('➤    ',showCodeSnip code1)('➤    ',showObjSnip vOut)
                     show ∆COM⍨CTL.poke ifTrue vOut
                 }register'⍎directiveP  EL (?:SE)? IF\b \h* (.*) $'
                ⍝ ELSE
                 '::ELSE' 0{ ⍝ flip <-> peek, flip bit, poke
                     CTL.flip ∆COM ⍵ ∆FIELD 0
                 }register'⍎directiveP ELSE \b .* $'
                ⍝ END, ENDIF, ENDIFDEF, ENDIFNDEF
                 '::ENDIFDEF~::ENDIF~::END' 0{
                     f0←⍵ ∆FIELD 0
                     CTL.stackEmpty:{
                         ⎕←box'Stmt invalid (out of context): ',⍵
                         '911 ⎕SIGNAL⍨ ''∆FIX ::END DOMAIN ERROR: out of scope.''',CR,0 ∆COM ⍵
                     }f0
                     CTL.pop ∆COM f0
                 }register'⍎directiveP  END  (?: IF  (?: N? DEF)? )? \b .* $'
               ⍝ CONDITIONAL INCLUDE - include only if not already included
                 filesIncluded←⍬
                 '::CINCLUDE' 1{
                     f0 fName←⍵ ∆FIELD 0 1 ⋄ fName←{k←'"'''∊⍨1↑⍵ ⋄ k↓(-k)↓⍵}fName
                     (⊂fName)∊##.filesIncluded:0 ∆COM f0⊣⎕←box f0,': File already included. Ignored.'
                     ##.filesIncluded,←⊂fName
                     rd←{22::22 ⎕SIGNAL⍨'∆FIX: Unable to CINCLUDE file: ',⍵ ⋄ readFile ⍵}fName
                     (CR,⍨∆COM f0),∆V2S(0 doScan)rd
                 }register'⍎directiveP  CINCLUDE \h+ (⍎stringP | [^\s]+) .* $'
                ⍝ INCLUDE
                 '::INCLUDE' 1{
                     f0 fName←⍵ ∆FIELD 0 1 ⋄ fName←{k←'"'''∊⍨1↑⍵ ⋄ k↓(-k)↓⍵}fName
                     ##.filesIncluded,←⊂fName   ⍝ See CINCLUDE
                     rd←{22::22 ⎕SIGNAL⍨'∆FIX: Unable to INCLUDE file: ',⍵ ⋄ readFile ⍵}fName
                     (CR,⍨∆COM f0),∆V2S(0 doScan)rd
                 }register'⍎directiveP  INCLUDE \h+ (⍎stringP | [^\s]+) .* $'
                ⍝ COND (cond) stmt   -- If cond is non-zero, a single stmt is made avail for execution.
                ⍝ COND single_word stmt
                ⍝ Does not affect the CTL.stack or CTL.skip...
                 '::COND' 1{
                     f0 cond0 stmt←⍵ ∆FIELD 0 1 3   ⍝ (parenP) uses up two fields
                     0=≢stmt~' ':0 ∆COM'No stmt to evaluate: ',f0
                     0::{
                         ⎕←↑⎕DMX.DM
                         ⎕←box'∆FIX VALUE ERROR: ',⍵
                         qw←⍵/⍨1+⍵=SQ
                         (0 ∆COM ⍵),NL,'911 ⎕SIGNAL⍨NO,''∆FIX VALUE ERROR: ',qw,SQ,NL
                     }f0
                     cond2←DICT.ns{⍺⍎⍵}cond1←(0 doScan)cond0
                     t←ifTrue cond2
                     stmt←⍕(0 doScan)stmt
                     show1←t ∆COM f0('➤  ',showCodeSnip cond1)('➤  ',showObjSnip cond2)('➤  ',showObjSnip t)
                     show1,CR,(NOc/⍨~t),stmt  ⍝ F1   F2               F2         F3
                 }register'⍎directiveP COND \h+ ((?| ⍎parenP | [^\s]+ () )) \h*  ( ⍎multiLineP ) $'
               ⍝ DEFINE name [ ← value]
               ⍝ Note: value is left unevaluated (as a string) in ∆FIX (see LET for alternative)
               ⍝     ::DEFINE name       field1=name, field3 is null string.
               ⍝     ::DEFINE name ← ... field1=name, field3 is rest of line after arrow/spaces
               ⍝ DEFINEL (L for literal or DEFINER for raw):
               ⍝     Don't add parens around code sequences outside parens...
                 defS←'⍎directiveP  DEF(?:INE)?([LR]?) \b \h* (⍎longNameP) (?:  (?: \h* ←)? \h*  ( ⍎multiLineP ) )? $'
                 '::DEF~::DEFINE' 1{
                     f0 l k vIn←⍵ ∆FIELD 0 1 2 3
                   ⍝ Replace leading and trailing blanks with single space
                     vIn←{
                         0=≢⍵:,'1'
                         '('=1↑⍵:'\h*\R\h*'⎕R' '⍠OPTSre⊣⍵
                         ⍵
                     }vIn
                     vOut←(0 doScan)vIn
                     _←DICT.set k(vOut)
                     ∆COM f0('➤  ',vOut)
                 }register defS
                ⍝ LET  name ← value   ⍝ value (which must fit on one line) is evaluated at compile time
                ⍝ EVAL name ← value   ⍝ (synonym)
                 '::LET::~::EVAL' 1{
                     f0 k vIn←⍵ ∆FIELD 0 1 2
                     0::{
                         ⎕←↑⎕DMX.DM
                         ⎕←box'∆FIX VALUE ERROR: ',⍵
                         _←DICT.del k
                         msg←(f0)('➤ UNDEF ',k)
                         qw←⍵/⍨1+⍵=SQ
                         (0 ∆COM msg),NL,'911 ⎕SIGNAL⍨''∆FIX VALUE ERROR: ',qw,SQ,NL
                     }f0
                     _←DICT.validate k
                     code←(0 doScan)vIn
                     vOut←DICT.ns{⍺⍎⍵}k,'←',code
                     msg1←'➤ LET ',k,' ← ',∆V2S code
                     msg2←'➤ DEF ',k,' ← ',∆V2S{0::'∆FIX LOGIC ERROR!' ⋄ ⎕FMT ⍵}vOut
                     ∆COM f0 msg1 msg2
                 }register'⍎directiveP  (?: LET | EVAL) \b \h* (⍎longNameP) \h* ← \h* (⍎multiLineP) $'
                ⍝ :PRAGMA name ← value
                ⍝  (Names are case insensitive)
                ⍝ Current Pragmas
                ⍝    FENCE.    Sets the name of the temp variable for "fence" constructions (←⍳5) etc.
                ⍝    Syntax:   ::PRAGMA FENCE ← 'var_name'
                ⍝    Default:  ::PRAGMA FENCE ← '⍙F⍙'
                 '::PRAGMA' 1{
                     f0 k vIn←⍵ ∆FIELD 0 1 2 ⋄ k←1(819⌶)k  ⍝ k: ignore case
                     0=≢k:∆COM f0⊣{
                         ''⊣⎕←box(' FENCE: ',SQ,(⍕##.PRAGMA_FENCE),SQ)(' DEBUG: ',⍕##.opts.debug)
                     }⍬
                     TRAP::{911 ⎕SIGNAL⍨'∆FIX ::PRAGMA VALUE ERROR: ',f0}⍬
                     _←DICT.validate k
                     vOut←DICT.ns{⍺⍎⍵}k,'←',vIn
                     msg←'➤ DEF ',k,' ← ',∆V2S{0::'∆FIX LOGIC ERROR!' ⋄ ⎕FMT ⍵}vOut
                     ∆COM f0 msg⊣{
                         'FENCE'≡k:⊢##.PRAGMA_FENCE∘←vOut
                         'DEBUG'≡k:⊢##.opts.debug∘←vOut
                         911 ⎕SIGNAL⍨'∆FIX ::PRAGMA KEYWORD UNKNOWN: "',k,'"'
                     }⍬
                 }register'⍎directiveP  PRAGMA \b (?:  \h+ (⍎longNameP)  \h* ← \h* (.*) | .*) $'
                ⍝ UNDEF(ine) name
                 '::UNDEF' 1{ ⍝ As eyecandy, we mark failure if name to undef not defined.
                     f0 k←⍵ ∆FIELD 0 1
                     _←DICT.del k⊣bool←DICT.defined k
                     bool ∆COM f0
                 }register'⍎directiveP  UNDEF (?:INE)? \b\h* (⍎longNameP) .* $'
                ⍝ ERROR stmt
                ⍝ Generates a preprocessor error signal...
                 '::ERROR' 1{
                ⍝  CTL.skip:0 ∆COM ⍵ ∆FIELD 0
                     line num msg←⍵ ∆FIELD¨0 1 2
                     num←⊃⊃⌽⎕VFI num,' 0' ⋄ num←(num≤0)⊃num 911
                     ⎕←CR@(NL∘=)⊣('\Q',line,'\E')⎕R(NO,'\0')⍠OPTSre⊣⍵.Block
                     ⎕SIGNAL/('∆FIX ERROR: ',msg)num
                 }register'⍎directiveP ERR(?:OR)? (?| \h+ (\d+) \h (.*) | () \h* (.*) ) $'
                ⍝ MESSAGE / MSG stmt
                ⍝ Puts out a msg while preprocessing...
                 '::MSG~::MESSAGE' 1{
                     line msg←⍵ ∆FIELD 0 1
                     ⎕←box msg
                     ∆COM line
                 }register'⍎directiveP  (?: MSG | MESSAGE)\h*+(.*)\h*?$'
               ⍝ ::FIRST\h*[text] ...lines... END(FIRST)\h*[text]
               ⍝   text:   must match (ignoring leading/trailing blanks).
               ⍝   lines:  are executed as the object is ⎕FIXed,
               ⍝           in the namespace of the caller. Any errors are noted then.
                  ⋄ firstP←'⍎directiveP FIRST\h* ( .* ) $ \n'
                  ⋄ firstP,←'((?: ^ .* $ \n)*?) ^ ⍎directiveP END (?: FIRST )?+  \h*+ (?>\1) \h*? $'
                  ⍝ firstBuffer: initialized at top
                 '::FIRST' 1{
                     f1 f2←⍵ ∆FIELD 1 2
                     code1←(0 doScan)f2
                     leaf1←(NL∘≠⊆⊢)f2 ⋄ leaf2←(NL∘≠⊆⊢)code1
                     join←∊leaf1,¨(⊂NL,' ➤ '),¨leaf2,¨NL
                     ##.firstBuffer,←code1
                     1 ∆COM'::FIRST ',f1,NL,join,'::ENDFIRST ',f1,NL
                 }register firstP
             :EndSection Register Directives

             :Section Register Macros and Related
               ⍝ Start of every NON-MACRO line → comment, if CTL.skip is set. Else NOP.
                 'SIMPLE_NON_MACRO' 0{
                     CTL.skip/NOc,⍵ ∆FIELD 0
                 }register'^'
               ⍝ ∇ function header...
                 '∇ FUNCTION DEF' 0{
                     f0 f1←⍵ ∆FIELD 0 1
                     0=≢f1:f0          ⍝ ∇ by itself-- not a header.
                     f0⊣processFnHdr(0 doScan)f1
                 }register'^\h* ∇ (?: \h* | (.*) ) $'
               ⍝ name Attributes: .. or •
               ⍝ name..DEF    OR name•DEF   → 1/0 if name is/notdefined
               ⍝                            → (0≠⎕NC 'myNs.myName')
               ⍝ name..UNDEF  OR name•UNDEF → 1/0 if name is not/is defined
               ⍝ name..Q      OR name•Q     → quotes name as   'name'
               ⍝ name..NC     etc           → returns ⎕NC ⊂,'name'
               ⍝ name..SIZE                           ⎕SIZE 'name'
               ⍝ name..DR                     returns 0 if name not defined
               ⍝                                     ¯1 if not a var or class 9
               ⍝                                      ⎕DR name otherwise
               ⍝ name..ENV    OR name•ENV   → returns value of getenv('name') or null
               ⍝ myNs.myName..DEF OR myNs.myName•DEF etc:
                 MacroScan1,←'name..cmd or name•cmd' 1{
                     nm cmd←⍵ ∆FIELD 1 2 ⋄ cmd←1(819⌶)cmd
               ⍝ For name of the form n1.n2.n3.n4,
               ⍝ check, in order, if any of these is a macro, i.e. has a value:
               ⍝        n1.n2.n3.n4, n1.n2.n3, n1.n2, n1
               ⍝ Using the first macro value found, cN, say n1.n2,
               ⍝ replace n1.n2.n3.n4 with cN.n3.n4.
               ⍝ If that is a name, use that here.
               ⍝ Otherwise keep the input n1.n2.n3.n4.
                     nm←DICT.resolve nm
                     cmd≡'ENV':' ',SQ,(getenv nm),SQ,' '
                     nmq←SQ,nm,SQ
                     cmd≡'DEF':'(0≠⎕NC',')',⍨nmq
                     cmd≡'UNDEF':'(0=⎕NC',')',⍨nmq
                     cmd≡'NC':'(⎕NC⊂',(','/⍨1=≢nm),')',⍨nmq
                     cmd≡'SIZE':'(⎕SIZE',')',⍨nmq
                     cmd≡'DR':'({⍺←⎕NC',nmq,'⋄ ⍺∊2 9: ⎕DR ',nm,'⋄ ⍺≠0:¯1 ⋄ 0}0)'
                     cmd≡,'Q':' ',SQ,nm,SQ,' '
                     ⎕SIGNAL/('Unknown cmd ',⍵ ∆FIELD 0)911
                 }register'(⍎longNameP)⍎nameAttributeP(ENV|DEF|UNDEF|NC|SIZE|DR|Q)\b'
               ⍝ ATOMS, PARAMETERS (PARMS)
               ⍝ atoms: n1 n2 n3 → anything,   `n1 n2 n3
               ⍝  parms: bc def ghi → xxx     →   ('abc' 'def' 'ghi')
               ⍝       ( → code;...) ( ...; → code; ...) are also allowed. The atom is then ⍬.
               ⍝ To do: Allow char constants-- just don't add quotes...
               ⍝ To do: Treat num constants as unquoted scalars
                 atomsP←' (?:         ⍎longNameP|¯?\d[\d¯EJ\.]*|⍎sqStringP|⍬)'
                 atomsP,←'(?:\h+   (?:⍎longNameP|¯?\d[\d¯EJ\.]*|⍎sqStringP)|\h*⍬+)*'
                 MacroScan1,←'ATOMS/PARMS' 2{
                     atoms arrow←⍵ ∆FIELD 1 2
               ⍝ Split match into individual atoms...
                     atoms←(##.stringP,'|[^\h''"]+')⎕S'\0'⍠OPTSre⊣,(0=≢atoms)⊃atoms'⍬'
                     o←1=≢atoms ⋄ s←0   ⍝ o: one atom; s: at least 1 scalar atom
                     atoms←{
                         NUM←('¯.',⎕D,'⍬') ⋄ a←1↑⍵
                         a∊NUM:⍵⊣s∘←1         ⍝ Pass through 123.45, w/o adding quotes (not needed)
                         a∊##.SQ:⍵⊣s∨←3=≢⍵        ⍝ Pass through 'abcd' w/o adding quotes (already there)
                         ##.SQ,##.SQ,⍨⍵⊣s∨←1=≢⍵
                     }¨atoms
                     sxo←s∧~o
                     atoms←(∊o s sxo/'⊂,¨'),1↓∊' ',¨atoms
                     1=≢arrow:'(⊂',atoms,'),⊂'     ⍝ 1=≢arrow: Is there a right arrow?
                     '(',atoms,')'
                 }register'\h* (?| (⍎atomsP) \h* (→) | (?<=[(;])() \h*  (→) | ` (⍎atomsP) ) \h* (→)?'
                ⍝ STRINGS: passthrough (only single-quoted strings appear.
                ⍝ Must follow ATOMs
                 MacroScan1,←'STRING' 0(0 register)sqStringP
                ⍝ Hexadecimal integers...
                ⍝ See ⎕UdhhX for hexadecimal Unicode constants
                 MacroScan1,←'HEX INTs' 2{
                     ⍕h2d ⍵ ∆FIELD 0
                 }register'(?<![⍎ALPH\d])  ¯? \d [\dA-F]* X \b'
                ⍝ Big integers...
                ⍝ ¯?dddddddddI  →  ('¯?ddddddd')
                 MacroScan1,←'BigInts' 2{
                     SQ,SQ,⍨⍵ ∆FIELD 1
                 }register'(?<![⍎ALPH\d])  (¯? \d+) I \b'
                ⍝ UNICODE, decimal (⎕UdddX) and hexadecimal (⎕UdhhX)
                ⍝ ⎕U123 →  '⍵', where ⍵ is ⎕UCS 123
                ⍝ ⎕U021X →  (⎕UCS 33) → '!'
                 MacroScan1,←'UNICODE' 2{
                     i←{'xX'∊⍨⊃⌽⍵:h2d ⍵ ⋄ 1⊃⎕VFI ⍵}⍵ ∆FIELD 1
                     (i≤32)∨i=132:'(⎕UCS ',(⍕i),')'
                     ' ',SQ,(⎕UCS i),SQ,' '
                 }register'⎕U ( \d+ | \d [\dA-F]* X ) \b'
                ⍝ MACRO: Match APL-style simple names that are defined via ::DEFINE above.
                ⍝ Captured as macroReg for re-use
                 MacroScan1,←'MACRO' 2{
                     TRAP::k⊣⎕←'Unable to get value of k. Returning k: ',k
                     v←DICT.resolve(k←⍵ ∆FIELD 1)
                     0=≢v:k
                     v
                 }register'(?<!'')((?>⍎longNameP))(?!\.\.)(?!'')'
                ⍝   ← becomes ⍙S⍙← after any of '()[]{}:;⋄'
                ⍝   ⍙S⍙: a "fence"
                 MacroScan1,←'ASSIGN' 2{
                     ##.PRAGMA_FENCE,'←'
                 }register'^ \h* ← | (?<=[(\[{;:⋄]) \h* ←  '
             :EndSection Register Macros and Related
         :EndSection MainScan1
         MainScan1←MEnd
     :EndSection Setup Scans

      ⍝ MacroScan1 - See description above.
     :Section Macro Scan(no::directives):Part II
         MacroScan1.MScanName←⊂'Macro Scan (no ::directives)'
     :EndSection Macro Scan(no::directives):Part II

     :Section List Scan
     ⍝ Handle lists of the form:
     ⍝        (name1; name2; ;)   (;;;) ()  ( name→val; name→val;) (one_item;) (`an atom of sorts;)
     ⍝ Lists must be of the form  \( ... \) with
     ⍝       - at least one semicolon or
     ⍝       - be exactly  \( \s* \), e.g. () or (  ).
     ⍝ Parenthetical expressions without semicolons are standard APL.
         MBegin'List Scan'
         Par←⎕NS'' ⋄ Par.enStack←0
         'COMMENTS FULL' 0(0 register)'^ \h* ⍝ .* $'
         'STRINGS' 0(0 register)'⍎sqStringP'
         'Null List/List Elem' 0{   ⍝ (),  (;) (;...;)
             sym←⍵ ∆FIELD 0 ⋄ nSemi←+/sym=';'
             '(',')',⍨(','⍴⍨nSemi=1),'⍬'⍴⍨1⌈nSemi
         }register'\((?:\s*;)*\)'
         'Parens/Semicolon' 0{
             Par←##.Par ⋄ sym endPar←⍵ ∆FIELD 0 1 ⋄ sym0←⊃sym
             inP←⊃⌽Par.enStack
             ';'=sym0:{
                 notP←1≥≢Par.enStack
                 Par.enStack↓⍨←-e←×≢endPar
               ⍝ Did we match a right paren (after semicolons)?
               ⍝ This is invalid whenever semicolon is on header line!
               ⍝ We handle function headers (q.v.) above.
                 notP:∊(⊂' ⊣')@(';'∘=)⊣⍵     ⍝   ';' outside [] or () treated as ⊣
                 ~inP:⍵
                 n←¯1++/';'=⍵
                 n=0:∊e⊃')(' ')'
                 ∊((0⌈n-1)⍴⊂'⍬'),e⊃')(⍬)(' ')(⍬)'
             }sym
             '('=sym0:{
                 Par.enStack,←1
                 n←+/';'=⍵
                 ∊(n⍴⊂'(⍬)'),'('
             }sym
             '['=sym:sym⊣Par.enStack,←0     ⍝ Semicolons governed by [] are not special.
             ']'=sym:sym⊣Par.enStack↓⍨←¯1
             '('=sym:sym⊣Par.enStack,←1     ⍝ Semicolons governed by () are special.
             ')'=sym:sym⊣Par.enStack↓⍨←¯1
         }register'\( \h* ; (?: \h* ; )* | ; (?: \h* ; )* \h* ( \)? ) |  [();\[\]]  '

         ListScan←MEnd
     :EndSection List Scan

     :Section Setup:Scan Procedure
     ⍝ To scan simple expressions:
     ⍝   code← [PreScan1 PreScan2] MainScan1 (⍺⍺ doScan)⊣ code
     ⍝          ⍺:    MainScan1 (default) or list of scans in order
     ⍝          ⍺⍺=1: Save and restore the IF and CTL.skip stacks during use.
     ⍝          ⍺⍺=0: Maintain existing stacks
         CTL.stack←1
         doScan←{
             TRAP::⎕SIGNAL/⎕DMX.(EM EN)
             ⍺←MacroScan1       ⍝ Default is MacroScan1 (Macros only from MainScan1)
             stackFlag←⍺⍺
             _←CTL.saveIf stackFlag
             res←⍺{
                 0=≢⍺:⍵
                 scan←⊃⍺

                 _code←scan.pats ⎕R(scan MActions)⍠OPTSre⊣⍵

                 (1↓⍺)∇ _code
             }⍵
             res⊣CTL.restoreIf stackFlag
         }
     :EndSection Setup:Scan Procedure
 :EndSection Setup:Scan Patterns and Actions
 :Section Executive:Perform Scans
       ⍝ =================================================================
       ⍝ Executive
       ⍝ =================================================================
     code←PreScan1 PreScan2 MainScan1 ListScan(0 doScan)code

       ⍝ Clean up based on comment specifications (opts.com)
     :Select opts.com
              ⍝ Even if COMPSPEC=3, we have generated new Case 2 comments ⍝[❌🅿️]
     :Case 3 ⋄ code←'(?x)^\h* ⍝ .*\n    (\h*\n)*' '^(\h*\n)+'⎕R'' '\n'⍠OPTSre⊣code
          ⋄ :Case 2 ⋄ code←'(?x)^\h* ⍝[❌🅿️].*\n(\h*\n)*' '^(\h*\n)+'⎕R'' '\n'⍠OPTSre⊣code
          ⋄ :Case 1 ⋄ code←'(?x)^\h* ⍝❌    .*\n(\h*\n)*' '^(\h*\n)+'⎕R'' '\n'⍠OPTSre⊣code
             ⍝ Otherwise: do nothing
     :EndSelect
       ⍝ Other cleanup: Handle (faux) semicolons in headers...
     code←{';'@(SEMICOLON_FAUX∘=)⊣⍵}¨code
 :EndSection Executive:Perform Scans

 :Section Complete Preprocessing
     :Section "::FIRST "Directive Phase II:Process firstBuffer
         :If 0≠≢firstBuffer
         :AndIf 0≠≢firstBuffer~' ',NL
             firstBuffer←'Bêgin',NL,firstBuffer
             :If ' '=1↑0⍴⎕FX NL(≠⊆⊢)firstBuffer
                 :Trap 0
                     :If opts.debug
                         '***** Begin processing...' ⋄ ⎕VR'Bêgin' ⋄ :EndIf
                     Bêgin
                     :If opts.debug ⋄ '***** End Begin processing' ⋄ :EndIf
                 :Else ⋄ ⎕←box↑⎕DMX.DM
                     :If 0=opts.debug
                         ⎕VR'Bêgin'
                         _←'∆FIX ERROR: ::FIRST sequence ran incompletely, due to invalid code.'
                         _ ⎕SIGNAL 11
                     :EndIf
                 :EndTrap
             :Else
                 _←'∆FIX ERROR: ::FIRST sequence could not be run at all.'
                 _ ⎕SIGNAL 11
             :EndIf
         :EndIf
     :EndSection "::FIRST "Directive Phase II:Process firstBuffer

     :If opts.showcompiled
         ⎕ED'code'
     :EndIf

     :Section Write object so we can do a 2∘⎕FIX import
         tmpfile←(739⌶0),'/','TMP~.dyalog'
         :Trap 11 ⍝ TRAP
             (⊂code)⎕NPUT tmpfile 1         ⍝ 1: overwrite file if it exists.
             objects←2(0⊃⎕RSI).⎕FIX'file://',tmpfile
       ⍝ Break association betw. <objects> and file TMP~ that ⎕FIX creates.
             :If 0∊(0⊃⎕RSI).(5178⌶)¨objects
                 ⎕←'∆FIX: Logic error dissociating objects: ',,⎕FMT objects ⋄ :EndIf
             :Select opts.out          ⍝ n|c|nc
                  ⋄ :Case 1 0 ⋄ result←1 objects
                  ⋄ :Case 1 1 ⋄ result←1 objects code
                  ⋄ :Case 0 1 ⋄ result←1 code
                  ⋄ :Case 0 0 ⋄ result←,1
             :EndSelect
         :Else ⍝ Error: returns    0 trap.( errno errmsg errordisplay)
             result←0 ⎕DMX.(EN EM DM)
         :EndTrap
         :If opts.debug ⋄ ⎕←'Debug: temporary file (normally deleted) is: ',tmpfile
         :Else ⋄ 1 ⎕NDELETE tmpfile
         :EndIf
     :EndSection Write object so we can do a 2∘⎕FIX import

     :If opts.debug
         ⎕←'PreScan1  Pats: 'PreScan1.info
         ⎕←'PreScan2  Pats: 'PreScan2.info
         ⎕←'MainScan1 Pats: 'MainScan1.info
         ⎕←'MacroScan1 Pats:'MacroScan1.info
         ⎕←'      *=passthrough'
         :If 0≠≢keys←DICT.keys
             'Defined names and values'
             ⍉↑keys DICT.values
         :Else
             'No names and values were set.'
         :EndIf
     :EndIf
 :EndSection Complete Preprocessing
