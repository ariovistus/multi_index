/**
A port of Joaquín M López Muñoz' 
<a 
href="http://www.boost.org/doc/libs/1_50_0/libs/multi_index/doc/index.html"
>
_multi_index </a>
library.


compilation options: $(BR)
<b>version=PtrHackery</b> - In boost::_multi_index, Muñoz stores the color of a RB 
Tree Node in the low bit of one of the pointers with the rationale that on 
'many' architectures, pointers only point to even addresses.

Source: $(LINK https://bitbucket.org/ariovistus/multi_index/src/)
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
indeces synchronized over insertion, removal, or replacement operations 
performed on any one index.  

Each index will typically require ($(D N * ptrsize * k)) additional bytes of 
memory, for some k < 4

$(B Quick Start):

A MultiIndexContainer needs two things: a value type and a list of indeces. Put the list of indeces inside $(D IndexedBy). 

-----
alias MultiIndexContainer!(int, IndexedBy!(Sequenced!())) MyContainer;

MyContainer c = new MyContainer;
-----

If you like, you can name your indeces
-----
alias MultiIndexContainer!(int, IndexedBy!(Sequenced!(),"seq")) MyContainer;

MyContainer c = new MyContainer;
-----

Generally you do not perform operations on a MultiIndexContainer, but on one of
its indeces. Access an index by its position in IndexedBy: 
-----
auto seq_index = c.get_index!0;
-----
If you named your index, you can access it that way:
-----
auto seq_index = c.seq;
-----
Although an element is inserted into the container through a single index, 
it must appear in every index, and each index provides a $(I default insertion), which will be automatically invoked. This is relevant when an index 
provides multiple insertion methods:
-----
alias MultiIndexContainer!(int, IndexedBy!(
            Sequenced!(), "a", 
            Sequenced!(), "b")) DualList;

DualList list = new DualList();

// Sequenced defaults to insert to back
list.a.insert([1,2,3,4]);
assert(equals(list.a[], [1,2,3,4]));
assert(equals(list.b[], [1,2,3,4]));

list.a.insertFront(5);
assert(equals(list.a[], [5,1,2,3,4]));
assert(equals(list.b[], [1,2,3,4,5]));
-----

The following index types are provided:
$(BOOKTABLE,

$(TR $(TH $(D Sequenced)))

$(TR  $(TD Provides a doubly linked list view - exposes 
fast access to the front and back of the index.  Default insertion inserts to 
the back of the index $(BR)

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

$(TEXTWITHCOMMAS Supported Operations:)
$(BOOKTABLE, 
$(TR  $(TD $(D
c[]
))$(TD $(TEXTWITHCOMMAS 
Returns a bidirectional range iterating over the index.
)))
$(TR  $(TD $(D
c.front
))$(TD $(TEXTWITHCOMMAS 
Returns the first element inserted into the index
)))
$(TR  $(TD $(D
c.front = value
))$(TD $(TEXTWITHCOMMAS 
Replaces the front element in the index with value
)))
$(TR  $(TD $(D
c.back
))$(TD $(TEXTWITHCOMMAS 
Returns the last element inserted into the index
)))
$(TR  $(TD $(D
c.back = value
))$(TD $(TEXTWITHCOMMAS 
Replaces the last element in the index with value
)))
$(TR  $(TD $(D
c.modify(r, mod)
))$(TD $(TEXTWITHCOMMAS 
Executes $(D mod(r.front)) and performs any necessary fixups to the 
container's indeces. If the result of mod violates any index' invariant, 
r.front is removed from the container.
)))
$(TR  $(TD $(D
c.replace(r, value)
))$(TD $(TEXTWITHCOMMAS 
Replaces $(D r.front) with $(D value).
)))
$(TR  $(TD $(D
c.relocateFront(r, loc)
))$(TD $(TEXTWITHCOMMAS 
Moves $(D r.front) to position before $(D loc.front).
)))
$(TR  $(TD $(D
c.relocateBack(r, loc)
))$(TD $(TEXTWITHCOMMAS 
Moves $(D r.back) to position after $(D loc.back).
)))
$(TR  $(TD $(D
c.insertFront(stuff)
))$(TD $(TEXTWITHCOMMAS 
Inserts stuff to the front of the index.
)))
$(TR  $(TD $(D
c.insertBack(stuff)
))$(TD $(TEXTWITHCOMMAS 
Inserts stuff to the back of the index.
)))
$(TR  $(TD $(D
c.insert(stuff)
))$(TD $(TEXTWITHCOMMAS 
Inserts stuff to the back of the index.
)))
$(TR  $(TD $(D
c.removeFront()
))$(TD $(TEXTWITHCOMMAS 
Removes the value at the front of the index.
)))
$(TR  $(TD $(D
c.removeBack()
))$(TD $(TEXTWITHCOMMAS 
Removes the value at the back of the index.
)))
$(TR  $(TD $(D
c.removeAny()
))$(TD $(TEXTWITHCOMMAS 
Removes the value at the back of the index.
)))
$(TR  $(TD $(D
c.remove(r)
))$(TD $(TEXTWITHCOMMAS 
Removes the values in range $(D r) from the container.
)))
)

))

$(TR $(TH $(D RandomAccess)))
$(TR $(TD Provides a random access view - exposes an
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

$(TEXTWITHCOMMAS Supported Operations:)
$(BOOKTABLE, 
$(TR  $(TD $(D
c[]
))$(TD $(TEXTWITHCOMMAS 
Returns a random access range iterating over the index.
)))
$(TR  $(TD $(D
c[a .. b]
))$(TD $(TEXTWITHCOMMAS 
Returns a random access range iterating over the subrange of the index.
)))
$(TR  $(TD $(D
c.capacity
))$(TD $(TEXTWITHCOMMAS 
Returns the length of the underlying store of the index.
)))
$(TR  $(TD $(D
c.reserve(c)
))$(TD $(TEXTWITHCOMMAS 
Ensures sufficient capacity to accommodate $(D c) elements
)))
$(TR  $(TD $(D
c.front
))$(TD $(TEXTWITHCOMMAS 
Returns the first element inserted into the index
)))
$(TR  $(TD $(D
c.front = value
))$(TD $(TEXTWITHCOMMAS 
Replaces the front element in the index with value
)))
$(TR  $(TD $(D
c.back
))$(TD $(TEXTWITHCOMMAS 
Returns the last element inserted into the index
)))
$(TR  $(TD $(D
c.back = value
))$(TD $(TEXTWITHCOMMAS 
Replaces the last element in the index with value
)))
$(TR  $(TD $(D
c[i]
))$(TD $(TEXTWITHCOMMAS 
Provides const view random access to elements of the index.
)))
$(TR  $(TD $(D
c[i] = value
))$(TD $(TEXTWITHCOMMAS 
Sets element $(D i) to $(D value), unless another index refuses it.
)))
$(TR  $(TD $(D
c.swapAt(i,j)
))$(TD $(TEXTWITHCOMMAS 
Swaps elements' positions in this index only. This can be done without checks!
)))
$(TR  $(TD $(D
c.modify(r, mod)
))$(TD $(TEXTWITHCOMMAS 
Executes $(D mod(r.front)) and performs any necessary fixups to the 
container's indeces. If the result of mod violates any index' invariant, 
r.front is removed from the container.
)))
$(TR  $(TD $(D
c.replace(r, value)
))$(TD $(TEXTWITHCOMMAS 
Replaces $(D r.front) with $(D value).
)))
$(TR  $(TD $(D
c.insertFront(stuff)
))$(TD $(TEXTWITHCOMMAS 
Inserts stuff to the front of the index.
)))
$(TR  $(TD $(D
c.insertBack(stuff)
))$(TD $(TEXTWITHCOMMAS 
Inserts stuff to the back of the index.
)))
$(TR  $(TD $(D
c.insert(stuff)
))$(TD $(TEXTWITHCOMMAS 
Inserts stuff to the back of the index.
)))
$(TR  $(TD $(D
c.removeFront()
))$(TD $(TEXTWITHCOMMAS 
Removes the value at the front of the index.
)))
$(TR  $(TD $(D
c.removeBack()
))$(TD $(TEXTWITHCOMMAS 
Removes the value at the back of the index.
)))
$(TR  $(TD $(D
c.removeAny()
))$(TD $(TEXTWITHCOMMAS 
Removes the value at the back of the index.
)))
$(TR  $(TD $(D
c.linearRemove(r)
))$(TD $(TEXTWITHCOMMAS 
Removes the values in range $(D r) from the container.
)))
)

))

$(TR $(TH $(D Ordered, OrderedUnique, OrderedNonUnique))) 
$(TR $(TD Provides a 
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

$(TEXTWITHCOMMAS Supported Operations:)
$(BOOKTABLE, 
$(TR  $(TD $(D
c[]
))$(TD $(TEXTWITHCOMMAS 
Returns a bidirectional range iterating over the index.
)))
$(TR  $(TD $(D
c.front
))$(TD $(TEXTWITHCOMMAS 
Returns the first element inserted into the index
)))
$(TR  $(TD $(D
c.back
))$(TD $(TEXTWITHCOMMAS 
Returns the last element inserted into the index
)))
$(TR  $(TD $(D
k in c
))$(TD $(TEXTWITHCOMMAS 
Checks if $(D k) is in the index, where $(D k) is either an element or a key
)))
$(TR  $(TD $(D
c[k]
))$(TD $(TEXTWITHCOMMAS 
Provides const view indexed access to elements of the index. Available for Unique variant.
)))
$(TR  $(TD $(D
c.modify(r, mod)
))$(TD $(TEXTWITHCOMMAS 
Executes $(D mod(r.front)) and performs any necessary fixups to the 
container's indeces. If the result of mod violates any index' invariant, 
r.front is removed from the container.
)))
$(TR  $(TD $(D
c.replace(r, value)
))$(TD $(TEXTWITHCOMMAS 
Replaces $(D r.front) with $(D value).
)))
$(TR  $(TD $(D
c.insert(stuff)
))$(TD $(TEXTWITHCOMMAS 
Inserts stuff into the index.
)))
$(TR  $(TD $(D
c.removeFront()
))$(TD $(TEXTWITHCOMMAS 
Removes the value at the front of the index.
)))
$(TR  $(TD $(D
c.removeBack()
))$(TD $(TEXTWITHCOMMAS 
Removes the value at the back of the index.
)))
$(TR  $(TD $(D
c.removeAny()
))$(TD $(TEXTWITHCOMMAS 
Removes the value at the back of the index.
)))
$(TR  $(TD $(D
c.remove(r)
))$(TD $(TEXTWITHCOMMAS 
Removes the values in range $(D r) from the container.
)))
$(TR  $(TD $(D
c.removeKey(stuff)
))$(TD $(TEXTWITHCOMMAS 
Removes values equivalent to the given values or keys. 
)))
$(TR  $(TD $(D
c.upperBound(k)
))$(TD $(TEXTWITHCOMMAS 
Get a range with all elements $(D e) such that $(D e < k)
)))
$(TR  $(TD $(D
c.lowerBound(k)
))$(TD $(TEXTWITHCOMMAS 
Get a range with all elements $(D e) such that $(D e > k)
)))
$(TR  $(TD $(D
c.equalRange(k)
))$(TD $(TEXTWITHCOMMAS 
Get a range with all elements $(D e) such that $(D e == k)
)))
$(TR  $(TD $(D
c.bounds!("[]")(lo,hi)
))$(TD $(TEXTWITHCOMMAS 
Get a range with all elements $(D e) such that $(D lo <= e <= hi). Boundaries parameter a la <a href="http://www.d-programming-language.org/phobos/std_random.html#uniform">std.random.uniform</a>!
)))
)

))

$(TR $(TH $(D Hashed, HashedUnique, HashedNonUnique))) 
$(TR $(TD Provides a 
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

$(TEXTWITHCOMMAS Supported Operations:)
$(BOOKTABLE, 
$(TR  $(TD $(D
c[]
))$(TD $(TEXTWITHCOMMAS 
Returns a forward range iterating over the index.
)))
$(TR  $(TD $(D
c.front
))$(TD $(TEXTWITHCOMMAS 
Returns the first element in the hash. No, this isn't helpful.
)))
$(TR  $(TD $(D
k in c
))$(TD $(TEXTWITHCOMMAS 
Checks if $(D k) is in the index, where $(D k) is either an element or a key
)))
$(TR  $(TD $(D
c.contains(value)
))$(TD $(TEXTWITHCOMMAS 
Checks if $(D value) is in the index. $(BR) EMN: Wat? Wat is this doing in here?
)))
$(TR  $(TD $(D
c[k]
))$(TD $(TEXTWITHCOMMAS 
Provides const view indexed access to elements of the index. Available for Unique variant.
)))
$(TR  $(TD $(D
c.modify(r, mod)
))$(TD $(TEXTWITHCOMMAS 
Executes $(D mod(r.front)) and performs any necessary fixups to the 
container's indeces. If the result of mod violates any index' invariant, 
r.front is removed from the container.
)))
$(TR  $(TD $(D
c.replace(r, value)
))$(TD $(TEXTWITHCOMMAS 
Replaces $(D r.front) with $(D value).
)))
$(TR  $(TD $(D
c.insert(stuff)
))$(TD $(TEXTWITHCOMMAS 
Inserts stuff into the index.
)))
$(TR  $(TD $(D
c.remove(r)
))$(TD $(TEXTWITHCOMMAS 
Removes the values in range $(D r) from the container.
)))
$(TR  $(TD $(D
c.removeKey(key)
))$(TD $(TEXTWITHCOMMAS 
Removes values equivalent to $(D key). 
)))
$(TR  $(TD $(D
c.equalRange(k)
))$(TD $(TEXTWITHCOMMAS 
Get a range with all elements $(D e) such that $(D e == k)
)))
)

))

$(TR $(TH $(D Heap))) 
$(TR $(TD Provides a max heap view - exposes fast access to 
the largest element in the container as defined by predicates KeyFromValue 
and Compare.

$(TEXTWITHCOMMAS Complexities:)
$(BOOKTABLE, $(TR $(TH) $(TH))
$(TR $(TD Insertion) $(TD $(TEXTWITHCOMMAS 
i(n) = log(n) 
))) 
$(TR $(TD Removal) $(TD $(TEXTWITHCOMMAS 
d(n) = log(n)
)))
$(TR $(TD Replacement) $(TD $(TEXTWITHCOMMAS 
r(n) = log(n) if the element's position does not change, log(n) otherwise 
))))
$(TEXTWITHCOMMAS Supported Operations:)
$(BOOKTABLE, 
$(TR  $(TD $(D
c[]
))$(TD $(TEXTWITHCOMMAS 
Returns a bidirectional (EMN: wat? why?!) range iterating over the index.
)))
$(TR  $(TD $(D
c.front
))$(TD $(TEXTWITHCOMMAS 
Returns the max element in the heap. 
)))
$(TR  $(TD $(D
c.back
))$(TD $(TEXTWITHCOMMAS 
Returns some element of the heap.. probably not the max element...
)))
$(TR  $(TD $(D
c.modify(r, mod)
))$(TD $(TEXTWITHCOMMAS 
Executes $(D mod(r.front)) and performs any necessary fixups to the 
container's indeces. If the result of mod violates any index' invariant, 
r.front is removed from the container.
)))
$(TR  $(TD $(D
c.replace(r, value)
))$(TD $(TEXTWITHCOMMAS 
Replaces $(D r.front) with $(D value).
)))
$(TR  $(TD $(D
c.capacity
))$(TD $(TEXTWITHCOMMAS 
Returns the length of the underlying store of the index.
)))
$(TR  $(TD $(D
c.reserve(c)
))$(TD $(TEXTWITHCOMMAS 
Ensures sufficient capacity to accommodate $(D c) elements
)))
$(TR  $(TD $(D
c.insert(stuff)
))$(TD $(TEXTWITHCOMMAS 
Inserts stuff into the index.
)))
$(TR  $(TD $(D
c.removeFront(stuff)
))$(TD $(TEXTWITHCOMMAS 
Removes the max element in the heap.
)))
$(TR  $(TD $(D
c.removeAny(stuff)
))$(TD $(TEXTWITHCOMMAS 
Removes the max element in the heap.
)))
$(TR  $(TD $(D
c.removeBack(stuff)
))$(TD $(TEXTWITHCOMMAS 
Removes the back element in the heap. $(BR) EMN: what the heck was I smoking?
)))
)

))

)

Mutability:
Providing multiple indeces to the same data does introduce some complexities, 
though. Consider:
-----
class Value{
    int i;
    string s;
    this(int _i, string _s){
        i = _i;
        s = _s;
    }
}
alias MultiIndexContainer!(Value,
        IndexedBy!(RandomAccess!(), OrderedUnique!("a.s"))) C;

C c = new C;
auto i = c.get_index!0;

i.insert(new Value(1,"a"));
i.insert(new Value(2,"b"));
i[1].s = "a"; // bad! index 1 now contains duplicates and is in invalid state! 
-----
In general, the container must either require the user not to perform any 
damning operation on its elements (which likely will entail paranoid and 
continual checking of the validity of its indeces), or else not provide 
a mutable view of its elements. By default, multi_index chooses the 
latter (with controlled exceptions). 

Thus you are limited to modification operations for which the indeces can 
detect and perform any fixups (or possibly reject). You can use a 
remove/modify/insert workflow here, or functions modify and replace, which
each index implements. 

For modifications which are sure not to invalidate any index, you might 
simply 
cast away the constness of the returned element. This will work, 
but it is not recommended on the grounds of aesthetics (it's ew) and 
maintainability (if the code changes, it's a ticking time bomb).

Finally, if you just have to have a mutable view, include
MutableView in the MultiIndexContainer specification. This is
the least safe option (but see $(D ValueChangedSlots)), and you might make 
liberal use of the convenience function check provided by 
MultiIndexContainer, which asserts the validity of each index.

Efficiency:

To draw on an example from boost::_multi_index, suppose a collection of 
Tuple!(int,int) needs to be kept in sorted order by both elements of the tuple.
This might be accomplished by the following:
------
import std.container;
alias RedBlackTree!(Tuple!(int,int), "a[0] < b[0]") T1;
alias RedBlackTree!(Tuple!(int,int)*, "(*a)[1] < (*b)[1]") T2;

T1 tree1 = new T1;
T2 tree2 = new T2;
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
Muñoz suggests making the element type of T2 an iterator of T1 for to obviate
the need for the second search. However, this is not possible in D, as D 
espouses ranges rather than indeces. (As a side note, Muñoz proceeds to point 
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

Signals_and_Slots:

An experimental feature of multi_index. 

You can receive signals from MultiIndexContainer. Someday. Maybe. 

Provided signals:

_*crickets*

You can design your value type to signal to MultiIndexContainer. 

(Note: std.signals won't work with multi_index,
so don't bother trying)

Provided slots:

ValueChangedSlots - MultiIndexContainer receives signals from a value when value is mutated such that its position in an index may have changed.

Example:
-------

import multi_index;
import std.algorithm: moveAll;

class MyRecord{
    int _i;

    @property int i()const{ return _i; }
    @property void i(int i1){
        _i = i1;
        emit(); // MultiIndexContainer is notified that this record's 
                // position in indeces may need to be fixed
    }

    // signal impl - MultiIndexContainer will use these
    // to connect. In this example, we actually only need
    // a single slot. For a value type with M signals 
    // (differentiated with mixin aliases), there will be 
    // M slots connected.
    mixin Signals!();
}

alias MultiIndexContainer!(MyRecord,
    IndexedBy!(OrderedUnique!("a.i")),
    ValueChangedSlots!(ValueSignal!(0)), // this tells MultiIndexContainer that you want
                                      // it to use the signal defined in MyRecord.
                                      // you just need to pass in the index number.
    MutableView,
) MyContainer;

MyContainer c = new MyContainer;

// populate c

MyRecord v = c.front();

v.i = 22; // v's position in c is automatically fixed
-------

Thus, MultiIndexContainers can be kept valid automatically PROVIDED no
modifications occur other than those succeeded by a call to emit.

But what happens if a modification breaks, for example, a uniqueness 
constraint? Well, you have two options: remove the offending element 
silently, or remove it loudly (throw an exception). multi_index chooses
the latter in this case.

$(B Thread Safety):

multi_index is not designed to be used in multithreading.
Find yourself a relational database.

$(B Memory Allocation)

In C++, memory allocators are used to control how a container allocates memory. D does not have a standardized allocator interface (but will soon). Until it does, multi_index will use a
simple allocator protocol to regulate allocation of container structures. 
Define a struct with two static methods:

------
struct MyAllocator{
 T* allocate(T)(size_t i); // return pointer to chunk of memory containing i*T.sizeof bytes 
 void deallocate(T)(T* t); // release chunk of memory at t
}
------
Pass the struct type in to MultiIndexContainer:
------
alias MultiIndexContainer!(int,IndexedBy!(Sequenced!()), MyAllocator) G;
------
Two allocators are predefined in multi_index: $(B GCAllocator) (default), and $(B MallocAllocator)

Compatible_Sorting_Criteria:

Loosely, predicates C1 and C2 are compatible if a sequence sorted by C1 is
also sorted by C2 (consult 
<a 
href="http://www.boost.org/doc/libs/1_50_0/libs/multi_index/doc/reference/ord_indices.html#set_operations"
>
_multi_index
</a> for a more complete definition).

For (KeyType, CompatibleKeyType), a compatible sorting criterion 
takes the form:
-----
struct CompatibleLess{
    static:
    bool kc_less(KeyType, CompatibleKeyType);
    bool ck_less(CompatibleKeyType, KeyType);
    bool cc_less(CompatibleKeyType, CompatibleKeyType);
}
-----

*/

