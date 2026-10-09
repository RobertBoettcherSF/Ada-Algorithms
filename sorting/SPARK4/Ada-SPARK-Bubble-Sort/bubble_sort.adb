--  Bubble_Sort body — SPARK Level 4 classic in-place bubble sort.
--  Outer loop shrinks the unsorted suffix; each pass bubbles the
--  maximum of the active prefix to Bound. Early exit on a swap-free
--  pass. Loop invariants track sortedness of the suffix and the
--  partition property vs. the remaining prefix.

package body Bubble_Sort
  with SPARK_Mode => On
is

   --  Loop invariants are proved by gnatprove and not re-evaluated at run
   --  time: the permutation invariants quantify over every Integer value.
   pragma Assertion_Policy (Loop_Invariant => Ignore);

   ---------------------------------------------------------------------------
   -- Permutation proof (ghost). Same_Occ is the logical multiset equality
   -- over every Integer value; it only appears in loop invariants and in
   -- lemma contracts, which are proved and not evaluated at run time (an
   -- evaluation would range over all Integer values).
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
      pragma Assertion_Policy (Pre => Ignore, Post => Ignore);

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
        (A, B : Element_Array; K : Live_Index; Last : Natural)
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
      procedure Lemma_Swap (A, B : Element_Array; X, Y : Live_Index)
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

      --  A positive count is witnessed by a slot.
      procedure Lemma_Occ_Witness (A : Element_Array; Last : Natural)
      with
        Global             => null,
        Pre                => In_Bounds (A) and then Last <= A'Last,
        Post               =>
          (for all V in Integer =>
             (if Occ (A, V, Last) > 0
              then (for some K in A'First .. Last => A (K) = V))),
        Subprogram_Variant => (Decreases => Last);

      --  The executable Is_Perm and the logical Same_Occ agree.
      procedure Lemma_Perm_Same (A, B : Element_Array)
      with
        Global => null,
        Pre    => In_Bounds (A) and then In_Bounds (B) and then Is_Perm (A, B),
        Post   => Same_Occ (A, B);

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
        (A, B : Element_Array; K : Live_Index; Last : Natural) is
      begin
         if Last > K then
            Lemma_Occ_Set (A, B, K, Last - 1);
         else
            Lemma_Occ_Frame (A, B, K - 1);
         end if;
      end Lemma_Occ_Set;

      procedure Lemma_Swap (A, B : Element_Array; X, Y : Live_Index) is
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

      procedure Lemma_Occ_Witness (A : Element_Array; Last : Natural) is
      begin
         if Last >= A'First then
            Lemma_Occ_Witness (A, Last - 1);
         end if;
      end Lemma_Occ_Witness;

      procedure Lemma_Perm_Same (A, B : Element_Array) is
      begin
         Lemma_Occ_Witness (A, A'Last);
         Lemma_Occ_Witness (B, B'Last);
      end Lemma_Perm_Same;

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

   --  One forward pass over A (A'First .. Bound): bubble the maximum of that
   --  range to index Bound via adjacent swaps. Preserves the already-
   --  sorted / partitioned suffix Bound+1 .. A'Last. Swapped is True
   --  iff at least one adjacent pair was exchanged (False ⇒ A(A'First .. Bound)
   --  was already adjacent-sorted).
   procedure Bubble_Pass
     (A       : in out Element_Array;
      Bound   : Index;
      Swapped : out Boolean)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Bound in A'First + 1 .. A'Last
         and then Sorted_Slice (A, Bound + 1, A'Last)
         and then Prefix_Leq_Suffix (A, A'First, Bound, Bound + 1, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Bound, A'Last)
         and then Prefix_Leq_Suffix (A, A'First, Bound - 1, Bound, A'Last)
         and then
           (if not Swapped then Sorted_Slice (A, A'First, Bound))
         and then Is_Perm (A, A'Old)
   is
      Orig : constant Element_Array := A with Ghost;
   begin
      Swapped := False;

      for I in A'First .. Bound - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         --  A(I) is the maximum of A(A'First .. I) so far this pass.
         pragma Loop_Invariant
           (for all K in A'First .. I => A (K) <= A (I));
         pragma Loop_Invariant (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, A'First, Bound, Bound + 1, A'Last));
         --  Suffix beyond the bubble front is unchanged this pass.
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         --  If no swaps yet, the scanned prefix is already sorted.
         pragma Loop_Invariant
           (if not Swapped then Sorted_Slice (A, A'First, I));
         pragma Loop_Invariant (Same_Occ (A, Orig));

         if A (I) > A (I + 1) then
            declare
               Before : constant Element_Array := A with Ghost;
            begin
               Swap (A, I, I + 1);
               Lemma_Swap (Before, A, I, I + 1);
            end;
            Swapped := True;
         end if;

         pragma Assert (for all K in A'First .. I + 1 => A (K) <= A (I + 1));
         pragma Assert (if not Swapped then Sorted_Slice (A, A'First, I + 1));
      end loop;

      pragma Assert (for all K in A'First .. Bound => A (K) <= A (Bound));
      pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, A'First, Bound, Bound + 1, A'Last));
      --  Max at Bound + old partition ⇒ A(Bound) <= A(Bound+1) when Bound < Last.
      pragma Assert (Bound = A'Last or else A (Bound) <= A (Bound + 1));
      pragma Assert (Sorted_Slice (A, Bound, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, A'First, Bound - 1, Bound, A'Last));
      pragma Assert (if not Swapped then Sorted_Slice (A, A'First, Bound));
      Lemma_Same_Perm (A, Orig);
   end Bubble_Pass;

   procedure Sort (A : in out Element_Array) is
      Orig    : constant Element_Array := A with Ghost;
      Bound   : Index;
      Swapped : Boolean;
   begin
      Lemma_Occ_Frame (A, Orig, A'Last);
      if A'Length <= 1 then
         Lemma_Same_Perm (A, Orig);
         return;
      end if;

      Bound := A'Last;

      pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, A'First, Bound, Bound + 1, A'Last));

      loop
         pragma Loop_Invariant (Bound in A'First + 1 .. A'Last);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, A'First, Bound, Bound + 1, A'Last));
         pragma Loop_Invariant (Same_Occ (A, Orig));
         pragma Loop_Variant (Decreases => Bound);

         declare
            Before : constant Element_Array := A with Ghost;
         begin
            Bubble_Pass (A, Bound, Swapped);
            Lemma_Perm_Same (A, Before);
         end;

         pragma Assert (Sorted_Slice (A, Bound, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, A'First, Bound - 1, Bound, A'Last));

         --  Clean pass ⇒ A(A'First .. Bound) sorted; glue onto sorted suffix.
         if not Swapped then
            pragma Assert (Sorted_Slice (A, A'First, Bound));
            pragma Assert (Sorted_Slice (A, Bound, A'Last));
            pragma Assert (Is_Sorted (A));
            Lemma_Same_Perm (A, Orig);
            return;
         end if;

         exit when Bound = A'First + 1;

         Bound := Bound - 1;

         pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, A'First, Bound, Bound + 1, A'Last));
      end loop;

      pragma Assert (Bound = A'First + 1);
      pragma Assert (Sorted_Slice (A, A'First + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, A'First, A'First, A'First + 1, A'Last));
      pragma Assert (Is_Sorted (A));
      Lemma_Same_Perm (A, Orig);
   end Sort;

end Bubble_Sort;
