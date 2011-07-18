all: topo
	
clean: 
	rm topo

topo: topo.d multi_index.d replace.d
	dmd -gc -oftopo topo.d multi_index.d replace.d

