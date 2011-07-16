all: topo
	
clean: 
	rm topo

topo: topo.d multi_index.d replace.d
	dmd -oftopo topo.d multi_index.d replace.d

