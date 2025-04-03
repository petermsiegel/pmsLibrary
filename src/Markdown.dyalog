:Namespace Markdown
  nl← ⎕UCS 10
  Esc←    '\\'  ⎕R  '\\\\'        
⍝ Src:  CVV← ∇ ['C'|'X']              Find source of form '⍝C' or '⍝X' in comments in this namespace 
  Src←  { src←'^\s*⍝', ⍵, '\s?(.*)$' ⋄ src ⎕S '\1'⊣ ⎕SRC ⎕THIS }
⍝ MD:   CVV← CVV ∇ CVV                Insert ⍺:markdown into ⍵:js at ___MYTEXT___
  MD← { md← Flt ⍺ ⋄ '^\h*___MYTEXT___.*$' ⎕R md⊣ ⍵ }
⍝ Flt:  CnlV← ∇ CVV                   Convert vector of char vectors into a CV with newlines.
  Flt← {¯1↓ ∊nl,⍨¨ ⊆⍵}

example← Src 'X'                       ⍝ /⍝X.../ - a markdown example. Stored as VV

∇ {js}← {size} Show markdown; md; html  
⍝ markdown: APL char vectors (CVV)  
⍝ size:     Html window size (IV[2], default: 800 1000)
⍝ js:       Javascript code to display markdown <markdown> as HTML  (CnlV: CV with newlines)  
⍝ extern: html
  :If 900⌶⍬ ⋄ size← 800 1000 ⋄ :EndIf 
  md← Esc markdown                      ⍝ Add escapes to the markdown                                       
  js← md MD Src 'C'                     ⍝ Insert the markdown text into the Javascript code    
  'html' ⎕WC 'HTMLRenderer' ('HTML',⍥⊂ Flt js) (size,⍨ ⊂'Size')('Coord' 'ScaledPixel')
  ⎕← 'Hit return after viewing html...'
  {}⍞↓⍨≢⍞←'<return> '
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
⍝X 
⍝X     > A blockquote would look great here...
⍝X 1. A final bullet?
⍝X 
⍝X ### Tonnage of Columbus' Ships
⍝X 
⍝X   | Ship | Niña |  Pinta | Santa Maria |
⍝X   |: ---- |: ----- :|:-----:|:-----:|
⍝X   | Tonnage | 50-60 tons   | 70 tons  | [100 tons](https://www.lakewizard.com/post/100-ton-boat/) |
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
⍝X ### Goodbye!
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
⍝C     ___MYTEXT___          // User Markdown will go here!
⍝C   </div>
⍝C   <div id="html-content"></div>
⍝C   <script>
⍝C     var markdownText = document.getElementById('markdown-content').textContent;
⍝C     const converter = new showdown.Converter({
⍝C      // We can just stick with the defaults. Options marked with *** seem to be very useful.
⍝C      // Enable tables ***
⍝C         tables: true,
⍝C      // Enable strikethrough ***
⍝C         strikethrough: true,
⍝C      // Omit extra line break in code blocks
⍝C         omitExtraWLInCodeBlocks: true,
⍝C      // Enable GitHub-compatible header IDs
⍝C         ghCompatibleHeaderId: true,
⍝C      // Fenced code blocks. True (default), enable code blocks with ``` ... ``` 
⍝C         ghCodeBlocks: true,
⍝C      // Prefix header IDs with "custom-id-"
⍝C         prefixHeaderId: 'custom-id-',
⍝C      // Enable emoji support ***
⍝C         emoji: true,
⍝C      // Enable task lists ***
⍝C         tasklists: true,
⍝C      // Disable automatic wrapping of HTML blocks
⍝C         noHTMLBlocks: false,
⍝C      // Simple line break: If true, prevent new para with a simple line break.
⍝C      //                    If false (default), create new para with simple line break
⍝C         simpleLineBreaks: false               
⍝C     });
⍝C     const html = converter.makeHtml(markdownText);
⍝C     document.getElementById('html-content').innerHTML = html;
⍝C   </script>
⍝C </body>
⍝C </html>

:EndNamespace 
