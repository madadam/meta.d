module function_facade;

import std.conv;
import std.traits;
import std.typecons;
import std.typetuple;

version(unittest) {
  struct A {
    string name;
  }

  struct B {
    string name;

    A opCast(T:A)() {
      return A(this.name ~ "(A)");
    }
  }

  string test1(A a) { return "[" ~ a.name ~ "]"; }
  string test2(A a1, A a2) { return "[" ~ a1.name ~ ", " ~ a2.name ~ "]"; }
  string test3(A a1, B a2) { return "[" ~ a1.name ~ ", " ~ a2.name ~ "]"; }
}

unittest {
  B b1 = B("bee1");
  B b2 = B("bee2");

  mixin DefineFacade!(test1, A, B);
  assert("[bee1(A)]" == test1(b1));

  mixin DefineFacade!(test2, A, B);
  assert("[bee1(A), bee2(A)]" == test2(b1, b2));

  mixin DefineFacade!(test3, A, B);
  assert("[bee1(A), bee2]" == test3(b1, b2));
}

/**
 * TODO: Documentation here
 */
mixin template DefineFacade(alias target, To, From) {
  mixin(facadeSource!(target, To, From));
}


// facadeSource
template facadeSource(alias target, To, From) {
  enum facadeSource = q{ ReturnType!target } ~ unqualifiedName!target ~
                      q{ (translateTypes!(To, From, ParameterTypeTuple!target) params) {
                        return facade!(target, To, From)(params);
                      }};
}

private:

// facade
unittest {
  B b1 = B("bee1");
  B b2 = B("bee2");

  assert("[bee1(A)]"          == facade!(test1, A, B)(b1));
  assert("[bee1(A), bee2(A)]" == facade!(test2, A, B)(b1, b2));
  assert("[bee1(A), bee2]"    == facade!(test3, A, B)(b1, b2));
}

template facade(alias target, To, From) {
  alias facadeDetails!(target, To, From).result facade;
}

template facadeDetails(alias target, To, From) {
  alias ReturnType!target                      R;
  alias ParameterTypeTuple!target              TargetTypes;
  alias translateTypes!(To, From, TargetTypes) FacadeTypes;

  R result(FacadeTypes params) {
    return target(tupleCast!(Tuple!TargetTypes)(params).field);
  }
}

// unqualifiedName
unittest {
  int a;

  struct Outer {
    static int inner;
  }

  static assert("a"     == unqualifiedName!a);
  static assert("inner" == unqualifiedName!(Outer.inner));
}

template unqualifiedName(alias E) {
  enum unqualifiedName = demodulize(__traits(identifier, E));
}

// translateTypes
unittest {
  struct A {}
  struct B {}
  struct C {}

  static assert(is(B == translateTypes!(A, B, A)));
  static assert(is(TypeTuple!(B, B) == translateTypes!(A, B, A, A)));
  static assert(is(TypeTuple!(B, B) == translateTypes!(A, B, A, B)));
  static assert(is(C == translateTypes!(A, B, C)));
}

template translateTypes(From, To, Types...) {
  static if (Types.length == 1) {
    alias translateType!(From, To, Types[0]) translateTypes;
  } else {
    alias TypeTuple!(translateType!(From, To, Types[0]), translateTypes!(From, To, Types[1 .. $]))
          translateTypes;
  }
}

// translateType
unittest {
  struct A {}
  struct B {}
  struct C {}

  static assert(is(B == translateType!(A, B, A)));
  static assert(is(B == translateType!(A, B, B)));
  static assert(is(C == translateType!(A, B, C)));
}

template translateType(From, To, T) {
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
  assert(is(A == typeof(r1.field[0])));
  assert("cee1" == r1.field[0].name);

  auto r2 = tupleCast!(Tuple!(A, B))(c1, c2);
  assert(is(A == typeof(r2.field[0])));
  assert(is(B == typeof(r2.field[1])));
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

// demodulize
unittest {
  assert("foo" == demodulize("foo"));
  assert("foo" == demodulize("bar.foo"));
  assert("foo" == demodulize("baz.bar.foo"));

  // CTFE
  enum name = demodulize("baz.bar.foo");
  static assert("foo" == name);
}

pure string demodulize(in string input) {
  auto last = lastIndexOf(input, '.');

  if (last >= 0) {
    return input[last + 1 .. $];
  } else {
    return input;
  }
}

// lastIndexOf
unittest {
  assert(-1 == lastIndexOf("",    'a'));
  assert(-1 == lastIndexOf("foo", 'a'));
  assert( 0 == lastIndexOf("foo", 'f'));
  assert( 2 == lastIndexOf("foo", 'o'));
}

pure int lastIndexOf(in string haystack, char needle) {
  for (int i = cast(int) haystack.length - 1; i >= 0; --i) {
    if (haystack[i] == needle) {
      return i;
    }
  }

  return -1;
}
