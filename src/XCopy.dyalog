XCopy←{

    ⎕IO←0
    DEBUG←0
    0/⍨~DEBUG::11 ⎕SIGNAL⍨{
        _←⊂'XCopy:  copy a single object to a destination namespace,'
        _,←⊂'        creating it as needed, optionally with a new name.'
        _,←⊂'Syntax: [options] XCopy objects'
        _,←⊂'        objects:  ''sourceName [destNm]'' ...'
        _,←⊂'        options:  (''destNs'' destNs)*  (''srcWs'' srcWs)   (''callNs'' callNs)'
        _,←⊂'                  *  assumed option if a simple string is specified.'
        _,←⊂'XCopy ⍬           ⍝ for help.'
        _,←⊂'DOMAIN ERROR'
        ¯1↓∊_,¨⎕UCS 13
    }⍬
    0=≢⍵:⎕ED't'⊣t←↑'^ *⍝H(.*)'⎕S' \1'⊣⎕NR'XCopy'
    Msg←('DOMAIN ERROR: '{⍺←''
        in←'^' '⍵' '\\n' '\\t' ⋄ out←⍺⍺(⍕⍺)'\r' (' '⍴⍨≢⍺⍺)
        in ⎕R out⊢⍵
    })

  ⍝ Decode Options (⍺) 'destns'   'callns'  'srcws'
    ⍺←⍬ ⋄ destNsIn←# ⋄ callNs_←⊃⎕RSI ⋄ srcWs←'dfns'
    _←{
        CASEdep←(|≡⍵)∘=
        ⋄ CASEdep 3:∇¨⍵ ⋄ CASEdep 1:destNsIn∘←⍵ ⋄ ~CASEdep 2:∘∘∘
        nm val←⍵
        CASEkey←(⎕C nm)∘≡
        ⋄ CASEkey'destns':destNsIn∘←val
        ⋄ CASEkey'callns':callNs_∘←val
        ⋄ CASEkey'srcws':srcWs∘←val
        ⋄ CASEkey'debug':DEBUG∘←1=val
        ∘∘∘
    }⍺

  ⍝ Determine destination namespace ref (obligatory) and name (if not anonymous)
  ⍝ Returns:  (ns_name)(ns_ref)
    destNsIn destNsIn_←{
        0=≢⍵:(⍕callNs_)callNs_
        nc←⎕NC'⍵'
        9=nc:(⍕⍵)⍵
        0::11 ⎕SIGNAL⍨⍵ Msg'The name "⍵" is in use or invalid: ⎕NC ',⍕nc
        '⎕SE' '#'∊⍨⊂⍵:⍵(⍎⍵)
        2≠nc:∘∘∘
        0 2 9(~∊⍨)nc←⎕NC ⍵:∘∘∘
        0::⍵(callNs_⍎⍵)
        ⍵(⍎⍵ callNs_.⎕NS'')
        ∘∘∘
    }destNsIn

  ⍝ Scanning through ⍵
    MainScan←{
    ⍝ Functions below may read any of:
    ⍝     classIn cloneFlg destNm destNs destNs_ callNs_  qDestNm qSrcNm srcName srcWs tempNs tempNs_
    ⍝ They may set any of these ONLY via return value

    ⍝ SplitNm: For qualified name 'pre.f.ix.simple', splits namespace(s) prefix from name: ('pre.f.ix' 'simple')
    ⍝            For name 'simple', return the name as is:  ('' 'simple')
    ⍝ SimpleNm: Returns the simple name (2nd elem) only.    
      SplitNm←{p←'.'⍳⍨⌽⍵ ⋄ p≥≢⍵: '' ⍵ ⋄ (⍵↓⍨-p+1)(⍵↑⍨-p)}
      SimpleNm←⊃∘⌽SplitNm
    ⍝ CpyWs2Temp
      CpyWs2Temp←{
          qualN srcN srcWS←qSrcNm srcName srcWs
        ⍝ Sets/Returns: ok(1/0), tempNs, tempNs_ classIn
          tempNs_←⍎tempNs←⍵ ⎕NS''
          0::0   ⍝ elements after ok are ignored (all 0)
          _←qualN tempNs_.⎕CY srcWS
          classIn←tempNs_.⎕NC srcN
          1 tempNs tempNs_ classIn
      }
    ⍝ CpyTemp2Dest
    ⍝ classOut ← ∇ classIn
      CpyTemp2Dest←{
          ⎕NC qDestNm⊣{classIn←⍵
              _←destNs_.⎕EX destNm
              classIn(~∊)3 4 9:destNm(destNs_{⍎'⍺⍺.',⍺,'←','⍵⍵.',⍵,' ⋄ 1' ⋄ ⍺⍺ ⍵⍵}tempNs_)srcName
            ⍝ classIn 9:   Copy ns from temp, don't point to temp obj
              classIn=9:destNm destNs_.⎕NS tempNs_.⎕OR srcName
            ⍝ classIn ∊3 4: Copy fn/op from temp
              ⋄ CloneFnOp←{~cloneFlg:⍵ ⋄ s←'\b\Q',⍺⍺,'\E\b' ⋄ c←⊂s ⎕R ⍵⍵⍠('UCP' 1)⊣⊃⍵ ⋄ c,1↓⍵}
              destNs_.⎕FX(srcName CloneFnOp destNm)tempNs_.⎕NR srcName
          }⍵
      }

      2<≢src_dest←' '(≠⊆⊢)⍵:∘∘∘
      qSrcNm qDestNm←src_dest
   
      destNsSub destNm← SplitNm qDestNm
      destNs destNs_←destNsIn destNsIn_{
        0=≢⍵: ⍺
        d d_←⍺
        ns←⍵ d_.⎕NS ''
        ns (⍎ns)
      }destNsSub

      srcName←SimpleNm qSrcNm
      destNm←{
        ⍵:srcName ⋄ SimpleNm destNm
      }0=≢destNm
      cloneFlg←destNm≢srcName

    ⍝ Get fully qualified qDestNm, which could include an anonymous namespace
      qDestNm←destNs{0::⍺,⍵ ⋄ ⍵,⍨⍺ callNs_.⎕NS''}'.',destNm
    ⍝ DEBUG? Show key vars...
      _←{~⍵:0
          ⎕←'1. qSrcNm:     ',qSrcNm
          ⎕←'2. destNm:     ',destNm
          ⎕←'   srcName:    ',srcName
          ⎕←'   qDestNm:    ',qDestNm
          ⎕←'   clone flag: ',cloneFlg
          ⎕←'   destNsIn:   ',destNsIn
          ⎕←'   destNs:     ',destNs
          ⎕←'   srcWs:      ',srcWs
          ⎕←'   call ns:    ',⍕callNs_
          ⎕←'   DEBUG:      ',DEBUG
          ⋄ 1
      }DEBUG
      ¯1∊⎕NC qSrcNm destNm srcWs:∘∘∘

      ⍙TEMPns←''   ⍝ Set scope for named temp ns
      (ok tempNs tempNs_ classIn)←CpyWs2Temp'⍙TEMPns'
      0=ok:⎕NULL          ⍝ Object not found...
      classOut← CpyTemp2Dest classIn
      classIn=classOut: qDestNm classIn     ⍝ Return the class of qDestNm
      911 ⎕SIGNAL⍨'Logic Error: obj "',qDestNm,'" has unexpected class ',⍕classOut 
  }

  MainScan¨⊆⍵

⍝H XCopy: Copy one or more objects to a destination namespace, creating it as needed,
⍝H        optionally with a new name...
⍝H   Syntax:
⍝H      nameReturned classReturned ← options XCopy obj1 [obj2 [obj3...]]
⍝H   ⍵: objN: 'srcName [destNm]'
⍝H     srcName   - a possibly qualified name of an object in the source workspace [string]
⍝H     destNm    - the new name for the object (if different from srcName).
⍝H               - If qualified (e.g. ns1.ns2.simple), places the object (simple) 
⍝H                 in the namespace specified (ns1.ns2), within destNs (if specified), creating it if required.
⍝H   ----------
⍝H     Example:
⍝H         XCopy 'cmpx compare'      -- copies cmpx, giving it the name compare.
⍝H     Example:
⍝H         XCopy 'notes.disp ndisp'  -- copies notes.disp into the target ns with the name ndisp.
⍝H                                      (otherwise, it might overwrite the function 'disp')
⍝H
⍝H   ⍺: Keyword Options
⍝H      destNs srcWs callNs (case ignored)
⍝H      ¯¯¯¯¯¯ ¯¯¯¯¯ ¯¯¯¯¯¯
⍝H      ('destNs' destNs) OR  destNs
⍝H        -  the destination namespace, relative to the calling namespace (see ⍺: callerNs).
⍝H           destNs is a reference or name (char vec).
⍝H           ∘ May be # or ⎕SE.  Defaults to '#'.
⍝H      destNs
⍝H        -  A lone option is interpreted as ('destNs' destNs)
⍝H      ('srcWs'  srcWs)
⍝H        -  the source workspace name (char vec). If omitted, 'dfns' is assumed.
⍝H      ('callNs' callNs)
⍝H        -  the caller's namespace. If omitted, the actual caller's namespace is used.
⍝H           callNs may be a namespace reference or name (char vec)
⍝H    Also...
⍝H      ('DEBUG' [1|0])
⍝H        -  Set DEBUG mode on (1) or off (0)
⍝H   ----------
⍝H      Example:
⍝H           ('destNs' 'notes') XCopy 'notes.disp MyDisplay'
⍝H           -- copies 'notes.disp' as 'notes.MyDisplay'
⍝H      Example:
⍝H           XCopy 'notes.disp MyDisplay'
⍝H           -- copies 'notes.disp' as #.MyDisplay      (if XCopy called from #)
⍝H
⍝H   Returns (nameReturned [classReturned]) as a vector of vectors...
⍝H     nameReturned:
⍝H        The fully qualified name of the object as copied into the workspace.
⍝H        ⎕NULL if unable to find and copy said object.
⍝H     classReturned:
⍝H        The nameclass of the returned object.
⍝H        (Omitted if nameReturned is ⎕NULL)

 }