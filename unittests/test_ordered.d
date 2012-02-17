
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
    // ordered unique index only
    alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!())) C1;

    C1 c = new C1;
    c.insert(0);
    c.insert(2);
    c.check();
    c.insert(-1);
    assert(array(c[]) == [-1,0,2]);
    writeln(c);
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

    while(!r.empty){
        if(r.back % 20 == 10) r.removeBack();
        else r.popBack();
    }
    assert(array(c[]) == [60,80]);
}

unittest{
    alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!())) C1;
    C1 c = new C1;
    c.insert(iota(20));
    assert(c.length == 20);
    assert(array(c[]) == [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]);
    auto i = c.removeKey(0);
    assert(i == 1);
    writeln("zookie");
    assert(c.length == 19);
    i = c.removeKey(0);
    assert(i == 0);
    assert(c.length == 19);
    i = c.removeKey(1,0,1,0,2,0,4);
    assert(array(c[]) == [3,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]);
    assert(i == 3);
}

unittest{
    // ordered unique, ordered nonunique
    alias MultiIndexContainer!(int, IndexedBy!(OrderedUnique!(), OrderedNonUnique!("-a"))) C1;

    C1 a = new C1;
    auto c = a.get_index!0;
    auto d = a.get_index!1;
    c.insert(0);
    c.insert(2);
    a.check();
    c.insert(-1);
    assert(array(c[]) == [-1,0,2]);
    assert(array(d[]) == [2,0,-1]);
    c.insert([5,-5,10,-10]);
    assert(array(c[]) == [-10,-5,-1,0,2,5,10]);
    assert(array(d[]) == [10,5,2,0,-1,-5,-10]);
    c.insert(5);
    assert(array(c[]) == [-10,-5,-1,0,2,5,10]);
    assert(array(d[]) == [10,5,2,0,-1,-5,-10]);
    assert(c.front() == -10);
    assert(c.back() == 10);
    assert(d.front() == 10);
    assert(d.back() == -10);
    assert(10 in c);
    assert(c[10] == 10);
    assert(c.removeAny() == -10);
    assert(d.removeAny() == 10);
    c.removeFront();
    assert(array(c[]) == [-1,0,2,5]);
    assert(array(d[]) == [5,2,0,-1]);
    c.removeBack();
    assert(array(c[]) == [-1,0,2]);
    assert(array(d[]) == [2,0,-1]);
    c.removeKey(2);
    assert(array(c[]) == [-1,0]);
    assert(array(d[]) == [0,-1]);
    c.insert(iota(0,20,2));
    assert(array(c[]) == [-1,0,2,4,6,8,10,12,14,16,18]);
    assert(array(d[]) == [18,16,14,12,10,8,6,4,2,0,-1]);
    auto r = c[];
    foreach(j; iota(10)) r.popFront();
    c.remove(r);
    assert(array(c[]) == [-1,0,2,4,6,8,10,12,14,16]);
    assert(array(d[]) == [16,14,12,10,8,6,4,2,0,-1]);
    r = c[];
    auto t = take(r, 3);
    c.remove(t);
    assert(array(c[]) == [4,6,8,10,12,14,16]);
    assert(array(d[]) == [16,14,12,10,8,6,4]);
    r = c.upperBound(10);
    c.remove(r);
    assert(array(c[]) == [4,6,8,10]);
    assert(array(d[]) == [10,8,6,4]);
    r = c.upperBound(10);
    c.remove(r);
    assert(array(c[]) == [4,6,8,10]);
    assert(array(d[]) == [10,8,6,4]);
    c.insert(iota(0,100,5));
    assert(array(c[]) == [0,4,5,6,8,10,15,20,25,30,35,40,45,50,55,60,65,70,
            75,80,85,90,95]);
    assert(array(d[]) == [95,90,85,80,75,70,65,60,55,50,45,40,
                    35,30,25,20,15,10,8,6,5,4,0]);
    r = c.lowerBound(0);
    assert(array(r) == []);
    c.remove(r);
    assert(array(c[]) == [0,4,5,6,8,10,15,20,25,30,35,40,45,50,55,60,65,70,
            75,80,85,90,95]);
    assert(array(d[]) == [95,90,85,80,75,70,65,60,55,50,45,40,
                    35,30,25,20,15,10,8,6,5,4,0]);
    r = c.lowerBound(24);
    c.remove(r);
    assert(array(c[]) == [25,30,35,40,45,50,55,60,65,70,
            75,80,85,90,95]);
    assert(array(d[]) == [95,90,85,80,75,70,65,60,55,50,45,40,
                    35,30,25]);
    r = c.equalRange(55);
    c.remove(r);
    assert(array(c[]) == [25,30,35,40,45,50,60,65,70,
            75,80,85,90,95]);
    assert(array(d[]) == [95,90,85,80,75,70,65,60,50,45,40,
                    35,30,25]);
    r = c.bounds!"[)"(30,50);
    assert(array(r) == [30,35,40,45]);
    c.remove(r);
    assert(array(c[]) == [25,50,60,65,70,75,80,85,90,95]);
    assert(array(d[]) == [95,90,85,80,75,70,65,60,50,25]);
    r = c.bounds!"()"(50,51);
    assert(array(r) == []);
    r = c.bounds!"[]"(50,50);
    assert(array(r) == [50]);
    c.modify(r, (ref int i){ i = 150; });
    assert(array(c[]) == [25,60,65,70,75,80,85,90,95,150]);
    assert(array(d[]) == [150,95,90,85,80,75,70,65,60,25]);
    r = c[];
    while(!r.empty){
        if(r.front % 10 == 5) r.removeFront();
        else r.popFront();
    }
    assert(array(c[]) == [60,70,80,90,150]);
    assert(array(d[]) == [150,90,80,70,60]);
    r = c[];

    while(!r.empty){
        if(r.back % 20 == 10) r.removeBack();
        else r.popBack();
    }
    assert(array(c[]) == [60,80]);
    assert(array(d[]) == [80,60]);
}

void main(){}