module multi_index;

/// A doubly linked list index.
template Sequenced() {

/**
Defines the index' primary range, which embodies a
bidirectional range 
*/
        struct SequencedRange(bool is_const) {
            static if(is_const) {
                alias const(ThisNode) Node;
                alias const(ThisContainer) Container;
            }else {
                alias ThisContainer Container;
                alias ThisNode Node;
            }
            Container c;
            Node* _front, _back;
            alias _front node;

            this(Container _c, Node* f, Node* b);

            /// _
            @property bool empty(); 

            /// _
            @property front(){
                return _front.value;
            }
            /// _
            @property back(){
                return _back.value;
            }

            /// _
            @property save(){ return this; }

            /// _
            void popFront();

            /// _
            void popBack();

            static if(!is_const) {
/**
Pops front and removes it from the container.
Does not invalidate this range.
Preconditions: !empty
Complexity: $(BIGOH d(n)), $(BR) $(BIGOH 1) for this index
*/
            void removeFront();

/**
Pops back and removes it from the container.
Does not invalidate this range.
Preconditions: !empty
Complexity: $(BIGOH d(n)), $(BR) $(BIGOH 1) for this index
*/
            void removeBack();
            }
        }

        alias TypeTuple!(N,Range) IndexTuple;
        alias TypeTuple!(N) NodeTuple;

            ThisNode* _front, _back;
            /// _
            alias Range_0!false SeqRange;
            /// _
            alias Range_0!true ConstSeqRange;

            template IsMyRange(T) {
                enum bool IsMyRange = 
                    is(T == SeqRange) || 
                    is(T == ConstSeqRange);
            }

/**
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
*/
            @property size_t length() const;

/**
Property returning $(D true) if and only if the container has no
elements.

Complexity: $(BIGOH 1)
*/
            @property bool empty() const;

/**
Fetch a range that spans all the elements in the container.

Complexity: $(BIGOH 1)
*/
            SeqRange opSlice();
            /// ditto
            ConstSeqRange opSlice()const;

/**
Complexity: $(BIGOH 1)
*/ 
            @property front() inout{
                return _front.value;
            }

/**
Complexity: $(BIGOH r(n)); $(BR) $(BIGOH 1) for this index
*/ 
            @property void front(Value value);


            /**
             * Complexity: $(BIGOH 1)
             */
            @property back() inout{
                return _back.value;
            }

            /**
             * Complexity: $(BIGOH r(n))
             */
            @property void back(Value value) ;

            void _ClearIndex() ;

            void clear();
/**
Moves moveme.front to the position before tohere.front and inc both ranges.
Probably not safe to use either range afterwards, but who knows. 
Preconditions: moveme and tohere are both ranges of the same container
Postconditions: moveme.front is incremented
Complexity: $(BIGOH 1)
*/
            void relocateFront(ref SeqRange moveme, SeqRange tohere);
/**
Moves moveme.back to the position after tohere.back and dec both ranges.
Probably not safe to use either range afterwards, but who knows. 
Preconditions: moveme and tohere are both ranges of the same container
Postconditions: moveme.back is decremented
Complexity: $(BIGOH 1)
*/
            void relocateBack(ref SeqRange moveme, SeqRange tohere);

/**
Perform mod on r.front and performs any necessary fixups to container's 
indeces. If the result of mod violates any index' invariant, r.front is
removed from the container.
Preconditions: !r.empty, $(BR)
mod is a callable of the form void mod(ref Value) 
Complexity: $(BIGOH m(n)), $(BR) $(BIGOH 1) for this index 
*/

            void modify(SomeRange, Modifier)(SomeRange r, Modifier mod)
            if(is(SomeRange == SeqRange) || 
                    is(SomeRange == typeof(retro(SeqRange.init)))); 

/**
Replaces r.front with value
Returns: whether replacement succeeded
Complexity: ??
*/
            bool replace(SomeRange)(SomeRange r, Value value)
            if(is(SomeRange == SeqRange) || 
                    is(SomeRange == typeof(retro(SeqRange.init))));

            bool _insertFront(ThisNode* node) nothrow;

            alias _insertBack _Insert;

            bool _insertBack(ThisNode* node) nothrow;

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
                            ValueView));

