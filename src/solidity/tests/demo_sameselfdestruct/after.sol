// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SelfDestructExample {
    constructor() payable {}

    // 漏洞：未做权限控制，任意人可调用
    // 利用方式：攻击者直接调用 destroy(attacker)，合约余额被转走并销毁合约
    function destroy(address payable to) external {
        selfdestruct(to);
    }

    receive() external payable {}

    // =========================
    // 全局声明（新增）
    // =========================
    address public owner;
    uint256 public totalDeposits;
    uint256 public totalWithdrawn;
    uint256 public nonce;
    bool public paused;

    struct Vault {
        uint256 balance;
        uint256 lastDepositAt;
        uint256 lastWithdrawAt;
        bool frozen;
    }

    struct Proposal {
        address proposer;
        bytes32 actionHash;
        uint256 createdAt;
        uint256 approvals;
        uint256 rejections;
        bool executed;
        mapping(address => bool) voted;
    }

    mapping(address => Vault) public vaults;
    mapping(bytes32 => Proposal) private proposals;
    mapping(address => bool) public guardians;
    mapping(address => uint256) public userNonces;

    bytes32 public domainSeparator;

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event Paused(bool state);
    event GuardianSet(address indexed guardian, bool enabled);
    event VaultFrozen(address indexed user, bool frozen);
    event ProposalCreated(bytes32 indexed id, address indexed proposer);
    event Voted(bytes32 indexed id, address indexed voter, bool approve);
    event ProposalExecuted(bytes32 indexed id);

    // =========================
    // 初始化逻辑（新增）
    // =========================
    function initialize(address _owner, address[] calldata _guardians) external {
        require(owner == address(0), "already initialized");
        require(_owner != address(0), "zero owner");
        owner = _owner;
        for (uint256 i = 0; i < _guardians.length; i++) {
            guardians[_guardians[i]] = true;
            emit GuardianSet(_guardians[i], true);
        }
        domainSeparator = keccak256(
            abi.encode(
                keccak256("SelfDestructExample(uint256 chainId,address contract)"),
                block.chainid,
                address(this)
            )
        );
        emit OwnerChanged(address(0), _owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyGuardian() {
        require(guardians[msg.sender], "not guardian");
        _;
    }

    modifier notPaused() {
        require(!paused, "paused");
        _;
    }

    // =========================
    // 资金逻辑（新增）
    // =========================
    function deposit() external payable notPaused {
        require(msg.value > 0, "zero value");
        Vault storage v = vaults[msg.sender];
        require(!v.frozen, "frozen");
        v.balance += msg.value;
        v.lastDepositAt = block.timestamp;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount, address payable to) external notPaused {
        require(amount > 0, "zero amount");
        Vault storage v = vaults[msg.sender];
        require(!v.frozen, "frozen");
        require(v.balance >= amount, "insufficient");
        v.balance -= amount;
        v.lastWithdrawAt = block.timestamp;
        totalWithdrawn += amount;
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "transfer failed");
        emit Withdraw(to, amount);
    }

    function emergencyWithdrawAll(address payable to) external onlyOwner {
        uint256 bal = address(this).balance;
        (bool ok, ) = to.call{value: bal}("");
        require(ok, "transfer failed");
        totalWithdrawn += bal;
        emit Withdraw(to, bal);
    }

    // =========================
    // 管理与暂停（新增）
    // =========================
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero owner");
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    function setPaused(bool state) external onlyOwner {
        paused = state;
        emit Paused(state);
    }

    function setGuardian(address guardian, bool enabled) external onlyOwner {
        guardians[guardian] = enabled;
        emit GuardianSet(guardian, enabled);
    }

    function freezeVault(address user, bool frozen) external onlyGuardian {
        vaults[user].frozen = frozen;
        emit VaultFrozen(user, frozen);
    }

    // =========================
    // 提案投票系统（新增）
    // =========================
    function createProposal(bytes32 actionHash) external notPaused returns (bytes32 id) {
        require(actionHash != bytes32(0), "zero hash");
        id = keccak256(abi.encodePacked(msg.sender, actionHash, block.number, nonce++));
        Proposal storage p = proposals[id];
        require(p.createdAt == 0, "exists");
        p.proposer = msg.sender;
        p.actionHash = actionHash;
        p.createdAt = block.timestamp;
        emit ProposalCreated(id, msg.sender);
    }

    function vote(bytes32 id, bool approve) external notPaused {
        Proposal storage p = proposals[id];
        require(p.createdAt != 0, "missing");
        require(!p.voted[msg.sender], "voted");
        p.voted[msg.sender] = true;
        if (approve) {
            p.approvals += 1;
        } else {
            p.rejections += 1;
        }
        emit Voted(id, msg.sender, approve);
    }

    function executeProposal(bytes32 id, bytes calldata data) external onlyOwner {
        Proposal storage p = proposals[id];
        require(p.createdAt != 0, "missing");
        require(!p.executed, "executed");
        require(p.approvals > p.rejections, "not approved");
        require(keccak256(data) == p.actionHash, "hash mismatch");
        p.executed = true;

        (bool ok, ) = address(this).call(data);
        require(ok, "exec failed");
        emit ProposalExecuted(id);
    }

    // =========================
    // 签名验证示例（新增）
    // =========================
    function permit(
        address user,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external notPaused {
        require(block.timestamp <= deadline, "expired");
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address user,uint256 amount,uint256 nonce,uint256 deadline)"),
                user,
                amount,
                userNonces[user]++,
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signer = ecrecover(digest, v, r, s);
        require(signer == user, "bad sig");

        Vault storage vlt = vaults[user];
        require(!vlt.frozen, "frozen");
        vlt.balance += amount;
        totalDeposits += amount;

        emit Deposit(user, amount);
    }

    // =========================
    // 视图函数（新增）
    // =========================
    function getProposal(bytes32 id)
        external
        view
        returns (
            address proposer,
            bytes32 actionHash,
            uint256 createdAt,
            uint256 approvals,
            uint256 rejections,
            bool executed
        )
    {
        Proposal storage p = proposals[id];
        return (p.proposer, p.actionHash, p.createdAt, p.approvals, p.rejections, p.executed);
    }

    function getVault(address user)
        external
        view
        returns (
            uint256 balance,
            uint256 lastDepositAt,
            uint256 lastWithdrawAt,
            bool frozen
        )
    {
        Vault storage v = vaults[user];
        return (v.balance, v.lastDepositAt, v.lastWithdrawAt, v.frozen);
    }
}