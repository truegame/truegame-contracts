pragma solidity ^0.4.18;


contract Random {
  uint private seed = block.number;

  function random() internal returns(uint) {
    return (seed = uint(keccak256(seed,
      block.blockhash(block.number - 1),
      block.blockhash(block.number - 2),
      block.blockhash(block.number - 3),
      block.blockhash(block.number - 4)
      )));
  }
}