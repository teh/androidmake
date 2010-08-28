import re
import os
import sys

try:
    directory = sys.argv[1]
except IndexError:
    directory = '.'

interest = [
    (root, os.path.join(root, f))
    for root, dirs, files in os.walk(directory)
    for f in files
    if f.endswith('.scala')
]

class_names = [(i, re.findall('class\s+(\w+)', open(i).read())) for _, i in interest]
all_classes = ['%s.class' % n for _, names in class_names for n in names]
print "CLASSES = %s ." % (" ".join(all_classes))
print "gen/scalamake.mk: %s" % (" ".join(set(root for root, _ in  interest)))

# Need a topological sort on class_names depending on where those
# classes appear.

# 1) Build graph
appear_in = {}
all_files = dict((path, open(path).read()) for path, _ in class_names)
class_map = dict((name, path) for path, names in class_names for name in names)

for def_path, names in class_names:
    for name in names:
        for appear_path, data in all_files.iteritems():
            appear_in.setdefault(appear_path, set())
            if 'new %s' % name in data: # e.g. val a = new Array[Int](100)
                if def_path == appear_path: # defined in the same file: skip
                    continue
                appear_in[appear_path].add(class_map[name])

# 2) Topological sort
# see e.g. http://en.wikipedia.org/wiki/Topological_sorting
build_order = []
no_incoming = set(path for path, incoming in appear_in.iteritems() if incoming == set())
while no_incoming:
    n = no_incoming.pop()
    build_order.append(n)
    for path, incoming in appear_in.iteritems():
        # Store vertex if it transitions from has-element to empty
        if n in incoming:
            incoming.discard(n)
            if incoming == set():
                no_incoming.add(path)

path_map = dict((path, names) for path, names in class_names)
for path in build_order:
    names = path_map[path]
    print "%s: %s" % (" ".join("gen/$(PACKAGE_PATH)/%s.class" % n for n in names), path)
    print "\t	scalac -classpath $(CLASSPATH) $< -d gen"
