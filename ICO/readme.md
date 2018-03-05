# README #



### What is this repository for? 

* Truegame ICO contract
* ver 1.0
* for crowdfunding during the pre and ICO phase


### How do I get set up?  

* Use truffle, Ethereum Wallet or Remix to deploy contract on Ethereum network.
* Deploy whitelist contract and obtain its address. 
* Second deploy "Crwodsale" contract and pass address from first step as a parameter and obtain its address.  
* Secondly deploy "Token" contract and use address from previous step as its input. Obtain address of the token contract.  
This step can be done after ICO as tokens will be distributed after ICO is finished. 
* Thirdly call function updateTokenAddress() of "Crowdsale" contract and provide address from Token contract as input.


### How do I run

* owner can start the contract by calling **start()** function. Argument provided to the **start()** function is number of blocks. Average block time on main net is around 15 seconds as of this writing.  

* contributions are accepted by sending ether to contract address 

* when contract is deployed first, it is configured to act as a presale contract.  

* to switch contract to public ICO mode call **setStep()** function and provide as argument "2", to set public ICO mode.  

* when the campaign is over, admin can run **finilize()** function to end the campaign and transfer unsold and dev tokens to individual wallet.  
During finalize, token contract is unlocked and contributors can start trading tokens. 

* in case of emergency function **emergencyStop()** can be called to stop contribution and function release() to start campaign again.  

* in  Crowdsale contract option to withdraw contributions is provided in case ICO was not successful. Minimum cap hasn't been reached.  

* contributors can call function **refund()** to burn the tokens and return the money to  pull their contribution from the contract.  

* in order for contributors to be able to get refunds, following conditions have to be met.  

    1. Current block number has to be higher then endBlock. 
    2. Campaign did't reach minCap.
    3. Step has to be set to "3" using setStep() function.  
    4. There has to be money in the Crowdsale contract. Since money is transferred out of contract during contribution, fundContract() functoin allows 
       to add funds to be refunded to contributors.  

* Function **eraseContribution()** can be used to delete allocation of tokens for contributor for manual refund. 
* Function **addManualContributor()** allows on manual allocation of tokens for contributor

