 result←{specs}∆FIX fileName;specialStringP
 ;ALPH;COMSPEC;CR;CTL;DEBUG;DQ;ListScan;MActions;MBegin;MEnd;MPats;MRegister
 ;MainScan1;Match;NL;NO;NOc;OPTS;OUTSPEC;PRAGMA_FENCE;Par;PreScan1;PreScan2
 ;SEMICOLON_FAUX;SHOWCOMPILED;SQ;TRAP;UTILS;YES;YESc;_;_MATCHED_GENERICp;anyNumP
 ;atomsP;box;braceCount;braceP;brackP;code;comment;commentP;defMatch;defS;dict
 ;dictNameP;directiveP;doScan;dqStringP;ellipsesP;err;eval;filesIncluded;first
 ;getenv;infile;keys;letS;longNameP;macro;macros;multiLineP;nameP;names;notZero
 ;obj;objects;parenP;pfx;readFile;register;setBrace;sfx;showObj;showCode;sqStringP
 ;stringAction;stringP;subMacro;tmpfile;ø;∆COM;∆DICT;∆FIELD;∆PFX;∆V2Q;∆V2S;⎕IO
 ;⎕ML;⎕PATH;⎕TRAP

 ⍝ A Dyalog APL preprocessor (rev. Nov 11 )
 ⍝
 ⍝ result ←  [OUTSPEC [COMSPEC [DEBUG] [SHOWCOMPILED]]]] ∆FIX  [fileName | ⍬ ]
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
 ⍝ OUTSPEC:  ∊0 (default), 1, 2. Indicates the format of the return value*.
 ⍝           On success, rc (return code) is 0.
 ⍝            0 - returns*: rc names             -- names: the list of objects created by a ⎕FIX.
 ⍝            1 - returns*: rc names code        -- code:  output (vec of strings) from the
 ⍝                                                         preprocessor.
 ⍝            2 - returns*: rc code              -- rc:    0 on success
 ⍝            * If an error occurs, returns:
 ⍝                signalNum signalMsg            -- signal...: APL ⎕SIGNAL number and message string
 ⍝
 ⍝ COMSPEC:  ∊0 (default), 1, 2. Indicates how to handle preprocessor statements in output.
 ⍝            0: Keep all preprocessor statements, identified as comments with ⍝🅿️ (path taken), ⍝❌ (not taken)
 ⍝            1: Omit (⍝❌) paths not taken
 ⍝            2: Omit also (⍝🅿️) paths taken (leave other user comments)
 ⍝
 ⍝ DEBUG:     0: not debug mode (default).
 ⍝            1: debug mode. ⎕SIGNALs will not be trapped.
 ⍝ SHOWCOMPILED:
 ⍝            0: Don't view the preprocessed code when done. (It may be returned via OUTSPEC=1).
 ⍝               Default if standard fileName was specified.
 ⍝            1: View the preprocessed code just before returning, via ⎕ED.
 ⍝               Default if fileName≡⍬, i.e. when prompting input from user.
 ⎕IO ⎕ML←0 1
 OUTSPEC COMSPEC DEBUG SHOWCOMPILED←'specs'{0≠⎕NC ⍺:4↑⎕OR ⍺ ⋄ ⍵}0 0 0 0
 '∆FIX: Invalid specification(s) (⍺)'⎕SIGNAL 11/⍨0∊OUTSPEC COMSPEC DEBUG SHOWCOMPILED∊¨⍳¨3 3 2 2

 TRAP←DEBUG×999 ⋄ ⎕TRAP←TRAP'C' '⎕SIGNAL/⎕DMX.(EM EN)'
 CR NL←⎕UCS 13 10 ⋄ SQ DQ←'''' '"'
 YES NO←'🅿️ ' '❌ ' ⋄ YESc NOc←'⍝',¨YES NO
 OPTS←('Mode' 'M')('EOL' 'LF')('NEOL' 1)('UCP' 1)('DotAll' 0)('IC' 1)
 CTL←⎕NS''
 PRAGMA_FENCE←'⍙F⍙'  ⍝ See ::PRAGMA
 ⍝ Faux Semicolon used to distinguish tradfn header semicolons from others...
 ⍝ By default, private use Unicode E000If DEBUG, it's a smiley face.
 SEMICOLON_FAUX←⎕UCS DEBUG⊃57344 128512

 :Section Utilities
⍝-------------------------------------------------------------------------------------------
   ⍝ getenv: Returns value of environment var.
     getenv←{⊢2 ⎕NQ'.' 'GetEnvironment'⍵}
   ⍝ notZero: If ⍵ is not numeric 0 singleton or null-string or ⎕NULL, return 1
   ⍝   See ::IF etc.
     notZero←{0=≢⍵:0 ⋄ (,⎕NULL)≡,⍵:0 ⋄ (,0)≢,⍵}
     box←{
         l←≢m←'│  ',⍵,'  │' ⋄ t←'┌','┐',⍨,'─'⍴⍨l-2 ⋄ b←'└','┘',⍨,'─'⍴⍨l-2 ⋄ t,CR,m,CR,b
     }
   ⍝ Show just a bit of an obj of unknown size. (Used for display info)
   ⍝ showObj: assumes values. Puts strings in quotes.
     showObj←{⍺←⎕PW-20 ⋄ maxW←⍺
         f←⎕FMT ⍵
         q←''''/⍨0=80|⎕DR ⍵
         clip←1 maxW<⍴f
         (q,q,⍨(,f↑⍨1 maxW⌊⍴f)),∊clip/'⋮…'
     }
   ⍝ showCode: assumes names or code
     showCode←{⍺←⎕PW-20 ⋄ maxW←⍺
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
     ∆PFX←{⍺←'⍝ ' ⋄ 1=|≡⍵:⍺ ∇(NL∘≠⊆⊢)⍵ ⋄ (⊂⍺),¨⍵}
   ⍝ ∆V2S: Convert a vector of vectors to a string, using carriage returns (APL prints nicely)
     ∆V2S←{1↓∊CR,¨⊆⍵}
   ⍝ ∆V2Q: Convert V of V to a quoted string equiv.
     ∆V2Q←{q←'''' ⋄ 1↓∊(⊂' ',q),¨q,⍨¨⊆⍵}
   ⍝ ∆COM: Convert a v of vs to a set of comments
     ∆COM←{⍺←1 ⋄ ∆V2S(⍺⊃NOc YESc)∆PFX ⍵}
   ⍝ PCRE routines
     ∆FIELD←{
         0=≢⍵:'' ⋄ 1<≢⍵:⍺ ∇¨⍵ ⋄ 0=⍵:⍺.Match
         ⍵≥≢⍺.Lengths:'' ⋄ ¯1=⍺.Lengths[⍵]:''
         ⍺.(Lengths[⍵]↑Offsets[⍵]↓Block)
     }
   ⍝ dictionary routines
   ⍝ Use a local namespace so we can use with ::IF etc.
     ∆DICT←{
         dict←⎕NS''
         dict.ns←dict.⎕NS''
         dict.validate←{
             ⍺←ns ⋄ n k←⍺ ⍵
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
             n(k v)←⍺ ⍵
             n validate k:n{⍺⍎k,'←⍵'}v
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
     register←{⍺←'[',(⍕1+≢Match),']' 1
         ns←⎕NS'SQ' 'DQ' 'TRAP' 'CR' 'NL' 'YES' 'YESc' 'NO' 'NOc' 'OPTS'
         ns.⎕PATH←'##'
         ns.CTL←CTL
         ⍝ Right now we don't do anything with ns.skip
         ⍝    0 - <action> handles skips; call it, whether skip active or not.
         ⍝    1 - If skip: don't call <action>; return: 0 ∆COM  ⍵ ∆FIELD 0
         ⍝    2 - If skip: don't call <action>; return: ⍵ ∆FIELD 0
         ns.(info skip)←2⍴(⊆⍺),0      ⍝ Default skip: 0
         ns.pRaw←⍵                    ⍝ For debugging
         ns.pats←eval ⍵       ⍝ xx-- allow spaces in [...] pats.
         ns.action←⍺⍺                 ⍝ a function OR a number (number → field[number]).

        ⍝  ⎕←'>>>' ⋄ ⎕←ns.info ⋄ ⎕←ns.pats

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

      ⍝   ⎕←'Matched: ',ns.info,' <',(⍵ ∆FIELD 0),'>'

         3=ns.⎕NC'action':ns ns.action ⍵          ⍝ m.action is a fn. Else a var.
         ' '=1↑0⍴ns.action:∊ns.action             ⍝ text? Return as is...
         ⍵ ∆FIELD ns.action                       ⍝ Else m.action is a field number...
     }
     eval←{
         pfx←'(?xx)'               ⍝ PCRE prefix -- required default!
         str,⍨←pfx/⍨~1↑pfx⍷str←⍵   ⍝ Add prefix if not already there...
         ~'⍎'∊str:str
         str≢res←'(?<!\\)⍎(\w+)'⎕R{
             0::f1
             ⍎f1←⍵ ∆FIELD 1
         }⍠('UCP' 1)⊣str:∇ res
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
 :EndSection

 ⍝-------------------------------------------------------------------------------------------
 :Section Reused Pattern Actions
     stringAction←{
       ⍝ Manage single/multiline single-quoted strings and single/multiline double-quoted strings
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
         enQ←{⍺←SQ ⋄ ⍵/⍨1+⍵=⍺}
         dq2sq←{SQ,SQ,⍨enQ DQ deQ 1↓¯1↓⍵}

       ⍝ Here, we handle ellipses at linend within SQ or DQ quotes as special:
       ⍝ Any spaces BEFORE them are preserved. If none, the next line is juxtaposed w/o spaces.
       ⍝ Not clear this (identical) behavior is what we want for SQ and DQ quotes.
       ⍝ WARNING: Right now, the ellipses must be the rightmost characters--
       ⍝   trailing blanks will force the ellipses to be treated as ordinary characters.
         ellipsesP←'(?:\…|\.{2,})$\s*'
         str←ellipsesP ⎕R''⍠OPTS⊣str

         str←dq2sq⍣(q=DQ)⊣str
         ~NL∊str:str
         sfx{
             addP←{'(',⍵,')'}
             nlCode←''',(⎕UCS 10),'''
             ⍺=SQ:'\h*\n\h*'⎕R' '⍠OPTS⊣⍵
             ⍺=DQ:addP'\h*\n\h*'⎕R nlCode⍠OPTS⊣⍵
             (⍺='L'):{
                 q=SQ:'\n'⎕R' '⍠OPTS⊣⍵
                 addP'\n'⎕R nlCode⍠OPTS⊣⍵
             }⍵
             ○LOGIC ERROR.UNREACHABLE
         }str
     }
 :EndSection
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
         SHOWCOMPILED←1
         ⎕SHADOW'counter' 'line' 'lines' 'more'
         lines←⍬ ⋄ counter←0
         '> Enter input lines. Null line when done.'
         ⎕←'    ∇ temp               ⍝ FIX temporary function'
         :While 1
             _←≢⍞←'[',(⍕counter←counter+1),'] '
             :If 0≠≢line←_↓⍞
                 lines,←⊂line
             :Else
                 :Leave
             :EndIf
         :EndWhile
         ⎕←'    ∇'
         fileName←(739⌶0),'/∆FIX_STDIN','.dyalog'
         :If ×≢lines
             1 ⎕NDELETE fileName
             lines←(⊂'∇temp'),lines,(⊂,'∇')
             (⊂lines)⎕NPUT fileName
             ⎕←↑⊃⎕NGET fileName 1
         :Else
             :If ⎕NEXISTS fileName
                 ⎕←↑⊃⎕NGET fileName 1
             :EndIf
         :EndIf
     :EndIf
     code←readFile fileName
 :EndSection Read In file or stdin

 dict←∆DICT''
 :Section Process File
   ⍝ Valid 1st chars of names...
     ALPH←'abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüþß'
     ALPH,←'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÕÔÖØÙÚÛÜÝ'
     ALPH,←'_∆⍙'
   ⍝ Valid APL simple names
     nameP←eval'(?:   ⎕? [⍎ALPH] [⍎ALPH\d]* | \#{1,2} )'
   ⍝ Valid APL complex names
     longNameP←eval'(?: ⍎nameP (?: \. ⍎nameP )* )  '
   ⍝ anyNumP: If you see '3..', 3 is the number, .. treated elsewhere
     anyNumP←'¯?\d([\dA-FJE¯_]+|\.(?!\.))+[XI]?'

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
   ⍝  field1 will be the string, including quotes. f2 may be null or a single alphabetic char.
     specialStringP←eval' (⍎stringP)  (?: \.{2,2} ([A-Z]) )? '
   ⍝ Comment pat
     commentP←'(?: ⍝.* )'
     ellipsesP←'(?:  \… | \.{2,} )'
   ⍝ A directive prefix
     directiveP←'^ \h* :: \h*'
   ⍝ Directives with code that spans lines.
   ⍝ ... Succeed only if {} () '' "" strings are balanced.
   ⍝ (Note: requires that RHS comments have already been removed.)
     multiLineP←'(?: (?: ⍎braceP | ⍎parenP | ⍎stringP  | [^{(''"\n]+ )* )'

     :Section Preprocess Tradfn Headers...
         :If ':⍝∇'∊⍨1↑' '~⍨⊃code
        ⍝ Tradfn header with leading ∇.
        ⍝ (To be treated as a header, it must have one alpha char after ∇.)
        ⍝ Could occur on any line...
             code←'(?x)^ \h* ∇ \h* \w [^\n]* $   (?: \n  \h* ; [^\n]* $ )*'⎕R{
                 SEMICOLON_FAUX@(';'∘=)⊣⍵ ∆FIELD 0
             }⍠OPTS⊣code
         :Else
        ⍝ Here, 1st line is assumed to be tradfn header without leading ∇: Process the header ONLY
             code←'(?x)\A [^\n]* $   (?: \n \h* ; [^\n]* $ )*'⎕R{
                 SEMICOLON_FAUX@(';'∘=)⊣i←⍵ ∆FIELD 0
             }⍠OPTS⊣code
         :EndIf
     :EndSection Preprocess Tradfn Headers

     :Section Setup Scans
         :Section PreScan1
             MBegin
           ⍝ CONTINUATION LINES ARE HANDLED IN SEVERAL WAYS
           ⍝ 1) Within multiline strings, newlines are treated specially (q.v.);
           ⍝ 2) Ellipses-- Unicode … or .., ..., etc.-- in code or strings,
           ⍝    are replaced by a single blank; any trailing comments or newlines or
           ⍝    leading blanks on the next line are ignored;
           ⍝ 3) When a semicolon appears at the end of a line (before opt'l comments),
           ⍝    the next line is appended after the semicolon.

           ⍝ Comments on their own line are kept.
             'COMMENTS_LINE*'(0 register)'^ \h* ⍝ .* $'

           ⍝ Multi-line strings:
           ⍝ Handles DQ strings (linends → newlines, ignoring trailing blanks)
           ⍝         SQ strings (linends → ' '
           ⍝ Handles .. (etc.) in either-- trailing blanks respected, not leading.
           ⍝ See stringAction above.
             'STRINGS'stringAction register specialStringP
           ⍝ Ellipses and .. (... etc) → space, with trailing and leading spaces ignored.
           ⍝ Warning: Ellipses in strings handled above via 'STRINGS' and stringAction.
             'CONT'(' 'register)'\h*  ⍎ellipsesP \h*  ⍎commentP?  $  \s*'
           ⍝ NUMS 123_456: ⍝ Remove _ from (extended) numbers-- APL and hexadecimal.
             'NUMS 123_456'{'_'~⍨⍵ ##.∆FIELD 0}register anyNumP
           ⍝ Leading and trailing semicolons are forced onto the same line...
           ⍝ They may be converted to other forms (see ATOM processing).
           ⍝          ;   <==   2nd-line leading ;           1st-line trailing ;
             'SEMI1'(';'register)'\h* ⍎commentP? $ \s* ; \h* | \h* ; ⍎commentP? $ \s*'

            ⍝ RHS Comments are ignored...
             'COMMENTS_RHS'(''register)'⍎commentP $'
             PreScan1←MEnd
         :EndSection
         :Section PreScan2
             MBegin
           ⍝ A lot of processing to handle multi-line parens or brackets ...
             'STRINGS'(0 register)stringP                ⍝ Skip
             'COMMENTS_LINE*'(0 register)'^\h* ⍎commentP $'     ⍝ Skip
             'Multiline () or []' 0{
               ⍝ Remove newlines and associated spaces in (...) and [...]
               ⍝ UNLESS inside quotes or braces!
               ⍝ But newlines inside quotes and braces have already been eaten above.
               ⍝ >>> RETHINK the logic here.
                 ##.stringP ##.braceP'\h*\n\h*'⎕R'\0' '\0' ' '⍠##.OPTS⊣⍵ ∆FIELD 0
             }register'(⍎brackP|⍎parenP)'
             PreScan2←MEnd
         :EndSection

         :Section MainScan1
             MBegin
            ⍝ IFDEF stmts
             'IFDEF+IFNDEF' 0{
                 CTL.skip:0 ∆COM ⍵ ∆FIELD 0

                 f0 n k←⍵ ∆FIELD¨0 1 2 ⋄ not←⍬⍴n∊'nN'
                 ##.CTL.stack,←~⍣not⊣##.dict.defined k
                 CTL.skip←~⊃⌽##.CTL.stack

                 (~CTL.skip)∆COM f0
             }register'⍎directiveP  IF(N?)DEF\b \h*(⍎longNameP) .* $'

           ⍝ IF stmts
           ⍝  doMap←{nm←⍵ ∆FIELD 1 ⋄ o i←'⍙Ø∆' '.#⎕' ⋄ {o[i⍳nm]}@(∊∘i)⊣nm}
           ⍝  dictNameP←eval'(?xx)(⍎longNameP)(?>\.\.\w)'
             'IF' 0{
                 CTL.skip:0 ∆COM ⍵ ∆FIELD 0

                 f0 code0←⍵ ∆FIELD¨0 1
                 0::{
                     CTL.skip←0 ⋄ ##.CTL.stack,←1
                     ⎕←NO,'Unable to evaluate ::IF ',⍵
                     '911 ⎕SIGNAL⍨''∆FIX VALUE ERROR''',NL,0 ∆COM'::IF ',⍵
                 }code0

                    ⍝ ⎕←'::IF code0 ',code0
                 code1←(0 doScan)code0
                    ⍝ ⎕←'::IF code1 ',code1
                 code2←##.dict.ns{⍺⍎⍵}code1
                    ⍝ ⎕←'::IF code2 ',code2

                 CTL.skip←~##.CTL.stack,←notZero code2  ⍝ (is code2 non-zero?)

                 (~CTL.skip)∆COM('::IF ',showCode code0)('➤    ',showCode code1)('➤    ',showObj code2)
             }register'⍎directiveP IF \b \h* (.*) $'
            ⍝ ELSEIF/ELIF stmts
             'ELSEIF/ELIF' 0{
                 CTL.skip←⊃⌽##.CTL.stack
                 CTL.skip:0 ∆COM ⍵ ∆FIELD 0

                 f0 code0←⍵ ∆FIELD¨0 1
                 0::{
                     CTL.skip←←0 ⋄ (⊃⌽##.CTL.stack)←1      ⍝ Elseif: unlike IF, replace last stack entry, don't push

                     ⎕←##.NO,'Unable to evaluate ::ELSEIF ',⍵
                     '911 ⎕SIGNAL⍨''∆FIX VALUE ERROR''',NL,0 ∆COM'::IF ',⍵
                 }code0
                 code1←(0 doScan)code0
                 code2←##.dict.ns{⍺⍎⍵}code1
                 CTL.skip←~(⊃⌽##.CTL.stack)←notZero code2            ⍝ Elseif: Replace, don't push. [See ::IF logic]
                 _←(~CTL.skip)∆COM('::ELSEIF ',showCode code0)('➤    ',showCode code1)
                 _,('➤    ',showObj code2)
             }register'⍎directiveP  EL(?:SE)IF\b \h* (.*) $'
            ⍝ ELSE
             'ELSE' 0{
                 CTL.skip←~(⊃⌽##.CTL.stack)←~⊃⌽##.CTL.stack    ⍝ Flip the condition of most recent item.
                 f0←⍵ ∆FIELD 0
                 (~CTL.skip)∆COM f0
             }register'⍎directiveP ELSE \b .* $'
            ⍝ END, ENDIF, ENDIFDEF
             'END(IF(DEF))' 0{
                 f0←⍵ ∆FIELD 0
                 oldskip←CTL.skip
                 CTL.skip←~⊃⌽##.CTL.stack⊣##.CTL.stack↓⍨←¯1

                 (~oldskip)∆COM f0
             }register'⍎directiveP  END  (?: IF  (?:DEF)? )? \b .* $'
           ⍝ CONDITIONAL INCLUDE - include only if not already included
             filesIncluded←⍬
             'CINCLUDE' 1{
                 CTL.skip:0 ∆COM ⍵ ∆FIELD 0
                 f0 fName←⍵ ∆FIELD¨0 1 ⋄ fName←{k←'"'''∊⍨1↑⍵ ⋄ k↓(-k)↓⍵}fName
                 (⊂fName)∊##.filesIncluded:0 ∆COM f0⊣⎕←box f0,': File already included. Ignored.'
                 ##.filesIncluded,←⊂fName

                 rd←{22::22 ⎕SIGNAL⍨'∆FIX: Unable to CINCLUDE file: ',⍵ ⋄ readFile ⍵}fName
                 (CR,⍨∆COM f0),∆V2S(0 doScan)rd
             }register'⍎directiveP  CINCLUDE \h+ (⍎stringP | [^\s]+) .* $'
            ⍝ INCLUDE
             'INCLUDE' 1{
                 CTL.skip:0 ∆COM ⍵ ∆FIELD 0

                 f0 fName←⍵ ∆FIELD¨0 1 ⋄ fName←{k←'"'''∊⍨1↑⍵ ⋄ k↓(-k)↓⍵}fName
                 ##.filesIncluded,←⊂fName   ⍝ See CINCLUDE

                 rd←{22::22 ⎕SIGNAL⍨'∆FIX: Unable to INCLUDE file: ',⍵ ⋄ readFile ⍵}fName
                 (CR,⍨∆COM f0),∆V2S(0 doScan)rd
             }register'⍎directiveP  INCLUDE \h+ (⍎stringP | [^\s]+) .* $'
           ⍝ COND (cond) stmt   -- If cond is non-zero, a single stmt is made avail for execution.
           ⍝ COND single_word stmt
           ⍝ Does not affect the CTL.stack or CTL.skip...
             'COND' 1{
                 CTL.skip:0 ∆COM ⍵ ∆FIELD 0

                 f0 cond0 stmt←⍵ ∆FIELD¨0 1 3   ⍝ (parenP) uses up two fields
                 0=≢stmt~' ':0 ∆COM('[Statement field is null: ]')f0
                 0::{
                     ⎕←NO,'Unable to evaluate ',⍵
                     '911 ⎕SIGNAL⍨''∆FIX VALUE ERROR''',CR,0 ∆COM ⍵
                 }f0
                 cond1←(0 doScan)cond0
                 cond2←##.dict.ns{⍺⍎⍵}cond1
                 bool←notZero cond2

                 stmt←⍕(0 doScan)stmt
                 out1←bool ∆COM f0('➤  ',showCode cond1)('➤  ',showObj cond2)('➤  ',showObj bool)
                 out2←CR,(NOc/⍨~bool),stmt
                 out1,out2
             }register'⍎directiveP  COND \h+ ( ⍎parenP | [^\s]+ ) \h (⍎multiLineP) $'
           ⍝ DEFINE name [ ← value]
           ⍝ Note: value is left unevaluated (as a string) in ∆FIX (see LET for alternative)
           ⍝     ::DEFINE name       field1=name, field2 is null string.
           ⍝     ::DEFINE name ← ... field1=name, field2 is rest of line after arrow/spaces
             defS←'⍎directiveP  DEF(?:INE)? \b \h* (⍎longNameP) (?:  \h* ← \h*  ( ⍎multiLineP ) )* $'
             'DEF(INE)' 1{
                 CTL.skip:0 ∆COM ⍵ ∆FIELD 0

                 f0 k v←⍵ ∆FIELD¨0 1 2
               ⍝ Replace leading and trailing blanks with single space
                 v←{'('=1↑⍵:'\h*\R\h*'⎕R' '⍠OPTS⊣⍵ ⋄ ⍵}v
                 v←⍕(0 doScan)v
                 _←##.dict.set k v
                 ∆COM f0
             }register defS
            ⍝ LET  name ← value   ⍝ value (which must fit on one line) is evaluated at compile time
            ⍝ EVAL name ← value   ⍝ (synonym)
             'LET~EVAL' 1{
                 CTL.skip:0 ∆COM ⍵ ∆FIELD 0

                 f0 k vIn←⍵ ∆FIELD¨0 1 2
                 0::{
                     ⎕←'>>> VALUE ERROR: ',f0
                     _←##.dict.del k
                     msg←(f0)('➤ UNDEF ',k)
                     '911 ⎕SIGNAL⍨''∆FIX VALUE ERROR: ',f0,'''',CR,0 ∆COM msg
                 }⍬
                 _←##.dict.validate k
                 vOut←##.dict.ns{⍺⍎⍵}k,'←',vIn
                 msg←'➤ DEF ',k,' ← ',∆V2S{0::'∆FIX LOGIC ERROR!' ⋄ ⎕FMT ⍵}vOut
                 ∆COM f0 msg
             }register'⍎directiveP  (?: LET | EVAL) \b \h* (⍎longNameP) \h* ← \h* (⍎multiLineP) $'
            ⍝ :PRAGMA name ← value
            ⍝  (Names are case insensitive)
            ⍝ Current:
            ⍝    name: FENCE.  Sets the temp. name for "fence" constructions (←⍳5) etc.
            ⍝    ::PRAGMA FENCE←'⍙F⍙'
             'PRAGMA' 1{
                 CTL.skip:0 ∆COM ⍵ ∆FIELD 0

                 f0 k vIn←⍵ ∆FIELD¨0 1 2 ⋄ k←1(819⌶)k  ⍝ k: ignore case
                 TRAP::{911 ⎕SIGNAL⍨'∆FIX ::PRAGMA VALUE ERROR: ',f0}⍬
                 _←##.dict.validate k
                 vOut←##.dict.ns{⍺⍎⍵}k,'←',vIn
                 msg←'➤ DEF ',k,' ← ',∆V2S{0::'∆FIX LOGIC ERROR!' ⋄ ⎕FMT ⍵}vOut
                 ∆COM f0 msg⊣{
                     'FENCE'≡k:⊢##.PRAGMA_FENCE∘←vOut
                     911 ⎕SIGNAL⍨'∆FIX ::PRAGMA KEYWORD UNKNOWN: "',k,'"'
                 }⍬
             }register'⍎directiveP  PRAGMA \b \h* (⍎longNameP) \h* ← \h* (.*) $'
           ⍝ UNDEF stmt
           ⍝ UNDEF stmt
             'UNDEF' 1{
                 CTL.skip:0 ∆COM ⍵ ∆FIELD 0

                 f0 k←⍵ ∆FIELD¨0 1
                 _←##.dict.del k
                 ∆COM f0
             }register'⍎directiveP  UNDEF \b\h* (⍎longNameP) .* $'
           ⍝ ERROR stmt
           ⍝ Generates a preprocessor error signal...
             'ERROR' 1{
                 CTL.skip:0 ∆COM ⍵ ∆FIELD 0

                 line num msg←⍵ ∆FIELD¨0 1 2
                 num←⊃⊃⌽⎕VFI num,' 0' ⋄ num←(num≤0)⊃num 911
                 ⎕←CR@(NL∘=)⊣('\Q',line,'\E')⎕R(NO,'\0')⍠OPTS⊣⍵.Block
                 ⎕SIGNAL/('∆FIX ERROR: ',msg)num
             }register'⍎directiveP ERR(?:OR)? (?| \h+ (\d+) \h (.*) | () \h* (.*) ) $'
            ⍝ MESSAGE / MSG stmt
            ⍝ Puts out a msg while preprocessing...
             'MESSAGE~MSG' 1{
                 CTL.skip:0 ∆COM ⍵ ∆FIELD 0

                 line msg←⍵ ∆FIELD¨0 1
                 ⎕←box msg
                 ∆COM line
             }register'⍎directiveP  (?: MSG | MESSAGE)\h(.*)$'
           ⍝ Start of every NON-MACRO line → comment, if CTL.skip is set. Else NOP.
             'SIMPLE_NON_MACRO' 0{
                 CTL.skip/NOc,⍵ ∆FIELD 0
             }register'^'
           ⍝ COMMENTS: passthrough
             'COMMENTS*'(0 register)'^\h*⍝.*$'
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
             'name..cmd' 1{
                 CTL.skip:0 ∆COM ⍵ ∆FIELD 0

                 nm cmd←⍵ ∆FIELD¨1 2 ⋄ cmd←1(819⌶)cmd ⋄ q←''''
               ⍝ Check nm of form a.b.c.d for macros in a, b, c, d
                 nm←subMacro nm

                 cmd≡'ENV':' ',q,(getenv nm),q,' '
                 cmd≡'DEF':'(0≠⎕NC',q,nm,q,')'
                 cmd≡'UNDEF':'(0=⎕NC',q,nm,q,')'
                 cmd≡,'Q':' ',q,nm,q,' '
                 ⎕SIGNAL/('Unknown cmd ',⍵ ∆FIELD 0)911
             }register'(⍎longNameP)\.{2,2}(DEF|UNDEF|Q|ENV)\b'
           ⍝ ATOMS, PARAMETERS (PARMS)
           ⍝ atoms: n1 n2 n3 → anything,   `n1 n2 n3
           ⍝  parms: bc def ghi → xxx     →   ('abc' 'def' 'ghi')
           ⍝       ( → code;...) ( ...; → code; ...) are also allowed. The atom is then ⍬.
           ⍝ To do: Allow char constants-- just don't add quotes...
           ⍝ To do: Treat num constants as unquoted scalars
             atomsP←' (?:         ⍎longNameP|¯?\d[\d¯EJ\.]*|⍎sqStringP|⍬)'
             atomsP,←'(?:\h+   (?:⍎longNameP|¯?\d[\d¯EJ\.]*|⍎sqStringP)|\h*⍬+)*'
             'ATOMS/PARMS' 2{
                 CTL.skip:⍵ ∆FIELD 0

                 atoms arrow←⍵ ∆FIELD 1 2
               ⍝ Split match into individual atoms...
                 atoms←(##.stringP,'|[^\h''"]+')⎕S'\0'⍠##.OPTS⊣,(0=≢atoms)⊃atoms'⍬'
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
             'STRINGS*' 0(0 register)'⍎sqStringP'
            ⍝ Hexadecimal integers...
            ⍝ See ⎕UdhhX for hexadecimal Unicode constants
             h2d←{ ⍝ Convert hex to decimal.
                 ∆D←⎕D,'ABCDEF',⎕D,'abcdef'
                 0::⍵⊣⎕←'∆FIX WARNING: Hexadecimal number out of range: ',⍵
                 (s⊃1 ¯1)×16⊥∆D⍳(¯1↓⍵)↓⍨s←'¯'=1↑⍵
             }
             'HEX INTs' 2{
                 CTL.skip:⍵ ∆FIELD 0

                 ⍕##.h2d ⍵ ∆FIELD 0
             }register'(?<![⍎ALPH])¯?\d[\dA-F]*X\b'
            ⍝ UNICODE, decimal (⎕UdddX) and hexadecimal (⎕UdhhX)
            ⍝ ⎕U123 →  '⍵', where ⍵ is ⎕UCS 123
            ⍝ ⎕U021X →  (⎕UCS 33) → '!'
             'UNICODE' 2{
                 CTL.skip:⍵ ∆FIELD 0
                 i←{'xX'∊⍨⊃⌽⍵:##.h2d ⍵ ⋄ 1⊃⎕VFI ⍵}⍵ ∆FIELD 1
                 (i≤32)∨i=132:'(⎕UCS ',(⍕i),')'
                 ' ',SQ,(⎕UCS i),SQ,' '
             }register'⎕U ( \d+ | \d [\dA-F]* X ) \b'

            ⍝ MACRO: Match APL-style simple names that are defined via ::DEFINE above.
             'MACRO' 2{
                 CTL.skip:⍵ ∆FIELD 0          ⍝ Don't substitute under CTL.skip

                 TRAP::k⊣⎕←'Unable to get value of k. Returning k: ',k
                 k←⍵ ∆FIELD 1
                 v←⍕##.dict.get k
                 0=≢v:k
                 '{(['∊⍨1↑v:v      ⍝ Don't wrap (...) around already wrapped strings.
                 '(',v,')'
             }register'(⍎longNameP)(?!\.\.)'
            ⍝   ← becomes ⍙S⍙← after any of '()[]{}:;⋄'
            ⍝   ⍙S⍙: a "fence"
             'ASSIGN' 2{
                 CTL.skip:⍵ ∆FIELD 0

                 ##.PRAGMA_FENCE,'←'
             }register'^ \h* ← | (?<=[()\[\]{};:⋄]) \h* ←  '
         :EndSection
         MainScan1←MEnd
     :EndSection

     :Section List Scan (experimental)
     ⍝ Handle lists of the form:
     ⍝        (name1; name2; ;)   (;;;) ()  ( name→val; name→val;) (one_item;) (`an atom of sorts;)
     ⍝ Lists must be of the form  \( ... \) with
     ⍝       - at least one semicolon or
     ⍝       - be exactly  \( \s* \), e.g. () or (  ).
     ⍝ Parenthetical expressions without semicolons are standard APL.
         MBegin
         Par←⎕NS'' ⋄ Par.enStack←0
         'Comments'(0 register)'^ \h* ⍝ .* $'
         'STRINGS'(0 register)'⍎sqStringP'
         'Null List/List Elem' 0{   ⍝ (),  (;) (;...;)
             sym←⍵ ∆FIELD 0 ⋄ nSemi←+/sym=';'
             '(',')',⍨(','⍴⍨nSemi=1),'⍬'⍴⍨1⌈nSemi
         }register'\((?:\s*;)*\)'
         'Parens/Semicolon' 0{
             Par←##.Par ⋄ sym endPar←⍵ ∆FIELD 0 1 ⋄ sym0←⊃sym
             inP←⊃⌽Par.enStack
             ';'=sym0:{
                 Par.enStack↓⍨←-e←×≢endPar
               ⍝ Did we match a right paren (after semicolons)?
               ⍝ This is invalid whenever semicolon is on header line!
               ⍝ We handle function headers (q.v.) above.
                 1=≢Par.enStack:∊(⊂' ⊣')@(';'∘=)⊣⍵     ⍝   ';' outside [] or () treated as ⊣
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
         }register'\( \h* ; (?: \h*;)* | ; (?: \h* ; )* \h* (\)?) |  [();\[\]]  '
         'Non-list sequences'(0 register)'[^();\[\]''⍝]+'
         ListScan←MEnd
     :EndSection

     :Section Define Scans
     ⍝ To scan simple expressions:
     ⍝   code← [PreScan1 PreScan2] MainScan1 (⍺⍺ doScan)⊣ code
     ⍝          ⍺⍺=1: Save and restore the IF and CTL.skip stacks during use.
     ⍝          ⍺⍺=0: Maintain existing stacks
         CTL.(stack skip save)←1 0 ⍬
         doScan←{
             TRAP::⎕SIGNAL/⎕DMX.(EM EN)
             ⍺←MainScan1       ⍝ Default is to omit the prescan
             stackFlag←⍺⍺
             saveStacks←{⍵:CTL.save,←⊂CTL.(stack skip) ⋄ CTL.(stack skip)←1 0 ⋄ ''}
             restoreStacks←{⍵:CTL.(save←¯1↓save⊣stack skip←⊃⌽save) ⋄ ''}

             _←saveStacks stackFlag
             res←⍺{
                 0=≢⍺:⍵
                 scan←⊃⍺
                 _code←scan.pats ⎕R(scan MActions)⍠OPTS⊣⍵
                 (1↓⍺)∇ _code
             }⍵
             res⊣restoreStacks stackFlag
         }
     :EndSection Define Scans

     :Section Do Scans
       ⍝ =================================================================
       ⍝ Executive
       ⍝ =================================================================
         code←PreScan1 PreScan2 MainScan1 ListScan(0 doScan)code

       ⍝ Clean up based on comment specifications (COMSPEC)
         :Select COMSPEC
              ⋄ :Case 2 ⋄ code←'(?x)^\h* ⍝[❌🅿️].*\n(\h*\n)*' '^(\h*\n)+'⎕R'' '\n'⍠OPTS⊣code
              ⋄ :Case 1 ⋄ code←'(?x)^\h* ⍝❌    .*\n(\h*\n)*' '^(\h*\n)+'⎕R'' '\n'⍠OPTS⊣code
             ⍝ Otherwise: do nothing
         :EndSelect
       ⍝ Other cleanup: Handle (faux) semicolons in headers...
         code←{';'@(SEMICOLON_FAUX∘=)⊣⍵}¨code
     :EndSection Do Scans
 :EndSection

 :If SHOWCOMPILED
     ⎕ED'code'
 :EndIf

 :Section Write out so we can then do a 2∘⎕FIX
     tmpfile←(739⌶0),'/','TMP~.dyalog'
     :Trap 0
         (⊂code)⎕NPUT tmpfile 1         ⍝ 1: overwrite file if it exists.
         objects←2(0⊃⎕RSI).⎕FIX'file://',tmpfile
       ⍝ Break association betw. <objects> and file TMP~ that ⎕FIX creates.
         :If 0∊(0⊃⎕RSI).(5178⌶)¨objects
             ⎕←'∆FIX: Logic error dissociating objects: ',,⎕FMT objects ⋄ :EndIf
         :Select OUTSPEC
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
     ⎕←'PreScan2  Pats:'PreScan2.info
     ⎕←'MainScan1 Pats:'MainScan1.info
     ⎕←'      *=passthrough'

     :If 0≠≢keys←dict.keys
         'Defined names and values'
         ⍉↑keys dict.values
     :EndIf
 :EndIf
