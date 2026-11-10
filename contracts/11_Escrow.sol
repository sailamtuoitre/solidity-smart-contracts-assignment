// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Checklist: buyer deploy(seller,arbiter) kem ETH; confirmDelivery -> tra seller;
// refundBuyer -> buyer; raiseDispute -> arbiter resolve; cam sai state/role.
// Arbiter la ben duoc tin cay; khong co timeout. Payout that bai thi revert.
contract Escrow {
    enum State { AwaitingPayment, AwaitingDelivery, Complete, Refunded, Disputed }
    address payable public immutable buyer;
    address payable public immutable seller;
    address payable public immutable arbiter;
    State public state;
    event StateChanged(State state);
    modifier stateCheck(State expected) { require(state == expected, "Wrong state"); _; }
    constructor(address payable _seller, address payable _arbiter) payable {
        require(_seller != address(0) && _arbiter != address(0), "Zero party");
        require(_seller != msg.sender && _arbiter != msg.sender && _seller != _arbiter, "Distinct parties required");
        require(msg.value > 0, "Payment required");
        buyer = payable(msg.sender); seller = _seller; arbiter = _arbiter;
        state = State.AwaitingDelivery;
    }
    function confirmDelivery() external stateCheck(State.AwaitingDelivery) {
        require(msg.sender == buyer, "Only buyer");
        _pay(seller, State.Complete);
    }
    function refundBuyer() external stateCheck(State.AwaitingDelivery) {
        require(msg.sender == arbiter || msg.sender == seller, "Only arbiter or seller");
        _pay(buyer, State.Refunded);
    }
    function raiseDispute() external stateCheck(State.AwaitingDelivery) {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller");
        state = State.Disputed;
        emit StateChanged(state);
    }
    function resolveToSeller() external stateCheck(State.Disputed) {
        require(msg.sender == arbiter, "Only arbiter");
        _pay(seller, State.Complete);
    }
    function resolveToBuyer() external stateCheck(State.Disputed) {
        require(msg.sender == arbiter, "Only arbiter");
        _pay(buyer, State.Refunded);
    }
    function _pay(address payable to, State next) private {
        state = next; // Chuyen state truoc khi goi ra ngoai, chan rut hai lan.
        (bool ok,) = to.call{value: address(this).balance}("");
        require(ok, "ETH transfer failed");
        emit StateChanged(next);
    }
}
