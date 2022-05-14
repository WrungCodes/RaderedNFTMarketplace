const hre = require("hardhat");

async function main() {
    const totalSupply = '1000000000000000000000000';

    const RadTokenContract = await hre.ethers.getContractFactory("RADToken");
    const radToken = await RadTokenContract.deploy(totalSupply);

    await radToken.deployed();

    console.log("RadTokenContract deployed to:", radToken.address, `totalSupply: ${totalSupply}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
