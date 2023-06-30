pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "../libraries/Base64.sol";
import { HouseGoodieBagFactory } from "./HouseGoodieBagFactory.sol";

/// @title StakeHouse Loot items that come from the community pools or minted from goodie bags
contract HouseGoodie is ERC721Upgradeable {
    using Base64 for bytes;
    using Strings for uint256;

    /// @notice Only minter allowed to mint skLoot items
    HouseGoodieBagFactory public lootFactory;

    // Used to assign a type to differentiate all of the skLoot items
    enum ItemType {
        sLand,
        sBuilding,
        sCharacter,
        sItem
    }

    // StakeHouse KNOT Loot Item definition. Consists of 3 things
    struct Item {
        string itemName; // Name of the minted item
        ItemType itemType; // Item type from the enum
        uint256 originalBrandTokenId; // Associated brand token ID - permanent once minted
    }

    /// @notice Token ID to Item definition
    mapping(uint256 => Item) public tokenIdToItem;

    /// @notice Total supply of skLoot items
    uint256 public totalSupply;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(HouseGoodieBagFactory _lootFactory) external initializer {
        require(address(_lootFactory) != address(0), "Loot factory is zero");
        lootFactory = _lootFactory;

        __ERC721_init("skGoodie", "skGoodie");
    }

    /// @notice Loot factory method for minting skLoot items that are associated with a brand and a KNOT
    /// @param _itemName String value of the item
    /// @param _type Item Type selected from an enum
    /// @param _brandTokenId ID of the brand associated with the loot item
    /// @param _recipient Address of the skLoot hodler
    function mint(string calldata _itemName, ItemType _type, uint256 _brandTokenId, address _recipient) external returns (uint256) {
        require(msg.sender == address(lootFactory), "Only loot factory");

        // Bump the supply and derive the new token ID
    unchecked { // number of open loot items unlikely to exceed ( (2 ^ 256) - 1 )
        totalSupply += 1;
    }

        // Store the item definition
        tokenIdToItem[totalSupply] = Item({
        itemName: _itemName,
        itemType: _type,
        originalBrandTokenId: _brandTokenId
        });

        // mint the token
        _mint(_recipient, totalSupply);

        return totalSupply;
    }

    /// @notice Gets all item information from the token ID
    function getItem(uint256 _tokenId) external view returns (Item memory) {
        require(_exists(_tokenId), "Loot item does not exist");
        return tokenIdToItem[_tokenId];
    }

    /// @notice Fully on-chain JSON metadata and SVG for the StakeHouse KNOT loot item (skLoot)
    /// @param _tokenId ID of the skLoot token
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Loot item does not exist");

        Item storage item = tokenIdToItem[_tokenId];

        string[7] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = item.itemName;

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = _itemTypeNameFromEnum(item.itemType);

        parts[4] = '</text><text x="10" y="60" class="base">';

        (string memory brandTickerDisplayVersion,) = lootFactory.brandCentral().brandNFT().tokenIdToBrand(item.originalBrandTokenId);
        parts[5] = brandTickerDisplayVersion;

        parts[6] = '</text></svg>';

        string memory imgSvg = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));

        string memory json = bytes(string(abi.encodePacked(
                '{"name": "skLoot #', _tokenId.toString(), '", "description": "StakeHouse KNOT loot item. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use it in any way you want.", "image": "data:image/svg+xml;base64,', bytes(imgSvg).encode(), '"}'
            ))).encode();

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    /// @dev internal helper function for converting the ItemType enum to a string
    function _itemTypeNameFromEnum(ItemType _type) private pure returns (string memory) {
        if (_type == ItemType.sLand) {
            return "sLand";
        } else if (_type == ItemType.sBuilding) {
            return "sBuilding";
        } else if (_type == ItemType.sCharacter) {
            return "sCharacter";
        }

        return "sItem";
    }
}
