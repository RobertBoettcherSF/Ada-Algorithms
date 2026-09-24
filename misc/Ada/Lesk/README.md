# Lesk Algorithm — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Lesk algorithm](https://en.wikipedia.org/wiki/Lesk_algorithm):
classical **word-sense disambiguation (WSD)** introduced by **Michael E. Lesk**
(SIGDOC 1986) — *Automatic sense disambiguation using machine readable
dictionaries: how to tell a pine cone from an ice cream cone*.

The premise: words in a local neighborhood tend to share a topic. Choose the
dictionary **sense** whose **gloss** overlaps that neighborhood
(**Simplified Lesk**) or overlaps other words' glosses (**Original Lesk**).
This package uses a tiny **in-memory dictionary** only — **no WordNet**
dependency. The Wikipedia **pine / cone** fixture is built in.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Primary** | Simplified Lesk | Gloss $\leftrightarrow$ context tokens |
| **Optional** | Original Lesk-style | Gloss $\leftrightarrow$ context glosses |
| **Overlap** | Set intersection $|A\cap B|$ | Not multiset; ties → lowest index |
| **Normalize** | Lowercase alphabetic runs | Hyphens split tokens |
| **Stops** | Optional stopword list | Default English function words |
| **Fixture** | Pine / cone (Lesk 1986) | pine$\#1\cap$cone$\#3=2$ |
| **I/O** | In-memory `Dictionary_Entry` | No external corpus |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Tokens | `Token`, `Token_List`, `Tokenize`, `Unique_Tokens` | Lowercase content words |
| Stops | `Stopword_List`, `Default_Stopwords`, `Filter_Stopwords` | Optional function-word drop |
| Overlap | `Overlap`, `Overlap_Count`, `Near` | $|set(A)\cap set(B)|$ |
| Dict | `Sense`, `Dictionary_Entry`, `Make_Entry`, `Find_Entry` | Mini lexicon |
| Simplified | `Simplified_Lesk`, `Best_Sense_Index`, `Sense_Overlap` | Per-word WSD |
| Original | `Original_Lesk` | Tiny gloss–gloss variant |
| Demo | `Pine_Entry`, `Cone_Entry`, `Pine_Cone_Demo` | Wikipedia example |

Named exception: `Invalid_Argument` (oversize / empty token).
`SPARK_Mode => Off`; helpers carry `Global => null` where meaningful.

## Lesk 1986 and the pine cone

Lesk (1986) disambiguates by counting words shared between dictionary
definitions. The classic illustration uses:

**PINE**

1. kinds of evergreen tree with needle-shaped leaves
2. waste away through sorrow or illness

**CONE**

1. solid body which narrows to a point
2. something of this shape whether solid or hollow
3. fruit of certain evergreen trees

Raw token sets (no stopword filter) share `of` and `evergreen`:

$$
|\mathrm{gloss}(\mathrm{pine}_1)\cap\mathrm{gloss}(\mathrm{cone}_3)|=2.
$$

That is the Wikipedia identity $\mathrm{Pine}\#1\cap\mathrm{Cone}\#3=2$.
(`tree` vs `trees` do **not** match — this package does not stem.)

## Simplified vs original

### Simplified Lesk

For a target word $w$ with senses $s_1,\ldots,s_k$ and a sentence context
$C$ (tokens of the sentence, typically **excluding** $w$, optionally minus
stopwords):

$$
\mathrm{score}(s_i)=|\mathrm{set}(\mathrm{gloss}(s_i))\cap\mathrm{set}(C)|,
\qquad
\hat{s}=\arg\max_i\mathrm{score}(s_i).
$$

Ties break to the **lowest index** (first sense). If every score is $0$,
return sense $1$ (Vasilescu-style most-frequent / first-sense backoff).

Empirically, Simplified Lesk often beats the original on Senseval-style data
(Vasilescu et al., 2004: about $58\%$ vs $42\%$ in one reported setting) and
is far cheaper.

### Original Lesk-style (educational)

Score a target sense by summing, over each other dictionary headword in a
small context dictionary, the **best** gloss–gloss overlap with that
headword's senses. Intended only for toy dictionaries such as pine+cone.

## Overlap definition

`Overlap` / `Overlap_Count` use the **set** of distinct lowercase tokens
(first-occurrence unique), not a multiset: repeating a word does not raise
the score. Documented and tested (`evergreen evergreen` $\cap$
`evergreen tree` $=2$ unique matches from the left side's set size
contribution of one `evergreen`).

Tokenization: alphabetic runs only; case-folded; non-letters (including
hyphens) are separators (`needle-shaped` $\rightarrow$ `needle`, `shaped`).

## Limitations

Dictionary glosses are **short**, so overlap is brittle: missing a single
content word can flip the decision. The algorithm is sensitive to exact
wording and does not use thesauri, syntax, or embeddings. Extensions
(Adapted/Extended Lesk, WordNet-related glosses, Banerjee & Pedersen 2002)
are discussed on Wikipedia but **not** implemented here.

## Usage

```ada
with Lesk; use Lesk;

procedure Demo is
   PS, CS, GO : Natural;
begin
   pragma Assert (Overlap_Count (Pine_Gloss_1, Cone_Gloss_3) = 2);

   Pine_Cone_Demo (PS, CS, GO);
   pragma Assert (PS = 1 and CS = 3 and GO = 2);

   pragma Assert
     (Simplified_Lesk (Pine_Entry, Pine_Context_Sentence) = 1);
   pragma Assert
     (Simplified_Lesk (Cone_Entry, Cone_Context_Sentence) = 3);
end Demo;
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Plesk.gpr`. Main program is `tests.adb`
(no `main.adb`). Expect **Fail_Count = 0** and at least **100** `PASS` lines
(pine/cone fixture, stopwords, ties, case folding, synthetic vignettes,
overlap symmetry, original Lesk smoke).

## Layout

| File | Role |
| --- | --- |
| `lesk.ads` | Package spec |
| `lesk.adb` | Package body |
| `lesk.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions in checks) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

## References

- Lesk, M. *Automatic sense disambiguation using machine readable
  dictionaries: how to tell a pine cone from an ice cream cone*.
  SIGDOC '86, ACM, 1986, pp. 24–26.
- Kilgarriff, A. & Rosenzweig, J. *English SENSEVAL: Report and Results*.
  LREC 2000.
- Vasilescu, F., Langlais, P. & Lapalme, G. *Evaluating Variants of the Lesk
  Approach for Disambiguating Words*. LREC 2004.
- Banerjee, S. & Pedersen, T. *An Adapted Lesk Algorithm for Word Sense
  Disambiguation Using WordNet*. CICLing 2002 (related extension; not this
  package).
- Wikipedia: [Lesk algorithm](https://en.wikipedia.org/wiki/Lesk_algorithm).

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning and research.