/++
Inserts value into the front of the sequence, if no other index rejects value
Returns:
The number if elements inserted into the index.
Complexity: $(BIGOH i(n)); $(BR) $(BIGOH 1) for this index
+/
            size_t insertFront(SomeValue)(SomeValue value)
                if(isImplicitlyConvertible!(SomeValue, ValueView));

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
                        isImplicitlyConvertible!(ElementType!SomeRange, ValueView));

/++
Inserts value into the back of the sequence, if no other index rejects value
Returns:
The number if elements inserted into the index.
Complexity: $(BIGOH i(n)); $(BR) $(BIGOH 1) for this index
+/
            size_t insertBack(SomeValue)(SomeValue value)
                if(isImplicitlyConvertible!(SomeValue, ValueView));

/++
Forwards to insertBack
+/
            alias insertBack insert;

            // reckon we'll trust n is somewhere between _front and _back
            void _Remove(ThisNode* n);

            ThisNode* _removeFront();

/++
Removes the value at the front of the index from the container. 
Precondition: $(D !empty)
Complexity: $(BIGOH d(n)); $(BIGOH 1) for this index
+/
            void removeFront();

/++
Removes the value at the back of the index from the container. 
Precondition: $(D !empty)
Complexity: $(BIGOH d(n)); $(BR) $(BIGOH 1) for this index
+/
            void removeBack();
/++
Forwards to removeBack
+/
            alias removeBack removeAny;

/++
Removes the values of r from the container.
Preconditions: r came from this index
Complexity: $(BIGOH n $(SUB r) * d(n)), $(BR) $(BIGOH n $(SUB r)) for this index
+/
            SeqRange remove(R)(R r)
            if(is(R == SeqRange) || is(R == Take!SeqRange));

            void _Check();

            string toString0();

            private SeqRange fromNode(ThisNode* n);

    }

