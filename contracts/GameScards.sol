pragma solidity ^0.4.18;

import "./GameCommon.sol";


contract GameScards is Game, Random {

  using SafeMath for uint;

  uint public nBets;

  uint public curBets = 0;

  struct Player {
    address addr;
    uint bets;
  }

  Player[] players;

  uint32 finalityPlayersIterator;

  function() public payable {
    require(false);
  }

  function isBetsAreEnded() internal view returns(bool) {
    return curBets == nBets;
  }

  function isFinalityEnded() internal view returns(bool) {
    return finalityPlayersIterator == players.length;
  }

  function init(uint _prizeFund, uint _playPrice) public onlyOwner hasState(State.NONE) updateState {
    prizeFund = _prizeFund;
    playPrice = _playPrice;
    finalityPlayersIterator = 0;
    nBets = prizeFund / playPrice;
    curBets = 0;
  }

  function play(address player, uint bets) public onlyOwner hasState(State.BETS) updateState {
    require((curBets.add(bets)) <= nBets);
    players.push(Player(player, bets));
    curBets += bets;
  }

  uint storageR;

  function finality() public onlyOwner hasState2(State.ENDBETS, State.FINALITY) updateState returns(bool) {

    uint r = (finalityPlayersIterator == 0) ? (storageR = (random() % nBets)) : storageR;
    uint cr = 0;

    Player storage winner;

    uint nsteps = 100;
    uint diffLength = (players.length - finalityPlayersIterator);
    uint end = (diffLength < nsteps) ? diffLength : nsteps;
    uint it;

    for(it = finalityPlayersIterator; it < end; ++it) {
      cr += players[it].bets;
      if(cr > r) {
        winner = players[it];
        break;
      }
    }

    finalityPlayersIterator = uint32(it);

    pay(winner.addr, prizeFund);
    return isFinalityEnded();
  }

}