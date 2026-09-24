--  Exponentiating_By_Squaring — Ada 2023 educational package for
--  binary exponentiation / square-and-multiply (exponentiating by squaring).
--  Integer Long_Integer powers, modular Pow_Mod, optional Float reciprocal
--  powers for negative exponents, and a 2×2 integer matrix powering sketch.
--  Primary source:
--  https://en.wikipedia.org/wiki/Exponentiating_by_squaring
--  Siblings (README): Ada-BKM, Ada-Montgomery-Reduction; upcoming
--  Addition-chain exponentiation, SRT division.

pragma Ada_2022;

package Exponentiating_By_Squaring
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Educational bounds (Long_Integer overflow domains)
   ---------------------------------------------------------------------------

   --  Naive multiply-loop is only for small exponents (oracle / pedagogy).
   Max_Naive_Exp : constant Natural := 10_000;

   --  Non-modular integer powering can overflow Long_Integer. Prefer
   --  Pow_Mod for large exponents. Classroom demos typically keep
   --  |Base|^Exp well inside Long_Integer'First .. Long_Integer'Last
   --  (roughly |Base| ≤ 10^9 and Exp ≤ 10 for worst-case growth, or
   --  smaller bases with larger Exp — e.g. 2^62 fits, 2^63 does not in
   --  signed 64-bit). Constraint_Error may be raised on overflow when
   --  checks are enabled.

   ---------------------------------------------------------------------------
   -- Exceptions / educational multiplication counter
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for: negative Exp on integer Power_*; Modulus ≤ 1;
   --  Power_Naive with Exp > Max_Naive_Exp; Power_Float with Base = 0.0
   --  and Exp ≤ 0; etc.

   --  Optional educational counter of (non-identity) multiplications /
   --  squarings performed by Power_* / Pow_Mod / matrix helpers when
   --  counting is enabled. Squares count as one multiplication.
   procedure Reset_Multiplication_Count
     with Global => null;

   procedure Enable_Counting (Enabled : Boolean)
     with Global => null;

   function Counting_Enabled return Boolean
     with Global => null;

   function Multiplication_Count return Natural
     with Global => null;

   ---------------------------------------------------------------------------
   -- Integer helpers
   ---------------------------------------------------------------------------

   function Abs_LI (X : Long_Integer) return Long_Integer
     with Global => null;

   --  Non-negative residue of A modulo M (M > 0). Result in 0 .. M−1.
   function Mod_Nonneg (A, M : Long_Integer) return Long_Integer
     with Pre => M > 0, Global => null;

   --  Classical (A * B) mod M with non-negative result. M > 1.
   function Mod_Mul (A, B, M : Long_Integer) return Long_Integer
     with Pre => M > 1, Global => null;

   ---------------------------------------------------------------------------
   -- Integer binary exponentiation  Base^Exp  (Exp ≥ 0)
   ---------------------------------------------------------------------------

   --  Recursive Wikipedia form:
   --    x^n = x (x^2)^((n-1)/2)  if n odd;
   --        = (x^2)^(n/2)        if n even;
   --    x^0 = 1  (including 0^0 := 1 by convention here).
   --  Raises Invalid_Argument never for Natural Exp; may raise
   --  Constraint_Error on Long_Integer overflow.
   function Power_Recursive
     (Base : Long_Integer;
      Exp  : Natural) return Long_Integer
     with Global => null;

   --  Iterative right-to-left square-and-multiply (constant auxiliary
   --  memory). Invariant: Result * Base^Exp stays equal to the original
   --  Base^Exp_original while Exp is halved each step.
   function Power_Iterative
     (Base : Long_Integer;
      Exp  : Natural) return Long_Integer
     with Global => null;

   --  Iterative left-to-right: scan bits of Exp from MSB down to LSB.
   --  Same asymptotic cost; useful to compare bit-order variants.
   function Power_Left_To_Right
     (Base : Long_Integer;
      Exp  : Natural) return Long_Integer
     with Global => null;

   --  Naive loop: Result := 1; for I in 1 .. Exp loop Result := Result*Base.
   --  Raises Invalid_Argument if Exp > Max_Naive_Exp.
   function Power_Naive
     (Base : Long_Integer;
      Exp  : Natural) return Long_Integer
     with Global => null;

   ---------------------------------------------------------------------------
   -- Modular binary exponentiation  Base^Exp mod Modulus
   ---------------------------------------------------------------------------

   --  Square-and-multiply modular power. Result in 0 .. Modulus−1.
   --  Raises Invalid_Argument if Modulus ≤ 1 or Exp < 0.
   --  Preferred for large Exp (no intermediate Long_Integer blow-up
   --  beyond Modulus^2 intermediates in Mod_Mul).
   function Pow_Mod
     (Base, Exp, Modulus : Long_Integer) return Long_Integer
     with Global => null;

   ---------------------------------------------------------------------------
   -- Optional Float powers (negative exponents → reciprocal)
   ---------------------------------------------------------------------------

   --  Float square-and-multiply. For Exp < 0 returns (1/Base)^(|Exp|).
   --  Raises Invalid_Argument if Base = 0.0 and Exp ≤ 0.
   --  0.0^positive → 0.0; nonzero^0 → 1.0.
   function Power_Float
     (Base : Float;
      Exp  : Integer) return Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Optional 2×2 integer matrix powering sketch (semigroup example)
   ---------------------------------------------------------------------------

   --  Row-major [[A11, A12], [A21, A22]]. Educational only — products
   --  can overflow Long_Integer; keep entries small (e.g. Fibonacci
   --  companion [[1,1],[1,0]] with modest Exp).
   type Matrix_2x2 is record
      A11, A12, A21, A22 : Long_Integer := 0;
   end record;

   function Identity_2x2 return Matrix_2x2
     with Global => null;

   function Multiply_2x2 (Left, Right : Matrix_2x2) return Matrix_2x2
     with Global => null;

   --  M^Exp by square-and-multiply (Exp = 0 → identity).
   function Power_Matrix_2x2
     (M   : Matrix_2x2;
      Exp : Natural) return Matrix_2x2
     with Global => null;

end Exponentiating_By_Squaring;
