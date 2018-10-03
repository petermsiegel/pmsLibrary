:namespace format

    :Section 1A. Documentation
        ⍝⍝⍝ See formatLib.Documentation> below.
        ⍝⍝⍝ Overview Documentation, see...
        ⍝⍝⍝      format.Documentation.README
        ⍝⍝⍝ Detailed Documentation:
        ⍝⍝⍝     './formatHelp.pdf'
        ⍝⍝⍝ Source Documentation:
        ⍝⍝⍝      [Google Docs] https://goo.gl/QaNsWq
    :EndSection 1A.

    :section  1B. Preamble and Constants
    ⎕IO ⎕ML ⎕PW ⎕FR←0 1 132 645
    QUIET←1
    TRAP_SIGNALS← 0 1000

     ⍝ Helper fn...
    _←⎕FX '{r}←msg txt' 'r←1' (' ' '⎕←txt'⊃⍨~QUIET)

   ⍝ Add format to ⎕PATH if it's empty on ]load format. Say so, if QUIET=0
    _←'When format was loaded or saved, #.⎕PATH was empty ('''').'
    msg _{0≠≢⍵.⎕PATH: ⍵ ⋄new←⍵.⎕PATH∘←⍕⎕THIS⋄ ↑⍺ ('>>> Setting ',(⍕⍵),'.⎕PATH←''',new,'''')  }#

  ⍝ formatPath: A run-time auxiliary function.
  ⍝     Returns this namespace reference.
  ⍝     Set as a function so it is found by ⎕PATH.
  ⍝     Used with:   ∆pad, ∆master, ∆, and ∆cat
  ⍝ Usage: Use with any run-time utilities used in ∆f/ormat, so we don't pollute the namespace.
  ⍝     Only these user-callable routines need be visible:
  ⍝        ∆f, ∆format, PLUS formatPath and format itself.
    ∇ ns←formatPath
      ns←⎕THIS
    ∇
    msg 'format library:      ',⍕formatPath
    msg 'format TRAP_SIGNAL(S): ',TRAP_SIGNALS

  ⍝ ALLOW_UNICODE_NULLS:  Installation option...
  ⍝ If allowed, right now, ⎕UCS 0 chars cause bugs with ⍎ (1 format ...).
  ⍝ We handle those bugs via nullMagicIn/_OUT code (q.v.).
  ⍝   1: allow and manage unicode nulls (by "hiding" them as non-nulls during ∆f's ⍎)
  ⍝   0: unicode nulls will be disallowed, e.g. when specified via via ⎕Unnn[X]
  ⍝ Bugs: A Minor Kludge.
    ALLOW_UNICODE_NULLS←1  ⋄    msg 'Allowing and Managing Unicode Nulls? ',ALLOW_UNICODE_NULLS⊃'No' 'Yes'

  ⍝ Key constants...
    ∆ALPH←⎕A,⎕UCS(⎕UCS'a')+⍳26
    SQ←'''' ⋄ DQ←'"' ⋄ LINE_BRK←⎕UCS 13 ⋄    KANJI_SPACE←⎕UCS 12288
    SPucs←⎕UCS ' '   ⍝ SPucs: space, i.e. decimal 32
    RCucs←65533      ⍝ RCucs: Unicode "replacement character" 65533  �

    :endSection 1B. Preamble and Constants

    :section 2.  Initialization
    :section 2A. Initialization: Define Run-time Utilities (Visible to User Code in <format> string)

