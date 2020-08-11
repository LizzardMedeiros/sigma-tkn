pragma solidity >=0.5.16 <0.7.0;

import './ERC20.sol';

// ----------------------------------------------------------------------------
// Invest Fund Token, IFT
// ----------------------------------------------------------------------------

contract IFT is FixedSupplyToken {
  using SafeMath for uint;
  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  constructor() public {
      symbol = "IFT";
      name = "Invest Fund Token";
      decimals = 18;
      _totalSupply
       = 1000000 * 10**uint(decimals); //1.000.000
      balances[owner] = _totalSupply;
      emit Transfer(address(0), owner, _totalSupply);
  }
}