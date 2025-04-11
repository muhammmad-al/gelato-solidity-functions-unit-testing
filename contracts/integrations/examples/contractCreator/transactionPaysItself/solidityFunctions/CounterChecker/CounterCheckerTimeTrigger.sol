// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "../../../../../AutomateTaskCreator.sol";

// task ID: https://app.gelato.network/functions/task/0x44d7c07e71ca13bc7ecb5ca9109163d9ed87c9211d2d36f7f6714ba13083701e:11155111

/**
 * @dev
 * Contract that creates a resolver task with a time trigger
 * using the transactionPaysItself fee model
 */
contract CounterCheckerTimeTrigger is AutomateTaskCreator {
    uint256 public count;
    uint256 public lastExecuted;
    bytes32 public taskId;
    uint256 public constant MAX_COUNT = 5;
    uint256 public constant INTERVAL = 3 minutes;
    
    // Address constant for ETH (native token)
    // address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    event CounterTaskCreated(bytes32 taskId);
    event CounterTaskCancelled(bytes32 taskId);
    
    constructor(address _automate) AutomateTaskCreator(_automate) {}
    
    function createTask() external {
        require(taskId == bytes32(""), "Already started task");
        
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
        
        // Configure time trigger with the interval
        moduleData.args[2] = _timeTriggerModuleArg(
            uint128(block.timestamp), // Start now
            uint128(INTERVAL) // Run every INTERVAL seconds
        );
        
        // Use selector of function to be called
        bytes memory execSelector = abi.encodeWithSelector(this.increaseCount.selector);
        
        // Register task with Gelato using transactionPaysItself
        bytes32 id = _createTask(
            address(this),
            execSelector,
            moduleData,
            ETH // Use ETH for transactionPaysItself
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
        // Get the fee that will be charged for this execution
        (uint256 fee, ) = _getFeeDetails();
        
        // Check if contract has enough ETH to pay for the execution
        if (address(this).balance < fee) {
            return (false, bytes("Not enough ETH for fee"));
        }
        
        // The trigger module handles the interval checking
        canExec = true;
        execPayload = abi.encodeCall(this.increaseCount, (1));
    }
    
    function cancelTask() public {
        require(taskId != bytes32(""), "No task to cancel");
        _cancelTask(taskId);
        emit CounterTaskCancelled(taskId);
        taskId = bytes32("");
    }
    
    // Function to receive ETH
    receive() external payable {}
    
    // Function to deposit ETH
    function deposit() external payable {}
    
    // Function to check if contract has enough ETH for next execution
    function checkFunds() external view returns (bool hasSufficientFunds, uint256 currentBalance, uint256 estimatedFee) {
        (uint256 fee, ) = _getFeeDetails();
        return (address(this).balance >= fee, address(this).balance, fee);
    }
}