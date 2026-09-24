--  Extended_Euclidean — Ada 2023 educational package for the
--  extended Euclidean algorithm: gcd(a,b) together with Bézout
--  coefficients x,y such that
--      a*x + b*y = gcd(a,b).
--  Primary source:
--  https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm
--  Note: Wikipedia / literature use "Euclidean" (not the common
--  misspelling "Euclidian").
--  Sibling packages (README only; do not `with`):
--    Ada-Multiplicative-Inverse-Algorithms,
--    Ada-Dixon, Ada-Congruence-Of-Squares.

pragma Ada_2022;

package Extended_Euclidean
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Integer)
   ---------------------------------------------------------------------------

   --  Soft classroom bound for moduli / operands used in demos and tests.
   Max_Educational : constant Long_Integer := 1_000_000;

   ---------------------------------------------------------------------------
   -- Results
   ---------------------------------------------------------------------------

   --  Extended_Gcd returns Gcd ≥ 0 and Bézout coefficients X, Y with
   --      A * X + B * Y = Gcd.
   --  Sign / zero conventions (documented + tested):
   --    * Gcd(0, 0) = 0 with (X, Y) = (1, 0)  —  0·1 + 0·0 = 0
   --    * Gcd(A, 0) / Gcd(0, B) use |A| / |B|; identity still holds
   --    * Negative inputs accepted; Gcd always non-negative
   --      (coefficients flipped if the raw remainder is negative)
   type Extended_Gcd_Result is record
      Gcd : Long_Integer := 0;
      X   : Long_Integer := 0;
      Y   : Long_Integer := 0;
   end record;

   --  Quotients A/Gcd and B/Gcd (signed operands ÷ positive Gcd).
   --  For (0,0) both fields are 0 (Gcd = 0; quotients undefined).
   type Quotient_Pair is record
      A_Over_G : Long_Integer := 0;
      B_Over_G : Long_Integer := 0;
   end record;

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Abs_LI (N : Long_Integer) return Long_Integer
     with Global => null;

   --  Non-negative residue of A modulo M (M > 0). Result in 0 .. M-1.
   function Mod_Nonneg (A, M : Long_Integer) return Long_Integer
     with Pre => M > 0, Global => null;

   --  True iff A * Inv ≡ 1 (mod M) with M > 1.
   function Is_Modular_Inverse
     (A, Inv, M : Long_Integer) return Boolean
     with Pre => M > 1, Global => null;

   --  True iff A * R.X + B * R.Y = R.Gcd and R.Gcd ≥ 0.
   function Verify_Bezout
     (A, B : Long_Integer; R : Extended_Gcd_Result) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Classical / extended Euclidean
   ---------------------------------------------------------------------------

   --  Classical Euclidean gcd; result ≥ 0.  Gcd(0, 0) = 0.
   function Gcd (A, B : Long_Integer) return Long_Integer
     with Global => null;

   --  Iterative extended Euclidean (Wikipedia pseudocode).
   --  Returns (Gcd, X, Y) with A*X + B*Y = Gcd and Gcd ≥ 0.
   function Extended_Gcd (A, B : Long_Integer) return Extended_Gcd_Result
     with Global => null;

   --  True iff Gcd(A, B) = 1.
   function Are_Coprime (A, B : Long_Integer) return Boolean
     with Global => null;

   --  Quotients of A and B by their (non-negative) gcd.
   --  When Gcd = 0 (only A = B = 0), returns (0, 0).
   function Quotients_By_Gcd (A, B : Long_Integer) return Quotient_Pair
     with Global => null;

   ---------------------------------------------------------------------------
   -- Modular multiplicative inverse
   ---------------------------------------------------------------------------

   --  Find Inv in 0 .. M-1 such that (A * Inv) mod M = 1 when
   --  Gcd(A, M) = 1 and M > 1.
   --  Raises Invalid_Argument when M ≤ 1 or Gcd(A, M) ≠ 1.
   function Modular_Inverse (A, M : Long_Integer) return Long_Integer
     with Global => null;

end Extended_Euclidean;
