require("@nomicfoundation/hardhat-ethers");

module.exports = {
  solidity: {
    version: "0.8.28",
    settings: { optimizer: { enabled: true, runs: 200 }, evmVersion: "paris" },
  },
  networks: {
    ganache: { url: "http://127.0.0.1:7545", chainId: 1337, accounts: "remote" },
  },
};
