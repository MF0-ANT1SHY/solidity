contract D {}

contract C {
	D public d;

	function f() public view {
		D e = this.d();
		assert(e == d); // should hold
		assert(address(e) == address(this)); // should fail
	}
}
// ====
// SMTEngine: all
// ----
// Warning 9170: (97-103): Comparison of variables of contract type will be deprecated in the next breaking version.Consider using an explicit cast to address type.
// Warning 6328: (123-158): CHC: Assertion violation happens here.
// Info 1391: CHC: 1 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
