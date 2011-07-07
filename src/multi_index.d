module multi_index;

import std.algorithm: find;
import std.traits;
import std.range;
import std.metastrings;
import replace;

/// A doubly linked list index.
template Sequenced(){
    template Inner(ThisNode, Value, size_t N){
        template Index(){
            alias SequencedIndex!(ThisNode, Value, N) Index;
        }
        /// node implementation (ish)

        mixin template NodeMixin(size_t N){
            typeof(this)* next, prev;
        }

    }
}

/// A random access index.
template RandomAccess(){
    template Inner(ThisNode, Value, size_t N){
        template Index(){
            alias RandomAccessIndex!(ThisNode, Value, N) Index;
        }
        /// node implementation (ish)

        // all the overhead is in the index
        mixin template NodeMixin(size_t N){
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

template OrderedNodeImpl(ThisNode, Value, size_t N, 
        alias keyFromValue, alias less, bool unique){
    mixin template NodeMixin(size_t N){
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
}

template OrderedUnique(alias KeyFromValue="a", alias less = "a<b"){
    template Inner(ThisNode, Value, size_t N){
        template Index(){
            alias OrderedIndex!(ThisNode, Value, N, KeyFromValue, less, true) 
                Index;
        }
        /// node implementation (ish)
        alias OrderedNodeImpl!(ThisNode, Value, N, KeyFromValue, less, true) 
            NodeImpl;
        alias NodeImpl.NodeMixin NodeMixin;

    }
}

/// A red black tree index
template OrderedNonUnique(alias KeyFromValue="a", alias less = "a<b"){
    template Index(ThisNode, Value, size_t N){
        alias OrderedIndex!(ThisNode, Value, N, KeyFromValue, less, false) 
            Index;
    }

    alias OrderedNodeImpl!(ThisNode, Value, KeyFromValue, less, false) NodeImpl;
    alias NodeImpl.NodeMixin NodeMixin;
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
    const(Value) value;

    template ForEachIndex(size_t N,L...){
        static if(L.length > 0){
            enum indexN = Format!("index%s",N);
            alias L[0] L0;
            enum result = 
                Replace!(q{
                    alias IndexedBy.List[$N] L$N;
                    alias L$N.Inner!(typeof(this),Value,$N) M$N;
                    mixin M$N.NodeMixin!($N) index$N;
                    template index(size_t n) if(n == $N){ alias index$N index; }
                },  "$N", Format!("%s",N)) ~ 
                ForEachIndex!(N+1, L[1 .. $]).result;
        }else{
            enum result = "";
        }
    }

    enum stuff = ForEachIndex!(0, IndexedBy.List).result;
    //pragma(msg, stuff);
    mixin(stuff);
}

template SequencedIndex(ThisNode,Value, size_t N){
    /// mixin requirements: whatever mixes this in better have
    /// ThisNode aliased to the node type and Value aliased to the value type
    /// and available symbol[ish]s _InsertAllBut!N, _replace, _RemoveAllBut!N,
    /// node_count
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
        /// accept an element in stuff, in which case a
        /// CannotInsertItemsException will be thrown
        size_t insertFront(SomeRange)(SomeRange stuff)
        if(isInputRange!SomeRange && 
                isImplicitlyConvertible!(ElementType!SomeRange, const(Value)))
        {
            if(stuff.empty) return 0;
            size_t count = 0;
            try{
                ThisNode* prev = _InsertAllBut!N(stuff.front);
                _insertFront(prev);
                stuff.popFront();
                foreach(item; stuff){
                    ThisNode* node = _InsertAllBut!N(item);
                    SequencedIndex._insertNext(node, prev);
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
            ThisNode* node = _InsertAllBut!N(value);
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
                isImplicitlyConvertible!(ElementType!SomeRange, const(Value)))
        {
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

        size_t insertBack(SomeValue)(SomeValue value)
        if(isImplicitlyConvertible!(SomeValue, const(Value))){
            ThisNode* node = _InsertAllBut!N(value);
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

template RandomAccessIndex(ThisNode,Value, size_t N){
    mixin template Index(size_t N){
        Array!(ThisNode*) ra;
        // todo!
    }
}

template OrderedIndex(ThisNode,Value, size_t N){
    mixin template Index(size_t N){
        alias ThisNode* Node;
        alias binaryFun!less _less;

        // BUG: this must come first in the struct due to issue 2810

        // add an element to the tree, returns the node added, or the existing node
        // if it has already been added and allowDuplicates is false

        private auto _add(Elem n)
        {
            Node result;
            static if(!allowDuplicates)
            {
                bool added = true;
                scope(success)
                {
                    if(added)
                        ++_length;
                }
            }
            else
            {
                scope(success)
                    ++_length;
            }

            if(!_end.index!N.left)
            {
                _end.index!N.left = result = allocate(n);
            }
            else
            {
                Node newParent = _end.index!N.left;
                Node nxt = void;
                while(true)
                {
                    if(_less(n, newParent.value))
                    {
                        nxt = newParent.index!N.left;
                        if(nxt is null)
                        {
                            //
                            // add to right of new parent
                            //
                            newParent.index!N.left = result = allocate(n);
                            break;
                        }
                    }
                    else
                    {
                        static if(!allowDuplicates)
                        {
                            if(!_less(newParent.value, n))
                            {
                                result = newParent;
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
                            newParent.index!N.right = result = allocate(n);
                            break;
                        }
                    }
                    newParent = nxt;
                }
            }

            static if(allowDuplicates)
            {
                result.index!N.setColor(_end);
                version(RBDoChecks)
                    check();
                return result;
            }
            else
            {
                if(added)
                    result.index!N.setColor(_end);
                version(RBDoChecks)
                    check();
                return Tuple!(bool, "added", Node, "n")(added, result);
            }
        }

        /**
         * Element type for the tree
         */
        alias const(Value) Elem;

        private Node   _end;
        private size_t _length;

        private void _setup()
        {
            assert(!_end); //Make sure that _setup isn't run more than once.
            _end = allocate();
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
                while(cur)
                {
                    if(_less(cur.value, e))
                        cur = cur.index!N.right;
                    else if(_less(e, cur.value))
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
                    if(_less(cur.value, e))
                        cur = cur.index!N.right;
                    else if(_less(e, cur.value))
                        cur = cur.index!N.left;
                    else
                        return cur;
                }
                return null;
            }
        }

        /**
         * Check if any elements exist in the container.  Returns $(D true) if at least
         * one element exists.
         */
        @property bool empty()
        {
            return _end.index!N.left is null;
        }

        /++
            Returns the number of elements in the container.

            Complexity: $(BIGOH 1).
            +/
            @property size_t length()
            {
                return _length;
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
            _end.index!N.left = null;
            _length = 0;
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
            static if(allowDuplicates)
            {
                _add(stuff);
                return 1;
            }
            else
            {
                return(_add(stuff).added ? 1 : 0);
            }
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
            static if(allowDuplicates)
            {
                foreach(e; stuff)
                {
                    ++result;
                    _add(e);
                }
            }
            else
            {
                foreach(e; stuff)
                {
                    if(_add(e).added)
                        ++result;
                }
            }
            return result;
        }

        /// ditto
        alias stableInsert insert;

        /**
         * Remove an element from the container and return its value.
         *
         * Complexity: $(BIGOH log(n))
         */
        Elem removeAny()
        {
            scope(success)
                --_length;
            auto n = _end.index!N.leftmost;
            auto result = n.value;
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
            scope(success)
                --_length;
            _end.index!N.leftmost.index!N.remove(_end);
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
            scope(success)
                --_length;
            _end.index!N.prev.index!N.remove(_end);
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
                b = b.index!N.remove(_end);
                --_length;
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
                b = b.index!N.remove(_end);
                --_length;
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
        if(isImplicitlyConvertible!(U, Elem))
        {
            immutable lenBefore = length;

            foreach(e; elems)
            {
                auto beg = _firstGreaterEqual(e);
                if(beg is _end || _less(e, beg.value))
                    // no values are equal
                    continue;
                beg.index!N.remove(_end);
                --_length;
            }

            return lenBefore - length;
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
        private Node _firstGreater(Elem e)
        {
            // can't use _find, because we cannot return null
            auto cur = _end.index!N.left;
            auto result = _end;
            while(cur)
            {
                if(_less(e, cur.value))
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
        private Node _firstGreaterEqual(Elem e)
        {
            // can't use _find, because we cannot return null.
            auto cur = _end.index!N.left;
            auto result = _end;
            while(cur)
            {
                if(_less(cur.value, e))
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
        Range upperBound(Elem e)
        {
            return Range(_firstGreater(e), _end);
        }

        /**
         * Get a range from the container with all elements that are < e according
         * to the less comparator
         *
         * Complexity: $(BIGOH log(n))
         */
        Range lowerBound(Elem e)
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
            auto beg = _firstGreaterEqual(e);
            if(beg is _end || _less(e, beg.value))
                // no values are equal
                return Range(beg, beg);
            static if(allowDuplicates)
            {
                return Range(beg, _firstGreater(e));
            }
            else
            {
                // no sense in doing a full search, no duplicates are allowed,
                // so we just get the next node.
                return Range(beg, beg.index!N.next);
            }
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
                        if(next !is _end && _less(next.value, n.value))
                            throw new Exception("ordering invalid at path " ~ path);
                    }
                    else
                    {
                        if(next !is _end && !_less(n.value, next.value))
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
}

template HashedIndex(ThisNode,Value, size_t N, alias KeyFromValue, alias Hash, alias Eq, bool unique){
    mixin template Index(size_t N){
        Array!(ThisNode*) hashes;
    }
}

struct MultiIndexContainer(IndexedBy, Value){
    alias MNode!(IndexedBy,Value) ThisNode;

    size_t node_count;

    @property size_t length(){
        return node_count;
    }

    @property bool empty(){
        return node_count == 0;
    }

    void _replace(ThisNode* node, const(Value) value){
        assert(false);
    }

    ThisNode* _InsertAllBut(size_t N)(const(Value) value){
        assert(false);
    }

    void _RemoveAllBut(size_t N)(ThisNode* node){
        assert(false);
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
                    mixin M$N.Index!().IndexMixin!($N) index$N;
                    template index(size_t n) if(n == $N){ alias index$N index; }
                },  "$N", Format!("%s",N)) ~ 
                ForEachIndex!(N+1, L[1 .. $]).result;
        }else{
            enum result = "";
        }
    }

    enum stuff = (ForEachIndex!(0, IndexedBy.List).result);
    //pragma(msg, stuff);
//#line 10000
    mixin(stuff);
}

void main(){
    alias MNode!(IndexedBy!(
                Sequenced!(), 
                OrderedUnique!(),
                ),int) Node;
    Node* n1 = new Node();
    Node* n2 = new Node();
    enum R = 1;
    n1.index!(0).next = n2;
    n1.index!(1).left = n2;
    /+
    alias MultiIndexContainer!(IndexedBy!(Sequenced!(), Sequenced!()),int) Ints;

    Ints i;
    i.index!(0).insert(1);
    i.index!(1).insert(1);
    +/
    //pragma(msg, Sequenced!().Inner!(N,int,0).Index!().IndexMixin);
        /+
    n1.next!0 = null;
    +/

}
