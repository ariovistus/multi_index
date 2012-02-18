import std.stdio;
import std.algorithm;
import std.traits;
import std.range;
import multi_index;

unittest{
    // sequenced index only
    alias MultiIndexContainer!(int, IndexedBy!(Sequenced!())) C1;

    C1 c = new C1;
    c.insert(1);
    c.insert(2);
    c.insert(1);
    c.insert(2);
    assert(equal(c[], [1,2,1,2]));
    assert(c.toString0() == "[1, 2, 1, 2]");
    c.insert([45,67,101]);
    assert(equal(c[], [1,2,1,2,45,67,101]));
    c.insertFront([-1,0,0,8]);
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101]));
    c.insertBack([13,14]);
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101,13,14]));
    c.insertFront(-2);
    assert(equal(c[], [-2,-1,0,0,8,1,2,1,2,45,67,101,13,14]));
    c.insertBack(15);
    assert(equal(c[], [-2,-1,0,0,8,1,2,1,2,45,67,101,13,14,15]));
    assert(c.front() == -2);
    c.removeFront();
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101,13,14,15]));
    assert(c.front() == -1);
    assert(c.back() == 15);
    c.removeBack();
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101,13,14]));
    assert(c.back() == 14);
    c.removeAny();
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101,13]));
    auto r = c[];
    popFrontN(r, 6);
    auto t = take(r, 3);
    c.remove(t);
    assert(equal(c[], [-1,0,0,8,1,2,67,101,13]));
    r = c[];
    popFrontN(r, 7);
    c.remove(r);
    assert(equal(c[], [-1,0,0,8,1,2,67]));

    r = c[];
    while(!r.empty){
        if (r.front() < 2) r.removeFront();
        else r.popFront();
    }
    assert(equal(c[], [8,2,67]));
    r = c[];
    while(!r.empty){
        if (r.back() < 3) r.removeBack();
        else r.popBack();
    }
    assert(equal(c[], [8,67]));
    c.insertFront([1,5,223,9,10]);
    assert(equal(c[], [1,5,223,9,10,8,67]));
    r = c[];
    while(!r.empty){
        if(r.front % 2) c.modify(r, (ref int i){ i = -i; });
        r.popFront();
    }
    assert(equal(c[], [-1,-5,-223,-9,10,8,-67]));
    auto rr = retro(c[]);
    while(!rr.empty){
        if(rr.front % 3) c.modify(rr, (ref int i){ i = -i; });
        rr.popFront();
    }
    assert(equal(c[], [1,5,223,-9,-10,-8,67]));

    c.front = 4;
    assert(equal(c[], [4,5,223,-9,-10,-8,67]));
    c.back = 42;
    assert(equal(c[], [4,5,223,-9,-10,-8,42]));

}

