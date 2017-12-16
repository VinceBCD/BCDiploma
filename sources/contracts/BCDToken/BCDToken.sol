pragma solidity ^0.4.18;

import './SafeMath.sol';
import './WhitelistsRegistration.sol';
import './VestedToken.sol';

/**
 * @title BCDToken
 * @dev The BCDT crowdsale
 */
contract BCDToken is VestedToken, WhitelistsRegistration {
    
    string public constant name = "Blockchain Certified Data Token";
    string public constant symbol = "BCDT";
    uint public constant decimals = 18;

    // Maximum contribution in ETH for silver whitelist 
    uint private constant MAX_ETHER_FOR_SILVER_WHITELIST = 10 ether;
    
    // ETH/BCDT rate
    uint public rateETH_BCDT = 8000;

    // Soft cap, if not reached contributors can withdraw their ethers
    uint public softCap = 3200 ether;

    // Cap in ether of presale
    uint public presaleCap = 3200 ether;
    
    // Cap in ether of Round 1 (presale cap + 3200 ETH)
    uint public round1Cap = 6400 ether;    
    
    // BCD Reserve/Community Wallets
    address public reserveAddress;
    address public communityAddress;

    // Different stage from the ICO
    enum State {
        // ICO isn't started yet, initial state
        Init,
        // Presale has started
        PresaleRunning,
        // Presale has ended
        PresaleFinished,
        // Round 1 has started
        Round1Running,
        // Round 1 has ended
        Round1Finished,
        // Round 2 has started
        Round2Running,
        // Round 2 has ended
        Round2Finished
    }
    
    // Initial state is Init
    State public currentState = State.Init;
    
    // BCDT total supply
    uint256 public totalSupply = MAX_TOTAL_BCDT_TO_SELL;

    // How much tokens have been sold
    uint256 public tokensSold;
    
    // Amount of ETH raised during ICO
    uint256 private etherRaisedDuringICO;
    
    // Maximum total of BCDT Token sold during ITS
    uint private constant MAX_TOTAL_BCDT_TO_SELL = 100000000 * 1 ether;

    // Token allocation per mille for reserve/community/founders
    uint private constant RESERVE_ALLOCATION_PER_MILLE_RATIO =  200;
    uint private constant COMMUNITY_ALLOCATION_PER_MILLE_RATIO =  103;
    uint private constant FOUNDERS_ALLOCATION_PER_MILLE_RATIO =  30;
    
    // List of contributors/contribution in ETH
    mapping(address => uint256) contributors;

    // Use to allow function call only if currentState is the one specified
    modifier onlyInState(State _state)
    {
        require(_state == currentState); 
        _; 
    }
    
    // Event call when aside tokens are minted
    event AsideTokensHaveBeenAllocated(address indexed to, uint256 amount);
    // Event call when a contributor withdraw his ethers
    event Withdraw(address indexed to, uint256 amount);
    // Event call when ICO state change
    event StateChanged(uint256 timestamp, State currentState);

    // Constructor
    function BCDToken() public {
    }

    function() public payable {
        require(currentState == State.PresaleRunning || currentState == State.Round1Running || currentState == State.Round2Running);

        // min transaction is 0.1 ETH
        if (msg.value < 100 finney) { revert(); }

        // If you're not in any whitelist, you cannot continue
        if (!silverWhiteList[msg.sender] && !goldWhiteList[msg.sender]) {
            revert();
        }

        // ETH sent by contributor
        uint256 ethSent = msg.value;
        
        // how much ETH will be used for contribution
        uint256 ethToUse = ethSent;

        // Address is only in the silver whitelist: contribution is capped
        if (!goldWhiteList[msg.sender]) {
            // Check if address has already contributed for maximum allowance
            if (contributors[msg.sender] >= MAX_ETHER_FOR_SILVER_WHITELIST) {
                revert();
            }
            // limit the total contribution to MAX_ETHER_FOR_SILVER_WHITELIST
            if (contributors[msg.sender].add(ethToUse) > MAX_ETHER_FOR_SILVER_WHITELIST) {
                ethToUse = MAX_ETHER_FOR_SILVER_WHITELIST.sub(contributors[msg.sender]);
            }
        }
        
         // Calculate how much ETH are available for this stage
        uint256 ethAvailable = getRemainingEthersForCurrentRound();
        uint rate = getBCDTRateForCurrentRound();

        // If cap of the round has been reached
        if (ethAvailable <= ethToUse) {
            // End the round
            privateSetState(getEndedStateForCurrentRound());
            // Only available ethers will be used to reach the cap
            ethToUse = ethAvailable;
        }
        
        // Calculate token amount to send in accordance to rate
        uint256 tokenToSend = ethToUse.mul(rate);
        
        // Amount of tokens sold to the current contributors is added to total sold
        tokensSold = tokensSold.add(tokenToSend);
        // Amount of ethers used for the current contribution is added the total raised
        etherRaisedDuringICO = etherRaisedDuringICO.add(ethToUse);
        // Token balance updated for current contributor
        balances[msg.sender] = balances[msg.sender].add(tokenToSend);
        // Contribution is stored for an potential withdraw
        contributors[msg.sender] = contributors[msg.sender].add(ethToUse);
        
        // Send back the unused ethers        
        if (ethToUse < ethSent) {
            msg.sender.transfer(ethSent.sub(ethToUse));
        }
        // Log token transfer operation
        Transfer(0x0, msg.sender, tokenToSend); 
    }

    // Allow contributors to withdraw after the end of the ICO if the softcap hasn't been reached
    function withdraw() public onlyInState(State.Round2Finished) {
        // Only contributors with positive ETH balance could Withdraw
        if(contributors[msg.sender] == 0) { revert(); }
        
        // Withdraw is possible only if softcap has not been reached
        require(etherRaisedDuringICO < softCap);
        
        // Get how much ethers sender has contribute
        uint256 ethToSendBack = contributors[msg.sender];
        
        // Set contribution to 0 for the contributor
        contributors[msg.sender] = 0;
        
        // Send back ethers
        msg.sender.transfer(ethToSendBack);
        
        // Log withdraw operation
        Withdraw(msg.sender, ethToSendBack);
    }

    // At the end of the sale, mint the aside tokens for the reserve, community and founders
    function mintAsideTokens() public onlyOwner onlyInState(State.Round2Finished) {

        // Reserve, community and founders address have to be set before mint aside tokens
        require((reserveAddress != 0x0) && (communityAddress != 0x0) && (reserveAddress != 0x0));

        // Aside tokens can be minted only if softcap is reached
        require(this.balance >= softCap);

        // Revert if aside tokens have already been minted 
        if (asideTokensHaveBeenMinted) { revert(); }

        // Set minted flag and date
        asideTokensHaveBeenMinted = true;
        asideTokensMintDate = now;

        // If 100M sold, 50M more have to be mint (15 / 10 = * 1.5 = +50%)
        totalSupply = tokensSold.mul(15).div(10);

        // 20% of total supply is allocated to reserve
        uint256 _amountMinted = setAllocation(reserveAddress, RESERVE_ALLOCATION_PER_MILLE_RATIO);

        // 10.3% of total supply is allocated to community
        _amountMinted = _amountMinted.add(setAllocation(communityAddress, COMMUNITY_ALLOCATION_PER_MILLE_RATIO));

        // 3% of total supply is allocated to founders
        _amountMinted = _amountMinted.add(setAllocation(vestedAddress, FOUNDERS_ALLOCATION_PER_MILLE_RATIO));
        
        // the allocation is only 33.3%*150/100 = 49.95% of the token solds. It is therefore slightly higher than it should.
        // to avoid that, we correct the real total number of tokens
        totalSupply = tokensSold.add(_amountMinted);
        // Send the eth to the owner of the contract
        owner.transfer(this.balance);
    }
    
    function setTokenAsideAddresses(address _reserveAddress, address _communityAddress, address _founderAddress) public onlyOwner {
        require(_reserveAddress != 0x0 && _communityAddress != 0x0 && _founderAddress != 0x0);

        // Revert when aside tokens have already been minted 
        if (asideTokensHaveBeenMinted) { revert(); }

        reserveAddress = _reserveAddress;
        communityAddress = _communityAddress;
        vestedAddress = _founderAddress;
    }
    
    function updateCapsAndRate(uint _presaleCapInETH, uint _round1CapInETH, uint _softCapInETH, uint _rateETH_BCDT) public onlyOwner onlyInState(State.Init) {
            
        // Caps and rate are updatable until ICO starts
        require(_round1CapInETH > _presaleCapInETH);
        require(_rateETH_BCDT != 0);
        
        presaleCap = _presaleCapInETH * 1 ether;
        round1Cap = _round1CapInETH * 1 ether;
        softCap = _softCapInETH * 1 ether;
        rateETH_BCDT = _rateETH_BCDT;
    }
    
    function getRemainingEthersForCurrentRound() public constant returns (uint) {
        require(currentState != State.Init); 
        require(!asideTokensHaveBeenMinted);
        
        if((currentState == State.PresaleRunning) || (currentState == State.PresaleFinished)) {
            // Presale cap is fixed in ETH
            return presaleCap.sub(etherRaisedDuringICO);
        }
        if((currentState == State.Round1Running) || (currentState == State.Round1Finished)) {
            // Round 1 cap is fixed in ETH
            return round1Cap.sub(etherRaisedDuringICO);
        }
        if((currentState == State.Round2Running) || (currentState == State.Round2Finished)) {
            // Round 2 cap is limited in tokens, 
            uint256 remainingTokens = totalSupply.sub(tokensSold);
            // ETH available is calculated from the number of remaining tokens regarding the rate
            return remainingTokens.div(rateETH_BCDT);
        }        
    }   

    function getBCDTRateForCurrentRound() public constant returns (uint) {
        require(currentState == State.PresaleRunning || currentState == State.Round1Running || currentState == State.Round2Running);              
        
        // ETH/BCDT rate during presale: 20% bonus
        if(currentState == State.PresaleRunning) {
            return rateETH_BCDT + rateETH_BCDT * 20 / 100;
        }
        // ETH/BCDT rate during presale: 10% bonus
        if(currentState == State.Round1Running) {
            return rateETH_BCDT + rateETH_BCDT * 10 / 100;
        }
        if(currentState == State.Round2Running) {
            return rateETH_BCDT;
        }        
    }  

    function setState(State _newState) public onlyOwner {
        privateSetState(_newState);
    }
    
    function privateSetState(State _newState) private {
        // no way to go back    
        if(_newState <= currentState) { revert(); }
        
        currentState = _newState;
        StateChanged(now, currentState);
    }
    
    
    function getEndedStateForCurrentRound() private constant returns (State) {
        require(currentState == State.PresaleRunning || currentState == State.Round1Running || currentState == State.Round2Running);
        
        if(currentState == State.PresaleRunning) {
            return State.PresaleFinished;
        }
        if(currentState == State.Round1Running) {
            return State.Round1Finished;
        }
        if(currentState == State.Round2Running) {
            return State.Round2Finished;
        }        
    }   

    function setAllocation(address _to, uint _ratio) private onlyOwner returns (uint256) {
        // Aside token is a percentage of totalSupply
        uint256 tokenAmountToTransfert = totalSupply.mul(_ratio).div(1000);
        balances[_to] = balances[_to].add(tokenAmountToTransfert);
        AsideTokensHaveBeenAllocated(_to, tokenAmountToTransfert);
        Transfer(0x0, _to, tokenAmountToTransfert);
        return tokenAmountToTransfert;
    }
}