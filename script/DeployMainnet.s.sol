// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { TransferContract } from "../src/TransferContract.sol";

/**
 * @title DeployMainnet
 * @author Your Name
 * @notice This script deploys ONLY the TransferContract to the Ethereum mainnet.
 *         It uses the 'mainnet' profile from foundry.toml for high optimization.
 *         WARNING: This is for MAINNET. Double-check all parameters.
 */
contract DeployMainnet is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("MAINNET_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        // --- PRE-DEPLOYMENT SAFETY CHECKS ---
        console.log("========================================");
        console.log("         *** MAINNET DEPLOYMENT ***         ");
        console.log("========================================");
        console.log("Deployer Address:", deployerAddress);
        console.log("Current Balance:", deployerAddress.balance / 1 ether, "ETH");
        console.log("Chain ID:", block.chainid);

        if (block.chainid != 1) {
            revert("ERROR: Not on Ethereum Mainnet (Chain ID 1). Aborting deployment.");
        }
        
        // Add a long delay to allow for cancellation
        console.log("WARNING: You have 15 seconds to cancel this deployment (Ctrl+C).");
        vm.sleep(15);

        // --- DEPLOYMENT ---
        vm.startBroadcast(deployerPrivateKey);

        console.log("\nDeploying TransferContract to MAINNET...");
        TransferContract transferContract = new TransferContract();
        console.log("SUCCESS: TransferContract deployed to:", address(transferContract));

        vm.stopBroadcast();

        // --- POST-DEPLOYMENT INFO ---
        console.log("\nDeployment successful!");
        console.log("Mainnet TransferContract Address:", address(transferContract));
        console.log("Don't forget to verify on Etherscan!");
    }
}
