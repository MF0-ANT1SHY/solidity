contract A layout at (2**256 + 1) * 2  - 2**256 - 3 {}
contract B layout at (2**2 - 2**3) * (2**5 - 2**8) {}
uint constant CONST1 = 1.23e100 / 2e50;
contract C layout at CONST1 {}
uint constant CONST2 = 2**256 * (500e-3);
contract D layout at CONST2 {}
uint constant CONST3 = (2**255 * 2) - (2**256 + 1) + 1;
contract E layout at CONST3 {}
// ----
// Warning 3495: (11-51): This contract is very close to the end of storage. This limits its future upgradability.
