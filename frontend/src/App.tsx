import {useEffect, useState} from "react";
import {
  useAccount,
  useConnect,
  useDisconnect,
  useReadContracts,
  useWriteContract,
  useWaitForTransactionReceipt,
  useChainId,
  useSwitchChain,
} from "wagmi";
import {formatEther} from "viem";
import {ABI, CONTRACT_ADDRESS, CHAIN} from "./contract.ts";

export function App() {
  const {address, isConnected} = useAccount();
  const {connect, connectors, isPending: connecting} = useConnect();
  const {disconnect} = useDisconnect();
  const chainId = useChainId();
  const {switchChain} = useSwitchChain();

  const wrongNetwork = isConnected && chainId !== CHAIN.id;

  return (
    <main className="container">
      <header>
        <h1>🪙 PortfolioToken Mint</h1>
        <p className="sub">A demo ERC-20 paid mint on {CHAIN.name}</p>
      </header>

      {!isConnected ? (
        <button
          className="primary"
          disabled={connecting}
          onClick={() => connect({connector: connectors[0]})}
        >
          {connecting ? "Connecting…" : "Connect Wallet"}
        </button>
      ) : (
        <div className="account">
          <span className="addr">{shorten(address!)}</span>
          <button className="ghost" onClick={() => disconnect()}>
            Disconnect
          </button>
        </div>
      )}

      {wrongNetwork && (
        <div className="warn">
          Wrong network.{" "}
          <button className="link" onClick={() => switchChain({chainId: CHAIN.id})}>
            Switch to {CHAIN.name}
          </button>
        </div>
      )}

      {isConnected && !wrongNetwork && <TokenPanel address={address!} />}

      <footer>
        Contract:{" "}
        <a
          href={`${CHAIN.blockExplorers?.default.url}/address/${CONTRACT_ADDRESS}`}
          target="_blank"
          rel="noreferrer"
        >
          {shorten(CONTRACT_ADDRESS)}
        </a>
      </footer>
    </main>
  );
}

function TokenPanel({address}: {address: `0x${string}`}) {
  const [amount, setAmount] = useState("1");

  const base = {address: CONTRACT_ADDRESS, abi: ABI} as const;
  const {data, refetch, isLoading} = useReadContracts({
    contracts: [
      {...base, functionName: "name"},
      {...base, functionName: "symbol"},
      {...base, functionName: "mintPrice"},
      {...base, functionName: "totalSupply"},
      {...base, functionName: "maxSupply"},
      {...base, functionName: "remainingSupply"},
      {...base, functionName: "balanceOf", args: [address]},
    ],
  });

  const {writeContract, data: txHash, isPending, error} = useWriteContract();
  const {isLoading: confirming, isSuccess: confirmed} = useWaitForTransactionReceipt({
    hash: txHash,
  });

  useEffect(() => {
    if (confirmed) refetch();
  }, [confirmed, refetch]);

  const [name, symbol, mintPrice, totalSupply, maxSupply, remaining, balance] = (data ?? []).map(
    (r) => r.result
  );

  const qty = safeBigInt(amount);
  const price = (mintPrice as bigint) ?? 0n;
  const cost = qty * price;

  function onMint() {
    if (qty <= 0n) return;
    writeContract({
      ...base,
      functionName: "publicMint",
      args: [qty],
      value: cost,
    });
  }

  if (isLoading) return <p>Loading token data…</p>;

  return (
    <section className="panel">
      <h2>
        {name as string} ({symbol as string})
      </h2>

      <dl className="stats">
        <Stat label="Your balance" value={`${fmt(balance)} ${symbol as string}`} />
        <Stat label="Total minted" value={fmt(totalSupply)} />
        <Stat label="Max supply" value={fmt(maxSupply)} />
        <Stat label="Remaining" value={fmt(remaining)} />
        <Stat label="Price / token" value={`${formatEther(price)} ETH`} />
      </dl>

      <div className="mint">
        <label>
          Amount
          <input
            type="number"
            min="1"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
        </label>
        <p className="cost">Cost: {formatEther(cost)} ETH</p>
        <button className="primary" disabled={isPending || confirming || qty <= 0n} onClick={onMint}>
          {isPending ? "Confirm in wallet…" : confirming ? "Minting…" : "Mint"}
        </button>
      </div>

      {confirmed && <p className="ok">✅ Mint confirmed!</p>}
      {error && <p className="err">{(error as {shortMessage?: string}).shortMessage ?? "Error"}</p>}
    </section>
  );
}

function Stat({label, value}: {label: string; value: string}) {
  return (
    <div>
      <dt>{label}</dt>
      <dd>{value}</dd>
    </div>
  );
}

function shorten(addr: string) {
  return `${addr.slice(0, 6)}…${addr.slice(-4)}`;
}

function safeBigInt(v: string): bigint {
  try {
    return BigInt(v || "0");
  } catch {
    return 0n;
  }
}

// Token amounts come back scaled by 1e18; show whole tokens.
function fmt(v: unknown): string {
  if (typeof v !== "bigint") return "—";
  return Number(formatEther(v)).toLocaleString();
}
