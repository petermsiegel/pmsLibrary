 (err objects)←{commentLvl}∆FIX file;SAVE_STACK;getenv;notZero;readFile;skipCom
 ;ALPH;CR;IF_STACK;MActions;MBegin;MEnd;MPats;MRegister;Match;NL;SKIP;ScanI;ScanII
 ;UTILS;_MATCHED_GENERICp
 ;braceCount;braceP;brackP;code;comment;defMatch;defP;defS;dict;doScan;dqStringP;eval
 ;infile;keys;letS;longNameP;macro;nameP;names;obj;opts;parenP;pfx;register;setBrace
 ;sfx;sqStringP;stringAction;stringP;tmpfile;ø;∆CASE;∆COM;∆DICT;∆FIELD;∆PFX;∆V2S;⎕IO;⎕ML;⎕PATH;⎕TRAP
 ⍝ A dyalog APL preprocessor
 ⍝ Takes an input file <file> in 2 ⎕FIX format, preprocesses the file, then 2 ⎕FIX's it, and
 ⍝ returns the objects found or ⎕FIX error messages.
 ⍝ Like, ⎕FIX, accepts either a mix of namespace-like objects (namespaces, classes, interfaces) and functions (marked with ∇)
 ⍝ or a single function (whose first line must be its header, with a ∇-prefix optional).

 ⍝ commentLvl∊0 (default), 1, 2
 ⍝            0: Keep all preprocessor statements, identified as comments with ⍝🅿️ (path taken), ⍝❌ (not taken)
 ⍝            1: Omit (⍝❌) paths not taken
 ⍝            2: Omit also (⍝🅿️) paths taken (leave other user comments)

 ⎕IO ⎕ML←0 1
 commentLvl←'commentLvl'{0=⎕NC ⍺:⍵ ⋄ ⎕OR ⍺}0


 ⍝⎕TRAP←0 'C' '⎕SIGNAL/⎕DMX.(EM EN)'

 CR NL←⎕UCS 13 10
 YES NO←'🅿️ ' '❌ ' ⋄ YESc NOc←'⍝',¨YES NO

 :Section Utilities
⍝-------------------------------------------------------------------------------------------

   ⍝ getenv: Returns value of environment var. See #ENV{name}
     getenv←{⊢2 ⎕NQ'.' 'GetEnvironment'⍵}

   ⍝ notZero: If ⍵ is not numeric 0 singleton or null-string or ⎕NULL, return 1
   ⍝   See ::IF etc.
     notZero←{
         0=≢⍵:0
         (,⎕NULL)≡,⍵:0
         (,0)≢,⍵
     }

⍝⍝⍝⍝ regexp internal routines...
⍝-------------------------------------------------------------------------------------------
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

