# Krauss Wildcard-Matching Algorithm in Ada 2023

## Project Overview

The **Krauss wildcard-matching algorithm** is a pattern-matching algorithm that implements the familiar Windows / shell-glob wildcard syntax (`*` and `?`) with a **non-recursive** pointer-or-index bookmark strategy. This package provides an Ada 2023 (ISO/IEC 8652:2023) educational implementation of that approach, based on the history, usage notes, and examples documented on [Wikipedia: Krauss wildcard-matching algorithm](https://en.wikipedia.org/wiki/Krauss_matching_wildcards_algorithm).

Unlike regular expressions, the Krauss grammar is intentionally small: there are no character classes, quantifiers, captures, or alternation. The payoff is a matcher that is easy to reason about, safe from recursion-depth stack overflows, and linear in its backtracking over each `*`.

## History and Intent

Kirk J. Krauss developed the algorithm after an unsuccessful search for a reliable **non-recursive** wildcard matcher. An early single-`while`-loop design drew community feedback; profiler-driven refinement led to a two-loop strategy that is especially fast on empty strings and on patterns with no wildcards. The open-source C++ forms (pointer-based and portable index-based) are published under the Apache License 2.0 and ship with shared test-case code. Ports have appeared in DataFlex, log readers, and the Unreal Engine model viewer.

This Ada package follows the same **star-bookmark** idea in the portable / index-based spirit: walk `Pattern` and `Text` together; when a `*` is seen, save bookmarks and try to match the remainder; on a later mismatch, advance the text bookmark by one character and retry. No call stack grows with input length.

## Features

- **Windows / glob semantics**
  - `*` matches any sequence of zero or more characters (including empty).
  - `?` matches exactly one character.
  - Every other character matches itself **literally** and **case-sensitively** (Ada `Character` equality).
- **Non-recursive Krauss bookmark walker** — linear backtracking after each `*`; consecutive `*` characters behave as a single star.
- **Empty-pattern rule** — empty `Pattern` matches only empty `Text` (documented choice; avoids POSIX `fnmatch` empty-pattern quirks).
- **Simple API** — `Match (Pattern, Text) return Boolean` with `Is_Match` as a rename alias.
- **`Invalid_Argument`** — declared for API symmetry; under this grammar every pattern is well-formed, so `Match` never raises it.
- **Contract-friendly pure function** — `Global => null`; suitable for classroom use and embedding in larger tools.

## Contrast with Regular Expressions

| Concern | Krauss / glob wildcards | Typical regex |
| --- | --- | --- |
| Grammar size | Two meta-characters | Large operator set |
| Matching cost | Linear bookmark retries | Can be exponential without care |
| Stack safety | Non-recursive by design | Often recursive or NFA-stack based |
| Escape / classes | None (literals only) | Escapes, classes, groups, … |
| Best for | File globs, filters, simple masks | Full language / structured text |

Use Krauss when you want shell-style masks; use a regex engine when you need the full formal-language toolkit.

## API

```ada
with Krauss_Matching_Wildcards; use Krauss_Matching_Wildcards;

--  True when Text matches Pattern (* = any sequence, ? = one char).
--  Matching is case-sensitive. Empty Pattern matches only empty Text.
Found : constant Boolean := Match ("*foo*", "seafood");

--  Alias:
Found2 : constant Boolean := Is_Match ("mini*", "minicomputer");
```

### Wikipedia-style examples

| Pattern | Meaning |
| --- | --- |
| `*foo*` | any string containing `foo` |
| `mini*` | any string that begins with `mini` (including `mini` itself) |
| `???*` | any string of three or more characters |

## Usage

The standalone test executable doubles as both an automated regression suite and an API usage demonstration.

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
Krauss_Matching_Wildcards test suite
====================================

=== 1. Empty pattern / empty text ===
  PASS — ...
...
Results:  NN PASS,  0 FAIL
```

## Testing

The suite in `tests.adb` covers:

- Empty pattern / empty text edge cases.
- Literals and **case sensitivity**.
- `?` alone and in mixes; `*` alone, prefix, suffix, and surround forms.
- Consecutive stars (`**`, `***a***`).
- Deliberate no-match and delayed-suffix backtracking cases.
- `Is_Match` alias equivalence.
- Cross-checks against a short-string recursive **oracle**.
- Wikipedia examples (`*foo*`, `mini*`, `???*`) plus glob-like extras.

Build uses `gnatmake -gnatwa -gnat2022` with **zero warnings**.

## Building

- **Prerequisites:** GNAT supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF 13+, GNAT 14+, or GNAT Pro).
- **Standard:** ISO/IEC 8652:2023.
- **Flags:** `-gnatwa -gnat2022` (treat warnings as visible; Ada 2022 language mode).

```bash
gnatmake -gnatwa -gnat2022 -Pkrauss_matching_wildcards.gpr
```

## References

- [Krauss wildcard-matching algorithm (Wikipedia)](https://en.wikipedia.org/wiki/Krauss_matching_wildcards_algorithm)
- Related concepts: [glob (programming)](https://en.wikipedia.org/wiki/Glob_(programming)), [pattern matching](https://en.wikipedia.org/wiki/Pattern_matching), wildmat.
