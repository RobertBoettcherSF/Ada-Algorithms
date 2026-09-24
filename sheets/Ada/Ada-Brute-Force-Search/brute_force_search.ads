--  Brute_Force_Search — Ada 2023 educational package for Wikipedia
--  "Brute-force search" (exhaustive search / generate-and-test):
--  systematically check every candidate until a solution is found (or
--  the candidate space is exhausted). Demonstrations: trial division,
--  linear search, subset-sum via 2^n bit masks, and small-n permutation
--  enumeration (password-style). Not to be confused with backtracking,
--  which prunes whole regions without enumerating them.
--  Reference: https://en.wikipedia.org/wiki/Brute-force_search
--  Sibling sheets (README only — do not `with`): Linear_Search,
--  Binary_Search, Backtracking.

pragma Ada_2022;

package Brute_Force_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum length for Linear_Search. Exhaustive list scan is O(n);
   --  this guard is pedagogical. Tests stay below Max_Linear_N except
   --  the deliberate Invalid_Argument case.
   Max_Linear_N : constant Positive := 100_000;

   --  Maximum length for Subset_Sum_Exists. Candidate space is 2^n;
   --  n > 20 is rejected to avoid combinatorial explosion in demos.
   Max_Subset_N : constant Positive := 20;

   --  Maximum n for permutation enumeration. Candidate space is n!;
   --  8! = 40_320 is still a light educational workload.
   Max_Perm_N : constant Positive := 8;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when an input exceeds an educational capacity (array length
   --  > Max_Linear_N / Max_Subset_N, or permutation n > Max_Perm_N).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia generate-and-test)
   ---------------------------------------------------------------------------
   --  first(P)  — produce the first candidate
   --  next(P,c) — produce the next candidate after c (or Λ when done)
   --  valid(P,c)— true iff c solves instance P
   --  output    — use the solution
   --
   --  c ← first(P)
   --  while c ≠ Λ do
   --     if valid(P,c) then output(P,c)
   --     c ← next(P,c)
   --  end while
   --
   --  Each demo below is a concrete specialisation of this loop.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- 1. Trial division (Wikipedia divisor enumeration)
   ---------------------------------------------------------------------------

   function Find_Divisor (N : Positive) return Natural
     with Global => null;
   --  Exhaustively test candidates c = 2, 3, …, N. Return the smallest
   --  c that divides N without remainder. For primes (and for N = 1)
   --  every proper candidate fails, so the result is N itself.
   --  Time Θ(d) where d is the returned divisor (worst case Θ(N) for
   --  primes). Smarter methods: trial up to √N, Pollard's rho, sieves.

   ---------------------------------------------------------------------------
   -- 2. Linear search (exhaustive scan of a list)
   ---------------------------------------------------------------------------

   function Linear_Search (A : Element_Array; Key : Integer) return Integer
     with Global => null;
   --  Generate-and-test over list indices: scan left-to-right until
   --  A(I) = Key. Returns the smallest matching index, or the sentinel
   --  A'First − 1 when Key is absent (including empty A).
   --  Raises Invalid_Argument when A'Length > Max_Linear_N.
   --  Time O(n). Prefer hashing / binary search when applicable.

   ---------------------------------------------------------------------------
   -- 3. Subset sum (exhaustive 2^n enumeration)
   ---------------------------------------------------------------------------

   function Subset_Sum_Exists
     (A      : Element_Array;
      Target : Integer) return Boolean
     with Global => null;
   --  Enumerate all 2^n subsets of A via bit masks and test whether any
   --  subset sums to Target. The empty subset sums to 0.
   --  Raises Invalid_Argument when A'Length > Max_Subset_N.
   --  Time Θ(2^n · n) naïve (Θ(2^n) with running sums). Meet-in-the-middle
   --  is O(2^{n/2}); DP is O(n · Σ|a_i|) when magnitudes are bounded.

   ---------------------------------------------------------------------------
   -- 4. Permutation enumeration (password-style, n ≤ Max_Perm_N)
   ---------------------------------------------------------------------------

   function Count_Permutations (N : Natural) return Natural
     with Global => null;
   --  Exhaustively generate every permutation of 1 .. N (Heap / lex
   --  style generate-and-test) and return how many were produced
   --  (equals N!). N = 0 yields 1 (one empty permutation).
   --  Raises Invalid_Argument when N > Max_Perm_N.
   --  Time Θ(N · N!).

   function Find_Permutation (Target : Element_Array) return Natural
     with Global => null;
   --  Among the N! permutations of 1 .. N in lexicographic order
   --  (N = Target'Length), return the 1-based rank of Target, or 0 if
   --  Target is not a permutation of 1 .. N.
   --  Raises Invalid_Argument when N > Max_Perm_N.
   --  Time O(N · N!) worst case (stops early on a hit).

   procedure Enumerate_Permutations
     (N     : Natural;
      Count : out Natural)
     with Global => null;
   --  Same exhaustive generation as Count_Permutations; writes the
   --  total into Count. Raises Invalid_Argument when N > Max_Perm_N.

end Brute_Force_Search;
