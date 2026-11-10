// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IStakingToken {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// Checklist: deploy(stakeToken,rewardToken) la hai MyToken khac nhau;
// owner approve reward -> fundRewards(amount,duration); user approve stake -> stake;
// doi vai giay -> earned -> claimReward -> withdraw; khong duoc rut principal cua nguoi khac.
// Chi ho tro ERC20 chuan tra bool, khong fee-on-transfer/rebasing. Phan thuong lam tron xuong.
contract StakingRewards {
    IStakingToken public immutable stakingToken;
    IStakingToken public immutable rewardsToken;
    address public immutable owner;
    uint256 public totalStaked;
    mapping(address => uint256) public balanceOf;
    uint256 public rewardRate;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    bool private locked;
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event Funded(uint256 amount, uint256 duration);
    modifier nonReentrant() { require(!locked, "Reentrant call"); locked = true; _; locked = false; }
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    constructor(address stakeToken, address rewardToken) {
        require(stakeToken.code.length > 0 && rewardToken.code.length > 0 && stakeToken != rewardToken, "Invalid tokens");
        stakingToken = IStakingToken(stakeToken); rewardsToken = IStakingToken(rewardToken);
        owner = msg.sender;
    }
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;
        return rewardPerTokenStored + (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / totalStaked;
    }
    function earned(address account) public view returns (uint256) {
        return balanceOf[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }
    // Chi bat dau dot moi sau khi dot truoc ket thuc; luon nap tien thuong moi.
    function fundRewards(uint256 amount, uint256 duration) external nonReentrant updateReward(address(0)) {
        require(msg.sender == owner, "Only owner");
        require(block.timestamp >= periodFinish, "Reward period active");
        require(duration > 0 && amount >= duration, "Invalid rewards");
        require(rewardsToken.transferFrom(msg.sender, address(this), amount), "Funding failed");
        rewardRate = amount / duration;
        lastUpdateTime = block.timestamp; periodFinish = block.timestamp + duration;
        emit Funded(amount, duration);
    }
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Zero stake");
        totalStaked += amount; balanceOf[msg.sender] += amount;
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Stake transfer failed");
        emit Staked(msg.sender, amount);
    }
    function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0 && amount <= balanceOf[msg.sender], "Invalid amount");
        totalStaked -= amount; balanceOf[msg.sender] -= amount;
        require(stakingToken.transfer(msg.sender, amount), "Withdrawal failed");
        emit Withdrawn(msg.sender, amount);
    }
    function claimReward() external nonReentrant updateReward(msg.sender) {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "No rewards");
        rewards[msg.sender] = 0;
        require(rewardsToken.transfer(msg.sender, amount), "Reward transfer failed");
        emit RewardPaid(msg.sender, amount);
    }
}
