
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

    C1 c = new C1;
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
    auto t = take(c[], 2);
    auto a = array(t);
    c.remove(t);
    foreach(x; a) assert(x !in c);
    c.insert(iota(10));
    auto r = c.equalRange(8);
    c.remove(r);
    assert(8 !in c);
    c.removeKey(5);
    assert(5 !in c);
}

unittest{
    // hashed index only 
    alias MultiIndexContainer!(int, IndexedBy!(HashedNonUnique!()), Allocator) C1;

    C1 c = new C1;
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
    auto t = take(c[], 2);
    auto a = array(t);
    c.remove(t);
    assert(c.length == 5);
    foreach(x; a) assert(x !in c);
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
}

// tests for removeKey
unittest{
    alias MultiIndexContainer!(int, IndexedBy!(HashedUnique!()), Allocator) C1;
    {
    C1 c = new C1;
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
    C2 c = new C2;
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
    auto rbt = new C2;
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
    auto rbt = new C1;
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
    auto rbt = new C3;
    rbt.insert([1,2,3,4,4,4,4,5,6,7]);
    assert(rbt.length == 10);
    assert(rbt.length == count(rbt[]));

    assert(set(rbt[]) == set([1,2,3,4,4,4,4,5,6,7]));
    assert(rbt.length == 10);

    auto keys2 = new C1;
    auto keys = new Ci;
    keys.insert([5,6]);
    keys2.insert([2,3]);

    auto r = rbt.equalRange(4);
    assert(equal(r, [4,4,4,4]));
    auto i = rbt.removeKey(take(r,3)); 
    assert(i == 3,format("i: %s",i));
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

    C1 y = new C1;
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
    auto t = take(c[], 2);
    a = array(t);
    c.remove(t);
    foreach(x; a) assert(x !in c);
    c.insert(iota(10));
    auto r = c.equalRange(8);
    c.remove(r);
    assert(8 !in c);
    c.removeKey(5);
    assert(5 !in c);
}

}

mixin Testsies!(GCAllocator) a1;
mixin Testsies!(MallocAllocator) a2;

void main(){
}
