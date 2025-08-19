abstract contract A {
    function f() public view mod {
        require(block.timestamp > 10);
    }
    modifier mod() virtual;
}
// ----
// Warning 8429: (106-129): Virtual modifiers will be deprecated in the next breaking version.
