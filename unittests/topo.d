import multi_index;
import std.file;
import std.regex;
import std.stdio;
import std.range;

alias MultiIndexContainer!(string, 
        IndexedBy!(OrderedUnique!())) 
    StringSet;

struct Node{
    string name;
    StringSet children;
    StringSet parents;

    size_t order(){
        return children.length + parents.length;
    }
}

alias MultiIndexContainer!(Node*,
        IndexedBy!(
            HashedUnique!("a.name"),
            Heap!("a.order()"),
            )) 
    NodeHeap;

void main(){
    NodeHeap heap = new NodeHeap();
    auto r = regex(r"\s*([^ ]+)\s*\(");
    foreach(string name; dirEntries("/home/ellery/dgraph/", SpanMode.depth)){
        File f = File(name);
        Node* n = new Node;
        n.parents = new StringSet;
        n.children = new StringSet;
        bool first = true;
        foreach(line; f.byLine()){
            auto m = match(line,r);
            if(!m.empty){
                string modle = m.captures()[1].idup;
                if(first){
                    n.name = modle;
                    first = false;
                    heap.index!0 .insert(n);
                }else{
                    n.children.insert(modle);
                }
            }
        }
    }

    auto ihash = heap.get_index!0;
    auto iheap = heap.get_index!1;
    foreach(node; iheap[]){
        auto rng = (cast(Node*)node).children.opSlice();
        while(!rng.empty){
            auto modl = rng.front();
            if (!ihash.contains(modl) || modl == node.name){
                rng.removeFront();
            }else{
                (cast(Node*)ihash.opIndex(modl)).parents.insert(node.name);
                rng.popFront();
            }
        }
    }
    foreach(node; iheap[]){
        writefln("module: %s", node.name);
        foreach(modl; (cast(Node*)node).children[]){
            writefln(" imports %s", modl);
        }
        foreach(modl; (cast(Node*)node).parents[]){
            writefln(" imported %s", modl);
        }
    }
}
