pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

contract StakeHouseUniverse {

    uint256 public numberOfStakeHouses;
    address public slotRegistry;

    mapping(address => uint256) public stakeHouseToKNOTIndex;
    mapping(uint256 => mapping(uint256 => bytes)) public subKNOTAtIndexCoordinates;

}