// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import { Faucet } from "contracts/Faucet.sol";

contract FaucetTestSetup is Test {
    uint256 constant INITIAL_BALANCE = 10e18;
    uint256 constant INITIAL_WITHDRAWAL_VALUE = 1e17;

    Faucet faucet;
    address payable alice;
    
    function setUp() public {
        alice = payable(makeAddr("alice"));
        faucet = new Faucet{value: INITIAL_BALANCE}(alice, INITIAL_WITHDRAWAL_VALUE);
    }
}

contract Construtor is FaucetTestSetup {
    function test_InitialBalanceIsSetCorrectly() view public {
        uint256 contractBalance = address(faucet).balance;
        assertEq(contractBalance, INITIAL_BALANCE);
    }

    function test_OwnerIsSetCorrectly() view public {
        assertEq(faucet.owner(), alice);
    }

    function test_WithdrawalValueIsSetCorrectly() view public {
        assertEq(faucet.withdrawableValue(), INITIAL_WITHDRAWAL_VALUE);
    }
}

contract FundFaucetFunction is FaucetTestSetup {
    uint256 ADDITIONAL_FUNDS = 1e18;

    event FundFaucet(uint256 indexed _value);

    function test_AddAdditionalFunds() public {
        faucet.fundFaucet{value: ADDITIONAL_FUNDS}();
        uint256 contractBalance = address(faucet).balance;
        assertEq(contractBalance, INITIAL_BALANCE + ADDITIONAL_FUNDS);
    }

    function test_EmitFundFaucetEvent() public {
        vm.expectEmit(true, true, true, true);
        emit FundFaucet(ADDITIONAL_FUNDS);
        faucet.fundFaucet{value: ADDITIONAL_FUNDS}();
    }
}

contract UpdateWithdrawableValueFunction is FaucetTestSetup {
    uint256 NEW_WITHDRAWABLE_VALUE = 1e15;

    event UpdateWithdrawValue(uint256 indexed _value);

    error OwnableUnauthorizedAccount(address account);

    function test_UpdateWithdrawableValue() public {
        vm.prank(alice);
        faucet.updateWithdrawableValue(NEW_WITHDRAWABLE_VALUE);
        assertEq(faucet.withdrawableValue(), NEW_WITHDRAWABLE_VALUE);
    }

    function test_EmitUpdateWithdrawValueEvent() public {
        vm.expectEmit(true, true, true, true);
        emit UpdateWithdrawValue(NEW_WITHDRAWABLE_VALUE);
        vm.prank(alice);
        faucet.updateWithdrawableValue(NEW_WITHDRAWABLE_VALUE);
    }

    function test_RevertWhen_CallerIsNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(this)));
        faucet.updateWithdrawableValue(NEW_WITHDRAWABLE_VALUE);
    }
}

contract RequestEtherFunction is FaucetTestSetup {

    uint256 private constant WAITING_PERIOD = 1 minutes;
    string private constant TRANSFER_ETHER_ERROR_MESSAGE = "Transfering Ether failed";

    event NextPossibleRequest(uint256 indexed _unixTimestamp);

    error FaucetOutOfFunds(uint256 withdrawAmount, uint256 availableAmount);
    error TooManyRequests();
    error TransferEther(string message);

    function test_RequestEtherInitially() public payable {
        vm.expectEmit(true, true, true, true);
        emit NextPossibleRequest(block.timestamp + WAITING_PERIOD);
        vm.prank(alice);
        faucet.requestEther();
        assertEq(INITIAL_BALANCE - INITIAL_WITHDRAWAL_VALUE, address(faucet).balance);
        assertEq(INITIAL_WITHDRAWAL_VALUE, address(alice).balance);
    }

    function test_RequestEtherAfterWaitingPeriodElapsed() public payable {
        vm.expectEmit(true, true, true, true);
        emit NextPossibleRequest(uint32(block.timestamp + WAITING_PERIOD));
        vm.prank(alice);
        faucet.requestEther();
        vm.warp(block.timestamp + 61);
        vm.prank(alice);
        faucet.requestEther();
        assertEq(INITIAL_BALANCE - 2 * INITIAL_WITHDRAWAL_VALUE, address(faucet).balance);
        assertEq(2 * INITIAL_WITHDRAWAL_VALUE, address(alice).balance);
    }

    /**
     * Reverts because the caller is a foundry contract which does not have a fallback function implemented
     */
    function test_RevertWhen_TheCallFunctionFails() public {
        vm.expectRevert(abi.encodeWithSelector(TransferEther.selector, TRANSFER_ETHER_ERROR_MESSAGE));
        faucet.requestEther();
    }

    function test_RevertWhen_TheCallerDidNotWaitLongEnough() public {
        vm.prank(alice);
        faucet.requestEther();
        vm.expectRevert(abi.encodeWithSelector(TooManyRequests.selector));
        vm.warp(block.timestamp + 30);
        vm.prank(alice);
        faucet.requestEther();
    }

    function test_RevertWhen_TheFaucetIsOutOfFunds() public {
        uint256 numberOfLoops = INITIAL_BALANCE / INITIAL_WITHDRAWAL_VALUE;
        for(uint16 i=0; i<numberOfLoops; i++){ 
            vm.warp(block.timestamp + 61);
            vm.prank(alice);
            faucet.requestEther();
        }
        vm.expectRevert(abi.encodeWithSelector(FaucetOutOfFunds.selector, INITIAL_WITHDRAWAL_VALUE, address(faucet).balance));
        vm.prank(alice);
        faucet.requestEther();
    }
}
