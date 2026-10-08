--  Timsort body — SPARK Level 4 educational hybrid: Minrun-aligned
--  natural runs + insertion extend, then bottom-up stable merge via
--  fixed Temp. Loop invariants track Sorted_Runs so Width ≥ N yields
--  Is_Sorted. Zero Intentional Annotate.

package body Timsort
  with SPARK_Mode => On
is

   --  Cursor one past the live range (drain / end-of-run sentinels).
   subtype Cursor is Natural range 0 .. Max_N + 1;

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
       Always_Terminates => True,
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
       Always_Terminates => True,
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

      A (J) := Key;

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
   is
   begin
      if Sorted_Last >= Hi then
         pragma Assert (Sorted_Slice (A, Lo, Hi));
         return;
      end if;

      for I in Sorted_Last + 1 .. Hi loop
         Insert_At (A, Lo, I);

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
   is
      I : Index := Lo;
      J : Index := Hi;
      T : Integer;
   begin
      while I < J loop
         pragma Loop_Invariant (I in Lo .. Hi);
         pragma Loop_Invariant (J in Lo .. Hi);
         pragma Loop_Invariant (I + J = Lo + Hi);
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Decreases => J - I);

         T := A (I);
         A (I) := A (J);
         A (J) := T;
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
   is
      Run_Hi : Index;
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
         Reverse_Range (A, Lo, Run_Hi);
         --  Only the first element is known sorted after reverse without
         --  a descending-order ghost; insertion-sort the reversed slice.
         pragma Assert (Sorted_Slice (A, Lo, Lo));
         Insertion_Extend (A, Lo, Lo, Run_Hi);
         pragma Assert (Sorted_Slice (A, Lo, Run_Hi));
      end if;

      Insertion_Extend (A, Lo, Run_Hi, Hi);
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
   is
      N  : constant Index := A'Last;
      Lo : Index := 1;
      Hi : Index;
   begin
      pragma Assert (Sorted_Runs_Prefix (A, Minrun, 0));

      while Lo <= N loop
         pragma Loop_Invariant (Lo in 1 .. N + 1);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (Lo = N + 1 or else (Lo - 1) rem Minrun = 0);
         pragma Loop_Invariant
           (Sorted_Runs_Prefix (A, Minrun, Lo - 1));
         pragma Loop_Variant (Decreases => N + 1 - Lo);

         Hi := Natural'Min (Lo + Minrun - 1, N);
         Prepare_Block (A, Lo, Hi);
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
   is
      I : Cursor := Lo;
      J : Cursor := Mid + 1;
      K : Cursor := Lo;
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
         pragma Loop_Variant (Decreases => (Mid - I + 1) + (Hi - J + 1));

         if A (I) <= A (J) then
            Temp (K) := A (I);
            pragma Assert (if K > Lo then Temp (K - 1) <= Temp (K));
            I := I + 1;
         else
            Temp (K) := A (J);
            pragma Assert (if K > Lo then Temp (K - 1) <= Temp (K));
            J := J + 1;
         end if;
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
         pragma Loop_Variant (Decreases => Mid - I + 1);

         Temp (K) := A (I);
         pragma Assert (Temp (K - 1) <= Temp (K));
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
         pragma Loop_Variant (Decreases => Hi - J + 1);

         Temp (K) := A (J);
         pragma Assert (Temp (K - 1) <= Temp (K));
         J := J + 1;
         K := K + 1;
      end loop;

      pragma Assert (K = Hi + 1);
      pragma Assert (Sorted_Slice (Temp, Lo, Hi));

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
   end Merge;

   procedure Lemma_Short_Tail
     (A : Element_Array; Width : Positive; Lo : Index)
     with
       Ghost             => True,
       Always_Terminates => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Width in 1 .. Max_N / 2
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
       Always_Terminates  => True,
       Subprogram_Variant => (Decreases => A'Last + 1 - Lo),
       Pre                =>
         In_Bounds (A)
         and then A'Last >= 2
         and then Temp'First = 1
         and then Temp'Last = Max_N
         and then Width in 1 .. A'Last - 1
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
   is
      N     : constant Index := A'Last;
      Twice : constant Positive := 2 * Width;
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
         pragma Assert (Hi <= Natural'Min (Mid + Width, N)
                        or else Hi = N);
         pragma Assert (Sorted_Slice (A, Mid + 1, Hi));

         Merge (A, Temp, Lo, Mid, Hi);

         pragma Assert (Sorted_Slice (A, Lo, Hi));
         pragma Assert (Sorted_Runs_Prefix (A, Twice, Lo - 1));
         Lemma_Slice_To_Prefix (A, Twice, Lo, Hi);
         pragma Assert (Sorted_Runs_Prefix (A, Twice, Hi));

         if Hi < N then
            pragma Assert (Sorted_Runs_Suffix (A, Width, Hi + 1));
            Merge_From (A, Temp, Width, Hi + 1);
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
         and then Width in 1 .. A'Last - 1
         and then Sorted_Runs (A, Width),
       Post   =>
         In_Bounds (A)
         and then
           (if Width <= Max_N / 2
            then Sorted_Runs (A, 2 * Width)
            else Is_Sorted (A))
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
   begin
      if A'Length <= 1 then
         return;
      end if;

      N := A'Last;
      pragma Assert (N in 2 .. Max_N);

      Make_Initial_Runs (A);

      if N <= Minrun then
         pragma Assert (Is_Sorted (A));
         return;
      end if;

      pragma Assert (Sorted_Runs (A, Minrun));
      pragma Assert (Minrun in 1 .. N - 1);

      Width := Minrun;
      while Width < N loop
         pragma Loop_Invariant (Width in Minrun .. N - 1);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Runs (A, Width));
         pragma Loop_Variant (Increases => Width);

         Merge_Pass (A, Temp, Width);

         if Width > Max_N / 2 then
            pragma Assert (Is_Sorted (A));
            return;
         end if;

         Width := 2 * Width;
         pragma Assert (Sorted_Runs (A, Width));
      end loop;

      pragma Assert (Is_Sorted (A));
   end Sort;

end Timsort;
