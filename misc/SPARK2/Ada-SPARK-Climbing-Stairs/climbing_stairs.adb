pragma Ada_2022;
package body Climbing_Stairs with SPARK_Mode => On is

   procedure Lemma_Facts is null;

   --  Stepping up with A = Ways (J), B = Ways (J - 1).
   function Count (N : Steps) return Positive is
      A : Positive := 1;
      B : Natural  := 0;
   begin
      Lemma_Facts;
      for J in 1 .. N loop
         pragma Loop_Invariant (To_Big_Integer (A) = Ways (J - 1) and then A <= 1_836_311_903);
         pragma Loop_Invariant (if J = 1 then B = 0 else To_Big_Integer (B) = Ways (J - 2));
         pragma Assert (if J = 1 then Ways (1) = 1 else Ways (J) = Ways (J - 1) + Ways (J - 2));
         pragma Assert (Ways (J) <= 1_836_311_903);
         declare
            Sum : constant Positive := A + B;
         begin
            B := A;
            A := Sum;
         end;
      end loop;
      return A;
   end Count;

   --  Prefix_Sum and Rank_Upto read only the first J steps.
   procedure Lemma_Same_Prefix (A, B : Step_List; N : Steps; J : Natural)
   with
     Ghost,
     Global             => null,
     Pre                => A'First = 1 and then B'First = 1 and then A'Last <= Max_Stairs
                           and then B'Last <= Max_Stairs and then J <= A'Last and then J <= B'Last
                           and then (for all I in 1 .. J => A (I) = B (I)),
     Post               => Prefix_Sum (A, J) = Prefix_Sum (B, J)
                           and then (if Prefix_Sum (A, J) <= N then Rank_Upto (A, N, J) = Rank_Upto (B, N, J)),
     Subprogram_Variant => (Decreases => J);

   procedure Lemma_Same_Prefix (A, B : Step_List; N : Steps; J : Natural) is
   begin
      if J > 0 then
         Lemma_Same_Prefix (A, B, N, J - 1);
      end if;
   end Lemma_Same_Prefix;

   function Climb (N : Steps; K : Natural) return Step_List is
      Buf  : Step_List (1 .. N) := [others => 1];
      P    : Natural := 0;
      R    : Natural := N;
      Left : Natural := K;
      A    : Natural := Count (N);                           --  Ways (R)
      B    : Natural := (if N = 0 then 0 else Count (N - 1));  --  Ways (R - 1)
   begin
      Lemma_Facts;
      while R > 0 loop
         pragma Loop_Invariant (R <= N and then P <= N - R);
         pragma Loop_Invariant (To_Big_Integer (A) = Ways (R) and then To_Big_Integer (B) = Ways (R - 1));
         pragma Loop_Invariant (Prefix_Sum (Buf, P) = N - R);
         pragma Loop_Invariant (Rank_Upto (Buf, N, P) + To_Big_Integer (Left) = To_Big_Integer (K));
         pragma Loop_Invariant (Left < A);
         pragma Loop_Variant (Decreases => R);
         declare
            Old : constant Step_List (1 .. N) := Buf with Ghost;
         begin
            if R >= 2 then
               pragma Assert (Ways (R) = Ways (R - 1) + Ways (R - 2));
            else
               pragma Assert (Ways (1) = 1 and then Ways (0) = 1);
            end if;
            if Left < B then
               --  Single step: the climb is among the first Ways (R - 1).
               Buf (P + 1) := 1;
               Lemma_Same_Prefix (Old, Buf, N, P);
               R := R - 1;
               declare
                  Next_B : constant Natural := A - B;    --  Ways (R - 2)
               begin
                  A := B;
                  B := Next_B;
               end;
            else
               --  Double step: skip the Ways (R - 1) climbs starting single.
               Buf (P + 1) := 2;
               Lemma_Same_Prefix (Old, Buf, N, P);
               Left := Left - B;
               R := R - 2;
               declare
                  Next_A : constant Natural := A - B;    --  Ways (R - 2)
               begin
                  A := Next_A;
                  B := B - Next_A;                       --  Ways (R - 3)
               end;
            end if;
            P := P + 1;
         end;
      end loop;
      pragma Assert (Left = 0);
      Lemma_Same_Prefix (Buf, Buf (1 .. P), N, P);
      return Buf (1 .. P);
   end Climb;
end Climbing_Stairs;
