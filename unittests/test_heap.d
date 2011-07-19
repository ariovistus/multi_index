import std.stdio;
import std.string;
import std.algorithm;
import std.range;
import multi_index;

int[] array(Range)(Range r)
if(isImplicitlyConvertible!(ElementType!Range, int)){
    int[] arr;
    foreach(e; r) arr ~= e;
    return arr;
}
unittest{
    // lone heap index
    alias MultiIndexContainer!(int, IndexedBy!(Heap!())) C1;

    C1 c = new C1;
    c.insert(1);
    c.insert(2);
    c.insert(3);
    assert(c.front() == 3);
    c.insert([5,6,7]);
    assert(c.front() == 7);
    c.modify(c[], (ref int i){ i = 77; });
    assert(c.front() == 77);
    assert(filter!"a==7"(c[]).empty);
    c.modify(c[], (ref int i){ i = 0; });
    assert(c.front() == 6);
    auto r = c[];
    r.popFront();
    r.popFront();
    auto tmp = r.front;
    c.modify(r, (ref int i){ i = 80; });
    assert(c.front() == 80);
    c.removeFront();
    assert(c.front() == 6);
    c.insert(tmp); // was tmp 5? not sure, so put it back if it was
    auto t = take(c[],1);
    c.remove(t);
    assert(c.front() == 5);
    assert(c.length == 5);
    foreach(i; 0 .. 5){
        c.removeBack();
    }
    assert(c.empty);
}

unittest{
    // lone heap index helper
    alias MultiIndexContainer!(int, IndexedBy!(Heap!())) C1;

    C1 d = new C1;
    auto c = d.get_index!0;
    c.insert(1);
    c.insert(2);
    c.insert(3);
    assert(c.front() == 3);
    c.insert([5,6,7]);
    assert(c.front() == 7);
    c.modify(c[], (ref int i){ i = 77; });
    assert(c.front() == 77);
    assert(filter!"a==7"(c[]).empty);
    c.modify(c[], (ref int i){ i = 0; });
    assert(c.front() == 6);
    auto r = c[];
    r.popFront();
    r.popFront();
    auto tmp = r.front;
    c.modify(r, (ref int i){ i = 80; });
    assert(c.front() == 80);
    c.removeFront();
    assert(c.front() == 6);
    c.insert(tmp); // was tmp 5? not sure, so put it back if it was
    auto t = take(c[],1);
    c.remove(t);
    assert(c.front() == 5);
    assert(c.length == 5);
    foreach(i; 0 .. 5){
        c.removeBack();
    }
    assert(c.empty);
}

unittest{
    // min heap, max heap
    alias MultiIndexContainer!(int, IndexedBy!(Heap!("a", "a>b"), 
                Heap!("a", "a<b"))) C1;

    C1 c = new C1;
    auto min = c.get_index!0;
    auto max = c.get_index!1;
    min.insert(1);
    min.insert(2);
    min.insert(3);
    assert(max.front() == 3);
    assert(min.front() == 1);
    min.insert([5,6,7]);
    assert(min.front() == 1);
    assert(max.front() == 7);
    max.modify(max[], (ref int i){ i = 77; });
    assert(min.front() == 1);
    assert(max.front() == 77);
    assert(filter!"a==7"(min[]).empty);
    assert(filter!"a==7"(max[]).empty);
    max.modify(max[], (ref int i){ i = 0; });
    assert(min.front() == 0);
    assert(max.front() == 6);
    auto r = min[];
    r.popFront();
    r.popFront();
    auto tmp = r.front;
    min.modify(r, (ref int i){ i = 80; });
    assert(min.front() == 0);
    assert(max.front() == 80);
    max.removeFront();
    assert(max.front() == 6);
    min.insert(tmp); // was tmp 5? not sure, so put it back if it was
    auto t = take(max[],1);
    max.remove(t);
    assert(max.front() == 5);
    assert(max.length == 5);
    foreach(i; 0 .. 5){
        max.removeBack();
    }
    assert(max.empty);
    assert(min.empty);
}

void main(){
}
