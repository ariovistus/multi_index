module multi_index;

import std.metastrings;
import replace;

template Sequenced(){
    template Inner(ThisNode, Value, int N){
        template Index(){
            alias SequencedIndex!(ThisNode, Value, N) Index;
        }
        /// node implementation (ish)

        enum next = Format!("_next%s",N);
        enum prev = Format!("_prev%s",N);

        // need unique vars for to avoid conflicts
        enum NodeMixin = Format!("typeof(this)* _next%s, _prev%s;", N,N);

        enum node_aliases = [
            ["next", Format!("_next%s",N)], 
            ["prev", Format!("_prev%s",N)],
        ];
    }
}

template RandomAccess(){
    template Inner(ThisNode, Value, int N){
        template Index(){
            alias RandomAccessIndex!(ThisNode, Value, N) Index;
        }
        /// node implementation (ish)

        // all the overhead is in the index
        enum NodeMixin = "";

        enum string[][] node_aliases = [];
    }
}

//////////// Red Black Tree impl stuff /////////////

/**
 * Enumeration determining what color the node is.  Null nodes are assumed
 * to be black.
 */
enum Color : byte
{
    Red,
    Black
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
Node* rotateR(size_t N, Node)(Node* t)
    in
    {
        assert(t._left!(N) !is null);
    }
    body
    {
        // sets _left._parent also
        if(isLeftNode!N(t))
            t.parent!N.left!N = t._left!N;
        else
            t.parent!N.right!N = t._left!N;
        Node* tmp = t._left!N._right!N;

        // sets _parent also
        t._left!N.right!N = &this;

        // sets tmp._parent also
        t.left!N = tmp;

        return t;
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
Node* rotateL(size_t N, Node)(Node* t)
    in
    {
        assert(t._right!(N) !is null);
    }
    body
    {
        // sets _right._parent also
        if(isLeftNode!N(t))
            t.parent!N.left!N = t._right!N;
        else
            t.parent!N.right!N = _right!N;
        Node* tmp = t._right!N._left!N;

        // sets _parent also
        t._right!N.left!N = &this;

        // sets tmp._parent also
        t.right!N = tmp;
        return &this;
    }


/**
 * Returns true if this node is a left child.
 *
 * Note that this should always return a value because the root has a
 * parent which is the marker node.
 */
bool isLeftNode(size_t N, Node)(Node* t) const
    in
    {
        assert(t._parent!(N) !is null);
    }
    body
    {
        return t._parent!N._left!N is t;
    }

/**
 * Set the color of the node after it is inserted.  This performs an
 * update to the whole tree, possibly rotating nodes to keep the Red-Black
 * properties correct.  This is an O(lg(n)) operation, where n is the
 * number of nodes in the tree.
 *
 * end is the marker node, which is the parent of the topmost valid node.
 */
void setColor(size_t N, Node)(Node* t, Node* end)
{
    // test against the marker node
    if(t._parent!(N) !is end)
    {
        if(t._parent!N.color!N == Color.Red)
        {
            Node* cur = t;
            while(true)
            {
                // because root is always black, _parent._parent always exists
                if(isLeftNode(cur._parent!N))
                {
                    // parent is left node, y is 'uncle', could be null
                    Node* y = cur._parent!N._parent!N._right!N;
                    if(y !is null && y.color!N == Color.Red)
                    {
                        cur._parent!N.color!N = Color.Black;
                        y.color!N = Color.Black;
                        cur = cur._parent!N._parent!N;
                        if(cur._parent!N is end)
                        {
                            // root node
                            cur.color!N = Color.Black;
                            break;
                        }
                        else
                        {
                            // not root node
                            cur.color!N = Color.Red;
                            if(cur._parent!N.color!N == Color.Black)
                                // satisfied, exit the loop
                                break;
                        }
                    }
                    else
                    {
                        if(!isLeftNode(cur))
                            cur = rotateL!N(cur._parent!N);
                        cur._parent!N.color!N = Color.Black;
                        cur = rotateR!N(cur._parent!N._parent!N);
                        cur.color!N = Color.Red;
                        // tree should be satisfied now
                        break;
                    }
                }
                else
                {
                    // parent is right node, y is 'uncle'
                    Node* y = cur._parent!N._parent!N._left!N;
                    if(y !is null && y.color!N == Color.Red)
                    {
                        cur._parent!N.color!N = Color.Black;
                        y.color!N = Color.Black;
                        cur = cur._parent!N._parent!N;
                        if(cur._parent is end)
                        {
                            // root node
                            cur.color!N = Color.Black;
                            break;
                        }
                        else
                        {
                            // not root node
                            cur.color!N = Color.Red;
                            if(cur._parent!N.color!N == Color.Black)
                                // satisfied, exit the loop
                                break;
                        }
                    }
                    else
                    {
                        if(isLeftNode!N(cur))
                            cur = rotateR!N(cur._parent);
                        cur._parent!N.color!N = Color.Black;
                        cur = rotateL!N(cur._parent!N._parent!N);
                        cur.color!N = Color.Red;
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
        t.color!N = Color.Black;
    }
}

/**
 * Remove this node from the tree.  The 'end' node is used as the marker
 * which is root's parent.  Note that this cannot be null!
 *
 * Returns the next highest valued node in the tree after this one, or end
 * if this was the highest-valued node.
 */
Node* remove(size_t N,Node)(Node* t, Node* end)
{
    //
    // remove this node from the tree, fixing the color if necessary.
    //
    Node* x;
    Node* ret;
    if(t._left!N is null || t._right!N is null)
    {
        ret = next!N(t);
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
        Node* yp, yl, yr;
        Node* y = next(t);
        yp = y._parent!N;
        yl = y._left!N;
        yr = y._right!N;
        auto yc = y.color!N;
        auto isyleft = isLeftNode!N(y);

        //
        // replace y's structure with structure of this node.
        //
        if(isLeftNode!N(t))
            t._parent!N.left!N = y;
        else
            t._parent!N.right!N = y;
        //
        // need special case so y doesn't point back to itself
        //
        y.left!N = t._left!N;
        if(t._right!N is y)
            y.right!N = t;
        else
            y.right!N = t._right!N;
        y.color!N = t.color!N;

        //
        // replace this node's structure with structure of y.
        //
        t.left!N = yl;
        t.right!N = yr;
        if(t._parent!(N) !is y)
        {
            if(isyleft)
                yp.left!N = t;
            else
                yp.right!N = t;
        }
        t.color!N = yc;

        //
        // set return value
        //
        ret = y;
    }

    // if this has less than 2 children, remove it
    if(t._left!(N) !is null)
        x = t._left!N;
    else
        x = t._right!N;

    // remove this from the tree at the end of the procedure
    bool removeThis = false;
    if(x is null)
    {
        // pretend this is a null node, remove this on finishing
        x = t;
        removeThis = true;
    }
    else if(isLeftNode!N(t))
        t._parent!N.left!N = x;
    else
        t._parent!N.right!N = x;

    // if the color of this is black, then it needs to be fixed
    if(t.color!N == Color.Black)
    {
        // need to recolor the tree.
        while(x._parent!(N) !is end && x.color!N == Color.Black)
        {
            if(isLeftNode!N(x))
            {
                // left node
                Node* w = x._parent!N._right!N;
                if(w.color!N == Color.Red)
                {
                    w.color!N = Color.Black;
                    x._parent!N.color!N = Color.Red;
                    x._parent!N.rotateL!N();
                    w = x._parent!N._right!N;
                }
                Node* wl = w.left!N;
                Node* wr = w.right!N;
                if((wl is null || wl.color!N == Color.Black) &&
                        (wr is null || wr.color!N == Color.Black))
                {
                    w.color!N = Color.Red;
                    x = x._parent!N;
                }
                else
                {
                    if(wr is null || wr.color!N == Color.Black)
                    {
                        // wl cannot be null here
                        wl.color!N = Color.Black;
                        w.color!N = Color.Red;
                        rotateR!N(w);
                        w = x._parent!N._right!N;
                    }

                    w.color!N = x._parent!N.color!N;
                    x._parent!N.color!N = Color.Black;
                    w._right!N.color!N = Color.Black;
                    rotateL!N(x._parent!N);
                    x = end.left!N; // x = root
                }
            }
            else
            {
                // right node
                Node* w = x._parent!N._left!N;
                if(w.color!N == Color.Red)
                {
                    w.color!N = Color.Black;
                    x._parent!N.color!N = Color.Red;
                    rotateR!N(x._parent!N);
                    w = x._parent!N._left!N;
                }
                Node* wl = w.left!N;
                Node* wr = w.right!N;
                if((wl is null || wl.color!N == Color.Black) &&
                        (wr is null || wr.color!N == Color.Black))
                {
                    w.color!N = Color.Red;
                    x = x._parent!N;
                }
                else
                {
                    if(wl is null || wl.color!N == Color.Black)
                    {
                        // wr cannot be null here
                        wr.color!N = Color.Black;
                        w.color!N = Color.Red;
                        rotateL!N(w);
                        w = x._parent!N._left!N;
                    }

                    w.color!N = x._parent!N.color!N;
                    x._parent!N.color!N = Color.Black;
                    w._left!N.color!N = Color.Black;
                    rotateR!N(x._parent!N);
                    x = end.left!N; // x = root
                }
            }
        }
        x.color!N = Color.Black;
    }

    if(removeThis)
    {
        //
        // clear this node out of the tree
        //
        if(isLeftNode)
            _parent!N.left!N = null;
        else
            _parent!N.right!N = null;
    }

    return ret;
}

/**
 * Return the leftmost descendant of this node.
 */
Node* leftmost(size_t N, Node)(Node* t)
{
    Node* result = t;
    while(result._left!(N) !is null)
        result = result._left!N;
    return result;
}

/**
 * Return the rightmost descendant of this node
 */
Node rightmost(size_t N,Node)(Node* t)
{
    Node* result = t;
    while(result._right!(N) !is null)
        result = result._right!N;
    return result;
}

/**
 * Returns the next valued node in the tree.
 *
 * You should never call this on the marker node, as it is assumed that
 * there is a valid next node.
 */
Node* next(size_t N, Node)(Node* t)
{
    Node* n = t;
    if(n.right!N is null)
    {
        while(!isLeftNode!N(n))
            n = n._parent!N;
        return n._parent!N;
    }
    else
        return leftmost!N(n.right!N);
}

/**
 * Returns the previous valued node in the tree.
 *
 * You should never call this on the leftmost node of the tree as it is
 * assumed that there is a valid previous node.
 */
Node* prev(size_t N,Node)(Node* t)
{
    Node* n = t;
    if(n.left!N is null)
    {
        while(isLeftNode!N(n))
            n = n._parent!N;
        return n._parent!N;
    }
    else
        return rightmost!N(n.left);
}


template OrderedNodeImpl(ThisNode, Value, int N, 
        alias keyFromValue, alias less, bool unique){
    // need unique vars for to avoid conflicts
    enum NodeMixin = Replace!(q{
        typeof(this)* _left, _right, _parent;
        Color color;
        @property typeof(this)* left() { return _left; }
        @property typeof(this)* right() { return _right; }
        @property typeof(this)* parent() { return _parent; }
    },  "left", Format!("left%s",N),
        "color", Format!("color%s",N),
        "right", Format!("right%s",N),
        "parent", Format!("parent%s",N)) ~
    Replace!(q{
        @property typeof(this)* left(typeof(this)* newNode)
        {
            _left = newNode;
            if(newNode !is null)
            newNode._parent = &this;
            return newNode;
        }
        @property typeof(this)* right(typeof(this)* newNode)
        {
            _right = newNode;
            if(newNode !is null)
            newNode._parent = &this;
            return newNode;
        }
    },  "left", Format!("left%s",N),
        "right", Format!("right%s",N),
        "parent", Format!("parent%s",N));

    enum node_aliases = [
        ["_parent", Format!("_parent%s",N)], 
        ["_left", Format!("_left%s",N)],
        ["_right", Format!("_right%s",N)],
        ["color", Format!("color%s",N)],
        ["parent", Format!("parent%s",N)], 
        ["left", Format!("left%s",N)],
        ["right", Format!("right%s",N)],
    ];
}

template OrderedUnique(alias KeyFromValue="a", alias less = "a<b"){
    template Inner(ThisNode, Value, int N){
        template Index(){
            alias OrderedIndex!(ThisNode, Value, N, KeyFromValue, less, true) 
                Index;
        }
        /// node implementation (ish)
        alias OrderedNodeImpl!(ThisNode, Value, N, KeyFromValue, less, true) 
            NodeImpl;
        alias NodeImpl.node_aliases node_aliases;
        alias NodeImpl.NodeMixin NodeMixin;

    }
}

template OrderedNonUnique(alias KeyFromValue="a", alias less = "a<b"){
    template Index(ThisNode, Value, int N){
        alias OrderedIndex!(ThisNode, Value, N, KeyFromValue, less, false) 
            Index;
    }

    alias OrderedNodeImpl!(ThisNode, Value, KeyFromValue, less, true) NodeImpl;
    alias NodeImpl.node_aliases node_aliases;
    alias NodeImpl.NodeMixin NodeMixin;
}

template HashedUnique(alias KeyFromValue="a", alias hash = "??", alias Eq = "a==b"){
    template Index(ThisNode, Value, int N){
        alias HashedIndex!(ThisNode, Value, N, KeyFromValue, hash, Eq, true) 
            Index;
    }

    mixin template NodeMixin(ThisNode, Value, int N){
        // empty
    }
}

template HashedNonUnique(alias KeyFromValue="a", alias hash = "??", alias Eq = "a==b"){
    template Index(ThisNode, Value, int N){
        alias HashedIndex!(ThisNode, Value, N, KeyFromValue, hash, Eq, false) 
            Index;
    }

    mixin template NodeMixin(ThisNode, Value, int N){
        // empty
    }
}

struct IndexedBy(L...)
{
    alias L List;

}

struct MNode(IndexedBy, Value){
    const(Value) value;

    template NAliased(string _alias, string _orig, int N){
        enum NAliased = Format!(
                "template %s(int N) if(N == %s){ alias %s %s; }",
                _alias, N, _orig, _alias);
        //pragma(msg, NAliased);
    }

    template ForEachAlias(size_t N,size_t index, alias X){
        alias X.Inner!(typeof(this),Value,N) Inner;
        static if(Inner.node_aliases.length > index){
            enum aliashere = NAliased!(Inner.node_aliases[index][0], 
                    Inner.node_aliases[index][1], N);
            enum result = aliashere ~ "\n" ~ ForEachAlias!(N,index+1, X).result;
        }else{
            enum result = "";
        }
    }

    template ForEachIndex(int N,L...){
        static if(L.length > 0){
            enum result = L[0].Inner!(typeof(this), Value, N).NodeMixin ~ "\n"
                ~ ForEachAlias!(N,0,L[0]).result 
                ~ ForEachIndex!(N+1,L[1 .. $]).result;
        }else{
            enum result = "";
        }
    }

    enum stuff = ForEachIndex!(0, IndexedBy.List).result;
    pragma(msg, stuff);
    mixin(stuff);
}

mixin template SequencedIndex(ThisNode,Value, int N){
    // need unique vars for to avoid conflicts
    // aliases can conflict ?!
    mixin(Format!("ThisNode* _front%s, _back%s
            alias _front%s _front;
            alias _back%s _back;", N, N, N, N));

    /// length - container keeps track of this in node_count
    /// empty - ditto


    /// implement the BidirectionalRange interface
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
            current = current.next!N;
        }

        void popBack(){
            current = current.prev!N;
        }
    }

    this(){
        _front = null;
        _back = null;
    }

    @property size_t length (){
        // hope mixin can see this
        return node_count;
    }

    Range opSlice( ){
        return Range(_front, _back);
    }

    //size_t insert ( OtherRange ) 

    const(Value) front(){
        return _front.value;
    }

    void front(const(Value) value){
        _front.value = value;
    }

    const(Value) back(){
        return _back.value;
    }
    void back(const(Value) value){
        _back.value = value;
    }

    bool empty(){
        // hope mixin can see this
        return node_count == 0;
    }

    void clear(){
        // todo
        assert (0);
    }

    // todo
    // opDollar

    // todo (or not)
    // opBinary!"~"  ?

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

    bool _insertBack(ThisNode* node) nothrow
    in{
        debug assert (node !is null);
    }body{
        if(_front is null){
            debug assert(_back is null);
            _front = _back = node;
        }else{
            _insertNext(node, _back);
            _back = next;
        }

        return true;
    }

    void _insertNext(ThisNode* node, ThisNode* prev) nothrow
    in{
        debug assert(prev !is null);
        debug assert(node !is null);
    }body{
        ThisNode* next = prev.next!N;
        prev.next!N = node;
        node.prev!N = prev;
        if(next !is null) next.prev!N = node;
        node.next!N = next;
    }

    void _insertPrev(ThisNode* node, ThisNode* next) nothrow
    in{
        debug assert(node !is null);
        debug assert(next !is null);
    }body{
        ThisNode* prev = next.prev!N;
        if(prev !is null) prev.next!N = node;
        node.prev!N = prev;
        next.prev!N = node;
        node.next!N = next;
    }

    /// Inserts stuff into the front of the sequence.
    /// will always succeed unless another index cannot
    /// accept an element in stuff, in which case a
    /// CannotInsertItemsException will be thrown
    size_t insertFront(SomeRange)(SomeRange stuff)
    if(isInputRange!SomeRange && 
            isImplicitlyConvertible!(ElementType!SomeRange, const(Value))){
        if(stuff.empty) return 0;
        size_t count = 0;
        try{
            ThisNode* prev = _insertAllBut!N(stuff.front);
            _insertFront(prev);
            stuff.popFront();
            foreach(item; stuff){
                ThisNode* node = _insertAllBut!N(item);
                _insertNext(node, prev);
                prev = node;
                count ++;
            }
            return count;
        }catch(CannotInsertItemException ex){
            throw new CannotInsertItemsException(ex, count);
        }
    }

    /// Inserts stuff into the front of the sequence.
    /// inserts as many elements of stuff as possible, returning
    /// a range of the items which could not be inserted
    // auto insertFront_BestEffort

    /// Inserts value into the front of the sequence.
    /// will always succeed, unless another index cannot accept value,
    /// in which case throws a CannotInsertItemException
    size_t insertFront(SomeValue)(SomeValue value)
    if(isImplicitlyConvertible!(SomeValue, const(Value))){
        ThisNode* node = _insertAllBut!N(value);
        auto inserted = _insertFront(node);
        return inserted;
    }

    // todo
    // stableInsert
    // todo
    // stableInsertFront
    /// inserts stuff into the front of the sequence
    size_t insertBack (SomeRange)(SomeRange range)
    if(isInputRange!SomeRange && 
            isImplicitlyConvertible!(ElementType!SomeRange, const(Value))){
        size_t count = 0;

        try{
            foreach(item; range){
                insertBack(item);
                count ++;
            }
            return count;
        }catch(CannotInsertItemException ex){
            throw new CannotInsertItemsException(ex, count);
        }
    }
    /+
    insertBack ( RangeStuff )
    insert
    stableInsertBack
    insertAfter ( Range, Stuff )
    stableInsertAfter
    insertBefore ( Range, Stuff )
    stableInsertAfter

    removeAny  // removes element $-1 ?
    stableRemoveAny 
    removeFront 
    stableRemoveFront
    removeBack 
    stableRemoveBack
    linearRemove ( Range )
    stableLinearRemove
    +/
}

template RandomAccessIndex(ThisNode,Value, int N){
    enum ra = Format!("_ra%s",N);
    mixin template mixme(){
        mixin Format!("Array!(ThisNode*) %s;", ra);
    }

    enum indexed_aliases = [
        ["ra", ra],
    ];

}

template OrderedIndex(ThisNode,Value, 
        int N, alias keyFromValue, alias less, bool unique){
    enum root = Format!("_root%s",N);
    mixin template mixme(){
        mixin(Format("ThisNode* %s;",root));
    }

    enum indexed_aliases = [
        ["root",root],
    ];
}

mixin template HashedIndex(ThisNode,Value, int N, alias KeyFromValue, alias Hash, alias Eq, bool unique){
    Array!(ThisNode*) hashes;
}


struct MultiIndexContainer(IndexedBy){
    /+
    alias MNode!(Stuff) ThisNode;

    size_t node_count;


    mixin List[0]
    for i,Item in List:
        mixin Item as Index!i
    +/
}

void main(){
    alias MNode!(IndexedBy!(
                Sequenced!(), 
                RandomAccess!(), 
                OrderedUnique!()),int) N;
    N* n1 = new N();
    N* n2 = new N();
    n1.next!0 = null;
}
