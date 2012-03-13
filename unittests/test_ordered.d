
import std.stdio;
import std.range;
import std.algorithm;
import multi_index;

unittest{
    // ordered unique index only
    alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!())) C1;

    C1 c = new C1;
    c.insert(0);
    c.insert(2);
    c.check();
    c.insert(-1);
    assert(equal(c[], [-1,0,2]));
    c.insert([5,-5,10,-10]);
    assert(equal(c[], [-10,-5,-1,0,2,5,10]));
    c.insert(5);
    assert(equal(c[], [-10,-5,-1,0,2,5,10]));
    assert(c.front() == -10);
    assert(c.back() == 10);
    assert(10 in c);
    assert(c[10] == 10);
    assert(c.removeAny() == -10);
    c.removeFront();
    assert(equal(c[], [-1,0,2,5,10]));
    c.removeBack();
    assert(equal(c[], [-1,0,2,5]));
    c.removeKey(2);
    assert(equal(c[], [-1,0,5]));
    c.insert(iota(0,20,2));
    assert(equal(c[], [-1,0,2,4,5,6,8,10,12,14,16,18]));
    auto r = c[];
    foreach(j; iota(10)) r.popFront();
    c.remove(r);
    assert(equal(c[], [-1,0,2,4,5,6,8,10,12,14]));
    r = c[];
    auto t = take(r, 3);
    c.remove(t);
    assert(equal(c[], [4,5,6,8,10,12,14]));
    r = c.upperBound(10);
    c.remove(r);
    assert(equal(c[], [4,5,6,8,10]));
    r = c.upperBound(10);
    c.remove(r);
    assert(equal(c[], [4,5,6,8,10]));
    c.insert(iota(0,100,5));
    assert(array(c[]) == [0,4,5,6,8,10,15,20,25,30,35,40,45,50,55,60,65,70,
            75,80,85,90,95]);
    r = c.lowerBound(0);
    assert(equal(r, cast(ElementType!(typeof(r))[])[]));
    c.remove(r);
    assert(array(c[]) == [0,4,5,6,8,10,15,20,25,30,35,40,45,50,55,60,65,70,
            75,80,85,90,95]);
    r = c.lowerBound(24);
    c.remove(r);
    assert(equal(c[], [25,30,35,40,45,50,55,60,65,70,75,80,85,90,95]));
    r = c.equalRange(55);
    c.remove(r);
    assert(equal(c[], [25,30,35,40,45,50,60,65,70,75,80,85,90,95]));
    r = c.bounds!"[)"(30,50);
    assert(equal(r, [30,35,40,45]));
    c.remove(r);
    assert(equal(c[], [25,50,60,65,70,75,80,85,90,95]));
    r = c.bounds!"()"(50,51);
    assert(equal(r, cast(ElementType!(typeof(r))[])[]));
    r = c.bounds!"[]"(50,50);
    assert(equal(r, [50]));
    c.modify(r, (ref int i){ i = 150; });
    assert(equal(c[], [25,60,65,70,75,80,85,90,95,150]));
    r = c[];
    while(!r.empty){
        if(r.front % 10 == 5) r.removeFront();
        else r.popFront();
    }
    assert(equal(c[], [60,70,80,90,150]));
    r = c[];

    while(!r.empty){
        if(r.back % 20 == 10) r.removeBack();
        else r.popBack();
    }
    assert(equal(c[], [60,80]));
}

