# String Metrics Survey in Ada 2023

## Project Overview

A **string metric** (also called a string similarity metric or string
distance function) measures distance — inverse similarity — between two
text strings for approximate matching, fuzzy search, and related tasks.
In the strict mathematical sense a metric must satisfy the **triangle
inequality**; in practice the term is often used more loosely for any
dissimilarity or similarity score between strings.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational *survey*:
self-contained implementations of several classical measures in one
mini-suite. Matching is **case-sensitive** (no folding). Characters are
opaque octets (Latin-1 `Character`); there is no Unicode normalization.
All algorithms live **inline** in `String_Metrics` — there is **no**
`with` of sibling Ada-* packages.

Primary source:
[Wikipedia — String metric](https://en.wikipedia.org/wiki/String_metric).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with string siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-String-Metrics`) | Survey: Levenshtein, OSA DL, Hamming, Jaro–Winkler, Dice bigrams |
| **[Ada-Levenshtein-Distance](https://github.com/RobertBoettcherSF/Ada-Levenshtein-Distance)** | Dedicated unit-cost Levenshtein + Similarity |
| **[Ada-Damerau-Levenshtein-Distance](https://github.com/RobertBoettcherSF/Ada-Damerau-Levenshtein-Distance)** | Dedicated OSA / restricted Damerau–Levenshtein |
| **[Ada-Jaro-Winkler-Distance](https://github.com/RobertBoettcherSF/Ada-Jaro-Winkler-Distance)** | Dedicated Jaro / Jaro–Winkler similarity & distance |
| **[Ada-Dice-Coefficient](https://github.com/RobertBoettcherSF/Ada-Dice-Coefficient)** | Dedicated Sørensen–Dice over unique bigrams |
| **[Ada-Trigram-Search](https://github.com/RobertBoettcherSF/Ada-Trigram-Search)** | Unique trigrams + Dice similarity |

README links only — **no** package `with` of siblings.

## Triangle inequality nuance

A mathematical **metric** $d$ on strings satisfies non-negativity,
identity of indiscernibles, symmetry, and the triangle inequality
$d(x,z) \le d(x,y) + d(y,z)$.

| Measure in this survey | Role | Triangle? |
| --- | --- | --- |
| `Levenshtein` | unit-cost edit **distance** | yes (metric) |
| `Damerau_Levenshtein_OSA` | OSA edit **distance** | yes under OSA costs (restricted DL) |
| `Hamming` | equal-length disagreement **distance** | yes (on equal-length strings) |
| `Jaro_Winkler_Similarity` | similarity in $[0,1]$ | $1-\mathrm{sim}$ is **not** a metric in general |
| `Dice_Bigram` | set similarity in $[0,1]$ | Dice distance $1-\mathrm{DSC}$ need not obey triangle |
| `Normalized_Levenshtein_Similarity` | similarity from Levenshtein | derived from a metric, but is a similarity not a distance |

Wikipedia notes that functions such as **Jaro–Winkler** measure
dissimilarity without necessarily fulfilling the triangle inequality,
and therefore are not metrics in the mathematical sense. Treat
similarities as ranking scores; use true distances when you need a
metric space (clustering with triangle guarantees, etc.).

## Algorithms

### Levenshtein

Let $A$ have length $m$ and $B$ length $n$. $D(i,j)$ is the distance
between prefixes $A[1..i]$ and $B[1..j]$:

$$
D(i,0)=i,\qquad D(0,j)=j
$$

$$
D(i,j)=\min\begin{cases}
D(i-1,j)+1 & \text{(delete)} \\
D(i,j-1)+1 & \text{(insert)} \\
D(i-1,j-1)+\delta(A[i],B[j]) & \text{(substitute / match)}
\end{cases}
$$

where $\delta(x,y)=0$ if $x=y$ else $1$. Answer $D(m,n)$. This package
uses a two-row rolling DP ($O(\min(m,n))$ auxiliary space).

Classic example: $\texttt{kitten}$ / $\texttt{sitting}$ → $3$.

### Damerau–Levenshtein (OSA)

Same recurrence plus an adjacent-transposition option when
$A[i]=B[j-1]$ and $A[i-1]=B[j]$, using $D(i-2,j-2)+\delta$. The
**optimal string alignment** (OSA) restriction forbids editing the same
substring more than once. Contrast: $\texttt{ab}$ / $\texttt{ba}$ → $1$
(OSA) vs $2$ (classical Levenshtein).

### Hamming

For equal-length strings, count positions where characters differ.
Requires $|A|=|B|$ (raises `Invalid_Argument` otherwise). Empty/empty
→ $0$.

### Jaro–Winkler similarity

Matching window $w=\max\bigl(0,\lfloor\max(|A|,|B|)/2\rfloor-1\bigr)$.
With $m$ matches and $t$ transpositions:

$$
\mathrm{sim}_j=\frac{1}{3}\left(\frac{m}{|A|}+\frac{m}{|B|}+\frac{m-t}{m}\right)
\quad (m>0;\ \mathrm{sim}_j=0\text{ if }m=0)
$$

$$
\mathrm{sim}_w=\mathrm{sim}_j+\ell\cdot p\cdot(1-\mathrm{sim}_j)
$$

where $\ell$ is the common prefix length capped at $4$ and $p$ defaults
to $0.1$. Empty/empty → $1.0$; exactly one empty → $0.0$.

### Dice (unique character bigrams)

Overlapping windows $S(i..i+1)$ form set $T_S$ (duplicates collapse):

$$
\mathrm{DSC}(A,B)=\frac{2\,|T_A\cap T_B|}{|T_A|+|T_B|}
$$

Both empty → $1.0$. Strings of length $<2$ yield empty bigram sets.

### Normalized Levenshtein similarity

$$
\mathrm{NormLev}(A,B)=\begin{cases}
1.0 & \text{if } |A|=|B|=0 \\
1-\dfrac{\mathrm{Lev}(A,B)}{\max(|A|,|B|)} & \text{otherwise}
\end{cases}
$$

## API Summary

Package `String_Metrics`:

| Entity | Kind | Notes |
| --- | --- | --- |
| `Max_Len` | `constant Positive := 1_000` | pedagogical bound |
| `Invalid_Argument` | exception | oversize or Hamming length mismatch |
| `Levenshtein (A, B)` | `Natural` | unit-cost edit distance |
| `Damerau_Levenshtein_OSA (A, B)` | `Natural` | restricted DL / OSA |
| `Hamming (A, B)` | `Natural` | equal length only |
| `Jaro_Winkler_Similarity (A, B; P := 0.1)` | `Float` | similarity in $[0,1]$ |
| `Dice_Bigram (A, B)` | `Float` | unique-bigram Dice; both empty → $1.0$ |
| `Normalized_Levenshtein_Similarity (A, B)` | `Float` | $1 - \mathrm{Lev}/\max(\|A\|,\|B\|)$ |

Every entry point raises `Invalid_Argument` when either string exceeds
`Max_Len`. Hamming also raises on unequal lengths.

## Complexity

| Function | Time | Aux space |
| --- | --- | --- |
| `Levenshtein` | $O(mn)$ | $O(\min(m,n))$ |
| `Damerau_Levenshtein_OSA` | $O(mn)$ | $O(\min(m,n))$ |
| `Hamming` | $O(n)$ | $O(1)$ |
| `Jaro_Winkler_Similarity` | $O(mn)$ worst (windowed scan) | $O(m+n)$ flags |
| `Dice_Bigram` | $O(u\cdot n)$ unique collect | $O(n)$ bigram buffer |
| `Normalized_Levenshtein_Similarity` | same as Levenshtein | same |

## Build and test

```bash
make
make test
# or:
gnatmake -gnatwa -gnat2022 -Pstring_metrics.gpr
./bin/tests
```

Requires GNAT (Ada 2022 switch `-gnat2022`). Expect **zero** `-gnatwa`
warnings and all tests **PASS**.

## Applications (from Wikipedia)

String metrics appear in information integration, fraud detection,
fingerprint / DNA / RNA analysis, plagiarism detection, ontology
merging, image analysis, database deduplication, data mining,
incremental search, malware detection, and semantic knowledge
integration.

## License

Educational reference implementation for the RobertBoettcherSF Ada
algorithm series. Adapt freely with attribution.
