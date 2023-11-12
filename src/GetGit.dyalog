 GetGit←{
    ⍝ GetGit filespec
    ⍝    filespec:  [file:// | https:// | http:// | ws:// | obj:// | [no prefix]]
    ⍝    If no prefix is specified, obj:// is assumed.      ¯¯¯¯¯¯  
    ⍝ Return the text of ...
    ⍝   a)  file on local disk (file://),
    ⍝   b)  object(s) to be copied from a local workspace (ws://ws fn)  (e.g. ws://dfns cmpx X)
    ⍝       in an executable form:  objName← value etc.
    ⍝       Returns 1 (enclosed) object for each object specified after the ws name.
    ⍝   c1) text on a web page (http:// or https:// not followed by github.com or //raw.github...
    ⍝   c2) a github text file (also https:// or http://, but followed by
    ⍝       a sequence starting with github.com/ or raw.githubusercontent.com/
    ⍝   d)  an APL object in the currently active user namespace.
    ⍝       The text will be an executable of the form
    ⍝            name← (executable code)
    ⍝ Returns:
    ⍝       the text as a vector of character vectors (lines)
    ⍝ If the file is not found or an error occurs, a ⎕SIGNAL is generated.

    ⍝ filespec← 'https://github.com/petermsiegel/pmsLibrary/blob/master/src/Concord.dyalog'
    ⍝ actually retrieves:
    ⍝           'https://raw.githubusercontent.com/petermsiegel/pmsLibrary/master/src/Concord.dyalog'

  6 11 22::⎕SIGNAL⊂⎕DMX.(('Message'Message)('EM'EM)('EN'EN))
    filespec← ⍵
    fiPfx httpsPfx httpPfx wsPfx objPfx←'file://' 'https://' 'http://' 'ws://' 'obj://'
    isFi isHTTPS isHTTP isWS isObj←1∊¨(⊂filespec)⍷⍨¨fiPfx httpsPfx httpPfx wsPfx objPfx 
    gitHdrs←'//github.com/' '//raw.githubusercontent.com/'
    APLObj← 1∘(~∊)'://'∘⍷
    GetObj← { ⍺← ⊃⎕RSI
          nc←⍺.⎕NC ⍵
        ¯1 0∊⍨nc:   ⎕SIGNAL⊂('Message' 'Invalid or missing APL object')('EN' 11)
        3 4∊⍨⍺.⎕NC ⍵: ⍺.⎕NR ⍵
        0::         ⎕SIGNAL⊂('Message' 'Unable to get value of APL object')('EN' 11)
        ⍝ Get an executable form of the value of object ⍵
          ⍵,'←',⎕SE.Dyalog.Array.(0∘Deserialise 1∘Serialise)⍺.⍎ ⍵
    }
    GetFromWs←{ NL←⎕UCS 10
          SplitA← {' '(≠⊆⊢)⍵}
          SplitF← {(SplitA p↓t)(t↑⍨p←' '⍳⍨t←⍵↓⍨+/∧\⍵=' ')}
          obj ws ← SplitF ⍵↓⍨≢wsPfx
        0=≢ws: ⎕SIGNAL⊂('EN' 11)('Message' 'No workspace was specified')
        0=≢obj: ⎕SIGNAL⊂('EN' 11)('Message' 'No objects were specified. Nothing copied from ws')
          ⊃⍪/{ns∘GetObj ⍵}¨obj⊣ obj (ns←⎕NS⍬).⎕CY ws  
    }
    GetFromURL←{
        11::⎕SIGNAL⊂⎕DMX.{e←'EN' 'EM',⍥⊂¨EN EM
            ∨/6 22∊⍨⊃⌽⎕VFI ¯3↑Message:e,⊂'Message' 'URL not found' ⋄ e,⊂'Message'Message
        }⍬
          DQ←'"'∘,,∘'"'
          GetFromGit←{BOM←⎕UCS 65279   ⍝ BOM: Byte Order Mark translated to invalid Unicode char.
              UTF8In←'UTF-8'∘⎕UCS∘⎕UCS
              gitTxt←'//github.com/' '/blob/'⎕R'//raw.githubusercontent.com/' '/'⊣⍵
              r←UTF8In¨⎕SH'Curl --fail ',DQ gitTxt   ⍝ --fail: 404 errors => (desired) Curl failure
            BOM≠⊃⊃r:r ⋄ r⊣(0⊃r)←1↓0⊃r  ⍝ Remove any BOM
          }
        1∊∊gitHdrs⍷¨⊂⍵:GetFromGit ⍵
          ⎕SH'Curl ',DQ ⍵
    }

    APLObj filespec: GetObj filespec
    isObj:           GetObj filespec↓⍨ ≢objPfx
    isFi:            ⊃⎕NGET(filespec↓⍨ ≢fiPfx)1
    isWS:            GetFromWs filespec
    isHTTPS⍱isHTTP:  ⎕SIGNAL⊂('EN' 11)('Message' 'Unrecognized file specification prefix')
    ⍝ http:... or https:... could be standard http or github texts
      GetFromURL filespec
 }
