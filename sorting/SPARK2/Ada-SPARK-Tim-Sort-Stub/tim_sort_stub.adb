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
   is
      S : constant Value_Array := W with Ghost;
      C : constant Natural := (Hi - Lo + 1) / 2;
      T : Value;
   begin
      for I in 0 .. C - 1 loop
         T := W (Lo + I);
         W (Lo + I) := W (Hi - I);
         W (Hi - I) := T;
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
   is
      S0 : constant Value_Array := W with Ghost;
      L, R, Mid : Positive;
      P  : Value;
      S2 : Value_Array (W'Range) with Ghost;
   begin
      for I in Start .. Hi loop
         pragma Loop_Invariant (Sorted (W, Lo, I - 1));
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
         for J in reverse L .. I - 1 loop
            W (J + 1) := W (J);
            pragma Loop_Invariant (for all K in J + 1 .. I => W (K) = S2 (K - 1));
            pragma Loop_Invariant (for all K in W'Range => (if K < J or else K > I then W (K) = S2 (K)));
         end loop;
         W (L) := P;
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
   is
      Tmp : constant Value_Array (1 .. M - B1 + 1) := W (B1 .. M);
      S0  : constant Value_Array := W with Ghost;
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
         pragma Loop_Variant (Increases => K);
         if J <= E2 and then W (J) < Tmp (I) then
            W (K) := W (J);
            J := J + 1;
         else
            W (K) := Tmp (I);
            I := I + 1;
         end if;
         K := K + 1;
      end loop;
      pragma Assert (K = J);
      pragma Assert (for all X in K .. E2 => W (X) = S0 (X));
      pragma Assert (Sorted (S0, K, E2));
      pragma Assert (Sorted (W, K, E2));
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
      Len    : array (1 .. Max_Len + 1) of Natural := [others => 0];
      Top    : Natural := 0;
      Pushes : Natural := 0;
      R, Force, Idx : Natural;

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
                  Reverse_Run (Output, Lo, Lo + R - 1);
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
               Binary_Insertion (Output, Lo, Lo + R, Lo + Force - 1);
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
               pragma Loop_Variant (Decreases => Top);
               Idx := Top - 1;
               if (Idx > 1 and then Len (Idx - 1) <= Len (Idx) + Len (Idx + 1))
                 or else (Idx > 2 and then Len (Idx - 2) <= Len (Idx - 1) + Len (Idx))
               then
                  if Len (Idx - 1) < Len (Idx + 1) then
                     Idx := Idx - 1;
                  end if;
                  Merge_At (Idx, Lo);
               elsif Len (Idx) <= Len (Idx + 1) then
                  Merge_At (Idx, Lo);
               else
                  exit;
               end if;
            end loop;
         end loop;
         --  merge_force_collapse
         while Top > 1 loop
            pragma Loop_Invariant (Top <= Pushes and then Count + Top = 2 * Pushes and then Pushes <= N);
            pragma Loop_Invariant (Count >= 1 and then Log (1).Kind = Push and then Log (1).A = Input'First);
            pragma Loop_Invariant (Lo = Input'Last + 1 and then Stack_Ok (Lo));
            pragma Loop_Variant (Decreases => Top);
            Idx := Top - 1;
            if Idx > 1 and then Len (Idx - 1) < Len (Idx + 1) then
               Idx := Idx - 1;
            end if;
            Merge_At (Idx, Lo);
         end loop;
         pragma Assert (Top = 1 and then Base (1) = Input'First and then Base (1) + (Len (1) - 1) = Input'Last);
      end;
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
