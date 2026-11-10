// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Checklist: deploy("Hello"), greeting(), setGreeting("Xin chao"), doc lai.
contract Greeting {
    string public greeting;
    event GreetingChanged(address indexed sender, string message);
    constructor(string memory initialGreeting) { greeting = initialGreeting; }
    function setGreeting(string calldata message) external {
        greeting = message;
        emit GreetingChanged(msg.sender, message);
    }
}
