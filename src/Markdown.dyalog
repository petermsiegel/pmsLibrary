:Namespace Markdown
⍝ Here: CVV← token@CV ∇  [CVV]                    
⍝   Find source of form ('⍝',token) in a vector of char vectors 
⍝   NB: If ⍺ is 'X', then it must be foll. by either at least one blank OR the end of the line.
⍝       I.e. the token after /\h*⍝/ must match exactly; it is not a (simple) prefix. 
  Here← { 
    re←'^\s*⍝', ⍺, '(?|\h(.*)|())$'              
    re ⎕S '\1'⊣ ⍵ 
  }
⍝ MD:   CVV← CVV ∇ CVV                             
⍝   Insert ⍺:markdown into ⍵:js at ___MYTEXT___
  MD← { 
      _Once← ⍠('ML' 1)      
      md← Flat '\\' ⎕R '\\\\'⊢ ⍺ 
      '^\h*___MYTEXT___.*$' ⎕R md _Once⊣ ⍵ 
  }
⍝ Flat:  CnlV← ∇ CVV                               
⍝   Convert vector of char vectors into a CV with newlines.
  Flat← {¯1↓ ∊⍵,¨ ⎕UCS 13}⊆
:Namespace Html 
⍝ Html.Render: Ø← size@I[2] ∇ js@CVV
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

∇ {js}← {size} Show markdown; h 
⍝ js@CVV← size@IV=(800 100) ∇ markdown@CVV
⍝ markdown: APL char vectors (CVV)  
⍝ size:     Html window size  
⍝ js:       Html and Javascript code to display markdown <markdown> as HTML    
  :If 900⌶⍬ ⋄ size← 800 1000 ⋄ :EndIf 
  js← markdown MD 'C' Here ⎕SRC ⎕THIS               ⍝ Insert the markdown text into the Javascript code   
  ⎕← 'Enter empty line...             to close Markdown html after viewing, or'
  ⎕← 'Type any char and hit return... to refresh Markdown html.' 
  :Repeat  
       h← size Html.Render js
  :Until 0= ≢ ⍞↓⍨ ≢ ⍞← '>>> '
∇

⍝  example: Markdown example source 
⍝X # An example of *Markdown* in the ***Showdown*** dialect
⍝X
⍝X This is a paragraph with **bold** text and this Emoji smile :smile: is marked via :smile\:.
⍝X This face 😜 is represented _directly_ in APL. 
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
⍝X This should work. Does it?  
⍝X ```
⍝X +/⍺⍳⍵
⍝X -\⍵⍳⍺
⍝X ```
⍝X
⍝X ### What about tasks?
⍝X - [x] This task is done
⍝X - [ ] This is still pending
⍝X 
⍝X ### Goodbye:exclamation::exclamation::exclamation:
⍝X 

⍝  Markdown code-- "showdown" javascript
⍝C <!DOCTYPE html>
⍝C <html>
⍝C <head>
⍝C   <title>Showdown Example</title>
⍝C   <script src="https://cdnjs.cloudflare.com/ajax/libs/showdown/2.1.0/showdown.min.js"></script>
⍝C </head>
⍝C <body>
⍝C   <div id="markdown-content" style="display:none;">
⍝C     ___MYTEXT___          // User Markdown will replace this entire line!
⍝C   </div>
⍝C   <div id="html-content"></div>
⍝C   <script>
⍝C     var markdownText = document.getElementById('markdown-content').textContent;
⍝C     const converter = new showdown.Converter({
⍝C      // For all options except ghCodeBlocks, the values are false
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
⍝C      // Simple line break: If true, simple line break in paragraph emits <br>.
⍝C      //                    If false (default), simple line break does not emit <br>.
⍝C         simpleLineBreaks: false, 
⍝C      // Allow simple URLs like dyalog.com to be treated as actual links. 
⍝C         simplifiedAutoLink: true,           
⍝C     });
⍝C     const html = converter.makeHtml(markdownText);
⍝C     document.getElementById('html-content').innerHTML = html;
⍝C   </script>
⍝C </body>
⍝C </html>

:EndNamespace 
