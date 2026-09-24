--  Bloom_Filter — Ada 2023 educational package for Wikipedia "Bloom filter"
--  (Burton Howard Bloom, 1970). Space-efficient probabilistic set membership:
--  false positives possible, false negatives never. Bit array of size m with
--  k hash functions; double hashing h_i(x) = h1(x) + i·h2(x) (mod m).
--  Optimal sizing: m = −n ln p / (ln 2)^2, k = (m/n) ln 2.
--  Related (README only): counting Bloom filter, cuckoo / quotient filters.

pragma Ada_2022;

with Ada.Finalization;

package Bloom_Filter
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Probability is Real range Real'Model_Small .. 1.0 - Real'Model_Small;
   --  Open (0,1) for target false-positive rate arguments.

   subtype Bit_Count is Positive;
   subtype Hash_Count is Positive;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Ln (X : Positive_Real) return Real
     with Global => null;
   --  Natural logarithm (series / Newton on exp). Raises Invalid_Argument
   --  if X <= 0 (enforced by subtype).

   function Exp (X : Real) return Positive_Real
     with Global => null;
   --  e^X via series (clamped for educational range).

   function Optimal_M
     (N                    : Positive;
      False_Positive_Rate  : Probability) return Bit_Count
     with Global => null;
   --  m = ceil(−n ln p / (ln 2)^2).

   function Optimal_K
     (M : Bit_Count;
      N : Positive) return Hash_Count
     with Global => null;
   --  k = max(1, round((m/n) ln 2)).

   function Optimal_K_From_Rate
     (False_Positive_Rate : Probability) return Hash_Count
     with Global => null;
   --  k = max(1, round(−ln p / ln 2)).

   ---------------------------------------------------------------------------
   -- Bloom filter
   ---------------------------------------------------------------------------

   type Filter is private;

   function Create
     (M : Bit_Count;
      K : Hash_Count) return Filter
     with Global => null;
   --  Empty filter: m-bit array, k hash functions (double hashing).

   function Create_For_Capacity
     (N                   : Positive;
      False_Positive_Rate : Probability) return Filter
     with Global => null;
   --  Choose m, k via Optimal_M / Optimal_K for expected n inserts and
   --  target false-positive probability p.

   function Size (F : Filter) return Natural
     with Global => null;
   --  Bit-array length m (0 if empty/default).

   function Hash_Functions (F : Filter) return Natural
     with Global => null;
   --  Number of hash functions k.

   function Insert_Count (F : Filter) return Natural
     with Global => null;
   --  Number of Add calls (not distinct-cardinality).

   function Bits_Set (F : Filter) return Natural
     with Global => null;
   --  Population count X of bits set to 1.

   procedure Add (F : in out Filter; Key : String)
     with Global => null;
   --  Insert string key (byte sequence). No-op semantics beyond setting
   --  the k bit positions; never raises for empty string.

   procedure Add (F : in out Filter; Key : Natural)
     with Global => null;
   --  Insert modular/integer key (little-endian byte image of Key).

   function Might_Contain (F : Filter; Key : String) return Boolean
     with Global => null;
   --  True => possibly in set; False => definitely not (no false negatives).

   function Might_Contain (F : Filter; Key : Natural) return Boolean
     with Global => null;

   function Probably_Contains (F : Filter; Key : String) return Boolean
     with Global => null;
   --  Alias of Might_Contain (String).

   function Probably_Contains (F : Filter; Key : Natural) return Boolean
     with Global => null;
   --  Alias of Might_Contain (Natural).

   procedure Clear (F : in out Filter)
     with Global => null;
   --  Reset all bits to 0 and Insert_Count to 0; keep m and k.

   function Fill_Ratio (F : Filter) return Unit_Interval
     with Global => null;
   --  X / m (fraction of bits set). 0 when m = 0.

   function Estimated_False_Positive_Rate (F : Filter) return Unit_Interval
     with Global => null;
   --  Approximate ε ≈ (1 − e^(−k n / m))^k using Insert_Count as n.
   --  Also ≈ (Fill_Ratio)^k under the independence model.

   function Estimated_Cardinality (F : Filter) return Non_Negative
     with Global => null;
   --  n* = −(m/k) ln(1 − X/m) when X < m; else a large sentinel.

   function Theoretical_FPR
     (M : Bit_Count;
      K : Hash_Count;
      N : Natural) return Unit_Interval
     with Global => null;
   --  (1 − e^(−k n / m))^k helper for tests / analysis.

private

   type Word is mod 2**64;
   type Word_Array is array (Natural range <>) of Word;
   type Word_Array_Access is access Word_Array;

   type Filter is new Ada.Finalization.Controlled with record
      Bits : Word_Array_Access := null;
      M    : Natural           := 0;
      K    : Natural           := 0;
      N    : Natural           := 0;
   end record;

   overriding procedure Adjust (F : in out Filter);
   overriding procedure Finalize (F : in out Filter);

end Bloom_Filter;
