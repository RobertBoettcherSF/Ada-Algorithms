--  Goldschmidt_Division — Ada 2023 educational package for Wikipedia
--  "Goldschmidt division" / "Division algorithm" § Goldschmidt: iteratively
--  multiply numerator and denominator by factors F_i so the denominator
--  converges to 1 and the numerator to the quotient Q:
--    F_i = 2 − D_i,   N ← N F_i,   D ← D F_i.
--  Educational Long_Float core. Contrast: Newton–Raphson finds a reciprocal
--  then forms Q = N · X once; Goldschmidt scales both N and D each step
--  (numerator/denominator multiplies may run in parallel in hardware).
--  Primary sources:
--  https://en.wikipedia.org/wiki/Goldschmidt_division
--  https://en.wikipedia.org/wiki/Division_algorithm#Goldschmidt_division
--  Siblings (README): Long division, Newton–Raphson division; upcoming
--  Division algorithms survey. Does not `with` Ada-Newton-Raphson-Division.

pragma Ada_2022;

package Goldschmidt_Division
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float)
   ---------------------------------------------------------------------------

   Default_Tol      : constant Long_Float := 1.0E-12;
   Default_Max_Iter : constant Positive   := 100;

   Epsilon_Tol : constant Long_Float := 1.0E-12;
   Near_Tol    : constant Long_Float := 1.0E-9;

   --  Status of Divide_Goldschmidt_Detail.
   --  Bad_Domain ≡ D = 0.
   type Status_Kind is
     (Converged,
      Bad_Domain,
      Max_Iterations_Reached);

   --  Float Goldschmidt result: Quotient ≈ N_k after D_k → 1.
   type Division_Result is record
      Quotient     : Long_Float  := 0.0;
      Final_Denom  : Long_Float  := 0.0;
      Iterations   : Natural     := 0;
      Status       : Status_Kind := Bad_Domain;
   end record;

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near
     (A, B : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Abs_Error (A, B : Long_Float) return Long_Float
     with Global => null;

   --  |Approx − Exact| / |Exact|; if Exact = 0 return |Approx|.
   function Rel_Error (Approx, Exact : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Oracle (comparison only)
   ---------------------------------------------------------------------------

   --  Exact Long_Float quotient N / D. Raises Invalid_Argument if D = 0.
   function Exact_Quotient (N, D : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Goldschmidt division: scale N and D by F_i = 2 − D_i until D → 1
   ---------------------------------------------------------------------------

   --  Detail form: returns Quotient, Final_Denom (≈ 1), Iterations, Status.
   --  D = 0 → Bad_Domain; never raises.
   function Divide_Goldschmidt_Detail
     (N, D     : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Division_Result
     with Pre => Tol >= 0.0, Global => null;

   --  Convenience: Goldschmidt float quotient. Raises Invalid_Argument if
   --  D = 0 or the iteration fails to converge.
   function Divide_Goldschmidt (N, D : Long_Float) return Long_Float
     with Global => null;

end Goldschmidt_Division;
