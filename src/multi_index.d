/**
A port of Joaquin M Lopez Munoz' _multi_index library.

Source: something somewhere?
Macros: 
TEXTWITHCOMMAS = $0
Copyright: Red-black tree code copyright (C) 2008- by Steven Schveighoffer. 
Other code copyright 2011- Ellery Newcomer. 
All rights reserved by the respective holders.

License: Distributed under the Boost Software License, Version 1.0.
(See accompanying file LICENSE_1_0.txt or copy at $(WEB
boost.org/LICENSE_1_0.txt)).

Authors: Steven Schveighoffer, Ellery Newcomer

Introduction:
A standard container maintains its elements in a specific structure which 
allows it to offer interesting or useful access to its elements. However,
sometimes a programmer needs functionality which is not offered by a single
collection type. Faced with such a need, a programmer must maintain auxiliary 
containers, either of duplicated elements or of pointers to elements of the 
primary container.
In either solution, keeping the parallel containers synchronized quickly 
becomes a pain, and may introduce inefficiencies in time or memory complexity.

Into this use case steps multi_index. It allows the user to specify multiple
<i>indeces</i> on the container elements, each of which provides interesting
access functionality. A multi_index container will automatically keep all 
indeces synchronized over any insertion, removal, or replacement operation 
performed on any one index.  Each index must define how to perform auxiliary 
insertion, removal, and replacement, 
which may have equal or better time complexity than those exposed to the user.

Each index will typically require ($(D N * ptrsize * k)) additional bytes of 
memory, for some k < 4

The following index types are provided:
$(BOOKTABLE,

$(TR $(TH Index) $(TH Description))

$(TR $(TDNW $(D Sequenced)) $(TD Provides a doubly linked list view - exposes 
fast access to the front and back of the index.  Default insertion inserts to 
the back of the index $(BR)

$(TEXTWITHCOMMAS Usage:)
-----
alias MultiIndexContainer!(int, IndexedBy!(Sequenced!(), ...)) C;
C c = new C;
c.index!0 .insert(0); // access the index directly (operator overloads won't work here)
c.index!0 .insert(1);
auto i0 = c.get_index!0; // or via a helper class (recommended)
assert(array(i0[]) == [0,1]); // assumes no index refused these elements
i0.insertFront([3,4,5]);
assert(array(i0[]) == [3,4,5,0,1]); // ditto
i0.removeAny();
assert(array(i0[]) == [3,4,5,0]);
i0.removeFront();
assert(array(i0[]) == [4,5,0]);
-----
$(TEXTWITHCOMMAS Complexities:)
$(BOOKTABLE, $(TR $(TH) $(TH))
$(TR $(TD Insertion) $(TD $(TEXTWITHCOMMAS 
i(n) = 1 for front and back insertion
))) 
$(TR $(TD Removal) $(TD $(TEXTWITHCOMMAS 
d(n) = 1 for front, back, and auxiliary removal
)))
$(TR $(TD Replacement) $(TD $(TEXTWITHCOMMAS 
r(n) = 1 for auxiliary replacement 
))))

))

$(TR $(TDNW $(D RandomAccess)) $(TD Provides a random access view - exposes an
array-like access to container elements. Default insertion inserts to the back of the index $(BR)

$(TEXTWITHCOMMAS Complexities:)
$(BOOKTABLE, $(TR $(TH) $(TH))
$(TR $(TD Insertion) $(TD $(TEXTWITHCOMMAS 
i(n) = 1 (amortized) for back insertion, n otherwise 
))) 
$(TR $(TD Removal) $(TD $(TEXTWITHCOMMAS 
d(n) = 1 for back removal, n otherwise 
)))
$(TR $(TD Replacement) $(TD $(TEXTWITHCOMMAS 
r(n) = 1 
))))

))

$(TR $(TDNW $(D Ordered, OrderedUnique, OrderedNonUnique)) $(TD Provides a 
red black tree view - keeps container elements in order defined by predicates 
KeyFromValue and Compare. 
Unique variant will cause the container to refuse 
insertion of an item if an equivalent item already exists in the container.

$(TEXTWITHCOMMAS Complexities:)
$(BOOKTABLE, $(TR $(TH) $(TH))
$(TR $(TD Insertion) $(TD $(TEXTWITHCOMMAS 
i(n) = log(n) $(BR)
))) 
$(TR $(TD Removal) $(TD $(TEXTWITHCOMMAS 
d(n) = log(n) $(BR)
)))
$(TR $(TD Replacement) $(TD $(TEXTWITHCOMMAS 
r(n) = 1 if the element's position does not change, log(n) otherwise 
))))

))

$(TR $(TDNW $(D Hashed, HashedUnique, HashedNonUnique)) $(TD Provides a 
hash table view - exposes fast access to every element of the container, 
given key defined by predicates KeyFromValue, Hash, and Eq.
Unique variant will cause the container to refuse 
insertion of an item if an equivalent item already exists in the container.

$(TEXTWITHCOMMAS Complexities:)
$(BOOKTABLE, $(TR $(TH) $(TH))
$(TR $(TD Insertion) $(TD $(TEXTWITHCOMMAS 
i(n) = 1 average, n worst case $(BR)
))) 
$(TR $(TD Removal) $(TD $(TEXTWITHCOMMAS 
d(n) = 1 for auxiliary removal, otherwise 1 average, n worst case $(BR)
)))
$(TR $(TD Replacement) $(TD $(TEXTWITHCOMMAS 
r(n) = 1 if the element's position does not change, log(n) otherwise 
))))

))

$(TR $(TDNW $(D Heap)) $(TD Provides a max heap view - exposes fast access to 
the largest element in the container as defined by predicates KeyFromValue 
and Compare.

Complexity

i(n) = log(n) $(BR)
d(n) = log(n) $(BR)
r(n) = 1 if the element's position does not change, log(N) otherwise $(BR)))

)

Mutability:
Providing multiple indeces to the same data does introduce some complexities, 
though. Consider:
-----
alias MultiIndexContainer!(Tuple!(int,string), IndexedBy!(RandomAccess!(), OrderedUnique!("a[1]"))) C;

C c = new C;

c.insert(tuple(1,"a"));
c.insert(tuple(2,"b"));

c[1][1] = "a"; // bad! index 1 now contains duplicates and is in invalid state! 
-----
In general, the container must either require the user 
not to perform any damning operation on its elements (which likely will entail 
paranoid and continual checking of the validity of its indeces), or else not 
provide a mutable view of its elements. multi_index chooses the latter.

For operations which are sure not to invalidate any index, one might simply 
cast away the constness of the returned element, as elements are not stored 
with special constness, though we don't recommended this on the grounds of
aesthetics (it's ew) and maintainability (if the code changes, it's a ticking 
time bomb).

Otherwise, the user must be limited to modification operations which the 
indeces can detect and perform any fixups for (or possibly reject). Currently 
that's remove/modify/insert (todo: boost::_multi_index exposes per-index 
replace and modify functions - shall 
we provide these also? issue: modify exposes a reference to container's 
elements) 

Efficiency:

To draw on an example from boost::_multi_index, suppose a collection of 
Tuple!(int,int) needs to be kept in sorted order by both elements of the tuple.
This might be accomplished by the following:
------
import std.container;
alias RedBlackTree!(Tuple!(int,int), "a[0] < b[0]") T1;
alias RedBlackTree!(Tuple!(int,int)*, "(*a)[1] < (*b)[1]") T2;

T1 tree1;
T2 tree2;
------

Insertion remains straightforward
------
tree1.insert(item);
tree2.insert(&item);
------
However removal introduces some inefficiency
------
tree1.remove(item);
tree2.remove(&item); // requires a log(n) search, followed by a potential log(n) rebalancing
------
Munoz suggests making the element type of T2 an iterator of T1 for to obviate
the need for the second search. However, this is not possible in D, as D 
espouses ranges rather than indeces. (As a side note, Munoz proceeds to point 
out that the iterator solution will require at minimum (N * ptrsize) more bytes 
of memory than will _multi_index, so we needn't lament over this fact.)

Our approach:
------
alias MultiIndexContainer!(Tuple!(int,int), 
        IndexedBy!(OrderedUnique!("a[0]"), 
            OrderedUnique!("a[1]"))) T;

T t = new T;
------

makes insertion and removal somewhat simpler:

------
t.insert(item);
t.remove(item);
------

and removal will not perform a log(n) search on the second index 
(rebalancing can't be avoided).


 */
module multi_index;

