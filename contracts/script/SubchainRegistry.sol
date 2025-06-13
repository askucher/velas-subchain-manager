// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {SubchainRegistry} from "../src/SubchainRegistry.sol";

/**
 * @title DeploySubchain
 * @notice Foundry script to deploy SubchainRegistry
 *
 * Usage:
 *   forge script script/DeploySubchain.s.sol \
 *     --private-key ${{PRIVATE_KEY}} \
 *     --rpc-url ${{RPC_URL}} \
 *     --broadcast
 *
 * Environment variables:
 *   USDC_ADDRESS        Address of USDC on target network
 *   USDT_ADDRESS        Address of USDT on target network
 *   REGISTRATION_FEE    Registration fee in USDC (6 decimals), e.g. 10000000000 for 10k
 *   MONTHLY_FEE         Monthly support fee in USDT (6 decimals), e.g. 1000000000 for 1k
 */
contract DeploySubchain is Script {
    function run() external {
        // Load deployment parameters from env
        address usdc = vm.envAddress("USDC_ADDRESS");
        address usdt = vm.envAddress("USDT_ADDRESS");
        uint256 registrationFee = vm.envUint("REGISTRATION_FEE");
        uint256 monthlyFee = vm.envUint("MONTHLY_FEE");

        vm.startBroadcast();

        // Deploy registry
        SubchainRegistry registry = new SubchainRegistry(
            usdc,
            usdt,
            registrationFee,
            monthlyFee
        );

        // Log the deployed address
        console.log("SubchainRegistry deployed at:", address(registry));

        vm.stopBroadcast();
    }
}
