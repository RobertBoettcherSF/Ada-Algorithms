# Extended Euclidean algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the
**extended Euclidean algorithm**: given integers $a$ and $b$, compute
$g=\gcd(a,b)$ together with Bézout coefficients $x,y$ such that
$ax+by=g$ (also written $\operatorname{xgcd}(a,b)$). See
[Wikipedia: Extended Euclidean algorithm](https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm).

Note: Wikipedia spelling is **Euclidean** (the sheet row title uses the
common misspelling “Euclidian”).

This package is a **classroom sketch** on `Long_Integer`: iterative
extended gcd, quotients $a/g$ and $b/g$, and modular multiplicative
inverse via Bézout when $\gcd(a,m)=1$. It is **not** a production
big-integer / crypto library.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Related / sibling rows (README links only — **no** package `with`):

- **[Ada-Integer-Factorization](https://github.com/RobertBoettcherSF/Ada-Integer-Factorization)** —
  factorization survey
- **[Ada-Dixon](https://github.com/RobertBoettcherSF/Ada-Dixon)** /
  **[Ada-Congruence-Of-Squares](https://github.com/RobertBoettcherSF/Ada-Congruence-Of-Squares)** —
  factorization building blocks that rely on gcd ideas
- Next sheet row: **Euclidean algorithm** (plain gcd) — planned as
  `Ada-Euclidean-Algorithm`

## API sketch

| Operation | Role |
| --- | --- |
| `Gcd` | Classical Euclidean gcd ($\ge 0$) |
| `Extended_Gcd` | $g,x,y$ with $ax+by=g$ |
| `Verify_Bezout` | Check the Bézout identity |
| `Quotients_By_Gcd` | $a/g$ and $b/g$ |
| `Are_Coprime` | $\gcd(a,b)=1$ |
| `Modular_Inverse` / `Is_Modular_Inverse` | $a^{-1} \bmod m$ when coprime |
| `Mod_Nonneg` / `Abs_LI` | Helpers |

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