/**
 * TODO:
 *  ordered index
 *   opIndex, opIndexAssign
 *   compatible sorting criteria
 *   move semantics?
 *   special constructor for SortedRange?
 *   KeyRange ?
 *  random access index
 *   insertAfter ? insertBefore ?
 *   move semantics ?
 *  hashed index
 *  tagging
 *  other indeces? sparse matrix? heap?
 *  allocation?
 *  dup
 *  make reserve perform reserve on all appropriate indeces?
 *  replace functionality
 *  clear functionality
 *  op ~ 
 */

import std.array;
import std.range;
import std.exception: enforce;
import std.algorithm: find, swap, copy, fill, max;
import std.traits: isImplicitlyConvertible;
import std.metastrings: Format, toStringNow;
import replace: Replace;
import std.typetuple: TypeTuple;
import std.functional: unaryFun, binaryFun;

/// A doubly linked list index.
template Sequenced(){
    // dam you, ddoc
    /// _
    template Inner(ThisNode, Value, size_t N){
        alias TypeTuple!(N) IndexTuple;
        alias TypeTuple!(N) NodeTuple;

        // node implementation 
        mixin template NodeMixin(size_t N){
            typeof(this)* next, prev;
        }

 /// index implementation 
 ///
 /// Requirements: the following symbols must be  
 /// defined in the scope in which this index is mixed in:
 ///
 // dangit, ddoc, show my single starting underscore!
 /// ThisNode, Value, __InsertAllBut!N, __InsertAll,  __Replace, 
 /// __RemoveAllBut!N, node_count
        mixin template IndexMixin(size_t N){
            ThisNode* _front, _back;

/**
Defines the index' primary range, which embodies a
bidirectional range 
*/
            struct Range{
                ThisNode* _front, _back;

                @property bool empty(){
                    return !_front || !_back;
                }
                @property const(Value) front(){
                    return _front.value;
                }
                @property const(Value) back(){
                    return _back.value;
                }

                Range save(){ return this; }

                void popFront(){
                    _front = _front.index!N.next;
                }

                void popBack(){
                    _back = _back.index!N.prev;
                }
            }

/**
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
*/
            @property size_t length(){
                return node_count;
            }

/**
Property returning $(D true) if and only if the container has no
elements.

Complexity: $(BIGOH 1)
*/
            @property bool empty(){
                return node_count == 0;
            }

/**
Fetch a range that spans all the elements in the container.

Complexity: $(BIGOH 1)
*/
            Range opSlice(){
                return Range(_front, _back);
            }

/**
Complexity: $(BIGOH 1)
*/ 
            const(Value) front(){
                return _front.value;
            }

/**
Complexity: $(BIGOH r(n)); $(BR) $(BIGOH 1) for this index
*/ 
            void front(const(Value) value){
                _Replace(_front, value);
            }

            void _insertNext(ThisNode* node, ThisNode* prev) nothrow
                in{
                    assert(prev !is null);
                    assert(node !is null);
                }body{
                    ThisNode* next = prev.index!N.next;
                    prev.index!N.next = node;
                    node.index!N.prev = prev;
                    if(next !is null) next.index!N.prev = node;
                    node.index!N.next = next;
                }

            void _insertPrev(ThisNode* node, ThisNode* next) nothrow
                in{
                    assert(node !is null);
                    assert(next !is null);
                }body{
                    ThisNode* prev = next.index!N.prev;
                    if(prev !is null) prev.index!N.next = node;
                    node.index!N.prev = prev;
                    next.index!N.prev = node;
                    node.index!N.next = next;
                }

            ThisNode* _removeNext(ThisNode* prev) nothrow
                in{
                    assert(prev !is null);
                }body{
                    ThisNode* next = prev.index!N.next;
                    if (!next) return null;
                    ThisNode* nextnext = next.index!N.next;
                    prev.index!N.next = nextnext;
                    if(nextnext) nextnext.index!N.prev = prev;
                    next.index!N.prev = next.index!N.next = null;
                    return next;
                }

            ThisNode* _removePrev(ThisNode* next) nothrow
                in{
                    assert(next !is null);
                }body{
                    ThisNode* prev = next.index!N.prev;
                    if (!prev) return null;
                    ThisNode* prevprev = prev.index!N.prev;
                    next.index!N.prev = prevprev;
                    if(prevprev) prevprev.index!N.next = next;
                    prev.index!N.prev = prev.index!N.next = null;
                    return prev;
                }

            /**
             * Complexity: $(BIGOH 1)
             */
            const(Value) back(){
                return _back.value;
            }

            /**
             * Complexity: $(BIGOH r(n))
             */
            void back(const(Value) value){
                _Replace(_back, value);
            }

            void clear(){
                // todo
                assert (0);
            }

            bool _insertFront(ThisNode* node) nothrow
                in{
                    debug assert(node !is null);
                }body{
                    if(_front is null){
                        debug assert(_back is null);
                        _front = _back = node;
                    }else{
                        _insertPrev(node, _front);
                        _front = node;
                    }

                    return true;
                }

            void _Insert(ThisNode* n){
                _insertBack(n);
            }

            bool _insertBack(ThisNode* node) nothrow
                in{
                    debug assert (node !is null);
                }body{
                    if(_front is null){
                        debug assert(_back is null);
                        _front = _back = node;
                    }else{
                        _insertNext(node, _back);
                        _back = node;
                    }

                    return true;
                }

/++
Inserts every element of stuff not rejected by another index into the front 
of the index.
Returns:
The number of elements inserted.
Complexity: $(BIGOH n $(SUB stuff) * i(n)); $(BR) $(BIGOH n $(SUB stuff)) for 
this index
+/
            size_t insertFront(SomeRange)(SomeRange stuff)
                if(isInputRange!SomeRange && 
                        isImplicitlyConvertible!(ElementType!SomeRange, 
                            const(Value)))
                {
                    if(stuff.empty) return 0;
                    size_t count = 0;
                    ThisNode* prev;
                    while(count == 0 && !stuff.empty){
                        prev = _InsertAllBut!N(stuff.front);
                        if (!prev) continue;
                        _insertFront(prev);
                        stuff.popFront();
                        count++;
                    }
                    foreach(item; stuff){
                        ThisNode* node = _InsertAllBut!N(item);
                        if (!node) continue;
                        _insertNext(node, prev);
                        prev = node;
                        count ++;
                    }
                    return count;
                }

/++
Inserts value into the front of the sequence, if no other index rejects value
Returns:
The number if elements inserted into the index.
Complexity: $(BIGOH i(n)); $(BR) $(BIGOH 1) for this index
+/
            size_t insertFront(SomeValue)(SomeValue value)
                if(isImplicitlyConvertible!(SomeValue, const(Value))){
                    ThisNode* node = _InsertAllBut!N(value);
                    if(!node) return 0;
                    _insertFront(node);
                    return 1;
                }

            // todo
            // stableInsert
            // todo
            // stableInsertFront
/++
Inserts every element of stuff not rejected by another index into the back 
of the index.
Returns:
The number of elements inserted.
Complexity: $(BIGOH n $(SUB stuff) * i(n)); $(BR) $(BIGOH n $(SUB stuff)) for 
this index
+/
            size_t insertBack (SomeRange)(SomeRange stuff)
                if(isInputRange!SomeRange && 
                        isImplicitlyConvertible!(ElementType!SomeRange, const(Value)))
                {
                    size_t count = 0;

                    foreach(item; stuff){
                        count += insertBack(item);
                    }
                    return count;
                }

/++
Inserts value into the back of the sequence, if no other index rejects value
Returns:
The number if elements inserted into the index.
Complexity: $(BIGOH i(n)); $(BR) $(BIGOH 1) for this index
+/
            size_t insertBack(SomeValue)(SomeValue value)
                if(isImplicitlyConvertible!(SomeValue, const(Value))){
                    ThisNode* node = _InsertAllBut!N(value);
                    if (!node) return 0;
                    _insertBack(node);
                    return 1;
                }

/++
Forwards to insertBack
+/
            alias insertBack insert;
            /+
                todo
                stableInsertBack

                todo? 
                size_t insertAfter(SomeRange)(SequencedIndex.Range cursor, SomeRange stuff)
                if(isInputRange!SomeRange && 
                        isImplicitlyConvertible!(ElementType!SomeRange,const(Value))){

                }
            insertAfter ( Range, Stuff )
                stableInsertAfter
                insertBefore ( Range, Stuff )
                stableInsertAfter
            +/

            // reckon we'll trust n is somewhere between _front and _back
            void _Remove(ThisNode* n){
                if(n is _front){
                    _removeFront();
                }else{
                    ThisNode* prev = n.index!N.prev;
                    _removeNext(prev);
                }
            }

            ThisNode* _removeFront()
                in{
                    assert(_back !is null);
                    assert(_front !is null);
                }body{
                    ThisNode* n = _front;
                    if(_back == _front){
                        _back = _front = null;
                    }else{
                        _front = _front.index!N.next;
                        n.index!N.next = null;
                        _front.index!N.prev = null;
                    }
                    return n;
                }

/++
Removes the value at the front of the index from the container. 
Precondition: $(D !empty)
Complexity: $(BIGOH d(n)); $(BIGOH 1) for this index
+/
            void removeFront(){
                _RemoveAll(_front);
            }

/++
Removes the value at the back of the index from the container. 
Precondition: $(D !empty)
Complexity: $(BIGOH d(n)); $(BR) $(BIGOH 1) for this index
+/
            void removeBack(){
                _RemoveAll(_back);
            }
/++
Forwards to removeBack
+/
            alias removeBack removeAny;

/++
Removes the values of r from the container.
Precondition: r belongs to this index
Complexity: $(BIGOH n $(SUB r) * d(n)).
+/
            Range linearRemove(Range r)
                in{
                    // range belongs to this index
                }body{
                    while(!r.empty){
                        ThisNode* f = r._front;
                        r.popFront();
                        _RemoveAll(f);
                    }
                    return Range(null,null);
                }
            /+
                todo:
                stableRemoveAny 
                stableRemoveFront
                stableRemoveBack
                stableLinearRemove
                +/
        }
    }
}

