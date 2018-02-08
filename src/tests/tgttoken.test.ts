import {W3, testAccounts, BigNumber, w3} from './init';

import { TGT } from '../contracts';

let TGTToken: TGT;

beforeEach(async () => {
  expect(await w3.isTestRPC).toBe(true);
  TGTToken = await TGT.New(
    W3.TX.txParamsDefaultDeploy(testAccounts[0]), {_multisig: testAccounts[0]}
  );
});

describe('TGTToken', async function() {
  
  
  it('Total supply == 0', async function() {
    let value = await TGTToken.totalSupply();
    
    expect(value).toEqual(new BigNumber(0));
    
    console.log('TX HASH: ', TGTToken.transactionHash);
  });
});