⍝ ∆COM: Convert a v of vs to a set of comments
     ∆COM←{⍺←1 ⋄ ∆V2S(⍺⊃NOc YESc)∆PFX ⍵}

 ⍝ PCRE routines
     ∆FIELD←{
         0=≢⍵:''
         0=⍵:⍺.Match ⋄ ⍵≥≢⍺.Lengths:'' ⋄ ¯1=⍺.Lengths[⍵]:'' ⋄ ⍺.(Lengths[⍵]↑Offsets[⍵]↓Block)
     }
     ∆CASE←{⍺.PatternNum∊⍵}

 ⍝ dictionary routines
 ⍝ Use a local namespace so we can use with ::IF etc.
     ∆DICT←{
         dict←⎕NS''
         dict.ns←⎕NS''
       ⍝ map: Convert #.a.b or ⎕SE.a.b into flat object Ø⍙a⍙b  ∆SE⍙a⍙b
       ⍝ ([0] map str) and inverse (1 map str)
         dict.map←{⍺←0 ⋄ o i←⌽⍣⍺⊣'⍙Ø∆' '.#⎕' ⋄ {o[i⍳⍵]}@(∊∘i)⊣⍵}
         dict.set←{⍺←ns
             d(k v)←⍺ ⍵
             k←map k
             1:{d⍎k,'←⍵'}v
         }
         dict.get←{⍺←ns
             d k←⍺ ⍵
             k←map k
             0≥d.⎕NC k:''
             ⍕d.⎕OR k
         }
         dict.del←{⍺←ns
             d k←⍺ ⍵
             k←map k
             1:d.⎕EX k
         }
         dict.defined←{⍺←ns
             d k←⍺ ⍵
             k←map k
             2=d.⎕NC k
         }
         _←dict.⎕FX'k←keys' 'k←1 map¨↓ns.⎕NL 2'
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
         ns.pats←'(?xx)',⍵         ⍝ xx-- allow spaces in [...] pats.
         ns.action←⍺⍺     ⍝ a function OR a number (number → field[number]).
         1:Match,←ns
     }

     MActions←{
         match←,⍺⍺    ⍝ Ensure vector...
         pn←⍵.PatternNum
         pn≥≢match:⎕SIGNAL/'The matched pattern was not registered' 911
         m←pn⊃match

         3=m.⎕NC'action':m m.action ⍵          ⍝ m.action is a fn. Else a var.
         ' '=1↑0⍴m.action:∊m.action            ⍝ text? Return as is...
         ⍵ ∆FIELD m.action                     ⍝ Else m.action is a field number...
     }

     eval←{
         '⍎(\w+)'⎕R{
             0::f1
             ⍎f1←⍵ ∆FIELD 1
         }⍠('UCP' 1)⊣⍵
     }

     ⎕SHADOW'LEFT' 'RIGHT' 'ALL' 'NAME'
     braceCount←¯1
     setBrace←{
         braceCount+←1
         LEFT∘←∊(⊂'\'),¨∊⍺ ⋄ RIGHT∘←∊(⊂'\'),¨∊⍵ ⋄ ALL∘←LEFT,RIGHT
         NAME∘←'BR',⍕braceCount
         ⍝ Matches one field (in addition to any outside)
         pat←'(?: (?J) (?<⍎NAME> ⍎LEFT (?> [^⍎ALL"''⍝]+ | ⍝.*?\R | (?: "[^"]*")+ '
         pat,←'                          | (?:''[^''\r\n]*'')+ | (?&⍎NAME)*     )+ ⍎RIGHT) )'
         eval pat~' '
     }
 ⍝-------------------------------------------------------------------------------------------
 :EndSection

 ⍝-------------------------------------------------------------------------------------------
 :Section Reused Pattern Actions

     stringAction←{NL←⎕UCS 10
         SQ DQ←'''' '"'
         deQ←{⍺←SQ ⋄ ⍵/⍨~(⍺,⍺)⍷⍵}
         enQ←{⍺←SQ ⋄ ⍵/⍨1+⍵=⍺}
         str←⍵ ∆FIELD 0 ⋄ q←⊃str
         q≡SQ:str
         str←SQ,SQ,⍨enQ DQ deQ 1↓¯1↓str
         ~NL∊str:str
         str←'\h*\n\h*'⎕R''',(⎕UCS 10),'''⍠##.opts⊣str          ⍝ ((str∊NL)/str)←⊂''',(⎕UCS 10),'''
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
         code≡⎕NULL:⎕SIGNAL/'File not found' 11 ⋄
         code
     }

     code←readFile file

 :EndSection


 dict←∆DICT''
 ⍝ Set at bottom:
 ⍝   IF_STACK←1 ⋄ SKIP←0

 :Section Process File

   ⍝ Valid 1st chars of names...
     ALPH←'abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüþß'
     ALPH,←'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÕÔÖØÙÚÛÜÝ'
     ALPH,←'_∆⍙'
   ⍝ Valid APL simple names
     nameP←eval'(?xx)(?:   ⎕? [⍎ALPH] [⍎ALPH\d]* | \#{1,2} )'
   ⍝ Valid APL complex names
     longNameP←eval'(?xx) (?: ⍎nameP (?: \. ⍎nameP )* )  '

   ⍝ Matches one field in addition to any additional surrounding
     parenP←'('setBrace')'
     brackP←'['setBrace']'
     braceP←'{'setBrace'}'

     dqStringP←'(?:  "[^"]*"     )+'
     sqStringP←'(?: ''[^''\n]*'' )+'
     stringP←eval'(?: ⍎dqStringP | ⍎sqStringP )'

     :Section Setup Scans
         opts←('Mode' 'M')('EOL' 'LF')('NEOL' 1)('UCP' 1)('DotAll' 1)('IC' 1)
       ⍝ SEMI-GLOBALS: IF_STACK, SKIP
         :Section ScanI
             MBegin
           ⍝ Double-quote "..." strings (multiline and with internal double-quotes doubled "")
           ⍝   → parenthesized single-quote strings...
             'STRINGS'stringAction register stringP
             'CONT'(' 'register)'\h*\.{2,}\h*(⍝.*?)?$(\s*)'      ⍝ Continuation lines [+ comments] → single space
             'COMMENTS_LINE*'(0 register)'^\h*⍝.*?$'           ⍝ Comments on their own line are kept.
             'COMMENTS_RHS'(''register)'\h*⍝.*?$'              ⍝ RHS Comments are ignored...
             ScanI←MEnd
         :EndSection

         :Section ScanII
             MBegin
            ⍝ IFDEF stmts
             'IFDEF+IFNDEF'{
                 f0 n k←⍵ ∆FIELD¨0 1 2 ⋄ not←⍬⍴n∊'nN'
                 ##.IF_STACK,←~⍣not⊣##.dict.defined k
                 ##.SKIP←~⊃⌽##.IF_STACK

                 (~##.SKIP)∆COM f0
             }register eval'^\h* :: \h* IF(N?)DEF\b \h*(⍎longNameP).*?$'
            ⍝ IF stmts
             'IF'{
                ⍝  nameMatch←{
                ⍝      macros←{v←##.dict.get ⍵ ⋄ 0=≢v:⍵ ⋄ v}¨
                ⍝      nm un←⍵ ∆FIELD¨1 2
                ⍝      ⎕←'nm in:  ',nm
                ⍝      nm←∊macros⊂nm       ⍝ Try the entire name, e.g. a.b.c.d
                ⍝      ⎕←'nm ut1: ',nm
                ⍝      nm←1↓∊'.',¨macros('.'∘≠⊆⊢)nm   ⍝ See if any names are replacements ("macros")
                ⍝      ⎕←'nm ut2: ',nm
                ⍝      vs←(1∊'uU'∊un)⊃'≠='
                ⍝      '(0',vs,'⎕NC ''',nm,''')'
                ⍝  }

                 ##.SKIP:0 ∆COM ⍵ ∆FIELD 0

                 f0 code0←⍵ ∆FIELD¨0 1
                 999::{
                     ##.SKIP∘←0 ⋄ ##.IF_STACK,←1
                     ⎕←##.NO,'Unable to evaluate ::IF ',⍵
                     '911 ⎕SIGNAL⍨''∆FIX VALUE ERROR''',##.NL,0 ∆COM'::IF ',⍵
                 }code0

                 code1←##.ScanII(0 ##.doScan)code0
                 code2←##.dict.ns{⍺⍎⍵}code1

                 ##.SKIP←~##.IF_STACK,←## notZero code2  ⍝ (is code2 non-zero?)

                 (~##.SKIP)∆COM('::IF ',code0)('➤    ',code1)('➤    ',⍕code2)
             }register eval'^\h* :: \h* IF\b \h*(.*?)$'
            ⍝ ELSEIF/ELIF stmts
             'ELSEIF/ELIF'{

                 ##.SKIP←⊃⌽##.IF_STACK
                 ##.SKIP:0 ∆COM ⍵ ∆FIELD 0

                 f0 code0←⍵ ∆FIELD¨0 1
                 0::{
                     ##.SKIP∘←0 ⋄ (⊃⌽##.IF_STACK)←1      ⍝ Elseif: unlike IF, replace last stack entry, don't push

                     ⎕←##.NO,'Unable to evaluate ::ELSEIF ',⍵
                     '911 ⎕SIGNAL⍨''∆FIX VALUE ERROR''',##.NL,0 ∆COM'::IF ',⍵
                 }code0

                 code1←##.ScanII(0 ##.doScan)code0
                 code2←##.dict.ns{⍺⍎⍵}code1

                 ##.SKIP←~(⊃⌽##.IF_STACK)←##.notZero code2            ⍝ Elseif: Replace, don't push. [See ::IF logic]

                 (~##.SKIP)∆COM('::ELSEIF ',code0)('➤    ',code1)('➤    ',⍕code2)
             }register eval'^\h* :: \h* EL(?:SE)IF\b \h*(.*?)$'
            ⍝ ELSE
             'ELSE'{
                 ##.SKIP←~(⊃⌽##.IF_STACK)←~⊃⌽##.IF_STACK    ⍝ Flip the condition of most recent item.
                 f0←⍵ ∆FIELD 0
                 (~##.SKIP)∆COM f0
             }register eval'^\h* :: \h* ELSE \b .*?$'
            ⍝ END, ENDIF, ENDIFDEF
             'END(IF(DEF))'{
                 f0←⍵ ∆FIELD 0
                 oldSKIP←##.SKIP
                 ##.SKIP←~⊃⌽##.IF_STACK⊣##.IF_STACK↓⍨←¯1

                 (~oldSKIP)∆COM f0
             }register'^\h* :: \h* END  (?: IF  (?:DEF)? )? \b .*?$'
           ⍝ INCLUDE
             'INCLUDE'{
                 ##.SKIP:0 ∆COM ⍵ ∆FIELD 0
                 f0 fName←⍵ ∆FIELD¨0 1 ⋄ fName←{k←'"'''∊⍨1↑⍵ ⋄ k↓(-k)↓⍵}fName
                 rd←readFile fName
                 (##.CR,⍨∆COM f0),∆V2S(0 doScan)rd

             }register eval'^\h* :: \h* INCLUDE \h+ (⍎sqStringP|⍎dqStringP|[^\s]+) .*?$'
           ⍝ COND (cond) stmt   -- If cond is non-zero, a single stmt is made avail for execution.
           ⍝ COND single_word stmt
           ⍝ Does not affect the IF_STACK or SKIP...
             'COND'{
                 f0 cond0 stmt←⍵ ∆FIELD¨0 1 3   ⍝ (parenP) counts as two fields
                 ##.SKIP:0 ∆COM f0

                 0=≢stmt~' ':0 ∆COM('[Statement field is null: ]')f0
                 0::{
                     ⎕←##.NO,'Unable to evaluate ',⍵
                     '911 ⎕SIGNAL⍨''∆FIX VALUE ERROR''',##.CR,0 ∆COM ⍵
                 }f0

                 cond1←##.ScanII(0 ##.doScan)cond0
                 cond2←##.dict.ns{⍺⍎⍵}cond1
                 bool←notZero cond2

                 stmt←⍕##.ScanII(0 ##.doScan)stmt
                 out1←bool ∆COM f0('➤  ',⍕cond1)('➤  ',⍕cond2)('➤  ',⍕bool)
                 out2←##.CR,(##.NOc/⍨~bool),stmt
                 out1,out2
             }register eval'^\h* :: \h* COND\h+(⍎parenP|[^\s]+)\h(.*?) $'
           ⍝ DEFINE name [ ← value]  ⍝ value is left unevaluated in ∆FIX
             defS←'^\h* :: \h* DEF(?:INE)? \b \h* (⍎nameP) '
             defS,←'(?|    \h* ← \h*  ( (?: ⍎braceP|⍎parenP|⍎sqStringP| ) .*? ) | .*?   )$'
             'DEF(INE)'{
                 ##.SKIP:0 ∆COM ⍵ ∆FIELD 0

                 f0 k v←⍵ ∆FIELD¨0 1 2
                 v←{
                     '('=1↑⍵:'\h*\R\h*'⎕R' '⍠##.opts⊣⍵
                     ⍵
                 }v
                 v←⍕##.ScanII(0 ##.doScan)v
                 _←##.dict.set k v
                 ∆COM f0
             }register eval defS
            ⍝ LET  name ← value   ⍝ value (which must fit on one line) is evaluated at compile time
            ⍝ EVAL name ← value   ⍝ (synonym)
             'LET~EVAL'{
                 ##.SKIP:0 ∆COM ⍵ ∆FIELD 0

                 f0 k vIn←⍵ ∆FIELD¨0 1 2
                 0::{
                     ⎕←'>>> VALUE ERROR: ',f0
                     _←##.dict.del k
                     msg←(f0)('➤ UNDEF ',k)
                     '911 ⎕SIGNAL⍨''∆FIX VALUE ERROR: ',f0,'''',##.CR,0 ∆COM msg
                 }⍬

                 vOut←##.dict.ns{⍺⍎⍵}(##.dict.map k),'←',vIn
                 msg←'➤ DEF ',k,' ← ',∆V2S{0::'???' ⋄ ⎕FMT ⍵}vOut
                 ∆COM f0 msg
             }register eval'^\h* :: \h* (?:LET | EVAL) \b \h* (⍎longNameP) \h* ← \h* (.*?) $'
           ⍝ UNDEF stmt
             'UNDEF'{
                 ##.SKIP:0 ∆COM ⍵ ∆FIELD 0

                 f0 k←⍵ ∆FIELD¨0 1
                 _←##.dict.del k
                 ∆COM f0
             }register eval'^\h* :: \h* UNDEF \b\h* (⍎longNameP) .*? $'
           ⍝ ERROR stmt
           ⍝ Generates a preprocessor error signal...
             'ERROR'{
                 ##.SKIP:0 ∆COM ⍵ ∆FIELD 0

                 line num msg←⍵ ∆FIELD¨0 1 2
                 num←⊃⊃⌽⎕VFI num,' 0' ⋄ num←(num≤0)⊃num 911
                 ⎕←##.CR@(##.NL∘=)⊣('\Q',line,'\E')⎕R(##.NO,'\0')⍠##.opts⊣⍵.Block
                 ⎕SIGNAL/('∆FIX ERROR: ',msg)num
             }register'^\h* :: \h* ERR(?:OR)? (?| \h+(\d+)\h(.*?) | ()\h*(.*?))$'
            ⍝ MESSAGE / MSG stmt
            ⍝ Puts out a msg while preprocessing...
             'MESSAGE~MSG'{
                 ##.SKIP:0 ∆COM ⍵ ∆FIELD 0

                 line msg←⍵ ∆FIELD¨0 1
                 box←{
                     l←≢m←'│  ',⍵,'  │'
                     t←'┌','┐',⍨,'─'⍴⍨l-2
                     b←'└','┘',⍨,'─'⍴⍨l-2
                     t,##.CR,m,##.CR,b
                 }

                 ⎕←box msg
                 ∆COM line
             }register'^\h* :: \h* (?: MSG | MESSAGE)\h(.*?)$'
           ⍝ Start of every NON-MACRO line → comment, if SKIP is set. Else NOP.
             'SIMPLE_NON_MACRO'{
                 ##.SKIP/##.NOc,⍵ ∆FIELD 0
             }register'^'
           ⍝ STRINGS: passthrough (only single-quoted strings happen here on in)
             'STRINGS*'(0 register)sqStringP
           ⍝ COMMENTS: passthrough
             'COMMENTS*'(0 register)'⍝.*?$'
           ⍝ name..DEF or name..UNDEF syntax
           ⍝     myNs.myName..DEF  → (0≠⎕NC 'myNs.myName')
             defP←eval'(?xx)(⍎longNameP)\.{2,2}(UN)?DEF\b'
             'DEF/UNDEF'{
                 dictMap←{⍺←0 ⋄ o i←⌽⍣⍺⊣'⍙Ø∆' '.#⎕' ⋄ {o[i⍳⍵]}@(∊∘i)⊣⍵}
                 macros←{v←##.dict.get ⍵ ⋄ 0=≢v:⍵ ⋄ v}¨
                 ##.SKIP:0 ∆COM ⍵ ∆FIELD 0

                 nm un←⍵ ∆FIELD¨1 2
                 nm←1↓∊'.',¨macros('.'∘≠⊆⊢)nm   ⍝ See if any names are replacements ("macros")
                 vs←(1∊'uU'∊un)⊃'≠='
                 '(0',vs,'⎕NC ''',(dictMap nm),''')'
             }register defP
            ⍝ #ENV: Get an environment variable's value as a string...
             '#ENV{name}'{
                 ##.SKIP:⍵ ∆FIELD 0
                 val←getenv ⍵ ∆FIELD 1
                 ' ''',val,''' '
             }register' \#ENV \{ \h* ( \w+ ) \h* \}'
            ⍝ #SH{string}: Return value of ⎕SH string
             '#ENV{name}'{
                 ##.SKIP:⍵ ∆FIELD 0
                 ∆V2S{0::⎕FMT ⎕DMX.(EN EM) ⋄ ⎕SH ⍵}1↓¯1↓⍵ ∆FIELD 1
             }register eval' \#SH (⍎braceP) .*? $'
            ⍝ MACRO: Match APL-style simple names that are defined via ::DEFINE above.
             'MACRO'{
                 ##.SKIP:⍵ ∆FIELD 0          ⍝ Don't substitute under SKIP

                 k←⍵ ∆FIELD 1
                 v←##.dict.get k
                 0=≢v:k
                 '{(['∊⍨1↑v:v      ⍝ Don't wrap (...) around already wrapped strings.
                 '(',v,')'
             }register eval'(⍎longNameP)'
             ScanII←MEnd
         :EndSection
     :EndSection

     :Section Perform Scans
     ⍝ To scan simple expressions:
     ⍝   code← [ScanI] ScanII (⍺⍺ doScan)⊣ code   ⍺⍺=1: Save and restore the IF and SKIP stacks during use.
     ⍝                                            ⍺⍺=0: Maintain existing stacks
         IF_STACK SKIP∘←1 0 ⋄ SAVE_STACK←⍬
         doScan←{
             ⍺←ScanI ScanII       ⍝ Default is ALL scans...

             stackFlag←⍺⍺
             saveStacks←{
                 ⍵:SAVE_STACK,←⊂IF_STACK SKIP ⋄ IF_STACK SKIP∘←1 0 ⋄ ''
             }
             restoreStacks←{
                 ⍵:(IF_STACK SKIP)SAVE_STACK∘←(⊃⌽SAVE_STACK)(¯1↓SAVE_STACK) ⋄ ''
             }

             _←saveStacks stackFlag
             res←⍺{
                 0=≢⍺:⍵
                 scan←⊃⍺
                 _code←scan.pats ⎕R(scan MActions)⍠opts⊣⍵
                 (1↓⍺)∇ _code
             }⍵
             _←restoreStacks stackFlag
             res
         }

         code←(0 doScan)code

         :Select commentLvl
              ⋄ :Case 2 ⋄ code←'(?x)^\h* ⍝[❌🅿️].*?\n(\h*\n)*' '^(\h*\n)+'⎕R'' '\n'⍠opts⊣code
              ⋄ :Case 1 ⋄ code←'(?x)^\h* ⍝❌    .*?\n(\h*\n)*' '^(\h*\n)+'⎕R'' '\n'⍠opts⊣code
              ⋄ ⋄ :Else
         :EndSelect

     :EndSection
 :EndSection

 :Section Write out so we can then do a 2∘⎕FIX
     tmpfile←(739⌶0),'/','TMP~.dyalog'

     :Trap 0
         (⊂code)⎕NPUT tmpfile 1         ⍝ 1: overwrite file if it exists.
         objects←2 ⎕FIX'file://',tmpfile
         err←0
     :Else
         ⎕←'∆FIX: #._CODE_ contains preprocessed function code.'
         err objects←⎕DMX.(EN EM)
         objects,⍨←'None: '
     :EndTrap
     1 ⎕NDELETE tmpfile
 :EndSection

 ⎕←'ScanI  Pats:'ScanI.info
 ⎕←'ScanII Pats:'ScanII.info
 ⎕←'      *=passthrough'

 :If 0≠≢keys←dict.keys
     'Defined names and values'
     ⍉↑keys dict.values
 :EndIf
 ⎕←'err'err' objects'objects
 #._CODE_←↑code
 ⎕←'done'
