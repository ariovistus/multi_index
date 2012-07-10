// mru example
// http://www.boost.org/doc/libs/1_48_0/libs/multi_index/example/serialization.cpp

import std.stdio;
import multi_index;
import std.string: strip;


class MRU(T){
    alias MultiIndexContainer!(T, 
            IndexedBy!(Sequenced!(), "seq", 
                       HashedUnique!(), "hash")) ItemList;
    
    ItemList itemlist;
    size_t max_num_items;

    this(size_t maxitems) {
        itemlist = new ItemList;
        max_num_items = maxitems;
    }

    void insert(T t){
        if(!itemlist.seq.insert(t)){
            // todo: get equal range out of insert?
            auto r = itemlist.hash.equalRange(t); // get a ref to item t
            /// @@@BUG@@@ issue 6475 prevents this code from working
            /*ItemList.index!0 .Range*/auto r2 = itemlist.to_range!0(r); // in terms of seq
            itemlist.seq.relocateFront(r2, itemlist.seq[]); // move item t to front of seq
        }else if(itemlist.seq.length > max_num_items){
            itemlist.seq.removeBack();
        }
    }

    auto opSlice() {
        return itemlist.seq[];
    }
}

void main(){
    auto mru = new MRU!(string)(10);
    while(true){
        writeln("Enter a term:");
        string s = stdin.readln().strip();
        if(s == "done") {
            writeln(mru[]);
            break;
        }else{
            mru.insert(s);
        }
    }
}
