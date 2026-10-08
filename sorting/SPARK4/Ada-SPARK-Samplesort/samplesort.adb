--  Samplesort body — SPARK Level 4 Wikipedia samplesort with static
--  Work / Counts / Borders. Sampling / distribute / per-bucket
--  insertion prove only In_Bounds / RTE; the final gap-1 bubble finish
--  reuses Bubble_Pass / Sorted_Slice / Prefix_Leq_Suffix so Sort proves
--  Is_Sorted (same split as Flashsort / Comb_Sort / Odd_Even_Sort).

package body Samplesort
  with SPARK_Mode => On
is

   --  Static work vector: live slots are 1 .. N with N ≤ Max_N.
   subtype Work_Array is Element_Array (1 .. Max_N);

   subtype Bucket_Id is Positive range 1 .. Num_Buckets;
   type Count_Array is array (Bucket_Id) of Natural;

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

   --  One forward pass over A (1 .. Bound): bubble the maximum of that
   --  range to index Bound via adjacent swaps.
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

   --  Map Item to bucket 1 .. Num_Buckets given sorted pivots
   --  (length Num_Buckets - 1). Item <= Pivots(K) → bucket K;
   --  otherwise bucket Num_Buckets.
   function Find_Bucket
     (Item   : Integer;
      Pivots : Element_Array) return Bucket_Id
     with
       Global => null,
       Pre    =>
         Pivots'First = 1
         and then Pivots'Last = Num_Buckets - 1,
       Post   => True
   is
   begin
      for K in 1 .. Num_Buckets - 1 loop
         if Item <= Pivots (K) then
            return K;
         end if;
      end loop;
      return Num_Buckets;
   end Find_Bucket;

   --  Insertion-sort a contiguous slice of Work (Lo .. Hi).
   --  Only RTE (sortedness comes from Bubble_Finish).
   procedure Sort_Slice
     (Work : in out Work_Array; Lo, Hi : Index)
     with
       Global => null,
       Pre    =>
         Lo >= 1
         and then Hi <= Max_N
         and then (Hi < Lo or else Lo <= Hi),
       Post   => True
   is
      Key : Integer;
      P   : Index;
   begin
      if Hi <= Lo then
         return;
      end if;

      for X in Lo + 1 .. Hi loop
         pragma Loop_Invariant (Lo in 1 .. Max_N);
         pragma Loop_Invariant (Hi in Lo .. Max_N);

         Key := Work (X);
         P   := X;

         while P > Lo and then Key < Work (P - 1) loop
            pragma Loop_Invariant (P in Lo + 1 .. X);
            pragma Loop_Variant (Decreases => P);

            Work (P) := Work (P - 1);
            P        := P - 1;
         end loop;

         Work (P) := Key;
      end loop;
   end Sort_Slice;

   --  Educational samplesort: sample pivots, count, distribute into
   --  Work, per-bucket insertion, copy back. Only In_Bounds / RTE.
   procedure Samplesort_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A)
   is
      N       : constant Index := A'Last;
      Pivots  : Element_Array (1 .. Num_Buckets - 1);
      Stride  : Natural;
      Counts  : Count_Array := [others => 0];
      Starts  : Count_Array := [others => 1];
      Curr    : Natural;
      Work    : Work_Array := [others => 0];
      Indices : Count_Array;
      B       : Bucket_Id;
      Lo, Hi  : Natural;
      Sample  : Positive;
      Key     : Integer;
      P       : Index;
   begin
      --  Too few elements for Num_Buckets buckets: leave to Bubble_Finish.
      if N < Num_Buckets then
         return;
      end if;

      pragma Assert (N >= Num_Buckets);
      pragma Assert (N <= Max_N);

      Stride := N / Num_Buckets;
      pragma Assert (Stride >= 1);
      pragma Assert (Stride <= N);

      --  Equally spaced samples → Num_Buckets-1 pivots (deterministic).
      for I in 1 .. Num_Buckets - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant (Stride >= 1);
         pragma Loop_Invariant (Stride <= Max_N);

         Sample := I * Stride;
         if Sample > N then
            Sample := N;
         end if;
         pragma Assert (Sample in 1 .. N);
         Pivots (I) := A (Sample);
      end loop;

      --  Sort the small pivot vector (insertion; Num_Buckets-1 = 7).
      for X in 2 .. Num_Buckets - 1 loop

         Key := Pivots (X);
         P   := X;

         while P > 1 and then Key < Pivots (P - 1) loop
            pragma Loop_Invariant (P in 2 .. X);
            pragma Loop_Variant (Decreases => P);

            Pivots (P) := Pivots (P - 1);
            P          := P - 1;
         end loop;

         Pivots (P) := Key;
      end loop;

      --  Count bucket sizes.
      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant
           (for all K in Bucket_Id => Counts (K) <= I - 1);
         pragma Loop_Invariant
           (for all K in Bucket_Id => Counts (K) <= Max_N);

         B := Find_Bucket (A (I), Pivots);
         Counts (B) := Counts (B) + 1;
      end loop;

      pragma Assert (for all K in Bucket_Id => Counts (K) <= N);
      pragma Assert (for all K in Bucket_Id => Counts (K) <= Max_N);

      --  Prefix borders: Starts(B) is 1-based start index in Work.
      Curr := 1;
      for K in Bucket_Id loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Curr >= 1);
         pragma Loop_Invariant (Curr <= N + 1);
         pragma Loop_Invariant
           (for all KK in Bucket_Id => Counts (KK) <= Max_N);
         pragma Loop_Invariant
           (for all KK in Bucket_Id => Counts (KK) <= N);
         pragma Loop_Invariant
           (for all KK in 1 .. K - 1 => Starts (KK) >= 1);
         pragma Loop_Invariant
           (for all KK in 1 .. K - 1 => Starts (KK) <= N + 1);

         Starts (K) := Curr;
         if Counts (K) <= N + 1 - Curr then
            Curr := Curr + Counts (K);
         else
            Curr := N + 1;
         end if;
      end loop;

      pragma Assert (for all K in Bucket_Id => Starts (K) >= 1);
      pragma Assert (for all K in Bucket_Id => Starts (K) <= N + 1);

      Indices := Starts;

      --  Distribute into Work (out-of-place partition).
      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant
           (for all K in Bucket_Id => Counts (K) <= Max_N);
         pragma Loop_Invariant
           (for all K in Bucket_Id => Starts (K) >= 1);
         pragma Loop_Invariant
           (for all K in Bucket_Id => Starts (K) <= N + 1);
         pragma Loop_Invariant
           (for all K in Bucket_Id => Indices (K) >= 1);
         pragma Loop_Invariant
           (for all K in Bucket_Id => Indices (K) <= Max_N + 1);

         B := Find_Bucket (A (I), Pivots);
         if Indices (B) in 1 .. N then
            Work (Indices (B)) := A (I);
            if Indices (B) < Max_N + 1 then
               Indices (B) := Indices (B) + 1;
            end if;
         end if;
      end loop;

      --  Insertion-sort each non-empty bucket in Work.
      for K in Bucket_Id loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all KK in Bucket_Id => Counts (KK) <= Max_N);
         pragma Loop_Invariant
           (for all KK in Bucket_Id => Starts (KK) >= 1);
         pragma Loop_Invariant
           (for all KK in Bucket_Id => Starts (KK) <= N + 1);

         if Counts (K) > 0 and then Starts (K) <= N then
            Lo := Starts (K);
            if Counts (K) - 1 <= N - Starts (K) then
               Hi := Starts (K) + Counts (K) - 1;
            else
               Hi := N;
            end if;
            if Hi >= Lo and then Hi <= Max_N and then Lo <= Max_N then
               Sort_Slice (Work, Lo, Hi);
            end if;
         end if;
      end loop;

      --  Concatenate Work back into A.
      for Pos in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         A (Pos) := Work (Pos);
      end loop;
   end Samplesort_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Samplesort_Phase (A);

      --  Gap-1 bubble finish → Is_Sorted (Flashsort / Strand L4 pattern).
      Bubble_Finish (A);
   end Sort;

end Samplesort;
