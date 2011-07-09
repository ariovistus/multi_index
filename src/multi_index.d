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
 *  hashed index
 *  tagging
 *  other indeces? sparse matrix? heap?
 *  allocation?
 */

import std.array;
import std.algorithm: find;
import std.traits;
import std.range;
import std.metastrings;
import replace;
import std.typetuple: TypeTuple;
import std.functional;

/// A doubly linked list index.
template Sequenced(){
    template Inner(ThisNode, Value, size_t N){
        alias TypeTuple!(N) IndexTuple;
        alias TypeTuple!(N) NodeTuple;

        /// node implementation (ish)

        mixin template NodeMixin(size_t N){
            typeof(this)* next, prev;
        }

        // index implementation 

        /// mixin requirements: whatever mixes this in better have
        /// ThisNode aliased to the node type and Value aliased to the 
        /// value type and available symbol[ish]s _InsertAllBut!N, _replace, 
        /// _RemoveAllBut!N, node_count
        mixin template IndexMixin(size_t N){
            ThisNode* _front, _back;

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
                    _front = _front.index!N.next;
                }

                void popBack(){
                    _back = _back.index!N.prev;
                }
            }

            @property size_t length(){
                return node_count;
            }

            @property bool empty(){
                return node_count == 0;
            }

            Range opSlice(){
                return Range(_front, _back);
            }

            const(Value) front(){
                return _front.value;
            }

            void front(const(Value) value){
                _replace(_front, value);
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

            const(Value) back(){
                return _back.value;
            }
            void back(const(Value) value){
                _replace(_back, value);
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

            /// Inserts stuff into the front of the sequence.
            /// will always succeed unless another index cannot
            /// accept an element in stuff
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
                        SequencedIndex._insertNext(node, prev);
                        prev = node;
                        count ++;
                    }
                    return count;
                }

            /// Inserts stuff into the front of the sequence.
            /// inserts as many elements of stuff as possible, returning
            /// a range of the items which could not be inserted
            // auto insertFront_BestEffort

            /// Inserts value into the front of the sequence, if no other
            /// index rejects value
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
            /// inserts stuff into the front of the sequence
            size_t insertBack (SomeRange)(SomeRange range)
                if(isInputRange!SomeRange && 
                        isImplicitlyConvertible!(ElementType!SomeRange, const(Value)))
                {
                    size_t count = 0;

                    foreach(item; range){
                        count += insertBack(item);
                    }
                    return count;
                }

            size_t insertBack(SomeValue)(SomeValue value)
                if(isImplicitlyConvertible!(SomeValue, const(Value))){
                    ThisNode* node = _InsertAllBut!N(value);
                    if (!node) return 0;
                    _insertBack(node);
                    return 1;
                }

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

            /// reckon we'll trust n is somewhere between
            /// _front and _back
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

            void removeFront(){
                ThisNode* node = _removeFront();
                _RemoveAllBut!N(node);
            }

            ThisNode* _removeBack()
                in{
                    assert(_back !is null);
                    assert(_front !is null);
                }body{
                    ThisNode* n = _back;
                    if(_back == _front){
                        _back = _front = null;
                    }else{
                        _back = _back.index!N.prev;
                        n.index!N.prev = null;
                        _back.index!N.next = null;
                    }
                    return n;
                }

            void removeBack(){
                ThisNode* node = _removeBack();
                _RemoveAllBut!N(node);
            }

            alias removeBack removeAny;

            Range linearRemove(Range range)
                in{
                    // range had better belong to this container
                    if(range._front !is _front && range._back !is _back){
                        ThisNode* node = _front;
                        while(node !is range._front){
                            node = node.index!N.next;
                        }
                        assert(node is range._front);
                    }
                }body{
                    if(range._front is _front){
                        foreach(item; range){
                            ThisNode* node = _removeFront();
                            _RemoveAllBut!N(node);
                        }
                    }else if(range._back is _back){
                        foreach(item; retro(range)){
                            ThisNode* node = _removeBack();
                            _RemoveAllBut!N(node);
                        }
                    }else{
                        ThisNode* prev = range._front.index!N.prev;
                        foreach(item; range){
                            ThisNode* node = _removeNext(prev); // == node
                            _RemoveAllBut!N(node);
                        }
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
    template Inner(ThisNode, Value, size_t N){
        alias TypeTuple!() NodeTuple;
        alias TypeTuple!(N) IndexTuple;
        /// node implementation (ish)

        // all the overhead is in the index
        mixin template NodeMixin(){
        }

        mixin template Index(size_t N){
            ThisNode*[] ra;
            size_t _length;

            struct Range{
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

            Range opSlice (){
                return Range(ra[0 .. _length]);
            }

            Range opSlice(size_t a, size_t b){
                return Range(ra[0 .. _length][a .. b]);
            }

            @property size_t length(){
                return node_count;
            }

            @property bool empty(){
                return node_count == 0;
            }

            size_t capacity(){
                return ra.length;
            }

            void reserve(size_t count){
                if(ra.length < count){
                    ra.length = count;
                }
            }

            const(Value) front(){
                return ra[0].value;
            }

            void front(const(Value) value){
                _replace(ra[0], value);
            }

            const(Value) back(){
                return ra[_length-1].value;
            }

            void back(const(Value) value){
                _replace(ra[_length-1], value);
            }


            void clear(){
                assert(0);
            }

            const(Value) opIndex(size_t i){
                return ra[0 .. _length][i].
            }

            const(Value) opIndexAssign(size_t i, const(Value) value){
                _replace(ra[0 .. _length][i], value);
                return ra[0 .. _length][i].value;
            }

            void swapAt( size_t i, size_t j){
                auto r = ra[0 .. _length];
                swap(r[i], r[j]);
            }

            const(Value) removeAny(){
                _RemoveAllBut!N(ra[_length-1]);
                const(Value) value = ra[_length-1].value;
                _length--;
                clear(ra[_length]);
                return value;
            }

    removeAny  // removes element $-1 ?
    stableRemoveAny

    insertBack
    insert
    stableInsertBack 

    removeBack
    stableRemoveBack

    insertAfter ( Range, stuff )  // not container primitive ?? eqiv to splice
    insertBefore ( Range, stuff )  // not container primitive ?? eqiv to splice

    linearRemove ( Range )
    stableLinearRemove
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

mixin template OrderedIndex(size_t N, bool allowDuplicates, alias KeyFromValue, alias Compare){
    alias ThisNode* Node;
    alias binaryFun!Compare _less;
    alias unaryFun!KeyFromValue key;

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
     * The range type for $(D RedBlackTree)
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
    private Node _find(Elem e)
    {
        static if(allowDuplicates)
        {
            Node cur = _end.index!N.left;
            Node result = null;
            auto k = key(e);
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
            auto k = key(e);
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

    private void _find2(Elem e, out bool found, out Node par)
    {
        Node cur = _end.index!N.left;
        par = null;
        found = false;
        auto k = key(e);
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
            return _find(e) !is null;
        }

    /**
     * Removes all elements from the container.
     *
     * Complexity: $(BIGOH 1)
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
     * Complexity: $(BIGOH log(n))
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
     * Complexity: $(BIGOH m * log(n))
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
     * Complexity: $(BIGOH log(n))
     */
    Elem removeAny()
    {
        auto n = _end.index!N.leftmost;
        auto result = n.value;
        _RemoveAllBut!N(n);
        n.index!N.remove(_end);
        version(RBDoChecks)
            check();
        return result;
    }

    /**
     * Remove the front element from the container.
     *
     * Complexity: $(BIGOH log(n))
     */
    void removeFront()
    {
        auto n = _end.index!N.leftmost;
        _RemoveAllBut!N(n);
        n.index!N.remove(_end);
        version(RBDoChecks)
            check();
    }

    /**
     * Remove the back element from the container.
     *
     * Complexity: $(BIGOH log(n))
     */
    void removeBack()
    {
        auto n = _end.index!N.prev;
        _RemoveAllBut!N(n);
        n.index!N.remove(_end);
        version(RBDoChecks)
            check();
    }

    /++
        Removes the given range from the container.

        Returns: A range containing all of the elements that were after the
        given range.

        Complexity: $(BIGOH m * log(n)) (where m is the number of elements in
                the range)
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

        Complexity: $(BIGOH m * log(n)) (where m is the number of elements in
                the range)
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

                  Complexity: $(BIGOH m log(n)) (where m is the number of elements to remove)

                  Examples:
                  --------------------
                  auto rbt = redBlackTree!true(0, 1, 1, 1, 4, 5, 7);
    rbt.removeKey(1, 4, 7);
    assert(std.algorithm.equal(rbt[], [0, 1, 1, 5]));
    rbt.removeKey(1, 1, 0);
    assert(std.algorithm.equal(rbt[], [5]));
    --------------------
    +/
    size_t removeKey(U)(U[] elems...)
    if(isImplicitlyConvertible!(U, typeof(key(Elem.init))))
    {
        size_t count = 0;

        foreach(e; elems)
        {
            auto beg = _firstGreaterEqual(e);
            if(beg is _end || _less(e, key(beg.value)))
                // no values are equal
                continue;
            _RemoveAllBut!N(beg);
            beg.index!N.remove(_end);
            count++;
        }

        return count++;
    }

    /++ Ditto +/
    size_t removeKey(Stuff)(Stuff stuff)
    if(isInputRange!Stuff &&
            isImplicitlyConvertible!(ElementType!Stuff, Elem) &&
            !is(Stuff == Elem[]))
    {
        //We use array in case stuff is a Range from this RedBlackTree - either
        //directly or indirectly.
        return removeKey(array(stuff));
    }

    // find the first node where the value is > e
    private Node _firstGreater(U)(U e)
    if(isImplicitlyConvertible!(U, typeof(key(Elem.init))))
    {
        // can't use _find, because we cannot return null
        auto cur = _end.index!N.left;
        auto result = _end;
        while(cur)
        {
            if(_less(e, key(cur.value)))
            {
                result = cur;
                cur = cur.index!N.left;
            }
            else
                cur = cur.index!N.right;
        }
        return result;
    }

    // find the first node where the value is >= e
    private Node _firstGreaterEqual(U)(U e)
    if(isImplicitlyConvertible!(U, typeof(key(Elem.init))))
    {
        // can't use _find, because we cannot return null.
        auto cur = _end.index!N.left;
        auto result = _end;
        while(cur)
        {
            if(_less(key(cur.value), e))
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
     * Get a range from the container with all elements that are > e according
     * to the less comparator
     *
     * Complexity: $(BIGOH log(n))
     */
    Range upperBound(U)(U e)
    if(isImplicitlyConvertible!(U, typeof(key(Elem.init))))
    {
        return Range(_firstGreater(e), _end);
    }

    /**
     * Get a range from the container with all elements that are < e according
     * to the less comparator
     *
     * Complexity: $(BIGOH log(n))
     */
    Range lowerBound(U)(U e)
    if(isImplicitlyConvertible!(U, typeof(key(Elem.init))))
    {
        return Range(_end.index!N.leftmost, _firstGreaterEqual(e));
    }

    /**
     * Get a range from the container with all elements that are == e according
     * to the less comparator
     *
     * Complexity: $(BIGOH log(n))
     */
    Range equalRange(Elem e)
    {
        auto beg = _firstGreaterEqual(key(e));
        if(beg is _end || _less(key(e), key(beg.value)))
            // no values are equal
            return Range(beg, beg);
        static if(allowDuplicates)
        {
            return Range(beg, _firstGreater(key(e)));
        }
        else
        {
            // no sense in doing a full search, no duplicates are allowed,
            // so we just get the next node.
            return Range(beg, beg.index!N.next);
        }
    }

    Range bounds(string boundaries = "[]", U,V)(U lower, V upper)
        if(isImplicitlyConvertible!(U, typeof(key(Elem.init))) &&
           isImplicitlyConvertible!(V, typeof(key(Elem.init))))
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

template OrderedUnique(alias KeyFromValue="a", alias Compare = "a<b"){
    template Inner(ThisNode, Value, size_t N){
        alias TypeTuple!(N, false, KeyFromValue, Compare) IndexTuple;
        alias OrderedIndex IndexMixin;

        enum IndexCtorMixin = "_end = alloc();";
        /// node implementation (ish)
        alias TypeTuple!(N) NodeTuple;
        alias OrderedNodeMixin NodeMixin;
    }
}

/// A red black tree index
template OrderedNonUnique(alias KeyFromValue="a", alias Compare = "a<b"){
    template Inner(ThisNode, Value, size_t N){
        alias TypeTuple!(N, true, KeyFromValue, Compare) IndexTuple;
        alias OrderedIndex IndexMixin;

        enum IndexCtorMixin = "_end = alloc();";
        /// node implementation (ish)
        alias TypeTuple!(N) NodeTuple;
        alias OrderedNodeMixin NodeMixin;
    }
}

// end RBTree impl

/// a hash table index
template HashedUnique(alias KeyFromValue="a", alias hash = "??", alias Eq = "a==b"){
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
template HashedNonUnique(alias KeyFromValue="a", alias hash = "??", alias Eq = "a==b"){
    template Inner(ThisNode, Value, size_t N){
        template Index(){
            alias HashedIndex!(ThisNode, Value, N, 
                    KeyFromValue, hash, Eq, false) Index;
        }
        /// node implementation (ish)

        // all the overhead is in the index
        mixin template NodeMixin(size_t N){
        }
    }
}

struct IndexedBy(L...)
{
    alias L List;
}

/// A multi_index node. Holds the value of a single element,
/// plus per-node headers of each index, if any. (random_access
/// and hashed don't have per-node headers)
/// The headers are all mixed in in the same scope. To prevent
/// naming conflicts, a header field must be accessed with the number
/// of its index. Example:
/// ----
/// alias MNode!(IndexedBy!(Sequenced!(), Sequenced!(), 
///     OrderedUnique!()), int) Node;
/// Node* n1 = new Node();
/// Node* n2 = new Node();
/// n1.index!(0).next = n2;
/// n2.index!(0).prev = n1;
/// n1.index!(1).prev = n2;
/// n2.index!(1).next = n1;
/// n1.index!(2).left = n2;
/// ----
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



template HashedIndex(ThisNode,Value, size_t N, alias KeyFromValue, alias Hash, alias Eq, bool unique){
    mixin template Index(size_t N){
        Array!(ThisNode*) hashes;
    }
}

class MultiIndexContainer(IndexedBy, Value){
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

    @property size_t length(){
        return node_count;
    }

    @property bool empty(){
        return node_count == 0;
    }

    void _replace(ThisNode* node, const(Value) value){
        assert(false);
    }

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
        pragma(msg,ForEachDoInsert!(0, N).result);
        mixin(ForEachDoInsert!(0, N).result);
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

    void _RemoveAllBut(size_t N)(ThisNode* node){
        mixin(ForEachDoRemove!(0, N).result);
    }

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
                },  "$N", Format!("%s",N)) ~ 
                ForEachIndex!(N+1, L[1 .. $]).result;
        }else{
            enum result = "";
        }
    }

    enum stuff = (ForEachIndex!(0, IndexedBy.List).result);
    mixin(stuff);
}

import std.array;
import std.stdio;
import std.string: format;

struct S{
    int i;
    int j;
    string toString()const{
        return format("(%s %s)", i,j);
    }
}
void main(){
    /+
    alias MNode!(IndexedBy!(
                Sequenced!(), 
                OrderedUnique!(),
                ),int) Node;
    Node* n1 = new Node();
    Node* n2 = new Node();
    enum R = 1;
    n1.index!(0).next = n2;
    n1.index!(1).left = n2;
    +/
    alias MultiIndexContainer!(IndexedBy!(Sequenced!(), 
                OrderedNonUnique!("a")),int) C;

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
    i.index!(0).insert(2);
    i.index!(0).insert(5);
    i.index!(0).insert(5);
    i.index!(0).insert(4);
    i.index!(0).insert(3);
    i.index!(0).insert(1);
    i.index!(0).insert(9);
    i.index!(0).insert(7);
    i.index!(0).insert(8);
    i.index!(0).insert(6);
    writeln("[2,6]: ", array(i.index!(1).bounds!("[]")(2,6)));
    writeln("[2,6): ", array(i.index!(1).bounds!("[)",int,int)(2,6)));
    writeln("(2,6]: ", array(i.index!(1).bounds!("(]",int,int)(2,6)));
    writeln("(2,6): ", array(i.index!(1).bounds!("()",int,int)(2,6)));
    //pragma(msg, Sequenced!().Inner!(N,int,0).Index!().IndexMixin);
        /+
    n1.next!0 = null;
    +/

}
