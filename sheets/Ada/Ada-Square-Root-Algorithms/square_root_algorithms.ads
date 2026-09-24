--  Square_Root_Algorithms — Ada 2023 educational package for Wikipedia
--  "Methods of computing square roots": Heron's (Babylonian / Newton)
--  method, digit-by-digit integer floor (and limited Float digits),
--  bisection, and an optional inverse-sqrt Newton sketch.
--  Educational Long_Float; domain S ≥ 0.
--  Primary source:
--  https://en.wikipedia.org/wiki/Methods_of_computing_square_roots
--  Siblings (README): Ada-Nth-Root, Ada-Binary-Splitting;
--  upcoming Alpha max plus beta min, Spigot, Rounding.

pragma Ada_2022;

package Square_Root_Algorithms
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float)
   ---------------------------------------------------------------------------

   Default_Tol      : constant Long_Float := 1.0E-12;
   Default_Max_Iter : constant Positive   := 200;

   Epsilon_Tol : constant Long_Float := 1.0E-12;
   Near_Tol    : constant Long_Float := 1.0E-9;

   --  Status of iterative extractors.
   --  Bad_Domain ≡ S < 0 (or other invalid argument).
   --  Sqrt convenience raises Invalid_Argument on failure.
   type Status_Kind is
     (Converged,
      Bad_Domain,
      Max_Iterations_Reached);

   type Sqrt_Result is record
      Value      : Long_Float  := 0.0;
      Iterations : Natural     := 0;
      Status     : Status_Kind := Bad_Domain;
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

   --  True iff N is a perfect square (0, 1, 4, 9, …).
   function Is_Perfect_Square (N : Natural) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Heron's method (Babylonian / Newton for sqrt)
   ---------------------------------------------------------------------------

   --  Iterate
   --    x_{k+1} = (1/2) (x_k + S / x_k)
   --  until |x_{k+1} − x_k| ≤ Tol (absolute or relative).
   --  Does not raise; S < 0 → Status = Bad_Domain, Value = 0.
   function Sqrt_Heron
     (S        : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Sqrt_Result
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Bisection on [0, max(1, S)]
   ---------------------------------------------------------------------------

   --  Bisect f(x) = x^2 − S = 0 on [0, max(1,S)] until half-width ≤ Tol.
   function Sqrt_Bisection
     (S        : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Sqrt_Result
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Digit-by-digit (binary bit-by-bit integer floor)
   ---------------------------------------------------------------------------

   --  Largest Natural R such that R^2 ≤ N. Binary digit-by-digit
   --  (Wikipedia isqrt / pencil-and-paper in base 2).
   function Sqrt_Digit_By_Digit (N : Natural) return Natural
     with Global => null;

   --  Educational Float approximation: digit-style scaling with
   --  Num_Digits decimal places after the point (capped). Returns
   --  floor(√S · 10^Num_Digits) / 10^Num_Digits for S ≥ 0; Bad_Domain if S < 0.
   function Sqrt_Digit_Float
     (S      : Long_Float;
      Num_Digits : Positive := 6) return Sqrt_Result
     with Global => null;

   ---------------------------------------------------------------------------
   -- Inverse-sqrt Newton (Quake-style educational Float; no bit hacks)
   ---------------------------------------------------------------------------

   --  Newton on 1/x^2 − S = 0:
   --    x ← x · (3/2 − (S/2) · x^2)
   --  then √S ≈ S · x. Does not raise; S < 0 → Bad_Domain; S = 0 → 0.
   function Sqrt_Inv_Newton
     (S        : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Sqrt_Result
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Convenience
   ---------------------------------------------------------------------------

   --  Heron with defaults; raises Invalid_Argument if Status ≠ Converged.
   function Sqrt (S : Long_Float) return Long_Float
     with Global => null;

end Square_Root_Algorithms;
