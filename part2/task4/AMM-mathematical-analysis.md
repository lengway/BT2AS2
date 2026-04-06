# AMM Mathematical Analysis (Task 4)

## 1) Constant product derivation and intuition

For a two-asset pool with reserves $(x, y)$, a constant product AMM maintains:

$$
x \cdot y = k
$$

A trader adds $\Delta x$ of token $X$ and receives $\Delta y$ of token $Y$, so post-trade reserves are:

$$
(x + \Delta x)(y - \Delta y) = k
$$

Solving for output:

$$
\Delta y = y - \frac{k}{x + \Delta x} = y - \frac{xy}{x + \Delta x} = \frac{y\Delta x}{x + \Delta x}
$$

This creates **endogenous price discovery**. The marginal spot price is approximately:

$$
P_{X\to Y} \approx \frac{y}{x}
$$

As $\Delta x$ grows, denominator $(x+\Delta x)$ increases and effective execution price worsens (slippage), which naturally protects pool inventory.

Why it works:
- Always provides a quote for any non-zero reserves.
- Enforces conservation through an invariant, eliminating the need for off-chain order books.
- Deterministically prices larger trades worse, compensating LPs through spread/fees.

## 2) Effect of 0.3% fee on invariant $k$

Uniswap V2-style fee uses only $99.7\%$ of input in pricing:

$$
\Delta x_{eff} = \Delta x \cdot 0.997
$$

Output formula:

$$
\Delta y = \frac{\Delta x_{eff} \cdot y}{x + \Delta x_{eff}}
$$

But full $\Delta x$ is deposited into reserves. Therefore, after swap:
- $x' = x + \Delta x$
- $y' = y - \Delta y$

Because output is computed with $\Delta x_{eff} < \Delta x$, trader receives slightly less than no-fee case. That leftover value remains in the pool, so product tends to increase:

$$
k' = x' y' \ge k
$$

In practice, $k$ is non-decreasing (up to integer rounding). This is exactly why fee revenue accrues to LPs.

## 3) Impermanent loss (IL)

Assume equal-value LP deposit in a 50/50 constant-product pool and external relative price moves by factor $r$.

Normalized LP value vs HODL yields:

$$
\text{LP value ratio} = \frac{2\sqrt{r}}{1+r}
$$

Impermanent loss (as relative underperformance vs HODL):

$$
IL(r) = \frac{2\sqrt{r}}{1+r} - 1
$$

For a 2x price move ($r=2$):

$$
IL(2) = \frac{2\sqrt{2}}{3} - 1 \approx 0.9428 - 1 = -0.0572
$$

So IL magnitude is about **5.72%**.

Interpretation:
- “Impermanent” if price reverts before LP exits.
- Realized at withdrawal if divergence persists.
- Fees can offset or exceed IL depending on volume and volatility.

## 4) Price impact vs trade size

Average execution price for input trade $\Delta x$ is:

$$
\bar{P} = \frac{\Delta x}{\Delta y}
$$

with

$$
\Delta y = \frac{0.997\,\Delta x\,y}{1000x + 0.997\,\Delta x}
$$

Hence price impact scales nonlinearly with trade fraction $\Delta x/x$:
- Small $\Delta x/x$: near-linear and low slippage.
- Large $\Delta x/x$: convex slippage growth, rapidly worse pricing.

Rule of thumb: doubling trade size more than doubles impact when trade is already a significant share of reserves.

## 5) Comparison with Uniswap V2: missing features in this assignment AMM

Implemented core behavior:
- Constant product pricing.
- 0.3% fee in swap path.
- LP mint/burn with proportional accounting.
- Slippage protection parameters.

Missing vs production Uniswap V2-like stack:
- Oracle primitives (TWAP accumulators).
- Protocol fee switch and fee-to logic.
- Full ERC-20 LP token semantics (allowances/transferability in this minimal version).
- Router architecture for multi-hop swaps and permit flows.
- Factory for deterministic pair creation and registry.
- More complete safety hardening and edge-case handling (e.g., fee-on-transfer tokens).

Overall, this implementation is suitable for educational validation of AMM mechanics, but not yet production-ready without the above protocol, security, and ecosystem integrations.
