// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {PortfolioToken} from "../src/PortfolioToken.sol";

/// @notice Deploys PortfolioToken. Reads config from environment variables.
/// @dev Usage:
///   forge script script/Deploy.s.sol \
///     --rpc-url $SEPOLIA_RPC_URL \
///     --private-key $PRIVATE_KEY \
///     --broadcast --verify
contract Deploy is Script {
    function run() external returns (PortfolioToken token) {
        // Defaults are sensible for a testnet demo; override via env if desired.
        string memory name = vm.envOr("TOKEN_NAME", string("Portfolio Token"));
        string memory symbol = vm.envOr("TOKEN_SYMBOL", string("PORT"));
        uint256 maxSupply = vm.envOr("TOKEN_MAX_SUPPLY", uint256(1_000_000));
        uint256 mintPrice = vm.envOr("TOKEN_MINT_PRICE", uint256(0.001 ether));

        // The signer comes from the CLI (--private-key or --account); msg.sender
        // inside the broadcast is the deployer, who becomes the token owner.
        vm.startBroadcast();
        address deployer = msg.sender;
        token = new PortfolioToken(name, symbol, maxSupply, mintPrice, deployer);
        vm.stopBroadcast();

        console2.log("PortfolioToken deployed at:", address(token));
        console2.log("Owner:", deployer);
        console2.log("Max supply (whole tokens):", maxSupply);
        console2.log("Mint price (wei):", mintPrice);
    }
}
