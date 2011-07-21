
import std.stdio;
import std.range;
import multi_index;

int[] array(Range)(Range r)
if(isImplicitlyConvertible!(ElementType!Range, int)){
    int[] arr;
    foreach(e; r) arr ~= e;
    return arr;
}

unittest{
    alias MultiIndexContainer!(int, IndexedBy!(HashedUnique!())) C1;

    C1 c = new C1;
    c.insert(1);
    assert(c.front() == 1);
    c.insert(2);
    c.insert(3);
    assert(1 in c);
    assert(2 in c);
    assert(3 in c);
    auto a = array(c[]);
    assert( a == [1,2,3] ||
            a == [1,3,2] ||
            a == [2,1,3] ||
            a == [2,3,1] ||
            a == [3,1,2] ||
            a == [3,2,1]);
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

unittest{
    // hashed index only 
    alias MultiIndexContainer!(int, IndexedBy!(HashedNonUnique!())) C1;

    C1 c = new C1;
    c.insert(1);
    assert(c.front() == 1);
    c.insert(2);
    c.insert(3);
    c.insert(3);
    assert(1 in c);
    assert(2 in c);
    assert(3 in c);
    auto a = array(c[]);
    assert(a.length == 4);
    c.insert([4,5,6]);
    assert(4 in c);
    assert(5 in c);
    assert(6 in c);
    assert(c.length == 7);
    auto t = take(c[], 2);
    a = array(t);
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
    auto sz = c.removeKey(5);
    assert(5 !in c);
    assert(c.length == 23-sz);
}

unittest{
    alias MultiIndexContainer!(int, IndexedBy!(HashedUnique!(), 
                HashedNonUnique!("a*a"))) C1;

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

void main(){
}
