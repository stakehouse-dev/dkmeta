pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { CommunityCentral } from "./CommunityCentral.sol";
import { BrandCentralClaimAuction } from "./BrandCentralClaimAuction.sol";
import { Base64 } from "../libraries/Base64.sol";

/// @notice The Brand NFT of a tokenised KNOT community
contract BrandNFT is ERC721Upgradeable {
    using Base64 for bytes;

    /// @notice Brand metadata i.e. description and image has been updated within the onchain JSON
    event TokenMetadataUpdated(uint256 indexed tokenId);

    struct Brand {
        string ticker; // all lowercase brand ticker / ERC721 metadata 'name' field
        bytes foundingKnot; // the KNOT that created the brand
    }

    /// @notice Brand Metadata fields which is used to generate ERC721 compliant metadata in the token URI function
    /// @dev ERC721 metadata has name, image, description for rendering on NFT explorers but here name is always the brand ticker
    struct BrandMetadata {
        // ERC721 metadata 'name' field - derived from the struct set on mint
        string description; // ERC721 metadata 'description' field - if empty, the token URI will just return the ticker
        string imageURI; //  ERC721 metadata 'image' field - if empty, the token URI will return a placeholder SVG
    }

    /// @notice contract manager
    CommunityCentral public brandCentral;

    /// @notice token ID -> Brand info
    mapping(uint256 => Brand) public tokenIdToBrand;

    /// @notice lowercase brand ticker -> minted token ID
    mapping(string => uint256) public lowercaseBrandTickerToTokenId;

    /// @notice KNOT ID -> token ID of brand that the knot 'founded'
    mapping(bytes => uint256) public foundingKnotToTokenId;

    /// @notice total brand NFTs minted
    uint256 public totalSupply;

    /// @notice Metadata associated with a brand token
    mapping(uint256 => BrandMetadata) public tokenIdToBrandMetadata;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(address _brandCentral) external initializer {
        require(_brandCentral != address(0), "Brand central is zero");
        brandCentral = CommunityCentral(_brandCentral);

        __ERC721_init("StakeHouseBrand", "SHNFT");
    }

    /// @notice Brand Central method that mints a brand NFT based on a 3-5 letter ticker supplied by a user
    /// @param _ticker that will be associated with the brand
    /// @param _memberId ID of the member KNOT that is founding the brand
    /// @param _recipient Address of the brand manager that will receive the brand NFT
    function mint(
        string calldata _ticker,
        bytes calldata _memberId,
        address _recipient
    ) external returns (uint256) {
        require(msg.sender == address(brandCentral), "Only brand central");
        require(
            bytes(_ticker).length >= 3 && bytes(_ticker).length <= 5,
            "Name must be between 3 and 5 characters"
        );

        string memory lowerCaseBrandTicker = toLowerCase(_ticker);
        require(lowercaseBrandTickerToTokenId[lowerCaseBrandTicker] == 0, "Brand name already exists");
        require(foundingKnotToTokenId[_memberId] == 0, "KNOT has already founded a brand");

    unchecked { // unlikely to exceed ( (2 ^ 256) - 1 )
        totalSupply += 1;
    }

        tokenIdToBrand[totalSupply] = Brand({
        ticker: _ticker,
        foundingKnot: _memberId
        });

        lowercaseBrandTickerToTokenId[lowerCaseBrandTicker] = totalSupply;
        foundingKnotToTokenId[_memberId] = totalSupply;

        _mint(_recipient, totalSupply);

        return totalSupply;
    }

    /// @notice Brand token owner can set the metadata. This means they can link any information about their brand
    /// @notice This is similar to traditional businesses. They may start off with one logo, re-brand + change it etc.
    function setBrandMetadata(uint256 _tokenId, string calldata _description, string calldata _imageURI) external {
        require(ownerOf(_tokenId) == msg.sender, "Only owner");
        tokenIdToBrandMetadata[_tokenId].description = _description;
        tokenIdToBrandMetadata[_tokenId].imageURI = _imageURI;
        emit TokenMetadataUpdated(_tokenId);
    }

    /// @notice get the token URI of a brand set by a brand owner
    /// @param _tokenId of the brand
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Brand does not exist");

        BrandMetadata memory metadata = tokenIdToBrandMetadata[_tokenId];
        string memory ticker = tokenIdToBrand[_tokenId].ticker;

        string memory description = metadata.description;
        if (bytes(description).length == 0) {
            description = ticker;
        }

        string memory image = metadata.imageURI;
        if (bytes(image).length == 0) {
            string[3] memory parts;
            parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

            parts[1] = ticker;

            parts[2] = '</text></svg>';

            string memory placeHolderSvgImg = string(abi.encodePacked(parts[0], parts[1], parts[2]));
            image = string(abi.encodePacked("data:image/svg+xml;base64,", bytes(placeHolderSvgImg).encode()));
        }

        string memory json = bytes(string(abi.encodePacked(
                '{"name": "', ticker, '", "description": "', description, '", "image": "', image, '"}'
            ))).encode();

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    /// @notice Check if a token by token ID has been minted
    /// @param _tokenId of the brand
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /// @notice Converts a string to its lowercase equivalent
    /// @dev Only 26 chars from the English alphabet
    /// @param _base String to convert
    /// @return string Lowercase version of string supplied
    function toLowerCase(string memory _base) public pure returns (string memory) {
        bytes memory bStr = bytes(_base);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i; i < bStr.length; ++i) {
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                require(bStr[i] >= 0x61 && bStr[i] <= 0x7A, "Name can only contain the 26 letters of the roman alphabet");
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}