/// A random access index.
template RandomAccess(){
    /// _
    template Inner(ThisNode, Value, size_t N){
        alias TypeTuple!() NodeTuple;
        alias TypeTuple!(N) IndexTuple;

        // node implementation 
        // all the overhead is in the index
        mixin template NodeMixin(){
        }

        /// index implementation 
        ///
        /// Requirements: the following symbols must be  
        /// defined in the scope in which this index is mixed in:
        ///
        // dangit, ddoc, show my single starting underscore!
        /// ThisNode, Value, __InsertAllBut!N, __InsertAll,  __Replace, 
        /// __RemoveAllBut!N, node_count
        mixin template IndexMixin(size_t N){
            ThisNode*[] ra;

            /// Defines the index' primary range, which embodies a
            /// random access range 
            struct Range{
                // storing a slice is probably really dumb, since
                // it requires pointer comparison to figure out where
                // in the original array the slice is.
                ThisNode*[] ra;

                const(Value) front(){ return ra[0].value; }

                void popFront(){ ra.popFront(); }

                @property bool empty(){ return ra.empty; }
                @property size_t length(){ return ra.length; }

                const(Value) back(){ return ra.back().value; }

                void popBack(){ ra.popBack(); }

                Range save(){ return this; }

                const(Value) opIndex(size_t i){ return ra[i].value; }
            }

/**
Fetch a range that spans all the elements in the container.

Complexity: $(BIGOH 1)
*/
            Range opSlice (){
                return Range(ra[0 .. node_count]);
            }

/**
Fetch a range that spans all the elements in the container from
index $(D a) (inclusive) to index $(D b) (exclusive).
Preconditions: a <= b && b <= length

Complexity: $(BIGOH 1)
*/
            Range opSlice(size_t a, size_t b){
                enforce(a <= b && b <= length);
                return Range(ra[a .. b]);
            }

/**
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
*/
            @property size_t length(){
                return node_count;
            }

/**
Property returning $(D true) if and only if the container has no elements.

Complexity: $(BIGOH 1)
*/
            @property bool empty(){
                return node_count == 0;
            }

/**
Returns the _capacity of the index, which is the length of the
underlying store 
*/
            @property size_t capacity(){
                return ra.length;
            }

/**
Ensures sufficient capacity to accommodate $(D n) elements.

Postcondition: $(D capacity >= n)

Complexity: $(BIGOH ??) if $(D e > capacity),
otherwise $(BIGOH 1).
*/
            void reserve(size_t count){
                if(ra.length < count){
                    ra.length = count;
                }
            }

/**
Complexity: $(BIGOH 1)
*/
            const(Value) front(){
                return ra[0].value;
            }

/**
Complexity: $(BIGOH r(n)); $(BR) $(BIGOH 1) for this index
*/
            void front(const(Value) value){
                _Replace(ra[0], value);
            }

/**
Complexity: $(BIGOH 1)
*/
            const(Value) back(){
                return ra[node_count-1].value;
            }

/**
Complexity: $(BIGOH r(n)); $(BR) $(BIGOH 1) for this index
*/
            void back(const(Value) value){
                _Replace(ra[node_count-1], value);
            }
/// ??
            void clear(){
                assert(0);
            }

/**
Preconditions: i < length
Complexity: $(BIGOH 1)
*/
            const(Value) opIndex(size_t i){
                enforce(i < length);
                return ra[i].value;
            }
/**
Sets index i to value, unless another index refuses value
Preconditions: i < length
Returns: the resulting _value at index i
Complexity: $(BIGOH r(n)); $(BR) $(BIGOH 1) for this index
*/
            const(Value) opIndexAssign(size_t i, const(Value) value){
                enforce(i < length);
                _Replace(ra[i], value);
                return ra[i].value;
            }

/**
Swaps element at index $(D i) with element at index $(D j).
Preconditions: i < length && j < length
Complexity: $(BIGOH 1)
*/
            void swapAt( size_t i, size_t j){
                enforce(i < length && j < length);
                swap(ra[i], ra[j]);
            }

/**
Removes the last element from this index.
Preconditions: !empty
Complexity: $(BIGOH d(n)); $(BR) $(BIGOH 1) for this index
*/
            void removeBack(){
                _RemoveAllBut!N(ra[node_count-1]);
                object.clear(ra[node_count]);
            }

            alias removeBack removeAny;

            void _Remove(ThisNode* n){
                foreach(i, item; ra[0 .. node_count]){
                    if(item is n){
                        copy(ra[i+1 .. node_count], ra[i .. node_count-1]);
                        ra[node_count-1] = null;
                        return;
                    }
                }
            }

            // todo stableRemoveAny
            // todo stableRemoveBack

            size_t insertBack(SomeValue)(SomeValue value)
            if(isImplicitlyConvertible!(SomeValue, const(Value)))
            {
                ThisNode* n = _InsertAllBut!N(value);
                if (!n) return 0;
                node_count--;
                _Insert(n);
                node_count++;
                return 1;
            }

            void _Insert(ThisNode* node){
                if (node_count >= ra.length){
                    reserve(max(ra.length * 2 + 1, node_count+1));
                }
                ra[node_count] = node;
            }

            alias insertBack insert;
            // todo stableInsertBack 

            Range linearRemove(Range r){
                size_t _length = node_count;
                if( ra.ptr <= r.ra.ptr && r.ra.ptr < ra.ptr + _length){
                    size_t rstart = r.ra.ptr - ra.ptr;
                    size_t rend = rstart + r.length;
                    size_t newlen = _length - (rend-rstart);
                    while(!r.empty){
                        _RemoveAllBut!N(r.ra[0]);
                    }
                    copy(ra[rend .. _length], ra[rstart .. newlen]);
                    fill(ra[newlen .. _length], cast(ThisNode*) null);
                    _length -= rend-rstart;
                    return Range(ra[rstart .. _length]);
                }else{
                    return Range(ra[_length .. _length]);
                }

            }
            // stableLinearRemove
        }
    }
}

// RBTree node impl. taken from std.container - that's Steven Schveighoffer's 
// code - and modified to suit.
// getting unique identifiers for all these member functions is a bother,
// so modified them to be standalone functions instead. 

/**
 * Enumeration determining what color the node is.  Null nodes are assumed
 * to be black.
 */
enum Color : byte
{
    Red,
    Black
}

