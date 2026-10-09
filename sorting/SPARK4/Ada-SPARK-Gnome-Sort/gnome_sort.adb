--  Gnome_Sort body — SPARK Level 4 classic gnome / stupid sort.
--  Outer loop grows a sorted prefix; inner gnome step bubbles A(I) left
--  by adjacent swaps (strict `<` so equals keep relative order). Loop
--  invariants track sortedness of the active prefix; Loop_Variant on Pos.

package body Gnome_Sort
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
      --  The logical Same_Occ gives the executable Is_Perm.
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

   --  Bubble A(I) left into the sorted prefix A(A'First .. I-1) by adjacent
   --  swaps, yielding sorted A(A'First .. I). Strict A(Pos) < A(Pos-1) keeps
   --  equal-key order (stable-ish gnome advance on >=).
   procedure Gnome_Step (A : in out Element_Array; I : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then I in A'First + 1 .. A'Last
         and then Sorted_Slice (A, A'First, I - 1),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, A'First, I)
         and then (for all K in I + 1 .. A'Last => A (K) = A'Old (K))
         and then Same_Occ (A, A'Old)
   is
      Pos : Index := I;
   begin
      --  Key sits at Pos. Left of Pos is sorted; right of Pos up to I
      --  are the bumped predecessors (all > Key, sorted).
      while Pos > A'First and then A (Pos) < A (Pos - 1) loop
         pragma Loop_Invariant (Pos in A'First + 1 .. I);
         pragma Loop_Invariant (Same_Occ (A, A'Loop_Entry));
         pragma Loop_Invariant (Sorted_Slice (A, A'First, Pos - 1));
         pragma Loop_Invariant (Sorted_Slice (A, Pos + 1, I));
         pragma Loop_Invariant
           (for all K in Pos + 1 .. I => A (K) > A (Pos));
         pragma Loop_Invariant
           (for all K in Pos + 1 .. I => A (Pos - 1) <= A (K));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Decreases => Pos);

         Swap (A, Pos, Pos - 1);
         Pos := Pos - 1;
      end loop;

      pragma Assert (Pos in A'First .. I);
      pragma Assert (Sorted_Slice (A, A'First, Pos - 1));
      pragma Assert (Sorted_Slice (A, Pos + 1, I));
      pragma Assert (for all K in Pos + 1 .. I => A (K) > A (Pos));
      pragma Assert (Pos = A'First or else A (Pos - 1) <= A (Pos));
      pragma Assert (if Pos > A'First then A (Pos - 1) <= A (Pos));
      pragma Assert (if Pos < I then A (Pos) <= A (Pos + 1));
      pragma Assert (Sorted_Slice (A, A'First, I));
   end Gnome_Step;

   procedure Sort (A : in out Element_Array) is
      Orig : constant Element_Array := A with Ghost;
   begin
      if A'Length <= 1 then
         Lemma_Occ_Frame (A, Orig, A'Last);
         Lemma_Same_Perm (A, Orig);
         return;
      end if;

      pragma Assert (Sorted_Slice (A, A'First, A'First));

      for I in A'First + 1 .. A'Last loop
         Gnome_Step (A, I);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, A'First, I));
         pragma Loop_Invariant (Is_Sorted (A (A'First .. I)));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last =>
              A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant (Same_Occ (A, Orig));
      end loop;
      Lemma_Same_Perm (A, Orig);
   end Sort;

end Gnome_Sort;
