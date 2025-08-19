contract A {
    modifier f(uint a) virtual { _; }
}
contract B {
    modifier f() virtual { _; }
}
contract C is A, B {
}
// ----
// Warning 8429: (17-50): Virtual modifiers will be deprecated in the next breaking version.
// Warning 8429: (70-97): Virtual modifiers will be deprecated in the next breaking version.
// TypeError 6480: (100-122): Derived contract must override modifier "f". Two or more base classes define modifier with same name.
