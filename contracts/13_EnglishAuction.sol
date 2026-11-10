// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IAuctionNFT {
    function ownerOf(uint256 id) external view returns (address);
    function transferFrom(address from, address to, uint256 id) external;
}

// Checklist: seller deploy(nft,id,reserve wei,duration); approve auction; start;
// B bid; C bid cao hon; B withdraw; het han end; winner nhan NFT, seller withdraw.
// NFT duoc ky gui; refund bang pull-payment de nguoi bi vuot gia khong chan dau gia.
contract EnglishAuction {
    IAuctionNFT public immutable nft;
    uint256 public immutable tokenId;
    address public immutable seller;
    uint256 public immutable duration;
    uint256 public immutable reservePrice;
    uint256 public endAt;
    bool public started;
    bool public ended;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public pendingReturns;
    event Started(uint256 endAt);
    event Bid(address indexed bidder, uint256 amount);
    event Ended(address indexed winner, uint256 amount);
    constructor(address nftAddress, uint256 id, uint256 reserve, uint256 secondsToRun) {
        require(nftAddress.code.length > 0 && secondsToRun > 0, "Invalid auction");
        nft = IAuctionNFT(nftAddress); tokenId = id; seller = msg.sender;
        reservePrice = reserve; duration = secondsToRun;
    }
    function start() external {
        require(msg.sender == seller && !started, "Cannot start");
        require(nft.ownerOf(tokenId) == seller, "Seller must own NFT");
        started = true; endAt = block.timestamp + duration;
        nft.transferFrom(seller, address(this), tokenId);
        emit Started(endAt);
    }
    function bid() external payable {
        require(started && !ended && block.timestamp < endAt, "Auction inactive");
        require(msg.sender != seller, "Seller cannot bid");
        require(msg.value >= reservePrice && msg.value > highestBid, "Bid too low");
        if (highestBidder != address(0)) pendingReturns[highestBidder] += highestBid;
        highestBidder = msg.sender; highestBid = msg.value;
        emit Bid(msg.sender, msg.value);
    }
    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No refund");
        pendingReturns[msg.sender] = 0;
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "ETH transfer failed");
    }
    function end() external {
        require(started && !ended && block.timestamp >= endAt, "Cannot end");
        ended = true;
        address recipient = highestBidder == address(0) ? seller : highestBidder;
        if (highestBidder != address(0)) pendingReturns[seller] += highestBid;
        // transferFrom khong goi receiver: bidder dang contract phai tu quan ly NFT.
        nft.transferFrom(address(this), recipient, tokenId);
        emit Ended(highestBidder, highestBid);
    }
}