/// A random access index.
template RandomAccess() {
        alias TypeTuple!() NodeTuple;
        alias TypeTuple!(N,ThisContainer) IndexTuple;

            ThisNode*[] ra;

            template IsMyRange(T) {
                enum bool IsMyRange = is(T == Range);
            }

            /// Defines the index' primary range, which embodies a
            /// random access range 
            struct RARangeT(bool is_const){
                static if(is_const) {
                    alias const(ThisNode) Node;
                    alias const(ThisContainer) Container;
                }else {
                    alias ThisContainer Container;
                    alias ThisNode Node;
                }
                Container c;
                size_t s, e;

                this(Container _c, size_t _s, size_t _e) {
                    c = _c;
                    s = _s;
                    e = _e;
                }

                @property Node* node();

                /// _
                @property front(){ 
                    assert(s < e && e <= c.index!N.length);
                    return c.index!N.ra[s].value; 
                }

                /// _
                void popFront();

                static if(!is_const) {
/**
Pops front and removes it from the container.
Does not invalidate this range.
Preconditions: !empty
Complexity: $(BIGOH d(n)), $(BR) $(BIGOH n) for this index
*/
                void removeFront();
                }

                /// _
                @property bool empty()const;
                /// _
                @property size_t length()const;

                /// _
                @property back(){ 
                    assert(s < e && e <= c.index!N.length);
                    return c.index!N.ra[e-1].value;
                }

                /// _
                void popBack();

                static if(!is_const) {
/**
Pops front and removes it from the container.
Does not invalidate this range.
Preconditions: !empty
Complexity: $(BIGOH d(n)), $(BR) $(BIGOH n) for this index
*/
                void removeBack();
                }

                /// _
                @property save(){ return this; }

                /// _
                auto opIndex(size_t i){ return c.index!N.ra[i].value; }
            }

/**
Fetch a range that spans all the elements in the container.

Complexity: $(BIGOH 1)
*/
            RARange opSlice ();
            /// ditto
            ConstRARange opSlice () const;

/**
Fetch a range that spans all the elements in the container from
index $(D a) (inclusive) to index $(D b) (exclusive).
Preconditions: a <= b && b <= length

Complexity: $(BIGOH 1)
*/
            RARange opSlice(size_t a, size_t b);
            /// ditto
            ConstRARange opSlice(size_t a, size_t b) const;

/**
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
*/
            @property size_t length()const;

/**
Property returning $(D true) if and only if the container has no elements.

Complexity: $(BIGOH 1)
*/
            @property bool empty() const;

/**
Returns the _capacity of the index, which is the length of the
underlying store 
*/
            @property size_t capacity() const;

/**
Ensures sufficient capacity to accommodate $(D count) elements.

Postcondition: $(D capacity >= count)

Complexity: $(BIGOH ??) if $(D e > capacity),
otherwise $(BIGOH 1).
*/
            void reserve(size_t count);

/**
Complexity: $(BIGOH 1)
*/
            @property front() inout{
                return ra[0].value;
            }

/**
Complexity: $(BIGOH r(n)); $(BR) $(BIGOH 1) for this index
*/
            @property void front(ValueView value);

/**
Complexity: $(BIGOH 1)
*/
            @property back() inout{
                return ra[node_count-1].value;
            }

/**
Complexity: $(BIGOH r(n)); $(BR) $(BIGOH 1) for this index
*/
            @property void back(ValueView value);

            void _ClearIndex();

            /// _
            void clear();

/**
Preconditions: i < length
Complexity: $(BIGOH 1)
*/
            auto opIndex(size_t i) inout{
                enforce(i < length);
                return ra[i].value;
            }
/**
Sets index i to value, unless another index refuses value
Preconditions: i < length
Returns: the resulting _value at index i
Complexity: $(BIGOH r(n)); $(BR) $(BIGOH 1) for this index
*/
            ValueView opIndexAssign(ValueView value, size_t i);

/**
Swaps element at index $(D i) with element at index $(D j).
Preconditions: i < length && j < length
Complexity: $(BIGOH 1)
*/
            void swapAt( size_t i, size_t j);

/**
Removes the last element from this index.
Preconditions: !empty
Complexity: $(BIGOH d(n)); $(BR) $(BIGOH 1) for this index
*/
            void removeBack();

            alias removeBack removeAny;

            void _Remove(ThisNode* n);

/**
inserts value in the back of this index.
Complexity: $(BIGOH i(n)), $(BR) amortized $(BIGOH 1) for this index
*/
            size_t insertBack(SomeValue)(SomeValue value)
            if(isImplicitlyConvertible!(SomeValue, ValueView));

/**
inserts elements of r in the back of this index.
Complexity: $(BIGOH n $(SUB r) * i(n)), $(BR) amortized $(BIGOH n $(SUB r)) 
for this index
*/
            size_t insertBack(SomeRange)(SomeRange r)
            if(isImplicitlyConvertible!(ElementType!SomeRange, ValueView));

            void _Insert(ThisNode* node);

/**
inserts elements of r in the back of this index.
Complexity: $(BIGOH n $(SUB r) * i(n)), $(BR) amortized $(BIGOH n $(SUB r)) 
for this index
*/
            alias insertBack insert;

/**
Perform mod on r.front and performs any necessary fixups to container's 
indeces. If the result of mod violates any index' invariant, r.front is
removed from the container.
Preconditions: !r.empty, $(BR)
mod is a callable of the form void mod(ref Value) 
Complexity: $(BIGOH m(n)), $(BR) $(BIGOH 1) for this index 
*/

            void modify(SomeRange, Modifier)(SomeRange r, Modifier mod)
            if(is(SomeRange == RARange) || 
                    is(SomeRange == typeof(retro(RARange.init)))) ;
/**
Replaces r.front with value
Returns: whether replacement succeeded
Complexity: ??
*/
            bool replace(SomeRange)(SomeRange r, ValueView value)
            if(is(SomeRange == RARange) || 
                    is(SomeRange == typeof(retro(RARange.init))));

/**
removes elements of r from this container.
Complexity: $(BIGOH n $(SUB r) * d(n)), $(BR) $(BIGOH n)
for this index
*/
            RARange linearRemove(Range)(Range r)
            if(IsMyRange!Range);

            void _Check();

            string toString0();

            private RARange fromNode(ThisNode* n);
}

/// A red black tree index
template Ordered(bool allowDuplicates = false, alias KeyFromValue="a", 
        alias Compare = "a<b") {

    enum bool BenefitsFromSignals = true;

    alias ThisNode* Node;
    alias binaryFun!Compare _less;
    alias unaryFun!KeyFromValue key;
    alias typeof(key(Value.init)) KeyType;

    /**
     * The range type for this index, which embodies a bidirectional range
     */
    struct OrderedRangeT(bool is_const)
    {
        static if(is_const) {
            alias const(ThisNode) Node;
            alias const(ThisContainer) Container;
        }else {
            alias ThisContainer Container;
            alias ThisNode Node;
        }
        Container c;   
        private Node* _begin;
        alias _begin node;
        private Node* _end;

        this(Container _c, Node* b, Node* e) {
            c = _c;
            _begin = b;
            _end = e;
        }

        /**
         * Returns $(D true) if the range is _empty
         */
        @property bool empty() const;

        /**
         * Returns the first element in the range
         */
        @property front() 
        {
            return _begin.value;
        }

        /**
         * Returns the last element in the range
         */
        @property back() 
        {
            return _end.index!N.prev.value;
        }

        /**
         * pop the front element from the range
         *
         * complexity: amortized $(BIGOH 1)
         */
        void popFront();

        /**
         * pop the back element from the range
         *
         * complexity: amortized $(BIGOH 1)
         */
        void popBack();
        static if(!is_const) {
/**
Pops front and removes it from the container.
Does not invalidate this range.
Preconditions: !empty
Complexity: $(BIGOH d(n)), $(BR) $(BIGOH log(n)) for this index
*/
        void removeFront();
/**
Pops back and removes it from the container.
Does not invalidate this range.
Preconditions: !empty
Complexity: $(BIGOH d(n)), $(BR) $(BIGOH log(n)) for this index
*/
        void removeBack();
        }

        /**
         * Trivial _save implementation, needed for $(D isForwardRange).
         */
        @property save()
        {
            return this;
        }
    }
    /// _
    alias OrderedRangeT!true ConstOrderedRange;
    /// _
    alias OrderedRangeT!false OrderedRange;

    template IsMyRange(T) {
        enum bool IsMyRange = 
            is(T == OrderedRange) || 
            is(T == ConstOrderedRange);
    }

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
            version(RBDoChecks) _Check();
            return added;
        }
        else
        {
            if(added)
                n.index!N.setColor(_end);
            version(RBDoChecks) _Check();
            return added;
        }
    }

    /**
     * Element type for the tree
     */
    alias ValueView Elem;

    Node   _end;

    static if(!allowDuplicates){
        bool _DenyInsertion(Node n, out Node cursor);
    }

    static if(allowDuplicates) alias _add _Insert;
    else void _Insert(Node n, Node cursor);


    // if k exists in this index, returns par such that eq(key(par.value),k), 
    // and returns true
    // if k !exists in this index, returns par such that k value belongs either
    // as par.left or par.right. remember to setColor! returns false.
    private bool _find2(KeyType k, out inout(ThisNode)* par) inout;

    private bool _find2At(KeyType k, Node cur, out Node par);

    /**
     * Check if any elements exist in the container.  Returns $(D true) if at least
     * one element exists.
     * Complexity: $(BIGOH 1)
     */
    @property bool empty() const;

/++
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
+/
        @property size_t length()const;

    /**
     * Fetch a range that spans all the elements in the container.
     *
     * Complexity: $(BIGOH log(n))
     */
    OrderedRange opSlice();
    /// ditto
    ConstOrderedRange opSlice() const;

    /**
     * The front element in the container
     *
     * Complexity: $(BIGOH log(n))
     */
    @property front() inout
    {
        return _end.index!N.leftmost.value;
    }

    /**
     * The last element in the container
     *
     * Complexity: $(BIGOH log(n))
     */
    @property back() inout
    {
        return _end.index!N.prev.value;
    }

    /++
        $(D in) operator. Check to see if the given element exists in the
        container.

        Complexity: $(BIGOH log(n))
        +/
        bool opBinaryRight(string op)(Elem e) const if (op == "in");
    /++
        $(D in) operator. Check to see if the given element exists in the
        container.

        Complexity: $(BIGOH log(n))
        +/
        static if(!isImplicitlyConvertible!(KeyType, Elem)){
            bool opBinaryRight(string op,K)(K k) if (op == "in" &&
                    isImplicitlyConvertible!(K, KeyType));
        }

    void _ClearIndex() ;

    /**
     * Removes all elements from the container.
     *
     * Complexity: ??
     */
    void clear();

    static if(!allowDuplicates){
/**
Available for Unique variant.
Complexity:
$(BIGOH log(n))
*/
        ValueView opIndex(KeyType k) inout;
    }

/**
Perform mod on r.front and performs any necessary fixups to container's 
indeces. If the result of mod violates any index' invariant, r.front is
removed from the container.
Preconditions: !r.empty, $(BR)
mod is a callable of the form void mod(ref Value) 
Complexity: $(BIGOH m(n)), $(BR) $(BIGOH log(n)) for this index 
*/

    void modify(SomeRange, Modifier)(SomeRange r, Modifier mod)
    if(is(SomeRange == Range)) ;
