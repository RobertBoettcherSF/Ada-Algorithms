# Matching Wildcards (Globbing) — Ada 2023 Survey

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Matching wildcards](https://en.wikipedia.org/wiki/Matching_wildcards):
anchored Windows / shell-glob matching with `*` (any sequence) and `?`
(exactly one character). Two runnable sketches — **Krauss** non-recursive
star-bookmark matching and classic **DP** boolean-table matching — plus a
`Method_Kind` dispatcher. Both methods must agree on every test.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (README links only — **no** `with` deps):

- **[Ada-Krauss-Matching-Wildcards](https://github.com/RobertBoettcherSF/Ada-Krauss-Matching-Wildcards)** — dedicated Krauss bookmark package (reimplemented here as a sketch; do not `with` it)
- Related: [glob (programming)](https://en.wikipedia.org/wiki/Glob_(programming)), [pattern matching](https://en.wikipedia.org/wiki/Pattern_matching), wildmat / fnmatch

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Problem** | Anchored wildcard match | Entire pattern vs entire text |
| **`*`** | Any sequence (incl. empty) | Greedy via bookmarks or DP |
| **`?`** | Exactly one character | Like `.` in a tiny regex |
| **Literals** | Case-sensitive equality | Ada `Character` compare |
| **Empty pattern** | Matches only empty text | Documented choice |
| **Krauss** | Non-recursive bookmarks | Linear backtracking after each `*` |
| **DP** | Boolean table $O(\|p\|\|t\|)$ | Richter / Snippets style recurrence |
| **Dispatcher** | `Match (…, Method)` | Default `Krauss` |
| **Escapes / classes** | None | Windows C-runtime style grammar |

## Brief history

Early wildcard matchers often used **recursion** on `*` (backtracking over
suffixes). Critics favoured **non-recursive** walkers that save a single
pattern/text bookmark and retry after consuming one more text character —
notably Kirk J. Krauss’s algorithm used at IBM. Separately, the problem has a
natural **dynamic-programming** formulation (similar in shape to edit
distance): fill a boolean table whose entry $m_{ij}$ is true when the pattern
truncated to length $i$ matches the text truncated to length $j$. Recursive
matchers (wildmat, fnmatch, Richter) and iterative ones (Krauss, Cantatore,
Kurt) all target the same small grammar; converting wildcards to a full regex
engine is possible but heavier than needed for `*` / `?` alone.

## Method taxonomy (this package)

| `Method_Kind` | Idea | Runnable? | Stack |
| --- | --- | --- | --- |
| `Krauss` | Star bookmark + linear retry | Yes | Non-recursive |
| `DP` | Classic $O(\|p\|\|t\|)$ boolean table | Yes | Iterative table |

Both sketches share identical semantics. Catalogue siblings (recursive wildmat,
fnmatch, NFA conversion) are discussed on Wikipedia and linked above; they are
not implemented here.

## Recurrence (DP sketch)

With 1-based lengths and $DP(i,j)$ meaning “pattern prefix of length $i$
matches text prefix of length $j$”:

$$
\begin{aligned}
DP(0,0) &= \mathrm{true} \\
DP(0,j) &= \mathrm{false} && (j > 0) \\
DP(i,0) &= (p_i = \text{‘*’}) \land DP(i-1,0) \\
DP(i,j) &=
  \begin{cases}
    DP(i,j-1) \lor DP(i-1,j) & \text{if } p_i = \text{‘*’} \\
    DP(i-1,j-1) & \text{if } p_i = \text{‘?’} \lor p_i = t_j \\
    \mathrm{false} & \text{otherwise}
  \end{cases}
\end{aligned}
$$

The Krauss walker realises the same language without allocating the table:
when a `*` is seen, bookmarks are saved; on a later mismatch the text bookmark
advances by one and matching resumes after that star.

## Features

- **Windows / glob semantics** — `*`, `?`, literals; no escapes or `[…]` classes.
- **Two agreeing methods** — `Match_Krauss` and `Match_DP`; dispatcher `Match`.
- **Empty-pattern rule** — empty `Pattern` matches only empty `Text`.
- **Taxonomy helpers** — `Method_Name`, `Method_Count`, `Describe`.
- **`Invalid_Argument`** — declared for API symmetry; never raised under this grammar.
- **Contract-friendly** — `Global => null` on pure matchers.

## API

```ada
with Matching_Wildcards; use Matching_Wildcards;

--  Explicit sketches
OK1 : constant Boolean := Match_Krauss ("*foo*", "seafood");
OK2 : constant Boolean := Match_DP ("mini*", "minicomputer");

--  Dispatcher (default Method => Krauss)
OK3 : constant Boolean := Match ("???*", "cat", DP);
OK4 : constant Boolean := Match ("a?c", "aXc");  -- Krauss default

--  Alias (Krauss)
OK5 : constant Boolean := Is_Match ("*.*", "a.b");
```

### Classic examples

| Pattern | Meaning |
| --- | --- |
| `*foo*` | any string containing `foo` |
| `mini*` | any string that begins with `mini` |
| `???*` | any string of three or more characters |
| `file?.txt` | `file` + one char + `.txt` |

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
Matching_Wildcards test suite
=============================

=== 1. Empty pattern / empty text ===
  PASS — ...
...
Results:  NNN PASS,  0 FAIL
```

## Testing

The suite in `tests.adb` covers:

- Empty pattern / empty text edge cases.
- Literals and **case sensitivity**.
- `?` alone and in mixes; `*` alone, prefix, suffix, and surround forms.
- Consecutive stars and delayed-suffix **backtracking** (incl. the classic
  `da*da*da*` / `daaadabadmanda` case).
- Wikipedia / glob-like extras (`*foo*`, `mini*`, `???*`, `*.*`).
- **Cross-method agreement** on every Expect pair plus extra Agree pairs.
- Dispatcher / `Is_Match` / taxonomy helpers.

Build uses `gnatmake -gnatwa -gnat2022` with **zero warnings**. Both methods
must report identical True/False on all cases.

## Building

- **Prerequisites:** GNAT supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF 13+, GNAT 14+, or GNAT Pro).
- **Standard:** ISO/IEC 8652:2023.
- **Flags:** `-gnatwa -gnat2022` (treat warnings as visible; Ada 2022 language mode).

```bash
gnatmake -gnatwa -gnat2022 -Pmatching_wildcards.gpr
```

## References

- [Matching wildcards (Wikipedia)](https://en.wikipedia.org/wiki/Matching_wildcards) — primary survey source
- [Krauss wildcard-matching algorithm (Wikipedia)](https://en.wikipedia.org/wiki/Krauss_matching_wildcards_algorithm)
- [Ada-Krauss-Matching-Wildcards](https://github.com/RobertBoettcherSF/Ada-Krauss-Matching-Wildcards) — sibling package
- [Glob (programming)](https://en.wikipedia.org/wiki/Glob_(programming))
- [Pattern matching](https://en.wikipedia.org/wiki/Pattern_matching)
