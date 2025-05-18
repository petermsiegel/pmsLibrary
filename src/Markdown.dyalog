:Namespace Markdown
⍝ For information on how to use, see ⍝HELP comments below...
⍝ Do not modify ⍝HTML, ⍝HELP, ⍝OPTS, and other comments of the form ¨⍝TOKEN¨.
:Section Constants 
    ⎕IO ⎕ML← 0 1 
    CR← ⎕UCS 13
:EndSection ⍝ Constants 

:Section Main_Routines  
⍝ Main routines and declarations
⍝ *** Show *** 
  ⍝ Show:     hNs@ns← newOpts ∇ markdown@CVV [style@CVV]
  ⍝ markdown: APL char vectors (CVV)  
  ⍝ newOpts:  New options for size, posn, style (all booleans); title (a string), 
  ⍝           and JSON option variables. 
  ⍝           Options are of the form: ('name' val), where a val of 1/0 is replaced by Json true/false.
  ⍝           Option names are in lowerCamelCase to be consistent with the Showdown markdown interface.
  ⍝ hNs:      Dyalog Render object (⎕WC namespace), which disappears when out of scope.
  Show←{    
  ⍝  0:: ⎕SIGNAL ⊂⎕DMX.{ ('EM' ( EM,⍨ ': ',⍨ ⍵↓⍨1+⍵⍳'.' ))('Message' Message)('EN' EN)} ⊃⎕XSI 
    
      _RShow← ⍠('ResultText' 'Simple')('EOL' 'CR')('Regex' (1 0))
      SetTitle← { ⍺≢  ⎕NULL: ⍕⍺ ⋄'*'~⍨ ⊃'#++\h?(.*)'⎕S '\1' ⍠('Mode' 'D')('ML' 1)⊢ ⍵ } 
      SetStyle← { ~⍺: 'STYLEC' Script src ⋄ 0=≢⍵: 'STYLEC?' Script src ⋄ ⍵ }

      ⍺← ⍬ ⋄ hN← #.⎕NS⍬ 
    ⍝ Get mdTxt and styleTxt from the one or two right arguments, depending on depth.
      mdTxt styleTxt← { 3≤ |≡⍵: ⍵ ⋄ ⍵ ⍬} ⊆⍵ 
      
    ⍝ ⍺ contains user's updated APL-style options. Default (and original) options are at ⍝OPTS below.
      src← ⎕SRC ⎕THIS 
      ns optsTxt← ⍺ SetOpts Flatten 'OPTS' Script src
      titleTxt← ns.title SetTitle mdTxt                     ⍝ Get title from ns.title or extract from mdTxt
      styleTxt← ns.style SetStyle styleTxt                  ⍝ Get styie from ns.style or styleTxt
      optTxt4← CR,¨ Flatten¨ mdTxt styleTxt titleTxt optsTxt
      stubs4←  '___'∘(,,⊣)¨ 'MARKDOWN' 'STYLE'  'TITLE'  'OPTS'  
      htmlTxt← stubs4 ⎕R optTxt4 _RShow 'HTML' Script src   ⍝ Add markdown, etc. to htmlTxt  
      HROpt← ('HTML'  htmlTxt) (ns.size,⍨ ⊂'Size') (ns.posn,⍨ ⊂'Posn') ('Coord' 'ScaledPixel')
      _← 'hN.htmlObj' ⎕WC 'HTMLRenderer',⍥⊆ HROpt           ⍝ Run HTMLRenderer
      hN.htmlObj ⊣ hN.htmlObj.(MD STYLE TITLE)← mdTxt styleTxt titleTxt  ⍝ Return the updated renderer obj. 
  }
  ⍝ *** Script ***
  ⍝ Script: CVV← token@CVregex ∇ src@CVV                    
  ⍝   See ⍝HELP documentation below.
  Script← { pfx src← ⍺ ⍵ ⋄ ('^\h*⍝', pfx, '(?:\h|$)(.*)') ⎕S '\1'⊣ src }
    
  ⍝ help: {html@ns}← ∇
  ⍝   To see the markdown source, see: html.MD 
  ∇ {html}← help  
    html← ('size',⍥⊂ 900 900)('posn',⍥⊂ 5 5) Show 'HELP' Script ⎕SRC ⎕THIS 
    {}⍞
  ∇
