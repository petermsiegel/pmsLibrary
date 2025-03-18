 Render
 ;html;size;coord;hr;_
⍝ Extern: hr
 html←''
 html,←∊'^\h*⍝H\h?(.*)'⎕S'\1\r'⊢⎕NR⊃⎕XSI

 size←550 1250
 coord←'ScaledPixel'
 'hr'⎕WC'HTMLRenderer'('HTML'html)('Size'size)('Coord'coord)
 _←⍞

⍝H <p> ∆F is a function that makes it easy to format strings that dynamically display text, variables, and (executed) code expressions in an APL-friendly multi-line (matrix) style.</p>
⍝H <ul>
⍝H <li>Text expressions can generate multi-line Unicode strings  </li>
⍝H <li>Each code expression is an ordinary dfn, with a few extensions, including  <ul>
⍝H <li>the option of double-quoted strings, escape chars, and simple shortcuts (pseudo-functions) for formatting APL arrays.</li>
⍝H </ul>
⍝H </li>
⍝H <li>∘ All variables and code are evaluated (and, if desired, updated) in the user&#39;s calling environment.  </li>
⍝H <li>∆F is inspired by Python F-strings, but designed for APL.</li>
⍝H </ul>
⍝H <h1 id="a-quick-examples"><strong>A. Quick Examples</strong></h1>
⍝H <p>⍝  A self-contained f-string<br>   <strong>∆F &#39;Water boils at {100}°C and {32+1.8×100}°F.&#39;</strong><br><strong>Water boils at 100°C and 212°F.</strong> </p>
⍝H <p>⍝  An f-string expression using a dfn and a data variable<br>   <strong>C2F←  32+1.8∘×</strong><br>   <strong>tempC← 100</strong><br>   <strong>∆F &#39;Water boils at {tempC}°C and {C2F tempC}°F.&#39;</strong><br><strong>Water boils at 100°C and 212°F.</strong> </p>
⍝H <p>⍝  An f-string expression using space fields { } to separate 2-D objects<br>⍝  and data values passed as an argument<br>   <strong>∆F &#39;Water{ }freezes`⋄boils{ }at {`⍵1}°C and {C2F `⍵1}°F.&#39; (⍪0 100)</strong><br><strong>Water freezes at   0°C and  32°F.</strong><br>      <strong>boils      100       212</strong> </p>
⍝H <p>⍝  An expression using a new line escape (`<strong>⋄)** and numeric formatting ($: ⎕FMT)<br>   **∆F &#39;Water{ }freezes`⋄boils{ }at {&quot;F5.1&quot; $ C2F `⍵1}°F.&#39; (0 100)</strong><br><strong>Water freezes at  32.0°F.</strong><br>      <strong>boils      212.0</strong></p>
⍝H <p>⍝  An expression showing boxes for each output field.<br>   <strong>0 0 1 ∆F &#39;Water{ }freezes`⋄boils{ }at {&quot;F5.1&quot;$C2F `⍵1}°F.&#39; (0 100)</strong><br><strong>┌─────┬─┬───────┬─┬───┬─────┬───┐</strong><br><strong>│Water│ │freezes│ │at │ 32.0│°F.│</strong><br><strong>│     │ │boils  │ │   │212.0│   │</strong><br><strong>└─────┴─┴───────┴─┴───┴─────┴───┘</strong></p>
⍝H <h1 id=""></h1>
⍝H <h1 id="-1"></h1>
⍝H <h1 id="b-syntax"><strong>B. Syntax</strong></h1>
⍝H <p><strong><code>[ result← ]  [ options ] ∆F f-string [ args ]</code></strong></p>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th align="left"><em>f-string</em></th>
⍝H <th align="left">A string containing variables and <em>dfn</em> code, text, and formatting specifications to display a mixture of APL objects as a character matrix.</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td align="left"><em><strong>args</strong></em></td>
⍝H <td align="left">0 or more scalar &quot;arguments&quot; that can be easily used to incorporate arbitrary values into the <em><code>f-string</code></em>. Each scalar in <em><code>⍵</code></em> can be selected in an <em>⎕IO-independent</em> fashion:
⍝H <em><code>⍹1</code>,<code>⍹2</code></em>,etc.<em><strong>;</strong></em><em><code>⍹</code>**;*</em><code>⍹0</code>.*(alternatively :<em><code>⍵ 1</code>,<code>⍵ 2</code></em>,etc.<em><strong>;</strong></em><em><code>⍵ _</code>**;*</em><code>⍵ 0</code>*),where<em><code>⍹1</code></em>refers to the<em>first</em>scalar(<code>1⊃⍵</code>);bare<em><code>⍹</code></em>: the<em>next scalar</em>[∧1];<em><code>⍹0</code></em>: the<em><code>f-string</code></em>itself.</td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><em><strong>options</strong></em></td>
⍝H <td align="left">**<em>Category</em>: [ [ <em>dfn</em> [ <em>debug</em> [ <em>box</em> ] ]</td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><em><strong>result</strong></em></td>
⍝H <td align="left">If dfn=0:    A character matrix, at a minimum a single row of 0-width (of shape <em><code>1 0</code></em>). If dfn=1:    A dfn that, when called, will return the same character matrix, given the same variables in the session/environment and/or additional arguments.</td>
⍝H </tr>
⍝H </tbody></table>
⍝H <p><strong>MODE option <em>(0⊃⍺)</em></strong></p>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th align="center">MODE Number</th>
⍝H <th align="center">MODE Description</th>
⍝H <th align="left">ACTION</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td align="center"><em><strong>1</strong></em></td>
⍝H <td align="center"><em><strong>IMMED Immediate</strong></em></td>
⍝H <td align="left"><strong>Returns</strong> a char matrix based on specifications within an <em><code>f-string</code></em> evaluated at runtime based on variables in the calling environment and passed as arguments to the <em><code>∆F</code></em> function.  Fields are executed from left to right, just like APL statements separated by <em><code>♢</code></em>.  <strong>(Default).</strong></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="center"><em><strong>0</strong></em></td>
⍝H <td align="center"><em><strong>CODEGEN Code-
 Generation</strong></em></td>
⍝H <td align="left"><strong>Returns</strong> a char vector, containing an executable in string form, which can be evaluated directly or established as a <em>dfn</em> (and called). Its output is identical to that under <em>immediate</em> mode (above).[^2] <em><code>MyDfn← ⍎0 ∆F myFString      ⍝ Create Dfn MyDfn (1 2 3) (⎕TS) etc.    ⍝ Call Dfn later</code></em></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="center"><em><strong>¯1</strong></em></td>
⍝H <td align="center"><em><strong>PSEUDO-CODE</strong></em></td>
⍝H <td align="left"><strong>Returns</strong> a char vector with a compact pseudo-code equivalent of the executable dfn returned via <em><code>Mode=0</code>,</em> suitable for inspection, etc. Output fields are generated in the order presented in the <em><strong><code>f-string</code></strong></em>.[^3]</td>
⍝H </tr>
⍝H </tbody></table>
⍝H <p>  <strong>BOX option  <em>(1⊃⍺)</em></strong></p>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th align="center">BOX</th>
⍝H <th align="left">Action</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td align="center"><em><strong>0</strong></em></td>
⍝H <td align="left">Displays each field normally (returns per MODE).  <strong>(Default).</strong></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="center"><em><strong>1</strong></em></td>
⍝H <td align="left">Displays each field in a 2D box (returns per MODE). 0-width fields are not displayed.  Blanks are replaced with a center dot (·).  Useful for debugging or pedagogy.</td>
⍝H </tr>
⍝H </tbody></table>
⍝H <p>⍝   ∆F Box example<br>    C2F← 32 + 1.8 ∘×<br>    1 1 ∆F &#39;Water boils at {100}°C and {C2F 100}°F.&#39;<br><strong>┌───────────────┐···┌───────┐···┌───┐</strong><br><strong>│Water·boils·at·│100│°C·and·│212│°F.│</strong><br><strong>└───────────────┘···└───────┘···└───┘</strong></p>
⍝H <p><strong>MYNS  (Shared Code Field Namespace) option</strong>[^4]  <em><strong>(2⊃⍺)  EXPERIMENTAL</strong></em></p>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th align="center">NS</th>
⍝H <th align="left">Action</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td align="center"><em><strong>0</strong></em></td>
⍝H <td align="left">Code Fields (CFs) have no <em>common</em> private namespace provided to them. <strong>Argument</strong> <code>⍺</code> <strong>is undefined.</strong> A CF may use/define variables in the calling environment per dfn conventions, with updates visible to all CFs to its right and outside ∆F.  <strong>(Default).</strong></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="center"><em><strong>1</strong></em></td>
⍝H <td align="left"><strong>Argument</strong> <code>⍺</code> <strong>is defined as an anonymous namespace visible to every Code Field (CF) while the current ∆F call is active.</strong> A CF may use/define variables in  <code>⍺</code> per dfn conventions, with updates visible to all CFs to its right, as well as variables in the calling environment.</td>
⍝H </tr>
⍝H </tbody></table>
⍝H <p><strong>EXECNS  (Execution Namespace) option</strong>[^5]  <em><strong>(3⊃⍺)  EXPERIMENTAL</strong></em></p>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th align="center">EXECNS</th>
⍝H <th align="left">Action</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td align="center"><em><strong>0</strong></em></td>
⍝H <td align="left">Sets the namespace in which code fields are executed in <em><strong>IMMED</strong></em> mode to the namespace from which <em>∆F</em> was called (<em>0⊃⎕RSI)</em>. <strong>(Default).</strong></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="center"><em><strong>ns_ref</strong></em></td>
⍝H <td align="left">If <em><strong>MODE=1</strong></em> and <em><strong>ns_ref</strong></em> is a namespace (class 9), sets the namespace in which code fields are executed in Immed mode to <em><strong>ns_ref</strong></em>.  Otherwise, an error is signaled. This option is ignored  if <em><strong>MODE≠1</strong></em>, since potential  execution is under user control  (for <em><strong>MODE=0</strong></em>).</td>
⍝H </tr>
⍝H </tbody></table>
⍝H <p><strong>MISCELLANEOUS OPTIONS <em>(⍺)</em></strong></p>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th>MISC.</th>
⍝H <th align="left">Action</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td><em><strong>’help’</strong></em></td>
⍝H <td align="left"><em><code>&#39;help&#39; ∆F anything</code></em>      or        <em><code>∆F⍨&#39;help&#39;</code></em>   Displays an informational (HELP) window; right argument <em><code>(⍵)</code></em> is ignored.<strong>Returns</strong>shy char matrix :<em><code>(1 0⍴&# 39;&# 39;).</code></em></td>
⍝H </tr>
⍝H <tr>
⍝H <td><em><strong>⍬</strong></em></td>
⍝H <td align="left"><em><code>⍬ ∆F anything</code></em> Exits  immediately; right argument <em><code>(⍵)</code></em> is ignored.[^6] <strong>Returns</strong> shy char matrix: <em><code>(1 0⍴&#39; &#39;)</code>.</em></td>
⍝H </tr>
⍝H </tbody></table>
⍝H <h1 id="-2"></h1>
⍝H <h1 id="b-examples"><strong>B. Examples</strong></h1>
⍝H <p>We&#39;ll start with examples first, but feel free to peek ahead for definitions and specifications.</p>
⍝H <p><strong>Example 1:</strong>  Text Fields and Code Fields <em><strong>{...}</strong></em> with simple variables.<br>Assume these declarations of multiline (matrix) objects:</p>
⍝H <h4 id="names←--↑john-jones--mary-smith"><em><code>names←  ↑&#39;John Jones&#39;  &#39;Mary Smith&#39;</code></em></h4>
⍝H <h4 id="addr←---↑1214-maiden-ln--24-hersham-rd"><em><code>addr←   ↑&#39;1214 Maiden Ln&#39;  &#39;24 Hersham Rd&#39;</code></em></h4>
⍝H <h4 id="-3"></h4>
⍝H <p><strong>Example 1a:</strong>  Text and Code Fields &quot;chained&quot; together horizontally.</p>
⍝H <h4 id="∆f-name--names---addr--addr-"><em><code>∆F &#39;Name: { names }  Addr: { addr }&#39;</code></em></h4>
⍝H <h5 id="name-john-jones--addr-1214-maiden-ln"><em><code>Name: John Jones  Addr: 1214 Maiden Ln</code></em></h5>
⍝H <h5 id="mary-smith--------24-hersham-rd"><em><code>Mary Smith        24 Hersham Rd</code></em></h5>
⍝H <p><strong>Example 1b:</strong>  Self-documenting[^7] code expressions <em><code>{...→}, {...↓}</code></em> in Code Fields.</p>
⍝H <h4 id="∆f-names→--addr→-----⍝-horizontal-→"><em><code>∆F &#39;{names→}  {addr→}&#39;     ⍝ Horizontal →</code></em></h4>
⍝H <h5 id="names→john-jones---addr→1214-maiden-ln"><em><code>names→John Jones   addr→1214 Maiden Ln</code></em></h5>
⍝H <h5 id="mary-smith--------24-hersham-rd-1"><em><code>Mary Smith        24 Hersham Rd</code></em></h5>
⍝H <h4 id="∆f-names↓--addr↓-----⍝-vertical-↓"><em><code>∆F &#39;{names↓}  {addr↓}&#39;     ⍝ Vertical ↓</code></em></h4>
⍝H <h5 id="names↓--------addr↓"><em><code>names↓        addr↓</code></em></h5>
⍝H <h5 id="john-jones--1214-maiden-ln"><em><code>John Jones  1214 Maiden Ln</code></em></h5>
⍝H <h5 id="mary-smith--24-hersham-rd"><em><code>Mary Smith  24 Hersham Rd</code></em></h5>
⍝H <p><strong>Example 1c:</strong>  Titles (using the <em><strong>OVER</strong></em> shortcut <em><strong>%</strong>).</em><br>Note that strings in Code Fields <em><code>{code}</code></em> use double quotes like <em><code>&quot;this!&quot;</code></em>.</p>
⍝H <h4 id="∆f-name--names--address--addr"><em><code>∆F &#39;{&quot;Name&quot; % names}  {&quot;Address&quot; % addr}&#39;</code></em></h4>
⍝H <h5 id="name--------address"><em><code>Name        Address</code></em></h5>
⍝H <h5 id="john-jones--1214-maiden-ln-1"><em><code>John Jones  1214 Maiden Ln</code></em></h5>
⍝H <h5 id="mary-smith--24-hersham-rd-1"><em><code>Mary Smith  24 Hersham Rd</code></em></h5>
⍝H <p><strong>Example 1d:</strong> Adding a calculated field with line numbers (and one &quot;null&quot; title).</p>
⍝H <h4 id="⍝----↓-null-title---------------⊢→→-------same-as-1c--------←←⊣"><em><code>⍝    ↓ Null Title               ⊢→→       Same as (1c)        ←←⊣</code></em></h4>
⍝H <h4 id="∆f-⍬--i1⊂⊃--1⍳≢names-name--names-address--addr"><em><code>∆F&#39;{ ⍬ % &quot;I1,⊂.⊃&quot; $ 1+⍳≢names} {&quot;Name&quot; % names} {&quot;Address&quot; % addr}&#39;</code></em></h4>
⍝H <h5 id="name--------address-1"><em><code>Name        Address</code></em></h5>
⍝H <h5 id="1-john-jones--1214-maiden-ln"><em><code>1. John Jones  1214 Maiden Ln</code></em></h5>
⍝H <h5 id="2-mary-smith--24-hersham-rd"><em><code>2. Mary Smith  24 Hersham Rd</code></em></h5>
⍝H <p><strong>Example 2:</strong>  Calculations and Formatting in Code Fields <em><code>($</code></em> is a shortcut for <em><code>⎕FMT)</code></em>.<br>Assume these declarations:</p>
⍝H <h4 id="c←---100-20-12-23-¯2----⍝-some-temps-in-celsius"><em><code>c←   100 20 12 23 ¯2    ⍝ Some temps in Celsius</code></em></h4>
⍝H <h4 id="c2f←-3218∘×-----------⍝-converts-celsius-to-fahr"><em><code>C2F← 32+1.8∘×           ⍝ Converts Celsius to Fahr.</code></em></h4>
⍝H <p><strong>Example 2a:</strong> Format specification as an argument <strong>⍵1</strong>, i.e. <strong>(<em>1+⎕IO)⊃⍵.</em></strong><br>(Degree sign (°): ⎕UCS 176)  Result is a 5-row 15-col char matrix.</p>
⍝H <h4 id="∆f--⍵1--c-c---⍵1--c2f-c-f-i3⊂°⊃"><em><code>∆F &#39;{ ⍵1 $ c }C = { ⍵1 $ C2F c }F&#39; &#39;I3,⊂°⊃&#39;</code></em></h4>
⍝H <h5 id="100°c---212°f"><em><code>100°C =  212°F</code></em></h5>
⍝H <h5 id="20°------68°"><em><code>20°      68°</code></em></h5>
⍝H <h5 id="12°------54°"><em><code>12°      54°</code></em></h5>
⍝H <h5 id="23°------73°"><em><code>23°      73°</code></em></h5>
⍝H <h5 id="¯2°------28°"><em><code>¯2°      28°</code></em></h5>
⍝H <p><strong>Example 2b:</strong> Format specification &quot;hardwired&quot; in Code Field.<br>Note alternative way to enter degree sign <strong>&#39;°&#39;</strong> as Unicode 176: <em><code>&quot;\U{176}&quot;.</code></em></p>
⍝H <h4 id="∆f--i3⊂°⊃--c-c---f51⊂u176⊃--c2f-c-f"><em><code>∆F &#39;{ &quot;I3,⊂°⊃&quot; $ c }C = { &quot;F5.1,⊂\U{176}⊃&quot; $ C2F c }F&#39;</code></em></h4>
⍝H <h5 id="100°c--2120°f"><em><code>100°C = 212.0°F</code></em></h5>
⍝H <h5 id="20°-----680°"><em><code>20°     68.0°</code></em></h5>
⍝H <h5 id="12°-----536°"><em><code>12°     53.6°</code></em></h5>
⍝H <h5 id="23°-----734°"><em><code>23°     73.4°</code></em></h5>
⍝H <h5 id="¯2°-----284°"><em><code>¯2°     28.4°</code></em></h5>
⍝H <p><strong>Example 2c:</strong> Variant on (2b) with a header for each Code field using the % (OVER) shortcut.</p>
⍝H <h4 id="hdrc←-celsius"><em><code>hdrC← &#39;Celsius&#39;</code></em></h4>
⍝H <h4 id="hdrf←-fahren"><em><code>hdrF← &#39;Fahren.&#39;</code></em></h4>
⍝H <h4 id="∆f--hdrc--i3⊂°⊃--c----hdrf--f51⊂°⊃--c2f-c-"><em><code>∆F &#39;{ hdrC % &quot;I3,⊂°⊃&quot; $ c }  { hdrF % &quot;F5.1,⊂°⊃&quot; $ C2F c }&#39;</code></em></h4>
⍝H <h5 id="celsius--fahren"><em><code>Celsius  Fahren.</code></em></h5>
⍝H <h5 id="100°----2120°"><em><code>100°    212.0°</code></em></h5>
⍝H <h5 id="20°-----680°-1"><em><code>20°     68.0°</code></em></h5>
⍝H <h5 id="12°-----536°-1"><em><code>12°     53.6°</code></em></h5>
⍝H <h5 id="23°-----734°-1"><em><code>23°     73.4°</code></em></h5>
⍝H <h5 id="¯2°-----284°-1"><em><code>¯2°     28.4°</code></em></h5>
⍝H <p><strong>Example 3a:</strong> <em><strong>BOX</strong></em> display option <em><strong>(1=1⊃⍺).</strong></em><br>Displays each field in its own &quot;box&quot; (ignoring (0-width) <strong>null fields</strong>).<br>Spaces are replaced by center dots (<code>·</code>).</p>
⍝H <h4 id="1-1-∆f-one-two-three0-four"><em><code>1 1 ∆F &#39;one{}{}{ }two {&quot;three&quot;}{:0:}{ }four&#39;</code></em></h4>
⍝H <h5 id="┌→──┐┌→┐┌→───┐┌→────┐┌→┐┌→───┐"><em><code>┌→──┐┌→┐┌→───┐┌→────┐┌→┐┌→───┐</code></em></h5>
⍝H <h5 id="│one││·││two·││three││·││four│"><em><code>│one││·││two·││three││·││four│</code></em></h5>
⍝H <h5 id="└───┘└─┘└────┘└─────┘└─┘└────┘"><em><code>└───┘└─┘└────┘└─────┘└─┘└────┘</code></em></h5>
⍝H <p><strong>Example 3b:</strong> (3a) <em>without</em> the <em><strong>BOX</strong></em> option <em><strong>(0=1⊃⍺)</strong></em>.</p>
⍝H <h4 id="∆f-one-two-three0-four---⍝-⍺1-0"><em><code>∆F &#39;one{}{}{ }two {&quot;three&quot;}{:0:}{ }four&#39;   ⍝ ⍺=1 0</code></em></h4>
⍝H <h5 id="one-two-three-four"><em><code>one two three four</code></em></h5>
⍝H <p><strong>Example 4a:</strong> Use of ⍹ to reference the next scalar in right argument ⍵. </p>
⍝H <h4 id="⍝-------------⍹1≡1⊃⍵--------⍹2≡2⊃⍵----------------⎕io←0"><em><code>⍝             ⍹1≡1⊃⍵        ⍹2≡2⊃⍵                (⎕IO←0)</code></em></h4>
⍝H <h4 id="∆f-name--⍹--addr--⍹--j-smith-24-broad-ln"><em><code>∆F &#39;{&quot;Name&quot; % ⍹}  {&quot;Addr&quot; % ⍹}&#39;  &#39;J. Smith&#39; &#39;24 Broad Ln&#39;</code></em></h4>
⍝H <h5 id="name---------addr"><em><code>Name         Addr</code></em></h5>
⍝H <h5 id="j-smith--24-broad-ln"><em><code>J. Smith  24 Broad Ln</code></em></h5>
⍝H <p><strong>Example 4b:</strong> Interaction of ⍹N and simple ⍹.</p>
⍝H <h4 id="∆f-⍹5-⍹-⍹3-⍹-⍹1-⍹-1-2-3-4-5-6"><em><code>∆F &#39;{⍹5 ⍹} {⍹3 ⍹} {⍹1 ⍹}&#39; 1 2 3 4 5 6</code></em></h4>
⍝H <h5 id="5-6-3-4-1-2"><em><code>5 6 3 4 1 2</code></em></h5>
⍝H <h1 id="c-the-f-string-⍹0"><strong>C. The</strong> <em><code>f-String</code></em> <strong><code>(⍹0)</code></strong></h1>
⍝H <p>The <em><code>f-string</code></em> is a character vector defining 0 or more &quot;fields.&quot; Fields are evaluated starting from the <em>leftmost</em> moving <em>to the right</em> (as for APL statements on a single line[^8]), converted to character matrices (if not already), and &quot;chained&quot; together into a single matrix. The successful result will always have rank <em><code>2</code></em>.[^9]  The input <em><code>f-string</code></em> is in special variable ⍹0, visible to all Code Fields.  </p>
⍝H <p> There are 3 types of field in an f-string (highlighted):</p>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th align="left">Field Type</th>
⍝H <th align="left">Example</th>
⍝H <th align="left">Output</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td align="left"><strong>Code</strong> <strong>Field</strong></td>
⍝H <td align="left"><em><code>∆F &#39;πr²={ pi←○1</code> <code>♢ </code> <code>r←2</code> <code>♢ </code> <code>pi×r*2}&#39; ∆F &#39;π={⎕FR←1287</code> <code>♢ </code> <code>16⍕ ○1 }!&#39;</code></em></td>
⍝H <td align="left"><em>π<code>r</code>²<code>=12.56637061</code> π<code>=3.1415926535897932!</code></em></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><strong>Space</strong> <strong>Field</strong></td>
⍝H <td align="left"><em><code>∆F &#39;1{ }1, 2{:2:}2, 3{:⍵1:}3.&#39; 3</code></em></td>
⍝H <td align="left"><em><code>1 1, 2  2, 3   3.</code></em></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><strong>Text</strong> <strong>Field</strong></td>
⍝H <td align="left"><em><code>∆F &#39;1:\♢ 2:\♢ 3:{ }Mary\♢ John\♢ Ted&#39;</code></em></td>
⍝H <td align="left"><em><code>1: Mary 2: John 3: Ted</code></em></td>
⍝H </tr>
⍝H </tbody></table>
⍝H <p>We&#39;ll start with <strong>Code Fields</strong> first, since they’re where all the power of <em><code>f-strings</code></em> resides.</p>
⍝H <h2 id="-4"></h2>
⍝H <h2 id="c1-code-fields"><strong>C1. Code Fields</strong></h2>
⍝H <p>Code Fields are single-line dfns, and may include multiple statements, guards, error handling, and so on. Each Code Field has an implicit right argument[^10] that includes everything passed to ∆F as <em><code>⍵</code></em> when called; there are shortcuts (special variables) for accessing the scalars in this argument described below.</p>
⍝H <p><em><code>R← 12 2.3 19</code></em><br><em><code>∆F &#39;{ A←(○⊢×⊢)R ⍝ area</code> <strong>♢</strong>  <code>&quot;F4.1,F8.2&quot; $ R,⍤¯1⊣ A }&#39;</code></em><br><em><code>12.0  452.39</code></em><br> <em><code>2.3   16.62</code></em><br><em><code>19.0 1134.11</code></em></p>
⍝H <h3 id="a--basics-of-code-fields"><strong>a.  Basics of Code Fields</strong></h3>
⍝H <ul>
⍝H <li>A Code Field itself is evaluated as a regular Dfn, left to right across statements, but right to left within a statement.  </li>
⍝H <li>A Code Field begins with a left brace <em><strong><code>{</code></strong></em> and ends with a balancing right brace <em><strong><code>}</code></strong></em>.   </li>
⍝H <li>A left brace preceded by a backslash <em><code>\{</code></em> does <em>not</em> begin a Code Field and, likewise, a <em><strong><code>\}</code></strong></em> does not end one. See <em>Text Fields.</em>  </li>
⍝H <li>A Code Field may contain any dfn code on a single line, including multiple stmts, guards, and error guards, with several modifications, shown below.  </li>
⍝H <li>A Code Field may include (limited) comments.[^11] Each comment:   <ul>
⍝H <li>must start with a lamp:    <em><code>⍝</code></em>  </li>
⍝H <li>must contain no backslashes,  statement terminators, or braces:    <em><strong>\</strong></em>  *<strong>♢ *  <em>{</em>   <em>}</em></strong>   </li>
⍝H <li>will  end just before either a statement terminator or a closing brace:    <em><strong>♢</strong></em>  <em><strong><code>}</code></strong></em>.</li>
⍝H </ul>
⍝H </li>
⍝H </ul>
⍝H <h4 id="∆f--pi←○1-⍝-calc-pi-♢-e←1-⍝-calc-e-♢-pie-⍝-silly-"><em><code>∆F &#39;{ pi←○1 ⍝ Calc pi ♢ e←*1 ⍝ Calc e ♢ pi*e ⍝ Silly! }&#39;</code></em></h4>
⍝H <h5 id="2245915772"><em><code>22.45915772</code></em></h5>
⍝H <h3 id="b--code-fields-special-variables--⍹0-⍹-etc-outside-strings"><strong>b.  Code Fields: Special Variables</strong>  <em>⍹0, ⍹,</em> <strong>etc., (outside strings)</strong></h3>
⍝H <ol>
⍝H <li><p><em><code>⍹0, ⍹1, ... ⍹N</code>,</em> denote the scalars in the right arg <em><code>(⍵)</code></em> passed to <em><code>∆F.</code></em><br><em><code>⍹</code></em> is the glyph <em><code>⎕UCS 9081.</code></em></p>
⍝H <p>  <strong>Special Variables in Code Fields (Outside Strings)</strong></p>
⍝H </li>
⍝H </ol>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th align="left">Shortcut</th>
⍝H <th align="left">Action</th>
⍝H <th align="left">Value</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td align="left"><em><code>⍹0, ⍵0</code></em></td>
⍝H <td align="left"><em><code>(0⊃⍵)</code></em></td>
⍝H <td align="left">the <em><code>f-string</code></em> itself.</td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><em><code>⍹1,⍵1</code></em></td>
⍝H <td align="left"><em><code>(1⊃⍵)</code></em></td>
⍝H <td align="left">the first scalar after the <em><code>f-string</code></em>.</td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><em><code>⍹N,⍵N</code></em></td>
⍝H <td align="left"><em><code>(N⊃⍵)</code></em></td>
⍝H <td align="left">the Nth scalar after the <em><code>f-string</code></em>, where N is one or more digits.</td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><em><code>⍹, ⍵_</code></em></td>
⍝H <td align="left"><em><code>(M⊃⍵)</code></em></td>
⍝H <td align="left">the <em>next</em> scalar <code>(M⊃⍵)</code>, based on incrementing from the <em><code>⍹</code></em> or <em><code>⍹N</code></em> to its left. If none, <em><strong><code>(1⊃⍵</code></strong><code>),</code></em> first scalar <em>after</em> the <em><code>f-string</code></em> itself.</td>
⍝H </tr>
⍝H </tbody></table>
⍝H <ol>
⍝H <li>If this is first use of  any form of <em><code>⍹</code>,</em> then the current <code>⍹</code> refers to <code>⍹1</code>.The counter for bare <em><code>⍹</code></em>, initially 0, is incremented by 1 just <em>before</em> each use.   <ol start="2">
⍝H <li>*<code>⍹</code>*’s index is set at “compile” time, scanning left to right, <em><strong>not</strong></em> right to left as you would expect for execution within a single statement. Thus,<br><strong><code>∆F &#39;{⍹ ⍹ ⍹} and {⍹ ⍹ ⍹}&#39; 1 2 3 4 5 6</code></strong><br>returns<br> <strong><code>1 2 3 and 4 5 6</code></strong><br>as if<br> <strong><code>∆F &#39;{⍹1 ⍹2 ⍹3} and {⍹4 ⍹5 ⍹6}’</code></strong>  </li>
⍝H <li>If a <em><code>⍹N</code></em> variable is the most recent to the left of the current simple <em><strong><code>⍹</code></strong></em> in <em>any</em> prior code field, the counter for <em><code>⍹</code></em> is incremented to <em><strong>N+1.</strong></em>  </li>
⍝H <li>If a simple <code>⍹</code> variable is the most recent to the left of the current simple <em><strong><code>⍹</code></strong></em>, and the former refers to the <em><code>M</code>-th</em> scalar in <em><code>⍵,</code></em> then the latter refers to the <em><code>(M+1)</code>-st,</em>  the <em>next</em> scalar in ⍵.  </li>
⍝H <li>By definition, <em><code>⍹0</code></em>  (the <em><code>f-string</code></em>) can only be accessed <em>explicitly</em>, not using bare <code>⍹</code>.</li>
⍝H </ol>
⍝H </li>
⍝H <li>Omega <em><code>⍵</code></em> without any suffixed digit or underscore is <em>not</em> a special variable. Within each Code Field, it will refer to the <em>entire</em> original right argument <em><code>⍵</code></em> to <em><code>∆F</code></em>: every scalar (including the <em><code>f-string</code></em>).</li>
⍝H </ol>
⍝H <h4 id="∆f--0-whoops-♢-○⍹1-⍝-calc-⍹1×pi--2"><em><code>∆F &#39;{ 0:: &quot;whoops!&quot; ♢ ○⍹1 ⍝ Calc ⍹1×pi }&#39; 2</code></em></h4>
⍝H <p><strong><code>6.283185307</code></strong></p>
⍝H <h4 id="∆f--0-whoops-♢-○⍹1-⍝-calc-⍹1×pi--two"><em><code>∆F &#39;{ 0:: &quot;whoops!&quot; ♢ ○⍹1 ⍝ Calc ⍹1×pi }&#39; &#39;two&#39;</code></em></h4>
⍝H <h5 id="whoops"><em><code>whoops!</code></em></h5>
⍝H <h3 id="c--code-fields-quoted-strings"><strong>c.  Code Fields: Quoted Strings</strong></h3>
⍝H <ul>
⍝H <li>Strings within Code Fields that fall within double quotes (<strong>&quot;...&quot;</strong>), rather than single quotes, allow for special escapes; except as indicated here, they work the same as standard APL strings.  </li>
⍝H <li>There are a limited number of special substrings within Code Field double-quoted strings. You can safely ignore these details unless you need carriage returns or <em><code>⎕UCS</code></em> characters in strings.</li>
⍝H </ul>
⍝H <p><strong>Substrings in Double-quoted Strings in Code Fields</strong></p>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th align="left">Substring</th>
⍝H <th align="left">What it indicates…</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td align="left"><em><code>\♢ </code></em></td>
⍝H <td align="left">A carriage return (⎕UCS 13). If MODE=¯1: a visible carriage return (<code>␍</code>) for debugging or inspection.</td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><em><code>\\♢
 ♢  </code></em></td>
⍝H <td align="left"><em><code>\♢</code></em> literal, <em><code>♢ </code></em> literal.</td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><em><code>\U{ddd}     \u{ddd}
 \U{ddd-eee}\u{ddd-eee}</code></em></td>
⍝H <td align="left"><em><code>⎕UCS ddd</code>                   — ddd</em> contains 1 or more digits. <em><code>(⎕UCS ddd)</code></em> to <em><code>(⎕UCS eee)</code></em> inclusive                                      <em>—</em> <em>ddd</em>, <em>eee</em> each contains 1 or more digits.   Ex:  <em><code>∆F &#39;&lt;{&quot;\u{97-108}...\u{57-48}&quot;}&gt;&#39;</code></em>  <em><code>&lt;abcdefghijkl...9876543210&gt;</code></em></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><code>\\u{ddd}  \\U{ddd}
 \\U{ddd-eee}\\U{anything}</code></td>
⍝H <td align="left"><code>\u{ddd}</code>       omitting the second escape*.*
 <code>\U{ddd}</code>omitting the second escape*.*
 <code>\u{ddd-eee}</code>omitting the second escape.<code>\\U{anything}</code>(space after<code>U</code>): as is,including the second escape.</td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left">Any other substring starting with a backslash <em><code>\</code></em>.</td>
⍝H <td align="left">Unchanged (backslash is the usual APL  function/operator).    <code>+\1 2 3</code></td>
⍝H </tr>
⍝H </tbody></table>
⍝H <h3 id="d-code-fields-shortcut-functions-only-outside-strings"><strong>d. Code Fields: Shortcut &quot;Functions&quot; (Only Outside Strings)</strong></h3>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th align="left">Name</th>
⍝H <th align="left">Short-
 cut</th>
⍝H <th align="left">Syntax</th>
⍝H <th align="left">Usage</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td align="left"><strong>Format</strong></td>
⍝H <td align="left"><em><code>$</code></em> infix</td>
⍝H <td align="left"><em><code>spec $ obj</code></em></td>
⍝H <td align="left">Calls <em><code>spec ⎕FMT obj.</code></em>
Ex:<em><code>{&quot;I2&quot;$⍳2}</code></em></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><strong>Box</strong></td>
⍝H <td align="left"><em><code>$$</code></em> prefix</td>
⍝H <td align="left"><em><code>$$ obj</code></em></td>
⍝H <td align="left">Displays a box[^12] containing  the object <em><code>obj.</code></em></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><strong>Over</strong></td>
⍝H <td align="left"><em><code>%</code></em> infix</td>
⍝H <td align="left"><em><code>obj1 % obj2</code></em></td>
⍝H <td align="left">Displays <em><code>obj1</code></em> <em>on top of (over)</em> <em><code>obj2</code></em>, each centered.
Ex:<em><code>{&quot;Temps&quot;%23 19 17}</code></em></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><strong>Chain</strong></td>
⍝H <td align="left"><em><code>%%</code></em> infix</td>
⍝H <td align="left"><em><code>obj1 %% obj2</code></em></td>
⍝H <td align="left">Displays <em><code>obj1</code></em> to the <em>left</em> of <em><code>obj2</code></em>, neither centered.</td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><strong>Self- Documenting Code</strong></td>
⍝H <td align="left"><strong>a. <em><code>→</code></em></strong> suffix <strong>b. <em><code>↓</code></em></strong> suffix</td>
⍝H <td align="left"><strong>a.</strong> <em><code>{... →}</code></em>
 <strong>b.</strong><em><code>{...↓}</code></em></td>
⍝H <td align="left">Generates self-documenting code, i.e. prints the contents (source) of the field {<strong>a.</strong> <em>followed by /</em> <strong>b.</strong> <em>over</em>} the value of the code executed.
Ex:<em><code>{MyTemps→}⇒&# 39;MyTemps→{MyTemps}&# 39;{MyTemps↓}⇒&# 39;&quot;MyTemps↓&quot;%{MyTemps}&# 39;</code></em>Input spacing is preserved..</td>
⍝H </tr>
⍝H </tbody></table>
⍝H <h2 id="-5"></h2>
⍝H <h2 id="c2-space-fields-----------5---⍹2---⍵2-"><strong>C2. Space Fields:</strong>      <code>{  } , { :5: }, { :⍹2: } { :⍵2: }</code></h2>
⍝H <p>Space Fields look like stripped down Code Fields.[^13]  They have two functions: </p>
⍝H <ul>
⍝H <li>Separate one (possibly multiline) Text Field from the next;  </li>
⍝H <li>Insert a field of zero or more spaces.</li>
⍝H </ul>
⍝H <p>A 0-width Space Field <em><code>{}</code></em> is handy as a separator between fields (see examples below).</p>
⍝H <p>Space fields indicate the number of spaces between (other) fields  in three ways:</p>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th align="left">Subtype</th>
⍝H <th align="left">Template</th>
⍝H <th align="left">Description</th>
⍝H <th align="left">Action</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td align="left"><strong>Simple Spaces</strong></td>
⍝H <td align="left"><code>{ss}</code></td>
⍝H <td align="left">ss: 0 or more spaces</td>
⍝H <td align="left">inserts spaces shown</td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><strong>Numeric</strong></td>
⍝H <td align="left"><code>{:nn:}</code></td>
⍝H <td align="left">nn: zero or more digits</td>
⍝H <td align="left">inserts <em>nn</em> spaces</td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><strong>Special Variable</strong></td>
⍝H <td align="left"><code>{:⍹N:}, {:⍹:}, {:⍵N:}, {:⍵_:}</code></td>
⍝H <td align="left">a single special variable</td>
⍝H <td align="left">inserts <em>⍹N</em> spaces at execution time.</td>
⍝H </tr>
⍝H </tbody></table>
⍝H <p>For Numeric or Special Variable Space Fields</p>
⍝H <ul>
⍝H <li>The colon prefix is required;  the colon suffix is optional.  </li>
⍝H <li>An ill-formed Space Field will be treated as a Code Field, likely triggering an error.  </li>
⍝H <li>In a Space Field, only one special variable is allowed (i.e. ⍹5 or ⍹, but not ⍹4+⍹5, etc.).  Its value will be used at execution time to determine the number of spaces.  </li>
⍝H <li>If you want to calculate spaces dynamically in a more complex way,[^14] simply use a code field:<br> {&quot; &quot;⍴⍨⍹4+2×⍹3}.</li>
⍝H </ul>
⍝H <p>Space Field Examples   </p>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th align="left">(Text-Field Space and) 0-Width Space Field</th>
⍝H <th align="left">Simple Space Field</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td align="left"><code>Who← ↑&#39;Mary&#39; &#39;Captain&#39; ∆F &#39;Name: \♢Rank:{}{Who}&#39;          Name: Mary                                            Rank: Captain</code></td>
⍝H <td align="left"><code>Who← ↑&#39;Mary&#39; &#39;Captain&#39; ∆F &#39;Name:\♢Rank:{ }{Who}&#39;  Name: Mary    Rank: Captain</code></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><strong>Numeric Space Field</strong></td>
⍝H <td align="left"><strong>Special Variable Space Field</strong></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><code>Who← ↑&#39;Mary&#39; &#39;Captain&#39; ∆F &#39;Name:\♢Rank:{:5:}{Who}&#39;    Name:     Mary    Rank:     Captain</code></td>
⍝H <td align="left"><code>Who← ↑&#39;Mary&#39; &#39;Captain&#39; ∆F &#39;Name:\♢Rank:{:⍵1:}{Who}&#39; 5  Name:     Mary    Rank:     Captain</code></td>
⍝H </tr>
⍝H </tbody></table>
⍝H <h2 id="c3-text-fields-∆f-1♢2♢3a♢b♢c15"><strong>C3. Text Fi</strong><code>elds: ∆F &#39;1\♢2\♢3{}a\♢b\♢c&#39;[^15]</code></h2>
⍝H <p> Everything else is a Text Field. Variable names, etc., in text fields are just text. There are only a few special sequences in text fields:  <code>\♢  \\♢  \{</code>  and  <em><code>\}.</code></em></p>
⍝H <ul>
⍝H <li>To insert a newline, enter a  carriage return[^16] using the sequence <code>\♢ .</code>    </li>
⍝H <li>To show literal <code>\♢ ,</code> enter <code>\\♢ .</code>  Simple <em><code>♢ </code></em> is entered as is: <code>♢ .</code>    </li>
⍝H <li>To show <code>{</code> or <em><code>}</code></em> as text, enter <em><code>\{</code></em> or <em><code>\}.</code></em>  Simple braces will demarcate a Code Field.  </li>
⍝H <li>In all other cases, simple <em><code>\</code></em> is not special: <em><code>+\</code></em> is simply <em><code>+\</code></em>.  </li>
⍝H <li>You can use <em><code>{}</code></em> (a 0-width Space Field) to separate 2 Text Fields. (See Space Fields above).</li>
⍝H </ul>
⍝H <h1 id="d-style-differences-from-python"><strong>D. Style Differences from Python</strong></h1>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th>∆F APL-style</th>
⍝H <th>Python-style</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td><em><code>⍝ Build fields all at once L to R          RGB←  123 145 255                       ∆F &#39;R:\♢G:\♢B:{ }{⍪RGB}&#39;             R: 123                                    G: 145                                    B: 255                        ⍝ Use APL for base conversions, etc.
 ∆F&# 39;&quot;{&quot;1&quot;[2⊥⍣¯1⊢⍵ 1]}&quot;&# 39;7  ⍝ ⎕IO←0           &quot;111&quot;                 ⍝ Is formatting floats old-fashioned?     x← 20.123                               ∆F&#39;{&quot;F8.5&quot;$x}&#39; ⍝ User calcs width       20.12300                                  ∆F &#39;{5⍕x}&#39;     ⍝ APL calcs width        20.12300</code></em></td>
⍝H <td><em><code># Build annotations row by row R = 123 ; G = 145 ; B = 255 print((f&#39;R: {R}\nG: {G}\nB: {B}&#39;)) R: 123 G: 145 B: 255         # Base conversions are built in f&#39;{7:b}&#39; &#39;111&#39;         # Similar approach, different conventions x = 20.123 print(f&#39;{x:0&lt;8}&#39;)   # User calcs width 20.12300 print(f&#39;{x:.5f}&#39;)   # Python calcs width 20.12300</code></em></td>
⍝H </tr>
⍝H </tbody></table>
⍝H <h1 id="e-performance"><strong>E. PERFORMANCE</strong></h1>
⍝H <h2 id="precompiling-heavily-used-f-strings--in-advance-using-mode0"><strong>Precompiling Heavily-Used <em><code>f-strings</code></em>  in Advance (Using</strong> <em><code>Mode=0</code>)</em></h2>
⍝H <p> As a prototype, <em><code>∆F</code></em> is relatively slow compared to building simple formatted objects &quot;by hand&quot; but serviceable enough. Where important, e.g. in loops, you may wish to scan (compile) the <em><code>f-string</code></em> before the loop and then run the resulting dfn. This may save perhaps 90% in execution time per iteration, with results closer to those formatted by hand. </p>
⍝H <h3 id="example"><strong>Example:</strong></h3>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th align="left">TradFn Example</th>
⍝H <th align="left">DFn Example</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td align="left"><em><strong><code>Fmt1← ⍎0 ∆F</code></strong> <code>&#39;{...}...{}...{}&#39;</code></em></td>
⍝H <td align="left"><em><strong><code>Fmt1← ⍎0 ∆F</code></strong> <code>&#39;{...}...{}...{}&#39;</code></em></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><em><code>:FOR i :IN ⍳ nIter                   ... do stuff ...  Fmt1 arg1 arg2 ...   :ENDFOR</code></em></td>
⍝H <td align="left"><em><code>_←{ 0≥⍵: _←⍺ ... do stuff ...         ⎕←Fmt1 arg1 arg2  ⍺ ∇ ⍵-1     ⍝ Iterate }⍨ nIter</code></em></td>
⍝H </tr>
⍝H </tbody></table>
⍝H <h2 id="preliminary-relative-∆f-timings17"><strong>[Preliminary] Relative ∆F Timings[^17]</strong></h2>
⍝H <p>Immediate Mode (<em><code>MODE=1</code></em>) vs. Code-Generation Mode (<em><code>MODE=0</code></em>)</p>
⍝H <table>
⍝H <thead>
⍝H <tr>
⍝H <th align="left">Component</th>
⍝H <th align="left">Action</th>
⍝H <th>ApproxTiming</th>
⍝H <th align="left">Relative Timings</th>
⍝H </tr>
⍝H </thead>
⍝H <tbody><tr>
⍝H <td align="left"><em><strong><code>∆F fmt ⍵1 ⍵2 …</code></strong></em></td>
⍝H <td align="left"><strong>Immediate</strong></td>
⍝H <td><em><strong>100%</strong></em></td>
⍝H <td align="left"><em><strong>⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕</strong></em></td>
⍝H </tr>
⍝H <tr>
⍝H <td align="left"><em><strong><code>CS←  0 ∆F fmt DFN← ⍎CS  DFN ⍵1 ⍵2 …</code></strong></em></td>
⍝H <td align="left"><strong>Generate Code
 Convert to DFn Run</strong></td>
⍝H <td><em><strong>86%   4%  10%</strong></em></td>
⍝H <td align="left"><em><strong>⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕                      ⎕                       ⎕⎕⎕</strong></em></td>
⍝H </tr>
⍝H </tbody></table>
⍝H <h1 id="-6"></h1>
⍝H <h1 id="example-code-listing-suitable-for-cut-and-paste"><strong>Example Code Listing (Suitable for Cut-and-Paste)</strong></h1>
⍝H <p><code>Examples</code><br><code>⍝ Example 1:  Text Fields and Code Fields {...} with simple variables.</code><br><code>⍝ Assume these declarations of multiline (matrix) objects:</code></p>
⍝H <p><code>names←↑&#39;John Jones&#39; &#39;Mary Smith&#39;</code><br><code>addr←↑&#39;1214 Maiden Ln&#39; &#39;24 Hersham Rd&#39;</code></p>
⍝H <p><code>⍝ Example 1a:  Text and Code Fields &quot;chained&quot; together horizontally.</code><br><code>⍝ .</code><br><code>∆F&#39;Name: { names }  Addr: { addr }&#39;</code><br><code>⍝ Name: John Jones  Addr: 1214 Maiden Ln</code><br><code>⍝       Mary Smith        24 Hersham Rd</code></p>
⍝H <p><code>⍝ Example 1b:  Self-documenting code expressions {...→} in Code Fields.</code></p>
⍝H <p><code>∆F&#39;{names→}  {addr→}&#39;</code><br><code>⍝ names→John Jones   addr→1214 Maiden Ln</code><br><code>⍝       Mary Smith        24 Hersham Rd</code></p>
⍝H <p><code>⍝ Example 1c:  Titles (using the OVER shortcut %).</code><br><code>⍝ Note that strings in Code Fields {code} use double quotes like &quot;this!&quot;.</code></p>
⍝H <p><code>∆F&#39;{&quot;Name&quot; % names}  {&quot;Address&quot; % addr}&#39;</code><br><code>⍝    Name        Address</code><br><code>⍝ John Jones  1214 Maiden Ln</code><br><code>⍝ Mary Smith  24 Hersham Rd</code></p>
⍝H <p><code>⍝ Example 1d: Adding a calculated field with line numbers (and one &quot;null&quot; title).</code><br><code>⍝    ↓ Null Title               ⊢→→       Same as (1c)        ←←⊣</code></p>
⍝H <p><em><code>∆</code></em><code>F&#39;{ ⍬ % &quot;I1,⊂.⊃&quot; $ 1+⍳≢names} {&quot;Name&quot; % names}  {&quot;Address&quot; % addr}&#39;</code><br><code>⍝      Name        Address</code><br><code>⍝ 1. John Jones  1214 Maiden Ln</code><br><code>⍝ 2. Mary Smith  24 Hersham Rd</code></p>
⍝H <p><code>⍝ Example 2:  Calculations and Formatting in Code Fields ($ is a shortcut for ⎕FMT).</code><br><code>⍝ Assume these declarations:</code></p>
⍝H <p><code>c←100 20 12 23 ¯2</code><br><code>C2F←32+1.8∘×           ⍝ Celsius to Fahr.</code></p>
⍝H <p><code>⍝ Example 2a: Format specification as an argument ⍵1, i.e. (1+⎕IO)⊃⍵.</code><br><code>⍝ (Degree sign (°): ⎕UCS 176)  Result is a 5-row 15-col char matrix.</code></p>
⍝H <p><code>∆F&#39;{ ⍵1 $ c }C = { ⍵1 $ C2F c }F&#39; &#39;I3,⊂°⊃&#39;</code><br><code>⍝ 100°C =  212°F</code><br><code>⍝  20°      68°</code><br><code>⍝  12°      54°</code><br><code>⍝  23°      73°</code><br><code>⍝  ¯2°      28°</code></p>
⍝H <p><code>⍝ Example 2b: Format specification hard-wired in Code Field.</code><br><code>⍝ Note alternative way to enter degree sign &#39;°&#39; as Unicode 176: &quot;\u{176}&quot;.</code></p>
⍝H <p><code>∆F&#39;{ &quot;I3,⊂°⊃&quot; $ c }C = { &quot;F5.1,⊂\u{176}⊃&quot; $ C2F c }F&#39;</code><br><code>⍝ 100°C = 212.0°F</code><br><code>⍝  20°     68.0°</code><br><code>⍝  12°     53.6°</code><br><code>⍝  23°     73.4°</code><br><code>⍝  ¯2°     28.4°</code></p>
⍝H <p><code>⍝ Example 2c: Variant on (2b) with a header for each Code field using the % (OVER) shortcut.</code></p>
⍝H <p><code>hdrC←&#39;Celsius&#39;</code><br><code>hdrF←&#39;Fahren.&#39;</code><br><code>∆F&#39;{ hdrC % &quot;I3,⊂°⊃&quot; $ c }  { hdrF % &quot;F5.1,⊂°⊃&quot; $ C2F c }&#39;</code><br><code>⍝ Celsius  Fahren.</code><br><code>⍝  100°    212.0°</code><br><code>⍝   20°     68.0°</code><br><code>⍝   12°     53.6°</code><br><code>⍝   23°     73.4°</code><br><code>⍝   ¯2°     28.4°</code></p>
⍝H <p><code>⍝ Example 3a: BOX display option (1=⊃⌽⍺).</code></p>
⍝H <p><code>⍝ Displays each field in its own &quot;box&quot; (ignoring null (0-width) fields)</code><br><code>1 1 ∆F&#39;one{}{}{ }two {&quot;three&quot;}{:0}{ }four&#39;</code><br><code>⍝ ┌→──┐┌→┐┌→───┐┌→────┐┌→┐┌→───┐</code><br><code>⍝ │one││ ││two ││three││ ││four│</code><br><code>⍝ └───┘└─┘└────┘└─────┘└─┘└────┘</code></p>
⍝H <p><code>⍝ Example 3b: (3a) without the BOX option (0=⊃⌽⍺).</code></p>
⍝H <p><code>∆F&#39;one{}{}{ }two {&quot;three&quot;}{:0}{ }three&#39;   ⍝ Or: 1 0 ∆F ...</code><br><code>⍝  one two three four</code></p>
⍝H <p><code>⍝ Example 4a: Use of ⍹ to reference the next scalar in right argument ⍵.</code><br><code>⍝   ⍝             ⍹1≡1⊃⍵       ⍹2≡2⊃⍵                (⎕IO←0)</code><br><code>∆F&#39;{&quot;Name&quot; % ⍹}  {&quot;Addr&quot; % ⍹}&#39; &#39;J. Smith&#39; &#39;24 Broad Ln&#39;</code><br><code>⍝   Name         Addr</code><br><code>⍝ J. Smith  24 Broad Ln</code></p>
⍝H <p><code>⍝ Example 4b: Interaction of ⍹N and simple ⍹.</code><br><code>∆F&#39;{⍹5 ⍹} {⍹3 ⍹} {⍹1 ⍹}&#39; 1 2 3 4 5 6</code><br><code>⍝ 5 6 3 4 1 2</code></p>
⍝H <p><code>∆F&#39;πr²={pi←○1 ⋄ r←2 ⋄ pi×r×2}&#39;</code><br><code>∆F&#39;π={ &quot;F10.8&quot; $ ○1 }!&#39;</code><br><code>∆F&#39;1 SP=&quot;{ }&quot;, 5 SP=&quot;{ :5: }&quot;&#39;</code><br><code>∆F&#39;This is a\⋄ three-line\⋄ field!&#39;</code></p>
⍝H <p><code>∆F&#39;&lt;{&quot;\u{97-108}...\u{57-48}&quot;}&gt;&#39;</code><br><code>⍝  &lt;abcdefghijkl...9876543210&gt;</code></p>
⍝H <p><code>Who←↑&#39;Mary&#39; &#39;Captain&#39;</code><br><code>∆F&#39;Name: \⋄Rank:{}{Who}&#39;</code><br><code>⍝  Name: Mary</code><br><code>⍝  Rank: Captain</code><br><code>Who←↑&#39;Mary&#39; &#39;Captain&#39;</code><br><code>∆F&#39;Name:\⋄Rank:{ }{Who}&#39;</code><br><code>⍝  Name: Mary</code><br><code>⍝  Rank: Captain</code></p>
⍝H <p><code>Who←↑&#39;Mary&#39; &#39;Captain&#39;</code><br><code>∆F&#39;Name:\⋄Rank:{:5:}{Who}&#39;</code><br><code>⍝  Name:     Mary</code><br><code>⍝  Rank:     Captain</code><br><code>Who←↑&#39;Mary&#39; &#39;Captain&#39;</code><br><code>∆F&#39;Name:\⋄Rank:{:⍵1:}{Who}&#39; 5</code><br><code>⍝  Name:     Mary</code><br><code>⍝  Rank:     Captain</code></p>
⍝H <p><code>⍝ APL vs Python!</code><br><code>⍝ APL                                 # Python</code><br><code>⍝ Build fields all at once L to R        # Build annotations row by row</code><br><code>RGB←123 145 255                          ⍝  R = 123 ; G = 145 ; B = 255</code><br><code>∆F &#39;R:\⋄ G:\⋄ B:{ }{⍪RGB}&#39;                ⍝  print((f&#39;R: {R}\nG: {G}\nB: {B}&#39;))</code><br><code>⍝ R: 123                                 ⍝    R: 123</code><br><code>⍝ G: 145                                 ⍝    G: 145</code><br><code>⍝ B: 255                                 ⍝    B: 255</code></p>
⍝H <p><code>⍝ Use APL for base conversions, etc.  # Base conversions are built in</code><br><code>∆F&#39;&quot;{&quot;01&quot;[2⊥⍣¯1⊢⍵1]}&quot;&#39; 7                 ⍝  f&#39;{7:b}&#39;</code><br><code>⍝ &quot;111&quot;                                  ⍝  &#39;111&#39;</code></p>
⍝H <p><code>⍝ Formatting Floats old-fashioned?    # Similar approach, different conventions</code><br><code>x←20.123                              ⍝  x = 20.123</code><br><code>∆F&#39;{&quot;F8.5&quot;$x}&#39; ⍝ User calcs width     ⍝  print(f&#39;{x:0&lt;8}&#39;)   # User calcs width</code><br><code>⍝ 20.12300                            ⍝    20.12300</code><br><code>∆F&#39;{5⍕x}&#39;     ⍝ APL calcs width       ⍝  print(f&#39;{x:.5f}&#39;)   # Python calcs width</code><br><code>⍝ 20.12300                            ⍝   20.12300</code>  </p>
⍝H <p>[^1]:  <em>Next scalar</em> is defined below.</p>
⍝H <p>[^2]:  Under identical circumstances, of course, i.e. in the same calling environment with the same system variables.</p>
⍝H <p>[^3]:  Comparing the value returned from  Immediate Mode <em><code>(Mode=1)</code></em> vs Pseudo-code Mode <em><code>(Mode=¯1)</code><strong>:</strong></em></p>
⍝H <p>[^4]:  The  <em><strong>MY</strong><code>NS</code></em> (Shared CodeField Namespace) option is experimental. No examples are currently given.</p>
⍝H <p>[^5]:  The  <em><strong>EXEC</strong><code>NS</code></em> (Execution  Namespace for CodeFields) option is experimental. No examples are currently given.</p>
⍝H <p>[^6]:  Typical use: if <strong>true, evaluate</strong> and <strong>return</strong> the F-string; otherwise**, skip processing** <strong>and (shyly) return</strong> immediately.<br>         <em><strong>(<code>1/</code></strong><code>⍨IF_TRUE) ∆F myFstring myData   ⍝ E.g. in tradfn</code></em></p>
⍝H <p>[^7]:  Compare <em>self-documenting</em> f-strings in Python..</p>
⍝H <p>[^8]:  Within each Code Field (see below), each <em>statement</em> is evaluated <em>right to</em> <em>left</em> as always.</p>
⍝H <p>[^9]:  If all fields are null, the result will have shape <em><code>1 0.</code></em></p>
⍝H <p>[^10]:  See also experimental option <em><code>NS</code></em> (above), which provides a temporary namespace <em><code>⍺</code></em> shared across all Code Fields.</p>
⍝H <p>[^11]:  Code Field comments will appear in self-documenting fields as expected.</p>
⍝H <p>[^12]:  <strong>Box</strong> uses <em><code>display</code></em> from ws <em><code>dfns</code></em>.</p>
⍝H <p>[^13]:  A Space Field may contain a single trailing comment. For format, see the <em>Basics of Code Fields</em> above.</p>
⍝H <p>[^14]:  But why?</p>
⍝H <p>[^15]:  Output: <code>1a</code></p>
⍝H <p>[^16]:  For newlines, <em>Dyalog APL</em> generally uses carriage returns <em>(decimal 13)</em> instead of line feeds <em>(10)</em>. Just go with it. </p>
⍝H <p>[^17]:  The benchmark code has six small fields, exhibiting a range of field types. ∆F strings are typically small in size and number.</p>
⍝H
⍝H ⍝H
