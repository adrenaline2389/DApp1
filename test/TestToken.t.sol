// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TestToken} from "../src/TestToken.sol";

contract TestTokenTest is Test {
    TestToken public testToken;
    
    address public owner;
    address public user1;
    address public user2;
    
    string public constant TOKEN_NAME = "Test Token";
    string public constant TOKEN_SYMBOL = "TST";
    uint8 public constant TOKEN_DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Deploy test token
        testToken = new TestToken(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, INITIAL_SUPPLY);
    }
    
    // =============================================================================
    // BASIC ERC20 TESTS
    // =============================================================================
    
    function test_TokenInfo() public {
        assertEq(testToken.name(), TOKEN_NAME);
        assertEq(testToken.symbol(), TOKEN_SYMBOL);
        assertEq(testToken.decimals(), TOKEN_DECIMALS);
        assertEq(testToken.totalSupply(), INITIAL_SUPPLY * 10**TOKEN_DECIMALS);
    }
    
    function test_InitialSupply() public {
        uint256 expectedSupply = INITIAL_SUPPLY * 10**TOKEN_DECIMALS;
        assertEq(testToken.totalSupply(), expectedSupply);
        assertEq(testToken.balanceOf(owner), expectedSupply);
    }
    
    function test_Transfer() public {
        uint256 transferAmount = 1000 * 10**TOKEN_DECIMALS;
        
        uint256 ownerBalanceBefore = testToken.balanceOf(owner);
        uint256 user1BalanceBefore = testToken.balanceOf(user1);
        
        // Test event emission
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user1, transferAmount);
        
        bool success = testToken.transfer(user1, transferAmount);
        assertTrue(success);
        
        // Verify balances
        assertEq(testToken.balanceOf(owner), ownerBalanceBefore - transferAmount);
        assertEq(testToken.balanceOf(user1), user1BalanceBefore + transferAmount);
    }
    
    function test_Transfer_InsufficientBalance_ShouldRevert() public {
        uint256 transferAmount = testToken.totalSupply() + 1;
        
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC20InsufficientBalance(address,uint256,uint256)")), owner, testToken.balanceOf(owner), transferAmount));
        testToken.transfer(user1, transferAmount);
    }
    
    function test_Transfer_ZeroAddress_ShouldRevert() public {
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC20InvalidReceiver(address)")), address(0)));
        testToken.transfer(address(0), 100);
    }
    
    function test_Approve() public {
        uint256 approveAmount = 500 * 10**TOKEN_DECIMALS;
        
        // Test event emission
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, user1, approveAmount);
        
        bool success = testToken.approve(user1, approveAmount);
        assertTrue(success);
        
        assertEq(testToken.allowance(owner, user1), approveAmount);
    }
    
    function test_TransferFrom() public {
        uint256 approveAmount = 1000 * 10**TOKEN_DECIMALS;
        uint256 transferAmount = 500 * 10**TOKEN_DECIMALS;
        
        // First approve
        testToken.approve(user1, approveAmount);
        
        uint256 ownerBalanceBefore = testToken.balanceOf(owner);
        uint256 user2BalanceBefore = testToken.balanceOf(user2);
        uint256 allowanceBefore = testToken.allowance(owner, user1);
        
        // Test transfer from
        vm.prank(user1);
        
        // Test event emission
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user2, transferAmount);
        
        bool success = testToken.transferFrom(owner, user2, transferAmount);
        assertTrue(success);
        
        // Verify balances and allowance
        assertEq(testToken.balanceOf(owner), ownerBalanceBefore - transferAmount);
        assertEq(testToken.balanceOf(user2), user2BalanceBefore + transferAmount);
        assertEq(testToken.allowance(owner, user1), allowanceBefore - transferAmount);
    }
    
    function test_TransferFrom_InsufficientAllowance_ShouldRevert() public {
        uint256 approveAmount = 100 * 10**TOKEN_DECIMALS;
        uint256 transferAmount = 200 * 10**TOKEN_DECIMALS;
        
        testToken.approve(user1, approveAmount);
        
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC20InsufficientAllowance(address,uint256,uint256)")), user1, approveAmount, transferAmount));
        testToken.transferFrom(owner, user2, transferAmount);
    }
    
    // =============================================================================
    // MINT FUNCTION TESTS
    // =============================================================================
    
    function test_Mint_OnlyOwner() public {
        uint256 mintAmount = 1000 * 10**TOKEN_DECIMALS;
        uint256 totalSupplyBefore = testToken.totalSupply();
        uint256 user1BalanceBefore = testToken.balanceOf(user1);
        
        // Test event emission
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user1, mintAmount);
        
        testToken.mint(user1, mintAmount);
        
        // Verify total supply and balance
        assertEq(testToken.totalSupply(), totalSupplyBefore + mintAmount);
        assertEq(testToken.balanceOf(user1), user1BalanceBefore + mintAmount);
    }
    
    function test_Mint_NotOwner_ShouldRevert() public {
        uint256 mintAmount = 1000 * 10**TOKEN_DECIMALS;
        
        vm.prank(user1);
        vm.expectRevert();
        testToken.mint(user2, mintAmount);
    }
    
    // =============================================================================
    // BURN FUNCTION TESTS
    // =============================================================================
    
    function test_Burn() public {
        uint256 burnAmount = 1000 * 10**TOKEN_DECIMALS;
        uint256 totalSupplyBefore = testToken.totalSupply();
        uint256 ownerBalanceBefore = testToken.balanceOf(owner);
        
        // Test event emission
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), burnAmount);
        
        testToken.burn(burnAmount);
        
        // Verify total supply and balance
        assertEq(testToken.totalSupply(), totalSupplyBefore - burnAmount);
        assertEq(testToken.balanceOf(owner), ownerBalanceBefore - burnAmount);
    }
    
    function test_Burn_InsufficientBalance_ShouldRevert() public {
        uint256 burnAmount = testToken.balanceOf(owner) + 1;
        
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC20InsufficientBalance(address,uint256,uint256)")), owner, testToken.balanceOf(owner), burnAmount));
        testToken.burn(burnAmount);
    }
    
    function test_Burn_FromUser() public {
        uint256 transferAmount = 1000 * 10**TOKEN_DECIMALS;
        uint256 burnAmount = 500 * 10**TOKEN_DECIMALS;
        
        // First transfer some tokens to user1
        testToken.transfer(user1, transferAmount);
        
        uint256 totalSupplyBefore = testToken.totalSupply();
        uint256 user1BalanceBefore = testToken.balanceOf(user1);
        
        // User1 burns their tokens
        vm.prank(user1);
        testToken.burn(burnAmount);
        
        // Verify balances
        assertEq(testToken.totalSupply(), totalSupplyBefore - burnAmount);
        assertEq(testToken.balanceOf(user1), user1BalanceBefore - burnAmount);
    }
    
    // =============================================================================
    // FAUCET FUNCTION TESTS
    // =============================================================================
    
    function test_Faucet() public {
        uint256 faucetAmount = 100 * 10**TOKEN_DECIMALS;
        uint256 totalSupplyBefore = testToken.totalSupply();
        uint256 user1BalanceBefore = testToken.balanceOf(user1);
        
        vm.prank(user1);
        
        // Test event emission
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user1, faucetAmount);
        
        testToken.faucet(faucetAmount);
        
        // Verify balances
        assertEq(testToken.totalSupply(), totalSupplyBefore + faucetAmount);
        assertEq(testToken.balanceOf(user1), user1BalanceBefore + faucetAmount);
    }
    
    function test_Faucet_MaxAmount() public {
        uint256 maxFaucetAmount = 1000 * 10**TOKEN_DECIMALS;
        
        vm.prank(user1);
        testToken.faucet(maxFaucetAmount);
        
        assertEq(testToken.balanceOf(user1), maxFaucetAmount);
    }
    
    function test_Faucet_ExceedsLimit_ShouldRevert() public {
        uint256 excessiveFaucetAmount = 1001 * 10**TOKEN_DECIMALS;
        
        vm.prank(user1);
        vm.expectRevert("Faucet limit exceeded");
        testToken.faucet(excessiveFaucetAmount);
    }
    
    function test_Faucet_MultipleCalls() public {
        uint256 faucetAmount = 500 * 10**TOKEN_DECIMALS;
        
        vm.startPrank(user1);
        
        // First call
        testToken.faucet(faucetAmount);
        assertEq(testToken.balanceOf(user1), faucetAmount);
        
        // Second call
        testToken.faucet(faucetAmount);
        assertEq(testToken.balanceOf(user1), faucetAmount * 2);
        
        vm.stopPrank();
    }
    
    // =============================================================================
    // OWNERSHIP TESTS
    // =============================================================================
    
    function test_Owner() public {
        assertEq(testToken.owner(), owner);
    }
    
    function test_TransferOwnership() public {
        testToken.transferOwnership(user1);
        assertEq(testToken.owner(), user1);
    }
    
    function test_TransferOwnership_NotOwner_ShouldRevert() public {
        vm.prank(user1);
        vm.expectRevert();
        testToken.transferOwnership(user2);
    }
    
    // =============================================================================
    // FUZZ TESTS
    // =============================================================================
    
    function testFuzz_Transfer(uint256 amount) public {
        amount = bound(amount, 1, testToken.balanceOf(owner));
        
        uint256 ownerBalanceBefore = testToken.balanceOf(owner);
        uint256 user1BalanceBefore = testToken.balanceOf(user1);
        
        testToken.transfer(user1, amount);
        
        assertEq(testToken.balanceOf(owner), ownerBalanceBefore - amount);
        assertEq(testToken.balanceOf(user1), user1BalanceBefore + amount);
    }
    
    function testFuzz_Mint(uint256 amount) public {
        amount = bound(amount, 1, type(uint128).max); // Reasonable upper bound
        
        uint256 totalSupplyBefore = testToken.totalSupply();
        uint256 user1BalanceBefore = testToken.balanceOf(user1);
        
        testToken.mint(user1, amount);
        
        assertEq(testToken.totalSupply(), totalSupplyBefore + amount);
        assertEq(testToken.balanceOf(user1), user1BalanceBefore + amount);
    }
    
    function testFuzz_Burn(uint256 amount) public {
        uint256 maxBurn = testToken.balanceOf(owner);
        amount = bound(amount, 1, maxBurn);
        
        uint256 totalSupplyBefore = testToken.totalSupply();
        uint256 ownerBalanceBefore = testToken.balanceOf(owner);
        
        testToken.burn(amount);
        
        assertEq(testToken.totalSupply(), totalSupplyBefore - amount);
        assertEq(testToken.balanceOf(owner), ownerBalanceBefore - amount);
    }
    
    function testFuzz_Faucet(uint256 amount) public {
        uint256 maxFaucet = 1000 * 10**TOKEN_DECIMALS;
        amount = bound(amount, 1, maxFaucet);
        
        uint256 totalSupplyBefore = testToken.totalSupply();
        uint256 user1BalanceBefore = testToken.balanceOf(user1);
        
        vm.prank(user1);
        testToken.faucet(amount);
        
        assertEq(testToken.totalSupply(), totalSupplyBefore + amount);
        assertEq(testToken.balanceOf(user1), user1BalanceBefore + amount);
    }
}