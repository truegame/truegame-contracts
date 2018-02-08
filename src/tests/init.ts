import { W3 } from 'soltsice';
import { testAccounts } from "../constants";
import * as ganache from 'ganache-cli';
import {BigNumber} from "bignumber.js";

let w3 = new W3(ganache.provider({
  mnemonic: 'truegame',
  network_id: 314
}));

w3.defaultAccount = testAccounts[0];
W3.Default = w3;

export {W3, testAccounts, w3, BigNumber};


