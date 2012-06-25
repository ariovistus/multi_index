// mru example
// http://www.boost.org/doc/libs/1_48_0/libs/multi_index/example/serialization.cpp

import std.stdio;
import multi_index;


class MRU(T){
    alias MultiIndexContainer!(T, 
            IndexedBy!(Sequenced!(), HashedUnique!())) ItemList;
    
    ItemList itemlist;
    size_t max_num_items;

    void insert(T t){
        if(!itemlist.get_index!0 .insert(t)){
            auto r = itemlist.get_index!1 .equalRange(t);
            /// @@@BUG@@@ issue 6475 prevents this code from working
            /*ItemList.index!0 .Range*/auto r2 = itemlist.to_range!0(r);
            itemlist.get_index!0 .relocate(r2, itemlist[]);
        }else if(itemlist.length > max_num_items){
            itemlist.removeBack();
        }
    }
}

void main(){
    auto mru = new MRU!(string);
    while(true){
        writeln("Enter a term:");
        stdin.readln();
    }
}
