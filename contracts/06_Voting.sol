// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Checklist: deploy(["A","B"]); chairperson authorize(B); B vote(1);
// cam chua authorized, bo lan 2, index sai; winnerName = B.
// Mot dia chi mot phieu, khong dam bao mot nguoi mot phieu.
contract Voting {
    struct Candidate { string name; uint256 voteCount; }
    struct Voter { bool authorized; bool voted; uint256 voteIndex; }
    Candidate[] public candidates;
    mapping(address => Voter) public voters;
    address public immutable chairperson;
    event Authorized(address indexed voter);
    event Voted(address indexed voter, uint256 indexed candidateIndex);
    modifier onlyChairperson() { require(msg.sender == chairperson, "Only chairperson"); _; }
    constructor(string[] memory candidateNames) {
        require(candidateNames.length >= 2 && candidateNames.length <= 100, "Need 2-100 candidates");
        chairperson = msg.sender;
        voters[msg.sender].authorized = true;
        for (uint256 i; i < candidateNames.length; i++) {
            require(bytes(candidateNames[i]).length > 0, "Empty name");
            candidates.push(Candidate(candidateNames[i], 0));
        }
    }
    function authorize(address voter) external onlyChairperson {
        require(voter != address(0), "Zero voter");
        require(!voters[voter].authorized, "Already authorized");
        voters[voter].authorized = true;
        emit Authorized(voter);
    }
    function vote(uint256 candidateIndex) external {
        Voter storage voter = voters[msg.sender];
        require(voter.authorized, "Not authorized");
        require(!voter.voted, "Already voted");
        require(candidateIndex < candidates.length, "Invalid candidate");
        voter.voted = true;
        voter.voteIndex = candidateIndex;
        candidates[candidateIndex].voteCount++;
        emit Voted(msg.sender, candidateIndex);
    }
    function totalVotes(uint256 candidateIndex) external view returns (uint256) {
        require(candidateIndex < candidates.length, "Invalid candidate");
        return candidates[candidateIndex].voteCount;
    }
    // Ket qua tam thoi; hoa thi ung vien co ID nho hon thang, khong co deadline.
    function winnerName() external view returns (string memory) {
        uint256 winner;
        for (uint256 i = 1; i < candidates.length; i++) {
            if (candidates[i].voteCount > candidates[winner].voteCount) winner = i;
        }
        return candidates[winner].name;
    }
}
