library test {
    modifier m virtual;
    function f() m public {
    }
}
// ----
// Warning 8429: (19-38): Virtual modifiers will be deprecated in the next breaking version.
// TypeError 3275: (19-38): Modifiers in a library cannot be virtual.
