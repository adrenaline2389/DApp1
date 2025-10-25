// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TransferContract} from "../src/TransferContract.sol";
import {TestToken} from "../src/TestToken.sol";

/**
 * @title Deploy Script
 * @dev Deployment script for TransferContract and TestToken on Sepolia testnet
 */
contract DeployScript is Script {
    
    // Deployment addresses will be stored here
    TransferContract public transferContract;
    TestToken public testToken;
    
    // Configuration
    string constant TOKEN_NAME = "Sepolia Test Token";
    string constant TOKEN_SYMBOL = "STT";
    uint8 constant TOKEN_DECIMALS = 18;
    uint256 constant INITIAL_SUPPLY = 1000000; // 1M tokens
    
    function setUp() public {}
    
    function run() public {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts to Sepolia testnet...");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        // Check if deployer has enough ETH
        require(deployer.balance > 0.01 ether, "Insufficient ETH balance for deployment");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy TestToken first
        console.log("Deploying TestToken...");
        testToken = new TestToken(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            TOKEN_DECIMALS,
            INITIAL_SUPPLY
        );
        console.log("TestToken deployed at:", address(testToken));
        console.log("Total supply:", testToken.totalSupply());
        
        // Deploy TransferContract
        console.log("Deploying TransferContract...");
        transferContract = new TransferContract();
        console.log("TransferContract deployed at:", address(transferContract));
        console.log("Contract owner:", transferContract.owner());
        
        vm.stopBroadcast();
        
        // Log deployment summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Network: Sepolia Testnet");
        console.log("Deployer:", deployer);
        console.log("TestToken:", address(testToken));
        console.log("TransferContract:", address(transferContract));
        console.log("========================\n");
        
        // Save deployment addresses to file
        saveDeploymentInfo();
        
        // Verify contracts are working
        verifyDeployment();
    }
    
    function saveDeploymentInfo() internal view {
        // Create deployment info that can be used by other scripts
        string memory deploymentInfo = string.concat(
            "SEPOLIA_TEST_TOKEN=", vm.toString(address(testToken)), "\n",
            "SEPOLIA_TRANSFER_CONTRACT=", vm.toString(address(transferContract)), "\n",
            "DEPLOYER=", vm.toString(vm.addr(vm.envUint("PRIVATE_KEY"))), "\n"
        );
        
        // Write to deployment file (this would need to be handled externally)
        console.log("Deployment addresses:");
        console.log(deploymentInfo);
    }
    
    function verifyDeployment() internal view {
        console.log("Verifying deployment...");
        
        // Verify TestToken
        require(bytes(testToken.name()).length > 0, "TestToken name not set");
        require(bytes(testToken.symbol()).length > 0, "TestToken symbol not set");
        require(testToken.decimals() == TOKEN_DECIMALS, "TestToken decimals incorrect");
        require(testToken.totalSupply() > 0, "TestToken total supply is zero");
        
        // Verify TransferContract
        require(transferContract.owner() != address(0), "TransferContract owner not set");
        require(transferContract.getContractBalance() == 0, "TransferContract should have zero balance initially");
        
        console.log("Deployment verification completed successfully!");
    }
}