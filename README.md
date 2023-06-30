# Community & Brand Central <> LSD + Stakehouse protocol

Brand central is the place to manage the way you present your house and LSD network to the outside world. Think of it like your shop front.

If you want to read about it from our past blogs, please take a look here: https://blog.blockswap.network/stakehouse-mainnet-the-importance-of-brand-central-2df2813b4a28 

## The creator of a Stakehouse or an LSD network becomes the manager of a brand NFT that is visible on OpenSea

https://opensea.io/collection/stakehousebrand

More information about smart contract deployments for community and brand central can be found here: https://github.com/stakehouse-dev/contract-deployments#community--brand-central-smart-contract-deployments 

By default, the NFT renders an on-chain SVG with the house ticker as follows:

![image](https://github.com/bsn-eng/dkmeta/assets/15893673/b6aa52d9-a586-4560-aa55-5042b5cb4aa4)


However, the NFT description and image can be updated on chain in the way that has been done by the sOpen house:

![image](https://github.com/bsn-eng/dkmeta/assets/15893673/8c76a173-aee7-44b0-b97b-3d95fffc661c)


The description and image URL can be updated on the brand NFT contract. If you are an LSD network DAO owner, you will be able to execute the following function on the liquid staking manager contract of your network:

![image](https://github.com/bsn-eng/dkmeta/assets/15893673/89649c0e-5354-43d7-b0ce-ff0927539eef)


More information on how to fetch a liquid staking manager instance that from the wizard is here: [LSD wizard SDK - accessing liquid staking manager](https://docs.joinstakehouse.com/lsd/wizardcontract#getting-the-contract-instances)

You can use community central and your brand to get closer to your community with automated loot generation every time a validator joins your house or LSD network. To do this, you will need to configure your brand. Here’s an example from the liquid staking manager of an LSD network:

![image](https://github.com/bsn-eng/dkmeta/assets/15893673/90109b0f-3274-4bd4-afd1-27749276fd4a)


What environment represents your community? Choose from:

![image](https://github.com/bsn-eng/dkmeta/assets/15893673/030ce568-bd3a-4cf3-82c9-3b0dc2a82b68)

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
