---
tip: 6
title: TRC-6 Fungible Tokens Standard
author: Anton Platonov <anton@platonov.us>, Dmitriy Yankin <d.s.yankin@gmail.com>
type: TRC
status: Draft
created: 2021-06-08
---

# Simple Summary

A standard interface for simple yet versatile fungible tokens.


# Abstract

The following standard allows for the implementation of a standard API for fungible tokens within smart contracts.

This standard provides basic functionality to create wallets, transfer and manage tokens and send/receive events.


# Motivation

A standard interface allows any tokens on Free TON blockchain to be re-used by other applications: from marketplaces to decentralized exchanges.

The motivation behind creation of new fungible token besides TIP-3 is that TIP-3 original standard:
 * doesn't respect asynchronous nature of Free TON blockchain (no callbacks or callback getters);
 * is too broad (covers 4 types of tokens instead of one); 
 * is complicated (including ownership by both public key and address);
 * allows sending tokens using wallet address directly (see `internalTransferFrom`), terget contract can be a malicious contract which implements `internalTransfer` function which will end up in loosing Tokens;
 * requires user to worry about wallet's balance (having multiple wallets without automation system that manages balances is a great place for human errors);
 
thus different teams are forced to create numerous TIP-3 forks that are incompatible with each other.


# Specification

## Notification Receiver
### Methods

**NOTES**:
 - The following specifications use syntax from TON Solidity `0.44.0` (or above)

#### receiveNotification

Interface to implement a contract to receive notification from a Wallet on successfull operation:

`amount` - Amount of tokens received;

`senderOwnerAddress` - Sender Wallet owner address to calculate Wallet address (may be zero when Root performs mint operation);

`initiatorAddress` - Transaction initiator (e.g. Multisig) to return the unspent change;

`body` - Custom body (business-logic specific, may be empty);

``` js
interface iFTNotify
{
    function receiveNotification(uint128 amount, address senderOwnerAddress, address initiatorAddress, TvmCell body) external;
}
```


## Wallet
### Methods

**NOTES**:
 - The following specifications use syntax from TON Solidity `0.44.0` (or above)

#### getWalletCode
#### callWalletCode

Returns the Wallet contract code;

``` js
function  getWalletCode() external view             returns (TvmCell);
function callWalletCode() external view responsible returns (TvmCell);
```


#### getOwnerAddress
#### callOwnerAddress

Returns the Wallet Owner address;

``` js
function  getOwnerAddress() external view             returns (address);
function callOwnerAddress() external view responsible returns (address);
```


#### getRootAddress
#### callRootAddress

Returns the Wallet Root address;

``` js
function  getRootAddress() external view             returns (address);
function callRootAddress() external view responsible returns (address);
```


#### getBalance
#### callBalance

Returns the Wallet balance;

``` js
function  getBalance() external view             returns (uint128);
function callBalance() external view responsible returns (uint128);
```


#### getNotifyOnReceiveAddress
#### callNotifyOnReceiveAddress

Returns the Wallet balance;

``` js
function  getNotifyOnReceiveAddress() external view             returns (address);
function callNotifyOnReceiveAddress() external view responsible returns (address);
```


#### burn

Sends burn command to Root;

ACCESS: only Wallet owner;

`amount` - Amount of tokens to burn;

``` js
function burn(uint128 amount) external;
```


#### transfer

Sends Tokens to another Wallet;

ACCESS: only Wallet owner;

RESTRICTIONS: sender wallet MUST create target wallet if it doesn't exist.

`amount` - Amount of tokens to send;

`targetOwnerAddress` - Receiver Wallet owner address to calculate Wallet address;

`initiatorAddress` - Transaction initiator (e.g. Multisig) to return the unspent change;

`notifyAddress` - `iFTNotify` contract address to receive a notification about minting (may be zero);

`body` - Custom body (business-logic specific, may be empty);

``` js
function transfer(uint128 amount, address targetOwnerAddress, address initiatorAddress, address notifyAddress, TvmCell body) external;
```


#### receiveTransfer

Receives Tokens from another Wallet or Root (minting);

`amount` - Amount of tokens to receive;

`senderOwnerAddress` - Sender Wallet owner address to calculate Wallet address (may be zero when Root performs mint operation);

`initiatorAddress` - Transaction initiator (e.g. Multisig) to return the unspent change;

`notifyAddress` - `iFTNotify` contract address to receive a notification about minting (may be zero);

`body` - Custom body (business-logic specific, may be empty);

``` js
function receiveTransfer(uint128 amount, address senderOwnerAddress, address initiatorAddress, address notifyAddress, TvmCell body) external;
```

#### changeNotifyOnReceiveAddress

hanges contract address to receive a notification when `receiveTransfer` is performed;

ACCESS: only Wallet owner;

`newNotifyOnReceiveAddress` - `iFTNotify` contract address to receive a notification (when zero no one is notified);

