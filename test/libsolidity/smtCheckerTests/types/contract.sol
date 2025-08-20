contract C
{
	function f(C c, C d) public pure {
		assert(c == d);
	}
}
// ====
// SMTEngine: all
// SMTIgnoreCex: yes
// ----
// Warning 9170: (58-64): Comparison of variables of contract type will be deprecated in the next breaking version.Consider using an explicit cast to address type.
// Warning 6328: (51-65): CHC: Assertion violation happens here.
