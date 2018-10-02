A library of useful APL functions and operators, specified as prototypes, best implemented within the language. 

This is a work in progress, as I move a handful of such functions out of workspaces into github.

1. require: Reminiscent of __import__ in Python and __require__ or __use__ in Perl, __require__ ensures that the "packages" in the right argument are either in the caller's namespace, in the ⎕PATH, in the filesystem search path (Unix environment __WSPATH__ or using built-in ⎕SE.∆WSPATH), or in the workspace indicated (e.g. 'dfns:cmpx'). If in the caller's namespace or ⎕PATH, nothing more is done. Also allows easy importing of an entire workspace ('dfns:') or all the __\*.dyalog__ files filesystem directory ('myfns.mymath').
