pragma solidity ^0.4.11;

import "./SafeMath.sol";
import "./MultiOwnable.sol";
import "./ACO.sol";


contract Crowdsale is MultiOwnable {

    using SafeMath for uint256;

    ACO public ACO_Token;

    bool private success;
    uint256 private rate;
    uint256 private rateWithBonus;
    uint256 public tokensSold;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public minimumGoal;
    uint256 public cap;
    uint256[4] private bonusStages;

    mapping (address => uint256) investments;
    mapping (address => bool) hasAuthorizedWithdrawal;

    event TokensPurchased(address indexed by, uint256 amount);
    event RefundIssued(address indexed by, uint256 amount);
    event FundsWithdrawn(address indexed by, uint256 amount);
    event IcoSuccess();
    event CapReached();

    function Crowdsale() public {
        ACO_Token = new ACO();
        minimumGoal = 1000 ether;
        cap = 2000 ether;
        rate = 4000;
        startTime = now;
        endTime = startTime.add(10 minutes);
        bonusStages[0] = startTime.add(2 minutes);

        for (uint i = 1; i < bonusStages.length; i++) {
            bonusStages[i] = bonusStages[i - 1].add(2 minutes);
        }
    }

    /**
     * Fallback function calls the buyTokens function when ETH is sent to this 
     * contact.
     * */
    function() public payable {
        buyTokens(msg.sender);
    }

    /**
     * Allows investors to buy ACO tokens. Once ETH is sent to this contract, 
     * the investor will automatically receive tokens. 
     * 
     * @param _beneficiary The address the newly minted tokens will be sent to.
     * */
    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != 0x0 && validPurchase() && this.balance.sub(msg.value) < cap);
        if (this.balance >= minimumGoal && !success) {
            success = true;
            IcoSuccess();
        }
        uint256 weiAmount = msg.value;
        if (this.balance > cap) {
            CapReached();
            uint256 toRefund = this.balance.sub(cap);
            msg.sender.transfer(toRefund);
            weiAmount = weiAmount.sub(toRefund);
        }
        uint256 tokens = weiAmount.mul(getCurrentRateWithBonus());
        ACO_Token.mint(_beneficiary, tokens);
        tokensSold = tokensSold.add(tokens);
        investments[_beneficiary] = investments[_beneficiary].add(weiAmount);
        TokensPurchased(_beneficiary, tokens);
    }

    /**
     * Returns the amount of tokens 1 ETH equates to with the bonus percentage.
     * */
    function getCurrentRateWithBonus() public returns (uint256) {
        rateWithBonus = (rate.mul(getBonusPercentage()).div(100)).add(rate);
        return rateWithBonus;
    }

    /**
     * Calculates and returns the bonus percentage based on how early an investment
     * is made. If ETH is sent to the contract after the bonus period, the bonus 
     * percentage will default to 0
     * */
    function getBonusPercentage() internal view returns (uint256 bonusPercentage) {
        uint256 timeStamp = now;
        if (timeStamp > bonusStages[3]) {
            bonusPercentage = 0;
        } else { 
            bonusPercentage = 25;
            for (uint i = 0; i < bonusStages.length; i++) {
                if (timeStamp <= bonusStages[i]) {
                    break;
                } else {
                    bonusPercentage = bonusPercentage.sub(5);
                }
            }
        }
        return bonusPercentage;
    }

    /**
     * Returns the current rate 1 ETH equates to including the bonus amount. 
     * */
    function currentRate() public constant returns (uint256) {
        return rateWithBonus;
    }

    /**
     * Checks whether an incoming transaction from the buyTokens function is 
     * valid or not. For a purchase to be valid, investors have to buy tokens
     * only during the ICO period and the value being transferred must be greater
     * than 0.
     * */
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }
    
    /**
     * Issues a refund to a given address. This function can only be called if
     * the duration of the ICO has ended and the minimum goal has not been reached.
     * 
     * @param _addr The address that will receive a refund. 
     * */
    function getRefund(address _addr) public {
        require(!isSuccess() && hasEnded() && investments[_addr] > 0);
        if (_addr == 0x0) {
            _addr = msg.sender;
        }
        uint256 toRefund = investments[_addr];
        investments[_addr] = 0;
        _addr.transfer(toRefund);
        RefundIssued(_addr, toRefund);
    }

    /**
     * This function can only be called by the onwers of the ICO contract. There 
     * needs to be 2 approvals, one from each owner. Once two approvals have been 
     * made, the funds raised will be sent to one of the owners accounts. This 
     * function cannot be called if the ICO is not a success.
     * */
    function authorizeWithdrawal() public onlyOwners {
        require(hasEnded() && isSuccess() && !hasAuthorizedWithdrawal[msg.sender]);
        hasAuthorizedWithdrawal[msg.sender] = true;
        if (hasAuthorizedWithdrawal[owners[0]] && hasAuthorizedWithdrawal[owners[1]]) {
            FundsWithdrawn(owners[0], this.balance);
            owners[0].transfer(this.balance);
        }
    }
    
    /**
     * Generates newly minted ACO tokens and sends them to a given address. This 
     * function can only be called by the owners of the ICO contract during the 
     * minting period.
     * 
     * @param _to The address to mint new tokens to.
     * @param _amount The amount of tokens to mint.
     * */
    function issueBounty(address _to, uint256 _amount) public onlyOwners {
        require(_to != 0x0 && _amount > 0);
        ACO_Token.mint(_to, _amount);
    }
    
    /**
     * Terminates the minting period permanently. This function can only be 
     * executed by the owners of the ICO contract. 
     * */
    function finishMinting() public onlyOwners {
        require(hasEnded());
        ACO_Token.finishMinting();
    }

    /**
     * Returns the minimum goal of the ICO.
     * */
    function minimumGoal() public constant returns (uint256) {
        return minimumGoal;
    }

    /**
     * Returns the maximum amount of funds the ICO can receive.
     * */
    function cap() public constant returns (uint256) {
        return cap;
    }

    /**
     * Returns the time that the ICO duration will end.
     * */
    function endTime() public constant returns (uint256) {
        return endTime;
    }

    /**
     * Returns the amount of ETH a given address has invested.
     * 
     * @param _addr The address to query the investment of. 
     * */
    function investmentOf(address _addr) public constant returns (uint256) {
        return investments[_addr];
    }

    /**
     * Returns true if the duration of the ICO is over.
     * */
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }

    /**
     * Returns true if the ICO is a success.
     * */
    function isSuccess() public constant returns (bool) {
        return success;
    }

    /**
     * Returns the amount of ETH raised in wei.
     * */
    function weiRaised() public constant returns (uint256) {
        return this.balance;
    }
}
