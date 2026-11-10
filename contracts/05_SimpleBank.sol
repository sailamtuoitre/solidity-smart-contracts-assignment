// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Checklist: deposit 1 ETH; withdraw 0.4; balances con 0.6; cam rut vuot so du.
contract SimpleBank {
    mapping(address => uint256) public balances;
    bool private locked;
    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);
    function deposit() public payable {
        require(msg.value > 0, "Zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    receive() external payable { deposit(); }
    function withdraw(uint256 amount) external {
        require(!locked, "Reentrant call");
        require(amount > 0 && amount <= balances[msg.sender], "Invalid amount");
        locked = true;
        // Checks -> effects -> interactions: tru so du truoc khi gui ETH.
        balances[msg.sender] -= amount;
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "ETH transfer failed");
        locked = false;
        emit Withdrawn(msg.sender, amount);
    }
}
