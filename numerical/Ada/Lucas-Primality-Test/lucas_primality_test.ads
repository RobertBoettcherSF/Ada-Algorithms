--  Lucas primality test — Ada 2023 educational package.
--  Deterministic test that needs the distinct prime factors of N−1
--  (Pratt certificate basis). Self-contained modular arithmetic.
--  Primary source:
--  https://en.wikipedia.org/wiki/Lucas_primality_test
--  Not Lucas–Lehmer and not Baillie–PSW / extra-strong Lucas PRP.
--  Siblings: Ada-Miller-Rabin; next: Fermat primality test.

pragma Ada_2022;

package Lucas_Primality_Test
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Distinct prime factors of N − 1 (caller-supplied or trial-found).
   type Factor_List is array (Positive range <>) of U64;

   --  Educational trial-factor limit for Factors_Of_N_Minus_1 /
   --  Is_Prime_Lucas_Auto (N must be ≤ this value).
   Max_Auto_N : constant U64 := 1_000_000;

   ------------------------------------------------------------------
   --  Modular arithmetic helpers
   ------------------------------------------------------------------

   --  (A * B) mod M without intermediate overflow.
   --  Uses Interfaces.Unsigned_128 for the product.
   --  Raises Invalid_Argument if M = 0.
   function Mul_Mod (A, B, M : U64) return U64
     with Global => null;

   --  (Base ^ Exp) mod Modulus via binary exponentiation + Mul_Mod.
   --  Raises Invalid_Argument if Modulus = 0.
   --  Convention: Mod_Pow (B, 0, M) = 1 rem M for M > 0 (so 0 when M = 1).
   function Mod_Pow (Base, Exp, Modulus : U64) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  Factoring N − 1 (educational trial division)
   ------------------------------------------------------------------

   --  Distinct prime factors of N − 1 via trial division.
   --  Raises Invalid_Argument if N < 2 or N > Max_Auto_N.
   --  For N = 2 returns an empty list (N − 1 = 1 has no prime factors).
   function Factors_Of_N_Minus_1 (N : U64) return Factor_List
     with Global => null;

   ------------------------------------------------------------------
   --  Lucas witness / primality
   ------------------------------------------------------------------

   --  True if base A certifies that N is prime under the Lucas conditions:
   --    A^{N−1} ≡ 1 (mod N), and
   --    A^{(N−1)/Q} ≢ 1 (mod N) for every prime factor Q of N − 1.
   --  Requires 1 < A < N and a non-empty Factors list when N > 2.
   --  Raises Invalid_Argument if N < 2, or N > 2 with empty Factors,
   --  or a listed factor does not divide N − 1 / is < 2.
   function Lucas_Witness
     (N       : U64;
      A       : U64;
      Factors : Factor_List) return Boolean
     with Global => null;

   --  Search for a Lucas witness base A = 2, 3, … up to a search bound.
   --  Returns the first witness found, or 0 if none found in the bound.
   --  Raises Invalid_Argument under the same domain rules as Lucas_Witness
   --  (except A is chosen internally).
   function Find_Lucas_Witness
     (N       : U64;
      Factors : Factor_List) return U64
     with Global => null;

   --  True iff a Lucas witness exists for N given Factors of N − 1.
   --  N = 2 → True (no factors needed). N even > 2 → False.
   --  Alias educational name: Is_Prime_With_Factors.
   function Is_Prime_Lucas
     (N       : U64;
      Factors : Factor_List) return Boolean
     with Global => null;

   function Is_Prime_With_Factors
     (N       : U64;
      Factors : Factor_List) return Boolean
     renames Is_Prime_Lucas;

   --  Factor N − 1 internally (N ≤ Max_Auto_N) then search for a witness.
   --  Alias educational name: Is_Prime_Small.
   --  Raises Invalid_Argument if N > Max_Auto_N.
   --  N < 2 → False; N = 2 → True; even N > 2 → False.
   function Is_Prime_Lucas_Auto (N : U64) return Boolean
     with Global => null;

   function Is_Prime_Small (N : U64) return Boolean
     renames Is_Prime_Lucas_Auto;

end Lucas_Primality_Test;
