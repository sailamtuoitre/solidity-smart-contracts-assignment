// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// CHI DEMO: blockhash co the bi thao tung; khong dung cho tien that.
// Checklist: deploy(entryFee wei, minPlayers >=2); manager khong duoc enter;
// du nguoi -> manager pickWinner; tien thuong gui thanh cong; round reset.
// Moi lan enter la mot ve; manager la ben duoc tin cay, khong co timeout.
contract Lottery {
    address payable[] private players;
    address public immutable manager;
    uint256 public immutable entryFee;
    uint256 public immutable minPlayers;
    bool private locked;
    event Entered(address indexed player);
    event WinnerSelected(address indexed winner, uint256 amount);
    constructor(uint256 fee, uint256 minimumPlayers) {
        require(fee > 0 && minimumPlayers >= 2, "Invalid lottery");
        manager = msg.sender; entryFee = fee; minPlayers = minimumPlayers;
    }
    function enter() public payable {
        require(!locked, "Reentrant call");
        require(msg.sender != manager, "Manager cannot enter");
        require(msg.value == entryFee, "Wrong fee");
        players.push(payable(msg.sender));
        emit Entered(msg.sender);
    }
    function playersCount() public view returns (uint256) { return players.length; }
    function pickWinner() public {
        require(msg.sender == manager, "Only manager");
        require(!locked, "Reentrant call");
        require(players.length >= minPlayers, "Not enough players");
        locked = true;
        uint256 index = uint256(blockhash(block.number - 1)) % players.length;
        address payable winner = players[index];
        uint256 amount = address(this).balance;
        delete players;
        (bool ok,) = winner.call{value: amount}("");
        require(ok, "ETH transfer failed");
        locked = false;
        emit WinnerSelected(winner, amount);
    }
}
