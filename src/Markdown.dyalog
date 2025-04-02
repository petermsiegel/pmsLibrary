﻿:Namespace Markdown
  NL← ⎕UCS 10
  AddEsc←    '\\'  ⎕R  '\\\\' ⍝ EscapeMD 
⍝ GetSrc: ∇ prefix  
  GetSrc←  { src←'^\s*⍝', ⍵, '\s?(.*)$' ⋄ src ⎕S '\1'⊣ ⎕SRC ⎕THIS }
⍝ InsertMD: insert markdown into jsCode
  InsertMD← { md← Flatten ⍺ ⋄ '^\h*___MYTEXT___.*$' ⎕R md⊣ ⍵ }
  Flatten← {¯1↓ ∊ NL,⍨¨ ⊆⍵}

example← GetSrc 'X'                         ⍝ /⍝X.../ - a markdown example. Stored as VV

∇ {jsCode}←  Show markdown; md; html  
⍝ markdown: APL char vectors (VV)  
⍝ jsCode:   Javascript code to display markdown as HTML (V with NL chars)
⍝ extern: html
  md← AddEsc markdown                      ⍝ Add escapes to the markdown                                       
  jsCode← md InsertMD GetSrc 'C'           ⍝ Insert the markdown text into the Javascript code     
  'html' ⎕WC 'HTMLRenderer' ('HTML',⍥⊂ Flatten jsCode) ('Size' 800 1000)('Coord' 'ScaledPixel') 
  ⎕← 'Hit return after viewing html'
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
⍝X   | Niña          |  Pinta          | Santa Maria  |
⍝X   |: ----- :|:-----:|:-----:|
⍝X   | 50-60 tons   | 70 tons  | [100 tons](https://www.lakewizard.com/post/100-ton-boat/) |
⍝X   | ~~big~~| ~~bigger~~ | ~~gigantic~~ |
⍝X   | shrimpy shrimp |  small shrimp  |  jumbo shrimp  |
⍝X   |             |               |               |
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
⍝X This should work. Does it?  ```⍺⍳⍵
⍝X ⍵⍳⍺```
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
⍝C      // We can just stick with the defaults, but those marked with *** seem to be very useful.
⍝C      // Enable tables ***
⍝C         tables: true,
⍝C      // Enable strikethrough ***
⍝C         strikethrough: true,
⍝C      // Omit extra line break in code blocks
⍝C         omitExtraWLInCodeBlocks: true,
⍝C      // Enable GitHub-compatible header IDs
⍝C         ghCompatibleHeaderId: true,
⍝C      // code blocks (```...```) don't seem to work???
⍝C         ghCodeBlocks: true,          // true: the default...
⍝C         fencedCodeBlocks: true,
⍝C      // Prefix header IDs with "custom-id-"
⍝C         prefixHeaderId: 'custom-id-',
⍝C      // Enable emoji support ***
⍝C         emoji: true,
⍝C      // Enable task lists ***
⍝C         tasklists: true,
⍝C      // Disable automatic wrapping of HTML blocks
⍝C         noHTMLBlocks: false,
⍝C      // Simple line break: If true, you can't split paragraphs across lines w/o extra trailing blanks.
⍝C         simpleLineBreaks: false,      // false: the default 
⍝C     });
⍝C     const html = converter.makeHtml(markdownText);
⍝C     document.getElementById('html-content').innerHTML = html;
⍝C   </script>
⍝C </body>
⍝C </html>

:EndNamespace 
