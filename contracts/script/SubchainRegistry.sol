// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {SubchainRegistry} from "../src/SubchainRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC20
 * @dev Minimal ERC20 with configurable decimals for local testing.
 */
contract MockERC20 is ERC20 {
    uint8 private _customDecimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _customDecimals = decimals_;
        // Mint a large supply to the deployer so you can pay fees in tests
        _mint(msg.sender, 1_000_000 * (10 ** decimals_));
    }

    function decimals() public view virtual override returns (uint8) {
        return _customDecimals;
    }
}

contract DeploySubchain is Script {
    function run() external {
        address usdc;
        address usdt;
        uint256 registrationFee;
        uint256 monthlyFee;

        vm.startBroadcast();

        // ——— USDC ———
        try vm.envAddress("USDC_ADDRESS") returns (address addr) {
            usdc = addr;
        } catch {
            MockERC20 usdcMock = new MockERC20("Mock USDC", "mUSDC", 6);
            usdc = address(usdcMock);
            console.log("Deployed mock USDC at:", usdc);
        }

        // ——— USDT ———
        try vm.envAddress("USDT_ADDRESS") returns (address addr) {
            usdt = addr;
        } catch {
            MockERC20 usdtMock = new MockERC20("Mock USDT", "mUSDT", 6);
            usdt = address(usdtMock);
            console.log("Deployed mock USDT at:", usdt);
        }

        // ——— Registration Fee ———
        try vm.envUint("REGISTRATION_FEE") returns (uint256 fee) {
            registrationFee = fee;
        } catch {
            registrationFee = 10_000 * 10 ** 6; // default: 10 000 USDC
            console.log("Using default registration fee:", registrationFee);
        }

        // ——— Monthly Fee ———
        try vm.envUint("MONTHLY_FEE") returns (uint256 fee) {
            monthlyFee = fee;
        } catch {
            monthlyFee = 1_000 * 10 ** 6; // default: 1 000 USDT
            console.log("Using default monthly fee:", monthlyFee);
        }

        // ——— Deploy Registry ———
        SubchainRegistry registry = new SubchainRegistry(
            usdc,
            usdt,
            registrationFee,
            monthlyFee
        );
        console.log("SubchainRegistry deployed at:", address(registry));

        vm.stopBroadcast();
    }
}
