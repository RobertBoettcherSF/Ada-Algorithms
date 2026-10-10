--  Timsort body — SPARK Level 4 educational hybrid: Minrun-aligned
--  natural runs + insertion extend, then bottom-up stable merge via
--  fixed Temp. Loop invariants track Sorted_Runs so Width ≥ N yields
--  Is_Sorted. Zero Intentional Annotate.

package body Timsort
  with SPARK_Mode => On
is

   --  Cursor one past the live range (drain / end-of-run sentinels).
   subtype Cursor is Natural range 0 .. Max_N + 1;

   --  Same_Occ quantifies over every Integer value, so the contracts,
   --  invariants and assertions of this body (all proved by gnatprove) are
   --  not checked at run time; the Post of Sort in the spec (sorted,
   --  Is_Perm) still is.
   pragma Assertion_Policy
     (Pre => Ignore, Post => Ignore, Loop_Invariant => Ignore, Assert => Ignore);

   --  A and B have the same bounds and every value occurs equally often.
   function Same_Occ (A, B : Element_Array) return Boolean is
     (A'First = B'First
      and then A'Last = B'Last
      and then (for all V in Integer =>
                  Occ (A, V, A'First, A'Last) = Occ (B, V, B'First, B'Last)))
   with
     Ghost,
     Global => null,
     Pre    => In_Bounds (A) and then In_Bounds (B);

   package Perm_Lemmas
     with Ghost
   is
      --  Counts over First .. Last only see First .. Last.
      procedure Lemma_Occ_Eq (A, B : Element_Array; First : Positive; Last : Natural)
      with
        Global             => null,
        Pre                =>
          (if First <= Last then
             First >= A'First and then Last <= A'Last
             and then First >= B'First and then Last <= B'Last
             and then (for all T in First .. Last => A (T) = B (T))),
        Post               =>
          (for all V in Integer =>
             Occ (A, V, First, Last) = Occ (B, V, First, Last)),
        Subprogram_Variant => (Decreases => Last);

      --  Counts over First .. Last split at Mid.
      procedure Lemma_Occ_Split
        (A : Element_Array; First : Positive; Mid, Last : Natural)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A)
          and then First >= A'First and then Last <= A'Last
          and then Mid <= Last and then First <= Mid + 1,
        Post               =>
          (for all V in Integer =>
             Occ (A, V, First, Last)
             = Occ (A, V, First, Mid) + Occ (A, V, Mid + 1, Last)),
        Subprogram_Variant => (Decreases => Last);

      --  The executable Is_Perm and the logical Same_Occ agree.
      procedure Lemma_Same_Perm (A, B : Element_Array)
      with
        Global => null,
        Pre    => In_Bounds (A) and then In_Bounds (B) and then Same_Occ (A, B),
        Post   => Is_Perm (A, B);

      procedure Lemma_Same_Trans (A, B, C : Element_Array)
      with
        Global => null,
        Pre    =>
          In_Bounds (A) and then In_Bounds (B) and then In_Bounds (C)
          and then Same_Occ (A, B) and then Same_Occ (B, C),
        Post   => Same_Occ (A, C);

      --  B is A with slot K changed.
      procedure Lemma_Occ_Set
        (A, B : Element_Array; K : Positive; First : Positive; Last : Natural)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First and then A'Last = B'Last
          and then K in First .. Last
          and then First >= A'First and then Last <= A'Last
          and then (for all J in A'Range => (if J /= K then A (J) = B (J))),
        Post               =>
          (for all V in Integer =>
             Occ (B, V, First, Last)
             = Occ (A, V, First, Last)
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
   end Perm_Lemmas;

   package body Perm_Lemmas is

      procedure Lemma_Occ_Eq (A, B : Element_Array; First : Positive; Last : Natural) is
      begin
         if First <= Last then
            Lemma_Occ_Eq (A, B, First, Last - 1);
         end if;
      end Lemma_Occ_Eq;

      procedure Lemma_Occ_Split
        (A : Element_Array; First : Positive; Mid, Last : Natural) is
      begin
         if Mid < Last then
            Lemma_Occ_Split (A, First, Mid, Last - 1);
         end if;
      end Lemma_Occ_Split;

      procedure Lemma_Occ_Set
        (A, B : Element_Array; K : Positive; First : Positive; Last : Natural) is
      begin
         if Last > K then
            Lemma_Occ_Set (A, B, K, First, Last - 1);
         else
            Lemma_Occ_Eq (A, B, First, K - 1);
         end if;
      end Lemma_Occ_Set;

      procedure Lemma_Swap (A, B : Element_Array; X, Y : Positive) is
      begin
         if X = Y then
            Lemma_Occ_Eq (A, B, A'First, A'Last);
            return;
         end if;
         declare
            C : constant Element_Array := (A with delta X => A (Y));
         begin
            Lemma_Occ_Set (A, C, X, A'First, A'Last);
            Lemma_Occ_Set (C, B, Y, A'First, A'Last);
         end;
      end Lemma_Swap;

      procedure Lemma_Same_Perm (A, B : Element_Array) is null;

      procedure Lemma_Same_Trans (A, B, C : Element_Array) is null;

   end Perm_Lemmas;
   use Perm_Lemmas;

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
         and then Same_Occ (A'Old, A)
   is
      T  : Integer;
      A0 : constant Element_Array := A with Ghost;
   begin
      T     := A (X);
      A (X) := A (Y);
      A (Y) := T;
      Lemma_Swap (A0, A, X, Y);
   end Swap;

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

   --  Every adjacent pair inside the same Width-aligned run is ordered.
   --  Vacuous for Width = 1. When Width >= A'Last, equivalent to Is_Sorted.
   function Sorted_Runs
     (A : Element_Array; Width : Positive) return Boolean
   is
     (for all K in 1 .. A'Last - 1 =>
        (if (K - 1) / Width = K / Width then A (K) <= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    => In_Bounds (A) and then Width <= Max_N;

   function Sorted_Runs_Prefix
     (A : Element_Array; Width : Positive; Bound : Natural) return Boolean
   is
     (for all K in 1 .. A'Last - 1 =>
        (if K < Bound
           and then (K - 1) / Width = K / Width
         then A (K) <= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Width <= Max_N
       and then Bound <= A'Last;

   function Sorted_Runs_Suffix
     (A : Element_Array; Width : Positive; Lo : Natural) return Boolean
   is
     (for all K in 1 .. A'Last - 1 =>
        (if K >= Lo
           and then (K - 1) / Width = K / Width
         then A (K) <= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Width <= Max_N
       and then Lo >= 1
       and then Lo <= A'Last + 1;

   procedure Lemma_Slice_To_Prefix
     (A : Element_Array; Width : Positive; Lo, Hi : Index)
     with
       Ghost             => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Width <= Max_N
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last
         and then (Lo - 1) rem Width = 0
         and then Hi = Natural'Min (Lo + Width - 1, A'Last)
         and then Sorted_Slice (A, Lo, Hi)
         and then Sorted_Runs_Prefix (A, Width, Lo - 1),
       Post              => Sorted_Runs_Prefix (A, Width, Hi)
   is
   begin
      pragma Assert (Sorted_Runs_Prefix (A, Width, Hi));
   end Lemma_Slice_To_Prefix;

   procedure Lemma_Runs_To_Slice
     (A : Element_Array; Width : Positive; Lo : Index)
     with
       Ghost             => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Width <= Max_N
         and then Lo in 1 .. A'Last
         and then (Lo - 1) rem Width = 0
         and then Sorted_Runs_Suffix (A, Width, Lo),
       Post              =>
         Sorted_Slice (A, Lo, Natural'Min (Lo + Width - 1, A'Last))
   is
      Hi : constant Natural := Natural'Min (Lo + Width - 1, A'Last);
   begin
      pragma Assert
        (for all K in Lo .. Hi - 1 =>
           (K - 1) / Width = K / Width);
      pragma Assert (Sorted_Slice (A, Lo, Hi));
   end Lemma_Runs_To_Slice;

   ---------------------------------------------------------------------------
   -- Insertion into a sorted slice prefix (stable: strict Key < A(J-1))
   ---------------------------------------------------------------------------

   procedure Insert_At
     (A : in out Element_Array; Lo, I : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then I in Lo + 1 .. A'Last
         and then Sorted_Slice (A, Lo, I - 1),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, I)
         and then (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then (for all K in I + 1 .. A'Last => A (K) = A'Old (K))
         and then Same_Occ (A'Old, A)
   is
      Key  : constant Integer := A (I);
      J    : Index := I;
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      --  Insertion by adjacent exchanges: Key moves down past every
      --  larger neighbour (same comparisons as shifting).
      while J > Lo and then Key < A (J - 1) loop
         pragma Loop_Invariant (J in Lo + 1 .. I);
         pragma Loop_Invariant (A (J) = Key);
         pragma Loop_Invariant (Sorted_Slice (A, Lo, J - 1));
         pragma Loop_Invariant (Sorted_Slice (A, J + 1, I));
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (K) > Key);
         pragma Loop_Invariant
           (if J < I and then J > Lo then A (J - 1) <= A (J + 1));
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Variant (Decreases => J);

         Prev := A;
         Swap (A, J - 1, J);
         Lemma_Same_Trans (A0, Prev, A);
         J := J - 1;
      end loop;

      pragma Assert (J in Lo .. I);
      pragma Assert (Sorted_Slice (A, Lo, J - 1));
      pragma Assert (Sorted_Slice (A, J + 1, I));
      pragma Assert (for all K in J + 1 .. I => A (K) > Key);
      pragma Assert (J = Lo or else A (J - 1) <= Key);
      pragma Assert (A (J) = Key);

      pragma Assert (if J > Lo then A (J - 1) <= A (J));
      pragma Assert (if J < I then A (J) <= A (J + 1));
      pragma Assert (Sorted_Slice (A, Lo, I));
   end Insert_At;

   --  Extend sorted A(Lo .. Sorted_Last) by inserting through Hi.
   procedure Insertion_Extend
     (A : in out Element_Array; Lo, Sorted_Last, Hi : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Sorted_Last in Lo .. A'Last
         and then Hi in Sorted_Last .. A'Last
         and then Sorted_Slice (A, Lo, Sorted_Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, Hi)
         and then (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
         and then Same_Occ (A'Old, A)
   is
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      if Sorted_Last >= Hi then
         pragma Assert (Sorted_Slice (A, Lo, Hi));
         return;
      end if;

      for I in Sorted_Last + 1 .. Hi loop
         Prev := A;
         Insert_At (A, Lo, I);
         Lemma_Same_Trans (A0, Prev, A);
         pragma Loop_Invariant (Same_Occ (A0, A));

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, Lo, I));
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Last => A (K) = A'Loop_Entry (K));
      end loop;
   end Insertion_Extend;

   ---------------------------------------------------------------------------
   -- Reverse a slice (used on strictly descending natural runs)
   ---------------------------------------------------------------------------

   procedure Reverse_Range
     (A : in out Element_Array; Lo, Hi : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last,
       Post   =>
         In_Bounds (A)
         and then (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
         and then Same_Occ (A'Old, A)
   is
      I    : Index := Lo;
      J    : Index := Hi;
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      while I < J loop
         pragma Loop_Invariant (I in Lo .. Hi);
         pragma Loop_Invariant (J in Lo .. Hi);
         pragma Loop_Invariant (I + J = Lo + Hi);
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Variant (Decreases => J - I);

         Prev := A;
         Swap (A, I, J);
         Lemma_Same_Trans (A0, Prev, A);
         I := I + 1;
         J := J - 1;
      end loop;
   end Reverse_Range;

   ---------------------------------------------------------------------------
   -- Prepare one Minrun-aligned window: natural run + insertion extend
   ---------------------------------------------------------------------------

   procedure Prepare_Block
     (A : in out Element_Array; Lo, Hi : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last,
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, Hi)
         and then (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
         and then Same_Occ (A'Old, A)
   is
      Run_Hi : Index;
      A0     : constant Element_Array := A with Ghost;
      Prev   : Element_Array (A'Range) with Ghost;
   begin
      if Lo = Hi then
         pragma Assert (Sorted_Slice (A, Lo, Hi));
         return;
      end if;

      if A (Lo) <= A (Lo + 1) then
         --  Nondecreasing natural run bounded by Hi.
         Run_Hi := Lo;
         while Run_Hi < Hi and then A (Run_Hi) <= A (Run_Hi + 1) loop
            pragma Loop_Invariant (Run_Hi in Lo .. Hi - 1);
            pragma Loop_Invariant (Sorted_Slice (A, Lo, Run_Hi));
            pragma Loop_Invariant
              (for all K in Lo .. Run_Hi =>
                 A (K) = A'Loop_Entry (K));
            pragma Loop_Variant (Decreases => Hi - Run_Hi);

            Run_Hi := Run_Hi + 1;
         end loop;
         pragma Assert (Sorted_Slice (A, Lo, Run_Hi));
      else
         --  Strictly descending natural run; reverse, then re-establish
         --  sortedness of the reversed slice via insertion (avoids a
         --  delicate reverse-sortedness lemma at Level 4).
         Run_Hi := Lo;
         while Run_Hi < Hi and then A (Run_Hi) > A (Run_Hi + 1) loop
            pragma Loop_Invariant (Run_Hi in Lo .. Hi - 1);
            pragma Loop_Invariant
              (for all K in Lo .. Run_Hi =>
                 A (K) = A'Loop_Entry (K));
            pragma Loop_Variant (Decreases => Hi - Run_Hi);

            Run_Hi := Run_Hi + 1;
         end loop;
         Prev := A;
         Reverse_Range (A, Lo, Run_Hi);
         Lemma_Same_Trans (A0, Prev, A);
         --  Only the first element is known sorted after reverse without
         --  a descending-order ghost; insertion-sort the reversed slice.
         pragma Assert (Sorted_Slice (A, Lo, Lo));
         Prev := A;
         Insertion_Extend (A, Lo, Lo, Run_Hi);
         Lemma_Same_Trans (A0, Prev, A);
         pragma Assert (Sorted_Slice (A, Lo, Run_Hi));
      end if;

      pragma Assert (Same_Occ (A0, A));
      Prev := A;
      Insertion_Extend (A, Lo, Run_Hi, Hi);
      Lemma_Same_Trans (A0, Prev, A);
      pragma Assert (Sorted_Slice (A, Lo, Hi));
   end Prepare_Block;

   --  Cover A with Minrun-aligned prepared blocks → Sorted_Runs (A, Minrun)
   --  or Is_Sorted when N ≤ Minrun.
   procedure Make_Initial_Runs (A : in out Element_Array)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 1,
       Post   =>
         In_Bounds (A)
         and then
           (if A'Last <= Minrun then Is_Sorted (A)
            else Sorted_Runs (A, Minrun))
         and then Same_Occ (A'Old, A)
   is
      N    : constant Index := A'Last;
      Lo   : Index := 1;
      Hi   : Index;
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      pragma Assert (Sorted_Runs_Prefix (A, Minrun, 0));

      while Lo <= N loop
         pragma Loop_Invariant (Lo in 1 .. N + 1);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (Lo = N + 1 or else (Lo - 1) rem Minrun = 0);
         pragma Loop_Invariant
           (Sorted_Runs_Prefix (A, Minrun, Lo - 1));
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Variant (Decreases => N + 1 - Lo);

         Hi := Natural'Min (Lo + Minrun - 1, N);
         Prev := A;
         Prepare_Block (A, Lo, Hi);
         Lemma_Same_Trans (A0, Prev, A);
         pragma Assert (Sorted_Slice (A, Lo, Hi));
         pragma Assert (Sorted_Runs_Prefix (A, Minrun, Lo - 1));
         Lemma_Slice_To_Prefix (A, Minrun, Lo, Hi);
         pragma Assert (Sorted_Runs_Prefix (A, Minrun, Hi));

         exit when Hi = N;
         Lo := Hi + 1;
      end loop;

      pragma Assert (Sorted_Runs_Prefix (A, Minrun, N));
      pragma Assert (Sorted_Runs (A, Minrun));
      pragma Assert
        (if N <= Minrun then Is_Sorted (A));
   end Make_Initial_Runs;

   ---------------------------------------------------------------------------
   -- Stable merge (prefer Left on ties) — same contracts as Merge_Sort
   ---------------------------------------------------------------------------

   procedure Merge
     (A           : in out Element_Array;
      Temp        : in out Element_Array;
      Lo, Mid, Hi : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then Temp'First = 1
         and then Temp'Last = Max_N
         and then Lo in 1 .. A'Last
         and then Hi in Lo + 1 .. A'Last
         and then Mid in Lo .. Hi - 1
         and then Sorted_Slice (A, Lo, Mid)
         and then Sorted_Slice (A, Mid + 1, Hi),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, Hi)
         and then
           (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then
           (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
         and then Same_Occ (A'Old, A)
   is
      I    : Cursor := Lo;
      J    : Cursor := Mid + 1;
      K    : Cursor := Lo;
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (Temp'Range) with Ghost;
   begin
      while I <= Mid and then J <= Hi loop
         pragma Loop_Invariant (I in Lo .. Mid);
         pragma Loop_Invariant (J in Mid + 1 .. Hi);
         pragma Loop_Invariant
           (K = Lo + (I - Lo) + (J - (Mid + 1)));
         pragma Loop_Invariant (K in Lo .. Hi);
         pragma Loop_Invariant
           (for all T in Lo .. Mid => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant
           (for all T in Mid + 1 .. Hi => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant
           (for all T in 1 .. Lo - 1 => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant
           (for all T in Hi + 1 .. A'Last => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant
           (if K > Lo then Sorted_Slice (Temp, Lo, K - 1));
         pragma Loop_Invariant
           (if K > Lo then Temp (K - 1) <= A (I));
         pragma Loop_Invariant
           (if K > Lo then Temp (K - 1) <= A (J));
         pragma Loop_Invariant (Sorted_Slice (A, I, Mid));
         pragma Loop_Invariant (Sorted_Slice (A, J, Hi));
         pragma Loop_Invariant
           (for all V in Integer =>
              Occ (Temp, V, Lo, K - 1)
              = Occ (A, V, Lo, I - 1) + Occ (A, V, Mid + 1, J - 1));
         pragma Loop_Variant (Decreases => (Mid - I + 1) + (Hi - J + 1));

         Prev := Temp;
         if A (I) <= A (J) then
            Temp (K) := A (I);
            pragma Assert (if K > Lo then Temp (K - 1) <= Temp (K));
            I := I + 1;
         else
            Temp (K) := A (J);
            pragma Assert (if K > Lo then Temp (K - 1) <= Temp (K));
            J := J + 1;
         end if;
         Lemma_Occ_Eq (Prev, Temp, Lo, K - 1);
         K := K + 1;
      end loop;

      while I <= Mid loop
         pragma Loop_Invariant (I in Lo .. Mid);
         pragma Loop_Invariant (J = Hi + 1);
         pragma Loop_Invariant
           (K = Lo + (I - Lo) + (J - (Mid + 1)));
         pragma Loop_Invariant (K in Lo .. Hi);
         pragma Loop_Invariant
           (for all T in Lo .. Mid => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant
           (for all T in Mid + 1 .. Hi => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant
           (for all T in 1 .. Lo - 1 => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant
           (for all T in Hi + 1 .. A'Last => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant (K > Lo);
         pragma Loop_Invariant (Sorted_Slice (Temp, Lo, K - 1));
         pragma Loop_Invariant (Temp (K - 1) <= A (I));
         pragma Loop_Invariant (Sorted_Slice (A, I, Mid));
         pragma Loop_Invariant
           (for all V in Integer =>
              Occ (Temp, V, Lo, K - 1)
              = Occ (A, V, Lo, I - 1) + Occ (A, V, Mid + 1, J - 1));
         pragma Loop_Variant (Decreases => Mid - I + 1);

         Prev := Temp;
         Temp (K) := A (I);
         pragma Assert (Temp (K - 1) <= Temp (K));
         Lemma_Occ_Eq (Prev, Temp, Lo, K - 1);
         I := I + 1;
         K := K + 1;
      end loop;

      while J <= Hi loop
         pragma Loop_Invariant (J in Mid + 1 .. Hi);
         pragma Loop_Invariant (I = Mid + 1);
         pragma Loop_Invariant
           (K = Lo + (I - Lo) + (J - (Mid + 1)));
         pragma Loop_Invariant (K in Lo .. Hi);
         pragma Loop_Invariant
           (for all T in Lo .. Mid => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant
           (for all T in Mid + 1 .. Hi => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant
           (for all T in 1 .. Lo - 1 => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant
           (for all T in Hi + 1 .. A'Last => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant (K > Lo);
         pragma Loop_Invariant (Sorted_Slice (Temp, Lo, K - 1));
         pragma Loop_Invariant (Temp (K - 1) <= A (J));
         pragma Loop_Invariant (Sorted_Slice (A, J, Hi));
         pragma Loop_Invariant
           (for all V in Integer =>
              Occ (Temp, V, Lo, K - 1)
              = Occ (A, V, Lo, I - 1) + Occ (A, V, Mid + 1, J - 1));
         pragma Loop_Variant (Decreases => Hi - J + 1);

         Prev := Temp;
         Temp (K) := A (J);
         pragma Assert (Temp (K - 1) <= Temp (K));
         Lemma_Occ_Eq (Prev, Temp, Lo, K - 1);
         J := J + 1;
         K := K + 1;
      end loop;

      pragma Assert (K = Hi + 1);
      pragma Assert (Sorted_Slice (Temp, Lo, Hi));
      Lemma_Occ_Split (A, Lo, Mid, Hi);
      pragma Assert
        (for all V in Integer =>
           Occ (Temp, V, Lo, Hi) = Occ (A, V, Lo, Hi));
      Lemma_Occ_Eq (A, A0, Lo, Hi);
      pragma Assert
        (for all V in Integer =>
           Occ (Temp, V, Lo, Hi) = Occ (A0, V, Lo, Hi));

      for X in Lo .. Hi loop
         pragma Loop_Invariant
           (for all T in Lo .. X - 1 => A (T) = Temp (T));
         pragma Loop_Invariant
           (for all T in X .. Hi => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant
           (for all T in 1 .. Lo - 1 => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant
           (for all T in Hi + 1 .. A'Last => A (T) = A'Loop_Entry (T));
         pragma Loop_Invariant (Sorted_Slice (Temp, Lo, Hi));

         A (X) := Temp (X);
      end loop;

      pragma Assert (for all T in Lo .. Hi => A (T) = Temp (T));
      pragma Assert (Sorted_Slice (A, Lo, Hi));

      --  Counts: outer parts unchanged, Lo .. Hi now holds Temp.
      Lemma_Occ_Eq (A, Temp, Lo, Hi);
      Lemma_Occ_Eq (A, A0, A'First, Lo - 1);
      Lemma_Occ_Eq (A, A0, Hi + 1, A'Last);
      Lemma_Occ_Split (A, A'First, Hi, A'Last);
      Lemma_Occ_Split (A, A'First, Lo - 1, Hi);
      Lemma_Occ_Split (A0, A'First, Hi, A'Last);
      Lemma_Occ_Split (A0, A'First, Lo - 1, Hi);
      pragma Assert (Same_Occ (A0, A));
   end Merge;

   procedure Lemma_Short_Tail
     (A : Element_Array; Width : Positive; Lo : Index)
     with
       Ghost             => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Width <= Max_N / 2
         and then Lo in 1 .. A'Last
         and then A'Last < Lo + Width
         and then (Lo - 1) rem Width = 0
         and then (Lo - 1) rem (2 * Width) = 0
         and then Sorted_Runs_Prefix (A, 2 * Width, Lo - 1)
         and then Sorted_Runs_Suffix (A, Width, Lo),
       Post              => Sorted_Runs (A, 2 * Width)
   is
      N     : constant Index := A'Last;
      Twice : constant Positive := 2 * Width;
   begin
      pragma Assert (N >= Lo);
      pragma Assert (N - Lo + 1 <= Width);

      Lemma_Runs_To_Slice (A, Width, Lo);
      pragma Assert
        (Sorted_Slice (A, Lo, Natural'Min (Lo + Width - 1, N)));
      pragma Assert (Natural'Min (Lo + Width - 1, N) = N);
      pragma Assert (Sorted_Slice (A, Lo, N));

      pragma Assert ((Lo - 1) rem Twice = 0);
      pragma Assert
        (for all K in 1 .. Lo - 2 =>
           (if (K - 1) / Twice = K / Twice then A (K) <= A (K + 1)));
      pragma Assert
        (for all K in Lo .. N - 1 => A (K) <= A (K + 1));

      pragma Assert
        (for all K in 1 .. N - 1 =>
           (if K + 1 < Lo then
              (if (K - 1) / Twice = K / Twice then A (K) <= A (K + 1))
            elsif K + 1 = Lo then
              True
            else
              A (K) <= A (K + 1)));
      pragma Assert (Sorted_Runs (A, Twice));
   end Lemma_Short_Tail;

   procedure Merge_From
     (A     : in out Element_Array;
      Temp  : in out Element_Array;
      Width : Positive;
      Lo    : Index)
     with
       Global             => null,
       Subprogram_Variant => (Decreases => A'Last + 1 - Lo),
       Pre                =>
         In_Bounds (A)
         and then A'Last >= 2
         and then Temp'First = 1
         and then Temp'Last = Max_N
         and then Width <= A'Last - 1
         and then Width <= Max_N / 2
         and then Lo in 1 .. A'Last + 1
         and then (Lo = A'Last + 1 or else (Lo - 1) rem Width = 0)
         and then (Lo = A'Last + 1 or else (Lo - 1) rem (2 * Width) = 0)
         and then Sorted_Runs_Prefix (A, 2 * Width, Lo - 1)
         and then
           (if Lo <= A'Last then Sorted_Runs_Suffix (A, Width, Lo)),
       Post               =>
         In_Bounds (A)
         and then Sorted_Runs (A, 2 * Width)
         and then Same_Occ (A'Old, A)
   is
      N     : constant Index := A'Last;
      Twice : constant Positive := 2 * Width;
      A0    : constant Element_Array := A with Ghost;
      A1    : Element_Array (A'Range) with Ghost;
   begin
      if Lo > N - Width then
         if Lo <= N then
            Lemma_Short_Tail (A, Width, Lo);
         else
            pragma Assert (Sorted_Runs_Prefix (A, Twice, N));
            pragma Assert (Sorted_Runs (A, Twice));
         end if;
         return;
      end if;

      declare
         Mid : constant Index := Lo + Width - 1;
         Hi  : constant Index :=
           (if Lo > N - Twice then N else Lo + Twice - 1);
      begin
         Lemma_Runs_To_Slice (A, Width, Lo);
         pragma Assert (Sorted_Slice (A, Lo, Mid));

         pragma Assert ((Mid) rem Width = 0);
         pragma Assert (Sorted_Runs_Suffix (A, Width, Mid + 1));
         Lemma_Runs_To_Slice (A, Width, Mid + 1);
         pragma Assert
           (Sorted_Slice
              (A, Mid + 1, Natural'Min (Mid + Width, N)));
         pragma Assert (Hi <= Natural'Min (Mid + Width, N));
         pragma Assert (Sorted_Slice (A, Mid + 1, Hi));

         Merge (A, Temp, Lo, Mid, Hi);
         A1 := A;

         pragma Assert (Sorted_Slice (A, Lo, Hi));
         pragma Assert (Sorted_Runs_Prefix (A, Twice, Lo - 1));
         Lemma_Slice_To_Prefix (A, Twice, Lo, Hi);
         pragma Assert (Sorted_Runs_Prefix (A, Twice, Hi));

         if Hi < N then
            pragma Assert (Sorted_Runs_Suffix (A, Width, Hi + 1));
            Merge_From (A, Temp, Width, Hi + 1);
            Lemma_Same_Trans (A0, A1, A);
         else
            pragma Assert (Sorted_Runs_Prefix (A, Twice, N));
            pragma Assert (Sorted_Runs (A, Twice));
         end if;
      end;
   end Merge_From;

   procedure Merge_Pass
     (A     : in out Element_Array;
      Temp  : in out Element_Array;
      Width : Positive)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then Temp'First = 1
         and then Temp'Last = Max_N
         and then Width <= A'Last - 1
         and then Sorted_Runs (A, Width),
       Post   =>
         In_Bounds (A)
         and then
           (if Width <= Max_N / 2
            then Sorted_Runs (A, 2 * Width)
            else Is_Sorted (A))
         and then Same_Occ (A'Old, A)
   is
      N   : constant Index := A'Last;
      Mid : Index;
   begin
      if Width > Max_N / 2 then
         Mid := Width;
         pragma Assert (Sorted_Runs (A, Width));
         Lemma_Runs_To_Slice (A, Width, 1);
         pragma Assert (Sorted_Slice (A, 1, Width));
         pragma Assert (Sorted_Runs_Suffix (A, Width, Width + 1));
         Lemma_Runs_To_Slice (A, Width, Width + 1);
         pragma Assert (Sorted_Slice (A, Width + 1, N));
         Merge (A, Temp, 1, Mid, N);
         pragma Assert (Sorted_Slice (A, 1, N));
         pragma Assert (Is_Sorted (A));
         return;
      end if;

      pragma Assert (Sorted_Runs_Prefix (A, 2 * Width, 0));
      pragma Assert (Sorted_Runs_Suffix (A, Width, 1));
      Merge_From (A, Temp, Width, 1);
      pragma Assert (Sorted_Runs (A, 2 * Width));
   end Merge_Pass;

   procedure Sort (A : in out Element_Array) is
      Temp  : Element_Array (1 .. Max_N) := [others => 0];
      Width : Positive;
      N     : Index;
      A0    : constant Element_Array := A with Ghost;
      Prev  : Element_Array (A'Range) with Ghost;
   begin
      if A'Length <= 1 then
         Lemma_Same_Perm (A, A0);
         return;
      end if;

      N := A'Last;
      pragma Assert (N >= 2);

      Make_Initial_Runs (A);

      if N <= Minrun then
         pragma Assert (Is_Sorted (A));
         Lemma_Same_Perm (A, A0);
         return;
      end if;

      pragma Assert (Sorted_Runs (A, Minrun));
      pragma Assert (Minrun <= N - 1);

      Width := Minrun;
      while Width < N loop
         pragma Loop_Invariant (Width in Minrun .. N - 1);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Runs (A, Width));
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Variant (Increases => Width);

         Prev := A;
         Merge_Pass (A, Temp, Width);
         Lemma_Same_Trans (A0, Prev, A);

         if Width > Max_N / 2 then
            pragma Assert (Is_Sorted (A));
            Lemma_Same_Perm (A, A0);
            return;
         end if;

         Width := 2 * Width;
         pragma Assert (Sorted_Runs (A, Width));
      end loop;

      pragma Assert (Is_Sorted (A));
      Lemma_Same_Perm (A, A0);
   end Sort;

end Timsort;
