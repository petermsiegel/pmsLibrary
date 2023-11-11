:Namespace get ⍝ 1.18
⍝ 2021 03 24 Adam Port from github.com/abrudz/get
⍝ 2021 03 25 Adam Move to Experimental group, fix for Classic
⍝ 2021 03 26 Adam Fix non-sync ⎕FIX on Classic
⍝ 2021 05 03 Adam Remove overwrite param for Link, convert numeric CSV columns to numbers, create target if missing, import dir to ns
⍝ 2021 05 04 Adam Localise name
⍝ 2021 05 13 Adam Let UCMD framework show ⎕DMX.Message
⍝ 2021 05 20 Adam Make sure to ⍞←nl after msgs
⍝ 2021 06 07 Adam Use ⎕SE.Dyalog.Utils.ExpandConfig
⍝ 2021 06 15 Adam Use Link overwrite again, handle plain GH repos, use origDir as dest, use RIDE 4.4's ⍞-handling
⍝ 2021 07 21 Adam add -unpack and -only, fix qa, overwrite existing
⍝ 2021 10 12 Adam handle empty paths
⍝ 2021 10 13 Adam report namespace name instead of member names
⍝ 2021 11 04 Adam handle ambigous ucmds
⍝ 2021 12 09 Adam handle namespaces
⍝ 2022 02 08 Adam avoid translation error on zip
⍝ 2022 02 17 Adam correct target namespace when using API fn, handle GitHub zip subdirs
⍝ 2022 02 18 Adam use ⎕JSON mangling to import invalid names

    :Section CONST ─────
    debug←0 ⋄ ⎕ML←1 ⋄ ⎕IO←1
    desc←'Fetch data/code in many formats from local or remote sources'

    :namespace tmp
        dir←'/dyalog-get-tmp-dir',⍨739⌶0
        zip←dir,'/dyalog-get-tmp.zip'
    :endnamespace

    :namespace sys
        scripts←'(dyalog|apl[fonci]|function|operator|script|class|interface)'
        (os ver)←⊢∘⍎\3↑¨2↑# ⎕WG'APLVersion'
        ellip←⎕UCS 8230(3⍴46)⊃⍨1+82=⎕DR''
    :endnamespace

    :Namespace gh
        latest←'^(https?://)(?:www\.)?github.com(/[^/]+/[^/]+/releases/latest)/?$'
        api←'\1api.github.com/repos\2'

        repo←'^(https?://)?(?:www\.)?(github.com)(/[^/]+/[^/]+)/?$'
        zipball←'\1api.\2/repos\3/zipball'

        specific←'^(https?://(?:www\.)?github.com/[^/]+/[^/]+/)(?:commit|releases/tag|tree)(/[^/]+)/?$'
        zip←'\1archive\2.zip'

        subdir←'^((?:https?://(?:www\.)?github.com/[^/]+/[^/]+/)(?:commit|releases/tag|tree)(?:/[^/]+))(/.*)'

        blob←'github.com(/[^/]+/[^/]+)/blob'
        raw←'raw.githubusercontent.com\1'
    :EndNamespace

    :Namespace gl
        blob←'(gitlab.com/[^\\]+/[^\\]+/-/)blob/'
        raw←'\1raw/'
    :EndNamespace

    :Namespace web
        url←'^((https?|ftp)://)?([^.\\/:]+\.)?([^.\\/:]+\.)+[^.\\/:]+/'
    :endnamespace
    :EndSection

    :Section ERROR ─────
    :Namespace error
        Resignal←{⎕DMX.(OSError{⍵,2⌽(×≢⊃⍬⍴2⌽⍺,⊂'')/'") ("',⊃⍬⍴2⌽⊆⍺}Message{⍺,⍵/⍨0=≢⍺}EM)}⎕SIGNAL{⎕DMX.EN}
        Conform←{'Number of sync flags must be 0 or 1 or match the number of sources'⎕SIGNAL 5}
        Old←{⎕DMX.(EN ⎕SIGNAL⍨'^.*? '⎕R''⍣⍵⊢EM)}
        Sync←{'Can only sync with APL code in local directory or file'⎕SIGNAL 11}
        Missing←{22 ⎕SIGNAL⍨⍵,' not found'}
        Only←{'Cannot filter source files'⎕SIGNAL 22}
    :Endnamespace
    :EndSection

    :Section IFACE ─────
      Get←{ ⍝ Function interface
          debug::error.Resignal ⍬
          ⍺←⊃⎕RSI
          ''≡0/⍺:⍵ ∇⍨⍎⍺ #.⎕NS ⍬ ⍝ ns name → ref
          3≤|≡⍵:Join ⍺ ∇¨⍵
     
          args←⊆⍵
          num←2|⎕DR¨args
          unpack_sync←(⊢↑⍨1⌈≢)⍬,num/args
          path←args/⍨~num
          ~(≢unpack_sync)∊1,≢path:error.Conform ⍬
          _←cleanup
          names←Join unpack_sync(⍺ _Get)¨path
          _←cleanup
     
          target←'.',⍨,⍕⍺
          Join target∘,¨Cut names
      }

    ∇ r←List
      r←⎕NS ⍬
      r.(Group Name Desc Parse)←'Experimental' 'Get'desc'99S -sync -target= -unpack -only='
    ∇
    ⍝ defaults:
    target←0
    only←0

      Help←{
          0=⍺:(⊂desc),Syntax ⍵
          r←0 ∇ ⍵
          b←3↑r
          a←2↓r
          a/⍨←~@(1+⍺)⊢1⍨¨a
          Fmt←{b,⍵,a}
          1=⍺:Fmt Details ⍵
          2=⍺:Fmt Examples ⍵
      }

      Run←{ ⍝ UCMD interface
          params←⊃⌽⍵
          path←params.Arguments
          0=≢path:''
          debug∨←⎕SE.SALTUtils.DEBUG
          state←⎕NS ⍬
          state.printed←0
          Msgs←state{
              ⍺⍺.printed←≢⎕DL 1
              ⍞←'Working on it',sys.ellip
              {⍴⍞←sys.ellip⊣⎕DL 0.5}⍣≢⍬
          }
          Stop←state{
              ⍺⍺.printed:⍵⊣⎕TKILL ⍺⊣⍞←⎕UCS 13
              ⍵⊣⎕TKILL ⍺
          }
          thread←Msgs&⍣(~debug)⊢⍬
          ⎕THIS.only←params.only
          debug::error.Old thread Stop 0
          Target←{
              0≡⍺:⍵
              ⍺ ⍵.⎕NS ⍬⊣⍵ Ex⍣(3 4∊⍨⊃⍵.⎕NC ⍺)⊢⍺
          }
          ns←params.target Target ##.THIS
          r←ns Get path,2⊥params.(unpack sync)
          thread Stop r
      }
    :EndSection

    :Section UHELP ─────
      Syntax←{
          r←,⊂'    ]',⍵,' <source>[:<ext>] [-only=<names>] [-target=<ns>] [-sync] [-unpack]'
          r,←⊂''
          r,←⊂']',⍵,' -??   ⍝ for details'
          r,←⊂']',⍵,' -???  ⍝ for examples'
          r
      }
      Details←{
          r←,⊂'<source>  local path (relative to current dir), URI (defaults to http), workspace name (uses WSPATH), SALT name (uses WORKDIR), or user command (uses CMDDIR)'
          r,←⊂''
          r,←⊂':<ext>    treat <source> as if it had the extension <ext> (d for directory, n for nested vector, s for simple vector, m for matrix)'
          r,←⊂''
          r,←⊂'-only=    restrict import to things with specific names <names> (only for workspaces and non-source files)'
          r,←⊂''
          r,←⊂'-target=  put imported things into <ns> (default is current namespace)'
          r,←⊂''
          r,←⊂'-sync     attempt to establish synchronisation between <source> and <ns> (only for local source files and directories)'
          r,←⊂''
          r,←⊂'-unpack   import members into target namespace rather than creating a new namespace there'
          r,←⊂''
          r,←⊂']',⍵,' is a development tool intended as a one-stop utility for quickly getting bringing resources into the workspace while programming. Do not use at run time, as exact results may vary. Instead, use precisely documented features like ⎕JSON, ⎕CSV, ⎕XML, and ⎕FIX in combination with loading tools like ⎕NGET, HttpCommand, ⎕SE.Link.Import, etc.'
          r,←⊂''
          r,←⊂']',⍵,' supports importing directories and the following file extensions (files with any other extensions are imported as character vectors):'
          r,←⊂'  apla aplc aplf apli apln aplo charlist charmat charstring charvec class csv dcf dcfg dws dyalog function interface js json json5 operator script tsv xml zip'
          r,←⊂''
          r,←⊂'Notes:'
          r,←⊂' ∘  GitHub repository/blob/release/commit URLs are parsed to determine the appropriate zip file (which is then extracted and imported) or source file. If a subdirectory is specified, only that part of the repository is imported.'
          r,←⊂' ∘  Supported formats like JSON, CSV, and XML, are converted to APL arrays based on file extensions.'
          r,←⊂' ∘  You can direct ]',⍵,' to act on a file as if it had a different extension by appending a colon (:) followed by the normal extension, for example myfile.txt:json'
          r,←⊂' ∘  If importing a variable or unscripted namespace with a name that isn''t a valid APL identifier, ]',⍵,' will employ JSON name translation, see:'
          r,←⊂'        ]Help 7162⌶'
          r
      }
      Examples←{
          r←,⊂'Examples:'
          Eg←,/'    ]'⍵' ',⊂
          r,←Eg'"C:\tmp\testme.apln"'
          r,←Eg'''file://C:\tmp\Take.aplf'' -sync'
          r,←Eg'C:\tmp\linktest'
          r,←Eg'/tmp/myapp -sync'
          r,←Eg'/tmp/ima.zip'
          r,←Eg'github.com/mkromberg/apldemo/blob/master/Units.csv'
          r,←Eg'github.com/Dyalog/Jarvis/blob/master/Distribution/Jarvis.dws'
          r,←Eg'http://github.com/json5/json5/blob/master/test/test.json5'
          r,←Eg'http://github.com/json5/json5/blob/master/test/test.json5:v'
          r,←Eg'https://github.com/mkromberg/d18demo/tree/master/perfected'
          r,←Eg'https://github.com/abrudz/Kbd'
          r,←Eg'raw.githubusercontent.com/Dyalog/MiServer/master/Config/Logger.xml'
          r,←Eg'ftp://ftp.software.ibm.com/software/test/foo.txt'
          r,←Eg'''"C:\tmp\myarray.apla"'''
          r,←Eg'HttpCommand -target=⎕SE'
          r,←Eg'dfns'
          r,←Eg'display -only=DISPLAY -unpack'
          r,←Eg']box'
          r,←Eg']box:vtv'
          r
      }
    :endsection

    :Section TESTS ─────
    ∇ ok←qa;targets;syncs;sync;target;ns;whats;what;call
      ok←⍬
      3 ⎕MKDIR'/tmp/myapp'
      'foo←{⍵ ⍵ ⍵}'⎕NPUT'/tmp/myapp/foo.aplf' 1
      :For call :In 1↓Examples List.Name
          :If ×≢'C:\\' ' /'⎕S 3⊢call
              :Continue
          :EndIf
          :If debug
              ⎕←call
          :EndIf
          :Trap debug
              ⎕EX'ns' ⋄ 'ns'⎕NS ⍬
              ⎕CS ns
              {}⎕SE.UCMD call
              ⎕CS ##
              ok,←1
          :Else
              ⎕CS ##
              ⎕←'*** FAIL: ',call
              ok,←0
          :EndTrap
      :EndFor
      3 ⎕NDELETE'/tmp/myapp'
      ok←∧/ok
    ∇
    :EndSection

    :Section TYPES ─────
    Unslash←{⍵↓⍨-'/\'∊⍨⊃⌽⍵}

      _Bare_←{(sync ns unpack path)←⍺ ⍺⍺ ⍵⍵ ⍵
          list←⎕SE.SALT.List path,' -raw -full=2'
          ×≢list:sync(ns _LocalFile_ unpack)'.dyalog',⍨list⊃⍨⊂1 2
          sync:error.Sync ⍬
          ~¯1 0 1∊⍨ns.⎕NC path:ns _Ns path
          ns _LocalWorkspace_ unpack⊢path
      }

      _Ns←{
          name←⊃⌽'.'Cut ⍵
          target←⍺
          tmp←target.⎕NS ⍵
          _←target.⎕EX name
          name⊣'target'⎕NS tmp
      }

      _LocalWorkspace_←{
          (path name ext)←⎕NPARTS ⍵
          name←Norm name
          0::'Not found'⎕SIGNAL 22
          pack←~⍵⍵
          target←name{⍎⍺ ⍵.⎕NS ⍬⊣⍵ Ex ⍺}⍣pack⊢⍺⍺
          All←{
              tmp←⎕NS ⍬
              _←tmp.⎕CY ⍵
              target←⍺
              _←target.⎕EX tmp.⎕NL-⍳9
              _←'target'⎕NS tmp
              tmp.⎕NL-⍳9
          }
          0≡only:Join⊆name⊣⍣pack⊢target All ⍵
          Struct←{
              ~'.'∊⍵:⍵⊣⍵ ⍺⍺.⎕CY ⍵⍵
              parts←'.'Cut ⍵
              target←⍬ ⍺⍺.⎕NS⍨path←'.'Join ¯1↓parts
              ⍵⊣⍵(⍎target).⎕CY ⍵⍵
          }
          Join⊆name⊣⍣pack⊢(target Struct ⍵)¨' ,;'Cut only
      }

      _LocalFile_←{
          path←1=≡⍵
          nget←⍺<path
          _Fix←{
              uri←'file://'{⍵,⍨⍺/⍨~⊃⍺⍷⍵}⍣path⊢⍵
              src←{⊃⎕NGET⍠'ContentType' 'APLCode'⊢(7↓⍵)1}⍣nget⊢uri
              names←⍺ ⍺⍺.⎕FIX src
              1↓∊' ',¨names
          }
          ns←Up⍣⍵⍵⊢⍺⍺
          Fix←ns _Fix∘⍵
          0::Fix 1
          Fix 2
      }

      _Dir_←{
          (dir origDir)←Unslash¨2⍴⊆⍵
          (names types)←0 1 ⎕NINFO⍠1⊢dir,'/*'
          types≡,1:⍺ ∇(⊃names)origDir
     
          (names types)←0 1 ⎕NINFO⍠'Recurse' 2⍠1⊢dir,'/*'
          files←names/⍨2=types
     
          scripts←files Has'\.',sys.scripts,'$'
          scripts∧0≢only:error.Only ⍬
          scripts:⍺(⍺⍺ _Link_ ⍵⍵)dir origDir
     
          files{0≡⍵:⍺ ⋄ ⍺/⍨(2⊃¨⎕NPARTS ⍺)∊' ,;'Cut ⍵}←only
     
          ws←'\.dws$'
          wss←files Has ws
          wss∧⍺:error.Sync ⍬
          wss:⍺⍺ _LocalWorkspace_ ⍵⍵¨ws ⎕S'%'⊢files
     
          name←Norm 2⊃⎕NPARTS origDir
          pack←~⍵⍵
          ref←name{⍺ ⍵.(⍎⎕NS)⍬⊣⍵ Ex ⍺}⍣pack⊢⍺⍺
          unpack_sync←2⊥⍵⍵ ⍺
          name⊣⍣pack⊢Join unpack_sync(ref _Get)¨files
      }

      _Link_←{
          (dir origDir)←Unslash¨2⍴⊆⍵
          (names types)←0 1 ⎕NINFO⍠1⊢dir,'/*'
          types≡,1:⍺ ∇(⊃names)origDir
          name←Norm 2⊃⎕NPARTS origDir
          pack←~⍵⍵
          ref←name{⍺ ⍵.⎕NS ⍬⊣⍵ Ex ⍺}⍣pack⊢⍺⍺
     
          ~⎕NEXISTS dir:error.Missing dir
          opts←⎕NS ⍬
          opts.source←'dir'
          opts.fastLoad←1
     
          Result←ref{⍵:⍵⍵ ⋄ Join ⍺⍺.⎕NL-⍳9}name∘pack
          0::error.Old 1
          ⍺:Result opts ⎕SE.Link.Create ref dir
          opts.overwrite←1
          Result opts ⎕SE.Link.Import ref dir
      }

      WebFile←{
          url←gl.blob gh.blob ⎕R gl.raw gh.raw⊢⍵
          name←∊1↓⎕NPARTS url
          file←tmp.dir,'/',name
          file Curl url
      }

      WebZip←{
     
          ⍝ github.com/USER/REPO/
          ⍝                                          → zipball/
          ⍝                      archive/NAME.zip    → archive/NAME.zip
          ⍝                      commit/NAME         → archive/NAME.zip
          ⍝                      releases/tag/NAME   → archive/NAME.zip
          ⍝                      releases/latest     → zipball_url from https://api.github.com/repos/{user}/{repo}/releases/latest
          ⍝                      tree/NAME           → /archive/NAME.zip
     
          dir←tmp.dir,'/',2⊃⎕NPARTS Unslash ⍵
          (HasExt∧∘~Has∘gh.specific)⍵:dir LocalZip tmp.zip Curl ⍵
          ×≢api←∊gh.(latest ⎕S api)⍵:∇ ZipURL api
          url←gh.(repo specific ⎕R zipball zip)⍵
          dir←tmp.dir,'/',2⊃⎕NPARTS ⍵
          r←dir LocalZip tmp.zip Curl url
          ⍺←''
          0=≢⍺:r
          contents←⊃⎕NINFO⍠1⊢dir,'/*'
          1≠≢contents:⎕SIGNAL⊂('EN' 11)('Message' 'Zip contains multiple directories')
          ⍺,⍨⊃contents
      }

      ZipURL←{
          req←⎕SE.SALT.New'HttpCommand'('Get'⍵)
          data←req.Run.Data
          ns←0 ⎕JSON data
          ns.zipball_url
      }

      Curl←{
          _←⎕CMD'curl -L -o ',⍺,' ',⍵
          'not found'≡(⎕NUNTIE⊢⎕NREAD⍤,∘82 9)⍺ ⎕NTIE ¯1:error.Missing ⍵
          ⍺
      }

      LocalZip←{
          ⍺←tmp.dir,'/',2⊃⎕NPARTS ⍵ ⍝ default dir
          _←3 ⎕MKDIR ⍺
          cmd←∊⍵ ⍺,¨⍨⊃('unzip ' ' -d ')('tar -xf ' ' -C ')⌽⍨'Win'≡sys.os
          ⍺⊣⎕NDELETE ⍵⊣⎕SH cmd
      }

      SV←{ ⍝ ⍺-separated values           ┌no quote if unusual sep  ┌comma if semicolon-sep
          F←⎕CSV⍠('Trim' 0)('Separator'⍺)('QuoteChar'('"'/⍨⍺∊',;'))('Decimal'(⊃'.,'↓⍨';'=⍺))
          num←(''∘≡∨2|⎕DR)¨F ⍵ ⍬ 4 ⍝ try to convert everything to numeric and also accept empty as numeric
          head←((1<≢)∧0∧.=⊣⌿)num   ⍝ first of multiple rows is all text?
          types←1+2×∧⌿head↓num     ⍝ all-numeric columns (except possibly the header)
          ⊃⍪⍨/F ⍵ ⍬ types head     ⍝ more specific this time
      }

    :EndSection

    :Section UTILS ─────
    L←{18≤sys.ver:⎕C ⍵ ⋄ 819⌶⍵}
    Has←{×≢⍵ ⎕S 3⊢⍺}
    Groups←{⊃⍺⎕S{⍵.(1↓Lengths↑¨Offsets↓¨⊂Block)}⍵}
    Norm←{1≥|≡⍵:0(7162⌶)⍵ ⋄ ∇¨⍵}
    Cut←{⍺←' ' ⋄ ⍵⊆⍨~⍵∊⍺}
    Join←{1↓∊' ',¨⍵}
    HasExt←''≢3⊃⎕NPARTS
    Up←{⍵.##}
    Ex←{name←(⍕⍺),'.',⍵ ⋄ 0::⎕EX name ⋄ ⎕SE.Link.Expunge name}
    ∇ {r}←cleanup
      3 ⎕NDELETE tmp.dir
      r←⍬
    ∇

      IsDir←{
          ⎕NEXISTS ⍵:1=1 ⎕NINFO ⍵
          0
      }
    ∇ F←Deserialise;old
      :If 3=⎕NC old←'⎕SE.Link.Deserialise'
          F←⍎old
      :Else
          F←⎕SE.Dyalog.Array.Deserialise
      :EndIf
      ⎕EX⊃⎕SI
      Deserialise←F
    ∇

      Download←{
          _←3 ⎕MKDIR tmp.dir
          ⍵ Has gh.(specific repo):WebZip ⍵
          ⍵ Has gh.subdir:⊃WebZip/⌽gh.subdir Groups ⍵
          WebFile ⍵
      }

      _Get←{(unpack_sync ns path)←⍺ ⍺⍺ ⍵
          0=≢path:''
          (unpack sync)←2 2⊤unpack_sync
     
          as←⊃':\w+$'⎕S'&'⊢path               ⍝ extract type
          path←'^\s+' ':\w+$' '\s+$'⎕R''⊢path ⍝ strip blanks and type
     
          path←⎕SE.Dyalog.Utils.({ExpandConfig ⍵}⍣(3∊⎕NC'ExpandConfig'))path
     
          Encl←1⌽'$^',⊃∘⊆,'(.*)',⊃∘⌽∘⊆ ⍝ e.g. "→"abc" and `´→`abc´
          encls←Encl¨'"''`',('\x{201C}' '\x{201D}')'[\xAB\xBB]'('\x{2018}' '\x{2019}')
          path Has encls:⍺ ∇ encls ⎕R'\1'⊢path
     
          ∨/'*?'∊path:Join sync ∇¨⊃⎕NINFO⍠1⊢path
     
          ']'=⊃path:Join sync ∇¨,∘as¨⊆'source: +(.*)'⎕S'\1'↓⎕SE.UCMD'uversion ',1↓path
          ~∨/'/\'∊path:sync(ns _Bare_ unpack)path
     
          www←path Has web.url
          path←'^file://'⎕R''⊢path
     
          (dir name ext)←⎕NPARTS path
          ext←L 1↓as⊣⍣(×≢as)⊢ext
     
          dir←IsDir path
          dir∨←'dir'(,'d')∊⍨⊂ext
          aplf←ext Has'^',sys.scripts,'$'
     
          sync∧www∨dir⍱aplf:error.Sync ⍬
          www:⍺ ∇ as,⍨Download path
     
          dir:sync(ns _Dir_ unpack)path
          aplf:sync(ns _LocalFile_ unpack)path ⍝ normal file
     
          'zip'≡ext:0 ∇ LocalZip path
          'dws'≡ext:ns _LocalWorkspace_ unpack⊢path
     
          name←Norm name
          ns←Up⍣unpack⊢ns
          Assign←name∘ns.{⍺⊣⍎⍺,'←⍵'}
     
          'dcf'≡ext:Assign(⎕FUNTIE⊢⊢(⎕FREAD,)¯1+2↓∘⍳/2↑⎕FSIZE)path ⎕FSTIE 0
          'csv'≡ext:Assign','SV path
          'tsv' 'tab'∊⍨⊂ext:Assign(⎕UCS 9)SV path
          'ssv'≡ext:Assign';'SV path
          'psv'≡ext:Assign'|'SV path
     
          'apla'≡ext:Assign Deserialise⊃⎕NGET path 1
          'charvec' 'charlist' 'vtv' 'nr'(,'n')'nv'∊⍨⊂ext:Assign⊃⎕NGET path 1
          'charmat' 'mat' 'cr'(,'m')'cm'∊⍨⊂ext:Assign↑⊃⎕NGET path 1
     
          content←⊃⎕NGET path
     
          'dcfg' 'js' 'json' 'json5'∊⍨⊂4↑ext:Assign 0 ⎕JSON⍠'Dialect' 'JSON5'⊢content
          'xml'≡ext:Assign ⎕XML content
     
          Assign content ⍝ fallback: plain text
      }
    :EndSection

:EndNamespace