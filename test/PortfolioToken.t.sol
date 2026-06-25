// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PortfolioToken} from "../src/PortfolioToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PortfolioTokenTest is Test {
    PortfolioToken internal token;

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    uint256 internal constant MAX_SUPPLY = 1_000_000; // whole tokens
    uint256 internal constant MINT_PRICE = 0.001 ether; // per whole token

    event PublicMint(address indexed to, uint256 amount, uint256 paid);
    event MintPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event ProceedsWithdrawn(address indexed to, uint256 amount);

    function setUp() public {
        token = new PortfolioToken("Portfolio Token", "PORT", MAX_SUPPLY, MINT_PRICE, owner);
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function test_Constructor_SetsMetadata() public view {
        assertEq(token.name(), "Portfolio Token");
        assertEq(token.symbol(), "PORT");
        assertEq(token.decimals(), 18);
        assertEq(token.maxSupply(), MAX_SUPPLY * 1e18);
        assertEq(token.mintPrice(), MINT_PRICE);
        assertEq(token.owner(), owner);
        assertEq(token.totalSupply(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                              PUBLIC MINT
    //////////////////////////////////////////////////////////////*/

    function test_PublicMint_HappyPath() public {
        uint256 amount = 100;
        uint256 cost = amount * MINT_PRICE;
        vm.deal(alice, cost);

        vm.expectEmit(true, false, false, true);
        emit PublicMint(alice, amount * 1e18, cost);

        vm.prank(alice);
        token.publicMint{value: cost}(amount);

        assertEq(token.balanceOf(alice), amount * 1e18);
        assertEq(token.totalSupply(), amount * 1e18);
        assertEq(address(token).balance, cost);
    }

    function test_PublicMint_RevertsOnZeroAmount() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert(PortfolioToken.ZeroAmount.selector);
        token.publicMint{value: 0}(0);
    }

    function test_PublicMint_RevertsOnUnderpayment() public {
        uint256 amount = 10;
        uint256 cost = amount * MINT_PRICE;
        vm.deal(alice, cost);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(PortfolioToken.IncorrectPayment.selector, cost - 1, cost)
        );
        token.publicMint{value: cost - 1}(amount);
    }

    function test_PublicMint_RevertsOnOverpayment() public {
        uint256 amount = 10;
        uint256 cost = amount * MINT_PRICE;
        vm.deal(alice, cost + 1);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(PortfolioToken.IncorrectPayment.selector, cost + 1, cost)
        );
        token.publicMint{value: cost + 1}(amount);
    }

    function test_PublicMint_RevertsWhenExceedingMaxSupply() public {
        uint256 amount = MAX_SUPPLY + 1;
        uint256 cost = amount * MINT_PRICE;
        vm.deal(alice, cost);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                PortfolioToken.MaxSupplyExceeded.selector, amount * 1e18, MAX_SUPPLY * 1e18
            )
        );
        token.publicMint{value: cost}(amount);
    }

    function test_PublicMint_CanMintExactlyToCap() public {
        uint256 amount = MAX_SUPPLY;
        uint256 cost = amount * MINT_PRICE;
        vm.deal(alice, cost);
        vm.prank(alice);
        token.publicMint{value: cost}(amount);

        assertEq(token.totalSupply(), MAX_SUPPLY * 1e18);
        assertEq(token.remainingSupply(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                              OWNER MINT
    //////////////////////////////////////////////////////////////*/

    function test_OwnerMint_HappyPath() public {
        vm.prank(owner);
        token.ownerMint(bob, 500);
        assertEq(token.balanceOf(bob), 500 * 1e18);
    }

    function test_OwnerMint_RevertsForNonOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        token.ownerMint(alice, 100);
    }

    function test_OwnerMint_RevertsOnZeroAmount() public {
        vm.prank(owner);
        vm.expectRevert(PortfolioToken.ZeroAmount.selector);
        token.ownerMint(bob, 0);
    }

    function test_OwnerMint_RevertsWhenExceedingMaxSupply() public {
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                PortfolioToken.MaxSupplyExceeded.selector,
                (MAX_SUPPLY + 1) * 1e18,
                MAX_SUPPLY * 1e18
            )
        );
        token.ownerMint(bob, MAX_SUPPLY + 1);
    }

    /*//////////////////////////////////////////////////////////////
                              SET PRICE
    //////////////////////////////////////////////////////////////*/

    function test_SetMintPrice_UpdatesAndEmits() public {
        uint256 newPrice = 0.005 ether;
        vm.expectEmit(false, false, false, true);
        emit MintPriceUpdated(MINT_PRICE, newPrice);
        vm.prank(owner);
        token.setMintPrice(newPrice);
        assertEq(token.mintPrice(), newPrice);
    }

    function test_SetMintPrice_RevertsForNonOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        token.setMintPrice(1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                              WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function test_Withdraw_TransfersProceedsToOwner() public {
        uint256 amount = 100;
        uint256 cost = amount * MINT_PRICE;
        vm.deal(alice, cost);
        vm.prank(alice);
        token.publicMint{value: cost}(amount);

        uint256 ownerBalanceBefore = owner.balance;

        vm.expectEmit(true, false, false, true);
        emit ProceedsWithdrawn(owner, cost);

        vm.prank(owner);
        token.withdraw();

        assertEq(owner.balance, ownerBalanceBefore + cost);
        assertEq(address(token).balance, 0);
    }

    function test_Withdraw_RevertsForNonOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        token.withdraw();
    }

    function test_Withdraw_RevertsWhenNoProceeds() public {
        vm.prank(owner);
        vm.expectRevert(PortfolioToken.NoProceeds.selector);
        token.withdraw();
    }

    /*//////////////////////////////////////////////////////////////
                              FUZZ
    //////////////////////////////////////////////////////////////*/

    function testFuzz_PublicMint_BalanceMatchesPayment(uint256 amount) public {
        amount = bound(amount, 1, MAX_SUPPLY);
        uint256 cost = amount * MINT_PRICE;
        vm.deal(alice, cost);
        vm.prank(alice);
        token.publicMint{value: cost}(amount);

        assertEq(token.balanceOf(alice), amount * 1e18);
        assertEq(address(token).balance, cost);
    }
}
