--  Approximate_Counting — Ada 2023 educational package for Wikipedia
--  "Approximate counting algorithm" (Morris probabilistic counter, 1977/78;
--  Flajolet analysis, BIT 1985). Stores only an exponent c and estimates the
--  true event count with an unbiased geometric estimator.
--  Classic: increment with probability p = 2^{-c}; estimate n̂ = 2^c − 1.
--  General base b > 1: p = b^{-c}; n̂ = (b^c − 1)/(b − 1).
--  Related siblings (README only, no deps): Ada-HyperLogLog / streaming
--  frequency-moment counters (not implemented here).

pragma Ada_2022;

package Approximate_Counting
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable power / estimate arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   --  Cap exponent so 2^c stays well inside Real range for educational use.
   Max_Exponent : constant Natural := 60;

   subtype Exponent_Value is Natural range 0 .. Max_Exponent;

   --  Bases strictly greater than 1 (classic Morris uses Base = 2).
   subtype Base_Value is Real range 1.0 + Real'Model_Small .. Real'Last;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Seeded RNG (LCG) for reproducible Increment draws
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Uniform on [0, 1).

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Power (Base : Real; Exp : Natural) return Real
     with Global => null;
   --  Base^Exp (real power by successive multiply). Raises Invalid_Argument
   --  if Base <= 0.0.

   function Increment_Probability
     (C    : Exponent_Value;
      Base : Base_Value := 2.0) return Unit_Interval
     with Global => null;
   --  p = Base^{-C}. For Base = 2 this is 2^{-C}. When C = 0, p = 1.

   ---------------------------------------------------------------------------
   -- Morris counter
   ---------------------------------------------------------------------------

   type Counter is private;

   function Create
     (Initial_Exponent : Exponent_Value := 0;
      Base             : Base_Value     := 2.0) return Counter
     with Global => null;
   --  New counter with exponent Initial_Exponent and geometric base Base.
   --  Classic Morris / Flajolet uses Base = 2.0.

   function Exponent (C : Counter) return Exponent_Value
     with Global => null;
   --  Stored exponent c.

   function Base_Of (C : Counter) return Base_Value
     with Global => null;

   function Estimate (C : Counter) return Non_Negative
     with Global => null;
   --  Unbiased Flajolet / Morris estimator:
   --    n̂ = (Base^c − 1) / (Base − 1).
   --  For Base = 2: n̂ = 2^c − 1.

   function Power_Approximation (C : Counter) return Non_Negative
     with Global => null;
   --  Wikipedia table "Approximation" column: Base^c (for Base = 2: 2^c).
   --  Not the unbiased estimator; documented separately from Estimate.

   procedure Increment
     (C     : in out Counter;
      State : in out RNG_State)
     with Global => null;
   --  With probability Base^{-c}, increment the exponent by 1.
   --  Draws Uniform[0,1) via Next_Unit. Raises Capacity_Exceeded if
   --  Exponent would exceed Max_Exponent.

   procedure Increment_With_Probability
     (C : in out Counter;
      U : Unit_Interval)
     with Global => null;
   --  Deterministic test hook: increment iff U < Base^{-c}.
   --  Inject U = 0.0 to force the success path when p > 0.
   --  Raises Capacity_Exceeded if Exponent would exceed Max_Exponent.

   procedure Increment_Many
     (C     : in out Counter;
      N     : Natural;
      State : in out RNG_State)
     with Global => null;
   --  Call Increment N times with the same RNG state.

   function Expectation_Given_Exponent (C : Counter) return Non_Negative
     with Global => null;
   --  Wikipedia table "Expectation (sufficiently large n)" column for
   --  Base = 2: 2^{c+1} − 2 = 2 * (2^c − 1). For general Base:
   --  Base * (Base^c − 1) / (Base − 1) − 1 when that form is meaningful;
   --  for Base = 2 matches the wiki column. Educational helper only.

private

   type Counter is record
      C    : Exponent_Value := 0;
      Base : Base_Value     := 2.0;
   end record;

end Approximate_Counting;