/**
Replaces r.front with value
Returns: whether replacement succeeded
Complexity: ??
*/
    bool replace(Range r, ValueView value) ;

    KeyType _NodePosition(ThisNode* node);

    // cursor = null -> no fixup needed
    // cursor != null -> fixup needed
    bool _PositionFixable(ThisNode* node, KeyType oldPosition, 
            out ThisNode* cursor);

    void _FixPosition(ThisNode* node, KeyType oldPosition, ThisNode* cursor);

    // n's value has changed and its position might be invalid.
    // remove n if it violates an invariant.
    // returns: true iff n's validity has been restored
    bool _NotifyChange(Node node);

    /**
     * Insert a single element in the container.  Note that this does not
     * invalidate any ranges currently iterating the container.
     *
     * Complexity: $(BIGOH i(n)); $(BR) $(BIGOH log(n)) for this index
     */
    size_t insert(Stuff)(Stuff stuff) 
        if (isImplicitlyConvertible!(Stuff, Elem));

    /**
     * Insert a range of elements in the container.  Note that this does not
     * invalidate any ranges currently iterating the container.
     *
     * Complexity: $(BIGOH n $(SUB stuff) * i(n)); $(BR) $(BIGOH n $(SUB 
     stuff) * log(n)) for this index
     */
    size_t insert(Stuff)(Stuff stuff) 
        if(isInputRange!Stuff && 
                isImplicitlyConvertible!(ElementType!Stuff, Elem));

    Node _Remove(Node n);

    /**
     * Remove an element from the container and return its value.
     *
     * Complexity: $(BIGOH d(n)); $(BR) $(BIGOH log(n)) for this index
     */
    Elem removeAny() ;

    /**
     * Remove the front element from the container.
     *
     * Complexity: $(BIGOH d(n)); $(BR) $(BIGOH log(n)) for this index
     */
    void removeFront() ;

    /**
     * Remove the back element from the container.
     *
     * Complexity: $(BIGOH d(n)); $(BR) $(BIGOH log(n)) for this index
     */
    void removeBack() ;

    /++
        Removes the given range from the container.

        Returns: A range containing all of the elements that were after the
        given range.

        Complexity:$(BIGOH n $(SUB r) * d(n)); $(BR) $(BIGOH n $(SUB r) * 
                log(n)) for this index
    +/
    OrderedRange remove(OrderedRange r);
    /// ditto
    OrderedRange remove(Take!OrderedRange r);

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
    alias MultiIndexContainer!(int, IndexedBy!(OrderedNonUnique!())) C;
    C c = new C();
    auto rbt = c.get_index!0;
    rbt.insert([0, 1, 1, 1, 4, 5, 7]);
    rbt.removeKey(1, 4, 7);
    assert(std.algorithm.equal(rbt[], [0, 1, 1, 5]));
    rbt.removeKey(1, 1, 0);
    assert(std.algorithm.equal(rbt[], [5]));
    --------------------
    +/
    size_t removeKey(Keys...)(Keys keys)
    if(allSatisfy!(implicitlyConverts,Keys));

    /// ditto
    size_t removeKey(Key)(Key[] keys)
    if(isImplicitlyConvertible!(Key, KeyType));
    
    private template implicitlyConverts(Key){
        enum implicitlyConverts = isImplicitlyConvertible!(Key,KeyType);
    }

    /++ Ditto +/
    size_t removeKey(Stuff)(Stuff stuff)
    if(isInputRange!Stuff &&
            isImplicitlyConvertible!(ElementType!Stuff, KeyType) &&
            !isDynamicArray!Stuff);

    // find the first node where the value is > k
    private inout(ThisNode)* _firstGreater(U)(U k) inout
    if(isImplicitlyConvertible!(U, KeyType));

    // find the first node where the value is >= k
    private inout(ThisNode)* _firstGreaterEqual(U)(U k) inout
    if(isImplicitlyConvertible!(U, KeyType));

    /**
     * Get a range from the container with all elements that are > k according
     * to the less comparator
     *
     * Complexity: $(BIGOH log(n))
     */
    auto upperBound(U)(U k)
    if(isImplicitlyConvertible!(U, KeyType));
    /// ditto
    auto upperBound(U)(U k) const 
    if(isImplicitlyConvertible!(U, KeyType));

    /**
     * Get a range from the container with all elements that are > k according
     * to the compatible sorting criterion.
     *
     * Complexity: $(BIGOH log(n))
     */
    auto upperBound(CompatibleLess, CompatibleKey)(CompatibleKey k);
    /// ditto
    auto upperBound(CompatibleLess, CompatibleKey)(CompatibleKey k) const;
    /**
     * Get a range from the container with all elements that are < k according
     * to the less comparator
     *
     * Complexity: $(BIGOH log(n))
     */
    auto lowerBound(U)(U k)
    if(isImplicitlyConvertible!(U, KeyType));
    /// ditto
    auto lowerBound(U)(U k) const
    if(isImplicitlyConvertible!(U, KeyType));
    /**
     * Get a range from the container with all elements that are < k according
     * to the compatible sorting criterion.
     *
     * Complexity: $(BIGOH log(n))
     */
    auto lowerBound(CompatibleLess, CompatibleKey)(CompatibleKey k);
    /// ditto
    auto lowerBound(CompatibleLess, CompatibleKey)(CompatibleKey k) const;

    /**
     * Get a range from the container with all elements that are == k according
     * to the less comparator
     *
     * Complexity: $(BIGOH log(n))
     */
    auto equalRange(U)(U k)
    if(isImplicitlyConvertible!(U, KeyType));
    /// ditto
    auto equalRange(U)(U k) const
    if(isImplicitlyConvertible!(U, KeyType));

    /**
     * Get a range from the container with all elements that are == k according
     * to the compatible sorting criterion.
     *
     * Complexity: $(BIGOH log(n))
     */
    OrderedRange cEqualRange(CompatibleLess, CompatibleKey)(CompatibleKey k)
    if(IsCompatibleLess!(CompatibleLess, KeyType, CompatibleKey));
    /// ditto
    ConstOrderedRange cEqualRange(CompatibleLess, CompatibleKey)(CompatibleKey k) const
    if(IsCompatibleLess!(CompatibleLess, KeyType, CompatibleKey));
/++
Get a range of values bounded below by lower and above by upper, with
inclusiveness defined by boundaries.
Complexity: $(BIGOH log(n))
+/
    auto bounds(string boundaries = "[]", U)(U lower, U upper)
    if(isImplicitlyConvertible!(U, KeyType));

/++
Get a range of values bounded below by lower and above by upper, with
inclusiveness defined by boundaries.
Complexity: $(BIGOH log(n))
+/
    auto bounds(CompatibleLess, string boundaries = "[]", CompatibleKey)
    (CompatibleKey lower, CompatibleKey upper)
    if(IsCompatibleLess!(CompatibleLess, KeyType, CompatibleKey));

        /*
         * Print the tree.  This prints a sideways view of the tree in ASCII form,
         * with the number of indentations representing the level of the nodes.
         * It does not print values, only the tree structure and color of nodes.
         */
        void printTree(Node n, int indent = 0);

        /*
         * Check the tree for validity.  This is called after every add or remove.
         * This should only be enabled to debug the implementation of the RB Tree.
         */
        void _Check();

        string toString0();
        
        private OrderedRange fromNode(ThisNode* n);
}

/// A red black tree index
template OrderedNonUnique(alias KeyFromValue="a", alias Compare = "a<b") {
    alias Ordered!(true, KeyFromValue, Compare) OrderedNonUnique;
}
/// A red black tree index
template OrderedUnique(alias KeyFromValue="a", alias Compare = "a<b") {
    alias Ordered!(false, KeyFromValue, Compare) OrderedUnique;
}

/// a max heap index
template Heap(alias KeyFromValue = "a", alias Compare = "a<b") {
        alias TypeTuple!() NodeTuple;
        alias TypeTuple!(N,KeyFromValue, Compare, ThisContainer) IndexTuple;

            alias unaryFun!KeyFromValue key;
            alias binaryFun!Compare less;
            alias typeof(key((Value).init)) KeyType;

            /// The primary range of the index, which embodies a bidirectional
            /// range. Ends up performing a breadth first traversal (I think..)
            /// removeFront and removeBack are not possible.
            struct HeapRangeT(bool is_const){
                static if(is_const) {
                    alias const(ThisNode) Node;
                    alias const(ThisContainer) Container;
                }else {
                    alias ThisContainer Container;
                    alias ThisNode Node;
                }
                Container c;
                size_t s,e;

                this(Container _c, size_t _s, size_t _e) {
                    c = _c;
                    s = _s;
                    e = _e;
                }

                @property Node* node();

                /// _
                @property front(){ 
                    return c.index!N._heap[s].value; 
                }

                /// _
                void popFront();

                /// _
                @property back(){
                    return c.index!N._heap[e-1].value; 
                }
                /// _
                void popBack();

                /// _
                @property bool empty()const;
                /// _
                @property size_t length()const;

                /// _
                @property save(){ return this; }
            }

            /// _
            alias HeapRangeT!true ConstHeapRange;
            /// _
            alias HeapRangeT!false HeapRange;

            template IsMyRange(T) {
                enum bool IsMyRange = 
                    is(T == ConstHeapRange) ||
                    is(T == HeapRange);
            }

            ThisNode*[] _heap;

            static size_t p(size_t n) pure;

            static size_t l(size_t n) pure;

            static size_t r(size_t n) pure;

            void swapAt(size_t n1, size_t n2);

            void sift(size_t n);



/**
Fetch a range that spans all the elements in the container.

Complexity: $(BIGOH 1)
*/
            HeapRange opSlice();
            /// ditto
            ConstHeapRange opSlice() const;

/**
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
*/
            @property size_t length()const;

/**
Property returning $(D true) if and only if the container has no
elements.

Complexity: $(BIGOH 1)
*/
            @property bool empty()const;

/**
Returns: the max element in this index
Complexity: $(BIGOH 1)
*/ 
            @property front() inout{
                return _heap[0].value;
            }
/**
Returns: the back of this index
Complexity: $(BIGOH 1)
*/ 
            @property back() inout{
                return _heap[node_count-1].value;
            }

            void _ClearIndex();
/**
??
*/
            void clear();

/**
Perform mod on r.front and performs any necessary fixups to container's 
indeces. If the result of mod violates any index' invariant, r.front is
removed from the container.
Preconditions: !r.empty, $(BR)
mod is a callable of the form void mod(ref Value) 
Complexity: $(BIGOH m(n)), $(BR) $(BIGOH log(n)) for this index 
*/

            void modify(SomeRange, Modifier)(SomeRange r, Modifier mod)
            if(IsMyRange!SomeRange) ;
/**
Replaces r.front with value
Returns: whether replacement succeeded
Complexity: ??
*/
            bool replace(HeapRange r, ValueView value);

            KeyType _NodePosition(ThisNode* node);

            bool _PositionFixable(ThisNode* node, KeyType oldPosition, 
                    out ThisNode* cursor);

            void _FixPosition(ThisNode* node, KeyType oldPosition, 
                    ThisNode* cursor);

            bool _NotifyChange(ThisNode* node);

/**
Returns the _capacity of the index, which is the length of the
underlying store 
*/
            size_t capacity()const;

/**
Ensures sufficient capacity to accommodate $(D n) elements.

Postcondition: $(D capacity >= n)

Complexity: $(BIGOH ??) if $(D e > capacity),
otherwise $(BIGOH 1).
*/
            void reserve(size_t count);
/**
Inserts value into this heap, unless another index refuses it.
Returns: the number of values added to the container
Complexity: $(BIGOH i(n)); $(BR) $(BIGOH log(n)) for this index
*/
            size_t insert(SomeValue)(SomeValue value)
            if(isImplicitlyConvertible!(SomeValue, ValueView));

            size_t insert(SomeRange)(SomeRange r)
            if(isImplicitlyConvertible!(ElementType!SomeRange, ValueView));

            void _Insert(ThisNode* node);

/**
Removes the max element of this index from the container.
Complexity: $(BIGOH d(n)); $(BR) $(BIGOH log(n)) for this index
*/
            void removeFront();

            void _Remove(ThisNode* node);
/**
Forwards to removeFront
*/
            alias removeFront removeAny;


/**
* removes the back of this index from the container. Why would you do this? 
No idea.
Complexity: $(BIGOH d(n)); $(BR) $(BIGOH 1) for this index
*/
            void removeBack();

            HeapRange remove(R)(R r)
            if (is(R == HeapRange) || is(R == Take!HeapRange));

            bool isLe(size_t a, size_t b);

            bool _invariant(size_t i);

            void _Check();

            void printHeap();

            void printHeap1(size_t n, size_t indent);

            string toString0();

            private HeapRange fromNode(ThisNode* n);
}

