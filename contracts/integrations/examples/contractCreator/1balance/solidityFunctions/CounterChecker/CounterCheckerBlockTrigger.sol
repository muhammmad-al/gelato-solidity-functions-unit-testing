// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "../../../../../AutomateTaskCreator.sol";

// task ID: https://app.gelato.network/functions/task/0xe6c0d4703a465a26e3cc8674e296cc59fe5a31e246490020756c8fc4b1f6199c:11155111

/**
 * @dev
 * Contract that creates a resolver task with a block trigger
 */
contract CounterCheckerBlockTrigger is AutomateTaskCreator {
    uint256 public count;
    uint256 public lastExecuted;
    bytes32 public taskId;
    uint256 public constant MAX_COUNT = 5;

    event CounterTaskCreated(bytes32 taskId);
    event CounterTaskCancelled(bytes32 taskId);

    constructor(address _automate) AutomateTaskCreator(_automate) {}

    function createTask() external {
        require(taskId == bytes32(""), "Already started task");

        // Setup module data with resolver + block trigger
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

        // Configure block trigger
        moduleData.args[2] = _blockTriggerModuleArg();

        // Use selector of function to be called
        bytes memory execSelector = abi.encodeWithSelector(this.increaseCount.selector);

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
        canExec = true; // The trigger module handles the block checking
        execPayload = abi.encodeCall(this.increaseCount, (1));
    }

    function cancelTask() public {
        require(taskId != bytes32(""), "No task to cancel");
        _cancelTask(taskId);
        emit CounterTaskCancelled(taskId);
        taskId = bytes32("");
    }
} 