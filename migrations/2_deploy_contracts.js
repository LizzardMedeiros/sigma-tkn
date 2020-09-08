//const SafeMath = artifacts.require("SafeMath");
//const Owned = artifacts.require("Owned");
//const ERC20 = artifacts.require("ERC20");

const IFT = artifacts.require('IFT');

module.exports = function(deployer) {
 deployer.deploy(IFT);
};