/// ordered node implementation
mixin template OrderedNodeMixin(size_t N){
    alias typeof(this)* Node;
    Node _left;
    Node _right;
    Node _parent;

    /**
     * The color of the node.
     */
    Color color;

    /**
     * Get the left child
     */
    @property Node left()
    {
        return _left;
    }

    /**
     * Get the right child
     */
    @property Node right()
    {
        return _right;
    }

    /**
     * Get the parent
     */
    @property Node parent()
    {
        return _parent;
    }

    /**
     * Set the left child.  Also updates the new child's parent node.  This
     * does not update the previous child.
     *
     * Returns newNode
     */
    @property Node left(Node newNode)
    {
        _left = newNode;
        if(newNode !is null)
            newNode.index!N._parent = &this;
        return newNode;
    }

    /**
     * Set the right child.  Also updates the new child's parent node.  This
     * does not update the previous child.
     *
     * Returns newNode
     */
    @property Node right(Node newNode)
    {
        _right = newNode;
        if(newNode !is null)
            newNode.index!N._parent = &this;
        return newNode;
    }

    // assume _left is not null
    //
    // performs rotate-right operation, where this is T, _right is R, _left is
    // L, _parent is P:
    //
    //      P         P
    //      |   ->    |
    //      T         L
    //     / \       / \
    //    L   R     a   T
    //   / \           / \
    //  a   b         b   R
    //
    /**
     * Rotate right.  This performs the following operations:
     *  - The left child becomes the parent of this node.
     *  - This node becomes the new parent's right child.
     *  - The old right child of the new parent becomes the left child of this
     *    node.
     */
    Node rotateR()
        in
        {
            assert(_left !is null);
        }
    body
    {
        // sets _left._parent also
        if(isLeftNode)
            parent.index!N.left = _left;
        else
            parent.index!N.right = _left;
        Node tmp = _left.index!N._right;

        // sets _parent also
        _left.index!N.right = &this;

        // sets tmp._parent also
        left = tmp;

        return &this;
    }

    // assumes _right is non null
    //
    // performs rotate-left operation, where this is T, _right is R, _left is
    // L, _parent is P:
    //
    //      P           P
    //      |    ->     |
    //      T           R
    //     / \         / \
    //    L   R       T   b
    //       / \     / \
    //      a   b   L   a
    //
    /**
     * Rotate left.  This performs the following operations:
     *  - The right child becomes the parent of this node.
     *  - This node becomes the new parent's left child.
     *  - The old left child of the new parent becomes the right child of this
     *    node.
     */
    Node rotateL()
        in
        {
            assert(_right !is null);
        }
    body
    {
        // sets _right._parent also
        if(isLeftNode)
            parent.index!N.left = _right;
        else
            parent.index!N.right = _right;
        Node tmp = _right.index!N._left;

        // sets _parent also
        _right.index!N.left = &this;

        // sets tmp._parent also
        right = tmp;
        return &this;
    }


    /**
     * Returns true if this node is a left child.
     *
     * Note that this should always return a value because the root has a
     * parent which is the marker node.
     */
    @property bool isLeftNode() const
        in
        {
            assert(_parent !is null);
        }
    body
    {
        return _parent.index!N._left is &this;
    }

    /**
     * Set the color of the node after it is inserted.  This performs an
     * update to the whole tree, possibly rotating nodes to keep the Red-Black
     * properties correct.  This is an O(lg(n)) operation, where n is the
     * number of nodes in the tree.
     *
     * end is the marker node, which is the parent of the topmost valid node.
     */
    void setColor(Node end)
    {
        // test against the marker node
        if(_parent !is end)
        {
            if(_parent.index!N.color == Color.Red)
            {
                Node cur = &this;
                while(true)
                {
                    // because root is always black, _parent._parent always exists
                    if(cur.index!N._parent.index!N.isLeftNode)
                    {
                        // parent is left node, y is 'uncle', could be null
                        Node y = cur.index!N._parent.index!N._parent.index!N._right;
                        if(y !is null && y.index!N.color == Color.Red)
                        {
                            cur.index!N._parent.index!N.color = Color.Black;
                            y.index!N.color = Color.Black;
                            cur = cur.index!N._parent.index!N._parent;
                            if(cur.index!N._parent is end)
                            {
                                // root node
                                cur.index!N.color = Color.Black;
                                break;
                            }
                            else
                            {
                                // not root node
                                cur.index!N.color = Color.Red;
                                if(cur.index!N._parent.index!N.color == Color.Black)
                                    // satisfied, exit the loop
                                    break;
                            }
                        }
                        else
                        {
                            if(!cur.index!N.isLeftNode)
                                cur = cur.index!N._parent.index!N.rotateL();
                            cur.index!N._parent.index!N.color = Color.Black;
                            cur = cur.index!N._parent.index!N._parent.index!N.rotateR();
                            cur.index!N.color = Color.Red;
                            // tree should be satisfied now
                            break;
                        }
                    }
                    else
                    {
                        // parent is right node, y is 'uncle'
                        Node y = cur.index!N._parent.index!N._parent.index!N._left;
                        if(y !is null && y.index!N.color == Color.Red)
                        {
                            cur.index!N._parent.index!N.color = Color.Black;
                            y.index!N.color = Color.Black;
                            cur = cur.index!N._parent.index!N._parent;
                            if(cur.index!N._parent is end)
                            {
                                // root node
                                cur.index!N.color = Color.Black;
                                break;
                            }
                            else
                            {
                                // not root node
                                cur.index!N.color = Color.Red;
                                if(cur.index!N._parent.index!N.color == Color.Black)
                                    // satisfied, exit the loop
                                    break;
                            }
                        }
                        else
                        {
                            if(cur.index!N.isLeftNode)
                                cur = cur.index!N._parent.index!N.rotateR();
                            cur.index!N._parent.index!N.color = Color.Black;
                            cur = cur.index!N._parent.index!N._parent.index!N.rotateL();
                            cur.index!N.color = Color.Red;
                            // tree should be satisfied now
                            break;
                        }
                    }
                }

            }
        }
        else
        {
            //
            // this is the root node, color it black
            //
            color = Color.Black;
        }
    }

    /**
     * Remove this node from the tree.  The 'end' node is used as the marker
     * which is root's parent.  Note that this cannot be null!
     *
     * Returns the next highest valued node in the tree after this one, or end
     * if this was the highest-valued node.
     */
    Node remove(Node end)
    {
        //
        // remove this node from the tree, fixing the color if necessary.
        //
        Node x;
        Node ret;
        if(_left is null || _right is null)
        {
            ret = next;
        }
        else
        {
            //
            // normally, we can just swap this node's and y's value, but
            // because an iterator could be pointing to y and we don't want to
            // disturb it, we swap this node and y's structure instead.  This
            // can also be a benefit if the value of the tree is a large
            // struct, which takes a long time to copy.
            //
            Node yp, yl, yr;
            Node y = next;
            yp = y.index!N._parent;
            yl = y.index!N._left;
            yr = y.index!N._right;
            auto yc = y.index!N.color;
            auto isyleft = y.index!N.isLeftNode;

            //
            // replace y's structure with structure of this node.
            //
            if(isLeftNode)
                _parent.index!N.left = y;
            else
                _parent.index!N.right = y;
            //
            // need special case so y doesn't point back to itself
            //
            y.index!N.left = _left;
            if(_right is y)
                y.index!N.right = &this;
            else
                y.index!N.right = _right;
            y.index!N.color = color;

            //
            // replace this node's structure with structure of y.
            //
            left = yl;
            right = yr;
            if(_parent !is y)
            {
                if(isyleft)
                    yp.left = &this;
                else
                    yp.right = &this;
            }
            color = yc;

            //
            // set return value
            //
            ret = y;
        }

        // if this has less than 2 children, remove it
        if(_left !is null)
            x = _left;
        else
            x = _right;

        // remove this from the tree at the end of the procedure
        bool removeThis = false;
        if(x is null)
        {
            // pretend this is a null node, remove this on finishing
            x = &this;
            removeThis = true;
        }
        else if(isLeftNode)
            _parent.index!N.left = x;
        else
            _parent.index!N.right = x;

        // if the color of this is black, then it needs to be fixed
        if(color == color.Black)
        {
            // need to recolor the tree.
            while(x.index!N._parent !is end && x.index!N.color == Color.Black)
            {
                if(x.index!N.isLeftNode)
                {
                    // left node
                    Node w = x.index!N._parent.index!N._right;
                    if(w.index!N.color == Color.Red)
                    {
                        w.index!N.color = Color.Black;
                        x.index!N._parent.index!N.color = Color.Red;
                        x.index!N._parent.index!N.rotateL();
                        w = x.index!N._parent.index!N._right;
                    }
                    Node wl = w.index!N.left;
                    Node wr = w.index!N.right;
                    if((wl is null || wl.index!N.color == Color.Black) &&
                            (wr is null || wr.index!N.color == Color.Black))
                    {
                        w.index!N.color = Color.Red;
                        x = x.index!N._parent;
                    }
                    else
                    {
                        if(wr is null || wr.color == Color.Black)
                        {
                            // wl cannot be null here
                            wl.index!N.color = Color.Black;
                            w.index!N.color = Color.Red;
                            w.index!N.rotateR();
                            w = x.index!N._parent.index!N._right;
                        }

                        w.index!N.color = x.index!N._parent.index!N.color;
                        x.index!N._parent.index!N.color = Color.Black;
                        w.index!N._right.index!N.color = Color.Black;
                        x.index!N._parent.index!N.rotateL();
                        x = end.left; // x = root
                    }
                }
                else
                {
                    // right node
                    Node w = x.index!N._parent.index!N._left;
                    if(w.index!N.color == Color.Red)
                    {
                        w.index!N.color = Color.Black;
                        x.index!N._parent.index!N.color = Color.Red;
                        x.index!N._parent.index!N.rotateR();
                        w = x.index!N._parent.index!N._left;
                    }
                    Node wl = w.index!N.left;
                    Node wr = w.index!N.right;
                    if((wl is null || wl.index!N.color == Color.Black) &&
                            (wr is null || wr.index!N.color == Color.Black))
                    {
                        w.index!N.color = Color.Red;
                        x = x.index!N._parent;
                    }
                    else
                    {
                        if(wl is null || wl.color == Color.Black)
                        {
                            // wr cannot be null here
                            wr.index!N.color = Color.Black;
                            w.index!N.color = Color.Red;
                            w.index!N.rotateL();
                            w = x.index!N._parent.index!N._left;
                        }

                        w.index!N.color = x.index!N._parent.index!N.color;
                        x.index!N._parent.index!N.color = Color.Black;
                        w.index!N._left.index!N.color = Color.Black;
                        x.index!N._parent.index!N.rotateR();
                        x = end.index!N.left; // x = root
                    }
                }
            }
            x.index!N.color = Color.Black;
        }

        if(removeThis)
        {
            //
            // clear this node out of the tree
            //
            if(isLeftNode)
                _parent.index!N.left = null;
            else
                _parent.index!N.right = null;
        }

        return ret;
    }

    /**
     * Return the leftmost descendant of this node.
     */
    @property Node leftmost()
    {
        Node result = &this;
        while(result.index!N._left !is null)
            result = result.index!N._left;
        return result;
    }

    /**
     * Return the rightmost descendant of this node
     */
    @property Node rightmost()
    {
        Node result = &this;
        while(result.index!N._right !is null)
            result = result.index!N._right;
        return result;
    }

    /**
     * Returns the next valued node in the tree.
     *
     * You should never call this on the marker node, as it is assumed that
     * there is a valid next node.
     */
    @property Node next()
    {
        Node n = &this;
        if(n.index!N.right is null)
        {
            while(!n.index!N.isLeftNode)
                n = n.index!N._parent;
            return n.index!N._parent;
        }
        else
            return n.index!N.right.index!N.leftmost;
    }

    /**
     * Returns the previous valued node in the tree.
     *
     * You should never call this on the leftmost node of the tree as it is
     * assumed that there is a valid previous node.
     */
    @property Node prev()
    {
        Node n = &this;
        if(n.left is null)
        {
            while(n.index!N.isLeftNode)
                n = n.index!N._parent;
            return n.index!N._parent;
        }
        else
            return n.index!N.left.index!N.rightmost;
    }

}

