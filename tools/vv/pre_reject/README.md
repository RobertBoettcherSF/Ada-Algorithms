# Pre-rejection rates (tools/vv/pre_reject)

How often does a subprogram's precondition refuse inputs that a caller
could plausibly pass? For each folder with a `Pre`, a small driver here:

1. generates inputs, either the way the folder's tests generate them, or
   uniformly over the parameter types within the documented limits
   (`Max_N`, `Max_Len`, ...; an unconstrained array's origin is uniform over
   its index type, since no origin limit is documented);
2. evaluates a copy of the `Pre` as an expression function in the driver
   (the copy calls the package's own public helpers such as `In_Bounds`);
3. counts rejections over a fixed seeded sample (10,000 draws, SplitMix64,
   seed 20261009; `pre_rng.ads`).

`run.sh` builds and runs every driver with GNAT 14 (`-gnata -gnatwa`) and
prints `folder|subprogram|generator|sample|rejected`. The results, with
a one-line judgement, are in `tools/vv/pre_reject.csv`, and the rate is
copied into the `pre_reject_rate` column of `tools/vv/contract_scan.csv`
where that file has a row for the subprogram.

Judgements: *needed* (the Pre is the problem's domain, for example a
reduced residue or a non-empty stack), *documented limit only*, *input
contract of the problem* (for example a rotated sorted array, which random
arrays almost never are), or *too narrow* (the Pre refuses inputs the
algorithm could handle, for example `A'First = 1`).

First batch (agent A3, 2026-10-09): the 20 highest-ranked SPARK folders
with a Pre in `tools/vv/sweep_rank_calibrated.csv`.
