--  Addition_Chain_Exponentiation — Ada 2023 educational package for
--  addition-chain exponentiation: represent chains, validate, evaluate
--  powers along a chain, build binary (Brauer/star) chains, and search
--  shortest star-chain lengths for tiny n (OEIS A003313 pedagogy).
--  Primary source:
--  https://en.wikipedia.org/wiki/Addition-chain_exponentiation
--  Also: https://en.wikipedia.org/wiki/Addition_chain
--  Sibling (README): Ada-Exponentiating-By-Squaring; upcoming SRT,
--  Restoring, Non-restoring division. Do not `with` the sibling — a
--  tiny binary power is reimplemented here for comparison only.

pragma Ada_2022;

package Addition_Chain_Exponentiation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Educational bounds
   ---------------------------------------------------------------------------

   --  Maximum index r in a stored chain 1 = a_0 < … < a_r = n.
   --  Chain length (multiplication count) is Last (= r).
   Max_Chain_Last : constant Natural := 64;

   --  Shortest-chain BFS/star search is educational and limited to tiny n.
   Max_Shortest_N : constant Positive := 32;

   --  Naive multiply-loop oracle only for small exponents.
   Max_Naive_Exp : constant Natural := 10_000;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for: empty/oversized chain; N = 0 where Positive required;
   --  Shortest_* with N > Max_Shortest_N; Modulus ≤ 1; naive Exp bound;
   --  Evaluate/Power with invalid chain when checked.

   ---------------------------------------------------------------------------
   -- Chain representation
   ---------------------------------------------------------------------------

   --  Elements(0 .. Last) holds the strictly increasing sequence
   --  1 = a_0 < a_1 < … < a_Last = n.  Multiplication count = Last.
   type Element_Array is array (0 .. Max_Chain_Last) of Positive;

   type Chain is record
      Last     : Natural := 0;
      Elements : Element_Array := [others => 1];
   end record;

   --  True iff Elements(0)=1, strictly increasing through Last, and each
   --  Elements(I) = Elements(J) + Elements(K) for some 0 ≤ K ≤ J < I.
   function Is_Valid_Chain (C : Chain) return Boolean
     with Global => null;

   --  Multiplication count (= Last). Raises Invalid_Argument if not valid.
   function Chain_Mul_Count (C : Chain) return Natural
     with Global => null;

   --  Terminal exponent n = Elements(Last). Raises if not valid.
   function Chain_Exponent (C : Chain) return Positive
     with Global => null;

   ---------------------------------------------------------------------------
   -- Constructive chains
   ---------------------------------------------------------------------------

   --  Binary-method (star / Brauer) addition chain for N ≥ 1.
   --  Recurrence: even N → append N after chain for N/2;
   --  odd N > 1 → append N after chain for N−1.
   --  Length equals Binary_Mul_Count(N).
   function Build_Binary_Chain (N : Positive) return Chain
     with Global => null;

   --  Shortest star addition chain for 1 ≤ N ≤ Max_Shortest_N (BFS).
   --  For N ≤ 32, star length equals OEIS A003313 (shortest length).
   --  Raises Invalid_Argument if N > Max_Shortest_N.
   function Build_Shortest_Chain (N : Positive) return Chain
     with Global => null;

   ---------------------------------------------------------------------------
   -- Lengths / multiplication counts
   ---------------------------------------------------------------------------

   --  Binary exponentiation multiplication count for N ≥ 1:
   --  ⌊log₂ N⌋ + ν(N) − 1, where ν is the Hamming weight (popcount).
   --  Equals 0 for N = 1.
   function Binary_Mul_Count (N : Positive) return Natural
     with Global => null;

   --  Length ℓ(N) of a shortest addition chain for N (multiplications).
   --  Computed by star-chain BFS for N ≤ Max_Shortest_N; matches A003313.
   --  Raises Invalid_Argument if N > Max_Shortest_N.
   function Shortest_Chain_Length (N : Positive) return Natural
     with Global => null;

   ---------------------------------------------------------------------------
   -- Evaluate powers along a chain
   ---------------------------------------------------------------------------

   --  Compute Base^n by multiplying along C (n = Chain_Exponent(C)).
   --  One Long_Integer multiply per chain step. May raise Constraint_Error
   --  on overflow; prefer Evaluate_Chain_Mod for large results.
   --  Raises Invalid_Argument if C is not a valid chain.
   function Evaluate_Chain
     (Base : Long_Integer;
      C    : Chain) return Long_Integer
     with Global => null;

   --  Modular evaluation: Base^n mod Modulus along C.
   --  Raises Invalid_Argument if C invalid or Modulus ≤ 1.
   function Evaluate_Chain_Mod
     (Base, Modulus : Long_Integer;
      C             : Chain) return Long_Integer
     with Global => null;

   --  Power via binary addition chain: Build_Binary_Chain(Exp) then evaluate.
   function Power_By_Chain
     (Base : Long_Integer;
      Exp  : Positive) return Long_Integer
     with Global => null;

   function Power_By_Chain_Mod
     (Base, Exp, Modulus : Long_Integer) return Long_Integer
     with Global => null;

   --  Power via shortest star chain (Exp ≤ Max_Shortest_N).
   function Power_By_Shortest_Chain
     (Base : Long_Integer;
      Exp  : Positive) return Long_Integer
     with Global => null;

   function Power_By_Shortest_Chain_Mod
     (Base, Exp, Modulus : Long_Integer) return Long_Integer
     with Global => null;

   ---------------------------------------------------------------------------
   -- Comparison helpers (tiny binary power + naive oracle; no sibling `with`)
   ---------------------------------------------------------------------------

   --  Right-to-left square-and-multiply (reimplemented for comparison).
   function Power_Binary
     (Base : Long_Integer;
      Exp  : Natural) return Long_Integer
     with Global => null;

   function Pow_Mod
     (Base, Exp, Modulus : Long_Integer) return Long_Integer
     with Global => null;

   --  Naive loop Result := 1; multiply Base, Exp times.
   --  Raises Invalid_Argument if Exp > Max_Naive_Exp.
   function Power_Naive
     (Base : Long_Integer;
      Exp  : Natural) return Long_Integer
     with Global => null;

   --  Non-negative residue; Modulus > 0.
   function Mod_Nonneg (A, M : Long_Integer) return Long_Integer
     with Pre => M > 0, Global => null;

   function Mod_Mul (A, B, M : Long_Integer) return Long_Integer
     with Pre => M > 1, Global => null;

end Addition_Chain_Exponentiation;
