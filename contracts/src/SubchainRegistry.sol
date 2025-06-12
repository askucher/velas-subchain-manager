// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SubchainRegistry is AccessControl {
    using SafeERC20 for IERC20;

    // --- Roles ---
    bytes32 public constant BACKEND_ROLE = keccak256("BACKEND_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    // --- Payment tokens & fees ---
    IERC20 public immutable usdc;
    IERC20 public immutable usdt;
    uint256 public immutable registrationFee; // in USDC (6 decimals)
    uint256 public immutable monthlyFee; // in USDT (6 decimals)

    // --- Status enum ---
    enum Status {
        Pending,
        Active,
        Suspended,
        Deleted
    }

    // --- Subchain data ---
    struct Subchain {
        string name;
        string domain;
        string symbol;
        uint256 chainId;
        address owner;
        Status status;
        uint256 registrationTime;
        uint256 activeTill;
    }

    Subchain[] private _subchains;

    // --- Uniqueness checks ---
    mapping(bytes32 => bool) private _domainUsed;
    mapping(uint256 => bool) private _chainIdUsed;

    // --- Events ---
    event SubchainRegistered(uint256 indexed index, address indexed owner);
    event StatusChanged(uint256 indexed index, Status newStatus);
    event MonthlyPayment(uint256 indexed index, uint256 newActiveTill);
    event FounderAdded(address indexed account);
    event BackendAdded(address indexed account);
    event OwnershipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    constructor(
        address _usdc,
        address _usdt,
        uint256 _registrationFee, // e.g. 10_000 * 10**6
        uint256 _monthlyFee // e.g. 1_000 * 10**6
    ) {
        require(
            _usdc != address(0) && _usdt != address(0),
            "Zero token address"
        );
        usdc = IERC20(_usdc);
        usdt = IERC20(_usdt);
        registrationFee = _registrationFee;
        monthlyFee = _monthlyFee;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BACKEND_ROLE, msg.sender);
    }

    /// @notice Add a founder address
    function addFounder(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(FOUNDER_ROLE, account);
        emit FounderAdded(account);
    }

    /// @notice Add a backend address
    function addBackend(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(BACKEND_ROLE, account);
        emit BackendAdded(account);
    }

    /// @notice Transfer ownership (admin role) to a new address
    function transferOwnership(
        address newAdmin
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAdmin != address(0), "Zero address");
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        emit OwnershipTransferred(msg.sender, newAdmin);
    }

    /// @notice Register a new Subchain by paying USDC
    function registerSubchain(
        string calldata name,
        string calldata domain,
        string calldata symbol,
        uint256 chainId
    ) external {
        bytes32 dh = keccak256(bytes(domain));
        require(!_domainUsed[dh], "Domain already used");
        require(!_chainIdUsed[chainId], "Chain ID already used");

        // collect fee
        usdc.safeTransferFrom(msg.sender, address(this), registrationFee);

        // mark uniqueness
        _domainUsed[dh] = true;
        _chainIdUsed[chainId] = true;

        // push new record
        _subchains.push(
            Subchain({
                name: name,
                domain: domain,
                symbol: symbol,
                chainId: chainId,
                owner: msg.sender,
                status: Status.Pending,
                registrationTime: block.timestamp,
                activeTill: 0
            })
        );

        uint256 idx = _subchains.length - 1;
        emit SubchainRegistered(idx, msg.sender);
    }

    /// @notice Pay monthly support in USDT to extend activeTill by 30 days
    function payMonthly(uint256 index) external {
        require(index < _subchains.length, "Invalid index");
        Subchain storage s = _subchains[index];
        require(msg.sender == s.owner, "Not owner");
        require(s.status == Status.Active, "Must be active");

        usdt.safeTransferFrom(msg.sender, address(this), monthlyFee);

        uint256 start = block.timestamp > s.activeTill
            ? block.timestamp
            : s.activeTill;
        s.activeTill = start + 30 days;

        emit MonthlyPayment(index, s.activeTill);
    }

    // --- Backend-only management ---
    function setStatus(
        uint256 index,
        Status newStatus
    ) external onlyRole(BACKEND_ROLE) {
        require(index < _subchains.length, "Invalid index");
        Subchain storage s = _subchains[index];
        s.status = newStatus;
        emit StatusChanged(index, newStatus);
    }

    // --- Read helpers ---
    function totalSubchains() external view returns (uint256) {
        return _subchains.length;
    }

    function getSubchain(
        uint256 index
    )
        external
        view
        returns (
            string memory name,
            string memory domain,
            string memory symbol,
            uint256 chainId,
            address owner,
            Status status,
            uint256 registrationTime,
            uint256 activeTill
        )
    {
        require(index < _subchains.length, "Invalid index");
        Subchain storage s = _subchains[index];
        return (
            s.name,
            s.domain,
            s.symbol,
            s.chainId,
            s.owner,
            s.status,
            s.registrationTime,
            s.activeTill
        );
    }

    function latestIndex() external view returns (uint256) {
        require(_subchains.length > 0, "No subchains");
        return _subchains.length - 1;
    }

    // --- Admin withdrawal ---
    function withdrawERC20(
        address token,
        uint256 amount,
        address to
    ) external onlyRole(FOUNDER_ROLE) {
        IERC20(token).safeTransfer(to, amount);
    }
}
