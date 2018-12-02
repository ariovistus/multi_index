dub build -b ddox
dmd source/ddoc.d source/std.ddoc -D -X -Xfdocs.json -c -o-
ddox generate-html docs.json docs --std-macros=source/std.ddoc
