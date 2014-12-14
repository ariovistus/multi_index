import multi_index;

unittest{
    alias MultiIndexContainer!(MyRecord, IndexedBy!(
        HashedUnique!("a.id"),"byid",
        OrderedNonUnique!("a.name"), "byname")) MyContainer;
    
    MyContainer c = new MyContainer();
    c.byid.insert(MyRecord(1, "John Smith", "Writer"));
    c.byid.insert(MyRecord(2, "Jamie Zawinski", "Barista"));
    c.byid.insert(MyRecord(3, "Art Carney", "Actor"));
    c.byid.insert(MyRecord(4, "John Smith", "Nuclear Physicist"));
    c.byid.insert(MyRecord(5, "Paulette Goddard", "Actress"));
    c.byid.insert(MyRecord(6, "John Smith",  "Soldier"));
    c.byid.insert(MyRecord(7, "William Donovan",  "Lawyer"));
    c.byid.insert(MyRecord(8, "Genghis Khan",  "Community Events Organizer"));
}

void main(){}

struct MyRecord{
    int id;
    string name;
    string occupation;
}
