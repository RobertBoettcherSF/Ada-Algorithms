pragma Ada_2022;
package body Climbing_Stairs with SPARK_Mode => On is

   type Big_Table is array (0 .. Max_Stairs + 1) of Big_Integer with Ghost;

   function Table_Facts (T : Big_Table) return Boolean is
     (T (0) = 1 and then T (1) = 1
      and then (for all J in 2 .. Max_Stairs + 1 => T (J) = T (J - 1) + T (J - 2))
      and then (for all J in Steps => T (J) >= 1 and then T (J) <= T (Max_Stairs))
      and then T (Max_Stairs) = 1_836_311_903
      and then T (Max_Stairs + 1) > To_Big_Integer (Natural'Last))
   with Ghost;

   --  Ways (0 .. 46) by the recurrence; run once, at elaboration.
   function Compute return Big_Table
   with Ghost, Global => null, Post => Table_Facts (Compute'Result);

   function Compute return Big_Table is
      T : Big_Table := [others => To_Big_Integer (1)];
   begin
      for J in 2 .. Max_Stairs + 1 loop
         pragma Loop_Invariant (T (0) = 1 and then T (1) = 1);
         pragma Loop_Invariant (for all I in 2 .. J - 1 => T (I) = T (I - 1) + T (I - 2));
         pragma Loop_Invariant (for all I in 0 .. J - 1 => T (I) >= 1 and then T (I) <= T (J - 1));
         T (J) := T (J - 1) + T (J - 2);
      end loop;
      pragma Assert (T (2) = 2);
      pragma Assert (T (3) = 3);
      pragma Assert (T (4) = 5);
      pragma Assert (T (5) = 8);
      pragma Assert (T (6) = 13);
      pragma Assert (T (7) = 21);
      pragma Assert (T (8) = 34);
      pragma Assert (T (9) = 55);
      pragma Assert (T (10) = 89);
      pragma Assert (T (11) = 144);
      pragma Assert (T (12) = 233);
      pragma Assert (T (13) = 377);
      pragma Assert (T (14) = 610);
      pragma Assert (T (15) = 987);
      pragma Assert (T (16) = 1_597);
      pragma Assert (T (17) = 2_584);
      pragma Assert (T (18) = 4_181);
      pragma Assert (T (19) = 6_765);
      pragma Assert (T (20) = 10_946);
      pragma Assert (T (21) = 17_711);
      pragma Assert (T (22) = 28_657);
      pragma Assert (T (23) = 46_368);
      pragma Assert (T (24) = 75_025);
      pragma Assert (T (25) = 121_393);
      pragma Assert (T (26) = 196_418);
      pragma Assert (T (27) = 317_811);
      pragma Assert (T (28) = 514_229);
      pragma Assert (T (29) = 832_040);
      pragma Assert (T (30) = 1_346_269);
      pragma Assert (T (31) = 2_178_309);
      pragma Assert (T (32) = 3_524_578);
      pragma Assert (T (33) = 5_702_887);
      pragma Assert (T (34) = 9_227_465);
      pragma Assert (T (35) = 14_930_352);
      pragma Assert (T (36) = 24_157_817);
      pragma Assert (T (37) = 39_088_169);
      pragma Assert (T (38) = 63_245_986);
      pragma Assert (T (39) = 102_334_155);
      pragma Assert (T (40) = 165_580_141);
      pragma Assert (T (41) = 267_914_296);
      pragma Assert (T (42) = 433_494_437);
      pragma Assert (T (43) = 701_408_733);
      pragma Assert (T (44) = 1_134_903_170);
      pragma Assert (T (45) = 1_836_311_903);
      pragma Assert (T (46) = 2_971_215_073);
      return T;
   end Compute;

   Ways_Table : constant Big_Table := Compute with Ghost;

   function Ways (N : Natural) return Big_Integer is (Ways_Table (N));

   --  Stepping up with A = Ways (J), B = Ways (J - 1).
   function Count (N : Steps) return Positive is
      A : Positive := 1;
      B : Natural  := 0;
   begin
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
