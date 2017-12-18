# BCDiploma ICO’s specifications

## Structure
Contributors will need to whitelist their address to participate in the ICO.

2 whitelists are available:
* A silver whitelist, with a contribution limit of 10 ETH maximum.
* A "gold" whitelist, without contribution limit

The minimum transaction is 0.1 ETH.

100,000,000 BCDT tokens will go on sale. 

The ICO takes place in 3 rounds, with a contribution limit for each, and gives rise to different bonuses:
* The "presale", limited to 3200 ETH*, grant 20% more tokens at the time of the contribution.
* The "round 1", limited to the presale cap + 3200 ETH*, grant 10% more tokens during the contribution.
* The "round 2" does not give rise to a bonus, limited to the 100 000 000 tokens put up for sale. The ETH/BCDT rate is set at 8000*.

> *The amounts indicated may vary until the start of the ICO, to take into account change fluctuations.

If the cap is reached for each of these rounds, the round is automatically completed. Otherwise, the round can be completed manually by the owner of the smartcontract. As an indication, the maximum expected durations for each round are as follows:
* Presale: maximum duration of 4 weeks
* Round 1: maximum duration of one week
* Round 2: maximum duration of one week

50% more tokens will be minted  after the ICO (maximum 50,000,000 additional tokens) and distributed over 3 addresses as follows:
* 20% of the total tokens allocated to the BCD reserve.
* 10.3% of the total minted tokens allocated to the BCD support community (e. g.: advisors, non-founder's team, bounty program)
* 3% of the total minted tokens allocated to the founders, blocked for 1 year.
* 
No BCDT token will ever be created again.

The tokens will be movable 12 days after the creation of the additional tokens above.

## Operational course of the ICO
The smart contract of the ICO has 7 states corresponding to the different states of progress of the ICO: an initial state, and a current and finished state for each of the rounds.

Whatever the current state (currentState), it is possible for the owner:
* To whitelist addresses (WhitelistsRegistration contract methods)
* To change the state of progress to a later state (setState method of the BCDToken contract)
* Fill in the addresses to receive the additional tokens created after the end of round 2 if the softcap is reached (setTokenAsideAddresses method of the BCDToken contract)

When the status of the contract is at "PresaleRunning","Round1Running" or "Round2Running", contributors with their whitelisted address can send their ETH to the contract:
* within the limits of the ETH still available for the round
* limited to 10 ETH if they are not whitelisted "gold".

The smart contract is deployed in the initial "Init" state. It is possible in this state (and only in this state) to change the caps and rate, and to switch to the "PresaleRunning" state.

In PresaleRunning status, contributors will receive BCDT tokens plus 20% bonus compared to the no bonus rate.
The contract will change to the "PresaleFinished" status:
* automatically when the ETH cap of the presale is reached.
* manually to the call of the setState method by the owner

The owner will then be able to switch to the Round1Running status, during which contributors will receive BCDT tokens plus 10% bonus compared to the no bonus rate.

The contract will change to the "Round1Finished" status:
* automatically when the ETH cap of round 1 is reached.
* manually to the call of the setState method by the owner

The owner will then be able to switch to the Round2Running state, during which contributors will then receive BCDT tokens at the no bonus rate specified in rateETH_BCDT.

The contract will change to the "Round2Finished" status:
* automatically when the ICO's hard cap in tokens is reached (100 000 000)
* manually to the call of the setState method by the owner

At this moment, if the softcap is not reached, contributors will be able to retrieve their contributions through the withdraw method.

If the softcap is reached, the owner will call the mintAsideTokens method which will have the effect:
* create additional tokens 
* transfer funds raised during the ICO to the owner's wallet
* set a reference date/time for the tradability time of tokens and founders vesting. 


## Known behaviours
Are admitted:

* that you can remove from the whitelist an address that has already contributed
* that the caps (softcap, presale cap in ETH, round1 cap in ETH) and the ETH/BCDT rate can be updated until the start of the ICO
* that the timing of the different stages of the ICO is at the discretion of the owner of the contract, and therefore that a round or ICO can be completed before reaching the caps.
* that a contributor can create several different wallets and contribute several times less than 10 ETH by being whitelisted simply "silver".
* that the softCap is not reached, the smart contract does not guarantee that the contributors will get their funds back, it just guarantees that the owner of the contract won’t receive them
* that the cap of round 1 is fixed in ETH regardless of the amount raised in front of it.

## Description of the modules

SafeMath.sol and Ownable.sol are based on the open source openzeppelin framework.

WhitelistsRegistration.sol, developed by BCD, inherits Ownable and allows management of the double whitelist by the owner and by another address

VestedToken. sol, developed by BCD implements the ERC-20 interface methods by introducing a token tradablity and vesting delay on an address (in this case, founders one)

BCDToken. sol, developed by BCD, inherits from VestedToken and WhitelistsRegistration and implements the ICO workflow.