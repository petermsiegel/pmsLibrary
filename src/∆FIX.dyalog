﻿ result←{specs}∆FIX fileName
 ;ALPH;CR;DEBUG;DQ;CTL_STACK;MActions;MainScan1;MBegin;MEnd;MPats;MRegister;Match;NO;NOc;NL;PreScan1
 ;SAVE_STACK;CTL_SKIP;SQ;TRAP;YES;UTILS;YESc;_MATCHED_GENERICp
 ;atomsP;box;braceCount;braceP;brackP;code;comment;comSpec;defMatch;defS;dict;dictNameP;doScan;dqStringP
 ;err;eval;filesIncluded;getenv;infile;keys;letS;longNameP;macros;macro;nameP;names;notZero;obj;oldCTL_SKIP;opts;objects
 ;show;showc;subMacroparenP;pfx;readFile;register;setBrace;sfx;CTL_SKIP;outSpec;sqStringP;stringAction
 ;stringP;tmpfile;ø;∆COM;∆DICT;∆FIELD;∆PFX;∆V2S;∆V2Q;⎕IO;⎕ML;⎕PATH;⎕TRAP

 ⍝ A Dyalog APL preprocessor
 ⍝
 ⍝ result ←  [outSpec [comSpec [DEBUG]]] ∆FIX fileName
 ⍝
 ⍝ Description:
 ⍝   Takes an input file <fileName> in 2 ⎕FIX format, preprocesses the file, then 2 ⎕FIX's it, and
 ⍝   returns the objects found or ⎕FIX error messages.
 ⍝   Like, ⎕FIX, accepts either a mix of namespace-like objects (namespaces, classes, interfaces) and functions (marked with ∇)
 ⍝   or a single function (whose first line must be its header, with a ∇-prefix optional).

 ⍝ fileName: the full file identifier; if no type is indicated, .dyalog is appended.
 ⍝
 ⍝ outSpec:  ∊0 (default), 1, 2. Indicates the format of the return value*.
 ⍝           On success, rc (return code) is 0.
 ⍝            0 - returns*: rc names             -- names: the list of objects created by a ⎕FIX.
 ⍝            1 - returns*: rc names code        -- code:  output (vec of strings) from the preprocessor.
 ⍝            2 - returns*: rc code              -- rc:    0 on success
 ⍝            * If an error occurs, returns:
 ⍝                signalNum signalMsg            -- signal...: APL ⎕SIGNAL number and message string
 ⍝
 ⍝ comSpec:  ∊0 (default), 1, 2. Indicates how to handle preprocessor statements in output.
 ⍝            0: Keep all preprocessor statements, identified as comments with ⍝🅿️ (path taken), ⍝❌ (not taken)
 ⍝            1: Omit (⍝❌) paths not taken
 ⍝            2: Omit also (⍝🅿️) paths taken (leave other user comments)
 ⍝
 ⍝ DEBUG:     0: not debug mode (default).
 ⍝            1: debug mode. ⎕SIGNALs will not be trapped.

 ⎕IO ⎕ML←0 1

 outSpec comSpec DEBUG←'specs'{0≠⎕NC ⍺:3↑⎕OR ⍺ ⋄ ⍵}0 0 0
 '∆FIX: Invalid specification(s)'⎕SIGNAL 11/⍨~(outSpec∊⍳3)∧(comSpec∊⍳3)∧(DEBUG∊⍳2)

 TRAP←DEBUG×999 ⋄ ⎕TRAP←TRAP'C' '⎕SIGNAL/⎕DMX.(EM EN)'

 CR NL←⎕UCS 13 10 ⋄ SQ DQ←'''' '"'
 YES NO←'🅿️ ' '❌ ' ⋄ YESc NOc←'⍝',¨YES NO

 :Section Utilities
⍝-------------------------------------------------------------------------------------------

   ⍝ getenv: Returns value of environment var. See #ENV{name}
     getenv←{⊢2 ⎕NQ'.' 'GetEnvironment'⍵}
   ⍝ notZero: If ⍵ is not numeric 0 singleton or null-string or ⎕NULL, return 1
   ⍝   See ::IF etc.
     notZero←{0=≢⍵:0 ⋄ (,⎕NULL)≡,⍵:0 ⋄ (,0)≢,⍵}
     box←{
         l←≢m←'│  ',⍵,'  │' ⋄ t←'┌','┐',⍨,'─'⍴⍨l-2 ⋄ b←'└','┘',⍨,'─'⍴⍨l-2 ⋄ t,CR,m,CR,b
     }
   ⍝ Display just a bit of an obj of unknown size. (Used for display info)
   ⍝ show: assumes values. Puts strings in quotes.
     show←{⍺←⎕PW-20 ⋄ maxW←⍺
         f←⎕FMT ⍵
         q←''''/⍨0=80|⎕DR ⍵
         clip←1 maxW<⍴f
         (q,q,⍨(,f↑⍨1 maxW⌊⍴f)),∊clip/'⋮…'
     }
   ⍝ showc: assumes names or code
     showc←{⍺←⎕PW-20 ⋄ maxW←⍺
         f←⎕FMT ⍵
         clip←1 maxW<⍴f
         ((,f↑⍨1 maxW⌊⍴f)),∊clip/'⋮…'
     }

