 GetObj←{
  ⍝ GetObj: See description at the bottom of this function
      ⎕IO←0 ⋄ ⍺←0
      'help'≡⍥⎕C ⍺: ⎕ED '_'⊣ _← ('^\h*⍝H ?(.*)') ⎕S ' \1'⊢⎕NR ⊃⎕XSI 
      autoDisclose← 1↑⍺
    6 11 22::⎕SIGNAL⊂⎕DMX.(('Message'Message)('EM'EM)('EN'EN))
      filespec← ⍵
      pfxList← 'file://' 'https://' 'http://'  'git://' 'ws://' 'obj://'
      fiPfx httpsPfx httpPfx gitPfx wsPfx objPfx← pfxList
      isFi isHttps   isHttp  isGit  isWs  isObj←  1∊¨(⊂filespec)⍷⍨¨ pfxList
      gitHdrs←'//github.com/' '//raw.githubusercontent.com/'
      IsObj←1∘(~∊) '://'∘⍷
      Split←' '∘(≠⊆⊢),                  
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
      GetFromHttp←{ 
        ⍝ If ⍺/git already 1, the obj started with a git:// specifier and possibly no git URL. 
        ⍝ Otherwise, we need to see an explicit git URL.
          ⍺←   1∊ ∊gitHdrs⍷¨ ⊂⍵
          git← ⍺   
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
              ⋄ emptyÊ← ⊂('EN' 11)('Message' 'URL may be invalid. Empty record returned')
            0=≢r: ⎕SIGNAL emptyÊ  ⍝ Technically there is a file, but it's empty...
              r⊣ (0⊃r)← (0⊃r)↓⍨ BOM= ⊃⊃r   ⍝ Remove any BOM from 1st record.
          }
        git:  GetFromGit ⍵
          ⎕SH 'Curl ', DQ ⍵
      }

      IsObj filespec:  AD GetObj¨ Split filespec
      isObj:           AD GetObj¨ Split filespec↓⍨≢objPfx
      isFi:                    ⊃⎕NGET  (filespec↓⍨ ≢fiPfx)1
      isWs:            AD GetFromWs     filespec↓⍨ ≢wsPfx
          ⋄ pfxÊ←⊂('EN' 11)('Message' 'Unrecognized file specification prefix')
      isGit: 1 GetFromHttp filespec    ⍝ (based on explicit git://)
      isHttps⍱ isHttp: ⎕SIGNAL pfxÊ
          GetFromHttp filespec         ⍝ http/s or implicit github text file 
⍝H  GetObj
⍝H     Retrieve objects from files, github, web pages (URLs), workspaces, 
⍝H     and active namespaces as text in executable (⎕FX or ⍎) formats.
⍝H     Fns and operators are in ⎕NR format, with ∇ distinguishing tradfns/ops from dfns/ops.
⍝H     Variables from a ws or ns are in Dyalog Array Definition (Deserialise) text format,
⍝H     amenable to ⍎. See example below.
⍝H     
⍝H  Syntax:
⍝H     lines← [opts] GetObj filespec   
⍝H     filespec:  prefix1://obj1   or  prefix2://obj1 [obj2] 
⍝H      prefix1:    file://fileid  | https://url  |   http://url |  git://url    
⍝H      prefix2:    ws://wsid obj1 [obj2]  |  obj://obj1 [obj2]  |  obj1 [obj2] ]
⍝H     If no prefix is specified, obj:// is assumed.
⍝H       fileid -   fully qualified or relative filename.
⍝H       url-       the url of a web page or a github document.
⍝H       git-       url to a github file ("blob" or text format)
⍝H       wsid-      a standard Dyalog apl workspace identifier
⍝H       objN-      name of an APL object
⍝H  Return the text of one of the following* as output: 
⍝H                       (*)filedesc is a file specification, obj is an APL obj name.
⍝H    a)  file://filedesc  
⍝H        file on local disk,
⍝H    b1) https://filedesc or http://filedesc  
⍝H        text on a web page in secure (https) or non-secure (http) encodings. 
⍝H    b2) https://github.com/... or https://raw.githubusercontent.com/... 
⍝H        an explicitly named github file  
⍝H      * Fully specified files will be processed as in b3) below.
⍝H        Note: If the http: prefix is specified for a github file, it will be honored,
⍝H              though it is likely an error.
⍝H    b3) git://userid/directory/.../obj.type OR as in b2) above:
⍝H      a. An abbreviated git URL specifying the full user directory and file path,
⍝H          https://USER/REPOSITORY/SUBDIR1/SUBDIR2/filename.type
⍝H      b. A git standard URL in binary ("blob") format: 
⍝H          https://github.com/USER/REPOSITORY/blob/SUBDIR1/SUBDIR2/filename.type
⍝H         Files in this format are replaced with their text version as in (c) below.
⍝H      c. Files in the text format are retrieved as is, with UTF-8 converted to Dyalog unicode.
⍝H         https://raw.githubusercontent.com/USER/REPOSITORY/SUBDIR1/SUBDIR2/filename.type
⍝H      * The prefix git:// will ALWAYS be replaced by https:// (not http://) for the transaction.
⍝H    c)  ws://ws obj1 [obj2...]
⍝H        object(s) to be copied from a local Dyalog workspace 'ws'
⍝H             e.g. ws://dfns cmpx X
⍝H        in an executable form:  objName←(...), objName← {...}
⍝H      * Returns 1 or more objects, o, in executable form.
⍝H           Objects returned as described for: d) APL object(s)
⍝H        autodisclose may apply.
⍝H    d)  obj://obj1 [obj2...] or  (with no prefix) obj1 [obj2...]
⍝H        APL object(s) in the currently active user namespace.
⍝H      * Returns 1 or more (enclosed) objects in executable form.
⍝H        * Non-fns will be in the form name←(...value...) per Dyalog 0∘Deserialise format 
⍝H        * Dfns/ops are returned in ordinary ⎕NR format
⍝H        * Tradfns/ops are returned in ⎕NR format with a prefixed and suffixed ∇
⍝H        autodisclose may apply.
⍝H 
⍝H  opts: autodisclose  
⍝H        autoDisclose← 0   If 1, if there is one object to be returned (c or d above),
⍝H                          disclose it. If 0, return enclosed, as for >1 object.
⍝H        'help'            Return help information (w/o processing right arg ⍵).
⍝H  
⍝H  Github test file...
⍝H    a← GetObj 'git://petermsiegel/pmsLibrary/blob/master/src/Concord.dyalog'
⍝H    b← GetObj 'https://github.com/petermsiegel/pmsLibrary/blob/master/src/Concord.dyalog'
⍝H  Both actually retrieve:
⍝H           'https://raw.githubusercontent.com/petermsiegel/pmsLibrary/master/src/Concord.dyalog'
⍝H
⍝H  Example of variable from workspace or an active namespace:
⍝H            a←⍳ 2 2
⍝H            b←GetObj 'a'  ⍝ or 'obj://a'
⍝H            b  ⍝ Returns (enclosed) Dyalog Deserialise-format executable char. vector.
⍝H         a←({⎕ML←1⋄↑⍵}1/¨((((0 0 )( 0 1 )) )( ((1 0 )( 1 1 )) )))  
⍝H           (⍳2 2) ≡ ⍎⊃GetObj'a'
⍝H         1 
 }
