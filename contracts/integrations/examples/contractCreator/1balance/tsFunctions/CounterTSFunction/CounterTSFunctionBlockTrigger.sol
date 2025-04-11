// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "../../../../../AutomateTaskCreator.sol";

/**
 * @dev
 * Contract that creates a Web3 Function task with a block trigger
 */
contract CounterTSFunctionBlockTrigger is AutomateTaskCreator {
    uint256 public count;
    uint256 public lastExecuted;
    uint256 public lastBlockNumber;
    bytes32 public taskId;
    uint256 public constant MAX_COUNT = 5;
    
    event CounterTaskCreated(bytes32 taskId);
    event CounterTaskCancelled(bytes32 taskId);
    
    constructor(address _automate) AutomateTaskCreator(_automate) {}
    
    function createTask(
        string memory _web3FunctionHash,
        bytes calldata _web3FunctionArgsHex
    ) external {
        require(taskId == bytes32(""), "Already started task");
        
        // Setup module data with Web3 Function + block trigger
        ModuleData memory moduleData = ModuleData({
            modules: new Module[](3),
            args: new bytes[](3)
        });
        
        moduleData.modules[0] = Module.PROXY;
        moduleData.modules[1] = Module.WEB3_FUNCTION;
        moduleData.modules[2] = Module.TRIGGER;
        
        moduleData.args[0] = _proxyModuleArg();
        moduleData.args[1] = _web3FunctionModuleArg(
            _web3FunctionHash,
            _web3FunctionArgsHex
        );
        
        // Configure block trigger - will execute on every new block
        moduleData.args[2] = _blockTriggerModuleArg();
        
        // Function to execute when Web3 Function returns true
        bytes memory execData = abi.encodeCall(this.increaseCount, (1));
        
        // Register task with Gelato using 1balance
        bytes32 id = _createTask(
            address(this),
            execData,
            moduleData,
            address(0) // address(0) means use 1balance
        );
        
        taskId = id;
        lastBlockNumber = block.number;
        emit CounterTaskCreated(id);
    }
    
    function increaseCount(uint256 _amount) external onlyDedicatedMsgSender {
        // Save the current block number
        lastBlockNumber = block.number;
        
        uint256 newCount = count + _amount;
        if (newCount >= MAX_COUNT) {
            _cancelTask(taskId);
            count = 0;
        } else {
            count += _amount;
            lastExecuted = block.timestamp;
        }
    }
    
    function cancelTask() external {
        require(taskId != bytes32(""), "No task to cancel");
        _cancelTask(taskId);
        emit CounterTaskCancelled(taskId);
        taskId = bytes32("");
    }
}