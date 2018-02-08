pragma solidity ^0.4.18;


import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Random.sol";


interface GameExternals {
  function getPlayPrice() public view returns(uint);
  function getPrizeFound() public view returns(uint);
}


interface GameCroupier {
  function internalPay(address player, uint prizeInTokens) public;
}


contract GameStateBase {

  enum State {
    NONE,
    BETS,
    ENDBETS,
    FINALITY
  }

  State __state = State.NONE;

  modifier hasState(State state) {
    require(__state == state);
    _;
  }

  modifier hasState2(State statea, State stateb) {
    require(__state == statea || __state == stateb);
    _;
  }

}


contract GameState is GameStateBase, Ownable {

  function isBetsAreEnded() internal view returns(bool);

  uint betsEndBlock;

  function isFinalityAllowed() public hasState(State.ENDBETS) view returns(bool) {
    return block.number > (betsEndBlock + 10);
  }

  function isFinalityEnded() internal view returns(bool);

  modifier updateState() {
    if(__state == State.NONE) {
      _;
      __state = State.BETS;

    } else if(__state == State.BETS) {
      _;
      if(isBetsAreEnded()) {
        betsEndBlock = block.number;
        __state = State.ENDBETS;
      }

    } else if(__state == State.ENDBETS) {
      if(isFinalityAllowed()) {
        __state = State.FINALITY;
        _;
        if(isFinalityEnded()) __state = State.NONE;
      } else require(false);

    } else if(__state == State.FINALITY) {
      _;
      if(isFinalityEnded())
        __state = State.NONE;
    } else require(false);
  }

  function finality() public onlyOwner hasState2(State.ENDBETS, State.FINALITY) updateState() returns(bool);
}


contract GameCroupierFeatures is Ownable {

  function pay(address player, uint prize) internal {
    GameCroupier croupier = GameCroupier(owner);
    croupier.internalPay(player, prize);
  }
}


contract Game is GameState, GameExternals, GameCroupierFeatures {

  uint playPrice;
  uint prizeFund;

  function getPlayPrice() public hasState(State.BETS) view returns(uint) {
    return playPrice;
  }

  function getPrizeFound() public view returns(uint) {
    return playPrice;
  }

}