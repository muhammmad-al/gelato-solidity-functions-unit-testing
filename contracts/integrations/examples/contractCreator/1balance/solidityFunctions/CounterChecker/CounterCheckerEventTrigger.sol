// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "../../../../../AutomateTaskCreator.sol";

// task ID: https://app.gelato.network/functions/task/0x20419b24c22199c4aa23d67b759f841a0cafd113847e59c2ee10b97a54a0d627:11155111

/**
 * @dev
 * Contract that creates a resolver task with an event trigger
 */
contract CounterCheckerEventTrigger is AutomateTaskCreator {
    uint256 public count;
    uint256 public lastExecuted;
    bytes32 public taskId;
    uint256 public constant MAX_COUNT = 5;
    
    // Event that will trigger the task
    event TriggerEvent(address indexed sender, uint256 timestamp);
    
    // Task events
    event CounterTaskCreated(bytes32 taskId);
    event CounterTaskCancelled(bytes32 taskId);

    constructor(address _automate) AutomateTaskCreator(_automate) {}

    function createTask() external {
        require(taskId == bytes32(""), "Already started task");

        // Setup module data with resolver + event trigger
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

        // Configure event trigger to listen for TriggerEvent
        bytes32[][] memory topics = new bytes32[][](1);
        topics[0] = new bytes32[](1);
        topics[0][0] = keccak256("TriggerEvent(address,uint256)");
        
        moduleData.args[2] = _eventTriggerModuleArg(
            address(this),  // Contract to listen to
            topics,         // Event topics to filter
            0              // No block confirmations needed
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
        uint256 newCount = count + _amount;
        if (newCount >= MAX_COUNT) {
            cancelTask();
            count = 0;
        } else {
            count += _amount;
            lastExecuted = block.timestamp;
        }
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = true; // The trigger module handles the event checking
        execPayload = abi.encodeCall(this.increaseCount, (1));
    }

    function cancelTask() public {
        require(taskId != bytes32(""), "No task to cancel");
        _cancelTask(taskId);
        emit CounterTaskCancelled(taskId);
        taskId = bytes32("");
    }
    
    // Function to emit the trigger event
    function emitTriggerEvent() external {
        emit TriggerEvent(msg.sender, block.timestamp);
    }
} 