unittest{
    // sequenced index only - mutable view
    alias MultiIndexContainer!(int, 
            IndexedBy!(Sequenced!()),
            MutableView,
            ) C1;

    C1 c = new C1;
    c.insert(1);
    c.insert(2);
    c.insert(1);
    c.insert(2);
    assert(equal(c[], [1,2,1,2]));
    c.insert([45,67,101]);
    assert(equal(c[], [1,2,1,2,45,67,101]));
    c.insertFront([-1,0,0,8]);
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101]));
    c.insertBack([13,14]);
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101,13,14]));
    c.insertFront(-2);
    assert(equal(c[], [-2,-1,0,0,8,1,2,1,2,45,67,101,13,14]));
    c.insertBack(15);
    assert(equal(c[], [-2,-1,0,0,8,1,2,1,2,45,67,101,13,14,15]));
    assert(c.front == -2);
    c.removeFront();
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101,13,14,15]));
    assert(c.front == -1);
    assert(c.back == 15);
    c.removeBack();
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101,13,14]));
    assert(c.back == 14);
    c.removeAny();
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101,13]));
    auto r = c[];
    popFrontN(r, 6);
    auto t = take(r, 3);
    c.remove(t);
    assert(equal(c[], [-1,0,0,8,1,2,67,101,13]));
    r = c[];
    popFrontN(r, 7);
    c.remove(r);
    assert(equal(c[], [-1,0,0,8,1,2,67]));

    r = c[];
    while(!r.empty){
        if (r.front() < 2) r.removeFront();
        else r.popFront();
    }
    assert(equal(c[], [8,2,67]));
    r = c[];
    while(!r.empty){
        if (r.back() < 3) r.removeBack();
        else r.popBack();
    }
    assert(equal(c[], [8,67]));
    c.insertFront([1,5,223,9,10]);
    assert(equal(c[], [1,5,223,9,10,8,67]));
    r = c[];
    while(!r.empty){
        if(r.front % 2) c.modify(r, (ref int i){ i = -i; });
        r.popFront();
    }
    assert(equal(c[], [-1,-5,-223,-9,10,8,-67]));
    auto rr = retro(c[]);
    while(!rr.empty){
        if(rr.front % 3) c.modify(rr, (ref int i){ i = -i; });
        rr.popFront();
    }
    assert(equal(c[], [1,5,223,-9,-10,-8,67]));

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
    assert(equal(c[], [1,2,1,2]));
    assert(equal(d[], [1,2,1,2]));
    c.insert([45,67,101]);
    assert(equal(c[], [1,2,1,2,45,67,101]));
    assert(equal(d[], [1,2,1,2,45,67,101]));
    c.insertFront([-1,0,0,8]);
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101]));
    assert(equal(d[], [1,2,1,2,45,67,101,-1,0,0,8]));
    c.insertBack([13,14]);
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101,13,14]));
    assert(equal(d[], [1,2,1,2,45,67,101,-1,0,0,8,13,14]));
    c.insertFront(-2);
    assert(equal(c[], [-2,-1,0,0,8,1,2,1,2,45,67,101,13,14]));
    assert(equal(d[], [1,2,1,2,45,67,101,-1,0,0,8,13,14,-2]));
    c.insertBack(15);
    assert(equal(c[], [-2,-1,0,0,8,1,2,1,2,45,67,101,13,14,15]));
    assert(equal(d[], [1,2,1,2,45,67,101,-1,0,0,8,13,14,-2,15]));
    assert(c.front() == -2);
    assert(d.front() == 1);
    c.removeFront();
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101,13,14,15]));
    assert(equal(d[], [1,2,1,2,45,67,101,-1,0,0,8,13,14,15]));
    assert(c.front() == -1);
    assert(d.front() == 1);
    assert(c.back() == 15);
    assert(d.back() == 15);
    c.removeBack();
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101,13,14]));
    assert(equal(d[], [1,2,1,2,45,67,101,-1,0,0,8,13,14]));
    assert(c.back() == 14);
    assert(d.back() == 14);
    c.removeAny();
    assert(equal(c[], [-1,0,0,8,1,2,1,2,45,67,101,13]));
    assert(equal(d[], [1,2,1,2,45,67,101,-1,0,0,8,13]));
    auto r = c[];
    popFrontN(r, 6);
    auto t = take(r, 3);
    c.remove(t);
    assert(equal(c[], [-1,0,0,8,1,2,67,101,13]));
    assert(equal(d[], [1,2,67,101,-1,0,0,8,13]));
    r = c[];
    popFrontN(r, 7);
    c.remove(r);
    assert(equal(c[], [-1,0,0,8,1,2,67]));
    assert(equal(d[], [1,2,67,-1,0,0,8]));

    r = c[];
    while(!r.empty){
        if (r.front() < 2) r.removeFront();
        else r.popFront();
    }
    assert(equal(c[], [8,2,67]));
    assert(equal(d[], [2,67,8]));
    auto r2 = d[];
    while(!r2.empty){
        if (r2.back() < 3) r2.removeBack();
        else r2.popBack();
    }
    assert(equal(c[], [8,67]));
    assert(equal(d[], [67,8]));
    c.insertFront([1,5,223,9,10]);
    assert(equal(c[], [1,5,223,9,10,8,67]));
    assert(equal(d[], [67,8,1,5,223,9,10]));
    r = c[];
    while(!r.empty){
        if(r.front % 2) c.modify(r, (ref int i){ i = -i; });
        r.popFront();
    }
    assert(equal(c[], [-1,-5,-223,-9,10,8,-67]));
    assert(equal(d[], [-67,8,-1,-5,-223,-9,10]));
    auto rr = retro(c[]);
    while(!rr.empty){
        if(rr.front % 3) c.modify(rr, (ref int i){ i = -i; });
        rr.popFront();
    }
    assert(equal(c[], [1,5,223,-9,-10,-8,67]));
    assert(equal(d[], [67,-8,1,5,223,-9,-10]));
}

unittest{
    class A{
        int i;
        int j;
        double d;

        this(int _i, int _j, double _d){
            i=_i; j=_j; d=_d;
        }

        bool opEquals(Object _a){
            A a = cast(A) _a;
            if (!a) return false;
            return i==a.i&&j==a.j&&d==a.d;
        }

        string toString()const{
            return format("%s %s %s", i,j,d);
        }
    }

    alias MultiIndexContainer!(A, IndexedBy!(Sequenced!())) C;

    C c = new C;

    c.insert(new A(1,2,3.4));
    c.insert(new A(4,2,4.2));
    c.insert(new A(10,20,42));
    assert(equal(c[], [new A(1,2,3.4), new A(4,2,4.2), new A(10,20,42)]));
    foreach(g; c[]){}
    auto r = c[];
    r.popFront();
    assert(equal(r.save(),[new A(4,2,4.2), new A(10,20,42)]));
    c.modify(r, (ref A a){ a.j = 55; a.d = 3.14; });
    assert(equal(c[], [new A(1,2,3.4), new A(4,55,3.14), new A(10,20,42)]));
    c.insertFront(new A(3,2,1.1));
    assert(equal(c[], [new A(3,2,1.1), new A(1,2,3.4), new A(4,55,3.14), 
            new A(10,20,42)]));
    c.insertFront([new A(3,2,1.1), new A(4,5,1.2)]);
    assert(equal(c[], [new A(3,2,1.1), new A(4,5,1.2), new A(3,2,1.1), 
            new A(1,2,3.4), new A(4,55,3.14), new A(10,20,42)]));
    c.front = new A(2,2,2.2);
    assert(equal(c[], [new A(2,2,2.2), new A(4,5,1.2), new A(3,2,1.1), 
            new A(1,2,3.4), new A(4,55,3.14), new A(10,20,42)]));
    c.back = cast() c.front;
    assert(equal(c[], [new A(2,2,2.2), new A(4,5,1.2), new A(3,2,1.1), 
            new A(1,2,3.4), new A(4,55,3.14), new A(2,2,2.2)]));
}

void main(){}
