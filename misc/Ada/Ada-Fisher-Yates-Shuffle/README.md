# Fisher–Yates Shuffle in Ada 2023

## Project Overview

The **Fisher–Yates shuffle** (also called the Knuth shuffle) generates a
uniformly random permutation of a finite sequence. The modern **in-place**
variant due to Richard Durstenfeld (1964), popularised by Donald Knuth, needs
only $O(1)$ extra memory and $n-1$ random index draws for an array of length
$n$.

If each draw is unbiased, every one of the $n!$ permutations is equally
likely:

$$
\Pr(\pi) = \frac{1}{n!} \quad \text{for every permutation } \pi.
$$

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
with a capacity guard (`Max_N = 100\,000`), a seeded 64-bit LCG for
reproducible tests, and an access-to-function RNG injection point.

Primary source:
[Wikipedia — Fisher–Yates shuffle](https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle).

## Algorithm

Modern in-place Fisher–Yates (Durstenfeld / Knuth) on array $A$ with bounds
`A'First .. A'Last`:

$$
\begin{align*}
&\textbf{for } i \leftarrow \mathrm{Last} \textbf{ downto } \mathrm{First}+1
\textbf{ do}\\
&\quad j \leftarrow \mathrm{Uniform}\{\mathrm{First},\ldots,i\}\\
&\quad \mathrm{swap}(A[j], A[i])
\end{align*}
$$

Equivalently in Ada:

```ada
for I in reverse A'First + 1 .. A'Last loop
   J := Random_In (A'First, I);
   Swap (A (J), A (I));
end loop;
```

Empty and singleton arrays are **no-ops**. The number of swaps performed is
at most $n-1$; after the loop finishes, position $i$ holds an element chosen
uniformly from the still-unfixed prefix.

### Why it is unbiased

At step $i$ there are $i - \mathrm{First} + 1$ candidates for $A[i]$. The
product of the reciprocal branch factors is

$$
\prod_{k=2}^{n} \frac{1}{k} = \frac{1}{n!},
$$

so each full permutation has probability $1/n!$ whenever every index draw is
uniform on its legal range.

## Complexity

| Resource | Bound | Notes |
| -------- | ----- | ----- |
| Time | $O(n)$ | Exactly $n-1$ index draws and $\le n-1$ swaps |
| Extra space | $O(1)$ | In-place (aside from RNG state) |
| RNG calls | $n-1$ | One per loop iteration |

## Features

- **`Shuffle (A, Seed)`** — in-place shuffle driven by a 64-bit LCG;
  `Seed : in out Interfaces.Unsigned_64` is advanced so successive calls
  continue the stream.
- **`Shuffle (A, Next)`** — same algorithm with
  `type Random_Index is access function (Lo, Hi : Natural) return Natural`
  for fully injectable RNG (ideal for tests / mocking).
- **`Is_Permutation_Of (A, Original)`** — same-multiset predicate for tests.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N` (default
  $100\,000$), when `Next` is null, or when an injected draw falls outside
  `A'First .. I`.
- **Arbitrary bounds** — works for any `A'First` (`Natural` index).
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pfisher_yates_shuffle.gpr`.

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
Results:  N PASS, 0 FAIL
```

with $N \ge 40$.

### Example

```ada
with Interfaces; use Interfaces;
with Fisher_Yates_Shuffle; use Fisher_Yates_Shuffle;

procedure Demo is
   A    : Element_Array := [1, 2, 3, 4, 5];
   Seed : Unsigned_64 := 42;
begin
   Shuffle (A, Seed);
   --  A is now a uniform random permutation of 1..5
end Demo;
```

Injected RNG form:

```ada
function My_Next (Lo, Hi : Natural) return Natural;
--  ...

Shuffle (A, My_Next'Access);
```

## API Summary

| Entity | Role |
| ------ | ---- |
| `Max_N` | Maximum accepted length ($100\,000$) |
| `Element_Array` | `array (Natural range <>) of Integer` |
| `Random_Index` | Access-to-function RNG on `Lo .. Hi` |
| `Shuffle (A, Seed)` | Seeded LCG shuffle |
| `Shuffle (A, Next)` | Injected-RNG shuffle |
| `Is_Permutation_Of` | Multiset equality helper |
| `Invalid_Argument` | Length / null / OOR guard |

## Project Layout

```text
ada-fisher-yates-shuffle/
├── .gitignore
├── Makefile
├── README.md
├── fisher_yates_shuffle.ads
├── fisher_yates_shuffle.adb
├── fisher_yates_shuffle.gpr
└── tests.adb
```

## References

1. [Fisher–Yates shuffle — Wikipedia](https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle)
2. Fisher, R. A. & Yates, F. (1938). *Statistical tables for biological,
   agricultural and medical research*.
3. Durstenfeld, R. (1964). Algorithm 235: Random permutation.
   *Communications of the ACM*.
4. Knuth, D. E. *The Art of Computer Programming*, Vol. 2: Seminumerical
   Algorithms — §3.4.2.

## License

Educational example code; use freely with attribution to the Wikipedia
article and the classical references above.