:EndSection ⍝ Main_Routines

:Section Variables 
  ⍝ example: e← ∇
  ⍝   A markdown example.  
  example← 'EX' Script ⎕SRC ⎕THIS 
:EndSection Variables

:Section Internal_Utilities
  ⍝ *** Flatten ***
  ⍝ Flatten:  CcrV← ∇ CVV                               
  ⍝   Convert vector of char vectors into a CV with carriage returns. 
  ⍝   Keep a CR before the FIRST line! 
  Flatten← 1∘↓(∊,⍨¨∘CR⍤⊆) 

  ⍝ *** SetOpts ***
  ⍝ SetOpts:   aplOut jsonOut← aplIn ∇ jsonIn
  ⍝    ∘ Load existing Markdown options in Json5 string format (jsonIn);
  ⍝    ∘ Merge any new options passed from APL as ⍠-style key-value pairs (aplIn), 
  ⍝      replacing 0, 1, ⎕NULL with (⊂'false'), (⊂'true'), (⊂'null') and vice versa for apl option form.
  ⍝ Returns updated options in ¨apl ns form¨ and ¨json text form¨.
  SetOpts←{ 
      aSty jSty← ¯1 1             ⍝ Styles
      J5← ⎕JSON⍠('Dialect' 'JSON5')('Null' ⎕NULL)('Compact' 0)  ⍝ Json null <=> APL ⎕NULL  
      Î← ↓⍉⍤↑                     ⍝ Invert:    (k v)(k v) <=> KK VV  
      ∆NS←{ ⍺← ⎕NS⍬ ⋄ ns← ⍺ ⋄ ns⊣ { ns⍎⍺,'←⍵'}/¨ ⍵ }
      _Set_← {                    ⍝ Set ⍵[0] to val ⍵[1] in namespace ⍺⍺ using style ⍵⍵
          ns sty← ⍺⍺ ⍵⍵
          in out← (1 0)(⊂¨'true' 'false')⌽⍨ sty≠1 
          Map← Î {kk vv← Î ⍵ ⋄ kk,⍥⊂ (in⍳ vv)⊃¨ ⊂out}
          Sel← {in∊⍨ ⊃∘⌽¨⍵}
          ns ∆NS Map@Sel ⍵
          ⍝ ns⊣ { ns⍎ ⍺,'←⍵' }/¨ Map@Sel ⍵
      }   
      SetJ← {                     ⍝ Merge APL opts ⍺ into Json5 ⍵; return new json string.
          (a jRaw) ns← ⍺ ⍵
        0=≢  a: jRaw
        2=|≡a: (,⊂a) jRaw ∇ ns 
          J5 ns _Set_ jSty⊢ a 
      }             
      SetA← {                     ⍝ Convert values of all ns vars to APL-style.
          kv← Î k,⍥⊂ ⍵.⎕OR¨ k← ⍵.⎕NL ¯2
          ⍵ _Set_ aSty⊢ kv
      }                   

      ns← J5 ⍵                    ⍝ ⍵ (Json5) => ns 
      (SetA ns) (⍺ ⍵ SetJ ns )    ⍝ Return ns in APL-style and string j in Json5-style
  }
:EndSection ⍝ Internal_Utilities

