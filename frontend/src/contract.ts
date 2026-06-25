import {sepolia} from "wagmi/chains";

// Deployed on Ethereum Sepolia. Override with VITE_CONTRACT_ADDRESS in .env if redeployed.
export const CONTRACT_ADDRESS = (import.meta.env.VITE_CONTRACT_ADDRESS ??
  "0xc433A842b35F273DcC6F36138f09A649bB1cC3e5") as `0x${string}`;

export const CHAIN = sepolia;

// Minimal ABI: only the functions/reads the dApp uses.
export const ABI = [
  {
    type: "function",
    name: "name",
    stateMutability: "view",
    inputs: [],
    outputs: [{type: "string"}],
  },
  {
    type: "function",
    name: "symbol",
    stateMutability: "view",
    inputs: [],
    outputs: [{type: "string"}],
  },
  {
    type: "function",
    name: "decimals",
    stateMutability: "view",
    inputs: [],
    outputs: [{type: "uint8"}],
  },
  {
    type: "function",
    name: "totalSupply",
    stateMutability: "view",
    inputs: [],
    outputs: [{type: "uint256"}],
  },
  {
    type: "function",
    name: "maxSupply",
    stateMutability: "view",
    inputs: [],
    outputs: [{type: "uint256"}],
  },
  {
    type: "function",
    name: "remainingSupply",
    stateMutability: "view",
    inputs: [],
    outputs: [{type: "uint256"}],
  },
  {
    type: "function",
    name: "mintPrice",
    stateMutability: "view",
    inputs: [],
    outputs: [{type: "uint256"}],
  },
  {
    type: "function",
    name: "balanceOf",
    stateMutability: "view",
    inputs: [{name: "account", type: "address"}],
    outputs: [{type: "uint256"}],
  },
  {
    type: "function",
    name: "publicMint",
    stateMutability: "payable",
    inputs: [{name: "amount", type: "uint256"}],
    outputs: [],
  },
] as const;
