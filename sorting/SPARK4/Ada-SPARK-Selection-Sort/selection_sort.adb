--  Selection_Sort body — SPARK Level 4 classic in-place selection sort.
--  Outer loop grows a sorted prefix; inner scan finds the extremum of the
--  unsorted suffix; a swap places it. Loop invariants track sortedness of
--  the prefix and the partition property vs. the remaining suffix.

package body Selection_Sort
  with SPARK_Mode => On
is

   --  Loop invariants and the Posts of the subprograms below are proved by
   --  gnatprove and not re-evaluated at run time: the permutation clauses
   --  (Same_Occ) quantify over every Integer value. The Post of the public
   --  Sort (spec) is still checked at run time, including Is_Perm.
   pragma Assertion_Policy (Loop_Invariant => Ignore, Post => Ignore);

   ---------------------------------------------------------------------------
   -- Permutation proof (ghost). Same_Occ: equal counts for every Integer.
   ---------------------------------------------------------------------------

   function Same_Occ (A, B : Element_Array) return Boolean is
     (A'First = B'First
      and then A'Last = B'Last
      and then (A'Length = 0
                or else (for all V in Integer =>
                           Occ (A, V, A'Last) = Occ (B, V, B'Last))))
   with
     Ghost,
     Global => null,
     Pre    => In_Bounds (A) and then In_Bounds (B);

   package Perm_Lemmas
     with Ghost
   is
      pragma Assertion_Policy (Pre => Ignore);

      --  Counts over A'First .. Last only see A'First .. Last.
      procedure Lemma_Occ_Frame (A, B : Element_Array; Last : Natural)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First
          and then Last <= A'Last and then Last <= B'Last
          and then (for all K in A'First .. Last => A (K) = B (K)),
        Post               =>
          (for all V in Integer => Occ (A, V, Last) = Occ (B, V, Last)),
        Subprogram_Variant => (Decreases => Last);

      --  B is A with slot K changed.
      procedure Lemma_Occ_Set
        (A, B : Element_Array; K : Positive; Last : Natural)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First and then A'Last = B'Last
          and then K in A'Range and then Last in K .. A'Last
          and then (for all J in A'Range => (if J /= K then A (J) = B (J))),
        Post               =>
          (for all V in Integer =>
             Occ (B, V, Last)
             = Occ (A, V, Last)
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

      --  Logical multiset equality gives the executable Is_Perm.
      procedure Lemma_Same_Perm (A, B : Element_Array)
      with
        Global => null,
        Pre    => In_Bounds (A) and then In_Bounds (B) and then Same_Occ (A, B),
        Post   => Is_Perm (A, B);
   end Perm_Lemmas;

   package body Perm_Lemmas is

      procedure Lemma_Occ_Frame (A, B : Element_Array; Last : Natural) is
      begin
         if Last >= A'First then
            Lemma_Occ_Frame (A, B, Last - 1);
         end if;
      end Lemma_Occ_Frame;

      procedure Lemma_Occ_Set
        (A, B : Element_Array; K : Positive; Last : Natural) is
      begin
         if Last > K then
            Lemma_Occ_Set (A, B, K, Last - 1);
         else
            Lemma_Occ_Frame (A, B, K - 1);
         end if;
      end Lemma_Occ_Set;

      procedure Lemma_Swap (A, B : Element_Array; X, Y : Positive) is
      begin
         if X = Y then
            Lemma_Occ_Frame (A, B, A'Last);
            return;
         end if;
         declare
            C : constant Element_Array := (A with delta X => A (Y));
         begin
            Lemma_Occ_Set (A, C, X, A'Last);
            Lemma_Occ_Set (C, B, Y, A'Last);
         end;
      end Lemma_Swap;

      procedure Lemma_Same_Perm (A, B : Element_Array) is null;

   end Perm_Lemmas;
   use Perm_Lemmas;

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
       and then L >= A'First
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
       and then Lo_P >= A'First
       and then Hi_P <= A'Last
       and then Lo_S >= A'First
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
       and then Lo_P >= A'First
       and then Hi_P <= A'Last
       and then Lo_S >= A'First
       and then Hi_S <= A'Last;

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
         and then Same_Occ (A, A'Old)
   is
      T : Integer;
      Before : constant Element_Array := A with Ghost;
   begin
      if X = Y then
         return;
      end if;
      T     := A (X);
      A (X) := A (Y);
      A (Y) := T;
      Lemma_Swap (Before, A, X, Y);
   end Swap;

   --  Place the minimum of A (I .. A'Last) at index I by swap.
   procedure Select_Min_Step (A : in out Element_Array; I : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then I in A'First .. A'Last - 1
         and then Sorted_Slice (A, A'First, I - 1)
         and then Prefix_Leq_Suffix (A, A'First, I - 1, I, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, A'First, I)
         and then Prefix_Leq_Suffix (A, A'First, I, I + 1, A'Last)
         and then Same_Occ (A, A'Old)
   is
      Min_Index : Index := I;
   begin
      for J in I + 1 .. A'Last loop
         pragma Loop_Invariant (Min_Index in I .. J - 1);
         pragma Loop_Invariant (Same_Occ (A, A'Loop_Entry));
         pragma Loop_Invariant
           (for all K in I .. J - 1 => A (Min_Index) <= A (K));
         pragma Loop_Invariant (Sorted_Slice (A, A'First, I - 1));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, A'First, I - 1, I, A'Last));
         pragma Loop_Invariant
           (for all K in A'Range => A (K) = A'Loop_Entry (K));

         if A (J) < A (Min_Index) then
            Min_Index := J;
         end if;
      end loop;

      pragma Assert (Min_Index in I .. A'Last);
      pragma Assert (for all K in I .. A'Last => A (Min_Index) <= A (K));
      pragma Assert (Sorted_Slice (A, A'First, I - 1));
      pragma Assert (Prefix_Leq_Suffix (A, A'First, I - 1, I, A'Last));
      --  Partition + min ⇒ A(I-1) <= A(Min_Index) when I > A'First.
      pragma Assert (I = A'First or else A (I - 1) <= A (Min_Index));

      Swap (A, I, Min_Index);

      pragma Assert (for all K in I .. A'Last => A (I) <= A (K));
      pragma Assert (I = A'First or else A (I - 1) <= A (I));
      pragma Assert (Sorted_Slice (A, A'First, I));
      pragma Assert (Prefix_Leq_Suffix (A, A'First, I, I + 1, A'Last));
   end Select_Min_Step;

   --  Place the maximum of A (I .. A'Last) at index I by swap.
   procedure Select_Max_Step (A : in out Element_Array; I : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then I in A'First .. A'Last - 1
         and then Sorted_Desc_Slice (A, A'First, I - 1)
         and then Prefix_Geq_Suffix (A, A'First, I - 1, I, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Desc_Slice (A, A'First, I)
         and then Prefix_Geq_Suffix (A, A'First, I, I + 1, A'Last)
         and then Same_Occ (A, A'Old)
   is
      Max_Index : Index := I;
   begin
      for J in I + 1 .. A'Last loop
         pragma Loop_Invariant (Max_Index in I .. J - 1);
         pragma Loop_Invariant (Same_Occ (A, A'Loop_Entry));
         pragma Loop_Invariant
           (for all K in I .. J - 1 => A (Max_Index) >= A (K));
         pragma Loop_Invariant (Sorted_Desc_Slice (A, A'First, I - 1));
         pragma Loop_Invariant
           (Prefix_Geq_Suffix (A, A'First, I - 1, I, A'Last));
         pragma Loop_Invariant
           (for all K in A'Range => A (K) = A'Loop_Entry (K));

         if A (J) > A (Max_Index) then
            Max_Index := J;
         end if;
      end loop;

      pragma Assert (Max_Index in I .. A'Last);
      pragma Assert (for all K in I .. A'Last => A (Max_Index) >= A (K));
      pragma Assert (Sorted_Desc_Slice (A, A'First, I - 1));
      pragma Assert (Prefix_Geq_Suffix (A, A'First, I - 1, I, A'Last));
      pragma Assert (I = A'First or else A (I - 1) >= A (Max_Index));

      Swap (A, I, Max_Index);

      pragma Assert (for all K in I .. A'Last => A (I) >= A (K));
      pragma Assert (I = A'First or else A (I - 1) >= A (I));
      pragma Assert (Sorted_Desc_Slice (A, A'First, I));
      pragma Assert (Prefix_Geq_Suffix (A, A'First, I, I + 1, A'Last));
   end Select_Max_Step;

   procedure Sort (A : in out Element_Array) is
      Orig : constant Element_Array := A with Ghost;
   begin
      if A'Length <= 1 then
         Lemma_Occ_Frame (A, Orig, A'Last);
         Lemma_Same_Perm (A, Orig);
         return;
      end if;

      pragma Assert (Sorted_Slice (A, A'First, A'First - 1));
      pragma Assert (Prefix_Leq_Suffix (A, A'First, A'First - 1, A'First, A'Last));

      for I in A'First .. A'Last - 1 loop
         Select_Min_Step (A, I);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, A'First, I));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, A'First, I, I + 1, A'Last));
         pragma Loop_Invariant (Is_Sorted (A (A'First .. I)));
         pragma Loop_Invariant (Same_Occ (A, Orig));
      end loop;

      pragma Assert (Sorted_Slice (A, A'First, A'Last - 1));
      pragma Assert (Prefix_Leq_Suffix (A, A'First, A'Last - 1, A'Last, A'Last));
      pragma Assert (Is_Sorted (A));
      Lemma_Same_Perm (A, Orig);
   end Sort;

   procedure Sort_Descending (A : in out Element_Array) is
      Orig : constant Element_Array := A with Ghost;
   begin
      if A'Length <= 1 then
         Lemma_Occ_Frame (A, Orig, A'Last);
         Lemma_Same_Perm (A, Orig);
         return;
      end if;

      pragma Assert (Sorted_Desc_Slice (A, A'First, A'First - 1));
      pragma Assert (Prefix_Geq_Suffix (A, A'First, A'First - 1, A'First, A'Last));

      for I in A'First .. A'Last - 1 loop
         Select_Max_Step (A, I);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Desc_Slice (A, A'First, I));
         pragma Loop_Invariant (Prefix_Geq_Suffix (A, A'First, I, I + 1, A'Last));
         pragma Loop_Invariant (Is_Sorted_Descending (A (A'First .. I)));
         pragma Loop_Invariant (Same_Occ (A, Orig));
      end loop;

      pragma Assert (Sorted_Desc_Slice (A, A'First, A'Last - 1));
      pragma Assert (Prefix_Geq_Suffix (A, A'First, A'Last - 1, A'Last, A'Last));
      pragma Assert (Is_Sorted_Descending (A));
      Lemma_Same_Perm (A, Orig);
   end Sort_Descending;

end Selection_Sort;
