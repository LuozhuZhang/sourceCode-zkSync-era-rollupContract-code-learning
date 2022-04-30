// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

/// @title Ownable Contract
/// @author Matter Labs
// 一般可以直接继承OZ的ownable合约：https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
contract Ownable {
    /// @dev Storage position of the masters address (keccak256('eip1967.proxy.admin') - 1)
    // private key，建议使用dotenv
    bytes32 private constant MASTER_POSITION = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /// @notice Contract constructor
    /// @dev Sets msg sender address as masters address
    /// @param masterAddress Master address
    constructor(address masterAddress) {
        // 设置初始的contract owner（MASTER_POSITION）
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
    // get data，所以也需要只读不写（view）
    function getMaster() public view returns (address master) {
        bytes32 position = MASTER_POSITION;
        // 操作EVM
        assembly {
            // 读取storage存储的variables
            // sload(p)	= storage[p]
            master := sload(position)
        }
    }

    /// @dev Sets new masters address
    /// @param _newMaster New master's address
    // 更换owner（需要操作EVM opcode，改变blockchain中的state）
    function setMaster(address _newMaster) internal {
        bytes32 position = MASTER_POSITION;
        // 引入汇编，直接操作EVM stack：https://docs.soliditylang.org/en/v0.8.11/assembly.html
        assembly {
            // sstore(p,v) 等同于 storage[p] := v
            sstore(position, _newMaster)
        }
    }

    /// @notice Transfer mastership of the contract to new master
    /// @param _newMaster New masters address
    // 把合约的控制主权交给新合约，调用了setMaster
    function transferMastership(address _newMaster) external {
        // 只有owner才可以调用（所以可以external）
        requireMaster(msg.sender);
        // 向0地址转账会创建一个新的contract，owner transfer到0 addr会发生什么呢？返回false还是产生更复杂的交易。这个问题也在阅读OZ源码时被解答 ⬇
        // 将owner转移到0，则放弃contract的所有权（contract不会被删除，但是没有所有者）
        require(_newMaster != address(0), "1d"); // otp11 - new masters address can't be zero address
        // 转移owner
        setMaster(_newMaster);
    }
}
