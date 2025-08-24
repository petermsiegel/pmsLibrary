<!-- Preview in sep files: cmd-shift-V,
Preview side-by-side: cmd-K, V,
md->HTML: opt-shift-M
-->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.5.0/github-markdown.min.css">

<!--
<style>
  body {
    font-size: 18px; /* 16: on screen in APL. Base font size for all text */
  }
  p {
    font-family: Times;
    line-height: 1.2;
  }
  li {
    font-family: Times;
  }
  code { /* Inline code */
    font-size: 95%;
    background-color: #ddfafaff;
    padding: 2px 4px;
    border-radius: 3px;
    font-family: "APL386 Unicode", APL385, "APL385 Unicode", "Courier New", Courier,
      "Lucida Console", "Consolas", monospace;
  }


pre { /_ Code blocks _/
background-color: #ddfafaff; /_ Background for code blocks _/
color: #0a0a0aff;
font-size: 95%;
line-height: 100%;
 padding: 15px;
border-radius: 5px;
overflow-x: auto; /_ Enable horizontal scrolling for long lines _/
font-family: "APL386 Unicode", APL385, "APL385 Unicode", "Courier New", Courier,
"Lucida Console", "Consolas", monospace;
}
table {
font-size: 85%;
 line-height: 100%;
background-color: #eae9ebaa;
font-family: "APL386 Unicode", APL385, "APL385 Unicode", "Courier New", Courier,
"Lucida Console", "Consolas", monospace;
}
th { /_ Table header _/
font-size: 100%; /_ Adjust this value as needed _/
line-height: 90%;
font-family: Times;
}
blockquote {
font-size: 110%;
background-color: #f4f5f5ff; /_ Background for code blocks _/
}
</style>

  -->

## ∆F — Formatted String Literals

### ∆F In Brief¹

> **∆F is a function for Dyalog APL that interprets f-strings,² a concise, yet powerful way to display multiline Unicode text and complex expressions in an APL-friendly style**.

**∆F f-strings** can concisely include:

