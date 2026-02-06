> **IMPORTANT:** *This repo is a work in progress, and contracts have not been audited.*

# RWAs

> Purpose of this project: To understand the tecnical side of tokenizing a commodity such as gold.

# Table of Contents

- [RWAs](#rwas)
- [Table of Contents](#table-of-contents)
- [Tokenized Commodity](#tokenized-commodity)
  - [dXAU.sol](#dxausol)
    - [V1](#v1)
    - [V2 (not implemented)](#v2-not-implemented)
  - [sXAU.sol](#sxausol)
  - [BridgedWETH.sol](#bridgedwethsol)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Installation](#installation)
- [Disclaimer](#disclaimer)


# Tokenized Commodity

In this repo, we will go over how to tokenize a real world asset. 

1. Cross-Chain WETH with On-Chain collateral, Directly Backed: `AOnCOnDB` - `CrossChainWETH.sol` 
2. Gold with Off-Chain collateral, Directly Backed: `AOffCOffDB` - `dXAU.sol` ✅ 
3. Gold with On-Chain collateral, Synthetic: `AOffCOnSB` - `sXAU.sol` ✅ 



## dXAU.sol

### V1
1. Only the owner can mint `dXAU`
2. Anyone can redeem `dXAU` for `USDC` or "the stablecoin" of choice.
  - Chainlink functions will kick off a `XAU` sell for USDC, and then send it to the contract
3. The user will have to then call `finishRedeem` to get their `USDC`.

### V2 (not implemented)
1. Users can send USDC -> `dXAU.sol` via `sendMintRequest` via Chainlink Functions. This will kick off the following:
  - USDC will be sent to HSBC
  - USDC will be sold for USD 
  - USD will be used to buy Gold
  - The Chainlink Functions will then callback to `_mintFulFillRequest`, to enable `dXAU` tokens to the user.
2. The user can then call `finishMint` to withdraw their minted `dXAU` tokens. 

## sXAU.sol

This is essentially a synthetic Gold token, it's follows a similar architecture to a stablecoin, where we use a Chainlink price feed to govern the price of the token.

Refer to [Cyfrin Updraft](https://updraft.cyfrin.io/). 

## BridgedWETH.sol

So, token transfers are baked into the CCIP protocol, but you have to work with the DONs to get these setup. We will show you how to create your own token pools with CCIP and not bother working with the DONs, since CCIP allows you to send arbitrary data to the other chain.

1. WETH contract on "home" chain 
2. BridgedWETH contract on all other chains 
3. Chainlink CCIP Sender & Receiver Contract 
  - Lock the WETH 
  - Emit the message to unlock on the other chain 
  - Mint the WETH 
  - Will need to burn the WETH and send it back 

# Getting Started 

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`
- [node](https://nodejs.org/en/download/)
  - You'll know you did it right if you can run `node --version` and you see a response like `v16.13.0`  
- [npm](https://www.npmjs.com/get-npm)
  - You'll know you did it right if you can run `npm --version` and you see a response like `8.1.0`
- [deno](https://docs.deno.com/runtime/manual/getting_started/installation)
  - You'll know you did it right if you can run `deno --version` and you see a response like `deno 1.40.5 (release, x86_64-apple-darwin) v8 12.1.285.27 typescript 5.3.3`

## Installation

1. Clone the repo, navigate to the directory, and install dependencies with `make`
```
git clone https://github.com/PatrickAlphaC/rwa-creator
cd rwa-creator
make
```

# Disclaimer 

None of the code has been audited or undergone a security review.