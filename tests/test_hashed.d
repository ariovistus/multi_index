
import std.stdio;
import std.range;
import std.algorithm;
import multi_index;
import std.traits;

template Testsies(Allocator) {

int[typeof(cast() ElementType!(Range).init)] set(Range)(Range r) {
    typeof(return) arr;
    foreach(e; r) arr[e]=1;
    return arr;
}
ElementType!Range[] array(Range)(Range r) {
    typeof(return) arr;
    foreach(e; r) arr ~= e;
    return arr;
}

unittest{
    alias MultiIndexContainer!(int, IndexedBy!(HashedUnique!()), Allocator) C1;

    C1 c = C1.create;
    c.insert(1);
    assert(c.front() == 1);
    c.insert(2);
    c.insert(3);
    assert(1 in c);
    assert(2 in c);
    assert(3 in c);
    assert(set(c[]) == set([1,2,3]));
    assert(c[1] == 1);
    c.insert([4,5,6]);
    assert(4 in c);
    assert(5 in c);
    assert(6 in c);
    assert(set(c[]) == set([1,2,3,4,5,6]));
    auto t = take(PSR(c[]), 2);
    auto a = array(t);
    c.remove(t);
    foreach(x; a) assert(x.v !in c);
    c.insert(iota(10));
    auto r = c.equalRange(8);
    c.remove(r);
    assert(8 !in c);
    c.removeKey(5);
    assert(5 !in c);


    c.clear();
    c.insert(iota(10));
    assert(set(c[]) == set([0,1,2,3,4,5,6,7,8,9]));
    r = c.equalRange(5);
    auto replace_count = c.replace(PSR(r).front, 6);
    assert(replace_count == 0);
    assert(set(c[]) == set([0,1,2,3,4,5,6,7,8,9]));

    replace_count = c.replace(PSR(r).front, 25);
    assert(replace_count == 1);
    assert(set(c[]) == set([0,1,2,3,4,25,6,7,8,9]));
    replace_count = c.replace(PSR(r).front, 25);
    assert(replace_count == 1);
    assert(set(c[]) == set([0,1,2,3,4,25,6,7,8,9]));

}

// again, but with immutable(int)
unittest{
    alias MultiIndexContainer!(immutable(int), IndexedBy!(HashedUnique!()), Allocator) C1;

    C1 c = C1.create;
    c.insert(1);
    assert(c.front() == 1);
    c.insert(2);
    c.insert(3);
    assert(1 in c);
    assert(2 in c);
    assert(3 in c);
    assert(set(c[]) == set([1,2,3]));
    assert(c[1] == 1);
    c.insert([4,5,6]);
    assert(4 in c);
    assert(5 in c);
    assert(6 in c);
    auto t = take(PSR(c[]), 2);
    auto a = array(t);
    c.remove(t);
    foreach(x; a) assert(x.v !in c);
    c.insert(iota(10));
    auto r = c.equalRange(8);
    c.remove(r);
    assert(8 !in c);
    c.removeKey(5);
    assert(5 !in c);

    c.clear();
    c.insert(iota(10));
    assert(set(c[]) == set([0,1,2,3,4,5,6,7,8,9]));
    r = c.equalRange(5);
    auto replace_count = c.replace(PSR(r).front, 6);
    assert(replace_count == 0);
    assert(set(c[]) == set([0,1,2,3,4,5,6,7,8,9]));

    replace_count = c.replace(PSR(r).front, 25);
    assert(replace_count == 1);
    assert(set(c[]) == set([0,1,2,3,4,25,6,7,8,9]));
    replace_count = c.replace(PSR(r).front, 25);
    assert(replace_count == 1);
    assert(set(c[]) == set([0,1,2,3,4,25,6,7,8,9]));
}

unittest{
    // hashed index only 
    alias MultiIndexContainer!(int, IndexedBy!(HashedNonUnique!()), Allocator) C1;

    C1 c = C1.create;
    c.insert(1);
    assert(c.front() == 1);
    c.insert(2);
    c.insert(3);
    c.insert(3);
    assert(set(c[]) == set([1,2,3])); // two 3
    assert(c.length == 4); // two 3
    c.insert([4,5,6]);
    assert(set(c[]) == set([1,2,3,4,5,6])); // two 3
    assert(c.length == 7); // two 3
    auto t = take(PSR(c[]), 2);
    auto a = array(t);
    c.remove(t);
    assert(c.length == 5);
    foreach(x; a) assert(x.v !in c);
    c.insert(iota(10));
    c.insert(iota(10));
    assert(c.length == 25);
    auto r = c.equalRange(8);
    assert(array(r.save()) == [8,8]);
    c.remove(r);
    assert(8 !in c);
    assert(c.length == 23);
    auto sz = c.removeKey(5,5,5);
    assert(5 !in c);
    assert(c.length == 23-sz);

    c.clear();
    c.insert(iota(10));
    assert(set(c[]) == set([0,1,2,3,4,5,6,7,8,9]));
    r = c.equalRange(5);
    auto replace_count = c.replace(PSR(r).front, 6);
    assert(replace_count == 1);
    assert(set(c[]) == set([0,1,2,3,4,6,7,8,9]));
    assert(c.length == 10);

    r = c.equalRange(6);
    replace_count = c.replace(PSR(r).front, 25);
    assert(replace_count == 1);
    assert(set(c[]) == set([0,1,2,3,4,25,6,7,8,9]));
    // r is pretty dang invalid now
    r = c.equalRange(25);
    replace_count = c.replace(PSR(r).front, 25);
    assert(replace_count == 1);
    assert(set(c[]) == set([0,1,2,3,4,25,6,7,8,9]));
}

// again, but with immutable(int)
unittest{
    // hashed index only 
    alias MultiIndexContainer!(immutable(int), IndexedBy!(HashedNonUnique!()), Allocator) C1;

    C1 c = C1.create;
    c.insert(1);
    assert(c.front() == 1);
    c.insert(2);
    c.insert(3);
    c.insert(3);
    assert(set(c[]) == set([1,2,3])); // two 3
    assert(c.length == 4); // two 3
    c.insert([4,5,6]);
    assert(set(c[]) == set([1,2,3,4,5,6])); // two 3
    assert(c.length == 7); // two 3
    auto t = take(PSR(c[]), 2);
    auto a = array(t);
    c.remove(t);
    assert(c.length == 5);
    foreach(x; a) assert(x.v !in c);
    c.insert(iota(10));
    c.insert(iota(10));
    assert(c.length == 25);
    auto r = c.equalRange(8);
    assert(array(r.save()) == [8,8]);
    c.remove(r);
    assert(8 !in c);
    assert(c.length == 23);
    auto sz = c.removeKey(5,5,5);
    assert(5 !in c);
    assert(c.length == 23-sz);

    c.clear();
    c.insert(iota(10));
    assert(set(c[]) == set([0,1,2,3,4,5,6,7,8,9]));
    r = c.equalRange(5);
    auto replace_count = c.replace(PSR(r).front, 6);
    assert(replace_count == 1);
    assert(set(c[]) == set([0,1,2,3,4,6,7,8,9]));
    assert(c.length == 10);

    r = c.equalRange(6);
    replace_count = c.replace(PSR(r).front, 25);
    assert(replace_count == 1);
    assert(set(c[]) == set([0,1,2,3,4,25,6,7,8,9]));
    // r is pretty dang invalid now
    r = c.equalRange(25);
    replace_count = c.replace(PSR(r).front, 25);
    assert(replace_count == 1);
    assert(set(c[]) == set([0,1,2,3,4,25,6,7,8,9]));
}

// tests for removeKey
unittest{
    alias MultiIndexContainer!(int, IndexedBy!(HashedUnique!()), Allocator) C1;
    {
    C1 c = C1.create;
    c.insert(iota(20));
    assert(c.length == 20);
    auto i = c.removeKey(0);
    assert(i == 1);
    assert(c.length == 19);
    i = c.removeKey(0);
    assert(i == 0);
    assert(c.length == 19);
    i = c.removeKey(1,0,1,0,2,0,4);
    assert(set(c[]) == set([3,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]));
    assert(i == 3);
    }

    alias MultiIndexContainer!(string, IndexedBy!(HashedUnique!()), Allocator) C2;
    {
    C2 c = C2.create;
    c.insert(["a","g","b","c","z"]);
    assert(set(c[]) == set(["a","b","c","g","z"]));
    auto i = c.removeKey(["a","z"]);
    assert(i == 2);
    assert(set(c[]) == set(["b","c","g"]));
    i = c.removeKey(map!("a.toLower()")(["C","G"]));
    assert(i == 2);
    assert(equal(c[], ["b"]));
    }
    // tests from std.container
    {
    auto rbt = C2.create;
    rbt.insert(["hello", "world", "foo", "bar"]);
    assert(set(rbt[]) == set(["bar", "foo", "hello", "world"]));
    assert(rbt.removeKey("hello") == 1);
    assert(rbt.length == 3);
    assert(rbt.length == 3);
    assert(set(rbt[]) == set(["bar", "foo", "world"]));
    assert(rbt.removeKey("hello") == 0);
    assert(set(rbt[]) == set(["bar", "foo", "world"]));
    assert(rbt.removeKey("hello", "foo", "bar") == 2);
    assert(set(rbt[]) == set(["world"]));
    assert(rbt.removeKey(["", "world", "hello"]) == 1);
    assert(rbt.empty);
    }
    {
    auto rbt = C1.create;
    rbt.insert([1, 2, 12, 27, 4, 500]);
    assert(set(rbt[]) == set([1, 2, 4, 12, 27, 500]));
    assert(rbt.removeKey(1u) == 1);
    assert(set(rbt[]) == set([2, 4, 12, 27, 500]));
    assert(rbt.removeKey(cast(byte)1) == 0);
    assert(set(rbt[]) == set([2, 4, 12, 27, 500]));
    assert(rbt.removeKey(1, 12u, cast(byte)27) == 2);
    assert(set(rbt[]) == set([2, 4, 500]));
    assert(rbt.removeKey([cast(short)0, cast(short)500, cast(short)1]) == 1);
    assert(set(rbt[]) == set([2, 4]));
    }
    // end tests from std.container
    {
    alias MultiIndexContainer!(int, IndexedBy!(HashedNonUnique!()), Allocator) C3;
    alias MultiIndexContainer!(int, IndexedBy!(Sequenced!()), Allocator) Ci;
    auto rbt = C3.create;
    rbt.insert([1,2,3,4,4,4,4,5,6,7]);
    assert(rbt.length == 10);
    assert(rbt.length == count(rbt[]));

    assert(set(rbt[]) == set([1,2,3,4,4,4,4,5,6,7]));
    assert(rbt.length == 10);

    auto keys2 = C1.create;
    auto keys = Ci.create;
    keys.insert([5,6]);
    keys2.insert([2,3]);

    auto r = rbt.equalRange(4);
    assert(equal(r, [4,4,4,4]));
    auto i = rbt.removeKey(take(r,3));
    import std.format : format;
    assert(i == 3, format("i: %s", i));
    assert(rbt.length == 7); 
    i = rbt.removeKey(r); 
    assert(i == 1);
    assert(set(rbt[]) == set([1,2,3,5,6,7]));
    i = rbt.removeKey(keys[]); 
    assert(i == 2);
    assert(set(rbt[]) == set([1,2,3,7]));
    i = rbt.removeKey(keys2[]); 
    assert(i == 2);
    assert(equal(rbt[], [1,7]));
    }
}

unittest{
    alias MultiIndexContainer!(int, IndexedBy!(HashedUnique!(), 
                HashedNonUnique!("a*a")), Allocator) C1;

    C1 y = C1.create;
    auto c = y.get_index!0;
    auto d = y.get_index!1;
    c.insert(1);
    assert(c.front() == 1);
    c.insert(2);
    c.insert(3);
    c.insert(3);
    d.insert(3);
    assert(1 in c);
    assert(2 in c);
    assert(3 in c);
    assert(c.length == 3);
    assert(1 in d);
    assert(2 in d);
    assert(3 in d);
    assert(d.length == 3);
    auto a = array(c[]);
    assert(c[1] == 1);
    c.insert([4,5,6]);
    assert(4 in c);
    assert(5 in c);
    assert(6 in c);
    auto t = take(PSR(c[]), 2);
    auto a2 = array(t);
    c.remove(t);
    foreach(x; a2) assert(x.v !in c);
    c.insert(iota(10));
    auto r = c.equalRange(8);
    c.remove(r);
    assert(8 !in c);
    c.removeKey(5);
    assert(5 !in c);
}

unittest {
    import std.typecons;
    int i = 1;
    int j = 2;
    string k = "hi";
    string m = "bi";
    alias Tuple!(int*,"i",string,"k") Tup;
    alias MultiIndexContainer!(Tup, 
            IndexedBy!(HashedUnique!("a.i"), HashedUnique!("a.k")), Allocator, MutableView) 
        C;

    C c = C.create();
    c.get_index!0 .insert(Tup(&i,"hi"));
    c.get_index!0 .insert(Tup(&j,"bi"));
    foreach(entry; c.get_index!0 .opSlice()) {
        writefln(" i=%x, k=%s", entry.i, entry.k);
    }
    assert(c.get_index!0 .length == 2);
    auto r = PSR(c.index!1 .equalRange("bi"));
    auto replace_count = c.index!0 .replace(r.front, Tup(null, "bi"));
    assert(replace_count == 1);
    foreach(entry; c.get_index!0 .opSlice()) {
        writefln(" i=%x, k=%s", entry.i, entry.k);
    }
    r = PSR(c.index!1 .equalRange("bi"));
    writefln("try to replace bi with %x, bi", &i);
    replace_count = c.index!0 .replace(r.front, Tup(&j, "bi"));
    assert(replace_count == 1);
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
    alias MultiIndexContainer!(A, IndexedBy!(HashedUnique!("a.i")), 
            MutableView, Allocator) C1;
    C1 c = C1.create();
    c.insert(new A(1,2));
    c.front.j = 65;
    c[].front.j = 85;
    c[1].j = 95;
}

unittest{
    class A{
    }
    alias MultiIndexContainer!(A, IndexedBy!(HashedUnique!()), 
            MutableView, Allocator) C1;
    C1 c = C1.create();
    auto a1 = new A();
    auto a2 = new A();
    c.insert(a1);
    c.insert(a2);
    c.insert(a1);
    assert(c.length == 2);
}

unittest{
    alias MultiIndexContainer!(int, IndexedBy!(HashedNonUnique!("a")), Allocator) C1;

    C1 c = C1.create;
    for(auto i = 0; i < 1000; i++) {
        c.insert(1);
        c.insert(1544);
    }

    assert(c.length == 2000);
}

}

mixin Testsies!(GCAllocator) a1;
mixin Testsies!(MallocAllocator) a2;

