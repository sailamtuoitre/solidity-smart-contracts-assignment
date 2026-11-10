// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Checklist: deploy(beneficiary, lockSeconds); deposit; cam rut som;
// beneficiary extendLock; den han withdraw; cam nguoi khac rut/extend.
contract TimeLockVault {
    address payable public immutable beneficiary;
    uint256 public unlockTime;
    bool private locked;
    event Deposited(address indexed from, uint256 amount, uint256 newUnlockTime);
    event Withdrawn(address indexed to, uint256 amount);
    event LockExtended(uint256 newUnlockTime);
    modifier onlyBeneficiary() { require(msg.sender == beneficiary, "Only beneficiary"); _; }
    constructor(address payable _beneficiary, uint256 _lockSeconds) {
        require(_beneficiary != address(0) && _lockSeconds > 0, "Invalid vault");
        beneficiary = _beneficiary; unlockTime = block.timestamp + _lockSeconds;
    }
    function deposit() public payable {
        require(msg.value > 0, "Zero deposit");
        emit Deposited(msg.sender, msg.value, unlockTime);
    }
    receive() external payable { deposit(); }
    function extendLock(uint256 _extraSeconds) external onlyBeneficiary {
        require(_extraSeconds > 0, "Zero extension");
        // Sau khi het han, khoa lai tu thoi diem hien tai.
        uint256 base = block.timestamp > unlockTime ? block.timestamp : unlockTime;
        unlockTime = base + _extraSeconds;
        emit LockExtended(unlockTime);
    }
    function withdraw() external onlyBeneficiary {
        require(!locked, "Reentrant call");
        require(block.timestamp >= unlockTime, "Vault is still locked");
        uint256 amount = address(this).balance;
        require(amount > 0, "Empty vault");
        locked = true;
        (bool ok,) = beneficiary.call{value: amount}("");
        require(ok, "ETH transfer failed");
        locked = false;
        emit Withdrawn(beneficiary, amount);
    }
    function timeRemaining() external view returns (uint256) {
        return block.timestamp < unlockTime ? unlockTime - block.timestamp : 0;
    }
}
