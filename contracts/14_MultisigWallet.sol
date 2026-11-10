// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Checklist: deploy([A,B,C],2); nap ETH; submitTransaction; A,B confirm;
// executeTransaction; cam duplicate confirm, non-owner, chua du chu ky, replay.
contract MultisigWallet {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public immutable required;
    struct Transaction { address to; uint256 value; bytes data; bool executed; uint256 confirmations; }
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;
    bool private locked;
    event Deposit(address indexed from, uint256 amount);
    event Submitted(uint256 indexed id, address indexed to, uint256 value);
    event Confirmed(uint256 indexed id, address indexed owner);
    event Revoked(uint256 indexed id, address indexed owner);
    event Executed(uint256 indexed id);
    modifier onlyOwner() { require(isOwner[msg.sender], "Only owner"); _; }
    modifier pending(uint256 id) {
        require(id < transactions.length, "Unknown transaction");
        require(!transactions[id].executed, "Already executed"); _;
    }
    constructor(address[] memory initialOwners, uint256 threshold) {
        require(initialOwners.length > 0 && threshold > 0 && threshold <= initialOwners.length, "Invalid threshold");
        for (uint256 i; i < initialOwners.length; i++) {
            address account = initialOwners[i];
            require(account != address(0) && !isOwner[account], "Invalid owner");
            isOwner[account] = true; owners.push(account);
        }
        required = threshold;
    }
    receive() external payable { emit Deposit(msg.sender, msg.value); }
    function transactionCount() external view returns (uint256) { return transactions.length; }
    function submitTransaction(address to, uint256 value, bytes calldata data) external onlyOwner returns (uint256 id) {
        require(to != address(0), "Zero recipient");
        id = transactions.length;
        transactions.push(Transaction(to, value, data, false, 0));
        emit Submitted(id, to, value);
    }
    function confirmTransaction(uint256 id) external onlyOwner pending(id) {
        require(!confirmed[id][msg.sender], "Already confirmed");
        confirmed[id][msg.sender] = true; transactions[id].confirmations++;
        emit Confirmed(id, msg.sender);
    }
    function revokeConfirmation(uint256 id) external onlyOwner pending(id) {
        require(confirmed[id][msg.sender], "Not confirmed");
        confirmed[id][msg.sender] = false; transactions[id].confirmations--;
        emit Revoked(id, msg.sender);
    }
    function executeTransaction(uint256 id) external onlyOwner pending(id) {
        require(!locked, "Reentrant call");
        Transaction storage txn = transactions[id];
        require(txn.confirmations >= required, "Not enough confirmations");
        locked = true; txn.executed = true;
        (bool ok,) = txn.to.call{value: txn.value}(txn.data);
        require(ok, "Execution failed");
        locked = false;
        emit Executed(id);
    }
}
