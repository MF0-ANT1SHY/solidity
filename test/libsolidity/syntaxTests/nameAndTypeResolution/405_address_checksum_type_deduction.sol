contract C {
    function f() public {
        payable(0xfA0bFc97E48458494Ccd857e1A85DC91F7F0046E).transfer(2);
    }
}
// ----
// Warning 9207: (47-107): transfer will be deprecated in the next breaking version.
