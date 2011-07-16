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
    auto rng = iheap[];
    while(!rng.empty){
        auto node = rng.front;
        // grr
        if ((node.name) !in ihash){
            auto rng2 = takeOne(rng); 
            rng.popFront();
            iheap.remove(rng2);
        }else{
            rng.popFront();
        }
    }
}
