pragma abicoder v1;
contract C {
    function f() public pure returns (uint[][2] memory) {}
}
// ----
// Warning 9511: (0-19): ABI coder v1 will be deprecated in the next breaking version.
// TypeError 4957: (71-87): This type is only supported in ABI coder v2. Use "pragma abicoder v2;" to enable the feature.