/// ordered index implementation
mixin template OrderedIndex(size_t N, bool allowDuplicates, alias KeyFromValue, alias Compare){
    alias ThisNode* Node;
    alias binaryFun!Compare _less;
    alias unaryFun!KeyFromValue key;
    alias typeof(key(Value.init)) KeyType;

    auto _add(Node n)
    {
        bool added = true;

        if(!_end.index!N.left)
        {
            _end.index!N.left = n;
        }
        else
        {
            Node newParent = _end.index!N.left;
            Node nxt = void;
            auto k = key(n.value);
            while(true)
            {
                auto pk = key(newParent.value);
                if(_less(k, pk))
                {
                    nxt = newParent.index!N.left;
                    if(nxt is null)
                    {
                        //
                        // add to right of new parent
                        //
                        newParent.index!N.left = n;
                        break;
                    }
                }
                else
                {
                    static if(!allowDuplicates)
                    {
                        if(!_less(pk, k))
                        {
                            added = false;
                            break;
                        }
                    }
                    nxt = newParent.index!N.right;
                    if(nxt is null)
                    {
                        //
                        // add to right of new parent
                        //
                        newParent.index!N.right = n;
                        break;
                    }
                }
                newParent = nxt;
            }
        }

        static if(allowDuplicates)
        {
            n.index!N.setColor(_end);
            version(RBDoChecks)
                check();
            return added;
        }
        else
        {
            if(added)
                n.index!N.setColor(_end);
            version(RBDoChecks)
                check();
            return added;
        }
    }

    /**
     * Element type for the tree
     */
    alias const(Value) Elem;

    private Node   _end;

    static if(!allowDuplicates){
        bool _DenyInsertion(Node n, out Node cursor){
            bool found;
            _find2(n.value, found, cursor);
            return !found;
        }
    }

    static if(allowDuplicates) alias _add _Insert;
    else void _Insert(Node n, Node cursor){
        if(cursor !is null){
            if (_less(key(n.value), key(cursor.value))){
                cursor.index!N.left = n;
            }else{
                cursor.index!N.right = n;
            }
        }else{
            _add(n);
        }

    }

    /**
     * The range type for this index, which embodies a bidirectional range
     */
    struct Range
    {
        private Node _begin;
        private Node _end;

        private this(Node b, Node e)
        {
            _begin = b;
            _end = e;
        }

        /**
         * Returns $(D true) if the range is _empty
         */
        @property bool empty() const
        {
            return _begin is _end;
        }

        /**
         * Returns the first element in the range
         */
        @property Elem front()
        {
            return _begin.value;
        }

        /**
         * Returns the last element in the range
         */
        @property Elem back()
        {
            return _end.index!N.prev.value;
        }

        /**
         * pop the front element from the range
         *
         * complexity: amortized $(BIGOH 1)
         */
        void popFront()
        {
            _begin = _begin.index!N.next;
        }

        /**
         * pop the back element from the range
         *
         * complexity: amortized $(BIGOH 1)
         */
        void popBack()
        {
            _end = _end.index!N.prev;
        }

        /**
         * Trivial _save implementation, needed for $(D isForwardRange).
         */
        @property Range save()
        {
            return this;
        }
    }

    // find a node based on an element value
    private Node _find(KeyType k)
    {
        static if(allowDuplicates)
        {
            Node cur = _end.index!N.left;
            Node result = null;
            while(cur)
            {
                auto ck = key(cur.value);
                if(_less(ck, k))
                    cur = cur.index!N.right;
                else if(_less(k, ck))
                    cur = cur.index!N.left;
                else
                {
                    // want to find the left-most element
                    result = cur;
                    cur = cur.index!N.left;
                }
            }
            return result;
        }
        else
        {
            Node cur = _end.index!N.left;
            while(cur)
            {
                auto ck = key(cur.value);
                if(_less(ck, k))
                    cur = cur.index!N.right;
                else if(_less(k, ck))
                    cur = cur.index!N.left;
                else
                    return cur;
            }
            return null;
        }
    }

    private void _find2(KeyType k, out bool found, out Node par)
    {
        Node cur = _end.index!N.left;
        par = null;
        found = false;
        while(cur)
        {
            auto ck = key(cur.value);
            par = cur;
            if(_less(ck, k)){
                cur = cur.index!N.right;
            }else if(_less(k, ck)){
                cur = cur.index!N.left;
            }else{
                found = true;
                return;
            }
        }
    }

    /**
     * Check if any elements exist in the container.  Returns $(D true) if at least
     * one element exists.
     * Complexity: $(BIGOH 1)
     */
    @property bool empty()
    {
        return node_count == 0;
    }

/++
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
+/
        @property size_t length()
        {
            return node_count;
        }

    /**
     * Fetch a range that spans all the elements in the container.
     *
     * Complexity: $(BIGOH log(n))
     */
    Range opSlice()
    {
        return Range(_end.index!N.leftmost, _end);
    }

    /**
     * The front element in the container
     *
     * Complexity: $(BIGOH log(n))
     */
    Elem front()
    {
        return _end.index!N.leftmost.value;
    }

    /**
     * The last element in the container
     *
     * Complexity: $(BIGOH log(n))
     */
    Elem back()
    {
        return _end.index!N.prev.value;
    }

    /++
        $(D in) operator. Check to see if the given element exists in the
        container.

        Complexity: $(BIGOH log(n))
        +/
        bool opBinaryRight(string op)(Elem e) if (op == "in")
        {
            return _find(key(e)) !is null;
        }
    /++
        $(D in) operator. Check to see if the given element exists in the
        container.

        Complexity: $(BIGOH log(n))
        +/
        bool opBinaryRight(string op,K)(K k) if (op == "in" &&
                isImplicitlyConvertible!(K, KeyType))
        {
            return _find(k) !is null;
        }

    /**
     * Removes all elements from the container.
     *
     * Complexity: ??
     */
    void clear()
    {
        assert(0);
        // todo
    }

    /**
     * Insert a single element in the container.  Note that this does not
     * invalidate any ranges currently iterating the container.
     *
     * Complexity: $(BIGOH i(n)); $(BR) $(BIGOH log(n)) for this index
     */
    size_t stableInsert(Stuff)(Stuff stuff) 
        if (isImplicitlyConvertible!(Stuff, Elem))
        {
            writeln(stuff);
            static if(!allowDuplicates){
                bool found;
                Node p;
                if((_find2(stuff,found,p), found)){
                    return 0;
                }
            }
            Node n = _InsertAllBut!N(stuff);

            if(!n) return 0;

            static if(!allowDuplicates){
                if(p){
                    if (_less(key(n.value), key(p.value))){
                        p.index!N.left = n;
                    }else{
                        p.index!N.right = n;
                    }
                }else _add(n);
            }else _add(n);
            return 1;
        }

    /**
     * Insert a range of elements in the container.  Note that this does not
     * invalidate any ranges currently iterating the container.
     *
     * Complexity: $(BIGOH n $(SUB stuff) * i(n)); $(BR) $(BIGOH n $(SUB 
     stuff) * log(n)) for this index
     */
    size_t stableInsert(Stuff)(Stuff stuff) 
        if(isInputRange!Stuff && 
                isImplicitlyConvertible!(ElementType!Stuff, Elem))
        {
            size_t result = 0;
            foreach(e; stuff)
            {
                result += stableInsert(e);
            }
            return result;
        }

    /// ditto
    alias stableInsert insert;

    void _Remove(Node n){
        n.index!N.remove(_end);
    }

    /**
     * Remove an element from the container and return its value.
     *
     * Complexity: $(BIGOH d(n)); $(BR) $(BIGOH log(n)) for this index
     */
    Elem removeAny()
    {
        auto n = _end.index!N.leftmost;
        auto result = n.value;
        _RemoveAll(n);
        version(RBDoChecks)
            check();
        return result;
    }

    /**
     * Remove the front element from the container.
     *
     * Complexity: $(BIGOH d(n)); $(BR) $(BIGOH log(n)) for this index
     */
    void removeFront()
    {
        auto n = _end.index!N.leftmost;
        _RemoveAll(n);
        version(RBDoChecks)
            check();
    }

    /**
     * Remove the back element from the container.
     *
     * Complexity: $(BIGOH d(n)); $(BR) $(BIGOH log(n)) for this index
     */
    void removeBack()
    {
        auto n = _end.index!N.prev;
        _RemoveAll(n);
        version(RBDoChecks)
            check();
    }

    /++
        Removes the given range from the container.

        Returns: A range containing all of the elements that were after the
        given range.

        Complexity:$(BIGOH n $(SUB r) * d(n)); $(BR) $(BIGOH n $(SUB r) * 
                log(n)) for this index
    +/
    Range remove(Range r)
    {
        auto b = r._begin;
        auto e = r._end;
        while(b !is e)
        {
            _RemoveAllBut!N(b);
            b = b.index!N.remove(_end);
        }
        version(RBDoChecks)
            check();
        return Range(e, _end);
    }

    /++
        Removes the given $(D Take!Range) from the container

        Returns: A range containing all of the elements that were after the
        given range.

        Complexity: $(BIGOH n $(SUB r) * d(n)); $(BR) $(BIGOH n $(SUB r) * 
                log(n)) for this index 
    +/
    Range remove(Take!Range r)
    {
        auto b = r.source._begin;

        while(!r.empty)
            r.popFront(); // move take range to its last element

        auto e = r.source._begin;

        while(b != e)
        {
            _RemoveAllBut!N(b);
            b = b.index!N.remove(_end);
        }

        return Range(e, _end);
    }

    /++
   Removes elements from the container that are equal to the given values
   according to the less comparator. One element is removed for each value
   given which is in the container. If $(D allowDuplicates) is true,
   duplicates are removed only if duplicate values are given.

   Returns: The number of elements removed.

   Complexity: $(BIGOH n $(SUB keys) d(n)); $(BR) $(BIGOH n 
   $(SUB keys) log(n)) for this index

   Examples:
    --------------------
    // ya, this needs updating
    auto rbt = redBlackTree!true(0, 1, 1, 1, 4, 5, 7);
    rbt.removeKey(1, 4, 7);
    assert(std.algorithm.equal(rbt[], [0, 1, 1, 5]));
    rbt.removeKey(1, 1, 0);
    assert(std.algorithm.equal(rbt[], [5]));
    --------------------
    +/
    size_t removeKey(U)(U[] keys...)
    if(isImplicitlyConvertible!(U, KeyType))
    {
        size_t count = 0;

        foreach(k; keys)
        {
            auto beg = _firstGreaterEqual(k);
            if(beg is _end || _less(k, key(beg.value)))
                // no values are equal
                continue;
            _RemoveAll(beg);
            count++;
        }

        return count++;
    }

    /++ Ditto +/
    size_t removeKey(Stuff)(Stuff stuff)
    if(isInputRange!Stuff &&
            isImplicitlyConvertible!(ElementType!Stuff, KeyType) &&
            !is(Stuff == Elem[]))
    {
        //We use array in case stuff is a Range from this RedBlackTree - either
        //directly or indirectly.
        return removeKey(array(stuff));
    }

    // find the first node where the value is > k
    private Node _firstGreater(U)(U k)
    if(isImplicitlyConvertible!(U, KeyType))
    {
        // can't use _find, because we cannot return null
        auto cur = _end.index!N.left;
        auto result = _end;
        while(cur)
        {
            if(_less(k, key(cur.value)))
            {
                result = cur;
                cur = cur.index!N.left;
            }
            else
                cur = cur.index!N.right;
        }
        return result;
    }

    // find the first node where the value is >= k
    private Node _firstGreaterEqual(U)(U k)
    if(isImplicitlyConvertible!(U, KeyType))
    {
        // can't use _find, because we cannot return null.
        auto cur = _end.index!N.left;
        auto result = _end;
        while(cur)
        {
            if(_less(key(cur.value), k))
                cur = cur.index!N.right;
            else
            {
                result = cur;
                cur = cur.index!N.left;
            }

        }
        return result;
    }

    /**
     * Get a range from the container with all elements that are > k according
     * to the less comparator
     *
     * Complexity: $(BIGOH log(n))
     */
    Range upperBound(U)(U k)
    if(isImplicitlyConvertible!(U, KeyType))
    {
        return Range(_firstGreater(k), _end);
    }

    /**
     * Get a range from the container with all elements that are < k according
     * to the less comparator
     *
     * Complexity: $(BIGOH log(n))
     */
    Range lowerBound(U)(U k)
    if(isImplicitlyConvertible!(U, KeyType))
    {
        return Range(_end.index!N.leftmost, _firstGreaterEqual(k));
    }

    /**
     * Get a range from the container with all elements that are == k according
     * to the less comparator
     *
     * Complexity: $(BIGOH log(n))
     */
    Range equalRange(U)(U k)
    if(isImplicitlyConvertible!(U, KeyType))
    {
        auto beg = _firstGreaterEqual(k);
        if(beg is _end || _less(k, key(beg.value)))
            // no values are equal
            return Range(beg, beg);
        static if(allowDuplicates)
        {
            return Range(beg, _firstGreater(k));
        }
        else
        {
            // no sense in doing a full search, no duplicates are allowed,
            // so we just get the next node.
            return Range(beg, beg.index!N.next);
        }
    }

/++
Get a range of values bounded below by lower and above by upper, with
inclusiveness defined by boundaries.
Complexity: $(BIGOH log(n))
+/
    Range bounds(string boundaries = "[]", U)(U lower, U upper)
    if(isImplicitlyConvertible!(U, KeyType))
    {
        static if(boundaries == "[]"){
            return Range(_firstGreaterEqual(lower), _firstGreater(upper));
        }else static if(boundaries == "[)"){
            return Range(_firstGreaterEqual(lower), _firstGreaterEqual(upper));
        }else static if(boundaries == "(]"){
            return Range(_firstGreater(lower), _firstGreater(upper));
        }else static if(boundaries == "()"){
            return Range(_firstGreater(lower), _firstGreaterEqual(upper));
        }else static assert(false, "waht is this " ~ boundaries ~ " bounds?!");
    }

    version(RBDoChecks)
    {
        /*
         * Print the tree.  This prints a sideways view of the tree in ASCII form,
         * with the number of indentations representing the level of the nodes.
         * It does not print values, only the tree structure and color of nodes.
         */
        void printTree(Node n, int indent = 0)
        {
            if(n !is null)
            {
                printTree(n.right, indent + 2);
                for(int i = 0; i < indent; i++)
                    write(".");
                writeln(n.color == n.color.Black ? "B" : "R");
                printTree(n.left, indent + 2);
            }
            else
            {
                for(int i = 0; i < indent; i++)
                    write(".");
                writeln("N");
            }
            if(indent is 0)
                writeln();
        }

        /*
         * Check the tree for validity.  This is called after every add or remove.
         * This should only be enabled to debug the implementation of the RB Tree.
         */
        void check()
        {
            //
            // check implementation of the tree
            //
            int recurse(Node n, string path)
            {
                if(n is null)
                    return 1;
                if(n.parent.left !is n && n.parent.right !is n)
                    throw new Exception("Node at path " ~ path ~ " has inconsistent pointers");
                Node next = n.next;
                static if(allowDuplicates)
                {
                    if(next !is _end && _less(key(next.value), key(n.value)))
                        throw new Exception("ordering invalid at path " ~ path);
                }
                else
                {
                    if(next !is _end && !_less(key(n.value), key(next.value)))
                        throw new Exception("ordering invalid at path " ~ path);
                }
                if(n.color == n.color.Red)
                {
                    if((n.left !is null && n.left.color == n.color.Red) ||
                            (n.right !is null && n.right.color == n.color.Red))
                        throw new Exception("Node at path " ~ path ~ " is red with a red child");
                }

                int l = recurse(n.left, path ~ "L");
                int r = recurse(n.right, path ~ "R");
                if(l != r)
                {
                    writeln("bad tree at:");
                    printTree(n);
                    throw new Exception("Node at path " ~ path ~ " has different number of black nodes on left and right paths");
                }
                return l + (n.color == n.color.Black ? 1 : 0);
            }

            try
            {
                recurse(_end.left, "");
            }
            catch(Exception e)
            {
                printTree(_end.left, 0);
                throw e;
            }
        }
    }
}

