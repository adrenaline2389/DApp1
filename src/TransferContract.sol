// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TransferContract
 * @dev A contract that enables ETH and ERC20 token transfers with security features
 */
contract TransferContract is Ownable, ReentrancyGuard {
    
    // Events
    event ETHTransfer(address indexed from, address indexed to, uint256 amount);
    event ERC20Transfer(address indexed token, address indexed from, address indexed to, uint256 amount);
    event ETHDeposit(address indexed from, uint256 amount);
    event ETHWithdraw(address indexed to, uint256 amount);
    
    // Mapping to track user balances
    mapping(address => uint256) public ethBalances;
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Deposit ETH to the contract
     */
    function depositETH() external payable {
        require(msg.value > 0, "Amount must be greater than 0");
        ethBalances[msg.sender] += msg.value;
        emit ETHDeposit(msg.sender, msg.value);
    }
    
    /**
     * @dev Transfer ETH from contract balance to another address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function transferETH(address payable to, uint256 amount) external nonReentrant {
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        require(ethBalances[msg.sender] >= amount, "Insufficient balance");
        
        ethBalances[msg.sender] -= amount;
        
        (bool success, ) = to.call{value: amount}("");
        require(success, "ETH transfer failed");
        
        emit ETHTransfer(msg.sender, to, amount);
    }
    
    /**
     * @dev Transfer ETH directly (sender pays gas)
     * @param to Recipient address
     */
    function directTransferETH(address payable to) external payable nonReentrant {
        require(to != address(0), "Invalid recipient address");
        require(msg.value > 0, "Amount must be greater than 0");
        
        (bool success, ) = to.call{value: msg.value}("");
        require(success, "ETH transfer failed");
        
        emit ETHTransfer(msg.sender, to, msg.value);
    }
    
    /**
     * @dev Transfer ERC20 tokens
     * @param token ERC20 token contract address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function transferERC20(
        address token,
        address to,
        uint256 amount
    ) external nonReentrant {
        require(token != address(0), "Invalid token address");
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20 erc20Token = IERC20(token);
        
        // Check if sender has enough balance
        require(erc20Token.balanceOf(msg.sender) >= amount, "Insufficient token balance");
        
        // Check if sender has approved this contract to spend tokens
        require(erc20Token.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        
        // Transfer tokens from sender to recipient
        bool success = erc20Token.transferFrom(msg.sender, to, amount);
        require(success, "Token transfer failed");
        
        emit ERC20Transfer(token, msg.sender, to, amount);
    }
    
    /**
     * @dev Batch transfer ETH to multiple recipients
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts to transfer
     */
    function batchTransferETH(
        address payable[] calldata recipients,
        uint256[] calldata amounts
    ) external payable nonReentrant {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length > 0, "No recipients provided");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        require(msg.value >= totalAmount, "Insufficient ETH sent");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(amounts[i] > 0, "Amount must be greater than 0");
            
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "ETH transfer failed");
            
            emit ETHTransfer(msg.sender, recipients[i], amounts[i]);
        }
        
        // Return excess ETH if any
        if (msg.value > totalAmount) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalAmount}("");
            require(success, "Excess ETH return failed");
        }
    }
    
    /**
     * @dev Batch transfer ERC20 tokens to multiple recipients
     * @param token ERC20 token contract address
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts to transfer
     */
    function batchTransferERC20(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant {
        require(token != address(0), "Invalid token address");
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length > 0, "No recipients provided");
        
        IERC20 erc20Token = IERC20(token);
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        require(erc20Token.balanceOf(msg.sender) >= totalAmount, "Insufficient token balance");
        require(erc20Token.allowance(msg.sender, address(this)) >= totalAmount, "Insufficient allowance");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(amounts[i] > 0, "Amount must be greater than 0");
            
            bool success = erc20Token.transferFrom(msg.sender, recipients[i], amounts[i]);
            require(success, "Token transfer failed");
            
            emit ERC20Transfer(token, msg.sender, recipients[i], amounts[i]);
        }
    }
    
    /**
     * @dev Withdraw ETH from contract balance
     * @param amount Amount to withdraw
     */
    function withdrawETH(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(ethBalances[msg.sender] >= amount, "Insufficient balance");
        
        ethBalances[msg.sender] -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH withdrawal failed");
        
        emit ETHWithdraw(msg.sender, amount);
    }
    
    /**
     * @dev Get contract ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get user's ETH balance in contract
     * @param user User address
     */
    function getUserETHBalance(address user) external view returns (uint256) {
        return ethBalances[user];
    }
    
    /**
     * @dev Get ERC20 token balance of an address
     * @param token ERC20 token contract address
     * @param user User address
     */
    function getERC20Balance(address token, address user) external view returns (uint256) {
        require(token != address(0), "Invalid token address");
        return IERC20(token).balanceOf(user);
    }
    
    /**
     * @dev Emergency function to withdraw all ETH (only owner)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Emergency withdrawal failed");
    }
    
    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {
        ethBalances[msg.sender] += msg.value;
        emit ETHDeposit(msg.sender, msg.value);
    }
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {
        ethBalances[msg.sender] += msg.value;
        emit ETHDeposit(msg.sender, msg.value);
    }
}