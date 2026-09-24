--  Quantum_Sort — Ada/SPARK Level 4 educational package of classical
--  stand-ins for quantum-sorting notions on an Integer array. Four
--  Sort_* entry points model comparison, parallel-network, frequency /
--  distribution, and space-bounded ideas with ordinary classical sorts
--  (insertion, Shell, selection, cocktail shaker). This is NOT a quantum
--  simulator and does not claim asymptotic quantum advantage.
--
--  SPARK port of Ada-Quantum-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Input_Size /
--  Element_Value range. Non-SPARK sibling allows a modest Element_Value
--  subtype and raises on invalid size; this port requires A'First = 1,
--  uses Pre => In_Bounds (A), Integer elements, and proves sortedness
--  via each educational algorithm plus a gap-1 finish where Level 4
--  needs it (Insertion_Pass for the Shell model; Bubble_Finish for the
--  cocktail model — same proof split as Ada-SPARK-Shell-Sort /
--  Ada-SPARK-Cocktail-Shaker-Sort). Full multiset / permutation
--  equality is verified by tests rather than claimed as a Level-4
--  postcondition (sortedness is proved).
--
--  References:
--    https://en.wikipedia.org/wiki/Quantum_sort
--    https://en.wikipedia.org/wiki/Insertion_sort
--    https://en.wikipedia.org/wiki/Shellsort
--    https://en.wikipedia.org/wiki/Selection_sort
--    https://en.wikipedia.org/wiki/Cocktail_shaker_sort

package Quantum_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

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
   -- Algorithm sketches (classical educational models / Wikipedia)
   ---------------------------------------------------------------------------
   --  Comparison → Insertion: grow a sorted prefix; insert each key with
   --    strict `>` shifts (stable). Proves Is_Sorted via Insert_Step.
   --  Parallel Network → Shell: fixed Ciura gaps (57,23,10,4,1) that fit
   --    Max_N; Gap_Pass for h > 1, Insertion_Pass for h = 1 → Is_Sorted.
   --  Frequency → Selection: place min of suffix at each prefix index.
   --    Proves Is_Sorted via Select_Min_Step + partition.
   --  Space-Bounded → Cocktail: capped Lo..Hi forward+backward rounds
   --    (In_Bounds / RTE only) + Bubble_Finish → Is_Sorted.
   --  Empty and singleton arrays are no-ops for every Sort_*.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting (four classical educational models)
   ---------------------------------------------------------------------------

   procedure Sort_Comparison (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Quantum comparison-sort model via classic stable insertion sort.
   --  Post proves sortedness; permutation checked by tests.

   procedure Sort_Parallel_Network (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Quantum parallel-network model via Shellsort (fixed Ciura gaps +
   --  gap-1 insertion finish). Unstable in general.

   procedure Sort_Frequency (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Quantum frequency / distribution model via selection sort.
   --  Not stable under the swap formulation.

   procedure Sort_Space_Bounded (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Space-bounded quantum-sort model via cocktail shaker + gap-1
   --  bubble finish. Stable when the swap predicate is strict `>`.

end Quantum_Sort;
