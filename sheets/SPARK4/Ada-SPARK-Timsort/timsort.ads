--  Timsort — Ada/SPARK Level 4 educational package for a hybrid stable
--  sort derived from merge sort and insertion sort (Tim Peters, 2002).
--  Finds natural runs inside Minrun-aligned windows, extends short ones
--  with insertion, then merges bottom-up via a fixed Temp buffer.
--
--  SPARK port of Ada-Timsort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses a full Timsort run stack, classic minrun in [32, 64],
--  arbitrary A'First, and raises on oversized n; this port requires
--  A'First = 1, uses fixed Minrun = 8 windows, a static Temp (1 .. Max_N),
--  and iterative bottom-up merging so Level 4 can discharge the VCs
--  without Timsort stack-invariant contracts. Full multiset /
--  permutation equality is verified by tests rather than claimed as a
--  Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Timsort

package Timsort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 100_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Classroom minimum run length. Full Timsort uses a power-of-two
   --  related minrun in [32, 64]; here a fixed Minrun keeps initial
   --  runs Width-aligned for bottom-up merge proofs at Level 4.
   Minrun : constant Positive := 8;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices are 1 .. N with N ≤ Max_N. Empty arrays use Last = 0.
   subtype Index is Natural range 0 .. Max_N;

   type Element_Array is array (Positive range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point. Empty arrays have
   --  A'Last = 0 when A'First = 1 (rejects Last < 0).

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (educational Timsort hybrid / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Allocate Temp : Element_Array (1 .. Max_N).
   --  1. Make initial runs: for each Minrun-aligned window
   --     Lo = 1, 1+Minrun, … with Hi = min (Lo+Minrun-1, N):
   --       • detect a natural nondecreasing or strictly descending run
   --         starting at Lo (bounded by Hi);
   --       • reverse a strictly descending run in place;
   --       • insertion-extend the sorted prefix through Hi.
   --     After this phase Sorted_Runs (A, Minrun) holds (or Is_Sorted
   --     when N ≤ Minrun).
   --  2. Bottom-up merge: Width := Minrun; while Width < N, stably merge
   --     adjacent Width-runs into 2·Width-runs via Temp (prefer Left when
   --     Left ≤ Right), then Width := 2·Width.
   --  Empty and singleton arrays are no-ops.
   --  Skipped vs full / sibling Timsort: galloping, classic stack
   --  invariants (X/Y/Z), power-of-two minrun in [32, 64], Powersort.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending educational Timsort hybrid (stable).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Timsort;
