// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

interface IForta {
    function raiseAlert(address user) external;
}

contract DetectionBot is IDetectionBot {

    // function delegateTransfer(address to, uint256 value, address origSender)
    bytes4 private constant delegateTransferSignature = bytes4(keccak256(bytes("delegateTransfer(address,uint256,address)")));
    address public vaultAddress;

    constructor(address _vaultAddress) {
        vaultAddress = _vaultAddress;
    }

    function handleTransaction(address user, bytes calldata msgData) external {
        if (bytes4(msgData[:4]) == delegateTransferSignature) {
            address to;
            uint256 value;
            address origSender;
            (to, value, origSender) = abi.decode(msgData[4:], (address, uint256, address));

            if (origSender == vaultAddress) {
                IForta forta = IForta(msg.sender);
                forta.raiseAlert(user);
            }
        }
    }
}
