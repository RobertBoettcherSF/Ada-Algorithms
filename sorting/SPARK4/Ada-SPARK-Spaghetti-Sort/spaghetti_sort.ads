--  Spaghetti_Sort — Ada/SPARK Level 4 educational package for A. K.
--  Dewdney's analog "spaghetti sort" (Scientific American), simulated
--  via height-bin counting on a bounded Integer array. Software cost
--  is O(n + U) with U = Max_Key + 1, not the analog O(n).
--
--  SPARK port of Ada-Spaghetti-Sort: hard Max_N / Max_Key bounds, static
--  Counts (0 .. Max_Key), no exceptions, In_Bounds / Keys_Ok / Is_Sorted
--  contracts replace Invalid_Argument. Non-SPARK sibling uses
--  Max_Length = Max_Key = 10_000, raises on oversize / out-of-range
--  keys, and also exports Sort_Extraction for general Integers; this
--  port takes any A'First in 1 .. Max_N, Pre =>
--  In_Bounds (A) and then Keys_Ok (A), exports only the height-bin
--  Sort, and proves that the height-bin phase itself sorts (no fallback
--  pass: the bins are shown to hold exactly N rods).
--  Full multiset / permutation equality is verified by tests rather
--  than claimed as a Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Spaghetti_sort

package Spaghetti_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity / key-domain bounds (classroom; static height-bin table)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_Length = 10_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Inclusive upper bound on nonnegative Integer keys. Count table is
   --  array (0 .. Max_Key) — size 65. Sibling uses Max_Key = 10_000.
   Max_Key : constant Natural := 64;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices lie in 1 .. Max_N (any A'First); Index includes 0 so
   --  an empty array may have Last = First - 1 = 0.
   subtype Index is Natural range 0 .. Max_N;

   --  Educational keys live in 0 .. Max_Key (rod lengths). Element type
   --  stays Integer so the API matches the non-SPARK sibling; Keys_Ok
   --  enforces the height-bin domain at the contract boundary.
   --  Live slots; the index subtype carries the 1 .. Max_N origin range,
   --  In_Bounds adds the length.
   subtype Live_Index is Positive range 1 .. Max_N;

   type Element_Array is array (Live_Index range <>) of Integer;

   subtype Count_Index is Natural range 0 .. Max_Key;
   type Count_Array is array (Count_Index) of Natural;

   ---------------------------------------------------------------------------
   -- Shape / key-domain / sortedness guards
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'Length <= Max_N
      and then A'First in 1 .. Max_N
      and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point: at most Max_N elements, any
   --  origin with First in 1 .. Max_N (empty arrays use Last = First - 1).

   function Keys_Ok (A : Element_Array) return Boolean is
     (for all I in A'Range => A (I) in 0 .. Max_Key)
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff every live element is a valid rod length in 0 .. Max_Key.

   function Is_Sorted (A : Element_Array) return Boolean is
     (A'Length <= 1
      or else (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1)))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Dewdney height-bin, proved without a finishing pass)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A) and Keys_Ok (A).
   --  1. Static Counts (0 .. Max_Key) := 0 (one bin per rod height).
   --  2. Tally: for each A (I), Counts (A (I)) += 1 (prepare the rods).
   --  3. Emit ascending: for H in 0 .. Max_Key, write Counts (H) copies
   --     of H into A left-to-right (short rods → tall rods). Analog
   --     spaghetti extracts tallest-first / descending; we emit
   --     ascending so Sort matches the documented API contract.
   --  4. Proof: ghost Sum_Below (Counts, H) = rods in bins below H; the
   --     tally keeps Sum_Below (Counts, Max_Key + 1) = rods seen, so the
   --     emit cursor ends at N + 1, and each emitted rod is >= the rods
   --     before it, which gives Is_Sorted without any finishing pass.
   --  Empty and singleton arrays are no-ops.
   --  Software cost O(n + U), U = Max_Key + 1 — not the analog O(n).
   --  The non-SPARK sibling also has Sort_Extraction (O(n²) max-pull for
   --  general Integers); that variant is omitted here for L4 simplicity.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   --  How many of A (A'First .. Last) equal V.
   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural
   with
     Global             => null,
     Pre                => In_Bounds (A) and then Last <= A'Last,
     Post               => (if Last < A'First then Occ'Result = 0
                            else Occ'Result <= Last - A'First + 1),
     Subprogram_Variant => (Decreases => Last);

   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural is
     (if Last < A'First then 0
      else Occ (A, V, Last - 1) + (if A (Last) = V then 1 else 0));

   --  A and B have the same bounds and hold the same values, each equally
   --  often (a value in neither counts 0 in both).
   function Is_Perm (A, B : Element_Array) return Boolean is
     (A'First = B'First
      and then A'Last = B'Last
      and then (for all I in A'Range => Occ (A, A (I), A'Last) = Occ (B, A (I), B'Last))
      and then (for all I in B'Range => Occ (A, B (I), A'Last) = Occ (B, B (I), B'Last)))
   with
     Global => null,
     Pre    => In_Bounds (A) and then In_Bounds (B);

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then Keys_Ok (A),
       Post   => In_Bounds (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old);
   --  Ascending educational height-bin spaghetti sort (no finishing pass).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Spaghetti_Sort;
