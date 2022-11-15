<!-- Output copied to clipboard! -->

<!-----

Yay, no errors, warnings, or alerts!

Conversion time: 3.036 seconds.


Using this Markdown file:

1. Paste this output into your source file.
2. See the notes and action items below regarding this conversion run.
3. Check the rendered output (headings, lists, code blocks, tables) for proper
   formatting and use a linkchecker before you publish this page.

Conversion notes:

* Docs to Markdown version 1.0β33
* Mon Nov 14 2022 23:03:20 GMT-0800 (PST)
* Source doc: ∆F Strings: A Simple Format Utility
* Tables are currently converted to HTML tables.

WARNING:
You have 6 H1 headings. You may want to use the "H1 -> H2" option to demote all headings by one level.

----->


<p style="color: red; font-weight: bold">>>>>>  gd2md-html alert:  ERRORs: 0; WARNINGs: 1; ALERTS: 0.</p>
<ul style="color: red; font-weight: bold"><li>See top comment block for details on ERRORs and WARNINGs. <li>In the converted Markdown or HTML, search for inline alerts that start with >>>>>  gd2md-html alert:  for specific instances that need correction.</ul>

<p style="color: red; font-weight: bold">Links to alert messages:</p>
<p style="color: red; font-weight: bold">>>>>> PLEASE check and correct alert issues and delete this message and the inline alerts.<hr></p>


_∆F_ is a function that uses simple input string expressions, **<code><em>f-strings,</em></code></strong>[^1] to dynamically build 2-dimensional output from variables and dfn-style code, shortcuts for numerical formatting, titles, and more. To support an idiomatic APL style, _∆F_ uses the concept of _fields_ to organize output of vector and multidimensional objects using building blocks that already exist in the _Dyalog_ implementation.


# A. Syntax  


```
[ result← ]  [ options ] ∆F f-string [ args ]


<table>
  <tr>
   <td>```

<strong><code><em>f-string</em></code></strong>
   </td>
   <td>A string containing variables and dfn code, text, and formatting specifications to display a mixture of APL objects as a character matrix.
   </td>
  </tr>
  <tr>
   <td><strong><code><em>args</em></code></strong>
   </td>
   <td>0 or more scalar "arguments" that can be easily used to incorporate on-the-fly variables and specifications into the <em>f-string</em>. Each scalar in <em>⍵</em> can be selected in an ⎕IO-independent fashion  as  \
      <code> <em>⍹1, ⍹2</em></code>, etc.<strong><em>;</em></strong> <em>⍹<strong>;</strong> ⍹0.</em>
<em>⍹1</em> refers to the <em>first</em> scalar,[^2] bare <em>⍹</em>: the <em>next </em>scalar,[^3] <em>⍹0</em>: the <em>f-string</em> itself.
   </td>
  </tr>
  <tr>
   <td><strong><code><em>options</em></code></strong>
   </td>
   <td><strong><em>Category</em>:  </strong>[ [ [ <strong><em>MODE  </em></strong>[<strong> <em> BOX  </em></strong>[ <strong><em> NS </em></strong>] ] <strong>|  <em>MISCELLANY</em>  </strong>] ] ]
<p>
<strong><em>Values:  <code>           1      0    0          'help'</code></em></strong>
<strong><code><em>                 0      1    1            ⍬</em></code></strong>
<strong><code><em>                ¯1</em></code></strong>
   </td>
  </tr>
  <tr>
   <td><strong><code><em>result</em></code></strong>
   </td>
   <td>A character matrix, at a minimum a single row of 0-width (of shape <em>1 0</em>).
   </td>
  </tr>
</table>


**  MODE option <code><em>(0⊃⍺)</em></code></strong>


<table>
  <tr>
   <td><strong>MODE \
Number</strong>
   </td>
   <td><strong>MODE Description</strong>
   </td>
   <td><strong>ACTION</strong>
   </td>
  </tr>
  <tr>
   <td><strong><code><em>1 \
</em></code></strong>
   </td>
   <td><strong><code><em>IMMED</em></code></strong>
<strong><code><em>Immediate</em></code></strong>
   </td>
   <td><strong>Returns</strong> a char matrix based on specifications within an <em>f-string</em> evaluated at runtime based on variables in the calling environment and passed as arguments to the <em>∆F</em> function.  Fields are executed from left to right, as if separate APL statements.  <strong>(Default).</strong>
   </td>
  </tr>
  <tr>
   <td><strong><code><em>0 \
</em></code></strong>
   </td>
   <td><strong><code><em>CODEGEN</em></code></strong>
<strong><code><em>Code- \
Generation</em></code></strong>
   </td>
   <td><strong>Returns</strong> a char vector, containing an executable in string form, which can be evaluated directly or established as a <em>dfn</em> (and called). Its output is identical to that under <em>immediate</em> mode (<strong>MODE</strong>=1).[^4]
<p>

    <em>MyDfn← ⍎0 ∆F myFString      ⍝ Create Dfn</em>
<p>

    <em>MyDfn (1 2 3) (⎕TS) etc.    ⍝ Call Dfn later</em>
   </td>
  </tr>
  <tr>
   <td><strong><code><em>¯1 \
</em></code></strong>
   </td>
   <td><strong><code><em>PSEUDO- \
CODE</em></code></strong>
   </td>
   <td><strong>Returns</strong> a char vector with a compact pseudo-code equivalent of the executable dfn returned via <em>Mode=0,</em> suitable for inspection, etc. Output fields are generated in the order presented in the <strong><code><em>f-string</em></code></strong>.[^5]
   </td>
  </tr>
</table>


**  BOX option  <code><em>(1⊃⍺)</em></code></strong>


