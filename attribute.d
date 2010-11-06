module meta.attribute;

import std.algorithm;

// attributeReader
unittest {
  class Widget {
    mixin(attributeReader!(string, "name"));

    this(string name) {
      _name = name;
    }
  }

  auto widget = new Widget("foo");
  assert("foo" == widget.name);
}

// attributeReader allows manualy defined writer
unittest {
  class Widget {
    mixin(attributeReader!(string, "name"));

    @property
    string name(string value) {
      return _name = value;
    }
  }

  auto widget = new Widget;
  widget.name = "foo";

  assert("foo" == widget.name);
}

template attributeReader(T, names...) {
  enum attributeReader = attributeVariable!(T, names) ~
                         attributeReaderFunction!(T, names);
}

// attributeWriter
unittest {
  class Widget {
    mixin(attributeWriter!(string, "name"));

    string fetchName() {
      return _name;
    }
  }

  auto widget = new Widget;

  assert("foo" == (widget.name = "foo"));
  assert("foo" == widget.fetchName());
}

// attributeWriter allows manually defined reader
unittest {
  class Widget {
    mixin(attributeWriter!(string, "name"));

    @property
    string name() {
      return _name;
    }
  }

  auto widget = new Widget;
  widget.name = "foo";

  assert("foo" == widget.name);
}

template attributeWriter(T, names...) {
  enum attributeWriter = attributeVariable!(T, names) ~
                         attributeWriterFunction!(T, names);
}

// attributeAccessor
unittest {
  class Widget {
    mixin(attributeAccessor!(string, "name"));
  }

  auto widget = new Widget;

  assert("foo" == (widget.name = "foo"));
  assert("foo" == widget.name);
}

template attributeAccessor(T, names...) {
  enum attributeAccessor = attributeVariable!(T, names) ~
                           attributeReaderFunction!(T, names) ~
                           attributeWriterFunction!(T, names);
}

// multiple arguments
unittest {
  class User {
    mixin(attributeAccessor!(string, "firstName", "lastName"));
  }

  auto user = new User;

  assert("sheldon" == (user.firstName = "sheldon"));
  assert("cooper"  == (user.lastName  = "cooper"));

  assert("sheldon" == user.firstName);
  assert("cooper"  == user.lastName);
}


// helpers

private string attributeReaderFunction(T)() {
  return "";
}

private string attributeReaderFunction(T, string name, names...)() {
  return "@property " ~ T.stringof ~ " " ~ name ~ "() { return this._" ~ name ~ "; }" ~
    attributeReaderFunction!(T, names);
}



private string attributeWriterFunction(T)() {
  return "";
}

private string attributeWriterFunction(T, string name, names...)() {
  return "@property " ~ T.stringof ~ " " ~ name ~ "(" ~ T.stringof ~ " value) { return this._" ~ name ~ " = value; }" ~ attributeWriterFunction!(T, names);
}



private string attributeVariable(T)() {
  return "";
}

private string attributeVariable(T, string name, names...)() {
  return "private " ~ T.stringof ~ " _" ~ name ~ ";" ~ attributeVariable!(T, names);
}
