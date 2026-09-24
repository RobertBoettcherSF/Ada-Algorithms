# Sukhotin's Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing **Sukhotin's algorithm**
(B. V. Sukhotin): an **unsupervised** method that classifies alphabetic characters
as **vowels** or **consonants** from letter co-occurrence structure alone.

The dedicated Wikipedia page historically redirected; the algorithm is listed on
Wikipedia's [List of algorithms](https://en.wikipedia.org/wiki/List_of_algorithms)
and [Outline of natural language processing](https://en.wikipedia.org/wiki/Outline_of_natural_language_processing)
as classifying characters as vowels or consonants.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Alphabet** | Lowercase $a$–$z$ ($N=26$) | Non-letters skipped / break words |
| **Matrix** | Symmetric adjacency $A$ | $A_{ij}=A_{ji}$; diagonal $0$ |
| **Score** | $S_i=\sum_j A_{ij}$ | Initial vocalic residual |
| **Update** | $S_k\leftarrow S_k-2A_{vk}$ | After selecting vowel $v$ |
| **Stop** | No remaining $S_i>0$ | Leftovers = consonants |
| **Ties** | Lowest letter index | Deterministic |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Adjacency_Matrix`, `Score_Vector`, `Classification` | Domain model |
| Alphabet | `Is_Alphabetic`, `To_Lower_Letter`, `Char_To_Index`, `Index_To_Char` | $a$–$z$ mapping |
| Matrix | `Build_Adjacency`, `Empty_Adjacency`, `Is_Symmetric`, `Adjacency_Get` | Co-occurrence |
| Scores | `Initial_Scores`, `Near`, `Score_Of`, `Score_Vector_Of` | Row sums / residuals |
| Run | `Run_Sukhotin`, `Classify_Text` | Core iteration |
| Query | `Is_Vowel`, `Is_Consonant`, `Vowel_Set`, `Consonant_Set`, `Vowel_Count` | Labels |

Strong typing uses domain subtypes (`Letter_Index`, `Letter_Char`, `Count_Value`,
`Score_Value`). Public subprograms carry `Pre` / `Global` where meaningful
(`SPARK_Mode => Off`).

Named exception: `Invalid_Argument`.

## Algorithm (classic Sukhotin)

### Idea

Vowels tend to **alternate** with consonants rather than cluster with other
vowels. Sukhotin turns that into a greedy partition of the alphabet that
maximizes vowel–consonant adjacency mass.

### Adjacency matrix

From a text, keep only letters (map to lowercase $a$–$z$). Non-letters break
adjacency (word boundaries). For every consecutive pair of **distinct** letters
$(x,y)$ inside a word, treat the contact as undirected:

$$
A_{xy} \leftarrow A_{xy}+1,\qquad A_{yx} \leftarrow A_{yx}+1.
$$

The diagonal is kept at zero ($A_{ii}=0$). The matrix is always symmetric:
$A_{ij}=A_{ji}$.

### Initial scores

$$
S_i = \sum_{j=1}^{N} A_{ij}.
$$

All letters start unmarked (treated as consonants).

### Iterative selection (exact update rule)

While there exists an unmarked letter with positive score:

1. Let $v$ be an unmarked letter maximizing $S_v$ among those with $S_v>0$
   (ties broken by lowest index / alphabetical order).
2. Mark $v$ as a **vowel**.
3. For every remaining unmarked letter $k$:

$$
S_k \leftarrow S_k - 2\,A_{vk}.
$$

Interpretation: $S_i$ tracks (contacts with current consonants) minus
(contacts with already chosen vowels). Selecting $v$ moves it from the
consonant pool to the vowel pool; subtracting $2A_{vk}$ restores that
invariant without rebuilding row sums (Guy / Language Log presentation of
Sukhotin; cf. also Goldwater–Griffiths–Johnson–Tenenbaum-style write-ups of
the $R$ matrix).

Stop when every remaining unmarked score satisfies $S_i\le 0$. Those letters
are **consonants**.

### Example intuition

On English-like text, high-degree alternating letters such as $a,e,i,o,u$
(and sometimes $y$) tend to be selected first; frequent consonant digrams
(e.g. `th`) can occasionally disturb the partition on short corpora.

## Usage

```ada
with Sukhotin; use Sukhotin;

procedure Demo is
   C : constant Classification :=
     Classify_Text ("The quick brown fox jumps over the lazy dog.");
begin
   -- Vowel_Set (C) typically includes a,e,i,o,u on English pangrams
   if Is_Vowel (C, 'e') then
      null;
   end if;
end Demo;
```

Or build the matrix yourself:

```ada
A : constant Adjacency_Matrix := Build_Adjacency (My_Corpus);
C : constant Classification   := Run_Sukhotin (A);
S : constant Score_Vector     := Initial_Scores (A);
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Psukhotin.gpr`. Main program is
`tests.adb` (no `main.adb`).

## Layout

| File | Role |
| --- | --- |
| `sukhotin.ads` | Package spec |
| `sukhotin.adb` | Package body |
| `sukhotin.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions in cases) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

## References

- Sukhotin, B. V. Original work on automatic vowel identification from
  co-occurrence (1960s computational linguistics tradition).
- Guy, J. B. M. expositions of Sukhotin's procedure (symmetric contact
  matrix, row sums, subtract $2\times$ co-occurrence on vowel promotion).
- Goldwater, S.; Griffiths, T.; Johnson, M.; et al. discussions of Sukhotin
  as a baseline phonological-category learner (matrix $R$, score as
  consonant-minus-vowel contact difference).
- Wikipedia: [List of algorithms](https://en.wikipedia.org/wiki/List_of_algorithms);
  [Outline of NLP](https://en.wikipedia.org/wiki/Outline_of_natural_language_processing)
  (dedicated “Sukhotin's algorithm” page historically redirected).

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning and research.
