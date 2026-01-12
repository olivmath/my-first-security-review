// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/TokenSale.sol";

contract TokenSaleTest is Test {
    TokenSale public sale;
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        sale = new TokenSale();
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    function test_initialState() public view {
        assertEq(sale.tokenPrice(), 1 ether);
        assertEq(sale.totalSupply(), 0);
        assertTrue(sale.saleActive());
    }

    function test_buyTokens() public {
        sale.addToWhitelist(alice);

        vm.prank(alice);
        sale.buyTokens{value: 5 ether}(5);

        assertEq(sale.balances(alice), 5);
        assertEq(sale.totalSupply(), 5);
    }

    function test_transfer() public {
        sale.addToWhitelist(alice);

        vm.prank(alice);
        sale.buyTokens{value: 3 ether}(3);

        vm.prank(alice);
        sale.transfer(bob, 2);

        assertEq(sale.balances(alice), 1);
        assertEq(sale.balances(bob), 2);
    }

    function test_setPrice() public {
        sale.setPrice(2 ether);
        assertEq(sale.tokenPrice(), 2 ether);
    }

    function test_withdrawFunds() public {
        sale.addToWhitelist(alice);

        vm.prank(alice);
        sale.buyTokens{value: 10 ether}(10);

        uint256 ownerBalanceBefore = address(this).balance;
        sale.withdrawFunds();
        uint256 ownerBalanceAfter = address(this).balance;

        assertEq(ownerBalanceAfter - ownerBalanceBefore, 10 ether);
    }

    receive() external payable {}
}
