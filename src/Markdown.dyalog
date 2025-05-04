:Namespace Markdown

:Section Main_Routines  
⍝
⍝ -------------------------------------------------------------------------------------------
⍝ Main routines and declarations
⍝ *** Show *** 
  ⍝ Show:     hNs@ns← newOpts ∇ markdown@CVV
  ⍝ markdown: APL char vectors (CVV)  
  ⍝ newOpts:  New options for size and JSON option variables. Of the form
  ⍝          ('emoji' 0), ('tables' 1), ('size' (500 400)), 1 for Json true and 0 for false.
  ⍝ hNs:      Dyalog Render object (⎕WC namespace)
  ⍝           hNs.HTML contains the generated HTML as a character vector with CR's (via HTMLRenderer)
  ⍝           hNs.MD contains the source markdown used to generate it.
  ⍝           hNs.STYLE contains any CSS Style code (that goes between <style> and </style>)
  ⍝ Once the result returned disappears, the generated HTML object disappears also.
  ⍝ Do:              h← size Markdown.Show ... 
  ⍝ Then to delete:  ⎕EX 'h' OR h←''
  Show←{
    0:: ⎕SIGNAL ⊂⎕DMX.(('EM' EM)('Message' Message)('EN' EN))
      ⍺← ⍬ ⋄ o← ⍺ ⋄ hN← #.⎕NS⍬                      ⍝ Raw user markdown => hN.MD 
      mdTxt styleTxt ← { 3=≡⍵: ⍵ ⋄ ⍵ ⍬} ⍵ 
      (sizeOpt posnOpt styleOpt titleOpt) h0← o MergeOpts⊢ src← ⎕SRC ⎕THIS 
    ⍝ - If a title option is NOt used, the first markdown header (#, ##, etc.) 
    ⍝   will be the title (caption) for the HTML. * chars (for bold, italics) are deleted.
      titleTxt← titleOpt{
        0≠≢⍺: ⍺
            '*'~⍨ ⊃'#++\h?(.*)'⎕S '\1' ⍠('Mode' 'D')('ML' 1)⊢ ⍵
      } mdTxt 
      styleTxt← styleOpt{ 
          ~⍺: 'STC' Here src 
          0=≢⍵: 'STC?' Here src 
            ⍵ 
      } styleTxt         
      htmlTxt← h0 Customise mdTxt styleTxt titleTxt  ⍝ Insert the markdown text into the HTML/JS src code   
      optL← ('HTML'  htmlTxt) (sizeOpt,⍨ ⊂'Size') (posnOpt,⍨ ⊂'Posn') ('Coord' 'ScaledPixel')
      _← 'hN.htmlObj' ⎕WC 'HTMLRenderer',⍥⊆ optL     ⍝ Render and return the HTML object
      hN.htmlObj.(MD STYLE)← mdTxt styleTxt
      hN.htmlObj  
  }
  ⍝ *** Here ***
  ⍝ Here: CVV← token@CV ∇ CVV                    
  ⍝   Find payload in char vectors (CV) following ('^\h*⍝',token,'\h|$') in a vector of CV's. 
  ⍝     - If the token is 'XX', we match /^\h*⍝XX/ followed by /\h|$/. 
  ⍝       I.e., it will match XX, but not (simple) X, XY, XXX, etc.
  ⍝     - If the "token" is 'XX?' or 'X{1,2}', we will match X, XX, but not XY or XXX.
  ⍝   What follows the token and any following blank is the payload /(.*)/'. 
  Here← {  
    pfx src← ⍺ ⍵
    re←'^\h*⍝', pfx, '(?:\h|$)(.*)'                        
    re ⎕S '\1'⊣ src 
  }
  ⍝ *** defaults ***
  ⍝ defaults: d← ∇
  ⍝   Show the default options in JSON format, including 
  ⍝  'size' and 'posn'  used in the HTMLRenderer call.
  ∇ d← defaults ;pfx; defs; Q 
    Q← {q, q,⍨ ⍵/⍨ 1+⍵=q←''''} 
    pfx←  CR,     '  // HTMLRenderer options in Json format'
    pfx,← CR, CR,⍨'     size: [', '],',⍨ 1↓∊',',¨⍕¨sizeDef 
    pfx,←     CR,⍨'     posn: [', '],',⍨ 1↓∊',',¨⍕¨posnDef 
    pfx,←     CR,⍨  '  // Markdown.Show-internal options in Json format'
    pfx,←     CR,⍨'     style: ', ',',⍨ styleDef⊃ 'false' 'true'
    pfx,←     CR,⍨'     title: ', ',',⍨ Q titleDef 
    defs← '^\h{4}' ⎕R ' ' RE._Simple⊢ 'JS[CO]' Here ⎕SRC ⎕THIS 
    d← '{', pfx, defs, '}'  
  ∇
  ⍝ example: e← ∇
  ⍝   A markdown example.  
  ∇ e← example  
    e← 'EX' Here ⎕SRC ⎕THIS                                        
  ∇
  ⍝ help: {html@ns}← ∇
  ⍝   To see the markdown source, see: html.MD 
  ∇ {html}← help ; src  
    html← ('size',⍥⊂ 900 900)('posn',⍥⊂ 5 5) Show 'HELP' Here ⎕SRC ⎕THIS 
    {}⍞
  ∇

⍝ -------------------------------------------------------------------------------------------
⍝ Constants
  ⎕IO ⎕ML← 0 1 
  CR← ⎕UCS 13
⍝ -------------------------------------------------------------------------------------------
⍝ Variables                                          ⍝ size: height, width; posn: y, x 
  sizeDef posnDef styleDef← (800 1000) (5 5) 1       ⍝ style: 1=use our CSS styles, 0=use minimal defaults
  titleDef← ''                                       ⍝ default title (otherwise from markdown #...)
  exampleT← ''                                       ⍝ See  ∇ example ∇  
:EndSection ⍝ Main_Routines

:Section Internal_Utilities
⍝ -------------------------------------------------------------------------------------------
  ⍝ *** Customise ***
  ⍝ Customise:   CVV← ht@CVV ∇ md@CVV style@CVV                             
  ⍝   Insert md (markdown stmts) and style (CSS style stmts) into ⍺:ht (html) at ___MARKDOWN___
  ⍝   Don't process escape chars in the replacement field...
  Customise← {   
      ht (md st ti)← ⍺ (CR,¨Flatten¨ ⍵) 
      '___MARKDOWN___' '___STYLE___'  '___TITLE___'  ⎕R md st ti RE._Simple  RE._RE10⊢ ht 
  }
  ⍝ *** Flatten ***
  ⍝ Flatten:  CcrV← ∇ CVV                               
  ⍝   Convert vector of char vectors into a CV with carriage returns. 
  ⍝   Keep a CR before the FIRST line! 
  Flatten← 1∘↓(∊,⍨¨∘CR⍤⊆) 

  ⍝ *** MergeOpts ***
  ⍝ MergeOpts: 
  ⍝    ∘ Load old Markdown options (in Json format);
  ⍝    ∘ Merge any new options passed from APL, replacing 0 and 1 with (⊂'false') and (⊂'true'); 
  ⍝    ∘ Separate off the pseudo-option `size: [n1 n2]` and returning separately as (n1 n2);
  ⍝    ∘ Replace the ___OPTS___ stub in the HTML code with the up-to-date Json options.
  MergeOpts← { 
    optE← 'Each option must consist of exactly two items: a keyword and a scalar value' 11
    optNms← 'size' 'posn' 'style' 'title'
    optsIn src← ⍺ ⍵                                          ⍝ optsIn: size, posn, style, title
    oldJ← '{', CR, (Flatten 'JSO' Here src), CR, '}'          ⍝ JO: Default JSON options
    optsDef← ⎕OR¨ optNms,¨⊂'Def'
    optsOut curJ← oldJ (optsDef MergeJ optNms) optsIn               ⍝ optsOut: size, posn, style, title
    htmlOut← '___OPTS___' ⎕R curJ RE._Simple 'HT' Here src                      
    optsOut,⍥⊂ htmlOut                                       ⍝ HT: HTML including "stubs" for options, etc.
  } 
⍝ See MergeOpts
  MergeJ← {  true← ⊂⊂'true' ⋄ false← ⊂⊂'false'
      _J5← ⍠'Dialect' 'JSON5' 
      JIn← { 0=≢⍵:⎕NS ⍬ ⋄ ⎕JSON _J5  ⍵ }   
      L← { ,∘⊂⍣(2=|≡⍵)⊢ ⍵ }                     
      A2J←{ true false ⍵⊃⍨ 1 0⍳ ⊂⍵ } ⋄ J2A←{ ⍵≡ true: 1 ⋄ ⍵≡ false: 0 ⋄ ⍵ }
      ⍙Set← { ⍺ ⍺⍺.{ ⍎⍺,'←⍵' } ⍵ }              
      Merge← {(⍺ ⍙Set∘A2J)/¨⍵} 
      HOut←  { 0≠ ⎕NC ⍺⍺,⍺: (⎕EX ⍺⍺,⍺)⊢ J2A ⎕OR ⍺⍺,⍺ ⋄ ⍵ }
      ⍺← '{}' ⋄ j hDef← ⍺ ⍺⍺
    0=≢⍵:  j,⍨⍥⊂ hDef  
    2∨.≠ ≢¨ opts← L ⍵: ⎕SIGNAL/ optE 
      _← (ns←JIn j) Merge opts
      (⎕JSON _J5 ns),⍨⍥⊂ ⍵⍵ ('ns.' HOut)¨ hDef
  }
:EndSection ⍝ Internal_Utilities

:Section Regular_Expressions
  :Namespace RE
     _Simple← ⍠('ResultText' 'Simple')('EOL' 'CR')
     _RE10←   ⍠'Regex' (1 0)
  :EndNamespace 
:EndSection ⍝ Regular_Expressions 

:Section Alien_Stuff 
  :Section HTML_Code 
⍝ -------------------------------------------------------------------------------------------
⍝  Markdown-to-Html code-- "showdown" dialect
   ⍝HT <!DOCTYPE html>
   ⍝HT <html>
   ⍝HT <head>
   ⍝HT   <title>
   ⍝HT       ___TITLE___
   ⍝HT   </title>
   ⍝HT   <style> 
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
   ⍝       <!-- User Markdown goes here -->
   ⍝HT     ___MARKDOWN___             
   ⍝HT   </div>
   ⍝HT   <div id="html-content"></div>
   ⍝HT   <script>
   ⍝HT     var markdownText = document.getElementById('markdown-content').textContent;
   ⍝HT     var opts = ___OPTS___;    // Json Markdown options go here...
      
   ⍝JSC      // Json Markdown options (Showdown dialect)
   ⍝JSC      // ∘ For all binary (true/false) options except ghCodeBlocks, 
   ⍝JSC      //   the "built-in" default value is (false), potentially overridden here!
   ⍝JSC      // -------------------------------------------------------------------------------
   ⍝JSC      // Simple line break: If true, simple line break in paragraph emits <br>.
   ⍝JSC      //                    If false (default), simple line break does not emit <br>.
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
   ⍝JSC      // *** Doesn't appear to make any difference ***
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
   ⍝H
   ⍝HELP ## Help for Markdown.dyalog APL Utility
   ⍝HELP 
   ⍝HELP | :arrow_forward: |Use Markdown in an HTMLRenderer session in Dyalog|
   ⍝HELP |: --- :|: --- |
   ⍝HELP | :arrow_forward: |Based on the **Showdown** dialect of *Markdown*. See: https://showdownjs.com/. |
   ⍝HELP 
   ⍝HELP ## Key Routines
   ⍝HELP 
   ⍝HELP | Routine | Usage                                                   |         | Call   | Syntax |       |
   ⍝HELP |: ----   |: ---                                                    |   ---  :|: ---  :|   ---  |: ---  |
   ⍝HELP | Show    | Process and Display Markdown text via the HTMLRenderer  | HtmlNs← | [opts] | ∇      | CVV   |
   ⍝HELP | example | A bells-and-whistles Markdown example                   |CVV←     |        | ∇      |       |
   ⍝HELP | help    | Display (this) help information |[HtmlNs←]|| ∇ ||
   ⍝HELP | defaults | Show Markdown & HTMLRenderer defaults used |CV←||∇||
   ⍝HELP | Here | Pull Markdown from APL comments '⍝tok' in ⍵, a vector of "strings" ⍵. Examples of ⍵: `⎕SRC ⎕THIS`; `⎕NR ⊃⎕XSI`, etc. | CVV← |'tok' |∇ | CVV |
   ⍝HELP | Flatten | Convert APL char vector of vectors to a simple char vector (each line prefixed with a carriage return). | CV← || ∇ | CVV |
   ⍝HELP 
   ⍝HELP 
   ⍝HELP ## Using Markdown.Show:
   ⍝HELP 
   ⍝HELP ```md
   ⍝HELP [html←]  [options] Markdown.Show markdown
   ⍝HELP ```
   ⍝HELP 
   ⍝HELP where **markdown** is 
   ⍝HELP 
   ⍝HELP - a vector of character vectors containing standard "Showdown-style" Markdown, 
   ⍝HELP often extracted (via Markdown.Here) from comments in the current function or namespace.
   ⍝HELP 
   ⍝HELP and **options** are
   ⍝HELP 
   ⍝HELP - APL Variant (⍠) style specifications of [𝟏] HTMLRenderer and [𝟐] Markdown JSON5 options.      
   ⍝HELP    
   ⍝HELP *Markdown.Show* returns the value **html**,
   ⍝HELP
   ⍝HELP - an HTMLRenderer-generated namespace, augmented with MD, a copy of the generated Markdown source;
   ⍝HELP - When the variable html goes out of scope or is expunged, the HTML object rendered disappears.
   ⍝HELP                             
   ⍝HELP ### Options  [See Notes] 
   ⍝HELP | Show option | Format at destination | Destination | 
   ⍝HELP |: ---- |: ----- |: ---- | 
   ⍝HELP |   ('size' (800 1000))              | ('Size' 800 1000) |  HTMLRenderer |        
   ⍝HELP |   ('posn' (5 5))                   | ('Posn' 5 5) | [𝟯]  |         
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
   ⍝HELP |   ('openLinksInNewWindow' 1)       |  openLinksInNewWindow: true, |  [𝟯]           |    
   ⍝HELP |   ('underline' 1)                  |  underline: true, |   [𝟯]          |     
   ⍝HELP |   ('style' 1)                      | Use our own added CSS stype overrides (default) | Markdown APL |  
   ⍝HELP |   ('style' 0)                      | Use showdown's built-in (and lackluster) CSS style | [𝟯] |                
   ⍝HELP  
   ⍝HELP -----------------
   ⍝HELP 
   ⍝HELP | Notes |  |
   ⍝HELP | --- |: --- |
   ⍝HELP | 𝟭. | See **Showdown** documention for the Showdown options. E.g.&nbsp;for&nbsp;general&nbsp;info:&nbsp;https://github.com/showdownjs/showdown; emojis:&nbsp;https://github.com/showdownjs/showdown/wiki/emojis|
   ⍝HELP | 𝟮. | Call **Markdown.defaults** for the list of option variables (shown in Javascript format).|
   ⍝HELP | 𝟯. | Same as above |
   ⍝HELP 
   ⍝HELP ### Markdown.Show
   ⍝HELP Show returns the resulting HTML as a vector of character vectors.
   ⍝HELP 
   ⍝HELP 🛈 To see the returned HTML, store the result of ¨Show¨ in a variable:
   ⍝HELP
   ⍝HELP         html← Markdown.Show example
   ⍝HELP 
   ⍝HELP 🛈 To remove the returned HTML permanently, delete or reset the variable:
   ⍝HELP
   ⍝HELP         ⎕EX 'html'    OR     html←''
   ⍝HELP 
   ⍝HELP 🛈 To temporarily stop displaying the returned HTML, set html variable "visible" to 0:
   ⍝HELP
   ⍝HELP         html.visible←0     ⍝ To redisplay, html.visible←1
   ⍝HELP 
   ⍝HELP 🛈 To view the markdown example source, see Markdown.example below :point_down:. 
   ⍝HELP 
   ⍝HELP 🛈 See HTMLRenderer for other APL-side variables.
   ⍝HELP  
   ⍝HELP ### Markdown Utilities and Examples
   ⍝HELP #### :arrow_forward: Markdown.defaults 
   ⍝HELP returns all the HTML-directed and Markdown Showdown-dialect Json5 variables.
   ⍝HELP 
   ⍝HELP #### :arrow_forward: Markdown.Here
   ⍝HELP makes it easy to take comments in APL functions or namespaces and return them as Markdown or HTML code.
   ⍝HELP
   ⍝HELP                                              ⍝ Find APL comment line /⍝tok/, foll. by /(\h|$)/
   ⍝HELP        vv← 'tok' Markdown.Here ⊃⎕XSI         ⍝ ... in the current function.
   ⍝HELP        vv← 'tok' Markdown.Here ⎕SRC ⎕THIS    ⍝ ... in the current namespace.
   ⍝HELP 
   ⍝HELP #### :arrow_forward: Markdown.Flatten 
   ⍝HELP converts a vector of character vectors to a flat char vector with each line prefixed by a character return.
   ⍝HELP
   ⍝HELP #### :arrow_forward: Markdown.example 
   ⍝HELP contains a nice Markdown example. (See also the source for Markdown.help)
   ⍝HELP
   ⍝HELP 🛈 To see the example source, do:
   ⍝HELP
   ⍝HELP        {⎕ED 'a'⊣ a←⍵} Markdown.example
   ⍝HELP
   ⍝HELP 🛈 To see the result, do: 
   ⍝HELP  
   ⍝HELP        x← Markdown.(Show example)
   ⍝HELP 
   ⍝HELP #### :arrow_forward: Markdown.help
   ⍝HELP displays help information for this Markdown namespace.
   ⍝HELP 
   ⍝HELP        Markdown.help 
   ⍝HELP
   ⍝HELP The source for markdown help can be viewed several ways, including this one:
   ⍝HELP
   ⍝HELP       {⍵.⎕ED 'MD' }Markdown.help
   ⍝HELP  
  :EndSection ⍝ Help 

  :Section Example 
⍝ -------------------------------------------------------------------------------------------
⍝  example: Markdown example source 
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
   ⍝EX has 3 (or more) trailing spaces. We have five (5) such lines here making one paragraph. 
   ⍝EX This face 😜 is represented ***directly*** in APL (as unicode *128540*). 
   ⍝EX
   ⍝EX > If you want contiguous lines to include linebreaks, set ***('simpleLineBreaks' 1)***
   ⍝EX > in the *APL* options. This line has an escaped underscore \__variable\__ and an ellipsis...
   ⍝EX 
   ⍝EX #### These lines produce level 1 (#) and level 2 (##) headings:
   ⍝EX 
   ⍝EX      This is a level 1 heading!
   ⍝EX      ==========================
   ⍝EX 
   ⍝EX      This is a level 2 heading.
   ⍝EX      --------------------------
   ⍝EX 
   ⍝EX #### Below are the level 1 and level 2 headings produced from the source above!
   ⍝EX 
   ⍝EX This is a level 1 heading!
   ⍝EX ==========================
   ⍝EX 
   ⍝EX This is a level 2 heading.
   ⍝EX --------------------------
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
   ⍝EX **Note**: The above link to Columbus' Ships is an *explicit* link.
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
  :EndSection ⍝ example

:EndSection ⍝ Alien_Stuff  
:EndNamespace 
