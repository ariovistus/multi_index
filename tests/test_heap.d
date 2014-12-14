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

class MyRecord{
    static MyRecord Duh(int i) {
        return new MyRecord(i);
    }
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

    override string toString() const{
        return format("Record(%s)", _i);
    }
}

template Testies(Allocator) {
unittest{
    // lone heap index
    alias MultiIndexContainer!(int, IndexedBy!(Heap!()), Allocator) C1;

    C1 c = new C1;
    c.insert(1);
    c.insert(2);
    c.insert(3);
    assert(c.front() == 3);
    c.insert([5,6,7]);
    assert(c.front() == 7);
    c.modify(takeOne(PSR(c[])), (ref int i){ i = 77; });
    assert(c.front() == 77);
    assert(filter!"a==7"(c[]).empty);
    c.modify(takeOne(PSR(c[])), (ref int i){ i = 0; });
    assert(c.front() == 6);
    auto r = c[];
    r.popFront();
    r.popFront();
    auto tmp = r.front;
    c.modify(takeOne(PSR(r)), (ref int i){ i = 80; });
    assert(c.front() == 80);
    c.removeFront();
    assert(c.front() == 6);
    c.insert(tmp); // was tmp 5? not sure, so put it back if it was
    auto t = take(PSR(c[]),1);
    c.remove(t);
    assert(c.front() == 5);
    assert(c.length == 5);
    foreach(i; 0 .. 5){
        c.removeBack();
    }
    assert(c.empty);
}

// again, but with immutable(int)
unittest{
    // lone heap index
    alias MultiIndexContainer!(immutable(int), IndexedBy!(Heap!()), Allocator) C1;

    C1 c = new C1;
    c.insert(1);
    c.insert(2);
    c.insert(3);
    assert(c.front() == 3);
    c.insert([5,6,7]);
    assert(c.front() == 7);
    writeln(c[]);
    auto r = c[];
    r.popFront();
    c.removeFront();
    auto tmp = r.front;
    assert(c.front() == 6);
    auto t = take(PSR(c[]),1);
    c.remove(t);
    assert(c.front() == 5);
    assert(c.length == 4);
    foreach(i; 0 .. 4){
        c.removeBack();
    }
    assert(c.empty);
}

unittest{
    // lone heap index helper
    alias MultiIndexContainer!(int, IndexedBy!(Heap!()), Allocator) C1;

    C1 d = new C1;
    auto c = d.get_index!0;
    c.insert(1);
    c.insert(2);
    c.insert(3);
    assert(c.front() == 3);
    c.insert([5,6,7]);
    assert(c.front() == 7);
    c.modify(takeOne(PSR(c[])), (ref int i){ i = 77; });
    assert(c.front() == 77);
    assert(filter!"a==7"(c[]).empty);
    c.modify(takeOne(PSR(c[])), (ref int i){ i = 0; });
    assert(c.front() == 6);
    auto r = c[];
    r.popFront();
    r.popFront();
    auto tmp = r.front;
    c.modify(takeOne(PSR(r)), (ref int i){ i = 80; });
    assert(c.front() == 80);
    c.removeFront();
    assert(c.front() == 6);
    c.insert(tmp); // was tmp 5? not sure, so put it back if it was
    auto t = take(PSR(c[]),1);
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
                Heap!("a", "a<b")), Allocator) C1;

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
    max.modify(takeOne(PSR(max[])), (ref int i){ i = 77; });
    assert(min.front() == 1);
    assert(max.front() == 77);
    assert(filter!"a==7"(min[]).empty);
    assert(filter!"a==7"(max[]).empty);
    max.modify(takeOne(PSR(max[])), (ref int i){ i = 0; });
    assert(min.front() == 0);
    assert(max.front() == 6);
    auto r = min[];
    r.popFront();
    r.popFront();
    auto tmp = r.front;
    min.modify(takeOne(PSR(r)), (ref int i){ i = 80; });
    assert(min.front() == 0);
    assert(max.front() == 80);
    max.removeFront();
    assert(max.front() == 6);
    min.insert(tmp); // was tmp 5? not sure, so put it back if it was
    auto t = take(PSR(max[]),1);
    max.remove(t);
    assert(max.front() == 5);
    assert(max.length == 5);
    foreach(i; 0 .. 5){
        max.removeBack();
    }
    assert(max.empty);
    assert(min.empty);
}


unittest{


    alias MultiIndexContainer!(MyRecord,
            IndexedBy!(Heap!("a.i","a>b")),
            // this tells MultiIndexContainer that you want
            // it to use the signal defined in MyRecord.
            // you just need to pass in the index number.
            ValueChangedSlots!(ValueSignal!(0)), 
            MutableView,
            Allocator,
            ) MyContainer;

    MyContainer c = new MyContainer;
    c.insert(map!(function(int i){return new MyRecord(i);})(iota(20)));

    writeln(c[]);

    MyRecord v = c.front();

    writefln("changing %s to %s", v._i, 22);

    v.i = 22; // v's position in c is automatically fixed
    writeln(c[]);
}

}

mixin Testies!(GCAllocator) a1;
mixin Testies!(MallocAllocator) a2;

