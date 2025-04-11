// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "../../../../../AutomateTaskCreator.sol";

// task ID: https://app.gelato.network/functions/task/0xd49ae826e1d16a46c57ee81abe164f9e74179817f3a1405c0a0003435f4ccb96:11155111

/**
 * @dev
 * Contract that creates a Web3 Function task with an event trigger
 * using the transactionPaysItself fee model
 */
contract CounterTSFunctionEventTrigger is AutomateTaskCreator {
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
    
    function createTask(
        string memory _web3FunctionHash,
        bytes calldata _web3FunctionArgsHex
    ) external {
        require(taskId == bytes32(""), "Already started task");
        
        // Setup module data with Web3 Function + event trigger
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
        
        // Configure event trigger to listen for TriggerEvent
        bytes32[][] memory topics = new bytes32[][](1);
        topics[0] = new bytes32[](1);
        topics[0][0] = keccak256("TriggerEvent(address,uint256)");
        
        moduleData.args[2] = _eventTriggerModuleArg(
            address(this),  // Contract to listen to
            topics,         // Event topics to filter
            0              // No block confirmations needed
        );
        
        // Function to execute when Web3 Function returns true
        bytes memory execData = abi.encodeCall(this.increaseCount, (1));
        
        // Register task with Gelato using transactionPaysItself (ETH as fee token)
        bytes32 id = _createTask(
            address(this),
            execData,
            moduleData,
            ETH // Use ETH for transactionPaysItself model
        );
        
        taskId = id;
        emit CounterTaskCreated(id);
    }
    
    function increaseCount(uint256 _amount) external payable onlyDedicatedMsgSender {
        // Get the fee details from Gelato
        (uint256 fee, address feeToken) = _getFeeDetails();
        
        // Make sure this contract has enough ETH to pay the fee
        require(address(this).balance >= fee, "Not enough ETH for fee");
        
        // Pay the fee to Gelato
        _transfer(fee, feeToken);
        
        // Now handle the counter logic
        uint256 newCount = count + _amount;
        if (newCount >= MAX_COUNT) {
            _cancelTask(taskId);
            count = 0;
            taskId = bytes32("");
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
    
    // Function to check if contract has enough ETH for next execution
    function checkFunds() external view returns (bool hasSufficientFunds, uint256 currentBalance, uint256 estimatedFee) {
        (uint256 fee, ) = _getFeeDetails();
        return (address(this).balance >= fee, address(this).balance, fee);
    }
    
    // Function to receive ETH
    receive() external payable {}
    
    // Function to deposit ETH
    function deposit() external payable {}
    
    // Function to emit the trigger event
    function emitTriggerEvent() external {
        emit TriggerEvent(msg.sender, block.timestamp);
    }
} 