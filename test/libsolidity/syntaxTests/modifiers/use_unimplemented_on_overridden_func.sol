abstract contract A {
    modifier m() virtual;
    function f() m public virtual {}
}
abstract contract B is A {
    function f() public override {}
}
// ----
// Warning 8429: (26-47): Virtual modifiers will be deprecated in the next breaking version.
