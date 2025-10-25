// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TransferContract} from "../src/TransferContract.sol";
import {TestToken} from "../src/TestToken.sol";

contract TransferContractTest is Test {
    TransferContract public transferContract;
    TestToken public testToken;
    
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    
    uint256 public constant INITIAL_BALANCE = 10 ether;
    uint256 public constant TOKEN_INITIAL_SUPPLY = 1000000;
    
    event ETHTransfer(address indexed from, address indexed to, uint256 amount);
    event ERC20Transfer(address indexed token, address indexed from, address indexed to, uint256 amount);
    event ETHDeposit(address indexed from, uint256 amount);
    event ETHWithdraw(address indexed to, uint256 amount);
    
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
        
        // Mint test tokens to users
        testToken.mint(user1, 1000 * 10**18);
        testToken.mint(user2, 1000 * 10**18);
    }
    
    // =============================================================================
    // ETH DEPOSIT TESTS
    // =============================================================================
    
    function test_DepositETH() public {
        uint256 depositAmount = 1 ether;
        
        vm.startPrank(user1);
        
        // Test event emission
        vm.expectEmit(true, true, false, true);
        emit ETHDeposit(user1, depositAmount);
        
        transferContract.depositETH{value: depositAmount}();
        
        // Verify balance
        assertEq(transferContract.getUserETHBalance(user1), depositAmount);
        assertEq(transferContract.getContractBalance(), depositAmount);
        
        vm.stopPrank();
    }
    
    function test_DepositETH_ZeroAmount_ShouldRevert() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Amount must be greater than 0");
        transferContract.depositETH{value: 0}();
        
        vm.stopPrank();
    }
    
    function test_DepositETH_ReceiveFunction() public {
        uint256 depositAmount = 2 ether;
        
        vm.startPrank(user1);
        
        // Test event emission
        vm.expectEmit(true, true, false, true);
        emit ETHDeposit(user1, depositAmount);
        
        // Send ETH directly to contract
        (bool success, ) = address(transferContract).call{value: depositAmount}("");
        assertTrue(success);
        
        // Verify balance
        assertEq(transferContract.getUserETHBalance(user1), depositAmount);
        
        vm.stopPrank();
    }
    
    // =============================================================================
    // ETH TRANSFER TESTS
    // =============================================================================
    
    function test_TransferETH() public {
        uint256 depositAmount = 5 ether;
        uint256 transferAmount = 2 ether;
        
        vm.startPrank(user1);
        
        // First deposit ETH
        transferContract.depositETH{value: depositAmount}();
        
        // Test event emission
        vm.expectEmit(true, true, false, true);
        emit ETHTransfer(user1, user2, transferAmount);
        
        // Transfer ETH
        transferContract.transferETH(payable(user2), transferAmount);
        
        // Verify balances
        assertEq(transferContract.getUserETHBalance(user1), depositAmount - transferAmount);
        assertEq(user2.balance, INITIAL_BALANCE + transferAmount);
        
        vm.stopPrank();
    }
    
    function test_TransferETH_InsufficientBalance_ShouldRevert() public {
        uint256 depositAmount = 1 ether;
        uint256 transferAmount = 2 ether;
        
        vm.startPrank(user1);
        
        transferContract.depositETH{value: depositAmount}();
        
        vm.expectRevert("Insufficient balance");
        transferContract.transferETH(payable(user2), transferAmount);
        
        vm.stopPrank();
    }
    
    function test_TransferETH_ZeroAddress_ShouldRevert() public {
        vm.startPrank(user1);
        
        transferContract.depositETH{value: 1 ether}();
        
        vm.expectRevert("Invalid recipient address");
        transferContract.transferETH(payable(address(0)), 1 ether);
        
        vm.stopPrank();
    }
    
    function test_DirectTransferETH() public {
        uint256 transferAmount = 3 ether;
        
        vm.startPrank(user1);
        
        uint256 user2BalanceBefore = user2.balance;
        
        // Test event emission
        vm.expectEmit(true, true, false, true);
        emit ETHTransfer(user1, user2, transferAmount);
        
        transferContract.directTransferETH{value: transferAmount}(payable(user2));
        
        // Verify balance
        assertEq(user2.balance, user2BalanceBefore + transferAmount);
        
        vm.stopPrank();
    }
    
    // =============================================================================
    // ETH WITHDRAWAL TESTS
    // =============================================================================
    
    function test_WithdrawETH() public {
        uint256 depositAmount = 4 ether;
        uint256 withdrawAmount = 2 ether;
        
        vm.startPrank(user1);
        
        // Deposit first
        transferContract.depositETH{value: depositAmount}();
        
        uint256 user1BalanceBefore = user1.balance;
        
        // Test event emission
        vm.expectEmit(true, true, false, true);
        emit ETHWithdraw(user1, withdrawAmount);
        
        transferContract.withdrawETH(withdrawAmount);
        
        // Verify balances
        assertEq(transferContract.getUserETHBalance(user1), depositAmount - withdrawAmount);
        assertEq(user1.balance, user1BalanceBefore + withdrawAmount);
        
        vm.stopPrank();
    }
    
    // =============================================================================
    // ERC20 TRANSFER TESTS
    // =============================================================================
    
    function test_TransferERC20() public {
        uint256 transferAmount = 100 * 10**18;
        
        vm.startPrank(user1);
        
        // Approve the contract to spend tokens
        testToken.approve(address(transferContract), transferAmount);
        
        uint256 user1BalanceBefore = testToken.balanceOf(user1);
        uint256 user2BalanceBefore = testToken.balanceOf(user2);
        
        // Test event emission
        vm.expectEmit(true, true, true, true);
        emit ERC20Transfer(address(testToken), user1, user2, transferAmount);
        
        transferContract.transferERC20(address(testToken), user2, transferAmount);
        
        // Verify balances
        assertEq(testToken.balanceOf(user1), user1BalanceBefore - transferAmount);
        assertEq(testToken.balanceOf(user2), user2BalanceBefore + transferAmount);
        
        vm.stopPrank();
    }
    
    function test_TransferERC20_InsufficientBalance_ShouldRevert() public {
        uint256 transferAmount = 2000 * 10**18; // More than user1 has
        
        vm.startPrank(user1);
        
        testToken.approve(address(transferContract), transferAmount);
        
        vm.expectRevert("Insufficient token balance");
        transferContract.transferERC20(address(testToken), user2, transferAmount);
        
        vm.stopPrank();
    }
    
    function test_TransferERC20_InsufficientAllowance_ShouldRevert() public {
        uint256 transferAmount = 100 * 10**18;
        
        vm.startPrank(user1);
        
        // Don't approve or approve less than needed
        testToken.approve(address(transferContract), transferAmount - 1);
        
        vm.expectRevert("Insufficient allowance");
        transferContract.transferERC20(address(testToken), user2, transferAmount);
        
        vm.stopPrank();
    }
    
    // =============================================================================
    // BATCH TRANSFER TESTS
    // =============================================================================
    
    function test_BatchTransferETH() public {
        address payable[] memory recipients = new address payable[](2);
        uint256[] memory amounts = new uint256[](2);
        
        recipients[0] = payable(user2);
        recipients[1] = payable(user3);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;
        
        uint256 totalAmount = 3 ether;
        
        vm.startPrank(user1);
        
        uint256 user2BalanceBefore = user2.balance;
        uint256 user3BalanceBefore = user3.balance;
        
        transferContract.batchTransferETH{value: totalAmount}(recipients, amounts);
        
        // Verify balances
        assertEq(user2.balance, user2BalanceBefore + amounts[0]);
        assertEq(user3.balance, user3BalanceBefore + amounts[1]);
        
        vm.stopPrank();
    }
    
    function test_BatchTransferETH_ExcessETH_ShouldReturnExcess() public {
        address payable[] memory recipients = new address payable[](1);
        uint256[] memory amounts = new uint256[](1);
        
        recipients[0] = payable(user2);
        amounts[0] = 1 ether;
        
        uint256 sentAmount = 2 ether; // Send more than needed
        uint256 expectedExcess = 1 ether;
        
        vm.startPrank(user1);
        
        uint256 user1BalanceBefore = user1.balance;
        
        transferContract.batchTransferETH{value: sentAmount}(recipients, amounts);
        
        // Verify excess was returned
        assertEq(user1.balance, user1BalanceBefore - amounts[0]);
        
        vm.stopPrank();
    }
    
    function test_BatchTransferERC20() public {
        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        
        recipients[0] = user2;
        recipients[1] = user3;
        amounts[0] = 50 * 10**18;
        amounts[1] = 75 * 10**18;
        
        uint256 totalAmount = 125 * 10**18;
        
        vm.startPrank(user1);
        
        testToken.approve(address(transferContract), totalAmount);
        
        uint256 user1BalanceBefore = testToken.balanceOf(user1);
        uint256 user2BalanceBefore = testToken.balanceOf(user2);
        uint256 user3BalanceBefore = testToken.balanceOf(user3);
        
        transferContract.batchTransferERC20(address(testToken), recipients, amounts);
        
        // Verify balances
        assertEq(testToken.balanceOf(user1), user1BalanceBefore - totalAmount);
        assertEq(testToken.balanceOf(user2), user2BalanceBefore + amounts[0]);
        assertEq(testToken.balanceOf(user3), user3BalanceBefore + amounts[1]);
        
        vm.stopPrank();
    }
    
    // =============================================================================
    // EMERGENCY FUNCTIONS TESTS
    // =============================================================================
    
    function test_EmergencyWithdraw_OnlyOwner() public {
        uint256 depositAmount = 5 ether;
        
        // User deposits ETH
        vm.prank(user1);
        transferContract.depositETH{value: depositAmount}();
        
        // Owner can withdraw
        uint256 ownerBalanceBefore = address(this).balance;
        transferContract.emergencyWithdraw();
        
        assertEq(address(this).balance, ownerBalanceBefore + depositAmount);
        assertEq(transferContract.getContractBalance(), 0);
    }
    
    function test_EmergencyWithdraw_NotOwner_ShouldRevert() public {
        vm.prank(user1);
        transferContract.depositETH{value: 1 ether}();
        
        vm.prank(user2);
        vm.expectRevert();
        transferContract.emergencyWithdraw();
    }
    
    // =============================================================================
    // VIEW FUNCTIONS TESTS
    // =============================================================================
    
    function test_GetContractBalance() public {
        uint256 depositAmount = 3 ether;
        
        vm.prank(user1);
        transferContract.depositETH{value: depositAmount}();
        
        assertEq(transferContract.getContractBalance(), depositAmount);
    }
    
    function test_GetUserETHBalance() public {
        uint256 depositAmount = 2 ether;
        
        vm.prank(user1);
        transferContract.depositETH{value: depositAmount}();
        
        assertEq(transferContract.getUserETHBalance(user1), depositAmount);
        assertEq(transferContract.getUserETHBalance(user2), 0);
    }
    
    function test_GetERC20Balance() public {
        uint256 user1Balance = testToken.balanceOf(user1);
        
        assertEq(transferContract.getERC20Balance(address(testToken), user1), user1Balance);
    }
    
    // =============================================================================
    // FUZZ TESTS
    // =============================================================================
    
    function testFuzz_DepositETH(uint96 amount) public {
        vm.assume(amount > 0);
        
        vm.deal(user1, amount);
        vm.prank(user1);
        
        transferContract.depositETH{value: amount}();
        
        assertEq(transferContract.getUserETHBalance(user1), amount);
        assertEq(transferContract.getContractBalance(), amount);
    }
    
    function testFuzz_TransferETH(uint96 depositAmount, uint96 transferAmount) public {
        vm.assume(depositAmount > 0);
        vm.assume(transferAmount > 0);
        vm.assume(transferAmount <= depositAmount);
        
        vm.deal(user1, depositAmount);
        vm.startPrank(user1);
        
        transferContract.depositETH{value: depositAmount}();
        
        uint256 user2BalanceBefore = user2.balance;
        transferContract.transferETH(payable(user2), transferAmount);
        
        assertEq(transferContract.getUserETHBalance(user1), depositAmount - transferAmount);
        assertEq(user2.balance, user2BalanceBefore + transferAmount);
        
        vm.stopPrank();
    }
    
    // =============================================================================
    // HELPER FUNCTIONS
    // =============================================================================
    
    receive() external payable {}
}