/// a hash table index
///
/// KeyFromValue(value) = key of type KeyType
///
/// Hash(key) = hash of type size_t (on Hash = "??", uses D's default hashing mechanism)
///
/// Eq(key1, key2) determines equality of key1, key2
template Hashed(bool allowDuplicates = false, alias KeyFromValue="a", 
        alias Hash="??", alias Eq="a==b") {
    // this index allocates the table, and an array in removeKey

        alias unaryFun!KeyFromValue key;
        alias typeof(key(Value.init)) KeyType;
        static if (Hash == "??") {
            static if(is(typeof(KeyType.init.toHash()))) {
                enum _Hash = "a.toHash()";
            }else{
                enum _Hash = "typeid(a).getHash(&a)";
            }
        }else{
            enum _Hash = Hash;
        }

        alias TypeTuple!(N) NodeTuple;
        alias TypeTuple!(N,KeyFromValue, _Hash, Eq, allowDuplicates, 
                Sequenced!().Inner!(ThisContainer, ThisNode,Value,ValueView,N,Allocator).Range, 
                ThisContainer) IndexTuple;
        // node implementation 
        // could be singly linked, but that would make aux removal more 
        // difficult
        alias Sequenced!().Inner!(ThisContainer, ThisNode, Value, ValueView,N,Allocator).NodeMixin 
            NodeMixin;

        enum IndexCtorMixin = Replace!(q{
            index!$N .hashes = Allocator.allocate!(ThisNode*)(primes[0])[0 .. primes[0]];
            index!$N .load_factor = 0.80;
        }, "$N", N);

            alias unaryFun!KeyFromValue key;
            alias typeof(key((Value).init)) KeyType;
            alias unaryFun!Hash hash;
            alias binaryFun!Eq eq;

            /// the primary range for this index, which embodies a forward 
            /// range. iteration has time complexity O(n) 
            struct HashedRangeT(bool is_const){
                static if(is_const) {
                    alias const(ThisNode) Node;
                    alias const(ThisContainer) Container;
                }else {
                    alias ThisContainer Container;
                    alias ThisNode Node;
                }
                Container c;
                Node* node;
                size_t n;

                this(Container _c, Node* _node, size_t _n) {
                    c = _c;
                    node = _node;
                    n = _n;
                }

                /// _
                @property bool empty()/*const*/;

                /// _
                @property front() {
                    return node.value;
                }

                /// _
                void popFront();

                /// _
                void removeFront();

                /// _
                @property save(){
                    return this;
                }
            }
            /// _
            alias HashedRangeT!true ConstHashedRange;
            /// _
            alias HashedRangeT!false HashedRange;

            template IsMyRange(T) {
                enum bool IsMyRange = 
                    is(T == HashedRange) || 
                    is(T == ConstHashedRange) || 
                    is(T == BucketSeqRange) ||
                    is(T == ConstBucketSeqRange);
            }

            ThisNode*[] hashes;
            ThisNode* _first;
            double load_factor;

            bool isFirst(ThisNode* n);

            // sets n as the first in bucket list at index
            void setFirst(ThisNode* n, size_t index);

            void removeFirst(ThisNode* n);


/**
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
*/
            @property size_t length()const;

/**
Property returning $(D true) if and only if the container has no
elements.

Complexity: $(BIGOH 1)
*/
            @property bool empty()const;

/**
Preconditions: !empty
Complexity: $(BIGOH 1) 
*/ 
            @property front() inout{
                return _first.value;
            }
    
            void _ClearIndex();
/**
??
*/
            void clear();

/**
Gets a range of all elements in container.
Complexity: $(BIGOH 1)
*/
            HashedRange opSlice();
            /// ditto
            ConstHashedRange opSlice() const;

            // returns true iff k was found.
            // when k in hashtable:
            // node = first node in hashes[ix] such that eq(key(node.value),k)
            // when k not in hashtable:
            // node = null -> put value of k in hashes[ix]
            // or node is last node in hashes[ix] chain -> 
            //  put value of k in node.next 
            bool _find(KeyType k, out inout(ThisNode)* node, out size_t index) inout;

            static if(!allowDuplicates){
/**
Available for Unique variant.
Complexity:
$(BIGOH n) ($(BIGOH 1) on a good day)
*/
                ValueView opIndex ( KeyType k ) const;
            }

/**
Reports whether a value exists in the collection such that eq(k, key(value)).
Complexity:
$(BIGOH n) ($(BIGOH 1) on a good day)
 */
            static if(!isImplicitlyConvertible!(KeyType, ValueView)){
                bool opBinaryRight(string op)(KeyType k) const
                if (op == "in");
            }

            /// ditto
            bool opBinaryRight(string op)(ValueView value) const
            if (op == "in");

/**
Reports whether value exists in this collection
Complexity:
$(BIGOH n) ($(BIGOH n 1) on a good day)
 */
            bool contains(ValueView value) const;

            /// ditto
            bool contains(KeyType k) const;

/**
Perform mod on r.front and performs any necessary fixups to container's 
indeces. If the result of mod violates any index' invariant, r.front is
removed from the container.
Preconditions: !r.empty, $(BR)
mod is a callable either of the form void mod(ref Value) or Value mod(Value)
Complexity: $(BIGOH m(n)), $(BR) $(BIGOH n) for this index ($(BIGOH 1) on a good day)
*/

            void modify(SomeRange, Modifier)(SomeRange r, Modifier mod)
            if(IsMyRange!SomeRange);
/**
Replaces r.front with value
Returns: whether replacement succeeded
Complexity: ??
*/
            bool replace(SomeRange)(SomeRange r, ValueView value)
            if(IsMyRange!SomeRange);

            KeyType _NodePosition(ThisNode* node);

            // cursor = null -> no fixup necessary or fixup to start of chain
            // cursor != null -> fixup necessary
            bool _PositionFixable(ThisNode* node, KeyType oldPosition, 
                    out ThisNode* cursor);

            void _FixPosition(ThisNode* node, KeyType oldPosition,
                    ThisNode* cursor);

            bool _NotifyChange(ThisNode* node);


/**
Returns a range of all elements with eq(key(elem), k). 
Complexity:
$(BIGOH n) ($(BIGOH n $(SUB result)) on a good day)
 */
            BucketSeqRange equalRange( KeyType k );
            /// ditto 
            ConstBucketSeqRange equalRange( KeyType k ) const;

            static if(allowDuplicates){
                void _Insert(ThisNode* n);
            }else{
                bool _DenyInsertion(ThisNode* node, out ThisNode* cursor);
                void _Insert(ThisNode* node, ThisNode* cursor);
            }

            void _Remove(ThisNode* n);

            /// _
            @property size_t loadFactor() const;
            @property void loadFactor(size_t _load_factor);

            size_t maxLoad(size_t n);

            /// _
            @property size_t capacity() const;

            void reserve(size_t n);
/**
insert value into this container. For Unique variant, will refuse value
if value already exists in index.
Returns:
number of items inserted into this container.
Complexity:
$(BIGOH i(n)) $(BR) $(BIGOH n) for this index ($(BIGOH 1) on a good day)
*/
            size_t insert(SomeValue)(SomeValue value)
            if(isImplicitlyConvertible!(SomeValue, ValueView)) ;

/**
insert contents of r into this container. For Unique variant, will refuse 
any items in content if it already exists in index.
Returns:
number of items inserted into this container.
Complexity:
$(BIGOH i(n)) $(BR) $(BIGOH n+n $(SUB r)) for this index 
($(BIGOH n $(SUB r)) on a good day)
*/
            size_t insert(SomeRange)(SomeRange r)
            if(isImplicitlyConvertible!(ElementType!SomeRange, ValueView));

/** 
Removes all of r from this container.
Preconditions:
r came from this index
Returns:
an empty range
Complexity:
$(BIGOH n $(SUB r) * d(n)), $(BR)
$(BIGOH n $(SUB r)) for this index
*/
            HashedRange remove(R)( R r )
            if( is(R == HashedRange) || is(R == BucketSeqRange) ||
                is(R == Take!HashedRange) || is(R == Take!BucketSeqRange));

/** 
Removes all elements with key k from this container.
Returns:
the number of elements removed
Complexity:
$(BIGOH n $(SUB k) * d(n)), $(BR)
$(BIGOH n + n $(SUB k)) for this index ($(BIGOH n $(SUB k)) on a good day)
*/
version(OldWay){
            size_t removeKey(KeyType k);
}else{

            size_t removeKey(Keys...)(Keys keys)
            if(allSatisfy!(implicitlyConverts,Keys)) ;

            size_t removeKey(Key)(Key[] keys)
            if(isImplicitlyConvertible!(Key, KeyType));
    
            private template implicitlyConverts(Key){
                enum implicitlyConverts = isImplicitlyConvertible!(Key,KeyType);
            }

            /++ Ditto +/
            size_t removeKey(Stuff)(Stuff stuff)
            if(isInputRange!Stuff &&
            isImplicitlyConvertible!(ElementType!Stuff, KeyType) &&
            !isDynamicArray!Stuff) ;
}

            void _Check();

            string toString0();

            private HashedRange fromNode(ThisNode* n);
}
/// _
template HashedUnique(alias KeyFromValue="a", 
        alias Hash="??", alias Eq="a==b"){}