// tests for removeKey
unittest{
    alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!())) C1;
    {
    C1 c = new C1;
    c.insert(iota(20));
    assert(c.length == 20);
    assert(equal(c[], [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]));
    auto i = c.removeKey(0);
    assert(i == 1);
    assert(c.length == 19);
    i = c.removeKey(0);
    assert(i == 0);
    assert(c.length == 19);
    i = c.removeKey(1,0,1,0,2,0,4);
    assert(equal(c[], [3,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]));
    assert(i == 3);
    }

    alias MultiIndexContainer!(string, IndexedBy!(OrderedUnique!())) C2;
    {
    C2 c = new C2;
    c.insert(["a","g","b","c","z"]);
    assert(equal(c[], ["a","b","c","g","z"]));
    auto i = c.removeKey(["a","z"]);
    assert(i == 2);
    assert(equal(c[], ["b","c","g"]));
    i = c.removeKey(map!("a.toLower()")(["C","G"]));
    assert(i == 2);
    assert(equal(c[], ["b"]));
    }
    // tests from std.container
    {
    auto rbt = new C2;
    rbt.insert(["hello", "world", "foo", "bar"]);
    assert(equal(rbt[], ["bar", "foo", "hello", "world"]));
    assert(rbt.removeKey("hello") == 1);
    assert(equal(rbt[], ["bar", "foo", "world"]));
    assert(rbt.removeKey("hello") == 0);
    assert(equal(rbt[], ["bar", "foo", "world"]));
    assert(rbt.removeKey("hello", "foo", "bar") == 2);
    assert(equal(rbt[], ["world"]));
    assert(rbt.removeKey(["", "world", "hello"]) == 1);
    assert(rbt.empty);
    }
    {
    auto rbt = new C1;
    rbt.insert([1, 2, 12, 27, 4, 500]);
    assert(equal(rbt[], [1, 2, 4, 12, 27, 500]));
    assert(rbt.removeKey(1u) == 1);
    assert(equal(rbt[], [2, 4, 12, 27, 500]));
    assert(rbt.removeKey(cast(byte)1) == 0);
    assert(equal(rbt[], [2, 4, 12, 27, 500]));
    assert(rbt.removeKey(1, 12u, cast(byte)27) == 2);
    assert(equal(rbt[], [2, 4, 500]));
    assert(rbt.removeKey([cast(short)0, cast(short)500, cast(short)1]) == 1);
    assert(equal(rbt[], [2, 4]));
    }
    // end tests from std.container
    {
    alias MultiIndexContainer!(int, IndexedBy!(Sequenced!())) Ci;
    auto rbt = new C1;
    rbt.insert(iota(20));

    auto keys2 = new C1;
    auto keys = new Ci;
    keys.insert([17,18]);
    keys2.insert([1,2]);

    auto r = rbt.bounds!"[]"(4,15);
    auto i = rbt.removeKey(take(r,3)); 
    assert(i == 3);
    writeln(rbt[]);
    assert(equal(rbt[], [0,1,2,3,7,8,9,10,11,12,13,14,15,16,17,18,19]));
    i = rbt.removeKey(r); 
    assert(i == 9);
    assert(equal(rbt[], [0,1,2,3,16,17,18,19]));
    i = rbt.removeKey(keys[]); 
    assert(i == 2);
    assert(equal(rbt[], [0,1,2,3,16,19]));
    writeln(keys2[]);
    i = rbt.removeKey(keys2[]); 
    assert(i == 2);
    assert(equal(rbt[], [0,3,16,19]));
    }
}

