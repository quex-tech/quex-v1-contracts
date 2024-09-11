require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
      version: "0.8.22",
      settings: {
          evmVersion: "paris",
          viaIR: true,
          optimizer: {
              enabled: true,
              runs: 200
          }
      },
  },
    networks: {
        hardhat: {
            initialDate: '30 Aug 2024 10:30:30 GMT',
        }
    }
};
