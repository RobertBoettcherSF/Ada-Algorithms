--  Merge_Sort body — SPARK Level 4 classic stable bottom-up merge sort.
--  Outer loop doubles run width; each pass stably merges adjacent
--  Width-runs into 2·Width-runs via a fixed Temp buffer. Loop
--  invariants track Sorted_Runs so the final Width ≥ N yields Is_Sorted.

package body Merge_Sort
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

      procedure Lemma_Same_Perm (A, B : Element_Array) is null;

      procedure Lemma_Same_Trans (A, B, C : Element_Array) is null;

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

   --  Every adjacent pair inside the same Width-aligned run is ordered.
   --  Runs are aligned at A'First: K lies in run (K - A'First) / Width.
   --  Vacuous for Width = 1. When Width >= A'Length, equivalent to
   --  Is_Sorted.
   function Sorted_Runs
     (A : Element_Array; Width : Positive) return Boolean
   is
     (for all K in A'First .. A'Last - 1 =>
        (if (K - A'First) / Width = (K - A'First + 1) / Width
         then A (K) <= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    => In_Bounds (A) and then Width <= Max_N;

   --  Sorted_Runs restricted to indices overlapping A'First .. Bound
   --  (Bound may be A'First - 1 meaning nothing). Used as the "processed
   --  prefix" ghost state.
   function Sorted_Runs_Prefix
     (A : Element_Array; Width : Positive; Bound : Natural) return Boolean
   is
     (for all K in A'First .. A'Last - 1 =>
        (if K < Bound
           and then (K - A'First) / Width = (K - A'First + 1) / Width
         then A (K) <= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Width <= Max_N
       and then Bound >= A'First - 1
       and then Bound <= A'Last;

   --  Sorted_Runs restricted to indices >= Lo (unprocessed suffix).
   function Sorted_Runs_Suffix
     (A : Element_Array; Width : Positive; Lo : Natural) return Boolean
   is
     (for all K in A'First .. A'Last - 1 =>
        (if K >= Lo
           and then (K - A'First) / Width = (K - A'First + 1) / Width
         then A (K) <= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Width <= Max_N
       and then Lo >= A'First
       and then Lo <= A'Last + 1;

   procedure Lemma_Slice_To_Prefix
     (A : Element_Array; Width : Positive; Lo, Hi : Index)
     with
       Ghost             => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Width <= Max_N
         and then Lo in A'Range
         and then Hi in Lo .. A'Last
         and then (Lo - A'First) rem Width = 0
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
         and then Lo in A'Range
         and then (Lo - A'First) rem Width = 0
         and then Sorted_Runs_Suffix (A, Width, Lo),
       Post              =>
         Sorted_Slice (A, Lo, Natural'Min (Lo + Width - 1, A'Last))
   is
      Hi : constant Natural := Natural'Min (Lo + Width - 1, A'Last);
   begin
      pragma Assert
        (for all K in Lo .. Hi - 1 =>
           (K - A'First) / Width = (K - A'First + 1) / Width);
      pragma Assert (Sorted_Slice (A, Lo, Hi));
   end Lemma_Runs_To_Slice;

   --  Stable merge of sorted A(Lo .. Mid) and A(Mid+1 .. Hi) into Temp,
   --  then copy back. Prefer Left when Left <= Right (stability).
   procedure Merge
     (A           : in out Element_Array;
      Temp        : in out Element_Array;
      Lo, Mid, Hi : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Temp'First = 1
         and then Temp'Last = Max_N
         and then Lo in A'Range
         and then Hi in Lo + 1 .. A'Last
         and then Mid in Lo .. Hi - 1
         and then Sorted_Slice (A, Lo, Mid)
         and then Sorted_Slice (A, Mid + 1, Hi),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Lo, Hi)
         and then
           (for all K in A'First .. Lo - 1 => A (K) = A'Old (K))
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
           (for all T in A'First .. Lo - 1 => A (T) = A'Loop_Entry (T));
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
           (for all T in A'First .. Lo - 1 => A (T) = A'Loop_Entry (T));
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
           (for all T in A'First .. Lo - 1 => A (T) = A'Loop_Entry (T));
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
           (for all T in A'First .. Lo - 1 => A (T) = A'Loop_Entry (T));
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


   --  Short leftover Lo .. N (length <= Width), Twice-aligned at Lo.
   --  Prefix is Twice-sorted through Lo-1; Width-suffix gives Sorted_Slice
   --  on the tail. Boundary Lo-1|Lo straddles Twice-runs, so glueing them
   --  yields Sorted_Runs at Twice.
   procedure Lemma_Short_Tail
     (A : Element_Array; Width : Positive; Lo : Index)
     with
       Ghost             => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Width <= Max_N / 2
         and then Lo in A'Range
         and then A'Last < Lo + Width
         and then (Lo - A'First) rem Width = 0
         and then (Lo - A'First) rem (2 * Width) = 0
         and then Sorted_Runs_Prefix (A, 2 * Width, Lo - 1)
         and then Sorted_Runs_Suffix (A, Width, Lo),
       Post              => Sorted_Runs (A, 2 * Width)
   is
      N     : constant Index := A'Last;
      Twice : constant Positive := 2 * Width;
   begin
      pragma Assert (N >= Lo);
      --  Base case of Merge_From: Lo > N - Width => length <= Width.
      pragma Assert (N - Lo + 1 <= Width);

      Lemma_Runs_To_Slice (A, Width, Lo);
      pragma Assert
        (Sorted_Slice (A, Lo, Natural'Min (Lo + Width - 1, N)));
      pragma Assert (Natural'Min (Lo + Width - 1, N) = N);
      pragma Assert (Sorted_Slice (A, Lo, N));

      pragma Assert ((Lo - A'First) rem Twice = 0);
      pragma Assert
        (for all K in A'First .. Lo - 2 =>
           (if (K - A'First) / Twice = (K - A'First + 1) / Twice
            then A (K) <= A (K + 1)));
      pragma Assert
        (for all K in Lo .. N - 1 => A (K) <= A (K + 1));

      pragma Assert
        (for all K in A'First .. N - 1 =>
           (if K + 1 < Lo then
              (if (K - A'First) / Twice = (K - A'First + 1) / Twice
               then A (K) <= A (K + 1))
            elsif K + 1 = Lo then
              True
            else
              A (K) <= A (K + 1)));
      pragma Assert (Sorted_Runs (A, Twice));
   end Lemma_Short_Tail;

   --  Merge adjacent Width-runs starting at Lo; recurse for the rest.
   --  Prefix A'First .. Lo-1 is already Sorted_Runs at Twice (= 2*Width).
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
         and then A'Length >= 2
         and then Temp'First = 1
         and then Temp'Last = Max_N
         and then Width <= A'Length - 1
         and then Width <= Max_N / 2
         and then Lo in A'First .. A'Last + 1
         and then (Lo = A'Last + 1 or else (Lo - A'First) rem Width = 0)
         and then (Lo = A'Last + 1 or else (Lo - A'First) rem (2 * Width) = 0)
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

         --  Right run Mid+1 .. Hi is Width-aligned when Mid+1 <= N.
         pragma Assert ((Mid + 1 - A'First) rem Width = 0);
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
         --  Merge preserves prefix left of Lo and suffix right of Hi.
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
         and then A'Length >= 2
         and then Temp'First = 1
         and then Temp'Last = Max_N
         and then Width <= A'Length - 1
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
         --  Single merge covers the whole array.
         Mid := A'First + Width - 1;
         pragma Assert (Sorted_Runs (A, Width));
         Lemma_Runs_To_Slice (A, Width, A'First);
         pragma Assert (Sorted_Slice (A, A'First, Mid));
         pragma Assert (Sorted_Runs_Suffix (A, Width, Mid + 1));
         Lemma_Runs_To_Slice (A, Width, Mid + 1);
         pragma Assert (Sorted_Slice (A, Mid + 1, N));
         Merge (A, Temp, A'First, Mid, N);
         pragma Assert (Sorted_Slice (A, A'First, N));
         pragma Assert (Is_Sorted (A));
         return;
      end if;

      pragma Assert (Sorted_Runs_Prefix (A, 2 * Width, A'First - 1));
      pragma Assert (Sorted_Runs_Suffix (A, Width, A'First));
      Merge_From (A, Temp, Width, A'First);
      pragma Assert (Sorted_Runs (A, 2 * Width));
   end Merge_Pass;

   procedure Sort (A : in out Element_Array) is
      Temp  : Element_Array (1 .. Max_N) := [others => 0];
      Width : Positive;
      N     : Index;   --  length (runs are counted from A'First)
      A0    : constant Element_Array := A with Ghost;
      Prev  : Element_Array (A'Range) with Ghost;
   begin
      if A'Length <= 1 then
         Lemma_Same_Perm (A, A0);
         return;
      end if;

      N := A'Length;
      pragma Assert (N >= 2);
      pragma Assert (Sorted_Runs (A, 1));

      Width := 1;
      while Width < N loop
         pragma Loop_Invariant (Width <= N - 1);
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

end Merge_Sort;
