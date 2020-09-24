// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

import './IFT.sol';

contract IFTM is IFT {

  constructor () public {
    symbol = 'IFTM';
  }

  function addMonth(uint16 _qtd) public {
    currentMonth += _qtd;
  }

  function createBound(int32 _preIndex) public onlyOwner {
    bounds[currentMonth] = Bound(_preIndex, 0, 0, 0, 0);
    currentMonth += 1;
    lastBoundEmition = currentMonth;
    emit CreateBound(currentMonth);
  }

  function updatePreIndex(int32 _newPreIndex, uint16 _birthday) public onlyOwner {
    int32 preIndex = bounds[_birthday].preIndex;
    int32 posIndex = bounds[_birthday].posIndex;
    bounds[_birthday].curIndex = (preIndex > posIndex) ? preIndex : posIndex;
    bounds[_birthday].preIndex = _newPreIndex;

    emit UpdateIndex(_newPreIndex);
  }

  function updatePosIndex(int32 _newPosIndex, uint16 _birthday) public onlyOwner {
    bounds[_birthday].posIndex = _newPosIndex;
    emit UpdateIndex(_newPosIndex);
  }

}
