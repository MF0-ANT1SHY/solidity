contract D
{
	uint x;
}

contract C
{
	function f(D c, D d) public pure {
		assert(c == d);
	}
}
// ====
// SMTEngine: all
// SMTIgnoreCex: yes
// ----
// Warning 9170: (83-89): Comparison of variables of contract type will be deprecated in the next breaking version.Consider using an explicit cast to address type.
// Warning 6328: (76-90): CHC: Assertion violation happens here.
