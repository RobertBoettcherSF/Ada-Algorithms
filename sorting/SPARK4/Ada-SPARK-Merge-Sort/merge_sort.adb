--  Merge_Sort body — SPARK Level 4 classic stable bottom-up merge sort.
--  Outer loop doubles run width; each pass stably merges adjacent
--  Width-runs into 2·Width-runs via a fixed Temp buffer. Loop
--  invariants track Sorted_Runs so the final Width ≥ N yields Is_Sorted.

package body Merge_Sort
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

   --  Sorted_Runs restricted to indices overlapping 1 .. Bound (Bound may
   --  be 0 meaning nothing). Used as the "processed prefix" ghost state.
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

   --  Sorted_Runs restricted to indices >= Lo (unprocessed suffix).
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


   --  Short leftover Lo .. N (length <= Width), Twice-aligned at Lo.
   --  Prefix is Twice-sorted through Lo-1; Width-suffix gives Sorted_Slice
   --  on the tail. Boundary Lo-1|Lo straddles Twice-runs, so glueing them
   --  yields Sorted_Runs at Twice.
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
      --  Base case of Merge_From: Lo > N - Width => length <= Width.
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

   --  Merge adjacent Width-runs starting at Lo; recurse for the rest.
   --  Prefixed 1 .. Lo-1 is already Sorted_Runs at Twice (= 2*Width).
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

         --  Right run Mid+1 .. Hi is Width-aligned when Mid+1 <= N.
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
         --  Merge preserves prefix left of Lo and suffix right of Hi.
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
         --  Single merge covers the whole array.
         Mid := Width;  -- Mid = 1 + Width - 1
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
      pragma Assert (Sorted_Runs (A, 1));

      Width := 1;
      while Width < N loop
         pragma Loop_Invariant (Width in 1 .. N - 1);
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

end Merge_Sort;
