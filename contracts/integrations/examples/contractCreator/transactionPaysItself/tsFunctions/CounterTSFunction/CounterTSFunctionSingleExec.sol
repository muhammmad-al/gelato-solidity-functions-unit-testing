// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "../../../../../AutomateTaskCreator.sol";

// task ID: https://app.gelato.network/functions/task/0xc401aaeb0ebbecb76e2d8ff387105e39b60a22b302d0da00953a970d7d31ab68:11155111

/**
 * @dev
 * Contract that creates a Web3 Function task with single execution
 * using the transactionPaysItself fee model
 */
contract CounterTSFunctionSingleExec is AutomateTaskCreator {
    uint256 public count;
    uint256 public lastExecuted;
    bytes32 public taskId;
    
    // Task events
    event CounterTaskCreated(bytes32 taskId);
    event CounterExecuted(uint256 newCount, uint256 timestamp);

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
        
        // Update counter and timestamp
        count += _amount;
        lastExecuted = block.timestamp;
        
        // Task will be automatically cancelled after this execution
        taskId = bytes32("");

        emit CounterExecuted(count, block.timestamp);
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
} 