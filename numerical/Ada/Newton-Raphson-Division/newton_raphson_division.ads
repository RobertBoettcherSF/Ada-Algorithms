--  Newton_Raphson_Division — Ada 2023 educational package for Wikipedia
--  "Division algorithm" § Newton–Raphson division: find X ≈ 1/D by the
--  Newton reciprocal iteration
--    X ← X (2 − D X)
--  then form the quotient Q = N · X. Educational Long_Float core, with
--  optional Integer wrappers (toward-zero and floor) that check
--  N = Q D + R against Ada / and rem oracles.
--  Primary source:
--  https://en.wikipedia.org/wiki/Division_algorithm#Newton%E2%80%93Raphson_division
--  also https://en.wikipedia.org/wiki/Newton%E2%80%93Raphson_division
--  Siblings (README): Ada-Non-Restoring-Division, Ada-Restoring-Division,
--  Ada-SRT-Division, Ada-Newton-Multiplicative-Inverse; upcoming Long
--  division, Goldschmidt, Division algorithms survey.
--  Self-contained: reimplements a small reciprocal iteration (does not
--  `with` Ada-Newton-Multiplicative-Inverse).

pragma Ada_2022;

package Newton_Raphson_Division
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float)
   ---------------------------------------------------------------------------

   Default_Tol      : constant Long_Float := 1.0E-12;
   Default_Max_Iter : constant Positive   := 100;

   Epsilon_Tol : constant Long_Float := 1.0E-12;
   Near_Tol    : constant Long_Float := 1.0E-9;

   --  Status of Reciprocal_Newton / Divide_NR_Detail.
   --  Bad_Domain ≡ D = 0.
   type Status_Kind is
     (Converged,
      Bad_Domain,
      Max_Iterations_Reached);

   type Reciprocal_Result is record
      Value      : Long_Float  := 0.0;
      Iterations : Natural     := 0;
      Status     : Status_Kind := Bad_Domain;
   end record;

   --  Float division result: Quotient = N · X where X ≈ 1/D.
   type Division_Result is record
      Quotient   : Long_Float  := 0.0;
      Reciprocal : Long_Float  := 0.0;
      Iterations : Natural     := 0;
      Status     : Status_Kind := Bad_Domain;
   end record;

   --  Integer division result: N = Quotient * D + Remainder.
   type Integer_Division_Result is record
      Quotient  : Integer := 0;
      Remainder : Integer := 0;
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
   -- Oracles (comparison only)
   ---------------------------------------------------------------------------

   --  Exact Long_Float quotient N / D. Raises Invalid_Argument if D = 0.
   function Exact_Quotient (N, D : Long_Float) return Long_Float
     with Global => null;

   --  Exact reciprocal 1 / D. Raises Invalid_Argument if D = 0.
   function Exact_Reciprocal (D : Long_Float) return Long_Float
     with Global => null;

   --  Ada Integer truncating division: Quotient = N / D, Remainder = N rem D
   --  (toward zero). Raises Invalid_Argument if D = 0.
   function Exact_Integer_Divide (N, D : Integer) return Integer_Division_Result
     with Global => null;

   ---------------------------------------------------------------------------
   -- Reciprocal Newton (self-contained; core of NR division)
   ---------------------------------------------------------------------------

   --  Find X = 1/D by Newton on f(X) = 1/X − D:
   --    X_{i+1} = X_i (2 − D X_i)
   --  Initial guess: dyadic scale |D| into [1/2, 1), seed with the classic
   --  linear NR-division approximant (48/17) − (32/17) M, then restore
   --  sign and scale. Quadratic convergence roughly doubles correct digits
   --  each iteration (ε_{i+1} = ε_i²). Does not raise; D = 0 → Bad_Domain.
   function Reciprocal_Newton
     (D        : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Reciprocal_Result
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Newton–Raphson division: Q = N · Reciprocal_Newton(D)
   ---------------------------------------------------------------------------

   --  Detail form: returns Quotient, Reciprocal, Iterations, Status.
   --  D = 0 → Bad_Domain; never raises.
   function Divide_NR_Detail
     (N, D     : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Division_Result
     with Pre => Tol >= 0.0, Global => null;

   --  Convenience: NR float quotient. Raises Invalid_Argument if D = 0
   --  or reciprocal fails to converge.
   function Divide_NR (N, D : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Optional Integer wrappers (via Long_Float NR + rounding)
   ---------------------------------------------------------------------------

   --  Toward-zero integer quotient of N/D via Divide_NR, with Remainder
   --  chosen so N = Q·D + R and |R| < |D| (Ada rem sign: same as N when
   --  R ≠ 0). Raises Invalid_Argument if D = 0.
   function Divide_Integer_Toward_Zero
     (N, D : Integer) return Integer_Division_Result
     with Global => null;

   --  Floor (mathematical floor) integer quotient of N/D via Divide_NR,
   --  with Remainder so N = Q·D + R and 0 ≤ R < |D| when D > 0, or
   --  −|D| < R ≤ 0 when D < 0 (Euclidean-friendly when D > 0).
   --  Raises Invalid_Argument if D = 0.
   function Divide_Integer_Floor
     (N, D : Integer) return Integer_Division_Result
     with Global => null;

end Newton_Raphson_Division;
