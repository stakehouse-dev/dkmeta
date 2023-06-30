pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

interface IStakeHouseRegistry {
    function isActiveMember(bytes calldata _blsPubKey) external view returns (bool);
    function hasMemberRageQuit(bytes calldata _blsPubKey) external view returns (bool);
    function numberOfMemberKNOTs() external view returns (uint256);
    function getMemberInfo(bytes memory _memberId) external view returns (
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint16 flags,          // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    );
}