- **Text fields**, expressions that can generate multiline Unicode text (using `` `⋄ `` to indicate a newline);

- **Code fields**, that allow users to display APL objects in the user environment or passed as **∆F** arguments, as well as arbitrary APL expressions and full multi-statement³ dfn logic; each **Code field** must return a value, simple or otherwise, which will be aligned and catenated with other fields and returned from **∆F**;

- **Code fields** also provide a number of concise, convenient extensions, such as:

  - **Quoted strings** in **Code fields**, with several quote styles:

    - **double-quotes** `{"like this"}` or this `` {"on`⋄three`⋄lines"}``,
    - **single-quotes**, _distractingly_ `{''shown ''''right'''' here''}'`, or even
    - **double angle quotation marks**,⁵ i.e. _guillemets_,

      `{«with internal "quotes" and ''more''.»}`;

  - Simple shortcuts⁶ for

    - formatting numeric arrays, **\$** (short for **⎕FMT**): `{"F7.5" $ ?0 0}`,
    - putting a box around a specific expression, **\`B**: `` {`B ⍳2 2} ``,
    - placing the output of one expression _above_ another, **%**: `{"Pi"% ○1}`,
    - formatting date and time expressions from APL timestamps (**⎕TS**) using **\`T** ( short for an expression with **1200⌶** and **⎕DT**):`` {"hh:mm:ss" `T ⎕TS} ``:,

    and more; as well as concisely inserting data from

    - user objects or arbitrary code: `{tempC}` or `{32+tempC×9÷5}`,
      and/or
    - arguments to **∆F** that follow the format string: `` {32+`⍵1×9÷5} ``, where `` `⍵1 `` is a shortcut for `(⍵⊃⍨1+⎕IO)`;

- **Space fields**, providing a simple mechanism both for separating adjacent **Text fields** and inserting (rectangular) blocks of any number of spaces between any two fields, where needed;

- Multiline (matrix) output built up field-by-field, left-to-right, from values and expressions in the calling environment or arguments to **∆F**;

  - after each field is generated, it is conformed to and concatenated with every other field to form one character matrix, as in this simple example:

  ```
    tempC← ⍪35 85
    ⍴⎕← ∆F 'The temperature is {tempC}{2 2⍴"∘C"} or {32+tempC×9÷5}{2 2⍴"∘F"}'
  The temperature is 35∘C or  95∘F.
                     85∘C    185∘F
  2 32
  ```

**∆F** is designed for ease of use, _ad hoc_ debugging, and informal user interaction; APL's native tools and Dyalog's enhancements are always the best⁴ way to build and display complex objects, unless **∆F**'s specific functionality is of use.

---

<p style="margin: 10px 20px;line-height: 1.3;font-size: 85%;font-family: APL386, APL385;color: black;"> ¹ Throughout this documentation, notably in the many examples, an index origin of zero (<b>⎕IO←0</b>) is assumed. Users may utilize <i>any</i> index origin in the <b>f-string Code fields</b>  they define, as long as it's <b>1</b> or <b>0</b>. <b>Code fields</b>  inherit the index origin of the environment (i.e. namespace) from which <b>∆F</b> is called. <br> ² <b>∆F</b> is inspired by Python <a href="https://docs.python.org/3/tutorial/inputoutput.html"><b>f-strings</b></a> (short for "<b>formatted string literals</b>"), but designed for APL's multi-dimensional worldview. <br> ³ <b>∆F Code fields</b> <i>as input</i> are limited to a single, possibly very long, line.<br> ⁴ As a prototype, <b>∆F</b> is currently relatively slow, in that it analyzes the <b>f-string</b> using an APL recursive scan. <br> ⁵ Double angle quotation marks <b>«»</b> (guillemets) are Unicode chars <b><small>⎕UCS 171 187</small></b>. When including literal guillemets in guillemet-bracketed quotations (<i>but why?</i>), opening guillemets <b>«</b> are <i>not</i> doubled, but <i>two</i> closing guillemets are needed for each literal <b>»</b> required.<br>
⁶ Details on all the shortcuts are provided later in this document. See <i><b>Code Field Shortcuts.</b></i></p>

---

## ∆F EXAMPLES

Before providing information on ∆F syntax and other details, _let's start with some examples_...

```
⍝  Set some values we'll need for our examples...
   ⎕RL ⎕IO ⎕ML←2342342 0 1         ⍝ ⎕RL: Ensure our random #s aren't random!
```

```
⍝  Code fields with plain variables
   name← 'Fred' ⋄ age← 43
   ∆F 'The patient''s name is {name}. {name} is {age} years old.'
The patient's name is Fred. Fred is 43 years old.
```

```
⍝  Arbitrary code expressions
   names← 'Mary' 'Jack' 'Tony' ⋄ prize← 1000
   ∆F 'Customer {names⊃⍨ ?≢names} wins £{?prize}!'
Customer Jack wins £80!
   ∆F 'Customer {names⊃⍨ ?≢names} wins £{?prize}!'
Customer Jack wins £230!
```

> Isn't Jack lucky, winning twice in a row!

```
⍝  Some multi-line Text fields separated by non-null Space fields
⍝  ∘ The backtick is our "escape" character.
⍝  ∘ Here each  `⋄ displays a newline character in the left-most "field."
⍝  ∘ { } is a Space Field indicating one space, given one space
⍝    within the braces.
⍝  A Space field is useful here because each multi-line field is built
⍝  in its own rectangular space.
   ∆F 'This`⋄is`⋄an`⋄example{ }Of`⋄multi-line{ }Text`⋄Fields'
This    Of         Text
is      multi-line Fields
an
example
```

```
⍝  Two adjacent Text fields can be separated by a Null Space field {},
⍝  for example when at least one field contains multiline input that you
⍝  want formatted separately (keeping each field in is own rectangular space):
   ∆F 'Cat`⋄Elephant `⋄Mouse{}Felix`⋄Dumbo`⋄Mickey'
Cat      Felix
Elephant Dumbo
Mouse    Mickey
⍝  In the above example, we added an extra space after the longest
⍝  animal name...
```

### But wait! There's an easier way!

```
⍝  Here, you surely want the lefthand field to be guaranteed to have a space
⍝  after EACH word without fiddling, so a Space field with at least
⍝  one space would be way more convenient:
   ∆F 'Cat`⋄Elephant`⋄Mouse{ }Felix`⋄Dumbo`⋄Mickey'
Cat      Felix
Elephant Dumbo
Mouse    Mickey
```

```
⍝  A similar example with double-quote-delimited strings in Code fields with
⍝  the newline sequence (`⋄):
   ∆F '{"This`⋄is`⋄an`⋄example"} {"Of`⋄Multi-line"} {"Strings`⋄in`⋄Code`⋄Fields"}'
This    Of          Strings
is      Multi-line  in
an                  Code
example             Fields
```

```
⍝  Here is some multiline data we'll add to our Code fields
   fn←   'John'           'Mary'         'Ted'
   ln←   'Smith'          'Jones'        'Templeton'
   addr← '24 Mulberry Ln' '22 Smith St'  '12 High St'
   ∆F '{↑fn} {↑ln} {↑addr}'
John Smith     24 Mulberry Ln
Mary Jones     22 Smith St
Ted  Templeton 12 High St
```

```
⍝  A slightly more interesting code expression, using the shortcut $ (⎕FMT)
⍝   to round the calculated Fahrenheit numbers to the nearest tenth:
   C← 11 30 60
   ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ 32+9×C÷5}°F'
The temperature is 11°C or  51.8°F
30       86.0
60      140.0
```

```
⍝  Here we place boxes around key Code fields using the shortcut `B (box).
   ∆F'`⋄The temperature is {`B "I2" $ C}`⋄°C or {`B "F5.1" $ 32+9×C÷5}`⋄°F'
                   ┌──┐      ┌─────┐
The temperature is │11│°C or │ 51.8│°F
                   │30│      │ 86.0│
                   │60│      │140.0│
                   └──┘      └─────┘
```

#### What if you want to place a box around every **Code**, **Text**, **_and_** **Space field**?

Just use **Box mode**: `0 0 1 ∆F...`

```
⍝  While we can't place boxes around text (or space) fields using `B,
⍝  we can place a box around EACH of our fields by setting the
⍝  third ∆F option (⍺[2]):
   0 0 1 ∆F'`⋄The temperature is {"I2" $ C}`⋄°C or {"F5.1" $ 32+9×C÷5}`⋄°F'
┌───────────────────┬──┬──────┬─────┬──┐
│                   │11│      │ 51.8│  │
│The temperature is │30│°C or │ 86.0│°F│
│                   │60│      │140.0│  │
└───────────────────┴──┴──────┴─────┴──┘
```

We said you could place a box around every field.
**Null Space fields** `{}`, i.e. 0-width **Space fields**, are an exception: after doing their work of separating adjacent **Text fields**, **Null Space fields** are ignored and won't be placed in boxes.
Try this expression on your own:

    `0 0 1 ∆F 'abc{}def{}{}ghi{""}jkl{ }mno'`

In contrast, **Code fields** that return null values (like `{""}` above) _will_ be displayed!

```
⍝  Referencing an external variable (C) and function (C2F)
   C← 11 30 60
   C2F← 32+9×÷∘5
   ∆F'The temperature is {"I2" $ C}°C or {"F5.1" $ C2F C}°F'
The temperature is 11°C or 51.8°F
                   30      86.0
                   60     140.0
```

```
⍝  We can reference ∆F additional arguments (those after the f-string),
⍝  using omega shortcut expressions of the form `⍵1, `⍵99, `⍵, etc.
⍝  Here `⍵1 is the same as (⍵⊃⍨ 1+⎕IO), selecting the first argument
⍝  after the f-string. Similarly, `⍵99 would select (⍵⊃⍨ 99+⎕IO).
⍝  We discuss bare `⍵ (i.e. w/o an adjacent non-negative integer) below.
   ∆F'The temperature is {"I2" $ `⍵1}°C or {"F5.1" $ C2F `⍵1}°F' (11 15 20)
The temperature is 11°C or 51.8°F
                   15      59.0
                   20      68.0
```

```
⍝  The temperature of the sun at its core in degrees C.
   sun_core← 15E6
⍝  Use Dyalog's built-in formatting specifier "C" with shortcut $ (⎕FMT)
⍝  to add appropriate commas to the temperatures!
   ∆F'The sun''s core is at {"CI10"$sun_ core}°C or {"CI10"$C2F sun_ core}°F'
The sun's core is at 15,000,000°C or 27,000,032°F
```

#### An easier way to add commas to large numbers or numeric strings: the `` `C `` shortcut

```
⍝  Use the `C shortcut to add the commas to the temperatures!
⍝  This has the advantage of not requiring you to guesstimate field widths.
⍝  Typically, each number (or numeric string) presented to `C is an integer.
   ∆F'The sun''s core is at {`C sun_ core}°C or {`C C2F sun_ core}°F'
The sun's core is at 15,000,000°C or 27,000,032°F
```

```
⍝  Let's use argument `⍵1 in a calculation.      ⍝ NB: 'π²' is (⎕UCS 960 178)
   ∆F 'π²={`⍵1*2}, π={`⍵1}' (○1)
π²=9.869604401, π=3.141592654
```

#### Self-documenting **Code fields** (SDCFs) are a useful debugging tool.

What's an SDCF? An SDCF allows whatever source code is in a **Code Field** to be automatically displayed literally along with the result of evaluating that code. It can be shown:

- to the left of the result of evaluating that code; or,

- centered above the result of evaluating that code.

All you have to do is place

- a **→** (horizontal SDCF), or

- a **↓** (vertical SDCF)

as the last non-space in the **Code field**, before the _final_ right brace.

```
⍝  Horizontal SDCF example
   name←'John Smith' ⋄ age← 34
   ∆F 'Current employee: {name→}, {age→}.'
Current employee: name→John Smith, age→34.
```

> Note that spaces just before or after the symbol **→** or **↓** are preserved **_verbatim_** in the output.

```
⍝  Note how the spaces adjacent to the symbol "→" are mirrored in the output:
   name←'John Smith' ⋄ age← 34
   ∆F 'Current employee: {name → }, {age→   }.'
Current employee: name → John Smith, age→   34.
```

```
⍝  Vertical SDCF example
   name←'John Smith' ⋄ age← 34
   ∆F 'Current employee: {name↓} {age↓}.'
Current employee:   name↓    age↓.
                  John Smith  34
```

```
⍝  Here's the same result, but with a box around each field, to make it
⍝  easy to see.
⍝     ⍵[2]=1: Box all args (⎕IO=0).
   0 0 1 ∆F 'Current employee: {name↓} {age↓}.'
┌──────────────────┬──────────┬─┬────┬─┐
│Current employee: │  name↓   │ │age↓│.│
│                  │John Smith│ │ 34 │ │
└──────────────────┴──────────┴─┴────┴─┘
```

#### A cut above the rest. Using % (_above_).

```
⍝  Let's use the shortcut % to display one expression centered above another;
⍝  It's called "above" and can also be expressed as  `A.
⍝  Remember, `⍵1 refers to the first argument after the f-string itself;
⍝  And `⍵2 refers to the second.
   ∆F '{"Employee" % ⍪`⍵1} {"Age" % ⍪`⍵2}' ('John Smith' 'Mary Jones')(29 23)
 Employee   Age
John Smith  29
Mary Jones  23
```

Note that `` `⍵0 `` refers to the f-string itself. Try this yourself:

> <small>`` ∆F 'Our string{`⍵0↓}is {≢`⍵0} characters' ``</small>

#### The _next_ best thing: the use of _bare_ `` `⍵ `` in **Code field** expressions

The expression `` `⍵ `` selects the _next_ element of the right argument `⍵`, defaulting to `` `⍵1 `` when first encountered, i.e. if there are **_no_** `` `⍵ `` elements to the **_left_** in the f-string. If there is any such expression (e.g. `` `⍵5 ``), then `` `⍵ `` points to the element after that one (here, `` `⍵6 ``). If the item to the left is `` `⍵ ``, then we simply increment by `1` from that one. **Let's try an example.**

```
⍝  Let's display arbitrary 2-dimensional expressions, one above the other.
⍝  `⍵ refers to the next argument in sequence, left to right, starting with `⍵1, the first.
⍝  ☞ From left to right `⍵ is `⍵1, `⍵2, and `⍵3. Easy peasy.
   ∆F'{(⍳2⍴`⍵) % (⍳2⍴`⍵) % (⍳2⍴`⍵)}' 1 2 3
    0 0
  0 0 0 1
  1 0 1 1
0 0 0 1 0 2
1 0 1 1 1 2
2 0 2 1 2 2
```

#### Dates and Times using ⎕TS-format timestamps: the `T shortcut...

```
⍝  A simple Date-Time shortcut `T built from 1200⌶ and ⎕DT.
⍝  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝  ∘ Let's look at the use of the `T (Date-Time) shortcut to show the
⍝    current time (now).
⍝  ∘ The right argument is always a ⎕TS or any non-empty prefix thereof.
   ∆F'It is now {"t:mm pp" `T ⎕TS}.'
It is now 8:08 am.         ⍝ NB: this will be the current actual time, of course.
```

```
⍝  Here's a more powerful example (the power is in 1200⌶ and ⎕DT).
⍝  (Right arg "hardwired" into F-string)
   ∆F'{ "D MMM YYYY ''was a'' Dddd."`T 2025 01 01}'
1 JAN 2025 was a Wednesday.
```

```
⍝  If it bothers you to use `T for a date-only expression,
⍝  you can use `D, which means exactly the same thing.
   ∆F'{ "D MMM YYYY ''was a'' Dddd." `D 2025 01 02}'
2 JAN 2025 was a Thursday.
```

```
⍝  Here, we'll pass the time stamp via a single omega
⍝  expression: `⍵1.
   ∆F'{ "D Mmm YYYY ''was a'' Dddd." `T `⍵1}' (2025 1 21)
21 Jan 2025 was a Tuesday.
```

```
⍝  ∘ And here, we pass the time stamp via a sequence of omega
⍝    expressions: `⍵ `⍵ `⍵.
⍝  ∘ Here, this is equivalent to the slightly verbose
⍝    expression: `⍵1 `⍵2 `⍵3
   ∆F'{ "D Mmm YYYY ''was a'' Dddd." `T `⍵ `⍵ `⍵}' 2025 1 21
21 Jan 2025 was a Tuesday.
```

#### Precomputed F-strings: Performance of ∆F (or 0 ∆F) vs 1 ∆F ...

```
⍝  Finally, let's explore getting the best performance for a heavily
⍝  used ∆F string. Using the DFN option (⍺[0]=1), we can generate a
⍝  dfn that will display the formatted output, without having to reanalyze
⍝  the f-string each time.
⍝  We will compare the performance of an ∆F-string evaluated on the fly
⍝     ∆F ...    ⍝ The same as 0 ∆F ...
⍝  and precomputed and returned as a dfn:
⍝     1 ∆F ...
```

```
⍝  First, let's get cmpx, so we can compare the performance...
  'cmpx' ⎕CY 'dfns'
⍝  Now, let's proceed...
   C← 11 30 60
⍝ Here's our ∆F String t
   t←'The temperature is {"I2" $ C}°C or {"F5.1" $ F← 32+9×C÷5}°F'
⍝  Let's precompute a dfn T, given ∆F String t.
⍝  It has everything needed to generate the output,
⍝  except the external variables or additional arguments needed.
  T←1 ∆F t

⍝  Compare the performance of the two formats...
⍝  The precomputed version is about 17 times faster, in this run.
   cmpx '∆F t' 'T ⍬'
∆F t → 1.7E¯4 |   0% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
T ⍬  → 1.0E¯5 | -94% ⎕⎕
```

#### Before we get to syntax and other information...

```
⍝  We'll leave you with this variant, where we pass the centigrade value,
⍝  not as a variable, but as a subsequent argument to ∆F.
   t←'The temperature is {"I2" $ `⍵1}°C or {"F5.1" $ F← 32+9×`⍵1÷5}°F'
   T← 1 ∆F t
   ∆F t 35
The temperature is 35°C or 95.0°F
   T 35
The temperature is 35°C or 95.0°F
   cmpx '∆F t 35' 'T 35'
∆F t 35 → 1.7E¯4 |   0% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
T 35    → 8.9E¯6 | -95% ⎕⎕
```

### ∆F Syntax and Other Information

#### Call Syntax Overview

| Call Syntax <div style="width:250px"></div> | Description                                                                                                                                              |
| :------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **∆F** _f-string_                           | Display an _f-string_; use the default options. The string may reference objects in the environment or in the string itself. Returns a character matrix. |
| **∆F** _f-string_ _arg1_ [*arg2* ...]       | Display an _f-string_; use the default options. Args presented may be referred to in the f-string. Returns a character matrix.                           |
| _options_ **∆F** _f-string_ [*args*]        | Display an _f-string_; control result with _options_ (see below).                                                                                        |
|                                             | If the initial option (DFN) is **0** or omitted, returns a character matrix.                                                                             |
|                                             | If the initial option (DFN) is **1**, returns a dfn generating such a matrix.                                                                            |
| 'help' **∆F** ''                            | Display help info and examples for **∆F**. The _f-string_ is not examined.                                                                               |
| **∆F**⍨'help'                               | A shortcut for displaying help info and examples (above).                                                                                                |

#### Call Syntax Details

| Element <div style="width:250px"></div> | Description                                                                                                                                                                                                                                                                                 |
| :-------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| f-string                                | a format string, a single character vector.                                                                                                                                                                                                                                                 |
| args                                    | elements of ⍵ after the f-string, each of which can be accessed in the f-string via a **\`⍵** shortcut (or ordinary **⍵** expression)                                                                                                                                                       |
| options                                 | [ options← [ 0 [ 0 [ 0 [ 0 ] ] ] ] \| 'help' ]                                                                                                                                                                                                                                              |
| &nbsp;&nbsp;options[0] (**_DFN_**)      | If `1`, **∆F** returns a dfn, which (upon execution) produces the same output as the default mode. Default: **∆F** returns a char. matrix.                                                                                                                                                  |
| &nbsp;&nbsp;options[1] (**_DBG_**)      | If `1`, prints out (via `⎕←`) the dfn-version of the f-string.                                                                                                                                                                                                                              |
| &nbsp;&nbsp;options[2] (**_BOX_**)      | If `1`, each field (except a Null Text field) is boxed separately. If `0`, you may box any **Code fields** you want using the _box_ `` `B `` routine. **BOX** mode can be used both with **DFN** and default output mode.                                                                   |
| &nbsp;&nbsp;options[3] (**_INLINE_**)   | If `1`, a copy of each needed internal support function is included in the result. If `0`, calls are made to the library created when ∆F was loaded. Setting **_INLINE_** to `1` is only useful if the **DFN** option is set. This option is experimental and may simply disappear one day. |
| &nbsp;&nbsp;'help'                      | If `'help'` is specified, this amazing documentation is displayed.                                                                                                                                                                                                                          |
| result                                  | If `0=⊃options`, the result is always a character matrix. If `1=⊃options`, the result is a dfn that, _when executed_, generates that same character matrix.                                                                                                                                 |

### Options (⍺)

- If the left argument `⍺` is omitted, the options are `4⍴0`.

- If the left argument `⍺` is a simple boolean vector or scalar, or an empty numeric vector `⍬`, the options are `4↑⍺`; subsequent elements are ignored;

- If the left argument `⍺` starts with `'help'` (case ignored), this help information is displayed.

- Otherwise, an error is signaled.

### Return Value

- Unless the **DFN** option is selected, **∆F** always returns a character matrix of at least one row `1 0⍴0` on success. If the 'help' option is specified, **∆F** returns `1 0⍴0`.

- If the **DFN** option is selected, **∆F** always returns a standard Dyalog dfn on success.

- On failure of any sort, an informative APL error is signaled.

### ∆F f-string building blocks

The first element in the right arg to ∆F is a character vector, an **f-string**,
which contains 3 types of fields: **Text fields**, **Code fields**, and **Space fields**.

- **Text Fields** consist of simple text, which may include any Unicode characters desired, including newlines. Newlines (actually, carriage returns, `⎕UCS 13`) are normally entered via the sequence `` `⋄ ``. Additionally, literal curly braces can be added via `` `{ `` and `` `} ``, so there is no confusion with the simple curly braces used to begin and end **Code fields** and **Space Fields**. Finally, a simple backtick escape can be entered into a **Text field** by simply entering two such characters ` `` `.

- **Code fields** are run-time evaluated expressions enclosed within
  simple, unescaped curly braces `{}`, i.e. those not preceded by a back-tick (see the previous paragraph). **Code fields** are essentially a Dyalog dfn with some extras.

- **Space Fields** are essentially a _degenerate_ form of **Code fields**, consisting of a single pair of simple curly braces `{}` with zero or more spaces in between. A **Space Field** with zero spaces is a **Null Space Field**; while it may separate any other fields, its practical use is separating two adjacent **Text Fields**.

The building blocks of an **f-string** are these defined "fields," catenated left to right,
each of which will display as a logically separate 2-D output space. While **Code fields** can return objects of any number of dimensions mapped onto 2-D by APL rules, **Text fields** and **Space fields** are always simple rectangles (minimally 1 row and zero columns). Between fields, **∆F** adds no automatic spaces. That spacing is under user control.

##### Escape Sequences for Text Fields and Quoted Strings

∆F-string **Text fields** and **Quoted strings** in **Code fields** may include
a small number of escape sequences, beginning with the backtick `` ` ``.

| Escape sequence&nbsp;&nbsp; | Literal Output&nbsp;&nbsp; | Meaning     |
| :-------------------------: | :------------------------- | :---------- |
|             \`⋄             | (newline)                  | (⎕UCS 13)   |
|            \`\`             | `                          | backtick    |
|             `{              | {                          | left brace  |
|             \`}             | }                          | right brace |

Other instances of the backtick character in **Text fields** or **Quoted strings** in **Code fields** will be treated literally, _i.e._
as an ordinary backtick `` ` ``.

##### Code Field Shortcuts

∆F-string **Code fields** may contain various shortcuts, intended to be concise and expressive tools for common tasks. **Shortcuts** are valid **only** outside **Quoted strings**. They include:

| Shortcut <div style="width:100px"></div> | Name <div style="width:150px"></div> | Meaning                                                                                                                                      |
| :--------------------------------------- | :----------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------- |
| $, \`F                                   | ⎕FMT                                 | `[⍺] ⎕FMT ⍵`                                                                                                                                 |
| %, \`A                                   | above                                | Places object `⍺` above object `⍵`. Default `⍺←''`.                                                                                          |
| \`B                                      | box                                  | Places `⍵` in a box. `⍵` is any object.                                                                                                      |
| \`C                                      | commas                               | Adds commas to `⍵` after every 3rd digit. `⍵` is a vector of num strings or numbers.                                                         |
| \`T, \`D                                 | Date-Time¹                           | Displays `⍵` according to `⍺`. `⍵` is one or more APL timestamps `⎕TS`. `⍺` is a date-time template. If omitted, `⍺← 'YYYY-MM-DD hh:mm:ss'`. |
| \`⍵𝒋, ⍹𝒋                                 | Omega explicitly indexed             | a shortcut of the form `` `⍵𝒋 `` (or `⍹𝒋`), to access the `𝒋`**th** element of `⍵`, i.e. `⍵⊃⍨ 𝒋+⎕IO`. _See details below._                   |
| \`⍵, ⍹                                   | Omega implicitly indexed             | a shortcut of the form `` `⍵ `` (or `⍹`), to access the **next** element of `⍵`. _See details below._                                        |

---

<p style="margin: 10px 20px;line-height: 1.3;font-size: 85%;font-family: APL386, APL385;color: black;"> ¹ The syntax for the Date-Time specifications (left arg) can be found in the Dyalog documentation under <b>1200⌶</b>. For the curious, here's the code actually called for the Date-Time shortcut: <br>&nbsp;&nbsp;&nbsp;&nbsp;<small><b>{⍺←'YYYY-MM-DD hh:mm:ss' ⋄ ∊⍣(1=≡⍵)⊢ ⍺(1200⌶)⊢ 1⎕DT ⊆⍵}</b></small>.  </p>

---

##### Omega Shortcut Expressions

|     | Expression                                                                                                                                                                                                                                    |     |
| :-- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- |
| 1.  | **⍹** is a synonym for **\`⍵**. It is Unicode character `⎕UCS 9081`. Either expression is valid only in **Code** fields and outside **Quoted strings**.                                                                                       |
| 2.  | **\`⍵** or **⍹** uses an "_omega index counter_" (**OIC**) which we'll represent as **Ω**, common across all **Code** fields, which is initially set to zero, `Ω←0`. (Ω is just used for explication; don't actually use this symbol)         |
| 3.  | All omega shortcut expressions in the **f-string** are evaluated left to right and are ⎕IO-independent.                                                                                                                                       |
| 4.  | **\`⍵𝒋** or **⍹𝒋** sets the _OIC_ to 𝒋, `Ω←𝒋`, and returns the expression `⍵⊃⍨Ω+⎕IO`. Here **𝒋** must be a _non-negative integer_ with at least 1 digit.                                                                                      |
| 5.  | Bare **\`⍵** (i.e. with no digits appended) increments the _OIC_, `Ω+←1`, _before_ using it as the index in the expression `⍵⊃⍨Ω+⎕IO`.                                                                                                        |
| 6.  | You can only access the 0-th element of **⍵** via an _explicitly indexed omega_ `⍵0`. The _implicitly indexed_ omega always increments its index _before_ use, so the first index that can be used **_implicitly_** is **1**, i.e. `` `⍵1 ``. |
| 7.  | If an element of the dfn's right argument **⍵** is accessed via any means, shortcut or traditional, that element must exist when accessed at runtime.                                                                                         |
