library L {
    modifier mv virtual { _; }
}
// ----
// Warning 8429: (16-42): Virtual modifiers will be deprecated in the next breaking version.
// TypeError 3275: (16-42): Modifiers in a library cannot be virtual.
