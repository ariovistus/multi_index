import multi_index;

// the following must give nice error messages.

// missing IndexedBy. 
//alias MultiIndexContainer!(int, OrderedUnique!()) C1;
// empty IndexedBy.
//alias MultiIndexContainer!(int, IndexedBy!()) C2;
// allocator in IndexedBy
//alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!(), MallocAllocator)) C3;
// constness view in IndexedBy
//alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!(), MutableView)) C4;
// too many constness views
//alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!()), MutableView, ConstView) C5;
// too many SignalOnChange
/+
alias MultiIndexContainer!(MyRecord,
            IndexedBy!(Heap!("a.i","a>b")),
            SignalOnChange!(ValueSignal!(0)), 
            SignalOnChange!(ValueSignal!(1)), 
            ) C6;
            +/
// too many allocators
//alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!()), GCAllocator, MallocAllocator) C7;
// something extraneous
//alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!()), int) C8;
// duplicate index names
alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!(), "a", Sequenced!(), "a")) C8;
void main(){
}

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
