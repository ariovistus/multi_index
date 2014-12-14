import multi_index;
import std.stdio;

alias MultiIndexContainer!(int, IndexedBy!(RandomAccess!()), MallocAllocator) C;

class Destructable {
    void delegate() fn;
    // here's a cheap way to determine if we do any allocations in a function
    ~this() {
        fn();
    }
}

unittest {
    Destructable d = new Destructable();
    C container = new C();
    d.fn = { container.insert(1); };
}
unittest {
    Destructable d = new Destructable();
    C container = new C();
    container.insert(1);
    d.fn = { container.removeBack(); };
}
unittest {
    Destructable d = new Destructable();
    C container = new C();
    container.insert(1);
    d.fn = { container.replace(PSR(container[]).front, 2); };
}

