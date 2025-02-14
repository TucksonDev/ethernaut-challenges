// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestAddressMapping {
    function getAbiEncode(address key, uint8 slotIndex) public pure returns (bytes memory) {
        return abi.encode(key, slotIndex);
    }

    function getMappingElementSlotIndex(address key, uint8 slotIndex) public pure returns (bytes32) {
        return keccak256(abi.encode(key, slotIndex));
    }
}