<table>
  <tr>
   <td><strong>BOX</strong>
   </td>
   <td><strong>Action</strong>
   </td>
  </tr>
  <tr>
   <td><strong><code><em>0</em></code></strong>
   </td>
   <td>Displays each field normally (returns per MODE).  <strong>(Default).</strong>
   </td>
  </tr>
  <tr>
   <td><strong><code><em>1</em></code></strong>
   </td>
   <td>Displays each field in a 2D box (returns per MODE). 0-width fields are not displayed.  Blanks are replaced with a center dot (·).
<p>
Useful for debugging or pedagogy.
   </td>
  </tr>
</table>


**    NS  (Shared Namespace) option**[^6]**  <code><em>(2⊃⍺)</em></code></strong>


<table>
  <tr>
   <td><strong>NS</strong>
   </td>
   <td><strong>Action</strong>
   </td>
  </tr>
  <tr>
   <td><strong><code><em>0</em></code></strong>
   </td>
   <td>Code Fields (CFs) have no <em>common</em> private namespace provided to them. <strong>Argument </strong>⍺<strong> is undefined.</strong> A CF may use/define variables in the calling environment per dfn conventions, with updates visible to all CFs to its right and outside ∆F.  <strong>(Default).</strong>
   </td>
  </tr>
  <tr>
   <td><strong><code><em>1</em></code></strong>
   </td>
   <td><strong>Argument </strong>⍺<strong> is defined as an anonymous namespace visible to every Code Field (CF) while the current ∆F call is active. </strong>A CF may use/define variables in <strong> </strong>⍺<strong> </strong>per dfn conventions, with updates visible to all CFs to its right, as well as variables in the calling environment.
   </td>
  </tr>
</table>


**  MISCELLANEOUS OPTIONS <code><em>(⍺)</em></code></strong>


<table>
  <tr>
   <td><strong>MISC.</strong>
   </td>
   <td><strong>Action</strong>
   </td>
  </tr>
  <tr>
   <td><strong><code><em>'help'</em></code></strong>
   </td>
   <td>    <em> ∆F⍨'help'   </em>or<em>  </em> <em>'help' ∆F anything</em>
<p>
Displays an informational (HELP) window; right argument <em>(⍵)</em> is ignored. \
<strong>Returns </strong>shy char matrix:<strong> <em>(1 0⍴' ').</em></strong>
   </td>
  </tr>
  <tr>
   <td><strong><code><em>  ⍬</em></code></strong>
   </td>
   <td>    <em>⍬ ∆F anything</em>
