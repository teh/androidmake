import re
import os
import sys

try:
    directory = sys.argv[1]
except IndexError:
    directory = '.'

interest = [
    os.path.join(root, f)
    for root, dirs, files in os.walk(directory)
    for f in files
    if f.endswith('.scala')
]

class_names = [(i, re.findall('class\s+(\w+)', open(i).read())) for i in interest]
all_classes = ['%s.class' % n for _, names in class_names for n in names]
print "CLASSES = %s" % " ".join(all_classes)
for path, names in class_names:
    print "%s: %s" % (" ".join("gen/$(PACKAGE_PATH)/%s.class" % n for n in names), path)
    print "\t	scalac -classpath $(CLASSPATH) $< -d gen"
