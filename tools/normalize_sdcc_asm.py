import sys, re

lines = open(sys.argv[1]).readlines()
out = []
for line in lines:
    line = line.rstrip()
    # Skip blank lines, comments, assembler directives
    if not line or line.startswith(';') or line.startswith('.'):
        continue
    # Strip inline comments
    line = re.sub(r'\s*;.*$', '', line)
    out.append(line)

print('\n'.join(out))