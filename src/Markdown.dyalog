:Namespace Markdown

:Section Main_Routines  
⍝ Main routines and declarations
⍝ *** Show *** 
  ⍝ Show:     hNs@ns← newOpts ∇ markdown@CVV [style@CVV]
  ⍝ markdown: APL char vectors (CVV)  
  ⍝ newOpts:  New options for size, posn, style (a boolean), and JSON option variables. 
  ⍝           Options are of the form: ('name' val), where a val of 1/0 is replaced by Json true/false.
  ⍝ hNs:      Dyalog Render object (⎕WC namespace)
  ⍝           hNs.HTML contains the generated HTML as a character vector with CR's (via HTMLRenderer)
  ⍝           hNs.MD contains the source markdown used to generate it.
  ⍝           hNs.STYLE contains any CSS Style code (that goes between <style> and </style>)
  ⍝ The generated HTML object scope continues as long as the resulting value in hNs is in scope.
  ⍝ 
  Show←{
    0:: ⎕SIGNAL ⊂⎕DMX.(('EM' EM)('Message' Message)('EN' EN))
      ⍺← ⍬ ⋄ opts← ⍺ ⋄ hN← #.⎕NS⍬                       
    ⍝ If |depth| is less than 3, ⍵ contains just the markdown. Any style will come from
    ⍝ within the Markdown namespace comments (marked with token 'ST').
    ⍝ If 3, ⍵ contains two items: the markdown (CVV) and the style directives (CVV).
      mdTxt styleTxt← { 3=|≡⍵: ⍵ ⋄ ⍵ ⍬} ⊆⍵ 
      src← ⎕SRC ⎕THIS 
      ns jsonTxt← (,∘⊂⍣(2=|≡opts)⊢ opts) MergeOpts '{', '}',⍨ Flatten 'JSO' TokenScript src

      SetTitle← { ⍺≢  ⎕NULL: ⍺ ⋄'*'~⍨ ⊃'#++\h?(.*)'⎕S '\1' ⍠('Mode' 'D')('ML' 1)⊢ ⍵ } 
      SetStyle← { ~⍺: 'STC' TokenScript src ⋄ 0=≢⍵: 'STC?' TokenScript src ⋄ ⍵ }

      titleTxt← ns.title SetTitle mdTxt 
      styleTxt← ns.style SetStyle styleTxt   
      htmlTxt← mdTxt styleTxt titleTxt jsonTxt Customise 'HT' TokenScript src   
      optL← ('HTML'  htmlTxt) (ns.size,⍨ ⊂'Size') (ns.posn,⍨ ⊂'Posn') ('Coord' 'ScaledPixel')
      _← 'hN.htmlObj' ⎕WC 'HTMLRenderer',⍥⊆ optL      
      hN.htmlObj ⊣ hN.htmlObj.(MD STYLE TITLE)← mdTxt styleTxt titleTxt 
  }
  ⍝ *** TokenScript ***
  ⍝ TokenScript: CVV← token@CV ∇ CVV                    
  ⍝   Find payload in char vectors (CV) following ('^\h*⍝',token,'\h|$') in a vector of CV's. 
  ⍝     - If the token is 'XX', we match /^\h*⍝XX/ followed by /\h|$/. 
  ⍝       I.e., it will match XX, but not (simple) X, XY, XXX, etc.
  ⍝     - If the "token" is 'XX?' or 'X{1,2}', we will match X, XX, but not XY or XXX.
  ⍝   What follows the token and any following blank is the payload /(.*)/'. 
  TokenScript← { pfx src← ⍺ ⍵ 
      ('^\h*⍝', pfx, '(?:\h|$)(.*)') ⎕S '\1'⊣ src 
  }
  
  ⍝ example: e← ∇
  ⍝   A markdown example.  
    example← 'EX' TokenScript ⎕SRC ⎕THIS 
  
  ⍝ help: {html@ns}← ∇
  ⍝   To see the markdown source, see: html.MD 
  ∇ {html}← help  
    html← ('size',⍥⊂ 900 900)('posn',⍥⊂ 5 5) Show 'HELP' TokenScript ⎕SRC ⎕THIS 
    {}⍞
  ∇
:EndSection ⍝ Main_Routines

