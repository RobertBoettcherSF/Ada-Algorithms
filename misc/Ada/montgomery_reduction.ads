--  Montgomery_Reduction — Ada 2023 educational package for
--  Montgomery reduction (REDC) and Montgomery modular multiplication.
--  Odd modulus N, radix R = 2^k > N with gcd(N, R) = 1.
--  REDC(T) computes T R^{-1} mod N without dividing by N, using
--  N' = -N^{-1} mod R. Montgomery multiply is REDC of a product of
--  Montgomery forms ã = a R mod N.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Montgomery_modular_multiplication
--  https://en.wikipedia.org/wiki/Montgomery_reduction
--  Sibling (README): Ada-Multiplication-Algorithms; upcoming CORDIC,
--  BKM, exponentiation by squaring.

pragma Ada_2022;

package Montgomery_Reduction
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Educational bounds (Long_Integer-safe intermediates)
   ---------------------------------------------------------------------------

   --  R = 2^R_Bits. Keep R_Bits ≤ Max_R_Bits so 2·R·N fits in Long_Integer
   --  when N < R (REDC intermediate T + m N).
   Max_R_Bits : constant := 30;

   --  Default classroom radix R = 2^16 = 65536 (N odd, 1 < N < R).
   Default_R_Bits : constant := 16;

   ---------------------------------------------------------------------------
   -- Context / precomputed Montgomery parameters
   ---------------------------------------------------------------------------

   --  N         — odd modulus, 1 < N < R
   --  R         — 2^R_Bits (power-of-two radix)
   --  R_Bits    — k in R = 2^k
   --  N_Prime   — N' with N·N' ≡ −1 (mod R)
   --  R_Mod_N   — R mod N  (= Montgomery form of 1)
   --  R2_Mod_N  — R² mod N (used by To_Montgomery)
   type Context is record
      N        : Long_Integer := 0;
      R        : Long_Integer := 0;
      R_Bits   : Natural      := 0;
      N_Prime  : Long_Integer := 0;
      R_Mod_N  : Long_Integer := 0;
      R2_Mod_N : Long_Integer := 0;
   end record;

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Integer helpers / classical modular arithmetic (oracle)
   ---------------------------------------------------------------------------

   function Abs_LI (X : Long_Integer) return Long_Integer
     with Global => null;

   --  Non-negative residue of A modulo M (M > 0). Result in 0 .. M−1.
   function Mod_Nonneg (A, M : Long_Integer) return Long_Integer
     with Pre => M > 0, Global => null;

   function Gcd (A, B : Long_Integer) return Long_Integer
     with Global => null;

   --  True iff X is a positive power of two (X = 2^k for some k ≥ 0).
   function Is_Power_Of_Two (X : Long_Integer) return Boolean
     with Global => null;

   --  Floor(log2(X)) for X ≥ 1; raises Invalid_Argument if X < 1.
   function Floor_Log2 (X : Long_Integer) return Natural
     with Global => null;

   --  Classical (A * B) mod N with non-negative result. N > 1.
   function Mod_Mul (A, B, N : Long_Integer) return Long_Integer
     with Pre => N > 1, Global => null;

   --  Classical binary modular exponentiation Base^Exp mod N.
   function Mod_Pow
     (Base, Exp, N : Long_Integer) return Long_Integer
     with Pre => N > 1 and then Exp >= 0, Global => null;

   --  Modular inverse of A modulo M via extended Euclidean (0 .. M−1).
   --  Raises Invalid_Argument if M ≤ 1 or gcd(A, M) ≠ 1.
   function Mod_Inverse (A, M : Long_Integer) return Long_Integer
     with Global => null;

   ---------------------------------------------------------------------------
   -- Context construction
   ---------------------------------------------------------------------------

   --  Build Montgomery context for odd N with R = 2^R_Bits > N.
   --  Raises Invalid_Argument if:
   --    N ≤ 1, N even, R_Bits = 0, R_Bits > Max_R_Bits, or R ≤ N.
   function Create_Context
     (N      : Long_Integer;
      R_Bits : Natural := Default_R_Bits) return Context
     with Global => null;

   --  True if Ctx looks like a successfully created context.
   function Is_Valid_Context (Ctx : Context) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Montgomery domain conversions
   ---------------------------------------------------------------------------

   --  ã = a R mod N  via  REDC((a mod N) · (R² mod N)).
   function To_Montgomery
     (Ctx : Context;
      A   : Long_Integer) return Long_Integer
     with Global => null;

   --  a = ã R^{-1} mod N  via  REDC(ã).
   function From_Montgomery
     (Ctx     : Context;
      A_Tilde : Long_Integer) return Long_Integer
     with Global => null;

   ---------------------------------------------------------------------------
   -- REDC / Montgomery multiply / Montgomery pow
   ---------------------------------------------------------------------------

   --  Montgomery reduction: S ≡ T R^{-1} (mod N), S in 0 .. N−1.
   --  Expects 0 ≤ T < R·N for the standard single-subtraction form.
   --  Raises Invalid_Argument if Ctx invalid or T < 0.
   function REDC
     (Ctx : Context;
      T   : Long_Integer) return Long_Integer
     with Global => null;

   --  Montgomery multiplication: REDC(ã · b̃) ≡ (a b) R mod N.
   function Montgomery_Multiply
     (Ctx             : Context;
      A_Tilde, B_Tilde : Long_Integer) return Long_Integer
     with Global => null;

   --  Square-and-multiply modular exponentiation in Montgomery domain.
   --  Returns Base^Exp mod N in ordinary (non-Montgomery) form.
   --  Raises Invalid_Argument if Ctx invalid or Exp < 0.
   function Montgomery_Pow
     (Ctx  : Context;
      Base : Long_Integer;
      Exp  : Long_Integer) return Long_Integer
     with Global => null;

end Montgomery_Reduction;
