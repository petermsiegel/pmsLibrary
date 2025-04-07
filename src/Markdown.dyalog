:Namespace Markdown
⍝⍝⍝⍝ Use Markdown in an HTMLRenderer session in Dyalog
⍝⍝⍝⍝ Usage:
⍝⍝⍝⍝   [html←]  [size] Markdown.Show markdown
⍝⍝⍝⍝ where ¨markdown¨ is a vector of character vectors containing standard "Showdown-style" Markdown.
⍝⍝⍝⍝ and ¨size¨ is an optional size in pixels of the resulting page (default: 800 1000).
⍝⍝⍝⍝ ¨Show¨ returns the resulting HTML as a vector of character vectors.
⍝⍝⍝⍝ 
⍝⍝⍝⍝ There are a couple of useful utilities, such as ¨Here¨ and ¨Flat¨.
⍝⍝⍝⍝ ¨Here¨ makes it easy to take comments in APL functions and return them as Markdown or HTML code.
⍝⍝⍝⍝ ¨Flat¨ convers a vector of character vectors to a flat char vector with carriage returns. 
⍝⍝⍝⍝
⍝⍝⍝⍝   Markdown.example
⍝⍝⍝⍝ contains a nice example. To see the result, do:
⍝⍝⍝⍝   Markdown.(Show example)
⍝⍝⍝⍝
⍝⍝⍝⍝ 
  ⍝ Here: CVV← token@CV ∇ CVV                    
  ⍝   Find payload in char vectors (CV) matching ('^\h*⍝',token) in a vector of CV's. 
  ⍝   If the token is XX, we match /^\h*⍝XX/ followed by /\h|$/. 
  ⍝   What follows /.*$/ is the payload. 
  Here← { 
    re←'^\h*⍝', ⍺, '(?:\h|$)(.*)'                        
    re ⎕S '\1'⊣ ⍵ 
  }
  ⍝ MD:   CVV← CVV ∇ CVV                             
  ⍝   Insert ⍺:markdown into ⍵:html at ___MYTEXT___
  MD← { 
      _Once← ⍠('ML' 1) 
      Esc_← '\\' ⎕R '\\\\'      
      from to← '^\h*___MYTEXT___.*$' (Flat Esc_ ⍺)
      from  ⎕R to _Once⊣ ⍵ 
  }
  ⍝ Flat:  CcrV← ∇ CVV                               
  ⍝   Convert vector of char vectors into a CV with carriage returns.
  Flat← {¯1↓ ∊⍵,¨ ⎕UCS 13}⊆
:Namespace Html 
  ⍝ Html.Render: Ø← size@I[2] ∇ html@CVV
  ⍝   Sets html variable in caller namespace...
  Render← {  
    h← 'HTML',⍥⊂ ##.Flat ⍵
    s← ⍺,⍨ ⊂'Size'
    c← 'Coord' 'ScaledPixel' 
    me← ⎕NS ⍬
    me⊣ 'me.htmlObj' ⎕WC 'HTMLRenderer' h s c  
  } 
:EndNamespace 

example← 'X' Here ⎕SRC ⎕THIS                       ⍝ a markdown example.  

∇ {html}← {size} Show markdown; h 
⍝ html@CVV← size@IV=(800 1000) ∇ markdown@CVV
⍝ markdown: APL char vectors (CVV)  
⍝ size:     Html window size  
⍝ html:       Html and Javascript code to display markdown <markdown> as HTML    
  :If 900⌶⍬ ⋄ size← 800 1000 ⋄ :EndIf 
  html← markdown MD 'C' Here ⎕SRC ⎕THIS               ⍝ Insert the markdown text into the Javascript code   
  h← size Html.Render html
  {} ⍞↓⍨ ≢ ⍞← '>>> '
∇

