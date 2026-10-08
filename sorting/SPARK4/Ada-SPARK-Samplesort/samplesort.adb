--  Samplesort body.  Equally spaced samples give Num_Buckets - 1 pivots,
--  which are sorted.  The buckets are then cut out of the array in place,
--  one pivot at a time: a partition of the not yet placed suffix
--  A (Lo .. A'Last) moves the elements <= the pivot to its front, and
--  that bucket is insertion-sorted where it lies.  The last bucket (all
--  elements above the largest pivot) is sorted the same way.  With fewer
--  than Num_Buckets elements there are no pivots and the whole array is
--  that single bucket.
--
--  Proof: one invariant carries the sort across buckets.  A (1 .. Lo - 1)
--  is sorted, Floor is its last element (Integer'First while it is
--  empty), and every element of A (Lo .. A'Last) is >= Floor.  A bucket
--  holds values in Floor .. Pivot and the rest stays > Pivot, so the
--  sorted bucket extends the sorted prefix.

package body Samplesort
  with SPARK_Mode => On
is

   --  Positions one past the end are needed for empty slices.
   subtype Pos is Positive range 1 .. Max_N + 1;

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

   --  Every element of A (L .. R) lies in Low .. High.
   function All_In
     (A : Element_Array; L, R : Natural; Low, High : Integer) return Boolean
   is
     (for all K in L .. R => A (K) in Low .. High)
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Last;

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

   --  Insert A (I) into the sorted A (Lo .. I - 1).  Values only move
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
         and then I in Lo + 1 .. A'Last
         and then Sorted_Slice (A, Lo, I - 1)
         and then All_In (A, Lo, I, Low, High),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, I)
         and then All_In (A, Lo, I, Low, High)
         and then
           (for all K in 1 .. A'Last =>
              (if K < Lo or else K > I then A (K) = A'Old (K)))
   is
      Key : constant Integer := A (I);
      J   : Index := I;
   begin
      while J > Lo and then Key < A (J - 1) loop
         pragma Loop_Invariant (J in Lo + 1 .. I);
         pragma Loop_Invariant (Key in Low .. High);
         pragma Loop_Invariant (Sorted_Slice (A, Lo, J - 1));
         pragma Loop_Invariant (Sorted_Slice (A, J + 1, I));
         pragma Loop_Invariant (for all K in J + 1 .. I => A (K) > Key);
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (J - 1) <= A (K));
         pragma Loop_Invariant
           (if J < I then A (J) = A (J + 1) else A (J) = Key);
         pragma Loop_Invariant (All_In (A, Lo, I, Low, High));
         pragma Loop_Invariant
           (for all K in 1 .. A'Last =>
              (if K < Lo or else K > I then A (K) = A'Loop_Entry (K)));
         pragma Loop_Variant (Decreases => J);

         A (J) := A (J - 1);
         J     := J - 1;
      end loop;

      pragma Assert (Sorted_Slice (A, Lo, J - 1));
      pragma Assert (Sorted_Slice (A, J + 1, I));
      pragma Assert (for all K in J + 1 .. I => A (K) > Key);
      pragma Assert (J = Lo or else A (J - 1) <= Key);

      A (J) := Key;

      pragma Assert (if J > Lo then A (J - 1) <= A (J));
      pragma Assert (if J < I then A (J) <= A (J + 1));
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
         and then Hi <= A'Last
         and then Lo <= Hi + 1
         and then All_In (A, Lo, Hi, Low, High),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, Hi)
         and then All_In (A, Lo, Hi, Low, High)
         and then
           (for all K in 1 .. A'Last =>
              (if K < Lo or else K > Hi then A (K) = A'Old (K)))
   is
   begin
      for I in Lo + 1 .. Hi loop
         pragma Loop_Invariant (Sorted_Slice (A, Lo, I - 1));
         pragma Loop_Invariant (All_In (A, Lo, Hi, Low, High));
         pragma Loop_Invariant
           (for all K in 1 .. A'Last =>
              (if K < Lo or else K > Hi then A (K) = A'Loop_Entry (K)));

         Insert_Step (A, Lo, I, Low, High);
      end loop;
   end Sort_Bucket;

   --  Partition the suffix A (Lo .. A'Last) by Pivot: afterwards
   --  A (Lo .. M - 1) <= Pivot < A (M .. A'Last).  Elements only move
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
         and then Lo <= A'Last + 1
         and then All_In (A, Lo, A'Last, Floor, Integer'Last),
       Post   =>
         In_Bounds (A)
         and then M in Lo .. A'Last + 1
         and then All_In (A, Lo, M - 1, Floor, Pivot)
         and then (for all K in M .. A'Last => A (K) > Pivot)
         and then All_In (A, Lo, A'Last, Floor, Integer'Last)
         and then (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
   is
   begin
      M := Lo;
      for I in Lo .. A'Last loop
         pragma Loop_Invariant (M in Lo .. I);
         pragma Loop_Invariant (All_In (A, Lo, M - 1, Floor, Pivot));
         pragma Loop_Invariant (for all K in M .. I - 1 => A (K) > Pivot);
         pragma Loop_Invariant
           (All_In (A, Lo, A'Last, Floor, Integer'Last));
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (K) = A'Loop_Entry (K));

         if A (I) <= Pivot then
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
         and then A'Last >= Num_Buckets
         and then Pivots'First = 1
         and then Pivots'Last = Num_Buckets - 1,
       Post   => Sorted_Slice (Pivots, 1, Pivots'Last)
   is
      Stride : constant Positive := A'Last / Num_Buckets;
      Sample : Natural := 0;
   begin
      for I in Pivots'Range loop
         pragma Loop_Invariant (Sample = (I - 1) * Stride);
         pragma Loop_Invariant (Sample + (Num_Buckets - I + 1) * Stride <= A'Last);

         Sample := Sample + Stride;
         Pivots (I) := A (Sample);
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

      if A'Last >= Num_Buckets then
         Choose_Pivots (A, Pivots);
         for K in Pivots'Range loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (Lo <= A'Last + 1);
            pragma Loop_Invariant (Sorted_Slice (A, 1, Lo - 1));
            pragma Loop_Invariant (Lo = 1 or else A (Lo - 1) = Floor);
            pragma Loop_Invariant
              (All_In (A, Lo, A'Last, Floor, Integer'Last));

            Partition (A, Lo, Pivots (K), Floor, M);
            Sort_Bucket (A, Lo, M - 1, Floor, Pivots (K));
            if M > Lo then
               Floor := A (M - 1);
            end if;
            pragma Assert (Sorted_Slice (A, 1, M - 1));
            Lo := M;
         end loop;
      end if;

      --  Last bucket: everything above the largest pivot (the whole
      --  array when there are no pivots).
      Sort_Bucket (A, Lo, A'Last, Floor, Integer'Last);
      pragma Assert (Sorted_Slice (A, 1, A'Last));
   end Sort;

end Samplesort;
