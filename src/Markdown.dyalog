:Namespace Markdown
⍝D ## Markdown Utility (namespace)
⍝D 
⍝D - Use Markdown in an HTMLRenderer session in Dyalog
⍝D - Based on the *Showdown* dialect of *Markdown*
⍝D 
⍝D | Routine | Usage | &nbsp;&nbsp; | Type ||
⍝D |: ---- |: --- | --- :|: --- :|: --- |
⍝D | Show | Primary Display Function | Ns← [opts] | ∇ | CVV |
⍝D | example | A bells-and-whistles example |CVV←| ∇ ||
⍝D | help | This help information || ∇ ||
⍝D | defaults | Show Markdown & HTMLRenderer defaults used |CV←|∇||
⍝D | Here | Pull Markdown from APL comments in fn or class | CVV← pfx |∇ | ⎕SRC ⎕THIS |
⍝D |      |                                                | CVV← pfx |∇ | ⎕NR ⊂⎕XSI |
⍝D | Flat | Convert APL char vector of vectors to a simple char vector (with CR's) | CV← | ∇ | CVV |
⍝D 
⍝D 
⍝D ### Usage:
⍝D 
⍝D [**html**←]  [**options**] Markdown.Show **markdown** 
⍝D 
⍝D where **markdown** is 
⍝D 
⍝D     a vector of character vectors containing standard "Showdown-style" Markdown
⍝D 
⍝D and **options** are
⍝D 
⍝D     APL Variant (⍠) style specifications of HTMLRenderer or Markdown JSON5 options:      
⍝D                                
⍝D ### Options sent to HTMLRenderer
⍝D | Show option | What HTMLRenderer sees | 
⍝D |: ---- |: ----- | 
⍝D |   ('size' (800 1000))              | ('Size' 800 1000) |         
⍝D |   ('posn' (5 5))                   | ('Posn' 5 5) |  
⍝D 
⍝D ### Options converted to Json and sent to Javascript Markdown Showdown translator 
⍝D | Show option | What Markdown sees | 
⍝D |: ---- |: ----- |          
⍝D |   ('simpleLineBreaks' 0)           | simpleLineBreaks: false,  |            
⍝D |   ('tables' 1)                     | tables: true,      |                   
⍝D |   ('strikethrough' 1)              |  strikethrough: true,   |               
⍝D |   ('omitExtraWLInCodeBlocks' 1)    |  omitExtraWLInCodeBlocks: true,  |      
⍝D |   ('ghCompatibleHeaderId' 1)       |  ghCompatibleHeaderId: true, |          
⍝D |   ('ghCodeBlocks' 1)               |  ghCodeBlocks: true,   |                
⍝D |   ('prefixHeaderId' 'custom-id-')  |  prefixHeaderId: 'custom-id-',   |      
⍝D |   ('emoji' 1)                      |  emoji: true,           |               
⍝D |   ('tasklists' 1)                  |  tasklists: true,       |               
⍝D |   ('noHTMLBlocks' 0)               |  noHTMLBlocks: false,    |              
⍝D |   ('simplifiedAutoLink' 0)         |  simplifiedAutoLink: false  | 
⍝D   
⍝D  Note [1]: See **Showdown** documention, especially for the Github options.  
⍝D  Note [2]: Call **Markdown.defaults** for the list of option variables (shown in Javascript format).
⍝D 
⍝D ### Markdown.Show
⍝D Show returns the resulting HTML as a vector of character vectors.
⍝D 
⍝D      To see the returned HTML, store the result of ¨Show¨ in a variable:
⍝D
⍝D         html← Markdown.Show example
⍝D 
⍝D      To remove the returned HTML permanently, delete or reset the variable:
⍝D
⍝D         ⎕EX 'html'    OR     html←''
⍝D 
⍝D      To temporarily stop displaying the returned HTML, set html variable "visible" to 0:
⍝D
⍝D         html.visible←0     ⍝ To redisplay, html.visible←1
⍝D 
⍝D      See HTMLRenderer for other APL-side variables.
⍝D  
⍝D ### Markdown Utilities and Examples
⍝D #### Markdown.defaults 
⍝D     returns all the HTML-directed and Markdown Showdown-dialect Json variables.
⍝D 
⍝D #### Markdown.Here
⍝D     makes it easy to take comments in APL functions and return them as Markdown or HTML code.
⍝D 
⍝D        vv← 'pfx' Markdown.Here ⊃⎕XSI     ⍝ Find '⍝pfx' lines in the current function.
⍝D 
⍝D #### Markdown.Flat 
⍝D     converts a vector of character vectors to a flat char vector with carriage returns. 
⍝D 
⍝D #### Markdown.example 
⍝D     contains a nice example. 
⍝D 
⍝D To see the example source, do:
⍝D 
⍝D      a←Markdown.example
⍝D      )ed a
⍝D 
⍝D To see the result, do: 
⍝D  
⍝D        x← Markdown.(Show example)
⍝D 
⍝D #### Markdown.help
⍝D     shows help information for Markdown.
⍝D 
⍝D        Markdown.help 
⍝D  
⍝
⍝ -------------------------------------------------------------------------------------------
⍝ Main routines
⍝ *** Show *** 
  ⍝ Show:     hNs@ns← newOpts ∇ markdown@CVV
  ⍝ markdown: APL char vectors (CVV)  
  ⍝ newOpts:  New options for size and JSON option variables. Of the form
  ⍝          ('emoji' 0), ('tables' 1), ('size' (500 400)), 1 for Json true and 0 for false.
  ⍝ hNs:      Dyalog Render object (⎕WC namespace)
  ⍝           hNs.HTML contains the generated HTML as a character vector with CR's (via HTMLRenderer)
  ⍝           hNs.MD contains the source markdown used to generate it.
  ⍝ Once the result returned disappears, the generated HTML object disappears also.
  ⍝ Do:              h← size Markdown.Show ... 
  ⍝ Then to delete:  ⎕EX 'h' OR h←''
  Show←{
    0:: ⎕SIGNAL ⊂⎕DMX.(('EM' EM)('Message' Message)('EN' EN))
      ⍺← ⍬ ⋄ o← ⍺ ⋄ md← Flat ⍵ 
      s hj← o MergeOpts ⎕SRC ⎕THIS 
      html← hj InsertMD md                            ⍝ Insert the markdown text into the HTML/JS code   
      r← s HtmlRender html                            ⍝ Render and return the HTML object
      r⊣ r.MD← ⍵                                      ⍝ Make a private copy of the markdown from the user...
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
  ⍝  'size' and 'posn'  used on the HTMLRenderer page.
  ∇ d← defaults  ;s; p; defs
    s←    '   size: [', ']',⍨ 1↓∊',',¨⍕¨sizeDef 
    p←    '   posn: [', ']',⍨ 1↓∊',',¨⍕¨posnDef 
    defs← '^\s+' ⎕R '   ' RE._Simple⊢ 'J' Here ⎕SRC ⎕THIS 
    d← '{', CR, s, CR, p, CR, defs, '}'  
  ∇
  ⍝ example: e← ∇
  ⍝   A markdown example.  
  ∇ e← example                                         
    e← { 0=≢⍵: exampleT⊢← 'M' Here ⎕SRC ⎕THIS ⋄ ⍵ } exampleT 
  ∇
  ∇ wait← help  ;r
    r← ('size' (900 900)) Show 'D' Here ⎕SRC ⎕THIS 
    wait←⍞⊢⍞←'> '
  ∇
⍝ -------------------------------------------------------------------------------------------
⍝ Constants
  ⎕IO ⎕ML← 0 1 
  CR← ⎕UCS 13
⍝ -------------------------------------------------------------------------------------------
⍝ Variables 
  sizeDef posnDef← (800 1000) (5 5)                  ⍝ size: height, width; posn: y, x 
  exampleT← ''                                       ⍝ See  ∇ example ∇  

⍝ -------------------------------------------------------------------------------------------
⍝ Internal Utilities
  ⍝ *** InsertMD ***
  ⍝ InsertMD:   CVV← CVV ∇ CVV                             
  ⍝   Insert ⍺:markdown into ⍵:html at ___MYTEXT___
  ⍝   Don't process escape chars in the replacement field...
  InsertMD← {  
      '^\h*___MYTEXT___.*$'  ⎕R ⍵ RE._Simple RE._Once RE._RE10⊢ ⍺ 
  }
  ⍝ *** Flat ***
  ⍝ Flat:  CcrV← ∇ CVV                               
  ⍝   Convert vector of char vectors into a CV with carriage returns.
  Flat← {¯1↓ ∊⍵,¨ CR}⊆
  
⍝ ⎕R options we use...
  :Namespace RE
     _Simple← ⍠('ResultText' 'Simple')('EOL' 'CR')
     _Once←   ⍠'ML' 1
     _RE10←   ⍠'Regex' (1 0)
  :EndNamespace 
  
  ⍝ *** HtmlRender ***
  ⍝ HtmlRender: ns.htmlObj@HTMLRenderer_obj← size@I2 posn@I2 ∇ html@CVV
  ⍝   Returns an html renderer object generated by ⎕WC.
  HtmlRender← {  
    s p← ⍺ 
    parms← ('HTML',⍥⊂ ⍵) (s,⍨ ⊂'Size') (p,⍨ ⊂'Posn') ('Coord' 'ScaledPixel')
    ns← #.⎕NS⍬                                       ⍝ Private ns for generated obj 
    _← 'ns.htmlObj' ⎕WC 'HTMLRenderer',⍥⊆ parms     ⍝ Generate the renderer as ns.htmlObj. 
    ns.htmlObj                                        ⍝ Return the generated object itself.
  }  

  ⍝ *** MergeOpts ***
  ⍝ MergeOpts: 
  ⍝    ∘ Load old Markdown options (in JSON format);
  ⍝    ∘ Merge any new options passed from APL, replacing 0 and 1 with (⊂'false') and (⊂'true'); 
  ⍝    ∘ Separate off the pseudo-option `size: [n1 n2]` and returning separately as (n1 n2);
  ⍝    ∘ Replace the ___OPTS___ stub in the HTML code with the up-to-date JSON options.
    ⍝ JMerge: 
    ⍝   ∘ Merge new APL-specified options into existing Json options
    ⍝   ∘ Returning the new or default size@IV[2]
    ⍝ ((sizeOut@I[2] posnOut@I[2]) jsonOut@CVV)← [jsonIn←''] (sizeDef@I[2] posnDef@I[2] ∇) opt1 [opt2 ...]
    ⍝ jsonIn:
    ⍝   a JSON5 list of key-value pairs or null.
    ⍝ sizeDef, posnDef
    ⍝   the default size/posn variables for use in an HTMLRenderer call.
    ⍝   ∘ Each has 2 items: (integers: height, width) and posn (integers: y and x offsets)
    ⍝   ∘ Their value  will be the ¨size¨ and ¨posn¨ returned, unless an option overrides it.
    ⍝ optN:
    ⍝   an APL-style key-value pair of the form ('Name' value).
    ⍝   A value of 1 or 0 will be replaced by ⊂'true' or ⊂'false', respectively.
    ⍝   Special case: keys 'size' and 'posn' will have their value replace the default size.
    ⍝       The size value must be of the form (height width);
    ⍝       The posn value must be of the form (y and x offsets):
    ⍝       ('size' (1000 600)) and ('posn' (5 5)) 
    ⍝ sizeOut, posnOut
    ⍝   The values set per above, either the defaults or explicitly set values.
    ⍝ jsonOut:
    ⍝   The 2nd element returned; a char. string representing the udpated
    ⍝   JSON5 key-value pairs.
  MergeOpts← { 
    JMerge←{
        T F← ⊂∘⊂¨'true' 'false'   ⍝ JSON true (1) and false (0)
        Json← ⎕JSON⍠'Dialect' 'JSON5'
        JImport← {0=≢⍵:⎕NS ⍬ ⋄ Json ⍵}
        Canon← { ,∘⊂⍣(2≥|≡⍵)⊢ ⍵ }
        J2A← { 
          ⍺ ⍺⍺.{
            2=≢⍵:⍎⍺,'←⍵'
            em← 'Options must consist of exactly two items: a key and a (scalar) value'
            em ⎕SIGNAL 11
          }⊃T F ⍵/⍨1,⍨1 0≡¨ ⊂⍵ 
        }
        GetHOpt← 'ns.' { 0≠ ⎕NC ⍺⍺,⍺: (⎕EX ⍺⍺,⍺)⊢ ⎕OR ⍺⍺,⍺ ⋄ ⍵ }
        ⍺← '{}' ⋄ j (s p)← ⍺ ⍺⍺
      0=≢⍵:  j,⍨⍥⊂ s p 
        ns← JImport j ⋄ _← (ns J2A)/¨ Canon ⍵
        (Json ns),⍨⍥⊂ ('size' GetHOpt s) ('posn' GetHOpt p)
    }
    optsApl src← ⍺ ⍵ 
    jStub← '___OPTS___'
    jOld← '{', CR, (Flat 'J' Here src), CR, '}'                 ⍝ J: Default JSON
    sp jNow← jOld (sizeDef posnDef JMerge) optsApl              ⍝ sp: size pair and posn pair
    JUpdate← jStub ⎕R jNow RE._Simple RE._Once                      
    sp,⍥⊂ JUpdate 'H' Here src                                  ⍝ H: Includes stub for JSON
  } 

⍝ -------------------------------------------------------------------------------------------
⍝  example: Markdown example source 
⍝M # An example of *Markdown* in the ***Showdown*** dialect
⍝M
⍝M ## A Paragraph
⍝M This is a paragraph with **bold** text and this Emoji smile :smile: is generated via 
⍝M the expression :smile\:.  By ***default***, we have set **simpleLineBreaks: false**, so 
⍝M a single paragraph can be generated from multiple contiguous lines.
⍝M We have four such lines here making one paragraph. This face 😜 is represented _directly_ in APL. 
⍝M
⍝M **Note**:
⍝M If you want contiguous lines to include linebreaks, set ***('simpleLineBreaks' 1)***
⍝M in the *APL* options.
⍝M 
⍝M 1. This is a bullet
⍝M      * This is a *sub-*bullet.
⍝M           * A sub***ber*** bullet.
⍝M           * And another!
⍝M 1. This is another top-level bullet. 
⍝M 1. As is this.
⍝M      We right now do NOT allow simplified autolinks to places like http://www.dyalog.com.
⍝M
⍝M     > A blockquote would look great here...
⍝M
⍝M 1. A final bullet?
⍝M 
⍝M ### Tonnage of [Columbus' Ships](http://columbuslandfall.com/ccnav/ships.shtml)\. 
⍝M 
⍝M   | Ship  | Niña    | Pinta | Santa Maria |
⍝M   |: ---- |: ----- :|:-----:|:-----:|
⍝M   | Type | caravel | caravel | carrack |
⍝M   | Tonnage | 50-60 tons   | 70 tons  | 100 tons |
⍝M   | Perceived size | ~~big~~| ~~bigger~~ | ~~gigantic~~ |
⍝M   | Actual size| shrimpy shrimp | small shrimp | jumbo shrimp |
⍝M
⍝M **Note**: The above link to Columbus' Ships is an *explicit* link.
⍝M
⍝M ----
⍝M 
⍝M This is code: `⍳2` 
⍝M 
⍝M This is *also* code: <code>⍳3</code> 
⍝M 
⍝M And so is this:
⍝M 
⍝M      ⍝ Set off with 6 blanks
⍝M        ∇ P← A IOTA B
⍝M          P← A ⍳ B
⍝M        ∇
⍝M
⍝M This should work. Does it? (**Yes**)
⍝M ```
⍝M +/⍺⍳⍵
⍝M -\⍵⍳⍺
⍝M ```
⍝M
⍝M ### What about tasks?
⍝M + [x] This task is done
⍝M - [ ] This is still pending
⍝M + [x] We knocked this out of the park!
⍝M 
⍝M ### Goodbye:exclamation::exclamation::exclamation:
⍝M 

⍝ -------------------------------------------------------------------------------------------
⍝  Markdown-to-Html code-- "showdown" javascript
⍝H <!DOCTYPE html>
⍝H <html>
⍝H <head>
⍝H   <title>Showdown Example</title>
⍝H   <script src="https://cdnjs.cloudflare.com/ajax/libs/showdown/2.1.0/showdown.min.js" 
⍝H        integrity="sha512-LhccdVNGe2QMEfI3x4DVV3ckMRe36TfydKss6mJpdHjNFiV07dFpS2xzeZedptKZrwxfICJpez09iNioiSZ3hA==" 
⍝H        crossorigin="anonymous" referrerpolicy="no-referrer">
⍝H   </script>
⍝H </head>
⍝H <body>
⍝H   <div id="markdown-content" style="display:none;">
⍝H     ___MYTEXT___          // User Markdown will replace this entire line!
⍝H   </div>
⍝H   <div id="html-content"></div>
⍝H   <script>
⍝H     var markdownText = document.getElementById('markdown-content').textContent;
⍝H     var opts = ___OPTS___;    // Stub for JSON options
⍝H     const converter = new showdown.Converter(opts);
⍝H     const html = converter.makeHtml(markdownText);
⍝H     document.getElementById('html-content').innerHTML = html;
⍝H   </script>
⍝H </body>
⍝H </html>

⍝ -------------------------------------------------------------------------------------------
⍝  JSON Option Defaults. Used in place of ___OPTS___ above 
⍝     var opts = {
⍝        // For all options except ghCodeBlocks, the DEFAULT value is false
⍝        // Simple line break: If true, simple line break in paragraph emits <br>.
⍝        //                    If false (default), simple line break does not emit <br>.
⍝J          simpleLineBreaks: false, 
⍝        // Enable tables 
⍝J          tables: true,
⍝        // Enable strikethrough 
⍝J          strikethrough: true,
⍝        // Omit extra line break in code blocks
⍝J          omitExtraWLInCodeBlocks: true,
⍝        // Enable GitHub-compatible header IDs
⍝J          ghCompatibleHeaderId: true,
⍝        // Fenced code blocks. True (default), enable code blocks with ``` ... ``` 
⍝J          ghCodeBlocks: true,
⍝        // Prefix header IDs with "custom-id-"
⍝J          prefixHeaderId: 'custom-id-',
⍝        // Enable emoji support 
⍝J          emoji: true,
⍝        // Enable task lists 
⍝J          tasklists: true,
⍝        // Disable automatic wrapping of HTML blocks
⍝J          noHTMLBlocks: false,
⍝        // Allow simple URLs like http://dyalog.com in text to be treated as actual links. 
⍝        // Keep in mind that selecting a link will leave the Markdown page, w/o an easy way  
⍝        // to return (except by recreating the page).
⍝J          simplifiedAutoLink: false,           
⍝    }
:EndNamespace 
