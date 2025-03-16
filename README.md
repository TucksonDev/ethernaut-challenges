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

### 16. Naught Coin

This contract forces a lockup period before allowing transfering tokens, but it's only applying that lock to the `transfer()` function, while the ERC-20 standard contains another means for transferring tokens through `transferFrom()`. So we just need to leverage that method to do it. We first allow another address to move our tokens, and then call `transferFrom()` from that account. You can even use the player's account as the "other" account:

```shell
$ cast send -r $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY $CONTRACT "approve(address,uint256)()" $SEPOLIA_ADDRESS 1000000000000000000000000
$ cast send -r $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY $CONTRACT "transferFrom(address,address,uint256)" $SEPOLIA_ADDRESS $CONTRACT 1000000000000000000000000
```

### 17. Preservation

This contract is storing addresses in the first 2 slots of its storage, and then delegate-calling a function `setTime(uint256)` on those addresses that modifies the first storage slot. If we want to change the contents of the third storage slot (`owner`), we can craft a contract that has a function `setTime(uint256)` and modifies that slot (since the Presentation contract is delegate-calling it).

Hack steps:

1. Deploy `PreservationHack`
2. Convert its address to uint256: `cast to-dec 0xAddress`
3. Call `setFirstTime(uint256)` with the address of the hacking contract: `$ cast send -r $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY $CONTRACT "setFirstTime(uint256)()" DecNumberOfAddress`
4. Call `setFirstTime(uint256)` again, so it triggers the function in the hacking contract and modifies the owner: `$ cast send -r $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY $CONTRACT "setFirstTime(uint256)()" 1`

Potential fix: make `LibraryContract` a library instead of a contract.

Code: [./src/PreservationHack.sol](./src/PreservationHack.sol)

### 18. Recovery

_NOTE: Since the Dencun upgrade, this level can't be completed by the usual means._

We need to recover funds from a SimpleToken contract that was created by the Recovery contract. Since we know the address of the Recovery contract, we can calculate the address of the contracts deployed by it.

The `CREATE` opcode calculates the contract address to be created using the following formula: `keccak256(rlp(<sender_address>, <nonce>))`. The description of the challenge tells us that the SimpleToken we want to recover the funds from was the first one created, so we can calculate the address of it with the following cast command:

```shell
$ cast keccak $(cast to-rlp '["0xAddressOfRecovery, "0x01"]') | tail -c 41
```

Once we know the address, we can call the `destroy()` method, which will selfdestruct the contract and send the funds to the address we want.

```shell
$ cast send -r $SEPOLIA_RPC --privat
e-key $SEPOLIA_PRIVATE_KEY 0xAddressOfSimpleToken "destroy(address)()" $SEPOLIA_ADDRESS
```


### 19. MagicNumber

To solve this challenge we need to deploy a contract that returns the uint256 "42" when calling it, but the contract must consist of only 10 bytes. To do that, we'll have to craft the bytecode by hand and deploy it.

Bytecode deployed on-chain consists of 2 parts: a runtime bytecode which is what's ultimately stored on-chain and contains the logic of the contract, and an initialization bytecode which copies the runtime bytecode to the chain and performs any initialization logic.

#### Runtime bytecode

We want our contract to return the uint256 number "42". To do that, we need to store that value in memory (`MSTORE`), and return it (`RETURN`).

```
# MSTORE(position, value) -- Store "value" in position "position" in memory)
PUSH1 0x2a  (value = 42)
PUSH1 0x00  (position = 0)
MSTORE
# Bytecode => 602a600052

# RETURN(position, size) -- Return position "position" from memory, of size "size"
PUSH1 0x20  (size = 32 bytes)
PUSH1 0x00  (position = 0)
RETURN
# Bytecode => 60206000f3

# Final runtime bytecode => 0x602a60005260206000f3
```

#### Initialization bytecode

Once we have the runtime bytecode, we can craft the initialization bytecode. We first call `CODECOPY` to copy the runtime bytecode into memory, and then return it (`RETURN`).

```
# CODECOPY(position, offset, size) -- Copy the code at offset "offset" in this line, with size "size", to memory position "position"
PUSH1 0x0a  (size = 10 bytes, runtime bytecode has size 10)
PUSH1 0x0c  (offset = 12, in the final code to deploy, runtime bytecode starts at byte 12)
PUSH1 0x00  (position = 0)
CODECOPY
# Bytecode => 600a600c600039

# RETURN(position, size) -- Return position "position" from memory, of size "size"
PUSH1 0x0a  (size = 10 bytes)
PUSH1 0x00  (position = 0)
RETURN
# Bytecode => 600a6000f3

# Final initialization bytecode => 0x600a600c600039600a6000f3
```

#### Final bytecode

We now concatenate both the initialization bytecode and the runtime bytecode to obtain the final bytecode that we need to deploy on-chain.

```
0x600a600c600039600a6000f3602a60005260206000f3
```

We can deploy this bytecode using `cast`:

```shell
$ cast send -r $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY --create 0x600a600c600039600a6000f3602a60005260206000f3
```

### 20. Alien Codex

This contract has a bytes32 dynamic array that can have its length manipulated by a specific function, `retract()`.

Dynamic arrays have their length stored in the specified storage slot. Then, each value of the dynamic array is stored from the slot keccak256(slotNumber). So, if the dynamic array length is in the storage slot 1, its values would be stored from slot keccak256(1). The first element will be stored in keccak256(1), the second element in keccak256(1)+1, and the nth element in keccak256(1)+n.

Since we can tweak the dynamic array length and cause an underflow, we can actually set the length of the array to max(uint256). When doing so, and using the function that allows us to modify any of the elements in the array, we can actually access any storage slot in the contract.

The contract owner is stored in slot 0. Since we can modify any storage slot using this dynamic array, we can calculate what index we should use to touch slot 0:

1. We calculate uint256(keccak256(1))
```shell
$ cast to-dec $(cast keccak 0x0000000000000000000000000000000000000000000000000000000000000001)
80084422859880547211683076133703299733277748156566366325829078699459944778998
```
2. We subtract max(uint256) - uint256(keccak256(1)). This will give us the index to use to modify the last storage slot of the contract.
```shell
115792089237316195423570985008687907853269984665640564039457584007913129639935 - 80084422859880547211683076133703299733277748156566366325829078699459944778998

35707666377435648211887908874984608119992236509074197713628505308453184860937
```
3. We add 1 to that amount, and we get the index we need to use to modify storage slot 0.
```shell
$ cast send -r $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY 0x090014E1F39A52da81616BC554182f71BD64Bcf5 "revise(uint256,bytes32)()" 35707666377435648211887908874984608119992236509074197713628505308453184860938 0x000000000000000000000000193cA786e7C7CC67B6227391d739E41C43AF285f
```

### 21. Denial

In this contract, calling `withdraw()` will send 1% of the balance of the contract to the current `partner` and to the `owner`. The contract specifies that it's expected for the call to the `partner` to potentially fail, and it will not disrupt the rest of the function execution. However, the contract is vulnerable to gas exhaustion attacks. By using a contract that consumes almost all gas available, as the `partner`, only 1/64 gas will be available after calling it, which is not enough to finish the execution of the function. Thus, the transaction will revert, creating a DoS condition.

Additionally, the contract might suffer from a reentrancy attack, since the state is updated after the calls.

Potential fix: pass a hardcoded gas to the `partner.call`, or use the `transfer` function instead. State modification should also be done before making the calls.

Code: [./src/DenialHack.sol](./src/DenialHack.sol)

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

Pending

### 34. Magical Animal Carousel

Pending