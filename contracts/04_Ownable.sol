// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Checklist: owner = deployer; cam non-owner; transferOwnership(B); chu cu mat quyen.
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    modifier onlyOwner() { require(msg.sender == owner, "Not the owner"); _; }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Zero owner");
        address previous = owner;
        owner = newOwner;
        emit OwnershipTransferred(previous, newOwner);
    }
}

// Ke thua modifier onlyOwner: ai cung nap ETH, chi owner duoc rut.
contract ProtectedVault is Ownable {
    bool private locked;
    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    function deposit() public payable {
        require(msg.value > 0, "Zero deposit");
        emit Deposited(msg.sender, msg.value);
    }
    receive() external payable { deposit(); }
    function withdraw(address payable to, uint256 amt) public onlyOwner {
        require(!locked, "Reentrant call");
        require(to != address(0) && amt > 0 && amt <= address(this).balance, "Invalid withdrawal");
        locked = true;
        (bool ok,) = to.call{value: amt}("");
        require(ok, "ETH transfer failed");
        locked = false;
        emit Withdrawn(to, amt);
    }
    function contractBalance() public view returns (uint256) { return address(this).balance; }
}
