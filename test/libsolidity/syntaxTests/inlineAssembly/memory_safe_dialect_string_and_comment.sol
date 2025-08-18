function f() pure {
    /// @solidity memory-safe-assembly
    assembly "evmasm" ("memory-safe") {
    }
}
// ----
// Warning 8544: (63-104): Inline assembly marked as memory safe using both a NatSpec tag and an assembly flag. If you are not concerned with backwards compatibility, only use the assembly flag, otherwise only use the NatSpec tag.
// Warning 2424: (63-104): Natspec memory safe annotation for inline assembly will be deprecated in the next breaking version.