<p>
Exits  immediately; right argument <em>(⍵)</em> is ignored.[^7]
<strong><code>(</code>Returns </strong>shy char matrix: <em>(1 0⍴' ').</em>
   </td>
  </tr>
</table>



# B. Examples

We'll start with examples first, but feel free to peek ahead for definitions and specifications.

**Example 1: ** Text Fields and Code Fields **<code><em>{...}</em></code></strong> with simple variables.

Assume these declarations of multiline (matrix) objects:


#### names←  ↑'John Jones'  'Mary Smith'


#### addr←   ↑'1214 Maiden Ln'  '24 Hersham Rd'

**Example 1a: ** Text and Code Fields "chained" together horizontally.


#### ∆F 'Name: { names }  Addr: { addr }'


##### Name: John Jones  Addr: 1214 Maiden Ln


#####       Mary Smith        24 Hersham Rd


```


```


**Example 1b:**  Self-documenting[^8] code expressions _{...→}, {...↓}_ in Code Fields.


#### ∆F '{names→}  {addr→}'     ⍝ Horizontal →


##### names→John Jones   addr→1214 Maiden Ln 


#####       Mary Smith        24 Hersham Rd


#### ∆F '{names↓}  {addr↓}'     ⍝ Vertical ↓


#####   names↓        addr↓    


##### John Jones  1214 Maiden Ln


##### Mary Smith  24 Hersham Rd

**Example 1c:**  Titles (using the **<code><em>OVER</em></code></strong> shortcut <strong><code><em>%).</em></code></strong>  \
Note that strings in Code Fields <em>{code} </em>use double quotes like <em>"this!"</em>.


#### ∆F '{"Name" % names}  {"Address" % addr}'


#####    Name        Address   


##### John Jones  1214 Maiden Ln


##### Mary Smith  24 Hersham Rd


```


```


**Example 1d:** Adding a calculated field with line numbers (and one "null" title).


#### ⍝    ↓ Null Title               ⊢→→       Same as (1c)        ←←⊣


#### ∆F'{ ⍬ % "I1,⊂.⊃" $ 1+⍳≢names} {"Name" % names} {"Address" % addr}'


#####       Name        Address   


##### 1. John Jones  1214 Maiden Ln


##### 2. Mary Smith  24 Hersham Rd

**Example 2: ** Calculations and Formatting in Code Fields _($** **_is a shortcut for _⎕FMT)_.

Assume these declarations:


#### c←   100 20 12 23 ¯2    ⍝ Some temps in Celsius


#### C2F← 32+1.8∘×           ⍝ Converts Celsius to Fahr.**<code> \
</code></strong>

**Example 2a:** Format specification as an argument**<code> ⍵1</code></strong>, i.e. <strong>(<code><em>1+⎕IO)⊃⍵.  \
</em></code></strong>(Degree sign (°): ⎕UCS 176)  Result is a 5-row 15-col char matrix.


#### ∆F '{ ⍵1 $ c }C = { ⍵1 $ C2F c }F' 'I3,⊂°⊃'     


##### 100°C =  212°F


#####  20°      68°             


#####  12°      54°             


#####  23°      73°             


#####  ¯2°      28° 


```


```


**Example 2b: **Format specification "hardwired" in Code Field.

Note alternative way to enter degree sign **<code>'°'</code> </strong>as Unicode 176:<em> "\{176}".</em>


#### ∆F '{ "I3,⊂°⊃" $ c }C = { "F5.1,⊂\{176}⊃" $ C2F c }F' 


##### 100°C = 212.0°F


#####  20°     68.0°


#####  12°     53.6°


#####  23°     73.4°


#####  ¯2°     28.4°


```


```


**Example 2c:** Variant on (2b) with a header for each Code field using the % (OVER) shortcut.


#### 
    hdrC← 'Celsius' 


#### 
    hdrF← 'Fahren.'


#### 
                                            ∆F '{ hdrC % "I3,⊂°⊃" $ c }  { hdrF % "F5.1,⊂°⊃" $ C2F c }'


##### Celsius  Fahren.


#####  100°    212.0°


#####   20°     68.0°


#####   12°     53.6°


#####   23°     73.4°


#####   ¯2°     28.4° \
` `

**Example 3a:** **<code><em>BOX</em></code></strong> display option <strong><code><em>(1=1⊃⍺).</em></code></strong>

Displays each field in its own "box" (ignoring (0-width)** null fields**). \
Spaces are replaced by center dots (·).


#### 1 1 ∆F 'one**<code>{}{}</code></strong>{ }two {"three"}<strong><code>{:0:}</code></strong>{ }four' 


##### ┌→──┐┌→┐┌→───┐┌→────┐┌→┐┌→───┐


##### │one││·││two·││three││·││four│


##### └───┘└─┘└────┘└─────┘└─┘└────┘

**Example 3b: **(3a) _without_ the **<code><em>BOX</em></code></strong> option <strong><code><em>(0=1⊃⍺)</em></code></strong>.


#### ∆F 'one{}{}{ }two {"three"}{:0:}{ }four'   ⍝ ⍺=1 0  


#####  one two three four

** \
Example 4a:** Use of ⍹ to reference the next scalar in right argument ⍵. 


#### ⍝             ⍹1≡1⊃⍵        ⍹2≡2⊃⍵                (⎕IO←0)


#### ∆F '{"Name" % ⍹}  {"Addr" % ⍹}'  'J. Smith' '24 Broad Ln'


#####   Name         Addr    


##### J. Smith  24 Broad Ln

**Example 4b:** Interaction of ⍹N and simple ⍹.


#### ∆F '{⍹5 ⍹} {⍹3 ⍹} {⍹1 ⍹}' 1 2 3 4 5 6


##### 5 6 3 4 1 2


# C. The _f-String_ (⍹0)

The _f-string_ is a character vector defining 0 or more "fields." Fields are evaluated _left to right_ starting with the leftmost field (as if APL statements[^9]), converted to character matrices (if not already), and "chained" together into a single matrix. The successful result will always have rank _2_.[^10]  The input _f-string_ is in special variable ⍹0, visible to all Code Fields.

 

 There are 3 types of field in an f-string (highlighted):


<table>
  <tr>
   <td>
    <strong>Field Type</strong>
   </td>
   <td><strong> Example</strong>
   </td>
   <td><strong>Output</strong>
   </td>
  </tr>
  <tr>
   <td><strong>Code</strong> <strong>Field</strong>
   </td>
   <td>
    <em>∆F 'πr²={ pi←○1 ♢  r←2 ♢  pi×r*2}'</em>
<p>

    <em>∆F 'π={⎕FR←1287 ♢  16⍕ ○1 }!'</em>
   </td>
   <td><em>πr²=12.56637061</em>
<p>
<em>π=3.1415926535897932!</em>
   </td>
  </tr>
  <tr>
   <td><strong>Space</strong> <strong>Field</strong>
   </td>
   <td>
    <em>∆F '1{ }1, 2{:2:}2, 3{:⍵1:}3.' 3</em>
   </td>
   <td><em>1 1, 2  2, 3   3.</em>
   </td>
  </tr>
  <tr>
   <td><strong>Text</strong> <strong>Field</strong>
   </td>
   <td>
    <em>∆F '1:\♢ 2:\♢ 3:{ }Mary\♢ John\♢ Ted'</em>
   </td>
   <td><em>1: Mary</em>
<p>
<em>2: John</em>
<p>
<em>3: Ted</em>
   </td>
  </tr>
</table>


We'll start with **Code Fields** first, since they’re where all the power of _f-strings_ resides.


## 


## C1. Code Fields

Code Fields are single-line dfns, and may include multiple statements, guards, error handling, and so on. Each Code Field has an implicit right argument[^11] that includes everything passed to ∆F as _⍵_ when called; there are shortcuts (special variables) for accessing the scalars in this argument described below.


    _R← 12 2.3 19_


    _∆F '{ A←(○⊢×⊢)R ⍝ area **♢**  "F4.1,F8.2" $ R,⍤¯1⊣ A }'_

_12.0  452.39_

_ 2.3   16.62_

_19.0 1134.11_


### a.  Basics of Code Fields



* A Code Field itself is evaluated as a regular Dfn, left to right across statements, but right to left within a statement.
* A Code Field begins with a left brace **<code><em>{ </em></code></strong>and ends with a balancing right brace <strong><code><em>}</em></code></strong>. 
* A left brace preceded by a backslash <em>\{</em> does <em>not</em> begin a Code Field and, likewise, a <strong><code><em>\}</em></code></strong> does not end one. See <em>Text Fields.</em>
* A Code Field may contain any dfn code on a single line, including multiple stmts, guards, and error guards, with several modifications, shown below.
* A Code Field may include (limited) comments.[^12] Each comment: 


    * must start with a lamp:    _⍝_
    * must contain no backslashes,  statement terminators, or braces:    **_\_  _♢ _  _{ _  _}_** 
    * will  end just before either a statement terminator or a closing brace:    **_♢_  <code><em>}</em></code></strong>.  \
 


