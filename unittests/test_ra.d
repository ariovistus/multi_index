import std.stdio;
import std.algorithm;
import std.range;
import multi_index;

template Testies(Allocator) {
unittest{
    // ra index only
    alias MultiIndexContainer!(int, IndexedBy!(RandomAccess!()),Allocator) C1;

    C1 c = new C1;
    c.insert(1);
    c.insert(2);
    c.insert(3);
    assert(equal(c[], [1,2,3]));
    c.insert([4,5,6]);
    assert(equal(c[], [1,2,3,4,5,6]));
    assert(equal(c[3 .. c.length], [4,5,6]));
    assert(c.front() == 1);
    assert(c.back() == 6);
    assert(c[2] == 3);
    c.removeBack();
    assert(equal(c[], [1,2,3,4,5]));
    assert(c.back() == 5);
    c.removeAny();
    assert(equal(c[], [1,2,3,4]));
    assert(c.back() == 4);
    // eh, replace not implemented
    c[1] = -1;
    //c.modify(c[1 .. 2], (ref int i){ i = -1; });
    assert(equal(c[], [1,-1,3,4]));
    c.swapAt(0,1);
    assert(equal(c[], [-1,1,3,4]));
    c.modify(c[2 .. c.length], (ref int i){ i = 100; });
    assert(equal(c[], [-1,1,100,4]));
    c.linearRemove(c[1 .. 3]);
    assert(equal(c[], [-1,4]));
    c.insert([9,10,11,22]);
    auto r = c[];
    while(!r.empty){
        if(r.front % 3 % 2) r.removeFront();
        else r.popFront();
    }
    assert(equal(c[], [9,11]));
}

unittest{
    // ra index, ra index
    alias MultiIndexContainer!(int, IndexedBy!(RandomAccess!(), 
                RandomAccess!()),Allocator) C1;

    C1 a = new C1;
    auto c = a.get_index!0;
    auto d = a.get_index!1;
    c.insert(1);
    c.insert(2);
    c.insert(3);
    assert(equal(c[], [1,2,3]));
    assert(equal(d[], [1,2,3]));
    c.insert([4,5,6]);
    assert(equal(c[], [1,2,3,4,5,6]));
    assert(equal(d[], [1,2,3,4,5,6]));
    assert(equal(c[3 .. c.length], [4,5,6]));
    assert(equal(d[3 .. c.length], [4,5,6]));
    assert(c.front() == 1);
    assert(c.back() == 6);
    assert(c[2] == 3);
    c.removeBack();
    assert(equal(c[], [1,2,3,4,5]));
    assert(c.back() == 5);
    c.removeAny();
    assert(equal(c[], [1,2,3,4]));
    assert(c.back() == 4);
    c[1] = -1;
    assert(equal(c[], [1,-1,3,4]));
    c.swapAt(0,1);
    assert(equal(c[], [-1,1,3,4]));
    c.modify(c[2 .. c.length], (ref int i){ i = 100; });
    assert(equal(c[], [-1,1,100,4]));
    c.linearRemove(c[1 .. 3]);
    assert(equal(c[], [-1,4]));
    assert(equal(d[], [-1,4]));
    c.insert([9,10,11,22]);
    assert(equal(d[], [-1,4,9,10,11,22]));
    auto r = c[];
    while(!r.empty){
        if(r.front % 3 % 2) r.removeFront();
        else r.popFront();
    }
    assert(equal(c[], [9,11]));
    assert(equal(d[], [9,11]));
}
}

mixin Testies!(GCAllocator) a1;
mixin Testies!(MallocAllocator) a2;

void main(){
}
