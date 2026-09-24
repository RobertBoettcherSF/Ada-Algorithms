# Bloom Filter — Ada 2023

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: Bloom filter](https://en.wikipedia.org/wiki/Bloom_filter)
— **Burton Howard Bloom**'s probabilistic membership structure (1970).

A Bloom filter is a **space-efficient** approximate set: queries return
either *possibly in the set* or *definitely not in the set*. **False
positives** are possible; **false negatives are not**. Elements can be
added but not removed in the classic structure (see counting Bloom filters
for deletions).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **State** | Bit array of length $m$ | All bits start at $0$ |
| **Hashes** | $k$ indices via double hashing | $h_i(x)=h_1(x)+i\cdot h_2(x)\bmod m$ |
| **Add** | Set $k$ bit positions to $1$ | Strings and `Natural` keys |
| **Query** | All $k$ bits must be $1$ | Else definitely absent |
| **Sizing** | $m=-\frac{n\ln p}{(\ln 2)^2}$, $k=\frac{m}{n}\ln 2$ | Target FPR $p$ |
| **Fill** | Fraction of bits set $X/m$ | Rises with inserts |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Filter`, `Real`, `Bit_Count`, `Hash_Count`, `Probability` | Domain model |
| Setup | `Create`, `Create_For_Capacity` | Explicit $m,k$ or capacity+$p$ |
| Insert / query | `Add`, `Might_Contain`, `Probably_Contains` | String / `Natural` overloads |
| Inspect | `Size`, `Hash_Functions`, `Insert_Count`, `Bits_Set` | Parameters / occupancy |
| Rates | `Fill_Ratio`, `Estimated_False_Positive_Rate`, `Estimated_Cardinality` | $X/m$, $\varepsilon$, $n^*$ |
| Optimal | `Optimal_M`, `Optimal_K`, `Optimal_K_From_Rate`, `Theoretical_FPR` | Classic formulas |
| Helpers | `Near`, `Ln`, `Exp`, `Clear` | Numerics / reset |

Strong typing uses domain subtypes (`Probability` open $(0,1)$, …).
Public subprograms carry `Pre` / `Global` where meaningful
(`SPARK_Mode => Off`). Named exception: `Invalid_Argument`.

## Formula summary (Bloom 1970 / Wikipedia)

### Structure

An empty Bloom filter is a bit array of $m$ bits, all $0$, equipped with
$k$ hash functions mapping keys into $\{0,\ldots,m-1\}$.

**Add** key $x$: for each $i=0,\ldots,k-1$, set bit $h_i(x)$ to $1$.

**Query** $x$: if any bit $h_i(x)$ is $0$, then $x$ is **definitely not**
in the set; if all are $1$, then $x$ is **possibly** in the set (true
positive or false positive).

### Double hashing

Independent hash families are expensive for large $k$. This package uses
**double hashing** (Kirsch–Mitzenmacher / Dillinger–Manolios style):

$$
h_i(x) = \bigl(h_1(x) + i\cdot h_2(x)\bigr) \bmod m,
$$

with $h_1,h_2$ derived from a 64-bit FNV-1a fingerprint of the key bytes
(and a fixed mix for $h_2$). If $h_2=0$, it is replaced by $1$.

### False-positive probability

After $n$ insertions, under standard independence approximations,

$$
\varepsilon \approx \left(1 - e^{-kn/m}\right)^k.
$$

The probability a given bit is still $0$ is $\approx e^{-kn/m}$, so the
fill ratio concentrates near $1-e^{-kn/m}$.

### Optimal $k$ and $m$

For fixed $m$ and $n$, the $k$ minimizing $\varepsilon$ is

$$
k = \frac{m}{n}\ln 2.
$$

For target false-positive rate $p$ (denoted $\varepsilon$ or $p$ in the
literature) and expected cardinality $n$,

$$
m = -\frac{n\ln p}{(\ln 2)^2},
\qquad
k = -\frac{\ln p}{\ln 2}.
$$

Equivalently $m/n \approx -2.08\ln p$ bits per element. About **10 bits
per element** yield roughly $p\approx 1\%$.

### Estimating cardinality

With $X$ bits set,

$$
n^* = -\frac{m}{k}\ln\left(1-\frac{X}{m}\right)
$$

(when $X<m$). Implemented as `Estimated_Cardinality`.

## Usage

```ada
with Bloom_Filter; use Bloom_Filter;

procedure Demo is
   F : Filter := Create_For_Capacity (N => 10_000, False_Positive_Rate => 0.01);
begin
   Add (F, "alice");
   Add (F, 42);
   if Might_Contain (F, "alice") then
      null;  -- possibly present (here: truly inserted)
   end if;
   if not Might_Contain (F, "carol") then
      null;  -- definitely absent
   end if;
end Demo;
```

Explicit size:

```ada
F : Filter := Create (M => 10_000, K => 7);
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pbloom_filter.gpr`. Main program is
`tests.adb` (no `main.adb`).

## Layout

| File | Role |
| --- | --- |
| `bloom_filter.ads` | Package spec |
| `bloom_filter.adb` | Package body |
| `bloom_filter.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

## References

- Bloom, B. H. *Space/Time Trade-offs in Hash Coding with Allowable Errors*.
  Communications of the ACM 13, 7 (1970), 422–426.
- Kirsch, A.; Mitzenmacher, M. *Less Hashing, Same Performance: Building a
  Better Bloom Filter*. ESA 2006 / Random Structures & Algorithms.
- Fan, L.; Cao, P.; Almeida, J.; Broder, A. *Summary Cache: A Scalable Wide-Area
  Web Cache Sharing Protocol* (counting Bloom filters). IEEE/ACM ToN 2000.
- Wikipedia: [Bloom filter](https://en.wikipedia.org/wiki/Bloom_filter).

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning and research.
