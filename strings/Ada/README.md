# Aho–Corasick Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the
[Aho–Corasick algorithm](https://en.wikipedia.org/wiki/Aho–Corasick_algorithm)
(Alfred V. Aho & Margaret J. Corasick, 1975) — a **dictionary-matching**
string search that locates **all** occurrences of every pattern in a
finite set simultaneously. Construction builds a **trie** of the
dictionary, then a BFS adds **failure (suffix) links** and **output
(dictionary-suffix) links** so the search never backtracks in the text.

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling packages:
[Knuth–Morris–Pratt](https://github.com/RobertBoettcherSF/Ada-Knuth-Morris-Pratt)
(single-pattern LPS / failure table) and
[Boyer–Moore](https://github.com/RobertBoettcherSF/Ada-Boyer-Moore)
(right-to-left single-pattern search).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Trie + failure links + output links

1. **Trie (goto)** — one node per distinct prefix of the dictionary;
   black child arcs spell the patterns from the root.
2. **Failure (suffix) links** — blue arcs computed by BFS: from each
   node, the longest proper suffix that is still a trie prefix. On a
   missing goto transition the automaton follows failure links instead
   of rewinding the text cursor.
3. **Output (dictionary-suffix) links** — green arcs to the next
   dictionary word along the failure chain, so a hit such as `she`
   also reports the suffix pattern `he` in constant extra work per
   emitted match.

A single left-to-right scan of the text follows goto / failure
transitions and, at every state, walks the output-link chain.

Complexity is linear in the total length of the patterns plus the
length of the text plus the number of reported matches:

$$
O\bigl(|P_1|+\cdots+|P_k| + n + z\bigr).
$$

## Classic example

Dictionary `{he, she, his, hers}` against text `ushers`:

| End | Patterns reported |
| --- | --- |
| 4 | `she` (start 2), `he` (start 3) |
| 6 | `hers` (start 3) |

The `he` hit is reached via the output link from the `she` node — the
algorithm reports **all** occurrences, including patterns that are
suffixes of others and overlapping hits.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| **Build** (trie + BFS links) | $O(m\cdot\lvert\Sigma\rvert)$ worst with dense goto; $O(m)$ expected on sparse dictionaries | $O(\textit{Max\_Nodes}\cdot\lvert\Sigma\rvert)$ |
| **Search** | $O(n + z)$ | $O(1)$ extra beyond the automaton |
| **Naive oracle** | $O(k\cdot n\cdot L)$ | $O(z)$ |

This package uses the full 8-bit `Character` alphabet
($\lvert\Sigma\rvert = 256$).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Dictionary** | `Build (Patterns) → Automaton` | Trie + failure + output links |
| **Scan** | `Search (Automaton, Text)` | One pass; emit via output links |
| **Oracle** | `Naive_Search` | Brute-force multi-pattern for tests |
| **Alphabet** | `Character'Pos` → $0..255$ | Documented educational bound |
| **Indexing** | 1-based | `Pattern_Index`, `Start_Position`, `End_Position` |
| **Empty list / pattern** | `Invalid_Argument` | Empty text → no matches |

## API

| Subprogram / type | Role |
| --- | --- |
| `Build (Patterns)` | Compile dictionary → `Automaton` |
| `Search (A, Text)` | All hits as `Match_List` |
| `Naive_Search (Patterns, Text)` | Linear oracle; same result contract |
| `Pattern_Count` / `Node_Count` | Automaton size queries |
| `Pattern_Length (A, Index)` | Length of pattern `Index` |
| `Patterns (...)` | Convenience builders → `Pattern_Array` |
| `Pattern_Array` | `array of Unbounded_String` |
| `Match` | `Pattern_Index`, `Start_Position`, `End_Position` |
| `Match_List` | `array (Positive range <>) of Match` |
| `Invalid_Argument` | Empty list/pattern or capacity overflow |
| `Max_Patterns` / `Max_Pattern_Len` / `Max_Nodes` | Educational caps |
| `Alphabet_Size` | $256$ |

Positions are 1-based offsets into `Text` viewed as `1 .. Text'Length`.
`Start_Position = End_Position - Pattern_Length + 1`. Matches are ordered
by ascending `End_Position`, then ascending `Pattern_Index`.

## Build / test

```bash
make        # gnatmake -gnatwa -gnat2022 -Paho_corasick.gpr
make test   # prints Results: N PASS, 0 FAIL
```

Requires GNAT with Ada 2022 support. Object files land in `obj/`, the
test binary in `bin/tests`.

## References

- [Wikipedia: Aho–Corasick algorithm](https://en.wikipedia.org/wiki/Aho–Corasick_algorithm)
- Aho, A. V.; Corasick, M. J. (1975). “Efficient string matching: an aid to bibliographic search.” *Communications of the ACM* 18(6):333–340.
- Commentz-Walter algorithm (see also), for the reverse multi-pattern automaton.
