--  Sieve of Eratosthenes — Ada 2023 educational package.
--  Classical boolean-array sieve for primes up to N (Natural / Positive).
--  Primary source:
--  https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes
--  Note-sheet typo "Erastothenes" → Eratosthenes.
--  Sundaram row skipped (Ada-Sieve-Of-Sundaram may already exist).
--  Next: Sieve of Atkin.

pragma Ada_2022;

package Sieve_Of_Eratosthenes
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Educational capacity
   ------------------------------------------------------------------

   --  Cap keeps classroom tests fast (π(200_000) ≈ 17_984).
   Max_N : constant := 200_000;

   --  Valid indices / sieve upper bounds live in 0 .. Max_N.
   --  Callable sieve N must further satisfy N >= 2 (else Invalid_Argument).
   subtype Limit is Natural range 0 .. Max_N;

   --  Index = candidate; True means still marked prime after sieving.
   type Flag_Array is array (Natural range <>) of Boolean;

   --  Unconstrained list of primes (secondary-stack return).
   type Prime_List is array (Positive range <>) of Positive;

   --  Bounded buffer for Fill_Primes (Last = number of primes written).
   subtype Prime_Buffer is Prime_List (1 .. Max_N);

   Invalid_Argument : exception;

   ------------------------------------------------------------------
   --  Core sieve
   ------------------------------------------------------------------

   --  Is_Prime (0 .. N). Indices 0 and 1 are False; composites marked
   --  from p² stepping by p for each prime p ≤ floor(sqrt(N)).
   --  Raises Invalid_Argument if N < 2 or N > Max_N.
   --  (N is conceptually a Limit; Natural lets us raise Invalid_Argument
   --  instead of Constraint_Error when N > Max_N.)
   function Sieve (N : Natural) return Flag_Array
     with Global => null;

   --  π(N) = number of primes ≤ N.
   function Count_Primes (N : Natural) return Natural
     with Global => null;

   --  Unconstrained secondary-stack return of all primes ≤ N.
   function Primes_Up_To (N : Natural) return Prime_List
     with Global => null;

   --  Fill Primes (1 .. Last) with primes ≤ N; Last = π(N).
   procedure Fill_Primes
     (N      : Natural;
      Primes : out Prime_Buffer;
      Last   : out Natural)
     with Global => null;

   --  K-th prime ≤ N (1-based among primes ≤ N). Raises Invalid_Argument
   --  if N invalid, K = 0 is excluded by Positive, or K > π(N).
   function Nth_Prime (N : Natural; K : Positive) return Positive
     with Global => null;

   --  Lookup in a previously computed flag array.
   --  Raises Invalid_Argument if K not in Flags'Range.
   function Is_Prime_In_Sieve
     (Flags : Flag_Array;
      K     : Natural) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Odds-only bonus (compact educational variant)
   ------------------------------------------------------------------

   --  Odds-only marking internally; returns full Is_Prime (0 .. N) for
   --  easy comparison with Sieve. Raises Invalid_Argument if N invalid.
   function Sieve_Odds (N : Natural) return Flag_Array
     with Global => null;

   ------------------------------------------------------------------
   --  Helpers
   ------------------------------------------------------------------

   --  Raises Invalid_Argument unless N in 2 .. Max_N.
   procedure Ensure_Valid_N (N : Natural)
     with Global => null;

   --  Integer square root floor(sqrt(N)), self-contained (no Float).
   function Floor_Sqrt (N : Natural) return Natural
     with Global => null;

end Sieve_Of_Eratosthenes;
