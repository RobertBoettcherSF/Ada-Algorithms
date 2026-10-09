--  Insertion_Sort body — SPARK Level 4 classic stable in-place insertion
--  sort. Outer loop grows a sorted prefix; inner shift loop opens a hole
--  for Key. Loop invariants track sortedness of the active prefix.

package body Insertion_Sort
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
      --  Counts equal to a common A are equal to each other.
      procedure Lemma_Occ_Chain (A, B, C : Element_Array)
      with
        Global => null,
        Pre    =>
          In_Bounds (A) and then In_Bounds (B) and then In_Bounds (C)
          and then Same_Occ (A, B) and then Same_Occ (A, C),
        Post   => Same_Occ (B, C);
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

      procedure Lemma_Occ_Chain (A, B, C : Element_Array) is null;

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

   --  Insert A(I) into the sorted prefix A(A'First .. I-1), yielding
   --  sorted A(A'First .. I). Strict Key < A(J-1) keeps equal-key order (stable).
   procedure Insert_Step (A : in out Element_Array; I : Index)
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
      Key  : constant Integer := A (I);
      J    : Index := I;
      Orig : constant Element_Array := A with Ghost;
      --  Hole view: A with Key at the hole J. It has the counts of A'Old.
      H    : Element_Array := A with Ghost;
   begin
      Lemma_Occ_Frame (H, Orig, A'Last);
      --  Shift strictly larger predecessors one slot right.
      --  Hole sits at J: A(A'First .. J-1) untouched sorted prefix; A(J+1 .. I)
      --  are the shifted values (all > Key, sorted); A(J) duplicates
      --  A(J+1) when J < I (or still equals Key when J = I).
      while J > A'First and then Key < A (J - 1) loop
         pragma Loop_Invariant (J in A'First + 1 .. I);
         pragma Loop_Invariant (Sorted_Slice (A, A'First, J - 1));
         pragma Loop_Invariant (Sorted_Slice (A, J + 1, I));
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (K) > Key);
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (J - 1) <= A (K));
         pragma Loop_Invariant
           (if J < I then A (J) = A (J + 1) else A (J) = Key);
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in A'Range => H (K) = (if K = J then Key else A (K)));
         pragma Loop_Invariant (Same_Occ (H, Orig));
         pragma Loop_Variant (Decreases => J);

         declare
            Prev : constant Element_Array := H with Ghost;
         begin
            A (J) := A (J - 1);
            J     := J - 1;
            H (J + 1) := A (J + 1);
            H (J)     := Key;
            Lemma_Swap (Prev, H, J, J + 1);
            Lemma_Occ_Chain (Prev, H, Orig);
         end;
      end loop;

      pragma Assert (J in A'First .. I);
      pragma Assert (Sorted_Slice (A, A'First, J - 1));
      pragma Assert (Sorted_Slice (A, J + 1, I));
      pragma Assert (for all K in J + 1 .. I => A (K) > Key);
      pragma Assert (J = A'First or else A (J - 1) <= Key);

      A (J) := Key;
      pragma Assert (for all K in A'Range => H (K) = A (K));
      Lemma_Occ_Frame (H, A, A'Last);
      Lemma_Occ_Chain (H, A, Orig);

      --  Glue left | Key | right into one adjacent-sorted prefix.
      pragma Assert (if J > A'First then A (J - 1) <= A (J));
      pragma Assert (if J < I then A (J) <= A (J + 1));
      pragma Assert (Sorted_Slice (A, A'First, I));
   end Insert_Step;

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
         Insert_Step (A, I);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Same_Occ (A, Orig));
         pragma Loop_Invariant (Sorted_Slice (A, A'First, I));
         pragma Loop_Invariant (Is_Sorted (A (A'First .. I)));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last =>
              A (K) = A'Loop_Entry (K));
      end loop;
      Lemma_Same_Perm (A, Orig);
   end Sort;

end Insertion_Sort;