:Section Scripts 
  :Section HTML_Code 
  ⍝ -------------------------------------------------------------------------------------------
  ⍝  Markdown-to-Html code-- "showdown" dialect
  ⍝HTML <!DOCTYPE html>
  ⍝HTML <html>
  ⍝HTML <head>
  ⍝HTML   <title>
  ⍝      // The Markdown title goes here.
  ⍝HTML       ___TITLE___
  ⍝HTML   </title>
  ⍝HTML   <style> 
  ⍝      // CTSS style statements go here.
  ⍝HTML  ___STYLE___ 

  ⍝      // CTSS style statements follow...
  ⍝STYLE :root {
  ⍝STYLE    --default-text-color: #333333;
  ⍝STYLE    --muted-text-color: #666666;
  ⍝STYLE    --link-color: #f05675;
  ⍝STYLE    --muted-border-color: #dddddd;
  ⍝STYLE    --muted-background-color: #eeeeee;
  ⍝STYLE    --codeblock-background-color: #772222;
  ⍝STYLE    --codeblock-text-color: #eeeeee;
  ⍝STYLE  }
  ⍝STYLE  table {
  ⍝STYLE    font-family: arial, sans-serif;
  ⍝STYLE    width: 90%;
  ⍝STYLE  }
  ⍝STYLE  td, th {
  ⍝STYLE    border: 2px black;
  ⍝STYLE    background-color:rgba(244, 239, 232, 0.77);
  ⍝STYLE    padding: 8px;
  ⍝STYLE  }
  ⍝STYLE  tr:nth-of-type(odd) {
  ⍝STYLE    background-color: lightBlue;
  ⍝STYLE    color: darkBlue;
  ⍝STYLE  } 
  ⍝STYLE  tr:nth-of-type(even) {
  ⍝STYLE    background-color: lightRed;
  ⍝STYLE    color: darkRed;
  ⍝STYLE  }
  ⍝STYLE  blockquote {
  ⍝STYLE    font-family: Baskerville, Garamond, Georgia; 
  ⍝STYLE    font-size: 110%;
  ⍝STYLE    border-left: 3px solid darkRed;
  ⍝STYLE    padding-left: 5px;
  ⍝STYLE    color:rgb(0, 50, 3);
  ⍝STYLE  }
  ⍝STYLE  pre {
  ⍝STYLE    padding: 1rem;
  ⍝STYLE    border-radius: 4px;
  ⍝STYLE    color: var(--codeblock-text-color);
  ⍝STYLE    background-color: var(--codeblock-background-color);
  ⍝STYLE    overflow-x: auto;
  ⍝STYLE  }
  ⍝STYLEC code {
  ⍝STYLEC  font-size: 90%;
  ⍝STYLEC   font-family: "APL386 Unicode", APL385, "APL385 Unicode", "Courier New", Courier, 
  ⍝STYLEC                "Lucida Console", "Consolas", monospace;
  ⍝STYLEC }

  ⍝HTML   </style>
  ⍝       // This is where we load the javascript which does the actual conversion...
  ⍝HTML   <script src="https://cdnjs.cloudflare.com/ajax/libs/showdown/2.1.0/showdown.min.js" 
  ⍝HTML        integrity="sha512-LhccdVNGe2QMEfI3x4DVV3ckMRe36TfydKss6mJpdHjNFiV07dFpS2xzeZedptKZrwxfICJpez09iNioiSZ3hA==" 
  ⍝HTML        crossorigin="anonymous" referrerpolicy="no-referrer">
  ⍝HTML   </script>
  ⍝HTML </head>
  ⍝HTML <body>
  ⍝HTML   <div id="markdown-content" style="display:none;">
  ⍝       // User Markdown goes here  
  ⍝HTML      ___MARKDOWN___  
  ⍝           
  ⍝HTML   </div>
  ⍝HTML   <div id="html-content"></div>
  ⍝HTML   <script>
  ⍝HTML     var markdownText = document.getElementById('markdown-content').textContent;
  ⍝      // Markdown Options in Json5 format go here
  ⍝HTML     var opts = ___OPTS___;   

  ⍝      //  Markdown Options in Json5 format follow...
  ⍝OPTS⍝    // Json Markdown options (Showdown dialect)
  ⍝OPTS⍝    // ∘ For all binary (true/false) options except ghCodeBlocks, 
  ⍝OPTS⍝    //   the "built-in" default value is (false), potentially overridden here!
  ⍝OPTS⍝    // -------------------------------------------------------------------------------
  ⍝OPTS⍝    // Simple line break: If true, simple line break in paragraph emits <br>.
  ⍝OPTS⍝    //                    If false (default), simple line break does not emit <br>.
  ⍝OPTS⍝    // "APL" only opts...
  ⍝OPTS     {
  ⍝OPTS        title: null, style: 1, posn: [5, 5], size: [800, 1000],
  ⍝OPTS⍝    // True JSON opts...  
  ⍝OPTS        simpleLineBreaks: false, 
  ⍝OPTS⍝    // Enable tables 
  ⍝OPTS        tables: true,
  ⍝OPTS⍝    // Enable strikethrough 
  ⍝OPTS        strikethrough: true,
  ⍝OPTS⍝    // Omit extra line break in code blocks
  ⍝OPTS        omitExtraWLInCodeBlocks: true,
  ⍝OPTS⍝    // Enable GitHub-compatible header IDs
  ⍝OPTS        ghCompatibleHeaderId: true,
  ⍝OPTS⍝    // Fenced code blocks. True (default), enable code blocks with ``` ... ``` 
  ⍝OPTS        ghCodeBlocks: true,
  ⍝OPTS⍝    // Prefix header IDs with "custom-id-"
  ⍝OPTS        prefixHeaderId: 'custom-id-',
  ⍝OPTS⍝    // Enable emoji support 
  ⍝OPTS        emoji: true,
  ⍝OPTS⍝    // Enable task lists 
  ⍝OPTS        tasklists: true,
  ⍝OPTS⍝    // Disable automatic wrapping of HTML blocks
  ⍝OPTS        noHTMLBlocks: false,
  ⍝OPTS⍝    // Allow simple URLs like http://dyalog.com in text to be treated as actual links. 
  ⍝OPTS⍝    // Keep in mind that selecting a link will leave the Markdown page, w/o an easy way  
  ⍝OPTS⍝    // to return (except by recreating the page).
  ⍝OPTS        simplifiedAutoLink: false,        
  ⍝OPTS⍝    // Enable support for setting image dimensions in Markdown,  
  ⍝OPTS⍝    //      e.g. ![foo](foo.jpg =100x80)  OR ![baz](baz.jpg =80%x5em)
  ⍝OPTS        parseImgDimensions: false, 
  ⍝OPTS⍝    // Force new links to open in a new window
  ⍝OPTS⍝    // In reality, if <true> links are suppressed when using HTMLRenderer.
  ⍝OPTS⍝    // If <false>, then the links are followed, but there is no mechanism to get back.
  ⍝OPTS        openLinksInNewWindow: true, 
  ⍝OPTS⍝    // if true, suppresses any special treatment of underlines 
  ⍝OPTS⍝    // *** Doesn't appear to make any difference ***
  ⍝OPTS        underline: true,
  ⍝OPTS    }

  ⍝HTML     const converter = new showdown.Converter(opts);
  ⍝HTML     const html = converter.makeHtml(markdownText);
  ⍝HTML     document.getElementById('html-content').innerHTML = html;
  ⍝HTML   </script>
  ⍝HTML </body>
  ⍝HTML </html>
  :EndSection ⍝ HTML_Code 

  :Section Help_Info 
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
   ⍝HELP | Script     | Return Markdown (HTML, etc.) strings from namespace or function comments prefixed with a specific token.| lines← 'token' |∇ | lines |
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
   ⍝HELP typically extracted (via Markdown.Script) from comments in the current function or namespace;
   ⍝HELP     - If a single vector, it will be treated as a 1-element vector of character vectors.
   ⍝HELP 
   ⍝HELP where **style** is 
   ⍝HELP 
   ⍝HELP - an optional vector of character vectors containing standard CSS style information, 
   ⍝HELP often extracted (via Markdown.Script) from comments in the current function or namespace;
   ⍝HELP and defaulting to something reasonable;
   ⍝HELP     - To view the default CSS style, do `⎕ED 's'⊣ s←'STYLEC?' Markdown.Script ⎕SRC Markdown`.
   ⍝HELP 
   ⍝HELP where **options** are APL variant-style (⍠) specifications [𝟏] of:
   ⍝HELP 
   ⍝HELP - `Show` function options, 
   ⍝HELP - `HTMLRenderer` options, and 
   ⍝HELp -  *Markdown Json5* [𝟐] options. 
   ⍝HELP 
   ⍝HELP | Notes |  |
   ⍝HELP | --- |: --- |
   ⍝HELP | 𝟭. | See **Show Options & Their Defaults** below for the list of option variables (in "APL" and Javascript formats).|
   ⍝HELP | 𝟮. | See **Showdown** documention for details on the Showdown options. E.g.&nbsp;for&nbsp;general&nbsp;info:&nbsp;https://github.com/showdownjs/showdown; emojis:&nbsp;https://github.com/showdownjs/showdown/wiki/emojis|
   ⍝HELP
   ⍝HELP #### Return value
   ⍝HELP *Markdown.Show* returns the value **html**,
   ⍝HELP - an HTMLRenderer-generated namespace, augmented with (each as a vector of character vectors):
   ⍝HELP     - `html.HTML`, generated by HTMLRenderer to contain all the HTML code displayed (including markdown and style info below);
   ⍝HELP     - `html.MD`, the generated Markdown source;
   ⍝HELP     - `html.STYLE`, a copy of any CSS style instructions used; 
   ⍝HELP     - `html.TITLE`, the title generated from the `('title' title)` option or the first header line found.
   ⍝HELP - When the variable html goes out of scope or is expunged, the HTML object rendered disappears.
   ⍝HELP                             
   ⍝HELP ### Show Options & Their Defaults
   ⍝HELP ##### &nbsp;&nbsp;&nbsp;[See Notes below] 
   ⍝HELP
   ⍝HELP |  Options in Show (APL) env. | Options & defaults in target env. | Target env. | 
   ⍝HELP |: ---- |: ----- |: ---- | 
   ⍝HELP |   ('size' (800 1000))              | ('Size' 800 1000) |  HTMLRenderer |        
   ⍝HELP |   ('posn' (5 5))                   | ('Posn' 5 5) | [𝟯]  |    
   ⍝HELP |   ('title' title)              | Displays passed or default title. The default title is the first user-specified Markdown header, if any. The default title is selected if no title option is specified or if `('title' ⎕NULL)` is specified. |  Show&nbsp;function |        
   ⍝HELP |   ('style' 1)                   | Displays passed or default CSS style data | [𝟯]  |      
   ⍝HELP |   ('style' 0)                      | Use showdown's built-in (and lackluster) CSS style | [𝟯] |                
   ⍝HELP |   ('simpleLineBreaks' 0)           | simpleLineBreaks: false,  | Showdown&nbsp;Translator |           
   ⍝HELP |   ('tables' 1)                     | tables: true,      | [𝟯]  |                      
   ⍝HELP |   ('strikethrough' 1)              |  strikethrough: true,    |  [𝟯]               |                  
   ⍝HELP |   ('omitExtraWLInCodeBlocks'&nbsp;1)    |  omitExtraWLInCodeBlocks:&nbsp;true,  |    [𝟯]         |          
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
   ⍝HELP x← Markdown.Show a
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
   ⍝HELP #### :arrow_forward: Markdown.Script
   ⍝HELP makes it easy to take comments in APL functions or namespaces and return them as Markdown or HTML code.
   ⍝HELP
   ⍝HELP > Find APL comment line /⍝tok/, foll. by /(\h|$)/. Whatever follows on each selected line is returned.
   ⍝HELP 
   ⍝HELP ```
   ⍝HELP vv← 'tok' Markdown.Script ⎕NR ⊃⎕XSI     ⍝ ... in the current function.
   ⍝HELP vv← 'tok' Markdown.Script ⎕SRC ⎕THIS    ⍝ ... in the current namespace.
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
   ⍝HELP myScript← 'ADD' Markdown.Script ⎕NR ⊃⎕XSI 
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
  :EndSection ⍝ Help_Info 

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
   ⍝EX This `APL` should all line up properly...
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

:EndSection ⍝ Scripts  
:EndNamespace 
