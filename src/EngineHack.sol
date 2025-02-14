// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EngineHack {
    function destroy() external {
        selfdestruct(payable(msg.sender));
    }
}
