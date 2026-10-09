# Ada-SPARK-Word-Break-II

Word Break II: `Sentences (S, N, D, DC, List, Count)` lists every way to split the text S (1 .. N), up to 12 letters, into words of the dictionary D (1 .. DC), up to 50 words of up to 12 letters (each word usable any number of times); each sentence is a break set (`Breaks (P)` = a word ends at P). `Count_Sentences` counts them. Method: a dynamic-programming table Ways (P) = number of splits of S (P .. N), then a depth-first walk that only enters suffixes and emits exactly Ways (P) sentences. The original 4-symbol `Segmentations` (single symbols and pairs of equal neighbours) is kept, now without its saturating add (its count is at most 2 ** 4, proved).

Proof (SPARK, `make prove`, cvc5 level 2, 150 checks): no run-time error; `Count_Sentences` is the DP table's first entry and the table is proved to satisfy Ways (P) = sum of Ways (P + L) over the word lengths L matching at P, with Ways (P) <= 2 ** (N + 1 - P); `Sentences` lists exactly `Count_Sentences` sentences (so List never overflows). Not in the Post (partial claim, `tools/vv/contract_scan.csv`): that each listed sentence is a valid split and that they are distinct; `own_checks.adb` checks it.

Tests: `tests.adb` (original) and `own_checks.adb` (brute force over all 2 ** (N - 1) splits; exhaustive texts of length 0 .. 6 on {a, b} with a 6-word dictionary, the all-a text of 12 letters with 12 words (2,048 sentences), 2,000 random cases on {a, b, c}; seed 20261009).

```sh
make test
make prove
```
