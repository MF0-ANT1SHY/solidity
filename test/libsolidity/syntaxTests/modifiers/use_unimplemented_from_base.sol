abstract contract A {
    modifier m() virtual;
    function f() m public {}
}
contract B is A {
    modifier m() virtual override { _; }
}
// ----
// Warning 8429: (26-47): Virtual modifiers will be deprecated in the next breaking version.
// Warning 8429: (101-137): Virtual modifiers will be deprecated in the next breaking version.
