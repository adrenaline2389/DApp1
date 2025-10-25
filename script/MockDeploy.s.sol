// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TransferContract} from "../src/TransferContract.sol";
import {TestToken} from "../src/TestToken.sol";

/**
 * @title Mock Deploy Script
 * @dev 模拟部署脚本，用于在本地环境测试部署流程
 */
contract MockDeployScript is Script {
    
    TransferContract public transferContract;
    TestToken public testToken;
    
    // 模拟的部署地址
    address public constant MOCK_DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    
    function setUp() public {}
    
    function run() public {
        console.log("=== MOCK DEPLOYMENT TO SEPOLIA TESTNET ===");
        console.log("Deployer address:", MOCK_DEPLOYER);
        console.log("Simulating deployment process...");
        
        vm.startBroadcast(MOCK_DEPLOYER);
        
        // 模拟部署TestToken
        console.log("\n1. Deploying TestToken...");
        testToken = new TestToken("Sepolia Test Token", "STT", 18, 1000000);
        console.log("TestToken deployed at:", address(testToken));
        console.log("Initial supply:", testToken.totalSupply());
        
        // 模拟部署TransferContract
        console.log("\n2. Deploying TransferContract...");
        transferContract = new TransferContract();
        console.log("TransferContract deployed at:", address(transferContract));
        console.log("Contract owner:", transferContract.owner());
        
        vm.stopBroadcast();
        
        // 记录部署信息
        logDeploymentInfo();
        
        // 验证部署
        verifyDeployment();
        
        // 测试基本功能
        testBasicFunctionality();
        
        console.log("\n=== MOCK DEPLOYMENT COMPLETED SUCCESSFULLY ===");
    }
    
    function logDeploymentInfo() internal view {
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Network: Sepolia Testnet (Simulated)");
        console.log("Deployer:", MOCK_DEPLOYER);
        console.log("TestToken Address:", address(testToken));
        console.log("TransferContract Address:", address(transferContract));
        console.log("Gas Used: ~2,300,000 (estimated)");
        console.log("Deployment Cost: ~0.005 ETH (estimated)");
        console.log("==========================");
    }
    
    function verifyDeployment() internal view {
        console.log("\n=== VERIFYING DEPLOYMENT ===");
        
        // 验证TestToken
        require(address(testToken) != address(0), "TestToken deployment failed");
        require(testToken.totalSupply() > 0, "TestToken supply not set");
        require(keccak256(bytes(testToken.name())) == keccak256(bytes("Sepolia Test Token")), "TestToken name incorrect");
        console.log("TestToken verification passed");
        
        // 验证TransferContract
        require(address(transferContract) != address(0), "TransferContract deployment failed");
        require(transferContract.owner() == MOCK_DEPLOYER, "TransferContract owner incorrect");
        require(transferContract.getContractBalance() == 0, "TransferContract should start with zero balance");
        console.log("TransferContract verification passed");
        
        console.log("All deployment verifications passed!");
    }
    
    function testBasicFunctionality() internal {
        console.log("\n=== TESTING BASIC FUNCTIONALITY ===");
        
        vm.startBroadcast(MOCK_DEPLOYER);
        
        // 测试代币水龙头
        console.log("Testing token faucet...");
        uint256 faucetAmount = 100 * 10**18;
        testToken.faucet(faucetAmount);
        uint256 balance = testToken.balanceOf(MOCK_DEPLOYER);
        require(balance >= faucetAmount, "Faucet test failed");
        console.log("Token faucet working, balance:", balance);
        
        // 测试代币批准
        console.log("Testing token approval...");
        uint256 approveAmount = 50 * 10**18;
        testToken.approve(address(transferContract), approveAmount);
        uint256 allowance = testToken.allowance(MOCK_DEPLOYER, address(transferContract));
        require(allowance == approveAmount, "Approval test failed");
        console.log("Token approval working, allowance:", allowance);
        
        // 测试ETH存款 (模拟)
        console.log("Testing ETH deposit...");
        vm.deal(MOCK_DEPLOYER, 10 ether); // 模拟ETH余额
        uint256 depositAmount = 0.1 ether;
        transferContract.depositETH{value: depositAmount}();
        uint256 ethBalance = transferContract.getUserETHBalance(MOCK_DEPLOYER);
        require(ethBalance == depositAmount, "ETH deposit test failed");
        console.log("ETH deposit working, balance:", ethBalance);
        
        vm.stopBroadcast();
        
        console.log("All functionality tests passed!");
    }
}