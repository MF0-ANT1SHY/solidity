contract A {
    modifier m() virtual { _; }
}
abstract contract B {
    modifier m() virtual;
}
contract C is A, B {
    modifier m() override(A, B) { _; }
    function f() B.m public {}
}
// ----
// Warning 8429: (17-44): Virtual modifiers will be deprecated in the next breaking version.
// Warning 8429: (73-94): Virtual modifiers will be deprecated in the next breaking version.
// TypeError 1835: (174-177): Cannot call unimplemented modifier. The modifier has no implementation in the referenced contract. Refer to it by its unqualified name if you want to call the implementation from the most derived contract.
