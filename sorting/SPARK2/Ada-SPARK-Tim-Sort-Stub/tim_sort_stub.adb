pragma Ada_2022;

package body Tim_Sort_Stub with SPARK_Mode => On is

   function Min_Run (N : Natural) return Natural is
      X   : Natural := N;
      Low : Boolean := False;
   begin
      while X >= 64 loop
         pragma Loop_Invariant (X <= N);
         pragma Loop_Variant (Decreases => X);
         if X mod 2 = 1 then
            Low := True;
         end if;
         X := X / 2;
      end loop;
      pragma Assert (if N >= 64 then X in 32 .. 63);
      return X + (if Low then 1 else 0);
   end Min_Run;

   --  A and B have the same bounds and every value occurs equally often.
   function Same_Occ (A, B : Value_Array) return Boolean is
     (A'First = B'First and then A'Last = B'Last
      and then (for all V in Value => Occ (A, V, A'First, A'Last) = Occ (B, V, B'First, B'Last)))
   with Ghost;

   package Perm_Lemmas with Ghost is
      --  Counts over First .. Last only see First .. Last.
      procedure Lemma_Occ_Eq (A, B : Value_Array; First, Last : Integer)
        with Pre  => (if First <= Last then
                        First >= A'First and then Last <= A'Last
                        and then First >= B'First and then Last <= B'Last
                        and then (for all T in First .. Last => A (T) = B (T))),
             Post => (for all V in Value => Occ (A, V, First, Last) = Occ (B, V, First, Last)),
             Subprogram_Variant => (Decreases => Last);

      --  Counts over First .. Last split after Mid.
      procedure Lemma_Occ_Split (A : Value_Array; First, Mid, Last : Integer)
        with Pre  => First >= A'First and then Last <= A'Last and then Last < Integer'Last
                     and then Mid <= Last and then First <= Mid + 1,
             Post => (for all V in Value =>
                        Occ (A, V, First, Last) = Occ (A, V, First, Mid) + Occ (A, V, Mid + 1, Last)),
             Subprogram_Variant => (Decreases => Last);

      --  T (1 .. L) is S (F .. F + L - 1).
      procedure Lemma_Occ_Shift (T, S : Value_Array; F : Positive; L : Natural)
        with Pre  => T'First = 1 and then L <= T'Last
                     and then (L = 0 or else (F in S'Range and then L - 1 <= S'Last - F))
                     and then (for all X in 1 .. L => T (X) = S (F + (X - 1))),
             Post => (for all V in Value => Occ (T, V, 1, L) = Occ (S, V, F, F + (L - 1))),
             Subprogram_Variant => (Decreases => L);

      --  B is A with slot K changed.
      procedure Lemma_Occ_Set (A, B : Value_Array; K : Positive; First, Last : Integer)
        with Pre  => A'First = B'First and then A'Last = B'Last
                     and then K in First .. Last and then First >= A'First and then Last <= A'Last
                     and then (for all J in A'Range => (if J /= K then A (J) = B (J))),
             Post => (for all V in Value =>
                        Occ (B, V, First, Last)
                        = Occ (A, V, First, Last) - (if A (K) = V then 1 else 0) + (if B (K) = V then 1 else 0)),
             Subprogram_Variant => (Decreases => Last);

      --  B is A with slots X and Y exchanged.
      procedure Lemma_Swap (A, B : Value_Array; X, Y : Positive)
        with Pre  => A'First = B'First and then A'Last = B'Last
                     and then X in A'Range and then Y in A'Range
                     and then B (X) = A (Y) and then B (Y) = A (X)
                     and then (for all J in A'Range => (if J /= X and then J /= Y then A (J) = B (J))),
             Post => Same_Occ (A, B);

      --  B equals A outside Lo .. Hi and has the same counts inside.
      procedure Lemma_Frame (A, B : Value_Array; Lo, Hi : Positive)
        with Pre  => A'First = B'First and then A'Last = B'Last and then A'Last < Positive'Last
                     and then Lo <= Hi and then Lo in A'Range and then Hi in A'Range
                     and then (for all K in A'Range => (if K < Lo or else K > Hi then A (K) = B (K)))
                     and then (for all V in Value => Occ (A, V, Lo, Hi) = Occ (B, V, Lo, Hi)),
             Post => Same_Occ (A, B);

      procedure Lemma_Same_Trans (A, B, C : Value_Array)
        with Pre  => Same_Occ (A, B) and then Same_Occ (B, C),
             Post => Same_Occ (A, C);

      --  The executable Is_Perm follows from Same_Occ.
      procedure Lemma_Same_Perm (A, B : Value_Array)
        with Pre  => Same_Occ (A, B),
             Post => Is_Perm (A, B);
   end Perm_Lemmas;

   package body Perm_Lemmas is
      procedure Lemma_Occ_Eq (A, B : Value_Array; First, Last : Integer) is
      begin
         if First <= Last then
            Lemma_Occ_Eq (A, B, First, Last - 1);
         end if;
      end Lemma_Occ_Eq;

      procedure Lemma_Occ_Split (A : Value_Array; First, Mid, Last : Integer) is
      begin
         if Mid < Last then
            Lemma_Occ_Split (A, First, Mid, Last - 1);
         end if;
      end Lemma_Occ_Split;

      procedure Lemma_Occ_Shift (T, S : Value_Array; F : Positive; L : Natural) is
      begin
         if L > 0 then
            Lemma_Occ_Shift (T, S, F, L - 1);
         end if;
      end Lemma_Occ_Shift;

      procedure Lemma_Occ_Set (A, B : Value_Array; K : Positive; First, Last : Integer) is
      begin
         if Last > K then
            Lemma_Occ_Set (A, B, K, First, Last - 1);
         else
            Lemma_Occ_Eq (A, B, First, K - 1);
         end if;
      end Lemma_Occ_Set;

      procedure Lemma_Swap (A, B : Value_Array; X, Y : Positive) is
      begin
         if X = Y then
            Lemma_Occ_Eq (A, B, A'First, A'Last);
            return;
         end if;
         declare
            C : constant Value_Array := (A with delta X => A (Y));
         begin
            Lemma_Occ_Set (A, C, X, A'First, A'Last);
            Lemma_Occ_Set (C, B, Y, A'First, A'Last);
         end;
      end Lemma_Swap;

      procedure Lemma_Frame (A, B : Value_Array; Lo, Hi : Positive) is
      begin
         Lemma_Occ_Eq (A, B, A'First, Lo - 1);
         Lemma_Occ_Eq (A, B, Hi + 1, A'Last);
         Lemma_Occ_Split (A, A'First, Hi, A'Last);
         Lemma_Occ_Split (A, A'First, Lo - 1, Hi);
         Lemma_Occ_Split (B, B'First, Hi, B'Last);
         Lemma_Occ_Split (B, B'First, Lo - 1, Hi);
      end Lemma_Frame;

      procedure Lemma_Same_Trans (A, B, C : Value_Array) is null;

      procedure Lemma_Same_Perm (A, B : Value_Array) is null;
   end Perm_Lemmas;
   use Perm_Lemmas;

   --  Exchange W (X) and W (Y); the counts stay the same.
   procedure Swap (W : in out Value_Array; X, Y : Positive)
     with Pre  => X in W'Range and then Y in W'Range,
          Post => W (X) = W'Old (Y) and then W (Y) = W'Old (X)
                  and then (for all K in W'Range => (if K /= X and then K /= Y then W (K) = W'Old (K)))
                  and then Same_Occ (W'Old, W)
   is
      W0 : constant Value_Array := W with Ghost;
      T  : constant Value := W (X);
   begin
      W (X) := W (Y);
      W (Y) := T;
      Lemma_Swap (W0, W, X, Y);
   end Swap;

   --  Neighbours in order give the pairwise form.
   procedure Lemma_Pairs (W : Value_Array; Lo, Hi : Positive)
     with Ghost,
          Pre  => Lo <= Hi and then Lo in W'Range and then Hi in W'Range
                  and then (for all K in Lo .. Hi - 1 => W (K) <= W (K + 1)),
          Post => Sorted (W, Lo, Hi)
   is
   begin
      for B in Lo .. Hi loop
         pragma Loop_Invariant (for all X in Lo .. B - 1 => (for all Y in X .. B - 1 => W (X) <= W (Y)));
         pragma Loop_Invariant (for all X in Lo .. B - 1 => W (X) <= W (B));
      end loop;
   end Lemma_Pairs;

   --  W (Lo .. Hi) is reversed; it was strictly descending, so it is now
   --  sorted. Outside Lo .. Hi nothing changes.
   procedure Reverse_Run (W : in out Value_Array; Lo, Hi : Positive)
     with Pre  => Lo <= Hi and then Lo in W'Range and then Hi in W'Range and then W'Last < Positive'Last
                  and then (for all K in Lo .. Hi - 1 => W (K + 1) < W (K)),
          Post => Sorted (W, Lo, Hi)
                  and then (for all K in W'Range => (if K < Lo or else K > Hi then W (K) = W'Old (K)))
                  and then Same_Occ (W'Old, W)
   is
      S : constant Value_Array := W with Ghost;
      C : constant Natural := (Hi - Lo + 1) / 2;
      Prev : Value_Array (W'Range) with Ghost;
   begin
      Lemma_Occ_Eq (S, W, W'First, W'Last);
      for I in 0 .. C - 1 loop
         Prev := W;
         Swap (W, Lo + I, Hi - I);
         Lemma_Same_Trans (S, Prev, W);
         pragma Loop_Invariant (Same_Occ (S, W));
         pragma Loop_Invariant
           (for all K in Lo .. Lo + I => W (K) = S (Hi - (K - Lo)));
         pragma Loop_Invariant
           (for all K in Hi - I .. Hi => W (K) = S (Hi - (K - Lo)));
         pragma Loop_Invariant (for all K in Lo + I + 1 .. Hi - I - 1 => W (K) = S (K));
         pragma Loop_Invariant (for all K in W'Range => (if K < Lo or else K > Hi then W (K) = S (K)));
      end loop;
      pragma Assert (for all K in Lo .. Lo + C - 1 => W (K) = S (Hi - (K - Lo)));
      pragma Assert (for all K in Hi - C + 1 .. Hi => W (K) = S (Hi - (K - Lo)));
      pragma Assert (for all K in Lo + C .. Hi - C => W (K) = S (K) and then K - Lo = Hi - K);
      pragma Assert (for all K in Lo .. Hi => W (K) = S (Hi - (K - Lo)));
      pragma Assert (for all K in Lo .. Hi - 1 => W (K) <= W (K + 1));
      Lemma_Pairs (W, Lo, Hi);
   end Reverse_Run;

   --  Binary insertion: W (Lo .. Start - 1) is sorted; insert W (Start ..
   --  Hi) one by one after equal keys. Outside Lo .. Hi nothing changes.
   procedure Binary_Insertion (W : in out Value_Array; Lo, Start, Hi : Positive)
     with Pre  => W'Last < Positive'Last and then Lo in W'Range and then Hi in W'Range and then Lo < Start and then Start <= Hi + 1
                  and then Sorted (W, Lo, Start - 1),
          Post => Sorted (W, Lo, Hi)
                  and then (for all K in W'Range => (if K < Lo or else K > Hi then W (K) = W'Old (K)))
                  and then Same_Occ (W'Old, W)
   is
      S0 : constant Value_Array := W with Ghost;
      L, R, Mid : Positive;
      P  : Value;
      S2 : Value_Array (W'Range) with Ghost;
      Prev : Value_Array (W'Range) with Ghost;
   begin
      Lemma_Occ_Eq (S0, W, W'First, W'Last);
      for I in Start .. Hi loop
         pragma Loop_Invariant (Sorted (W, Lo, I - 1));
         pragma Loop_Invariant (Same_Occ (S0, W));
         pragma Loop_Invariant (for all K in W'Range => (if K < Lo or else K > Hi then W (K) = S0 (K)));
         P := W (I);
         L := Lo;
         R := I;
         while L < R loop
            pragma Loop_Invariant (Lo <= L and then L < R and then R <= I);
            pragma Loop_Invariant (for all K in Lo .. L - 1 => W (K) <= P);
            pragma Loop_Invariant (for all K in R .. I - 1 => P < W (K));
            pragma Loop_Variant (Decreases => R - L);
            Mid := L + (R - L) / 2;
            if P < W (Mid) then
               R := Mid;
            else
               L := Mid + 1;
            end if;
         end loop;
         S2 := W;
         pragma Assert (for all K in Lo .. L - 1 => S2 (K) <= P);
         pragma Assert (for all K in L .. I - 1 => P < S2 (K));
         pragma Assert (S2 (I) = P);
         --  Shift W (L .. I - 1) up by one and put P at L, as adjacent
         --  exchanges (P moves down from I to L).
         for J in reverse L .. I - 1 loop
            Prev := W;
            Swap (W, J, J + 1);
            Lemma_Same_Trans (S0, Prev, W);
            pragma Loop_Invariant (W (J) = P);
            pragma Loop_Invariant (for all K in J + 1 .. I => W (K) = S2 (K - 1));
            pragma Loop_Invariant (for all K in W'Range => (if K < J or else K > I then W (K) = S2 (K)));
            pragma Loop_Invariant (Same_Occ (S0, W));
         end loop;
         pragma Assert (W (L) = P);
         pragma Assert (for all K in L + 1 .. I => W (K) = S2 (K - 1));
         pragma Assert (for all K in Lo .. L - 1 => W (K) = S2 (K));
         pragma Assert (for all X in Lo .. L - 1 => (for all Y in X .. L - 1 => W (X) <= W (Y)));
         pragma Assert (for all X in Lo .. L => W (X) <= W (L));
         pragma Assert (for all Y in L .. I => W (L) <= W (Y));
         pragma Assert (for all X in L + 1 .. I => (for all Y in X .. I => W (X) <= W (Y)));
         pragma Assert (for all X in Lo .. L - 1 => (for all Y in L + 1 .. I => W (X) <= W (Y)));
      end loop;
   end Binary_Insertion;

   --  merge_lo: W (B1 .. M) and W (M + 1 .. E2) are sorted; afterwards
   --  W (B1 .. E2) is sorted. Outside B1 .. E2 nothing changes.
   procedure Merge_Runs (W : in out Value_Array; B1, M, E2 : Positive)
     with Pre  => W'Last < Positive'Last and then B1 <= M and then M < E2 and then B1 in W'Range and then E2 in W'Range
                  and then E2 - B1 < Max_Len
                  and then Sorted (W, B1, M) and then Sorted (W, M + 1, E2),
          Post => Sorted (W, B1, E2)
                  and then (for all K in W'Range => (if K < B1 or else K > E2 then W (K) = W'Old (K)))
                  and then Same_Occ (W'Old, W)
   is
      Tmp : constant Value_Array (1 .. M - B1 + 1) := W (B1 .. M);
      S0  : constant Value_Array := W with Ghost;
      Prev : Value_Array (W'Range) with Ghost;
      I   : Positive := 1;          --  next of Tmp
      J   : Positive := M + 1;      --  next of the right run
      K   : Positive := B1;         --  next slot
   begin
      pragma Assert (for all X in Tmp'Range => Tmp (X) = S0 (B1 + X - 1));
      pragma Assert (Sorted (Tmp, 1, Tmp'Last));
      while I <= Tmp'Last loop
         pragma Loop_Invariant (J in M + 1 .. E2 + 1 and then K = B1 + (I - 1) + (J - M - 1));
         pragma Loop_Invariant (for all X in J .. E2 => W (X) = S0 (X));
         pragma Loop_Invariant (for all X in W'Range => (if X < B1 or else X > E2 then W (X) = S0 (X)));
         pragma Loop_Invariant (Sorted (W, B1, K - 1));
         pragma Loop_Invariant (for all X in B1 .. K - 1 => (for all Y in I .. Tmp'Last => W (X) <= Tmp (Y)));
         pragma Loop_Invariant (for all X in B1 .. K - 1 => (for all Y in J .. E2 => W (X) <= S0 (Y)));
         pragma Loop_Invariant
           (for all V in Value => Occ (W, V, B1, K - 1) = Occ (Tmp, V, 1, I - 1) + Occ (S0, V, M + 1, J - 1));
         pragma Loop_Variant (Increases => K);
         Prev := W;
         if J <= E2 and then W (J) < Tmp (I) then
            W (K) := W (J);
            Lemma_Occ_Eq (Prev, W, B1, K - 1);
            J := J + 1;
         else
            W (K) := Tmp (I);
            Lemma_Occ_Eq (Prev, W, B1, K - 1);
            I := I + 1;
         end if;
         K := K + 1;
      end loop;
      pragma Assert (K = J);
      pragma Assert (for all X in K .. E2 => W (X) = S0 (X));
      pragma Assert (Sorted (S0, K, E2));
      pragma Assert (Sorted (W, K, E2));
      --  Counts: B1 .. K - 1 holds Tmp and S0 (M + 1 .. K - 1), K .. E2 is S0.
      Lemma_Occ_Shift (Tmp, S0, B1, Tmp'Last);
      Lemma_Occ_Eq (W, S0, K, E2);
      Lemma_Occ_Split (W, B1, K - 1, E2);
      Lemma_Occ_Split (S0, B1, M, E2);
      Lemma_Occ_Split (S0, M + 1, K - 1, E2);
      pragma Assert (for all V in Value => Occ (W, V, B1, E2) = Occ (S0, V, B1, E2));
      Lemma_Frame (S0, W, B1, E2);
   end Merge_Runs;

   --  A stack run: Len >= 1 values from Base, inside W, sorted.
   function Run_Ok (W : Value_Array; B : Positive; L : Natural) return Boolean is
     (L >= 1 and then B in W'Range and then L - 1 <= W'Last - B
      and then Sorted (W, B, B + (L - 1)))
   with Ghost;

   procedure Sort_Traced
     (Input : Value_Array; Output : out Value_Array; Log : out Event_Log; Count : out Natural)
   is
      N      : constant Natural := Input'Length;
      Min    : constant Natural := Min_Run (N);
      Base   : array (1 .. Max_Len + 1) of Positive := [others => 1];
      Len    : Length_Array (1 .. Max_Len + 1) := [others => 0];
      Top    : Natural := 0;
      Pushes : Natural := 0;
      R, Force, Idx : Natural;
      Prev   : Value_Array (Input'Range) with Ghost;

      --  The stack: runs 1 .. Top, contiguous from Input'First to Lo - 1.
      function Stack_Ok (Lo : Positive) return Boolean is
        (Top <= Max_Len
         and then (for all X in 1 .. Top => Run_Ok (Output, Base (X), Len (X)) and then Lo - Base (X) >= Len (X))
         and then (for all X in 1 .. Top => (for all Y in X + 1 .. Top => Base (Y) - Base (X) >= Len (X)))
         and then (for all X in 1 .. Top - 1 => Base (X + 1) - Base (X) = Len (X))
         and then (if Top = 0 then Lo = Input'First
                   else Base (1) = Input'First and then Lo - Base (Top) = Len (Top)))
      with Ghost,
           Pre => Output'First = Input'First and then Output'Last = Input'Last;

      --  Merge stack runs I and I + 1.
      procedure Merge_At (I : Positive; Lo : Positive)
        with Pre  => I < Top and then Log'First = 1 and then Count >= 1 and then Count < Log'Last
                     and then Output'First = Input'First and then Output'Last = Input'Last
                     and then Input'Length <= Max_Len and then Input'Last < Positive'Last
                     and then Lo in Input'First .. Input'Last + 1
                     and then Stack_Ok (Lo),
             Post => Top = Top'Old - 1 and then Count = Count'Old + 1 and then Stack_Ok (Lo)
                     and then Log (1) = Log'Old (1)
                     and then (for all X in 1 .. I - 1 => Len (X) = Len'Old (X))
                     and then Len (I) = Len'Old (I) + Len'Old (I + 1)
                     and then (for all X in I + 1 .. Top => Len (X) = Len'Old (X + 1))
                     and then (for all X in Output'Range => (if X >= Lo then Output (X) = Output'Old (X)))
                     and then Same_Occ (Output'Old, Output)
      is
         W0 : constant Value_Array := Output with Ghost;
         B0 : constant Positive := Base (I) with Ghost;
         E2 : constant Positive := Base (I + 1) + (Len (I + 1) - 1);
      begin
         pragma Assert (E2 < Lo);
         Merge_Runs (Output, Base (I), Base (I) + (Len (I) - 1), E2);
         Len (I) := Len (I) + Len (I + 1);
         for X in I + 1 .. Top - 1 loop
            Base (X) := Base (X + 1);
            Len (X) := Len (X + 1);
            pragma Loop_Invariant (for all Y in I + 1 .. X => Base (Y) = Base'Loop_Entry (Y + 1) and then Len (Y) = Len'Loop_Entry (Y + 1));
            pragma Loop_Invariant (for all Y in 1 .. I => Base (Y) = Base'Loop_Entry (Y) and then Len (Y) = Len'Loop_Entry (Y));
            pragma Loop_Invariant (for all Y in X + 1 .. Top => Base (Y) = Base'Loop_Entry (Y) and then Len (Y) = Len'Loop_Entry (Y));
         end loop;
         Top := Top - 1;
         Count := Count + 1;
         Log (Count) := (Merge, I, 0);
         pragma Assert (Base (I) = B0 and then Base (I) + (Len (I) - 1) = E2);
         pragma Assert (for all X in Output'Range => (if X < B0 or else X > E2 then Output (X) = W0 (X)));
         pragma Assert (for all X in 1 .. I - 1 => Base (X) + (Len (X) - 1) < B0);
         pragma Assert (for all X in I + 1 .. Top => Base (X) > E2);
      end Merge_At;
   begin
      Output := Input;
      Lemma_Occ_Eq (Input, Output, Input'First, Input'Last);
      Log := [others => (Push, 0, 0)];
      Count := 0;
      if N = 0 then
         return;
      end if;
      declare
         Lo : Positive := Input'First;
      begin
         while Lo <= Input'Last loop
            pragma Loop_Invariant (Top <= Pushes and then Pushes <= Lo - Input'First);
            pragma Loop_Invariant (Count + Top = 2 * Pushes);
            pragma Loop_Invariant (Count >= 1 or else Lo = Input'First);
            pragma Loop_Invariant (if Count >= 1 then Log (1).Kind = Push and then Log (1).A = Input'First);
            pragma Loop_Invariant (Stack_Ok (Lo));
            pragma Loop_Invariant (Same_Occ (Input, Output));
            pragma Loop_Invariant (Runs_Rule (Len, Top));
            pragma Loop_Variant (Increases => Lo);
            --  count_run
            R := 1;
            if Lo < Input'Last then
               R := 2;
               if Output (Lo + 1) < Output (Lo) then
                  while Lo + R <= Input'Last and then Output (Lo + R) < Output (Lo + R - 1) loop
                     pragma Loop_Invariant (R >= 2 and then Lo + R - 1 <= Input'Last);
                     pragma Loop_Invariant (for all K in Lo .. Lo + R - 2 => Output (K + 1) < Output (K));
                     pragma Loop_Variant (Increases => R);
                     R := R + 1;
                  end loop;
                  Prev := Output;
                  Reverse_Run (Output, Lo, Lo + R - 1);
                  Lemma_Same_Trans (Input, Prev, Output);
               else
                  while Lo + R <= Input'Last and then not (Output (Lo + R) < Output (Lo + R - 1)) loop
                     pragma Loop_Invariant (R >= 2 and then Lo + R - 1 <= Input'Last);
                     pragma Loop_Invariant (for all K in Lo .. Lo + R - 2 => Output (K) <= Output (K + 1));
                     pragma Loop_Variant (Increases => R);
                     R := R + 1;
                  end loop;
                  Lemma_Pairs (Output, Lo, Lo + R - 1);
               end if;
            end if;
            pragma Assert (Sorted (Output, Lo, Lo + R - 1));
            Force := Natural'Min (Min, Input'Last - Lo + 1);
            if R < Force then
               Prev := Output;
               Binary_Insertion (Output, Lo, Lo + R, Lo + Force - 1);
               Lemma_Same_Trans (Input, Prev, Output);
               R := Force;
            end if;
            pragma Assert (Stack_Ok (Lo));
            Top := Top + 1;
            Pushes := Pushes + 1;
            Base (Top) := Lo;
            Len (Top) := R;
            Count := Count + 1;
            Log (Count) := (Push, Lo, R);
            Lo := Lo + R;
            pragma Assert (Stack_Ok (Lo));
            --  merge_collapse
            while Top > 1 loop
               pragma Loop_Invariant (Top <= Pushes and then Count + Top = 2 * Pushes and then Pushes <= Lo - Input'First);
               pragma Loop_Invariant (Count >= 1 and then Log (1).Kind = Push and then Log (1).A = Input'First);
               pragma Loop_Invariant (Stack_Ok (Lo));
               pragma Loop_Invariant (Same_Occ (Input, Output));
               --  Below the top three runs the whole-stack rule holds: a
               --  merge only touches the top three (H174).
               pragma Loop_Invariant (Runs_Rule (Len, Top - 2));
               pragma Loop_Variant (Decreases => Top);
               Idx := Top - 1;
               if (Idx > 1 and then Len (Idx - 1) <= Len (Idx) + Len (Idx + 1))
                 or else (Idx > 2 and then Len (Idx - 2) <= Len (Idx - 1) + Len (Idx))
               then
                  if Len (Idx - 1) < Len (Idx + 1) then
                     Idx := Idx - 1;
                  end if;
                  Prev := Output;
                  Merge_At (Idx, Lo);
                  Lemma_Same_Trans (Input, Prev, Output);
               elsif Len (Idx) <= Len (Idx + 1) then
                  Prev := Output;
                  Merge_At (Idx, Lo);
                  Lemma_Same_Trans (Input, Prev, Output);
               else
                  exit;
               end if;
            end loop;
            --  After every merge_collapse the rule holds over the whole
            --  stack, not only the top three runs (H174).
            pragma Assert (Runs_Rule (Len, Top));
         end loop;
         --  merge_force_collapse
         while Top > 1 loop
            pragma Loop_Invariant (Top <= Pushes and then Count + Top = 2 * Pushes and then Pushes <= N);
            pragma Loop_Invariant (Count >= 1 and then Log (1).Kind = Push and then Log (1).A = Input'First);
            pragma Loop_Invariant (Lo = Input'Last + 1 and then Stack_Ok (Lo));
            pragma Loop_Invariant (Same_Occ (Input, Output));
            pragma Loop_Variant (Decreases => Top);
            Idx := Top - 1;
            if Idx > 1 and then Len (Idx - 1) < Len (Idx + 1) then
               Idx := Idx - 1;
            end if;
            Prev := Output;
            Merge_At (Idx, Lo);
            Lemma_Same_Trans (Input, Prev, Output);
         end loop;
         pragma Assert (Top = 1 and then Base (1) = Input'First and then Base (1) + (Len (1) - 1) = Input'Last);
      end;
      Lemma_Same_Perm (Output, Input);
   end Sort_Traced;

   function Sort (Input : Value_Array) return Value_Array is
      Output : Value_Array (Input'Range);
      Log    : Event_Log (1 .. 2 * Input'Length + 1);
      Count  : Natural;
   begin
      Sort_Traced (Input, Output, Log, Count);
      pragma Assert (Count <= 2 * Input'Length and then (if Input'Length > 0 then Log (1).A = Input'First));
      return Output;
   end Sort;
end Tim_Sort_Stub;
