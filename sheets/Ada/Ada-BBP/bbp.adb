--  BBP body — Bailey–Borwein–Plouffe series for π in Long_Float,
--  plus an educational hex-digit extraction sketch.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;

package body BBP
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near
     (Left, Right : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
   is
   begin
      return abs (Left - Right) <= Tol;
   end Near;

   function Abs_Error (Approx_V, Exact_V : Long_Float) return Long_Float is
   begin
      return abs (Approx_V - Exact_V);
   end Abs_Error;

   function Rel_Error (Approx_V, Exact_V : Long_Float) return Long_Float is
   begin
      if Exact_V = 0.0 then
         if Approx_V = 0.0 then
            return 0.0;
         else
            return 1.0E30;
         end if;
      end if;
      return abs (Approx_V - Exact_V) / abs (Exact_V);
   end Rel_Error;

   --  Keep only the fractional part in [0, 1).
   function Frac (X : Long_Float) return Long_Float is
      Y : Long_Float := X - Long_Float'Truncation (X);
   begin
      if Y < 0.0 then
         Y := Y + 1.0;
      end if;
      if Y >= 1.0 then
         Y := Y - 1.0;
      end if;
      return Y;
   end Frac;

   ---------------------------------------------------------------------------
   -- Oracles
   ---------------------------------------------------------------------------

   function Ada_Pi return Long_Float is
   begin
      return Long_Float (Ada.Numerics.Pi);
   end Ada_Pi;

   function Elementary_Pi return Long_Float is
   begin
      return 4.0 * EF.Arctan (1.0);
   end Elementary_Pi;

   ---------------------------------------------------------------------------
   -- Series
   ---------------------------------------------------------------------------

   function Term_Parenthesis (K : Natural) return Long_Float is
      KF : constant Long_Float := Long_Float (K);
   begin
      return
        4.0 / (8.0 * KF + 1.0)
        - 2.0 / (8.0 * KF + 4.0)
        - 1.0 / (8.0 * KF + 5.0)
        - 1.0 / (8.0 * KF + 6.0);
   end Term_Parenthesis;

   function Series_Term (K : Natural) return Long_Float is
      Pow : Long_Float := 1.0;
   begin
      if K > Max_Terms - 1 then
         raise Invalid_Argument;
      end if;

      for J in 1 .. K loop
         Pow := Pow / 16.0;
      end loop;
      return Pow * Term_Parenthesis (K);
   end Series_Term;

   function Series_Sum (Terms : Natural) return Long_Float is
      Acc : Long_Float := 0.0;
      Pow : Long_Float := 1.0;  -- 16^(−k), starts at k = 0
   begin
      if Terms = 0 or else Terms > Max_Terms then
         raise Invalid_Argument;
      end if;

      for K in 0 .. Integer (Terms) - 1 loop
         Acc := Acc + Pow * Term_Parenthesis (Natural (K));
         Pow := Pow / 16.0;
      end loop;
      return Acc;
   end Series_Sum;

   ---------------------------------------------------------------------------
   -- Core
   ---------------------------------------------------------------------------

   function Approximate_Pi
     (Terms : Term_Count := Default_Terms) return Long_Float
   is
   begin
      return Series_Sum (Natural (Terms));
   end Approximate_Pi;

   procedure Approximate_Pi
     (Terms    :     Term_Count := Default_Terms;
      Estimate : out Long_Float;
      Sum      : out Long_Float)
   is
   begin
      Sum      := Series_Sum (Natural (Terms));
      Estimate := Sum;
   end Approximate_Pi;

   ---------------------------------------------------------------------------
   -- Hex-digit extraction (educational Long_Float sketch)
   ---------------------------------------------------------------------------

   --  16^Exp mod Modulus for Modulus > 0, via binary modular exponentiation
   --  in Long_Integer (denominators stay modest under Max_Hex_Digit).
   function Modular_Pow_16
     (Exp : Natural; Modulus : Long_Integer) return Long_Integer
   is
      Result : Long_Integer := 1;
      Base   : Long_Integer := 16 mod Modulus;
      E      : Natural      := Exp;
   begin
      if Modulus <= 0 then
         raise Invalid_Argument;
      end if;
      if Modulus = 1 then
         return 0;
      end if;

      while E > 0 loop
         if E mod 2 = 1 then
            Result := (Result * Base) mod Modulus;
         end if;
         Base := (Base * Base) mod Modulus;
         E    := E / 2;
      end loop;
      return Result;
   end Modular_Pow_16;

   --  Fractional part of Σ_k 16^(N−k) / (8k+J)  (Wikipedia digit extract).
   function Series_Sj_Frac (N : Natural; J : Positive) return Long_Float is
      S   : Long_Float := 0.0;
      Den : Long_Integer;
      Num : Long_Integer;
      Pow : Long_Float;
      Term : Long_Float;
      --  Tail terms after k = N; a few dozen suffice for Long_Float.
      Tail_Extra : constant Natural := 40;
   begin
      --  Finite sum k = 0 .. N with modular reduction (fractional only).
      for K in 0 .. N loop
         Den := 8 * Long_Integer (K) + Long_Integer (J);
         Num := Modular_Pow_16 (N - K, Den);
         S   := Frac (S + Long_Float (Num) / Long_Float (Den));
      end loop;

      --  Infinite tail k = N+1 .. ∞ without modular reduction (powers → 0).
      Pow := 1.0 / 16.0;  -- 16^(N−(N+1))
      for K in N + 1 .. N + Tail_Extra loop
         Den  := 8 * Long_Integer (K) + Long_Integer (J);
         Term := Pow / Long_Float (Den);
         S    := S + Term;
         exit when Term < 1.0E-18;
         Pow := Pow / 16.0;
      end loop;

      return Frac (S);
   end Series_Sj_Frac;

   function Hex_Fractional_Part (N : Natural) return Long_Float is
      X : Long_Float;
   begin
      if N > Max_Hex_Digit then
         raise Invalid_Argument;
      end if;

      X :=
        4.0 * Series_Sj_Frac (N, 1)
        - 2.0 * Series_Sj_Frac (N, 4)
        - Series_Sj_Frac (N, 5)
        - Series_Sj_Frac (N, 6);
      return Frac (X);
   end Hex_Fractional_Part;

   function Hex_Digit_Of_Pi (N : Natural) return Hex_Digit is
      Fr : Long_Float;
      D  : Integer;
   begin
      if N > Max_Hex_Digit then
         raise Invalid_Argument;
      end if;

      Fr := Hex_Fractional_Part (N);
      D  := Integer (Long_Float'Truncation (Fr * 16.0));
      if D < 0 then
         D := 0;
      elsif D > 15 then
         D := 15;
      end if;
      return Hex_Digit (D);
   end Hex_Digit_Of_Pi;

end BBP;
