# Binary GCD algorithm (Stein) — Ada 2023

Educational, self-contained Ada 2023 package for the **binary GCD
algorithm** (also Stein's algorithm / binary Euclidean algorithm):
compute $g=\gcd(u,v)$ for nonnegative integers using only arithmetic
shifts, comparisons, and subtraction — no division or remainder in the
main Stein path. See
[Wikipedia: Binary GCD algorithm](https://en.wikipedia.org/wiki/Binary_GCD_algorithm).

This package is a **classroom sketch** on unsigned 64-bit words (`U64`):
iterative Stein (preferred), a recursive identity-driven variant, bit
helpers (trailing-zero count / shifts), and a local classical Euclidean
reference for cross-checks. It is **not** a production big-integer /
crypto library.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Euclidean siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Binary-GCD`) | Stein: shifts + subtract; no division |
| **[Ada-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Euclidean-Algorithm)** | Classical remainders: $\gcd(u,v)=\gcd(v,u\bmod v)$ |
| **[Ada-Extended-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Extended-Euclidean-Algorithm)** | Bézout: $ax+by=g$ and modular inverse |

README links only — **no** package `with` of siblings.

Stein typically does more loop iterations than Euclidean but each step is
cheaper when division is expensive (and maps well to hardware CTZ /
shifts). Asymptotically both are $O(n^{2})$ bit operations for $n$-bit
inputs; a finer analysis finds binary GCD uses fewer bit ops on average.

## Identities

$$
\begin{align*}
\gcd(u,0) &= u \\
\gcd(2u,2v) &= 2\cdot\gcd(u,v) \\
\gcd(u,2v) &= \gcd(u,v) && \text{($u$ odd)} \\
\gcd(u,v) &= \gcd(u,v-u) && \text{($u,v$ odd, $u\le v$)}
\end{align*}
$$

Domain: nonnegative (`U64`). Convention $\gcd(0,0)=0$.

## API sketch

| Operation | Role |
| --- | --- |
| `Gcd` | Iterative Stein binary gcd |
| `Gcd_Recursive` | Recursive Stein (same results) |
| `Gcd_Euclidean` | Classical Euclidean reference |
| `Are_Coprime` | $\gcd(a,b)=1$ |
| `Trailing_Zeros` / `Shift_Left` / `Shift_Right` / `Is_Odd` | Bit helpers |

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
