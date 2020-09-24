const HDWalletProvider = require('truffle-hdwallet-provider');
const CONFIG = require('./config.json');

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 7545,
      network_id: "5777", // Match any network id
      gas: 2000000
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(
          CONFIG.MNEMONIC,
          `https://ropsten.infura.io/v3/${CONFIG.INFURA_API_KEY}`,
        );
      },
      network_id: '3',
    }
  },
  compilers: {
    solc: {
      version: "^0.5.16",
      settings: {
        optimizer: {
          enabled: true, // Default: false
          runs: 200      // Default: 200
        },
      }
    }
  }
};
