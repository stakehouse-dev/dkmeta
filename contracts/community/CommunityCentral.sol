pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IBrandCentral } from '../interfaces/IBrandCentral.sol';
import { IGateKeeper } from '../interfaces/IGateKeeper.sol';
import { BrandNFT } from "./BrandNFT.sol";
import { BrandCentralClaimAuction } from "./BrandCentralClaimAuction.sol";
import { HouseGoodieBagFactory } from "./HouseGoodieBagFactory.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IStakeHouseRegistry } from "../interfaces/IStakeHouseRegistry.sol";
import { ModuleGuards } from "../guards/ModuleGuards.sol";

interface ISlotRegistry {
    function totalUserCollateralisedSLOTBalanceForKnot(
        address _stakeHouse,
        address _user,
        bytes calldata _knotBlsPubKey
    ) external view returns (uint256);
}

/// @title Community Software Development Kit - Central place for brand, house goodie bags and goodie items
contract CommunityCentral is Initializable, IBrandCentral, ModuleGuards {

    struct CommunityNetMerkleTreeMetadata {
        bytes32 root; // merkle tree root
        string dataIpfsHash; // IPFS hash containing all merkle tree nodes
    }

    /// @notice End block when priority over the open loot pool ends
    uint256 public communityNetPriorityEndBlock;

    /// @notice restricted brand ticker -> ticker recipient -> is enabled
    mapping(string => mapping(address => bool)) public isRestrictedTickerRecipient;

    /// @notice KNOT member ID -> brand token ID
    mapping(bytes => uint256) public knotToAssociatedBrandTokenId;

    /// @notice Brand token ID -> number of knots (and their SLOT) which is associated with brand
    mapping(uint256 => uint256) public numberOfKnotsAssociatedWithBrand;

    /// @notice KNOT member ID -> whether skLoot item has been minted in the open pool
    mapping(bytes => bool) public skOpenLootClaimed;

    /// @notice Community net member -> whether they have claimed ANY NFT from the open pool during priority period
    mapping(address => bool) public communityNetNftClaimed;

    /// @notice Brand token ID to address of smart contract gate keeping users from joining brand (if set)
    mapping(uint256 => IGateKeeper) public brandGateKeeper;

    /// @notice Merkle Tree metadata associated with community net participants
    CommunityNetMerkleTreeMetadata public communityNetMerkleMetadata;

    /// @notice skLootBag and skLootItem factory for brand central
    HouseGoodieBagFactory public skLootFactory;

    /// @notice SHB ticker auction contract
    BrandCentralClaimAuction public claimAuction;

    /// @notice ERC721 brand nft contract
    BrandNFT public brandNFT;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(
        address _brandNFTLogic,
        address _goodieFactoryLogic,
        address _goodieLogic,
        BrandCentralClaimAuction _claimAuction
    ) external initializer {
        require(address(_brandNFTLogic) != address(0), "NFT is zero");
        require(address(_goodieFactoryLogic) != address(0), "Loot factory is zero");
        require(address(_claimAuction) != address(0), "Claim auction is zero");

        brandNFT = BrandNFT(address(
                new ERC1967Proxy(_brandNFTLogic, abi.encodeCall(BrandNFT(_brandNFTLogic).init, (address(this))))
            ));

        skLootFactory = HouseGoodieBagFactory(address(
                new ERC1967Proxy(_goodieFactoryLogic, abi.encodeCall(
                    HouseGoodieBagFactory(_goodieFactoryLogic).init,
                    (CommunityCentral(address(this)), _goodieLogic)
                ))
            ));

        claimAuction = _claimAuction;

        emit BrandCentralInit();
    }

    /// @notice Users adding a KNOT and creating a brand achieve: Creation of a brand, registering a building and associating a KNOT with a brand
    /// @param _brandTicker 3 - 5 character ticker being minted
    /// @param _recipient of the brand NFT
    /// @param _memberId ID of the KNOT being added to the StakeHouse
    function mintBrand(
        string calldata _brandTicker,
        address _recipient,
        bytes calldata _memberId
    ) external onlyModule returns (uint256) {
        _assertBrandMintingPossible(_brandTicker, _recipient);

        uint256 brandTokenId = brandNFT.mint(_brandTicker, _memberId, _recipient);

        // associate KNOT with brand token ID
        _associateSlotWithBrand(brandTokenId, _memberId);

        return brandTokenId;
    }

    /// @inheritdoc IBrandCentral
    function registerBuildingTypeToBrand(uint256 _brandTokenId, uint256 _buildingTypeId) external override {
        require(msg.sender == brandNFT.ownerOf(_brandTokenId), "Only creator");
        skLootFactory.registerBuildingTypeToBrand(_brandTokenId, _buildingTypeId);
    }

    /// @inheritdoc IBrandCentral
    function setBrandGateKeeper(uint256 _brandTokenId, IGateKeeper _gateKeeper) external override {
        require(msg.sender == brandNFT.ownerOf(_brandTokenId), "Only creator");
        brandGateKeeper[_brandTokenId] = _gateKeeper;
    }

    /// @notice For KNOTs joining an existing StakeHouse that are not creating a brand, they must associate with a brand via this universe method
    /// @param _brandTokenId ID of the brand token
    /// @param _memberId ID of the KNOT being added to the StakeHouse
    function associateSlotWithBrand( // a.k.a 'follow' a brand
        uint256 _brandTokenId,
        bytes calldata _memberId
    ) external onlyModule {
        require(msg.sender == address(universe), "Only universe");
        require(brandNFT.exists(_brandTokenId), "Brand does not exist");
        _associateSlotWithBrand(_brandTokenId, _memberId);
    }

    /// @notice If an existing knot that is associated with a brand is rage quitting, we need to remove the association
    function removeSlotAssociationWithBrand(bytes calldata _memberId) external onlyModule {
        require(knotToAssociatedBrandTokenId[_memberId] > 0, "Not associated with brand");

        uint256 brandTokenId = knotToAssociatedBrandTokenId[_memberId];
        knotToAssociatedBrandTokenId[_memberId] = 0;
        numberOfKnotsAssociatedWithBrand[brandTokenId] -= 1;
    }

    /// @inheritdoc IBrandCentral
    function moveSlotToAnotherBrand( // a.k.a 'follow' another brand instead of the current brand that a KNOT is associated with
        uint256 _brandTokenId,
        address _stakeHouse,
        bytes calldata _memberId
    ) external override onlyValidStakeHouse(_stakeHouse) onlyValidStakeHouseKnot(_stakeHouse, _memberId) {
        require(
            _isCollateralisedSlotOwnerForKnot(_stakeHouse, msg.sender, _memberId),
            "Only collateralised slot"
        );

        require(brandNFT.exists(_brandTokenId), "Brand does not exist");

        uint256 currentBrandTokenId = knotToAssociatedBrandTokenId[_memberId];
        require(currentBrandTokenId > 0, "Not associated with a brand");
        require(currentBrandTokenId != _brandTokenId, "Invalid move to same brand");
        require(skLootFactory.brandTokenIdToBuildingTypeId(currentBrandTokenId) > 0, "Current brand not set up");

        if (!hasKnotClaimedBrandNFT(_memberId)) {
            require(!isLootBagAvailableForKnot(_memberId), "Cannot move until skLootBag minted");
            require(skOpenLootClaimed[_memberId], "Cannot move until skLoot item minted");
        }

        numberOfKnotsAssociatedWithBrand[currentBrandTokenId] -= 1;
        _associateSlotWithBrand(_brandTokenId, _memberId);
    }

    /// @inheritdoc IBrandCentral
    function skLootBagClaim(
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _characterId
    ) external override onlyValidStakeHouse(_stakeHouse) onlyValidStakeHouseKnot(_stakeHouse, _memberId) {
        (address applicant, uint256 knotMemberIndex,,) = IStakeHouseRegistry(_stakeHouse).getMemberInfo(_memberId);
        {
            require(msg.sender == applicant, "Only applicant");
            require(skLootFactory.brandTokenIdToBuildingTypeId(knotToAssociatedBrandTokenId[_memberId]) > 0, "Current brand not set up");
            require(!hasKnotClaimedBrandNFT(_memberId), "Cannot claim a brand and a skLootBag");
        }

        uint256 tokenId = skLootFactory.skLootBagClaim(
            knotToAssociatedBrandTokenId[_memberId],
            universe.stakeHouseToKNOTIndex(_stakeHouse),
            knotMemberIndex,
            _characterId,
            _memberId,
            msg.sender
        );

        emit skLootBagClaimed(tokenId);
    }

    /// @inheritdoc IBrandCentral
    function skOpenLootPoolClaim(
        address _stakeHouse,
        bytes calldata _memberId
    ) external override onlyValidStakeHouse(_stakeHouse) onlyValidStakeHouseKnot(_stakeHouse, _memberId) {
        require(!skOpenLootClaimed[_memberId], "skLOOT already claimed from the open pool");
        require(knotToAssociatedBrandTokenId[_memberId] > 0, "Not associated with brand");
        require(skLootFactory.brandTokenIdToBuildingTypeId(knotToAssociatedBrandTokenId[_memberId]) > 0, "Current brand not set up");
        require(_blockNumber() >= communityNetPriorityEndBlock, "CommunityNet still has priority");

        skOpenLootClaimed[_memberId] = true;

        skLootFactory.skLootItemClaim(_stakeHouse, msg.sender, knotToAssociatedBrandTokenId[_memberId]);
    }

    /// @inheritdoc IBrandCentral
    function skCommunityPoolLootClaim(
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _index,
        bytes32[] calldata _merkleProof
    ) external override onlyValidStakeHouse(_stakeHouse) onlyValidStakeHouseKnot(_stakeHouse, _memberId) {
        require(_blockNumber() < communityNetPriorityEndBlock, "CommunityNet priority has ended");
        require(!skOpenLootClaimed[_memberId], "skLOOT already claimed from the open pool");
        require(!communityNetNftClaimed[msg.sender], "skLoot claimed by community member");
        require(knotToAssociatedBrandTokenId[_memberId] > 0, "Not associated with brand");
        require(skLootFactory.brandTokenIdToBuildingTypeId(knotToAssociatedBrandTokenId[_memberId]) > 0, "Current brand not set up");

        bytes32 node = keccak256(abi.encodePacked(_index, msg.sender));
        require(
            MerkleProof.verify(_merkleProof, communityNetMerkleMetadata.root, node),
            "Merkle verification failed"
        );

        skOpenLootClaimed[_memberId] = true;
        communityNetNftClaimed[msg.sender] = true;

        skLootFactory.skLootItemClaim(_stakeHouse, msg.sender, knotToAssociatedBrandTokenId[_memberId]);
    }

    /// @notice Can check whether a skLoot bag has been claimed by a KNOT owner
    function isLootBagAvailableForKnot(bytes calldata _memberId) public view returns (bool) {
        return skLootFactory.knotToLootBagTokenId(_memberId) == 0;
    }

    /// @notice Whether a KNOT has claimed a brand over an skLootBag
    function hasKnotClaimedBrandNFT(bytes calldata _memberId) public view returns (bool) {
        return brandNFT.foundingKnotToTokenId(_memberId) > 0;
    }

    /// @dev Pre-flight checks for minting a brand
    function _assertBrandMintingPossible(string calldata _brandTicker, address _recipient) internal view {
        string memory lowerBrandTicker = brandNFT.toLowerCase(_brandTicker);

        // Ensure only the legitimate callers are claiming restricted tickers
        uint256 claimTokenId = claimAuction.lowerTickerToTokenId(lowerBrandTicker);
        if (claimTokenId > 0) {
            require(claimAuction.ownerOf(claimTokenId) == _recipient, "Only claim token owner");
        } else if (claimAuction.isRestrictedBrandTicker(lowerBrandTicker)) {
            require(isRestrictedTickerRecipient[lowerBrandTicker][_recipient], "Restricted brand ticker");
        }
    }

    /// @dev Method for associating the SLOT of a KNOT with a brand and increasing the number of KNOTs associated with the brand
    function _associateSlotWithBrand(
        uint256 _brandTokenId,
        bytes calldata _memberId
    ) internal {
        if (address(brandGateKeeper[_brandTokenId]) != address(0)) {
            require(brandGateKeeper[_brandTokenId].isMemberPermitted(_memberId), "Blocked");
        }

        knotToAssociatedBrandTokenId[_memberId] = _brandTokenId;

        unchecked { // unlikely to exceed ( (2 ^ 256) - 1 )
            numberOfKnotsAssociatedWithBrand[_brandTokenId] += 1;
        }

        emit SlotAssociatedWithBrand(_memberId);
    }

    /// @dev For a given KNOT, does a collateralised slot owner own at least 2 SLOT for certain operations
    function _isCollateralisedSlotOwnerForKnot(
        address _stakeHouse,
        address _slotOwner,
        bytes calldata _memberId
    ) internal view returns (bool) {
        ISlotRegistry slotRegistry = ISlotRegistry(address(universe.slotRegistry()));
        return slotRegistry.totalUserCollateralisedSLOTBalanceForKnot(_stakeHouse, _slotOwner, _memberId) >= 2 ether;
    }

    /// @dev internal method that can be overriden for testing
    function _blockNumber() internal virtual view returns (uint256) {
        return block.number;
    }
}
