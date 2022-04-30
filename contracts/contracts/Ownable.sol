// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

/// @title Ownable Contract
/// @author Matter Labs
contract Ownable {
    /// @dev Storage position of the masters address (keccak256('eip1967.proxy.admin') - 1)
    bytes32 private constant MASTER_POSITION = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /// @notice Contract constructor
    /// @dev Sets msg sender address as masters address
    /// @param masterAddress Master address
    constructor(address masterAddress) {
        setMaster(masterAddress);
    }

    /// @notice Check if specified address is master
    /// @param _address Address to check
    // 检查调用的地址是否是master（owner），这个function被许多contract调用使用
    // view（v0.5中定义），只读不写
    // 好奇onlyOwner就可以，为什么要写的这么复杂呢？这个问题在阅读openzepplien源码时被解答：
    // onlyOwner并不是solidity native的，而是op中的basic contract，zksync在这里做了完全相同的事情
    function requireMaster(address _address) internal view {
        require(_address == getMaster(), "1c"); // oro11 - only by master
    }

    /// @notice Returns contract masters address
    /// @return master Master's address
    function getMaster() public view returns (address master) {
        bytes32 position = MASTER_POSITION;
        assembly {
            master := sload(position)
        }
    }

    /// @dev Sets new masters address
    /// @param _newMaster New master's address
    function setMaster(address _newMaster) internal {
        bytes32 position = MASTER_POSITION;
        assembly {
            sstore(position, _newMaster)
        }
    }

    /// @notice Transfer mastership of the contract to new master
    /// @param _newMaster New masters address
    function transferMastership(address _newMaster) external {
        requireMaster(msg.sender);
        // 向0地址转账会创建一个新的contract，owner transfer到0 addr会发生什么呢？返回false还是产生更复杂的交易。这个问题也在阅读OZ源码时被解答 ⬇
        // 将owner转移到0，则放弃contract的所有权（contract不会被删除，但是没有所有者）
        require(_newMaster != address(0), "1d"); // otp11 - new masters address can't be zero address
        setMaster(_newMaster);
    }
}
