// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

/// @title Interface of the upgradeable master contract (defines notice period duration and allows finish upgrade during preparation of it)
/// @author Matter Labs

// interface的使用方式：https://www.tutorialspoint.com/solidity/solidity_interfaces.htm
interface UpgradeableMaster {
    /// @notice Notice period before activation preparation status of upgrade mode
    // 1）升级模式激活状态准备前的通知时间？return的是0，所以应该不是返回时间，更像是获取通知权限（这个function在upgradeGatekeeper也被调用了，可以看看作用是什么）
    function getNoticePeriod() external returns (uint256);
    // 在zksync中调用，就是返回0（return 0） - zksync
    // 会赋值给upgradeStatus，从而控制合约是否更新 - upgrade gatekeeper

    /// @notice Notifies contract that notice period started
    // 2）开始更新，返回block.timestamp - zksync
    function upgradeNoticePeriodStarted() external;

    /// @notice Notifies contract that upgrade preparation status is activated
    // 3）激活更新状态 - zksync
    function upgradePreparationStarted() external;

    /// @notice Notifies contract that upgrade canceled
    // 4）取消更新，并清除与更新有关的所有state
    function upgradeCanceled() external;

    /// @notice Notifies contract that upgrade finishes
    // 5）更新完成，也清除state
    function upgradeFinishes() external;

    /// @notice Checks that contract is ready for upgrade
    /// @return bool flag indicating that contract is ready for upgrade
    // 6）表示合约是否准备升级，zksync返回true
    function isReadyForUpgrade() external returns (bool);
}
