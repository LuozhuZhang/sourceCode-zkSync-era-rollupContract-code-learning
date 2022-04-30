// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Events.sol";
import "./Ownable.sol";
import "./Upgradeable.sol";
import "./UpgradeableMaster.sol";

/// @title Upgrade Gatekeeper Contract
/// @author Matter Labs
contract UpgradeGatekeeper is UpgradeEvents, Ownable {
    using SafeMath for uint256;

    /// @notice Array of addresses of upgradeable contracts managed by the gatekeeper
    // 一个list？其中包含所有待升级的contract address？
    Upgradeable[] public managedContracts;

    /// @notice Upgrade mode statuses
    // Idle的true和false决定了合约能否被升级
    enum UpgradeStatus {
        Idle,
        NoticePeriod,
        Preparation
    }

    UpgradeStatus public upgradeStatus;

    /// @notice Notice period finish timestamp (as seconds since unix epoch)
    /// @dev Will be equal to zero in case of not active upgrade mode
    uint256 public noticePeriodFinishTimestamp;

    /// @notice Addresses of the next versions of the contracts to be upgraded (if element of this array is equal to zero address it means that appropriate upgradeable contract wouldn't be upgraded this time)
    /// @dev Will be empty in case of not active upgrade mode
    address[] public nextTargets;

    /// @notice Version id of contracts
    // Contract版本号
    uint256 public versionId;

    /// @notice Contract which defines notice period duration and allows finish upgrade during preparation of it
    // 把upgrade master定义为了mainContract，感觉前者就是合约升级的一系列接口
    UpgradeableMaster public mainContract;

    /// @notice Contract constructor
    /// @param _mainContract Contract which defines notice period duration and allows finish upgrade during preparation of it
    /// @dev Calls Ownable contract constructor
    // 定义权限：只有ownable可以调用，所以ownable调用合约更新（看看在哪里会写这个逻辑，貌似单独封装了一个contract，而且是一级合约）
    constructor(UpgradeableMaster _mainContract) Ownable(msg.sender) {
        mainContract = _mainContract;
        versionId = 0;
    }

    /// @notice Adds a new upgradeable contract to the list of contracts managed by the gatekeeper
    // gatekeeper是什么？
    /// @param addr Address of upgradeable contract to add
    // 添加所升级合约的地址
    function addUpgradeable(address addr) external {
        requireMaster(msg.sender);
        // 如果upgradeStatus中的Idle是false，说明合约不能升级
        // 在隔壁upgrademaster文件中的upgradeCanceled() function，其作用就是把upgradeStatus Idle状态改为False，从而起到停止合约升级的效果
        require(upgradeStatus == UpgradeStatus.Idle, "apc11"); /// apc11 - upgradeable contract can't be added during upgrade

        // 把contract addr添加到managedContracts中（managedContracts估计是在UpgradeEvents中定义的接口）
        managedContracts.push(Upgradeable(addr));
        // emit触发一个event，上传版本号和合约地址
        emit NewUpgradable(versionId, addr);
    }

    /// @notice Starts upgrade (activates notice period)
    // 开始更新
    /// @param newTargets New managed contracts targets (if element of this array is equal to zero address it means that appropriate upgradeable contract wouldn't be upgraded this time)
    function startUpgrade(address[] calldata newTargets) external {
        requireMaster(msg.sender);
        require(upgradeStatus == UpgradeStatus.Idle, "spu11"); // spu11 - unable to activate active upgrade mode
        // 如果newTargets中没有addr，该合约不会被更新？
        require(newTargets.length == managedContracts.length, "spu12"); // spu12 - number of new targets must be equal to the number of managed contracts

        // 获取通知期限（return 0）
        uint256 noticePeriod = mainContract.getNoticePeriod();
        // 开始升级合约，所以 startUpgrade 才是升级合约真正需要调用的函数
        mainContract.upgradeNoticePeriodStarted();
        // upgradeStatus被定义为了0
        upgradeStatus = UpgradeStatus.NoticePeriod;
        noticePeriodFinishTimestamp = block.timestamp.add(noticePeriod);
        nextTargets = newTargets;
        // 调用event，传入versionI、calldata（external调用时传入的data）、notice period
        emit NoticePeriodStart(versionId, newTargets, noticePeriod);
    }

    /// @notice Cancels upgrade
    function cancelUpgrade() external {
        requireMaster(msg.sender);
        require(upgradeStatus != UpgradeStatus.Idle, "cpu11"); // cpu11 - unable to cancel not active upgrade mode

        // 取消更新，清除状态
        mainContract.upgradeCanceled();
        upgradeStatus = UpgradeStatus.Idle;
        noticePeriodFinishTimestamp = 0;
        delete nextTargets;
        emit UpgradeCancel(versionId);
    }

    /// @notice Activates preparation status
    /// @return Bool flag indicating that preparation status has been successfully activated
    function startPreparation() external returns (bool) {
        requireMaster(msg.sender);
        require(upgradeStatus == UpgradeStatus.NoticePeriod, "ugp11"); // ugp11 - unable to activate preparation status in case of not active notice period status

        // 还是一样的逻辑，需要timestamp大于noticePeriod Finish Timestamp（这个function跟zksync区别在哪里，貌似完成的任务不同）
        if (block.timestamp >= noticePeriodFinishTimestamp) {
            upgradeStatus = UpgradeStatus.Preparation;
            // 调用主合约，激活准备状态
            mainContract.upgradePreparationStarted();
            emit PreparationStart(versionId);
            return true;
        } else {
            return false;
        }
    }

    /// @notice Finishes upgrade
    /// @param targetsUpgradeParameters New targets upgrade parameters per each upgradeable contract
    function finishUpgrade(bytes[] calldata targetsUpgradeParameters) external {
        requireMaster(msg.sender);
        require(upgradeStatus == UpgradeStatus.Preparation, "fpu11"); // fpu11 - unable to finish upgrade without preparation status active
        require(targetsUpgradeParameters.length == managedContracts.length, "fpu12"); // fpu12 - number of new targets upgrade parameters must be equal to the number of managed contracts
        // 准备升级？
        require(mainContract.isReadyForUpgrade(), "fpu13"); // fpu13 - main contract is not ready for upgrade
        mainContract.upgradeFinishes();

        for (uint64 i = 0; i < managedContracts.length; i++) {
            address newTarget = nextTargets[i];
            if (newTarget != address(0)) {
                managedContracts[i].upgradeTarget(newTarget, targetsUpgradeParameters[i]);
            }
        }
        versionId++;
        emit UpgradeComplete(versionId, nextTargets);

        // 清除state
        upgradeStatus = UpgradeStatus.Idle;
        noticePeriodFinishTimestamp = 0;
        delete nextTargets;
    }
}
