
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


void main(){
}
