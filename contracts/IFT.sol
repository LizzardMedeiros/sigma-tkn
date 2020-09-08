// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

import './ERC1155.sol';

// ----------------------------------------------------------------------------
// Invest Fund Token, IFT
// ----------------------------------------------------------------------------

contract IFT is ERC1155 {
  using SafeMath for uint;

  // Variáveis globais
  uint16 public currentMonth;
  int32 public adminFee; // Precisão 0.01%
  uint public lastBoundEmition;

  // Endereço dos desenvolvedores
  address payable _programmerAddr;

  // Estrutura dos ativos
  struct Bound {
    int32 preIndex; // Indexador Pré - Precisão 0.01%
    int32 posIndex; // Indexador Pós - Precisão 0.01%
    uint nextPreIndexUpdate; // Próxima atualização taxa pré
    uint nextPosIndexUpdate; // Próxima atualização taxa pós
  }

  mapping(uint16 => Bound) public bounds; // Lista de bounds emitidas

  uint private _precision; // Precisão das margens

  event Received(address, uint, uint16);
  event Withdraw(address, uint);
  event UpdateIndex(int32);
  event UpdateFee(int32);

  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  
  constructor() public {
    symbol = 'IFT';
    name = 'Invest Fund Token';
    currentMonth = 0;
    lastBoundEmition = 0;
    adminFee = 0;
    _precision = 10 ** 4; // 1 = 0.01%
    _programmerAddr = address(uint160(0x00cBE0F4904d15E227Ba109221d7957642DB4b18));
  }

  modifier noCreateInLastMonth {
    require(now > lastBoundEmition + (30 * 24 * 60 * 60));
    _;
  }

  // ------------------------------------------------------------------------
  // TAXAS DE CONTRATO
  // Preindex e Posindex - precisão 1/10000 ou 0.01%
  // ------------------------------------------------------------------------

  function createBound(int32 _preIndex) public onlyOwner noCreateInLastMonth {
    uint nextYear = now + (365 * 24 * 60 * 60); 
    uint nextMonth = now + (30 * 24 * 60 * 60);
    bounds[currentMonth] = Bound(_preIndex, 0, nextYear, nextMonth);
    currentMonth += 1;
    lastBoundEmition = now;
  }

  function updatePreIndex(int32 _newPreIndex, uint16 _birthday) public onlyOwner {
    require(now > bounds[_birthday].nextPreIndexUpdate);
    bounds[_birthday].preIndex = _newPreIndex;
    // Mudar o cálculo para manter a precisão do ano em segundos
    bounds[_birthday].nextPreIndexUpdate = now + (365 * 24 * 60 * 60);

    emit UpdateIndex(_newPreIndex);
  }

  function updatePosIndex(int32 _newPosIndex, uint16 _birthday) public onlyOwner {
    require(now > bounds[_birthday].nextPosIndexUpdate);
    bounds[_birthday].posIndex = _newPosIndex;
    bounds[_birthday].nextPosIndexUpdate = now + (30 * 24 * 60 * 60);

    emit UpdateIndex(_newPosIndex);
  }

  function updateFees(int32 _newFee) public onlyOwner {
    require( _newFee >= int32(_precision) * -1 && _newFee <= int32(_precision));
    adminFee = _newFee;
    emit UpdateFee(_newFee);
  }

  function estimateProfit(uint _tokens, uint16 _birthday) public view returns (uint, uint) {
    uint pos = _tokens;
    uint pre = _tokens;
    for (uint16 m = 0; m < _birthday; m += 1) {
      pos = (pos * uint(bounds[_birthday].posIndex)) / _precision;
      pre = (pre * uint(bounds[_birthday].preIndex) / 12) / _precision; // Revisar
    }
    return (pre, pos);
  }

  // ------------------------------------------------------------------------
  // Permite o cliente sacar ETHs proporcionalmente à quantidade de IFTs
  // enviadas ao contrato referente à taxa de juros definida pelo indexador
  // ------------------------------------------------------------------------

  function clientWithdraw(uint _tokens, uint16 _birthday) public {
    uint _amount = ((_tokens * (_precision - uint(adminFee))) / _precision); 

    require(balances[msg.sender][_birthday] >= _amount);
    uint8 MOUNTS = 13;
    uint amountEth = _amount;

    if (_birthday % MOUNTS == 0) {
      (uint pre, uint pos) = estimateProfit(_amount, _birthday);
      amountEth = (pre > pos) ? pre : pos;
    }
     
    require(address(this).balance >= amountEth);

    // Queima os títulos enviados para o contrato
    ERC1155.transfer(address(0), _tokens, _birthday);
    msg.sender.transfer(amountEth);

    emit Withdraw(msg.sender, amountEth);
  }

  // ------------------------------------------------------------------------
  // Modificação da função de transferência padrão para a cambiação
  // IFT -> ETH.
  // ------------------------------------------------------------------------

  function transfer(address _to, uint _tokens, uint16 _birthday) public returns (bool) {
    if(_to == address(this)) clientWithdraw(_tokens, _birthday);
    else ERC1155.transfer(_to, _tokens, _birthday);
    return true;
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
