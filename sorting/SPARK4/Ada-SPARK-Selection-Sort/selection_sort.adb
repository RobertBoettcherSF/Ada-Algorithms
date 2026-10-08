--  Selection_Sort body — SPARK Level 4 classic in-place selection sort.
--  Outer loop grows a sorted prefix; inner scan finds the extremum of the
--  unsorted suffix; a swap places it. Loop invariants track sortedness of
--  the prefix and the partition property vs. the remaining suffix.

package body Selection_Sort
  with SPARK_Mode => On
is

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

   --  Adjacent nonincreasing on A (L .. R). Vacuous when L >= R.
   function Sorted_Desc_Slice
     (A : Element_Array; L, R : Natural) return Boolean
   is
     (L >= R
      or else (for all K in L .. R - 1 => A (K) >= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Last;

   --  Every element of A (Lo_P .. Hi_P) is <= every element of A (Lo_S .. Hi_S).
   function Prefix_Leq_Suffix
     (A                    : Element_Array;
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

   --  Every element of A (Lo_P .. Hi_P) is >= every element of A (Lo_S .. Hi_S).
   function Prefix_Geq_Suffix
     (A                    : Element_Array;
      Lo_P, Hi_P, Lo_S, Hi_S : Natural) return Boolean
   is
     (Hi_P < Lo_P
      or else Hi_S < Lo_S
      or else
        (for all K in Lo_P .. Hi_P =>
           (for all L in Lo_S .. Hi_S => A (K) >= A (L))))
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

   --  Place the minimum of A (I .. A'Last) at index I by swap.
   procedure Select_Min_Step (A : in out Element_Array; I : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then I in 1 .. A'Last - 1
         and then Sorted_Slice (A, 1, I - 1)
         and then Prefix_Leq_Suffix (A, 1, I - 1, I, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, 1, I)
         and then Prefix_Leq_Suffix (A, 1, I, I + 1, A'Last)
   is
      Min_Index : Index := I;
   begin
      for J in I + 1 .. A'Last loop
         pragma Loop_Invariant (Min_Index in I .. J - 1);
         pragma Loop_Invariant
           (for all K in I .. J - 1 => A (Min_Index) <= A (K));
         pragma Loop_Invariant (Sorted_Slice (A, 1, I - 1));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, I - 1, I, A'Last));
         pragma Loop_Invariant
           (for all K in 1 .. A'Last => A (K) = A'Loop_Entry (K));

         if A (J) < A (Min_Index) then
            Min_Index := J;
         end if;
      end loop;

      pragma Assert (Min_Index in I .. A'Last);
      pragma Assert (for all K in I .. A'Last => A (Min_Index) <= A (K));
      pragma Assert (Sorted_Slice (A, 1, I - 1));
      pragma Assert (Prefix_Leq_Suffix (A, 1, I - 1, I, A'Last));
      --  Partition + min ⇒ A(I-1) <= A(Min_Index) when I > 1.
      pragma Assert (I = 1 or else A (I - 1) <= A (Min_Index));

      Swap (A, I, Min_Index);

      pragma Assert (for all K in I .. A'Last => A (I) <= A (K));
      pragma Assert (I = 1 or else A (I - 1) <= A (I));
      pragma Assert (Sorted_Slice (A, 1, I));
      pragma Assert (Prefix_Leq_Suffix (A, 1, I, I + 1, A'Last));
   end Select_Min_Step;

   --  Place the maximum of A (I .. A'Last) at index I by swap.
   procedure Select_Max_Step (A : in out Element_Array; I : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then I in 1 .. A'Last - 1
         and then Sorted_Desc_Slice (A, 1, I - 1)
         and then Prefix_Geq_Suffix (A, 1, I - 1, I, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Desc_Slice (A, 1, I)
         and then Prefix_Geq_Suffix (A, 1, I, I + 1, A'Last)
   is
      Max_Index : Index := I;
   begin
      for J in I + 1 .. A'Last loop
         pragma Loop_Invariant (Max_Index in I .. J - 1);
         pragma Loop_Invariant
           (for all K in I .. J - 1 => A (Max_Index) >= A (K));
         pragma Loop_Invariant (Sorted_Desc_Slice (A, 1, I - 1));
         pragma Loop_Invariant
           (Prefix_Geq_Suffix (A, 1, I - 1, I, A'Last));
         pragma Loop_Invariant
           (for all K in 1 .. A'Last => A (K) = A'Loop_Entry (K));

         if A (J) > A (Max_Index) then
            Max_Index := J;
         end if;
      end loop;

      pragma Assert (Max_Index in I .. A'Last);
      pragma Assert (for all K in I .. A'Last => A (Max_Index) >= A (K));
      pragma Assert (Sorted_Desc_Slice (A, 1, I - 1));
      pragma Assert (Prefix_Geq_Suffix (A, 1, I - 1, I, A'Last));
      pragma Assert (I = 1 or else A (I - 1) >= A (Max_Index));

      Swap (A, I, Max_Index);

      pragma Assert (for all K in I .. A'Last => A (I) >= A (K));
      pragma Assert (I = 1 or else A (I - 1) >= A (I));
      pragma Assert (Sorted_Desc_Slice (A, 1, I));
      pragma Assert (Prefix_Geq_Suffix (A, 1, I, I + 1, A'Last));
   end Select_Max_Step;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      pragma Assert (Sorted_Slice (A, 1, 0));
      pragma Assert (Prefix_Leq_Suffix (A, 1, 0, 1, A'Last));

      for I in 1 .. A'Last - 1 loop
         Select_Min_Step (A, I);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, 1, I));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, 1, I, I + 1, A'Last));
         pragma Loop_Invariant (Is_Sorted (A (1 .. I)));
      end loop;

      pragma Assert (Sorted_Slice (A, 1, A'Last - 1));
      pragma Assert (Prefix_Leq_Suffix (A, 1, A'Last - 1, A'Last, A'Last));
      pragma Assert (Is_Sorted (A));
   end Sort;

   procedure Sort_Descending (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      pragma Assert (Sorted_Desc_Slice (A, 1, 0));
      pragma Assert (Prefix_Geq_Suffix (A, 1, 0, 1, A'Last));

      for I in 1 .. A'Last - 1 loop
         Select_Max_Step (A, I);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Desc_Slice (A, 1, I));
         pragma Loop_Invariant (Prefix_Geq_Suffix (A, 1, I, I + 1, A'Last));
         pragma Loop_Invariant (Is_Sorted_Descending (A (1 .. I)));
      end loop;

      pragma Assert (Sorted_Desc_Slice (A, 1, A'Last - 1));
      pragma Assert (Prefix_Geq_Suffix (A, 1, A'Last - 1, A'Last, A'Last));
      pragma Assert (Is_Sorted_Descending (A));
   end Sort_Descending;

end Selection_Sort;
