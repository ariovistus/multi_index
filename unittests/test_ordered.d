
import std.stdio;
import std.range;
import multi_index;

int[] array(Range)(Range r)
if(isImplicitlyConvertible!(ElementType!Range, int)){
    int[] arr;
    foreach(e; r) arr ~= e;
    return arr;
}

unittest{
    alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!())) C1;

    C1 c = new C1;
    c.insert(0);
    c.insert(2);
    c.check();
    c.insert(-1);
    assert(array(c[]) == [-1,0,2]);
    c.insert([5,-5,10,-10]);
    assert(array(c[]) == [-10,-5,-1,0,2,5,10]);
    c.insert(5);
    assert(array(c[]) == [-10,-5,-1,0,2,5,10]);
    assert(c.front() == -10);
    assert(c.back() == 10);
    assert(10 in c);
    assert(c[10] == 10);
    assert(c.removeAny() == -10);
    c.removeFront();
    assert(array(c[]) == [-1,0,2,5,10]);
    c.removeBack();
    assert(array(c[]) == [-1,0,2,5]);
    c.removeKey(2);
    assert(array(c[]) == [-1,0,5]);
    c.insert(iota(0,20,2));
    assert(array(c[]) == [-1,0,2,4,5,6,8,10,12,14,16,18]);
    auto r = c[];
    foreach(j; iota(10)) r.popFront();
    c.remove(r);
    assert(array(c[]) == [-1,0,2,4,5,6,8,10,12,14]);
    r = c[];
    auto t = take(r, 3);
    c.remove(t);
    assert(array(c[]) == [4,5,6,8,10,12,14]);
    r = c.upperBound(10);
    c.remove(r);
    assert(array(c[]) == [4,5,6,8,10]);
    r = c.upperBound(10);
    c.remove(r);
    assert(array(c[]) == [4,5,6,8,10]);
    c.insert(iota(0,100,5));
    assert(array(c[]) == [0,4,5,6,8,10,15,20,25,30,35,40,45,50,55,60,65,70,
            75,80,85,90,95]);
    r = c.lowerBound(0);
    assert(array(r) == []);
    c.remove(r);
    assert(array(c[]) == [0,4,5,6,8,10,15,20,25,30,35,40,45,50,55,60,65,70,
            75,80,85,90,95]);
    r = c.lowerBound(24);
    c.remove(r);
    assert(array(c[]) == [25,30,35,40,45,50,55,60,65,70,75,80,85,90,95]);
    r = c.equalRange(55);
    c.remove(r);
    assert(array(c[]) == [25,30,35,40,45,50,60,65,70,75,80,85,90,95]);
    r = c.bounds!"[)"(30,50);
    assert(array(r) == [30,35,40,45]);
    c.remove(r);
    assert(array(c[]) == [25,50,60,65,70,75,80,85,90,95]);
    r = c.bounds!"()"(50,51);
    assert(array(r) == []);
    r = c.bounds!"[]"(50,50);
    assert(array(r) == [50]);
    c.modify(r, (ref int i){ i = 150; });
    assert(array(c[]) == [25,60,65,70,75,80,85,90,95,150]);
    r = c[];
    while(!r.empty){
        if(r.front % 10 == 5) r.removeFront();
        else r.popFront();
    }
    assert(array(c[]) == [60,70,80,90,150]);
    r = c[];
    c.check();

    while(!r.empty){
        if(r.back % 20 == 10) r.removeBack();
        else r.popBack();
    }
    assert(array(c[]) == [60,80]);

}
void main(){}
