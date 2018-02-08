pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";


contract TGT is StandardToken, Ownable {

  string public constant name = "TGT TOKEN";
  string public constant symbol = "TGT";
  uint8 public constant decimals = 0;
  uint __price = (1 ether / 10000) / 1000;

  function price() public view returns(uint) {
    return __price;
  }

  function mint(address to, uint amount) public onlyOwner returns(bool)  {
    require(to != address(0) && amount > 0);
    totalSupply_ = totalSupply_.add(amount);
    balances[to] = balances[to].add(amount);
    Transfer(address(0), to, amount);
    return true;
  }

  function burn(address from, uint amount) public onlyOwner returns(bool) {
    require(from != address(0) && amount > 0);
    balances[from] = balances[from].sub(amount);
    totalSupply_ = totalSupply_.sub(amount);
    Transfer(from, address(0), amount);
    return true;
  }

  function get(address from, address to, uint amount) public onlyOwner returns(bool) {
    require(from != address(0) && amount > 0);
    balances[from] = balances[from].sub(amount);
    balances[to] = balances[to].add(amount);
    Transfer(from, to, amount);
    return true;
  }

  function toEthers(uint tokens) public view returns(uint) {
    return tokens.mul(__price);
  }

  function fromEthers(uint ethers) public view returns(uint) {
    return ethers / __price;
  }

  function buy(address recipient) public payable returns(bool) {
    return mint(recipient, fromEthers(msg.value));
  }

  function sell(address recipient, uint tokens) public returns(bool) {
    burn(recipient, tokens);
    recipient.transfer(toEthers(tokens));
  }

  function() public payable {
    buy(msg.sender);
  }

}