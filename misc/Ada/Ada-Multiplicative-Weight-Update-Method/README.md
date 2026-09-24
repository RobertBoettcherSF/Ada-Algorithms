# Multiplicative weight update method — Ada 2023

Educational, self-contained Ada 2023 package for the **multiplicative
weights update (MWU)** method and the closely related **Hedge**
algorithm: online learning / prediction from expert advice by keeping
positive weights and updating them multiplicatively from observed
per-round losses. See
[Wikipedia: Multiplicative weight update method](https://en.wikipedia.org/wiki/Multiplicative_weight_update_method).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT
(`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Project overview

Each round $t=1,\ldots,T$ an algorithm maintains positive weights
$w_1^t,\ldots,w_N^t$ over $N$ experts, plays the normalized distribution

$$
p_i^t=\frac{w_i^t}{\sum_{j=1}^{N}w_j^t},
$$

observes a loss vector $\ell^t\in\mathbb{R}^N$ (often in $[0,1]^N$),
suffers expected loss $\langle p^t,\ell^t\rangle$, and multiplies each
weight by a factor that shrinks experts who lost more.

This package is a classroom implementation: a `Learner` with $N$ experts
and learning rate $\eta$, both the classic multiplicative rule and
Hedge, deterministic `Choose` (argmax), cumulative losses, and external /
average regret.

## Update rules

| Variant | Rule | Typical losses |
| --- | --- | --- |
| `Multiplicative` | $w_i\leftarrow w_i\,(1-\eta)^{\ell_i}$ | $\ell_i\in[0,1]$, $0<\eta<1$ |
| `Hedge` | $w_i\leftarrow w_i\,\exp(-\eta\,\ell_i)$ | bounded (often $[0,1]$), $\eta>0$ |

Weighted majority is the special case of the multiplicative rule on
binary $0/1$ losses. Hedge (Freund–Schapire) is the exponential-weights
form used throughout online learning.

`Update_Rewards` converts rewards $r$ into losses $\ell=-r$ before the
same update (for `Multiplicative`, require $r\in[-1,0]$ so that
$-r\in[0,1]$).

## No-regret guarantee (sketch)

Let $L_{\mathrm{alg}}=\sum_{t=1}^{T}\langle p^t,\ell^t\rangle$ and
$L_i=\sum_{t=1}^{T}\ell_i^t$. External regret against the best expert in
hindsight is

$$
R_T=L_{\mathrm{alg}}-\min_{i\in\{1,\ldots,N\}}L_i.
$$

For Hedge with losses in $[0,1]$ and learning rate
$\eta=\sqrt{(\ln N)/T}$,

$$
R_T\le 2\sqrt{T\ln N},\qquad
\frac{R_T}{T}=O\!\left(\sqrt{\frac{\ln N}{T}}\right).
$$

`Suggested_Eta` returns that classroom schedule (capped at $1/2$ for
`Multiplicative`). `External_Regret` / `Average_Regret` expose $R_T$ and
$R_T/T$ on a live learner.

## Mirror descent / regret siblings (README only)

Hedge is **entropic mirror descent** on the probability simplex: the
negative-entropy regularizer $\sum_i p_i\ln p_i$ yields the multiplicative
(exponential) update. Contrast — documentation only, **do not** `with` —

- Ada-Mirror-Descent (Bregman / mirror-descent templates)
- Ada regret-minimization siblings (external / internal regret, MWU as a
  special case)

This package stays self-contained so it can be studied as a first
online-learning primitive.

## API summary

| Symbol | Role |
| --- | --- |
| `Learner` | Opaque state: $N$, $\eta$, variant, weights, cumulatives, $T$ |
| `Create` | Uniform $w_i=1$ or custom positive initial weights |
| `Reset` | Restore uniform / custom weights; clear cumulatives |
| `Update` / `Update_Rewards` | One MWU or Hedge round |
| `Weights` / `Weight_Sum` | Unnormalized positive weights |
| `Distribution` / `Probabilities` | $p_i=w_i/\sum w$ |
| `Choose` | Deterministic argmax of $w$ (smallest index on ties) |
| `Best_Expert` / `Expert_Loss` | Hindsight-best expert so far |
| `Algorithm_Loss` | $\sum_t\langle p^t,\ell^t\rangle$ |
| `External_Regret` / `Average_Regret` | $R_T$ and $R_T/T$ |
| `Suggested_Eta` | $\sqrt{(\ln N)/T}$ (Multiplicative capped at $1/2$) |
| `Invalid_Argument` | Bad $N$, $\eta$, lengths, non-positive weights, … |

Bounds: $1\le N\le\texttt{Max\_Experts}=64$. Arrays are $1$-based.

## Build and test

```bash
make
make test
```

Uses `gnatmake -gnatwa -gnat2022` via
`multiplicative_weight_update_method.gpr`. Expect a green suite with
zero warnings.

## Classroom walk-through

1. `L := Create (3, 0.2, Hedge);` — three experts, uniform weights.
2. Each round observe losses, e.g. `[1.0, 0.0, 0.5]`, then
   `Update (L, Losses);`.
3. Read `Probabilities (L)` to play a mixed strategy, or `Choose (L)` for
   a deterministic classroom pick.
4. After $T$ rounds inspect `Average_Regret (L)` — it should shrink like
   $O(\sqrt{(\ln N)/T})$ when $\eta$ is set with `Suggested_Eta`.

### Pseudocode (Hedge)

```text
w_i ← 1 for all i
for t = 1 .. T:
    p_i ← w_i / sum(w)
    play p; observe loss vector ell
    for each i:
        w_i ← w_i * exp(-eta * ell_i)
```

## References

- [Multiplicative weight update method (Wikipedia)](https://en.wikipedia.org/wiki/Multiplicative_weight_update_method)
- Arora, Hazan, Kale — *The Multiplicative Weights Update Method: a Meta-Algorithm and Applications* (Theory of Computing, 2012)
- Freund & Schapire — *A Decision-Theoretic Generalization of On-Line Learning and an Application to Boosting* (JCSS, 1997) — Hedge
- Littlestone & Warmuth — *The Weighted Majority Algorithm* (Information and Computation, 1994)

## License

Educational example for the RobertBoettcherSF Ada algorithm series.
