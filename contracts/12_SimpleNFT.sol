// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface INFTReceiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// Checklist: deploy(name,symbol); owner mint(to,uri); approve; transferFrom;
// cam mint boi nguoi khac / transfer trai phep; safeTransfer kiem tra receiver.
contract SimpleNFT {
    string public name;
    string public symbol;
    address public immutable minter;
    uint256 public nextTokenId = 1;
    mapping(uint256 => address) private owners;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) private approvals;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(uint256 => string) private uris;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    constructor(string memory _name, string memory _symbol) {
        name = _name; symbol = _symbol; minter = msg.sender;
    }
    function supportsInterface(bytes4 id) external pure returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd || id == 0x5b5e139f;
    }
    function balanceOf(address account) public view returns (uint256) {
        require(account != address(0), "Zero owner");
        return balances[account];
    }
    function ownerOf(uint256 id) public view returns (address) {
        address account = owners[id];
        require(account != address(0), "Unknown token");
        return account;
    }
    function tokenURI(uint256 id) external view returns (string memory) {
        ownerOf(id);
        return uris[id];
    }
    function mint(address to, string calldata uri) external returns (uint256 id) {
        require(msg.sender == minter, "Only minter");
        require(to != address(0), "Zero recipient");
        id = nextTokenId++;
        owners[id] = to; balances[to]++; uris[id] = uri;
        emit Transfer(address(0), to, id);
        _checkReceiver(address(0), to, id, "");
    }
    function getApproved(uint256 id) public view returns (address) {
        ownerOf(id);
        return approvals[id];
    }
    function approve(address to, uint256 id) external {
        address account = ownerOf(id);
        require(msg.sender == account || isApprovedForAll[account][msg.sender], "Not authorized");
        require(to != account, "Approval to owner");
        approvals[id] = to;
        emit Approval(account, to, id);
    }
    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "Approval to self");
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function transferFrom(address from, address to, uint256 id) public {
        address account = ownerOf(id);
        require(account == from, "Wrong from");
        require(to != address(0), "Zero recipient");
        require(msg.sender == account || approvals[id] == msg.sender || isApprovedForAll[account][msg.sender], "Not authorized");
        delete approvals[id];
        balances[from]--; balances[to]++; owners[id] = to;
        emit Transfer(from, to, id);
    }
    function safeTransferFrom(address from, address to, uint256 id) external {
        safeTransferFrom(from, to, id, "");
    }
    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) public {
        transferFrom(from, to, id);
        _checkReceiver(from, to, id, data);
    }
    function _checkReceiver(address from, address to, uint256 id, bytes memory data) private {
        if (to.code.length > 0) {
            require(INFTReceiver(to).onERC721Received(msg.sender, from, id, data) == INFTReceiver.onERC721Received.selector, "Unsafe receiver");
        }
    }
}
