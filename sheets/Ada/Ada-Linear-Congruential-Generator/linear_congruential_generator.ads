--  Linear_Congruential_Generator — Ada 2023 educational package for the
--  classical linear congruential generator (LCG)
--
--      X_{n+1} = (a * X_n + c) mod m
--
--  Types for Parameters (A, C, M) and Generator state / seed. Create /
--  Reset / Next / Next_Float (the last in [0, 1)). Built-in well-known
--  parameter sets (Numerical Recipes, glibc, Borland, Park–Miller, …).
--  Hull–Dobell full-period helpers. Overflow-safe modular multiply via a
--  128-bit intermediate (or add-and-double). Invalid_Argument for M = 0
--  and other bad parameters.
--  Reference: https://en.wikipedia.org/wiki/Linear_congruential_generator
--  Sibling sheets (README only — do not `with`): Lagged Fibonacci
--  generator, Blum Blum Shub, Mersenne Twister —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Linear_Congruential_Generator
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Word type (unsigned 64-bit; modulus M lives in 2 .. 2^64 − 1)
   ---------------------------------------------------------------------------

   --  All LCG integers (A, C, M, seed, state) are nonnegative by
   --  construction. M = 0 is not representable as a working modulus
   --  (that encoding would collide with 2^64 wrap) and is rejected.
   type Value is mod 2 ** 64;

   ---------------------------------------------------------------------------
   -- Parameters (A, C, M) and generator state
   ---------------------------------------------------------------------------

   --  Multiplier A, increment C, modulus M of the recurrence
   --  X_{n+1} = (A * X_n + C) mod M.
   --  Valid parameters satisfy M ≥ 2 and A ≢ 0 (mod M). Published
   --  multipliers may exceed M (e.g. Visual Basic); they are reduced
   --  modulo M. C is reduced modulo M. When C ≡ 0 (mod M) the
   --  generator is a multiplicative congruential generator (MCG /
   --  Lehmer RNG).
   type Parameters is record
      A : Value := 0;
      C : Value := 0;
      M : Value := 0;
   end record;

   type Generator is private;
   --  Holds Parameters, the current state X_n, and the last Reset /
   --  Create seed X_0. Default (uninitialised) Parameters have M = 0
   --  and are rejected by Next / Reset / Next_Float.

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when M = 0 or M = 1, when A ≡ 0 (mod M), when a seed
   --  or state is ≥ M, or when a modular helper is called with
   --  modulus 0.

   ---------------------------------------------------------------------------
   -- Well-known parameter sets (popularity, not endorsement)
   -- Values follow the Wikipedia “Parameters in common use” table.
   ---------------------------------------------------------------------------

   --  Numerical Recipes (Press et al.), 32-bit mixed LCG.
   Numerical_Recipes : constant Parameters :=
     (A => 1_664_525, C => 1_013_904_223, M => 2 ** 32);

   --  glibc rand() / ANSI C (Watcom, Digital Mars, …): same (A, C, M).
   Glibc : constant Parameters :=
     (A => 1_103_515_245, C => 12_345, M => 2 ** 31);

   ANSI_C : constant Parameters :=
     (A => 1_103_515_245, C => 12_345, M => 2 ** 31);

   --  Borland C/C++.
   Borland_C : constant Parameters :=
     (A => 22_695_477, C => 1, M => 2 ** 32);

   --  Borland Delphi / Virtual Pascal.
   Borland_Delphi : constant Parameters :=
     (A => 134_775_813, C => 1, M => 2 ** 32);

   --  Microsoft Visual / Quick C/C++.
   Microsoft_Visual_C : constant Parameters :=
     (A => 214_013, C => 2_531_011, M => 2 ** 32);

   --  Microsoft Visual Basic 6 and earlier.
   Microsoft_Visual_Basic : constant Parameters :=
     (A => 1_140_671_485, C => 12_820_163, M => 2 ** 24);

   --  Park–Miller MINSTD (C++11 minstd_rand0): Lehmer / MCG.
   Park_Miller : constant Parameters :=
     (A => 16_807, C => 0, M => 2 ** 31 - 1);

   --  C++11 minstd_rand (improved Park–Miller multiplier).
   MINSTD_Rand : constant Parameters :=
     (A => 48_271, C => 0, M => 2 ** 31 - 1);

   --  RANDU (historically infamous; period and spectral defects).
   RANDU : constant Parameters :=
     (A => 65_539, C => 0, M => 2 ** 31);

   --  Java java.util.Random / POSIX [ln]rand48 (48-bit state).
   Java_Util_Random : constant Parameters :=
     (A => 25_214_903_917, C => 11, M => 2 ** 48);

   --  VMS MTH$RANDOM / old glibc.
   VMS_MTH_Random : constant Parameters :=
     (A => 69_069, C => 1, M => 2 ** 32);

   --  Sinclair ZX81 (tiny educational mixed LCG; m = 65537 prime).
   ZX81 : constant Parameters :=
     (A => 75, C => 74, M => 65_537);

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Parameters (Params : Parameters) return Boolean
     with Global => null;
   --  True iff M ≥ 2 and A rem M ≠ 0.

   function Reduce (Params : Parameters) return Parameters
     with Global => null;
   --  (A rem M, C rem M, M). Raises Invalid_Argument when M = 0.

   ---------------------------------------------------------------------------
   -- Create / Reset / Next / Next_Float
   ---------------------------------------------------------------------------

   --  Algorithm sketch:
   --    Store (A, C, M) and seed X_0 (0 ≤ X_0 < M).
   --    Each Next replaces the state by  X ← (A * X + C) mod M
   --    using a 128-bit intermediate product so A * X + C cannot wrap
   --    the 64-bit word before the reduction, and returns the new X.
   --    Next_Float returns X / M ∈ [0, 1).

   function Create (Params : Parameters; Seed : Value) return Generator
     with Global => null;
   --  New generator with the given parameters and seed X_0 = Seed.
   --  Raises Invalid_Argument when Params is invalid or Seed ≥ M.

   procedure Reset (G : in out Generator; Seed : Value)
     with Global => null;
   --  Set state and stored seed to Seed (parameters unchanged).
   --  Raises Invalid_Argument when Seed ≥ M or G has M = 0.

   function Next (G : in out Generator) return Value
     with Global => null;
   --  Advance: X ← (A * X + C) mod M, return the new X
   --  (so the first Next after Create (P, S) is X_1).
   --  Raises Invalid_Argument when G has invalid parameters.

   function Next_Float (G : in out Generator) return Long_Float
     with Global => null;
   --  Advance as Next and return X / M as a Long_Float in [0, 1).
   --  Raises Invalid_Argument when G has invalid parameters.

   function Step (State : Value; Params : Parameters) return Value
     with Global => null;
   --  Pure recurrence: return (A * State + C) mod M.
   --  Raises Invalid_Argument when Params is invalid or State ≥ M.

   ---------------------------------------------------------------------------
   -- Inspectors
   ---------------------------------------------------------------------------

   function Get_Parameters (G : Generator) return Parameters
     with Global => null;

   function Get_State (G : Generator) return Value
     with Global => null;
   --  Current X_n (does not advance). After Create / Reset this is X_0.

   function Get_Seed (G : Generator) return Value
     with Global => null;
   --  Seed last supplied to Create / Reset.

   ---------------------------------------------------------------------------
   -- Overflow-safe modular arithmetic (educational helpers)
   ---------------------------------------------------------------------------

   function Add_Mod (X, Y, M : Value) return Value
     with Global => null;
   --  (X + Y) mod M. Raises Invalid_Argument when M = 0.

   function Mul_Mod (X, Y, M : Value) return Value
     with Global => null;
   --  (X * Y) mod M via a 128-bit intermediate (no 64-bit wrap of the
   --  product). Raises Invalid_Argument when M = 0.

   function Gcd (X, Y : Value) return Value
     with Global => null;
   --  Euclidean gcd. Gcd (0, 0) = 0; Gcd (0, Y) = Y; Gcd (X, 0) = X.

   function Are_Coprime (X, Y : Value) return Boolean
     with Global => null;
   --  True iff Gcd (X, Y) = 1.

   ---------------------------------------------------------------------------
   -- Hull–Dobell period checks
   -- Full period m for every seed  ⇔
   --   (1) gcd(C, M) = 1
   --   (2) A − 1 is divisible by every prime factor of M
   --   (3) A − 1 is divisible by 4 whenever M is divisible by 4
   ---------------------------------------------------------------------------

   function Prime_Factors_Divide (D, M : Value) return Boolean
     with Global => null;
   --  True iff every prime factor of M divides D.
   --  Raises Invalid_Argument when M = 0.

   function Increment_Coprime (Params : Parameters) return Boolean
     with Global => null;
   --  Hull–Dobell (1): gcd(C, M) = 1.
   --  Raises Invalid_Argument when Params is invalid.

   function Multiplier_Condition (Params : Parameters) return Boolean
     with Global => null;
   --  Hull–Dobell (2): every prime factor of M divides A − 1.
   --  Raises Invalid_Argument when Params is invalid.

   function Four_Condition (Params : Parameters) return Boolean
     with Global => null;
   --  Hull–Dobell (3): if 4 | M then 4 | (A − 1).
   --  Raises Invalid_Argument when Params is invalid.

   function Hull_Dobell_Satisfied (Params : Parameters) return Boolean
     with Global => null;
   --  True iff all three Hull–Dobell conditions hold (period = M for
   --  every seed). Raises Invalid_Argument when Params is invalid.
   --  Mixed LCGs with a power-of-two modulus commonly satisfy this;
   --  MCGs (C = 0) never do for M > 1.

private

   type Generator is record
      Params : Parameters;
      State  : Value := 0;
      Seed   : Value := 0;
   end record;

end Linear_Congruential_Generator;
