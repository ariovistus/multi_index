import multi_index;
import std.typecons;

alias MultiIndexContainer!(
    Tuple!(int*,"i",string,"k"), 
    IndexedBy!(HashedUnique!("a.i"), HashedUnique!("a.k")), 
) C;
