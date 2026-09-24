# Levenshtein Distance in Ada/SPARK

## Project Overview
Bounded educational [Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance) (unit-cost Wagner–Fischer DP). Ada 2022 + SPARK. Companion: [Ada-Levenshtein-Distance](https://github.com/RobertBoettcherSF/Ada-Levenshtein-Distance).

$$
m,n \le \mathrm{Max\_Len}=16
$$

No exceptions — length bounds are `Pre`.

## Proof bar (Pareto)
Default `make prove` is Level 3. Use `make prove-l4` / `make prove-l2` to raise or lower the bar.

## Usage
`make` · `make test` · `make prove`

Shipped with `make test` green. Run `make prove` (Pareto L2+) when the prove queue is free.