/// A red black tree index
template Ordered(bool allowDuplicates = false, alias KeyFromValue="a", 
        alias Compare = "a<b"){
    template Inner(ThisNode, Value, size_t N){
        alias TypeTuple!(N, allowDuplicates, KeyFromValue, Compare) IndexTuple;
        alias OrderedIndex IndexMixin;

        enum IndexCtorMixin = "_end = alloc();";
        /// node implementation (ish)
        alias TypeTuple!(N) NodeTuple;
        alias OrderedNodeMixin NodeMixin;
    }
}

/// A red black tree index
template OrderedNonUnique(alias KeyFromValue="a", alias Compare = "a<b"){
    alias Ordered!(true, KeyFromValue, Compare) OrderedNonUnique;
}
/// A red black tree index
template OrderedUnique(alias KeyFromValue="a", alias Compare = "a<b"){
    alias Ordered!(false, KeyFromValue, Compare) OrderedUnique;
}

// end RBTree impl

/// a max heap index
template Heap(alias KeyFromValue = "a", alias Compare = "a<b"){
    /// _
    template Inner(ThisNode, Value, size_t N){
        alias TypeTuple!() NodeTuple;
        alias TypeTuple!(N,KeyFromValue, Compare) IndexTuple;

        mixin template NodeMixin(){
            size_t _index;
        }

        /// index implementation
        mixin template IndexMixin(size_t N, alias KeyFromValue, alias Compare){
            alias unaryFun!KeyFromValue key;
            alias binaryFun!Compare less;

            ThisNode*[] _heap;

            static size_t p(size_t n) pure{
                return n / 2;
            }

            static size_t l(size_t n) pure{
                return 2*n + 1;
            }

            static size_t r(size_t n) pure{
                return 2*n + 2;
            }

            void swapAt(size_t n1, size_t n2){
                swap(_heap[n1].index!N._index, _heap[n2].index!N._index); 
                swap(_heap[n1], _heap[n2]); 
            }

            void sift(size_t n){
                auto k = key(_heap[n].value);
                if(n > 0 && less(key(_heap[p(n)].value), k)){
                    do{
                        swapAt(n, p(n));
                        n = p(n);
                    }while(n > 0 && less(key(_heap[p(n)].value), k));
                }else if(l(n) < node_count){
                    auto ch = l(n);
                    auto chk = key(_heap[ch].value);
                    if (r(n) < node_count){
                        auto rk = key(_heap[r(n)].value);
                        if(less(chk, rk)){
                            chk = rk;
                            ch = r(n);
                        }
                    }
                    while(l(n) < node_count && less(k,chk)){
                        swapAt(n, ch);
                        n = ch;
                        ch = l(n);
                        chk = key(_heap[ch].value);
                        if (r(n) < node_count){
                            auto rk = key(_heap[r(n)].value);
                            if(less(chk, rk)){
                                chk = rk;
                                ch = r(n);
                            }
                        }
                    }
                }
            }

            /// The primary range of the index, which embodies a bidirectional
            /// range.
            ///
            /// Ends up performing a breadth first traversal (I think..)
            struct Range{
                ThisNode*[] _rng;

                const(Value) front(){ return _rng[0].value; }

                void popFront(){ _rng.popFront(); }

                @property bool empty(){ return _rng.empty; }
                @property size_t length(){ return _rng.length; }

                const(Value) back(){ return _rng.back().value; }

                void popBack(){ _rng.popBack(); }

                Range save(){ return this; }
            }

/**
Fetch a range that spans all the elements in the container.

Complexity: $(BIGOH 1)
*/
            Range opSlice(){
                return Range(_heap[0 .. node_count]);
            }

/**
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
*/
            @property size_t length(){
                return node_count;
            }

/**
Property returning $(D true) if and only if the container has no
elements.

Complexity: $(BIGOH 1)
*/
            @property bool empty(){
                return node_count == 0;
            }

/**
Returns: the max element in this index
Complexity: $(BIGOH 1)
*/ 
            const(Value) front(){
                return _heap[0].value;
            }
/**
Returns: the back of this index
Complexity: $(BIGOH 1)
*/ 
            const(Value) back(){
                return _heap[node_count-1].value;
            }
/**
  ??
*/
            void clear(){
                assert(0);
            }

/**
Returns the _capacity of the index, which is the length of the
underlying store 
*/
            @property size_t capacity(){
                return _heap.length;
            }

/**
Ensures sufficient capacity to accommodate $(D n) elements.

Postcondition: $(D capacity >= n)

Complexity: $(BIGOH ??) if $(D e > capacity),
otherwise $(BIGOH 1).
*/
            void reserve(size_t count){
                if(_heap.length < count){
                    _heap.length = count;
                }
            }
/**
Inserts value into this heap, unless another index refuses it.
Returns: the number of values added to the container
Complexity: $(BIGOH i(n)); $(BR) $(BIGOH log(n)) for this index
*/
            size_t insert(SomeValue)(SomeValue value)
            if(isImplicitlyConvertible!(SomeValue, const(Value)))
            {
                ThisNode* n = _InsertAllBut!N(value);
                if(!n) return 0;
                node_count++;
                _Insert(n);
                node_count--;
                return 1;
            }

            void _Insert(ThisNode* node){
                if(node_count == _heap.length){
                    reserve(max(_heap.length*2+1, node_count+1));
                }
                _heap[node_count] = node;
                _heap[node_count].index!N._index = node_count;
                sift(node_count);
            }

            // todo stableInsert

/**
Removes the max element of this index from the container.
Complexity: $(BIGOH d(n)); $(BR) $(BIGOH log(n)) for this index
*/
            void removeFront(){
                _RemoveAll(_heap[0]);
            }

            void _Remove(ThisNode* node){
                swapAt(node.index!N._index, node_count-1);
                _heap[node_count-1] = null;
                sift(node.index!N._index);
            }
            // todo stableRemoveFront
/**
Forwards to removeFront
*/
            alias removeFront removeAny;
            // todo stableRemoveAny


/**
* removes the back of this index from the container. Why would you do this? 
No idea.
Complexity: $(BIGOH d(n)); $(BR) $(BIGOH 1) for this index
*/
            void removeBack(){
                _RemoveAllBut!N(_heap[node_count-1]);
            }
            /// todo stableRemoveBack

        }
    }
}

