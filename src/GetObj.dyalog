 GetObj←{
  ⍝ GetObj: See full description at the bottom of this function or GetObj⍨'help'
      ⎕IO←0 ⋄ ⍺←⍬
    'help'≡⍥⎕C ⍺: ⎕ED '_'⊣ _← ('^\h*⍝H ?(.*)') ⎕S ' \1'⊢⎕NR ⊃⎕XSI 
      
      defaultOpts← ('autoDisclose' 0)('multiReq' 0)('debug' 0)('AnyProtocol' 0)('emptyResult' 1)
      GetOpts← { minLen←4 ⋄ Keys← ⊃¨ ⋄ Vals← ⊃∘⌽¨ ⋄ valsD← Vals⊢ d← ⍺ 
        0:: 11 ⎕SIGNAL⍨ 'Option format is invalid'
        2|80|⎕DR ⍵: ⍵, valsD↓⍨ ≢⍵                      ⍝ By position
           p← d ⍳⍥(⎕C minLen∘↑¨⍤Keys) u←⊂⍣ (2≥|≡⍵)⊢ ⍵  ⍝ By (minLen pfx of each) keyword                   
        ~1∊ bad← p= ≢d: (Vals u)@ p⊣ valsD
          11 ⎕SIGNAL⍨ 'Invalid option(s):',∊' ',¨ bad/Keys u
      }
      autoDiscÔ multiReqÔ debugÔ anyProtÔ emptyResOkÔ← defaultOpts GetOpts ⍺

  ⍝ If multiReqÔ=0 and ⍵ not a simple vector or 1-item VV, simply pass thru
    (~multiReqÔ)∧ 1<≢⊆⍵: ⍵ 

    6 11 22/⍨ ~debugÔ:: ⎕SIGNAL ⊂⎕DMX.(('Message'Message)('EM'EM)('EN'EN))

      GetSpec← {  
          protocols← 'file' 'https' 'http'  'git' 'ws'  'local' 'loc'
          classes←   'file' 'http'  'http'  'git' 'ws'  'loc'   'loc' 'unknown'
        ~1∊b← '://'(<\⍷)⍵: ⍵ ⍵ 'loc' 'loc'         ⍝ mark first occurance of :// (if any)
          proto id← 0 2↓¨ ⍵⊆⍨ ~b ⋄ proto← ⎕C proto
          class← classes⊃⍨ protocols⍳ ⊂proto 
          ⍵  id  class proto                       ⍝ Returns: (proId←⍵), id, class, protocol
      } 
      Split←' '∘(≠⊆⊢),                  
      AD← { ~autoDiscÔ: ⍵ ⋄ ⊃∘⊃⍣ (1=≢⍵)⊢ ⍵ }       ⍝ Disclose if ⍵ has one element
      FromLoc←{ 
        ⍝ Return dfns/ops, tradfns/ops, and variables differently
        ⍝ dfns:      Form VV: nm←{...}
        ⍝ tradfns:   Form VV: ∇ ... nm ... ∇
        ⍝ variables: Form V:  nm←( Dyalog Deserialise format ) 
          ⋄ objNmÊ←  ⊂('Message' 'APL object does not exist or is invalid')('EN' 11)
          ⋄ objValÊ← ⊂('Message' 'Unable to get value of APL object')('EN' 11)
          ⍺←⊃⎕RSI 
          Case← (⍺.⎕NC ⊂,⍵)∘∊
        Case¯1   0:   ⎕SIGNAL objNmÊ
        Case 3.2 4.2: ⊂⍺.⎕NR ⍵             
        Case 3.1 4.1: ⊂fn⊣ (⊃⊃fn)← (⊃⊃⌽fn)← '∇' ⊣ fn←' ',⍨¨ ' ',⍨ ⍺.⎕NR ⍵  
        0/⍨ ~debugÔ:: ⎕SIGNAL objValÊ
        ⍝ enclose as VV to align with fns/ops above. Coded vals will always be vectors.
          ⊂⍵,'←',⎕SE.Dyalog.Array.(0∘Deserialise 1∘Serialise)⍺.⍎⍵  ⍝ Form nm←(...)
      }
      FromWs←{ 
          ⋄ wsObjNmÊ← ⊂('EN' 11)('Message' 'Missing ws or object name/s')
          BareNm← {⍵↑⍨ -'.'⍳⍨ r← ⌽⍵ }
          ws_oS← Split ⍵
        2>≢ws_oS: ⎕SIGNAL wsObjNmÊ
          ws oV← (⊃ws_oS) (1↓ ws_oS)
          tempNs∘FromLoc∘BareNm¨ oV ⊣ oV (tempNs← ⎕NS ⍬).⎕CY ws
      }
      FromHttp←{ 
        ⍝ If ⍺/git explicitly 1, 
        ⍝    the obj started with a git:// specifier and possibly no git URL before username etc.. 
        ⍝ Otherwise, we need to see an explicit git URL.
          noReqÊ← ⊂('EN' 11)('Message' 'URL returned no records')
          gitHdrs←'//github.com/' '//raw.githubusercontent.com/'
          ⍺←   1∊ ∊gitHdrs⍷¨ ⊂⍵
          git← ⍺   
        11/⍨ ~debugÔ:: ⎕SIGNAL ⊂⎕DMX.{e←'EN' 'EM',⍥⊂¨ EN EM ⋄ et← ⊃⊃⌽⎕VFI ¯3↑Message
            et∊ 3 6 22 60: e, ⊂'Message' 'URL not found' ⋄ e, ⊂'Message'Message
            }⍬
          DQ← '"'∘, ,∘'"'
          FromGit← {
              BOM←⎕UCS 65279                          ⍝ The byte-order-mark BOM U+FEFF.
              UTF8In← 'UTF-8'∘⎕UCS∘⎕UCS
              Git2Https← '^(?i)git://(?<!raw\.git|git)' ⎕R 'https://raw.githubusercontent.com/' 
              Deblob← '//github.com/' '/blob/' ⎕R '//raw.githubusercontent.com/' '/' 
          ⍝ Curl --fail: Treat '404 Not Found' as a signaled error.
              r←UTF8In¨ ⎕SH 'Curl --fail ', DQ Deblob Git2Https ⍵
          ⍝ Remove any BOM from start of 1st record. 
            ×≢r: r⊣ (0⊃r)← (0⊃r)↓⍨ BOM= ⊃⊃r 
              r⊣ ⎕SIGNAL noReqÊ/⍨ ~emptyResOkÔ        ⍝ Empty records ok by default
          }
        git: FromGit ⍵ 
        ×≢r← ⎕SH 'Curl --fail ', DQ ⍵: r  
          r⊣ ⎕SIGNAL noReqÊ/⍨ ~emptyResOkÔ            ⍝ Empty records ok by default        
      }
  ⍝ Main program
  ⊃⍣(1≥|≡⍵)⊢ {
      proId id class proto← GetSpec ⍵
      Case←  class∘≡
    Case 'loc':   AD FromLoc¨ Split id  
    Case 'file':  ⊃⎕NGET id 1
    Case 'ws':    AD FromWs id 
    Case 'git':   1 FromHttp proId                 ⍝ explicit git file
    Case 'http':  FromHttp proId                   ⍝ http/s or implicit git file  
    anyProtÔ∧ Case 'unknown': ⎕SH 'Curl --fail ',proId  
      ⋄ pfxÊ←⊂('EN' 11)('Message',⍥⊂ 'Unrecognized protocol: ', proto)
      ⎕SIGNAL pfxÊ
  }¨⊆⍵
             
⍝H  GetObj
⍝H     Retrieve objects from files, github, web pages (URLs via http), workspaces, 
⍝H     and active namespaces and returns them as text in executable (⎕FX or ⍎) formats.
⍝H     Fns and operators are in ⎕NR format, in three styles:
⍝H         dfn_op←{ body }
⍝H         variable←(...)
⍝H         ∇ tradfn ... [lines] ... ∇
⍝H     Variables from a ws or ns are in Dyalog Array Definition (Deserialise) text format,
⍝H     amenable to ⍎. Objects that can't be converted to that format (q.v.) can't be retrieved.
⍝H     See example below.
⍝H     
⍝H  Syntax:
⍝H  I. Passthru form (do nothing!) If multiReq=0 (option [1]), the default.
⍝H     VV← [n 0 n] GetObj VV
⍝H                  If the object has more than one vector, simply pass the data thru,
⍝H                  as if ⍵ is already an object (from an early fn in the pipeline).
⍝H                  If multiReq=1 (option [1]), treat each vector (line) as a GetObj request. 
⍝H  II. GetObj form
⍝H     lines← [opts] GetObj fileSpec   
⍝H     fileSpec:  format1   or  format2
⍝H      format1:    protocol://spec
⍝H                  file://fileid  | https://url  |   http://url |  git://url    
⍝H      format2:    prefix://spec1 [spec2...]
⍝H                  ws://wsid obj1 [obj2]  |  loc[al]://obj1 [obj2]  |  obj1 [obj2] ]
⍝H     If no protocol is specified, local:// (or loc://) is assumed.
⍝H       fileid -   fully qualified or relative filename.
⍝H       url-       the url of a web page or a github document.
⍝H       git-       url to a github file ("blob" or text format)
⍝H       wsid-      a standard Dyalog apl workspace identifier
⍝H       objN-      name of an APL object. If not qualified, relative to caller namespace.
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
⍝H  opts:
⍝H   By Position: autodisclose/0  multiReq/0  debug/0  anyProtocol/0  emptyResult/1
⍝H   For Help:    'help'  
⍝H   By Keyword:  ('autodisclose' 0) ('multireq' 0) ('debug' 0) ('anyprotocol' 0) ('emptyResult' 1)
⍝H  (Min 4 char): ('auto' 0)         ('mult' 0)     ('debug' 0) ('anyp' 0)        ('empty' 0)
⍝H        autoDisclose← 0   If 1, if there is one object to be returned (c or d above),
⍝H                          disclose it. If 0, return enclosed, as for >1 object.
⍝H        multiReq←0        multiple requests: If 1, and there are multiple vectors 
⍝H                          passed as ⍵, execute GetObj on each vector, and return the results.
⍝H                          If 0, and there are multiple vectors passed as ⍵, pass ⍵
⍝H                          through without processing.
⍝H        debug← 0          If 1, then signal any errors where they occur.
⍝H        anyProtocol←0     If another protocol besides ws:, https:, git:, etc.
⍝H                          is used (e.g. ftp:), allow it; don't signal an error.
⍝H                          Default: other protocols aren't allowed.
⍝H        emptyResult←1     If an http, https, or git returns a null record, return it as is.
⍝H                          If 0, returning a null record will cause an error.
⍝H       'help'             Return help information (w/o processing right arg ⍵).
⍝H  
⍝H  Github test file...
⍝H    a← GetObj 'git://petermsiegel/pmsLibrary/blob/master/src/Concord.dyalog'
⍝H    b← GetObj 'https://github.com/petermsiegel/pmsLibrary/blob/master/src/Concord.dyalog'
⍝H  Both actually retrieve (and decode UTF8):
⍝H           'https://raw.githubusercontent.com/petermsiegel/pmsLibrary/master/src/Concord.dyalog'
⍝H
⍝H  Example of variable from workspace or an active namespace:
⍝H            a←⍳ 2 2
⍝H            1 GetObj 'a'  ⍝ or GetObj 'local://a'   or ('auto' 1) GetObj 'loc://a'
⍝H         a←({⎕ML←1⋄↑⍵}1/¨((((0 0 )( 0 1 )) )( ((1 0 )( 1 1 )) )))  
⍝H           (⍳2 2) ≡ ⍎1 GetObj'a'
⍝H         1 
 }
