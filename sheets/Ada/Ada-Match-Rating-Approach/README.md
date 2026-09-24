# Match Rating Approach (MRA) in Ada 2023

## Project Overview

The **Match Rating Approach (MRA)** is a phonetic algorithm developed by
Western Airlines in 1977 for indexing and comparing homophonous personal
names. Unlike Soundex or Metaphone (which only emit a code), MRA defines
both an alphabetic **codex** (also called a personal numeric identifier /
PNI, at most 6 letters) and a **similarity comparison** with a
length-dependent minimum rating table.

Classic Wikipedia examples:

| Names | Codexes | Min rating | Similarity | Match? |
| --- | --- | --- | --- | --- |
| Byrne / Boern | BYRN / BRN | 4 | 5 | yes |
| Smith / Smyth | SMTH / SMYTH | 3 | 5 | yes |
| Catherine / Kathryn | CTHRN / KTHRYN | 3 | 4 | yes |

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of the Western Airlines / Wikipedia encoding rules plus the
Apache Commons Codec L→R / R→L similarity scrub (the concrete procedure
that reproduces the published ratings above).

Primary sources:

- [Wikipedia — Match rating approach](https://en.wikipedia.org/wiki/Match_rating_approach)
- G. B. Moore et al., Western Airlines name-matching work (1977)
- Reference comparison behaviour aligned with [Apache Commons Codec `MatchRatingApproachEncoder`](https://commons.apache.org/proper/commons-codec/apidocs/org/apache/commons/codec/language/MatchRatingApproachEncoder.html)

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with string siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Match-Rating-Approach`) | Phonetic codex ≤6 + similarity threshold |
| **[Ada-Soundex](https://github.com/RobertBoettcherSF/Ada-Soundex)** | American Soundex (letter + 3 digits) |
| **[Ada-NYSIIS](https://github.com/RobertBoettcherSF/Ada-NYSIIS)** | NYSIIS alphabetic key (trunc. 6) |
| **[Ada-Metaphone](https://github.com/RobertBoettcherSF/Ada-Metaphone)** | Original Metaphone (trunc. 4) |
| **[Ada-Levenshtein-Distance](https://github.com/RobertBoettcherSF/Ada-Levenshtein-Distance)** | Unit-cost edit distance |

README links only — **no** package `with` of siblings.

## Algorithm

### Encoding (codex / PNI)

1. **Strip non-letters** and fold to upper case.
2. **Delete vowels** `{A,E,I,O,U}` unless the vowel **begins** the word.
   `Y` is **not** a vowel (kept as a consonant — crucial for Smith/Smyth).
3. **Collapse adjacent duplicate** letters (double consonants, including
   `YY`). Educational choice: full adjacent collapse (e.g. `Pfeiffer` →
   `PFR`), clearer than a single non-overlapping pair replace.
4. If the result is longer than 6 characters, keep the **first 3** and
   **last 3** only.

The encoded name never contains more than 6 alphabetic characters.
Length is therefore $1..\mathrm{Max\_Code\_Len}$ (unpadded).

If the input is empty, longer than $\mathrm{Max\_Len}$, or contains no
A–Z letter after stripping non-letters, `Encode` raises
`Invalid_Argument`.

### Comparison

In this section “string” means **encoded** string.

1. If the length difference between the encodings is **3 or greater**,
   no similarity comparison is done (`Compare` → False;
   `Similarity_Rating` → 0).
2. Obtain the **minimum rating** from the **sum** of the encoded lengths
   (Table A below).
3. Scrub identical characters at the same offset from the **left** and
   from the **right** (Commons Codec procedure: comparisons use the
   original encodings; matches are blanked in working copies).
4. Let $r = 6 - L$ where $L$ is the length of the longer residual string
   after scrubbing. This is the **similarity rating**.
5. The names match if $r$ is greater than or equal to the Table-A minimum.

### Table A — minimum threshold

| Sum of encoded lengths | Minimum rating |
| --- | --- |
| ≤ 4 | 5 |
| 4 < sum ≤ 7 | 4 |
| 7 < sum ≤ 11 | 3 |
| = 12 | 2 |
| > 12 | 1 (unreachable for Max_Code_Len = 6; defensive) |

### Documented choices / ambiguities

- **Encode length policy:** return an unpadded uppercase alphabetic
  string of length $1..6$. When the intermediate encoding exceeds 6,
  join first 3 + last 3 (Wikipedia / Western Airlines).
- **Y as consonant:** kept; enables Smith/Smyth matching (unlike early
  NYSIIS).
- **Double consonants:** full adjacent-letter collapse after vowel
  removal (Wikipedia “remove the second consonant of any double
  consonants”).
- **Single-letter names:** encoded as that letter (Wikipedia-faithful).
  Commons Codec returns empty for length-1 inputs and treats them as
  non-matches before encoding — this package does not adopt that
  bulletproof shortcut.
- **Similarity scrub:** Commons Codec simultaneous L→R / R→L position
  matching on the original characters (verified against Byrne/Boern
  rating 5, Smith/Smyth rating 5, Catherine/Kathryn rating 4).
- **Non-letters:** digits, spaces, and punctuation are stripped
  (educational), matching sibling Soundex/NYSIIS packages.

### Classic examples

| Name | Codex |
| ---- | ----- |
| Byrne | BYRN |
| Boern | BRN |
| Smith | SMTH |
| Smyth | SMYTH |
| Catherine | CTHRN |
| Kathryn | KTHRYN |
| Lloyd | LYD |
| Aaron | ARN |
| Washington | WSHGTN |
| Macintosh | MCNTSH |
| Pfeiffer | PFR |

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(n)$ strip + vowel pass + collapse + $O(1)$ truncate; compare $O(1)$ on codes ≤ 6 |
| Auxiliary space | $O(n)$ working buffer ($\le\mathrm{Max\_Len}$) |
| Capacity | $n \le \mathrm{Max\_Len}=10000$; code $\le 6$ |

## Features

- **`Encode`** — MRA codex, unpadded length $1..6$.
- **`Compare`** — Boolean match under similarity rating + Table A.
- **`Similarity_Rating`** — exposes $6 - L$ (or 0 when length diff ≥ 3).
- **`Minimum_Rating`** — Table A lookup (documentation / tests).
- **Non-letters skipped** — digits, spaces, punctuation ignored.
- **Case-insensitive** — letters folded to upper case.
- **Y kept** — consonant for Smith/Smyth-style pairs.
- **Capacity / empty guard** — `Invalid_Argument` for empty, overlong,
  or letter-free input.
- **Arbitrary `String'First`** — slices work.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pmatch_rating_approach.gpr`.

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

=== 1. Wikipedia classic encode vectors ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 100.)

## Testing

The test suite in `tests.adb` covers:

- Wikipedia Byrne/Boern, Smith/Smyth, Catherine/Kathryn encode + rating
- Vowel deletion, leading-vowel keep, Y-as-consonant
- Adjacent double-consonant collapse and first3+last3 truncation
- Table A `Minimum_Rating` boundaries
- `Compare` true/false pairs, symmetry, length-diff ≥ 3 skip
- `Similarity_Rating` residuals and identical-codex rating 6
- Case folding and non-letter stripping
- Empty / letter-free / over-`Max_Len` → `Invalid_Argument`
- Non-1 `String'First` slices
- Length invariant ($1..6$) and alphabetic code checks
- Bulk single-letter alphabet and long inputs
- Punctuated names (O'Brien, Mary-Jane)

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Match_Rating_Approach is
   Max_Len      : constant Positive := 10_000;
   Max_Code_Len : constant Positive := 6;
   Invalid_Argument : exception;

   function Encode (Name : String) return String;
   --  Unpadded uppercase codex, length 1 .. Max_Code_Len.

   function Similarity_Rating (A, B : String) return Natural;
   --  6 - longer residual after LTR/RTL scrub; 0 if |len| diff >= 3.

   function Compare (A, B : String) return Boolean;
   --  True iff Similarity_Rating >= Minimum_Rating (sum of code lengths).

   function Minimum_Rating (Sum_Length : Natural) return Natural;
end Match_Rating_Approach;
```

Raises `Invalid_Argument` if an input is empty, longer than `Max_Len`,
or contains no A–Z letter.

## License

Educational reference implementation. See repository `LICENSE` if present.
