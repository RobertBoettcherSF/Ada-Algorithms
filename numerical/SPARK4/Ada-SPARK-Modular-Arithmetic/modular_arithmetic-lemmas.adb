--  Version: 0.001
--  Proofs of Modular_Arithmetic.Lemmas.

pragma Ada_2022;

package body Modular_Arithmetic.Lemmas
  with SPARK_Mode => On
is

   procedure Mod_Unique (X : Mag126; Q : Mag63; R : Wide; N : Wide_Pos)
   is null;

   procedure Div_Mod (X : Mag126; N : Wide_Pos) is null;

   procedure Mod_Add_Multiple (X : Mag126; K : Mag126; N : Wide_Pos)
   is null;

   procedure Mul_Of_Multiple (A, M : Mag63; N : Wide_Pos) is
   begin
      if M >= 0 then
         Mul_Mod_Right (A, M, N);
         pragma Assert ((A * M) mod N = (A * 0) mod N);
      else
         pragma Assert (M = Floor_Div (M, N) * N);
         Mod_Unique (-M, -Floor_Div (M, N), 0, N);
         Mul_Mod_Right (A, -M, N);
         pragma Assert (A * ((-M) mod N) = 0);
         pragma Assert ((A * (-M)) mod N = 0);
         pragma Assert (A * M = -(A * (-M)));
      end if;
   end Mul_Of_Multiple;

   procedure Mul_Mod_Right (A : Mag63; B : Wide_Nat; N : Wide_Pos) is
      R : constant Wide := B mod N;
      Q : constant Wide := B / N;
   begin
      Div_Mod (B, N);
      pragma Assert (B = Q * N + R);
      pragma Assert (A * B = A * R + (A * Q) * N);
      Mod_Add_Multiple (A * R, A * Q, N);
   end Mul_Mod_Right;

   procedure Mul_Mod_Left (A : Wide_Nat; B : Mag63; N : Wide_Pos) is
   begin
      Mul_Mod_Right (A => B, B => A, N => N);
   end Mul_Mod_Left;

   procedure Add_Mod_Right (A, B : Mag126; N : Wide_Pos) is
      R : constant Wide := B mod N;
      Q : constant Mag126 := Floor_Div (B, N);
   begin
      pragma Assert (B = Q * N + R);
      Mod_Add_Multiple (A + R, Q, N);
   end Add_Mod_Right;

   procedure Mul_Assoc (X, Y, Z : Wide_Nat; N : Wide_Pos) is
      Q1 : constant Wide := (X * Y) / N;
      R1 : constant Wide := (X * Y) mod N;
      Q2 : constant Wide := (Y * Z) / N;
      R2 : constant Wide := (Y * Z) mod N;
   begin
      Div_Mod (X * Y, N);
      Div_Mod (Y * Z, N);
      pragma Assert (Q1 < N);
      pragma Assert (Q2 < N);
      pragma Assert (R1 * Z = X * R2 + (X * Q2 - Q1 * Z) * N);
      Mod_Add_Multiple (X * R2, X * Q2 - Q1 * Z, N);
   end Mul_Assoc;

   procedure Mod_Mod (Y : Mag126; P, M : Wide_Pos) is
      Q : constant Wide := Y / P;
      S : constant Wide := P / M;
   begin
      Div_Mod (P, M);
      Div_Mod (Y, P);
      pragma Assert (P = S * M);
      pragma Assert (Y = Q * P + Y mod P);
      pragma Assert (Q * P <= Y);
      pragma Assert (Y = (Q * S) * M + Y mod P);
      Mod_Add_Multiple (Y mod P, Q * S, M);
   end Mod_Mod;

   procedure Sq_Mul (X, Y : Wide_Nat; N : Wide_Pos) is
      U : constant Wide_Nat := (X * Y) mod N;
   begin
      --  m(u, u) = m(x, m(y, u))
      Mul_Assoc (X, Y, U, N);
      --  m(y, u) = m(y, m(x, y)) = m(m(y, x), y) = m(u, y)
      Mul_Assoc (Y, X, Y, N);
      pragma Assert ((Y * X) mod N = U);
      --  m(x, m(u, y)) = m(m(x, u), y)
      Mul_Assoc (X, U, Y, N);
      --  m(x, u) = m(x, m(x, y)) = m(m(x, x), y)
      Mul_Assoc (X, X, Y, N);
   end Sq_Mul;

   procedure Mul4 (A, B, C, D : Wide_Nat; N : Wide_Pos) is
      CD : constant Wide_Nat := (C * D) mod N;
      BC : constant Wide_Nat := (B * C) mod N;
      BD : constant Wide_Nat := (B * D) mod N;
   begin
      --  m(m(a,b), cd) = m(a, m(b, cd))
      Mul_Assoc (A, B, CD, N);
      --  m(b, m(c,d)) = m(m(b,c), d)
      Mul_Assoc (B, C, D, N);
      pragma Assert ((C * B) mod N = BC);
      --  m(m(c,b), d) = m(c, m(b,d))
      Mul_Assoc (C, B, D, N);
      --  m(a, m(c, bd)) = m(m(a,c), bd)
      Mul_Assoc (A, C, BD, N);
   end Mul4;

   procedure Nonneg_Mul (A, B : Mag63) is
   begin
      pragma Assert (A * B >= 0);
   end Nonneg_Mul;

   procedure Le_Mul (S, G : Mag63) is
   begin
      pragma Assert (S * G = S * (G - 1) + S);
      Nonneg_Mul (S, G - 1);
   end Le_Mul;

end Modular_Arithmetic.Lemmas;