#### <em>∆F '{ pi←○1 ⍝ Calc pi ♢ e←*1 ⍝ Calc e ♢ pi*e ⍝ Silly! }'</em>


##### 22.45915772


### b.  Code Fields: Special Variables _ ⍹0, ⍹,_ etc., (outside strings)



1. _⍹0, ⍹1, ... ⍹N,_ denote the scalars in the right arg _(⍵)_ passed to _∆F.  \
⍹_ is the glyph _⎕UCS 9081._

**     Special Variables in Code Fields (Outside Strings)**


<table>
  <tr>
   <td><strong>Shortcut</strong>
   </td>
   <td><strong>Action</strong>[^13]
   </td>
   <td><strong>Value</strong>
   </td>
  </tr>
  <tr>
   <td><em>⍹0, ⍵0</em>
   </td>
   <td><em>(0⊃⍵)</em>
   </td>
   <td>the <em>f-string</em> itself.
   </td>
  </tr>
  <tr>
   <td><em>⍹1,⍵1</em>
   </td>
   <td><em>(1⊃⍵) </em>
   </td>
   <td>the first scalar after the <em>f-string</em>.
   </td>
  </tr>
  <tr>
   <td><em>⍹N,⍵N</em>
   </td>
   <td><em>(N⊃⍵) </em>
   </td>
   <td>the Nth scalar after the <em>f-string</em>, where N is one or more digits.
   </td>
  </tr>
  <tr>
   <td><em>⍹, ⍵_</em>
   </td>
   <td><em>(M⊃⍵)</em>
   </td>
   <td>the <em>next</em> scalar<code> <strong><em>(M⊃⍵)</em></strong></code>, based on incrementing from the <em>⍹</em> or <em>⍹N</em> to its left. If none,<strong><em> <code>(1⊃⍵</code>), </em></strong>first scalar <em>after</em> the <em>f-string</em> itself.
   </td>
  </tr>
</table>


 



    1. If this is first use of _ _any form of _⍹, _then the current ⍹ refers to ⍹1.The counter for bare _⍹_, initially 0, is incremented by 1 just _before_ each use. 
    2. If a _⍹N_ variable is the most recent to the left of the current simple **<code><em>⍹ </em></code></strong>in <em>any</em> prior code field, the counter for <em>⍹ </em>is incremented to <strong><em>N+1.</em></strong>
    3. If a simple ⍹ variable is the most recent to the left of the current simple <strong><code><em>⍹</em></code></strong>, and the former refers to the <em>M-th </em>scalar in <em>⍵, </em>then the latter refers to the<em> (M+1)-st, </em> the <em>next</em> scalar in ⍵.
    4. By definition, <em>⍹0</em>  (the <em>f-string</em>) can only be accessed <em>explicitly</em>, not using bare ⍹. 
2. Omega <em>⍵</em> without any suffixed digit or underscore is <em>not </em>a special variable. Within each Code Field, it will refer to the <em>entire</em> original right argument <em>⍵</em> to <em>∆F</em>: every scalar (including the <em>f-string</em>). \
 


#### ∆F '{ 0:: "whoops!" ♢ ○⍹1 ⍝ Calc ⍹1×pi }' 2


```
6.283185307
```



#### ∆F '{ 0:: "whoops!" ♢ ○⍹1 ⍝ Calc ⍹1×pi }' 'two'


##### whoops!


### c.  Code Fields: Quoted Strings



* Quoted strings within Code Fields fall within double quotes (**"..."**), rather than single quotes. Except as indicated here, they work the same as standard APL strings.
* There are a limited number of special substrings within Code Field strings. You can safely ignore these details unless you need carriage returns or _⎕UCS _characters in strings. \


**     Substrings in Quoted Strings in Code Fields**


<table>
  <tr>
   <td>
    Substring 
   </td>
   <td>
    What it indicates…
   </td>
  </tr>
  <tr>
   <td>
    <em>\♢ </em>
   </td>
   <td>
    A carriage return (⎕UCS 13).
<p>

    <em>\♢ </em> if <em>MODE=¯1, </em>for easier debugging or inspection.
   </td>
  </tr>
  <tr>
   <td>
    <em>\\♢  \
♢  </em>
   </td>
   <td>
    <em>\♢ </em>literal,
<p>

    <em>♢  </em>literal.
   </td>
  </tr>
  <tr>
   <td>
    <em>\{nnn}   \
\{nnn-ppp}</em>
<p>

    <em>   nnn, ppp: </em>digits.
   </td>
   <td>
    <em>⎕UCS nnn </em>
<p>

    <em>(⎕UCS nnn) </em>to<em> (⎕UCS ppp)</em> inclusive.
<p>
<em> </em>Ex: <em> ∆F '&lt;{"\{97-108}...\{57-48}"}>'</em>
<p>
 <em>&lt;abcdefghijkl...9876543210></em>
   </td>
  </tr>
  <tr>
   <td>
    \\{<em>nnn</em>}  \
\\{<em>nnn</em>-mmm}
   </td>
   <td>
    \{<em>nnn</em>} \
\{<em>nnn</em>-<em>mmm</em>}
   </td>
  </tr>
  <tr>
   <td>
    Any other substring starting with a backslash <em>\</em>.
   </td>
   <td>
    Unchanged (backslash is the usual APL  function/operator).
