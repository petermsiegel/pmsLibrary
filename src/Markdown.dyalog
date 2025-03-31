:Namespace Markdown
    NL← ⎕UCS 10
    AddEsc←   '(?<!\\)`' '\\'  ⎕R '\\\\`' '\\\\' ⍝ EscapeMD 
    GetSrc←  {                              ⍝ Get javascript from source.
        src←'^\s*⍝',⍺,'\s?(.*)$'            ⍝ Match lines with prefix: /^\s*⍝/ + ⍺ + /\s?/. 
        src ⎕S '\1'⊣⊆⍵                      ⍝ Take whatever follows the prefix. Return VV
    }    
    InsertMD← {                             ⍝ insert markdown into jsCode
      code← '^\h*___MYTEXT___.*$'
      mark← Flatten ⍺
      _Once← ⍠'ML' 1 
      code ⎕R mark _Once⊢ ⍵
    }
    Flatten← {¯1↓ ∊ NL,⍨¨ ⊆⍵}

example← 'X' GetSrc ⎕SRC ⎕THIS                 ⍝ /⍝X.../ - a markdown example. Stored as VV

∇ {jsCode}←  Show markdown; md; html  
⍝ markdown: APL char vectors (VV)  
⍝ jsCode:   Javascript code to display markdown as HTML (V with NL chars)
⍝ extern: html
  md← AddEsc markdown                           ⍝ Add escapes to the markdown                                        
  jsCode← md InsertMD 'C' GetSrc ⎕SRC ⎕THIS     ⍝ Insert the markdown text into the Javascript code     
⍝ Render the code
  'html' ⎕WC 'HTMLRenderer' ('HTML',⍥⊂ Flatten jsCode) ('Size' 800 1000)('Coord' 'ScaledPixel') 
  {}⍞↓⍨≢⍞←'<Hit return> '
∇

⍝  example: Markdown example source 
⍝X # An example of *Markdown* in the ***Showdown*** dialect
⍝X
⍝X This is a paragraph with **bold** text and this Emoji smile :smile: is marked via :smile\:.
⍝X This face 😜 is represented _directly_ in APL. 
⍝X
⍝X 1. This is a bullet
⍝X      * This is a *sub-*bullet.
⍝X           * A sub**ber** bullet.
⍝X           * And another!
⍝X 1. This is another top-level bullet.
⍝X 1. As is this.
⍝X 
⍝X     > A blockquote would look great here...
⍝X 1. A final bullet?
⍝X 
⍝X   | Nina  |   Pinta | Santa Maria  |
⍝X   |:-----:|:-------:|:------------:|
⍝X   | 100   | 200  | 300             |
⍝X   | big | *bigger* | ~~biggest~~ |
⍝X   | big | *bigger* | ***also*** big |
⍝X
⍝X This is code: `⍳2` 
⍝X 
⍝X This is *also* code: <code>⍳3</code> 
⍝X 
⍝X And so is this:
⍝X 
⍝X        ∇ P← A IOTA B
⍝X          P← A ⍳ B
⍝X        ∇
⍝X
⍝X ### Goodbye!
⍝X 

⍝  Markdown code-- "showdown" javascript
⍝C <!DOCTYPE html>
⍝C <html>
⍝C <head>
⍝C     <title>Showdown Example</title>
⍝C     <script src="https://cdnjs.cloudflare.com/ajax/libs/showdown/2.1.0/showdown.min.js"></script>
⍝C </head>
⍝C <body>
⍝C     <div id="markdown-content" style="display:none;">
⍝C     ___MYTEXT___          // User Markdown will go here!
⍝C     </div>
⍝C     <div id="html-content"></div>
⍝C     <script>
⍝C         var markdownText = document.getElementById('markdown-content').textContent;
⍝C         const converter = new showdown.Converter({
⍝            These are optional, but those marked with *** seem to be very useful.
⍝C          // Enable tables ***
⍝C             tables: true,
⍝C          // Enable strikethrough ***
⍝C             strikethrough: true,
⍝C          // Omit extra line break in code blocks
⍝C             omitExtraWLInCodeBlocks: true,
⍝C          // Enable GitHub-compatible header IDs
⍝C             ghCompatibleHeaderId: true,
⍝C          // code blocks (```...```) don't seem to work???
⍝C             ghCodeBlocks: true,     // The default...
⍝C          // Prefix header IDs with "custom-id-"
⍝C             prefixHeaderId: 'custom-id-',
⍝C          // Enable emoji support ***
⍝C             emoji: true,
⍝C          // Enable task lists ***
⍝C             tasklists: true,
⍝C          // Disable automatic wrapping of HTML blocks
⍝C             noHTMLBlocks: false,
⍝C          // Simple line break
⍝C             simpleLineBreaks: true
⍝C         });
⍝C         const html = converter.makeHtml(markdownText);
⍝C         document.getElementById('html-content').innerHTML = html;
⍝C     </script>
⍝C </body>
⍝C </html>

:EndNamespace 
