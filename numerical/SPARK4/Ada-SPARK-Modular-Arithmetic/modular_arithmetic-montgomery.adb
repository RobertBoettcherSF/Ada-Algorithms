--  Version: 0.001
--  Modular_Arithmetic.Montgomery body and proofs.

pragma Ada_2022;

with Modular_Arithmetic.Lemmas;

package body Modular_Arithmetic.Montgomery
  with SPARK_Mode => On
is

   package L renames Modular_Arithmetic.Lemmas;

   WR : constant Wide := R;

   -----------------------
   -- Lemma_Odd_Coprime --
   -----------------------

   --  An odd divisor of 2*H divides H.
   procedure Halve (G : Wide_Pos; H : Wide)
     with Ghost,
          Global => null,
          Pre  => G mod 2 = 1 and then H in 1 .. 2**61
                  and then (2 * H) mod G = 0,
          Post => H mod G = 0;

   procedure Halve (G : Wide_Pos; H : Wide) is
      Cq : constant Wide := (2 * H) / G;
   begin
      L.Div_Mod (2 * H, G);
      pragma Assert (2 * H = Cq * G);
      pragma Assert (Cq <= 2 * H);
      L.Div_Mod (Cq, 2);
      if Cq mod 2 = 1 then
         pragma Assert (Cq * G = ((Cq / 2) * G + G / 2) * 2 + 1);
         L.Mod_Unique (Cq * G, (Cq / 2) * G + G / 2, 1, 2);
         L.Mod_Unique (2 * H, H, 0, 2);
         pragma Assert (False);
      end if;
      pragma Assert (H = (Cq / 2) * G);
      L.Mod_Unique (H, Cq / 2, 0, G);
   end Halve;

   procedure Lemma_Odd_Coprime (N : Modulus_Type) is
      E : constant Bezout := Extended_Gcd (N, R);
      G : constant Wide := Wide (E.G);
   begin
      pragma Assert (G >= 1);
      --  G is odd, because it divides the odd N.
      L.Div_Mod (Wide (N), G);
      if G mod 2 = 0 then
         L.Div_Mod (G, 2);
         pragma Assert (Wide (N) = ((Wide (N) / G) * (G / 2)) * 2);
         L.Mod_Unique (Wide (N), (Wide (N) / G) * (G / 2), 0, 2);
         pragma Assert (False);
      end if;
      --  G divides 2**62, 2**61, ..., 2**0 = 1.
      pragma Assert (WR mod G = 0);
      Halve (G, 2**61);
      Halve (G, 2**60);
      Halve (G, 2**59);
      Halve (G, 2**58);
      Halve (G, 2**57);
      Halve (G, 2**56);
      Halve (G, 2**55);
      Halve (G, 2**54);
      Halve (G, 2**53);
      Halve (G, 2**52);
      Halve (G, 2**51);
      Halve (G, 2**50);
      Halve (G, 2**49);
      Halve (G, 2**48);
      Halve (G, 2**47);
      Halve (G, 2**46);
      Halve (G, 2**45);
      Halve (G, 2**44);
      Halve (G, 2**43);
      Halve (G, 2**42);
      Halve (G, 2**41);
      Halve (G, 2**40);
      Halve (G, 2**39);
      Halve (G, 2**38);
      Halve (G, 2**37);
      Halve (G, 2**36);
      Halve (G, 2**35);
      Halve (G, 2**34);
      Halve (G, 2**33);
      Halve (G, 2**32);
      Halve (G, 2**31);
      Halve (G, 2**30);
      Halve (G, 2**29);
      Halve (G, 2**28);
      Halve (G, 2**27);
      Halve (G, 2**26);
      Halve (G, 2**25);
      Halve (G, 2**24);
      Halve (G, 2**23);
      Halve (G, 2**22);
      Halve (G, 2**21);
      Halve (G, 2**20);
      Halve (G, 2**19);
      Halve (G, 2**18);
      Halve (G, 2**17);
      Halve (G, 2**16);
      Halve (G, 2**15);
      Halve (G, 2**14);
      Halve (G, 2**13);
      Halve (G, 2**12);
      Halve (G, 2**11);
      Halve (G, 2**10);
      Halve (G, 2**9);
      Halve (G, 2**8);
      Halve (G, 2**7);
      Halve (G, 2**6);
      Halve (G, 2**5);
      Halve (G, 2**4);
      Halve (G, 2**3);
      Halve (G, 2**2);
      Halve (G, 2**1);
      Halve (G, 2**0);
      pragma Assert (G = 1);
   end Lemma_Odd_Coprime;

   ------------------
   -- Make_Context --
   ------------------

   function Make_Context (N : Modulus_Type) return Context is
      WN  : constant Wide := Wide (N);
      Inv : Natural_64;
      Np  : Natural_64;
      K   : Wide;
      C   : Context;
   begin
      Lemma_Odd_Coprime (N);
      Inv := Inverse (N, R);                    --  N * Inv = 1 (mod R)
      pragma Assert ((WN * Wide (Inv)) mod WR = 1);
      pragma Assert (Inv >= 1);
      Np := R - Inv;                            --  N * Np = -1 (mod R)
      pragma Assert (WN * Wide (Np) = (WN - 1) * WR + (WR - WN * Wide (Inv)));
      L.Div_Mod (WN * Wide (Inv), WR);
      pragma Assert
        (WN * Wide (Np)
         = (WN - 1 - (WN * Wide (Inv)) / WR) * WR + (WR - 1));
      L.Mod_Unique
        (WN * Wide (Np), WN - 1 - (WN * Wide (Inv)) / WR, WR - 1, WR);

      --  K * R = N * Np + 1, so R * K = 1 (mod N).
      K := (WN * Wide (Np) + 1) / WR;
      L.Div_Mod (WN * Wide (Np), WR);
      pragma Assert (WN * Wide (Np) + 1 = K * WR);
      pragma Assert (K <= WN);
      L.Mod_Unique (WR * K, Wide (Np), 1, WN);

      C.N       := N;
      C.N_Prime := Np;
      C.R_Mod_N := R mod N;
      C.R_Inv   := Natural_64 (K mod WN);
      --  (R mod N) * (K mod N) = R * K = 1 (mod N).
      L.Mul_Mod_Left (WR, K mod WN, WN);
      L.Mul_Mod_Right (WR, K, WN);
      pragma Assert
        ((Wide (C.R_Mod_N) * Wide (C.R_Inv)) mod WN = 1);
      return C;
   end Make_Context;

   ----------
   -- Redc --
   ----------

   function Redc (T : Wide; C : Context) return Natural_64 is
      WN  : constant Wide := Wide (C.N);
      NP  : constant Wide := Wide (C.N_Prime);
      Tl  : constant Wide := T mod WR;                --  T mod R
      M   : constant Wide := (Tl * NP) mod WR;        --  m = T * N' mod R
      U   : constant Wide := T + M * WN;              --  divisible by R
      Tq  : Wide;
      Res : Wide;

      --  U mod R = 0, because M * N = -T (mod R).
      procedure Prove_Divisible with Ghost is
      begin
         --  (M * N) mod R = (Tl * (N' * N mod R)) mod R = (-Tl) mod R.
         L.Mul_Assoc (Tl, NP, WN, WR);
         pragma Assert ((NP * WN) mod WR = WR - 1);
         pragma Assert ((M * WN) mod WR = (Tl * (WR - 1)) mod WR);
         L.Div_Mod (T, WR);
         L.Div_Mod (M * WN, WR);
         pragma Assert (T / WR < WN);
         pragma Assert ((M * WN) / WR < WN);
         if Tl = 0 then
            L.Mod_Unique (Tl * (WR - 1), 0, 0, WR);
            pragma Assert (U = (T / WR + (M * WN) / WR) * WR);
         else
            L.Mod_Unique (Tl * (WR - 1), Tl - 1, WR - Tl, WR);
            pragma Assert (U = (T / WR + (M * WN) / WR + 1) * WR);
         end if;
      end Prove_Divisible;

   begin
      Prove_Divisible;
      pragma Assert (U mod WR = 0);

      Tq := U / WR;                                   --  exact, < 2N
      L.Div_Mod (U, WR);
      pragma Assert (U = Tq * WR);
      pragma Assert (Tq < 2 * WN);
      L.Div_Mod (T, WN);
      pragma Assert (T / WN < WR);
      --  (Res * R) mod N = T mod N.
      if Tq >= WN then
         Res := Tq - WN;
         pragma Assert (Res * WR = T + (M - WR) * WN);
         pragma Assert
           (Res * WR = (T / WN + (M - WR)) * WN + T mod WN);
         L.Mod_Unique (Res * WR, T / WN + (M - WR), T mod WN, WN);
      else
         Res := Tq;
         pragma Assert (Res * WR = T + M * WN);
         pragma Assert (Res * WR = (T / WN + M) * WN + T mod WN);
         L.Mod_Unique (Res * WR, T / WN + M, T mod WN, WN);
      end if;

      --  Res = Res * (R mod N) * R^-1 = (T mod N) * R^-1 (mod N).
      L.Mul_Mod_Right (Res, WR, WN);
      pragma Assert ((Res * Wide (C.R_Mod_N)) mod WN = T mod WN);
      L.Mul_Assoc (Res, Wide (C.R_Mod_N), Wide (C.R_Inv), WN);
      pragma Assert
        (Res = (Res * ((Wide (C.R_Mod_N) * Wide (C.R_Inv)) mod WN)) mod WN);
      return Natural_64 (Res);
   end Redc;

   -------------------
   -- To_Montgomery --
   -------------------

   function To_Montgomery (A : Natural_64; C : Context) return Natural_64 is
   begin
      L.Mul_Mod_Right (Wide (A), WR, Wide (C.N));
      return Mul_Mod (A, C.R_Mod_N, C.N);
   end To_Montgomery;

   ---------------------
   -- From_Montgomery --
   ---------------------

   function From_Montgomery (X : Natural_64; C : Context) return Natural_64
   is
      Res : constant Natural_64 := Redc (Wide (X), C);
   begin
      L.Mod_Unique (Wide (X), 0, Wide (X), Wide (C.N));
      pragma Assert (Wide (X) mod Wide (C.N) = Wide (X));
      pragma Assert (Wide (Res) = (Wide (X) * Wide (C.R_Inv)) mod Wide (C.N));
      return Res;
   end From_Montgomery;

   -------------------------
   -- Montgomery_Multiply --
   -------------------------

   function Montgomery_Multiply (X, Y : Natural_64; C : Context)
     return Natural_64
   is
   begin
      pragma Assert (Wide (X) * Wide (Y) <= Wide (X) * Wide (C.N));
      pragma Assert (Wide (X) * Wide (Y) < Wide (C.N) * R);
      return Redc (Wide (X) * Wide (Y), C);
   end Montgomery_Multiply;

   --------------
   -- Multiply --
   --------------

   function Multiply (A, B : Natural_64; C : Context) return Natural_64 is
      WN : constant Wide := Wide (C.N);
      Rm : constant Wide := Wide (C.R_Mod_N);
      Ri : constant Wide := Wide (C.R_Inv);
      X  : constant Natural_64 := To_Montgomery (A, C);
      Y  : constant Natural_64 := To_Montgomery (B, C);
      Z  : constant Natural_64 := Montgomery_Multiply (X, Y, C);
      W  : constant Natural_64 := From_Montgomery (Z, C);
      AB : constant Wide := (Wide (A) * Wide (B)) mod WN with Ghost;
      RR : constant Wide := (Rm * Rm) mod WN with Ghost;
   begin
      --  X = A*Rm, Y = B*Rm (mod N).
      L.Mul_Mod_Right (Wide (A), WR, WN);
      L.Mul_Mod_Right (Wide (B), WR, WN);
      pragma Assert (Wide (X) = (Wide (A) * Rm) mod WN);
      pragma Assert (Wide (Y) = (Wide (B) * Rm) mod WN);
      --  X*Y = AB * (Rm*Rm).
      L.Mul4 (Wide (A), Rm, Wide (B), Rm, WN);
      pragma Assert ((Wide (X) * Wide (Y)) mod WN = (AB * RR) mod WN);
      --  Z = AB * (Rm*Rm) * Ri = AB * (Rm * (Rm * Ri)) = AB * Rm.
      L.Mul_Assoc (AB, RR, Ri, WN);
      L.Mul_Assoc (Rm, Rm, Ri, WN);
      pragma Assert ((RR * Ri) mod WN = Rm);
      pragma Assert (Wide (Z) = (((Wide (X) * Wide (Y)) mod WN) * Ri) mod WN);
      pragma Assert (Wide (Z) = (((AB * RR) mod WN) * Ri) mod WN);
      pragma Assert (Wide (Z) = (AB * ((RR * Ri) mod WN)) mod WN);
      pragma Assert (Wide (Z) = (AB * Rm) mod WN);
      --  W = AB * Rm * Ri = AB.
      L.Mul_Assoc (AB, Rm, Ri, WN);
      pragma Assert (Wide (W) = (Wide (Z) * Ri) mod WN);
      pragma Assert (Wide (W) = (((AB * Rm) mod WN) * Ri) mod WN);
      pragma Assert ((Rm * Ri) mod WN = 1);
      pragma Assert (Wide (W) = (AB * 1) mod WN);
      L.Mod_Unique (AB, 0, AB, WN);
      pragma Assert (Wide (W) = AB);
      return W;
   end Multiply;

end Modular_Arithmetic.Montgomery;
