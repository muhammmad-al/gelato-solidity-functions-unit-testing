// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "../../../../../AutomateTaskCreator.sol";

// CID: QmQa6b9fwHRDgJQcjrXpKgsfERZmJAm4GSaiP5Z1U2dPeT
// task ID: https://app.gelato.network/functions/task/0x02408b152e917cd023cba2ff38f8d290f84a7876e85bc5dd9ef8a77a7d4b7534:11155111

/**
 * @dev
 * Contract that creates a Web3 Function task with a time trigger
 */
contract CounterTSFunctionTimeTrigger is AutomateTaskCreator {
    uint256 public count;
    uint256 public lastExecuted;
    bytes32 public taskId;
    uint256 public constant MAX_COUNT = 5;
    uint256 public constant INTERVAL = 3 minutes;
    
    event CounterTaskCreated(bytes32 taskId);
    event CounterTaskCancelled(bytes32 taskId);
    
    constructor(address _automate) AutomateTaskCreator(_automate) {}
    
    function createTask(
        string memory _web3FunctionHash,
        bytes calldata _web3FunctionArgsHex
    ) external {
        require(taskId == bytes32(""), "Already started task");
        
        // Setup module data with Web3 Function + time trigger
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
        
        // Configure time trigger with the interval
        moduleData.args[2] = _timeTriggerModuleArg(
            uint128(block.timestamp), // Start now
            uint128(INTERVAL) // Run every INTERVAL seconds
        );
        
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
        emit CounterTaskCreated(id);
    }
    
    function increaseCount(uint256 _amount) external onlyDedicatedMsgSender {
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