/// _
template HashedNonUnique(alias KeyFromValue="a", 
        alias Hash="??", alias Eq="a==b"){}

/++
Encapsulate the list of indeces to be used by the container.
---
IndexedBy!(Sequenced(), HashedUnique!())
---
Indeces may be named:
---
IndexedBy!(Sequenced(), "seq", HashedUnique!(), "hash")
---
Then they may be accessed from the container by name:
---
auto seq_index = container.seq;
---
Otherwise, an index is accessed by its index (ouch) in the list:
---
auto seq_index = container.get_index!0
---
+/
struct IndexedBy(L...);


/**
For use with MultiCompare
*/
struct ComparisonEx(alias _key, alias _less);

/**
For use with MultiCompare
*/
struct DefaultComparison(alias _less);

/**
Convenience template to compose comparison of a sequence of items. 
Consider when comparison of an object is dependent on more than one field:
-----
struct A {
    int x;
    int y;

    int opCmp(A other) {
        if(x == other.x) {
            if(y == other.y) {
                return 0;
            }else {
                return y < other.y ? -1 : 1;
            }
        }else{
            return x < other.x ? -1 : 1;
        }
    }
}
-----
Manual translation to a $(D less) function usable by appropriate indeces 
is kind of nasty:
-----
alias binaryFun!"a.x == b.x ? a.y < b.y : a.x < b.x" less;
-----
and gets progressively worse with more fields. An equvalent $(D less)
using MultiCompare:
-----
alias MultiCompare!("a.x", "a.y") less;
-----
The actual comparison operator used can be controlled on a per-field basis:
-----
alias MultiCompare!("a.x", ComparisonEx!("a.y", "a>b")) less1;
-----
Or on all subsequent fields:
-----
// equivalent to less1
alias MultiCompare!("a.x", DefaultComparison!"a>b","a.y") less2;
-----
By default, MultiCompare uses the 'a<b' less than operator.
*/
template MultiCompare(F...) {
    template NormComps(size_t i = 0, alias Dflt = "a<b") {
        static if(i == F.length) {
            alias TypeTuple!() NormComps;
        }else {
            static if(F[i].stringof.startsWith("DefaultComparison!") &&
                    __traits(compiles, F[i].less)) {
                alias NormComps!(i+1, F[i].less) NormComps;
            }else{
                static if (F[i].stringof.startsWith("ComparisonEx!") &&
                        __traits(compiles, F[i].less) &&
                        __traits(compiles, F[i].key)) {
                    alias F[i] Cmp;
                }else {
                    alias ComparisonEx!(F[i], Dflt) Cmp;
                }
                alias TypeTuple!(Cmp, NormComps!(i+1, Dflt)) NormComps;
            }
        }
    }

    alias NormComps!() Comps;

    /// _
    bool MultiCompare(T)(T a, T b) {
        foreach(i, cmp; Comps) {
            auto a1 = cmp.key(a);
            auto b1 = cmp.key(b);
            auto less = cmp.less(a1,b1);
            if(less) return true;
            auto gtr = cmp.less(b1,a1);
            if(gtr) return false;
            static if(i == Comps.length-1) {
                return false;
            }
        }
        assert(0);
    }
}

/**
  Build a compatible sorting criterion given a MultiIndexContainer index,
  a conversion from KeyType to CompatibleKeyType, and an optional 
  comparison operator over CompatibleKeyType.
*/
struct CriterionFromKey(MultiIndex, size_t index, 
        alias CompatibleKeyFromKey,
        alias CompatibleLess = "a<b");

/** 
Specifies how to hook up value signals to indeces with the semantics that 
whenever value changes in a way that will cause 
its position in index to change or become invalid, a signal is sent to the
index.
The index will respond by fixing the position, or if that is not possible,
by throwing an exception.

Pass in one or more instantiations of $(D ValueSignal). 

A signal can be shared by multiple indeces; however do not associate a signal 
to the same index more than once.
*/

struct ValueChangedSlots(L...) ;

/**
A $(D ValueSignal!(index, mixinAlias)) specifies which $(D index) receives 
signals, and how to access the value's signal interface. Of course, the 
value type must provide a signal interface, e.g. 
-----
value.connect(void delegate() slot);
value.disconnect(void delegate() slot);
-----
See $(D Signals) for an example implementation.

If a value type wishes to support multiple signal interfaces, 
mixin aliases are expected to disambiguate:
-----
value.mixinAlias.connect(void delegate() slot);
// etc
-----
If you wish to associate a signal with every index,
-----
ValueSignal!("*", mixinAlias) 
-----
may be used.
*/
struct ValueSignal(size_t index, string mixinAlias = "")
{
    enum size_t Index = index;
    enum MixinAlias = mixinAlias;
}

/// _
struct ValueSignal(string tag, string mixinAlias = "")
{
    enum Tag = tag;
    enum MixinAlias = mixinAlias;
}

/+
/++
A multi_index node. Holds the value of a single element,
plus per-node headers of each index, if any. 
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
struct MNode(ThisContainer, IndexedBy, Allocator, Signals, Value, ValueView);
+/

/// _
struct ConstView{}
/// _
struct MutableView{}

/++ 
The container. Don't call any index methods from this container directly; use
a reference to an individual index, which can be obtained via
---
container.get_index!N
container.name // for named indeces
---
+/
class MultiIndexContainer(Value, Args...) {

    alias FindIndexedBy!Args IndexedBy;
    // @@@ DMD ISSUE 6475 @@@ following gives forward reference error
    //alias FindValueChangedSlots!Args .Inner!(IndexedBy) NormSignals;
    alias typeof(FindValueChangedSlots!Args .Inner!(IndexedBy).exposeType()) NormSignals;
    alias FindConstnessView!Args ConstnessView;
    alias FindAllocator!Args Allocator;

    static if(is(ConstnessView == ConstView)){
        alias const(Value) ValueView;
    }else static if(is(ConstnessView == MutableView)){
        alias Value ValueView;
    }else static assert(false);
    alias MNode!(typeof(this), IndexedBy,Allocator,NormSignals,Value, ValueView) ThisNode;

    size_t node_count;

    template ForEachCtorMixin(size_t i){
        static if(i < IndexedBy.Indeces.length){
            static if(is(typeof(IndexedBy.Indeces[i].Inner!(typeof(this), 
                                ThisNode,Value,ValueView,i,Allocator).IndexCtorMixin))){
                enum result =  IndexedBy.Indeces[i].Inner!(typeof(this), 
                        ThisNode,Value, ValueView,i,Allocator).IndexCtorMixin ~ 
                    ForEachCtorMixin!(i+1).result;
            }else enum result = ForEachCtorMixin!(i+1).result;
        }else enum result = "";
    }

    this(){
        mixin(ForEachCtorMixin!(0).result);
    }

    void dealloc(ThisNode* node){
        // disconnect signals from slots
        foreach(i, x; NormSignals.Mixin2Index){
            foreach(j, malias; OU!(string).arr2tuple!(x.MixinAliases)){
                static if(malias == ""){
                    mixin(Replace!(q{
                        node.value.disconnect(&node.slot$i);
                    }, "$i", i));
                }else{
                    mixin(Replace!(q{
                        node.value.$alias.disconnect(&node.slot$i);
                    }, "$i", i,"$alias", malias)); 
                }
            }
        }
        object.clear(node);
        Allocator.deallocate(node);
    }

    new(size_t sz) {
        void* p = Allocator.allocate!void(sz);
        return p;
    }
    delete(void* p) {
        Allocator.deallocate(p);
    }

    template ForEachIndex(size_t N,L...){
        static if(L.length > 0){
            enum result = 
                Replace!(q{
                    alias IndexedBy.Indeces[$N] L$N;
                    alias L$N.Inner!(typeof(this),ThisNode,Value, ValueView,$N,Allocator) M$N;
                    mixin M$N.IndexMixin!(M$N.IndexTuple) index$N;
                    template index(size_t n) if(n == $N){ alias index$N index; }
                    class Index$N{

                        // grr opdispatch not handle this one
                        auto opSlice(T...)(T ts){
                            return this.outer.index!($N).opSlice(ts);
                        }

                        // grr opdispatch not handle this one
                        auto opIndex(T...)(T ts){
                            return this.outer.index!($N).opIndex(ts);
                        }

                        // grr opdispatch not handle this one
                        auto opIndexAssign(T...)(T ts){
                            return this.outer.index!($N).opIndexAssign(ts);
                        }

                        // grr opdispatch not handle this one
                        auto opBinaryRight(string op, T...)(T ts){
                            return this.outer.index!($N).opBinaryRight!(op)(ts);
                        }

                        // grr opdispatch not handle this one
                        auto bounds(string bs = "[]", T)(T t1, T t2){
                            return this.outer.index!($N).bounds!(bs,T)(t1,t2);
                        }

                        auto opDispatch(string s, T...)(T args){
                            mixin("return this.outer.index!($N)."~s~"(args);");
                        }
                    }
                    @property Index$N get_index(size_t n)() if(n == $N){
                        return this.new Index$N();
                    }
                },  "$N", N) ~ 
                ForEachIndex!(N+1, L[1 .. $]).result;
        }else{
            enum result = "";
        }
    }

