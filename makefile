all: topo test_heap test_sequenced test_ra test_ordered test_hashed
	
clean: 
	rm topo test_heap test_sequenced test_ra test_ordered test_hashed

topo: topo.d multi_index.d replace.d
	dmd -gc -oftopo topo.d multi_index.d replace.d

test_heap: test_heap.d multi_index.d replace.d
	dmd -gc -unittest -oftest_heap test_heap.d multi_index.d replace.d

test_sequenced: test_sequenced.d multi_index.d replace.d
	dmd -gc -unittest -oftest_sequenced test_sequenced.d multi_index.d replace.d

test_ra: test_ra.d multi_index.d replace.d
	dmd -gc -unittest -oftest_ra test_ra.d multi_index.d replace.d

test_ordered: test_ordered.d multi_index.d replace.d
	dmd -gc -unittest -oftest_ordered test_ordered.d multi_index.d replace.d -version=RBDoChecks

test_hashed: test_hashed.d multi_index.d replace.d
	dmd -gc -unittest -oftest_hashed test_hashed.d multi_index.d replace.d 
