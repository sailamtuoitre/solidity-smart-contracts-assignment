// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Checklist: retrieve() ban dau = 0; store(42) -> 42; store(0) -> 0.
// Thu them type(uint256).max va goi store tu tai khoan khac.
contract Storage {
    // Bien state duoc luu tren blockchain; uint256 mac dinh bang 0.
    uint256 private number;

    // Bat ky tai khoan nao cung co the ghi de gia tri. Giao dich ton gas.
    function store(uint256 value) external {
        number = value;
    }

    // view chi doc state; doc qua RPC khong can gui giao dich.
    function retrieve() external view returns (uint256) {
        return number;
    }
}
