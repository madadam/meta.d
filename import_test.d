// This file's sole purpose is to test that Facade works also when imported into other module.

version(unittest) {
  import function_facade;

  struct A {
    string opCast(T:string)() {
      return "A";
    }
  }

  string test(string s) {
    return "test: " ~ s;
  }
}

unittest {
  A a;

  mixin Facade!(test, string, A);
  assert("test: A" == test(a));
}
