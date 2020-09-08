pragma solidity >=0.4.22 <0.7.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IFT.sol";

contract TestIFT {

  function testContractNameAndSymbol() public {
    IFT meta = new IFT();
    string memory expectedName = "Invest Fund Token";
    string memory expectedSymbol = "Invest Fund Token";

    Assert.equal(meta.name(), expected, "Name have to be equal Invest Fund Token");
    Assert.equal(meta.symbol(), expected, "Symbol have to be equal IFT");
  }

}
