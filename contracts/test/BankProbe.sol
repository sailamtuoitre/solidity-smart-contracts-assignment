// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
// Test helper only: attempts a nested bank withdrawal, or rejects ETH.
interface ITestBank {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}
contract BankProbe {
    ITestBank public bank;
    bool public rejectPayment;
    bool public nestedSucceeded;
    constructor(address target) { bank = ITestBank(target); }
    function deposit() external payable { bank.deposit{value: msg.value}(); }
    function withdraw(uint256 amount, bool reject) external {
        rejectPayment = reject;
        bank.withdraw(amount);
    }
    receive() external payable {
        require(!rejectPayment, "Reject payment");
        (nestedSucceeded,) = address(bank).call(abi.encodeCall(ITestBank.withdraw, (1)));
    }
}
