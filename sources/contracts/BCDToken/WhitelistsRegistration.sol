pragma solidity ^0.4.18;

import './SafeMath.sol';
import './Ownable.sol';

/**
 * @title WhitelistsRegistration
 * @dev This is an extension to add 2 levels whitelists to the crowdsale
 */
contract WhitelistsRegistration is Ownable {
    // List of whitelisted addresses for KYC under 10 ETH
    mapping(address => bool) silverWhiteList;
    
    // List of whitelisted addresses for KYC over 10 ETH
    mapping(address => bool) goldWhiteList;
    
    // Different stage from the ICO
    enum WhiteListState {
        // This address is not whitelisted
        None,
        // this address is on the silver whitelist
        Silver,
        // this address is on the gold whitelist
        Gold
    }
    
    address public whiteLister;

    event SilverWhitelist(address indexed _address, bool _isRegistered);
    event GoldWhitelist(address indexed _address, bool _isRegistered);  
    event SetWhitelister(address indexed newWhiteLister);
    
    /**
    * @dev Throws if called by any account other than the owner or the whitelister.
    */
    modifier onlyOwnerOrWhiteLister() {
        require((msg.sender == owner) || (msg.sender == whiteLister));
    _;
    }
    
    // Return registration status of an specified address
    function checkRegistrationStatus(address _address) public constant returns (WhiteListState) {
        if (goldWhiteList[_address]) { return WhiteListState.Gold; }
        if (silverWhiteList[_address]) { return WhiteListState.Silver; }
        return WhiteListState.None;
    }
    
    // Change registration status for an address in the whitelist for KYC under 10 ETH
    function changeRegistrationStatusForSilverWhiteList(address _address, bool _isRegistered) public onlyOwnerOrWhiteLister {
        silverWhiteList[_address] = _isRegistered;
        SilverWhitelist(_address, _isRegistered);
    }
    
    // Change registration status for an address in the whitelist for KYC over 10 ETH
    function changeRegistrationStatusForGoldWhiteList(address _address, bool _isRegistered) public onlyOwnerOrWhiteLister {
        goldWhiteList[_address] = _isRegistered;
        GoldWhitelist(_address, _isRegistered);
    }
    
    // Change registration status for several addresses in the whitelist for KYC under 10 ETH
    function massChangeRegistrationStatusForSilverWhiteList(address[] _targets, bool _isRegistered) public onlyOwnerOrWhiteLister {
        for (uint i = 0; i < _targets.length; i++) {
            changeRegistrationStatusForSilverWhiteList(_targets[i], _isRegistered);
        }
    } 
    
    // Change registration status for several addresses in the whitelist for KYC over 10 ETH
    function massChangeRegistrationStatusForGoldWhiteList(address[] _targets, bool _isRegistered) public onlyOwnerOrWhiteLister {
        for (uint i = 0; i < _targets.length; i++) {
            changeRegistrationStatusForGoldWhiteList(_targets[i], _isRegistered);
        }
    }
    
    /**
    * @dev Allows the current owner or whiteLister to transfer control of the whitelist to a newWhitelister.
    * @param newWhitelister The address to transfer whitelist to.
    */
    function setWhitelister(address newWhiteLister) public onlyOwnerOrWhiteLister {
      require(newWhiteLister != address(0));
      SetWhitelister(newWhiteLister);
      whiteLister = newWhiteLister;
    }
}