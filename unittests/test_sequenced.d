import std.stdio;
import std.algorithm;
import std.traits;
import std.range;
import multi_index;

template Testsies(Allocator) {
unittest{
    // sequenced index only
    alias MultiIndexContainer!(int, IndexedBy!(Sequenced!()),Allocator) C1;

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
    auto t = take(PSR(r), 3);
    c.remove(t);
    assert(equal(c[], [-1,0,0,8,1,2,67,101,13]));
    r = c[];
    popFrontN(r, 7);
    c.remove(r);
    assert(equal(c[], [-1,0,0,8,1,2,67]));
    c.remove(filter!"a.v < 2"(PSR(c[])));
    assert(equal(c[], [8,2,67]));
    c.remove(filter!"a.v < 3"(retro(PSR(c[]))));
    assert(equal(c[], [8,67]));
    c.insertFront([1,5,223,9,10]);
    assert(equal(c[], [1,5,223,9,10,8,67]));

    c.modify(filter!"a.v % 2 == 1"(PSR(c[])), 
            (ref int i) { i = -i; });
    /+
    r = c[];
    while(!r.empty){
        if(r.front % 2) c.modify(r, (ref int i){ i = -i; });
        r.popFront();
    }
    +/
    assert(equal(c[], [-1,-5,-223,-9,10,8,-67]));

    c.modify(filter!"a.v % 3 != 0"(retro(PSR(c[]))),
            (ref int i){ i = -i; });
    /+
    auto rr = retro(PSR(c[]));
    while(!rr.empty){
        if(rr.front.v % 3) c.modify(rr, (ref int i){ i = -i; });
        rr.popFront();
    }
    +/
    assert(equal(c[], [1,5,223,-9,-10,-8,67]));

    c.front = 4;
    assert(equal(c[], [4,5,223,-9,-10,-8,67]));
    c.back = 42;
    assert(equal(c[], [4,5,223,-9,-10,-8,42]));

}

// again, but for immutable(int)
unittest{
    // sequenced index only
    alias MultiIndexContainer!(immutable(int), IndexedBy!(Sequenced!()),Allocator) C1;

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
    auto t = take(PSR(r), 3);
    c.remove(t);
    assert(equal(c[], [-1,0,0,8,1,2,67,101,13]));
    r = c[];
    popFrontN(r, 7);
    c.remove(r);
    assert(equal(c[], [-1,0,0,8,1,2,67]));
    c.remove(filter!"a.v < 2"(PSR(c[])));
    assert(equal(c[], [8,2,67]));
    c.remove(filter!"a.v < 3"(retro(PSR(c[]))));
    assert(equal(c[], [8,67]));
    c.insertFront([1,5,223,9,10]);
    assert(equal(c[], [1,5,223,9,10,8,67]));

    c.front = 4;
    assert(equal(c[], [4,5,223,9,10,8,67]));
    c.back = 42;
    assert(equal(c[], [4,5,223,9,10,8,42]));

    auto posrng = PSR(c[]);
    auto replace_count = c.replace(posrng.front, 3);
    assert(replace_count == 1);
    assert(equal(c[], [3,5,223,9,10,8,42]));
    replace_count = c.replace(posrng.front, 3);
    assert(replace_count == 1);
    assert(equal(c[], [3,5,223,9,10,8,42]));

}

unittest{
    // sequenced index only - mutable view
    alias MultiIndexContainer!(int, 
            IndexedBy!(Sequenced!()),
            MutableView,
            Allocator,
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
    auto t = take(PSR(r), 3);
    c.remove(t);
    assert(equal(c[], [-1,0,0,8,1,2,67,101,13]));
    r = c[];
    popFrontN(r, 7);
    c.remove(r);
    assert(equal(c[], [-1,0,0,8,1,2,67]));
    c.remove(filter!"a.v < 2"(PSR(c[])));
    assert(equal(c[], [8,2,67]));
    c.remove(filter!"a.v < 3"(retro(PSR(c[]))));
    assert(equal(c[], [8,67]));
    c.insertFront([1,5,223,9,10]);
    assert(equal(c[], [1,5,223,9,10,8,67]));

    c.modify(filter!"a.v % 2 == 1"(PSR(c[])),
            (ref int i){ i = -i; });
    /+
    r = c[];
    while(!r.empty){
        if(r.front % 2) c.modify(r, (ref int i){ i = -i; });
        r.popFront();
    }
    +/

    assert(equal(c[], [-1,-5,-223,-9,10,8,-67]));
    c.modify(filter!"a.v % 3 != 0"(retro(PSR(c[]))),
            (ref int i){ i = -i; });
    /+
    auto rr = retro(PSR(c[]));
    while(!rr.empty){
        if(rr.front.v % 3) c.modify(rr, (ref int i){ i = -i; });
        rr.popFront();
    }
    +/
    assert(equal(c[], [1,5,223,-9,-10,-8,67]));

    auto posrng = PSR(c[]);
    auto replace_count = c.replace(posrng.front, 3);
    assert(replace_count == 1);
    assert(equal(c[], [3,5,223,-9,-10,-8,67]));
    replace_count = c.replace(posrng.front, 3);
    assert(replace_count == 1);
    assert(equal(c[], [3,5,223,-9,-10,-8,67]));

}

unittest{
    // sequenced, sequenced
    alias MultiIndexContainer!(int, IndexedBy!(Sequenced!(), Sequenced!()), Allocator) C1;

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
    auto t = take(PSR(r), 3);
    c.remove(t);
    assert(equal(c[], [-1,0,0,8,1,2,67,101,13]));
    assert(equal(d[], [1,2,67,101,-1,0,0,8,13]));
    r = c[];
    popFrontN(r, 7);
    c.remove(r);
    assert(equal(c[], [-1,0,0,8,1,2,67]));
    assert(equal(d[], [1,2,67,-1,0,0,8]));

    c.remove(filter!"a.v < 2"(PSR(c[])));
    assert(equal(c[], [8,2,67]));
    assert(equal(d[], [2,67,8]));
    c.remove(filter!"a.v < 3"(PSR(d[])));
    assert(equal(c[], [8,67]));
    assert(equal(d[], [67,8]));
    c.insertFront([1,5,223,9,10]);
    assert(equal(c[], [1,5,223,9,10,8,67]));
    assert(equal(d[], [67,8,1,5,223,9,10]));
    c.modify(filter!"a.v % 2 == 1"(PSR(c[])), 
            (ref int i) { i = -i; });
    /+
    r = c[];
    while(!r.empty){
        if(r.front % 2) c.modify(r, (ref int i){ i = -i; });
        r.popFront();
    }
    +/
    assert(equal(c[], [-1,-5,-223,-9,10,8,-67]));
    assert(equal(d[], [-67,8,-1,-5,-223,-9,10]));
    c.modify(filter!"a.v % 3 != 0"(retro(PSR(c[]))),
            (ref int i){ i = -i; });
    /+
    auto rr = retro(PSR(c[]));
    while(!rr.empty){
        if(rr.front.v % 3) c.modify(rr, (ref int i){ i = -i; });
        rr.popFront();
    }
    +/
    assert(equal(c[], [1,5,223,-9,-10,-8,67]));
    assert(equal(d[], [67,-8,1,5,223,-9,-10]));

    auto posrng = PSR(c[]);
    auto replace_count = c.replace(posrng.front, 3);
    assert(replace_count == 1);
    assert(equal(c[], [3,5,223,-9,-10,-8,67]));
    assert(equal(d[], [67,-8,3,5,223,-9,-10]));

    replace_count = c.replace(posrng.front, 3);
    assert(replace_count == 1);
    assert(equal(c[], [3,5,223,-9,-10,-8,67]));
    assert(equal(d[], [67,-8,3,5,223,-9,-10]));

    auto posrng2 = PSR(d[]);
    replace_count = d.replace(posrng2.front, 69);
    assert(replace_count == 1);
    assert(equal(c[], [3,5,223,-9,-10,-8,69]));
    assert(equal(d[], [69,-8,3,5,223,-9,-10]));

    replace_count = d.replace(posrng2.front, 69);
    assert(replace_count == 1);
    assert(equal(c[], [3,5,223,-9,-10,-8,69]));
    assert(equal(d[], [69,-8,3,5,223,-9,-10]));

    replace_count = c.replace(posrng2.front, 70);
    assert(replace_count == 1);
    assert(equal(c[], [3,5,223,-9,-10,-8,70]));
    assert(equal(d[], [70,-8,3,5,223,-9,-10]));

    replace_count = c.replace(posrng2.front, 70);
    assert(replace_count == 1);
    assert(equal(c[], [3,5,223,-9,-10,-8,70]));
    assert(equal(d[], [70,-8,3,5,223,-9,-10]));
}

// again, but with immutable(int)
unittest{
    // sequenced, sequenced
    alias MultiIndexContainer!(immutable(int), IndexedBy!(Sequenced!(), Sequenced!()), Allocator) C1;

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
    auto t = take(PSR(r), 3);
    c.remove(t);
    assert(equal(c[], [-1,0,0,8,1,2,67,101,13]));
    assert(equal(d[], [1,2,67,101,-1,0,0,8,13]));
    r = c[];
    popFrontN(r, 7);
    c.remove(r);
    assert(equal(c[], [-1,0,0,8,1,2,67]));
    assert(equal(d[], [1,2,67,-1,0,0,8]));

    c.remove(filter!"a.v < 2"(PSR(c[])));
    assert(equal(c[], [8,2,67]));
    assert(equal(d[], [2,67,8]));
    c.remove(filter!"a.v < 3"(PSR(d[])));
    assert(equal(c[], [8,67]));
    assert(equal(d[], [67,8]));
    c.insertFront([1,5,223,9,10]);
    assert(equal(c[], [1,5,223,9,10,8,67]));
    assert(equal(d[], [67,8,1,5,223,9,10]));

    auto posrng = PSR(c[]);
    auto replace_count = c.replace(posrng.front, 3);
    assert(replace_count == 1);
    assert(equal(c[], [3,5,223,9,10,8,67]));
    assert(equal(d[], [67,8,3,5,223,9,10]));

    auto rng2 = d[];
    auto posrng2 = PSR(rng2);
    assert(!posrng2.empty);
    assert(!rng2.empty);
    replace_count = c.replace(posrng2.front, 69);
    assert(replace_count == 1);
    assert(equal(c[], [3,5,223,9,10,8,69]));
    assert(equal(d[], [69,8,3,5,223,9,10]));

    replace_count = d.replace(posrng2.front, 69);
    assert(replace_count == 1);
    assert(equal(c[], [3,5,223,9,10,8,69]));
    assert(equal(d[], [69,8,3,5,223,9,10]));

    rng2.popFront();
    posrng2.popFront();
    assert(!rng2.empty);
    assert(!posrng2.empty);
    replace_count = d.replace(posrng2.front, 7);
    assert(equal(c[], [3,5,223,9,10,7,69]));
    assert(equal(d[], [69,7,3,5,223,9,10]));
}

unittest{
    class A{
        int i;
        int j;
        double d;

        this(int _i, int _j, double _d){
            i=_i; j=_j; d=_d;
        }

        override bool opEquals(Object _a){
            A a = cast(A) _a;
            if (!a) return false;
            return i==a.i&&j==a.j&&d==a.d;
        }

        override string toString()const{
            return format("%s %s %s", i,j,d);
        }
    }

    alias MultiIndexContainer!(A, IndexedBy!(Sequenced!()), Allocator) C;

    C c = new C;

    c.insert(new A(1,2,3.4));
    c.insert(new A(4,2,4.2));
    c.insert(new A(10,20,42));
    assert(equal(c[], [new A(1,2,3.4), new A(4,2,4.2), new A(10,20,42)]));
    foreach(g; c[]){}
    auto r = c[];
    r.popFront();
    assert(equal(r.save(),[new A(4,2,4.2), new A(10,20,42)]));
    c.modify(takeOne(PSR(r)), (ref A a){ a.j = 55; a.d = 3.14; });
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

    auto posrng = PSR(c[]);
    auto replace_count = c.replace(posrng.back, new A(7,3,67.4));
    assert(replace_count == 1);
    assert(equal(c[], [new A(2,2,2.2), new A(4,5,1.2), new A(3,2,1.1), 
            new A(1,2,3.4), new A(4,55,3.14), new A(7,3,67.4)]));

    replace_count = c.replace(posrng.back, new A(7,3,67.4));
    assert(replace_count == 1);
    assert(equal(c[], [new A(2,2,2.2), new A(4,5,1.2), new A(3,2,1.1), 
            new A(1,2,3.4), new A(4,55,3.14), new A(7,3,67.4)]));

    alias MultiIndexContainer!(A, IndexedBy!(Sequenced!()), Allocator, MutableView) C2;

    C2 c2 = new C2();
    c2.insert(new A(1,2,3.4));
    c2.front.j = 4;
    c2[].front.j = 5;
    c2.back.j = 6;
    c2[].back.j = 7;
}

// again, but with immutable(A)
unittest{
    class _A{
        int i;
        int j;
        double d;

        this(int _i, int _j, double _d){
            i=_i; j=_j; d=_d;
        }

        override bool opEquals(Object _a){
            _A a = cast(_A) _a;
            if (!a) return false;
            return i==a.i&&j==a.j&&d==a.d;
        }

        override string toString()const{
            return format("%s %s %s", i,j,d);
        }
    }

    alias immutable(_A) A;
    alias MultiIndexContainer!(A, IndexedBy!(Sequenced!()), Allocator) C;

    C c = new C;

    c.insert( cast(immutable) new _A(1,2,3.4));
    c.insert( cast(immutable) new _A(4,2,4.2));
    c.insert( cast(immutable) new _A(10,20,42));
    assert(equal(c[], [cast(immutable) new _A(1,2,3.4), cast(immutable) new _A(4,2,4.2), cast(immutable) new _A(10,20,42)]));
    foreach(g; c[]){}
    auto r = c[];
    r.popFront();
    assert(equal(r.save(),[cast(immutable) new _A(4,2,4.2), cast(immutable) new _A(10,20,42)]));

    c.insertFront(cast(immutable) new _A(3,2,1.1));
    assert(equal(c[], [cast(immutable) new _A(3,2,1.1), cast(immutable) new _A(1,2,3.4), cast(immutable) new _A(4,2,4.2), 
            cast(immutable) new _A(10,20,42)]));
    c.insertFront([cast(immutable) new _A(3,2,1.1), cast(immutable) new _A(4,5,1.2)]);
    assert(equal(c[], [cast(immutable) new _A(3,2,1.1), cast(immutable) new _A(4,5,1.2), cast(immutable) new _A(3,2,1.1), 
            cast(immutable) new _A(1,2,3.4), cast(immutable) new _A(4,2,4.2), cast(immutable) new _A(10,20,42)]));
    c.front = cast(immutable) new _A(2,2,2.2);
    assert(equal(c[], [cast(immutable) new _A(2,2,2.2), cast(immutable) new _A(4,5,1.2), cast(immutable) new _A(3,2,1.1), 
            cast(immutable) new _A(1,2,3.4), cast(immutable) new _A(4,2,4.2), cast(immutable) new _A(10,20,42)]));
    c.back = c.front;
    assert(equal(c[], [cast(immutable) new _A(2,2,2.2), cast(immutable) new _A(4,5,1.2), cast(immutable) new _A(3,2,1.1), 
            cast(immutable) new _A(1,2,3.4), cast(immutable) new _A(4,2,4.2), cast(immutable) new _A(2,2,2.2)]));

    auto posrng = PSR(c[]);
    auto replace_count = c.replace(posrng.back, cast(immutable) new _A(7,3,67.4));
    assert(replace_count == 1);
    assert(equal(c[], [cast(immutable) new _A(2,2,2.2), cast(immutable) new _A(4,5,1.2), cast(immutable) new _A(3,2,1.1), 
            cast(immutable) new _A(1,2,3.4), cast(immutable) new _A(4,2,4.2), cast(immutable) new _A(7,3,67.4)]));

    replace_count = c.replace(posrng.back, cast(immutable) new _A(7,3,67.4));
    assert(replace_count == 1);
    assert(equal(c[], [cast(immutable) new _A(2,2,2.2), cast(immutable) new _A(4,5,1.2), cast(immutable) new _A(3,2,1.1), 
            cast(immutable) new _A(1,2,3.4), cast(immutable) new _A(4,2,4.2), cast(immutable) new _A(7,3,67.4)]));


}

// test rearrangement 
unittest{
    alias MultiIndexContainer!(int, IndexedBy!(Sequenced!()),Allocator) C1;

    C1 c = new C1;
    c.insert(iota(20));
    auto r = c[];
    while(r.empty == false){
        if(r.front() % 2 == 1){
            c.relocateFront(r,c[]);
        }else{
            r.popFront();
        }
    }
    assert(equal(c[], [19,17,15,13,11,9,7,5,3,1,0,2,4,6,8,10,12,14,16,18]));

    c.clear();
    c.insert(iota(20));
    r = c[];
    while(r.empty == false){
        if(r.front() % 2 == 0){
            c.relocateFront(r,c[]);
        }else{
            r.popFront();
        }
    }
    assert(equal(c[], [18,16,14,12,10,8,6,4,2,0,1,3,5,7,9,11,13,15,17,19]));
    auto c0 = array(c[]);

    {
        r = drop(c[],19);
        auto r2 = drop(c[],4);

        assert(equal(r,[19]));
        assert(equal(r2,[10,8,6,4,2,0,1,3,5,7,9,11,13,15,17,19]));

        c.relocateFront(r2,r);
        assert(equal(c[], [18,16,14,12,8,6,4,2,0,1,3,5,7,9,11,13,15,17,10,19]));
        assert(equal(r,[19]));
        assert(equal(r2,[8,6,4,2,0,1,3,5,7,9,11,13,15,17,10,19]));
        c.relocateFront(r2,r);
        assert(equal(c[], [18,16,14,12,6,4,2,0,1,3,5,7,9,11,13,15,17,10,8,19]));
        assert(equal(r,[19]));
        assert(equal(r2,[6,4,2,0,1,3,5,7,9,11,13,15,17,10,8,19]));
        popBackN(r2,5);
        assert(equal(r2,[6,4,2,0,1,3,5,7,9,11,13]));
        c.relocateBack(r2,r);
        assert(equal(c[], [18,16,14,12,6,4,2,0,1,3,5,7,9,11,15,17,10,8,19,13]));
        assert(equal(r2,[6,4,2,0,1,3,5,7,9,11]));
        assert(equal(r,[19]));
    }


    alias MultiIndexContainer!(int, IndexedBy!(Sequenced!(),OrderedUnique!()),Allocator) C2;

    C2 z = new C2;
    auto z0 = z.get_index!0;
    auto z1 = z.get_index!1;
    z0.insert(c0);
    assert(equal(z0[],[18,16,14,12,10,8,6,4,2,0,1,3,5,7,9,11,13,15,17,19]));
    assert(equal(z1[],iota(20)));
    /+
    auto r2 = z1.upperBound(0); // should be called aboveBound?!
    auto r3 = z.to_range!0(r2);
    assert(equal(r3, [1,3,5,7,9,11,13,15,17,19]));
    +/
}

// again, but with immutable(int)
unittest{
    alias MultiIndexContainer!(immutable(int), IndexedBy!(Sequenced!()),Allocator) C1;

    C1 c = new C1;
    c.insert(iota(20));
    auto r = c[];
    while(r.empty == false){
        if(r.front() % 2 == 1){
            c.relocateFront(r,c[]);
        }else{
            r.popFront();
        }
    }
    assert(equal(c[], [19,17,15,13,11,9,7,5,3,1,0,2,4,6,8,10,12,14,16,18]));

    c.clear();
    c.insert(iota(20));
    r = c[];
    while(r.empty == false){
        if(r.front() % 2 == 0){
            c.relocateFront(r,c[]);
        }else{
            r.popFront();
        }
    }
    assert(equal(c[], [18,16,14,12,10,8,6,4,2,0,1,3,5,7,9,11,13,15,17,19]));
    auto c0 = array(c[]);

    {
        r = drop(c[],19);
        auto r2 = drop(c[],4);

        assert(equal(r,[19]));
        assert(equal(r2,[10,8,6,4,2,0,1,3,5,7,9,11,13,15,17,19]));

        c.relocateFront(r2,r);
        assert(equal(c[], [18,16,14,12,8,6,4,2,0,1,3,5,7,9,11,13,15,17,10,19]));
        assert(equal(r,[19]));
        assert(equal(r2,[8,6,4,2,0,1,3,5,7,9,11,13,15,17,10,19]));
        c.relocateFront(r2,r);
        assert(equal(c[], [18,16,14,12,6,4,2,0,1,3,5,7,9,11,13,15,17,10,8,19]));
        assert(equal(r,[19]));
        assert(equal(r2,[6,4,2,0,1,3,5,7,9,11,13,15,17,10,8,19]));
        popBackN(r2,5);
        assert(equal(r2,[6,4,2,0,1,3,5,7,9,11,13]));
        c.relocateBack(r2,r);
        assert(equal(c[], [18,16,14,12,6,4,2,0,1,3,5,7,9,11,15,17,10,8,19,13]));
        assert(equal(r2,[6,4,2,0,1,3,5,7,9,11]));
        assert(equal(r,[19]));
    }


    alias MultiIndexContainer!(int, IndexedBy!(Sequenced!(),OrderedUnique!()),Allocator) C2;

    C2 z = new C2;
    auto z0 = z.get_index!0;
    auto z1 = z.get_index!1;
    z0.insert(c0);
    assert(equal(z0[],[18,16,14,12,10,8,6,4,2,0,1,3,5,7,9,11,13,15,17,19]));
    assert(equal(z1[],iota(20)));
    /+
    auto r2 = z1.upperBound(0); // should be called aboveBound?!
    auto r3 = z.to_range!0(r2);
    assert(equal(r3, [1,3,5,7,9,11,13,15,17,19]));
    +/
}
}

mixin Testsies!(GCAllocator) X;
mixin Testsies!(MallocAllocator) Y;



void main(){}
