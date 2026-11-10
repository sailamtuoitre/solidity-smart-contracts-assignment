// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Checklist: increment -> 1; decrement -> 0; cam am; cam tang qua 100; reset -> 0.
contract Counter {
    uint256 public count;
    uint256 public constant Max = 100;
    event Incremented(address indexed updater, uint256 newCount);
    event Decremented(address indexed updater, uint256 newCount);
    event Reset(address indexed updater);
    function increment() public {
        require(count < Max, "Max limit reached");
        count++;
        emit Incremented(msg.sender, count);
    }
    function decrement() public {
        require(count > 0, "count is zero");
        count--;
        emit Decremented(msg.sender, count);
    }
    function reset() public {
        count = 0;
        emit Reset(msg.sender);
    }
}
