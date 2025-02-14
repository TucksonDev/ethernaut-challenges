# Ethernaut challenges

This repository contains code and notes written while I go over Ethernaut challenges

## Challenges

### 1. Hello Ethernaut

Just call the different functions starting on the first `info()` function, and end up with `authenticate()` and the password obtained.

### 2. Fallback

The `receive()` method only requires receiving any value, and having already contributed to the contract. So if we `contribute()` first with any amount below 0.001 ether, and then send any value to the contract, we will become the new owner. We can then `withdraw()` all funds.

```shell
$ cast send -r $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY $CONTRACT "contribute()()" --value 1
$ cast send -r $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY $CONTRACT --value 1
$ cast send -r $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY $CONTRACT "withdraw()()"
```

### 3. Fallout

Coin Flip

Telephone

Token

Delegation

Force

Vault

King

Re-entrancy

Elevator

Privacy

Gatekeeper One

Gatekeeper Two

Naught Coin

Preservation

Recovery

MagicNumber

Alien Codex

Denial

### 22. Shop

The key here is that `_buyer.price()` is called twice in the `Shop.buy()` contract, one for check, and another one for setting the new price. We can modify that function in our `Buyer` contract to set any price we want by calling back the `Shop` contract to see at what point of execution we are (checking the `isSold` variable).

Potential fix: only make one `_buyer.price()` call, save that to a variable in memory and use it for both check and set actions.

Code: [./src/ShopHack.sol](./src/ShopHack.sol)

### 23. Dex

This hack leverages the fact that price calculation does not protect from unexpected rounding. By always swapping the max amount of one token, the amount received on the other token will be greater. We can do that until we empty the pool from one of the tokens.

Potential fix: rely on another source for obtaining the price of the tokens. Something more reliable that does not depend on potential rounding errors.

Code: [./script-ts/dex-hack.js](./script-ts/dex-hack.js)

### 24. Dex Two

Following on the previous challenge, this DEX doesn't check that the swapping tokens are the ones that the Dex contract is operating with. Thus, you can manipulate the amount that is being swapped by either token, by creating an additional token and play with the supply of the Dex contract.

Potential fix: verify that the contract only operates with its tokens.

Code: [./src/Dex2TokenHack.sol](./src/Dex2TokenHack.sol)

### 25. Puzzle Wallet

The main issue with this contract is that the Proxy contract is not using specific storage slots for their state variables. `pendingAdmin` and `admin` are using storage slots 0 and 1 respectively, which clash with the state variables `owner` and `maxBalance` of the implementation contract.

You can follow this process to escalate priviledges:

1. `proposeNewAdmin()`: that would change both the `pendingAdmin` and `owner`
2. `addToWhitelist()`: to get whitelisted in the `PuzzleWallet` contract
3. `multicall()`: we send 0.001 ETH (the current balance of the contract) and 2 calls:
    1. `deposit()`, to deposit those funds
    2. `multicall()`, with another `deposit()` call to bypass the "depositCalled" filter
4. `execute()` to empty the contract balance
5. `setMaxBalance()`, passing the uint256 representation of the address. This will also change the `admin` storage slot of the Proxy contract.

### 26. Motorbike

_NOTE: Since the Dencun upgrade, this level can't be completed by the usual means._

In this case, we have a proxy contract, and an implementation contract elsewhere. Since it's using the UUPS proxy, the implementation contract has the functions related to changing the implementation logic of this contract. In this case, we could render the code sitting at the implementation contract address useless, by calling `initialize()` directly in the implementation contract, and then upgrading to a different contract that selfdestructs the code in this contract.

Potential fix: do not allow calling `initialize()` directly in the implementation contract.

Code: [./src/EngineHack.sol](./src/EngineHack.sol)

### 27. DoubleEntryPoint

This Vault sets an underlying token $DET that has a double entry point. $DET can be transfered by calling the $DET contract directly, or by calling the delegated token and using `delegateTransfer()`.

Thus, when calling `Vault.sweepToken($LGT)`, in reality we are transfering out $DET from the Vault. To solve it, we write a Forta bot that will revert the `delegateTransfer()` call when we try to transfer $DET tokens from the Vault.

Code: [./src/DetectionBot.sol](./src/DetectionBot.sol)

