pragma Ada_2022;

package body Patience_Sort with SPARK_Mode => On is

   ---------------------------------------------------------------------------
   --  Permutation lemmas (ghost, proved)
   ---------------------------------------------------------------------------

   procedure Lemma_Occ_Frame (A, B : Input_Array; Last : Natural)
   with Ghost, Global => null,
        Pre                => Last <= Index'Last and then (for all K in 1 .. Last => A (K) = B (K)),
        Post               => (for all V in Value => Occ (A, V, Last) = Occ (B, V, Last)),
        Subprogram_Variant => (Decreases => Last);

   procedure Lemma_Occ_Frame (A, B : Input_Array; Last : Natural) is
   begin
      if Last > 0 then
         Lemma_Occ_Frame (A, B, Last - 1);
      end if;
   end Lemma_Occ_Frame;

   procedure Lemma_Occ_Set (A, B : Input_Array; K : Index; Last : Natural)
   with Ghost, Global => null,
        Pre                => Last in K .. Index'Last
                              and then (for all J in Index => (if J /= K then A (J) = B (J))),
        Post               => (for all V in Value =>
                                 Occ (B, V, Last) = Occ (A, V, Last) - (if A (K) = V then 1 else 0)
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

   procedure Lemma_Swap (A, B : Input_Array; X, Y : Index)
   with Ghost, Global => null,
        Pre  => B (X) = A (Y) and then B (Y) = A (X)
                and then (for all J in Index => (if J /= X and then J /= Y then A (J) = B (J))),
        Post => Is_Perm (A, B);

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

   procedure Swap (A : in out Input_Array; X, Y : Index)
   with Global => null,
        Post   => A (X) = A'Old (Y) and then A (Y) = A'Old (X)
                  and then (for all J in Index => (if J /= X and then J /= Y then A (J) = A'Old (J)))
                  and then Is_Perm (A'Old, A);

   procedure Swap (A : in out Input_Array; X, Y : Index) is
      Before : constant Input_Array := A with Ghost;
      T      : constant Value := A (X);
   begin
      A (X) := A (Y);
      A (Y) := T;
      Lemma_Swap (Before, A, X, Y);
   end Swap;

   --  Move A (From) down to To, shifting A (To .. From - 1) up by one slot
   --  (adjacent exchanges).
   procedure Rotate (A : in out Input_Array; To, From : Index)
   with Global => null,
        Pre    => To <= From,
        Post   => A (To) = A'Old (From)
                  and then (for all P in To + 1 .. From => A (P) = A'Old (P - 1))
                  and then (for all P in Index => (if P < To or else P > From then A (P) = A'Old (P)))
                  and then Is_Perm (A'Old, A);

   procedure Rotate (A : in out Input_Array; To, From : Index) is
      Old : constant Input_Array := A with Ghost;
      J   : Index := From;
   begin
      Lemma_Occ_Frame (Old, A, Index'Last);
      while J > To loop
         pragma Loop_Invariant (J in To .. From);
         pragma Loop_Invariant (A (J) = Old (From));
         pragma Loop_Invariant (for all P in J + 1 .. From => A (P) = Old (P - 1));
         pragma Loop_Invariant (for all P in Index => (if P < J or else P > From then A (P) = Old (P)));
         pragma Loop_Invariant (Is_Perm (Old, A));
         pragma Loop_Variant (Decreases => J);
         Swap (A, J - 1, J);
         J := J - 1;
      end loop;
   end Rotate;

   ---------------------------------------------------------------------------
   --  Piles (ghost): pile Q is A (E (Q - 1) + 1 .. E (Q)), top at E (Q).
   ---------------------------------------------------------------------------

   subtype Slot is Natural range 0 .. Index'Last;
   type Ends is array (0 .. Index'Last) of Slot;
   subtype Lo_Slot is Positive range 1 .. Index'Last + 1;

   --  A (Lo .. Hi) is nonincreasing (every pair, not only neighbours).
   function Pile_Ok (A : Input_Array; Lo : Positive; Hi : Natural) return Boolean is
     (for all I in Lo .. Hi => (for all J in I .. Hi => A (I) >= A (J)))
   with Ghost, Pre => Hi <= Index'Last;

   --  E (0 .. Np) is nondecreasing (every pair).
   function Chain (E : Ends; Np : Slot) return Boolean is
     (for all Q in 0 .. Np => (for all R in Q .. Np => E (Q) <= E (R)))
   with Ghost;

   function Piles_Ok (A : Input_Array; E : Ends; Np : Slot) return Boolean is
     (for all Q in 1 .. Np => Pile_Ok (A, E (Q - 1) + 1, E (Q)))
   with Ghost;

   --  A pile moved by D slots stays nonincreasing.
   procedure Lemma_Shift (Old, A : Input_Array; Lo : Lo_Slot; Hi : Slot; D : Slot)
   with Ghost, Global => null,
        Pre  => Lo >= 1 and then D <= 1 and then Hi + D <= Index'Last
                and then Pile_Ok (Old, Lo, Hi)
                and then (for all P in Lo .. Hi => A (P + D) = Old (P)),
        Post => Pile_Ok (A, Lo + D, Hi + D);

   procedure Lemma_Shift (Old, A : Input_Array; Lo : Lo_Slot; Hi : Slot; D : Slot) is null;

   --  A key no larger than the top, put on top, keeps the pile nonincreasing.
   procedure Lemma_Extend (Old, A : Input_Array; Lo : Index; Hi : Slot)
   with Ghost, Global => null,
        Pre  => Lo >= 1 and then Lo <= Hi and then Hi < Index'Last
                and then Pile_Ok (Old, Lo, Hi)
                and then (for all P in Lo .. Hi => A (P) = Old (P))
                and then A (Hi + 1) <= Old (Hi),
        Post => Pile_Ok (A, Lo, Hi + 1);

   procedure Lemma_Extend (Old, A : Input_Array; Lo : Index; Hi : Slot) is null;

   --  Every slot Lo + 1 .. E (Np) lies in some pile.
   procedure Lemma_In_Pile (E : Ends; Np : Slot; J : Index)
   with Ghost, Global => null,
        Pre  => Np >= 1 and then Chain (E, Np) and then J > E (0) and then J <= E (Np),
        Post => (for some R in 1 .. Np => J in E (R - 1) + 1 .. E (R));

   procedure Lemma_In_Pile (E : Ends; Np : Slot; J : Index) is
   begin
      for R in 1 .. Np loop
         pragma Loop_Invariant (J > E (R - 1));
         if J <= E (R) then
            pragma Assert (J in E (R - 1) + 1 .. E (R));
            return;
         end if;
      end loop;
   end Lemma_In_Pile;

   ---------------------------------------------------------------------------

   procedure Sort_Traced
     (Input : Input_Array; Output : out Input_Array; Deal, Take : out Pile_Log; Piles : out Index)
   is
      A     : Input_Array := Input;
      E     : Ends := [others => 0];
      Np    : Slot := 0;
      Found : Slot;
      Old   : Input_Array with Ghost;
      E0    : Ends with Ghost;
   begin
      Deal := [others => 1];
      Lemma_Occ_Frame (Input, A, Index'Last);
      --  Deal: key K goes on the leftmost pile whose top is >= it.
      for K in Index loop
         pragma Loop_Invariant (Is_Perm (Input, A));
         pragma Loop_Invariant (Np <= K - 1 and then E (0) = 0 and then E (Np) = K - 1);
         pragma Loop_Invariant (for all Q in 1 .. Np => E (Q - 1) < E (Q));
         pragma Loop_Invariant (Chain (E, Np));
         pragma Loop_Invariant (Piles_Ok (A, E, Np));
         Found := 0;
         for Q in 1 .. Np loop
            if A (E (Q)) >= A (K) then
               Found := Q;
               exit;
            end if;
         end loop;
         if Found = 0 then
            Np := Np + 1;
            E (Np) := K;
            Deal (K) := Np;
            pragma Assert (Pile_Ok (A, K, K));
            pragma Assert (Piles_Ok (A, E, Np));
         else
            Old := A;
            E0 := E;
            Rotate (A, E (Found) + 1, K);
            E := [for Q in 0 .. Index'Last => (if Q in Found .. Np then E (Q) + 1 else E (Q))];
            Deal (K) := Found;
            pragma Assert (for all Q in 1 .. Np => E (Q - 1) < E (Q));
            pragma Assert (Chain (E, Np));
            for Q in 1 .. Np loop
               pragma Loop_Invariant (for all R in 1 .. Q - 1 => Pile_Ok (A, E (R - 1) + 1, E (R)));
               if Q < Found then
                  Lemma_Shift (Old, A, E0 (Q - 1) + 1, E0 (Q), 0);
               elsif Q = Found then
                  Lemma_Extend (Old, A, E0 (Q - 1) + 1, E0 (Q));
               else
                  Lemma_Shift (Old, A, E0 (Q - 1) + 1, E0 (Q), 1);
               end if;
            end loop;
         end if;
      end loop;
      Piles := Np;
      --  Output: A (1 .. E (0)) is the sorted output; repeatedly move the
      --  smallest pile top to its end.
      for M in Index loop
         pragma Loop_Invariant (Is_Perm (Input, A));
         pragma Loop_Invariant (Np >= 1 and then E (0) = M - 1 and then E (Np) = Index'Last);
         pragma Loop_Invariant (Chain (E, Np));
         pragma Loop_Invariant (Piles_Ok (A, E, Np));
         pragma Loop_Invariant (for all I in 1 .. M - 2 => A (I) <= A (I + 1));
         pragma Loop_Invariant (for all I in 1 .. M - 1 => (for all J in M .. Index'Last => A (I) <= A (J)));
         Found := 0;
         for Q in 1 .. Np loop
            if E (Q - 1) < E (Q) and then (Found = 0 or else A (E (Q)) < A (E (Found))) then
               Found := Q;
            end if;
            pragma Loop_Invariant (if Found = 0 then E (Q) = E (0));
            pragma Loop_Invariant
              (if Found /= 0 then Found <= Q and then E (Found - 1) < E (Found)
                  and then (for all R in 1 .. Q => (if E (R - 1) < E (R) then A (E (Found)) <= A (E (R)))));
         end loop;
         pragma Assert (Found /= 0);
         --  The smallest top is the smallest remaining key.
         for J in M .. Index'Last loop
            pragma Loop_Invariant (for all P in M .. J - 1 => A (E (Found)) <= A (P));
            Lemma_In_Pile (E, Np, J);
            pragma Assert (A (E (Found)) <= A (J));
         end loop;
         pragma Assert (for all P in M .. Index'Last => A (E (Found)) <= A (P));
         Old := A;
         E0 := E;
         Rotate (A, M, E (Found));
         pragma Assert (for all P in M + 1 .. Index'Last => A (M) <= A (P));
         pragma Assert (for all I in 1 .. M - 1 => A (I) = Old (I));
         pragma Assert (for all I in 1 .. M - 1 => A (I) <= A (M));
         pragma Assert (for all I in 1 .. M - 1 => (for all J in M + 1 .. Index'Last => A (I) <= A (J)));
         E := [for Q in 0 .. Index'Last => (if Q < Found then E (Q) + 1 else E (Q))];
         Take (M) := Found;
         pragma Assert (Chain (E, Np));
         pragma Assert (E (Found) = E0 (Found) and then E0 (Found) <= Index'Last);
         for Q in 1 .. Np loop
            pragma Loop_Invariant (for all R in 1 .. Q - 1 => Pile_Ok (A, E (R - 1) + 1, E (R)));
            if Q < Found then
               Lemma_Shift (Old, A, E0 (Q - 1) + 1, E0 (Q), 1);
            elsif Q = Found then
               pragma Assert (Pile_Ok (Old, E0 (Q - 1) + 1, E0 (Q) - 1));
               Lemma_Shift (Old, A, E0 (Q - 1) + 1, E0 (Q) - 1, 1);
            else
               Lemma_Shift (Old, A, E0 (Q - 1) + 1, E0 (Q), 0);
            end if;
         end loop;
      end loop;
      Output := A;
   end Sort_Traced;

   function Sort (Input : Input_Array) return Input_Array is
      Output     : Input_Array;
      Deal, Take : Pile_Log;
      Piles      : Index;
   begin
      Sort_Traced (Input, Output, Deal, Take, Piles);
      pragma Assert (Piles in Index and then Deal (1) in Index and then Take (1) in Index);
      return Output;
   end Sort;
end Patience_Sort;
