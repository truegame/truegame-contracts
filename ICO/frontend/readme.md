# README #



### What is this repository for? 

* L-Pesa front end for white listing



### How do I get set up?  

* first deploy white listing contract found in sol folder to any of the testnet nodes. 
* record the contract address and assign it to var **whiteListContractAddress =**   it in **interface.js** file 
* Update **connectionString** in **interface.js** to proper node address you have deployed your whitelist contract to. 
* Open file **whitelistuser.html** to white list a member. You will need Metamask to be able to use this front end. 
* Smart contract contains two functions to add white listed user. It is a single mode addition and batch addition. 
  Using batch, you have to ensure that you don't run out of gas. Test smaller batches to see how many users you can add using max allowable gas which can 
  be found here https://ethstats.net/

