import multi_index;
import std.algorithm;
import std.stdio;
import std.algorithm;
import std.string;

class MyRecord{
    string _name; // first middle last

    this(string _j){ _name = _j; }

    invariant(){
        assert(count(_name, " ") == 2);
    }

    @property string name()const{ return _name; }
    @property void name(string i1){
        _name = i1;
        emit(); // MultiIndexContainer is notified that this record's
        // position in indeces may need to be fixed
    }

    // signal impl - MultiIndexContainer will use these
    // to connect. In this example, we actually [might] only need
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

    equals_t opEquals(Object o) {
        if (!cast(MyRecord) o) return false;
        return _name == (cast(MyRecord)o)._name;
    }
    string toString() const{
        return format("Record(%s)", _name);
    }
}

template Testies(Allocator) {


        template fun1(Container) {
            unittest{

                Container c = new Container;

                c.insert(new MyRecord("William T Garrard"));
                c.insert(new MyRecord("John-Jacob Jingleheimer Schmidt"));
                c.insert(new MyRecord("Karl Heinrich Marx"));  


                assert(equal(c[], [new MyRecord("John-Jacob Jingleheimer Schmidt"),
                            new MyRecord("Karl Heinrich Marx"),
                            new MyRecord("William T Garrard")]));

                MyRecord v = c.front();
                v.name = "Steven J Fox"; 
                assert(equal(c[], [
                            new MyRecord("Karl Heinrich Marx"),
                            new MyRecord("Steven J Fox"),
                            new MyRecord("William T Garrard")]));

            }
        }

        alias MultiIndexContainer!(MyRecord,
                IndexedBy!(OrderedUnique!("a.name")),
                SignalOnChange!(ValueSignal!(0)), 
                MutableView,
                Allocator,
                ) MyContainer1;
        mixin fun1!MyContainer1;

        alias MultiIndexContainer!(MyRecord,
                IndexedBy!(OrderedUnique!("a.name"), "sup"),
                SignalOnChange!(ValueSignal!("sup")), 
                MutableView,
                Allocator,
                ) MyContainer2;
        mixin fun1!MyContainer2;

        alias MultiIndexContainer!(MyRecord,
                IndexedBy!(OrderedUnique!("a.name")),
                SignalOnChange!(ValueSignal!("*")), 
                MutableView,
                Allocator,
                ) MyContainer3;
        mixin fun1!MyContainer3;

        alias MultiIndexContainer!(MyRecord,
                IndexedBy!(
                    OrderedUnique!("a.name"), "main",
                    OrderedNonUnique!(
                        function(a){return a.name.findSplit(" ")[0]; }), 
                    "first",
                    OrderedNonUnique!(
                        function(a){return a.name.findSplit(" ")[2].findSplit(" ")[0]; }), 
                    "middle",
                    OrderedNonUnique!(
                        function(a){return a.name.findSplit(" ")[2].findSplit(" ")[2]; }), 
                    "last",
                ),
                SignalOnChange!(ValueSignal!("*")), 
                MutableView,
                Allocator,
                ) MyContainer4;

        unittest {
            MyContainer4 c = new MyContainer4;

            auto john = new MyRecord("John James Albright");
            auto albert = new MyRecord("Albert Steven Moresley");
            auto glinda = new MyRecord("Glinda Dolores Philby");

            c.main.insert(john);
            c.main.insert(albert);
            c.main.insert(glinda);

            assert(equal(c.main[], [albert, glinda, john]));
            assert(equal(c.first[], [albert, glinda, john]));
            assert(equal(c.middle[], [glinda, john, albert]));
            assert(equal(c.last[], [john, albert, glinda]));

            auto x = c.main[].front;
            x.name = "Zalbert Cteven Zoresley";

            assert(equal(c.main[], [glinda, john, albert]));
            assert(equal(c.first[], [glinda, john, albert]));
            assert(equal(c.middle[], [albert,glinda, john]));
            assert(equal(c.last[], [john, glinda, albert]));

        }
}

mixin Testies!(GCAllocator) a1;
mixin Testies!(MallocAllocator) a2;
void main(){}
