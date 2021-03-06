pragma solidity ^0.4.11;


import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract ACO is ERC20, Ownable {
    
    using SafeMath for uint256;

    bool public mintingFinished;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
  
    event Mint(address indexed to, uint256 amount);
    event MintingFinished();

    function ACO() public {
        totalSupply = 0;
        decimals = 18;
        name = "ACO";
        symbol = "ACO";
    }

    /**
     * Returns the balance of a given address.
     * 
     * @param _addr The address of the balance to query.
     **/
    function balanceOf(address _addr) public constant returns (uint256) {
        return balances[_addr];
    }

    /**
     * Transfers ACO tokens from the sender's account to another given account.
     * 
     * @param _to The address of the recipient.
     * @param _amount The amount of tokens to send.
     * */
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    /**
     * Allows another account to spend a given amount of tokens on behalf of the 
     * sender's account.
     * 
     * @param _spender The address of the spenders account.
     * @param _amount The amount of tokens the spender is allowed to spend.
     * */
    function approve(address _spender, uint256 _amount) public returns (bool) {
        allowances[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    /**
     * Increases the amount a given account can spend on behalf of the sender's 
     * account.
     * 
     * @param _spender The address of the spenders account.
     * @param _amount The amount of tokens the spender is allowed to spend.
     * */
    function increaseApproval(address _spender, uint256 _amount) public returns (bool) {
        allowances[msg.sender][_spender] = allowances[msg.sender][_spender].add(_amount);
        Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

    /**
     * Decreases the amount of tokens a given account can spend on behalf of the 
     * sender's account.
     * 
     * @param _spender The address of the spenders account.
     * @param _amount The amount of tokens the spender is allowed to spend.
     * */
    function decreaseApproval(address _spender, uint256 _amount) public returns (bool) {
        require(allowances[msg.sender][_spender] != 0);
        if(_amount >= allowances[msg.sender][_spender]) {
            allowances[msg.sender][_spender] = 0;
        } else {
            allowances[msg.sender][_spender] = allowances[msg.sender][_spender].sub(_amount);
            Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        }
    }
    
    /**
     * Returns the approved allowance from an owners account to a spenders account.
     * 
     * @param _owner The address of the owners account.
     * @param _spender The address of the spenders account.
     **/
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowances[_owner][_spender];
    }
    
    /**
     * Transfers tokens from the account of the owner by an approved spender. 
     * The spender cannot spend more than the approved amount. 
     * 
     * @param _from The address of the owners account.
     * @param _amount The amount of tokens to transfer.
     * */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(allowances[_from][msg.sender] >= _amount && balances[_from] >= _amount);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_amount);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

    /**
     * Generates new ACO tokens during the ICO, after which the minting period 
     * will terminate permenantly. This function can only be called by the ICO 
     * contract.
     * 
     * @param _to The address of the account to mint new tokens to.
     * @param _amount The amount of tokens to mint. 
     * */
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        require(_to != 0x0 && _amount > 0 && !mintingFinished);
        balances[_to] = balances[_to].add(_amount);
        totalSupply = totalSupply.add(_amount);
        Mint(_to, _amount);
    }

    /**
     * Terminates the minting period permenantly. This function can only be called
     * by the ICO contract only when the duration of the ICO has ended. 
     * */
    function finishMinting() external onlyOwner {
        require(!mintingFinished);
        mintingFinished = true;
        MintingFinished();
    }
    
    /**
     * Returns true if the minting period has ended, false otherwhise.
     * */
    function mintingFinished() public constant returns (bool) {
        return mintingFinished;
    }
}
