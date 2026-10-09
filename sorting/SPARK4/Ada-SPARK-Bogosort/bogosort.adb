--  Bogosort body — bounded random-shuffle bogosort. Shuffle proves the
--  permutation (ghost Occ counts, one Lemma_Swap per exchange); Sort
--  loops while not sorted and under Budget, then reports the outcome.

package body Bogosort
  with SPARK_Mode => On
is

   --  Loop invariants and the Posts of the subprograms below are proved by
   --  gnatprove and not re-evaluated at run time: the permutation clauses
   --  (Same_Occ) quantify over every Integer value. The Post of the public
   --  Sort (spec) is still checked at run time, including Is_Perm.
   pragma Assertion_Policy (Loop_Invariant => Ignore, Post => Ignore);

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

   --  One generator step; Draw in 0 .. Bound - 1.
   procedure Next (Seed : in out Seed_Type; Bound : Positive; Draw : out Natural)
     with
       Global => null,
       Pre    => Bound <= Max_N,
       Post   => Draw < Bound
   is
   begin
      Seed := Seed * 1_664_525 + 1_013_904_223;
      Draw := Natural ((Seed / 2 ** 16) mod Seed_Type (Bound));
   end Next;

   --  Fisher-Yates from the right.
   procedure Shuffle (A : in out Element_Array; Seed : in out Seed_Type)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Same_Occ (A'Old, A)
   is
      Orig : constant Element_Array := A with Ghost;
      D    : Natural;
      J    : Positive;
   begin
      if A'Length > 0 then
         Lemma_Occ_Frame (A, Orig, A'Last);
      end if;
      if A'Length <= 1 then
         return;
      end if;
      for I in reverse A'First + 1 .. A'Last loop
         pragma Loop_Invariant (Same_Occ (Orig, A));
         Next (Seed, I - A'First + 1, D);
         J := A'First + D;
         declare
            Before : constant Element_Array := A with Ghost;
            T      : constant Integer := A (I);
         begin
            A (I) := A (J);
            A (J) := T;
            Lemma_Swap (Before, A, I, J);
            Lemma_Occ_Chain (Before, Orig, A);
         end;
      end loop;
   end Shuffle;

   procedure Sort
     (A        : in out Element_Array;
      Seed     : in out Seed_Type;
      Result   : out Outcome;
      Shuffles : out Natural;
      Budget   : Shuffle_Count := Max_Shuffles)
   is
      Orig : constant Element_Array := A with Ghost;
   begin
      Shuffles := 0;
      if A'Length > 0 then
         Lemma_Occ_Frame (A, Orig, A'Last);
      end if;
      while not Is_Sorted (A) and then Shuffles < Budget loop
         pragma Loop_Invariant (Shuffles < Budget);
         pragma Loop_Invariant (Same_Occ (Orig, A));
         pragma Loop_Variant (Increases => Shuffles);
         declare
            Before : constant Element_Array := A with Ghost;
         begin
            Shuffle (A, Seed);
            Lemma_Occ_Chain (Before, Orig, A);
         end;
         Shuffles := Shuffles + 1;
      end loop;
      Result := (if Is_Sorted (A) then Sorted else Gave_Up);
      Lemma_Occ_Chain (Orig, A, Orig);
      Lemma_Same_Perm (A, Orig);
   end Sort;

end Bogosort;
