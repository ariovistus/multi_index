DMD = dmd 
HERE = $(shell pwd)
MODEL=64
DDOCFLAGS=-m$(MODEL) -d -c -o- -version=StdDdoc 
DOCS = src/std.ddoc 

all: topo test_heap test_sequenced test_ra test_ordered test_hashed
	
clean: 
	rm -f topo test_heap test_sequenced test_ra test_ordered test_hashed
	rm -f *.o
	rm -f multi_index.html

html: multi_index.html

test: test.d src/replace.d src/multi_index.d
	dmd -gc -of$@ $^

mru: unittests/mru.d src/replace.d src/multi_index.d
	dmd -gc -of$@ $^

multi_index.html: src/replace.d src/multi_index.d $(DOCS)
	$(DMD) $(DDOCFLAGS) -Df$@ $^
topo: unittests/topo.d src/multi_index.d src/replace.d
	$(DMD) -gc -oftopo $^ 

test_heap: src/multi_index.d src/replace.d unittests/test_heap.d
	$(DMD) -gc -unittest -oftest_heap $^

test_sequenced: unittests/test_sequenced.d src/multi_index.d src/replace.d
	$(DMD) -gc -unittest -oftest_sequenced $^

test_ra: unittests/test_ra.d src/multi_index.d src/replace.d
	$(DMD) -gc -unittest -oftest_ra $^

test_ordered: unittests/test_ordered.d src/multi_index.d src/replace.d
	$(DMD) -gc -unittest -oftest_ordered $^ -version=RBDoChecks

test_hashed: unittests/test_hashed.d src/multi_index.d src/replace.d
	$(DMD) -gc -unittest -oftest_hashed $^
