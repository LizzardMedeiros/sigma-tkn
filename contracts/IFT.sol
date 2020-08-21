// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

import './ERC1155.sol';

// ----------------------------------------------------------------------------
// Invest Fund Token, IFT
// ----------------------------------------------------------------------------

contract IFT is ERC1155 {
  using SafeMath for uint;

  mapping(uint16 => int16) private _tokenPreIndex; // Indexador Pré
  mapping(uint16 => int16) private _tokenPosIndex; // Indexador Pós
  uint16 private _currentMonth; // Mês vigente
  uint private _lastPreIndexUpdate; // Última atualização do pré-indexador
  uint private _lastPosIndexUpdate; // Última atualização do pré-indexador

  uint16 private _precision; //Precisão das margens

  event Received(address, uint, uint16);
  event Withdraw(address, uint);
  event UpdateIndex(int16);

  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  constructor() public {
    symbol = "IFT";
    name = "Invest Fund Token";
    decimals = 18;
    _precision = 10000; // 1 = 0.01%. 

    _currentMonth = 0;

    _tokenPreIndex[0] = 0;
    _tokenPosIndex[0] = 0;

    _lastPreIndexUpdate = 0;
    _lastPosIndexUpdate = 0;
  }

  modifier noUpdateInLastMonth{
    require(now > _lastPosIndexUpdate + (30 * 24 * 60 * 60));
    _;
  }

  modifier noUpdateInLastYear{
    require(now > _lastPreIndexUpdate + (365 * 24 * 60 * 60));
    _;
  }

  // Precisão 0.01% 
  function updatePreIndex(int16 _newPreIndex) public onlyOwner noUpdateInLastYear {
    uint16 currentYear = _currentMonth / 12;
    _tokenPreIndex[currentYear] = _newPreIndex;
    _lastPreIndexUpdate = now;
    emit UpdateIndex(_newPreIndex);
  }

  // 1 = 1/10000
  function updatePosIndex(int16 _newPosIndex) public onlyOwner noUpdateInLastMonth {
    _tokenPosIndex[_currentMonth] = _newPosIndex;
    _currentMonth++;
    _lastPosIndexUpdate = now;
    emit UpdateIndex(_newPosIndex);
  }

  function estimateProfit(uint _tokens, uint16 _birthday) public view returns (uint pos, uint pre) {
    // Precisão 0.01%
    pos = ((_tokens / _precision) * uint(1 + _tokenPosIndex[_birthday])) ** (_currentMonth - _birthday);
    pre = ((_tokens / _precision) * uint(1 + _tokenPreIndex[_birthday])) ** ((_currentMonth / 12) - _birthday);
  }

  // ------------------------------------------------------------------------
  // Permite o cliente sacar ETHs proporcionalmente à quantidade de IFTs
  // enviadas ao contrato referente à taxa de juros definida pelo indexador
  // ------------------------------------------------------------------------
  function clientWithdraw(uint _tokens, uint16 _birthday) public returns (bool success){
    require(balances[msg.sender][_birthday] >= _tokens);
    (uint pos, uint pre) = estimateProfit(_tokens, _birthday);
    uint amountEth = (pos > pre) ? pos : pre;

    require( address(this).balance >= amountEth );
    require(ERC1155.transfer(address(0), _tokens, _birthday));

    msg.sender.transfer(amountEth);
    emit Withdraw(msg.sender, amountEth);

    return true;
  }

  // ------------------------------------------------------------------------
  // Modificação da função de transferência padrão para a cambiação
  // IFT -> ETH.
  // ------------------------------------------------------------------------
  function transfer(address to, uint tokens, uint16 _birthday) public returns (bool success) {
    if(to == address(this)) return clientWithdraw(tokens, _birthday);
    return ERC1155.transfer(to, tokens, _birthday);
  }

  // Permite ao proprietário do contrato, sacar Ethereum
  function ownerWithdrawEth(uint _amount) public onlyOwner {
    require( address(this).balance >= _amount );
    msg.sender.transfer(_amount);
    emit Withdraw(msg.sender, _amount);
  }

  function () external payable {
    uint tokens = msg.value;
    balances[msg.sender][_currentMonth] = balances[msg.sender][_currentMonth].add(tokens);

    emit Received(msg.sender, tokens, _currentMonth);
  }
}