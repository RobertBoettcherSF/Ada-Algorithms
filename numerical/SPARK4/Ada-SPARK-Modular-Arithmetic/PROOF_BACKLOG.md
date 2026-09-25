# Proof backlog: Ada-SPARK-Modular-Arithmetic

Version 0.001. Proof runs are **paused** (policy of 2026-09-25, to save
compute). The last proof state, reached on 2026-09-25 around 10:46 CEST
before the pause, was **1629 / 1629 checks proved at `--level=4`**
(GNATprove 16.1, `make prove`). This total merges per-unit runs: the final
edits to CRT/Lemmas were reproved with `-u`, and the other units come from the
preceding full run. It has not been reconfirmed in one clean full run.

The generic `Ring` instance `Big_Ring` (N = 2**63-25) is **not analysed** by
GNATprove. The instantiation is outside SPARK_Mode, so it is reported as
skipped. The Z/97, Z/11 and Z/10 instances inside `Check_Digits` are
analysed. The ghost lemmas in `Modular_Arithmetic.Lemmas` are proof
infrastructure and are not listed.

Each entry is marked in the source by a comment directly above the
subprogram declaration:
`--  PROOF-LATER: Importance N/10, Urgency N/10, SPARKL`
(SPARKL = target GNATprove level SPARK1 .. SPARK4, or `Ada` if no proof is planned).

Sorted by importance, then urgency (both descending).

