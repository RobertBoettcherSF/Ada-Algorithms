--  Bitonic_Sorter body — SPARK Level 4 Batcher bitonic network.
--  Bitonic_Sort / Bitonic_Merge / Compare_Swap prove only In_Bounds / RTE
--  with Subprogram_Variant (Decreases => Count). Sort pads a static Work
--  buffer, runs the network, copies back, then Bubble_Finish reuses
--  Bubble_Pass / Sorted_Slice / Prefix_Leq_Suffix so Is_Sorted proves
--  (same split as Comb / Odd_Even / Strand / Stooge). No Intentional Annotate.

package body Bitonic_Sorter
  with SPARK_Mode => On
is

   --  Adjacent nondecreasing on A (L .. R). Vacuous when L >= R.
   function Sorted_Slice
     (A : Element_Array; L, R : Natural) return Boolean
   is
     (L >= R
      or else (for all K in L .. R - 1 => A (K) <= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Last;

   --  Every element of A (Lo_P .. Hi_P) is <= every element of A (Lo_S .. Hi_S).
   function Prefix_Leq_Suffix
     (A                      : Element_Array;
      Lo_P, Hi_P, Lo_S, Hi_S : Natural) return Boolean
   is
     (Hi_P < Lo_P
      or else Hi_S < Lo_S
      or else
        (for all K in Lo_P .. Hi_P =>
           (for all L in Lo_S .. Hi_S => A (K) <= A (L))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Lo_P >= 1
       and then Hi_P <= A'Last
       and then Lo_S >= 1
       and then Hi_S <= A'Last;

   --  Classroom power-of-two set for Max_N = 64.
   function Is_Power_Of_Two (N : Natural) return Boolean is
     (N = 1 or else N = 2 or else N = 4 or else N = 8
      or else N = 16 or else N = 32 or else N = 64)
   with
     Global => null;

   function Next_Power_Of_Two (N : Natural) return Natural
   with
     Global => null,
     Pre    => N in 1 .. Max_N,
     Post   =>
       Next_Power_Of_Two'Result in N .. Max_N
       and then Is_Power_Of_Two (Next_Power_Of_Two'Result)
   is
      P : Natural := 1;
   begin
      while P < N loop
         pragma Loop_Invariant (P >= 1);
         pragma Loop_Invariant (P <= Max_N);
         pragma Loop_Invariant (Is_Power_Of_Two (P));
         pragma Loop_Invariant (P < N);
         pragma Loop_Invariant (P <= Max_N / 2);
         pragma Loop_Variant (Increases => P);

         pragma Assert (P <= Max_N / 2);
         P := P * 2;
         pragma Assert (Is_Power_Of_Two (P));
      end loop;
      return P;
   end Next_Power_Of_Two;

   procedure Swap (A : in out Element_Array; X, Y : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then X in 1 .. A'Last
         and then Y in 1 .. A'Last,
       Post   =>
         In_Bounds (A)
         and then A (X) = A'Old (Y)
         and then A (Y) = A'Old (X)
         and then
           (for all K in 1 .. A'Last =>
              (if K /= X and then K /= Y then A (K) = A'Old (K)))
   is
      T : Integer;
   begin
      if X = Y then
         return;
      end if;
      T     := A (X);
      A (X) := A (Y);
      A (Y) := T;
   end Swap;

   --  One sorting-network wire (trusted indices). Ascending: ensure
   --  A(I) ≤ A(J); descending: ensure A(I) ≥ A(J). Only In_Bounds / RTE.
   procedure Compare_Swap
     (A         : in out Element_Array;
      I, J      : Index;
      Ascending : Boolean)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then I in 1 .. A'Last
         and then J in 1 .. A'Last,
       Post   => In_Bounds (A)
   is
   begin
      if Ascending then
         if A (I) > A (J) then
            Swap (A, I, J);
         end if;
      else
         if A (I) < A (J) then
            Swap (A, I, J);
         end if;
      end if;
   end Compare_Swap;

   --  Bitonic merge on A (Low .. Low+Count-1). Count is a power of two
   --  (or ≤ 1). Variant Count halves on each recursive call.
   procedure Bitonic_Merge
     (A         : in out Element_Array;
      Low       : Index;
      Count     : Natural;
      Ascending : Boolean)
     with
       Global             => null,
       Always_Terminates  => True,
       Subprogram_Variant => (Decreases => Count),
       Pre                =>
         In_Bounds (A)
         and then Count <= Max_N
         and then
           (Count <= 1
            or else
              (Low in 1 .. A'Last
               and then Low - 1 <= A'Last - Count
               and then Is_Power_Of_Two (Count))),
       Post               => In_Bounds (A)
   is
      K : Natural;
   begin
      if Count <= 1 then
         return;
      end if;

      K := Count / 2;
      pragma Assert (K >= 1);
      pragma Assert (Is_Power_Of_Two (K));
      pragma Assert (K < Count);
      pragma Assert (Low + Count - 1 <= A'Last);
      pragma Assert (Low + K - 1 <= A'Last);
      pragma Assert (Low + K in 1 .. A'Last);

      for I in Low .. Low + K - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I in Low .. Low + K);
         pragma Loop_Invariant (K = Count / 2);
         pragma Loop_Invariant (Low + Count - 1 <= A'Last);
         pragma Loop_Invariant (I + K <= Low + Count - 1);
         pragma Loop_Invariant (I in 1 .. A'Last);
         pragma Loop_Invariant (I + K in 1 .. A'Last);

         Compare_Swap (A, I, I + K, Ascending);
      end loop;

      Bitonic_Merge (A, Low, K, Ascending);
      Bitonic_Merge (A, Low + K, K, Ascending);
   end Bitonic_Merge;

   --  Bitonic sort on A (Low .. Low+Count-1). Produces a monotone
   --  sequence in direction Ascending. Variant Count halves.
   procedure Bitonic_Sort
     (A         : in out Element_Array;
      Low       : Index;
      Count     : Natural;
      Ascending : Boolean)
     with
       Global             => null,
       Always_Terminates  => True,
       Subprogram_Variant => (Decreases => Count),
       Pre                =>
         In_Bounds (A)
         and then Count <= Max_N
         and then
           (Count <= 1
            or else
              (Low in 1 .. A'Last
               and then Low - 1 <= A'Last - Count
               and then Is_Power_Of_Two (Count))),
       Post               => In_Bounds (A)
   is
      K : Natural;
   begin
      if Count <= 1 then
         return;
      end if;

      K := Count / 2;
      pragma Assert (K >= 1);
      pragma Assert (Is_Power_Of_Two (K));
      pragma Assert (K < Count);
      pragma Assert (Low + Count - 1 <= A'Last);
      pragma Assert (Low + K in 1 .. A'Last);

      --  First half ascending, second half descending → bitonic sequence.
      Bitonic_Sort (A, Low, K, True);
      Bitonic_Sort (A, Low + K, K, False);
      Bitonic_Merge (A, Low, Count, Ascending);
   end Bitonic_Sort;

   --  One forward pass over A (1 .. Bound): bubble the maximum of that
   --  range to index Bound via adjacent swaps. Preserves the already-
   --  sorted / partitioned suffix Bound+1 .. A'Last.
   procedure Bubble_Pass
     (A       : in out Element_Array;
      Bound   : Index;
      Swapped : out Boolean)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then Bound in 2 .. A'Last
         and then Sorted_Slice (A, Bound + 1, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Bound, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Bound - 1, Bound, A'Last)
         and then
           (if not Swapped then Sorted_Slice (A, 1, Bound))
   is
   begin
      Swapped := False;

      for I in 1 .. Bound - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all K in 1 .. I => A (K) <= A (I));
         pragma Loop_Invariant (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (if not Swapped then Sorted_Slice (A, 1, I));

         if A (I) > A (I + 1) then
            Swap (A, I, I + 1);
            Swapped := True;
         end if;

         pragma Assert (for all K in 1 .. I + 1 => A (K) <= A (I + 1));
         pragma Assert (if not Swapped then Sorted_Slice (A, 1, I + 1));
      end loop;

      pragma Assert (for all K in 1 .. Bound => A (K) <= A (Bound));
      pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
      pragma Assert (Bound = A'Last or else A (Bound) <= A (Bound + 1));
      pragma Assert (Sorted_Slice (A, Bound, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Bound - 1, Bound, A'Last));
      pragma Assert (if not Swapped then Sorted_Slice (A, 1, Bound));
   end Bubble_Pass;

   --  Final gap = 1: ordinary bubble sort with early exit. Proves Is_Sorted.
   procedure Bubble_Finish (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A) and then Is_Sorted (A)
   is
      Bound   : Index;
      Swapped : Boolean;
   begin
      Bound := A'Last;

      pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));

      loop
         pragma Loop_Invariant (Bound in 2 .. A'Last);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
         pragma Loop_Variant (Decreases => Bound);

         Bubble_Pass (A, Bound, Swapped);

         pragma Assert (Sorted_Slice (A, Bound, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, 1, Bound - 1, Bound, A'Last));

         if not Swapped then
            pragma Assert (Sorted_Slice (A, 1, Bound));
            pragma Assert (Sorted_Slice (A, Bound, A'Last));
            pragma Assert (Is_Sorted (A));
            return;
         end if;

         exit when Bound = 2;

         Bound := Bound - 1;

         pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
      end loop;

      pragma Assert (Bound = 2);
      pragma Assert (Sorted_Slice (A, 2, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, 1, 2, A'Last));
      pragma Assert (Is_Sorted (A));
   end Bubble_Finish;

   --  Pad → bitonic network on Work → copy-back. Only In_Bounds / RTE.
   procedure Bitonic_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A)
   is
      N    : constant Index := A'Last;
      P    : Natural;
      Work : Element_Array (1 .. Max_N) := [others => 0];
   begin
      P := Next_Power_Of_Two (N);
      pragma Assert (P >= N);
      pragma Assert (P <= Max_N);
      pragma Assert (Is_Power_Of_Two (P));
      pragma Assert (In_Bounds (Work));

      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (In_Bounds (Work));
         pragma Loop_Invariant
           (for all T in 1 .. I - 1 => Work (T) = A (T));

         Work (I) := A (I);
      end loop;

      --  Ascending sentinels: Integer'Last sorts to the high end and is
      --  discarded when trimming back to length N. Equal to live
      --  Integer'Last data is fine (multiset of first N after a full
      --  ascending sort of data+pad equals the original multiset).
      for I in N + 1 .. P loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (In_Bounds (Work));
         pragma Loop_Invariant (I in N + 1 .. P + 1);
         pragma Loop_Invariant
           (for all T in 1 .. N => Work (T) = A (T));
         pragma Loop_Invariant
           (for all T in N + 1 .. I - 1 => Work (T) = Integer'Last);

         Work (I) := Integer'Last;
      end loop;

      Bitonic_Sort (Work, 1, P, True);

      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (In_Bounds (Work));

         A (I) := Work (I);
      end loop;
   end Bitonic_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Bitonic_Phase (A);

      --  Gap-1 bubble finish → Is_Sorted (same role as Comb / Odd_Even).
      --  On a correctly network-sorted prefix this is an O(n) clean pass.
      Bubble_Finish (A);
   end Sort;

end Bitonic_Sorter;
