---
name: polymarket-arb
description: "Polymarket negRisk 套利扫描。扫描天气+体育市场全桶套利机会（Σask < 阈值 → 无风险利润）。用法: /polymarket-arb [--threshold 0.95] [--tag weather]"
user-invocable: true
allowed-tools: [Bash]
context: inline
argument-hint: "[--threshold 0.95] [--tag weather|sports] [--limit 50]"
---

# Polymarket negRisk Arbitrage Scanner

Scan Polymarket negRisk markets for full-bucket arbitrage opportunities where Σ(ask) < threshold, using the `polymarket` CLI.

## When to Use

- User asks about Polymarket arbitrage opportunities
- User wants to scan negRisk markets for mispricing
- User requests weather or sports market arbitrage analysis
- User mentions Polymarket套利 or negRisk

## Strategy

In negRisk markets, exactly one bucket settles at $1. If the sum of all YES ask prices < 1.0 (or a threshold), buying all buckets locks in guaranteed profit:

- **Cost** = Σ(ask_i) × shares
- **Revenue** = 1.0 × shares (one bucket always wins)
- **Profit** = (1.0 - Σask_i) × shares

## Prerequisites

- `polymarket` CLI installed and configured (`polymarket setup` completed)
- Private key configured in `~/.polymarket/config.toml` or `PRIVATE_KEY` env var (needed only for execution)

## Workflow

### Step 1: Discover negRisk Events

Use `polymarket events list` to find active negRisk events. Parse `$ARGUMENTS` for user-specified filters.

```bash
polymarket events list --active true --limit 50 -o json
```

If user specifies `--tag`, add the filter:
```bash
polymarket events list --active true --tag weather --limit 50 -o json
```

From the JSON output, filter for events where `"negRisk": true`. Extract each event's `markets[]` array. Each market contains `clobTokenIds` — a JSON array of `[YES_token, NO_token]`. Collect the YES token (index 0) from every market.

### Step 2: Get Ask Prices for Each negRisk Event

For each negRisk event, batch-query ask prices using the YES token IDs (quoted, comma-separated):

```bash
polymarket clob batch-prices "TOKEN1,TOKEN2,TOKEN3" --side sell -o json
```

`--side sell` returns the best ask (lowest sell offer) for each token — this is the cost to buy YES shares.

**Alternative** — get full order books for depth data:
```bash
polymarket clob books "TOKEN1,TOKEN2,TOKEN3" -o json
```

### Step 3: Calculate Arbitrage

For each negRisk event, compute:

1. **Σ ask** = sum of best ask prices across all buckets
2. **Threshold check**: if Σ ask < threshold (default 0.95), arbitrage exists
3. **Per-share profit** = 1.0 - Σ ask
4. **ROI** = profit / cost × 100%
5. **Fee adjustment**: query fee rate per token via `polymarket clob fee-rate <token_id>` and subtract total fees from profit

### Step 4: Present Results

Present as a structured Markdown report. For each arbitrage opportunity:

**Summary Table:**

| Event | Buckets | Σ Ask | Fee Est. | Net Profit/Share | ROI | Suggested $10 Shares |
|-------|---------|-------|----------|-----------------|-----|---------------------|

**Per-bucket detail for each opportunity:**

| # | Outcome | Ask | Fee Rate | Token ID (first 12 chars) |
|---|---------|-----|----------|---------------------------|

Sort opportunities by ROI descending. Exclude events where:
- Σ ask ≥ threshold (no arb)
- Market titles contain crypto keywords (bitcoin, btc, eth, solana, crypto, "price above", "price below")

### Step 5: Execution (Only on User Confirmation)

If the user explicitly asks to execute a trade on a specific opportunity:

1. Check balance first:
```bash
polymarket clob balance --asset-type collateral
```

2. Confirm: event name, spend amount, number of shares per bucket
3. Calculate shares: `floor(spend / Σask)`
4. **Batch order** — use `post-orders` to submit all bucket buys atomically:

```bash
polymarket clob post-orders \
  --tokens "TOKEN1,TOKEN2,TOKEN3" \
  --side buy \
  --prices "0.15,0.20,0.55" \
  --sizes "10,10,10"
```

5. If batch fails or is unavailable, fall back to individual FOK orders:
```bash
polymarket clob create-order --token <token_id> --side buy --price <ask_price> --size <shares> --order-type FOK
```

6. After all orders, verify fills:
```bash
polymarket clob trades -o json
```

**NEVER auto-execute trades. Always require explicit user confirmation. Show the full order plan before executing.**

## Key CLI Commands Reference

| Command | Purpose |
|---------|---------|
| `polymarket events list --active true -o json` | Discover active events |
| `polymarket events get <id> -o json` | Get event details + markets |
| `polymarket clob batch-prices "IDs" --side sell` | Best ask prices (batch) |
| `polymarket clob books "IDs" -o json` | Full order books (batch) |
| `polymarket clob fee-rate <token_id>` | Taker fee rate |
| `polymarket clob neg-risk <token_id>` | Confirm negRisk status |
| `polymarket clob post-orders --tokens "IDs" --side buy --prices "Ps" --sizes "Ns"` | Batch order |
| `polymarket clob create-order --token <id> --side buy --price <p> --size <n>` | Single order |
| `polymarket clob balance --asset-type collateral` | Check USDC balance |
| `polymarket clob trades -o json` | Verify recent fills |

## Filtering Rules

- **Skip crypto**: Exclude events/markets with titles matching: bitcoin, btc, eth, solana, sol, crypto, "price above", "price below", "above $", "below $"
- **negRisk only**: Only analyze events where `negRisk: true`
- **Active only**: Only scan `active: true, closed: false` events
