pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "../libraries/Base64.sol";
import { CommunityCentral } from "./CommunityCentral.sol";
import { StakeHouseUniverse } from "../StakeHouseUniverse.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { HouseGoodie } from "./HouseGoodie.sol";
import { IStakeHouseRegistry } from "../interfaces/IStakeHouseRegistry.sol";

/// @title The goodie bag and goodie item factory.
/// @notice The HouseGoodieBagFactory contains the blue print for creating meta-composable goodie bags as well as goodie items
contract HouseGoodieBagFactory is ERC721Upgradeable {
    using Base64 for bytes;
    using Strings for uint256;

    /// @notice A new brand has assigned a building that all goodie bags will receive
    event BuildingTypeRegisteredToBrand(uint256 indexed brandTokenId, uint256 indexed buildingTypeId);

    /// @notice An item has been removed from a goodie bag and minted
    event skLootBagItemRemoved(uint256 indexed bagTokenId, skBagComponent componentRemoved);

    /// @notice An item from the open pool has been claimed for a new KNOT
    event skLootItemClaimedForKnot(uint256 indexed tokenId);

    /// @notice List of building types that can be associated with brands
    function buildingTypes() public pure returns (string[6] memory) {
        return [
        "None",
        "Skyscraper",
        "House",
        "Office",
        "Apartment Block",
        "NFT Art Gallery"
        ];
    }

    /// @notice List of characters that skLootBag hodlers can elect to represent themselves
    function characters() public pure returns (string[9] memory) {
        return [
        "Ultrasound Bat",
        "Whale",
        "Punk",
        "Ape",
        "Degen",
        "Maxi",
        "Hodler",
        "Staker",
        "Farmer"
        ];
    }

    // Coordinates that define a piece of land in the StakeHouse metaverse
    struct sLandCoordinates {
        uint256 x; // StakeHouse index in universe
        uint256 y; // KNOT index within the StakeHouse
    }

    // Definition of a skLootBag (StakeHouse KNOT loot bag)
    // It consists of 3 items from 3 categories:
    // sLAND - coordinates that are unique and exclusive to the KNOT that minted the bag
    // sBUILDING - Building that is derived from the associated brand
    // sCHAR - The persona that the skLootBag hodler wants to be in the sMetaverse
    struct skLootBag {
        sLandCoordinates land;
        string building;
        string character;
    }

    // 3 categories of a skLootBag defined in an enum structure
    enum skBagComponent {
        sLand,
        sBuilding,
        sCharacter
    }

    // ------------- Open Pool Comments -------------------
    // Community members will have the opportunity to mint an skLootItem NFT
    // The item minted is pseudo randomly selected from the lucky dip list unless the code
    // goes down a 'special' path in which a rare or super rare gem will be minted.
    function luckyDipItems() public pure returns (string[8] memory) {
        return [
        "Potion",
        "Sword",
        "Shield",
        "Treasure Map",
        "Keys",
        "Axe",
        "Pick Axe",
        "Food"
        ];
    }

    function specialLuckyDipGems() public pure returns (string[6] memory) {
        return [
        "Ruby",
        "Sapphire",
        "Flawless Garnet", // Rarest item
        "Emerald",
        "Diamond",
        "Tanzanite"       // Rarest item
        ];
    }

    // ------------- End Open Pool Comments --------------

    /// @notice Track which components of an skLootBag has been removed (The skLootBag is meta composable)
    mapping(uint256 => mapping(skBagComponent => bool)) public skLootBagTokenIdToComponentRemoved;

    /// @notice skLootBag token ID associated with a KNOT that was added to a StakeHouse
    mapping(bytes => uint256) public knotToLootBagTokenId;

    /// @notice Token ID -> sk loot bag info
    mapping(uint256 => skLootBag) public skLootBagTokenInfo;

    /// @notice skLootBag token ID -> brand token ID
    mapping(uint256 => uint256) public lootBagTokenIdToBrandTokenId;

    /// @notice Brand token ID -> building type Id from the buildingTypes array
    mapping(uint256 => uint256) public brandTokenIdToBuildingTypeId;

    /// @notice Total supply of the loot bags only
    uint256 public totalSupply;

    /// @notice Community central contract address
    CommunityCentral public brandCentral;

    /// @notice Address of the HouseGoodie item NFT contract
    HouseGoodie public skLoot;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(CommunityCentral _brandCentral, address _skLootLogic) external initializer {
        require(address(_brandCentral) != address(0), "Brand central is zero");
        require(_skLootLogic != address(0), "Loot logic is zero");
        brandCentral = _brandCentral;

        __ERC721_init("skGoodieBag", "skGoodieBag");

        ERC1967Proxy skLootProxy = new ERC1967Proxy(
            _skLootLogic,
            abi.encodeCall(
                HouseGoodie(_skLootLogic).init,
                (HouseGoodieBagFactory(address(this)))
            )
        );

        skLoot = HouseGoodie(address(skLootProxy));
    }

    /// @notice Brand central method for associating a building type ID with a brand token
    /// @notice Once set, then all loot bags for a brand are minted with this building type
    /// @param _brandTokenId Token ID of the brand
    /// @param _buildingTypeId ID of the building type (index of the buildingTypes array)
    function registerBuildingTypeToBrand(uint256 _brandTokenId, uint256 _buildingTypeId) external {
        require(msg.sender == address(brandCentral), "Only brand central");
        require(_buildingTypeId > 0, "Type ID cannot be 0");
        require(_buildingTypeId < 6, "Invalid building type ID");
        require(brandTokenIdToBuildingTypeId[_brandTokenId] == 0, "Already registered");

        brandTokenIdToBuildingTypeId[_brandTokenId] = _buildingTypeId;

        emit BuildingTypeRegisteredToBrand(_brandTokenId, _buildingTypeId);
    }

    /// @notice Brand central method for allowing a new StakeHouse KNOT to claim an skLootBag
    /// @param _brandTokenId Token ID of brand associated with KNOT
    /// @param _stakeHouseKnotIndex Index of the StakeHouse associated with KNOT
    /// @param _memberKnotIndex Index of the KNOT within the StakeHouse
    /// @param _characterId ID of the character chosen by the KNOT owner (from the character array)
    /// @param _memberId ID of the member part of the StakeHouse (validator public key)
    /// @param _recipient Proud owner of the skLootBag
    function skLootBagClaim(
        uint256 _brandTokenId,
        uint256 _stakeHouseKnotIndex,
        uint256 _memberKnotIndex,
        uint256 _characterId,
        bytes calldata _memberId,
        address _recipient
    ) external returns (uint256) {
        require(msg.sender == address(brandCentral), "Only brand central");
        require(brandTokenIdToBuildingTypeId[_brandTokenId] > 0, "Building type not registered");
        require(knotToLootBagTokenId[_memberId] == 0, "House goodie claimed");
        require(_characterId < 9, "Invalid character ID");

        // token ID is driven by total supply
    unchecked { // unlikely to exceed ( (2 ^ 256) - 1 )
        totalSupply += 1;
    }

        // Brand is always associated with a loot bag
        lootBagTokenIdToBrandTokenId[totalSupply] = _brandTokenId;

        // record sk loot bag info
        knotToLootBagTokenId[_memberId] = totalSupply;
        skLootBagTokenInfo[totalSupply] = skLootBag({
        land: sLandCoordinates(_stakeHouseKnotIndex, _memberKnotIndex),
        building: buildingTypes()[brandTokenIdToBuildingTypeId[_brandTokenId]],
        character: characters()[_characterId]
        });

        _mint(_recipient, totalSupply);

        return totalSupply;
    }

    /// @notice With the skLootBag being meta composable NFT, the items in the bag can be removed by minting them
    /// @param _tokenId Token ID of the loot bag
    /// @param _componentToRemove Enum specifying which item category in the bag is being removed
    /// @param _recipient Who is to receive the child NFT that has been minted and taken out of the bag
    function openskLootBagAndRemoveItem(
        uint256 _tokenId,
        skBagComponent _componentToRemove,
        address _recipient
    ) external {
        require(msg.sender == ownerOf(_tokenId), "Not loot bag owner");

        require(
            !skLootBagTokenIdToComponentRemoved[_tokenId][_componentToRemove],
            "Component already removed"
        );

        sLandCoordinates storage land = skLootBagTokenInfo[_tokenId].land;
        bytes memory memberId = brandCentral.universe().subKNOTAtIndexCoordinates(land.x, land.y);
        uint256 _brandTokenId = brandCentral.knotToAssociatedBrandTokenId(memberId);

        if (_componentToRemove == skBagComponent.sLand) {
            sLandCoordinates storage coords = skLootBagTokenInfo[_tokenId].land;
            skLoot.mint(
                string(abi.encodePacked("(",coords.x.toString(), ", ", coords.y.toString(), ")")),
                HouseGoodie.ItemType.sLand,
                _brandTokenId,
                _recipient
            );
        } else if (_componentToRemove == skBagComponent.sBuilding) {
            skLoot.mint(
                skLootBagTokenInfo[_tokenId].building,
                HouseGoodie.ItemType.sBuilding,
                _brandTokenId,
                _recipient
            );
        } else {
            skLoot.mint(
                skLootBagTokenInfo[_tokenId].character,
                HouseGoodie.ItemType.sCharacter,
                _brandTokenId,
                _recipient
            );
        }

        skLootBagTokenIdToComponentRemoved[_tokenId][_componentToRemove] = true;

        emit skLootBagItemRemoved(_tokenId, _componentToRemove);
    }

    /// @notice Brand central method allowing anyone to claim skLoot item from the open pool when a new member is added to any StakeHouse
    /// @notice Item given is from a lucky dip list where special draws can be made from a rare gem list
    /// @param _stakeHouse StakeHouse where member was added
    /// @param _recipient that will hodl the skLoot item
    /// @param _brandTokenId Brand associated with the skLoot item
    function skLootItemClaim(
        address _stakeHouse,
        address _recipient,
        uint256 _brandTokenId
    ) external {
        require(msg.sender == address(brandCentral), "Only brand central");

        // Source of entropy
        uint256 numberOfKnotsInHouse = IStakeHouseRegistry(_stakeHouse).numberOfMemberKNOTs();
        uint256 numberOfHouseKnotInUniverse = brandCentral.universe().numberOfStakeHouses();
        uint256 totalKnotsInUniverse = numberOfKnotsInHouse + numberOfHouseKnotInUniverse;

        bool isSpecial = (_blockNumber() + totalKnotsInUniverse) % 50 == 0;

        // Generate a pseudo random number using above and blockchain entropy
        // in theory, miners dont manipulate basefee as that is burnt - EIP1559
        uint256 pseudoRandomNumber = uint256(keccak256(abi.encodePacked(
                block.difficulty,
                block.timestamp,
                block.basefee,
                numberOfKnotsInHouse,
                numberOfHouseKnotInUniverse,
                isSpecial,
                totalKnotsInUniverse
            )));

        // pluck an item depending on whether its special or knot :)
        string memory pickedItem;
        if (isSpecial) {
            string[6] memory _specialLuckyDipGems = specialLuckyDipGems();
            pickedItem = _specialLuckyDipGems[pseudoRandomNumber % _specialLuckyDipGems.length];
        } else {
            string[8] memory _luckyDipItems = luckyDipItems();
            pickedItem = _luckyDipItems[pseudoRandomNumber % _luckyDipItems.length];
        }

        // mint the token
        uint256 tokenId = skLoot.mint(pickedItem, HouseGoodie.ItemType.sItem, _brandTokenId, _recipient);

        emit skLootItemClaimedForKnot(tokenId);
    }

    /// @notice Fully on-chain JSON metadata and SVG for the StakeHouse KNOT loot bag (skLootBag)
    /// @param _tokenId ID of the skLootBag token
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Loot bag does not exist");

        skLootBag storage lootBag = skLootBagTokenInfo[_tokenId];

        string[8] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';

        string memory additionalLandTextStyle = skLootBagTokenIdToComponentRemoved[_tokenId][skBagComponent.sLand] ? ' text-decoration="line-through" ' : '';
        parts[1] = string(abi.encodePacked('<text x="10" y="20" class="base"', additionalLandTextStyle, '>'));

        parts[2] = string(abi.encodePacked("(",lootBag.land.x.toString(), ", ", lootBag.land.y.toString(), ")"));

        string memory additionalBuildingTextStyle = skLootBagTokenIdToComponentRemoved[_tokenId][skBagComponent.sBuilding] ? ' text-decoration="line-through" ' : '';
        parts[3] = string(abi.encodePacked('</text><text x="10" y="40" class="base"', additionalBuildingTextStyle, '>'));

        parts[4] = lootBag.building;

        string memory additionalCharTextStyle = skLootBagTokenIdToComponentRemoved[_tokenId][skBagComponent.sCharacter] ? ' text-decoration="line-through" ' : '';
        parts[5] = string(abi.encodePacked('</text><text x="10" y="60" class="base"', additionalCharTextStyle, '>'));

        parts[6] = lootBag.character;

        parts[7] = '</text></svg>';

        string memory imgSvg = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));

        string memory json = bytes(string(abi.encodePacked(
                '{"name": "skLootBag #', _tokenId.toString(),
                '", "description": "StakeHouse KNOT loot bag. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use it in any way you want.", "image": "data:image/svg+xml;base64,', bytes(imgSvg).encode(),
                '"}'
            ))).encode();

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _blockNumber() internal virtual view returns (uint256) {
        return block.number;
    }
}
