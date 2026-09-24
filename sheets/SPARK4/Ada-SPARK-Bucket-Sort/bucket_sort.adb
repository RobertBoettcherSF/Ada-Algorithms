--  Bucket_Sort body — SPARK Level 4 classic bucket sort. Scatter into
--  Max_Buckets uniform-width bins on a static flat store, insertion-
--  sort each bin, gather. Scatter / per-bucket insertion / gather
--  prove only In_Bounds / RTE; the final Insertion_Pass reuses the
--  Insert_Step / Sorted_Slice argument from Ada-SPARK-Insertion-Sort
--  (Shell gap-1 pattern) so Sort proves Is_Sorted.

package body Bucket_Sort
  with SPARK_Mode => On
is

   Flat_Last : constant Positive := Max_Buckets * Max_N;
   --  Static store: bucket B occupies Slot (B, 1 .. Max_N).

   type Flat_Store is array (Positive range 1 .. Flat_Last) of Element;

   --  1-based offset of item J in bucket B. J in 1 .. Max_N.
   function Slot (B : Bucket_Index; J : Positive) return Positive
   is (B * Max_N + J)
   with
     Global => null,
     Pre    => J in 1 .. Max_N,
     Post   => Slot'Result in 1 .. Flat_Last;

   --  Uniform-width bucket index over the closed key domain.
   function Bucket_Of (X : Element) return Bucket_Index
   is (X / Bucket_Width)
   with Global => null;

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
   --  A(1 .. I). Strict Key < A(J-1) keeps equal-key order (stable).
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
      Key : constant Element := A (I);
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

   --  Ordinary insertion sort. Proves Is_Sorted (Shell gap-1 pattern).
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

   --  Stable insertion sort of Store (Slot (B, 1) .. Slot (B, Cnt)).
   --  Only In_Bounds / RTE are proved (sortedness comes from Insertion_Pass).
   procedure Sort_Bucket
     (Store : in out Flat_Store;
      B     : Bucket_Index;
      Cnt   : Natural)
     with
       Global => null,
       Pre    => Cnt <= Max_N,
       Post   => True
   is
      Key : Element;
      J   : Natural;
   begin
      if Cnt <= 1 then
         return;
      end if;

      for I in 2 .. Cnt loop
         pragma Loop_Invariant (Cnt in 2 .. Max_N);
         pragma Loop_Invariant (I in 2 .. Cnt + 1);

         Key := Store (Slot (B, I));
         J   := I;

         while J > 1 and then Key < Store (Slot (B, J - 1)) loop
            pragma Loop_Invariant (J in 2 .. I);
            pragma Loop_Invariant (J <= Max_N);
            pragma Loop_Variant (Decreases => J);

            Store (Slot (B, J)) := Store (Slot (B, J - 1));
            J                   := J - 1;
         end loop;

         Store (Slot (B, J)) := Key;
      end loop;
   end Sort_Bucket;

   --  Scatter / per-bucket insertion / gather. RTE / In_Bounds only.
   procedure Bucket_Pass (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A)
   is
      N      : constant Index := A'Last;
      Store  : Flat_Store := [others => 0];
      Counts : Count_Array := [others => 0];
      B      : Bucket_Index;
      Pos    : Natural;
   begin
      --  Histogram + scatter into the flat store (left-to-right = stable).
      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant
           (for all K in Bucket_Index => Counts (K) <= I - 1);
         pragma Loop_Invariant
           (for all K in Bucket_Index => Counts (K) <= Max_N);

         B := Bucket_Of (A (I));
         Counts (B) := Counts (B) + 1;
         Store (Slot (B, Counts (B))) := A (I);
      end loop;

      pragma Assert (for all K in Bucket_Index => Counts (K) <= N);
      pragma Assert (for all K in Bucket_Index => Counts (K) <= Max_N);

      --  Insertion-sort each non-empty bucket in the flat store.
      for K in Bucket_Index loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all KK in Bucket_Index => Counts (KK) <= Max_N);

         if Counts (K) > 0 then
            Sort_Bucket (Store, K, Counts (K));
         end if;
      end loop;

      --  Gather buckets 0 .. Max_Buckets-1 back into A.
      --  The Pos <= N guard discharges the write index without a
      --  ghost cardinality lemma (sum of counts is n at run time).
      Pos := 1;
      for K in Bucket_Index loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Pos >= 1);
         pragma Loop_Invariant
           (for all KK in Bucket_Index => Counts (KK) <= Max_N);

         for J in 1 .. Counts (K) loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (Pos >= 1);
            pragma Loop_Invariant (J in 1 .. Counts (K) + 1);
            pragma Loop_Invariant (Counts (K) <= Max_N);

            if Pos in 1 .. N then
               A (Pos) := Store (Slot (K, J));
               Pos     := Pos + 1;
            end if;
         end loop;
      end loop;
   end Bucket_Pass;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Bucket_Pass (A);

      --  Final insertion pass → Is_Sorted (Shell gap-1 pattern).
      Insertion_Pass (A);
   end Sort;

end Bucket_Sort;
