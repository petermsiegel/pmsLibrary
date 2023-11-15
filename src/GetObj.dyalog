 GetObj←{
  ⍝ GetObj: See full description at the bottom of this function or GetObj⍨'help'
      ⎕IO←0 ⋄ ⍺←0
    'help'≡⍥⎕C ⍺: ⎕ED '_'⊣ _← ('^\h*⍝H ?(.*)') ⎕S ' \1'⊢⎕NR ⊃⎕XSI 
      autoDisclose debug← 2↑⍺
    6 11 22/⍨~debug ::⎕SIGNAL⊂⎕DMX.(('Message'Message)('EM'EM)('EN'EN))

      GetSpec← { ⍝ Returns (fullSpec, objId, type)
          pfxList← 'file://' 'https://' 'http://'  'git://' 'ws://' 'local://' 'loc://' '://'
          pfxType← 'file'    'http'     'http'     'git'    'ws'    'loc'      'loc'    'other' 'loc'
          which← 1∊¨ pfxList ⍷¨ ⍵
          len← ⊃which/ ≢¨ pfxList             ⍝ 0 if default of no prefix
          type← ⊃pfxType/⍨ which, 1           ⍝ 'loc' if no prefix
          ⍵ (len↓⍵) type  
      } 
      Split←' '∘(≠⊆⊢),                  
      AD← { ~autoDisclose: ⍵ ⋄ ⊃∘⊃⍣ (1=≢⍵)⊢ ⍵ }
      GetLocal←{ 
        ⍝ Return dfns/ops, tradfns/ops, and variables differently
        ⍝ dfns:      Form VV: nm←{...}
        ⍝ tradfns:   Form VV: ∇ ... nm ... ∇
        ⍝ variables: Form V:  nm←( Dyalog Deserialise format ) 
          ⋄ objNmÊ←  ⊂('Message' 'APL object does not exist or is invalid')('EN' 11)
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
          hide∘GetLocal∘BareNm¨ oV ⊣ oV (hide← ⎕NS ⍬).⎕CY ws
      }
      GetFromHttp←{ 
        ⍝ If ⍺/git explicitly 1, 
        ⍝    the obj started with a git:// specifier and possibly no git URL before username etc.. 
        ⍝ Otherwise, we need to see an explicit git URL.
          gitHdrs←'//github.com/' '//raw.githubusercontent.com/'
          ⍺←   1∊ ∊gitHdrs⍷¨ ⊂⍵
          git← ⍺   
        11:: ⎕SIGNAL ⊂⎕DMX.{e←'EN' 'EM',⍥⊂¨ EN EM ⋄ et← ⊃⊃⌽⎕VFI ¯3↑Message
            et∊ 3 6 22: e, ⊂'Message' 'URL not found' ⋄ e, ⊂'Message'Message
            }⍬
          DQ← '"'∘, ,∘'"'
          GetFromGit← {
              BOM←⎕UCS 65279   ⍝ BOM: As xlated to "invalid Unicode" char per UTF-8.
              UTF8In← 'UTF-8'∘⎕UCS∘⎕UCS
              Git2Https← '^git://(?<!raw\.git|git)' ⎕R 'https://raw.githubusercontent.com/' 
              Deblob← '//github.com/' '/blob/' ⎕R '//raw.githubusercontent.com/' '/' 

            ⍝ Curl --fail: Treat '404 Not Found' as a signaled error.
              r←UTF8In¨ ⎕SH 'Curl --fail ', DQ Deblob Git2Https ⍵
            ⍝ Remove any BOM from 1st record.
            ×≢r: r⊣ (0⊃r)← (0⊃r)↓⍨ BOM= ⊃⊃r 
            ⍝ A record was returned, but it was empty!  
              ⋄ emptyÊ← ⊂('EN' 11)('Message' 'URL may be invalid. Empty record returned')
              ⎕SIGNAL emptyÊ   
          }
        git:  GetFromGit ⍵ ⋄ ⎕SH 'Curl ', DQ ⍵
      }
  ⍝ Main program
      fullSpec objId type← GetSpec ⍵
      Case←  type∘≡
    Case 'loc':   AD GetLocal¨ Split objId  
    Case 'file':  ⊃⎕NGET objId 1
    Case 'ws':    AD GetFromWs objId 
    Case 'git':   1 GetFromHttp fullSpec    ⍝ (based on explicit git://)
    Case 'http':  GetFromHttp fullSpec  ⍝ http/s or implicit github text file    
      ⋄ pfxÊ←⊂('EN' 11)('Message' 'Unrecognized file specification prefix')
      ⎕SIGNAL pfxÊ
             
⍝H  GetObj
⍝H     Retrieve objects from files, github, web pages (URLs), workspaces, 
⍝H     and active namespaces as text in executable (⎕FX or ⍎) formats.
⍝H     Fns and operators are in ⎕NR format, with ∇ distinguishing tradfns/ops from dfns/ops.
⍝H     Variables from a ws or ns are in Dyalog Array Definition (Deserialise) text format,
⍝H     amenable to ⍎. See example below.
⍝H     
⍝H  Syntax:
⍝H     lines← [opts] GetObj fileSpec   
⍝H     fileSpec:  prefix1://obj1   or  prefix2://obj1 [obj2] 
⍝H      prefix1:    file://fileid  | https://url  |   http://url |  git://url    
⍝H      prefix2:    ws://wsid obj1 [obj2]  |  loc[al]://obj1 [obj2]  |  obj1 [obj2] ]
⍝H     If no prefix is specified, local:// (or loc://) is assumed.
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
⍝H      * autodisclose may apply.
⍝H    d)  local://obj1 [obj2...], loc://obj1 [obj2...], or (with no prefix) obj1 [obj2...]
⍝H        APL object(s) in the currently active user namespace.
⍝H      * Returns 1 or more (enclosed) objects in executable form.
⍝H        * Non-fns will be in the form name←(...value...) per Dyalog 0∘Deserialise format 
⍝H        * Dfns/ops are returned in ordinary ⎕NR format
⍝H        * Tradfns/ops are returned in ⎕NR format with a prefixed and suffixed ∇
⍝H      * autodisclose may apply.
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
⍝H            GetObj 'a'  ⍝ or GetObj 'local://a'
⍝H         a←({⎕ML←1⋄↑⍵}1/¨((((0 0 )( 0 1 )) )( ((1 0 )( 1 1 )) )))  
⍝H           (⍳2 2) ≡ ⍎1 GetObj'a'
⍝H         1 
 }
