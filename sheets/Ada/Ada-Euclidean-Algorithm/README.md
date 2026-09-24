# Euclidean algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the classical
**Euclidean algorithm** — computing $\gcd(a,b)$ by successive remainders.
See [Wikipedia: Euclidean algorithm](https://en.wikipedia.org/wiki/Euclidean_algorithm).

Note: the spreadsheet row title may say “Euclidian”; Wikipedia spelling is
**Euclidean**.

This package is a **classroom sketch** on `Long_Integer`: classical gcd,
lcm, coprimality, division-step counts, and Stein’s binary gcd (same
results). It is **not** a production big-integer library.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Related / sibling rows (README links only — **no** package `with`):

- **[Ada-Extended-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Extended-Euclidean-Algorithm)** —
  Bézout coefficients $ax+by=g$ and modular inverse

## API sketch

| Operation | Role |
| --- | --- |
| `Gcd` | Classical Euclidean gcd ($\ge 0$) |
| `Lcm` | Least common multiple (educational bound) |
| `Are_Coprime` | $\gcd(a,b)=1$ |
| `Division_Steps` | Remainder-loop iteration count |
| `Binary_Gcd` | Stein’s algorithm (same result as `Gcd`) |

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
