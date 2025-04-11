// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "../../../../../AutomateTaskCreator.sol";

/**
 * @dev
 * Contract that creates a resolver task that executes only once
 */
contract CounterCheckerSingleExec is AutomateTaskCreator {
    uint256 public count;
    uint256 public lastExecuted;
    bytes32 public taskId;
    bool public hasExecuted;
    
    // Task events
    event CounterTaskCreated(bytes32 taskId);
    event CounterTaskCancelled(bytes32 taskId);
    event SingleExecutionCompleted(uint256 timestamp);

    constructor(address _automate) AutomateTaskCreator(_automate) {}

    function createTask() external {
        require(taskId == bytes32(""), "Already started task");
        require(!hasExecuted, "Task has already executed once");

        // Setup module data with resolver + time trigger
        ModuleData memory moduleData = ModuleData({
            modules: new Module[](3),
            args: new bytes[](3)
        });

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.PROXY;
        moduleData.modules[2] = Module.TRIGGER;

        moduleData.args[0] = _resolverModuleArg(
            address(this),
            abi.encodeCall(this.checker, ())
        );

        moduleData.args[1] = _proxyModuleArg();

        // Configure time trigger to execute immediately
        moduleData.args[2] = _timeTriggerModuleArg(
            0,  // Execute immediately
            0   // No interval (will only execute once)
        );

        // Use selector of function to be called with argument
        bytes memory execSelector = abi.encodeCall(this.increaseCount, (1));

        // Register task with Gelato using 1balance
        bytes32 id = _createTask(
            address(this),
            execSelector,
            moduleData,
            address(0)  // address(0) means use 1balance
        );

        taskId = id;
        emit CounterTaskCreated(id);
    }

    function increaseCount(uint256 _amount) external onlyDedicatedMsgSender {
        // Increment the counter
        count += _amount;
        lastExecuted = block.timestamp;
        
        // Mark as executed and cancel the task
        hasExecuted = true;
        emit SingleExecutionCompleted(block.timestamp);
        cancelTask();
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        // Only execute if it hasn't executed yet
        canExec = !hasExecuted;
        execPayload = abi.encodeCall(this.increaseCount, (1));
    }

    function cancelTask() public {
        require(taskId != bytes32(""), "No task to cancel");
        _cancelTask(taskId);
        emit CounterTaskCancelled(taskId);
        taskId = bytes32("");
    }
} 