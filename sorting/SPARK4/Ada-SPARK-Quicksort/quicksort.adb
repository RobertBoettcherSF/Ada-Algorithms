--  Quicksort body — SPARK Level 4 classic in-place quicksort.
--  Median-of-three places a middle-ish pivot at Hi; Lomuto partition
--  lands it in a final slot P. Recursive Sort_Range is bounded by
--  Subprogram_Variant (Hi - Lo). Loop invariants track the Lomuto
--  split; ghost All_Leq / All_Geq carry the partition bounds through
--  recursive calls so the glue lemma can reassemble Is_Sorted.

package body Quicksort
  with SPARK_Mode => On
is

   --  One past the live range (Lomuto write cursor after a full left fill).
   subtype Cursor is Natural range 0 .. Max_N + 1;

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

   --  Every A (L .. R) is <= V. Vacuous when L > R.
   function All_Leq
     (A    : Element_Array;
      L, R : Natural;
      V    : Integer) return Boolean
   is
     (L > R or else (for all K in L .. R => A (K) <= V))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Last;

   --  Every A (L .. R) is >= V. Vacuous when L > R.
   function All_Geq
     (A    : Element_Array;
      L, R : Natural;
      V    : Integer) return Boolean
   is
     (L > R or else (for all K in L .. R => A (K) >= V))
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

   --  Glue: sorted left + sorted right + junctions at P ⇒ sorted Lo .. Hi.
   procedure Lemma_Glue
     (A          : Element_Array;
      Lo, P, Hi  : Index)
     with
       Ghost             => True,
       Always_Terminates => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last
         and then P in Lo .. Hi
         and then Sorted_Slice (A, Lo, P)
         and then Sorted_Slice (A, P, Hi),
       Post              => Sorted_Slice (A, Lo, Hi)
   is
   begin
      pragma Assert (Sorted_Slice (A, Lo, P));
      pragma Assert (Sorted_Slice (A, P, Hi));
      pragma Assert
        (for all K in Lo .. P - 1 => A (K) <= A (K + 1));
      pragma Assert
        (for all K in P .. Hi - 1 => A (K) <= A (K + 1));
      pragma Assert (Sorted_Slice (A, Lo, Hi));
   end Lemma_Glue;

   --  Order A(Lo), A(Mid), A(Hi) and move the median to Hi (Lomuto pivot).
   procedure Median_Of_Three
     (A                    : in out Element_Array;
      Lo, Hi               : Index;
      Lower_Bound, Upper_Bound : Integer)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then Lo in 1 .. A'Last
         and then Hi in Lo + 1 .. A'Last
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound),
       Post   =>
         In_Bounds (A)
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound)
         and then
           (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then
           (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
   is
      Mid : constant Index := Lo + (Hi - Lo) / 2;
   begin
      pragma Assert (Mid in Lo .. Hi);

      if A (Mid) < A (Lo) then
         Swap (A, Lo, Mid);
      end if;
      pragma Assert (All_Geq (A, Lo, Hi, Lower_Bound));
      pragma Assert (All_Leq (A, Lo, Hi, Upper_Bound));

      if A (Hi) < A (Lo) then
         Swap (A, Lo, Hi);
      end if;
      pragma Assert (All_Geq (A, Lo, Hi, Lower_Bound));
      pragma Assert (All_Leq (A, Lo, Hi, Upper_Bound));

      if A (Hi) < A (Mid) then
         Swap (A, Mid, Hi);
      end if;
      pragma Assert (All_Geq (A, Lo, Hi, Lower_Bound));
      pragma Assert (All_Leq (A, Lo, Hi, Upper_Bound));

      --  A(Lo) <= A(Mid) <= A(Hi); median sits at Mid. Park it at Hi.
      Swap (A, Mid, Hi);
      pragma Assert (All_Geq (A, Lo, Hi, Lower_Bound));
      pragma Assert (All_Leq (A, Lo, Hi, Upper_Bound));
   end Median_Of_Three;

   --  Lomuto partition of A (Lo .. Hi). Pivot is A(Hi) on entry (after
   --  median-of-three). Returns P such that A(Lo .. P-1) <= A(P) and
   --  A(P+1 .. Hi) > A(P). Bounds of the whole slice are preserved.
   procedure Partition
     (A                        : in out Element_Array;
      Lo, Hi                   : Index;
      Lower_Bound, Upper_Bound : Integer;
      P                        : out Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then Lo in 1 .. A'Last
         and then Hi in Lo + 1 .. A'Last
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound),
       Post   =>
         In_Bounds (A)
         and then P in Lo .. Hi
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound)
         and then All_Leq (A, Lo, P - 1, A (P))
         and then All_Geq (A, P + 1, Hi, A (P))
         and then
           (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then
           (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
   is
      Pivot : Integer;
      I     : Cursor;
   begin
      Median_Of_Three (A, Lo, Hi, Lower_Bound, Upper_Bound);

      Pivot := A (Hi);
      I     := Cursor (Lo);

      pragma Assert (All_Geq (A, Lo, Hi, Lower_Bound));
      pragma Assert (All_Leq (A, Lo, Hi, Upper_Bound));
      pragma Assert (All_Leq (A, Lo, Lo - 1, Pivot));

      for J in Lo .. Hi - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I in Lo .. J);
         pragma Loop_Invariant (A (Hi) = Pivot);
         pragma Loop_Invariant (All_Geq (A, Lo, Hi, Lower_Bound));
         pragma Loop_Invariant (All_Leq (A, Lo, Hi, Upper_Bound));
         pragma Loop_Invariant (All_Leq (A, Lo, I - 1, Pivot));
         pragma Loop_Invariant
           (for all K in I .. J - 1 => A (K) > Pivot);
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Last => A (K) = A'Loop_Entry (K));

         if A (J) <= Pivot then
            pragma Assert (I in 1 .. A'Last);
            pragma Assert (J in 1 .. A'Last);
            Swap (A, Index (I), J);
            I := I + 1;
         end if;

         pragma Assert (I in Lo .. J + 1);
         pragma Assert (All_Leq (A, Lo, I - 1, Pivot));
         pragma Assert (for all K in I .. J => A (K) > Pivot);
      end loop;

      pragma Assert (I in Lo .. Hi);
      pragma Assert (A (Hi) = Pivot);
      pragma Assert (All_Leq (A, Lo, I - 1, Pivot));
      pragma Assert (for all K in I .. Hi - 1 => A (K) > Pivot);
      pragma Assert (All_Geq (A, Lo, Hi, Lower_Bound));
      pragma Assert (All_Leq (A, Lo, Hi, Upper_Bound));

      Swap (A, Index (I), Hi);

      P := Index (I);

      pragma Assert (P in Lo .. Hi);
      pragma Assert (A (P) = Pivot);
      pragma Assert (All_Leq (A, Lo, P - 1, A (P)));
      pragma Assert (for all K in P + 1 .. Hi => A (K) > Pivot);
      pragma Assert (All_Geq (A, P + 1, Hi, A (P)));
      pragma Assert (All_Geq (A, Lo, Hi, Lower_Bound));
      pragma Assert (All_Leq (A, Lo, Hi, Upper_Bound));
   end Partition;

   --  Quicksort A (Lo .. Hi). Lower_Bound / Upper_Bound are ghost-style
   --  value bounds of the live slice: every cell stays in that interval
   --  so the partition property survives the recursive permutations.
   procedure Sort_Range
     (A                        : in out Element_Array;
      Lo, Hi                   : Index;
      Lower_Bound, Upper_Bound : Integer)
     with
       Global            => null,
       Subprogram_Variant => (Decreases => Hi - Lo),
       Pre               =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound),
       Post              =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, Hi)
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound)
         and then
           (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then
           (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
   is
      P : Index;
   begin
      if Lo >= Hi then
         pragma Assert (Sorted_Slice (A, Lo, Hi));
         return;
      end if;

      pragma Assert (Hi >= Lo + 1);
      pragma Assert (A'Last >= 2);

      Partition (A, Lo, Hi, Lower_Bound, Upper_Bound, P);

      pragma Assert (P in Lo .. Hi);
      pragma Assert (All_Geq (A, Lo, Hi, Lower_Bound));
      pragma Assert (All_Leq (A, Lo, Hi, Upper_Bound));
      pragma Assert (All_Leq (A, Lo, P - 1, A (P)));
      pragma Assert (All_Geq (A, P + 1, Hi, A (P)));
      pragma Assert (A (P) >= Lower_Bound);
      pragma Assert (A (P) <= Upper_Bound);

      if P > Lo then
         pragma Assert (P - 1 >= Lo);
         pragma Assert ((P - 1) - Lo < Hi - Lo);
         pragma Assert (All_Geq (A, Lo, P - 1, Lower_Bound));
         pragma Assert (All_Leq (A, Lo, P - 1, A (P)));
         Sort_Range (A, Lo, P - 1, Lower_Bound, A (P));
         pragma Assert (Sorted_Slice (A, Lo, P - 1));
         pragma Assert (All_Leq (A, Lo, P - 1, A (P)));
         pragma Assert (All_Geq (A, Lo, P - 1, Lower_Bound));
      else
         pragma Assert (P = Lo);
         pragma Assert (Sorted_Slice (A, Lo, P - 1));
      end if;

      pragma Assert (All_Geq (A, P + 1, Hi, A (P)));
      pragma Assert (All_Leq (A, P + 1, Hi, Upper_Bound));

      if P < Hi then
         pragma Assert (Hi - (P + 1) < Hi - Lo);
         pragma Assert (All_Geq (A, P + 1, Hi, A (P)));
         pragma Assert (All_Leq (A, P + 1, Hi, Upper_Bound));
         Sort_Range (A, P + 1, Hi, A (P), Upper_Bound);
         pragma Assert (Sorted_Slice (A, P + 1, Hi));
         pragma Assert (All_Geq (A, P + 1, Hi, A (P)));
         pragma Assert (All_Leq (A, P + 1, Hi, Upper_Bound));
      else
         pragma Assert (P = Hi);
         pragma Assert (Sorted_Slice (A, P + 1, Hi));
      end if;

      --  Junctions: last of left <= pivot <= first of right.
      pragma Assert (if P > Lo then A (P - 1) <= A (P));
      pragma Assert (if P < Hi then A (P) <= A (P + 1));
      pragma Assert (Sorted_Slice (A, Lo, P - 1));
      pragma Assert (Sorted_Slice (A, P + 1, Hi));
      pragma Assert (Sorted_Slice (A, Lo, P));
      pragma Assert (Sorted_Slice (A, P, Hi));

      Lemma_Glue (A, Lo, P, Hi);

      pragma Assert (Sorted_Slice (A, Lo, Hi));

      --  Whole-slice bounds: left <= A(P) <= Upper, A(P) >= Lower,
      --  right >= A(P) and <= Upper.
      pragma Assert (All_Leq (A, Lo, P - 1, A (P)));
      pragma Assert (A (P) <= Upper_Bound);
      pragma Assert (All_Leq (A, Lo, Hi, Upper_Bound));
      pragma Assert (All_Geq (A, P + 1, Hi, A (P)));
      pragma Assert (A (P) >= Lower_Bound);
      pragma Assert (All_Geq (A, Lo, Hi, Lower_Bound));
   end Sort_Range;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      pragma Assert (A'First = 1);
      pragma Assert (A'Last in 2 .. Max_N);
      pragma Assert (All_Geq (A, 1, A'Last, Integer'First));
      pragma Assert (All_Leq (A, 1, A'Last, Integer'Last));

      Sort_Range (A, 1, A'Last, Integer'First, Integer'Last);

      pragma Assert (Sorted_Slice (A, 1, A'Last));
      pragma Assert (Is_Sorted (A));
   end Sort;

end Quicksort;