<p>

       +\1 2 3
   </td>
  </tr>
</table>



### d. Code Fields: Shortcut "Functions" (Only Outside Strings)


<table>
  <tr>
   <td><strong>Name</strong>
   </td>
   <td><strong>Short- \
cut</strong>
   </td>
   <td><strong>Syntax</strong>
   </td>
   <td><strong>Usage</strong>
   </td>
  </tr>
  <tr>
   <td><strong>Format</strong>
   </td>
   <td><strong><code><em>$ </em></code></strong>infix
   </td>
   <td><em>spec $ obj</em>
   </td>
   <td>Calls<em> spec ⎕FMT obj. \
</em>Ex:   <em>{"I2" $ ⍳2}</em>
   </td>
  </tr>
  <tr>
   <td><strong>Box</strong>
   </td>
   <td><strong><code><em>$$ </em></code></strong>prefix
   </td>
   <td><em>$$ obj</em>
   </td>
   <td>Displays a box[^14] containing  the object <em>obj.</em>
   </td>
  </tr>
  <tr>
   <td><strong>Over</strong>
   </td>
   <td><strong><code><em>% </em></code></strong>infix
   </td>
   <td><em>obj1 % obj2</em>
   </td>
   <td>Displays <em>obj1</em> <em>on top of (over)</em> <em>obj2</em>, each centered.  \
Ex: <em>{"Temps" % 23 19 17}</em>
   </td>
  </tr>
  <tr>
   <td><strong>Chain</strong>
   </td>
   <td><strong><code><em>%% </em></code></strong>infix
   </td>
   <td><em>obj1 %% obj2</em>
   </td>
   <td>Displays <em>obj1</em> to the <em>left</em> of <em>obj2</em>, neither centered.
   </td>
  </tr>
  <tr>
   <td><strong>Self-</strong>
<p>
<strong>Documenting Code</strong>
   </td>
   <td><strong>a.<em> <code>→</code> </em></strong>suffix
<strong>b. <code><em>↓</em></code></strong> suffix
   </td>
   <td><strong>a. <em>{... →}  \
</em>b. <em>{... ↓}</em></strong>
   </td>
   <td>Generates self-documenting code, i.e. prints the contents (source) of the field {<strong>a. <em>followed by /</em></strong> <strong>b. <em>over</em></strong>} the value of the code executed. \
Ex: <em>{MyTemps→} ⇒  'MyTemps→{MyTemps}'</em>
<p>
<em>   {MyTemps↓} ⇒ '"MyTemps↓" % {MyTemps}'</em>
<p>
Input spacing is  preserved..
   </td>
  </tr>
</table>



##  C2. Space Fields:      {  } , { :5: }, { :⍹2: }

Space Fields look like stripped down Code Fields.[^15]  They have two functions:  \




* Separate one (possibly multiline) Text Field from the next;
* Insert a field of zero or more spaces. \


A 0-width Space Field _{}_ is handy as a separator between fields (see examples below).

Space fields indicate the number of spaces between (other) fields  in three ways: \



<table>
  <tr>
   <td><strong>Subtype</strong>
   </td>
   <td><strong>Template</strong>
   </td>
   <td><strong>Description</strong>
   </td>
   <td><strong>Action</strong>
   </td>
  </tr>
  <tr>
   <td><strong>Simple Spaces</strong>
   </td>
   <td>{ss} 
   </td>
   <td>ss: 0 or more spaces
   </td>
   <td>inserts spaces shown
   </td>
  </tr>
  <tr>
   <td><strong>Numeric</strong>
   </td>
   <td>{:nn:}
   </td>
   <td>nn: zero or more digits
   </td>
   <td>inserts <em>nn</em> spaces
   </td>
  </tr>
  <tr>
   <td><strong>Special Variable</strong>
   </td>
   <td><em>{:⍹N:}, {:⍹:}, {:⍵N:}, {:⍵_:}</em>
   </td>
   <td>a single special variable
   </td>
   <td>inserts<em> ⍹N</em> spaces at execution time.
   </td>
  </tr>
</table>


 \
For Numeric or Special Variable Space Fields



* The colon prefix is required;  the colon suffix is optional.
* An ill-formed Space Field will be treated as a Code Field, likely triggering an error.
* In a Space Field, only one special variable is allowed (i.e. ⍹5 or ⍹, but not ⍹4+⍹5, etc.).  Its value will be used at execution time to determine the number of spaces.
* If you want to calculate spaces dynamically in a more complex way,[^16] simply use a code field:

     {" "⍴⍨⍹4+2×⍹3}.

 

Space Field Examples   


<table>
  <tr>
   <td><strong>(Text-Field Space and) 0-Width Space Field</strong>
   </td>
   <td><strong>Simple Space Field</strong>
   </td>
  </tr>
  <tr>
   <td>
    Who← ↑'Mary' 'Captain'
<p>

    <em>∆F 'Name: \♢Rank:{}{Who}'        </em>
<p>
<em> Name: Mary                                          </em>
<p>
<em> Rank: Captain </em>
   </td>
   <td>
    Who← ↑'Mary' 'Captain'
<p>

    <em>∆F 'Name:\♢Rank:{ }{Who}'</em>
<p>
<em> Name: Mary  </em>
<p>
<em> Rank: Captain</em>
   </td>
  </tr>
  <tr>
   <td><strong>Numeric Space Field</strong>
   </td>
   <td><strong>Special Variable Space Field</strong>
   </td>
  </tr>
  <tr>
   <td>
    Who← ↑'Mary' 'Captain'
<p>

    <em>∆F 'Name:\♢Rank:{:5:}{Who}'  </em>