``` js
function changeNotifyOnReceiveAddress(address newNotifyOnReceiveAddress) external;
```

### Events

#### tokensBurned

Event on Token burn;

`amount` - Amount of tokens burned;

``` js
event tokensBurned(uint128 amount);
```


#### tokensSent

Event on Token sent;

`amount` - Amount of tokens sent;

`targetOwnerAddress` - Receiver Wallet owner address;

`body` - Custom body (business-logic specific, may be empty);

``` js
event tokensSent(uint128 amount, address targetOwnerAddress, TvmCell body);
```


#### tokensReceived

Event on Token received;

`amount` - Amount of tokens received;

`senderOwnerAddress` - Sender Wallet owner address;

`body` - Custom body (business-logic specific, may be empty);

``` js
event tokensReceived(uint128 amount, address senderOwnerAddress, TvmCell body);
```


## Root
### Methods

**NOTES**:
 - The following specifications use syntax from TON Solidity `0.44.0` (or above)


#### getWalletCode
#### callWalletCode

Returns the Wallet contract code;

``` js
function  getWalletCode() external view             returns (TvmCell);
function callWalletCode() external view responsible returns (TvmCell);
```


#### getOwnerAddress
#### callOwnerAddress

Returns the Wallet Owner address;

``` js
function  getOwnerAddress() external view             returns (address);
function callOwnerAddress() external view responsible returns (address);
```


#### getRootInfo
#### callRootInfo

Returns the Root information + binary icon (icon is an array of chunks, concatenate the chunks to get the media).

Icon is a utf8-string with encoded PNG image (RFC 2397). The string format is `"data:image/png;base64,<image>"`, where image - image bytes encoded in base64. Example: `"data:image/png;base64,iVBORw0KG...5CYII="`;

``` js
function  getRootInfo() external view             returns (bytes name, bytes symbol, uint8 decimals, uint128 totalSupply, bytes[] icon);
function callRootInfo() external view responsible returns (bytes name, bytes symbol, uint8 decimals, uint128 totalSupply, bytes[] icon);
```


#### getWalletAddress
#### callWalletAddress

Returns the Wallet address for a specific owner;

``` js
function  getWalletAddress(address ownerAddress) external view             returns (address);
function callWalletAddress(address ownerAddress) external view responsible returns (address);
```


#### burn

Receives burn command from Wallet;

`amount` - Amount of tokens to burn;

`senderOwnerAddress` - Sender Wallet owner address to calculate and verify Wallet address;

`initiatorAddress` - Transaction initiator (e.g. Multisig) to return the unspent change;

``` js
function burn(uint128 amount, address senderOwnerAddress, address initiatorAddress) external;
```


#### mint

Mints tokens from Root to a target Wallet;

ACCESS: only root owner;

RESTRICTIONS: root MUST create target wallet if it doesn't exist.

`amount` - Amount of tokens to mint;

`targetOwnerAddress` - Receiver Wallet owner address to calculate Wallet address;

`notifyAddress` - `iFTNotify` contract address to receive a notification about minting (may be zero);

`body` - Custom body (business-logic specific, may be empty);

``` js
function mint(uint128 amount, address targetOwnerAddress, address notifyAddress, TvmCell body) external;
```


#### createWallet
#### callCreateWallet

Creates a new Wallet with `tokensAmount` Tokens; `tokensAmount > 0` is available only for root;

Returns Wallet address;

`ownerAddress` - Receiver Wallet owner address to calculate Wallet address;
`tokensAmount` - When called by Root Owner, you can mint Tokens when creating a wallet;
`notifyOnReceiveAddress` - `iFTNotify` contract address to receive a notification when Wallet receives a transfer;

``` js
function createWallet(address ownerAddress, address notifyOnReceiveAddress, uint128 tokensAmount) external returns (address);
function callCreateWallet(address ownerAddress, address notifyOnReceiveAddress, uint128 tokensAmount) external responsible returns (address);
```


### Events

#### tokensMinted

Event on Token burn;

`amount` - Amount of tokens minted;

`senderOwnerAddress` - Wallet owner address (mint receiver);

`body` - Custom body (business-logic specific, may be empty);

``` js
event tokensMinted(uint128 amount, address targetOwnerAddress, TvmCell body);
```


#### walletCreated

Event on Wallet creation;

`ownerAddress` - Wallet owner;

`walletAddress` - Wallet address;

``` js
event walletCreated(address ownerAddress, address walletAddress);
```


#### tokensBurned

Event on Token burn;

`amount` - Amount of tokens burned;

`senderOwnerAddress` - Wallet owner address (burn initiator);

``` js
event tokensBurned(uint128 amount, address senderOwnerAddress);
```


# Implementation

Interface is in `interfaces` folder.

`Liquid contracts` Root and Wallet implementation in `contracts` folder.


# History

TODO



# Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).