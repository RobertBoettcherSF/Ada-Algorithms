--  Introsort body — SPARK Level 4 Musser introsort.
--  Median-of-three Lomuto quicksort, insertion on partitions of size
--  ≤ Insertion_Threshold, and a heapsort fallback when the depth
--  budget is exhausted. Recursive Intro_Sort_Rec is bounded by
--  Subprogram_Variant (Hi - Lo). Ghost All_Leq / All_Geq carry
--  partition bounds through recursive calls so the glue lemma can
--  reassemble Is_Sorted. The heapsort fallback runs in place on the
--  exhausted slice Lo .. Hi with the offset heap (Parent =
--  Lo+(I-Lo-1)/2; Has_Left checked before Left = Lo+2*(I-Lo)+1), the
--  same general form as Ada-SPARK-Heapsort; any A'First.

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
       and then L >= A'First
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
       and then L >= A'First
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
       and then L >= A'First
       and then R <= A'Last;

   procedure Swap (A : in out Element_Array; X, Y : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then X in A'Range
         and then Y in A'Range,
       Post   =>
         In_Bounds (A)
         and then A (X) = A'Old (Y)
         and then A (Y) = A'Old (X)
         and then
           (for all K in A'Range =>
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
         and then Lo in A'First .. A'Last
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
         and then Lo in A'First .. A'Last
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
           (for all K in A'First .. Lo - 1 => A (K) = A'Old (K))
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
           (for all K in A'First .. Lo - 1 => A (K) = A'Loop_Entry (K));
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
         and then Lo in A'First .. A'Last
         and then Hi in Lo .. A'Last
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, Hi)
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound)
         and then
           (for all K in A'First .. Lo - 1 => A (K) = A'Old (K))
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
           (for all K in A'First .. Lo - 1 => A (K) = A'Loop_Entry (K));
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
   -- First-relative heap on Base .. Last (any Base; room offset form)
   --   Parent (I) = Base + (I - Base - 1) / 2
   --   Has_Left (I) <=> I - Base <= (Hi - Base - 1) / 2   (checked first)
   --   Left (I)   = Base + 2 * (I - Base) + 1             (no overflow)
   ---------------------------------------------------------------------------

   function Parent (Base, I : Index) return Index is
     (Base + (I - Base - 1) / 2)
   with
     Global => null,
     Pre    => I > Base and then Base >= 1,
     Post   =>
       Parent'Result in Base .. I - 1
       and then 2 * (Parent'Result - Base) + 1 <= I - Base
       and then I - Base <= 2 * (Parent'Result - Base) + 2;

   function Has_Left (Base, Hi, I : Index) return Boolean is
     (Hi > Base and then I - Base <= (Hi - Base - 1) / 2)
   with
     Global => null,
     Pre    => Base >= 1 and then Hi >= Base and then I in Base .. Hi;

   function Left_Child (Base, Hi, I : Index) return Index
   with
     Global => null,
     Pre    =>
       Base >= 1
       and then Hi >= Base
       and then I in Base .. Hi
       and then Has_Left (Base, Hi, I),
     Post   =>
       Left_Child'Result in I + 1 .. Hi
       and then Left_Child'Result = Base + 2 * (I - Base) + 1
       and then Parent (Base, Left_Child'Result) = I
       and then
         (if Left_Child'Result < Hi then
            Parent (Base, Left_Child'Result + 1) = I)
   is
      Off : constant Natural := I - Base;
      L   : Index;
   begin
      pragma Assert (2 * Off + 1 <= Hi - Base);
      L := Base + 2 * Off + 1;
      pragma Assert ((L - Base - 1) / 2 = Off);
      pragma Assert (Parent (Base, L) = I);
      if L < Hi then
         pragma Assert ((L + 1 - Base - 1) / 2 = Off);
         pragma Assert (Parent (Base, L + 1) = I);
      end if;
      return L;
   end Left_Child;

   function Is_Heap
     (A : Element_Array; Base, Last : Index) return Boolean
   is
     (Last <= Base
      or else
        (for all I in Base + 1 .. Last => A (Parent (Base, I)) >= A (I)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Base in A'Range
       and then Last <= A'Last;

   function Heap_From
     (A : Element_Array; Base, Last : Index; Bound : Natural)
      return Boolean
   is
     (Last <= Base
      or else Bound > Natural (Last)
      or else
        (for all I in Base + 1 .. Last =>
           (if Natural (Parent (Base, I)) >= Bound then
              A (Parent (Base, I)) >= A (I))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Base in A'Range
       and then Last <= A'Last
       and then Bound <= Natural (Max_N) + 1;

   function Heap_Leq_Suffix
     (A : Element_Array; Base, Heap_Last, N : Index) return Boolean
   is
     (Heap_Last < Base
      or else Heap_Last >= N
      or else
        (for all H in Base .. Heap_Last =>
           (for all S in Heap_Last + 1 .. N => A (H) <= A (S))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Base in A'Range
       and then N <= A'Last
       and then Heap_Last <= N;

   function Heap_Except_Hole
     (A : Element_Array; Base, Last, Root, R : Index) return Boolean
   is
     (for all I in Base + 1 .. Last =>
        (if Parent (Base, I) >= Root and then Parent (Base, I) /= R then
           A (Parent (Base, I)) >= A (I)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Base in A'Range
       and then Last <= A'Last
       and then Root in Base .. Last
       and then R in Root .. Last;

   procedure Lemma_Root_Is_Max
     (A : Element_Array; Base, Last : Index)
     with
       Ghost             => True,
       Always_Terminates => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Base in A'Range
         and then Last in Base .. A'Last
         and then Is_Heap (A, Base, Last),
       Post              =>
         (for all K in Base .. Last => A (Base) >= A (K))
   is
   begin
      for K in Base .. Last loop
         pragma Loop_Invariant
           (for all J in Base .. K - 1 => A (Base) >= A (J));
         pragma Loop_Invariant (Is_Heap (A, Base, Last));

         declare
            P : Index := K;
         begin
            while P > Base loop
               pragma Loop_Invariant (P in Base .. Last);
               pragma Loop_Invariant (A (P) >= A (K));
               pragma Loop_Invariant (Is_Heap (A, Base, Last));
               pragma Loop_Variant (Decreases => P);

               pragma Assert (A (Parent (Base, P)) >= A (P));
               P := Parent (Base, P);
            end loop;
            pragma Assert (P = Base);
         end;
      end loop;
   end Lemma_Root_Is_Max;

   procedure Sift_Down_Restore
     (A                        : in out Element_Array;
      Base, Root, Heap_Last, N : Index;
      Lower_Bound, Upper_Bound : Integer)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Base in A'Range
         and then N in Heap_Last .. A'Last
         and then Heap_Last in Base .. A'Last
         and then Root in Base .. Heap_Last
         and then Heap_From (A, Base, Heap_Last, Natural (Root) + 1)
         and then Heap_Leq_Suffix (A, Base, Heap_Last, N)
         and then All_Geq (A, Base, N, Lower_Bound)
         and then All_Leq (A, Base, N, Upper_Bound),
       Post   =>
         In_Bounds (A)
         and then Heap_From (A, Base, Heap_Last, Natural (Root))
         and then Heap_Leq_Suffix (A, Base, Heap_Last, N)
         and then All_Geq (A, Base, N, Lower_Bound)
         and then All_Leq (A, Base, N, Upper_Bound)
         and then
           (for all K in Heap_Last + 1 .. A'Last => A (K) = A'Old (K))
         and then
           (for all K in A'First .. Root - 1 => A (K) = A'Old (K))
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
           (for all K in A'First .. Root - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (Heap_Except_Hole (A, Base, Heap_Last, Root, R));
         pragma Loop_Invariant
           (if R > Root then A (Parent (Base, R)) >= A (R));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Base, Heap_Last, N));
         pragma Loop_Invariant (All_Geq (A, Base, N, Lower_Bound));
         pragma Loop_Invariant (All_Leq (A, Base, N, Upper_Bound));
         pragma Loop_Invariant
           (if R > Root and then Has_Left (Base, Heap_Last, R) then
              A (Parent (Base, R)) >= A (Left_Child (Base, Heap_Last, R))
              and then
              (if Left_Child (Base, Heap_Last, R) < Heap_Last then
                 A (Parent (Base, R))
                   >= A (Left_Child (Base, Heap_Last, R) + 1)));
         pragma Loop_Variant (Decreases => Heap_Last - R + 1);

         if not Has_Left (Base, Heap_Last, R) then
            pragma Assert
              (Heap_From (A, Base, Heap_Last, Natural (Root)));
            return;
         end if;

         Left := Left_Child (Base, Heap_Last, R);
         pragma Assert (Parent (Base, Left) = R);
         pragma Assert
           (if Left < Heap_Last then Parent (Base, Left + 1) = R);
         Child := Left;

         if Left < Heap_Last and then A (Left) < A (Left + 1) then
            Child := Left + 1;
         end if;

         pragma Assert (Child = Left or else Child = Left + 1);
         pragma Assert (Parent (Base, Child) = R);
         pragma Assert (A (Child) >= A (Left));
         pragma Assert
           (if Left < Heap_Last then A (Child) >= A (Left + 1));
         pragma Assert
           (if R > Root then A (Parent (Base, R)) >= A (Child));
         pragma Assert
           (if Has_Left (Base, Heap_Last, Child) then
              Parent (Base, Left_Child (Base, Heap_Last, Child)) = Child
              and then A (Child) >= A (Left_Child (Base, Heap_Last, Child))
              and then
              (if Left_Child (Base, Heap_Last, Child) < Heap_Last then
                 Parent (Base, Left_Child (Base, Heap_Last, Child) + 1)
                   = Child
                 and then
                 A (Child)
                   >= A (Left_Child (Base, Heap_Last, Child) + 1)));

         if A (R) >= A (Child) then
            pragma Assert
              (for all I in Base + 1 .. Heap_Last =>
                 (if Parent (Base, I) = R then
                    I = Left or else I = Left + 1));
            pragma Assert
              (for all I in Base + 1 .. Heap_Last =>
                 (if Parent (Base, I) >= Root then
                    A (Parent (Base, I)) >= A (I)));
            pragma Assert
              (Heap_From (A, Base, Heap_Last, Natural (Root)));
            return;
         end if;

         Swap (A, R, Child);

         pragma Assert (A (R) >= A (Left));
         pragma Assert
           (if Left < Heap_Last then A (R) >= A (Left + 1));
         pragma Assert (A (R) >= A (Child));
         pragma Assert (Parent (Base, Child) = R);
         pragma Assert (if R > Root then A (Parent (Base, R)) >= A (R));
         pragma Assert
           (if Has_Left (Base, Heap_Last, Child) then
              A (R) >= A (Left_Child (Base, Heap_Last, Child))
              and then
              (if Left_Child (Base, Heap_Last, Child) < Heap_Last then
                 A (R) >= A (Left_Child (Base, Heap_Last, Child) + 1)));
         pragma Assert
           (for all I in Base + 1 .. Heap_Last =>
              (if Parent (Base, I) = R then I = Left or else I = Left + 1));
         pragma Assert
           (for all I in Base + 1 .. Heap_Last =>
              (if Parent (Base, I) = R then A (R) >= A (I)));
         pragma Assert
           (Heap_Except_Hole (A, Base, Heap_Last, Root, Child));
         pragma Assert (Heap_Leq_Suffix (A, Base, Heap_Last, N));
         pragma Assert (All_Geq (A, Base, N, Lower_Bound));
         pragma Assert (All_Leq (A, Base, N, Upper_Bound));

         R := Child;
         pragma Assert (if R > Root then A (Parent (Base, R)) >= A (R));
      end loop;
   end Sift_Down_Restore;

   --  In-place heapsort of Lo .. Hi with the offset heap (Base = Lo):
   --  slices mid-sort rarely start at 1, so no scratch copy and no
   --  A'First = 1 assumption.
   procedure Heapsort_Range
     (A                        : in out Element_Array;
      Lo, Hi                   : Index;
      Lower_Bound, Upper_Bound : Integer)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Lo in A'First .. A'Last
         and then Hi in Lo + 1 .. A'Last
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, Hi)
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound)
         and then
           (for all K in A'First .. Lo - 1 => A (K) = A'Old (K))
         and then
           (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
   is
      Heap_Last : Index;
      Start     : Index;
   begin
      Start := Parent (Lo, Hi);
      pragma Assert (Heap_From (A, Lo, Hi, Natural (Start) + 1));
      pragma Assert (Heap_Leq_Suffix (A, Lo, Hi, Hi));
      loop
         pragma Loop_Invariant (Start in Lo .. Parent (Lo, Hi));
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Heap_From (A, Lo, Hi, Natural (Start) + 1));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Lo, Hi, Hi));
         pragma Loop_Invariant (All_Geq (A, Lo, Hi, Lower_Bound));
         pragma Loop_Invariant (All_Leq (A, Lo, Hi, Upper_Bound));
         pragma Loop_Invariant
           (for all K in A'First .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Decreases => Start);

         Sift_Down_Restore
           (A, Lo, Start, Hi, Hi, Lower_Bound, Upper_Bound);
         pragma Assert (Heap_From (A, Lo, Hi, Natural (Start)));

         exit when Start = Lo;
         Start := Start - 1;
      end loop;

      pragma Assert (Is_Heap (A, Lo, Hi));
      Lemma_Root_Is_Max (A, Lo, Hi);

      Heap_Last := Hi;
      pragma Assert (Sorted_Slice (A, Hi + 1, Hi));

      while Heap_Last > Lo loop
         pragma Loop_Invariant (Heap_Last in Lo + 1 .. Hi);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Is_Heap (A, Lo, Heap_Last));
         pragma Loop_Invariant (Sorted_Slice (A, Heap_Last + 1, Hi));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Lo, Heap_Last, Hi));
         pragma Loop_Invariant (All_Geq (A, Lo, Hi, Lower_Bound));
         pragma Loop_Invariant (All_Leq (A, Lo, Hi, Upper_Bound));
         pragma Loop_Invariant
           (for all K in A'First .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Decreases => Heap_Last);

         Lemma_Root_Is_Max (A, Lo, Heap_Last);
         pragma Assert
           (for all K in Lo .. Heap_Last => A (Lo) >= A (K));

         Swap (A, Lo, Heap_Last);

         pragma Assert
           (Heap_Last = Hi or else A (Heap_Last) <= A (Heap_Last + 1));
         pragma Assert (Sorted_Slice (A, Heap_Last, Hi));
         pragma Assert
           (for all H in Lo .. Heap_Last - 1 =>
              (for all S in Heap_Last .. Hi => A (H) <= A (S)));
         pragma Assert
           (Heap_From (A, Lo, Heap_Last - 1, Natural (Lo) + 1));

         Heap_Last := Heap_Last - 1;

         pragma Assert (Heap_Leq_Suffix (A, Lo, Heap_Last, Hi));
         pragma Assert (Heap_From (A, Lo, Heap_Last, Natural (Lo) + 1));

         Sift_Down_Restore
           (A, Lo, Lo, Heap_Last, Hi, Lower_Bound, Upper_Bound);
         pragma Assert (Is_Heap (A, Lo, Heap_Last));
      end loop;

      pragma Assert (Heap_Last = Lo);
      pragma Assert (Sorted_Slice (A, Lo + 1, Hi));
      pragma Assert (Heap_Leq_Suffix (A, Lo, Lo, Hi));
      pragma Assert (A (Lo) <= A (Lo + 1));
      pragma Assert (Sorted_Slice (A, Lo, Hi));
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
         and then Lo in A'First .. A'Last
         and then Hi in Lo + 1 .. A'Last
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound),
       Post   =>
         In_Bounds (A)
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound)
         and then
           (for all K in A'First .. Lo - 1 => A (K) = A'Old (K))
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
         and then Lo in A'First .. A'Last
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
           (for all K in A'First .. Lo - 1 => A (K) = A'Old (K))
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
           (for all K in A'First .. Lo - 1 => A (K) = A'Loop_Entry (K));
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
         and then Lo in A'First .. A'Last
         and then Hi in Lo .. A'Last
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound),
       Post               =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, Hi)
         and then All_Geq (A, Lo, Hi, Lower_Bound)
         and then All_Leq (A, Lo, Hi, Upper_Bound)
         and then
           (for all K in A'First .. Lo - 1 => A (K) = A'Old (K))
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
      Lo    : Index;
      Hi    : Index;
   begin
      if A'Length <= 1 then
         return;
      end if;

      Lo := Index (A'First);
      Hi := Index (A'Last);
      pragma Assert (Hi >= Lo + 1);
      pragma Assert (All_Geq (A, Lo, Hi, Integer'First));
      pragma Assert (All_Leq (A, Lo, Hi, Integer'Last));

      Depth := 2 * Floor_Log2 (A'Length);

      Intro_Sort_Rec
        (A, Lo, Hi, Depth, Integer'First, Integer'Last);

      pragma Assert (Sorted_Slice (A, Lo, Hi));
      pragma Assert (Is_Sorted (A));
   end Sort;

end Introsort;