⍝-------------------------------------------------------------------------------------------
⍝⍝⍝⍝ regexp internal routines...
   ⍝ ∆PFX:   pfx ∇ lines
   ⍝    lines: a single string possibly containing newlines as line separators, OR
   ⍝           a vector of vectors
   ⍝    pfx:   a string prefix. Default '⍝ '
   ⍝
   ⍝ Returns lines prefixed with pfx in vector of vectors format.
   ⍝
     ∆PFX←{⍺←'⍝ ' ⋄ 1=|≡⍵:⍺ ∇(NL∘≠⊆⊢)⍵ ⋄ (⊂⍺),¨⍵}
   ⍝ ∆V2S: Convert a vector of vectors to a string, using carriage returns (APL prints nicely)
     ∆V2S←{1↓∊CR,¨⊆⍵}
   ⍝ ∆V2Q: Convert V of V to a quoted string equiv.
     ∆V2Q←{q←'''' ⋄ 1↓∊(⊂' ',q),¨q,⍨¨⊆⍵}
   ⍝ ∆COM: Convert a v of vs to a set of comments
     ∆COM←{⍺←1 ⋄ ∆V2S(⍺⊃NOc YESc)∆PFX ⍵}
   ⍝ PCRE routines
     ∆FIELD←{
         0=≢⍵:''
         1<≢⍵:⍺ ∇¨⍵
         0=⍵:⍺.Match
         ⍵≥≢⍺.Lengths:''
         ¯1=⍺.Lengths[⍵]:''
         ⍺.(Lengths[⍵]↑Offsets[⍵]↓Block)
     }
   ⍝ dictionary routines
   ⍝ Use a local namespace so we can use with ::IF etc.
     ∆DICT←{
         dict←⎕NS''
         dict.ns←dict.⎕NS''
       ⍝ map: Ensure that name ⍵ of form a.b.c is valid by ensuring
       ⍝      that a and a.b are undefined or  namespaces and that c can be defined.
       ⍝ Call:
       ⍝    dict.amp 'name'
       ⍝ Returns:
       ⍝    'name'
       ⍝ On error, ⎕SIGNALs an error 911
       ⍝
       ⍝ Relative names are created in a private namespace.
       ⍝ Absolute namespaces, or those above the private namespace should
       ⍝ be used with care, as they can affect the workspace or the preprocessor.
       ⍝ Safe:   a.b.c      Use with care:  #.test ⎕SE.test    Dangerous: ##.test
       ⍝
         dict.map←{⍺←ns
             ##.TRAP::⎕SIGNAL/⎕DMX.(EM EN)
             ⋄ verify←{pfx←1⊃⎕NPARTS ⍵ ⋄ ~'.'∊pfx:1 ⋄ ~9 0∊⍨⍺.⎕NC pfx:0 ⋄ ⍺ ∇ pfx}
             ~'.'∊⍵:⍵             ⍝ simple name
             ns2←1⊃⎕NPARTS ⍵      ⍝ ns2: prefix a.b.c for name a.b.c.d
             ⍺ verify ⍵:⍵⊣ns2 ⍺.⎕NS''
             err←'∆FIX: Object ',⍵,' invalid: prefix ',ns2,' in use as non-namespace object.'
             err ⎕SIGNAL 911
         }
         dict.set←{⍺←ns
             n(k v)←⍺ ⍵
             k←n map k
             1:n{⍺⍎k,'←⍵'}v
         }
         dict.get←{⍺←ns
             n k←⍺ ⍵
             0≥n.⎕NC k:''
             ⍕n.⎕OR k
         }
         dict.del←{⍺←ns
             n k←⍺ ⍵
             1:n.⎕EX k
         }
         dict.defined←{⍺←ns
             n k←⍺ ⍵
             2=n.⎕NC k
         }
         _←dict.⎕FX'k←keys' 'k←↓ns.⎕NL 2'
         _←dict.⎕FX'v←values' 'v←ns.⎕OR¨↓ns.⎕NL 2'
         dict
     }
⍝-------------------------------------------------------------------------------------------
⍝ Pattern Building Routines...
     ⎕FX'MBegin' 'Match←⍬'
     ⎕FX'm←MEnd' 'm←Match'
     register←{⍺←'[',(⍕1+≢Match),']'
         ns←⎕NS''
         ns.⎕PATH←'##'
         ns.info←⍺
         ns.pRaw←⍵                    ⍝ For debugging
         ns.pats←'(?xx)',eval ⍵       ⍝ xx-- allow spaces in [...] pats.
         ns.action←⍺⍺                 ⍝ a function OR a number (number → field[number]).
         1:Match,←ns
     }
     MActions←{
         TRAP::⎕SIGNAL/⎕DMX.(EM EN)
         match←,⍺⍺    ⍝ Ensure vector...
         pn←⍵.PatternNum
         pn≥≢match:⎕SIGNAL/'The matched pattern was not registered' 911
         m←pn⊃match
         3=m.⎕NC'action':m m.action ⍵          ⍝ m.action is a fn. Else a var.
         ' '=1↑0⍴m.action:∊m.action            ⍝ text? Return as is...
         ⍵ ∆FIELD m.action                     ⍝ Else m.action is a field number...
     }
     eval←{
         ~'⍎'∊⍵:⍵
         ⍵≢res←'(?<!\\)⍎(\w+)'⎕R{
             0::f1
             ⍎f1←⍵ ∆FIELD 1
         }⍠('UCP' 1)⊣⍵:∇ res
       ⍝ DEBUG: '⍎'∊⍵:⍵⊣⎕←'Warning: eval unable to resolve string var: ',⍵
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
         pat←'(?: (?J) (?<⍎NAME> ⍎LEFT (?> [^⍎ALL"''⍝]+ | ⍝.*?\R | (?: "[^"]*")+ '
         pat,←'                          | (?:''[^''\r\n]*'')+ | (?&⍎NAME)*     )+ ⍎RIGHT) )'
         eval pat~' '
     }
 ⍝-------------------------------------------------------------------------------------------
 :EndSection

 ⍝-------------------------------------------------------------------------------------------
 :Section Reused Pattern Actions
     stringAction←{SQ DQ NL←##.(SQ DQ NL)
         deQ←{⍺←SQ ⋄ ⍵/⍨~(⍺,⍺)⍷⍵}
         enQ←{⍺←SQ ⋄ ⍵/⍨1+⍵=⍺}
         str←⍵ ∆FIELD 0 ⋄ q←⊃str
         q≡SQ:str
         str←SQ,SQ,⍨enQ DQ deQ 1↓¯1↓str   ⍝ Double SQs and de-double DQs
         ~NL∊str:str                      ⍝ Remove leading blanks on trailing lines
         str←'\h*\n\h*'⎕R''',(⎕UCS 10),'''⍠##.opts⊣str
         '(',')',⍨∊str
     }
 :EndSection
 ⍝-------------------------------------------------------------------------------------------

 :Section Read in file
     readFile←{
         pfx obj sfx←{
             p o s←⎕NPARTS ⍵      ⍝
             s≡'.dyalog':p o s    ⍝  a/b/c.d.dyalog   →   a/b/   c.d  .dyalog
             s≡'':p o'.dyalog'    ⍝  a/b/c            →   a/b/   c    .dyalog
             p(o,s)'.dyalog'      ⍝  a/b/c.d          →   a/b/   c.d  .dyalog
         }⍵
         infile←pfx,obj,sfx

         code←{0::⎕NULL ⋄ ⊃⎕NGET ⍵ 1}infile
         code≡⎕NULL:22 ⎕SIGNAL⍨('∆FIX: File not found: ',infile)
         code
     }
     code←readFile fileName
 :EndSection


 dict←∆DICT''
 ⍝ Set at bottom:
 ⍝   CTL_STACK←1 ⋄ CTL_SKIP←0

 :Section Process File
   ⍝ Valid 1st chars of names...
     ALPH←'abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüþß'
     ALPH,←'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÕÔÖØÙÚÛÜÝ'
     ALPH,←'_∆⍙'
   ⍝ Valid APL simple names
     nameP←eval'(?:   ⎕? [⍎ALPH] [⍎ALPH\d]* | \#{1,2} )'
   ⍝ Valid APL complex names
     longNameP←eval'(?: ⍎nameP (?: \. ⍎nameP )* )  '

   ⍝ Matches one field in addition to any additional surrounding
     parenP←'('setBrace')'
     brackP←'['setBrace']'
     braceP←'{'setBrace'}'

     dqStringP←'(?:  "[^"]*"     )+'
     sqStringP←'(?: ''[^''\n]*'' )+'
     stringP←eval'(?: ⍎dqStringP | ⍎sqStringP )'

     :Section Setup Scans
         opts←('Mode' 'M')('EOL' 'LF')('NEOL' 1)('UCP' 1)('DotAll' 1)('IC' 1)

         :Section PreScan1
             MBegin
           ⍝ Double-quote "..." strings (multiline and with internal double-quotes doubled "")
           ⍝   → parenthesized single-quote strings...
             'STRINGS'stringAction register stringP
             'CONT'(' 'register)'\h*\.{2,}\h*(⍝.*?)?$(\s*)'      ⍝ Continuation lines [+ comments] → single space
             'COMMENTS_LINE*'(0 register)'^\h*⍝.*?$'           ⍝ Comments on their own line are kept.
             'COMMENTS_RHS'(''register)'\h*⍝.*?$'              ⍝ RHS Comments are ignored...
             PreScan1←MEnd
         :EndSection

         :Section MainScan1
             MBegin
            ⍝ IFDEF stmts
             'IFDEF+IFNDEF'{
                 f0 n k←⍵ ∆FIELD¨0 1 2 ⋄ not←⍬⍴n∊'nN'
                 ##.CTL_STACK,←~⍣not⊣##.dict.defined k
                 ##.CTL_SKIP←~⊃⌽##.CTL_STACK

                 (~##.CTL_SKIP)∆COM f0
             }register'^\h* :: \h* IF(N?)DEF\b \h*(⍎longNameP).*?$'
            ⍝ IF stmts
           ⍝  doMap←{nm←⍵ ∆FIELD 1 ⋄ o i←'⍙Ø∆' '.#⎕' ⋄ {o[i⍳nm]}@(∊∘i)⊣nm}
           ⍝  dictNameP←eval'(?xx)(⍎longNameP)(?>\.\.\w)'
             'IF'{
                 ##.CTL_SKIP:0 ∆COM ⍵ ∆FIELD 0

                 f0 code0←⍵ ∆FIELD¨0 1
                 ##.TRAP::{
                     ##.CTL_SKIP∘←0 ⋄ ##.CTL_STACK,←1
                     ⎕←##.NO,'Unable to evaluate ::IF ',⍵
                     '911 ⎕SIGNAL⍨''∆FIX VALUE ERROR''',##.NL,0 ∆COM'::IF ',⍵
                 }code0

                    ⍝ ⎕←'::IF code0 ',code0
                 code1←(0 doScan)code0
                    ⍝ ⎕←'::IF code1 ',code1
                 code2←##.dict.ns{⍺⍎⍵}code1
                    ⍝ ⎕←'::IF code2 ',code2

                 ##.CTL_SKIP←~##.CTL_STACK,←##.notZero code2  ⍝ (is code2 non-zero?)

                 (~##.CTL_SKIP)∆COM('::IF ',showc code0)('➤    ',showc code1)('➤    ',show code2)
             }register'^\h* :: \h* IF\b \h*(.*?)$'
            ⍝ ELSEIF/ELIF stmts
             'ELSEIF/ELIF'{

                 ##.CTL_SKIP←⊃⌽##.CTL_STACK
                 ##.CTL_SKIP:0 ∆COM ⍵ ∆FIELD 0

                 f0 code0←⍵ ∆FIELD¨0 1
                 ##.TRAP::{
                     ##.CTL_SKIP∘←0 ⋄ (⊃⌽##.CTL_STACK)←1      ⍝ Elseif: unlike IF, replace last stack entry, don't push

                     ⎕←##.NO,'Unable to evaluate ::ELSEIF ',⍵
                     '911 ⎕SIGNAL⍨''∆FIX VALUE ERROR''',##.NL,0 ∆COM'::IF ',⍵
                 }code0

                 code1←(0 doScan)code0
                 code2←##.dict.ns{⍺⍎⍵}code1

                 ##.CTL_SKIP←~(⊃⌽##.CTL_STACK)←##.notZero code2            ⍝ Elseif: Replace, don't push. [See ::IF logic]

                 (~##.CTL_SKIP)∆COM('::ELSEIF ',showc code0)('➤    ',showc code1)('➤    ',show code2)
             }register'^\h* :: \h* EL(?:SE)IF\b \h*(.*?)$'
            ⍝ ELSE
             'ELSE'{
                 ##.CTL_SKIP←~(⊃⌽##.CTL_STACK)←~⊃⌽##.CTL_STACK    ⍝ Flip the condition of most recent item.
                 f0←⍵ ∆FIELD 0
                 (~##.CTL_SKIP)∆COM f0
             }register'^\h* :: \h* ELSE \b .*?$'
            ⍝ END, ENDIF, ENDIFDEF
             'END(IF(DEF))'{
                 f0←⍵ ∆FIELD 0
                 oldCTL_SKIP←##.CTL_SKIP
                 ##.CTL_SKIP←~⊃⌽##.CTL_STACK⊣##.CTL_STACK↓⍨←¯1

                 (~oldCTL_SKIP)∆COM f0
             }register'^\h* :: \h* END  (?: IF  (?:DEF)? )? \b .*?$'
           ⍝ CONDITIONAL INCLUDE - include only if not already included
             filesIncluded←⍬
             'CINCLUDE'{
                 ##.CTL_SKIP:0 ∆COM ⍵ ∆FIELD 0
                 f0 fName←⍵ ∆FIELD¨0 1 ⋄ fName←{k←'"'''∊⍨1↑⍵ ⋄ k↓(-k)↓⍵}fName
                 (⊂fName)∊##.filesIncluded:0 ∆COM f0⊣⎕←box f0,': File already included. Ignored.'
                 ##.filesIncluded,←⊂fName

                 rd←{22::22 ⎕SIGNAL⍨'∆FIX: Unable to CINCLUDE file: ',⍵ ⋄ readFile ⍵}fName
                 (##.CR,⍨∆COM f0),∆V2S(0 doScan)rd
             }register'^\h* :: \h* CINCLUDE \h+ (⍎sqStringP|⍎dqStringP|[^\s]+) .*?$'
            ⍝ INCLUDE
             'INCLUDE'{
                 ##.CTL_SKIP:0 ∆COM ⍵ ∆FIELD 0
                 f0 fName←⍵ ∆FIELD¨0 1 ⋄ fName←{k←'"'''∊⍨1↑⍵ ⋄ k↓(-k)↓⍵}fName
                 ##.filesIncluded,←⊂fName   ⍝ See CINCLUDE

                 rd←{22::22 ⎕SIGNAL⍨'∆FIX: Unable to INCLUDE file: ',⍵ ⋄ readFile ⍵}fName
                 (##.CR,⍨∆COM f0),∆V2S(0 doScan)rd
             }register'^\h* :: \h* INCLUDE \h+ (⍎sqStringP|⍎dqStringP|[^\s]+) .*?$'
           ⍝ COND (cond) stmt   -- If cond is non-zero, a single stmt is made avail for execution.
           ⍝ COND single_word stmt
           ⍝ Does not affect the CTL_STACK or CTL_SKIP...
             'COND'{
                 f0 cond0 stmt←⍵ ∆FIELD¨0 1 3   ⍝ (parenP) counts as two fields
                 ##.CTL_SKIP:0 ∆COM f0

                 0=≢stmt~' ':0 ∆COM('[Statement field is null: ]')f0
                 ##.TRAP::{
                     ⎕←##.NO,'Unable to evaluate ',⍵
                     '911 ⎕SIGNAL⍨''∆FIX VALUE ERROR''',##.CR,0 ∆COM ⍵
                 }f0
                 cond1←(0 doScan)cond0
                 cond2←##.dict.ns{⍺⍎⍵}cond1
                 bool←##.notZero cond2

                 stmt←⍕(0 doScan)stmt
                 out1←bool ∆COM f0('➤  ',showc cond1)('➤  ',show cond2)('➤  ',show bool)
                 out2←##.CR,(##.NOc/⍨~bool),stmt
                 out1,out2
             }register'^\h* :: \h* COND\h+(⍎parenP|[^\s]+)\h(.*?) $'
           ⍝ DEFINE name [ ← value]  ⍝ value is left unevaluated in ∆FIX
             defS←'^\h* :: \h* DEF(?:INE)? \b \h* (⍎longNameP) '
             defS,←'(?|    \h* ← \h*  ( (?: ⍎braceP|⍎parenP|⍎sqStringP| ) .*? ) | .*?   )$'
             'DEF(INE)'{
                 ##.CTL_SKIP:0 ∆COM ⍵ ∆FIELD 0

                 f0 k v←⍵ ∆FIELD¨0 1 2
               ⍝ Replace leading and training blanks with single space
                 v←{'('=1↑⍵:'\h*\R\h*'⎕R' '⍠##.opts⊣⍵ ⋄ ⍵}v
                 v←⍕(0 doScan)v
                 _←##.dict.set k v
                 ∆COM f0
             }register defS
            ⍝ LET  name ← value   ⍝ value (which must fit on one line) is evaluated at compile time
            ⍝ EVAL name ← value   ⍝ (synonym)
             'LET~EVAL'{
                 ##.CTL_SKIP:0 ∆COM ⍵ ∆FIELD 0

                 f0 k vIn←⍵ ∆FIELD¨0 1 2
                 ##.TRAP::{
                     ⎕←'>>> VALUE ERROR: ',f0
                     _←##.dict.del k
                     msg←(f0)('➤ UNDEF ',k)
                     '911 ⎕SIGNAL⍨''∆FIX VALUE ERROR: ',f0,'''',##.CR,0 ∆COM msg
                 }⍬
                 vOut←##.dict.ns{⍺⍎⍵}(##.dict.map k),'←',vIn
                 msg←'➤ DEF ',k,' ← ',∆V2S{0::'∆FIX LOGIC ERROR!' ⋄ ⎕FMT ⍵}vOut
                 ∆COM f0 msg
             }register'^\h* :: \h* (?:LET | EVAL) \b \h* (⍎longNameP) \h* ← \h* (.*?) $'
           ⍝ UNDEF stmt
             'UNDEF'{
                 ##.CTL_SKIP:0 ∆COM ⍵ ∆FIELD 0

                 f0 k←⍵ ∆FIELD¨0 1
                 _←##.dict.del k
                 ∆COM f0
             }register'^\h* :: \h* UNDEF \b\h* (⍎longNameP) .*? $'
           ⍝ ERROR stmt
           ⍝ Generates a preprocessor error signal...
             'ERROR'{
                 ##.CTL_SKIP:0 ∆COM ⍵ ∆FIELD 0

                 line num msg←⍵ ∆FIELD¨0 1 2
                 num←⊃⊃⌽⎕VFI num,' 0' ⋄ num←(num≤0)⊃num 911
                 ⎕←##.CR@(##.NL∘=)⊣('\Q',line,'\E')⎕R(##.NO,'\0')⍠##.opts⊣⍵.Block
                 ⎕SIGNAL/('∆FIX ERROR: ',msg)num
             }register'^\h* :: \h* ERR(?:OR)? (?| \h+(\d+)\h(.*?) | ()\h*(.*?))$'
            ⍝ MESSAGE / MSG stmt
            ⍝ Puts out a msg while preprocessing...
             'MESSAGE~MSG'{
                 ##.CTL_SKIP:0 ∆COM ⍵ ∆FIELD 0

                 line msg←⍵ ∆FIELD¨0 1
                 ⎕←box msg
                 ∆COM line
             }register'^\h* :: \h* (?: MSG | MESSAGE)\h(.*?)$'
           ⍝ Start of every NON-MACRO line → comment, if CTL_SKIP is set. Else NOP.
             'SIMPLE_NON_MACRO'{
                 ##.CTL_SKIP/##.NOc,⍵ ∆FIELD 0
             }register'^'
           ⍝ COMMENTS: passthrough
             'COMMENTS*'(0 register)'⍝.*?$'
           ⍝
           ⍝ For nm a of form a1.a2.a3.a4,
           ⍝ see if any of a1 .. a4 are macros,
           ⍝ but accept value vN for aN only if name.
             subMacro←{
                 ~'.'∊⍵:⍵              ⍝ a is simple...
                 1↓∊'.',¨{
                     vN←dict.get ⍵  ⍝ Check value vN of aN
                     0=≢vN:⍵           ⍝ aN not macro. Use aN.
                     ¯1=⎕NC vN:⍵       ⍝ vN not a name? Use aN.
                     vN                ⍝ Use value vN of aN
                 }¨('.'∘≠⊆⊢)⍵          ⍝ Send each through
             }
           ⍝ name..DEF     is name defined?
           ⍝ name..UNDEF   is name undefined?
           ⍝ name..Q       'name'
           ⍝ name..ENV     getenv('name')
           ⍝ myNs.myName..DEF  → (0≠⎕NC 'myNs.myName')
           ⍝ name..Q  →  'name' (after any macro substitution)
             'name..cmd'{
                 ##.CTL_SKIP:0 ∆COM ⍵ ∆FIELD 0

                 nm cmd←⍵ ∆FIELD¨1 2 ⋄ cmd←1(819⌶)cmd ⋄ q←''''
               ⍝ Check nm of form a.b.c.d for macros in a, b, c, d
                 nm←subMacro nm

                 cmd≡'ENV':' ',q,(##.getenv nm),q,' '
                 cmd≡'DEF':'(0≠⎕NC',q,nm,q,')'
                 cmd≡'UNDEF':'(0=⎕NC',q,nm,q,')'
                 cmd≡,'Q':' ',q,nm,q,' '
                 ⎕SIGNAL/('Unknown cmd ',⍵ ∆FIELD 0)911
             }register'(⍎longNameP)\.{2,2}(DEF|UNDEF|Q|ENV)\b'

            ⍝ #ENV: Get an environment variable's value as a string...  ** DEPRECATED **
             '#ENV{name}'{
                 ##.CTL_SKIP:⍵ ∆FIELD 0
                 val←##.getenv ⍵ ∆FIELD 1
                 ' ''',val,''' '
             }register' \#ENV \{ \h* ( \w+ ) \h* \}'
            ⍝ #SH{string}: Return value of ⎕SH string
             '#SHell{name}'{
                 ##.CTL_SKIP:⍵ ∆FIELD 0
                 ∆V2Q{0::⎕FMT ⎕DMX.(EN EM) ⋄ ⎕SH ⍵}1↓¯1↓⍵ ∆FIELD 1
             }register' \#SH (⍎braceP) .*? $'
            ⍝ #EXEC{string}: Return value of ⍎string
             '#EXECute{name}'{
                 ##.CTL_SKIP:⍵ ∆FIELD 0
                 ∆V2Q{0::⎕FMT ⎕DMX.(EN EM) ⋄ ↓⎕FMT⍎⍵}1↓¯1↓⍵ ∆FIELD 1
             }register' \#EXEC (⍎braceP) .*? $'
           ⍝ ATOMS:   n1 n2 n3 → anything,   `n1 n2 n3
           ⍝     abc def ghi → xxx     →   ('abc' 'def' 'ghi')
           ⍝ To do: Allow char constants-- just don't add quotes...
           ⍝ To do: Treat num constants as unquoted scalars
             atomsP←' (?:      ⍎longNameP|¯?\d[\d¯EJ\.]*|⍎sqStringP)'
             atomsP,←'(?:\h+(?:⍎longNameP|¯?\d[\d¯EJ\.]*|⍎sqStringP))*'
             'ATOMS'{
                 ##.CTL_SKIP:⍵ ∆FIELD 0

                 atoms arrow←⍵ ∆FIELD 1 2
                 atoms←(' '∘≠⊆⊢)atoms
                 qt←''''
                 o←1=≢atoms ⋄ s←0   ⍝ o: one atom; s: at least 1 scalar atom

                 atoms←{
                     isN isQ←('¯.',⎕D)'''' ⋄ f←1↑⍵
                     f∊isN:⍵⊣s∘←1       ⍝ Pass through 123.45 w/o quoting
                     f∊isQ:⍵⊣s∨←3=≢⍵    ⍝ Pass through 'abcd' w/o quoting
                     qt,qt,⍨⍵⊣s∨←1=≢⍵
                 }¨atoms
                 sxo←s∧~o
                 atoms←(∊o s sxo/'⊂,¨'),1↓∊' ',¨atoms

                 1=≢arrow:'(⊂',atoms,'),⊂'     ⍝ 1=≢arrow: Is there a right arrow?
                 '(',atoms,')'
             }register'\h* (?| (⍎atomsP) \h* (→) | ` (⍎atomsP) ) \h* (→)?'
            ⍝ STRINGS: passthrough (only single-quoted strings appear.
            ⍝ Must follow ATOMs
             'STRINGS*'({⍵ ∆FIELD 0}register)'⍎sqStringP'
            ⍝ MACRO: Match APL-style simple names that are defined via ::DEFINE above.
             'MACRO'{
                 ##.CTL_SKIP:⍵ ∆FIELD 0          ⍝ Don't substitute under CTL_SKIP

                 ##.TRAP::k⊣⎕←'Unable to get value of k. Returning k: ',k
                 k←⍵ ∆FIELD 1
                 v←⍕##.dict.get k
                 0=≢v:k
                 '{(['∊⍨1↑v:v      ⍝ Don't wrap (...) around already wrapped strings.
                 '(',v,')'
             }register'(⍎longNameP)(?!\.\.)'
         :EndSection
         MainScan1←MEnd

     :EndSection

     :Section Define Scans
     ⍝ To scan simple expressions:
     ⍝   code← [PreScan1] MainScan1 (⍺⍺ doScan)⊣ code   ⍺⍺=1: Save and restore the IF and CTL_SKIP stacks during use.
     ⍝                                            ⍺⍺=0: Maintain existing stacks
         CTL_STACK CTL_SKIP∘←1 0 ⋄ SAVE_STACK←⍬
         doScan←{
             TRAP::⎕SIGNAL/⎕DMX.(EM EN)
             ⍺←MainScan1       ⍝ Default is to omit the prescan
             stackFlag←⍺⍺
             saveStacks←{⍵:SAVE_STACK,←⊂CTL_STACK CTL_SKIP ⋄ CTL_STACK CTL_SKIP∘←1 0 ⋄ ''}
             restoreStacks←{⍵:(CTL_STACK CTL_SKIP)SAVE_STACK∘←(⊃⌽SAVE_STACK)(¯1↓SAVE_STACK) ⋄ ''}

             _←saveStacks stackFlag
             res←⍺{
                 0=≢⍺:⍵
                 scan←⊃⍺
                 _code←scan.pats ⎕R(scan MActions)⍠opts⊣⍵
                 (1↓⍺)∇ _code
             }⍵
             res⊣restoreStacks stackFlag
         }
     :EndSection Define Scans

     :Section Do Scans
       ⍝ =================================================================
       ⍝ Executive
       ⍝ =================================================================
         code←PreScan1 MainScan1(0 doScan)code
         :Select comSpec
              ⋄ :Case 2 ⋄ code←'(?x)^\h* ⍝[❌🅿️].*?\n(\h*\n)*' '^(\h*\n)+'⎕R'' '\n'⍠opts⊣code
              ⋄ :Case 1 ⋄ code←'(?x)^\h* ⍝❌    .*?\n(\h*\n)*' '^(\h*\n)+'⎕R'' '\n'⍠opts⊣code
             ⍝ Otherwise: do nothing
         :EndSelect
     :EndSection Do Scans
 :EndSection

 :Section Write out so we can then do a 2∘⎕FIX
     tmpfile←(739⌶0),'/','TMP~.dyalog'
     :Trap 0
         (⊂code)⎕NPUT tmpfile 1         ⍝ 1: overwrite file if it exists.
         objects←2(0⊃⎕RSI).⎕FIX'file://',tmpfile
       ⍝ Break association betw. <objects> and file TMP~ that ⎕FIX creates.
         :If 0∊(0⊃⎕RSI).(5178⌶)¨objects
             ⎕←'∆FIX: Logic error dissociating objects: ',,⎕FMT objects ⋄ :EndIf
         :Select outSpec
              ⋄ :Case 0 ⋄ result←0 objects
              ⋄ :Case 1 ⋄ result←0 objects code
              ⋄ :Case 2 ⋄ result←0 code
         :EndSelect
     :Else ⍝ Error: return  trapCode trapMsg
         result←⎕DMX.(EN EM)
     :EndTrap
     1 ⎕NDELETE tmpfile
 :EndSection

 :If DEBUG
     ⎕←'PreScan1  Pats:'PreScan1.info
     ⎕←'MainScan1 Pats:'MainScan1.info
     ⎕←'      *=passthrough'

     :If 0≠≢keys←dict.keys
         'Defined names and values'
         ⍉↑keys dict.values
     :EndIf
 :EndIf