:Section Constants_and_Variables
  ⍝ Constants
    ⎕IO ⎕ML← 0 1 
    CR← ⎕UCS 13
  ⍝ Variables                                          ⍝ size: height, width; posn: y, x 
    sizeDef posnDef styleDef← (800 1000) (5 5) 1       ⍝ style: 1=use our CSS styles, 0=use minimal defaults
    titleDef← ''                                       ⍝ default title (otherwise from markdown #...)
    exampleT← ''                                       ⍝ See  ∇ example ∇  
:EndSection ⍝ Constants_and_Variables

:Section Internal_Utilities
  ⍝ *** Customise ***
  ⍝ Customise:  ∇ md@CVV style@CVV ∇ htmlSrc@CVV                              
  ⍝   Insert option text (¨mdTxt styleTxt titleTxt¨) into html at "stub" locations.  
  ⍝   Don't process escape chars in the replacement field...
  Customise← {   
      optTxt4← CR,¨Flatten¨ ⍺ 
      stubs4← '___MARKDOWN___' '___STYLE___'  '___TITLE___'  '___OPTS___'
      stubs4 ⎕R optTxt4 RE._Simple RE._RE10 ⍵
  }
  ⍝ *** Flatten ***
  ⍝ Flatten:  CcrV← ∇ CVV                               
  ⍝   Convert vector of char vectors into a CV with carriage returns. 
  ⍝   Keep a CR before the FIRST line! 
  Flatten← 1∘↓(∊,⍨¨∘CR⍤⊆) 

  ⍝ *** MergeOpts ***
  ⍝ MergeOpts:   aplOut jsonOut← aplIn ∇ jsonIn
  ⍝    ∘ Load existing Markdown options (jsonIn: in Json format);
  ⍝    ∘ Merge any new options passed from APL (aplIn: as ⍠-style key-value pairs), 
  ⍝      replacing 0, 1, ⎕NULL with (⊂'false'), (⊂'true'), (⊂'null') and vice versa for apl option form.
  ⍝ Returns updated options in ¨apl ns form¨ and ¨json text form¨.
  MergeOpts←{ 
      J5← ⎕JSON⍠('Dialect' 'JSON5')('Null' ⎕NULL)
      _Set← { ⍺⍺⍎ ⍺,'←⍵' } 
      SetIn← { 0=≢⍺: ⍵ ⋄ ⍵⊣ (⊃¨⍺) (⍵ _Set)∘⊃∘⌽¨⍺ } 
      Map← { 
        ns← ⍵ 
        tf1 tf2← ⍺⌽ 1 0,⍥⊂ ⊂¨'true' 'false'  
        ns⊣ { ⍵ (ns _Set) (tf1⍳ v)⊃ tf2, v← ⊂ns.⎕OR ⍵ }¨ ns.⎕NL ¯2   
      }
      (1 Map ns),⍥⊂ J5 0 Map⊢ ns← ⍺ SetIn J5 ⍵ 
  }
:EndSection ⍝ Internal_Utilities

:Section Regular_Expression_Utils
  :Namespace RE
     _Simple← ⍠('ResultText' 'Simple')('EOL' 'CR')
     _RE10←   ⍠'Regex' (1 0)
  :EndNamespace 
:EndSection ⍝ Regular_Expression_Utils 

:Section Alien_Stuff 
  :Section HTML_Code 
⍝ -------------------------------------------------------------------------------------------
⍝  Markdown-to-Html code-- "showdown" dialect
  ⍝HT <!DOCTYPE html>
  ⍝HT <html>
  ⍝HT <head>
  ⍝HT   <title>
  ⍝   The page title goes here.
  ⍝HT       ___TITLE___
  ⍝HT   </title>
  ⍝HT   <style> 
  ⍝    CTSS style statements go here.
  ⍝HT      ___STYLE___ 
   
    ⍝ST  :root {
    ⍝ST     --default-text-color: #333333;
    ⍝ST     --muted-text-color: #666666;
    ⍝ST     --link-color: #f05675;
    ⍝ST     --muted-border-color: #dddddd;
    ⍝ST     --muted-background-color: #eeeeee;
    ⍝ST     --codeblock-background-color: #772222;
    ⍝ST     --codeblock-text-color: #eeeeee;
    ⍝ST   }
    ⍝ST   table {
    ⍝ST     font-family: arial, sans-serif;
    ⍝ST     width: 90%;
    ⍝ST   }
    ⍝ST   td, th {
    ⍝ST     border: 2px black;
    ⍝ST     background-color:rgba(244, 239, 232, 0.77);
    ⍝ST     padding: 8px;
    ⍝ST   }
    ⍝ST   tr:nth-of-type(odd) {
    ⍝ST     background-color: lightBlue;
    ⍝ST     color: darkBlue;
    ⍝ST   } 
    ⍝ST   tr:nth-of-type(even) {
    ⍝ST     background-color: lightRed;
    ⍝ST     color: darkRed;
    ⍝ST   }
    ⍝ST   blockquote {
    ⍝ST     font-family: Baskerville, Garamond, Georgia; 
    ⍝ST     font-size: 110%;
    ⍝ST     border-left: 3px solid darkRed;
    ⍝ST     padding-left: 5px;
    ⍝ST     color:rgb(0, 50, 3);
    ⍝ST   }
    ⍝ST   pre {
    ⍝ST     padding: 1rem;
    ⍝ST     border-radius: 4px;
    ⍝ST     color: var(--codeblock-text-color);
    ⍝ST     background-color: var(--codeblock-background-color);
    ⍝ST     overflow-x: auto;
    ⍝ST   }
    ⍝STC  code {
    ⍝STC   font-size: 90%;
    ⍝STC    font-family: "APL386 Unicode", APL385, "APL385 Unicode", "Courier New", Courier, 
    ⍝STC                 "Lucida Console", "Consolas", monospace;
    ⍝STC  }

  ⍝HT   </style>
  ⍝HT   <script src="https://cdnjs.cloudflare.com/ajax/libs/showdown/2.1.0/showdown.min.js" 
  ⍝HT        integrity="sha512-LhccdVNGe2QMEfI3x4DVV3ckMRe36TfydKss6mJpdHjNFiV07dFpS2xzeZedptKZrwxfICJpez09iNioiSZ3hA==" 
  ⍝HT        crossorigin="anonymous" referrerpolicy="no-referrer">
  ⍝HT   </script>
  ⍝HT </head>
  ⍝HT <body>
  ⍝HT   <div id="markdown-content" style="display:none;">
  ⍝   User Markdown goes here  
  ⍝HT     ___MARKDOWN___  
  ⍝           
  ⍝HT   </div>
  ⍝HT   <div id="html-content"></div>
  ⍝HT   <script>
  ⍝HT     var markdownText = document.getElementById('markdown-content').textContent;
  ⍝   Json Markdown options go here...
  ⍝HT     var opts = ___OPTS___;   

  ⍝ Json Markdown options    
    ⍝JSC      // Json Markdown options (Showdown dialect)
    ⍝JSC      // ∘ For all binary (true/false) options except ghCodeBlocks, 
    ⍝JSC      //   the "built-in" default value is (false), potentially overridden here!
    ⍝JSC      // -------------------------------------------------------------------------------
    ⍝JSC      // Simple line break: If true, simple line break in paragraph emits <br>.
    ⍝JSC      //                    If false (default), simple line break does not emit <br>.
    ⍝         "APL" only opts...
    ⍝JSO         title: null, style: 1, posn: [5, 5], size: [800, 1000],
    ⍝         True JSON opts...  
    ⍝JSO         simpleLineBreaks: false, 
    ⍝JSC      // Enable tables 
    ⍝JSO         tables: true,
    ⍝JSC      // Enable strikethrough 
    ⍝JSO         strikethrough: true,
    ⍝JSC      // Omit extra line break in code blocks
    ⍝JSO         omitExtraWLInCodeBlocks: true,
    ⍝JSC      // Enable GitHub-compatible header IDs
    ⍝JSO         ghCompatibleHeaderId: true,
    ⍝JSC      // Fenced code blocks. True (default), enable code blocks with ``` ... ``` 
    ⍝JSO         ghCodeBlocks: true,
    ⍝JSC      // Prefix header IDs with "custom-id-"
    ⍝JSO         prefixHeaderId: 'custom-id-',
    ⍝JSC      // Enable emoji support 
    ⍝JSO         emoji: true,
    ⍝JSC      // Enable task lists 
    ⍝JSO         tasklists: true,
    ⍝JSC      // Disable automatic wrapping of HTML blocks
    ⍝JSO         noHTMLBlocks: false,
    ⍝JSC      // Allow simple URLs like http://dyalog.com in text to be treated as actual links. 
    ⍝JSC      // Keep in mind that selecting a link will leave the Markdown page, w/o an easy way  
    ⍝JSC      // to return (except by recreating the page).
    ⍝JSO         simplifiedAutoLink: false,        
    ⍝JSC      // Enable support for setting image dimensions in Markdown,  
    ⍝JSC      //      e.g. ![foo](foo.jpg =100x80)  OR ![baz](baz.jpg =80%x5em)
    ⍝JSO         parseImgDimensions: false, 
    ⍝JSC      // Force new links to open in a new window
    ⍝JSC      // In reality, if <true> links are suppressed when using HTMLRenderer.
    ⍝JSC      // If <false>, then the links are followed, but there is no mechanism to get back.
    ⍝JSO         openLinksInNewWindow: true, 
    ⍝JSC      // if true, suppresses any special treatment of underlines 
    ⍝JSC      // *** Doesn't appear to make any difference ***
    ⍝JSO         underline: true,

  ⍝HT     const converter = new showdown.Converter(opts);
  ⍝HT     const html = converter.makeHtml(markdownText);
  ⍝HT     document.getElementById('html-content').innerHTML = html;
  ⍝HT   </script>
  ⍝HT </body>
  ⍝HT </html>
  :EndSection ⍝ HTML_Code 

  :Section Help 
   ⍝  Help information in Markdown style
   ⍝
   ⍝HELP ## Help for Markdown.dyalog APL Utility
   ⍝HELP 
   ⍝HELP | :arrow_forward: |Use Markdown in an HTMLRenderer session in Dyalog|
   ⍝HELP |: --- :|: --- |
   ⍝HELP | :arrow_forward: |Based on the **Showdown** dialect of *Markdown*. See: https://showdownjs.com/. |
   ⍝HELP 
   ⍝HELP ## Key *Markdown* Routines
   ⍝HELP 
   ⍝HELP | Routine  | Usage                                                   |          |   Call Syntax     |       |
   ⍝HELP |: ----    |: ---                                                    |           ---      :|:  --- :|: -------- |
   ⍝HELP | Show     | Process and Display Markdown text via the HTMLRenderer  | htmlNs←&nbsp;[opts] | ∇      | md&nbsp;[style] |
   ⍝HELP | help     | Display Markdown help information                       |   [htmlNs←]         | ∇      |       | 
   ⍝HELP | example  | Return the source for a Markdown example (variable)     |    mdLines←         | ∇      |       |
   ⍝HELP | TokenScript     | Return Markdown (HTML, etc.) strings from namespace or function comments prefixed with a specific token.| lines← 'token' |∇ | lines |
   ⍝HELP | Flatten  | Convert APL strings to a simple char vector (with carriage returns). | string← | ∇     | lines |
   ⍝HELP 
   ⍝HELP ## Using Markdown.Show:
   ⍝HELP 
   ⍝HELP ```md
   ⍝HELP [html←]  [options] Markdown.Show markdown [style]
   ⍝HELP ```
   ⍝HELP 
   ⍝HELP where **markdown** is 
   ⍝HELP 
   ⍝HELP - a vector of character vectors containing Showdown-flavoured Markdown, 
   ⍝HELP typically extracted (via Markdown.TokenScript) from comments in the current function or namespace;
   ⍝HELP     - If a single vector, it will be treated as a 1-element vector of character vectors.
   ⍝HELP 
   ⍝HELP where **style** is 
   ⍝HELP 
   ⍝HELP - an optional vector of character vectors containing standard CSS style information, 
   ⍝HELP often extracted (via Markdown.TokenScript) from comments in the current function or namespace;
   ⍝HELP and defaulting to something reasonable;
   ⍝HELP     - To view the default CSS style, do `⎕ED 's'⊣ s←'ST.?' Markdown.TokenScript ⎕SRC Markdown`.
   ⍝HELP 
   ⍝HELP where **options** are
   ⍝HELP 
   ⍝HELP - APL Variant (⍠) style specifications of internal (Markdown namespace) options, HTMLRenderer [𝟏] options, and Markdown JSON5 [𝟐] options. 
   ⍝HELP 
   ⍝HELP | Notes |  |
   ⍝HELP | --- |: --- |
   ⍝HELP | 𝟭. | See **Showdown** documention for the Showdown options. E.g.&nbsp;for&nbsp;general&nbsp;info:&nbsp;https://github.com/showdownjs/showdown; emojis:&nbsp;https://github.com/showdownjs/showdown/wiki/emojis|
   ⍝HELP | 𝟮. | Call **Markdown.defaults** for the list of option variables (shown in Javascript format).|
   ⍝HELP    
   ⍝HELP *Markdown.Show* returns the value **html**,
   ⍝HELP
   ⍝HELP - an HTMLRenderer-generated namespace, augmented with (each as a vector of character vectors):
   ⍝HELP     - `html.HTML`, generated by HTMLRenderer to contain all the HTML code displayed (including markdown and style info below);
   ⍝HELP     - `html.MD`, the generated Markdown source;
   ⍝HELP     - `html.STYLE`, a copy of any CSS style instructions used; 
   ⍝HELP     - `html.TITLE`, the title generated from the `('title' title)` option or the first header line found.
   ⍝HELP - When the variable html goes out of scope or is expunged, the HTML object rendered disappears.
   ⍝HELP                             
   ⍝HELP ### `Show` Options and Their Defaults  &nbsp;&nbsp;&nbsp;[See Notes below] 
   ⍝HELP
   ⍝HELP | `Show` options & defaults | Options & default at destination | Destination | 
   ⍝HELP |: ---- |: ----- |: ---- | 
   ⍝HELP |   ('size' (800 1000))              | ('Size' 800 1000) |  HTMLRenderer |        
   ⍝HELP |   ('posn' (5 5))                   | ('Posn' 5 5) | [𝟯]  |    
   ⍝HELP |   ('title' title)              | Displays passed or default title. The default title is the first user-specified Markdown header, if any. |  Markdown&nbsp;ns |        
   ⍝HELP |   ('style' 1)                   | Displays passed or default CSS style data | [𝟯]  |      
   ⍝HELP |   ('simpleLineBreaks' 0)           | simpleLineBreaks: false,  | Showdown Json5 |           
   ⍝HELP |   ('tables' 1)                     | tables: true,      | [𝟯]  |                      
   ⍝HELP |   ('strikethrough' 1)              |  strikethrough: true,    |  [𝟯]               |                  
   ⍝HELP |   ('omitExtraWLInCodeBlocks' 1)    |  omitExtraWLInCodeBlocks: true,  |    [𝟯]         |          
   ⍝HELP |   ('ghCompatibleHeaderId' 1)       |  ghCompatibleHeaderId: true, |   [𝟯]          |             
   ⍝HELP |   ('ghCodeBlocks' 1)               |  ghCodeBlocks: true,   |    [𝟯]          |                  
   ⍝HELP |   ('prefixHeaderId' 'custom-id-')  |  prefixHeaderId: 'custom-id-',   |  [𝟯]           |          
   ⍝HELP |   ('emoji' 1)                      |  emoji: true,           |     [𝟯]        |                  
   ⍝HELP |   ('tasklists' 1)                  |  tasklists: true,       |     [𝟯]        |                  
   ⍝HELP |   ('noHTMLBlocks' 0)               |  noHTMLBlocks: false,    |     [𝟯]        |                 
   ⍝HELP |   ('simplifiedAutoLink' 0)         |  simplifiedAutoLink: false  |  [𝟯]           |    
   ⍝HELP |   ('parseImgDimensions' 0)         |  parseImgDimensions: false, |   [𝟯]          |    
   ⍝HELP |   ('openLinksInNewWindow' 1)       |  openLinksInNewWindow: true, |  [𝟯, 𝟰]           |    
   ⍝HELP |   ('underline' 1)                  |  underline: true, |   [𝟯]          |     
   ⍝HELP |   ('style' 1)                      | Use our own added CSS stype overrides (default) | Markdown APL |  
   ⍝HELP |   ('style' 0)                      | Use showdown's built-in (and lackluster) CSS style | [𝟯] |                
   ⍝HELP  
   ⍝HELP -----------------
   ⍝HELP 
   ⍝HELP | Notes |  |
   ⍝HELP | --- |: --- |
   ⍝HELP | 𝟯. | Destination is the same as for the option just above. |
   ⍝HELP | 𝟰. | `openLinksInNewWindow`: if `1` (true), links appear selectable, but are ignored. If `0` (false), links are followed, but without any way to navigate back. |
   ⍝HELP 
   ⍝HELP ### Markdown.Show
   ⍝HELP Show returns the resulting HTML as a vector of character vectors.
   ⍝HELP 
   ⍝HELP 🛈 To see the returned HTML, store the result of ¨Show¨ in a variable:
   ⍝HELP
   ⍝HELP ```
   ⍝HELP html← Markdown.Show example
   ⍝HELP ```
   ⍝HELP 
   ⍝HELP 🛈 To remove the returned HTML permanently, let it go out of scope or delete or reset the variable.
   ⍝HELP
   ⍝HELP ```
   ⍝HELP ⎕EX 'html'    OR     html←''
   ⍝HELP ```
   ⍝HELP 
   ⍝HELP 🛈 To temporarily stop displaying the returned HTML, set html variable "visible" to 0:
   ⍝HELP
   ⍝HELP ```
   ⍝HELP html.visible←0     ⍝ To redisplay, set back to 1
   ⍝HELP ```
   ⍝HELP 
   ⍝HELP 🛈 To view the markdown example source, see Markdown.example below :point_down:. 
   ⍝HELP 
   ⍝HELP 🛈 See HTMLRenderer for other APL-side variables.
   ⍝HELP 
   ⍝HELP # How to add two numbers
   ⍝HELP 
   ⍝HELP ```
   ⍝HELP ⍝ An APL Session Example
   ⍝HELP a← '### How to add two numbers' '```A← 10 20 30' 'B←¯20 ¯40 ¯60' 'C← A+B' '⎕← C```' '> That''s all'
   ⍝HELP Markdown.Show a
   ⍝HELP ```
   ⍝HELP 
   ⍝HELP ### How to add two numbers
   ⍝HELP ```
   ⍝HELP A← 10 20 30
   ⍝HELP B← ¯20 ¯40 ¯60
   ⍝HELP C← A+B
   ⍝HELP ⎕← C
   ⍝HELP ``` 
   ⍝HELP > That's all
   ⍝HELP  
   ⍝HELP ### Markdown Utilities and Examples
   ⍝HELP #### :arrow_forward: Markdown.TokenScript
   ⍝HELP makes it easy to take comments in APL functions or namespaces and return them as Markdown or HTML code.
   ⍝HELP
   ⍝HELP > Find APL comment line /⍝tok/, foll. by /(\h|$)/. Whatever follows on each selected line is returned.
   ⍝HELP 
   ⍝HELP ```
   ⍝HELP vv← 'tok' Markdown.TokenScript ⎕NR ⊃⎕XSI     ⍝ ... in the current function.
   ⍝HELP vv← 'tok' Markdown.TokenScript ⎕SRC ⎕THIS    ⍝ ... in the current namespace.
   ⍝HELP ```
   ⍝HELP 
   ⍝HELP #### 🛈 A script to embed in an APL function. To retrieve the script, use token 'ADD'.
   ⍝HELP > For the output from running  `RunDemo`, see "How to add two numbers" above. 
   ⍝HELP 
   ⍝HELP ```
   ⍝HELP ∇ RunDemo ; myScript; x 
   ⍝HELP ⍝ADD ### How to add two numbers
   ⍝HELP ⍝ADD ```  
   ⍝HELP ⍝ADD A← 10 20 30 
   ⍝HELP ⍝ADD B←¯20 ¯40 ¯60 
   ⍝HELP ⍝ADD C← A+B 
   ⍝HELP ⍝ADD ⎕← C
   ⍝HELP ⍝ADD ``` 
   ⍝HELP ⍝ADD > That''s all
   ⍝HELP 
   ⍝HELP myScript← 'ADD' Markdown.TokenScript ⎕NR ⊃⎕XSI 
   ⍝HELP x← Markdown.Show myScript 
   ⍝HELP {}⍞
   ⍝HELP ∇
   ⍝HELP 
   ⍝HELP RunDemo 
   ⍝HELP ```
   ⍝HELP 
   ⍝HELP #### :arrow_forward: Markdown.Flatten 
   ⍝HELP converts a vector of character vectors to a flat char vector with each line prefixed by a character return.
   ⍝HELP
   ⍝HELP #### :arrow_forward: Markdown.example 
   ⍝HELP returns a nice Markdown example. (See also the source for Markdown.help)
   ⍝HELP
   ⍝HELP 🛈 To peruse the source for a Markdown example:
   ⍝HELP
   ⍝HELP ```
   ⍝HELP ⎕ED 'Markdown.example'      ⍝ NB. Editable read-write
   ⍝HELP ```
   ⍝HELP
   ⍝HELP 🛈 To view the Html page **generated from** `Markdown.example`, do: 
   ⍝HELP  
   ⍝HELP ```
   ⍝HELP h← Markdown.(Show example)
   ⍝HELP ```
   ⍝HELP 
   ⍝HELP #### :arrow_forward: Markdown.help
   ⍝HELP displays the help information for this Markdown namespace. *(Depress ¨return¨ when done.)*
   ⍝HELP 
   ⍝HELP ```
   ⍝HELP Markdown.help 
   ⍝HELP ```
   ⍝HELP
   ⍝HELP The source markdown generated by `Markdown.help` can be viewed several ways, including this one:
   ⍝HELP
   ⍝HELP ```
   ⍝HELP ⎕ED 'h.MD'⊣ h← Markdown.help 
   ⍝HELP ```
   ⍝HELP  
  :EndSection ⍝ Help 

  :Section Markdown_Example 
⍝  example: Markdown example
   ⍝EX 
   ⍝EX # An example of *Markdown* in the ***Showdown*** dialect
   ⍝EX
   ⍝EX
   ⍝EX ## A Paragraph (1)
   ⍝EX
   ⍝EX This shows how to separate lines of a paragraph via 2 trailing spaces, 
   ⍝EX just like **this:**  
   ⍝EX there are 2 spaces after the characters **this:** above.
   ⍝EX 
   ⍝EX ## A Paragraph (2)
   ⍝EX This is a paragraph with **bold** text and this Emoji smile :smile: is generated via 
   ⍝EX the expression :smile\:.  Since ('simpleLineBreaks' 0) is the default, 
   ⍝EX a single paragraph can be generated from multiple contiguous lines, as long as none
   ⍝EX has multiple trailing spaces. We have five such lines here (**sans** trailing spaces), making one paragraph. 
   ⍝EX This face 😜 is represented ***directly*** in APL (as unicode *128540*). 
   ⍝EX
   ⍝EX > If you want contiguous lines to include linebreaks, set `('simpleLineBreaks' 1)`
   ⍝EX > in the *APL* options. This line has an escaped underscore \__variable\__ and an ellipsis...
   ⍝EX 
   ⍝EX #### These lines produce level 1 and level 2 headings:
   ⍝EX 
   ⍝EX      This is a level 1 heading!
   ⍝EX      ==========================
   ⍝EX      # And so is this.
   ⍝EX 
   ⍝EX      This is a level 2 heading.
   ⍝EX      --------------------------
   ⍝EX      ## As is this! 
   ⍝EX 
   ⍝EX #### Below are the level 1 and level 2 headings produced from the source above!
   ⍝EX 
   ⍝EX This is a level 1 heading!
   ⍝EX ==========================
   ⍝EX # And so is this.
   ⍝EX 
   ⍝EX This is a level 2 heading.
   ⍝EX --------------------------
   ⍝EX ## As is this.
   ⍝EX 
   ⍝EX 1. This is a bullet
   ⍝EX      * This is a *sub-*bullet.
   ⍝EX           * A sub***ber*** bullet.
   ⍝EX           * And another!
   ⍝EX 
   ⍝EX 1. This is another top-level bullet. 
   ⍝EX 
   ⍝EX 1. As is this.
   ⍝EX      We right now do NOT allow simplified autolinks to places like http://www.dyalog.com.
   ⍝EX
   ⍝EX 1. A blockquote:
   ⍝EX     > Fourscore and seven years ago our fathers brought forth on this continent, a new nation, conceived in Liberty, 
   ⍝EX     > and dedicated to the proposition that all men are created equal.
   ⍝EX     
   ⍝EX 1. A final bullet?
   ⍝EX
   ⍝EX > Now we are engaged in a great civil war, testing whether that nation, or any nation so conceived and so dedicated, 
   ⍝EX > can long endure. We are met on a great battle-field of that war. 
   ⍝EX > We have come to dedicate a portion of that field, as a final resting place for those who here gave 
   ⍝EX > their lives that that nation might live. It is altogether fitting and proper that we should do this.
   ⍝EX 
   ⍝EX ### Tonnage of [Columbus' Ships](http://columbuslandfall.com/ccnav/ships.shtml)\. 
   ⍝EX 
   ⍝EX   | Ship  | Niña    | Pinta | Santa Maria |
   ⍝EX   |: ---- |: ----- :|:-----:|:-----:|
   ⍝EX   | Type | caravel | caravel | carrack |
   ⍝EX   | Tonnage | 50-60 tons   | 70 tons  | 100 tons |
   ⍝EX   | Perceived size | ~~big~~| ~~bigger~~ | ~~gigantic~~ |
   ⍝EX   | Actual size| shrimpy shrimp | small shrimp | jumbo shrimp |
   ⍝EX
   ⍝EX **Note**: The above link to Columbus' Ships is an *explicit* link, 
   ⍝EX which (by default) is not active. 
   ⍝EX If you set `('openLinksInNewWindow' 1)` as a **Show** option, 
   ⍝EX the link will be followed (displayed),
   ⍝EX but sadly there are *no navigation options* to allow a return to the original page.
   ⍝EX
   ⍝EX ----
   ⍝EX 
   ⍝EX This is code: `⍳2` 
   ⍝EX 
   ⍝EX And so is this, because it's set off with *6* blanks:
   ⍝EX 
   ⍝EX      ∇ P← A IOTA B
   ⍝EX        P← A ⍳ B
   ⍝EX      ∇
   ⍝EX
   ⍝EX This should all line up properly...
   ⍝EX ```
   ⍝EX w←⊃(⊃0⍴⍵){                           ⍝    ┌┌─2─┐           monadic; use ↓
   ⍝EX     (e a)←|⍺                         ⍝    ├ 0 0 1 1 1      dyadic;  use /
   ⍝EX     T←⌽⍣(0>⊃⌽⍺)                      ⍝    └──→⍺⍺←─────┐
   ⍝EX     Pad←⍵⍵⍉(T⊣)⍪⍵⍪(T⊢)               ⍝     ┌⍺┐  ⌺     │
   ⍝EX     need←(1+e),1↓⍴⍵                  ⍝     ┌─────⍵⍵──┐┘
   ⍝EX     a=0:(1↓need⍴0↑⍵)Pad(1↓need⍴0↑⊢⍵) ⍝  0 0│1 2 3 4 5│0 0  Zero
   ⍝EX     a=1:(1↓need⍴1↑⍵)Pad(1↓need⍴1↑⊖⍵) ⍝  1 1│1 2 3 4 5│5 5  Replicate
   ⍝EX     a=2:(⊖¯1↓need⍴⊢⍵)Pad(¯1↓need⍴⊖⍵) ⍝  2 1│1 2 3 4 5│5 4  Reverse
   ⍝EX     a=3:(⊖⊢1↓need⍴⊢⍵)Pad(⊢1↓need⍴⊖⍵) ⍝  3 2│1 2 3 4 5│4 3  Mirror
   ⍝EX     a=4:(⊖¯1↓need⍴⊖⍵)Pad(¯1↓need⍴⊢⍵) ⍝  4 5│1 2 3 4 5│1 2  Wrap
   ⍝EX }(¯1⌽⍳≢⍴⍵)/(⌽extra,¨⍺⊣0),⊂⍵          ⍝     └────⍵────┘
   ⍝EX ```
   ⍝EX
   ⍝EX ### What about tasks?
   ⍝EX + [x] This task is done. 
   ⍝EX - [ ] This is still pending 
   ⍝EX + [x] We knocked this out of the park! 
   ⍝EX 
   ⍝EX ### Goodbye:exclamation::exclamation::exclamation:
   ⍝EX 
  :EndSection ⍝ Markdown_Example

:EndSection ⍝ Alien_Stuff  
:EndNamespace 
