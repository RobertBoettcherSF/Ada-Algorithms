--  Version: 0.001
--  Modular_Arithmetic.CRT body and proofs.

pragma Ada_2022;

with Modular_Arithmetic.Lemmas;

package body Modular_Arithmetic.CRT
  with SPARK_Mode => On
is

   package L renames Modular_Arithmetic.Lemmas;

   ----------
   -- Crt2 --
   ----------

   function Crt2
     (R1 : Natural_64; M1 : Modulus_Type;
      R2 : Natural_64; M2 : Modulus_Type) return Natural_64
   is
      W1  : constant Wide := Wide (M1);
      W2  : constant Wide := Wide (M2);
      Inv : constant Natural_64 := Inverse (M1, M2);   --  M1 * Inv = 1
      R1m : constant Natural_64 := Reduce (R1, M2);
      D   : constant Natural_64 := Sub_Mod (R2, R1m, M2);  --  R2 - R1
      K   : constant Natural_64 := Mul_Mod (D, Inv, M2);   --  (R2 - R1) / M1
      M1m : constant Natural_64 := Reduce (M1, M2);
      X   : constant Wide := Wide (R1) + W1 * Wide (K);
   begin
      --  Range: X <= (M1 - 1) + M1 * (M2 - 1) < M1 * M2.
      pragma Assert (W1 * Wide (K) <= W1 * (W2 - 1));
      pragma Assert (X < W1 * W2);

      --  X mod M1 = R1.
      L.Mod_Unique (X, Wide (K), Wide (R1), W1);

      --  (M1 mod M2) * Inv = 1 (mod M2).
      L.Mul_Mod_Left (W1, Wide (Inv), W2);
      pragma Assert ((Wide (M1m) * Wide (Inv)) mod W2 = 1);
      --  (M1 mod M2) * K = D (mod M2).
      L.Mul_Assoc (Wide (M1m), Wide (Inv), Wide (D), W2);
      pragma Assert ((Wide (Inv) * Wide (D)) mod W2 = Wide (K));
      pragma Assert
        (((Wide (M1m) * Wide (Inv)) mod W2) * Wide (D) = Wide (D));
      pragma Assert (Wide (D) mod W2 = Wide (D));
      pragma Assert ((Wide (M1m) * Wide (K)) mod W2 = Wide (D));
      --  M1 * K = D (mod M2).
      L.Mul_Mod_Left (W1, Wide (K), W2);
      pragma Assert ((W1 * Wide (K)) mod W2 = Wide (D));
      --  X = R1 + D (mod M2).
      L.Add_Mod_Right (Wide (R1), W1 * Wide (K), W2);
      pragma Assert (X mod W2 = (Wide (R1) + Wide (D)) mod W2);
      --  R1 + ((R2 - R1 mod M2) mod M2) = R2 (mod M2).
      L.Add_Mod_Right (Wide (R1), Wide (R2) - Wide (R1m), W2);
      pragma Assert
        (Wide (R1) + (Wide (R2) - Wide (R1m))
         = Wide (R2) + Wide (R1 / M2) * W2);
      L.Mod_Unique
        (Wide (R2) + Wide (R1 / M2) * W2, Wide (R1 / M2), Wide (R2), W2);
      pragma Assert (X mod W2 = Wide (R2));
      return Natural_64 (X);
   end Crt2;

   -----------------------
   -- Lemma_Crt2_Unique --
   -----------------------

   procedure Lemma_Crt2_Unique (X, Y : Natural_64; M1, M2 : Modulus_Type) is
      W1 : constant Wide := Wide (M1);
      W2 : constant Wide := Wide (M2);

      --  If D = X - Y >= 0 is a multiple of M1 and of M2 and below M1*M2,
      --  then D = 0.
      procedure Zero (A, B : Natural_64)
        with Pre  => Gcd (M1, M2) = 1
                     and then W1 * W2 <= Max_Modulus
                     and then A >= B
                     and then Wide (A) < W1 * W2
                     and then A mod M1 = B mod M1
                     and then A mod M2 = B mod M2,
             Post => A = B
      is
         D   : constant Wide := Wide (A) - Wide (B);
         U   : constant Wide := D / W1;
         Inv : constant Natural_64 := Inverse (M1, M2);
         M1m : constant Wide := W1 mod W2;
      begin
         --  D = M1 * U with 0 <= U < M2.
         L.Mod_Unique
           (Wide (A), Wide (A / M1), Wide (A mod M1), W1);
         pragma Assert (Wide (A) = Wide (A / M1) * W1 + Wide (A mod M1));
         pragma Assert (Wide (B) = Wide (B / M1) * W1 + Wide (B mod M1));
         pragma Assert (D = (Wide (A / M1) - Wide (B / M1)) * W1);
         L.Mod_Unique (D, Wide (A / M1) - Wide (B / M1), 0, W1);
         pragma Assert (D mod W1 = 0);
         L.Div_Mod (D, W1);
         pragma Assert (D = U * W1);
         pragma Assert (D >= 0 and then D <= Wide (A));
         pragma Assert (U * W1 < W1 * W2);
         if U >= W2 then
            pragma Assert (U * W1 >= W2 * W1);
            pragma Assert (W2 * W1 = W1 * W2);
            pragma Assert (False);
         end if;
         pragma Assert (U < W2);
         --  D mod M2 = 0.
         pragma Assert (Wide (A) = Wide (A / M2) * W2 + Wide (A mod M2));
         pragma Assert (Wide (B) = Wide (B / M2) * W2 + Wide (B mod M2));
         L.Mod_Unique (D, Wide (A / M2) - Wide (B / M2), 0, W2);
         --  (U * M1) mod M2 = 0, so (U * (M1 mod M2)) mod M2 = 0.
         L.Mul_Mod_Right (U, W1, W2);
         pragma Assert ((U * M1m) mod W2 = 0);
         --  U = U * (M1m * Inv) = (U * M1m) * Inv = 0 (mod M2).
         L.Mul_Mod_Left (W1, Wide (Inv), W2);
         pragma Assert ((M1m * Wide (Inv)) mod W2 = 1);
         L.Mul_Assoc (U, M1m, Wide (Inv), W2);
         pragma Assert ((U * ((M1m * Wide (Inv)) mod W2)) mod W2 = U);
         pragma Assert (((U * M1m) mod W2) * Wide (Inv) = 0);
         pragma Assert (U = 0);
      end Zero;

   begin
      if X >= Y then
         Zero (X, Y);
      else
         Zero (Y, X);
      end if;
   end Lemma_Crt2_Unique;

   ---------------------------------------------------------------
   --  Coprimality of products:  gcd(a,c) = 1 and gcd(b,c) = 1
   --  imply gcd(a*b, c) = 1.
   ---------------------------------------------------------------

   procedure Lemma_Coprime_Mul (A, B : Natural_64; C : Modulus_Type)
     with Ghost,
          Global => null,
          Pre  => A >= 1 and then B >= 1
                  and then Wide (A) * Wide (B) <= Max_Modulus
                  and then Gcd (A, C) = 1 and then Gcd (B, C) = 1,
          Post => Gcd (A * B, C) = 1;

   procedure Lemma_Coprime_Mul (A, B : Natural_64; C : Modulus_Type) is
      WC : constant Wide := Wide (C);
      AB : constant Natural_64 := A * B;
      Ia : constant Natural_64 := Inverse (A, C);
      Ib : constant Natural_64 := Inverse (B, C);
      Am : constant Wide := Wide (A) mod WC;
      Bm : constant Wide := Wide (B) mod WC;
      U  : constant Wide := Wide (AB) mod WC;
      V  : constant Wide := (Wide (Ia) * Wide (Ib)) mod WC;
      E  : constant Bezout := Extended_Gcd (AB, C);
      G  : constant Wide := Wide (E.G);
   begin
      --  U = Am * Bm (mod C).
      L.Mul_Mod_Left (Wide (A), Wide (B), WC);
      L.Mul_Mod_Right (Am, Wide (B), WC);
      pragma Assert (U = (Am * Bm) mod WC);
      --  Am * Ia = 1, Bm * Ib = 1 (mod C).
      L.Mul_Mod_Left (Wide (A), Wide (Ia), WC);
      L.Mul_Mod_Left (Wide (B), Wide (Ib), WC);
      pragma Assert ((Am * Wide (Ia)) mod WC = 1);
      pragma Assert ((Bm * Wide (Ib)) mod WC = 1);
      --  U * V = (Am * Ia) * (Bm * Ib) = 1 (mod C).
      L.Mul4 (Am, Bm, Wide (Ia), Wide (Ib), WC);
      pragma Assert ((U * V) mod WC = 1);

      --  G divides AB and C, hence U = AB - C * (AB / C), hence U*V - C*k = 1.
      pragma Assert (G >= 1);
      L.Div_Mod (Wide (AB), G);
      L.Div_Mod (WC, G);
      L.Div_Mod (Wide (AB), WC);
      L.Div_Mod (U * V, WC);
      declare
         P : constant Wide := Wide (AB) / G;
         W : constant Wide := WC / G;
         Q : constant Wide := Wide (AB) / WC;
         K : constant Wide := (U * V) / WC;
         S : constant Wide := P - W * Q;
      begin
         pragma Assert (Wide (AB) = P * G);
         pragma Assert (WC = W * G);
         pragma Assert (Wide (AB) = Q * WC + U);
         pragma Assert (W * Q <= P);
         pragma Assert (U = S * G);
         pragma Assert (S >= 0);
         pragma Assert (W <= WC and then Q <= Wide (AB) and then P <= Wide (AB));
         L.Nonneg_Mul (W, Q);
         pragma Assert (S <= P);
         L.Le_Mul (S, G);
         pragma Assert (S <= S * G);
         pragma Assert (U < WC);
         pragma Assert (S <= U);
         pragma Assert (S < WC);
         pragma Assert (U * V = K * WC + 1);
         pragma Assert (K < WC);
         pragma Assert (G * (S * V - K * W) = 1);
         pragma Assert (S * V - K * W >= 1);
         pragma Assert (G <= G * (S * V - K * W));
      end;
      pragma Assert (G = 1);
   end Lemma_Coprime_Mul;

   --  After P is multiplied by C(I).M, P stays coprime to C(I+1 .. Last).
   procedure Lemma_Coprime_Rest
     (C : Congruence_Array; I : Positive; P : Natural_64)
     with Ghost,
          Global => null,
          Pre  => I in C'Range
                  and then P >= 1
                  and then Wide (P) * Wide (C (I).M) <= Max_Modulus
                  and then Pairwise_Coprime (C)
                  and then (for all J in I .. C'Last =>
                              Gcd (P, C (J).M) = 1),
          Post => (for all J in I + 1 .. C'Last =>
                     Gcd (P * C (I).M, C (J).M) = 1);

   procedure Lemma_Coprime_Rest
     (C : Congruence_Array; I : Positive; P : Natural_64) is
   begin
      for J in I + 1 .. C'Last loop
         pragma Assert (Gcd (C (I).M, C (J).M) = 1);
         Lemma_Coprime_Mul (P, C (I).M, C (J).M);
         pragma Loop_Invariant
           (for all K in I + 1 .. J => Gcd (P * C (I).M, C (K).M) = 1);
      end loop;
   end Lemma_Coprime_Rest;

   --  Extending the solution from C (First .. I-1) to C (First .. I)
   --  keeps the earlier congruences.
   procedure Lemma_Prefix_Kept
     (C : Congruence_Array; I : Positive; P, X2 : Natural_64)
     with Ghost,
          Global => null,
          Pre  => I in C'Range and then I > C'First
                  and then P >= 1
                  and then Wide (P) * Wide (C (I).M) <= Max_Modulus
                  and then (for all J in C'First .. I - 1 =>
                              P mod C (J).M = 0
                              and then (X2 mod P) mod C (J).M = C (J).R),
          Post => (for all J in C'First .. I - 1 =>
                     (P * C (I).M) mod C (J).M = 0
                     and then X2 mod C (J).M = C (J).R);

   procedure Lemma_Prefix_Kept
     (C : Congruence_Array; I : Positive; P, X2 : Natural_64) is
   begin
      for J in C'First .. I - 1 loop
         L.Mod_Mod (Wide (X2), Wide (P), Wide (C (J).M));
         L.Mul_Of_Multiple (Wide (C (I).M), Wide (P), Wide (C (J).M));
         pragma Assert ((P * C (I).M) mod C (J).M = 0);
         pragma Assert (X2 mod C (J).M = C (J).R);
         pragma Loop_Invariant
           (for all K in C'First .. J =>
              (P * C (I).M) mod C (K).M = 0
              and then X2 mod C (K).M = C (K).R);
      end loop;
   end Lemma_Prefix_Kept;

   ---------------
   -- Crt_Array --
   ---------------

   function Crt_Array (C : Congruence_Array) return Natural_64 is
      X : Natural_64 := C (C'First).R;
      P : Natural_64 := C (C'First).M;
   begin
      pragma Assert (Prefix_Product (C, C'First - 1) = 1);
      pragma Assert (Wide (P) = Prefix_Product (C, C'First));
      for I in C'First + 1 .. C'Last loop
         pragma Loop_Invariant (Wide (P) = Prefix_Product (C, I - 1));
         pragma Loop_Invariant (P >= 2 and then X < P);
         pragma Loop_Invariant
           (for all J in C'First .. I - 1 =>
              P mod C (J).M = 0 and then X mod C (J).M = C (J).R);
         pragma Loop_Invariant
           (for all J in I .. C'Last => Gcd (P, C (J).M) = 1);

         pragma Assert (Prefix_Product (C, I) <= Max_Modulus);
         pragma Assert (Wide (P) * Wide (C (I).M) = Prefix_Product (C, I));
         declare
            M  : constant Modulus_Type := C (I).M;
            X2 : constant Natural_64 := Crt2 (X, P, C (I).R, M);
            P2 : constant Natural_64 := P * M;
         begin
            Lemma_Coprime_Rest (C, I, P);
            Lemma_Prefix_Kept (C, I, P, X2);
            L.Mod_Unique (Wide (P2), Wide (P), 0, Wide (M));
            X := X2;
            P := P2;
         end;
      end loop;
      return X;
   end Crt_Array;

end Modular_Arithmetic.CRT;
