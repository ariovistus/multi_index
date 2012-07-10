DMD = dmd 
HERE = $(shell pwd)
MODEL=64
DDOCFLAGS=-m$(MODEL) -d -c -o- -version=StdDdoc 
DOCS = src/std.ddoc 

MI = src/replace.d src/multi_index.d 

all: test_heap test_sequenced test_ra test_ordered test_hashed 
	
clean: 
	rm -f topo test_heap test_sequenced test_ra test_ordered test_hashed mru test tagging messups
	rm -f *.o
	rm -f multi_index.html

html: multi_index.html

test: test.d $(MI)
	dmd -gc -of$@ $^

mru: unittests/mru.d $(MI)
	dmd -gc -of$@ $^

messups: unittests/messups.d $(MI)
	dmd -gc -of$@ $^

tagging: unittests/tagging.d $(MI)
	dmd -gc -of$@ $^ -unittest

multi_index.html: src/ddoc.d $(DOCS)
	$(DMD) $(DDOCFLAGS) -Df$@ $^
topo: unittests/topo.d src/multi_index.d src/replace.d
	$(DMD) -gc -oftopo $^ 

test_heap: unittests/test_heap.d $(MI)
	$(DMD) -gc -unittest -oftest_heap $^

test_sequenced: unittests/test_sequenced.d $(MI)
	$(DMD) -gc -unittest -oftest_sequenced $^

test_ra: unittests/test_ra.d $(MI)
	$(DMD) -gc -unittest -oftest_ra $^

test_ordered: unittests/test_ordered.d $(MI)
	$(DMD) -gc -unittest -oftest_ordered $^ -version=RBDoChecks

test_hashed: unittests/test_hashed.d $(MI)
	$(DMD) -gc -unittest -oftest_hashed $^
