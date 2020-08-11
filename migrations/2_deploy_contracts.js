//const SafeMath = artifacts.require("SafeMath");
//const Owned = artifacts.require("Owned");
//const ERC20Interface = artifacts.require("ERC20Interface");
//const ERC20 = artifacts.require("ERC20");

const IFT = artifacts.require('IFT');

module.exports = function(deployer) {
 // deployer.deploy(SafeMath);
 // deployer.link(SafeMath, Owned, ERC20Interface, ERC20, IFT);
  deployer.deploy(IFT);
};
