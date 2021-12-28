require("@nomiclabs/hardhat-waffle");
const fs = require("fs");
const projectId = '3fa92291caad4246a60fdc03ec444a57'

const keyData = fs.readFileSync("./priv-key.txt", { encoding: "utf8", flag: "r" });

module.exports = {
  solidity: { 
    version: "0.8.4",
    settings: {
      optimizer: { enabled: true, runs: 200 },
    }
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: { chainId: 1337 },
    ropsten: { url: `https://ropsten.infura.io/v3/${projectId}`, accounts: [ keyData ] },
    mainnet: { url: `https://mainnet.infura.io/v3/${projectId}`, accounts: [ keyData ] },
  },
};
