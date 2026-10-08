--  Bucket_Sort body — SPARK Level 4 classic bucket sort. Scatter into
--  Max_Buckets uniform-width bins on a static flat store, insertion-sort
--  each bin, gather the bins in order. Proof: every key in bin B lies in
--  B * Bucket_Width .. B * Bucket_Width + Bucket_Width - 1, the insertion
--  sort keeps a bin's keys in that range and sorts them, and a ghost sum
--  of the bin counts equals n, so the gather writes all n positions and
--  each bin's keys are above every key of the bins before it. Nothing else
--  sorts the array.

package body Bucket_Sort
  with SPARK_Mode => On
is

   Flat_Last : constant Positive := Max_Buckets * Max_N;
   --  Static store: bucket B occupies Slot (B, 1 .. Max_N).

   type Flat_Store is array (Positive range 1 .. Flat_Last) of Element;

   subtype Bin_Count is Natural range 0 .. Max_Buckets;

   --  1-based offset of item J in bucket B.
   function Slot (B : Bucket_Index; J : Index) return Positive
   is (B * Max_N + J)
   with
     Global => null,
     Pre    => J >= 1,
     Post   => Slot'Result <= Flat_Last;

   --  Uniform-width bucket index over the closed key domain.
   function Bucket_Of (X : Element) return Bucket_Index
   is (X / Bucket_Width)
   with Global => null;

   --  Smallest and largest key of bucket B.
   function Low_Key (B : Bucket_Index) return Element
   is (B * Bucket_Width)
   with Global => null;

   function High_Key (B : Bucket_Index) return Element
   is (B * Bucket_Width + Bucket_Width - 1)
   with Global => null;

   ---------------------------------------------------------------------------
   -- Ghost model
   ---------------------------------------------------------------------------

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

   --  Every key of A in Lo .. Hi.
   function All_In (A : Element_Array; Lo, Hi : Element) return Boolean is
     (for all K in A'Range => A (K) in Lo .. Hi)
   with Ghost => True, Global => null;

   --  Counts (0) + .. + Counts (K - 1).
   function Sum (Counts : Count_Array; K : Bin_Count) return Natural is
     (if K = 0 then 0 else Sum (Counts, K - 1) + Counts (K - 1))
   with
     Ghost              => True,
     Global             => null,
     Subprogram_Variant => (Decreases => K),
     Pre                => (for all B in Bucket_Index => Counts (B) <= Max_N),
     Post               => Sum'Result <= K * Max_N;

   --  Adding one to Counts (B) adds one to the sums that include it.
   procedure Lemma_Sum_Inc (C1, C2 : Count_Array; B : Bucket_Index)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         (for all K in Bucket_Index => C1 (K) <= Max_N)
         and then (for all K in Bucket_Index => C2 (K) <= Max_N)
         and then C2 (B) = C1 (B) + 1
         and then (for all K in Bucket_Index =>
                     (if K /= B then C2 (K) = C1 (K))),
       Post   => Sum (C2, Max_Buckets) = Sum (C1, Max_Buckets) + 1
   is
   begin
      for K in Bin_Count range 1 .. Max_Buckets loop
         pragma Loop_Invariant
           (Sum (C2, K) = Sum (C1, K) + (if B < K then 1 else 0));
      end loop;
   end Lemma_Sum_Inc;

   --  Sums grow with K.
   procedure Lemma_Sum_Mono (C : Count_Array; K : Bin_Count)
     with
       Ghost  => True,
       Global => null,
       Pre    => (for all B in Bucket_Index => C (B) <= Max_N),
       Post   => Sum (C, K) <= Sum (C, Max_Buckets)
   is
   begin
      for J in Bin_Count range K .. Max_Buckets loop
         pragma Loop_Invariant (Sum (C, K) <= Sum (C, J));
      end loop;
   end Lemma_Sum_Mono;

   ---------------------------------------------------------------------------
   -- Insertion sort of one bucket
   ---------------------------------------------------------------------------

   --  Insert A(I) into the sorted prefix A(1 .. I-1), yielding sorted
   --  A(1 .. I). Strict Key < A(J-1) keeps equal-key order (stable). Keys
   --  only move, so a key range Lo .. Hi of A is kept.
   procedure Insert_Step
     (A : in out Element_Array; I : Index; Lo, Hi : Element)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then I in 2 .. A'Last
         and then Sorted_Slice (A, 1, I - 1)
         and then All_In (A, Lo, Hi),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, 1, I)
         and then All_In (A, Lo, Hi)
         and then (for all K in I + 1 .. A'Last => A (K) = A'Old (K))
   is
      Key : constant Element := A (I);
      J   : Index := I;
   begin
      while J > 1 and then Key < A (J - 1) loop
         pragma Loop_Invariant (J <= I);
         pragma Loop_Invariant (Sorted_Slice (A, 1, J - 1));
         pragma Loop_Invariant (Sorted_Slice (A, J + 1, I));
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (K) > Key);
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (J - 1) <= A (K));
         pragma Loop_Invariant
           (if J < I then A (J) = A (J + 1) else A (J) = Key);
         pragma Loop_Invariant (All_In (A, Lo, Hi));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Decreases => J);

         A (J) := A (J - 1);
         J     := J - 1;
      end loop;

      pragma Assert (J = 1 or else A (J - 1) <= Key);

      A (J) := Key;

      pragma Assert (if J > 1 then A (J - 1) <= A (J));
      pragma Assert (if J < I then A (J) <= A (J + 1));
      pragma Assert (Sorted_Slice (A, 1, I));
   end Insert_Step;

   --  Insertion sort of one bucket's keys, all in Lo .. Hi.
   procedure Sort_Bucket (A : in out Element_Array; Lo, Hi : Element)
     with
       Global => null,
       Pre    => In_Bounds (A) and then All_In (A, Lo, Hi),
       Post   =>
         In_Bounds (A)
         and then Is_Sorted (A)
         and then All_In (A, Lo, Hi)
   is
   begin
      for I in 2 .. A'Last loop
         Insert_Step (A, I, Lo, Hi);

         pragma Loop_Invariant (Sorted_Slice (A, 1, I));
         pragma Loop_Invariant (All_In (A, Lo, Hi));
      end loop;
   end Sort_Bucket;

   ---------------------------------------------------------------------------
   -- Bucket sort
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array) is
      N      : constant Index := A'Last;
      Store  : Flat_Store := [others => 0];
      Counts : Count_Array := [others => 0];
      B      : Bucket_Index;
      Pos    : Positive;
      Old    : Count_Array with Ghost;
   begin
      if N <= 1 then
         return;
      end if;

      --  Scatter: A (I) goes to the end of bucket Bucket_Of (A (I))
      --  (left to right, so equal keys keep their order).
      for I in 1 .. N loop
         pragma Loop_Invariant
           (for all K in Bucket_Index => Counts (K) <= I - 1);
         pragma Loop_Invariant (Sum (Counts, Max_Buckets) = I - 1);
         pragma Loop_Invariant
           (for all K in Bucket_Index =>
              (for all J in 1 .. Counts (K) =>
                 Store (Slot (K, J)) in Low_Key (K) .. High_Key (K)));

         B := Bucket_Of (A (I));
         Old := Counts;
         Counts (B) := Counts (B) + 1;
         Lemma_Sum_Inc (Old, Counts, B);
         Store (Slot (B, Counts (B))) := A (I);
      end loop;

      --  Sort each bucket (insertion sort) and append it to A.
      Pos := 1;
      for K in Bucket_Index loop
         pragma Loop_Invariant (Pos = Sum (Counts, K) + 1);
         pragma Loop_Invariant (Sorted_Slice (A, 1, Pos - 1));
         pragma Loop_Invariant (Pos = 1 or else A (Pos - 1) < Low_Key (K));

         Lemma_Sum_Mono (Counts, K + 1);
         pragma Assert (Pos - 1 + Counts (K) <= N);

         declare
            Cnt : constant Index := Counts (K);
            Bin : Element_Array (1 .. Cnt) :=
              [for J in 1 .. Cnt => Store (Slot (K, J))];
         begin
            pragma Assert (All_In (Bin, Low_Key (K), High_Key (K)));

            Sort_Bucket (Bin, Low_Key (K), High_Key (K));

            for J in 1 .. Cnt loop
               pragma Loop_Invariant (Pos = Sum (Counts, K) + J);
               pragma Loop_Invariant (Sorted_Slice (A, 1, Pos - 1));
               pragma Loop_Invariant
                 (if J > 1 then A (Pos - 1) = Bin (J - 1)
                  else Pos = 1 or else A (Pos - 1) < Low_Key (K));

               A (Pos) := Bin (J);
               Pos := Pos + 1;
            end loop;
         end;
      end loop;

      pragma Assert (Pos = N + 1);
      pragma Assert (Sorted_Slice (A, 1, N));
   end Sort;

end Bucket_Sort;
