// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "../../../../../AutomateTaskCreator.sol";

// task ID: https://app.gelato.network/functions/task/0xe0d49f33f19c11cb5671fc4ba3d006e4de73038f56397bacedefd02575ce55ab:11155111

/**
 * @dev
 * Contract that creates a Web3 Function task with single execution
 */
contract CounterTSFunctionSingleExec is AutomateTaskCreator {
    uint256 public count;
    uint256 public lastExecuted;
    bytes32 public taskId;
    
    // Task events
    event CounterTaskCreated(bytes32 taskId);

    constructor(address _automate) AutomateTaskCreator(_automate) {}

    function createTask(
        string memory _web3FunctionHash,
        bytes calldata _web3FunctionArgsHex
    ) external {
        require(taskId == bytes32(""), "Already started task");

        // Setup module data with Web3 Function + single execution
        ModuleData memory moduleData = ModuleData({
            modules: new Module[](3),
            args: new bytes[](3)
        });

        // Modules must be in ascending order according to the Module enum
        moduleData.modules[0] = Module.PROXY;
        moduleData.modules[1] = Module.SINGLE_EXEC;
        moduleData.modules[2] = Module.WEB3_FUNCTION;

        moduleData.args[0] = _proxyModuleArg();
        moduleData.args[1] = _singleExecModuleArg();
        moduleData.args[2] = _web3FunctionModuleArg(
            _web3FunctionHash, 
            _web3FunctionArgsHex
        );

        // Function to execute when Web3 Function returns true
        bytes memory execData = abi.encodeCall(this.increaseCount, (1));

        // Register task with Gelato using 1balance
        bytes32 id = _createTask(
            address(this),
            execData,
            moduleData,
            address(0)  // address(0) means use 1balance
        );

        taskId = id;
        emit CounterTaskCreated(id);
    }

    function increaseCount(uint256 _amount) external onlyDedicatedMsgSender {
        count += _amount;
        lastExecuted = block.timestamp;
        // Task will be automatically cancelled after this execution
    }
} 