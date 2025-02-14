// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Privacy {
    function unlock(bytes16) external;
}

contract UnlockPrivacy {
    function unlock(address targetContractAddress, bytes32 dataItem) public {
        Privacy targetContract = Privacy(targetContractAddress);
        targetContract.unlock(bytes16(dataItem));
    }
}
