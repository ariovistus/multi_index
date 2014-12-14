
import multi_index;


struct G {
    int i;
    int f;
    string g;
    double t;
}

alias MultiCompare!("a.i", "a.g", ComparisonEx!("a.t", "a>b")) Less1;

unittest {
    G g0 = G(1,5,"abc",2.2);
    G g1 = G(1,5,"abc",2.2);
    G g2 = G(8,5,"abc",2.2);
    assert(Less1(g1, g2));
    assert(!Less1(g2, g1));

    assert(!Less1(g0, g1));
    assert(!Less1(g1, g0));
    G g3 = G(1,5,"abc",2.2);
    G g4 = G(1,5,"abd",2.2);
    assert(Less1(g3, g4));
    assert(!Less1(g4, g3));
    G g5 = G(1,5,"abc",2.3);
    G g6 = G(1,5,"abc",2.2);
    assert(Less1(g5, g6));
    assert(!Less1(g6, g5));
}

alias MultiCompare!(DefaultComparison!"a>b","a.i", "a.g", "a.f") Less2;

unittest {
    G g1 = G(1,5,"abc",2.2);
    G g2 = G(8,5,"abc",2.2);
    assert(Less2(g2, g1));
    assert(!Less2(g1, g2));
    G g3 = G(1,5,"abc",2.2);
    G g4 = G(1,5,"abd",2.2);
    assert(Less2(g4, g3));
    assert(!Less2(g3, g4));
    G g5 = G(1,6,"abc",2.2);
    G g6 = G(1,5,"abc",2.2);
    assert(Less2(g5, g6));
    assert(!Less2(g6, g5));
}


void main() {}
