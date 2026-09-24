--  Trial division — Ada 2023 educational package.
--  Integer factorization / primality by trying candidate divisors up to √N.
--  Self-contained unsigned 64-bit arithmetic (wheel: skip evens after 2).
--  Primary source:
--  https://en.wikipedia.org/wiki/Trial_division
--  Siblings: Ada-Sieve-Of-Eratosthenes, Ada-Miller-Rabin, Ada-Primality-Test.
--  Next (educational sketch): SNFS / NFS family; Shor already on GitHub.

pragma Ada_2022;

package Trial_Division
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   --  Candidates live in the full unsigned 64-bit range. Trial loops use
   --  overflow-safe comparisons (D <= N/D) so N up to 2^64−1 is fine;
   --  classroom examples typically stay near 2^63 and below.
   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   ------------------------------------------------------------------
   --  Factor representation (prime powers with multiplicity)
   ------------------------------------------------------------------

   --  One prime power p^e in the complete factorization of N.
   type Prime_Power is record
      Prime    : U64;
      Exponent : Natural;
   end record;

   --  Unconstrained list of distinct prime powers (secondary-stack return).
   --  Empty for N = 1. Ordered by increasing Prime.
   type Factor_List is array (Positive range <>) of Prime_Power;

   ------------------------------------------------------------------
   --  Core API
   ------------------------------------------------------------------

   --  True iff N is prime. N = 0 → raise Invalid_Argument.
   --  N = 1 → False. Trial up to floor(sqrt(N)); wheel skips even D > 2.
   function Is_Prime (N : U64) return Boolean
     with Global => null;

   --  Least prime p that divides N. N = 0 or N = 1 → Invalid_Argument.
   --  If N is prime, returns N.
   function Smallest_Prime_Factor (N : U64) return U64
     with Global => null;

   --  Complete factorization of N into prime powers (with multiplicity
   --  encoded as Exponent). N = 0 → Invalid_Argument. N = 1 → empty list.
   --  Example: Factorize (100) = [(2,2), (5,2)]; Factorize (70) = [(2,1),(5,1),(7,1)].
   function Factorize (N : U64) return Factor_List
     with Global => null;

   ------------------------------------------------------------------
   --  Helpers
   ------------------------------------------------------------------

   --  Integer square root floor(sqrt(N)), self-contained (no Float).
   --  Overflow-safe binary search on U64. N = 0 → 0.
   function Floor_Sqrt (N : U64) return U64
     with Global => null;

end Trial_Division;
