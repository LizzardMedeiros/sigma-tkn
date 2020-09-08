// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

import './SafeMath.sol';
import './Owned.sol';

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

// ----------------------------------------------------------------------------
// ERC1155 Token, with the addition of symbol, name
// ----------------------------------------------------------------------------

contract ERC1155 is Owned {
    using SafeMath for uint;

    string public symbol;
    string public name;

    mapping(uint16 => uint) public _totalSupply;
    mapping(address => mapping(uint16 => uint)) balances;
    mapping(address => mapping(address => mapping( uint16 => uint))) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "FIXED";
        name = "Example Fixed Supply Token";
    }
    
    event Transfer(address indexed from, address indexed to, uint tokens, uint16 _birthday);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens, uint16 _birthday);

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply(uint16 _birthday) public view returns (uint) {
        return _totalSupply[_birthday] - balances[address(0)][_birthday];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner, uint16 _birthday) public view returns (uint balance) {
        return balances[tokenOwner][_birthday];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens, uint16 _birthday) public returns (bool success) {
        balances[msg.sender][_birthday] = balances[msg.sender][_birthday].sub(tokens);
        balances[to][_birthday] = balances[to][_birthday].add(tokens);
        emit Transfer(msg.sender, to, tokens, _birthday);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens, uint16 _birthday) public returns (bool success) {
        allowed[msg.sender][spender][_birthday] = tokens;
        emit Approval(msg.sender, spender, tokens, _birthday);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens, uint16 _birthday) public returns (bool success) {
        balances[from][_birthday] = balances[from][_birthday].sub(tokens);
        allowed[from][msg.sender][_birthday] = allowed[from][msg.sender][_birthday].sub(tokens);
        balances[to][_birthday] = balances[to][_birthday].add(tokens);
        emit Transfer(from, to, tokens, _birthday);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender, uint16 _birthday) public view returns (uint remaining) {
        return allowed[tokenOwner][spender][_birthday];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint256 tokens, bytes memory data, uint16 _birthday) public returns (bool success) {
        allowed[msg.sender][spender][_birthday] = tokens;
        emit Approval(msg.sender, spender, tokens, _birthday);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
}