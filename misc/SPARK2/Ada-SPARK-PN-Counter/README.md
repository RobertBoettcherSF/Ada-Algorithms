# Ada-SPARK-PN-Counter

Bounded educational sheet for a [PN-Counter](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type#PN-Counter) (Positive-Negative Counter) [CRDT](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type). Ada 2022 + SPARK.

A PN-Counter pairs two grow-only vectors $P$ (increments) and $N$ (decrements).  
$\mathrm{Value} = \sum_i P_i - \sum_i N_i$, and $\mathrm{Merge}$ is componentwise $\max$ on both vectors.

This sheet is an independent clean-room educational exercise from public CRDT literature; it is not derived from third-party Alire crates.

## Design choices

- Fixed `Max_Actors = 4` replica slots; per-actor ticks bounded by `Max_Ticks = 16`.
- Operations: `Empty`, `Increment`, `Decrement`, `Value`, `Merge`, plus `P_At` / `N_At` observers.
- No heap, no access types; `Pre` / `Post` / `Global` contracts; `SPARK_Mode => On`.

## Verification (measured)

Last successful local run (`source /home/box/deps/spark/env.sh && make prove`):

- GNATprove **Level 2**, prover `cvc5`, `--warnings=error`, `--checks-as-errors=on`
- **23 / 23** checks proved (0 unproved; flow + CVC5)
- `make test` clean under `-gnatwa` (zero warnings)

Educational sheet only — not a DO-178C / ISO / third-party compliance audit.

## Usage

```sh
source /home/box/deps/spark/env.sh
make test
make prove
```
