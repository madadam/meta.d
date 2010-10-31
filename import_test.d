// This file's sole purpose is to test that Adapter works also when imported into other module.

version(unittest) {
  import adapter;

  struct A {
    string opCast(T:string)() { return "A"; }
  }

  string test(string s) {
    return "test: " ~ s;
  }
}

unittest {
  A a;

  mixin Adapter!(test, A, string);
  assert("test: A" == test(a));
}
