contract A { modifier mod(uint a) virtual { _; } }
contract B is A { modifier mod(uint a) override { _; } }
// ----
// Warning 8429: (13-48): Virtual modifiers will be deprecated in the next breaking version.
