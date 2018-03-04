pragma solidity ^ 0.4.17;


library SafeMath {
    function mul(uint a, uint b) pure internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) pure internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) pure internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) 
            owner = newOwner;
    }

    function kill() public {
        if (msg.sender == owner) 
            selfdestruct(owner);
    }

    modifier onlyOwner() {
        if (msg.sender == owner)
            _;
    }
}


contract Pausable is Ownable {
    bool public stopped;

    modifier stopInEmergency {
        if (stopped) {
            revert();
        }
        _;
    }

    modifier onlyInEmergency {
        if (!stopped) {
            revert();
        }
        _;
    }

    // Called by the owner in emergency, triggers stopped state
    function emergencyStop() external onlyOwner() {
        stopped = true;
    }

    // Called by the owner to end of emergency, returns to normal state
    function release() external onlyOwner() onlyInEmergency {
        stopped = false;
    }
}


// Whitelist smart contract
// This smart contract keeps list of addresses to whitelist
contract WhiteList is Ownable {

    
    mapping(address => bool) public whiteList;
    mapping(address => address) public affiliates;
    uint public totalWhiteListed; //white listed users number

    event LogWhiteListed(address indexed user, address affiliate, uint whiteListedNum);
    event LogWhiteListedMultiple(uint whiteListedNum);
    event LogRemoveWhiteListed(address indexed user);

    // @notice it will return status of white listing
    // @return true if user is white listed and false if is not
    function isWhiteListedAndAffiliate(address _user) external view returns (bool, address) {
        return (whiteList[_user], affiliates[_user]); 
    }

    // @notice it will return refferal address 
    // @param _user {address} address of contributor
    function returnReferral(address _user) external view returns (address) {
        return  affiliates[_user];
    
    }

    // @notice it will remove whitelisted user
    // @param _contributor {address} of user to unwhitelist
    function removeFromWhiteList(address _user) external onlyOwner() returns (bool) {
       
        require(whiteList[_user] == true);
        whiteList[_user] = false;
        affiliates[_user] = address(0);
        totalWhiteListed--;
        LogRemoveWhiteListed(_user);
        return true;
    }

    // @notice it will white list one member
    // @param _user {address} of user to whitelist
    // @return true if successful
    function addToWhiteList(address _user, address _affiliate) external onlyOwner() returns (bool) {

        if (whiteList[_user] != true) {
            whiteList[_user] = true;
            affiliates[_user] = _affiliate;
            totalWhiteListed++;
            LogWhiteListed(_user, _affiliate, totalWhiteListed);            
        }
        return true;
    }

    // @notice it will white list multiple members
    // @param _user {address[]} of users to whitelist
    // @return true if successful
    function addToWhiteListMultiple(address[] _users) external onlyOwner() returns (bool) {

        for (uint i = 0; i < _users.length; ++i) {

            if (whiteList[_users[i]] != true) {
                whiteList[_users[i]] = true;
                totalWhiteListed++;                          
            }           
        }
        LogWhiteListedMultiple(totalWhiteListed); 
        return true;
    }
}