<p>
<em> Name:     Mary  </em>
<p>
<em> Rank:     Captain</em>
   </td>
   <td>
    Who← ↑'Mary' 'Captain'
<p>

    <em>∆F 'Name:\♢Rank:{:⍵1:}{Who}' 5</em>
<p>
<em> Name:     Mary  </em>
<p>
<em> Rank:     Captain</em>
   </td>
  </tr>
</table>



##  C3. Text Fields: _∆F '1\<code>♢</code>2\<code>♢</code>3{}a\<code>♢</code>b\<code>♢</code>c'</em>[^17]

 Everything else is a Text Field. Variable names, etc., in text fields are just text. There are only a few special sequences in text fields:  \**<code><em>♢  </em></code></strong>\\<strong><code><em>♢</em></code></strong>  \{<em>  </em>and  <em>\}. \
</em>



* To insert a newline, enter a  carriage return[^18] using the sequence \**<code><em>♢ .  </em></code></strong>

* To show literal \<em>♢ </em>, enter \\<em>♢ .  </em>Simple <em>♢ </em> is entered as is: <em>♢ .  </em>
* To show <em>{</em> or<em> }</em> as text, enter <em>\{</em> or <em>\}. </em> Simple braces will demarcate a Code Field.
* In all other cases, simple<em> \ </em>is not special: <em>+\</em> is simply <em>+\</em>.
* You can use <em>{} </em>(a 0-width Space Field) to separate 2 Text Fields. (See Space Fields above).


#   \
D. Style Differences from Python


<table>
  <tr>
   <td><strong>∆F APL-style                                            </strong>
   </td>
   <td><strong>Python-style</strong>
   </td>
  </tr>
  <tr>
   <td><em>⍝ Build fields all at once L to R         </em>
<h4>
    RGB←  123 145 255                      </h4>


<h4>
    ∆F 'R:\♢G:\♢B:{ }{⍪RGB}'            </h4>


<h5>R: 123                                   </h5>


<h5>G: 145                                   </h5>


<h5>B: 255               </h5>


<p>
<em>       </em>
<p>
<em>⍝ Use APL for base conversions, etc.           \
  ∆F '"{"01"[2⊥⍣¯1⊢⍵1]}"' 7  ⍝ ⎕IO←0           "111"        </em>
<p>
<em>       </em>
<p>
<em>⍝ Is formatting floats old-fashioned?    </em>
<p>

    <em>x← 20.123                              </em>
<p>

    <em>∆F'{"F8.5"$x}' ⍝ User calcs width      </em>
<p>
<em>20.12300                                 </em>
<p>

    <em>∆F '{5⍕x}'     ⍝ APL calcs width       </em>
<p>
<em>20.12300   </em>
   </td>
   <td><em># Build annotations row by row</em>
<p>
<em>R = 123 ; G = 145 ; B = 255</em>
<p>
<em>print((f'R: {R}\nG: {G}\nB: {B}'))</em>
<p>
<em>R: 123</em>
<p>
<em>G: 145</em>
<p>
<em>B: 255</em>
<p>
<em>       </em>
<p>
<em># Base conversions are built in</em>
<p>
<em>f'{7:b}'</em>
<p>
<em>'111'</em>
<p>
<em>       </em>
<p>
<em># Similar approach, different conventions</em>
<p>
<em>x = 20.123</em>
<p>
<em>print(f'{x:0&lt;8}')   # User calcs width</em>
<p>
<em>20.12300</em>
<p>
<em>print(f'{x:.5f}')   # Python calcs width</em>
<p>
<em>20.12300   </em>
   </td>
  </tr>
</table>



#   \
E. PERFORMANCE


## Precompiling Heavily-Used <code><em>f-strings</em></code>  in Advance (Using<em> Mode=0)</em>

 As a prototype, _∆F_ is relatively slow compared to building simple formatted objects "by hand" but serviceable enough. Where important, e.g. in loops, you may wish to scan (compile) the _f-string _before the loop and then run the resulting dfn. This may save perhaps 90% in execution time per iteration, with results closer to those formatted by hand. 


### Example:


<table>
  <tr>
   <td><strong>TradFn Example</strong>
   </td>
   <td><strong>DFn Example</strong>
   </td>
  </tr>
  <tr>
   <td><strong><code><em>Fmt1← ⍎0 ∆F '{...}...{}...{}'</em></code></strong>
   </td>
   <td><strong><code><em>Fmt1← ⍎0 ∆F '{...}...{}...{}' </em></code></strong>
   </td>
  </tr>
  <tr>
   <td><em>:FOR i :IN ⍳ nIter                  </em>
<p>

    <em>... do stuff ... </em>
<p>

    <strong><code><em>Fmt1 arg1 arg2 ...  </em></code></strong>
<em>:ENDFOR    </em>
   </td>
   <td><em>_←{ 0≥⍵: _←⍺</em>
<p>

    <em>... do stuff ...        </em>
<p>

    <em>⎕<strong><code>←Fmt1 </code></strong>arg1 arg2 </em>

    <em>⍺ ∇ ⍵-1     ⍝ Iterate</em>
<p>
<em>}⍨ nIter</em>
   </td>
  </tr>
</table>



##   \
[Preliminary] Relative ∆F Timings[^19]

Immediate Mode (_MODE=1_) vs. Code-Generation Mode (_MODE=0_)


