import multi_index;
import std.algorithm;
import std.file;
import std.regex;
import std.stdio;
import std.range;
import std.signals;
import std.string;

alias MultiIndexContainer!(string, 
        IndexedBy!(OrderedUnique!())) 
    StringSet;

struct Node{
    string name;
    StringSet children;
    StringSet parents;
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

    void removeParent(string pname){
        parents.remove(parents.equalRange(pname));
        emit();
    }

    void addParent(string pname){
        parents.insert(pname);
        emit();
    }

    void removeChild(string cname){
        children.remove(children.equalRange(cname));
        emit();
    }

    void addChild(string cname){
        children.insert(cname);
        emit();
    }

    size_t order()const{
        return children.length + parents.length;
    }

    string toString()const{
        return format("%s (%s)", name, order());
    }
}

alias MultiIndexContainer!(Node*,
        SignalOnChange!(ValueSignal!(1)),
        IndexedBy!(
            HashedUnique!("a.name"),
            Heap!("a.order()", "a>b"),
            OrderedUnique!("a.name")
            ),
        MutableView
        )
    NodeHeap;

void main(){
    NodeHeap heap = new NodeHeap();
    auto ihash = heap.get_index!0;
    auto iheap = heap.get_index!1;
    auto itree = heap.get_index!2;
    auto r = regex(r"\s*([^ ]+)\s*\(");
    foreach(string name; dirEntries("/home/ellery/dgraph/", SpanMode.depth)){
        File f = File(name);
        Node* n = new Node;
        n.children = new StringSet;
        n.parents = new StringSet;
        bool first = true;
        foreach(line; f.byLine()){
            auto m = match(line,r);
            if(!m.empty){
                string modle = m.captures()[1].idup;
                if(first){
                    n.name = modle;
                    first = false;
                    heap.index!0 .insert(n);
                    assert(ihash.contains(n));
                }else{
                    n.addChild(modle);
                }
            }
        }
    }
    writeln("heap: ",array(map!("cast(string) a.toString()")(iheap[])));
    writeln("_--------------------------------_");

    foreach(node; iheap[]){
        auto rng = (cast(Node*)node).children.opSlice();
        while(!rng.empty){
            auto modl = rng.front();
            if (!ihash.contains(modl) || modl == node.name){
                rng.removeFront();
                (cast(Node*)node).emit();
            }else{
                (cast(Node*)ihash.opIndex(modl)).addParent(node.name);
                rng.popFront();
            }
        }
    }
    auto count = 0;
    foreach(node; ihash[]){
        count++;
        /*
        foreach(modl; (cast(Node*)node).children[]){
            writefln(" imports %s", modl);
        }
        foreach(modl; (cast(Node*)node).parents[]){
            writefln(" imported %s", modl);
        }
        */
    }
    count = 0;
    
    while(!iheap.empty && iheap.front.order() <= 1){
        auto node = iheap.front();
        iheap.removeFront();
        writeln(node.toString());
        foreach(ch; (cast(Node*)node).children.index!(0).opSlice()){
            (cast(Node*)ihash[ch]).removeParent(node.name);
        }
        foreach(par; (cast(Node*)node).parents.index!(0).opSlice()){
            (cast(Node*)ihash[par]).removeChild(node.name);
        }
    }
    writeln("heap: ",array(map!("cast(string) a.toString()")(iheap[])));
}
