
const { HardhatUserConfig } = require('hardhat/config');
//require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();
//require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");


const config = {
  solidity: {
    version: '0.8.17',
    settings:{
      optimizer:{
        enabled :true,
        runs:50
      }
    }
  },
  
  networks: {
    // for mainnet
    'base-mainnet': {
      url: 'https://mainnet.base.org',
      accounts: [process.env.WALLET_KEY],
      gasPrice: 1000000000,
    },
    // for testnet
    'base-goerli': {
      url: 'https://goerli.base.org',
      accounts: [process.env.WALLET_KEY],
      gasPrice: 1000000000,
    },
    
    // for local dev environment
    'base-local': {
      url: 'http://localhost:8545',
      accounts: [process.env.WALLET_KEY],
      gasPrice: 1000000000,
    },
  },
  
  defaultNetwork: 'hardhat',
};

module.exports = config;
