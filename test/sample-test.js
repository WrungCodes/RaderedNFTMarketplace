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

    const totalTiles = await Radverse._getAllTilesForAddress();
    console.log(totalTiles);

    const lat1 = '35.2054800';
    const long1 = '-97.0609900';
    const lat2 = '36.2054545';
    const long2 = '-98.0613590';

    // approve for addr1 to spend 500000000000000 tokens
    const area = calcArea(lat1, long1, lat2, long2);
    console.log(`Area ${area}`);

    await RadToken.connect(addr1).approve(Radverse.address, 500000000000000 * area);

    // mint tokens
    const mint = await Radverse.connect(addr1).mintToken(
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      lat1,
      long1,
      lat2,
      long2
    );

    await mint.wait();

    console.log(`mint:`, mint);

    console.log(`Radverse Total Number of tiles ${await Radverse._getTotalTiles()}`);
    const totalTiles1 = await Radverse.connect(addr1)._getAllTilesForAddress();
    console.log(totalTiles1);

    const addr1NewBalance = await RadToken.balanceOf(addr1.address);
    console.log(`${addr1.address} has ${ethers.utils.formatEther(addr1NewBalance)} RAD`);

    await RadToken.connect(addr1).approve(Radverse.address, 100000000000000);

    const changeURI = await Radverse.connect(addr1).setNewTokenURI(
      1,
      'https://www.www.com/watch?v=dQw4w9WgXcQ'
    );

    await changeURI.wait();

    console.log(`changeURI:`, changeURI);

    const addr1NewBalance2 = await RadToken.balanceOf(addr1.address);
    console.log(`${addr1.address} has ${ethers.utils.formatEther(addr1NewBalance2)} RAD`);

    const totalTiles2 = await Radverse.connect(addr1)._getAllTilesForAddress();
    console.log(totalTiles2);
  })

  const calcArea = (x1, y1, x2, y2) => {
    return Math.ceil(Math.abs(Math.abs(x2) -  Math.abs(x1)) * Math.abs(Math.abs(y2) -  Math.abs(y1)));
  }
  
});
