import multi_index;
import std.algorithm;
import std.stdio;

void example1() {
    class Value{
        int i;
        string s;
        this(int _i, string _s){
            i = _i;
            s = _s;
        }
    }
    alias MultiIndexContainer!(Value,
            IndexedBy!(RandomAccess!(), OrderedUnique!("a.s")),
            MutableView) C;

    C c = new C;
    auto i = c.get_index!0;

    i.insert(new Value(1,"a"));
    i.insert(new Value(2,"b"));
    i[1].s = "a";
    // this will assert
    //c.check();
}
void example2() {
    alias MultiIndexContainer!(int, IndexedBy!(OrderedNonUnique!())) C;
    C c = new C();
    auto rbt = c.get_index!0;
    rbt.insert([0, 1, 1, 1, 4, 5, 7]);
    rbt.removeKey(1, 4, 7);
    assert(std.algorithm.equal(rbt[], [0, 1, 1, 5]));
    rbt.removeKey(1, 1, 0);
    assert(std.algorithm.equal(rbt[], [5]));
}


void main() {
    example2();
}
