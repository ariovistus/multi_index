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
    // sequenced index only
    alias MultiIndexContainer!(int, IndexedBy!(Sequenced!())) C1;

    C1 c = new C1;
    c.insert(1);
    c.insert(2);
    c.insert(1);
    c.insert(2);
    assert(array(c[]) == [1,2,1,2]);
    c.insert([45,67,101]);
    assert(array(c[]) == [1,2,1,2,45,67,101]);
    c.insertFront([-1,0,0,8]);
    assert(array(c[]) == [-1,0,0,8,1,2,1,2,45,67,101]);
    c.insertBack([13,14]);
    assert(array(c[]) == [-1,0,0,8,1,2,1,2,45,67,101,13,14]);
    c.insertFront(-2);
    assert(array(c[]) == [-2,-1,0,0,8,1,2,1,2,45,67,101,13,14]);
    c.insertBack(15);
    assert(array(c[]) == [-2,-1,0,0,8,1,2,1,2,45,67,101,13,14,15]);
    assert(c.front() == -2);
    c.removeFront();
    assert(array(c[]) == [-1,0,0,8,1,2,1,2,45,67,101,13,14,15]);
    assert(c.front() == -1);
    assert(c.back() == 15);
    c.removeBack();
    assert(array(c[]) == [-1,0,0,8,1,2,1,2,45,67,101,13,14]);
    assert(c.back() == 14);
    c.removeAny();
    assert(array(c[]) == [-1,0,0,8,1,2,1,2,45,67,101,13]);
    auto r = c[];
    popFrontN(r, 6);
    auto t = take(r, 3);
    c.remove(t);
    assert(array(c[]) == [-1,0,0,8,1,2,67,101,13]);
    r = c[];
    popFrontN(r, 7);
    c.remove(r);
    assert(array(c[]) == [-1,0,0,8,1,2,67]);

    r = c[];
    while(!r.empty){
        if (r.front() < 2) r.removeFront();
        else r.popFront();
    }
    assert(array(c[]) == [8,2,67]);
    r = c[];
    while(!r.empty){
        if (r.back() < 3) r.removeBack();
        else r.popBack();
    }
    assert(array(c[]) == [8,67]);
    c.insertFront([1,5,223,9,10]);
    assert(array(c[]) == [1,5,223,9,10,8,67]);
    r = c[];
    while(!r.empty){
        if(r.front % 2) c.modify(r, (ref int i){ i = -i; });
        r.popFront();
    }
    assert(array(c[]) == [-1,-5,-223,-9,10,8,-67]);
    auto rr = retro(c[]);
    while(!rr.empty){
        if(rr.front % 3) c.modify(rr, (ref int i){ i = -i; });
        rr.popFront();
    }
    assert(array(c[]) == [1,5,223,-9,-10,-8,67]);

}

unittest{
    // sequenced, sequenced
    alias MultiIndexContainer!(int, IndexedBy!(Sequenced!(), Sequenced!())) C1;

    C1 a = new C1;
    auto c = a.get_index!0;
    auto d = a.get_index!1;
    c.insert(1);
    c.insert(2);
    c.insert(1);
    c.insert(2);
    assert(array(c[]) == [1,2,1,2]);
    assert(array(d[]) == [1,2,1,2]);
    c.insert([45,67,101]);
    assert(array(c[]) == [1,2,1,2,45,67,101]);
    assert(array(d[]) == [1,2,1,2,45,67,101]);
    c.insertFront([-1,0,0,8]);
    assert(array(c[]) == [-1,0,0,8,1,2,1,2,45,67,101]);
    assert(array(d[]) == [1,2,1,2,45,67,101,-1,0,0,8]);
    c.insertBack([13,14]);
    assert(array(c[]) == [-1,0,0,8,1,2,1,2,45,67,101,13,14]);
    assert(array(d[]) == [1,2,1,2,45,67,101,-1,0,0,8,13,14]);
    c.insertFront(-2);
    assert(array(c[]) == [-2,-1,0,0,8,1,2,1,2,45,67,101,13,14]);
    assert(array(d[]) == [1,2,1,2,45,67,101,-1,0,0,8,13,14,-2]);
    c.insertBack(15);
    assert(array(c[]) == [-2,-1,0,0,8,1,2,1,2,45,67,101,13,14,15]);
    assert(array(d[]) == [1,2,1,2,45,67,101,-1,0,0,8,13,14,-2,15]);
    assert(c.front() == -2);
    assert(d.front() == 1);
    c.removeFront();
    assert(array(c[]) == [-1,0,0,8,1,2,1,2,45,67,101,13,14,15]);
    assert(array(d[]) == [1,2,1,2,45,67,101,-1,0,0,8,13,14,15]);
    assert(c.front() == -1);
    assert(d.front() == 1);
    assert(c.back() == 15);
    assert(d.back() == 15);
    c.removeBack();
    assert(array(c[]) == [-1,0,0,8,1,2,1,2,45,67,101,13,14]);
    assert(array(d[]) == [1,2,1,2,45,67,101,-1,0,0,8,13,14]);
    assert(c.back() == 14);
    assert(d.back() == 14);
    c.removeAny();
    assert(array(c[]) == [-1,0,0,8,1,2,1,2,45,67,101,13]);
    assert(array(d[]) == [1,2,1,2,45,67,101,-1,0,0,8,13]);
    auto r = c[];
    popFrontN(r, 6);
    auto t = take(r, 3);
    c.remove(t);
    assert(array(c[]) == [-1,0,0,8,1,2,67,101,13]);
    assert(array(d[]) == [1,2,67,101,-1,0,0,8,13]);
    r = c[];
    popFrontN(r, 7);
    c.remove(r);
    assert(array(c[]) == [-1,0,0,8,1,2,67]);
    assert(array(d[]) == [1,2,67,-1,0,0,8]);

    r = c[];
    while(!r.empty){
        if (r.front() < 2) r.removeFront();
        else r.popFront();
    }
    assert(array(c[]) == [8,2,67]);
    assert(array(d[]) == [2,67,8]);
    auto r2 = d[];
    while(!r2.empty){
        if (r2.back() < 3) r2.removeBack();
        else r2.popBack();
    }
    assert(array(c[]) == [8,67]);
    assert(array(d[]) == [67,8]);
    c.insertFront([1,5,223,9,10]);
    assert(array(c[]) == [1,5,223,9,10,8,67]);
    assert(array(d[]) == [67,8,1,5,223,9,10]);
    r = c[];
    while(!r.empty){
        if(r.front % 2) c.modify(r, (ref int i){ i = -i; });
        r.popFront();
    }
    assert(array(c[]) == [-1,-5,-223,-9,10,8,-67]);
    assert(array(d[]) == [-67,8,-1,-5,-223,-9,10]);
    auto rr = retro(c[]);
    while(!rr.empty){
        if(rr.front % 3) c.modify(rr, (ref int i){ i = -i; });
        rr.popFront();
    }
    assert(array(c[]) == [1,5,223,-9,-10,-8,67]);
    assert(array(d[]) == [67,-8,1,5,223,-9,-10]);
}

void main(){}
