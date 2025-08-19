pragma abicoder v1;
contract C {
	constructor(uint[][][] memory t) {}
}
// ----
// Warning 9511: (0-19): ABI coder v1 will be deprecated in the next breaking version.
// TypeError 4957: (46-65): This type is only supported in ABI coder v2. Use "pragma abicoder v2;" to enable the feature. Alternatively, make the contract abstract and supply the constructor arguments from a derived contract.
