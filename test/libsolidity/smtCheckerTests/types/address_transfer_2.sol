contract C
{
	function f(uint x, address payable a, address payable b) public {
		require(a != b);
		require(x == 100);
		require(x == a.balance);
		require(a.balance == b.balance);
		a.transfer(600);
		b.transfer(100);
		// Fails since a == this is possible.
		assert(a.balance > b.balance);
	}
}
// ====
// SMTEngine: all
// SMTIgnoreCex: yes
// ----
// Warning 9207: (184-194): transfer will be deprecated in the next breaking version.
// Warning 9207: (203-213): transfer will be deprecated in the next breaking version.
// Warning 8656: (184-199): CHC: Insufficient funds happens here.
// Warning 8656: (203-218): CHC: Insufficient funds happens here.
// Warning 6328: (262-291): CHC: Assertion violation happens here.
