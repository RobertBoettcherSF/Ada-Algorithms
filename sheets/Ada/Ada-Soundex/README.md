# American Soundex in Ada 2023

## Project Overview

**American Soundex** is a phonetic algorithm that encodes an English
surname as one uppercase letter followed by three digits — for example
$\texttt{Robert}\to\texttt{R163}$, $\texttt{Rupert}\to\texttt{R163}$,
$\texttt{Rubin}\to\texttt{R150}$. Names that sound alike tend to share
a code, which historically helped census and genealogy indexes group
variant spellings.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of the American Soundex rules used by the U.S.
National Archives (NARA) and documented on Wikipedia: keep the first letter,
map consonants to digits, drop vowels / $\texttt{H}$ / $\texttt{W}$ / $\texttt{Y}$
after the first letter (H/W do not separate equal codes; vowels and Y do),
collapse adjacent equal digit codes, and pad
with $\texttt{0}$ to length 4.

Primary source:
[Wikipedia — Soundex](https://en.wikipedia.org/wiki/Soundex).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with string siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Soundex`) | Phonetic surname code (letter + 3 digits) |
| **[Ada-Levenshtein-Distance](https://github.com/RobertBoettcherSF/Ada-Levenshtein-Distance)** | Unit-cost insert/delete/substitute edit distance |
| **[Ada-Dice-Coefficient](https://github.com/RobertBoettcherSF/Ada-Dice-Coefficient)** | Bigram-set Sørensen–Dice similarity |
| **[Ada-Jaro-Winkler-Distance](https://github.com/RobertBoettcherSF/Ada-Jaro-Winkler-Distance)** | Prefix-biased Jaro–Winkler similarity |
| **[Ada-String-Metrics](https://github.com/RobertBoettcherSF/Ada-String-Metrics)** | Bundle of common string metrics |

README links only — **no** package `with` of siblings.

## Algorithm

### Letter → digit map

| Digits | Letters |
| ------ | ------- |
| 1 | B, F, P, V |
| 2 | C, G, J, K, Q, S, X, Z |
| 3 | D, T |
| 4 | L |
| 5 | M, N |
| 6 | R |
| 0 (drop) | A, E, I, O, U, H, W, Y |

### Encoding steps

1. Walk the input left-to-right. **Ignore non-letters** (digits,
   spaces, punctuation). Fold letters to upper case.
2. Retain the **first letter** as the code's leading character.
3. Remember that letter's map value as $\mathrm{Prev}$.
4. For each later letter with map code $c$:
   - if $c=0$ and the letter is H or W: skip, leave $\mathrm{Prev}$
     unchanged;
   - if $c=0$ and the letter is a vowel or Y: skip and set
     $\mathrm{Prev}:=0$;
   - if $c=\mathrm{Prev}$, skip (adjacent duplicate);
   - otherwise append digit $c$ and set $\mathrm{Prev}:=c$.
5. Stop after three digits; **pad** with $\texttt{0}$ to length 4.

If the input is empty, longer than $\mathrm{Max\_Len}$, or contains no
A–Z letter after stripping non-letters, `Encode` raises
`Invalid_Argument`.

### H / W / Y variant (documented choice)

This package implements **American Soundex as described by NARA /
Wikipedia**:

- $\texttt{H}$ and $\texttt{W}$ are dropped and **do not** reset
  $\mathrm{Prev}$, so equal consonant codes on either side **collapse**.
- Vowels $\texttt{A,E,I,O,U}$ and $\texttt{Y}$ are dropped and **do**
  reset $\mathrm{Prev}$, so equal consonant codes on either side of a
  vowel are **both kept**.

Classic consequence:

$$
\texttt{Ashcraft}\to\texttt{A261}
$$

(not $\texttt{A226}$). A rule that treated H/W as separators preventing
collapse would yield $\texttt{A226}$; that rule is **not** used here.

### Classic examples

| Name | Code |
| ---- | ---- |
| Robert | R163 |
| Rupert | R163 |
| Rubin | R150 |
| Ashcraft | A261 |
| Ashcroft | A261 |
| Tymczak | T522 |
| Pfister | P236 |
| Euler | E460 |
| Ellery | E460 |
| Gauss | G200 |
| Ghosh | G200 |
| Hilbert | H416 |
| Heilbronn | H416 |
| Knuth | K530 |
| Kant | K530 |
| Lloyd | L300 |
| Ladd | L300 |
| Lukasiewicz | L222 |
| Lissajous | L222 |

`Codes_Match(A,B)` is simply $\mathrm{Encode}(A)=\mathrm{Encode}(B)$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(n)$ one left-to-right pass |
| Auxiliary space | $O(1)$ fixed 4-character result |
| Capacity | $n \le \mathrm{Max\_Len}=10000$ |

## Features

- **`Encode`** — American Soundex `Code_String` (always length 4).
- **`Codes_Match`** — equality of Soundex codes.
- **Non-letters skipped** — educational choice; documentedly ignore
  digits, spaces, and punctuation rather than rejecting them.
- **Case-insensitive** — letters folded to upper case.
- **H/W non-separating (NARA/Wikipedia)** — Ashcraft $\to$ A261; vowels/Y separate.
- **Capacity / empty guard** — `Invalid_Argument` for empty, overlong,
  or letter-free input.
- **Arbitrary `String'First`** — slices work.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Psoundex.gpr`.

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

=== 1. Classic surname examples ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 100.)

## Testing

The test suite in `tests.adb` covers:

- Classic surnames (Robert/Rupert/Rubin, Ashcraft/Ashcroft, Knuth table)
- Case folding and mixed case
- Padding with zeros (short names, single letter)
- Adjacent duplicate collapse and H/W/Y drop (A261)
- First-letter same-code skip (Pfister → P236)
- Non-letter stripping (spaces, hyphens, digits)
- `Codes_Match` true/false pairs
- Empty / letter-free / over-`Max_Len` → `Invalid_Argument`
- Non-1 `String'First` slices
- Length-4 result invariant and digit alphabet checks
- Bulk micro-cases over the alphabet

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Soundex is
   Max_Len : constant Positive := 10_000;
   Invalid_Argument : exception;

   subtype Code_String is String (1 .. 4);

   function Encode (Name : String) return Code_String;
   function Codes_Match (A, B : String) return Boolean;
end Soundex;
```

Raises `Invalid_Argument` if the input is empty, longer than `Max_Len`,
or contains no A–Z letter.

## License

Educational reference implementation. See repository `LICENSE` if present.
