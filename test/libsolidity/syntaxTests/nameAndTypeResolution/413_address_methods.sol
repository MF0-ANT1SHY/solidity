contract C {
    function f() public {
        address payable addr;
        uint balance = addr.balance;
        (bool callSuc,) = addr.call("");
        (bool delegatecallSuc,) = addr.delegatecall("");
        bool sendRet = addr.send(1);
        addr.transfer(1);
        balance; callSuc; delegatecallSuc; sendRet;
    }
}
// ----
// Warning 9207: (227-236): send will be deprecated in the next breaking version.
// Warning 9207: (249-262): transfer will be deprecated in the next breaking version.
