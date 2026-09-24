--  Introsort body — SPARK Level 4 Musser introsort.
--  Median-of-three Lomuto quicksort, insertion on partitions of size
--  ≤ Insertion_Threshold, and a heapsort fallback when the depth
--  budget is exhausted. Recursive Intro_Sort_Rec is bounded by
--  Subprogram_Variant (Hi - Lo). Ghost All_Leq / All_Geq carry
--  partition bounds through recursive calls so the glue lemma can
--  reassemble Is_Sorted. The heapsort fallback copies the exhausted
--  slice to a 1-based scratch array so Floyd sift uses Parent = I/2,
--  Left = 2*I (same contracts as Ada-SPARK-Heapsort).

package body Introsort
  with SPARK_Mode => On
is

   --  One past the live range (Lomuto write cursor after a full left fill).
   subtype Cursor is Natural range 0 .. Max_N + 1;

   --  2 * floor(log2(Max_N)) = 12; Musser depth budget never exceeds this.
   subtype Depth_Count is Natural range 0 .. 12;

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

   function Is_Heap (A : Element_Array; Last : Index) return Boolean is
     (Last < 2
      or else (for all I in 2 .. Last => A (I / 2) >= A (I)))
   with
     Ghost  => True,
     Global => null,
     Pre    => In_Bounds (A) and then Last <= A'Last;

   function Heap_From
     (A : Element_Array; Last : Index; Bound : Natural) return Boolean
   is
     (Last < 2
      or else Bound > Natural (Last)
      or else
        (for all I in 2 .. Last =>
           (if Natural (I / 2) >= Bound then A (I / 2) >= A (I))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Last <= A'Last
       and then Bound <= Natural (Max_N) + 1;

   function Heap_Leq_Suffix
     (A : Element_Array; Heap_Last, N : Index) return Boolean
   is
     (Heap_Last = 0
      or else Heap_Last >= N
      or else
        (for all H in 1 .. Heap_Last =>
           (for all S in Heap_Last + 1 .. N => A (H) <= A (S))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then N <= A'Last
       and then Heap_Last <= N;

   function Heap_Except_Hole
     (A : Element_Array; Last, Root, R : Index) return Boolean
   is
     (for all I in 2 .. Last =>
        (if I / 2 >= Root and then I / 2 /= R then A (I / 2) >= A (I)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Last <= A'Last
       and then Root in 1 .. Last
       and then R in Root .. Last;

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
     (A         : Element_Array;
      Lo, P, Hi : Index)
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

   procedure Lemma_Root_Is_Max (A : Element_Array; Last : Index)
     with
       Ghost             => True,
       Always_Terminates => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Last in 1 .. A'Last
         and then Is_Heap (A, Last),
       Post              =>
         (for all K in 1 .. Last => A (1) >= A (K))
   is
   begin
      for K in 1 .. Last loop
         pragma Loop_Invariant
           (for all J in 1 .. K - 1 => A (1) >= A (J));
         pragma Loop_Invariant (Is_Heap (A, Last));

         declare
            P : Index := K;
         begin
            pragma Assert (A (P) >= A (K));
            while P > 1 loop
               pragma Loop_Invariant (P in 1 .. Last);
               pragma Loop_Invariant (A (P) >= A (K));
               pragma Loop_Invariant (Is_Heap (A, Last));
               pragma Loop_Variant (Decreases => P);

               pragma Assert (P in 2 .. Last);
               pragma Assert (A (P / 2) >= A (P));
               P := P / 2;
               pragma Assert (A (P) >= A (K));
            end loop;
            pragma Assert (P = 1);
            pragma Assert (A (1) >= A (K));
         end;
      end loop;
   end Lemma_Root_Is_Max;

   --  Decision-tree ⌊log₂ N⌋ for N in 1 .. Max_N (avoids a bit-loop VC).
   function Floor_Log2 (N : Index) return Natural
     with
       Global => null,
       Pre    => N in 1 .. Max_N,
       Post   => Floor_Log2'Result <= 6
   is
   begin
      if N <= 1 then
         return 0;
      elsif N <= 3 then
         return 1;
      elsif N <= 7 then
         return 2;
      elsif N <= 15 then
         return 3;
      elsif N <= 31 then
         return 4;
      elsif N <= 63 then
         return 5;
      else
         return 6;
      end if;
   end Floor_Log2;

   ---------------------------------------------------------------------------
   -- Insertion sort on inclusive Lo .. Hi (Ada-SPARK-Insertion-Sort style)
   ---------------------------------------------------------------------------

   procedure Insert_Step
     (A                        : in out Element_Array;
      Lo, I                    : Index;
      Lower_Bound, Upper_Bound : Integer)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then I in Lo + 1 .. A'Last
         and then Sorted_Slice (A, Lo, I - 1)
         and then All_Geq (A, Lo, I, Lower_Bound)
         and then All_Leq (A, Lo, I, Upper_Bound),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, I)
         and then All_Geq (A, Lo, I, Lower_Bound)
         and then All_Leq (A, Lo, I, Upper_Bound)
         and then
           (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then
           (for all K in I + 1 .. A'Last => A (K) = A'Old (K))
   is
      Key : constant Integer := A (I);
      J   : Index := I;
   begin
      while J > Lo and then Key < A (J - 1) loop
         pragma Loop_Invariant (J in Lo + 1 .. I);
         pragma Loop_Invariant (Sorted_Slice (A, Lo, J - 1));
         pragma Loop_Invariant (Sorted_Slice (A, J + 1, I));
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (K) > Key);
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (J - 1) <= A (K));
         pragma Loop_Invariant
           (if J < I then A (J) = A (J + 1) else A (J) = Key);
         pragma Loop_Invariant (All_Geq (A, Lo, I, Lower_Bound));
         pragma Loop_Invariant (All_Leq (A, Lo, I, Upper_Bound));
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Decreases => J);

         A (J) := A (J - 1);
         J     := J - 1;
      end loop;

      pragma Assert (J in Lo .. I);
      pragma Assert (Sorted_Slice (A, Lo, J - 1));
      pragma Assert (Sorted_Slice (A, J + 1, I));
      pragma Assert (for all K in J + 1 .. I => A (K) > Key);
      pragma Assert (J = Lo or else A (J - 1) <= Key);
      pragma Assert (All_Geq (A, Lo, I, Lower_Bound));
      pragma Assert (All_Leq (A, Lo, I, Upper_Bound));
      pragma Assert (Key >= Lower_Bound);
      pragma Assert (Key <= Upper_Bound);

      A (J) := Key;

      pragma Assert (if J > Lo then A (J - 1) <= A (J));
      pragma Assert (if J < I then A (J) <= A (J + 1));
      pragma Assert (Sorted_Slice (A, Lo, I));
      pragma Assert (All_Geq (A, Lo, I, Lower_Bound));
      pragma Assert (All_Leq (A, Lo, I, Upper_Bound));
   end Insert_Step;

   procedure Insertion_Sort_Range
     (A                        : in out Element_Array;
      Lo, Hi                   : Index;
      Lower_Bound, Upper_Bound : Integer)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, Hi)
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound)
         and then
           (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then
           (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
   is
   begin
      if Lo >= Hi then
         pragma Assert (Sorted_Slice (A, Lo, Hi));
         return;
      end if;

      pragma Assert (Sorted_Slice (A, Lo, Lo));

      for I in Lo + 1 .. Hi loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, Lo, I - 1));
         pragma Loop_Invariant (All_Geq (A, Lo, Hi, Lower_Bound));
         pragma Loop_Invariant (All_Leq (A, Lo, Hi, Upper_Bound));
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in I .. Hi => A (K) = A'Loop_Entry (K));

         Insert_Step (A, Lo, I, Lower_Bound, Upper_Bound);

         pragma Assert (Sorted_Slice (A, Lo, I));
         pragma Assert (All_Geq (A, Lo, I, Lower_Bound));
         pragma Assert (All_Leq (A, Lo, I, Upper_Bound));
      end loop;
   end Insertion_Sort_Range;

   ---------------------------------------------------------------------------
   -- 1-based heapsort (Ada-SPARK-Heapsort style) + range wrapper
   ---------------------------------------------------------------------------

   procedure Sift_Down_Restore
     (A                        : in out Element_Array;
      Root                     : Index;
      Heap_Last                : Index;
      N                        : Index;
      Lower_Bound, Upper_Bound : Integer)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then N in Heap_Last .. A'Last
         and then Heap_Last in 1 .. A'Last
         and then Root in 1 .. Heap_Last
         and then Heap_From (A, Heap_Last, Natural (Root) + 1)
         and then Heap_Leq_Suffix (A, Heap_Last, N)
         and then All_Geq (A, 1, N, Lower_Bound)
         and then All_Leq (A, 1, N, Upper_Bound),
       Post   =>
         In_Bounds (A)
         and then Heap_From (A, Heap_Last, Natural (Root))
         and then Heap_Leq_Suffix (A, Heap_Last, N)
         and then All_Geq (A, 1, N, Lower_Bound)
         and then All_Leq (A, 1, N, Upper_Bound)
         and then
           (for all K in Heap_Last + 1 .. A'Last => A (K) = A'Old (K))
         and then
           (for all K in 1 .. Root - 1 => A (K) = A'Old (K))
   is
      R     : Index := Root;
      Child : Index;
      Left  : Index;
   begin
      loop
         pragma Loop_Invariant (R in Root .. Heap_Last);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all K in Heap_Last + 1 .. A'Last =>
              A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in 1 .. Root - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (Heap_Except_Hole (A, Heap_Last, Root, R));
         pragma Loop_Invariant
           (if R > Root then A (R / 2) >= A (R));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Heap_Last, N));
         pragma Loop_Invariant (All_Geq (A, 1, N, Lower_Bound));
         pragma Loop_Invariant (All_Leq (A, 1, N, Upper_Bound));
         pragma Loop_Invariant
           (if R > Root and then R <= Heap_Last / 2 then
              A (R / 2) >= A (2 * R)
              and then
              (if 2 * R < Heap_Last then A (R / 2) >= A (2 * R + 1)));
         pragma Loop_Variant (Decreases => Heap_Last - R + 1);

         if R > Heap_Last / 2 then
            pragma Assert (Heap_From (A, Heap_Last, Natural (Root)));
            return;
         end if;

         Left := 2 * R;
         pragma Assert (Left in 2 .. Heap_Last);
         Child := Left;

         if Left < Heap_Last and then A (Left) < A (Left + 1) then
            Child := Left + 1;
         end if;

         pragma Assert (Child = Left or else Child = Left + 1);
         pragma Assert (Child / 2 = R);
         pragma Assert (A (Child) >= A (Left));
         pragma Assert
           (if Left < Heap_Last then A (Child) >= A (Left + 1));
         pragma Assert
           (if R > Root then A (R / 2) >= A (Child));

         if A (R) >= A (Child) then
            pragma Assert (A (R) >= A (Left));
            pragma Assert
              (if Left < Heap_Last then A (R) >= A (Left + 1));
            pragma Assert
              (for all I in 2 .. Heap_Last =>
                 (if I / 2 >= Root then A (I / 2) >= A (I)));
            pragma Assert (Heap_From (A, Heap_Last, Natural (Root)));
            return;
         end if;

         Swap (A, R, Child);

         pragma Assert (A (R) >= A (Left));
         pragma Assert
           (if Left < Heap_Last then A (R) >= A (Left + 1));
         pragma Assert (A (R) >= A (Child));
         pragma Assert (A (R) >= A (Child));
         pragma Assert (if R > Root then A (R / 2) >= A (R));
         pragma Assert (Heap_Except_Hole (A, Heap_Last, Root, Child));
         pragma Assert (Heap_Leq_Suffix (A, Heap_Last, N));
         pragma Assert (All_Geq (A, 1, N, Lower_Bound));
         pragma Assert (All_Leq (A, 1, N, Upper_Bound));
         pragma Assert
           (if Child <= Heap_Last / 2 then
              A (R) >= A (2 * Child)
              and then
              (if 2 * Child < Heap_Last then A (R) >= A (2 * Child + 1)));

         R := Child;
         pragma Assert (if R > Root then A (R / 2) >= A (R));
      end loop;
   end Sift_Down_Restore;

   --  Classic 1-based heapsort of a live In_Bounds array (scratch T).
   procedure Heap_Sort
     (A                        : in out Element_Array;
      Lower_Bound, Upper_Bound : Integer)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then All_Geq (A, 1, A'Last, Lower_Bound)
         and then All_Leq (A, 1, A'Last, Upper_Bound),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, 1, A'Last)
         and then All_Geq (A, 1, A'Last, Lower_Bound)
         and then All_Leq (A, 1, A'Last, Upper_Bound)
   is
      Heap_Last : Index;
      N         : Index;
      Start     : Index;
   begin
      N := A'Last;
      pragma Assert (N in 2 .. Max_N);

      Start := N / 2;
      pragma Assert (Heap_From (A, N, Natural (Start) + 1));
      pragma Assert (Heap_Leq_Suffix (A, N, N));
      loop
         pragma Loop_Invariant (Start in 1 .. N / 2);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Heap_From (A, N, Natural (Start) + 1));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, N, N));
         pragma Loop_Invariant (All_Geq (A, 1, N, Lower_Bound));
         pragma Loop_Invariant (All_Leq (A, 1, N, Upper_Bound));
         pragma Loop_Variant (Decreases => Start);

         Sift_Down_Restore
           (A, Start, N, N, Lower_Bound, Upper_Bound);
         pragma Assert (Heap_From (A, N, Natural (Start)));

         exit when Start = 1;
         Start := Start - 1;
      end loop;

      pragma Assert (Is_Heap (A, N));
      Lemma_Root_Is_Max (A, N);

      Heap_Last := N;
      pragma Assert (Sorted_Slice (A, N + 1, N));
      pragma Assert (Heap_Leq_Suffix (A, N, N));

      while Heap_Last > 1 loop
         pragma Loop_Invariant (Heap_Last in 2 .. N);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Is_Heap (A, Heap_Last));
         pragma Loop_Invariant (Sorted_Slice (A, Heap_Last + 1, N));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Heap_Last, N));
         pragma Loop_Invariant (All_Geq (A, 1, N, Lower_Bound));
         pragma Loop_Invariant (All_Leq (A, 1, N, Upper_Bound));
         pragma Loop_Variant (Decreases => Heap_Last);

         Lemma_Root_Is_Max (A, Heap_Last);
         pragma Assert (for all K in 1 .. Heap_Last => A (1) >= A (K));

         Swap (A, 1, Heap_Last);

         pragma Assert
           (Heap_Last = N
            or else A (Heap_Last) <= A (Heap_Last + 1));
         pragma Assert (Sorted_Slice (A, Heap_Last, N));
         pragma Assert
           (for all H in 1 .. Heap_Last - 1 =>
              (for all S in Heap_Last .. N => A (H) <= A (S)));
         pragma Assert (All_Geq (A, 1, N, Lower_Bound));
         pragma Assert (All_Leq (A, 1, N, Upper_Bound));

         pragma Assert (Heap_From (A, Heap_Last - 1, 2));

         Heap_Last := Heap_Last - 1;

         pragma Assert (Heap_Leq_Suffix (A, Heap_Last, N));
         pragma Assert (Heap_From (A, Heap_Last, 2));

         Sift_Down_Restore
           (A, 1, Heap_Last, N, Lower_Bound, Upper_Bound);
         pragma Assert (Is_Heap (A, Heap_Last));
         pragma Assert (Sorted_Slice (A, Heap_Last + 1, N));
         pragma Assert (Heap_Leq_Suffix (A, Heap_Last, N));
      end loop;

      pragma Assert (Heap_Last = 1);
      pragma Assert (Sorted_Slice (A, 2, N));
      pragma Assert (Heap_Leq_Suffix (A, 1, N));
      pragma Assert (A (1) <= A (2));
      pragma Assert (Sorted_Slice (A, 1, N));
      pragma Assert (All_Geq (A, 1, N, Lower_Bound));
      pragma Assert (All_Leq (A, 1, N, Upper_Bound));
   end Heap_Sort;

   --  Heapsort A (Lo .. Hi) via a 1-based scratch copy (classroom
   --  concession vs in-place First-relative sift: Parent = I/2 VCs).
   procedure Heapsort_Range
     (A                        : in out Element_Array;
      Lo, Hi                   : Index;
      Lower_Bound, Upper_Bound : Integer)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo + 1 .. A'Last
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, Hi)
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound)
         and then
           (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then
           (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
   is
      Len : constant Index := Hi - Lo + 1;
      T   : Element_Array (1 .. Len) := [others => 0];
   begin
      pragma Assert (Len in 2 .. Max_N);
      pragma Assert (In_Bounds (T));

      for I in 1 .. Len loop
         T (I) := A (Lo + I - 1);

         pragma Loop_Invariant (In_Bounds (T));
         pragma Loop_Invariant
           (for all K in 1 .. I => T (K) = A (Lo + K - 1));
         pragma Loop_Invariant (All_Geq (T, 1, I, Lower_Bound));
         pragma Loop_Invariant (All_Leq (T, 1, I, Upper_Bound));
      end loop;

      pragma Assert (All_Geq (T, 1, Len, Lower_Bound));
      pragma Assert (All_Leq (T, 1, Len, Upper_Bound));
      pragma Assert (T'Last >= 2);

      Heap_Sort (T, Lower_Bound, Upper_Bound);

      pragma Assert (Sorted_Slice (T, 1, Len));
      pragma Assert (All_Geq (T, 1, Len, Lower_Bound));
      pragma Assert (All_Leq (T, 1, Len, Upper_Bound));

      for I in 1 .. Len loop
         A (Lo + I - 1) := T (I);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all K in 1 .. I => A (Lo + K - 1) = T (K));
         pragma Loop_Invariant (Sorted_Slice (A, Lo, Lo + I - 1));
         pragma Loop_Invariant (All_Geq (A, Lo, Lo + I - 1, Lower_Bound));
         pragma Loop_Invariant (All_Leq (A, Lo, Lo + I - 1, Upper_Bound));
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Lo + I .. A'Last => A (K) = A'Loop_Entry (K));
      end loop;

      pragma Assert (Lo + Len - 1 = Hi);
      pragma Assert (Sorted_Slice (A, Lo, Hi));
      pragma Assert (All_Geq (A, Lo, Hi, Lower_Bound));
      pragma Assert (All_Leq (A, Lo, Hi, Upper_Bound));
   end Heapsort_Range;

   ---------------------------------------------------------------------------
   -- Median-of-three + Lomuto (Ada-SPARK-Quicksort style)
   ---------------------------------------------------------------------------

   procedure Median_Of_Three
     (A                        : in out Element_Array;
      Lo, Hi                   : Index;
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

      Swap (A, Mid, Hi);
      pragma Assert (All_Geq (A, Lo, Hi, Lower_Bound));
      pragma Assert (All_Leq (A, Lo, Hi, Upper_Bound));
   end Median_Of_Three;

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

   ---------------------------------------------------------------------------
   -- Recursive introsort on inclusive Lo .. Hi
   ---------------------------------------------------------------------------

   procedure Intro_Sort_Rec
     (A                        : in out Element_Array;
      Lo, Hi                   : Index;
      Depth                    : Depth_Count;
      Lower_Bound, Upper_Bound : Integer)
     with
       Global             => null,
       Subprogram_Variant => (Decreases => Hi - Lo),
       Pre                =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound),
       Post               =>
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
      N : Natural;
   begin
      if Lo >= Hi then
         pragma Assert (Sorted_Slice (A, Lo, Hi));
         return;
      end if;

      pragma Assert (Hi >= Lo + 1);
      pragma Assert (A'Last >= 2);

      N := Hi - Lo + 1;

      if N <= Insertion_Threshold then
         Insertion_Sort_Range (A, Lo, Hi, Lower_Bound, Upper_Bound);
         pragma Assert (Sorted_Slice (A, Lo, Hi));
         return;
      end if;

      if Depth = 0 then
         Heapsort_Range (A, Lo, Hi, Lower_Bound, Upper_Bound);
         pragma Assert (Sorted_Slice (A, Lo, Hi));
         return;
      end if;

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
         Intro_Sort_Rec
           (A, Lo, P - 1, Depth - 1, Lower_Bound, A (P));
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
         Intro_Sort_Rec
           (A, P + 1, Hi, Depth - 1, A (P), Upper_Bound);
         pragma Assert (Sorted_Slice (A, P + 1, Hi));
         pragma Assert (All_Geq (A, P + 1, Hi, A (P)));
         pragma Assert (All_Leq (A, P + 1, Hi, Upper_Bound));
      else
         pragma Assert (P = Hi);
         pragma Assert (Sorted_Slice (A, P + 1, Hi));
      end if;

      pragma Assert (if P > Lo then A (P - 1) <= A (P));
      pragma Assert (if P < Hi then A (P) <= A (P + 1));
      pragma Assert (Sorted_Slice (A, Lo, P - 1));
      pragma Assert (Sorted_Slice (A, P + 1, Hi));
      pragma Assert (Sorted_Slice (A, Lo, P));
      pragma Assert (Sorted_Slice (A, P, Hi));

      Lemma_Glue (A, Lo, P, Hi);

      pragma Assert (Sorted_Slice (A, Lo, Hi));
      pragma Assert (All_Leq (A, Lo, P - 1, A (P)));
      pragma Assert (A (P) <= Upper_Bound);
      pragma Assert (All_Leq (A, Lo, Hi, Upper_Bound));
      pragma Assert (All_Geq (A, P + 1, Hi, A (P)));
      pragma Assert (A (P) >= Lower_Bound);
      pragma Assert (All_Geq (A, Lo, Hi, Lower_Bound));
   end Intro_Sort_Rec;

   procedure Sort (A : in out Element_Array) is
      Depth : Depth_Count;
   begin
      if A'Length <= 1 then
         return;
      end if;

      pragma Assert (A'First = 1);
      pragma Assert (A'Last in 2 .. Max_N);
      pragma Assert (All_Geq (A, 1, A'Last, Integer'First));
      pragma Assert (All_Leq (A, 1, A'Last, Integer'Last));

      Depth := 2 * Floor_Log2 (A'Last);

      Intro_Sort_Rec
        (A, 1, A'Last, Depth, Integer'First, Integer'Last);

      pragma Assert (Sorted_Slice (A, 1, A'Last));
      pragma Assert (Is_Sorted (A));
   end Sort;

end Introsort;
