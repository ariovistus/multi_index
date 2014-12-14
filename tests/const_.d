import std.algorithm;
import multi_index;


// Things we can do with const Sequenced: 
alias MultiIndexContainer!(int, IndexedBy!(Sequenced!())) SList_i;

void seq_const_stuff(const SList_i list) {
    // can iterate over a const sequence.
    assert(equal(list[], [1,2,3,4]));
    // can read elements of const sequence.
    assert(list.front == 1);
    assert(list.back == 4);
    // can read length and test emptiness
    assert(list.length == 4);
    assert(list.empty == false);
}

// Things we can do with const Ordered:
alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!())) Tree_i;

void tree_const_stuff(const Tree_i tree) {
    // can iterate over a const Ordered
    assert(equal(tree[], [1,2,3,4]));
    assert(equal(tree.equalRange(2), [2]));
    assert(equal(tree.lowerBound(3), [1,2]));
    assert(equal(tree.upperBound(3), [4]));
    // templates and inout causing problems
    //assert(equal(tree.bounds!"()"(0,3), [1,2]));
    // can read elements of const Ordered
    assert(tree.front == 1);
    assert(tree.back == 4);
    // can read length and test emptiness
    assert(tree.length == 4);
    assert(tree.empty == false);
    assert(2 in tree);
    assert(tree[2] == 2);
}


// Things we can do with const RandomAccess:
alias MultiIndexContainer!(int, IndexedBy!(RandomAccess!())) Arr_i;

void ra_const_stuff(const Arr_i arr) {
    // can iterate over a const RandomAccess.
    assert(equal(arr[], [1,2,3,4]));
    assert(equal(arr[0 .. 2], [1,2]));
    // can read elements of const RandomAccess.
    assert(arr.front == 1);
    assert(arr.back == 4);
    assert(arr[1] == 2);
    // can read properties of const RandomAccess
    assert(arr.length == 4);
    assert(arr.empty == false);
    assert(arr.capacity != 0);

}

// Things we can do with const Hashed:
alias MultiIndexContainer!(int, IndexedBy!(HashedUnique!())) Hash_i;

void hashed_const_stuff(const Hash_i hash) {
    // can iterate over a const Hashed.
    assert(!hash[].empty);
    assert(equal(hash.equalRange(2),[2]));
    // can read elements of a const Hashed.
    assert(hash.front != 0);
    assert(1 in hash);
    assert(2 in hash);
    assert(3 in hash);
    assert(hash.contains(4));
    assert(hash[1] == 1);
    // can read properties of a const Hashed.
    assert(hash.loadFactor != 0);
    assert(hash.capacity != 0);
    assert(hash.length == 4);
    assert(hash.empty == false);
}

// Things we can do with const Heap:
alias MultiIndexContainer!(int, IndexedBy!(Heap!())) Heap_i;

void heap_const_stuff(const Heap_i heap) {
    // can iterate over a const Heap.
    assert(!heap[].empty);
    // can read elements of const Heap.
    assert(heap.front == 4);
    assert(heap.back != 4);
    // can read properties of const Heap.
    assert(heap.length == 4);
    assert(heap.empty == false);
    assert(heap.capacity != 0);
}


unittest {
    SList_i list = new SList_i();
    list.insert([1,2,3,4]);
    seq_const_stuff(list);
}

unittest {
    Tree_i tree = new Tree_i();
    tree.insert([1,2,3,4]);
    tree_const_stuff(tree);
}

unittest {
    Hash_i hash = new Hash_i();
    hash.insert([1,2,3,4]);
    hashed_const_stuff(hash);
}

unittest {
    Heap_i heap = new Heap_i();
    heap.insert([1,2,3,4]);
    heap_const_stuff(heap);
}