| File | Subprogram | Importance | Urgency | Target | Reason |
|------|-----------|-----------:|--------:|:------:|--------|
| modular_arithmetic-montgomery.ads | Redc | 10/10 | 4/10 | SPARK4 | core REDC step, overflow and exactness subtle; proved L4 |
| modular_arithmetic.ads | Inverse | 10/10 | 4/10 | SPARK4 | A*Inv = 1 mod N used by CRT and Montgomery; proved L4 |
| modular_arithmetic.ads | Mul_Mod | 10/10 | 4/10 | SPARK4 | 128-bit product, base of everything; proved L4, recheck in one clean run |
| modular_arithmetic-crt.ads | Crt_Array | 9/10 | 5/10 | SPARK4 | array CRT proved L4 but uniqueness for k > 2 moduli not yet proved |
| modular_arithmetic-crt.ads | Crt2 | 9/10 | 4/10 | SPARK4 | two-modulus CRT; proved L4, recheck in one clean run |
| modular_arithmetic-montgomery.ads | Make_Context | 9/10 | 4/10 | SPARK4 | N' and R^-1 constants; proved L4, recheck in one clean run |
| modular_arithmetic-montgomery.ads | Montgomery_Multiply | 9/10 | 4/10 | SPARK4 | proved L4; recheck in one clean run |
| modular_arithmetic-montgomery.ads | Multiply | 9/10 | 4/10 | SPARK4 | end-to-end = Mul_Mod; needed extra hints, recheck in one clean run |
| modular_arithmetic.ads | Extended_Gcd | 9/10 | 4/10 | SPARK4 | Bezout identity and bounds feed Inverse/CRT; proved L4 |
| modular_arithmetic.ads | Pow_Mod | 9/10 | 4/10 | SPARK4 | square-and-multiply vs Pow_Spec; proved L4, iterative form still unproved |
| modular_arithmetic-montgomery.ads | From_Montgomery | 8/10 | 3/10 | SPARK4 | needed extra hints; proved L4, recheck in one clean run |
| modular_arithmetic-montgomery.ads | To_Montgomery | 8/10 | 3/10 | SPARK4 | proved L4; recheck in one clean run |
| modular_arithmetic.ads | Add_Mod | 8/10 | 3/10 | SPARK4 | overflow-free add near 2**63; proved L4, recheck in one clean run |
| modular_arithmetic.ads | Sub_Mod | 8/10 | 3/10 | SPARK4 | wrap-around subtraction; proved L4, recheck in one clean run |
| modular_arithmetic-crt.ads | Lemma_Crt2_Unique | 7/10 | 3/10 | SPARK4 | uniqueness proved for two moduli only |
| modular_arithmetic.ads | Gcd | 7/10 | 2/10 | SPARK4 | proved via Extended_Gcd; recheck in one clean run |
| modular_arithmetic-check_digits.ads | Iban_Check_Digits | 6/10 | 4/10 | SPARK3 | only AoRTE proved; result not proved to make Iban_Valid true |
| modular_arithmetic-check_digits.ads | Iban_Valid | 6/10 | 4/10 | SPARK3 | only AoRTE proved; functional mod 97-10 spec is tested, not proved |
| modular_arithmetic-ring.ads | Inverse | 6/10 | 4/10 | SPARK3 | generic wrapper; Big_Ring instance not analysed |
| modular_arithmetic-ring.ads | Mul | 6/10 | 4/10 | SPARK3 | generic wrapper; Big_Ring instance not analysed |
| modular_arithmetic-ring.ads | Pow | 6/10 | 4/10 | SPARK3 | generic wrapper; Big_Ring instance not analysed |
| modular_arithmetic-montgomery.ads | Lemma_Odd_Coprime | 6/10 | 2/10 | SPARK4 | odd N coprime to 2**62 (62-step unrolled halving); proved L4 |
| modular_arithmetic.ads | Is_Unit | 6/10 | 2/10 | SPARK4 | proved via Gcd; recheck in one clean run |
| modular_arithmetic.ads | Neg_Mod | 6/10 | 2/10 | SPARK4 | proved L4; recheck in one clean run |
| modular_arithmetic-ring.ads | Add | 5/10 | 4/10 | SPARK3 | generic wrapper; Big_Ring instance not analysed |
| modular_arithmetic-ring.ads | Neg | 5/10 | 4/10 | SPARK3 | generic wrapper; Big_Ring instance not analysed |
| modular_arithmetic-ring.ads | Reduce | 5/10 | 4/10 | SPARK3 | generic wrapper; Big_Ring instance (2**63-25) not analysed by GNATprove |
| modular_arithmetic-ring.ads | Sub | 5/10 | 4/10 | SPARK3 | generic wrapper; Big_Ring instance not analysed |
| modular_arithmetic-check_digits.ads | Luhn_Check_Digit | 5/10 | 3/10 | SPARK3 | only AoRTE proved; round trip with Luhn_Valid tested |
| modular_arithmetic-check_digits.ads | Luhn_Valid | 5/10 | 3/10 | SPARK3 | only AoRTE proved; functional spec tested |
| modular_arithmetic.ads | Multiplicative_Order | 5/10 | 2/10 | SPARK3 | proved L4 against Pow_Spec; O(N) search only |
| modular_arithmetic.ads | Orbit_Length | 5/10 | 2/10 | SPARK3 | proved L4; Post does not yet state distinctness of the multiples |
| modular_arithmetic.ads | Reduce | 5/10 | 2/10 | SPARK4 | proved L4; recheck in one clean run |
| modular_arithmetic-check_digits.ads | Ean13_Check_Digit | 4/10 | 3/10 | SPARK3 | only AoRTE proved; round trip tested |
| modular_arithmetic-check_digits.ads | Ean13_Valid | 4/10 | 3/10 | SPARK3 | only AoRTE proved; functional spec tested |
| modular_arithmetic-check_digits.ads | Isbn10_Check_Digit | 4/10 | 3/10 | SPARK3 | only AoRTE proved; round trip tested |
| modular_arithmetic-check_digits.ads | Isbn10_Valid | 4/10 | 3/10 | SPARK3 | only AoRTE proved; functional spec tested |
| modular_arithmetic-ring.ads | Is_Unit | 4/10 | 3/10 | SPARK3 | generic wrapper; Big_Ring instance not analysed |
| modular_arithmetic-ring.ads | Orbit_Length | 4/10 | 3/10 | SPARK3 | generic wrapper; Big_Ring instance not analysed |
| modular_arithmetic-ring.ads | Order | 4/10 | 3/10 | SPARK3 | generic wrapper; Big_Ring instance not analysed |
| modular_arithmetic-crt.ads | Prefix_Product | 4/10 | 2/10 | SPARK3 | recursive spec helper; proved L4 |
| modular_arithmetic-check_digits.ads | Isbn13_Valid | 3/10 | 2/10 | Ada | prefix test plus Ean13_Valid; AoRTE proved, enough |
| modular_arithmetic-crt.ads | Pairwise_Coprime | 3/10 | 1/10 | Ada | spec helper, expression function |
| modular_arithmetic-crt.ads | Product_Fits | 3/10 | 1/10 | Ada | spec helper, expression function |
| modular_arithmetic-crt.ads | Sat_Mul | 3/10 | 1/10 | Ada | spec helper (saturating product), trivially safe |
| modular_arithmetic-montgomery.ads | Valid | 3/10 | 1/10 | Ada | predicate on the context record, expression function |
| modular_arithmetic-check_digits.ads | Is_Digit | 1/10 | 1/10 | Ada | character class, trivial |
| modular_arithmetic-check_digits.ads | Is_Upper | 1/10 | 1/10 | Ada | character class, trivial |
