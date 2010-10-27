module function_facade;

import std.conv;
import std.traits;
import std.typetuple;

/**
 * Generator of function facades.
 *
 * This mixin template generates generates a overloaded function of the given
 * name which accepts different parameters, converts them to the types the
 * original function accepts and calls the original function with them.
 *
 * Examples:
 * -------------------------------------------------------------------------------
 *   void doStruff(A a, B b) { ... }
 *
 *   A a;
 *   B b;
 *   C c;
 *
 *   mixin FunctionFacade!("doStuff", C, A);
 *
 *   doStuff(c, b); // <-- doStuff can now be called with first argument of type C
 * -------------------------------------------------------------------------------
 *
 * Params:
 *   name    = name of the function to create facade for
 *   NewType = type of a parameter of the facade
 *   OldType = type NewType will be cast to
 */
mixin template FunctionFacade(string name, NewType, OldType) {
  enum originalName = "." ~ name;
  enum newName = demodulize(name);

  alias ParameterTypeTuple!(mixin(originalName)) OriginalTypes;
  alias translateTypes!(OldType, NewType, OriginalTypes) NewTypes;

  mixin("ReturnType!(" ~ originalName ~ ") " ~
        newName ~ "(" ~ parametersString!NewTypes ~ ")" ~
        "{ return " ~ originalName ~ "(" ~ castsString!OriginalTypes ~ "); }");
}

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

  string test1(A a) {
    return "[" ~ a.name ~ "]";
  }

  string test2(A a1, A a2) {
    return "[" ~ a1.name ~ ", " ~ a2.name ~ "]";
  }

  string test3(A a1, B a2) {
    return "[" ~ a1.name ~ ", " ~ a2.name ~ "]";
  }
}

unittest {
  B b1 = B("bee1");
  B b2 = B("bee2");

  mixin FunctionFacade!("test1", B, A);
  assert("[bee1(A)]" == test1(b1));

  mixin FunctionFacade!("test2", B, A);
  assert("[bee1(A), bee2(A)]", test2(b1, b2));

  mixin FunctionFacade!("test3", B, A);
  assert("[bee1(A), bee2]", test3(b1, b2));
}

private {
  // parametersString
  unittest {
    static assert(""                  == parametersString!());
    static assert("int a0"            == parametersString!int);
    static assert("int a0, int a1"    == parametersString!(int, int));
    static assert("int a0, string a1" == parametersString!(int, string));
  }

  template parametersString(Types...) {
    enum parametersString = mapTypesToString!(parameterString, Types);
  }

  // parameterString
  unittest {
    static assert("int a0"    == parameterString!(int, 0));
    static assert("string a1" == parameterString!(string, 1));
  }

  template parameterString(T, int index) {
    enum parameterString = T.stringof ~ " a" ~ to!string(index);
  }

  // castsStrings
  unittest {
    static assert(""                              == castsString!());
    static assert("cast(int) a0"                  == castsString!int);
    static assert("cast(int) a0, cast(string) a1" == castsString!(int, string));
  }

  template castsString(Types...) {
    enum castsString = mapTypesToString!(castString, Types);
  }

  // castString
  unittest {
    static assert("cast(int) a0"    == castString!(int, 0));
    static assert("cast(string) a1" == castString!(string, 1));
  }

  template castString(T, int index) {
    enum castString = "cast(" ~ T.stringof ~ ") a" ~ to!string(index);
  }

  // mapTypesToString
  version(unittest) {
    template testTypeMapper(T, int index) {
      enum testTypeMapper = to!string(index) ~ ": " ~ T.stringof;
    }
  }

  unittest {
    static assert(""                  == mapTypesToString!(testTypeMapper));
    static assert("0: int"            == mapTypesToString!(testTypeMapper, int));
    static assert("0: int, 1: string" == mapTypesToString!(testTypeMapper, int, string));
  }

  template mapTypesToString(alias F, Types...) {
    enum mapTypesToString = mapTypesToStringHelper!(0, F, Types);
  }

  template mapTypesToStringHelper(int index, alias F, Types...) {
    static if (Types.length == 0) {
      enum mapTypesToStringHelper = "";
    } else static if (Types.length == 1) {
      enum mapTypesToStringHelper = F!(Types[0], index);
    } else {
      enum mapTypesToStringHelper = F!(Types[0], index) ~ ", " ~
           mapTypesToStringHelper!(index + 1, F, Types[1 .. $]);
    }
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
}
