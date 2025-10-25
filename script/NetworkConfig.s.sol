// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

/**
 * @title Network Configuration
 * @dev Manages network-specific configurations for different chains
 */
contract NetworkConfig is Script {
    
    struct NetworkInfo {
        uint256 chainId;
        string name;
        string rpcUrl;
        address faucetAddress;
        uint256 blockConfirmations;
    }
    
    // Network configurations
    NetworkInfo public sepoliaConfig;
    NetworkInfo public mainnetConfig;
    NetworkInfo public localConfig;
    
    constructor() {
        // Sepolia testnet configuration
        sepoliaConfig = NetworkInfo({
            chainId: 11155111,
            name: "Sepolia",
            rpcUrl: "https://eth-sepolia.g.alchemy.com/v2/",
            faucetAddress: address(0), // No official faucet contract
            blockConfirmations: 3
        });
        
        // Ethereum mainnet configuration  
        mainnetConfig = NetworkInfo({
            chainId: 1,
            name: "Mainnet",
            rpcUrl: "https://eth-mainnet.g.alchemy.com/v2/",
            faucetAddress: address(0),
            blockConfirmations: 6
        });
        
        // Local development configuration
        localConfig = NetworkInfo({
            chainId: 31337,
            name: "Local",
            rpcUrl: "http://127.0.0.1:8545",
            faucetAddress: address(0),
            blockConfirmations: 1
        });
    }
    
    function getNetworkConfig() public view returns (NetworkInfo memory) {
        if (block.chainid == 11155111) {
            return sepoliaConfig;
        } else if (block.chainid == 1) {
            return mainnetConfig;
        } else {
            return localConfig;
        }
    }
    
    function getSepoliaConfig() public view returns (NetworkInfo memory) {
        return sepoliaConfig;
    }
    
    function getMainnetConfig() public view returns (NetworkInfo memory) {
        return mainnetConfig;
    }
    
    function getLocalConfig() public view returns (NetworkInfo memory) {
        return localConfig;
    }
    
    function isTestnet() public view returns (bool) {
        return block.chainid == 11155111 || block.chainid == 31337;
    }
    
    function isMainnet() public view returns (bool) {
        return block.chainid == 1;
    }
}