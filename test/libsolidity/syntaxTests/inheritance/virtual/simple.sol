contract C
{
	function foo() public virtual {}
	function foo2() virtual public {}
	modifier modi() virtual {_;}
}
// ----
// Warning 8429: (83-111): Virtual modifiers will be deprecated in the next breaking version.
