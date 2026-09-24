--  Computation_Of_Pi body — Long_Float survey sketches for computing π.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;

package body Computation_Of_Pi
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   procedure Require_Effort (N : Natural) is
   begin
      if N = 0 or else N > Max_Effort then
         raise Invalid_Argument;
      end if;
   end Require_Effort;

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
   -- Leibniz
   ---------------------------------------------------------------------------

   function Leibniz_Pi (Terms : Natural) return Long_Float is
      S     : Long_Float := 0.0;
      Sign  : Long_Float := 1.0;
      Denom : Long_Float;
   begin
      Require_Effort (Terms);
      for K in 0 .. Terms - 1 loop
         Denom := 2.0 * Long_Float (K) + 1.0;
         S := S + Sign / Denom;
         Sign := -Sign;
      end loop;
      return 4.0 * S;
   end Leibniz_Pi;

   ---------------------------------------------------------------------------
   -- Nilakantha
   ---------------------------------------------------------------------------

   function Nilakantha_Pi (Terms : Natural) return Long_Float is
      S    : Long_Float := 3.0;
      Sign : Long_Float := 1.0;
      N2   : Long_Float;
   begin
      Require_Effort (Terms);
      for K in 1 .. Terms loop
         N2 := 2.0 * Long_Float (K);
         S := S + Sign * 4.0 / (N2 * (N2 + 1.0) * (N2 + 2.0));
         Sign := -Sign;
      end loop;
      return S;
   end Nilakantha_Pi;

   ---------------------------------------------------------------------------
   -- Arctan series + Machin
   ---------------------------------------------------------------------------

   function Arctan_Series (X : Long_Float; Terms : Natural) return Long_Float is
      S     : Long_Float := 0.0;
      Power : Long_Float := X;
      X2    : constant Long_Float := X * X;
      Sign  : Long_Float := 1.0;
      Denom : Long_Float;
   begin
      Require_Effort (Terms);
      for K in 0 .. Terms - 1 loop
         Denom := 2.0 * Long_Float (K) + 1.0;
         S := S + Sign * Power / Denom;
         Power := Power * X2;
         Sign := -Sign;
      end loop;
      return S;
   end Arctan_Series;

   function Machin_Pi (Terms : Natural) return Long_Float is
      A5, A239 : Long_Float;
   begin
      Require_Effort (Terms);
      A5   := Arctan_Series (0.2, Terms);
      A239 := Arctan_Series (1.0 / 239.0, Terms);
      return 4.0 * (4.0 * A5 - A239);
   end Machin_Pi;

   ---------------------------------------------------------------------------
   -- Archimedes polygon doubling
   ---------------------------------------------------------------------------

   --  Unit circle, inscribed regular hexagon: side length = 1.
   --  Doubling: if s_n is the chord for n sides, then
   --    s_{2n} = √(2 − 2√(1 − (s_n/2)²)) = √(2 − √(4 − s_n²)).
   --  Perimeter = n · s_n; π ≈ perimeter / 2 (radius = 1).

   function Archimedes_Pi (Doublings : Natural) return Long_Float is
      Sides : Long_Float := 6.0;
      Side  : Long_Float := 1.0;
      Next  : Long_Float;
   begin
      Require_Effort (Doublings);
      for I in 1 .. Doublings loop
         Next := EF.Sqrt (2.0 - EF.Sqrt (4.0 - Side * Side));
         Side := Next;
         Sides := Sides * 2.0;
      end loop;
      return (Sides * Side) / 2.0;
   end Archimedes_Pi;

   ---------------------------------------------------------------------------
   -- Tiny BBP partial sum
   ---------------------------------------------------------------------------

   function BBP_Partial_Pi (Terms : Natural) return Long_Float is
      S     : Long_Float := 0.0;
      Pow16 : Long_Float := 1.0;
      Kf    : Long_Float;
      Paren : Long_Float;
   begin
      Require_Effort (Terms);
      for K in 0 .. Terms - 1 loop
         Kf := Long_Float (K);
         Paren :=
           4.0 / (8.0 * Kf + 1.0)
           - 2.0 / (8.0 * Kf + 4.0)
           - 1.0 / (8.0 * Kf + 5.0)
           - 1.0 / (8.0 * Kf + 6.0);
         S := S + Pow16 * Paren;
         Pow16 := Pow16 / 16.0;
      end loop;
      return S;
   end BBP_Partial_Pi;

   ---------------------------------------------------------------------------
   -- Light AGM / Brent–Salamin
   ---------------------------------------------------------------------------

   function AGM_Pi (Iterations : Natural) return Long_Float is
      A, B, T, P, A_Next, B_Next : Long_Float;
   begin
      Require_Effort (Iterations);
      A := 1.0;
      B := 1.0 / EF.Sqrt (2.0);
      T := 0.25;
      P := 1.0;
      for I in 1 .. Iterations loop
         A_Next := (A + B) / 2.0;
         B_Next := EF.Sqrt (A * B);
         T := T - P * (A - A_Next) * (A - A_Next);
         P := 2.0 * P;
         A := A_Next;
         B := B_Next;
      end loop;
      return (A + B) * (A + B) / (4.0 * T);
   end AGM_Pi;

   ---------------------------------------------------------------------------
   -- Catalogue Chudnovsky (term-ratio form)
   ---------------------------------------------------------------------------

   function Chudnovsky_Pi (Terms : Natural) return Long_Float is
      A_Const : constant Long_Float := 13_591_409.0;
      B_Const : constant Long_Float := 545_140_134.0;
      C3      : constant Long_Float := 262_537_412_640_768_000.0;
      Term    : Long_Float := A_Const;
      Sum     : Long_Float := A_Const;
      Kf      : Long_Float;
      Numer   : Long_Float;
      Denom   : Long_Float;
      Ratio   : Long_Float;
   begin
      Require_Effort (Terms);
      for K in 0 .. Terms - 2 loop
         Kf := Long_Float (K);
         Numer :=
           (6.0 * Kf + 1.0) * (6.0 * Kf + 2.0) * (6.0 * Kf + 3.0)
           * (6.0 * Kf + 4.0) * (6.0 * Kf + 5.0) * (6.0 * Kf + 6.0)
           * (A_Const + B_Const * (Kf + 1.0));
         Denom :=
           (3.0 * Kf + 1.0) * (3.0 * Kf + 2.0) * (3.0 * Kf + 3.0)
           * (Kf + 1.0) * (Kf + 1.0) * (Kf + 1.0)
           * (-C3)
           * (A_Const + B_Const * Kf);
         Ratio := Numer / Denom;
         Term := Term * Ratio;
         Sum := Sum + Term;
      end loop;
      return 426_880.0 * EF.Sqrt (10_005.0) / Sum;
   end Chudnovsky_Pi;

   ---------------------------------------------------------------------------
   -- Dispatcher
   ---------------------------------------------------------------------------

   function Approximate_Pi
     (Which  : Method;
      Effort : Effort_Count := Default_Effort) return Long_Float
   is
   begin
      case Which is
         when Leibniz =>
            return Leibniz_Pi (Effort);
         when Nilakantha =>
            return Nilakantha_Pi (Effort);
         when Machin =>
            return Machin_Pi (Effort);
         when Archimedes =>
            return Archimedes_Pi (Effort);
         when BBP_Partial =>
            return BBP_Partial_Pi (Effort);
         when AGM =>
            return AGM_Pi (Effort);
         when Chudnovsky_Term =>
            return Chudnovsky_Pi (Effort);
      end case;
   end Approximate_Pi;

   procedure Approximate_Pi
     (Which     :     Method;
      Effort    :     Effort_Count := Default_Effort;
      Estimate  : out Long_Float;
      Abs_Err   : out Long_Float)
   is
   begin
      Estimate := Approximate_Pi (Which, Effort);
      Abs_Err  := Abs_Error (Estimate, Pi_Constant);
   end Approximate_Pi;

end Computation_Of_Pi;
