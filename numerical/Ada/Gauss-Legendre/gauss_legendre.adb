--  Gauss_Legendre body — Brent–Salamin AGM iteration for π in Long_Float.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;

package body Gauss_Legendre
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near
     (A, B : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
   is
   begin
      return abs (A - B) <= Tol;
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
      S : State;
   begin
      S.A          := 1.0;
      S.B          := 1.0 / EF.Sqrt (2.0);
      S.T          := 0.25;
      S.P          := 1.0;
      S.Iterations := 0;
      return S;
   end Initial_State;

   function Iterate (S : State) return State is
      Next   : State;
      A_Next : Long_Float;
   begin
      if S.Iterations >= Max_Iterations then
         raise Invalid_Argument;
      end if;
      if S.T <= 0.0 then
         raise Invalid_Argument;
      end if;

      A_Next      := 0.5 * (S.A + S.B);
      Next.B      := EF.Sqrt (S.A * S.B);
      Next.T      := S.T - S.P * (S.A - A_Next) * (S.A - A_Next);
      Next.P      := 2.0 * S.P;
      Next.A      := A_Next;
      Next.Iterations := S.Iterations + 1;
      return Next;
   end Iterate;

   function Pi_Estimate (S : State) return Long_Float is
      Sum : Long_Float;
   begin
      if S.T <= 0.0 then
         raise Invalid_Argument;
      end if;
      Sum := S.A + S.B;
      return (Sum * Sum) / (4.0 * S.T);
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

end Gauss_Legendre;
