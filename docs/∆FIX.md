# ∆FIX command
__Description__

__∆FIX__ is a preprocessor for _Dyalog APL_ files following the formal specifications of the `2∘⎕FIX` command. Normally identified as dot-Dyalog (__.dyalog__) files, these files contain one or more 
* namespace-like objects (namespaces, classes, and interfaces), 
* traditional functions (marked with `∇...∇`, unless the sole object in the file), and 
* direct fns (_dfns_).

__Syntax__
   - _opts_ ∇  [_objName_ | _objName exp_]
   
   - _opts_: 0 (default), 1, or 2.  <BR>
         `0` Preprocess and `⎕FIX` in workspace. Include all preprocessor cmds as comments. <BR>
         `1` As above, but include preprocessor  cmds only for the paths taken (via ::IF, etc.) <BR>
         `2`  As above, but omit all preprocessor cmds, keeping other comments. <BR>
	
   - __objName__:  The name of the file containing the objects, plus preprocessor directives. The names in the workspace will be derived from the names of objects defined within the file. If the objName has no type, it is assumed to be .dyalog.
	
   -  __exp__: 
If specified, may be 0, 1, or 2 (default: 0). Determines whether the object is fixed in the workspace (exp=0,1), and what is returned (below).
    __Returns__: 
      exp=0: Returns the names of the objects 2∘⎕FIXED in the workspace. Default.
      exp=1: Returns a 2-element array
              [0] names of objects fixed in the workspace.
              [1] the contents of the preprocessor output text
      exp=2: Nothing is fixed. Returns only the contents of the preprocessor output. 

## Preprocessor Directives

Directives are of the form ``::DIRECTIVE name ← value`` or ``::DIRECTIVE (cond) action``
Directives are always the first item on any line of input (leading spaces are ignored).


Special commands are of the form:
      #COMMAND{argument}
Or
      name..COMMAND

Command Descriptions

:DEF[INE] name ← string

:UNDEF name

:LET name ← value
:EVAL name ← value 

:IFDEF name
    …
:ELSE    
    …
:ENDIF[DEF]

:IF cond
:ELSEIF cond
:ELSE
:ENDIF

::INCLUDE  fileID
Include file right here, replacing the include statement, and preprocess it. fileID: (currently) a file identifier; if no filetype is indicated, .dyalog is assumed.
::CINCLUDE fileID
Include the file right here, as for ::INCLUDE, but only if not already included via ::INCLUDE or ::CINCLUDE. fileID: see ::INCLUDE.

:COND cond statement

:MESSAGE any text
:MSG any text

:ERROR [errcode] any text

#ENV{name}		
returns the value of the environment variable “name”.
#SH[ELL]{shell_cmd}
	Returns the value of the shell command ⎕SH ‘shell_cmd’.
#EXEC{apl_cmd}
	Returns the value of the APL command ⍎‘apl_cmd’.

name..DEF                becomes (0≠⎕NC ‘name’)
name1.name2.name3..DEF   becomes (0≠⎕NC ‘name1.name2.name3’)

name..UNDEF              becomes (0=⎕NC ‘name’)
name1.name2.name3..UNDEF becomes (0=⎕NC ‘name1.name2.name3’)


APL STRINGS
APL strings in single quotes are handled as in APL. Strings may appear in double quotes (“...”), may contain unduplicated single quotes, and may extend over multiple lines.  Double quoted strings are converted to single-quoted strings, after:
Doubling internal single quotes
Processing doubled internal double quotes.
Converting newlines to ⎕UCS 10, in this way ( ⏎ used to show newline):
“String1 ⏎string2” → (‘String’,(⎕UCS 10),’string2’)
Blanks at the beginning of each continuation line are removed (the symbol · shows where the leading blanks are).
BEFORE:
	“This is line 1. ⏎       
······This is line 2.”  
	AFTER:
     (‘This is line 1.’,(⎕UCS 10),’This is line 2.’)

Simple Macros
  All names defined by ::DEF or ::LET (or synonym, ::EVAL) are replaced anywhere in APL text outside of quoted strings. If those objects contain non-text, they are converted to text; if they appear on multiple lines, it must make sense in the APL context.

Continuation lines in APL code
   You may continue any APL line by placing two or more dots .. before any comments on that line.
   In some cases, where the preprocessor handles arguments in parentheses or braces, those arguments may span multiple lines as left-hand parentheses or braces are matched by their right-hand counterparts. These will be documented in a later edition of this document.

Bugs
   In this version, trailing (right-hand) comments are omitted from the preprocessor output. Lines containing nothing but comments (possibly with leading blanks) are maintained as is. This may cause problems for those using comments as “here text” or otherwise manipulating the comments in the (preprocessed) source file. Since most such uses depend on full comment lines, this should in most cases not be a problem.


