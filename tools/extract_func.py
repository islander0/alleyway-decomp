# <source.asm> <FuncName> [--verbose]
import sys, re

src, name = sys.argv[1], sys.argv[2]
verbose = '--verbose' in sys.argv

try:
    lines = open(src, encoding='utf-16', errors='ignore').readlines()
except UnicodeError:
    lines = open(src, encoding='utf-8-sig', errors='ignore').readlines()

capturing = False
result = []
for line in lines:
    if re.match(rf'^{name}:', line):
        capturing = True
    if capturing:
        result.append(line)
        if result and len(result) > 1 and re.match(r'^[A-Za-z_][A-Za-z0-9_]*:', line):
            result.pop()
            break

if verbose:
    print(''.join(result))
else:
    cleaned = []
    for line in result:
        line = line.rstrip()
        if not line or line.startswith(';'):
            continue
        line = re.sub(r'\s*;.*$', '', line)
        if line.strip():
            cleaned.append(line)
    print('\n'.join(cleaned))