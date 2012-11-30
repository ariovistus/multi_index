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
    assert(equal(c[], [-1,1,100,100]));
    c.remove(c[1 .. 3]);
    assert(equal(c[], [-1,100]));
    c.insert([9,10,11,22]);
}

// again, but with immutable(int)
unittest{
    // ra index only
    alias MultiIndexContainer!(immutable(int), IndexedBy!(RandomAccess!()),Allocator) C1;

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
    assert(equal(c[], [1,-1,3,4]));
    c.swapAt(0,1);
    assert(equal(c[], [-1,1,3,4]));
    c.remove(c[1 .. 3]);
    assert(equal(c[], [-1,4]));
    c.insert([9,10,11,22]);
}

unittest{
    // ra index, ra index
    alias MultiIndexContainer!(int, IndexedBy!(RandomAccess!(), 
                RandomAccess!()),Allocator) C1;

    C1 a = new C1;
    auto c = a.get_index!0;
    auto d = a.get_index!1;

    alias typeof(c[]) Range1;
    import std.range;
    static assert(isInputRange!Range1);
    static assert(isBidirectionalRange!Range1);
    c.insert(1);
    c.insert(2);
    c.insert(3);
    assert(equal(c[], [1,2,3]));
    assert(equal(d[], [1,2,3]));
    c.insert([4,5,6]);
    a.check();
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
    a.check();
    c[1] = -1;
    assert(equal(c[], [1,-1,3,4]));
    c.swapAt(0,1);
    assert(equal(c[], [-1,1,3,4]));
    a.check();
    c.modify(c[2 .. c.length], (ref int i){ i = 100; });
    a.check();
    assert(equal(c[], [-1,1,100,100]));
    c.remove(c[1 .. 3]);
    assert(equal(c[], [-1,100]));
    assert(equal(d[], [-1,100]));
    a.check();
    c.insert([9,10,11,22]);
    assert(equal(d[], [-1,100,9,10,11,22]));
    a.check();
    c.remove(filter!"(a.v % 3 % 2) != 0"(PSR(c[])));
    /+
    auto r = c[];
    while(!r.empty){
        if(r.front % 3 % 2) r.removeFront();
        else r.popFront();
    }
    +/
    assert(equal(c[], [9,11]));
    assert(equal(d[], [9,11]));
}
// again, but with immutable(int)
unittest{
    // ra index, ra index
    alias MultiIndexContainer!(immutable(int), IndexedBy!(RandomAccess!(), 
                RandomAccess!()),Allocator) C1;

    C1 a = new C1;
    auto c = a.get_index!0;
    auto d = a.get_index!1;

    alias typeof(c[]) Range1;
    import std.range;
    static assert(isInputRange!Range1);
    static assert(isBidirectionalRange!Range1);
    c.insert(1);
    c.insert(2);
    c.insert(3);
    assert(equal(c[], [1,2,3]));
    assert(equal(d[], [1,2,3]));
    c.insert([4,5,6]);
    a.check();
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
    a.check();
    c[1] = -1;
    assert(equal(c[], [1,-1,3,4]));
    c.swapAt(0,1);
    assert(equal(c[], [-1,1,3,4]));
    c.remove(c[1 .. 3]);
    assert(equal(c[], [-1,4]));
    assert(equal(d[], [-1,4]));
    a.check();
    c.insert([9,10,11,22]);
    assert(equal(d[], [-1,4,9,10,11,22]));
    a.check();
    c.remove(filter!"(a.v % 3 % 2) != 0"(PSR(c[])));
    assert(equal(c[], [9,11]));
    assert(equal(d[], [9,11]));
}

unittest{
    class A{
        int i;
        int j;
        this(int _i, int _j) {
            i = _i;
            j = _j;
        }
    }
    alias MultiIndexContainer!(A, IndexedBy!(RandomAccess!()),
            MutableView, Allocator) C1;
    C1 c = new C1();
    c.insert(new A(1,2));
    c.front.j = 5;
    c[].front.j = 6;
    c.back.j = 7;
    c[].back.j = 8;
    c[0].j = 9;
}
}

mixin Testies!(GCAllocator) a1;
mixin Testies!(MallocAllocator) a2;

void main(){
}
