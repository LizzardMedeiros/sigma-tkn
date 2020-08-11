pragma solidity >=0.4.22 <0.7.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IFT.sol";

contract TestIFT {

  function testInitialBalanceUsingDeployedContract() public {
    IFT meta = IFT(DeployedAddresses.IFT());

    uint expected = 1000000;

    Assert.equal(meta.balanceOf(tx.origin), expected, "Owner should have 1000000 MetaCoin initially");
  }

  function testInitialBalanceWithNewIFT() public {
    IFT meta = new IFT();

    uint expected = 1000000;

    Assert.equal(meta.balanceOf(tx.origin), expected, "Owner should have 1000000 MetaCoin initially");
  }

}
