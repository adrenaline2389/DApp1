// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TransferContract} from "../src/TransferContract.sol";
import {TestToken} from "../src/TestToken.sol";

/**
 * @title Interact Script
 * @dev Script to interact with deployed contracts on Sepolia testnet
 */
contract InteractScript is Script {
    
    TransferContract public transferContract;
    TestToken public testToken;
    
    // These addresses should be updated after deployment
    address constant TRANSFER_CONTRACT_ADDRESS = 0x7214BA8c2AF04281D759E5185936507757e1c8c1; // Update after deployment
    address constant TEST_TOKEN_ADDRESS = 0x1074814fa9F5c646c421eF21c5e83e872bFbBED7; // Update after deployment
    
    function setUp() public {
        // Load contract instances if addresses are provided
        if (TRANSFER_CONTRACT_ADDRESS != address(0)) {
            transferContract = TransferContract(payable(TRANSFER_CONTRACT_ADDRESS));
        }
        if (TEST_TOKEN_ADDRESS != address(0)) {
            testToken = TestToken(TEST_TOKEN_ADDRESS);
        }
    }
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Interacting with contracts on Sepolia...");
        console.log("User address:", deployer);
        console.log("User balance:", deployer.balance);
        
        if (address(transferContract) == address(0) || address(testToken) == address(0)) {
            console.log("Please update contract addresses in Interact.s.sol");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Test contract interactions
        testBasicFunctionality();
        
        vm.stopBroadcast();
        
        // Query contract state (read-only)
        queryContractState();
    }
    
    function testBasicFunctionality() internal {
        console.log("\n=== Testing Basic Functionality ===");
        
        // 1. Test token faucet
        console.log("Testing token faucet...");
        uint256 faucetAmount = 100 * 10**18; // 100 tokens
        testToken.faucet(faucetAmount);
        console.log("Faucet successful, received:", faucetAmount);
        
        // 2. Test ETH deposit
        console.log("Testing ETH deposit...");
        uint256 depositAmount = 0.001 ether;
        transferContract.depositETH{value: depositAmount}();
        console.log("ETH deposit successful:", depositAmount);
        
        // 3. Test token approval
        console.log("Testing token approval...");
        uint256 approveAmount = 50 * 10**18;
        testToken.approve(address(transferContract), approveAmount);
        console.log("Token approval successful:", approveAmount);
        
        console.log("Basic functionality tests completed!");
    }
    
    function queryContractState() internal view {
        console.log("\n=== Contract State Query ===");
        
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        
        // Query TestToken state
        console.log("TestToken Information:");
        console.log("- Name:", testToken.name());
        console.log("- Symbol:", testToken.symbol());
        console.log("- Decimals:", testToken.decimals());
        console.log("- Total Supply:", testToken.totalSupply());
        console.log("- User Balance:", testToken.balanceOf(deployer));
        console.log("- Allowance to TransferContract:", testToken.allowance(deployer, address(transferContract)));
        
        // Query TransferContract state
        console.log("\nTransferContract Information:");
        console.log("- Contract Address:", address(transferContract));
        console.log("- Contract Owner:", transferContract.owner());
        console.log("- Contract ETH Balance:", transferContract.getContractBalance());
        console.log("- User ETH Balance in Contract:", transferContract.getUserETHBalance(deployer));
        
        console.log("\n=== State Query Complete ===");
    }
}