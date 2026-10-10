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

   --  Same_Occ quantifies over every Integer value, so the contracts,
   --  invariants and assertions of this body (all proved by gnatprove) are
   --  not checked at run time; the Post of Sort in the spec (sorted,
   --  Is_Perm) still is.
   pragma Assertion_Policy
     (Pre => Ignore, Post => Ignore, Loop_Invariant => Ignore, Assert => Ignore);

   --  A and B have the same bounds and every value occurs equally often.
   function Same_Occ (A, B : Element_Array) return Boolean is
     (A'First = B'First
      and then A'Last = B'Last
      and then (A'Length = 0
                or else (for all V in Integer =>
                           Occ (A, V, A'First, A'Last)
                           = Occ (B, V, B'First, B'Last))))
   with
     Ghost,
     Global => null,
     Pre    => In_Bounds (A) and then In_Bounds (B);

   package Perm_Lemmas
     with Ghost
   is
      --  Counts over First .. Last only see First .. Last.
      procedure Lemma_Occ_Eq (A, B : Element_Array; First : Positive; Last : Natural)
      with
        Global             => null,
        Pre                =>
          (if First <= Last then
             First >= A'First and then Last <= A'Last
             and then First >= B'First and then Last <= B'Last
             and then (for all T in First .. Last => A (T) = B (T))),
        Post               =>
          (for all V in Integer =>
             Occ (A, V, First, Last) = Occ (B, V, First, Last)),
        Subprogram_Variant => (Decreases => Last);

      --  The executable Is_Perm and the logical Same_Occ agree.
      procedure Lemma_Same_Perm (A, B : Element_Array)
      with
        Global => null,
        Pre    => In_Bounds (A) and then In_Bounds (B) and then Same_Occ (A, B),
        Post   => Is_Perm (A, B);

      procedure Lemma_Same_Trans (A, B, C : Element_Array)
      with
        Global => null,
        Pre    =>
          In_Bounds (A) and then In_Bounds (B) and then In_Bounds (C)
          and then Same_Occ (A, B) and then Same_Occ (B, C),
        Post   => Same_Occ (A, C);

      --  B is A with slot K changed.
      procedure Lemma_Occ_Set
        (A, B : Element_Array; K : Positive; First : Positive; Last : Natural)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First and then A'Last = B'Last
          and then K in First .. Last
          and then First >= A'First and then Last <= A'Last
          and then (for all J in A'Range => (if J /= K then A (J) = B (J))),
        Post               =>
          (for all V in Integer =>
             Occ (B, V, First, Last)
             = Occ (A, V, First, Last)
               - (if A (K) = V then 1 else 0)
               + (if B (K) = V then 1 else 0)),
        Subprogram_Variant => (Decreases => Last);

      --  B is A with slots X and Y exchanged.
      procedure Lemma_Swap (A, B : Element_Array; X, Y : Positive)
      with
        Global => null,
        Pre    =>
          In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First and then A'Last = B'Last
          and then X in A'Range and then Y in A'Range
          and then B (X) = A (Y) and then B (Y) = A (X)
          and then (for all J in A'Range =>
                      (if J /= X and then J /= Y then A (J) = B (J))),
        Post   => Same_Occ (A, B);
   end Perm_Lemmas;

   package body Perm_Lemmas is

      procedure Lemma_Occ_Eq (A, B : Element_Array; First : Positive; Last : Natural) is
      begin
         if First <= Last then
            Lemma_Occ_Eq (A, B, First, Last - 1);
         end if;
      end Lemma_Occ_Eq;

      procedure Lemma_Occ_Set
        (A, B : Element_Array; K : Positive; First : Positive; Last : Natural) is
      begin
         if Last > K then
            Lemma_Occ_Set (A, B, K, First, Last - 1);
         else
            Lemma_Occ_Eq (A, B, First, K - 1);
         end if;
      end Lemma_Occ_Set;

      procedure Lemma_Swap (A, B : Element_Array; X, Y : Positive) is
      begin
         if X = Y then
            Lemma_Occ_Eq (A, B, A'First, A'Last);
            return;
         end if;
         declare
            C : constant Element_Array := (A with delta X => A (Y));
         begin
            Lemma_Occ_Set (A, C, X, A'First, A'Last);
            Lemma_Occ_Set (C, B, Y, A'First, A'Last);
         end;
      end Lemma_Swap;

      procedure Lemma_Same_Perm (A, B : Element_Array) is null;

      procedure Lemma_Same_Trans (A, B, C : Element_Array) is null;

   end Perm_Lemmas;
   use Perm_Lemmas;

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
         and then Same_Occ (A'Old, A)
   is
      T  : Integer;
      A0 : constant Element_Array := A with Ghost;
   begin
      if X = Y then
         return;
      end if;
      T     := A (A'First + (X - 1));
      A (A'First + (X - 1)) := A (A'First + (Y - 1));
      A (A'First + (Y - 1)) := T;
      Lemma_Swap (A0, A, A'First + (X - 1), A'First + (Y - 1));
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
         and then Same_Occ (A'Old, A)
   is
      Key  : constant Integer := A (A'First + (I - 1));
      J    : Index := I;
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      --  Insertion by adjacent exchanges: Key moves down past every
      --  larger neighbour (same comparisons as shifting).
      while J > Lo and then Key < A (A'First + (J - 1 - 1)) loop
         pragma Loop_Invariant (J in Lo + 1 .. I);
         pragma Loop_Invariant (Key in Low .. High);
         pragma Loop_Invariant (A (A'First + (J - 1)) = Key);
         pragma Loop_Invariant (Sorted_Slice (A, Lo, J - 1));
         pragma Loop_Invariant (Sorted_Slice (A, J + 1, I));
         pragma Loop_Invariant (for all K in J + 1 .. I => A (A'First + (K - 1)) > Key);
         pragma Loop_Invariant
           (if J < I and then J > Lo then A (A'First + (J - 1 - 1)) <= A (A'First + (J + 1 - 1)));
         pragma Loop_Invariant (All_In (A, Lo, I, Low, High));
         pragma Loop_Invariant
           (for all K in 1 .. A'Length =>
              (if K < Lo or else K > I then A (A'First + (K - 1)) = A'Loop_Entry (A'First + (K - 1))));
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Variant (Decreases => J);

         Prev := A;
         Swap (A, J - 1, J);
         Lemma_Same_Trans (A0, Prev, A);
         J := J - 1;
      end loop;

      pragma Assert (Sorted_Slice (A, Lo, J - 1));
      pragma Assert (Sorted_Slice (A, J + 1, I));
      pragma Assert (for all K in J + 1 .. I => A (A'First + (K - 1)) > Key);
      pragma Assert (J = Lo or else A (A'First + (J - 1 - 1)) <= Key);
      pragma Assert (A (A'First + (J - 1)) = Key);

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
         and then Same_Occ (A'Old, A)
   is
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      for I in Lo + 1 .. Hi loop
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Invariant (Sorted_Slice (A, Lo, I - 1));
         pragma Loop_Invariant (All_In (A, Lo, Hi, Low, High));
         pragma Loop_Invariant
           (for all K in 1 .. A'Length =>
              (if K < Lo or else K > Hi then A (A'First + (K - 1)) = A'Loop_Entry (A'First + (K - 1))));

         Prev := A;
         Insert_Step (A, Lo, I, Low, High);
         Lemma_Same_Trans (A0, Prev, A);
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
         and then Same_Occ (A'Old, A)
   is
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      M := Lo;
      for I in Lo .. A'Length loop
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Invariant (M in Lo .. I);
         pragma Loop_Invariant (All_In (A, Lo, M - 1, Floor, Pivot));
         pragma Loop_Invariant (for all K in M .. I - 1 => A (A'First + (K - 1)) > Pivot);
         pragma Loop_Invariant
           (All_In (A, Lo, A'Length, Floor, Integer'Last));
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (A'First + (K - 1)) = A'Loop_Entry (A'First + (K - 1)));

         if A (A'First + (I - 1)) <= Pivot then
            Prev := A;
            Swap (A, M, I);
            Lemma_Same_Trans (A0, Prev, A);
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

   --  Sortedness by positions is the spec's Is_Sorted (proved on its own,
   --  away from the count facts of Sort).
   procedure Lemma_Slice_Is_Sorted (A : Element_Array)
   with
     Ghost,
     Global => null,
     Pre    => In_Bounds (A) and then Sorted_Slice (A, 1, A'Length),
     Post   => Is_Sorted (A);

   procedure Lemma_Slice_Is_Sorted (A : Element_Array) is null;

   procedure Sort (A : in out Element_Array) is
      Pivots : Element_Array (1 .. Num_Buckets - 1);
      Lo     : Pos := 1;
      M      : Pos;
      Floor  : Integer := Integer'First;
      A0     : constant Element_Array := A with Ghost;
      Prev   : Element_Array (A'Range) with Ghost;
   begin
      if A'Length <= 1 then
         Lemma_Same_Perm (A, A0);
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
            pragma Loop_Invariant (Same_Occ (A0, A));

            Prev := A;
            Partition (A, Lo, Pivots (K), Floor, M);
            Lemma_Same_Trans (A0, Prev, A);
            Prev := A;
            Sort_Bucket (A, Lo, M - 1, Floor, Pivots (K));
            Lemma_Same_Trans (A0, Prev, A);
            if M > Lo then
               Floor := A (A'First + (M - 1 - 1));
            end if;
            pragma Assert (Sorted_Slice (A, 1, M - 1));
            Lo := M;
         end loop;
      end if;

      --  Last bucket: everything above the largest pivot (the whole
      --  array when there are no pivots).
      pragma Assert (Same_Occ (A0, A));
      Prev := A;
      Sort_Bucket (A, Lo, A'Length, Floor, Integer'Last);
      Lemma_Same_Trans (A0, Prev, A);
      pragma Assert (Sorted_Slice (A, 1, A'Length));
      Lemma_Slice_Is_Sorted (A);
      Lemma_Same_Perm (A, A0);
   end Sort;

end Samplesort;
