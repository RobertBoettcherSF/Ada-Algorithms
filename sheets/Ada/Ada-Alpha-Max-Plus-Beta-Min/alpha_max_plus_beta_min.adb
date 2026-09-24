--  Alpha_Max_Plus_Beta_Min body — α·Max + β·Min magnitude approximation.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Alpha_Max_Plus_Beta_Min
  with SPARK_Mode => Off
is

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
   -- Exact oracle
   ---------------------------------------------------------------------------

   function Exact_Hypot (A, B : Long_Float) return Long_Float is
      use Ada.Numerics.Long_Elementary_Functions;
      AA : constant Long_Float := abs (A);
      BB : constant Long_Float := abs (B);
   begin
      if AA = 0.0 and then BB = 0.0 then
         return 0.0;
      end if;
      return Sqrt (AA * AA + BB * BB);
   end Exact_Hypot;

   ---------------------------------------------------------------------------
   -- Core
   ---------------------------------------------------------------------------

   function Approx
     (A, B        : Long_Float;
      Alpha, Beta : Long_Float) return Long_Float
   is
      AA  : constant Long_Float := abs (A);
      BB  : constant Long_Float := abs (B);
      Mx  : Long_Float;
      Mn  : Long_Float;
   begin
      if AA >= BB then
         Mx := AA;
         Mn := BB;
      else
         Mx := BB;
         Mn := AA;
      end if;
      return Alpha * Mx + Beta * Mn;
   end Approx;

   function Approx_Clamped
     (A, B        : Long_Float;
      Alpha, Beta : Long_Float) return Long_Float
   is
      AA  : constant Long_Float := abs (A);
      BB  : constant Long_Float := abs (B);
      Mx  : Long_Float;
      Mn  : Long_Float;
      Est : Long_Float;
   begin
      if AA >= BB then
         Mx := AA;
         Mn := BB;
      else
         Mx := BB;
         Mn := AA;
      end if;
      Est := Alpha * Mx + Beta * Mn;
      if Est > Mx then
         return Est;
      else
         return Mx;
      end if;
   end Approx_Clamped;

   function Approx_Two_Segment
     (A, B            : Long_Float;
      Alpha_0, Beta_0 : Long_Float;
      Alpha_1, Beta_1 : Long_Float) return Long_Float
   is
      Z0 : constant Long_Float := Approx (A, B, Alpha_0, Beta_0);
      Z1 : constant Long_Float := Approx (A, B, Alpha_1, Beta_1);
   begin
      if Z0 >= Z1 then
         return Z0;
      else
         return Z1;
      end if;
   end Approx_Two_Segment;

   ---------------------------------------------------------------------------
   -- Named presets
   ---------------------------------------------------------------------------

   function Approx_Half (A, B : Long_Float) return Long_Float is
   begin
      return Approx (A, B, Alpha_Half, Beta_Half);
   end Approx_Half;

   function Approx_Quarter (A, B : Long_Float) return Long_Float is
   begin
      return Approx (A, B, Alpha_Quarter, Beta_Quarter);
   end Approx_Quarter;

   function Approx_Shift_Friendly (A, B : Long_Float) return Long_Float is
   begin
      return Approx (A, B, Alpha_Shift, Beta_Shift);
   end Approx_Shift_Friendly;

   function Approx_Fifteenths (A, B : Long_Float) return Long_Float is
   begin
      return Approx (A, B, Alpha_Fifteenths, Beta_Fifteenths);
   end Approx_Fifteenths;

   function Approx_Optimal (A, B : Long_Float) return Long_Float is
   begin
      return Approx (A, B, Alpha_Optimal, Beta_Optimal);
   end Approx_Optimal;

   function Approx_Optimal_Clamped (A, B : Long_Float) return Long_Float is
   begin
      return Approx_Clamped (A, B, Alpha_Optimal, Beta_Optimal);
   end Approx_Optimal_Clamped;

end Alpha_Max_Plus_Beta_Min;
