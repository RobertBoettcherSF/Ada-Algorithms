--  Samplesort body.  Equally spaced samples give Num_Buckets - 1 pivots,
--  which are sorted.  The buckets are then cut out of the array in place,
--  one pivot at a time: a partition of the not yet placed suffix
--  A (Lo .. A'Length) moves the elements <= the pivot to its front, and
--  that bucket is insertion-sorted where it lies.  The last bucket (all
--  elements above the largest pivot) is sorted the same way.  With fewer
--  than Num_Buckets elements there are no pivots and the whole array is
--  that single bucket.
--
--  Proof: one invariant carries the sort across buckets.  A (1 .. Lo - 1)
--  is sorted, Floor is its last element (Integer'First while it is
--  empty), and every element of A (Lo .. A'Length) is >= Floor.  A bucket
--  holds values in Floor .. Pivot and the rest stays > Pivot, so the
--  sorted bucket extends the sorted prefix.

package body Samplesort
  with SPARK_Mode => On
is

   --  Any origin: the internals count positions 1 .. A'Length, and
   --  position K is A (A'First + (K - 1)).  The comments below speak of
   --  positions.

   --  Positions one past the end are needed for empty slices.
   subtype Pos is Positive range 1 .. Max_N + 1;

   --  Adjacent nondecreasing on A (L .. R). Vacuous when L >= R.
   function Sorted_Slice
     (A : Element_Array; L, R : Natural) return Boolean
   is
     (L >= R
      or else (for all K in L .. R - 1 => A (A'First + (K - 1)) <= A (A'First + (K + 1 - 1))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Length;

   --  Every element of A (L .. R) lies in Low .. High.
   function All_In
     (A : Element_Array; L, R : Natural; Low, High : Integer) return Boolean
   is
     (for all K in L .. R => A (A'First + (K - 1)) in Low .. High)
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Length;

   procedure Swap (A : in out Element_Array; X, Y : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then X in 1 .. A'Length
         and then Y in 1 .. A'Length,
       Post   =>
         In_Bounds (A)
         and then A (A'First + (X - 1)) = A'Old (A'First + (Y - 1))
         and then A (A'First + (Y - 1)) = A'Old (A'First + (X - 1))
         and then
           (for all K in 1 .. A'Length =>
              (if K /= X and then K /= Y then A (A'First + (K - 1)) = A'Old (A'First + (K - 1))))
   is
      T : Integer;
   begin
      if X = Y then
         return;
      end if;
      T     := A (A'First + (X - 1));
      A (A'First + (X - 1)) := A (A'First + (Y - 1));
      A (A'First + (Y - 1)) := T;
   end Swap;

   --  Insert A (A'First + (I - 1)) into the sorted A (Lo .. I - 1).  Values only move
   --  inside Lo .. I, so bounds that hold there keep holding.
   procedure Insert_Step
     (A         : in out Element_Array;
      Lo, I     : Index;
      Low, High : Integer)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Lo >= 1
         and then I in Lo + 1 .. A'Length
         and then Sorted_Slice (A, Lo, I - 1)
         and then All_In (A, Lo, I, Low, High),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, I)
         and then All_In (A, Lo, I, Low, High)
         and then
           (for all K in 1 .. A'Length =>
              (if K < Lo or else K > I then A (A'First + (K - 1)) = A'Old (A'First + (K - 1))))
   is
      Key : constant Integer := A (A'First + (I - 1));
      J   : Index := I;
   begin
      while J > Lo and then Key < A (A'First + (J - 1 - 1)) loop
         pragma Loop_Invariant (J in Lo + 1 .. I);
         pragma Loop_Invariant (Key in Low .. High);
         pragma Loop_Invariant (Sorted_Slice (A, Lo, J - 1));
         pragma Loop_Invariant (Sorted_Slice (A, J + 1, I));
         pragma Loop_Invariant (for all K in J + 1 .. I => A (A'First + (K - 1)) > Key);
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (A'First + (J - 1 - 1)) <= A (A'First + (K - 1)));
         pragma Loop_Invariant
           (if J < I then A (A'First + (J - 1)) = A (A'First + (J + 1 - 1)) else A (A'First + (J - 1)) = Key);
         pragma Loop_Invariant (All_In (A, Lo, I, Low, High));
         pragma Loop_Invariant
           (for all K in 1 .. A'Length =>
              (if K < Lo or else K > I then A (A'First + (K - 1)) = A'Loop_Entry (A'First + (K - 1))));
         pragma Loop_Variant (Decreases => J);

         A (A'First + (J - 1)) := A (A'First + (J - 1 - 1));
         J     := J - 1;
      end loop;

      pragma Assert (Sorted_Slice (A, Lo, J - 1));
      pragma Assert (Sorted_Slice (A, J + 1, I));
      pragma Assert (for all K in J + 1 .. I => A (A'First + (K - 1)) > Key);
      pragma Assert (J = Lo or else A (A'First + (J - 1 - 1)) <= Key);

      A (A'First + (J - 1)) := Key;

      pragma Assert (if J > Lo then A (A'First + (J - 1 - 1)) <= A (A'First + (J - 1)));
      pragma Assert (if J < I then A (A'First + (J - 1)) <= A (A'First + (J + 1 - 1)));
      pragma Assert (Sorted_Slice (A, Lo, I));
   end Insert_Step;

   --  Insertion-sort one bucket A (Lo .. Hi) in place (empty if Hi < Lo).
   procedure Sort_Bucket
     (A         : in out Element_Array;
      Lo        : Pos;
      Hi        : Index;
      Low, High : Integer)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Hi <= A'Length
         and then Lo <= Hi + 1
         and then All_In (A, Lo, Hi, Low, High),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, Hi)
         and then All_In (A, Lo, Hi, Low, High)
         and then
           (for all K in 1 .. A'Length =>
              (if K < Lo or else K > Hi then A (A'First + (K - 1)) = A'Old (A'First + (K - 1))))
   is
   begin
      for I in Lo + 1 .. Hi loop
         pragma Loop_Invariant (Sorted_Slice (A, Lo, I - 1));
         pragma Loop_Invariant (All_In (A, Lo, Hi, Low, High));
         pragma Loop_Invariant
           (for all K in 1 .. A'Length =>
              (if K < Lo or else K > Hi then A (A'First + (K - 1)) = A'Loop_Entry (A'First + (K - 1))));

         Insert_Step (A, Lo, I, Low, High);
      end loop;
   end Sort_Bucket;

   --  Partition the suffix A (Lo .. A'Length) by Pivot: afterwards
   --  A (Lo .. M - 1) <= Pivot < A (M .. A'Length).  Elements only move
   --  inside the suffix, so a lower bound on it is kept.
   procedure Partition
     (A     : in out Element_Array;
      Lo    : Pos;
      Pivot : Integer;
      Floor : Integer;
      M     : out Pos)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Lo <= A'Length + 1
         and then All_In (A, Lo, A'Length, Floor, Integer'Last),
       Post   =>
         In_Bounds (A)
         and then M in Lo .. A'Length + 1
         and then All_In (A, Lo, M - 1, Floor, Pivot)
         and then (for all K in M .. A'Length => A (A'First + (K - 1)) > Pivot)
         and then All_In (A, Lo, A'Length, Floor, Integer'Last)
         and then (for all K in 1 .. Lo - 1 => A (A'First + (K - 1)) = A'Old (A'First + (K - 1)))
   is
   begin
      M := Lo;
      for I in Lo .. A'Length loop
         pragma Loop_Invariant (M in Lo .. I);
         pragma Loop_Invariant (All_In (A, Lo, M - 1, Floor, Pivot));
         pragma Loop_Invariant (for all K in M .. I - 1 => A (A'First + (K - 1)) > Pivot);
         pragma Loop_Invariant
           (All_In (A, Lo, A'Length, Floor, Integer'Last));
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (A'First + (K - 1)) = A'Loop_Entry (A'First + (K - 1)));

         if A (A'First + (I - 1)) <= Pivot then
            Swap (A, M, I);
            M := M + 1;
         end if;
      end loop;
   end Partition;

   --  Num_Buckets - 1 pivots from equally spaced samples (stride
   --  N / Num_Buckets, no RNG), sorted with the bucket insertion sort.
   procedure Choose_Pivots
     (A : Element_Array; Pivots : out Element_Array)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= Num_Buckets
         and then Pivots'First = 1
         and then Pivots'Last = Num_Buckets - 1,
       Post   => Sorted_Slice (Pivots, 1, Pivots'Last)
   is
      Stride : constant Positive := A'Length / Num_Buckets;
      Sample : Natural := 0;
   begin
      for I in Pivots'Range loop
         pragma Loop_Invariant (Sample = (I - 1) * Stride);
         pragma Loop_Invariant (Sample + (Num_Buckets - I + 1) * Stride <= A'Length);

         Sample := Sample + Stride;
         Pivots (I) := A (A'First + (Sample - 1));
      end loop;
      Sort_Bucket (Pivots, 1, Pivots'Last, Integer'First, Integer'Last);
   end Choose_Pivots;

   procedure Sort (A : in out Element_Array) is
      Pivots : Element_Array (1 .. Num_Buckets - 1);
      Lo     : Pos := 1;
      M      : Pos;
      Floor  : Integer := Integer'First;
   begin
      if A'Length <= 1 then
         return;
      end if;

      if A'Length >= Num_Buckets then
         Choose_Pivots (A, Pivots);
         for K in Pivots'Range loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (Lo <= A'Length + 1);
            pragma Loop_Invariant (Sorted_Slice (A, 1, Lo - 1));
            pragma Loop_Invariant (Lo = 1 or else A (A'First + (Lo - 1 - 1)) = Floor);
            pragma Loop_Invariant
              (All_In (A, Lo, A'Length, Floor, Integer'Last));

            Partition (A, Lo, Pivots (K), Floor, M);
            Sort_Bucket (A, Lo, M - 1, Floor, Pivots (K));
            if M > Lo then
               Floor := A (A'First + (M - 1 - 1));
            end if;
            pragma Assert (Sorted_Slice (A, 1, M - 1));
            Lo := M;
         end loop;
      end if;

      --  Last bucket: everything above the largest pivot (the whole
      --  array when there are no pivots).
      Sort_Bucket (A, Lo, A'Length, Floor, Integer'Last);
      pragma Assert (Sorted_Slice (A, 1, A'Length));
   end Sort;

end Samplesort;
