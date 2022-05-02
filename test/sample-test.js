const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Radered", function () {

  it("test eg", async function () {
    const Strings = await ethers.getContractFactory("strings");
    const strings = await Strings.deploy();
    await strings.deployed();

    const Float = await ethers.getContractFactory("Float");
    const float = await Float.deploy();
    await float.deployed();

    // Get the deployed contract RaderedShardNFT
    const testContract = await ethers.getContractFactory("Test", { libraries: { Float: float.address} });

    const test = await testContract.deploy();

    const a = "-6.204000";
    const b = "10.400010";

    console.log(await test.add(a, b));
    console.log(await test.sub(a, b));
    console.log(await test.multiply(a, b));
    console.log(await test.isGreaterThan(a, b));
    console.log(await test.isLessThan(a, b));

    console.log(await test.DivideBy2('4.000000'));
    console.log(await test.DivideBy2('5.000000'));
  })

  it("Generate Token", async function () {
    // Get the ERC20 deployed contract RadToken
    const radTokenContract = await ethers.getContractFactory("RADToken");
    const RadToken = await radTokenContract.deploy('100000000000000000');
    await RadToken.deployed();
    const totalSupply = await RadToken.totalSupply();

    console.log(`RADToken contract address ${RadToken.address}`);
    console.log(`RADToken total supply ${ethers.utils.formatEther(totalSupply)}`);

    const [ owner, admin, addr1 ] = await ethers.getSigners();

    const ownerBalance = await RadToken.balanceOf(owner.address);
    console.log(`${owner.address} has ${ethers.utils.formatEther(ownerBalance)} RAD`);

    expect(await RadToken.totalSupply()).to.equal(ownerBalance);

    // Transfer 50 tokens from owner to addr1
    console.log(`Transfer 100 RAD from ${owner.address} to ${addr1.address}`);
    await RadToken.transfer(addr1.address, '50000000000000000');

    const addr1Balance = await RadToken.balanceOf(addr1.address);
    console.log(`${addr1.address} has ${ethers.utils.formatEther(addr1Balance)} RAD`);

    // const amount = ethers.utils.parseEther("1.0");

    // Float Library Contract
    const Float = await ethers.getContractFactory("Float");
    const float = await Float.deploy();
    await float.deployed();

    // Get the deployed Universe contract 
    const radverseContract = await ethers.getContractFactory("Radverse", { libraries: { Float: float.address} });
    const Radverse = await radverseContract.deploy(RadToken.address, admin.address, 500000000000000, 100000000000000);
    await Radverse.deployed();

    console.log(`Radverse contract address ${Radverse.address}`);
    console.log(`Radverse Total Number of tiles ${await Radverse._getTotalTiles()}`);
  })

  it("Should return the new greeting once it's changed", async function () {

    const Strings = await ethers.getContractFactory("strings");
    const strings = await Strings.deploy();
    await strings.deployed();

    const Float = await ethers.getContractFactory("Float");
    const float = await Float.deploy();
    await float.deployed();

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

    const [_, buyerAddress, locatorAddress] = await ethers.getSigners();

    const hunkTokenId = await creation.connect(buyerAddress).mintToken(
      hunkAddress, 
      shardAddress, 
      ['http://example.com/hunk.png', 'http://example.com/shard1.png', 'http://example.com/shard2.png', 'http://example.com/shard3.png'],
      [ ethers.utils.parseEther("1"), ethers.utils.parseEther("2"), ethers.utils.parseEther("3")], 
      // [ "-50.531052,-39.531052,-60.531052,-40.531052,", "6.442251,3.531052,6.442000,3.530500,", "41.403362,-3.832292,41.336416,-4.020151," ] //
      [ 
        [ ['1', '50', '531052'], ['1', '39', '531052'], ['1', '60', '531052'], ['1', '40', '531052'] ],
        [ ['1', '6', '442251'], ['1', '3', '531052'], ['1', '6', '442000'], ['1', '3', '530500'] ],
        [ ['1', '41', '403362'], ['1', '1', '832292'], ['1', '41', '336416'], ['1', '1', '020151'] ]
      ] //

    );

    await hunkTokenId.wait();

    // console.log(`hunkTokenId:`, hunkTokenId);

    // console.log(await creation.connect(buyerAddress).getAllRadereds());

    // console.log(await shard.connect(buyerAddress).getAllShards());

    const locate1 = await creation.connect(locatorAddress).isLocationVerifcation(
      shardAddress, 
      1, 
      "-60.000000",
      "-40.000000",
      { value: ethers.utils.parseEther("0.0004") }
    )

    await locate1.wait();

    const locate2 = await creation.connect(locatorAddress).isLocationVerifcation(
      shardAddress, 
      2, 
      "6.442100",
      "3.530600",
      { value: ethers.utils.parseEther("0.0004") }
    )

    await locate2.wait();

    const locate3 = await creation.connect(locatorAddress).isLocationVerifcation(
      shardAddress, 
      3,
      "41.378560", // 41.378560994761045, -3.8984102827389635
      "-3.898410",
      { value: ethers.utils.parseEther("0.0004") }
    )

    await locate3.wait();

    // console.log(`locate:`, locate);

    console.log(await creation.connect(locatorAddress).getUserDiscoveredShards());

    // console.log('isGreaterThan: ', await shard.isGreaterThan({_value: [1, 3, 8984102827389635]}, {_value:[1, 4, 020151617165021]}));
    // console.log('isLesserThan: ', await shard.isLesserThan({_value: [1, 3, 8984102827389635]}, {_value:[1, 3, 832292144214467]}));

    // console.log('isGreaterThan: ', await shard.isGreaterThan({_value: [0, 41, 378560]}, {_value:[0, 41, 336416]}));
    // console.log('isLesserThan: ', await shard.isLesserThan({_value: [0, 41, 378560]}, {_value:[0, 41, 403362]}));


    // console.log((await shard.connect(locatorAddress).getShardDetails(2)).location); 31.38252529279829, 2.1171138388337334  31.381830678299888, 2.1158120155397127


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