unittest{
    // ordered unique, ordered nonunique
    alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!(), OrderedNonUnique!("-a"))) C1;

    C1 a = new C1;
    auto c = a.get_index!0;
    auto d = a.get_index!1;
    c.insert(0);
    c.insert(2);
    a.check();
    c.insert(-1);
    assert(equal(c[], [-1,0,2]));
    assert(equal(d[], [2,0,-1]));
    c.insert([5,-5,10,-10]);
    assert(equal(c[], [-10,-5,-1,0,2,5,10]));
    assert(equal(d[], [10,5,2,0,-1,-5,-10]));
    c.insert(5);
    assert(equal(c[], [-10,-5,-1,0,2,5,10]));
    assert(equal(d[], [10,5,2,0,-1,-5,-10]));
    assert(c.front() == -10);
    assert(c.back() == 10);
    assert(d.front() == 10);
    assert(d.back() == -10);
    assert(10 in c);
    assert(c[10] == 10);
    assert(c.removeAny() == -10);
    assert(d.removeAny() == 10);
    c.removeFront();
    assert(equal(c[], [-1,0,2,5]));
    assert(equal(d[], [5,2,0,-1]));
    c.removeBack();
    assert(equal(c[], [-1,0,2]));
    assert(equal(d[], [2,0,-1]));
    c.removeKey(2);
    assert(equal(c[], [-1,0]));
    assert(equal(d[], [0,-1]));
    c.insert(iota(0,20,2));
    assert(equal(c[], [-1,0,2,4,6,8,10,12,14,16,18]));
    assert(equal(d[], [18,16,14,12,10,8,6,4,2,0,-1]));
    auto r = c[];
    foreach(j; iota(10)) r.popFront();
    c.remove(r);
    assert(equal(c[], [-1,0,2,4,6,8,10,12,14,16]));
    assert(equal(d[], [16,14,12,10,8,6,4,2,0,-1]));
    r = c[];
    auto t = take(r, 3);
    c.remove(t);
    assert(equal(c[], [4,6,8,10,12,14,16]));
    assert(equal(d[], [16,14,12,10,8,6,4]));
    r = c.upperBound(10);
    c.remove(r);
    assert(equal(c[], [4,6,8,10]));
    assert(equal(d[], [10,8,6,4]));
    r = c.upperBound(10);
    c.remove(r);
    assert(equal(c[], [4,6,8,10]));
    assert(equal(d[], [10,8,6,4]));
    c.insert(iota(0,100,5));
    assert(array(c[]) == [0,4,5,6,8,10,15,20,25,30,35,40,45,50,55,60,65,70,
            75,80,85,90,95]);
    assert(array(d[]) == [95,90,85,80,75,70,65,60,55,50,45,40,
                    35,30,25,20,15,10,8,6,5,4,0]);
    r = c.lowerBound(0);
    assert(equal(r,cast(ElementType!(typeof(r))[])[]));
    c.remove(r);
    assert(array(c[]) == [0,4,5,6,8,10,15,20,25,30,35,40,45,50,55,60,65,70,
            75,80,85,90,95]);
    assert(array(d[]) == [95,90,85,80,75,70,65,60,55,50,45,40,
                    35,30,25,20,15,10,8,6,5,4,0]);
    r = c.lowerBound(24);
    c.remove(r);
    assert(array(c[]) == [25,30,35,40,45,50,55,60,65,70,
            75,80,85,90,95]);
    assert(array(d[]) == [95,90,85,80,75,70,65,60,55,50,45,40,
                    35,30,25]);
    r = c.equalRange(55);
    c.remove(r);
    assert(array(c[]) == [25,30,35,40,45,50,60,65,70,
            75,80,85,90,95]);
    assert(array(d[]) == [95,90,85,80,75,70,65,60,50,45,40,
                    35,30,25]);
    r = c.bounds!"[)"(30,50);
    assert(equal(r, [30,35,40,45]));
    c.remove(r);
    assert(equal(c[], [25,50,60,65,70,75,80,85,90,95]));
    assert(equal(d[], [95,90,85,80,75,70,65,60,50,25]));
    r = c.bounds!"()"(50,51);
    assert(equal(r, cast(ElementType!(typeof(r))[])[]));
    r = c.bounds!"[]"(50,50);
    assert(equal(r, [50]));
    c.modify(r, (ref int i){ i = 150; });
    assert(equal(c[], [25,60,65,70,75,80,85,90,95,150]));
    assert(equal(d[], [150,95,90,85,80,75,70,65,60,25]));
    r = c[];
    while(!r.empty){
        if(r.front % 10 == 5) r.removeFront();
        else r.popFront();
    }
    assert(equal(c[], [60,70,80,90,150]));
    assert(equal(d[], [150,90,80,70,60]));
    r = c[];

    while(!r.empty){
        if(r.back % 20 == 10) r.removeBack();
        else r.popBack();
    }
    assert(equal(c[], [60,80]));
    assert(equal(d[], [80,60]));
}

unittest{

    class MyRecord{
        int _i;

        this(int _j){ _i = _j; }

        @property int i()const{ return _i; }
        @property void i(int i1){
            _i = i1;
            emit(); // MultiIndexContainer is notified that this record's
            // position in indeces may need to be fixed
        }

        // signal impl - MultiIndexContainer will use these
        // to connect. In this example, we actually only need
        // a single slot. For a value type with M signals
        // (differentiated with mixin aliases), there will be
        // M slots connected.
        void delegate()[] slots;

        void connect(void delegate() slot){
            slots ~= slot;
        }
        void disconnect(void delegate() slot){
            size_t index = slots.length;
            foreach(i, slot1; slots){
                if(slot is slot1){
                    index = i;
                    moveAll(slots[i+1 .. $], slots[i .. $-1]);
                    slots.length-=1;
                    break;
                }
            }
        }
        void emit(){
            foreach(slot; slots){
                slot();
            }
        }

        string toString() const{
            return format("Record(%s)", _i);
        }
    }

    alias MultiIndexContainer!(MyRecord,
            IndexedBy!(OrderedUnique!("a.i")),
            // this tells MultiIndexContainer that you want
            // it to use the signal defined in MyRecord.
            // you just need to pass in the index number.
            SignalOnChange!(ValueSignal!(0)), 
            MutableView,
            ) MyContainer;

    MyContainer c = new MyContainer;

    c.insert(map!(a => new MyRecord(a))(iota(20)));

    writeln(c[]);

    auto a = c[];
    a.popFront();

    MyRecord v = c.front();

    writefln("changing %s to %s", v.i, 22);

    v.i = 22; // v's position in c is automatically fixed
    writeln(c[]);

    writefln("changing %s to %s", v.i, -1);
    v = c.back();
    v.i = -1;
    writeln(c[]);

}

void main(){}
