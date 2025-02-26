# Ethernaut challenges

This repository contains code and notes written while I go over Ethernaut challenges.

## Challenges

_Note: some of the challenges don't have a description of the resolution here, but the contract or notes should be available in `src`, `notes` or `script`._

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

### 28. Good samaritan

The main problem of the GoodSamaritan contract is relying on reciving a specific error (without any extra parameters) to empty its wallet. Since the coin being used optionally calls a contract on a specific method to notify of the transfer, an attacker can leverage that to revert with the specific error that the Samaritan is expecting.

Potential fix: check the actual balance before transfering the remainder. Or any other further check instead of blindly transfering all balance.

Code: [./src/SamaritanHack.sol](./src/SamaritanHack.sol)

### 29. Gatekeeper Three

There are three gates that we must pass to become "entrant" in this contract:

1. For the first gate, we just call the `construct0r()` method from a contract we create
2. For the second gate, we have to first create an instance of SimpleTrick, by calling `createTrick()` and then we can simply call `getAllowance()` and pass the right password. If we do both things in the same transaction, we can pass `block.timestamp` as the password and we'll enable `allowEntrance`. we can also create trick in one transaction, check its storage to get the right password, and then call getAllowance() with that password.
3. For the third gate, we can just transfer any amount higher than 0.001 ether to the Gatekeeper contract, and then make sure the `owner` contract can't receive any ETH.

Basically, we can create a contract that, upon construction calls performs all those calls and, in an additional call just call `enter()` to pass the three gates. We can also do everything in one function (as long as it's not the constructor).

Code: [./script/AttackGateThree.s.sol](./script/AttackGateThree.s.sol)

### 30. Switch

To call the method `turnSwitchOn()` in this contract, we need to go through `flipSwitch()`, which has the modifier `onlyOff()`. This modifier checks that the 4 bytes starting on position 68 of the calldata are the signature of `turnSwitchOff()`. However, hardcoding this position, specially when dealing with dynamic types (bytes memory), is not very reliable.

[This article](https://www.rareskills.io/post/abi-encoding) goes through how the different types are encoded in the calldata. For the "bytes" type, which is similar to the string, we can see that the first 32-byte word after the function signature determine the offset where the information of the data is. By default, this is "32", meaning that the information of the data starts 32 bytes after the function signature. The information contains:
    1. A 32-byte word representing the length of the data (in this case 4 bytes)
    2. The actual data

So, by default, if we want to call `turnSwitchOn()` we would call it like this:

```
0x
30c13ade                                                            => function signature (flipSwitch())
0000000000000000000000000000000000000000000000000000000000000020    => offset (32 bytes)
0000000000000000000000000000000000000000000000000000000000000004    => length of the data (4 bytes)
76227e12                                                            => data (turnSwitchOn())
```

Checking the 4 bytes starting on position 68 works for the standard case, so sending this calldata will make the call revert. But we can craft a calldata that has a different offset so we can include the data later than expected. For example, like this:

```
0x
30c13ade                                                            => function signature (flipSwitch())
0000000000000000000000000000000000000000000000000000000000000060    => offset (96 bytes)
0000000000000000000000000000000000000000000000000000000000000000    => empty calldata
20606e1500000000000000000000000000000000000000000000000000000000    => empty calldata (including the signature of turnSwitchOff() which is expected by onlyOff())
0000000000000000000000000000000000000000000000000000000000000004    => length of the data (4 bytes)
76227e1200000000000000000000000000000000000000000000000000000000    => data (turnSwitchOn())
```

### 31. Higher order

This challenge follows a similar approach than the last one, in which we can craft the calldata in any form we want. In this case, `registerTreasury()` expects to receive a uint8, and then uses `calldataload()` to load a 32-byte word starting from position 4 of the calldata. Since the contract uses an old solidity version, we can craft a calldata that includes a number higher than 255 (even if that means it doesn't fit a uint8) and call the contract with it:

```
0x
211c85ab                                                          => function signature (registerTreasury(uint8))
0000000000000000000000000000000000000000000000000000000000000100  => 256
```

With that, we can then call `claimLeadership()` to become the commander.

Note that if the contract were using a solidity version ^0.8.0, the call would revert if the calldata doesn't fit a uint8.

### 32. Stake

This contracts presents an issue when making low-level calls to an external ERC-20 contract and not checking that the call was actually successful. In `StakeWETH()`, the contract checks the amount returned in the call to `WETH.allowance()`. However, when calling `transferFrom()`, the "success" boolean (called "transfered" here) is not checked, so even if the transfer fails, the user is still added as a Staker, and the amount is still added to the stake.

Now, I don't fully understand why these requirements were chosen to beat the level, but we can perform the following operations to "drain" the contract:

1. With the main account, `approve()` the Stake contract to spend that account's WETH
2. With the main account, call `StakeWETH()` with some amount (0.0011ether), so it becomes a staker, and the `totalStaked` amount is increased
2. With a second account send ETH through `StakeETH()` to increase the contract's balance (since it must have some balance, make it greater than 0.0011ether)
5. With the main account, call `Unstake()` to obtain your balance back

### 33. Impersonator

