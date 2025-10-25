// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title ITransferContract
 * @dev Interface for the transfer contract functionality
 */
interface ITransferContract {
    
    // Events
    event ETHTransfer(address indexed from, address indexed to, uint256 amount);
    event ERC20Transfer(address indexed token, address indexed from, address indexed to, uint256 amount);
    event ETHDeposit(address indexed from, uint256 amount);
    event ETHWithdraw(address indexed to, uint256 amount);
    
    // ETH Functions
    function depositETH() external payable;
    function transferETH(address payable to, uint256 amount) external;
    function directTransferETH(address payable to) external payable;
    function withdrawETH(uint256 amount) external;
    
    // ERC20 Functions
    function transferERC20(address token, address to, uint256 amount) external;
    
    // Batch Functions
    function batchTransferETH(
        address payable[] calldata recipients,
        uint256[] calldata amounts
    ) external payable;
    
    function batchTransferERC20(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external;
    
    // View Functions
    function getContractBalance() external view returns (uint256);
    function getUserETHBalance(address user) external view returns (uint256);
    function getERC20Balance(address token, address user) external view returns (uint256);
}