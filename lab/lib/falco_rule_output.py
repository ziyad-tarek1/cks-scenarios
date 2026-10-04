#!/usr/bin/env python3
"""Print the `output:` value of a named Falco rule. Usage: <file> <rule name>"""
import sys, re

path, rule = sys.argv[1], sys.argv[2]
try:
    txt = open(path).read()
except OSError:
    sys.exit(1)

for block in re.split(r'\n(?=-\s*rule:)', txt):
    if re.search(r'-\s*rule:\s*' + re.escape(rule) + r'\s*$', block, re.M):
        m = re.search(r'^\s*output:\s*(.+?)\s*$', block, re.M)
        if m:
            print(m.group(1).strip().strip('"').strip("'"))
        break
