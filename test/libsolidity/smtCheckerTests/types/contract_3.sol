contract C
{
	function f(C c, C d, C e) public pure {
		require(c == d);
		require(d == e);
		assert(c == e);
	}
}
// ====
// SMTEngine: all
// ----
// Warning 9170: (64-70): Comparison of variables of contract type will be deprecated in the next breaking version.Consider using an explicit cast to address type.
// Warning 9170: (83-89): Comparison of variables of contract type will be deprecated in the next breaking version.Consider using an explicit cast to address type.
// Warning 9170: (101-107): Comparison of variables of contract type will be deprecated in the next breaking version.Consider using an explicit cast to address type.
// Info 1391: CHC: 1 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
