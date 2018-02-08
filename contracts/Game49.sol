pragma solidity ^0.4.18;

import "./GameCommon.sol";


contract Game49 is Game, Random {

  struct Player {
    address addr;
    uint48 data;
  }

  Player[] public players;

  function playersLength() public view returns(uint) {
    return players.length;
  }

  uint32 finalityPlayersIterator;
  uint64 endTime;

  function init(uint _prizeFund, uint _playPrice, uint64 _endTime) public onlyOwner hasState(State.NONE) updateState {
    prizeFund = _prizeFund;
    playPrice = _playPrice;
    endTime = _endTime;
    finalityPlayersIterator = 0;
  }

  function isBetsAreEnded() internal view returns(bool) {
    return now > endTime;
  }

  function isFinalityEnded() internal view returns(bool) {
    return finalityPlayersIterator == players.length;
  }

  function() public payable {
    require(false);
  }

  function getPrize(uint w) public hasState(State.BETS) view returns(uint) {
    if(w < 2) return 0;
    if(w == 2) return playPrice;//для двух
    uint8[4] memory coefs = [5, 10, 20, 50];
    require((w - 3) < 4);
    return (prizeFund * coefs[w - 3]) / 100;
  }


  function play(address player, uint48 data) public onlyOwner hasState(State.BETS) updateState {
    players.push(Player(player, data));
  }


  function find(uint[6] data, uint x) private pure returns(uint w) {

    for(uint it = 0; it < 6; ++it) {
      if(data[it] == x) ++w;
    }
  }

  function random_fill() private returns(uint[6] res) {

    uint r;

    for(uint it = 0; it < 6; ++it) {
      for(uint w = 1; w != 0; w = find(res, (r = ((random() % 49) + 1)))) {}
      res[it] = r;
    }
  }

  function diff(uint48 a, uint[6] b) private pure returns(uint w) {

    for(uint i = 0; i < 6; ++i) {
      uint x = ((a >> (8 * i)) & 0xff);
      for(uint j = 0; j < 6; ++j) {
        if(b[j] == x) ++w;
      }
    }
  }

  uint[6] public storageData;

  function finality() public onlyOwner hasState2(State.ENDBETS, State.FINALITY) updateState returns(bool) {

    uint[6] memory data = (finalityPlayersIterator == 0) ? (storageData = random_fill()) : storageData;


    uint nsteps = 100;
    uint diffLength = (players.length - finalityPlayersIterator);
    uint end = (diffLength < nsteps) ? diffLength : nsteps;
    uint it;

    for(it = finalityPlayersIterator; it < end; ++it) {

      Player storage player = players[it];

      uint w = diff(player.data, data);
      uint prize = getPrize(w);

      if(prize != 0) {
        pay(player.addr, prize);
      }
    }

    finalityPlayersIterator = uint32(it);
    return isFinalityEnded();
  }
}