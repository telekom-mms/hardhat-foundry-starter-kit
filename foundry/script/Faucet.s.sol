// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Faucet} from "contracts/Faucet.sol";

contract FaucetDeploymentScript is Script {

    uint256 constant INITIAL_BALANCE = 1e18;
    uint256 constant INITIAL_WITHDRAWABLE_VALUE = 1e17;

    function run() external {
        uint256[] memory deployerPrivateKeys = vm.envUint("LOCALHOST_PRIVATE_KEYS", ",");
        address payable ownerAddress = payable(vm.addr(deployerPrivateKeys[0]));
        vm.startBroadcast(deployerPrivateKeys[0]);
        new Faucet{value: INITIAL_BALANCE}(ownerAddress, INITIAL_WITHDRAWABLE_VALUE);
        vm.stopBroadcast();
    }
}
