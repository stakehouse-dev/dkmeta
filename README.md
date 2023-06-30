# Community & Brand Central <> LSD + Stakehouse protocol

Brand central is the place to manage the way you present your house and LSD network to the outside world. Think of it like your shop front.

If you want to read about it from our past blogs, please take a look here: https://blog.blockswap.network/stakehouse-mainnet-the-importance-of-brand-central-2df2813b4a28 

## The creator of a Stakehouse or an LSD network becomes the manager of a brand NFT that is visible on OpenSea

https://opensea.io/collection/stakehousebrand

More information about smart contract deployments for community and brand central can be found here: https://github.com/stakehouse-dev/contract-deployments#community--brand-central-smart-contract-deployments 

By default, the NFT renders an on-chain SVG with the house ticker as follows:

![image](https://user-images.githubusercontent.com/102478146/250107401-819663ae-0f33-4d4f-b3f9-b7cbd7ab780a.png)


However, the NFT description and image can be updated on chain in the way that has been done by the sOpen house:

![image](https://user-images.githubusercontent.com/102478146/250107429-1feaa0b6-9b61-4633-9d24-b9640e23f067.png)


The description and image URL can be updated on the brand NFT contract. If you are an LSD network DAO owner, you will be able to execute the following function on the liquid staking manager contract of your network:

```solidity
function updateBrandInfo(
        uint256 _tokenId, string calldata _description, string calldata _imageURI
    ) external onlyDAO {
        IBrandNFT(brand).setBrandMetadata(_tokenId, _description, _imageURI);
    }
```

More information on how to fetch a liquid staking manager instance that from the wizard is here: [LSD wizard SDK - accessing liquid staking manager](https://docs.joinstakehouse.com/lsd/wizardcontract#getting-the-contract-instances)

You can use community central and your brand to get closer to your community with automated loot generation every time a validator joins your house or LSD network. To do this, as the owner of the brand NFT, you will need to configure your brand. Here’s an example for the DAO to execute on the liquid staking manager of an LSD network:

```solidity
function registerBuildingTypeToBrand(uint256 _tokenId, uint256 _buildingType) external onlyDAO {
        IBrandCentral(IBrandNFT(brand).brandCentral()).registerBuildingTypeToBrand(_tokenId, _buildingType);
    }
```


What environment represents your community? Choose from:

```solidity
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
```

Once your community is configured, your community can claim a loot item for every validator that joins your house or LSD network. The items received is pseudo-randomised and only 1 loot item can be openly claimed by anyone per validator. This is a separate NFT as follows:

https://opensea.io/collection/skgoodie

What possible items can your community members receive?

How to perform the claim? With the community central contract address you got from the [link](https://github.com/stakehouse-dev/contract-deployments#community--brand-central-smart-contract-deployments) at the start of the article, and the following ABI:
```
[
{
 "inputs": [
   {
     "internalType": "address",
     "name": "_stakeHouse",
     "type": "address"
   },
   {
     "internalType": "bytes",
     "name": "_blsPublicKey",
     "type": "bytes"
   }
 ],
 "name": "skOpenLootPoolClaim",
 "outputs": [],
 "stateMutability": "nonpayable",
 "type": "function"
}
]
```

You just supply the address of the house and the BLS public key and the claim will happen unless someone else has already claimed a loot item for a BLS public key!

## What next?
It's up to the community. dkmeta is just a tooling that allows NFTs to be minted based on registry rules i.e. when a house is created (auto) or when a new validator joins a house (manual claim). Possibilities include but are not limited to:
- Updating your brand NFT as the brand owner
- Claiming loot items
- Creating periphery contracts that can issue tokens for people staking loot or can convert them to other more valuable tokens
- etc.

We're only getting started
