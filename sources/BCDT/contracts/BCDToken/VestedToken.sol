pragma solidity ^0.4.19;

import './SafeMath.sol';
import './Ownable.sol';

/**
 * @title VestedToken
 * @dev The VestedToken contract implements ERC20 standard basics function and 
 * - vesting for an address
 * - token tradability delay
 */
contract VestedToken {
    using SafeMath for uint256;
    
    // Vested wallet address
    address public vestedAddress;
    // Vesting time
    uint private constant VESTING_DELAY = 1 years;  
    // Token will be tradable TOKEN_TRADABLE_DELAY after 
    uint private constant TOKEN_TRADABLE_DELAY = 12 days;

    // True if aside tokens have already been minted after second round
    bool public asideTokensHaveBeenMinted = false;
    // When aside tokens have been minted ?
    uint public asideTokensMintDate;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    modifier transferAllowed { require(asideTokensHaveBeenMinted && now > asideTokensMintDate + TOKEN_TRADABLE_DELAY); _; }
    
    // Get the balance from an address
    function balanceOf(address _owner) public constant returns (uint256) { return balances[_owner]; }  

    // transfer ERC20 function
    function transfer(address _to, uint256 _value) transferAllowed public returns (bool success) {
        require(_to != 0x0);
        
        // founders wallets is blocked 1 year
        if (msg.sender == vestedAddress && (now < (asideTokensMintDate + VESTING_DELAY))) { revert(); }

        return privateTransfer(_to, _value);
    }

    // transferFrom ERC20 function
    function transferFrom(address _from, address _to, uint256 _value) transferAllowed public returns (bool success) {
        require(_from != 0x0);
        require(_to != 0x0);
        
        // founders wallet is blocked 1 year
        if (_from == vestedAddress && (now < (asideTokensMintDate + VESTING_DELAY))) { revert(); }

        uint256 _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        
        return true;
    }

    // approve ERC20 function
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        
        return true;
    }

    // allowance ERC20 function
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function privateTransfer (address _to, uint256 _value) private returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    // Events ERC20
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}