const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Radered", function () {

  it("Should return the new greeting once it's changed", async function () {

    const Float = await ethers.getContractFactory("Float");
    const float = await Float.deploy();
    await float.deployed();

    const Strings = await ethers.getContractFactory("strings");
    const strings = await Strings.deploy();
    await strings.deployed();

    const RaderedUtils = await ethers.getContractFactory("RaderedUtils", { libraries: { Float: float.address } });
    const raderedUtils = await RaderedUtils.deploy();
    await raderedUtils.deployed();
    
    // Get the deployed contract RaderedHunkNFT
    const RaderedHunkNFT = await ethers.getContractFactory("RaderedHunkNFT");

    // Get the deployed contract RaderedShardNFT
    const RaderedShardNFT = await ethers.getContractFactory("RaderedShardNFT", { libraries: { Float: float.address, RaderedUtils: raderedUtils.address } });

    // Get the deployed contract RaderedCreation
    const RaderedCreation = await ethers.getContractFactory("RaderedCreation", { libraries: { RaderedUtils: raderedUtils.address } });

    // Get the deployed contract RaderedMarket
    const RaderedMarket = await ethers.getContractFactory("RaderedMarket");


    const market = await RaderedMarket.deploy();
    await market.deployed();
    const marketAddress = market.address;

    const creation = await RaderedCreation.deploy();
    await creation.deployed();
    const creationAddress = creation.address;

    const hunk = await RaderedHunkNFT.deploy(marketAddress, creationAddress);
    await hunk.deployed();
    const hunkAddress = hunk.address;

    const shard = await RaderedShardNFT.deploy(marketAddress, creationAddress);
    await hunk.deployed();
    const shardAddress = shard.address;

    const [_, buyerAddress] = await ethers.getSigners();

    console.log(await creation.connect(buyerAddress).getAllRadereds());


    // const Greeter = await ethers.getContractFactory("Greeter");
    // const greeter = await Greeter.deploy("Hello, world!");
    // await greeter.deployed();

    // expect(await greeter.greet()).to.equal("Hello, world!");

    // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // // wait until the transaction is mined
    // await setGreetingTx.wait();

    // expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