<table>
  <tr>
   <td>Component
   </td>
   <td>Action
   </td>
   <td>ApproxTiming
   </td>
   <td>Relative Timings
   </td>
  </tr>
  <tr>
   <td><strong><code><em>∆F fmt ⍵1 ⍵2 …</em></code></strong>
   </td>
   <td><strong><code>Immediate</code></strong>
   </td>
   <td><strong><code><em>100%</em></code></strong>
   </td>
   <td><strong><code><em>⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕</em></code></strong>
   </td>
  </tr>
  <tr>
   <td><strong><code><em>CS←  0 ∆F fmt</em></code></strong>
<strong><code><em>DFN← ⍎CS </em></code></strong>
<strong><code><em>DFN ⍵1 ⍵2 …    </em></code></strong>
   </td>
   <td><strong>Generate Code \
Convert to DFn</strong>
<p>
<strong>Run</strong>
   </td>
   <td><strong><code><em> 86%</em></code></strong>
<strong><code><em>  4%</em></code></strong>
<strong><code><em> 10%</em></code></strong>
   </td>
   <td><strong><code><em>⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕</em></code></strong>
<strong><code><em>                     ⎕</em></code></strong>
<strong><code><em>                      ⎕⎕⎕</em></code></strong>
   </td>
  </tr>
</table>



# Example Code Listing (Suitable for Cut-and-Paste)

Examples

⍝ Example 1:  Text Fields and Code Fields {...} with simple variables.

⍝ Assume these declarations of multiline (matrix) objects:

names←↑'John Jones' 'Mary Smith'

addr←↑'1214 Maiden Ln' '24 Hersham Rd'

⍝ Example 1a:  Text and Code Fields "chained" together horizontally.

⍝ .

∆F'Name: { names }  Addr: { addr }'

⍝ Name: John Jones  Addr: 1214 Maiden Ln

⍝       Mary Smith        24 Hersham Rd

⍝ Example 1b:  Self-documenting code expressions {...→} in Code Fields.

∆F'{names→}  {addr→}'

⍝ names→John Jones   addr→1214 Maiden Ln

⍝       Mary Smith        24 Hersham Rd

⍝ Example 1c:  Titles (using the OVER shortcut %).

⍝ Note that strings in Code Fields {code} use double quotes like "this!".

∆F'{"Name" % names}  {"Address" % addr}'

⍝    Name        Address

⍝ John Jones  1214 Maiden Ln

⍝ Mary Smith  24 Hersham Rd

⍝ Example 1d: Adding a calculated field with line numbers (and one "null" title).

⍝    ↓ Null Title               ⊢→→       Same as (1c)        ←←⊣

_ \
∆_F'{ ⍬ % "I1,⊂.⊃" $ 1+⍳≢names} {"Name" % names}  {"Address" % addr}'

⍝      Name        Address   

⍝ 1. John Jones  1214 Maiden Ln

⍝ 2. Mary Smith  24 Hersham Rd

⍝ Example 2:  Calculations and Formatting in Code Fields ($ is a shortcut for ⎕FMT).

⍝ Assume these declarations:

c←100 20 12 23 ¯2

C2F←32+1.8∘×           ⍝ Celsius to Fahr.

⍝ Example 2a: Format specification as an argument ⍵1, i.e. (1+⎕IO)⊃⍵.

⍝ (Degree sign (°): ⎕UCS 176)  Result is a 5-row 15-col char matrix.

∆F'{ ⍵1 $ c }C = { ⍵1 $ C2F c }F' 'I3,⊂°⊃'

⍝ 100°C =  212°F

⍝  20°      68°

⍝  12°      54°

⍝  23°      73°

⍝  ¯2°      28°

⍝ Example 2b: Format specification hard-wired in Code Field.

⍝ Note alternative way to enter degree sign '°' as Unicode 176: "\{176}".

∆F'{ "I3,⊂°⊃" $ c }C = { "F5.1,⊂\{176}⊃" $ C2F c }F'

⍝ 100°C = 212.0°F

⍝  20°     68.0°

⍝  12°     53.6°

⍝  23°     73.4°

⍝  ¯2°     28.4°

⍝ Example 2c: Variant on (2b) with a header for each Code field using the % (OVER) shortcut.

hdrC←'Celsius'

hdrF←'Fahren.'

∆F'{ hdrC % "I3,⊂°⊃" $ c }  { hdrF % "F5.1,⊂°⊃" $ C2F c }'

⍝ Celsius  Fahren.

⍝  100°    212.0°

⍝   20°     68.0°

⍝   12°     53.6°

⍝   23°     73.4°

⍝   ¯2°     28.4°

⍝ Example 3a: BOX display option (1=⊃⌽⍺).

⍝ Displays each field in its own "box" (ignoring null (0-width) fields)

1 1 ∆F'one{}{}{ }two {"three"}{:0}{ }four'

⍝ ┌→──┐┌→┐┌→───┐┌→────┐┌→┐┌→───┐

⍝ │one││ ││two ││three││ ││four│

⍝ └───┘└─┘└────┘└─────┘└─┘└────┘

⍝ Example 3b: (3a) without the BOX option (0=⊃⌽⍺).

∆F'one{}{}{ }two {"three"}{:0}{ }three'   ⍝ Or: 1 0 ∆F ...

⍝  one two three four

⍝ Example 4a: Use of ⍹ to reference the next scalar in right argument ⍵.

⍝   ⍝             ⍹1≡1⊃⍵       ⍹2≡2⊃⍵                (⎕IO←0)

∆F'{"Name" % ⍹}  {"Addr" % ⍹}' 'J. Smith' '24 Broad Ln'

⍝   Name         Addr

⍝ J. Smith  24 Broad Ln

⍝ Example 4b: Interaction of ⍹N and simple ⍹.

∆F'{⍹5 ⍹} {⍹3 ⍹} {⍹1 ⍹}' 1 2 3 4 5 6