⍝⍝ -----------------------------------------------------------------------------------------------------⍝⍝
⍝⍝ FUNCTIONS VISIBLE TO format-internal user-specified code- and variable name-fields when executed.
⍝⍝ These functions will be called fully-specified via formatPath
⍝⍝ While user-callable, we generate them within ∆f/∆format.
⍝⍝ -----------------------------------------------------------------------------------------------------⍝⍝

    ⍝ ∆pad:
    ⍝   "Pad any APL object, converted to a character matrix."
    ⍝   objOut@S ← width@N type@N pad@N|0 ∇ objIn@S
    ⍝     width: ≥0
    ⍝     type:  ¯1 (put text on left), 1 (put text on right), 0 (center)
    ⍝     pad:   a single padding character in text or unicode numeric format. Missing→' '.
    ⍝ Any pad char that affects line spacing is replaced by Replacement Char (RC) '�' on output.

      ∆pad←{⍝0::⎕SIGNAL/'∆pad: Invalid padding width, type, or character' 11
          width type pad←⍺,0 32↑⍨0⌊¯3+≢⍺            ⍝  width [type=0 [pad=32]]
          ' '=1↑0⍴pad:width type(⎕UCS ⍬⍴pad)∇ ⍵
     
          ch←⎕UCS pad RCucs⊃⍨pad∊0 9 10 13 133         ⍝ Ctl chars and null treated as soft error
     
          mh mw←⍴mx←⎕FMT ⍵                 ⍝ the ht and width of the matrix
          mw>width:mx⊣(¯2↑[1]mx)←'.'⊣mx←mh width↑mx
          mw=width:mx
     
          type=¯1:mx,mh(0⌈width-mw)⍴ch     ⍝ ¯1: text on left  (padding on right)
          type=+1:mx,⍨mh(0⌈width-mw)⍴ch    ⍝  1: text on right (padding on left)
        ⍝ ↓↓↓                              ⍝  0: text centered
          (mh(0⌈⌈hf)⍴ch),mx,(mh(0⌈⌊hf)⍴ch)⊣hf←0.5×width-mw
      }
    ∆padNm←'formatPath.∆pad' ⍝ The "name" of the ∆pad function.

    ⍝ ∆master: allow for connecting displayable objects horizontally and vertically.
      ∆master←{
     
          ⎕PP←(⎕IO⊃⎕RSI).⎕PP              ⍝ Get ⎕PP from calling environment...
          widths←⍬
        ⍝ M: keep Matrix;  B: box it;  W: include widths; V: Convert 1-line matrix result to vector (default)
        ⍝ W (incl. widths) is no longer used in the format namespace.
          caseM caseB caseW←'MBW'∊⍺⍺
          box←⊢    ⍝ box is suppressed/ignored in this version
     
          over←{
            ⍝ L: Put ⍵ on left; R: Put ⍵ on right; C: Put ⍵ in center (default)
              caseL caseR←'LR'∊⍺⍺
              widA widW←⊃∘⌽∘⍴¨⍺ ⍵
              widA=widW:⍺,[0]⍵
              caseL∨caseR:⍺{
                  mult←caseR⊃1 ¯1
                  widA<widW:((mult×widW)↑[1]⍺),[0]⍵
                  ⋄ ⋄ ⋄ ⋄ ⋄ ((mult×widA)↑[1]⍵),[0]⍨⍺
              }⍵
            ⍝ case 'C' (the default case)
              ⍺{
                  dif←⌊0.5×|widW-widA
                  widA<widW:(widW↑[1](-widA+dif)↑[1]⍺),[0]⍵
                  ⋄ ⋄ ⋄ ⋄ ⋄ (widA↑[1](-widW+dif)↑[1]⍵),[0]⍨⍺
              }⍵
          }
          form←{
              0 1∊⍨|≡⍵:{caseW:⍵⊣widths,←⊃⌽⍴⍵ ⋄ ⍵}⎕FMT ⍵
              (0=⍴⍴⍵)∧0<|≡⍵:∇⊃⍵
              {⊃,/[0](⊃⌈/0∘⌷∘⍴¨⍵)↑[0]¨⍵}∇¨⍵
          }
        ⍝ flatM2V: "Convert a 1-row matrix to a vector, if ⍺=1. Otherwise, a NOP."
        ⍝
          flatM2V←{
              ,⍣(⍺⍱1≠⍬⍴⍴⍵)⊣⍵
          }
          ⍺←⊢
        ⍝ dyadic...
        ⍝ case M:           return matrix result
        ⍝ case V (Default): return vector if 1-row matrix, else matrix
          opt2To1←'M',caseB/'B'
          1≢⍺ 1:box⍣caseB⊣caseM flatM2V(opt2To1 ∇∇ ⍺)(⍺⍺ over)(opt2To1 ∇∇ ⍵)
     
        ⍝ monadic...
        ⍝ case M/MW:               Return matrix result
        ⍝ case V|VW (V default):   Return vector if 1-row matrix, else matrix.
        ⍝ ret ∊⍨ W      Also include widths of each item
          obj←box⍣caseB⊣caseM flatM2V form ⍵
          caseW:obj widths
          obj
      }
    ∆masterNm←'formatPath.∆master'    ⍝ My "name" as a string.

    ⍝ ∆: General case for building rectangular/multidimensional objects
    ⍝        ⍺ ∆ ⍵                ⍺ over ⍵
    ⍝        ∆ ⍵1 ⍵2 ... ⍵N       ⍵ concat'd with ⍵2 ... with ⍵N
    ⍝    default "cat" and "over" with default options: 'V' (convert to vector if 1-row). 'C' center is default.
    ∆←{⍺←⊢⋄⍺ (''∆master) ⍵}
    ∆overNm←'formatPath.∆ '         ⍝ ∆ with default options. Final space required.

    ⍝ ∆FMTx:
    ⍝   "Converts a simple vector right argument to a 1-row matrix, then calls 2-adic ⎕FMT.
    ⍝    Otherwise, identical to ⎕FMT."
    ⍝    ∘ ⎕FMT treats a simple vector rt. arg. as a column vector (⍪⍵); sometimes, you
    ⍝      want each item in ⍵ to be formatted separately. ∆FMTx handles this case, without
    ⍝      changing other objects (with different depth or shape).
    ⍝   Example:  'F5.2' ∆FMTx 1 2 3  ←-→  'F5.2' ⎕FMT 1 3⍴1 2 3
    ⍝   Usage:    See <format> syntax $, $$, e.g. format '{F5.2$$ 1 2 3}' calls ∆FMTx.
    ∆FMTx←⎕FMT∘{1≠⍴⍴⍵:⍵ ⋄ 1≠≡⍵:⍵ ⋄ ⍉⍪⍵}
    ∆FMTxNm←'formatPath.∆FMTx',' '         ⍝ My "name"; final space required.

    ⍝ ∆cat:
    ⍝   "Catenates each element ⍵N in ⍵, if a vector, treating ⍵N as a character matrix,
    ⍝    and joining it to those on its left and right by extending their heights as required.
    ⍝    No spaces are placed between items (those must be specified explicitly)."
    ⍝       objOut ← [widthF←0] ∇ items
    ⍝       ∘ items: zero or more objects of any shape in a list.
    ⍝       ∘ widthF←0: If 0, returns the objects catenated per above.
    ⍝                   If 1, returns a two-element list: the width of all objects, the objects as above.
    ⍝       ∘ objOut: The objects returned or (widths, objects) returned.
      ∆cat←{
          ⍺←0 ⋄ (⍺⊃'V' 'VW')∆master ⍵
      }
    ∆catNm←'formatPath.∆cat',' '           ⍝ My "name"; final space required.

    :endSection 2A. Initialization Phase to Define Run-time Utilities

    :section 2B. Initialization Phase to Define Compile-Time (Internal) Utilities

    ⍝ decHex2Num: Convert decimal string or hex string (with trailing [xX]) to number
      decHex2Num←{
          'xX'∊⍨⊃⌽⍵:h2d ⍵      ⍝ Shex → Idec
          ⊃⌽⎕VFI ⍵             ⍝ Sdec → Idec
      }
    ⍝ h2d:
    ⍝  "Takes unsigned numeric strings of form [\da-fA-F][xX]? and
    ⍝   returns decimal numbers."
      h2d←{                                   ⍝ Decimal from hexadecimal
          0=≢⍵:0                              ⍝ dec'' → 0.
          11::eConversion ⎕SIGNAL 11          ⍝ number too big.
          16⊥16|hexDigits⍳⍵∩hexDigits         ⍝ Ignore ⍵ not ∊ hexDigits
      }
    hexDigits←⎕D,'ABCDEF',⎕D,'abcdef'
    eConversion←'Number too large to convert to/from hexadecimal'

    ⍝ d2h:
    ⍝    "Takes one APL integer and returns a char vector representing a hexadecimal integer,
    ⍝     beginning with a decimal digit (0-9) and otherwise digits in 0-9A-F."
    ⍝     ∘ No X suffix is added to the hex result.
    ⍝        ⍺ omitted: Leading zeros are removed.
    ⍝        ⍺ present: Returns hex string of length ⍺. Any extra digits are truncated."
    ⍝     Requires: ⎕IO←0
      d2h←{⎕CT←0                              ⍝ Hexadecimal from decimal.
          ⍺←⊢                                 ⍝ Default: No width specification.
          0=⍵:,'0'
          1∊⍵=1+⍵:eConversion ⎕SIGNAL 11      ⍝ loss of precision.
          n←⍬⍴⍺,2*⌈2⍟2⌈16⍟1+|⍵                ⍝ default width.
          h←,hexDigits[(n/16)⊤⍵]              ⍝ character hex numbers.
          0≢⍺ 0:h                             ⍝ If ⍺ was set, don't remove or add leading 0's.
          h↓⍨←+/∧\h='0'                       ⍝ remove leading 0's unless only digit left.
          ('0'/⍨'ABCDEF'∊⍨1↑h),h              ⍝ If leading char is [A-F], prefix with 0.
      }
  ⍝ :Section 2B1. Regular expression (⎕R/⎕S) routines
    :namespace RE
        ⍝ RE.get:
        ⍝   "Returns pcre regexp field #⍵, if defined; else character nullstring."
        ⍝ call:
        ⍝   ns i←⍺ ⍵, ns@Ns i@I,  where fields ≥1 per pcre; 0 is the entire match.
        ⍝ returns:
        ⍝   field <i> from ⎕R-generated namespace <ns>, or '' if undefined (or inactive).
        ⍝
          get←{                       ⍝ Regexp get field by #. Returns '' if fld not defined.
              1<≢⍵:⍺ ∇¨⍵              ⍝ a b c← ⍺ get 1 2 3   vs   a←⍺ get 1
              ns i←⍺ ⍵
              i=0:ns.Match            ⍝ ⍵ get 0: get the full match...
              i≥≢ns.Offsets:''
              ¯1=ns.Offsets[i]:''     ⍝ field exists somewhere in the pattern (e.g. alternation), but not here!
              ns.Lengths[i]↑ns.Offsets[i]↓ns.Block
          }
        ⍝ RE.case: Usage:   case pat1,pat2    Returns 1 if ⍺.PatternNum is in the pattern list spec'd.
        ⍝   "For ⎕R namespace ⍺,
        ⍝    ∘ returns 1 if ⍺.PatternNum is in the list of pattern nums ⍵;
        ⍝    ∘ else 0"
          case←{
              ⍺.PatternNum∊⍵
          }

        ⍝ canon:
        ⍝   "Take regexp patterns in APL Strand "vector" format:
        ⍝      in:  'one. '   ' two a b c.'   '   3   '
        ⍝    removing spaces and strands added for readability."
        ⍝      out: 'one.twoabc.3'
          canon←{' '~⍨∊⍵
          }
    :EndNamespace
  ⍝ :EndSection 2B1.  Regular Expression Routines

       ⍝ setFormFieldChar:
       ⍝ Given a format field char of the form [CLR]ddd⍞str⍞...$,
       ⍝ converts str to the proper element based (in order) on
       ⍝   (1) Single Char    ⍞x⍞  or ⍞9⍞
       ⍝       If 1=≢str, use that char, even if a digit. I.e. '9' matches the character '9'.
       ⍝          To enter the Unicode number 9, enter '09' ('009' etc.).
       ⍝          In this version, the following may not be properly matched or handled:
       ⍝               (especially if not balanced):  ' " { } ( )
       ⍝          Use formats (2) or (3) for these (symbols or Unicode digits
       ⍝   (2) Multi-char Symbol   ⍞LP⍞
       ⍝       If SQ, DQ, SP, LP, RP, LB, RB, MD, KS, RC [see Note 1]:
       ⍝         SQ → '   DQ → "  SP → ' '  LP→ ( RP→ ) LB → {    RB → }   MD → ·    KS → '　'   RC→ �
       ⍝         'SingleQuote' 'DoubleQuote'  'Space'     'LeftParen'  'RightParen'
       ⍝         'LeftBracket' 'RightBracket' 'MiddleDot' 'KanjiSpace' 'ReplacementChar'
       ⍝   (3) Multi-digit Unicode  ⍞63⍞  ←-→ ⍞?⍞
       ⍝       - If digits ddd of length of at least 2, matches ⎕UCS ddd.  See Note 2.
       ⍝       - To include a single-digit unicode constant, prefix with 0: ⍞01⍞ uses (⎕UCS 1).
       ⍝         ⍞9⍞ inserts the character '9', equivalent to ⍞57⍞.
       ⍝       - To include hexadecimal, e.g. hex 100, specify ⍞⎕N100⍞ ←-→ ⍞64⍞.
       ⍝         (If the value may be 9 or under in decimal, be sure to prefix with 0).
       ⍝   (4) Otherwise, an error.
       ⍝ Note 1:
       ⍝ ∘ MD=middle dot.  ⎕U183 middle dot (·).
       ⍝ ∘ KS=Kanji-space ('　'). ⎕U12288 CJK-space,
       ⍝   wide space matching width of CJK ("Kanji") chars, similar to em-space.
       ⍝ ∘ RC=replacement char (used in Unicode as a replacement for invalid or unavailable chars)
       ⍝ Note 2:
       ⍝ ∘ The NULL (⎕UCS 0) character is mangled on output currently (Dyalog 16 on MacOS),
       ⍝   and when used in strings executed via ⍎, which format requires, so they are either
       ⍝   disallowed or managed via a kludge (see KLUDGE in 4a. below).

  ⍝ Form Field Character routines and data
      setFormFieldChar←{
          0=≢⍵:SPucs                           ⍝ No char specified, use space
          1=≢⍵:⎕UCS ⍵                          ⍝ Single char specified...
          uc←⊃(FFCharOut,⊂⍵)[FFCharIn⍳⊂,⍵]     ⍝ Name specified: Use the Unicode number as a text literal
          ' '=1↑0⍴uc:⊃⌽⎕VFI uc                 ⍝ See FFCharIn/Out below.
          uc
      }
  ⍝ Map symbolic names to numeric unicode.
  ⍝ If user specified a number instead of a name, it is used directly.
  ⍝ E.g.  '39' → numeric 39
    FFCharIn← 'SQ' '""'  'DQ' 'SP' 'LP' 'RP' 'LB' 'RB' 'MD' 'KS' 'RC'
    FFCharOut← 39  34 34 32 40 41 123 125  183 12288  65533

  ⍝ procFmtSymbols: processing basic formatting symbols and their escapes:
  ⍝     e.g. ⍎⋄, ⍎⍎  {{   }}
  ⍝ fmtSymbolDict:
  ⍝     "Dictionary mapping from special symbol combos to their values."
  ⍝ Mappings:
  ⍝    in     out                     in     out
  ⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯       ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  ⍝    ⍎⋄     linebreak               ⍎⍎     ⍎
  ⍝    {{     {                       }}     }
  ⍝    [[     [                       ]]     ]
  ⍝    ⍎>     unicode 12288 (space matching width of CJK chars [similar to em-space, but not so defined])
  ⍝ HANDLED ELSEWHERE:
  ⍝    {} and related      See processNullFArg. Handled separately.
  ⍝    ⍺N, ⍺⍺N             See procAlphas. Handled separately.
  ⍝    ⍠ and ⍠⍠            See <compile> pre-processing, routine <preprocessOptions>.
  ⍝
    _sd←('⍎⍎' '⍎')  ('⍎>' KANJI_SPACE) ('⍎⋄' LINE_BRK)
    _sd,← ('{{' '{') ('}}' '}')
    _sd,←  ('[[' '[')   (']]' ']')

    fmtSymbolDict←{{(⊃¨⍵)((⊃∘⌽¨⍵),⊂'**BADSYMBL**')},¨¨⍵}_sd
    ⍝ procFmtSymbols: "Process Symbols like ⍎⋄ ⍎⍎ {{ etc. as defined above."
      procFmtSymbols←{
          (1⊃fmtSymbolDict)⊃⍨(0⊃fmtSymbolDict)⍳⊂⍵~' '
      }

  ⍝ procSpaceFld: Format '{25}'
  ⍝ Description:  "Processes NullF argument if a non-neg integer (≥0)."
  ⍝ ∇ arg@S:/\s*\d*\s*/
    maxSFSpacing←999         ⍝ maxSFSpacing: If {nnn} has  nnn>maxSFSpacing, an error occurs
      procSpaceFld←{
        ⍝ {} or {0} signifies a null (space) field (creates a new field of 0-length).
          n←¯1↑⊃⌽⎕VFI ⍵
        ⍝ ..ss{nn}ss..  →  ..ss' 'spaces' 'ss...
          0=n:SQ,' ',SQ                                    ⍝ NullField
          (0≤n)∧n≤maxSFSpacing:SQ,' ',(enQ n⍴' '),' ',SQ   ⍝ (Non-null) Space Field
          ⎕SIGNAL/('Null Field spacing out of range [0..',(⍕maxSFSpacing),']: {',⍵,'}')11
      }

  ⍝ spaceFldP: {} | { \h+ } | { \d+ } (We grab { ¯\d+} in order to treat as error)
    spaceFldP←'(?<!\{)\{((?:\h*¯?\d*\h*))\}'  ⍝ ← Fld 1 is what is inside braces ONLY.

  ⍝ symbolsP: Symbols  with exception of spaceFldP,
  ⍝           e.g. ⍎⍎, ⍎⋄, {{ and }}
    symbolsP←RE.canon' (?| ( ⍎[>⍎] ) | ( \{ \{ ) | (\}\}) | ((?<!⍎) ⍎⋄)  ) '
    ⍝ procAllSymbols: "Process sequence for SpaceField (incl. NullField) and various symbols"
      procAllSymbols←{
          spaceFldP symbolsP ⎕R{
              s←⍵ RE.get 1
              ⍵ RE.case 0:procSpaceFld s
              procFmtSymbols s
          }⍵
      }

    ⍝ cvt2SQString ⍵@S:
    ⍝   "Convert a single- or double-quoted string to a single-quoted string,
    ⍝    handing any internal quotes."
    ⍝    ∘ If start- and end- quotes are SQ, return as is.
    ⍝    ∘ If both DQ, convert internal doubled DQs ("") to a single DQ ("),
    ⍝      convert internal single SQs (') to double, and return as SQ string.
    ⍝    ∘ If start and end quotes are different ('like this"), return error!
      cvt2SQString←{
          ⍺←⊃⍵
          ⍺≠⊃⌽⍵:('String has different start & end quotes: ',⍵)⎕SIGNAL 11
          SQ=⍺:⍵        ⍝ If already 'xxxx', do nothing!
          enQX deQX ⍵   ⍝ If "xxx""x'xx", convert to xxx"x'xx, then to 'xxx"x''xx'.
      }
    ⍝ enQ ⍵:   "enquote:
    ⍝           Put ⍵ between ⍺ (default: single) quotes. Don't scan for internal quotes."
      enQ←{
          ⍺←SQ
          ⍺,⍺,⍨⍵
      }
    ⍝ enQX ⍵:  "enquote and double internal SQs.
    ⍝           Put ⍵ between ⍺ (default: single) quotes. Scan and double internal quotes found."
      enQX←{
          ⍺←SQ
          ⍺,⍺,⍨⍵/⍨1+⍺=⍵
      }
    ⍝ enQXPlus ⍵: "enquote extra with spaces around string.
    ⍝              Like enQX, but include a space before and after quoted string."
      enQXPlus←{
          ⍺←SQ
          ' ',' ',⍨⍺ enQX ⍵
      }
    ⍝ deQX ⍵:   dequote and remove doubled quotes internal to string.
    ⍝          "Take quoted string, remove quotes, and convert doubled quotes to singletons.
    ⍝           The 1st char of string is assumed to be the quote and the first and last chars are removed."
      deQX←{
          ⍺←⊃⍵
          ⍵{⍵/⍨~⍵⍷⍨2⍴⍺}1↓¯1↓⍵
      }

    ⍝ selectUCSrc: "Process Unicode var ⎕Uddd[X] or literal ⎕⎕Uddd[x],
    ⍝    with various args (string vs. regexp namespace) and return values."
    ⍝ If ⍺=0, return ⍵:S
    ⍝ If ⍺=1, then ⍵@S. Process substrings matching unicodeP
    ⍝ If ⍺=2, then ⍵@NS is a ⎕R-generated namespace matching unicodeP
    ⍝ If ⍺=3, then ⍵@NS is unicode char w/ inside quotes.
      selectUCSrc←{
          charNullE←'⎕U0 (NUL) character is not allowed (Dyalog ⍎ bug)' 11
        ⍝ ALLOW_UNICODE_NULLS←1
          noNulls←~ALLOW_UNICODE_NULLS ⍝ If noNulls=1, treat ⎕U0 (NUL) as an error
        ⍝ STR→STR: ⍵@S. Result@S: same string. (I.e. do nothing).
          ⍺=0:⍵
        ⍝ STR→UNI: ⍵@S. Result@C1, Unicode char (within existing quotes).
          ⍺=1:unicodeP ⎕R{
              2 selectUCSrc ⍵
          }⍵
          double←2=≢⍵ RE.get 1
        ⍝ ⎕R→UNI: ⍵@Ns: ⎕R-generated. Result@C1: Unicode char (within existing quotes)
        ⍝         field1: ⎕ or ⎕⎕,  field2: digits
          ⍺=2:{
              double:1↓⍵ RE.get 0         ⍝ Saw ⎕⎕Uddd[X]; return ⎕Uddd[X]
              n←decHex2Num ⍵ RE.get 2
              noNulls∧0=n:⎕SIGNAL/charNullE
              ⎕UCS n  ⍝ Saw ⎕Uddd[X];  return ⎕UCS ddd (hex → dec)
          }⍵
        ⍝ ⎕R→'UNI': ⍵@Ns: ⎕R-generated. Result@S[3]: Unicode char w/added surrounding squotes.
        ⍝           fields: as for ⍺=2
          ⍺=3:{
              double:enQXPlus 1↓⍵ RE.get 0
              n←decHex2Num ⍵ RE.get 2
              noNulls∧0=n:⎕SIGNAL/charNullE
              enQXPlus ⎕UCS n
          }⍵
      }

    ⍝ procFmtExtensions:
    ⍝  "Process extensions to ⎕FMT based on prefixes C, L, R + int; and V (no int)"
    ⍝   Search a string for patterns looking like the pseudo-⎕FMT extensions:"
    ⍝      1. Center/Left/Right justification:
    ⍝                                     Cddd[⍞pad⍞] Lddd[⍞pad⍞] and Rddd[⍞pad⍞]
    ⍝         ⍞pad⍞, where ⍞ is any ⎕FMT delimiter pair (⍞⍞  ⎕⎕ ⊂⊃ <> ¨¨), and
    ⍝         pad is
    ⍝         - a single char (but not a quote or brace-- due to how we do parsing);
    ⍝         - a 2-digit or more unicode decimal value or the multi-char "names":
    ⍝         - SP: ' ', LB: '{', RB: '}', DQ: ", SQ: ', MD: (a mid-level small dot), KS: (Kanji/large space)
    ⍝         format 'F9.4,I6$⍵0' (1.1 2.2)  →    ('F9.4,I6'⎕FMT 1.1 2.2)
    ⍝
    ⍝      2. Treat Simple Vectors as Row vectors, not column vectors:
    ⍝                                     V
    ⍝      e.g.  t←1 3 5 ⋄ format 'V,I3$t'  ←-→  format 'I3,V$t' ←-→  format 'I3$$t'
    ⍝      See also format flag: $$ vs $.
    ⍝
      procFmtExtensions←{
        ⍝ fieldReset (fr) fieldWidth (fw) fieldType (ft) fieldPadN (fp) rowVec (rv)
          fr fw ft fp rv←⍺                ⍝ ⍺ has values of semi-globals fieldWidth fieldType fieldPadC rowVec
          str←formatExtensionsP ⎕R{
              f1 f2←⍵ RE.get¨1 2
              f1='V':''⊣rv∘←1              ⍝ Note:  0=≢f2:
            ⍝ f1 can only be C|L|R here.   ⍝ Only one is allowed per $/⎕FMT field...
              0≠≢ft:''⊣fr∘←1               ⍝ If fieldType already set (not null), set fieldReset←1, but don't update other vars.
              ft∘←¯1 1 0['LR'⍳1↑'C',⍨f1]   ⍝ Default is 0 (Center)
              fw∘←1↑⊃⌽⎕VFI f2              ⍝ fw=0 if invalid width
              fp∘←setFormFieldChar 1↓¯1↓⍵ RE.get 3
              ''
          }⊣⍵
          str(fr fw ft fp rv)             ⍝ str fieldReset fieldWidth fieldType fieldPadC rowVec
      }

    ⍝ setAlphaP: "Determine # of digits for an ⍺-variable, e.g. ⍺1. Following digits are treated as literals.
    ⍝             ⍠A1 is the default (allowing ⍺0..⍺9) (see below)."
    ⍝ ⍠A1: ⍺0..⍺9   ⍠A2: ⍺0..⍺99   ⍠A3: ⍺0..⍺999
    ∇ null←setAlphaP width;w
      w←⍕width←1⌈3⌊width                             ⍝ width forced to be between 1 and 3.
    ⍝ :external alphaP - a pattern that matches the desired ⍺n and ⍺⍺n patterns.
    ⍝ If ⍺⍺\d is seen, the ⍺⍺ → ⍺ (we don't need to check whether \d or \d{2,})
    ⍝ If ⍺\d+ is seen, we take <width> digits of \d+ as part of the ⍺-var.
    ⍝ If ⍺⍵ is seen, we treat it as ⍺DD, where the prior was ⍺(0⌈DD-1)
      alphaP←('⍺⍺ (?=\d) ')(' ⍺ (?: (\d{1,',w,'}) | ⍵)')~¨' ' ⍝  lit: ⍺⍺→⍺ or ⍺⍺123→⍺123; processed: ⍺9 or ⍺⍵
      null←''
    ∇

  ⍝ Set the default ⍠A1 here. Creates "global" pair of patterns alphaP. See ∇procAlphas∇.
    _←setAlphaP 1

    ⍝ procAlphas:
      procAlphas←{
          alphas←⍺                  ⍝ Make visible to ⎕R fn below
          ⎕PP←34                    ⍝ Make large for ⍕ below...
          ⍝ ⍠An: Forced between 1 and 3 in setAlphaP1
          str←'(?<!⍠)⍠A(\d)'⎕R{setAlphaP1⊃⌽⎕VFI ⍵ RE.get 1}⍵
     
          alphaP ⎕R{
              ⍵ RE.case 0:'⍺'
            ⍝ case 1:
              f1←⍵ RE.get 1
              ix←⊃⌽⎕VFI ⍵.CUR_ALPHA←{
                  reNs f1←⍵
                  0=≢f1:{0::'0' ⋄ ⍕1+⊃⌽⎕VFI ⍵.CUR_ALPHA}reNs
                  f1
              }⍵ f1
              ~ix∊⍳≢alphas:⍵ RE.get 0  ⍝ Unknown values → literal
              val←ix⊃alphas
              ⎕NULL≡val:⍵ RE.get 0     ⍝ ⎕NULL-- consider value "missing"
              ⍕val                   ⍝ Depends on ⎕PP above.
          }⊣str
      }

    ⍝ Dealing with sections
    ⍝ A section ends with ⍎→ or at the end of the string.
    ⍝ This simply breaks input lines into one or more lines at section breaks!
    ⍝ Then breaks sections into stacks (subsections of stacked components)
    ⍝ (Note: ⍎⍎ always means literal '⍎', so ⍎⍎→ is literal '⍎→', ditto ⍎⍎↓ as ⍎↓)
    ⍝
    ⍝ |...      section 1        ... |  ...      section 2        ...|
    ⍝  stack11 ⍎↓ stack12 ⍎↓ stack13 ⍎→ stack21 ⍎↓ stack22 ⍎↓ stack23
    ⍝          ↓                                       ↓
    ⍝          ↓                  becomes              ↓
    ⍝          ↓                                       ↓
    ⍝ section1 sections2 ← [stack11 stack12 stack13] [stack21 stack22 stack23]
    ⍝
      splitStackIntoSections←{
        ⍝ [2] split sections into stacks ← [1] Split a line into sections;
        ⍝ ⍎↓ at start of string is treated as NOP, not a null stack.
          {'⍎⍎↓' '^⍎↓' '⍎↓'⎕R'⍎↓' '' '\r\n'⊣⊂⍵}¨⊆'⍎⍎→' '⍎→'⎕R'⍎→' '\r\n'⊣⊂⍵
      }


    ⍝ preprocessOptions: "Matching and removing all ⍠Sc (where c is any character) in ⍵,
    ⍝                     replace in the source (input) text
    ⍝
    ⍝ ⍠Sc: replace all characters c with spaces and, simult., remove input spaces.
    ⍝                     Only the first c is used, but all matching ⍠Sc patterns are removed.
    ⍝                     Escapes... ⍠⍠Sc → ⍠Sc"
    ⍝ Set ⍺←1 to bypass ⍠S processing (e.g. if no ⍠ chars in input)
      preprocessOptions←{ ⋄ ⍺←0
          header←footer←⍬                   ⍝ ⍬= no header/footer; '' means 0-length
          ⍺:⍵ header footer                 ⍝ ⍺=1? No options (⍠), so return ⍵ as is.
          SP NL←' ' '' ⋄ fs←SP              ⍝ fs: faux space char.
          text←{
              fs=SP:⍵                       ⍝ Do no more processing if fs not set by user or set to SP.
              fs,⍨←'\'/⍨~fs∊∆ALPH           ⍝ Escape fs if not in a-zA-Z.  . → \., but B → B.
              fs SP ⎕R SP''⊣⍵               ⍝ fs→space and space→''
          }preOptionsP ⎕R{           ⍝ preOptionsP-- see below
              let val←⍵ RE.get¨1 2
              ⍝ A: Handled in procAlphas:
              ⍝⍝⍝ let='A':setAlphaP⊃⌽⎕VFI val
            ⍝ ⍠? "HELP" processing.
            ⍝ Option A: Service HELP request, then treat as a null, and continue normal processing.
            ⍝ Option B: Service HELP request, then signal 911 and allow processing as an Error/Non-std exit.
              let='?':''⊣Documentation.formatHelp ⍝'⍠? option: HELP displayed'      ⍝ Option A
              let='H':''⊣header∘←_compile 1↓¯1↓val   ⍝ ⊣msg 'header IN'val
              let='F':''⊣footer∘←_compile 1↓¯1↓val   ⍝ ⊣msg 'footer IN'val
              let≠'S':⎕SIGNAL/('Unexpected preprocessing option: ',⍵ RE.get 0)11
              fs∘←(fs=SP)⊃fs val             ⍝ Once fs has been set to anything but SP, changes are ignored.
              ''
          }⍵
          text header footer
      }

    ⍝ processSpecialNumbers: "Handles code of form ⎕N123 and ⎕N123X, as well as ⎕⎕N.
    ⍝          These are treated not as variables, but directly as numbers or text:
    ⍝             ⎕⎕N     →  '⎕N' literal
    ⍝             ⎕N123   →  '7B' conversion of 123 decimal to hexadecimal string. Leading 0s are removed.
    ⍝             ⎕N7BX   →  123  conversion of '7B' hexadecimal to decimal number.
    ⍝             Invalid numbers trigger an error.
    ⍝ Right now, we require ⎕N numbers to ALWAYS start with a digit in 0..9, even if HEX,
    ⍝ so there's no confusion between a pseudo-variable (e.g. ⎕NEEDX) and a number (⎕N0EEDX).
    ⍝ E.g.   ⍎C30⊂⎕N0FFFDX⊃$"Hello" is equiv. to ⍎C30⊂RC⊃$"Hello", where RC is the replacement char �
      processSpecialNumbers←{
          quadNP0 quadNP1 ⎕R{
              ⍵ RE.case 0:'⎕',⍵ RE.get 1       ⍝ ⎕⎕N → ⎕N
              ⍝ case 1:
              num hex←⍵ RE.get¨1 2
              0≠≢hex:⍕∊h2d num                 ⍝ HEX → DEC
              ∊d2h⊃⌽⎕VFI num                   ⍝ DEC → HEX
          }⍵
      }

    ⍝ postprocessStacks: "After each stacked component is compiled, we now
    ⍝    build and return the list of sections (with stacked
    ⍝    components flattened into a combo of components and stacking instructions)
    ⍝    The left-side stacked segment may set the options for the current stacking instruction.
    ⍝    That will become the default for the next. Returns a flattened string including all stacks."
    ⍝ Set ⍺=0 to require ∇ to execute in full. ⍺=1 skips option ⍠ processing...
    ⍝
    ⍝ Handles options ⍠[BCLR]. If there are NO stacked sections, these options are INVALID.
      postprocessStacks←{⍺←0
          noOpts←⍺
          opt←optT←'L' ⋄ box←''                        ⍝ Default for 'CLR' is 'L', left justified.
          ∊{
              '(',')',⍨∊(⍳≢⍵){
                  stk←{
                      noOpts:⍵      ⍝ We skip scan only if no ⍠ anywhere...
                      '(?<!⍠)⍠([BCLR])'⎕R{opt←⍵ RE.get 1
                          opt='B':''⊣box∘←'B'              ⍝ opt∊B
                          ''⊣optT∘←opt                     ⍝ opt∊LCR
                      }⊣⍵
                  }⍵
                  code←{
                      ⍺=0:'(',stk,')'
                      ' (',SQ,'V',box,opt,SQ,' ',∆masterNm,') (',stk,')'
                  }⍨⍺
                  opt∘←optT
                  code
              }¨⍵   ⍝ ⍵: stack1a stack1b ... stack1z
          }¨⍵       ⍝ ⍵: [ stack1a stack1b ... stack1z ] [stack2a stack2b ...]
      }

    ⍝ postprocessCleanup:   noOpts=1|0 ∇ string
    ⍝    Performs "final" cleanup and check of options etc.
      postprocessCleanup←{
          ⍺:⍵                                       ⍝ ⍺=1? No options (⍠), so return as is.
          postOptionsP ⎕R{pfx opt←⍵ RE.get¨1 2
              2=≢pfx:'⍠',opt                         ⍝ (⍠⍠)([a-zA-Z])      →   ⍠\2
              em1←'Option used in wrong context or with invalid value: '
              em2←'Option unknown: '
              em←em2 em1⊃⍨'BCLPSAHF'∊⍨⊃opt
              11 ⎕SIGNAL⍨em,⍵ RE.get 0
          }⍵
      }

  ⍝ balPat: generates a pattern that matches balanced parens or equivalent,
  ⍝         skipping embedded SQ strings, DQ strings.
  ⍝         ∘ Skips comments ⍝...
  ⍝         ∘ Skips "escaped" closing parens: ⍎)
  ⍝   ...P ← balPat '()'
    _bpCount←1    ⍝ Use the ctr to generate a unique name balNNN for referencing inside the pattern.
      balPat←{    ⍝ ⍵←L R where  L: left delimiter; R: right delim
          N←'bal',⍕_bpCount ⋄ _bpCount+←1     ⍝ local N- unique pattern-internal name.
          L R←⍵
          ∊'(?:(?J)(?<'N'>\'L'(?>[^\'L'\'R'"''⍝]+|⍝.*\R|(?:"[^"]*")+|(?:''[^''\r\n]*'')+|(?&'N')*)+(?<!⍎)\'R'))'
      }
    :endSection Initialization Phase B

    :Section 2C.   Initializing Patterns for (3)  Compilation Phases
    :Section 2C1.  Initializing Patterns for (3A) Compilation Main Loop
 ⍝↓ -----------------------------------------------------------------------------------------
 ⍝↓ Patterns required for Compiler Main Loop [includes building blocks for Subloop]
 ⍝⍝ Most patterns are "compiled" at namespace creation (fixing) for efficiency, and
 ⍝⍝ so that clearly written and spaced patterns have no run-time costs...
 ⍝↓ -----------------------------------------------------------------------------------------

  ⍝  Balanced patterns for parens, brackets, and braces...
  ⍝  These handle embedded quotes and the left and right bracket type, but ignore others.
  ⍝  So   ( [[ (abc[))  will match because the parens match-- the brackets are blissfully ignored.
  ⍝  That makes sense here.
  ⍝  _...P  e.g. _braceP  - patterns used within other patterns only
  ⍝   ...P  e.g. unicodeP - patterns used in Phases C1 and C1a (and, if noted, elsewhere)
    _parenP←balPat '()'⋄  _brackP←balPat '[]'
    _braceP←balPat '{}'⋄  codeFieldP←'(',_braceP,')'

  ⍝ Unicode ⎕U literals must start with a decimal digit 0..9, even if hexadecimal.
  ⍝ See also ⎕N literals.
    unicodeP←'(?i)(⎕{1,2})U(\d[\dA-F]*X|\d+)\.?'     ⍝ Handle both ⎕U... Unicode and ⎕⎕U... literals.

  ⍝ _optFmtPfxP: "Format prefixes are a pseudo-extension to ⎕FMT left arg,
  ⍝               terminated by a $ suffix, i.e. $ must be used in place of ⎕FMT for this purpose.
  ⍝               See <procFmtExtensions> for details. Here we simply accommodate anything fitting
  ⍝               the basic format of ⎕FMT's left arg.
    _fmtQuoteP←'⍞[^⍞]*?⍞ | ⎕[^⎕]*?⎕ | <[^>]*?> | ⊂[^⊃]*?⊃ | ¨[^¨]*?¨'
  ⍝ _aplFmtP: matches most or all ⎕FMT left args and permissively passes through ill-formed specs to ⎕FMT
    _aplFmtP←'(?: [A-Z\d\.\,¯]+ | '_parenP' | '_fmtQuoteP' )+'
    _qStringP←'(?: "[^"]*" )+ | (?: ''[^'']*'')+'

    _fmtPfx0P←_aplFmtP' | '_qStringP' |'
    _quadFMT← '\h* (\${1,2} | ⎕FMT )\h*'
  ⍝ _optFmtPfxP: See also fmtPfx1aP below.
    _optFmtPfxP←'(?: (?: ' _fmtPfx0P ') ' _quadFMT,' )?'

    _fnP←'[+\-×÷*⍟⌹○!?|⌈⌊⊥⊤⊣⊢=≠≤<>≥≡≢∨∧⍲⍱↑↓⊂⊃⊆⌷⍋⍒⍳⍸∊⍷∪∩~/\\⌿⍀,⍪⍴⌽⊖⍉¨⍨⍣.∘⍤@⌸⌺⍎⍕&\[\]]+'
    _numP←'(?: ¯? (?: \d+ (?:\.\d*)? | \.\d+ ) (?: [eE]¯?\d+)? )'
    _numVecP←'(?: ' _numP ' (?: \h+' _numP ')* )'

    _codePfxP←'(?: '_parenP '|' _numVecP '|' _fnP ')*'

  ⍝ _omegaP: special meaning with ⍎ or {}:  ⍵⍵ or ⍵1..⍵99 etc. ⍵⍵3 accepted as <⍵⍵><3>
    _omegaP←'⍵(⍵|\d{1,2})? '_brackP'?'      ⍝ We allow simple '⍵', which we let APL handle as a var.
    _varP←'(?: (?:\#{1,2} | ⎕?[_\pL]\p{Xwd}*) (?:\.(?:\#{1,2} | ⎕?[_\pL]\p{Xwd}*))* '_brackP'? )'
    _stringP←'(?: (?: "[^"]*" )+ | (?: ''[^'']*'' )+   )'
    _nameLitP←'( '_omegaP' | '_varP' | '_stringP' )'   ⍝ F2 is the name or "..."/'...'

    nameFieldP←RE.canon'⍎(' _optFmtPfxP _codePfxP   _nameLitP ')'

  ⍝ preOptionsP: options handled in preprocessOptions
  ⍝ ⍠S.  ⍠A[123]  ⍠H⊂...⊃  ⍠F⊂...⊃
    preOptionsP←RE.canon '(?<!⍠) ⍠ (?| (\?) | (S)(.) | (A)([123]) | ([HF]) ('_fmtQuoteP ') )' ⍝ See preprocessOptions

  ⍝ quadNP0/1: Special system "variables" handled in processSpecialNumbers
  ⍝ ⎕N\d+ (A decimal # converted to hex string)
  ⍝ ⎕N[\dA-Fa-f]+ (a hexadecimal # converted to decimal).
  ⍝ See also Unicode variables: ⎕U\d[\dA-Fa-f]*
  ⍝     field1: hex_number; field2: X/x or ''
    quadNP0←RE.canon '⎕⎕([Nn])'
    quadNP1←RE.canon'⎕[Nn] (?| (\d[\da-fA-F]*)([Xx]) | (\d+) ()\.? )'

  ⍝ postOptionsP: Handle options in prostProcessCleanup (q.v.) which were not handled elsewhere.
  ⍝ Those not escaped (⍠⍠X) are treated as errors.
  ⍝ We assume options are of the form ⍠\pL, unless a 2nd ⍠ precedes.
    postOptionsP←RE.canon'(?| (⍠⍠) (\pL) | (⍠) ([SA].| \pL)   )'

    :endSection 2C1. Initializing Patterns for (3A) Compiler Main Loop

    :Section 2C1A. Initializing Patterns for (3B) Compiler Subloop

    formatExtensionsP←RE.canon',? (?| ([CLR])(\d+) | (V))(',_fmtQuoteP,')?,?'
    quoteStringP←RE.canon'(',_qStringP,')'
  ⍝ Match ⍵⍵ (next ⍵) or ⍵\d+ (\d+ ⊃ ⍵).
  ⍝ # of digits matched is set by _omegaP, not omegaP
    omegaP←RE.canon '⍵ (?:⍵ | (\d+) )'    ⍝ field1 matches digits, not 2nd ⍵
  ⍝ fmtPfx1aP is similar to optFmtPfxP, except the former is optional and
  ⍝      the latter captures the format string (either quoted or unquoted),
  ⍝      so the string can be processed correctly (with "..." → '...', etc.).
    fmtPfx1aP←RE.canon'(' _fmtPfx0P ')' _quadFMT       ⍝ Last alternate: monadic $ (⎕FMT)

    skipSQP←''''
    newlineP←'(?<!⍎)⍎⋄'    ⍝ Newlines in code are handled differently, as codestring (⎕UCS 13)

⍝↑ -----------------------------------------------------------------------------------------
⍝↑ END patterns for Compilation Subphase C1a
⍝↑ -----------------------------------------------------------------------------------------
    :endSection 2C1A. Initializing Patterns for (3B) Compilation Subloop
    :EndSection 2C. Initializing Patterns for (3) Compilation Phases

    :endSection 2. Initialization

    :section 3. Compilation Phase - Main Scan of Format String
    ⍝  compile and _compile
    ⍝  compile: a cover function, returns a complete executable (⍎) string including any user right args.
    ⍝ _compile: a compilation engine, may be called repeatedly, even recursively.

    ⍝ _compile:
    ⍝     "format each substring or section... Returns the string alone.
    ⍝      ∘ See also "compile" below.
      _compile←{
          CUR_OMEGA←0
          ⍬≡⍵:⍵         ⍝ numeric null ⍵ means bypass compilation. Different from ''
          str←⍵
          str←processSpecialNumbers str
          str←spaceFldP symbolsP codeFieldP nameFieldP skipSQP unicodeP ⎕R{
      ⍝ CASE: nl        sy       cf         nf         qu      un
              nl sy cf nf qu un←⍳6
              ⋄ CASE←⍵.PatternNum∘∊
              ⋄ s1←⍵ RE.get 1             ⍝ normally s1 is the string matched, but it varies.
     
              CASE nl:procSpaceFld s1    ⍝ s1 is the digits or blanks inside {  [\s\d]* }
              CASE sy:procFmtSymbols s1
              CASE un:2 selectUCSrc ⍵ ⍝ Unquoted Unicode value
              CASE qu:''''''
     
               ⍝⍝ CFs/NFs: Only continue if named fields and code fields (NF's, CF's)
               ⍝⍝ pn ∊ nf cf → continue
              ~CASE nf cf:⎕SIGNAL/'Logic Error: unexpected patternNum' 11
              s1←{
                  s2←{'{'=⊃⍵:1↓¯1↓⍵ ⋄ ⍵}⍵   ⍝ Remove braces if CF...
     
              ⍝ :section 3 A.Compilation Subloop-Scan of NameFields,Code Fields and Related
              ⍝↓ ----------------------------------------------------------------------------
              ⍝↓ 3A. Scan Namefields (⍎...), Codefields {code} and Related:
              ⍝⍝     Spacefields {5} and Nullfields {}
              ⍝↓ ----------------------------------------------------------------------------
     
                  ⍝⍝ Compilation Phase (1a) - for Name Fields & Code Fields
                  ⍝⍝ fieldType is 0-length if not set, else ¯1 0 1
                  fieldType(fieldReset fieldWidth fieldPadN rowVec)←⍬ 0
     
                  s2←fmtPfx1aP unicodeP quoteStringP omegaP newlineP ⎕R{
             ⍝ CASE: fm1       un1      qu1          om1    nl1
                      fm1 un1 qu1 om1 nl1←⍳5
                      ⋄ CASE←⍵.PatternNum∘∊
                      ⋄ field1 fmtIn←⍵ RE.get¨1 3
                      ⋄ ∆FMTx←fmtIn∘{⍵:∆FMTxNm ⋄ ⍺≡'$$':∆FMTxNm ⋄ '⎕FMT '}
     
                      CASE nl1:'(⎕UCS 13)'
                      CASE fm1:{
                          0=≢⍵:∆FMTx 0
                          s←{(⊃⍵)∊SQ,DQ:1↓¯1↓⍵ ⋄ ⍵}⍵
                          ⋄ fldArgs←fieldReset fieldWidth fieldType fieldPadN rowVec
                          s fldArgs←fldArgs procFmtExtensions s
                          ⋄ fieldReset fieldWidth fieldType fieldPadN rowVec∘←fldArgs
     
                          fieldReset:('field padding already Unicode:',(fieldType),'. Not changed.')⎕SIGNAL 11
     
                          0=≢s~' ':∆FMTx rowVec
                          (enQXPlus s),∆FMTx rowVec
                      }field1
                      CASE un1:3 selectUCSrc ⍵
     
                      CASE om1:{pfx sfx←'(⍵⊃⍨⎕IO+' ')'
                          0=≢⍵:pfx,sfx,⍨CUR_OMEGA∘←{0::'0' ⋄ ⍕1+⊃⌽⎕VFI ⍵}CUR_OMEGA ⍝ ⍵⍵
                          ⋄ ⋄ pfx,sfx,⍨CUR_OMEGA∘←⍵                        ⍝ ⍵(\d+):  ⍵: only the digits!
                      }field1
     
                    ⍝ Quoted strings
                    ⍝ unicodeInQuotes←1|0: Set to 1 if you want Unicode processing ⎕Uxxx in quotes.
                      unicodeInQuotes←1    ⍝ ∊ 0 1
                      CASE qu1:unicodeInQuotes selectUCSrc cvt2SQString procAllSymbols field1
                      ⎕SIGNAL/('format logic error: pn1=',⍕pn1)999
                  }⊣s2
                ⍝ :Endsection 3A.Compilation Subloop
     
                ⍝ Do we have a positional fmt prefix?
                ⍝     Of the form  [CLR]ddd(⊂...⊃)?
                ⍝ NO  ---→ return s2
                  fieldWidth≤0:s2
                ⍝ YES ---→ Call ¨∆pad¨ on s2, e.g.
                ⍝ ∆pad syntax:  fieldWidth@I fieldType@CS padChar@CS ∇ matrix@SM
                ⍝   (    12               'C'                  ' '           ∆pad         s2)
     
                  larg←⍕fieldWidth fieldType fieldPadN
     
                  ∊'( ',larg,' ',∆padNm,' ',s2,' )'
              }s1
              ''' (',s1,') '''                  ⍝ 'a...{c}...b' →  'a...' (c) '...b'
          }⊣str
          '''','''',⍨str
      }

    ⍝ compile:  Format main compile code as executable string:
    ⍝             { ∆cat ('string') }⊃⌽êçR
    ⍝           ∆cat: fully-specified name of service routine <∆cat>.
    ⍝           string: the fully-compiled format string.
    ⍝           êçR:    original right argument (normalized) to <format>.


      compile←{
          alphas←⍺
     
          text←⍵
          text←alphas procAlphas text        ⍝ Note: ⍺'s may contain any code, including ⍠... and ⍎...
          ⋄ noOpts←~'⍠'∊text                    ⍝ If no ⍠, we will skip checks below for ⍠ args
          ⋄ noStacks←~1∊∊'⍎→' '⍎↓'⍷¨⊂⍵          ⍝ If no ⍎→ or ⍎↓, we will skip checks for "stacks"
     
          text header footer←noOpts preprocessOptions text
     
          text←noOpts postprocessCleanup noStacks{
              ⍺:_compile ⍵                    ⍝ _compile¨¨  :compile each stack of each section separately...
              noOpts postprocessStacks _compile¨¨splitStackIntoSections ⍵
          }text
     
        ⍝ Handle ⍠H/⍠F, headers and footers.
          text←header{0=≢⍺:⍵ ⋄ hd tx←⍺ ⍵ ⋄ '(',hd,')',∆overNm,tx}text
          text←footer{0=≢⍺:⍵ ⋄ ft tx←⍺ ⍵ ⋄ '(',tx,')',∆overNm,ft}text
     
          '{',∆catNm,text,'}⍵'
      }
    :endsection 3. Compilation Phase

    :section 4. Executive Function: ∆format
⍝↓ -----------------------------------------------------------------------------------------
⍝↓ Executive: Generate ∆format, ##.∆format, and ##.∆f
⍝↓ -----------------------------------------------------------------------------------------

    :section 4a. Executive Function: Kludges
    ⍝ Set up kludgey code to handle user's user of nulls.
    ⍝ Dyalog APL improperly handles string with null chars, so
    ⍝ we just hide them during compilation, if ALLOW_UNICODE_NULLS=1.
    NULLucs VISIBLE_NULLucs FAUX_NULLucs←⎕UCS 0 9216 57345
    nullMagicIn←{⍺←1 ⋄~ALLOW_UNICODE_NULLS: ⍵ ⋄ (VISIBLE_NULLucs FAUX_NULLucs⊃⍨0≠⍺)@(NULLucs∘=)⊣⍵}
    nullMagicOut←{~ALLOW_UNICODE_NULLS: ⍵  ⋄ NULLucs@(FAUX_NULLucs∘=)⊣⍵}
    :endSection 4a. Executive Functions: Kludges

    :section 4b. User-callable functions: ∆format, ∆f
      ∆format←{
          0::⎕SIGNAL/⎕DMX.(('∆format ',EM,(': '/⍨0≠≢Message),Message)EN)
          ⍺←1
          ⍺{
              ø←⍺{⍺≠2:⍵ ⋄ ⎕←'∆format'({enQX ⍵}(⊃⍵))(1↓⍵)}⍵
              ⍺=0:0 nullMagicIn(⊃1↓⍵)compile(⍕⊃⍵)
              nullMagicOut(⊃⌽⍵)((⎕RSI⊃⍨1+⎕IO){ ⍝ [1] Set ⎕PATH to include the format library (1 lvl up).
                  ⍝ ⎕PATH←⎕PATH,' ',⍕⊃⎕RSI     ⍝     To ensure ⎕PATH remains local, set via ←, not ,←
                  ⍺⍺.⍎⍺                        ⍝ [2] ⍺ must execute in ⍺⍺, the ns that called ∆f/ormat
              })⍨nullMagicIn(⊃1↓⍵)compile(⍕⊃⍵) ⍝     requiring ⎕PATH to find formatPath per [1].
          }{
              1≥|≡⍵:⍵ ⍬ ⋄ (⊃⍵)(1↓⍵)
          }⍵
      }
    ∆f←∆format                                 ⍝ ∆f is an alias for ∆format.

    :endSection 4b. User-callable functions: ∆format ∆f
    :endSection 4. Executive Functions: ∆format ∆f

   ⍝ Namespace ∆STD -- useful?
    :Namespace ∆STD
        ##.msg (⍕⎕THIS),': Namespace is undocumented'
      ⍝ NOT YET DOCUMENTED...
        Months←'January' 'February' 'March' 'April' 'May' 'June' 'July' 'August' 'September' 'October' 'November' 'December'
        Mo←3↑¨Months
        MO←  1 (819⌶) Mo
        mo←  0 (819⌶) Mo
        DayOfWeek←'Sunday' 'Monday' 'Tuesday' 'Wednesday' 'Thursday' 'Friday' 'Saturday'
        Dow←3↑¨DayOfWeek
        DOW←1 (819⌶) Dow
        dow←0 (819⌶)  Dow
    :EndNamespace

    :Section Exporting ∆f, ∆format, formatPath
   ⍝ Only export functions and operators here!
    0 ⎕EXPORT ⎕NL 3 4
    1 ⎕EXPORT '∆f' '∆format' 'formatPath'
    msg'Exporting:',∊' ',¨' '~⍨¨{⍵/⍨⎕EXPORT ⍵}↓ ⎕NL 3 4

    :EndSection Exporting ∆f, ∆format, formatPath


    :Namespace Documentation
        :Section 1B.   Documentation

        ∇ r←README
⍝ format.Documentation.README
⍝ The format has one major user function ∆format or ∆f.
⍝     ∆format or ∆f-
⍝        useful for displaying a mix of multi-line text, APL arrays (optionally using
⍝        APL dyadic format options and extensions) with headers and footers. Objects
⍝        are automatically converted to matrix formats and appropriately padded when
⍝        catenated horizontally or vertically.
⍝        Unicode and hexadecimal numbers are concisely supported.
⍝        See notes_format for details.
⍝ There is one auxiliary function which must be found when ∆format/∆f is executed:
⍝     formatPath-
⍝        This is called as part of service routines executed in ∆format/∆f.
⍝        Since the resulting format string is executed in the user's namespace,
⍝        format (e.g. #.format or ⎕SE.format) must be in ⎕PATH at that time.
⍝        WHen found, formatPath returns the specific path in format, so no other
⍝        utility functions need be exported to clutter the user namespace.
⍝
⍝ For HELP information, type  ∆format '⍠?'         ⍝ Note: ⍠? is typed `??
⍝ Source file for formatHelp.pdf is  https://goo.gl/QaNsWq
          r←{⍵⊣⎕ED'ed'⊣ed←' ',↑1↓¨nr/⍨∊'⍝'=1↑¨nr←⎕NR ⍵}⊃⎕SI
        ∇
        ∇ r←formatHelp;head;body
          :Trap 0
              ⎕SH'open formatHelp.pdf'
              r←⎕←'formatHelp: complete'
          :Else
              r←⎕←'formatHelp: Unable to find/display formatHelp.pdf info in default directory.'
              head←'<head><title>Format </title><head>'
              body←'<iframe src="//goo.gl/QaNsWq" width="1400" height="1400"></iframe>'
              'hr'⎕WC'HTMLRenderer'(head,body)('Size'(500 500))
          :EndTrap
        ∇
        :endSection 1B. Documentation
    :EndNamespace
    ∇ {r}←HELP
      r←Documentation.formatHelp
    ∇
    msg '>>> For overview, see            "',(⍕formatPath),'.Documentation.README"'
    msg '>>> Documentation is in          "formatHelp.pdf"'
    msg '>>> Source doc is in Google Docs "//goo.gl/QaNsWq"'
:endNamespace
