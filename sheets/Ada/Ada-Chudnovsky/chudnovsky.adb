--  Chudnovsky body — Ramanujan–Sato series for π in Long_Float
--  via term-ratio recurrence (no intermediate (6k)! blow-up).

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;

package body Chudnovsky
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

   function Pi_Numerator return Long_Float is
   begin
      return Prefactor_Int * EF.Sqrt (10005.0);
   end Pi_Numerator;

   function Term_Ratio (K : Natural) return Long_Float is
      KF   : constant Long_Float := Long_Float (K);
      Num  : Long_Float;
      Den  : Long_Float;
      Lin  : Long_Float;
   begin
      if K > Max_Terms - 2 then
         raise Invalid_Argument;
      end if;

      --  (6k+1)…(6k+6) / ((3k+1)(3k+2)(3k+3) (k+1)³ (−C³))
      --  × (A + B(k+1)) / (A + B k)
      Num := 1.0;
      for I in 1 .. 6 loop
         Num := Num * (6.0 * KF + Long_Float (I));
      end loop;

      Den :=
        (3.0 * KF + 1.0)
        * (3.0 * KF + 2.0)
        * (3.0 * KF + 3.0)
        * (KF + 1.0)
        * (KF + 1.0)
        * (KF + 1.0)
        * (-C3_Const);

      Lin := (A_Const + B_Const * (KF + 1.0)) / (A_Const + B_Const * KF);

      return (Num / Den) * Lin;
   end Term_Ratio;

   function Series_Term (K : Natural) return Long_Float is
      T : Long_Float;
   begin
      if K > Max_Terms - 1 then
         raise Invalid_Argument;
      end if;

      T := A_Const;  -- t_0
      for J in 0 .. Integer (K) - 1 loop
         T := T * Term_Ratio (Natural (J));
      end loop;
      return T;
   end Series_Term;

   function Series_Sum (Terms : Natural) return Long_Float is
      T   : Long_Float;
      Acc : Long_Float;
   begin
      if Terms = 0 or else Terms > Max_Terms then
         raise Invalid_Argument;
      end if;

      T   := A_Const;
      Acc := T;
      for K in 0 .. Integer (Terms) - 2 loop
         T   := T * Term_Ratio (Natural (K));
         Acc := Acc + T;
      end loop;
      return Acc;
   end Series_Sum;

   function Pi_From_Sum (Sum : Long_Float) return Long_Float is
   begin
      if Sum <= 0.0 then
         raise Invalid_Argument;
      end if;
      return Pi_Numerator / Sum;
   end Pi_From_Sum;

   ---------------------------------------------------------------------------
   -- Core
   ---------------------------------------------------------------------------

   function Approximate_Pi
     (Terms : Term_Count := Default_Terms) return Long_Float
   is
   begin
      return Pi_From_Sum (Series_Sum (Natural (Terms)));
   end Approximate_Pi;

   procedure Approximate_Pi
     (Terms    :     Term_Count := Default_Terms;
      Estimate : out Long_Float;
      Sum      : out Long_Float)
   is
   begin
      Sum      := Series_Sum (Natural (Terms));
      Estimate := Pi_From_Sum (Sum);
   end Approximate_Pi;

end Chudnovsky;
