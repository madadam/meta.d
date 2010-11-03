module meta.attribute;

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

template attributeReader(T, string name) {
  enum attributeReader = attributeVariable!T(name) ~
                         attributeReaderFunction!T(name);
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

template attributeWriter(T, string name) {
  enum attributeWriter = attributeVariable!T(name) ~
                         attributeWriterFunction!T(name);
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

template attributeAccessor(T, string name) {
  enum attributeAccessor = attributeVariable!T(name) ~
                           attributeReaderFunction!T(name) ~
                           attributeWriterFunction!T(name);
}



// helpers

private string attributeReaderFunction(T)(string name) {
  return "@property " ~ T.stringof ~ " " ~ name ~ "() { return this._" ~ name ~ "; }";
}

private string attributeWriterFunction(T)(string name) {
  return "@property " ~ T.stringof ~ " " ~ name ~ "(" ~ T.stringof ~ " value) { return this._" ~ name ~ " = value; }";
}

private string attributeVariable(T)(string name) {
  return "private " ~ T.stringof ~ " _" ~ name ~ ";";
}
