// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title MintToken
/// @notice A capped ERC-20 with a paid public mint and an owner-only mint for airdrops.
/// @dev Demonstrates: capped supply, payable mint, access control, and safe ETH withdrawal.
contract MintToken is ERC20, Ownable {
    /// @notice Maximum number of tokens that can ever exist (18 decimals).
    uint256 public immutable maxSupply;

    /// @notice Price in wei to mint a single whole token (1e18 units).
    uint256 public mintPrice;

    /// @dev Emitted when tokens are minted through the paid public sale.
    event PublicMint(address indexed to, uint256 amount, uint256 paid);

    /// @dev Emitted when the owner updates the mint price.
    event MintPriceUpdated(uint256 oldPrice, uint256 newPrice);

    /// @dev Emitted when accumulated ETH proceeds are withdrawn.
    event ProceedsWithdrawn(address indexed to, uint256 amount);

    error MaxSupplyExceeded(uint256 requested, uint256 remaining);
    error ZeroAmount();
    error IncorrectPayment(uint256 sent, uint256 required);
    error WithdrawFailed();
    error NoProceeds();

    /// @param _name Token name.
    /// @param _symbol Token symbol.
    /// @param _maxSupply Hard cap on total supply, in whole tokens (will be scaled by 1e18).
    /// @param _mintPrice Price in wei per whole token for the public mint.
    /// @param _owner Initial owner (receives admin rights).
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _mintPrice,
        address _owner
    ) ERC20(_name, _symbol) Ownable(_owner) {
        maxSupply = _maxSupply * 10 ** decimals();
        mintPrice = _mintPrice;
    }

    /// @notice Mint `amount` whole tokens to the caller by paying `amount * mintPrice`.
    /// @param amount Number of whole tokens to mint (not scaled by decimals).
    function publicMint(uint256 amount) external payable {
        if (amount == 0) revert ZeroAmount();

        uint256 cost = amount * mintPrice;
        if (msg.value != cost) revert IncorrectPayment(msg.value, cost);

        uint256 scaled = amount * 10 ** decimals();
        uint256 remaining = maxSupply - totalSupply();
        if (scaled > remaining) revert MaxSupplyExceeded(scaled, remaining);

        _mint(msg.sender, scaled);
        emit PublicMint(msg.sender, scaled, msg.value);
    }

    /// @notice Owner-only mint for airdrops or team allocation. No payment required.
    /// @param to Recipient address.
    /// @param amount Number of whole tokens to mint (not scaled by decimals).
    function ownerMint(address to, uint256 amount) external onlyOwner {
        if (amount == 0) revert ZeroAmount();

        uint256 scaled = amount * 10 ** decimals();
        uint256 remaining = maxSupply - totalSupply();
        if (scaled > remaining) revert MaxSupplyExceeded(scaled, remaining);

        _mint(to, scaled);
    }

    /// @notice Update the per-token mint price.
    function setMintPrice(uint256 newPrice) external onlyOwner {
        emit MintPriceUpdated(mintPrice, newPrice);
        mintPrice = newPrice;
    }

    /// @notice Withdraw all accumulated ETH proceeds to the owner.
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoProceeds();

        (bool ok,) = payable(owner()).call{value: balance}("");
        if (!ok) revert WithdrawFailed();

        emit ProceedsWithdrawn(owner(), balance);
    }

    /// @notice Tokens still available to mint, in scaled (1e18) units.
    function remainingSupply() external view returns (uint256) {
        return maxSupply - totalSupply();
    }
}
