// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Workshop faucet
 * @author Deutsche Telekom MMS GmbH
 */
contract Faucet is ReentrancyGuard, Ownable {
    
    uint256 private constant WAITING_PERIOD = 1 minutes;

    mapping(address => uint256) private lastCalls;
    uint256 public withdrawableValue;

    event FundFaucet(uint256 indexed _value);
    event NextPossibleRequest(uint256 indexed _unixTimestamp);
    event UpdateWithdrawValue(uint256 indexed _value);

    error FaucetOutOfFunds(uint256 withdrawAmount, uint256 availableAmount);
    error TooManyRequests();
    error TransferEther(string message);
    
    /**
     * 
     * @param _owner Owner of the contract 
     * @param _withdrawableValue Value which can be withdrawn by one request
     */
    constructor(address payable _owner, uint256 _withdrawableValue) payable Ownable(_owner){
        withdrawableValue = _withdrawableValue;
    }

    /**
     * Fund faucet
     */
    function fundFaucet() external payable {
        emit FundFaucet(msg.value);
    }

    /**
     * Update the amount which can be withdrawn by users
     * 
     * @param _value New withdrawable value
     */
    function updateWithdrawableValue(uint256 _value) external onlyOwner {
        withdrawableValue = _value;
        emit UpdateWithdrawValue(_value);
    }

    /**
     * Send the globally specified amount of Ether to the caller of the function
     */
    function requestEther() external payable nonReentrant {
        if (address(this).balance < withdrawableValue) {
            revert FaucetOutOfFunds(withdrawableValue, address(this).balance);
        }
        uint256 lastCall = getLastCall();
        if ((lastCall + WAITING_PERIOD) >= block.timestamp && lastCall != 0) {
            revert TooManyRequests();
        }
        lastCalls[msg.sender] = uint64(block.timestamp);
        (bool isCallSuccessful, ) = msg.sender.call{value: withdrawableValue}("");
        if (!isCallSuccessful) {
            revert TransferEther("Transfering Ether failed");
        }
        emit NextPossibleRequest(_getUnixTimestampForNextPossibleRequest());
    }

    /**
     * Get unix timestamp for the callers last withdrew
     */
    function getLastCall() public view returns(uint256) {
        return lastCalls[msg.sender];
    }

    /**
     * Calculate unix timstamp when next request is possible
     */
    function _getUnixTimestampForNextPossibleRequest() private view returns(uint256) {
        uint256 nextPossibleRequest = block.timestamp + WAITING_PERIOD;
        return nextPossibleRequest;
    }
}
