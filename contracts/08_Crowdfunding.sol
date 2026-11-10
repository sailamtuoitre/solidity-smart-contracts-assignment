// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Checklist: contribute truoc deadline; dat goal -> owner claimFunds sau han;
// khong dat goal -> refund; cam claim/refund hai lan, contribute sau han.
contract Crowdfunding {
    address payable public immutable owner;
    uint256 public immutable goal;
    uint256 public immutable deadline;
    uint256 public raised;
    bool public claimed;
    mapping(address => uint256) public contributions;
    event Contributed(address indexed contributor, uint256 amount);
    event Claimed(uint256 amount);
    event Refunded(address indexed contributor, uint256 amount);
    constructor(uint256 _goal, uint256 _durationSeconds) {
        require(_goal > 0 && _durationSeconds > 0, "Invalid campaign");
        owner = payable(msg.sender); goal = _goal;
        deadline = block.timestamp + _durationSeconds;
    }
    function contribute() external payable {
        require(block.timestamp < deadline, "Campaign closed");
        require(msg.value > 0, "Zero contribution");
        contributions[msg.sender] += msg.value; raised += msg.value;
        emit Contributed(msg.sender, msg.value);
    }
    function getRemainingTime() public view returns (uint256) {
        return block.timestamp < deadline ? deadline - block.timestamp : 0;
    }
    function claimFunds() external {
        require(msg.sender == owner, "Only owner");
        require(block.timestamp >= deadline, "Campaign active");
        require(raised >= goal && !claimed, "Cannot claim");
        claimed = true;
        (bool ok,) = owner.call{value: raised}("");
        require(ok, "ETH transfer failed");
        emit Claimed(raised);
    }
    function refund() external {
        require(block.timestamp >= deadline, "Campaign active");
        require(raised < goal, "Goal reached");
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "Nothing to refund");
        contributions[msg.sender] = 0;
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "ETH transfer failed");
        emit Refunded(msg.sender, amount);
    }
}
