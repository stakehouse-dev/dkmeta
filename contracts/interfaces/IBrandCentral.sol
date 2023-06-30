pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { IGateKeeper } from './IGateKeeper.sol';

// @title Public facing functions of CommunityCentral
interface IBrandCentral {
    /// @notice Emitted when all of the brand central modules are initialised
    event BrandCentralInit();

    /// @notice Merkle tree of community participants that can claim items from open pool updated
    event CommunityMerkleTreeUpdated();

    /// @notice Last orders community end block set
    event CommunityPriorityEndBlockUpdated();

    /// @notice All of the SLOT for a given KNOT has been aligned with a brand id
    event SlotAssociatedWithBrand(bytes memberId);

    /// @notice A KNOT founded a brand
    event BrandNFTClaimed(uint256 indexed brandTokenId);

    /// @notice A KNOT joined a brand and claimed their goodie bag from the brand
    event skLootBagClaimed(uint256 indexed tokenId);

    /// @notice For a given KNOT that wants to associate with another brand, it can do so by moving away from the current one
    /// @param _brandTokenId ID of the new brand
    /// @param _stakeHouse StakeHouse associated with KNOT
    /// @param _memberId ID of the KNOT that is part of the StakeHouse
    function moveSlotToAnotherBrand(uint256 _brandTokenId, address _stakeHouse, bytes calldata _memberId) external;

    /// @notice Allow a KNOT applicant / owner to claim the skLootBag if they have forfeited the opportunity to create a brand
    /// @param _stakeHouse Address of the StakeHouse that the KNOT is part of
    /// @param _memberId ID of the KNOT that has been added to the StakeHouse
    /// @param _characterId ID of the character that the user has chosen
    function skLootBagClaim(address _stakeHouse, bytes calldata _memberId, uint256 _characterId) external;

    /// @notice Method allowing anyone to claim skLoot item from the open pool when a new member is added to any StakeHouse
    /// @notice Item given is from a lucky dip list where special draws can be made from a rare gem list
    /// @param _stakeHouse StakeHouse where member was added
    /// @param _memberId ID of the KNOT added to a StakeHouse
    function skOpenLootPoolClaim(address _stakeHouse, bytes calldata _memberId) external;

    /// @notice Allow a community net member to claim from the community net pool if they are in the merkle tree
    /// @param _index tree index
    /// @param _merkleProof Account proof of presence in merkle tree
    function skCommunityPoolLootClaim(address _stakeHouse, bytes calldata _memberId, uint256 _index, bytes32[] calldata _merkleProof) external;

    /// @notice Allow a brand owner to control which KNOTs are allowed to associate their SLOT with the brand
    /// @param _brandTokenId Token ID of the brand
    /// @param _gateKeeper Address of the gate keeper contract. Set to zero to disable gate keeping
    function setBrandGateKeeper(uint256 _brandTokenId, IGateKeeper _gateKeeper) external;

    /// @notice Allow a brand owner to set the brand building type for issued goodie bags
    function registerBuildingTypeToBrand(uint256 _brandTokenId, uint256 _buildingTypeId) external;
}
