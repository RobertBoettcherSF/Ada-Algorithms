--  Borwein body — quartic AGM-style iteration for 1/π in Long_Float.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;

package body Borwein
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

   --  Fourth root via two square roots (Long_Float educational path).
   function Fourth_Root (X : Long_Float) return Long_Float is
   begin
      return EF.Sqrt (EF.Sqrt (X));
   end Fourth_Root;

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
   -- Core
   ---------------------------------------------------------------------------

   function Initial_State return State is
      S     : State;
      Sqrt2 : constant Long_Float := EF.Sqrt (2.0);
   begin
      S.Y          := Sqrt2 - 1.0;
      S.A          := 6.0 - 4.0 * Sqrt2;  -- = 2(√2−1)²
      S.Iterations := 0;
      return S;
   end Initial_State;

   function Iterate (S : State) return State is
      Next   : State;
      Y4     : Long_Float;
      Root   : Long_Float;
      Y_New  : Long_Float;
      One_Y  : Long_Float;
      Power  : Long_Float;
      N      : constant Natural := S.Iterations;
   begin
      if S.Iterations >= Max_Iterations then
         raise Invalid_Argument;
      end if;
      if S.A <= 0.0 then
         raise Invalid_Argument;
      end if;

      Y4    := S.Y * S.Y * S.Y * S.Y;
      Root  := Fourth_Root (1.0 - Y4);
      Y_New := (1.0 - Root) / (1.0 + Root);
      One_Y := 1.0 + Y_New;
      --  2^{2n+3} as successive doubling from 2^3 = 8 (avoids large exponents).
      Power := 8.0;
      for K in 1 .. N loop
         Power := Power * 4.0;  -- × 2² each increment of n
      end loop;

      Next.Y := Y_New;
      Next.A :=
        S.A * (One_Y * One_Y * One_Y * One_Y)
        - Power * Y_New * (1.0 + Y_New + Y_New * Y_New);
      Next.Iterations := N + 1;
      return Next;
   end Iterate;

   function Inv_Pi_Estimate (S : State) return Long_Float is
   begin
      if S.A <= 0.0 then
         raise Invalid_Argument;
      end if;
      return S.A;
   end Inv_Pi_Estimate;

   function Pi_Estimate (S : State) return Long_Float is
   begin
      if S.A <= 0.0 then
         raise Invalid_Argument;
      end if;
      return 1.0 / S.A;
   end Pi_Estimate;

   function Approximate_Pi
     (Iterations : Iteration_Count := Default_Iterations) return Long_Float
   is
      S : State := Initial_State;
   begin
      for K in 1 .. Iterations loop
         S := Iterate (S);
      end loop;
      return Pi_Estimate (S);
   end Approximate_Pi;

   procedure Approximate_Pi
     (Iterations :     Iteration_Count := Default_Iterations;
      Final      : out State;
      Estimate   : out Long_Float)
   is
      S : State := Initial_State;
   begin
      for K in 1 .. Iterations loop
         S := Iterate (S);
      end loop;
      Final    := S;
      Estimate := Pi_Estimate (S);
   end Approximate_Pi;

   function Approximate_Inv_Pi
     (Iterations : Iteration_Count := Default_Iterations) return Long_Float
   is
      S : State := Initial_State;
   begin
      for K in 1 .. Iterations loop
         S := Iterate (S);
      end loop;
      return Inv_Pi_Estimate (S);
   end Approximate_Inv_Pi;

   procedure Approximate_Inv_Pi
     (Iterations :     Iteration_Count := Default_Iterations;
      Final      : out State;
      Estimate   : out Long_Float)
   is
      S : State := Initial_State;
   begin
      for K in 1 .. Iterations loop
         S := Iterate (S);
      end loop;
      Final    := S;
      Estimate := Inv_Pi_Estimate (S);
   end Approximate_Inv_Pi;

end Borwein;
