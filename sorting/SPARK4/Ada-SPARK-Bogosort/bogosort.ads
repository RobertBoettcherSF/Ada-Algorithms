--  Bogosort — Ada/SPARK Level 4 educational package for bogosort
--  ("stupid sort"): shuffle the array at random until it is sorted.
--  The shuffle is a uniform Fisher-Yates shuffle driven by a small
--  linear congruential generator whose state the caller owns (Seed), so
--  every run is reproducible. Extremely inefficient by design.
--
--  Bounded, with an explicit outcome. Plain bogosort has no upper bound
--  on its running time, so this port stops after at most Budget
--  shuffles and says which way it ended: Sorted, or Gave_Up with the
--  array still a permutation of the input. There is no deterministic
--  fallback: a Gave_Up result is returned as such.
--
--  The give-up cap (Max_Shuffles). For n distinct values exactly one of
--  the n! orders is sorted, so one ideal uniform shuffle sorts with
--  probability 1/n!, and K shuffles all miss with probability
--  (1 - 1/n!) ** K <= exp (-K / n!). Asking for P (Gave_Up) <= 1e-9 gives
--  K >= n! * ln (1e9) ~ 20.723 * n!. With duplicates more orders are
--  sorted, so the bound only gets better; smaller n likewise. For the
--  largest accepted n = Max_N = 8: K >= 40_320 * 20.7232658 = 835_562.08,
--  so Max_Shuffles = 835_563. Run-time budget: a full Gave_Up run at n = 8
--  is about 6.7 million swaps (tens of milliseconds). Max_N = 9 would need
--  K = 7_520_094 (about 68 million swaps), which is why Max_N stays 8.
--  The bound is for an ideal uniform shuffle; the generator below is a
--  32-bit LCG (high 16 bits, reduced mod the range), so it is an
--  approximation, not a guarantee.
--
--  Generator: Seed := Seed * 1_664_525 + 1_013_904_223 (mod 2 ** 32); a
--  draw in 0 .. Bound - 1 is (Seed / 2 ** 16) mod Bound. Shuffle: for
--  I from A'Last down to A'First + 1, swap A (I) with
--  A (A'First + Draw (I - A'First + 1)). Sort: while A is not sorted and
--  Shuffles < Budget, shuffle once.
--
--  Reference: https://en.wikipedia.org/wiki/Bogosort

package Bogosort
  with SPARK_Mode => On
is

   --  Hard bound on array length (see the cap derivation above).
   Max_N : constant Positive := 8;

   --  Give-up cap: ceil (Max_N! * ln (1e9)) = ceil (835_562.08).
   Max_Shuffles : constant := 835_563;

   subtype Shuffle_Count is Natural range 0 .. Max_Shuffles;

   subtype Index is Natural range 0 .. Max_N;

   type Element_Array is array (Positive range <>) of Integer;

   type Seed_Type is mod 2 ** 32;

   type Outcome is (Sorted, Gave_Up);

   function In_Bounds (A : Element_Array) return Boolean is
     (A'Length <= Max_N)
   with Global => null;
   --  Shape guard used by every entry point: a length bound, any origin.

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'Range => (if I < A'Last then A (I) <= A (I + 1)))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing (empty / singleton vacuous).

   --  Occurrences of V in A (A'First .. Last).
   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural
   with
     Global             => null,
     Pre                => In_Bounds (A) and then Last <= A'Last,
     Post               => Occ'Result <= Last,
     Subprogram_Variant => (Decreases => Last);

   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural is
     (if Last < A'First then 0
      else Occ (A, V, Last - 1) + (if A (Last) = V then 1 else 0));

   --  A and B hold the same values with the same counts.
   function Is_Perm (A, B : Element_Array) return Boolean is
     (A'First = B'First
      and then A'Last = B'Last
      and then (for all I in A'Range =>
                  Occ (A, A (I), A'Last) = Occ (B, A (I), B'Last))
      and then (for all I in B'Range =>
                  Occ (A, B (I), A'Last) = Occ (B, B (I), B'Last)))
   with
     Global => null,
     Pre    => In_Bounds (A) and then In_Bounds (B);

   procedure Sort
     (A        : in out Element_Array;
      Seed     : in out Seed_Type;
      Result   : out Outcome;
      Shuffles : out Natural;
      Budget   : Shuffle_Count := Max_Shuffles)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   =>
         In_Bounds (A)
         and then Is_Perm (A, A'Old)
         and then Shuffles <= Budget
         and then (case Result is
                     when Sorted  => Is_Sorted (A),
                     when Gave_Up => Shuffles = Budget
                                     and then not Is_Sorted (A));
   --  Shuffle A until it is sorted or Budget shuffles are spent.
   --  Sorted: A is sorted. Gave_Up: all Budget shuffles were used and A is
   --  not sorted. Both outcomes keep A a permutation of the input. An
   --  already sorted A takes 0 shuffles and leaves Seed unchanged.

end Bogosort;
