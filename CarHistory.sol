// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Vehicle Lifecycle Recorder
 * @dev Stores vehicle maintenance history on-chain with access control.
 * Only authorized entities (e.g., certified 4S shops) can add records.
 */
contract CarHistory {
    
    // --- 核心数据结构 ---
    struct Record {
        uint256 timestamp;   // 上链时间
        uint256 mileage;     // 里程数 (KM)
        string ipfsHash;     // 维修详情的IPFS哈希 (存具体的PDF/图片)
        string recordType;   // 类型: "Maintenance"(保养), "Repair"(维修), "Accident"(事故)
        address recorder;    // 记录员地址
    }

    // --- 状态变量 ---
    address public admin; // 合约管理员 (通常是车企或监管机构)
    mapping(string => Record[]) private vehicleRecords; // VIN => 记录列表
    mapping(address => bool) public authorizedRecorders; // 授权的记录员名单 (白名单)

    // --- 事件 (方便前端查询) ---
    event RecordAdded(string indexed vin, uint256 mileage, string recordType, address indexed recorder);
    event RecorderAuthorized(address indexed recorder);
    event RecorderRevoked(address indexed recorder);

    // --- 自定义错误 (省 Gas 费且更专业) ---
    error NotAuthorized(); // 你没有权限
    error MileageRollbackDetected(uint256 current, uint256 previous); // 发现里程倒退
    error InvalidInput(); // 输入无效

    // --- 修饰器 (逻辑复用) ---
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAuthorized();
        _;
    }

    modifier onlyAuthorized() {
        if (!authorizedRecorders[msg.sender]) revert NotAuthorized();
        _;
    }

    constructor() {
        admin = msg.sender; // 部署合约的人自动成为管理员
        authorizedRecorders[msg.sender] = true; // 管理员默认有记录权限
    }

    // --- 核心功能 1: 授权新的 4S 店/维修站 ---
    // 只有管理员能调用。在现实中，这意味着车企给某个4S店开通权限。
    function authorizeRecorder(address _recorder) external onlyAdmin {
        authorizedRecorders[_recorder] = true;
        emit RecorderAuthorized(_recorder);
    }

    // --- 核心功能 2: 撤销权限 ---
    // 如果某个 4S 店造假，管理员可以取消它的资格
    function revokeRecorder(address _recorder) external onlyAdmin {
        authorizedRecorders[_recorder] = false;
        emit RecorderRevoked(_recorder);
    }

    // --- 核心功能 3: 上传维修记录 ---
    // 只有被授权的地址才能调用
    function addRecord(
        string calldata _vin, 
        uint256 _mileage, 
        string calldata _ipfsHash, 
        string calldata _recordType
    ) external onlyAuthorized {
        
        // 简单的输入检查
        if (bytes(_vin).length == 0) revert InvalidInput();

        // 防调表逻辑: 检查上一条记录
        Record[] storage history = vehicleRecords[_vin];
        if (history.length > 0) {
            uint256 lastMileage = history[history.length - 1].mileage;
            if (_mileage < lastMileage) {
                revert MileageRollbackDetected(_mileage, lastMileage);
            }
        }

        // 写入数据
        Record memory newRecord = Record({
            timestamp: block.timestamp,
            mileage: _mileage,
            ipfsHash: _ipfsHash,
            recordType: _recordType,
            recorder: msg.sender
        });

        vehicleRecords[_vin].push(newRecord);

        // 触发事件通知前端
        emit RecordAdded(_vin, _mileage, _recordType, msg.sender);
    }

    // --- 查询功能 ---
    function getVehicleHistory(string calldata _vin) external view returns (Record[] memory) {
        return vehicleRecords[_vin];
    }
