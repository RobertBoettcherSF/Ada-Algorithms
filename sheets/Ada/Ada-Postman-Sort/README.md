# Postman Sort in Ada 2023

## Project Overview

**Postman sort** (also called postal sorting or letter sorting) distributes
items into **pigeonholes** by successive characters or digits — the same idea
as a post office sorting mail by destination codes. Mail is first split into
broad bins (domestic vs international), then each bin is refined by region,
destination office, route, and so on. Computationally this is an **MSD**
(most-significant-digit) / multi-level **bucket** distribution:

1. Partition keys into buckets by the **most significant** digit (or character).
2. Recursively sort each non-empty bucket by the next digit, or stop when keys
   are exhausted for that subgroup.
3. Concatenate buckets in digit order.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
for **nonnegative** `Integer` keys. The default radix is $10$ (decimal);
`Sort_Base` accepts any base in $2 \ldots 256$. Distribution into digit
buckets is **stable** (left-to-right scatter).

Primary sources:

- [Wikipedia — Postman sort](https://en.wikipedia.org/wiki/Postman_sort)
  (may redirect; see educational notes)
- [Wikipedia — Bucket sort](https://en.wikipedia.org/wiki/Bucket_sort)
  (lists **Postman's sort** as a hierarchical bucket variant)

## Post-office analogy

| Postal step | Algorithm step |
| ----------- | -------------- |
| Sort domestic vs international | Bucket by MSD |
| Within country, sort by state/province | Recurse on next digit |
| Sort by local office / route | Deeper recursion |
| Stack trays in ZIP order | Concatenate buckets $0 \ldots k-1$ |

Because keys are not compared pairwise, sorting time is $O(c\,n)$ where $c$
depends on key length (digit depth) and the number of buckets — the same
family as top-down radix sort.

## MSD vs LSD (sibling radix sort)

| Variant | Digit order | Style | This package |
| ------- | ----------- | ----- | ------------ |
| **MSD / Postman** | Most → least significant | Recursive pigeonholes | **Yes** |
| **LSD radix** | Least → most significant | Flat counting-sort passes | Sibling package only |

For nonnegative integers treated with **leading-zero padding**, MSD and LSD
produce the same numeric order. MSD is the natural model for variable-length
strings and hierarchical keys (postal codes, file paths). This package
implements **MSD only** and does **not** `with` the LSD radix sibling —
the algorithm is reimplemented here.

## Relation to bucket and pigeonhole sorts

- **Bucket sort** scatters into bins, sorts each bin, then concatenates.
  Postman's sort is the hierarchical / multi-attribute form of that idea.
- **Pigeonhole sort** is the extreme of one distinct key per hole; Postman
  allows many keys per digit bucket and recurses on the next digit.
- **Top-down radix sort** is MSD with a power-of-two (or fixed) digit radix;
  Postman sort is the same distribution pattern described through the postal
  metaphor.

## Algorithm (MSD distribution)

Given an array $A$ of $n$ nonnegative keys and radix $k$ (the base):

1. If $n \le 1$, return. Let $M = \max A$; if $M = 0$, return.
2. Let $\mathit{Exp} = k^{p}$ be the highest power with $\mathit{Exp} \le M$.
3. **Scatter** (stable): for each key $x$ in index order, place $x$ into
   bucket $d(x) = \lfloor x / \mathit{Exp} \rfloor \bmod k$.
4. **Gather**: write buckets $0, 1, \ldots, k-1$ contiguously back into $A$.
5. If $\mathit{Exp} > 1$, **recurse** on each bucket with more than one
   element using $\mathit{Exp}/k$; otherwise stop.

### Complexity

With digit depth $d$ and radix $k$:

$$
O\bigl(d\,(n + k)\bigr)
$$

time in the uniform / balanced case, and $\Theta(n + k)$ auxiliary memory per
recursion level for the scatter buffer and counts (depth up to $d$). Worst
case degrades when many keys share long common prefixes (deep recursion on
large buckets), analogous to unbalanced bucket sort.

Stability follows from left-to-right scatter at every digit level.

## Signed-integer policy

Digit extraction $(x / k^{p}) \bmod k$ is defined here for **nonnegative**
keys only ($0 \ldots \texttt{Integer'Last}$). Any negative element raises
`Invalid_Argument` before sorting.

## Features

- **`Sort (A)`** — stable ascending MSD postman sort, base $10$.
- **`Sort_Base (A, Base)`** — same algorithm with radix in $2 \ldots 256$.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Recursive pigeonholes** — MSD distribute, recurse, concatenate.
- **Edge cases** — empty, singleton, all zeros, mixed digit lengths.
- **Guards** — `Invalid_Argument` on negatives or `A'Length > Max_Length`.
- **Arbitrary bounds** — works for any `A'First` (`Natural` index type).
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Ppostman_sort.gpr`.

## Usage

```bash
# Build test suite
make

# Run tests
make test

# Clean artifacts
make clean
```

### Expected Output

```text
Running tests...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 40.)

## Testing

The suite in `tests.adb` covers:

- Empty, singleton, and two-element arrays
- Classic multi-digit and variable-length numeric examples
- Already sorted, fully reversed, duplicates, and zeros
- Mixed / large digit lengths (up to `Integer'Last`)
- `Sort_Base` for radices $2$, $10$, $16$, and $256$
- Non-1-based index bounds
- Negatives and oversize arrays raising `Invalid_Argument`
- Idempotence; agreement of `Sort` with `Sort_Base (, 10)`
- Postal-prefix style keys; random nonnegative arrays vs insertion-sort reference

## Building

- Prerequisites: GNAT supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF 13+).
- Standard: ISO/IEC 8652:2023.
- Flags: `-gnatwa -gnat2022` with zero compiler warnings.

## API Summary

| Entity | Role |
| ------ | ---- |
| `Element_Array` | Unconstrained `array (Natural range <>) of Integer` |
| `Base_Range` | Subtype `Positive range 2 .. 256` |
| `Max_Length` | Educational capacity bound (`100_000`) |
| `Max_Base` | Upper radix bound (`256`) |
| `Invalid_Argument` | Raised on oversize length or negative keys |
| `Sort` | Ascending MSD postman sort, base $10$ |
| `Sort_Base` | Ascending MSD postman sort, explicit base |
| `Is_Sorted` | Nondecreasing predicate |

## License

Educational reference package. Algorithm description follows the public
Wikipedia articles on Postman sort and Bucket sort (Postman's sort variant).
