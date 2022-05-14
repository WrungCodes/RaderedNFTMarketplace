const hre = require("hardhat");

async function main() {

    const radTokenContractAddress = '0x5fbdb2315678afecb367f032d93f642f64180aa3';
    const adminAddress = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';

    const landFeeInUnitArea = '1000000000000000000';
    const changeURIfee = '1000000000000000000';

    // Float Library Contract
    const Float = await hre.ethers.getContractFactory("Float");
    const float = await Float.deploy();
    await float.deployed();

    const radverseContract = await hre.ethers.getContractFactory("Radverse", { libraries: { Float: float.address} });
    const radverse = await radverseContract.deploy(radTokenContractAddress, adminAddress, landFeeInUnitArea, changeURIfee);
    await radverse.deployed();

    console.log("RadVerse Contract deployed to:", radverse.address, `token contract address: ${radTokenContractAddress}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
