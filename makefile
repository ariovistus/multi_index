DMD = dmd #~/Downloads/dmd2.058/linux/bin64/dmd
HERE = $(shell pwd)
MODEL=64
DDOCFLAGS=-m$(MODEL) -d -c -o- -version=StdDdoc 

DPLGIT = ~/Downloads/d-programming-language.org

DOCS = std.ddoc #$(DPLGIT)/doc.ddoc $(DPLGIT)/macros.ddoc $(DPLGIT)/std.ddoc

all: topo test_heap test_sequenced test_ra test_ordered test_hashed
	
clean: 
	rm -f topo test_heap test_sequenced test_ra test_ordered test_hashed
	rm -f *.o
	rm -f multi_index.html

html: multi_index.html

multi_index.html: multi_index.d $(DOCS)
	$(DMD) $(DDOCFLAGS)  $(DOCS) -Df$@ $<
	#echo '$(HERE)/%.html : %.d $$(DDOC)' > posix.mak
	#echo -e '\t$(DMD) -c -o- -Df$$@ $$(DDOC) $$<' >> posix.mak
	#touch posix.mak
	#cp $< $(DPLGIT)/$<d
	#cd $(DPLGIT)
	#make -f posix.mak ./web/multi_index.html
	#cd $(HERE)
	#rm posix.mak
topo: topo.d multi_index.d replace.d
	$(DMD) -gc -oftopo topo.d multi_index.d replace.d

test_heap: multi_index.d replace.d test_heap.d
	$(DMD) -gc -unittest -oftest_heap multi_index.d replace.d test_heap.d

test_sequenced: test_sequenced.d multi_index.d replace.d
	$(DMD) -gc -unittest -oftest_sequenced test_sequenced.d multi_index.d replace.d

test_ra: test_ra.d multi_index.d replace.d
	$(DMD) -gc -unittest -oftest_ra test_ra.d multi_index.d replace.d

test_ordered: test_ordered.d multi_index.d replace.d
	$(DMD) -gc -unittest -oftest_ordered test_ordered.d multi_index.d replace.d -version=RBDoChecks

test_hashed: test_hashed.d multi_index.d replace.d
	$(DMD) -gc -unittest -oftest_hashed test_hashed.d multi_index.d replace.d 