⍝ -------------------------------------------------------------------------------------------
⍝  example: Markdown example source 
⍝X # An example of *Markdown* in the ***Showdown*** dialect
⍝X
⍝X ## A Paragraph
⍝X This is a paragraph with **bold** text and this Emoji smile :smile: is generated via 
⍝X the expression :smile\:.  We have set **simpleLineBreaks: false**, so a single paragraph 
⍝X can be generated from multiple contiguous lines.
⍝X We have four such lines here making one paragraph. This face 😜 is represented _directly_ in APL. 
⍝X
⍝X 1. This is a bullet
⍝X      * This is a *sub-*bullet.
⍝X           * A sub***ber*** bullet.
⍝X           * And another!
⍝X 1. This is another top-level bullet. 
⍝X 1. As is this.
⍝X      We allow simplified autolinks to places like http://www.dyalog.com.
⍝X
⍝X     > A blockquote would look great here...
⍝X
⍝X 1. A final bullet?
⍝X 
⍝X ### Tonnage of [Columbus' Ships](http://columbuslandfall.com/ccnav/ships.shtml)\. 
⍝X 
⍝X   | Ship  | Niña    | Pinta | Santa Maria |
⍝X   |: ---- |: ----- :|:-----:|:-----:|
⍝X   | Type | caravel | caravel | carrack |
⍝X   | Tonnage | 50-60 tons   | 70 tons  | 100 tons |
⍝X   | Perceived size | ~~big~~| ~~bigger~~ | ~~gigantic~~ |
⍝X   | Actual size| shrimpy shrimp | small shrimp | jumbo shrimp |
⍝X
⍝X This is code: `⍳2` 
⍝X 
⍝X This is *also* code: <code>⍳3</code> 
⍝X 
⍝X And so is this:
⍝X 
⍝X      ⍝ Set off with 6 blanks
⍝X        ∇ P← A IOTA B
⍝X          P← A ⍳ B
⍝X        ∇
⍝X
⍝X This should work. Does it? (**Yes**)
⍝X ```
⍝X +/⍺⍳⍵
⍝X -\⍵⍳⍺
⍝X ```
⍝X
⍝X ### What about tasks?
⍝X + [x] This task is done
⍝X - [ ] This is still pending
⍝X + [x] We knocked this out of the park!
⍝X 
⍝X ### Goodbye:exclamation::exclamation::exclamation:
⍝X 

⍝ -------------------------------------------------------------------------------------------
⍝  Markdown-to-Html code-- "showdown" javascript
⍝C <!DOCTYPE html>
⍝C <html>
⍝C <head>
⍝C   <title>Showdown Example</title>
⍝C   <script src="https://cdnjs.cloudflare.com/ajax/libs/showdown/2.1.0/showdown.min.js" 
⍝C        integrity="sha512-LhccdVNGe2QMEfI3x4DVV3ckMRe36TfydKss6mJpdHjNFiV07dFpS2xzeZedptKZrwxfICJpez09iNioiSZ3hA==" 
⍝C        crossorigin="anonymous" referrerpolicy="no-referrer">
⍝C   </script>
⍝C </head>
⍝C <body>
⍝C   <div id="markdown-content" style="display:none;">
⍝C     ___MYTEXT___          // User Markdown will replace this entire line!
⍝C   </div>
⍝C   <div id="html-content"></div>
⍝C   <script>
⍝C     var markdownText = document.getElementById('markdown-content').textContent;
⍝C     const converter = new showdown.Converter({
⍝C      // For all options except ghCodeBlocks, the DEFAULT value is false
⍝C      // Simple line break: If true, simple line break in paragraph emits <br>.
⍝C      //                    If false (default), simple line break does not emit <br>.
⍝C         simpleLineBreaks: false, 
⍝C      // Enable tables 
⍝C         tables: true,
⍝C      // Enable strikethrough 
⍝C         strikethrough: true,
⍝C      // Omit extra line break in code blocks
⍝C         omitExtraWLInCodeBlocks: true,
⍝C      // Enable GitHub-compatible header IDs
⍝C         ghCompatibleHeaderId: true,
⍝C      // Fenced code blocks. True (default), enable code blocks with ``` ... ``` 
⍝C         ghCodeBlocks: true,
⍝C      // Prefix header IDs with "custom-id-"
⍝C         prefixHeaderId: 'custom-id-',
⍝C      // Enable emoji support 
⍝C         emoji: true,
⍝C      // Enable task lists 
⍝C         tasklists: true,
⍝C      // Disable automatic wrapping of HTML blocks
⍝C         noHTMLBlocks: false,
⍝C      // Allow simple URLs like http://dyalog.com in text to be treated as actual links. 
⍝C      // Keep in mind that selecting a link will leave the Markdown page, w/o an easy way  
⍝/      // to return (except by recreating the page).
⍝C         simplifiedAutoLink: true,           
⍝C     });
⍝C     const html = converter.makeHtml(markdownText);
⍝C     document.getElementById('html-content').innerHTML = html;
⍝C   </script>
⍝C </body>
⍝C </html>
:EndNamespace 
