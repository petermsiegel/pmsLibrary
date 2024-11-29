# Tree.py
import sys
from pathlib import Path

def print_tree(p: Path, last=True, header=''):
  elbow = "└──"
  pipe = "│  "
  tee = "├──"
  blank = "   "
  print(header + (elbow if last else tee) + p.name  )
  if p.is_dir():
      children = list(p.iterdir())
      for i, c in enumerate(children):
          print_tree(c, 
                     i == len(children) - 1, 
                     header + (blank if last else pipe) 
          )

print_tree( Path(sys.argv[1]) )