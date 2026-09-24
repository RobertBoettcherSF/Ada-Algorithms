--  Multiplicative_Inverse_Algorithms — Ada 2023 educational survey of
--  algorithms for multiplicative inverses:
--    * Extended Euclidean modular inverse
--        a x ≡ 1 (mod m)  when gcd(a,m) = 1
--    * Fermat / Euler modular inverse for prime modulus
--        a^{p-2} mod p  (binary modular exponentiation)
--    * Tiny self-contained Newton–Raphson real reciprocal
--        x ← x (2 − a x)
--  Primary sources:
--  https://en.wikipedia.org/wiki/Multiplicative_inverse#Algorithms
--  https://en.wikipedia.org/wiki/Modular_multiplicative_inverse
--  https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm
--  Sibling (README only; do not `with`): Ada-Newton-Multiplicative-Inverse.
--  Upcoming: Toom–Cook, Schönhage–Strassen, Karatsuba, Fürer, Booth,
--  Multiplication survey, Montgomery.

pragma Ada_2022;

package Multiplicative_Inverse_Algorithms
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Integer / Float)
   ---------------------------------------------------------------------------

   --  Safe educational bound for moduli / bases used in tests and demos.
   --  Keeps products inside Long_Integer for typical classroom examples.
   Max_Educational_Modulus : constant Long_Integer := 1_000_000;

   Default_Tol      : constant Float := 1.0E-6;
   Default_Max_Iter : constant Positive := 64;

   ---------------------------------------------------------------------------
   -- Status / results
   ---------------------------------------------------------------------------

   --  Found         — inverse exists and was computed
   --  Not_Invertible    — gcd(A, M) ≠ 1 (or A ≡ 0 mod P for Fermat)
   --  Invalid_Input — M ≤ 1, P ≤ 1, non-positive Newton domain, etc.
   type Status_Kind is
     (Found,
      Not_Invertible,
      Invalid_Input,
      Converged,
      Bad_Domain,
      Max_Iterations_Reached);

   type Inverse_Result is record
      Value  : Long_Integer := 0;
      Status : Status_Kind  := Invalid_Input;
      G      : Long_Integer := 0;  --  gcd(A, M) when known
   end record;

   type Extended_Gcd_Result is record
      G : Long_Integer := 0;  --  gcd(A, B) ≥ 0
      X : Long_Integer := 0;  --  Bézout: A*X + B*Y = G
      Y : Long_Integer := 0;
   end record;

   type Reciprocal_Result is record
      Value      : Float       := 0.0;
      Iterations : Natural     := 0;
      Status     : Status_Kind := Bad_Domain;
   end record;

   Invalid_Argument : exception;
   No_Inverse : exception;

   ---------------------------------------------------------------------------
   -- Integer helpers
   ---------------------------------------------------------------------------

   function Abs_LI (N : Long_Integer) return Long_Integer
     with Global => null;

   --  Non-negative residue of A modulo M (M > 0). Result in 0 .. M-1.
   function Mod_Nonneg (A, M : Long_Integer) return Long_Integer
     with Pre => M > 0, Global => null;

   --  Classical Euclidean gcd; result ≥ 0. gcd(0,0) = 0.
   function Gcd (A, B : Long_Integer) return Long_Integer
     with Global => null;

   --  Extended Euclidean: returns (G, X, Y) with A*X + B*Y = G, G ≥ 0.
   function Extended_Gcd (A, B : Long_Integer) return Extended_Gcd_Result
     with Global => null;

   --  Educational primality test (trial division). For classroom moduli.
   function Is_Prime (N : Long_Integer) return Boolean
     with Global => null;

   --  Binary modular exponentiation: Base^Exp mod M (M > 1, Exp ≥ 0).
   --  Uses Long_Integer intermediates; keep Base, M educationally small.
   function Mod_Pow
     (Base, Exp, M : Long_Integer) return Long_Integer
     with Pre => M > 1 and then Exp >= 0, Global => null;

   ---------------------------------------------------------------------------
   -- Modular inverse — Extended Euclidean
   ---------------------------------------------------------------------------

   --  Find X in 0 .. M-1 such that (A * X) mod M = 1 when gcd(A,M) = 1.
   --  Never raises. Status:
   --    Found          — Value holds the inverse
   --    Not_Invertible     — G = gcd ≠ 1
   --    Invalid_Input  — M ≤ 1
   function Inverse_Mod_EEA
     (A, M : Long_Integer) return Inverse_Result
     with Global => null;

   --  Convenience: raises Invalid_Argument if M ≤ 1;
   --  raises No_Inverse if gcd ≠ 1.
   function Inverse_EEA (A, M : Long_Integer) return Long_Integer
     with Global => null;

   ---------------------------------------------------------------------------
   -- Modular inverse — Fermat / Euler (prime modulus)
   ---------------------------------------------------------------------------

   --  By Fermat's little theorem: if P is prime and A ≢ 0 (mod P), then
   --    A^{P-2} ≡ A^{-1} (mod P).
   --  Does not verify primality of P (caller / Is_Prime). Never raises.
   --  Status:
   --    Found         — Value = A^{P-2} mod P
   --    Not_Invertible    — A ≡ 0 (mod P)
   --    Invalid_Input — P ≤ 1
   function Inverse_Mod_Fermat
     (A, P : Long_Integer) return Inverse_Result
     with Global => null;

   --  Convenience; raises Invalid_Argument if P ≤ 1;
   --  raises No_Inverse if A ≡ 0 (mod P).
   function Inverse_Fermat (A, P : Long_Integer) return Long_Integer
     with Global => null;

   ---------------------------------------------------------------------------
   -- Real reciprocal — tiny self-contained Newton (Float)
   ---------------------------------------------------------------------------

   --  Find X ≈ 1/A by Newton on f(x) = 1/x − A:
   --    x ← x (2 − A x)
   --  Seed: simple reciprocal-of-magnitude guess. Self-contained sketch
   --  (does not `with` Ada-Newton-Multiplicative-Inverse). Never raises.
   --  A = 0 → Bad_Domain.
   function Reciprocal_Newton
     (A        : Float;
      Tol      : Float    := Default_Tol;
      Max_Iter : Positive := Default_Max_Iter) return Reciprocal_Result
     with Pre => Tol >= 0.0, Global => null;

   --  Convenience; raises Invalid_Argument if not Converged.
   function Reciprocal (A : Float) return Float
     with Global => null;

   --  Oracle Float reciprocal 1.0/A; raises Invalid_Argument if A = 0.
   function Exact_Reciprocal (A : Float) return Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Verification helpers
   ---------------------------------------------------------------------------

   --  True iff (A * Inv) mod M = 1 (M > 1).
   function Is_Modular_Inverse
     (A, Inv, M : Long_Integer) return Boolean
     with Pre => M > 1, Global => null;

   function Near
     (A, B : Float; Tol : Float := Default_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

end Multiplicative_Inverse_Algorithms;
