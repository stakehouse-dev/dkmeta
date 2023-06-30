# Community & Brand Central <> LSD + Stakehouse protocol

Brand central is the place to manage the way you present your house and LSD network to the outside world. Think of it like your shop front.

If you want to read about it from our past blogs, please take a look here: https://blog.blockswap.network/stakehouse-mainnet-the-importance-of-brand-central-2df2813b4a28 

## The creator of a Stakehouse or an LSD network becomes the manager of a brand NFT that is visible on OpenSea

https://opensea.io/collection/stakehousebrand

More information about smart contract deployments for community and brand central can be found here: https://github.com/stakehouse-dev/contract-deployments#community--brand-central-smart-contract-deployments 

By default, the NFT renders an on-chain SVG with the house ticker as follows:

![image](https://private-user-images.githubusercontent.com/15893673/249287233-b6aa52d9-a586-4560-aa55-5042b5cb4aa4.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJrZXkxIiwiZXhwIjoxNjg4MTExNjU5LCJuYmYiOjE2ODgxMTEzNTksInBhdGgiOiIvMTU4OTM2NzMvMjQ5Mjg3MjMzLWI2YWE1MmQ5LWE1ODYtNDU2MC1hYTU1LTUwNDJiNWNiNGFhNC5wbmc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBSVdOSllBWDRDU1ZFSDUzQSUyRjIwMjMwNjMwJTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDIzMDYzMFQwNzQ5MTlaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT00Y2ViNDRhMWRiYmZiZGQ4NGE1YTM5NTRjNDMzNDJjMDZjMjVkMmVmYzAwOGM1YmIwOWEwYTkxZTVjMmEwZGI1JlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCZhY3Rvcl9pZD0wJmtleV9pZD0wJnJlcG9faWQ9MCJ9.5YQoQygJ93WTnTHxVtbtyoc8-dg2-jKtq14XYw5JYtk)


However, the NFT description and image can be updated on chain in the way that has been done by the sOpen house:

![image](https://private-user-images.githubusercontent.com/15893673/249287349-8c76a173-aee7-44b0-b97b-3d95fffc661c.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJrZXkxIiwiZXhwIjoxNjg4MTExNjU5LCJuYmYiOjE2ODgxMTEzNTksInBhdGgiOiIvMTU4OTM2NzMvMjQ5Mjg3MzQ5LThjNzZhMTczLWFlZTctNDRiMC1iOTdiLTNkOTVmZmZjNjYxYy5wbmc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBSVdOSllBWDRDU1ZFSDUzQSUyRjIwMjMwNjMwJTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDIzMDYzMFQwNzQ5MTlaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT0wYTg3Njg3MWQyYzFkYWExY2FhNTczNWRkZjMyOWM3OTlmMTc1ZGM5MDIxNWViNTdkNWRlNGYxYWUyNjkzNGNiJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCZhY3Rvcl9pZD0wJmtleV9pZD0wJnJlcG9faWQ9MCJ9.X9sg6Sr4GhXEHF5OHUTeYlTU9y27yaGnPxL3kF9cc10)


The description and image URL can be updated on the brand NFT contract. If you are an LSD network DAO owner, you will be able to execute the following function on the liquid staking manager contract of your network:

![image](https://github.com/stakehouse-dev/dkmeta/assets/102478146/3bfa64be-f317-4df3-be96-4080fd072a57)

More information on how to fetch a liquid staking manager instance that from the wizard is here: [LSD wizard SDK - accessing liquid staking manager](https://docs.joinstakehouse.com/lsd/wizardcontract#getting-the-contract-instances)

You can use community central and your brand to get closer to your community with automated loot generation every time a validator joins your house or LSD network. To do this, as the owner of the brand NFT, you will need to configure your brand. Here’s an example for the DAO to execute on the liquid staking manager of an LSD network:

![image](https://github.com/stakehouse-dev/dkmeta/assets/102478146/12f65f60-3a83-4701-9dab-0baf5af434b5)


What environment represents your community? Choose from:

![image](https://github.com/stakehouse-dev/dkmeta/assets/102478146/36db20dc-c81f-4495-b17c-cda735765817)

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
