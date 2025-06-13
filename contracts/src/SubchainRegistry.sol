// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SubchainRegistry is AccessControl {
    using SafeERC20 for IERC20;

    // --- Roles ---
    // Role for backend operations such as status updates
    bytes32 public constant BACKEND_ROLE = keccak256("BACKEND_ROLE");
    // Role for founders who can withdraw funds
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    // --- Payment tokens & fees ---
    // USDC token used for registration fee payments
    IERC20 public immutable usdc;
    // USDT token used for monthly fee payments
    IERC20 public immutable usdt;
    // Registration fee amount in USDC (6 decimals)
    uint256 public immutable registrationFee;
    // Monthly fee amount in USDT (6 decimals)
    uint256 public immutable monthlyFee;

    // --- Status enum ---
    // Possible statuses for a subchain
    enum Status {
        Pending, // Newly registered, awaiting activation
        Active, // Active and operational
        Suspended, // Temporarily suspended
        Deleted // Deleted or deactivated
    }

    // --- Subchain data ---
    // Structure to hold subchain information
    struct Subchain {
        string name; // Name of the subchain
        string domain; // Unique domain identifier
        string symbol; // Symbol representing the subchain
        string metadataUrl; // URL to metadata
        uint256 chainId; // Unique chain ID starting with 86
        address owner; // Owner address of the subchain
        Status status; // Current status of the subchain
        uint256 registrationTime; // Timestamp of registration
        uint256 activeTill; // Timestamp until which the subchain is active
    }

    // Array to store all registered subchains
    Subchain[] private _subchains;

    // --- Uniqueness checks ---
    // Mapping to track used domains to ensure uniqueness
    mapping(bytes32 => bool) private _domainUsed;
    // Mapping to track used chain IDs to ensure uniqueness
    mapping(uint256 => bool) private _chainIdUsed;

    // --- Events ---
    // Emitted when a new subchain is registered
    event SubchainRegistered(uint256 indexed index, address indexed owner);
    // Emitted when a subchain's status changes
    event StatusChanged(uint256 indexed index, Status newStatus);
    // Emitted when a monthly payment is made to extend active period
    event MonthlyPayment(uint256 indexed index, uint256 newActiveTill);
    // Emitted when a founder role is added
    event FounderAdded(address indexed account);
    // Emitted when a backend role is added
    event BackendAdded(address indexed account);
    // Emitted when ownership (admin role) is transferred
    event OwnershipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    // Constructor to initialize tokens and fees, and assign roles to deployer
    constructor(
        address _usdc,
        address _usdt,
        uint256 _registrationFee, // e.g. 10_000 * 10**18
        uint256 _monthlyFee // e.g. 1_000 * 10**18
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
    /// @param account The address to grant founder role
    function addFounder(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(FOUNDER_ROLE, account);
        emit FounderAdded(account);
    }

    /// @notice Add a backend address
    /// @param account The address to grant backend role
    function addBackend(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(BACKEND_ROLE, account);
        emit BackendAdded(account);
    }

    /// @notice Transfer ownership (admin role) to a new address
    /// @param newAdmin The address to transfer ownership to
    function transferOwnership(
        address newAdmin
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAdmin != address(0), "Zero address");
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        emit OwnershipTransferred(msg.sender, newAdmin);
    }

    /// @notice Register a new Subchain by paying USDC registration fee
    /// @param name The name of the subchain
    /// @param domain The unique domain of the subchain
    /// @param symbol The symbol representing the subchain
    /// @param metadataUrl URL pointing to subchain metadata
    /// @param chainId Unique chain ID starting with 86
    function registerSubchain(
        string calldata name,
        string calldata domain,
        string calldata symbol,
        string calldata metadataUrl,
        uint256 chainId
    ) external {
        bytes32 dh = keccak256(bytes(domain));
        require(!_domainUsed[dh], "Domain already used");
        require(!_chainIdUsed[chainId], "Chain ID already used");

        uint256 prefix = chainId;
        // keep dividing by 10 until only the first two digits remain
        while (prefix >= 100) {
            prefix /= 10;
        }

        require(prefix == 86, "Chain ID must start with 86");

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
                metadataUrl: metadataUrl,
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

    /// @notice Pay monthly support fee in USDT to extend activeTill by 30 days
    /// @param index The index of the subchain to pay for
    function payMonthly(uint256 index) external {
        require(index < _subchains.length, "Invalid index");
        Subchain storage s = _subchains[index];
        require(msg.sender == s.owner, "Not owner");
        require(s.status == Status.Active, "Must be active");

        // collect monthly fee in USDT
        usdt.safeTransferFrom(msg.sender, address(this), monthlyFee);

        uint256 start = block.timestamp > s.activeTill
            ? block.timestamp
            : s.activeTill;
        s.activeTill = start + 30 days;

        emit MonthlyPayment(index, s.activeTill);
    }

    // --- Backend-only management ---
    /// @notice Set the status of a subchain
    /// @param index The index of the subchain
    /// @param newStatus The new status to set
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
    /// @notice Get the total number of registered subchains
    /// @return The count of subchains
    function totalSubchains() external view returns (uint256) {
        return _subchains.length;
    }

    /// @notice Get details of a subchain by index
    /// @param index The index of the subchain
    /// @return name The name of the subchain
    /// @return domain The domain of the subchain
    /// @return symbol The symbol of the subchain
    /// @return metadataUrl The metadata URL of the subchain
    /// @return chainId The chain ID of the subchain
    /// @return owner The owner address of the subchain
    /// @return status The current status of the subchain
    /// @return registrationTime The registration timestamp
    /// @return activeTill The timestamp until which the subchain is active
    function getSubchain(
        uint256 index
    )
        external
        view
        returns (
            string memory name,
            string memory domain,
            string memory symbol,
            string memory metadataUrl,
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
            s.metadataUrl,
            s.chainId,
            s.owner,
            s.status,
            s.registrationTime,
            s.activeTill
        );
    }

    /// @notice Get the latest subchain index
    /// @return The index of the latest subchain
    function latestIndex() external view returns (uint256) {
        require(_subchains.length > 0, "No subchains");
        return _subchains.length - 1;
    }

    // --- Admin withdrawal ---
    /// @notice Withdraw ERC20 tokens from the contract
    /// @param token The token address to withdraw
    /// @param amount The amount to withdraw
    /// @param to The recipient address
    function withdrawERC20(
        address token,
        uint256 amount,
        address to
    ) external onlyRole(FOUNDER_ROLE) {
        IERC20(token).safeTransfer(to, amount);
    }
}