    /++
     + Obtain a reference to the nth index in this container.
     +/
    @property IndexN get_index(size_t n)();

    enum stuff = (ForEachIndex!(0, IndexedBy.Indeces).result);
    mixin(stuff);

    template ForEachNamedIndex(size_t i){
        static if(i >= IndexedBy.Names.length) {
            enum result = "";
        }else {
            enum result = Replace!(q{
                alias get_index!$N $name;
            }, "$N", IndexedBy.NameIndeces[i], "$name", IndexedBy.Names[i]) ~
            ForEachNamedIndex!(i+1).result;
        }
    }

    enum named_stuff = ForEachNamedIndex!0 .result;
    mixin(named_stuff);


    template ForEachCheckInsert(size_t i, size_t N){
        static if(i < IndexedBy.Indeces.length){
            static if(i != N && is(typeof({ ThisNode* p; 
                            index!i._DenyInsertion(p,p);}))){
                enum result = (Replace!(q{
                        ThisNode* aY; 
                        bool bY = index!(Y)._DenyInsertion(node,aY);
                        if (bY) goto denied;
                }, "Y", i)) ~ ForEachCheckInsert!(i+1, N).result;
            }else enum result = ForEachCheckInsert!(i+1, N).result;
        }else enum result = "";
    }

    template ForEachDoInsert(size_t i, size_t N){
        static if(i < IndexedBy.Indeces.length){
            static if(i != N){
                static if(is(typeof({ ThisNode* p; 
                                index!i._DenyInsertion(p,p);}))){
                    enum result = Replace!(q{
                        index!(Y)._Insert(node,aY);
                    }, "Y", i) ~ ForEachDoInsert!(i+1,N).result;
                }else{
                    enum result = Replace!(q{
                        index!(Y)._Insert(node);
                    }, "Y", i) ~ ForEachDoInsert!(i+1,N).result;
                }
            }else enum result = ForEachDoInsert!(i+1, N).result;
        }else enum result = "";
    }

    ThisNode* _InsertAllBut(size_t N)(Value value){
        ThisNode* node = Allocator.allocate!(ThisNode)(1);
        node.value = value;

        // connect signals to slots
        foreach(i, x; NormSignals.Mixin2Index){
            static if(i == 0) node.container = this;

            foreach(j, malias; OU!(string).arr2tuple!(x.MixinAliases)){
                static if(malias == ""){
                    mixin(Replace!(q{
                        node.value.connect(&node.slot$i);
                    }, "$i", i));
                }else{
                    mixin(Replace!(q{
                        node.value.$alias.connect(&node.slot$i);
                    }, "$i", i,"$alias", malias));
                }
            }
        }

        // check with each index about insert op
        /+
        foreach(i, x; IndexedByList){
            /+
            static if(i != N && is(typeof({ ThisNode* p; 
                            index!i._DenyInsertion(p,p);}))){
                enum result = (Replace!(q{
                        ThisNode* aY; 
                        bool bY = index!(Y)._DenyInsertion(node,aY);
                        if (bY) goto denied;
                }, "Y", i)) ~ ForEachCheckInsert!(i+1, N).result;
            }kelse enum result = ForEachCheckInsert!(i+1, N).result;
            +/
        }
        +/
        mixin(ForEachCheckInsert!(0, N).result);
        // perform insert op on each index
        mixin(ForEachDoInsert!(0, N).result);
        node_count++;
        return node;
denied:
        return null;
    }

    template ForEachDoRemove(size_t i, size_t N){
        static if(i < IndexedBy.Indeces.length){
            static if(i != N){
                enum result = Replace!(q{
                    index!(Y)._Remove(node);
                }, "Y", i) ~ ForEachDoRemove!(i+1,N).result;
            }else enum result = ForEachDoRemove!(i+1, N).result;
        }else enum result = "";
    }

    // disattach node from all indeces except index N
    void _RemoveAllBut(size_t N)(ThisNode* node){
        mixin(ForEachDoRemove!(0, N).result);
        node_count --;
    }

    // disattach node from all indeces.
    // @@@BUG@@@ cannot pass length directly to _RemoveAllBut
    auto _RemoveAll(size_t N = -1)(ThisNode* node){
        static if(N == -1) {
            enum _grr_bugs = IndexedBy.Indeces.length;
            _RemoveAllBut!(_grr_bugs)(node);
        }else {
            _RemoveAllBut!N(node);
            auto res = index!N._Remove(node);
        }
        dealloc(node);

        static if(N != -1) {
            return res;
        }
    }

    template ForEachIndexPosition(size_t i){
        static if(i < IndexedBy.Indeces.length){
            static if(is(typeof(index!i ._NodePosition((ThisNode*).init)))){
                enum ante = Replace!(q{
                    auto pos$i = index!$i ._NodePosition(node);
                }, "$i", i) ~ ForEachIndexPosition!(i+1).ante;
                enum post = Replace!(q{
                    ThisNode* node$i;
                    if(!index!$i ._PositionFixable(node, pos$i, node$i)) 
                        goto denied;
                }, "$i", i) ~ ForEachIndexPosition!(i+1).post;
                enum postpost = Replace!(q{
                    index!$i ._FixPosition(node, pos$i, node$i);
                }, "$i", i) ~ ForEachIndexPosition!(i+1).postpost;
            }else{
                enum ante = ForEachIndexPosition!(i+1).ante;
                enum post = ForEachIndexPosition!(i+1).post;
                enum postpost = ForEachIndexPosition!(i+1).postpost;
            }
        }else{
            enum ante = "";
            enum post = "";
            enum postpost = "";
        }
    }


    bool _Replace(ThisNode* node, Value value){
        mixin(ForEachIndexPosition!0 .ante);
        Value old = node.value;
        node.value = value;
        mixin(ForEachIndexPosition!0 .post);
        mixin(ForEachIndexPosition!0 .postpost);
        return true;
denied:
        node.value = old;
        return false;
    }

/*
Perform mod on node.value and perform any necessary fixups to this container's 
indeces. mod may be of the form void mod(ref Value), in which case mod directly modifies the value in node. If the result of mod violates any index' invariant,
the node is removed from the container. 
Preconditions: mod is a callable of the form void mod(ref Value) 
Complexity: $(BIGOH m(n)) 
*/
    void _Modify(Modifier)(ThisNode* node, Modifier mod){
        mixin(ForEachIndexPosition!0 .ante);
        mod(node.value);
        mixin(ForEachIndexPosition!0 .post);
        mixin(ForEachIndexPosition!0 .postpost);
        return;
denied:
        _RemoveAll(node);
    }

    template ForEachClear(size_t i){
        static if(i < IndexedBy.Indeces.length){
            enum string result = Replace!(q{
                index!$i ._ClearIndex();
            }, "$i", i) ~ ForEachClear!(i+1).result;
        }else enum string result = "";
    }

    void _Clear(){
        auto r = index!0 .opSlice();
        while(!r.empty){
            ThisNode* node = r.node;
            r.popFront();
            dealloc(node);
        }
        mixin(ForEachClear!0 .result);
        node_count = 0;
    }

    template ForEachCheck(size_t i){
        static if(i < IndexedBy.Indeces.length){
            enum result = Replace!(q{
                index!($i)._Check();
            },"$i", i) ~ ForEachCheck!(i+1).result;
        }else{
            enum result = "";
        }
    }

    /**
      Test each index for consistency. Don't expect this to be a quick operation.
    */
    void check(){
        mixin(ForEachCheck!(0).result);
    }

    template ForEachAlias(size_t N,size_t index, alias X){
        alias X.Inner!(ThisNode,Value, ValueView,N,Allocator).Index!() Index;
        static if(Index.container_aliases.length > index){
            enum aliashere = NAliased!(Index.container_aliases[index][0], 
                    Index.container_aliases[index][1], N);
            enum result = aliashere ~ "\n" ~ ForEachAlias!(N,index+1, X).result;
        }else{
            enum result = "";
        }
    }


    /++ 
     + Similar to C++ multi_index's project function.
     + Converts r to a range of type index!N .Range,
     + guaranteeing that result.front == r.front.
     +/
    @property auto to_range(size_t N, Range0)(Range0 r)
    if(RangeIndexNo!Range0 != -1){
        static if(N == RangeIndexNo!Range0){
            return r;
        }else{
            return index!N.fromNode(r.node);
        }
    }

    private template RangeIndexNo(R){
        template IndexNoI(size_t i){
            static if(i == IndexedBy.Indeces.length){
                enum size_t IndexNoI = -1;
            }else static if(index!(i).IsMyRange!(R)){
                pragma(msg, Format!("%s is index!%s.Range (%s)",R.stringof,i, (index!(i).Range).stringof));
                enum size_t IndexNoI = i;
            }else{
                pragma(msg, Format!("%s is not index!%s.Range (%s)",R.stringof,i,(index!(i).Range).stringof));
                enum IndexNoI = IndexNoI!(i+1);
            }
        }
        enum size_t RangeIndexNo = IndexNoI!(0);
    }
}

/++ 
 + Simple signal implementation, which can be used in conjunction with
 + 
 + * ValueChangedSlots: In your value type, call emit when (after) the value has been mutated and its position in the index may have changed
 +/
mixin template Signal() {
    void delegate()[] slots;

    /// _
    void connect(void delegate() slot){
        slots ~= slot;
    }
    /// _
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
    /// _
    void emit(){
        foreach(slot; slots){
            slot();
        }
    }
}
