 GetObj←{
  ⍝ GetObj [filespec//]object(s)
  ⍝    filespec:  [file://fileId | https://url | http://url |
  ⍝                ws://wsid objs | obj://objs   | objs       ]
  ⍝    If no prefix is specified, obj:// is assumed.
  ⍝    fileId - fully qualified or relative filename.
  ⍝    url-     the url of a web page or a github document.
  ⍝    wsid-    a standard Dyalog apl workspace identifier
  ⍝    objs-    one or more space-separated objects
  ⍝ Return the text of ...
  ⍝   a)  file on local disk (file://),
  ⍝   b)  object(s) to be copied from a local workspace (ws://ws fn)  (
  ⍝            e.g. ws://dfns cmpx X
  ⍝       in an executable form:  objName← value etc.
  ⍝       Returns 1 or more objects, o, in executable form.
  ⍝          Objects returned as for: d) APL object(s)
  ⍝   c1) text on a web page (http:// or https:// not followed by github.com or //raw.github...
  ⍝   c2) a github text file (also https:// or http://, but followed by
  ⍝       a sequence starting with github.com/ or raw.githubusercontent.com/
  ⍝   d)  APL object(s) in the currently active user namespace.
  ⍝       Returns 1 or more (enclosed) objects, o, in executable form.
  ⍝       * Non-fns will be in the form name←(...value...) per Dyalog 0∘Deserialise format 
  ⍝       * Dfns/ops are returned in ordinary ⎕NR format
  ⍝       * Tradfns/ops are returned in ⎕NR format with a prefixed and suffixed ∇
  ⍝
  ⍝ Github test file...
  ⍝   filespec← 'https://github.com/petermsiegel/pmsLibrary/blob/master/src/Concord.dyalog'
  ⍝   actually retrieves:
  ⍝             'https://raw.githubusercontent.com/petermsiegel/pmsLibrary/master/src/Concord.dyalog'
      ⎕IO←0
    6 11 22::⎕SIGNAL⊂⎕DMX.(('Message'Message)('EM'EM)('EN'EN))
      filespec← ⍵
      fiPfx httpsPfx httpPfx wsPfx objPfx←'file://' 'https://' 'http://' 'ws://' 'obj://'
      isFi isHTTPS isHTTP isWS isObj←1∊¨(⊂filespec)⍷⍨¨fiPfx httpsPfx httpPfx wsPfx objPfx
      gitHdrs←'//github.com/' '//raw.githubusercontent.com/'
      APLObj←1∘(~∊) '://'∘⍷
      Split←' '∘(≠⊆⊢),                   ⍝ Trailing comma (,) ensures valid split of a single char.
      GetObj←{ 
          ⍝ Return dfns/ops, tradfns/ops, and variables differently
          ⍝ dfns:      Form VV: nm←{...}
          ⍝ tradfns:   Form VV: ∇ ... nm ... ∇
          ⍝ variables: Form V:  nm←( Dyalog Deserialise format ) 
            ⋄ objNmÊ←  ⊂('Message' 'Invalid or missing APL object name')('EN' 11)
            ⋄ objValÊ← ⊂('Message' 'Unable to get value of APL object')('EN' 11)
            ⍺←⊃⎕RSI ⋄ nc←⍺.⎕NC⊂,⍵
          ¯1 0∊⍨nc: ⎕SIGNAL objNmÊ
          3.2 4.2∊⍨ nc: ⍺.⎕NR ⍵             
          3.1 4.1∊⍨ nc: fn⊣ (⊃⊃fn)← (⊃⊃⌽fn)← '∇' ⊣ fn←' ',⍨¨ ' ',⍨ ⍺.⎕NR ⍵  
          0:: ⎕SIGNAL objValÊ
            ⍵,'←',⎕SE.Dyalog.Array.(0∘Deserialise 1∘Serialise)⍺.⍎⍵  ⍝ Form nm←(...)
      }
      GetFromWs←{
          ⋄ wsObjNmÊ← ⊂('EN' 11)('Message' 'Missing ws or object names')
          BareNm← {⍵↑⍨ -'.'⍳⍨ r← ⌽⍵ }
          ws_oS← Split ⍵
        2>≢_: ⎕SIGNAL wsObjNmÊ
          ws oV← (⊃ws_oS) (1↓ ws_oS)
          ns∘GetObj∘BareNm¨ oV ⊣ oV (ns← ⎕NS ⍬).⎕CY ws
      }
      GetFromURL←{
          11:: ⎕SIGNAL ⊂⎕DMX.{e←'EN' 'EM',⍥⊂¨ EN EM ⋄ et← ⊃⌽⎕VFI ¯3↑Message
            et∊ 6 22: e, ⊂'Message' 'URL not found' ⋄ e, ⊂'Message'Message
          }⍬
          DQ← '"'∘, ,∘'"'
          GetFromGit← {BOM←⎕UCS 65279   ⍝ BOM: As xlated to "invalid Unicode" char per UTF-8.
              UTF8In← 'UTF-8'∘⎕UCS∘⎕UCS
              gitTxt← '//github.com/' '/blob/'⎕R' //raw.githubusercontent.com/' '/'⊣ ⍵
              ⍝ Curl --fail: Treat '404 Not Found' as a signaled error.
              r←UTF8In¨ ⎕SH'Curl --fail ', DQ gitTxt
              r⊣ (0⊃r)← (0⊃r)↓⍨ BOM= ⊃⊃r   ⍝ Remove any BOM from 1st record.
          }
          1∊ ∊gitHdrs⍷¨ ⊂⍵: GetFromGit ⍵
          ⎕SH 'Curl ', DQ ⍵
      }

      APLObj filespec: GetObj¨ Split filespec
      isObj:           GetObj¨ Split filespec↓⍨≢objPfx
      isFi:                 ⊃⎕NGET  (filespec↓⍨ ≢fiPfx)1
      isWS:               GetFromWs  filespec↓⍨ ≢wsPfx
          ⋄ pfxÊ←⊂('EN' 11)('Message' 'Unrecognized file specification prefix')
      isHTTPS⍱ isHTTP: ⎕SIGNAL pfxÊ
          GetFromURL filespec     ⍝ std http/s or github text files
 }
