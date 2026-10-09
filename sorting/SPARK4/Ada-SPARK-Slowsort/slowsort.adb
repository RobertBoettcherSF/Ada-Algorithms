--  Slowsort body: SPARK Level 4 multiply-and-surrender recursion.
--  Slowsort_Range is proved to sort its range on its own: its Post says
--  A (I .. J) is sorted (pairwise) and no element exceeds the largest
--  element the range held on entry (Max_Of, a ghost function). That
--  bound is what the surrender step needs: after the swap, A (J) is the
--  range maximum, and the recursive call on I .. J - 1 cannot bring in
--  anything larger. Subprogram_Variant (J - I) proves termination.
--  No fallback pass, no Assume, no Annotate.

package body Slowsort
  with SPARK_Mode => On
is

   --  Postconditions and assertions inside this body are proof
   --  obligations, proved by gnatprove and not evaluated at run time:
   --  Same_Occ quantifies over every Integer value. (The Post of Sort in
   --  the spec, Is_Sorted and Is_Perm, is still checked at run time under
   --  -gnata.)
   pragma Assertion_Policy (Post => Ignore, Assert => Ignore);

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

      procedure Lemma_Same_Perm (A, B : Element_Array) is null;

   end Perm_Lemmas;
   use Perm_Lemmas;

   --  Every pair in A (L .. R) is in order. Vacuous when L >= R.
   function Sorted_Pairs
     (A : Element_Array; L, R : Natural) return Boolean
   is
     (for all P in L .. R =>
        (for all Q in P .. R => A (P) <= A (Q)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= A'First
       and then R <= A'Last;

   --  Every element of A (L .. R) is at most V.
   function All_Leq
     (A : Element_Array; L, R : Natural; V : Integer) return Boolean
   is
     (for all K in L .. R => A (K) <= V)
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= A'First
       and then R <= A'Last;

   --  Largest element of A (L .. R).
   function Max_Of (A : Element_Array; L, R : Index) return Integer
   is
     (if L = R then A (L) else Integer'Max (Max_Of (A, L, R - 1), A (R)))
   with
     Ghost              => True,
     Global             => null,
     Subprogram_Variant => (Decreases => R - L),
     Pre                =>
       In_Bounds (A)
       and then L in A'Range
       and then R in L .. A'Last;

   --  Max_Of is an upper bound of its range.
   procedure Lemma_Max_Upper (A : Element_Array; L, R : Index)
     with
       Ghost              => True,
       Global             => null,
       Subprogram_Variant => (Decreases => R - L),
       Pre                =>
         In_Bounds (A)
         and then L in A'Range
         and then R in L .. A'Last,
       Post               => All_Leq (A, L, R, Max_Of (A, L, R))
   is
   begin
      if L < R then
         Lemma_Max_Upper (A, L, R - 1);
      end if;
   end Lemma_Max_Upper;

   --  Max_Of is the least upper bound: any bound of the range bounds it.
   procedure Lemma_Max_Least (A : Element_Array; L, R : Index; V : Integer)
     with
       Ghost              => True,
       Global             => null,
       Subprogram_Variant => (Decreases => R - L),
       Pre                =>
         In_Bounds (A)
         and then L in A'Range
         and then R in L .. A'Last
         and then All_Leq (A, L, R, V),
       Post               => Max_Of (A, L, R) <= V
   is
   begin
      if L < R then
         Lemma_Max_Least (A, L, R - 1, V);
      end if;
   end Lemma_Max_Least;

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

   --  Classic slowsort on A (I .. J): sort both halves, move the larger
   --  half maximum to J, then sort I .. J - 1 ("surrender").
   procedure Slowsort_Range
     (A    : in out Element_Array;
      I, J : Index)
     with
       Global             => null,
       Subprogram_Variant => (Decreases => J - I),
       Pre                =>
         In_Bounds (A)
         and then I in A'Range
         and then J in I .. A'Last,
       Post               =>
         In_Bounds (A)
         and then Sorted_Pairs (A, I, J)
         and then All_Leq (A, I, J, Max_Of (A'Old, I, J))
         and then
           (for all K in A'First .. I - 1 => A (K) = A'Old (K))
         and then
           (for all K in J + 1 .. A'Last => A (K) = A'Old (K))
         and then Same_Occ (A, A'Old)
   is
      M  : Index;
      Mx : constant Integer := Max_Of (A, I, J) with Ghost;
      A0 : constant Element_Array := A with Ghost;
      A3 : Element_Array (A'Range) with Ghost;
      A1, A2 : Element_Array (A'Range) with Ghost;
   begin
      if I >= J then
         return;
      end if;

      Lemma_Max_Upper (A, I, J);
      pragma Assert (All_Leq (A, I, J, Mx));

      --  Overflow-safe midpoint: equivalent to (I + J) / 2 for I, J in range.
      M := I + (J - I) / 2;
      pragma Assert (M in I .. J - 1);

      --  Multiply: left half.
      pragma Assert (All_Leq (A, I, M, Mx));
      Lemma_Max_Least (A, I, M, Mx);
      Slowsort_Range (A, I, M);
      A1 := A;
      pragma Assert (Same_Occ (A1, A0));
      pragma Assert (All_Leq (A, I, M, Mx));
      pragma Assert (for all K in M + 1 .. J => A (K) = A0 (K));
      pragma Assert (All_Leq (A, M + 1, J, Mx));

      --  Multiply: right half.
      Lemma_Max_Least (A, M + 1, J, Mx);
      Slowsort_Range (A, M + 1, J);
      A2 := A;
      pragma Assert (Same_Occ (A2, A1));
      pragma Assert (Same_Occ (A2, A0));
      pragma Assert (All_Leq (A, M + 1, J, Mx));
      pragma Assert (All_Leq (A, I, M, Mx));
      pragma Assert (All_Leq (A, I, J, Mx));
      pragma Assert (All_Leq (A, I, M, A (M)));
      pragma Assert (All_Leq (A, M + 1, J, A (J)));

      --  The larger half maximum goes to J.
      if A (M) > A (J) then
         Swap (A, M, J);
         Lemma_Swap (A2, A, M, J);
      end if;
      pragma Assert (Same_Occ (A, A0));
      pragma Assert (All_Leq (A, I, J, Mx));
      pragma Assert (All_Leq (A, I, J - 1, A (J)));

      --  Surrender: sort the rest; nothing above A (J) can appear.
      A3 := A;
      Lemma_Max_Least (A, I, J - 1, A (J));
      Slowsort_Range (A, I, J - 1);
      pragma Assert (Same_Occ (A, A3));
      pragma Assert (Same_Occ (A, A0));
      pragma Assert (A (J) = A3 (J));
      pragma Assert (All_Leq (A, I, J - 1, A3 (J)));
      pragma Assert (A3 (J) <= Mx);
      pragma Assert (Sorted_Pairs (A, I, J));
      pragma Assert (All_Leq (A, I, J, Mx));
   end Slowsort_Range;

   procedure Sort (A : in out Element_Array) is
      A_In : constant Element_Array := A with Ghost;
   begin
      if A'Length <= 1 then
         return;
      end if;

      Slowsort_Range (A, A'First, A'Last);
      pragma Assert (Sorted_Pairs (A, A'First, A'Last));
      Lemma_Same_Perm (A, A_In);
   end Sort;

end Slowsort;