// Crowdsale Smart Contract
// This smart contract collects ETH and in return sends tokens to contributors
contract Crowdsale is Pausable {

    using SafeMath for uint;

    struct Backer {
        uint weiReceived; // amount of ETH contributed
        uint tokensToSend; // amount of tokens  sent  
        bool claimed;
        bool refunded; // true if user has been refunded       
    }

    

    Token public token; // Token contract reference   
    address public multisig; // Multisig contract that will receive the ETH    
    address public team; // Address at which the team tokens will be sent        
    uint public ethReceivedPresale; // Number of ETH received in presale
    uint public ethReceivedMain; // Number of ETH received in public sale
    uint public totalTokensSent; // Number of tokens sent to ETH contributors
    uint public totalAffiliateTokensSent;
    uint public startBlock; // Crowdsale start block
    uint public endBlock; // Crowdsale end block
    uint public maxCap; // Maximum number of tokens to sell
    uint public minCap; // Minimum number of ETH to raise
    uint public minInvestETH; // Minimum amount to invest   
    bool public crowdsaleClosed; // Is crowdsale still in progress
    Step public currentStep;  // to allow for controled steps of the campaign 
    uint public refundCount;  // number of refunds
    uint public totalRefunded; // total amount of refunds    
    uint public tokenPriceWei;  // price of token in wei
    WhiteList whiteList;
    uint public numOfBlocksInMinute;// number of blocks in one minute * 100. eg. 
    uint public claimCount;
    uint public totalClaimed;                   // Total number of tokens claimed

    mapping(address => Backer) public backers; //backer list
    mapping(address => uint) public affiliates;
    address[] public backersIndex; // to be able to itarate through backers for verification.  
    mapping(address => uint) public claimed;    // Tokens claimed by contibutors

    
    // @notice to verify if action is not performed out of the campaing range
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) 
            revert();
        _;
    }

    // @notice to set and determine steps of crowdsale
    enum Step {
        Unknown,
        FundingPreSale,     // presale mode
        FundingPublicSale,  // public mode
        Refunding,  // in case campaign failed during this step contributors will be able to receive refunds
        Claiming    // set this step to enable claiming of tokens. 
    }

    // Events
    event ReceivedETH(address indexed backer, address indexed affiliate, uint amount, uint tokenAmount, uint affiliateTokenAmount);
    event RefundETH(address backer, uint amount);
    event TokensClaimed(address backer, uint count);


    // Crowdsale  {constructor}
    // @notice fired when contract is crated. Initilizes all constnat and initial values.
    function Crowdsale(WhiteList _whiteListAddress) public {
        multisig = 0xc15464420aC025077Ba280cBDe51947Fc12583D6; 
        team = 0xc15464420aC025077Ba280cBDe51947Fc12583D6;                                  
        minInvestETH = 1 ether/100;
        startBlock = 0; // Should wait for the call of the function start
        endBlock = 0; // Should wait for the call of the function start                  
        tokenPriceWei = 108110000000000;
        maxCap = 210000000e18;         
        minCap = 21800000e18;        
        totalTokensSent = 0;  //TODO: add tokens sold in private sale
        setStep(Step.FundingPreSale);
        numOfBlocksInMinute = 438;  //  TODO: updte this value before deploying. E.g. 4.38 block/per minute wold be entered as 438   
        whiteList = WhiteList(_whiteListAddress);    
    }

    // @notice to populate website with status of the sale 
    function returnWebsiteData() external view returns(uint, uint, uint, uint, uint, uint, uint, uint, Step, bool, bool) {            
    
        return (startBlock, endBlock, backersIndex.length, ethReceivedPresale.add(ethReceivedMain), maxCap, minCap, totalTokensSent, tokenPriceWei, currentStep, stopped, crowdsaleClosed);
    }

    // @notice in case refunds are needed, money can be returned to the contract
    function fundContract() external payable onlyOwner() returns (bool) {
        return true;
    }

    // @notice Specify address of token contract
    // @param _tokenAddress {address} address of token contract
    // @return res {bool}
    function updateTokenAddress(Token _tokenAddress) external onlyOwner() returns(bool res) {
        token = _tokenAddress;
        return true;
    }

    // @notice set the step of the campaign 
    // @param _step {Step}
    function setStep(Step _step) public onlyOwner() {
        currentStep = _step;
        
        if (currentStep == Step.FundingPreSale) {  // for presale 
          
            minInvestETH = 1 ether/5;                             
        }else if (currentStep == Step.FundingPublicSale) { // for public sale           
            minInvestETH = 1 ether/10;               
        }      
    }

    // {fallback function}
    // @notice It will call internal function which handels allocation of Ether and calculates tokens.
    function () external payable {           
        contribute(msg.sender);
    }

    // @notice It will be called by owner to start the sale    
    function start(uint _block) external onlyOwner() {   

        require(_block < 246528);  // 4.28*60*24*40 days = 246528     
        startBlock = block.number;
        endBlock = startBlock.add(_block); 
    }

    // @notice Due to changing average of block time
    // this function will allow on adjusting duration of campaign closer to the end 
    function adjustDuration(uint _block) external onlyOwner() {

        require(_block < 308160);  // 4.28*60*24*50 days = 308160     
        require(_block > block.number.sub(startBlock)); // ensure that endBlock is not set in the past
        endBlock = startBlock.add(_block); 
    }

    // @notice It will be called by fallback function whenever ether is sent to it
    // @param  _backer {address} address contributor
    // @return res {bool} true if transaction was successful
    function contribute(address _backer) internal stopInEmergency respectTimeFrame returns(bool res) {

        uint affiliateTokens;

        var(isWhiteListed, affiliate) = whiteList.isWhiteListedAndAffiliate(_backer);

        require(isWhiteListed);      // ensure that user is whitelisted
    
        require(currentStep == Step.FundingPreSale || currentStep == Step.FundingPublicSale); // ensure that this is correct step
        require(msg.value >= minInvestETH);   // ensure that min contributions amount is met
          
        uint tokensToSend = determinePurchase();

        if (affiliate != address(0)) {
            affiliateTokens = (tokensToSend * 5) / 100; // give 5% of tokens to affiliate
            affiliates[affiliate] += affiliateTokens;
            Backer storage referrer = backers[affiliate];
            referrer.tokensToSend = referrer.tokensToSend.add(affiliateTokens);
        }
        
        require(totalTokensSent.add(tokensToSend.add(affiliateTokens)) < maxCap); // Ensure that max cap hasn't been reached  
            
        Backer storage backer = backers[_backer];
    
        if (backer.tokensToSend == 0)      
            backersIndex.push(_backer);
           
        backer.tokensToSend = backer.tokensToSend.add(tokensToSend); // save contributors tokens to be sent
        backer.weiReceived = backer.weiReceived.add(msg.value);  // save how much was the contribution
        totalTokensSent += tokensToSend + affiliateTokens;     // update the total amount of tokens sent
        totalAffiliateTokensSent += affiliateTokens;
    
        if (Step.FundingPublicSale == currentStep)  // Update the total Ether recived
            ethReceivedMain = ethReceivedMain.add(msg.value);
        else
            ethReceivedPresale = ethReceivedPresale.add(msg.value);     
       
        multisig.transfer(this.balance);   // transfer funds to multisignature wallet             
    
        ReceivedETH(_backer, affiliate, msg.value, tokensToSend, affiliateTokens); // Register event
        return true;
    }


    // @notice determine if purchase is valid and return proper number of tokens
    // @return tokensToSend {uint} proper number of tokens based on the timline     
    function determinePurchase() internal view  returns (uint) {
       
        require(msg.value >= minInvestETH);                        // ensure that min contributions amount is met  
        uint tokenAmount = msg.value.mul(1e18) / tokenPriceWei;    // calculate amount of tokens

        uint tokensToSend;  

        if (currentStep == Step.FundingPreSale)
            tokensToSend = calculateNoOfTokensToSend(tokenAmount); 
        else
            tokensToSend = tokenAmount;
                                                                                                       
        return tokensToSend;
    }

    // @notice This function will return number of tokens based on time intervals in the campaign
    // @param _tokenAmount {uint} amount of tokens to allocate for the contribution
    function calculateNoOfTokensToSend(uint _tokenAmount) internal view  returns (uint) {
              
        if (block.number <= startBlock + (numOfBlocksInMinute * 60 * 24 * 14) / 100)        // less equal then/equal 14 days
            return  _tokenAmount + (_tokenAmount * 40) / 100;  // 40% bonus
        else if (block.number <= startBlock + (numOfBlocksInMinute * 60 * 24 * 28) / 100)   // less equal  28 days
            return  _tokenAmount + (_tokenAmount * 30) / 100; // 30% bonus
        else
            return  _tokenAmount + (_tokenAmount * 20) / 100;   // remainder of the campaign 20% bonus
          
    }

    // @notice erase contribution from the database and do manual refund for disapproved users
    // @param _backer {address} address of user to be erased
    function eraseContribution(address _backer) external onlyOwner() {

        Backer storage backer = backers[_backer];        
        backer.refunded = true;
        
    }

    // @notice allow on manual addition of contributors
    // @param _backer {address} of contributor to be added
    // @parm _amountTokens {uint} tokens to be added
    function addManualContributor(address _backer, uint _amountTokens) external onlyOwner() {

        Backer storage backer = backers[_backer];        
        backer.tokensToSend = backer.tokensToSend.add(_amountTokens);
        if (backer.tokensToSend == 0)      
            backersIndex.push(_backer);
    }


    // @notice contributors can claim tokens after public ICO is finished
    // tokens are only claimable when token address is available and lock-up period reached. 
    function claimTokens() external {
        claimTokensForUser(msg.sender);
    }

    // @notice this function can be called by admin to claim user's token in case of difficulties
    // @param _backer {address} user address to claim tokens for
    function adminClaimTokenForUser(address _backer) external onlyOwner() {
        claimTokensForUser(_backer);
    }

    // @notice in case refunds are needed, money can be returned to the contract
    // and contract switched to mode refunding
    function prepareRefund() public payable onlyOwner() {
        
        require(msg.value == ethReceivedMain + ethReceivedPresale); // make sure that proper amount of ether is sent
        currentStep == Step.Refunding;
    }

    // @notice return number of contributors
    // @return  {uint} number of contributors   
    function numberOfBackers() public view returns(uint) {
        return backersIndex.length;
    }
 
    // @notice called to send tokens to contributors after ICO and lockup period. 
    // @param _backer {address} address of beneficiary
    // @return true if successful
    function claimTokensForUser(address _backer) internal returns(bool) {       

        require(currentStep == Step.Claiming);
                  
        Backer storage backer = backers[_backer];

        require(!backer.refunded);      // if refunded, don't allow for another refund           
        require(!backer.claimed);       // if tokens claimed, don't allow refunding            
        require(backer.tokensToSend != 0);   // only continue if there are any tokens to send           

        claimCount++;
        claimed[_backer] = backer.tokensToSend;  // save claimed tokens
        backer.claimed = true;
        totalClaimed += backer.tokensToSend;
        
        if (!token.transfer(_backer, backer.tokensToSend)) 
            revert(); // send claimed tokens to contributor account

        TokensClaimed(_backer, backer.tokensToSend);  
    }


    // @notice This function will finalize the sale.
    // It will only execute if predetermined sale time passed or all tokens are sold.
    // it will fail if minimum cap is not reached
    function finalize() external onlyOwner() {

        require(!crowdsaleClosed);        
        // purchasing precise number of tokens might be impractical, thus subtract 1000 tokens so finalizition is possible
        // near the end 
        require(block.number >= endBlock || totalTokensSent >= maxCap.sub(1000));                 
        require(totalTokensSent >= minCap);  // ensure that minimum was reached
        uint teamTokens = 45000000e18;

        crowdsaleClosed = true;  
        
        if (!token.transfer(team, teamTokens)) // transfer all remaing tokens to team address
            revert();

        if (!token.burn(this, token.balanceOf(this) - teamTokens - totalTokensSent)) // burn tokens
            revert();  
        token.unlock();                      
    }

    // @notice Failsafe drain
    function drain() external onlyOwner() {
        multisig.transfer(this.balance);               
    }

    // @notice Failsafe token transfer
    function tokenDrian() external onlyOwner() {
        if (block.number > endBlock) {
            if (!token.transfer(team, token.balanceOf(this))) 
                revert();
        }
    }
    
    // @notice it will allow contributors to get refund in case campaign failed
    function refund() external stopInEmergency returns (bool) {

        require(currentStep == Step.Refunding);         
       
        require(this.balance > 0);  // contract will hold 0 ether at the end of campaign.                                  
                                    // contract needs to be funded through fundContract() 

        Backer storage backer = backers[msg.sender];

        require(backer.weiReceived > 0);  // esnure that user has sent contribution
        require(!backer.refunded);         // ensure that user hasn't been refunded yet        
        backer.refunded = true;  // save refund status to true
    
        refundCount++;
        totalRefunded = totalRefunded.add(backer.weiReceived);
        msg.sender.transfer(backer.weiReceived);  // send back the contribution 
        RefundETH(msg.sender, backer.weiReceived);
        return true;
    }
}


contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public view returns(uint);

    function allowance(address owner, address spender) public view returns(uint);

    function transfer(address to, uint value) public returns(bool ok);

    function transferFrom(address from, address to, uint value) public returns(bool ok);

    function approve(address spender, uint value) public returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}




// The token
contract Token is ERC20, Ownable {

    using SafeMath for uint;
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals; // How many decimals to show.
    string public version = "v0.1";       
    uint public totalSupply;
    bool public locked;
    address public crowdSaleAddress;
    


    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // tokens are locked during the ICO. Allow transfer of tokens after ICO. 
    modifier onlyUnlocked() {
        if (msg.sender != crowdSaleAddress && locked) 
            revert();
        _;
    }

    // allow burning of tokens only by authorized users 
    modifier onlyAuthorized() {
        if (msg.sender != owner && msg.sender != crowdSaleAddress) 
            revert();
        _;
    }

    // The Token 
    function Token(address _crowdSaleAddress) public {
        
        locked = true;  // Lock the Crowdsale function during the crowdsale
        totalSupply = 300000000e18; 
        name = "Truegame"; // Set the name for display purposes
        symbol = "TGAME"; // Set the symbol for display purposes
        decimals = 18; // Amount of decimals for display purposes
        crowdSaleAddress = _crowdSaleAddress;
        balances[crowdSaleAddress] = totalSupply;
    }

    function unlock() public onlyAuthorized {
        locked = false;
    }

    function lock() public onlyAuthorized {
        locked = true;
    }
    
    function burn( address _member, uint256 _value) public onlyAuthorized returns(bool) {
        balances[_member] = balances[_member].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Transfer(_member, 0x0, _value);
        return true;
    }

    function returnTokens(address _member, uint256 _value) public onlyAuthorized returns(bool) {
        balances[_member] = balances[_member].sub(_value);
        balances[crowdSaleAddress] = balances[crowdSaleAddress].add(_value);
        Transfer(_member, crowdSaleAddress, _value);
        return true;
    }

    function transfer(address _to, uint _value) public onlyUnlocked returns(bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public onlyUnlocked returns(bool success) {
        require(balances[_from] >= _value); // Check if the sender has enough                            
        require(_value <= allowed[_from][msg.sender]); // Check if allowed is greater or equal        
        balances[_from] = balances[_from].sub(_value); // Subtract from the sender
        balances[_to] = balances[_to].add(_value); // Add the same to the recipient
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns(uint balance) {
        return balances[_owner];
    }


    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint remaining) {
        return allowed[_owner][_spender];
    }

    /**
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}