⍝ 5 6 3 4 1 2

∆F'πr²={pi←○1 ⋄ r←2 ⋄ pi×r×2}'

∆F'π={ "F10.8" $ ○1 }!'

∆F'1 SP="{ }", 5 SP="{ :5: }"'

∆F'This is a\⋄ three-line\⋄ field!'

∆F'&lt;{"\{97-108}...\{57-48}"}>'

⍝  &lt;abcdefghijkl...9876543210>

Who←↑'Mary' 'Captain'

∆F'Name: \⋄Rank:{}{Who}'

⍝  Name: Mary

⍝  Rank: Captain

Who←↑'Mary' 'Captain'

∆F'Name:\⋄Rank:{ }{Who}'

⍝  Name: Mary

⍝  Rank: Captain

Who←↑'Mary' 'Captain'

∆F'Name:\⋄Rank:{:5:}{Who}'

⍝  Name:     Mary

⍝  Rank:     Captain

Who←↑'Mary' 'Captain'

∆F'Name:\⋄Rank:{:⍵1:}{Who}' 5

⍝  Name:     Mary

⍝  Rank:     Captain

⍝ APL vs Python!

⍝ APL                                 # Python

⍝ Build fields all at once L to R    	# Build annotations row by row

RGB←123 145 255                      	⍝  R = 123 ; G = 145 ; B = 255

∆F 'R:\⋄ G:\⋄ B:{ }{⍪RGB}'            	⍝  print((f'R: {R}\nG: {G}\nB: {B}'))

⍝ R: 123                             	⍝    R: 123

⍝ G: 145                             	⍝    G: 145

⍝ B: 255                             	⍝    B: 255

⍝ Use APL for base conversions, etc.  # Base conversions are built in

∆F'"{"01"[2⊥⍣¯1⊢⍵1]}"' 7             	⍝  f'{7:b}'

⍝ "111"                              	⍝  '111'

⍝ Formatting Floats old-fashioned?    # Similar approach, different conventions

x←20.123                              ⍝  x = 20.123

∆F'{"F8.5"$x}' ⍝ User calcs width     ⍝  print(f'{x:0&lt;8}')   # User calcs width

⍝ 20.12300                            ⍝    20.12300

∆F'{5⍕x}'     ⍝ APL calcs width       ⍝  print(f'{x:.5f}')   # Python calcs width

⍝ 20.12300                            ⍝   20.12300


<!-- Footnotes themselves at the bottom. -->
## Notes

[^1]:
     The generic term <em>string interpolation </em>is discussed on Wikipedia, along with comparisons of implementations [[https://en.wikipedia.org/wiki/String_interpolation](https://en.wikipedia.org/wiki/String_interpolation)]. <em>F-strings</em>, as defined in Python, "provide a way to embed expressions inside string literals, using a minimal syntax" [[https://peps.python.org/pep-0498/](https://peps.python.org/pep-0498/)]. 

[^2]:
<p>
     That is, <em>(1⊃⍵)</em> given <em>⎕IO=0</em>, or <em>(⍵⊃⍨1+⎕IO)</em> in either origin.

[^3]:
<p>
     <em>Next scalar</em> is defined below.

[^4]:
<p>
     Under identical circumstances, of course, i.e. in the same calling environment with the same system variables.

[^5]:
     Comparing the value returned from  Immediate Mode<em> (Mode=1) </em>vs Pseudo-code Mode <em>(Mode=¯1)<strong>:</strong></em>
<p>
         <strong><code><em>∆F 'Pi={○1}{ }e={*1}' </em></code></strong>
    <strong><code><em> Pi=3.141592654 e=2.718281828</em></code></strong>
    <strong><code><em>    ¯1 ∆F 'Pi={○1}{ }e={*1}'  ⍝ Generates pseudo-code for inspection only</em></code></strong>
    <em> {{⊃⍙CHAIN/ 'Pi='({○1}⍵)({,' '}⍵) 'e='({*1}⍵)}'Pi={○1}{ }e={*1}',⍥⊆⍵}</em>
<p>
    <em> </em>Key: <strong>Auxiliary (Pseudo)code, F-string Translated to Code, Original F-string Text <em>(⍵0)</em></strong>

[^6]:
     The  _NS_ (Shared N amespace) option is experimental. No examples are currently given.

[^7]:
<p>
     Typical use: if <strong>true, evaluate</strong> the F-string; otherwise<strong>, skip processing</strong> <strong>and return</strong> immediately.<strong><em>
         (<code>1/</code>⍨<code>IF_TRUE) ∆F myFstring myData </code> </em></strong>

[^8]:
     Based on _self-documenting expressions_ in Python's implementation.

[^9]:
     Within each Code Field (see below), each _statement_ is evaluated _left to right_ as always.

[^10]:
     If all fields are null, the result will have shape _1 0._

[^11]:
     See also experimental option _NS,_ which provides a temporary namespace _⍺_ for sharing across Code Fields.

[^12]:

     Code Field comments will appear in self-documenting fields as expected.

[^13]:
<p>
     <em>⎕IO←0.</em>

[^14]:
<p>
     <strong>Box</strong> uses <em>display </em>from ws <em>dfns</em>.

[^15]:
     A Space Field may contain a single trailing comment. For format, see the _Basics of Code Fields_ above.

[^16]:

     But why?

[^17]:
     Output: 1a
               2b
               3c

[^18]:

     For newlines, _Dyalog APL_ generally uses carriage returns _(decimal 13)_ instead of line feeds _(10)_. Just go with it. 

[^19]:
     The benchmark code has six small fields, exhibiting a range of field types. ∆F strings are typically small in size and number.
