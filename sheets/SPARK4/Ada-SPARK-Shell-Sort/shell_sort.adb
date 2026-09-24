--  Shell_Sort body — SPARK Level 4 classic Shellsort with a fixed Ciura
--  gap prefix. Larger gaps only need RTE / In_Bounds; the final gap-1
--  insertion pass reuses the Insert_Step / Sorted_Slice argument from
--  Ada-SPARK-Insertion-Sort so Sort proves Is_Sorted.

package body Shell_Sort
  with SPARK_Mode => On
is

   --  Marcin Ciura gaps that fit Max_N = 64 (descending), ending with 1.
   --  Gaps > 1 are applied first; the final Insertion_Pass is gap 1.
   Gaps : constant array (Positive range <>) of Positive :=
     [57, 23, 10, 4, 1];

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

   --  Insert A(I) into the sorted prefix A(1 .. I-1), yielding sorted
   --  A(1 .. I). Gap-1 pass only (ordinary insertion sort step).
   procedure Insert_Step (A : in out Element_Array; I : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then I in 2 .. A'Last
         and then Sorted_Slice (A, 1, I - 1),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, 1, I)
         and then (for all K in I + 1 .. A'Last => A (K) = A'Old (K))
   is
      Key : constant Integer := A (I);
      J   : Index := I;
   begin
      while J > 1 and then Key < A (J - 1) loop
         pragma Loop_Invariant (J in 2 .. I);
         pragma Loop_Invariant (Sorted_Slice (A, 1, J - 1));
         pragma Loop_Invariant (Sorted_Slice (A, J + 1, I));
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (K) > Key);
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (J - 1) <= A (K));
         pragma Loop_Invariant
           (if J < I then A (J) = A (J + 1) else A (J) = Key);
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Decreases => J);

         A (J) := A (J - 1);
         J     := J - 1;
      end loop;

      pragma Assert (J in 1 .. I);
      pragma Assert (Sorted_Slice (A, 1, J - 1));
      pragma Assert (Sorted_Slice (A, J + 1, I));
      pragma Assert (for all K in J + 1 .. I => A (K) > Key);
      pragma Assert (J = 1 or else A (J - 1) <= Key);

      A (J) := Key;

      pragma Assert (if J > 1 then A (J - 1) <= A (J));
      pragma Assert (if J < I then A (J) <= A (J + 1));
      pragma Assert (Sorted_Slice (A, 1, I));
   end Insert_Step;

   --  Ordinary insertion sort (gap = 1). Proves Is_Sorted.
   procedure Insertion_Pass (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A) and then Is_Sorted (A)
   is
   begin
      pragma Assert (Sorted_Slice (A, 1, 1));

      for I in 2 .. A'Last loop
         Insert_Step (A, I);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, 1, I));
         pragma Loop_Invariant (Is_Sorted (A (1 .. I)));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last =>
              A (K) = A'Loop_Entry (K));
      end loop;
   end Insertion_Pass;

   --  h-sort for Gap > 1: insertion-sort each interleaved subsequence.
   --  Only In_Bounds / RTE are proved (sortedness comes from gap 1).
   procedure Gap_Pass (A : in out Element_Array; Gap : Positive)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Gap in 2 .. A'Last - 1,
       Post   => In_Bounds (A)
   is
      Key : Integer;
      J   : Index;
   begin
      for I in Gap + 1 .. A'Last loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I in Gap + 1 .. A'Last + 1);

         Key := A (I);
         J   := I;

         while J >= Gap + 1 and then A (J - Gap) > Key loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (J in Gap + 1 .. I);
            pragma Loop_Invariant (J <= A'Last);
            pragma Loop_Variant (Decreases => J);

            A (J) := A (J - Gap);
            J     := J - Gap;
         end loop;

         A (J) := Key;
      end loop;
   end Gap_Pass;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      --  Apply every table gap > 1 that is strictly less than n.
      for K in Gaps'Range loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (A'Length >= 2);

         declare
            G : constant Positive := Gaps (K);
         begin
            if G > 1 and then G < A'Length then
               Gap_Pass (A, G);
            end if;
         end;
      end loop;

      --  Final gap = 1: ordinary insertion sort → Is_Sorted.
      Insertion_Pass (A);
   end Sort;

end Shell_Sort;