/// a hash table index
template HashedUnique(alias KeyFromValue="a", alias Hash = "??", alias Eq = "a==b"){
    template Inner(ThisNode, Value, size_t N){
        template Index(){
            alias HashedIndex!(ThisNode, Value, N, 
                    KeyFromValue, hash, Eq, true) Index;
        }
        /// node implementation (ish)

        // all the overhead is in the index
        mixin template NodeMixin(size_t N){
        }
    }
}

/// a hash table index
template Hashed(bool allowDuplicates = false, alias KeyFromValue="a", 
        alias Hash = "??", alias Eq = "a==b"){
    template Inner(ThisNode, Value, size_t N){
        alias TypeTuple!() NodeTuple;
        alias TypeTuple!(N,KeyFromValue, Compare) IndexTuple;
        // node implementation 
        // all the overhead is in the index
        mixin template NodeMixin(size_t N){
        }

        mixin template IndexMixin(size_t N, alias KeyFromValue, alias Hash, 
                alias Eq, bool unique){
            ThisNode*[] hashes;
        }
    }
}

struct IndexedBy(L...)
{
    alias L List;
}

/++
A multi_index node. Holds the value of a single element,
plus per-node headers of each index, if any. (random_access
and hashed don't have per-node headers)
The headers are all mixed in in the same scope. To prevent
naming conflicts, a header field must be accessed with the number
of its index. 
Example:
----
alias MNode!(IndexedBy!(Sequenced!(), Sequenced!(), OrderedUnique!()), int) Node;
Node* n1 = new Node();
Node* n2 = new Node();
n1.index!0 .next = n2;
n2.index!0 .prev = n1;
n1.index!1 .prev = n2;
n2.index!1 .next = n1;
n1.index!2 .left = n2;
----
+/
struct MNode(IndexedBy, Value){
    Value value;

    template ForEachIndex(size_t N,L...){
        static if(L.length > 0){
            enum indexN = Format!("index%s",N);
            alias L[0] L0;
            enum result = 
                Replace!(q{
                    alias IndexedBy.List[$N] L$N;
                    alias L$N.Inner!(typeof(this),Value,$N) M$N;
                    mixin M$N.NodeMixin!(M$N.NodeTuple) index$N;
                    template index(size_t n) if(n == $N){ alias index$N index; }
                },  "$N", Format!("%s",N)) ~ 
                ForEachIndex!(N+1, L[1 .. $]).result;
        }else{
            enum result = "";
        }
    }

    enum stuff = ForEachIndex!(0, IndexedBy.List).result;
    mixin(stuff);
}




/++ 
The container
+/
class MultiIndexContainer(Value, IndexedBy){
    alias MNode!(IndexedBy,Value) ThisNode;

    size_t node_count;


    template ForEachCtorMixin(size_t i){
        static if(i < IndexedBy.List.length){
            static if(is(typeof(IndexedBy.List[i].Inner!(ThisNode,const(Value),i).IndexCtorMixin))){
                enum result =  IndexedBy.List[i].Inner!(ThisNode,const(Value),i).IndexCtorMixin ~ ForEachCtorMixin!(i+1).result;
            }else enum result = ForEachCtorMixin!(i+1).result;
        }else enum result = "";
    }

    this(){
        mixin(ForEachCtorMixin!(0).result);
    }

    void _Replace(ThisNode* node, const(Value) value){
        assert(false);
    }

    /// specify how to allocate a node
    /// todo: specify how to deallocate a node?
    ThisNode* alloc(){
        return new ThisNode;
    }

    template ForEachCheckInsert(size_t i, size_t N){
        static if(i < IndexedBy.List.length){
            static if(i != N && is(typeof({ ThisNode* p; 
                            index!i._DenyInsertion(p,p);}))){
                enum result = (Replace!(q{
                        ThisNode* aY; 
                        bool bY = index!(Y)._DenyInsertion(node,aY);
                        if (!bY) goto denied;
                }, "Y",toStringNow!i)) ~ ForEachCheckInsert!(i+1, N).result;
            }else enum result = ForEachCheckInsert!(i+1, N).result;
        }else enum result = "";
    }

    template ForEachDoInsert(size_t i, size_t N){
        static if(i < IndexedBy.List.length){
            static if(i != N){
                static if(is(typeof({ ThisNode* p; 
                                index!i._DenyInsertion(p,p);}))){
                    enum result = Replace!(q{
                        index!(Y)._Insert(node,aY);
                    }, "Y",toStringNow!i) ~ ForEachDoInsert!(i+1,N).result;
                }else{
                    enum result = Replace!(q{
                        index!(Y)._Insert(node);
                    }, "Y",toStringNow!i) ~ ForEachDoInsert!(i+1,N).result;
                }
            }else enum result = ForEachDoInsert!(i+1, N).result;
        }else enum result = "";
    }

    ThisNode* _InsertAllBut(size_t N)(const(Value) value){
        ThisNode* node = alloc();
        node.value = value;
        mixin(ForEachCheckInsert!(0, N).result);
        mixin(ForEachDoInsert!(0, N).result);
        node_count++;
        return node;
denied:
        return null;
    }

    template ForEachDoRemove(size_t i, size_t N){
        static if(i < IndexedBy.List.length){
            static if(i != N){
                enum result = Replace!(q{
                    index!(Y)._Remove(node);
                }, "Y",toStringNow!i) ~ ForEachDoRemove!(i+1,N).result;
            }else enum result = ForEachDoRemove!(i+1, N).result;
        }else enum result = "";
    }

    /// disattatch node from all indeces except index N
    void _RemoveAllBut(size_t N)(ThisNode* node){
        mixin(ForEachDoRemove!(0, N).result);
        node_count --;
    }

    enum _grr_bugs = IndexedBy.List.length;
    /// disattach node from all indeces.
    /// @@@BUG@@@ cannot pass length directly to _RemoveAllBut
    alias _RemoveAllBut!(_grr_bugs) _RemoveAll;

    template ForEachAlias(size_t N,size_t index, alias X){
        alias X.Inner!(ThisNode,Value,N).Index!() Index;
        static if(Index.container_aliases.length > index){
            enum aliashere = NAliased!(Index.container_aliases[index][0], 
                    Index.container_aliases[index][1], N);
            enum result = aliashere ~ "\n" ~ ForEachAlias!(N,index+1, X).result;
        }else{
            enum result = "";
        }
    }

    template ForEachIndex(size_t N,L...){
        static if(L.length > 0){
            enum result = 
                Replace!(q{
                    alias IndexedBy.List[$N] L$N;
                    alias L$N.Inner!(ThisNode,Value,$N) M$N;
                    mixin M$N.IndexMixin!(M$N.IndexTuple) index$N;
                    template index(size_t n) if(n == $N){ alias index$N index; }
                    class Index$N{
                        auto opDispatch(string s, T...)(T args){
                            mixin("return this.outer.index!($N)."~s~"(args);");
                        }
                    }
                    Index$N get_index(size_t n)() if(n == $N){
                        return this.new Index$N();
                    }
                },  "$N", Format!("%s",N)) ~ 
                ForEachIndex!(N+1, L[1 .. $]).result;
        }else{
            enum result = "";
        }
    }

    enum stuff = (ForEachIndex!(0, IndexedBy.List).result);
    mixin(stuff);
}

import std.stdio: writeln, writefln;
import std.string: format;

int[] arr(Range)(Range r){
    int[] result = new int[](r.length);
    size_t j = 0;
    foreach(e; r){
        result[j++] = e;
    }
    return result;
}
void main(){
    alias MNode!(IndexedBy!(
                Sequenced!(), 
                OrderedUnique!(),
                ),int) Node;
    Node* n1 = new Node();
    Node* n2 = new Node();
    enum R = 1;
    n1.index!0 .next = n2;
    n1.index!1 .left = n2;
    alias MultiIndexContainer!(int, 
            IndexedBy!(Sequenced!(), OrderedNonUnique!(), 
                RandomAccess!(), Heap!())) C;

    C i = new C;
    /+
    i.index!(1).insert(S(1,1));
    i.index!(1).insert(S(0,2));
    i.index!(1).insert(S(-1,2));
    i.index!(1).insert(S(3,3));
    i.index!(1).insert(S(2,40));
    i.index!(1).insert(S(1,5));
    writeln(array(i.index!(0).opSlice()));
    writeln(array(i.index!(1).opSlice()));
    i.index!(1).removeKey(3);
    writeln(array(i.index!(0).opSlice()));
    writeln(array(i.index!(1).opSlice()));
    +/
    auto c = i.get_index!0;
    struct J{}
    c.insert("a");
    i.index!(0).insert(5);
    i.index!(0).insert(5);
    i.index!(0).insert(4);
    i.index!(0).insert(3);
    i.index!(0).insert(1);
    i.index!(0).insert(9);
    i.index!(0).insert(7);
    i.index!(0).insert(8);
    i.index!(0).insert(6);
    writeln(i.index!(2).opIndex(3));
    writeln("sequenced: ", array(i.index!(0).opSlice()));
    writeln("ordered: ",array(i.index!(1).opSlice()));
    writeln("random access: ",arr(i.index!(2).opSlice()));
    writeln("heap: ",arr(i.index!(3).opSlice()));
    //pragma(msg, Sequenced!().Inner!(N,int,0).Index!().IndexMixin);
        /+
    n1.next!0 = null;
    +/

}
