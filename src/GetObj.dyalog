 GetObj←{
  ⍝ [opts] GetObj [filespec//]object(s)
  ⍝    filespec:  [file://fileId | https://url | http://url |
  ⍝                ws://wsid objs | obj://objs   | objs       ]
  ⍝    If no prefix is specified, obj:// is assumed.
  ⍝    fileId - fully qualified or relative filename.
  ⍝    url-     the url of a web page or a github document.
  ⍝    wsid-    a standard Dyalog apl workspace identifier
  ⍝    objs-    one or more space-separated objects
  ⍝ Return the text of one of the following 
  ⍝                          (filedesc is a file specification, obj is an APL obj name)
  ⍝   a)  file://filedesc  
  ⍝       file on local disk,
  ⍝   b1) http://filedesc or https://filedesc  
  ⍝       text on a web page 
  ⍝   b2) https://github.com/... or https://raw.githubusercontent.com/... or
  ⍝        http://github.com/... or  http://raw.githubusercontent.com/...
  ⍝       Github files will be processed as if the git: prefix (b3) was applied,
  ⍝       but http:// is allowed, not just https://.
  ⍝   b3) git://userid/directory/.../obj.type OR git://github.com/... or git://raw.git... 
  ⍝       a github text file.
  ⍝       The prefix '//raw.githubusercontent.com' will be added automatically.
  ⍝       If the file is encoded (a "blob"), it will be decoded for you. 
  ⍝       git:// will be replaced by https:// prefix for the transaction.
  ⍝   c)  ws://ws obj1 [obj2...]
  ⍝       object(s) to be copied from a local workspace 'ws'
  ⍝            e.g. ws://dfns cmpx X
  ⍝       in an executable form:  objName←(...), objName← {...}
  ⍝       Returns 1 or more objects, o, in executable form.
  ⍝          Objects returned as described for: d) APL object(s)
  ⍝       autodisclose may apply.
  ⍝   d)  obj://obj1 [obj2...] or  
  ⍝       (with no prefix) obj1 [obj2...]
  ⍝       APL object(s) in the currently active user namespace.
  ⍝       Returns 1 or more (enclosed) objects, o, in executable form.
  ⍝       * Non-fns will be in the form name←(...value...) per Dyalog 0∘Deserialise format 
  ⍝       * Dfns/ops are returned in ordinary ⎕NR format
  ⍝       * Tradfns/ops are returned in ⎕NR format with a prefixed and suffixed ∇
  ⍝       autodisclose may apply.
  ⍝
  ⍝ opts: autodisclose  
  ⍝       autoDisclose← 0   If 1, if there is one object to be returned (c or d above),
  ⍝                         disclose it. If 0, return enclosed, as for >1 object.
  ⍝ 
  ⍝ Github test file...
  ⍝   filespec← 'https://github.com/petermsiegel/pmsLibrary/blob/master/src/Concord.dyalog'
  ⍝   actually retrieves:
  ⍝             'https://raw.githubusercontent.com/petermsiegel/pmsLibrary/master/src/Concord.dyalog'
  
      ⎕IO←0 ⋄ ⍺←0
      autoDisclose← 1↑⍺
    6 11 22::⎕SIGNAL⊂⎕DMX.(('Message'Message)('EM'EM)('EN'EN))
      filespec← ⍵
      fiPfx httpsPfx httpPfx gitPfx wsPfx objPfx←'file://' 'https://' 'http://'  'git://' 'ws://' 'obj://'
      isFi isHTTPS isHTTP isGit isWS isObj←1∊¨(⊂filespec)⍷⍨¨fiPfx httpsPfx httpPfx  gitPfx wsPfx objPfx
      gitHdrs←'//github.com/' '//raw.githubusercontent.com/'
      APLObj←1∘(~∊) '://'∘⍷
      Split←' '∘(≠⊆⊢),                   ⍝ Trailing comma (,) ensures valid split of a single char.
      AD← { ~autoDisclose: ⍵ ⋄ ⊃⍣ (1=≢⍵)⊢ ⍵ }
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
          ⍝ enclose as VV to align with fns/ops above. Coded vals will always be vectors.
            ⊂⍵,'←',⎕SE.Dyalog.Array.(0∘Deserialise 1∘Serialise)⍺.⍎⍵  ⍝ Form nm←(...)
      }
      GetFromWs←{ 
          ⋄ wsObjNmÊ← ⊂('EN' 11)('Message' 'Missing ws or object names')
          BareNm← {⍵↑⍨ -'.'⍳⍨ r← ⌽⍵ }
          ws_oS← Split ⍵
        2>≢ws_oS: ⎕SIGNAL wsObjNmÊ
          ws oV← (⊃ws_oS) (1↓ ws_oS)
          ns∘GetObj∘BareNm¨ oV ⊣ oV (ns← ⎕NS ⍬).⎕CY ws
      }
      GetFromURL←{ ⍺←0  ⍝ If 1, the obj is a git obj. 
          11:: ⎕SIGNAL ⊂⎕DMX.{e←'EN' 'EM',⍥⊂¨ EN EM ⋄ et← ⊃⊃⌽⎕VFI ¯3↑Message
            et∊ 6 22: e, ⊂'Message' 'URL not found' ⋄ e, ⊂'Message'Message
          }⍬
          DQ← '"'∘, ,∘'"'
          GetFromGit← {BOM←⎕UCS 65279   ⍝ BOM: As xlated to "invalid Unicode" char per UTF-8.
              UTF8In← 'UTF-8'∘⎕UCS∘⎕UCS
              gitTxt← '^git://(?<!raw\.git|git)' ⎕R 'https://raw.githubusercontent.com/'⊣ ⍵
              gitTxt← { 
                Deblob← '//github.com/' '/blob/' ⎕R '//raw.githubusercontent.com/' '/'       
                1∊ '/blob/'⍷ ⍵: Deblob gitTxt ⋄ ⍵
              } gitTxt
              ⍝ Curl --fail: Treat '404 Not Found' as a signaled error.
              r←UTF8In¨ ⎕SH 'Curl --fail ', DQ gitTxt
              ⋄ emptyÊ← ⊂('EN' 11)('Message' 'URL not found. Empty record returned')
              0=≢r: ⎕SIGNAL emptyÊ
              r⊣ (0⊃r)← (0⊃r)↓⍨ BOM= ⊃⊃r   ⍝ Remove any BOM from 1st record.
          }
          ⍺: GetFromGit ⍵
          1∊ ∊gitHdrs⍷¨ ⊂⍵: GetFromGit ⍵
          ⎕SH 'Curl ', DQ ⍵
      }

      APLObj filespec: AD GetObj¨ Split filespec
      isObj:           AD GetObj¨ Split filespec↓⍨≢objPfx
      isFi:                 ⊃⎕NGET  (filespec↓⍨ ≢fiPfx)1
      isWS:            AD GetFromWs  filespec↓⍨ ≢wsPfx
          ⋄ pfxÊ←⊂('EN' 11)('Message' 'Unrecognized file specification prefix')
      isGit: 1 GetFromURL filespec
      isHTTPS⍱ isHTTP: ⎕SIGNAL pfxÊ
          GetFromURL filespec     ⍝ std http/s or github text files
 }
