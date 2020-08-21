module.exports = {
  networks: {
    development: {
      // host: http://lizzardeth.duckdns.org
      host: "localhost",
      //port: 8545,
      port: 7545,
      network_id: "5777", // Match any network id
      gas: 5000000
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
