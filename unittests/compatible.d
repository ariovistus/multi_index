
import std.stdio;
import std.string;
import std.exception;
import multi_index;

// compatible sorting criteria

class A {
    int i;
    double j;
    int k;

    this(int _i, double _j, int _k) {
        i = _i; j = _j; k = _k;
    }

    override string toString() {
        return format("A(%s,%s,%s)",i,j,k);
    }
}

// an ordered set that sorts first by i, then j, then k.
alias MultiIndexContainer!(A, 
        IndexedBy!(
            OrderedUnique!("a",
                MultiCompare!("a.i","a.j","a.k")))) Set1;

unittest {
    Set1 s = new Set1();
    // incidentally, following items appear in order inserted
    s.insert(new A(1,2.2,5));
    s.insert(new A(1,2.3,5));
    s.insert(new A(1,2.3,6));
    s.insert(new A(1,2.3,7));
    s.insert(new A(2,2.1,2));

    // suppose we want range of all items with i=1
    // then define a compatible sorting criterion.

    alias CriterionFromKey!(Set1, 0, "a.i") CompatibleLess;

    auto r = s.cEqualRange!CompatibleLess(1);
    int sum = 0;
    foreach(a; r) {
        assert(a.i == 1);
        sum++;
    }
    assert(sum==4);

    auto r2 = s.lowerBound!CompatibleLess(2);
    sum = 0;
    foreach(a; r2) {
        assert(a.i == 1);
        sum++;
    }
    assert(sum==4);

    auto r3 = s.upperBound!CompatibleLess(0);
    sum = 0;
    foreach(a; r3) {
        assert(a.i > 0);
        sum++;
    }
    assert(sum==5);

    auto r4 = s.cbounds!(CompatibleLess,"[)")(0,2);
    sum = 0;
    foreach(a; r4) {
        assert(a.i == 1);
        sum++;
    }
    assert(sum==4);
}

void main(){}
