pragma SPARK_Mode (On);

with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;

package body Paint_Fence_Lite is
   package LLI_Conversions is new Signed_Conversions (Long_Long_Integer);
   function Big (X : Long_Long_Integer) return Big_Integer renames LLI_Conversions.To_Big_Integer;

   --  W = P M + R with 0 <= R < M means R = W mod M.
   procedure Lemma_Mod_Unique (W, R : Long_Long_Integer; P : Big_Integer; M : Modulus)
   with
     Ghost,
     Global => null,
     Pre    => W >= 0 and then R in 0 .. Long_Long_Integer (M) - 1
               and then Big (W) = P * Big (Long_Long_Integer (M)) + Big (R),
     Post   => Md (W, M) = R;

   procedure Lemma_Mod_Unique (W, R : Long_Long_Integer; P : Big_Integer; M : Modulus) is
      MM : constant Big_Integer := Big (Long_Long_Integer (M));
      Q  : constant Big_Integer := Big (W / Long_Long_Integer (M));
      D  : constant Big_Integer := P - Q;
   begin
      pragma Assert (Big (W) = Q * MM + Big (Md (W, M)));
      pragma Assert (D * MM = Big (Md (W, M)) - Big (R));
      if D >= 1 then
         pragma Assert (D * MM >= MM);
      elsif D <= -1 then
         pragma Assert (D * MM <= -MM);
      end if;
      pragma Assert (D = 0);
   end Lemma_Mod_Unique;

   --  (A X mod M + A Y mod M) mod M = A ((X + Y) mod M) mod M.
   procedure Lemma_Distrib (A, X, Y : Residue; M : Modulus)
   with
     Ghost,
     Global => null,
     Pre    => A < Long_Long_Integer (M) and then X < Long_Long_Integer (M) and then Y < Long_Long_Integer (M),
     Post   => Md (Md (A * X, M) + Md (A * Y, M), M) = Md (A * Md (X + Y, M), M);

   procedure Lemma_Distrib (A, X, Y : Residue; M : Modulus) is
      MM  : constant Long_Long_Integer := Long_Long_Integer (M);
      RX  : constant Long_Long_Integer := Md (A * X, M);
      RY  : constant Long_Long_Integer := Md (A * Y, M);
      S   : constant Long_Long_Integer := Md (RX + RY, M);
      T2  : constant Long_Long_Integer := Md (X + Y, M);
      R2  : constant Long_Long_Integer := Md (A * T2, M);
      Sum : constant Big_Integer := Big (A) * Big (X) + Big (A) * Big (Y);
   begin
      --  A X + A Y = (A X / M + A Y / M + (RX + RY) / M) M + S.
      pragma Assert (Big (A * X) = Big ((A * X) / MM) * Big (MM) + Big (RX));
      pragma Assert (Big (A * Y) = Big ((A * Y) / MM) * Big (MM) + Big (RY));
      pragma Assert (Big (RX + RY) = Big ((RX + RY) / MM) * Big (MM) + Big (S));
      pragma Assert (Sum = (Big ((A * X) / MM) + Big ((A * Y) / MM) + Big ((RX + RY) / MM)) * Big (MM) + Big (S));
      --  A X + A Y = A T2 + A ((X + Y) / M) M = ((A T2) / M + A ((X + Y) / M)) M + R2.
      pragma Assert (Big (X + Y) = Big ((X + Y) / MM) * Big (MM) + Big (T2));
      pragma Assert (Big (A * T2) = Big ((A * T2) / MM) * Big (MM) + Big (R2));
      pragma Assert (Sum = (Big ((A * T2) / MM) + Big (A) * Big ((X + Y) / MM)) * Big (MM) + Big (R2));
      pragma Assert (Big (A * X + A * Y) = Sum);
      Lemma_Mod_Unique (A * X + A * Y, S, Big ((A * X) / MM) + Big ((A * Y) / MM) + Big ((RX + RY) / MM), M);
      Lemma_Mod_Unique (A * X + A * Y, R2, Big ((A * T2) / MM) + Big (A) * Big ((X + Y) / MM), M);
      pragma Assert (S = R2);
   end Lemma_Distrib;

   function Count (N : Number_Of_Posts; K : Colours; M : Modulus) return Natural is
      K1   : constant Residue := Md (Long_Long_Integer (K) - 1, M);
      X    : constant Residue := Md (Long_Long_Integer (K), M);
      --  Colourings of the posts so far whose last two posts have the same
      --  colour, and those whose last two differ (mod M).
      Same : Residue;
      Diff : Residue;
      Old  : Residue;
   begin
      if N = 1 then
         return Natural (X);
      elsif M = 1 then
         return 0;    --  every residue mod 1 is 0
      end if;
      --  Two posts: K equal pairs, K (K - 1) different pairs.
      Same := X;
      Diff := Md (K1 * X, M);
      --  X + K1 X = (1 + K1) X = X X (mod M), since 1 + K1 = K (mod M).
      Lemma_Distrib (X, 1, K1, M);
      Lemma_Mod_Unique (Long_Long_Integer (K), Md (1 + K1, M),
                        Big ((Long_Long_Integer (K) - 1) / Long_Long_Integer (M)) + Big ((1 + K1) / Long_Long_Integer (M)), M);
      pragma Assert (Md (1 + K1, M) = X);
      pragma Assert (Md (Same + Diff, M) = T (2, K, M));
      for I in 3 .. N loop
         pragma Loop_Invariant (Same < Long_Long_Integer (M) and then Diff < Long_Long_Integer (M));
         pragma Loop_Invariant
           (declare
              TT : constant Two_Terms := Terms (I - 1, K, M);
            begin
              Md (Same + Diff, M) = TT.Cur and then Diff = Md (K1 * TT.Prev, M));
         declare
            TT : constant Two_Terms := Terms (I - 1, K, M) with Ghost;
         begin
            Old := Diff;
            Diff := Md (K1 * Md (Same + Diff, M), M);
            Same := Old;
            Lemma_Distrib (K1, TT.Prev, TT.Cur, M);
            pragma Assert (Md (Same + Diff, M) = Step (TT, K, M).Cur);
         end;
      end loop;
      return Natural (Md (Same + Diff, M));
   end Count;
end Paint_Fence_Lite;
