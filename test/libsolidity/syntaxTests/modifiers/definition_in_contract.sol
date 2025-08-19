contract C {
    modifier m { _; }
    modifier mv virtual { _; }
}

abstract contract A {
    modifier m { _; }
    modifier mv virtual { _; }
    modifier muv virtual;
}
// ----
// Warning 8429: (39-65): Virtual modifiers will be deprecated in the next breaking version.
// Warning 8429: (117-143): Virtual modifiers will be deprecated in the next breaking version.
// Warning 8429: (148-169): Virtual modifiers will be deprecated in the next breaking version.
