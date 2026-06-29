# MintToken — ERC-20 with Paid Public Mint

A starter template for shipping a capped ERC-20 with a paid public mint. Built with
**Foundry** and **OpenZeppelin v5**, tested (unit + fuzz), with a minimal React +
wagmi/viem mint dApp. Clone it, change the name, cap, and price, deploy your own token.

The contract covers the common paid-mint requirements out of the box: a hard supply
cap, exact-payment public mint, owner-only mint for airdrops, an adjustable price, and
checked proceeds withdrawal. Adapt the parameters; the mint logic stays the same.

## 🟢 Demo Deployment

A live instance on Sepolia so you can try the dApp before deploying your own. This is the
template author's demo, not your token — deploy your own and point the frontend at it.

| | |
|---|---|
| Network | Ethereum Sepolia (testnet) |
| Contract | [`0xc433a842b35f273dcc6f36138f09a649bb1cc3e5`](https://sepolia.etherscan.io/address/0xc433a842b35f273dcc6f36138f09a649bb1cc3e5) |

## Features

- **Capped supply** — hard maximum enforced on every mint path.
- **Paid public mint** — anyone can mint by paying `amount × mintPrice` (exact payment enforced).
- **Owner mint** — owner-only mint for airdrops / team allocation.
- **Adjustable price** — owner can update the mint price.
- **Safe withdrawal** — owner withdraws ETH proceeds via low-level call with success check.
- **Custom errors** — gas-efficient reverts with actionable context.
- **Events** — every state change is observable on-chain.

## Tech Stack

| Layer | Tool |
|-------|------|
| Language | Solidity ^0.8.20 |
| Framework | Foundry (forge / cast / anvil) |
| Libraries | OpenZeppelin Contracts v5 |
| Target chain | Ethereum Sepolia (testnet) |

## Project Structure

```
src/MintToken.sol     # The token contract
test/MintToken.t.sol  # 17 tests (unit + fuzz)
script/Deploy.s.sol   # Deployment script
frontend/             # React + wagmi/viem mint dApp
```

## Quick Start

```bash
# Install dependencies
forge install

# Build
forge build

# Run tests
forge test -vv

# Gas report
forge test --gas-report

# Coverage
forge coverage
```

## Customize

This template ships with demo defaults. To make it your own:

- **Token name / symbol / cap / price** — set in `script/Deploy.s.sol` (defaults `"Mint Token"`,
  `"MINT"`, 1,000,000 cap, 0.001 ETH per token), or override per-deploy via the `TOKEN_*`
  environment variables in `.env`. These are display/config values; changing them does not
  touch the contract logic.
- **Contract identifier** — the Solidity contract is `MintToken`. Rename it (and the file,
  test, and deploy import) only if you want a different on-chain artifact name.
- **Frontend contract address** — set `VITE_CONTRACT_ADDRESS` in `frontend/.env` to your
  deployed address (see [Frontend dApp](#frontend-dapp)).

## Deployment (Ethereum Sepolia)

1. Get free testnet ETH from a [Sepolia faucet](https://www.alchemy.com/faucets/ethereum-sepolia).
2. Copy env file and fill in your **testnet-only** key:
   ```bash
   cp .env.example .env
   ```
3. Deploy and verify:
   ```bash
   source .env
   forge script script/Deploy.s.sol \
     --rpc-url $SEPOLIA_RPC_URL \
     --private-key $PRIVATE_KEY \
     --broadcast --verify \
     --etherscan-api-key $ETHERSCAN_API_KEY
   ```

## Frontend dApp

A minimal React + wagmi/viem dApp lives in `frontend/`. It connects an injected
wallet (MetaMask), reads live token stats, and lets users mint by paying ETH.

```bash
cd frontend
npm install
# Point the dApp at your deployed contract:
cp .env.example .env   # then set VITE_CONTRACT_ADDRESS
npm run dev
```

If `VITE_CONTRACT_ADDRESS` is unset, the dApp falls back to the demo deployment on Sepolia.

Stack: React 18, Vite, TypeScript, wagmi v2, viem v2, TanStack Query.

## Security Notes

- Exact-payment check prevents over/underpayment on mint.
- Supply cap checked before every `_mint`.
- Withdrawal uses checked low-level call and reverts on failure.
- `Ownable` guards all admin functions.
- ⚠️ This template is unaudited. Get an audit before deploying to mainnet with real value.

## License

MIT — see [LICENSE](LICENSE).

## Screenshots

| Test coverage | dApp UI |
|---|---|
| ![coverage](assets/coverage.png) | ![UI](assets/ui.png) |
