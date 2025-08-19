contract I {
	modifier f() virtual { _; }
}
contract J {
	modifier f() virtual { _; }
}
contract IJ is I, J {
	modifier f() virtual override (I, J) { _; }
}
contract A is IJ
{
	modifier f() override { _; }
}
contract B is IJ
{
}
contract C is A, B {}
// ----
// Warning 8429: (14-41): Virtual modifiers will be deprecated in the next breaking version.
// Warning 8429: (58-85): Virtual modifiers will be deprecated in the next breaking version.
// Warning 8429: (111-154): Virtual modifiers will be deprecated in the next breaking version.
// TypeError 6480: (229-250): Derived contract must override modifier "f". Two or more base classes define modifier with same name.
