// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SelfDestructExample {
    constructor() payable {}

    // 漏洞：未做权限控制，任意人可调用
    // 利用方式：攻击者直接调用 destroy(attacker)，合约余额被转走并销毁合约
    function destroy(address payable to) external {
        selfdestruct(to);
    }

    receive() external payable {}
}