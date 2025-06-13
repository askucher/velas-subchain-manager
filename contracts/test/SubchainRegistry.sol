// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SubchainRegistry.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @notice Simple ERC20 mintable mock for testing
contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract SubchainRegistryTest is Test {
    ERC20Mock public usdc;
    ERC20Mock public usdt;
    SubchainRegistry public registry;

    address public deployer;
    address public backend = address(0xBEEF);
    address public user = address(0xCAFE);

    uint256 constant REG_FEE = 10_000 * 1e18;
    uint256 constant MONTH_FEE = 1_000 * 1e18;

    // Re-declare events to capture them in tests
    event SubchainRegistered(uint256 indexed index, address indexed owner);
    event StatusChanged(
        uint256 indexed index,
        SubchainRegistry.Status newStatus
    );
    event MonthlyPayment(uint256 indexed index, uint256 newActiveTill);

    function setUp() public {
        deployer = address(this);
        // Deploy mocks and registry
        usdc = new ERC20Mock("USDC", "USDC");
        usdt = new ERC20Mock("USDT", "USDT");
        registry = new SubchainRegistry(
            address(usdc),
            address(usdt),
            REG_FEE,
            MONTH_FEE
        );

        // Grant backend role
        registry.grantRole(registry.BACKEND_ROLE(), backend);
        // Grant founder role for withdrawals
        registry.grantRole(registry.FOUNDER_ROLE(), deployer);

        // Mint tokens to user
        usdc.mint(user, REG_FEE * 10);
        usdt.mint(user, MONTH_FEE * 10);
    }

    /// @notice Should register a subchain successfully
    function testRegisterSubchainSuccess() public {
        vm.startPrank(user);
        usdc.approve(address(registry), REG_FEE);
        vm.expectEmit(true, true, false, false);
        emit SubchainRegistered(0, user);
        registry.registerSubchain(
            "Name",
            "domain",
            "SYM",
            "https://ipfs.org/xyz",
            861
        );
        vm.stopPrank();

        (
            string memory name,
            string memory domain,
            string memory symbol,
            ,
            uint256 chainId,
            ,
            SubchainRegistry.Status status,
            ,

        ) = registry.getSubchain(0);
        assertEq(name, "Name");
        assertEq(domain, "domain");
        assertEq(symbol, "SYM");
        assertEq(chainId, 861);
        assertEq(uint(status), uint(SubchainRegistry.Status.Pending));
        assertEq(registry.totalSubchains(), 1);
    }

    /// @notice Duplicate domain must revert
    function testRegisterDuplicateDomainFails() public {
        vm.startPrank(user);
        usdc.approve(address(registry), REG_FEE);
        registry.registerSubchain("A", "dup", "A", "https://ipfs.org/xyz", 862);

        usdc.approve(address(registry), REG_FEE);
        vm.expectRevert(bytes("Domain already used"));
        registry.registerSubchain("B", "dup", "B", "https://ipfs.org/xyz", 862);
        vm.stopPrank();
    }

    /// @notice Duplicate chainId must revert
    function testRegisterDuplicateChainIdFails() public {
        vm.startPrank(user);
        usdc.approve(address(registry), REG_FEE);
        registry.registerSubchain("A", "a", "A", "https://ipfs.org/xyz", 865);

        usdc.approve(address(registry), REG_FEE);
        vm.expectRevert(bytes("Chain ID already used"));
        registry.registerSubchain("B", "b", "B", "https://ipfs.org/xyz", 865);
        vm.stopPrank();
    }

    /// @notice Only backend role can change status
    function testSetStatusByBackend() public {
        // Register first
        vm.startPrank(user);
        usdc.approve(address(registry), REG_FEE);
        registry.registerSubchain("X", "x", "X", "https://ipfs.org/xyz", 8610);
        vm.stopPrank();

        // Unauthorized should revert
        vm.prank(user);
        vm.expectRevert();
        registry.setStatus(0, SubchainRegistry.Status.Active);

        // Backend can update status
        vm.prank(backend);
        vm.expectEmit(true, false, false, false);
        emit StatusChanged(0, SubchainRegistry.Status.Active);
        registry.setStatus(0, SubchainRegistry.Status.Active);

        (, , , , , , SubchainRegistry.Status st, , ) = registry.getSubchain(0);
        assertEq(uint(st), uint(SubchainRegistry.Status.Active));
    }

    /// @notice Monthly payment logic
    function testPayMonthly() public {
        // Setup and activate
        vm.startPrank(user);
        usdc.approve(address(registry), REG_FEE);
        registry.registerSubchain("Y", "y", "Y", "https://ipfs.org/xyz", 86123);
        vm.stopPrank();

        vm.prank(backend);
        registry.setStatus(0, SubchainRegistry.Status.Active);

        // Fail if not owner
        vm.prank(address(0xBAD));
        vm.expectRevert(bytes("Not owner"));
        registry.payMonthly(0);

        // Pay monthly
        vm.startPrank(user);
        usdc.approve(address(registry), MONTH_FEE);
        uint256 before = block.timestamp;
        vm.warp(before + 1 days);
        vm.expectEmit(true, false, false, false);
        emit MonthlyPayment(0, before + 1 days + 30 days);
        registry.payMonthly(0);
        vm.stopPrank();

        (, , , , , , , , uint256 activeTill) = registry.getSubchain(0);
        assertEq(activeTill, before + 1 days + 30 days);
    }

    /// @notice Admin withdrawal of tokens
    function testWithdrawERC20() public {
        // Mint to registry and withdraw
        usdc.mint(address(registry), 50);
        uint256 balBefore = usdc.balanceOf(deployer);
        registry.withdrawERC20(address(usdc), 50, deployer);
        assertEq(usdc.balanceOf(deployer) - balBefore, 50);
    }
}
