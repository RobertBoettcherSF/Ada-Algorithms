pragma Ada_2022;

package body Tim_Sort with SPARK_Mode => On is

   ---------------------------------------------------------------------------
   --  Permutation lemmas (ghost; proved, and run under -gnata only as
   --  cheap calls whose contracts are checked).
   ---------------------------------------------------------------------------

   --  Counts over 1 .. Last only see 1 .. Last.
   procedure Lemma_Occ_Frame (A, B : Input_Array; Last : Natural)
   with Ghost,
        Global             => null,
        Pre                => Last <= Index'Last
                              and then (for all K in 1 .. Last => A (K) = B (K)),
        Post               => (for all V in Value => Occ (A, V, Last) = Occ (B, V, Last)),
        Subprogram_Variant => (Decreases => Last);

   procedure Lemma_Occ_Frame (A, B : Input_Array; Last : Natural) is
   begin
      if Last > 0 then
         Lemma_Occ_Frame (A, B, Last - 1);
      end if;
   end Lemma_Occ_Frame;

   --  B is A with slot K changed.
   procedure Lemma_Occ_Set (A, B : Input_Array; K : Index; Last : Natural)
   with Ghost,
        Global             => null,
        Pre                => Last in K .. Index'Last
                              and then (for all J in Index => (if J /= K then A (J) = B (J))),
        Post               => (for all V in Value =>
                                 Occ (B, V, Last)
                                 = Occ (A, V, Last)
                                   - (if A (K) = V then 1 else 0)
                                   + (if B (K) = V then 1 else 0)),
        Subprogram_Variant => (Decreases => Last);

   procedure Lemma_Occ_Set (A, B : Input_Array; K : Index; Last : Natural) is
   begin
      if Last > K then
         Lemma_Occ_Set (A, B, K, Last - 1);
      else
         Lemma_Occ_Frame (A, B, K - 1);
      end if;
   end Lemma_Occ_Set;

   --  B is A with slots X and Y exchanged.
   procedure Lemma_Swap (A, B : Input_Array; X, Y : Index)
   with Ghost,
        Global => null,
        Pre    => B (X) = A (Y) and then B (Y) = A (X)
                  and then (for all J in Index =>
                              (if J /= X and then J /= Y then A (J) = B (J))),
        Post   => Is_Perm (A, B);

   procedure Lemma_Swap (A, B : Input_Array; X, Y : Index) is
      C : constant Input_Array := [A with delta X => A (Y)];
   begin
      if X = Y then
         Lemma_Occ_Frame (A, B, Index'Last);
      else
         Lemma_Occ_Set (A, C, X, Index'Last);
         Lemma_Occ_Set (C, B, Y, Index'Last);
      end if;
   end Lemma_Swap;

   --  Exchange A (X) and A (Y).
   procedure Swap (A : in out Input_Array; X, Y : Index)
   with Global => null,
        Post   => A (X) = A'Old (Y) and then A (Y) = A'Old (X)
                  and then (for all J in Index =>
                              (if J /= X and then J /= Y then A (J) = A'Old (J)))
                  and then Is_Perm (A'Old, A);

   procedure Swap (A : in out Input_Array; X, Y : Index) is
      Before    : constant Input_Array := A with Ghost;
      Temporary : constant Value := A (X);
   begin
      A (X) := A (Y);
      A (Y) := Temporary;
      Lemma_Swap (Before, A, X, Y);
   end Swap;

   --  Is_Perm is transitive (proof only).
   procedure Lemma_Trans (A, B, C : Input_Array)
   with Ghost, Global => null,
        Pre  => Is_Perm (A, B) and then Is_Perm (B, C),
        Post => Is_Perm (A, C)
   is
   begin
      null;
   end Lemma_Trans;

   procedure Sort_Traced
     (Input  : Input_Array; Output : out Input_Array; Trace : out Network;
      Length : out Natural; Run : out Natural; Reversed : out Boolean)
   is
      W  : Input_Array := Input;
      R  : Index := 2;
      Lo, Hi, Mid : Positive;
      P  : Value;
      S2 : Input_Array with Ghost;
      Before : Input_Array with Ghost;
   begin
      Trace := [others => (1, 1)];
      Lemma_Occ_Frame (Input, W, Index'Last);
      Length := 1;
      Trace (1) := (1, 2);
      Reversed := Input (2) < Input (1);
      if Reversed then
         while R < Index'Last loop
            pragma Loop_Invariant (Length in 1 .. R and then W = Input and then Trace (1) = (1, 2));
            pragma Loop_Invariant (for all K in 1 .. R - 1 => Input (K + 1) < Input (K));
            pragma Loop_Variant (Increases => R);
            Length := Length + 1;
            Trace (Length) := (R, R + 1);
            exit when not (W (R + 1) < W (R));
            R := R + 1;
         end loop;
         --  reverse W (1 .. R)
         for I in 1 .. R / 2 loop
            Before := W;
            Swap (W, I, R + 1 - I);
            Lemma_Trans (Input, Before, W);
            pragma Loop_Invariant (Is_Perm (Input, W));
            pragma Loop_Invariant
              (for all K in 1 .. I => W (K) = Input (R + 1 - K) and then W (R + 1 - K) = Input (K));
            pragma Loop_Invariant (for all K in I + 1 .. R - I => W (K) = Input (K));
            pragma Loop_Invariant (for all K in R + 1 .. Index'Last => W (K) = Input (K));
         end loop;
         pragma Assert (for all K in 1 .. R => W (K) = Input (R + 1 - K));
         pragma Assert (for all K in 1 .. R - 1 => W (K) <= W (K + 1));
      else
         while R < Index'Last loop
            pragma Loop_Invariant (Length in 1 .. R and then W = Input and then Trace (1) = (1, 2));
            pragma Loop_Invariant (for all K in 1 .. R - 1 => Input (K) <= Input (K + 1));
            pragma Loop_Variant (Increases => R);
            Length := Length + 1;
            Trace (Length) := (R, R + 1);
            exit when W (R + 1) < W (R);
            R := R + 1;
         end loop;
      end if;
      Run := R;
      --  pairwise sorted prefix
      pragma Assert (for all K in 1 .. R - 1 => W (K) <= W (K + 1));
      for B in 1 .. R loop
         pragma Loop_Invariant (for all X in 1 .. B - 1 => (for all Y in X .. B - 1 => W (X) <= W (Y)));
      end loop;
      pragma Assert (for all X in 1 .. R => (for all Y in X .. R => W (X) <= W (Y)));
      --  binarysort of W (R + 1 .. 8)
      for I in R + 1 .. Index'Last loop
         pragma Loop_Invariant (Is_Perm (Input, W));
         pragma Loop_Invariant (Length in 1 .. 8 * (I - 1) and then Trace (1) = (1, 2));
         pragma Loop_Invariant (for all X in 1 .. I - 1 => (for all Y in X .. I - 1 => W (X) <= W (Y)));
         P  := W (I);
         Lo := 1;
         Hi := I;
         while Lo < Hi loop
            pragma Loop_Invariant (1 <= Lo and then Lo < Hi and then Hi <= I);
            pragma Loop_Invariant (Length >= 1 and then Length + (Hi - Lo) <= 8 * (I - 1) + I - 1 and then Trace (1) = (1, 2));
            pragma Loop_Invariant (for all K in 1 .. Lo - 1 => W (K) <= P);
            pragma Loop_Invariant (for all K in Hi .. I - 1 => P < W (K));
            pragma Loop_Variant (Decreases => Hi - Lo);
            Mid := (Lo + Hi) / 2;
            Length := Length + 1;
            Trace (Length) := (Mid, I);
            if P < W (Mid) then
               Hi := Mid;
            else
               Lo := Mid + 1;
            end if;
         end loop;
         S2 := W;
         pragma Assert (Lo = Hi and then S2 (I) = P);
         pragma Assert (for all K in 1 .. Lo - 1 => S2 (K) <= P);
         pragma Assert (for all K in Lo .. I - 1 => P < S2 (K));
         pragma Assert (for all X in 1 .. I - 1 => (for all Y in X .. I - 1 => S2 (X) <= S2 (Y)));
         for J in reverse Lo .. I - 1 loop
            Before := W;
            Swap (W, J, J + 1);
            Lemma_Trans (Input, Before, W);
            pragma Loop_Invariant (Is_Perm (Input, W));
            pragma Loop_Invariant (W (J) = P);
            pragma Loop_Invariant (for all K in J + 1 .. I => W (K) = S2 (K - 1));
            pragma Loop_Invariant (for all K in 1 .. J - 1 => W (K) = S2 (K));
            pragma Loop_Invariant (for all K in I + 1 .. Index'Last => W (K) = S2 (K));
         end loop;
         pragma Assert (W (Lo) = P);
         pragma Assert (for all K in 1 .. Lo - 1 => W (K) = S2 (K));
         pragma Assert (for all K in Lo + 1 .. I => W (K) = S2 (K - 1));
         pragma Assert (for all X in 1 .. Lo - 1 => (for all Y in X .. Lo - 1 => W (X) <= W (Y)));
         pragma Assert (for all X in 1 .. Lo => W (X) <= W (Lo));
         pragma Assert (for all Y in Lo .. I => W (Lo) <= W (Y));
         pragma Assert (for all X in Lo + 1 .. I => (for all Y in X .. I => W (X) <= W (Y)));
         pragma Assert (for all X in 1 .. Lo - 1 => (for all Y in Lo + 1 .. I => W (X) <= W (Y)));
         pragma Assert (for all X in 1 .. I => (for all Y in X .. I => W (X) <= W (Y)));
      end loop;
      Output := W;
   end Sort_Traced;

   function Sort (Input : Input_Array) return Input_Array is
      Output   : Input_Array;
      Trace    : Network (1 .. Max_Trace);
      Length   : Natural;
      Run      : Natural;
      Reversed : Boolean;
   begin
      Sort_Traced (Input, Output, Trace, Length, Run, Reversed);
      pragma Assert (Length <= Max_Trace and then Run >= 2 and then Trace (1) = (1, 2)
                     and then Reversed = (Input (2) < Input (1)));
      return Output;
   end Sort;
end Tim_Sort;
