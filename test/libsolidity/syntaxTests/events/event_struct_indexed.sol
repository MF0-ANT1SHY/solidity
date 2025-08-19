pragma abicoder v1;
contract c {
    struct S { uint a ; }
    event E(S indexed);
}
// ----
// Warning 9511: (0-19): ABI coder v1 will be deprecated in the next breaking version.
// TypeError 3061: (71-80): This type is only supported in ABI coder v2. Use "pragma abicoder v2;" to enable the feature.
