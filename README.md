__pmsLibrary__: A library of useful APL functions and operators, specified as prototypes, best implemented within the language. 

* For source files, see _pmsLibrary/src_, all _.dyalog_ files.
* For help information, see _pmsLibrary/docs_, mostly _.help_ text files, but see _formatHelp.pdf_.

This is a work in progress, as I move a handful of such functions out of workspaces into github.

___Table of Contents___ 
* __require__     Ensure APL objects are in the active workspace, loading from other workspaces or directories.
* __∆MY__         Support static objects specific to a function/op, created once and maintained over calls.
* __dict__        Create ordered dictionaries with an array of creation, sorting, and searching services.
* __tinyDict__    Create low-overheaded ordered dictinaries with simple access to keys and values.
* __gen__         Create Python-like generators that allow for functions to iteratively "yield" values without returning.
* __future__      Create simple future objects, whose values may be scalars within APL arrays, built on isolate-related I-beams.
* __∆format, ∆f__ Support Python-like f-strings extended for APL multi-dimentional objects, allowing for variable interpolation into quoted strings.
* __bigInt__  Provides support for arbitrary-precision integers in convenient and higher-performance formats, along with an arbitrary-precision desk calculator in the tradition of Unix's __dc__.
* __∆here__       Robust support for "Here" documents within APL functions/ops, allowing multi-line HTML, documentation, or special strings to be pasted from other sources (or otherwise created) and passed to various web-based or other services.

___Descriptions of Packages___
1. __require__: Reminiscent of __import__ in Python and __require__ or __use__ in Perl, __require__ ensures that the "packages" in the right argument are either in the caller's namespace or the ⎕PATH (e.g. were "required" by another function/op or otherwise), in the filesystem search path (Unix environment (extension) __FSPATH__ or (Dyalog) __WSPATH__ or using "extension" ⎕SE.∆FSPATH), or in the workspace indicated (e.g. 'dfns:cmpx'). If in the caller's namespace or ⎕PATH, nothing more is done. Also allows easy importing of an entire workspace ('dfns:') or all the __\*.dyalog__ files filesystem directory ('myfns.mymath').
   * ``⍝ read cmpx from ws dfns, kt from same ws, tinyDict from subdir src, future from same subdir``<br>
     ``⍝ If already in caller's ns or ⎕PATH, return quietly.``<br>
     ``⍝ Store newly loaded objects (called packages) into a "standard library" (easily set by the user).``<br>
     ``require 'dfns:cmpx'  ':kt' 'src::tinyDict' '::future' ``                                                
   * See __require.dyalog__ and __require.help__.
1. __∆MY__: From the namespace __∆MYgrp__, __∆MY__ refers to a private namespace for the current calling function (determined from its actual APL name and the namespace in which it resides). It allows for *static* variables, i.e. ones that persist between executions, e.g. ``∆MY.count+←1`` 
and for *initialization*, e.g. 
``:IF ∆MY.∆FIRST ⋄ ∆MY.count←0 ⋄ :ENDIF``
   * See __∆MYgrp.dyalog__ and __∆MYgrp.help__.
1. __∆DICT__ in namespace __dict__: Create a robust dictionary using __⎕NEW__ or __∆DICT__, with options for string, numeric or arbitrary defaults (vis-a-vis missing keys), sorting, and more.
1. __tinyDict__: Similar to __∆DICT__, but designed for higher-performance, simpler environments. Uses a namespace, rather than a class; meant for memoization and similar simple, workhorse, situations.
1. __gen__: A namespace library for executing __generators__ of the sort used in Python. Including __yield__ and other tools.
1. __future__: Uses some of the undocumented _magic_ from __isolates__ to create simple, in-workspace, futures, i.e. array elements that will block until their (asynchronous) values are in place. User beware-- none of the features are documented and may work differently than expected. (Based solely on the OS X implementation).
1. __∆format__ / __∆f__ in namespace __format__: An APL-specific implementation of format-strings, reminiscent of Python's __f-strings__, but supporting APL multidimensional objects directly and formatting based on __⎕FMT__. Supports nice constructions like<br> 
      ``first←'John'  ⋄ middle←'Jacob' 'Jingleheimer' ⋄ last←'Schmidt'  ``<br>
      ``∆f'His name is {first} {middle} last. This name has {+/⍴∊first middle last} letters.'``<br>
``His name is John Jacob Jingleheimer Schmidt. This name has 28 letters.``<br>
Source: __format__. Help info: __formatHelp.pdf__.
1. __bigInt__: Provides basic arithmetic functions on big integers stored externally as strings
and internally as a series of (signed) integers. Built around dfns:nat as its numerical core,  extended to handle signed numbers,
reduce and scan, factorial, and roll(?). Has both an easy-to-use operator style ``'2434324' *BI '3443'`` that takes care of importing and exporting APL numbers and (string-format) big integers, as well as a higher-performance function style ``bigInt.sqrt '449432342'`` suitable for user-designed algorithms. Easily extended to work with arbitrary APL arrays.
1. __∆HERE__: When executed in a traditional function/operator or named dfn/op, 
generates and returns (as its value) a ___here__ document_-- i.e. a collection of the contiguous (see options) comment lines that  
follow-- combined into a single string or a vector of string vectors, with the comment prefixes removed from each. 
Has options for string style, whether blank (non-comment) lines end the __here__ document or not, and other options. 
* The default keywords are:  ⍝ ⍠ MULTI  NOBLANKS   -- Create vector of vector and end the ∆HERE doc at first non-comment
* A common alternative is:   ⍝ ⍠ CR BLANKS         -- Create a char string with lines separated by CR carriage return.<BR>
                                                   -- End the Here doc before the first code line (not first non-comment).

