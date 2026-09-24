-- Sieve of Sundaram - Package Specification
-- This package provides a strongly-typed implementation of the Sieve of Sundaram, 
-- an algorithm to find all prime numbers up to a specified integer.

package Sieve_Of_Sundaram is

   -- Strong typing: Custom array type to hold dynamically sized lists of prime numbers
   type Prime_Array is array (Positive range <>) of Integer;

   -- VARIANT 1: Standard Pre-calculated Array
   -- Computes and returns an array of all prime numbers up to the specified limit.
   -- Uses the O(n log n) sieve mechanism over a dynamically allocated boolean map.
   function Standard_Sundaram (Limit : Integer) return Prime_Array;

   -- VARIANT 2: Count-Only / Memory Efficient Sieve
   -- Evaluates the sieve mathematically to determine the *quantity* of primes 
   -- up to the given limit without allocating arrays for the primes themselves.
   function Count_Primes_Sundaram (Limit : Integer) return Natural;

   -- VARIANT 3: Single-Query Deterministic Sieve Check
   -- Modifies the algorithm to act as a primality tester. Instead of sieving 
   -- the whole domain, it evaluates if a specific number K can be factored 
   -- using the (i + j + 2ij) relation of the Sundaram Sieve.
   function Is_Prime_Sundaram (N : Integer) return Boolean;

end Sieve_Of_Sundaram;
