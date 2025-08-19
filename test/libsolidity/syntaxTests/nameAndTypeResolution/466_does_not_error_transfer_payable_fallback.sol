// This used to be a test for a.transfer to generate a warning
// because A does not have a payable fallback function.

contract A {
    receive() payable external {}
}

contract B {
    A a;

    fallback() external {
        payable(a).transfer(100);
    }
}
// ----
// Warning 9207: (227-246): transfer will be deprecated in the next breaking version.
