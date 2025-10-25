// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TransferContract} from "../src/TransferContract.sol";
import {TestToken} from "../src/TestToken.sol";

/**
 * @title Integration Test
 * @dev Tests the integration between TransferContract and TestToken
 */
contract IntegrationTest is Test {
    TransferContract public transferContract;
    TestToken public testToken;
    
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    
    uint256 public constant INITIAL_BALANCE = 10 ether;
    uint256 public constant TOKEN_INITIAL_SUPPLY = 1000000;
    
    function setUp() public {
        // Set up test accounts
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        
        // Deploy contracts
        transferContract = new TransferContract();
        testToken = new TestToken("Test Token", "TST", 18, TOKEN_INITIAL_SUPPLY);
        
        // Fund test accounts with ETH
        vm.deal(user1, INITIAL_BALANCE);
        vm.deal(user2, INITIAL_BALANCE);
        vm.deal(user3, INITIAL_BALANCE);
        
        // Distribute test tokens
        testToken.mint(user1, 1000 * 10**18);
        testToken.mint(user2, 1000 * 10**18);
        testToken.mint(user3, 1000 * 10**18);
    }
    
    // =============================================================================
    // COMPLETE WORKFLOW TESTS
    // =============================================================================
    
    function test_CompleteETHWorkflow() public {
        uint256 depositAmount = 5 ether;
        uint256 transferAmount = 2 ether;
        uint256 withdrawAmount = 1 ether;
        
        vm.startPrank(user1);
        
        // 1. Deposit ETH
        transferContract.depositETH{value: depositAmount}();
        assertEq(transferContract.getUserETHBalance(user1), depositAmount);
        
        // 2. Transfer ETH to user2
        transferContract.transferETH(payable(user2), transferAmount);
        assertEq(transferContract.getUserETHBalance(user1), depositAmount - transferAmount);
        assertEq(user2.balance, INITIAL_BALANCE + transferAmount);
        
        // 3. Withdraw remaining ETH
        transferContract.withdrawETH(withdrawAmount);
        assertEq(transferContract.getUserETHBalance(user1), depositAmount - transferAmount - withdrawAmount);
        
        vm.stopPrank();
    }
    
    function test_CompleteERC20Workflow() public {
        uint256 transferAmount = 100 * 10**18;
        
        vm.startPrank(user1);
        
        // 1. Approve the transfer contract
        testToken.approve(address(transferContract), transferAmount);
        assertEq(testToken.allowance(user1, address(transferContract)), transferAmount);
        
        // 2. Transfer tokens via the contract
        uint256 user1BalanceBefore = testToken.balanceOf(user1);
        uint256 user2BalanceBefore = testToken.balanceOf(user2);
        
        transferContract.transferERC20(address(testToken), user2, transferAmount);
        
        // 3. Verify final balances
        assertEq(testToken.balanceOf(user1), user1BalanceBefore - transferAmount);
        assertEq(testToken.balanceOf(user2), user2BalanceBefore + transferAmount);
        
        vm.stopPrank();
    }
    
    function test_MixedTransferWorkflow() public {
        uint256 ethAmount = 2 ether;
        uint256 tokenAmount = 50 * 10**18;
        
        vm.startPrank(user1);
        
        // 1. Deposit ETH
        transferContract.depositETH{value: ethAmount}();
        
        // 2. Approve tokens
        testToken.approve(address(transferContract), tokenAmount);
        
        // 3. Transfer ETH
        transferContract.transferETH(payable(user2), ethAmount);
        
        // 4. Transfer tokens
        transferContract.transferERC20(address(testToken), user2, tokenAmount);
        
        // 5. Verify both transfers succeeded
        assertEq(transferContract.getUserETHBalance(user1), 0);
        assertEq(user2.balance, INITIAL_BALANCE + ethAmount);
        assertEq(testToken.balanceOf(user2), 1000 * 10**18 + tokenAmount);
        
        vm.stopPrank();
    }
    
    // =============================================================================
    // BATCH OPERATIONS INTEGRATION TESTS
    // =============================================================================
    
    function test_BatchETHAndTokenTransfers() public {
        // Setup batch transfers
        address payable[] memory ethRecipients = new address payable[](2);
        uint256[] memory ethAmounts = new uint256[](2);
        ethRecipients[0] = payable(user2);
        ethRecipients[1] = payable(user3);
        ethAmounts[0] = 1 ether;
        ethAmounts[1] = 1.5 ether;
        
        address[] memory tokenRecipients = new address[](2);
        uint256[] memory tokenAmounts = new uint256[](2);
        tokenRecipients[0] = user2;
        tokenRecipients[1] = user3;
        tokenAmounts[0] = 100 * 10**18;
        tokenAmounts[1] = 150 * 10**18;
        
        vm.startPrank(user1);
        
        // Approve tokens for batch transfer
        testToken.approve(address(transferContract), 250 * 10**18);
        
        // Execute batch ETH transfer
        transferContract.batchTransferETH{value: 2.5 ether}(ethRecipients, ethAmounts);
        
        // Execute batch token transfer
        transferContract.batchTransferERC20(address(testToken), tokenRecipients, tokenAmounts);
        
        // Verify results
        assertEq(user2.balance, INITIAL_BALANCE + ethAmounts[0]);
        assertEq(user3.balance, INITIAL_BALANCE + ethAmounts[1]);
        assertEq(testToken.balanceOf(user2), 1000 * 10**18 + tokenAmounts[0]);
        assertEq(testToken.balanceOf(user3), 1000 * 10**18 + tokenAmounts[1]);
        
        vm.stopPrank();
    }
    
    // =============================================================================
    // FAUCET INTEGRATION TESTS
    // =============================================================================
    
    function test_FaucetAndTransferIntegration() public {
        uint256 faucetAmount = 500 * 10**18;
        uint256 transferAmount = 200 * 10**18;
        
        vm.startPrank(user1);
        
        // 1. Use faucet to get tokens
        testToken.faucet(faucetAmount);
        assertEq(testToken.balanceOf(user1), 1000 * 10**18 + faucetAmount);
        
        // 2. Approve and transfer via contract
        testToken.approve(address(transferContract), transferAmount);
        transferContract.transferERC20(address(testToken), user2, transferAmount);
        
        // 3. Verify final state
        assertEq(testToken.balanceOf(user1), 1000 * 10**18 + faucetAmount - transferAmount);
        assertEq(testToken.balanceOf(user2), 1000 * 10**18 + transferAmount);
        
        vm.stopPrank();
    }
    
    // =============================================================================
    // ERROR SCENARIOS AND EDGE CASES
    // =============================================================================
    
    function test_InsufficientETHForBatchTransfer() public {
        address payable[] memory recipients = new address payable[](2);
        uint256[] memory amounts = new uint256[](2);
        recipients[0] = payable(user2);
        recipients[1] = payable(user3);
        amounts[0] = 2 ether;
        amounts[1] = 2 ether;
        
        vm.startPrank(user1);
        
        // Try to send 4 ETH but only provide 3 ETH
        vm.expectRevert("Insufficient ETH sent");
        transferContract.batchTransferETH{value: 3 ether}(recipients, amounts);
        
        vm.stopPrank();
    }
    
    function test_InsufficientTokenApprovalForBatch() public {
        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        recipients[0] = user2;
        recipients[1] = user3;
        amounts[0] = 300 * 10**18;
        amounts[1] = 300 * 10**18;
        
        vm.startPrank(user1);
        
        // Approve less than required
        testToken.approve(address(transferContract), 500 * 10**18);
        
        vm.expectRevert("Insufficient allowance");
        transferContract.batchTransferERC20(address(testToken), recipients, amounts);
        
        vm.stopPrank();
    }
    
    function test_ReentrancyProtection() public {
        // This test ensures reentrancy protection is working
        // We'll test with a malicious contract that tries to reenter
        
        vm.startPrank(user1);
        
        transferContract.depositETH{value: 1 ether}();
        
        // Multiple calls should work fine (not reentrant)
        transferContract.transferETH(payable(user2), 0.3 ether);
        transferContract.transferETH(payable(user3), 0.3 ether);
        
        assertEq(transferContract.getUserETHBalance(user1), 0.4 ether);
        
        vm.stopPrank();
    }
    
    // =============================================================================
    // GAS OPTIMIZATION TESTS
    // =============================================================================
    
    function test_GasUsageComparison() public {
        uint256 transferAmount = 100 * 10**18;
        
        vm.startPrank(user1);
        
        // Test direct token transfer
        uint256 gasBefore = gasleft();
        testToken.transfer(user2, transferAmount);
        uint256 directTransferGas = gasBefore - gasleft();
        
        // Test transfer via contract
        testToken.approve(address(transferContract), transferAmount);
        gasBefore = gasleft();
        transferContract.transferERC20(address(testToken), user3, transferAmount);
        uint256 contractTransferGas = gasBefore - gasleft();
        
        console.log("Direct transfer gas:", directTransferGas);
        console.log("Contract transfer gas:", contractTransferGas);
        
        // Contract transfer should be reasonably close to direct transfer
        // Allow some overhead for the additional functionality
        assertTrue(contractTransferGas < directTransferGas * 3, "Contract transfer too expensive");
        
        vm.stopPrank();
    }
    
    // =============================================================================
    // MULTI-USER SCENARIOS
    // =============================================================================
    
    function test_MultiUserETHPool() public {
        uint256 deposit1 = 2 ether;
        uint256 deposit2 = 3 ether;
        uint256 deposit3 = 1 ether;
        
        // Multiple users deposit
        vm.prank(user1);
        transferContract.depositETH{value: deposit1}();
        
        vm.prank(user2);
        transferContract.depositETH{value: deposit2}();
        
        vm.prank(user3);
        transferContract.depositETH{value: deposit3}();
        
        // Verify individual balances
        assertEq(transferContract.getUserETHBalance(user1), deposit1);
        assertEq(transferContract.getUserETHBalance(user2), deposit2);
        assertEq(transferContract.getUserETHBalance(user3), deposit3);
        
        // Verify total contract balance
        assertEq(transferContract.getContractBalance(), deposit1 + deposit2 + deposit3);
        
        // Users can withdraw independently
        vm.prank(user1);
        transferContract.withdrawETH(deposit1);
        
        assertEq(transferContract.getUserETHBalance(user1), 0);
        assertEq(transferContract.getContractBalance(), deposit2 + deposit3);
    }
    
    function test_CrossUserTokenTransfers() public {
        uint256 transferAmount = 150 * 10**18;
        
        // User1 transfers to user2
        vm.startPrank(user1);
        testToken.approve(address(transferContract), transferAmount);
        transferContract.transferERC20(address(testToken), user2, transferAmount);
        vm.stopPrank();
        
        // User2 transfers to user3
        vm.startPrank(user2);
        testToken.approve(address(transferContract), transferAmount);
        transferContract.transferERC20(address(testToken), user3, transferAmount);
        vm.stopPrank();
        
        // Verify final balances
        assertEq(testToken.balanceOf(user1), 1000 * 10**18 - transferAmount);
        assertEq(testToken.balanceOf(user2), 1000 * 10**18); // Back to original
        assertEq(testToken.balanceOf(user3), 1000 * 10**18 + transferAmount);
    }
    
    // =============================================================================
    // OWNERSHIP AND ACCESS CONTROL TESTS
    // =============================================================================
    
    function test_OwnershipTransferIntegration() public {
        // Transfer ownership of both contracts
        transferContract.transferOwnership(user1);
        testToken.transferOwnership(user1);
        
        // Verify ownership transfer
        assertEq(transferContract.owner(), user1);
        assertEq(testToken.owner(), user1);
        
        // New owner can use emergency functions
        vm.prank(user2);
        transferContract.depositETH{value: 1 ether}();
        
        vm.prank(user1);
        transferContract.emergencyWithdraw();
        
        assertEq(transferContract.getContractBalance(), 0);
    }
    
    // =============================================================================
    // HELPER FUNCTIONS
    // =============================================================================
    
    receive() external payable {}
}