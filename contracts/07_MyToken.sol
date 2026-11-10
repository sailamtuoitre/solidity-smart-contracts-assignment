// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Checklist: deploy("VikToken","VKT",1000000); transfer; approve; transferFrom;
// cam vuot balance/allowance, dia chi 0. Supply tinh theo don vi nho nhat.
contract MyToken {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public immutable totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor(string memory _n, string memory _s, uint256 _supply) {
        name = _n; symbol = _s; totalSupply = _supply;
        balanceOf[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Zero spender");
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        uint256 permitted = allowance[from][msg.sender];
        require(permitted >= value, "Insufficient allowance");
        if (permitted != type(uint256).max) allowance[from][msg.sender] = permitted - value;
        _transfer(from, to, value);
        return true;
    }
    function _transfer(address from, address to, uint256 value) private {
        require(from != address(0) && to != address(0), "Zero address");
        require(balanceOf[from] >= value, "Insufficient balance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }
}
