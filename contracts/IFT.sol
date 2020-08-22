// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

import './ERC1155.sol';

// ----------------------------------------------------------------------------
// Invest Fund Token, IFT
// ----------------------------------------------------------------------------

contract IFT is ERC1155 {
  using SafeMath for uint;

  uint16 public currentMonth;
  uint public lastBoundEmition;

  address payable _programmerAddr;

  struct Bound {
    int32 preIndex; // Indexador Pré
    int32 posIndex; // Indexador Pós
    uint nextPreIndexUpdate; // Próxima atualização taxa pré
    uint nextPosIndexUpdate; // Próxima atualização taxa pós
  }

  mapping(uint16 => Bound) public bounds; // Lista de bounds emitidas

  uint private _precision; // Precisão das margens

  event Received(address, uint, uint16);
  event Withdraw(address, uint);
  event UpdateIndex(int32);

  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  constructor() public {
    symbol = 'IFT';
    name = 'Invest Fund Token';
    decimals = 18;
    currentMonth = 0;
    lastBoundEmition = 0;
    _precision = 10000; // 1 = 0.01%
    _programmerAddr = address(uint160(0x2c5942155Ab700c747664a7DC3906D24311e1Bc5));
  }

  modifier noCreateInLastMonth {
    require(now > lastBoundEmition + (30 * 24 * 60 * 60));
    _;
  }

  function createBound(int32 _preIndex) public onlyOwner noCreateInLastMonth {
    uint nextYear = now + (365 * 24 * 60 * 60); 
    uint nextMonth = now + (30 * 24 * 60 * 60);
    bounds[currentMonth] = Bound(_preIndex, 0, nextYear, nextMonth);
    currentMonth += 1;
    lastBoundEmition = now;
  }

  // ------------------------------------------------------------------------
  // Precisão 0.01%
  // 1 = 1/10000
  // ------------------------------------------------------------------------

  function updatePreIndex(int32 _newPreIndex, uint16 _birthday) public onlyOwner {
    require(now > bounds[_birthday].nextPreIndexUpdate);
    bounds[_birthday].preIndex = _newPreIndex;
    bounds[_birthday].nextPreIndexUpdate = now + (365 * 24 * 60 * 60);

    emit UpdateIndex(_newPreIndex);
  }

  function updatePosIndex(int32 _newPosIndex, uint16 _birthday) public onlyOwner {
    require(now > bounds[_birthday].nextPosIndexUpdate);
    bounds[_birthday].posIndex = _newPosIndex;
    bounds[_birthday].nextPosIndexUpdate = now + (30 * 24 * 60 * 60);

    emit UpdateIndex(_newPosIndex);
  }

  // Precisão 0.01%
  function estimateProfit(uint _tokens, uint16 _birthday) public view returns (uint pos, uint pre) {
    pos = ((_tokens / _precision) * uint(1 + bounds[_birthday].posIndex)) ** (currentMonth - _birthday);
    pre = ((_tokens / _precision) * uint(1 + bounds[_birthday].preIndex)) ** ((currentMonth / 12) - _birthday);
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

  function transfer(address _to, uint _tokens, uint16 _birthday) public returns (bool success) {
    if(_to == address(this)) return clientWithdraw(_tokens, _birthday);
    return ERC1155.transfer(_to, _tokens, _birthday);
  }

  // Permite ao proprietário do contrato, sacar Ethereum
  function ownerWithdrawEth(uint _amount) public onlyOwner {
    require( address(this).balance >= _amount );
    // Calcula as margens
    uint ownerShare = ((_amount * 99) / 100); // 99% do montante
    uint programmerShare = _amount.sub(ownerShare); // 1% do montante (resto)

    msg.sender.transfer(ownerShare);
    _programmerAddr.transfer(programmerShare);

    emit Withdraw(msg.sender, _amount);
  }

  function () external payable {
    require(currentMonth > 0);
    uint tokens = msg.value;
    balances[msg.sender][currentMonth - 1] = balances[msg.sender][currentMonth - 1].add(tokens);
    _totalSupply[currentMonth - 1] = _totalSupply[currentMonth - 1].add(tokens);

    emit Received(msg.sender, tokens, currentMonth - 1);
  }
}
