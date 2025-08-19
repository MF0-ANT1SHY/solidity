pragma abicoder v1;
contract c {
    event E(uint[][]);
}
// ----
// Warning 9511: (0-19): ABI coder v1 will be deprecated in the next breaking version.
// TypeError 3061: (45-53): This type is only supported in ABI coder v2. Use "pragma abicoder v2;" to enable the feature.
