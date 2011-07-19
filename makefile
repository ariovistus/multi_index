all: topo test_heap test_sequenced test_ra
	
clean: 
	rm topo

topo: topo.d multi_index.d replace.d
	dmd -gc -oftopo topo.d multi_index.d replace.d

test_heap: test_heap.d multi_index.d replace.d
	dmd -gc -unittest -oftest_heap test_heap.d multi_index.d replace.d

test_sequenced: test_sequenced.d multi_index.d replace.d
	dmd -gc -unittest -oftest_sequenced test_sequenced.d multi_index.d replace.d

test_ra: test_ra.d multi_index.d replace.d
	dmd -gc -unittest -oftest_ra test_ra.d multi_index.d replace.d
