module function_facade;

import std.conv;
import std.traits;
import std.typecons;
import std.typetuple;

version(unittest) {
  import std.stdio;

  struct A { string name; }

  struct B {
    string name;

    A opCast(T:A)() { return A(this.name ~ "(A)"); }
  }

  struct C { string name; }

  struct D {
    string name;

    C opCast(T:C)() {
      return C(this.name ~ "(C)");
    }
  }

  string test1(A a)        { return a.name; }
  string test2(C c)        { return c.name; }
  string test3(A a1, A a2) { return a1.name ~ ", " ~ a2.name; }
  string test4(A a, C c)   { return a.name ~ ", " ~ c.name; }
  string test5(A a, C c)   { return a.name ~ ", " ~ c.name; }
}

unittest {
  B b1 = B("b1");
  B b2 = B("b2");
  C c  = C("c");
  D d  = D("d");

  auto test1 = facade!(test1, B, A);
  assert("b1(A)" == test1(b1));

  auto test2 = facade!(test2, B, A);
  assert("c" == test2(c));

  auto test3 = facade!(test3, B, A);
  assert("b1(A), b2(A)" == test3(b1, b2));

  auto test4 = facade!(test4, B, A);
  assert("b1(A), c" == test4(b1, c));

  auto test5 = facade!(test5, B, A, D, C);
  assert("b1(A), d(C)" == test5(b1, d));
}

/**
 * TODO: Documentation here
 */
template facade(alias target, Map...) {
  alias facadeImpl!(target, Map).result facade;
}

private:

template facadeImpl(alias target, Map...) {
  alias ReturnType!target                      R;
  alias ParameterTypeTuple!target              OldTypes;
  alias translateTypes!(Tuple!(Map), OldTypes) NewTypes;

  enum result = function R(NewTypes params) {
    return target(tupleCast!(Tuple!OldTypes)(params).field);
  };
}

// translateTypes
unittest {
  struct A {}
  struct B {}
  struct C {}

  static assert(is(TypeTuple!(B)       == translateTypes!(Tuple!(B, A), A)));
  static assert(is(TypeTuple!(B, B)    == translateTypes!(Tuple!(B, A), A, A)));
  static assert(is(TypeTuple!(B, B)    == translateTypes!(Tuple!(B, A), A, B)));
  static assert(is(TypeTuple!(C)       == translateTypes!(Tuple!(B, A), C)));
  static assert(is(TypeTuple!(C, C, C) == translateTypes!(Tuple!(C, A, C, B), A, B, C)));
}

template translateTypes(Map, Types...) {
  static if (Types.length == 0) {
    alias TypeTuple!() translateTypes;
  } else {
    alias TypeTuple!(translateType!(Map, Types[0]), translateTypes!(Map, Types[1 .. $]))
          translateTypes;
  }
}

private

// translateType
unittest {
  struct A {}
  struct B {}
  struct C {}

  static assert(is(B == translateType!(Tuple!(B, A), A)));
  static assert(is(B == translateType!(Tuple!(B, A), B)));
  static assert(is(C == translateType!(Tuple!(B, A), C)));
  static assert(is(C == translateType!(Tuple!(C, A, C, B), A)));
}

template translateType(Map, T) {
  static assert(Map.Types.length % 2 == 0, "Translation map must have even number of types");

  static if (Map.Types.length == 0) {
    alias T translateType;
  } else {
    alias translateType!(Tuple!(Map.Types[2 .. $]), translateType!(Map.Types[0], Map.Types[1], T)) translateType;
  }
}

// translateType
unittest {
  struct A {}
  struct B {}
  struct C {}

  static assert(is(B == translateType!(B, A, A)));
  static assert(is(B == translateType!(B, A, B)));
  static assert(is(C == translateType!(B, A, C)));
}

template translateType(To, From, T) {
  static if (is(T == From)) {
    alias To translateType;
  } else {
    alias T translateType;
  }
}

// tupleCast
unittest {
  struct A {
    string name;
  }

  struct B {
    string name;
  }

  struct C {
    string name;

    A opCast(T:A)() {
      return A(name);
    }

    B opCast(T:B)() {
      return B(name);
    }
  }

  C c1 = C("cee1");
  C c2 = C("cee2");

  auto r1 = tupleCast!(Tuple!A)(c1);
  assert(is(Tuple!(A) == typeof(r1)));
  assert("cee1" == r1.field[0].name);

  auto r2 = tupleCast!(Tuple!(A, B))(c1, c2);
  assert(is(Tuple!(A, B) == typeof(r2)));
  assert("cee1" == r2.field[0].name);
  assert("cee2" == r2.field[1].name);
}

To tupleCast(To, From...)(From params) {
  static if (params.length == 1) {
    return tuple(cast(To.Types[0]) params[0]);
  } else {
    auto head = cast(To.Types[0]) params[0];
    auto tail = tupleCast!(Tuple!(To.Types[1 .. $]))(params[1 .. $]);

    return tuple(head, tail.field);
  }
}
