==== Source: A ====
pragma abicoder               v2;

struct Item {
    uint x;
}

contract C {
    event Ev(Item);
}
==== Source: B ====
pragma abicoder v1;
import "A";

contract D is C {}
// ====
// bytecodeFormat: legacy
// ----
// Warning 9511: (B:0-19): ABI coder v1 will be deprecated in the next breaking version.
