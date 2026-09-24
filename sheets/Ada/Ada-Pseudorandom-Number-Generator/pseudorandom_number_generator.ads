--  Pseudorandom_Number_Generator — Ada 2023 educational *survey* package
--  for classical pseudorandom number generators (PRNGs / DRBGs).
--
--  A PRNG is a deterministic algorithm that, from a seed, produces a
--  long sequence that approximates the statistical properties of true
--  randomness. Period, uniformity, and seed choice matter; poor choices
--  (e.g. RANDU) fail statistical tests. Cryptographic use needs CSPRNGs
--  (e.g. Blum Blum Shub) — not the toys in this survey.
--
--  Implements (self-contained; do NOT `with` sibling repos):
--    1. Linear Congruential Generator (LCG)
--         X_{n+1} = (a X_n + c) mod m
--    2. Small Lagged Fibonacci–style additive generator
--         X_n = (X_{n-j} + X_{n-k}) mod m   (fixed classroom lags)
--    3. Tiny xorshift (Marsaglia) toy for contrast
--         x ^= x << a; x ^= x >> b; x ^= x << c
--
--  Unified Generator wraps a Kind enum selecting the engine.
--  Helpers: seed/reset, Next, Next_Float in [0, 1), modular arithmetic.
--
--  Reference: https://en.wikipedia.org/wiki/Pseudorandom_number_generator
--  Sibling sheets (README only — do not `with`): Linear Congruential
--  Generator, Lagged Fibonacci Generator, ACORN, Blum Blum Shub —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Pseudorandom_Number_Generator
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Word type
   ---------------------------------------------------------------------------

   --  All PRNG integers (states, seeds, moduli, multipliers) are
   --  nonnegative by construction. Modulus 0 is rejected.
   type Value is mod 2 ** 64;

   ---------------------------------------------------------------------------
   -- Engine selector (unified Generator wraps one Kind)
   ---------------------------------------------------------------------------

   --  LCG               — classical mixed / multiplicative LCG
   --  Lagged_Fibonacci  — small fixed-lag additive LFG (classroom toy)
   --  Xorshift          — Marsaglia xorshift64 toy (nonzero seed)
   type Kind is (LCG, Lagged_Fibonacci, Xorshift);

   ---------------------------------------------------------------------------
   -- LCG parameters
   ---------------------------------------------------------------------------

   --  Multiplier A, increment C, modulus M of
   --  X_{n+1} = (A * X_n + C) mod M.
   --  Valid: M ≥ 2 and A rem M ≠ 0. Published A or C may exceed M;
   --  they are reduced. C ≡ 0 (mod M) ⇒ multiplicative / Lehmer LCG.
   type LCG_Parameters is record
      A : Value := 0;
      C : Value := 0;
      M : Value := 0;
   end record;

   --  Numerical Recipes (Press et al.), 32-bit mixed LCG.
   Numerical_Recipes : constant LCG_Parameters :=
     (A => 1_664_525, C => 1_013_904_223, M => 2 ** 32);

   --  glibc rand() / ANSI C (same (A, C, M)).
   Glibc : constant LCG_Parameters :=
     (A => 1_103_515_245, C => 12_345, M => 2 ** 31);

   --  Park–Miller MINSTD (Lehmer / MCG).
   Park_Miller : constant LCG_Parameters :=
     (A => 16_807, C => 0, M => 2 ** 31 - 1);

   --  Default LCG for Create (Kind => LCG, …).
   Default_LCG : constant LCG_Parameters := Numerical_Recipes;

   ---------------------------------------------------------------------------
   -- Lagged Fibonacci classroom constants (fixed small lags)
   ---------------------------------------------------------------------------

   --  Additive LFG: X_n = (X_{n-J} + X_{n-K}) mod LFG_Modulus
   --  with 0 < J < K. These lags are deliberately tiny for the survey
   --  (sibling Ada-Lagged-Fibonacci-Generator covers published pairs).
   LFG_J : constant Positive := 7;
   LFG_K : constant Positive := 10;
   LFG_Modulus : constant Value := 2 ** 32;

   ---------------------------------------------------------------------------
   -- Xorshift classroom shifts (Marsaglia xorshift64 triple)
   ---------------------------------------------------------------------------

   --  x ^= x << XS_A;  x ^= x >> XS_B;  x ^= x << XS_C
   XS_A : constant Natural := 13;
   XS_B : constant Natural := 7;
   XS_C : constant Natural := 17;

   ---------------------------------------------------------------------------
   -- Generator
   ---------------------------------------------------------------------------

   type Generator is private;
   --  Holds Kind, the last Create / Reset seed, and the active engine
   --  state (LCG triple + residue, LFG ring buffer, or xorshift word).
   --  Default (uninitialised) generators are rejected by Next / Reset.

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for invalid parameters (M < 2, A ≡ 0 mod M), seed / state
   --  out of range, zero xorshift seed, uninitialised generator, or
   --  modular helpers called with modulus 0.

   ---------------------------------------------------------------------------
   -- Create / Reset
   ---------------------------------------------------------------------------

   function Create
     (Engine : Kind;
      Seed   : Value;
      Params : LCG_Parameters := Default_LCG) return Generator
     with Global => null;
   --  New generator of the given Kind.
   --  LCG: Params (default Numerical Recipes); 0 ≤ Seed < M.
   --  Lagged_Fibonacci: Seed fills the K-word buffer via an internal
   --    LCG; Params is ignored.
   --  Xorshift: Seed must be nonzero; Params is ignored.
   --  Raises Invalid_Argument on illegal seed / Params.

   function Create_LCG
     (Seed   : Value;
      Params : LCG_Parameters := Default_LCG) return Generator
     with Global => null;
   --  Equivalent to Create (LCG, Seed, Params).

   function Create_Lagged_Fibonacci (Seed : Value) return Generator
     with Global => null;
   --  Equivalent to Create (Lagged_Fibonacci, Seed).

   function Create_Xorshift (Seed : Value) return Generator
     with Global => null;
   --  Equivalent to Create (Xorshift, Seed). Seed ≠ 0.

   procedure Reset (G : in out Generator; Seed : Value)
     with Global => null;
   --  Re-seed with the same Kind / LCG Params. Same seed constraints
   --  as Create. Raises Invalid_Argument if G is uninitialised or
   --  Seed is illegal for G's Kind.

   ---------------------------------------------------------------------------
   -- Sampling
   ---------------------------------------------------------------------------

   function Next (G : in out Generator) return Value
     with Global => null;
   --  Advance the active engine and return the new sample word.
   --  Raises Invalid_Argument if G is uninitialised.

   function Next_Float (G : in out Generator) return Long_Float
     with Global => null;
   --  Advance as Next and map into [0, 1):
   --    LCG / LFG  →  X / M
   --    Xorshift   →  X / 2^64
   --  Raises Invalid_Argument if G is uninitialised.

   ---------------------------------------------------------------------------
   -- Inspectors
   ---------------------------------------------------------------------------

   function Get_Kind (G : Generator) return Kind
     with Global => null;
   --  Raises Invalid_Argument if G is uninitialised.

   function Get_Seed (G : Generator) return Value
     with Global => null;
   --  Seed last supplied to Create / Reset.
   --  Raises Invalid_Argument if G is uninitialised.

   function Get_State (G : Generator) return Value
     with Global => null;
   --  Peek at the primary state word without advancing:
   --    LCG      → current X_n
   --    LFG      → most recently written buffer word (or seed fill tail)
   --    Xorshift → current 64-bit state
   --  Raises Invalid_Argument if G is uninitialised.

   function Get_LCG_Parameters (G : Generator) return LCG_Parameters
     with Global => null;
   --  LCG parameters stored in G (meaningful when Kind = LCG).
   --  Raises Invalid_Argument if G is uninitialised or Kind ≠ LCG.

   function Is_Initialised (G : Generator) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- LCG validation / pure step
   ---------------------------------------------------------------------------

   function Is_Valid_LCG_Parameters (Params : LCG_Parameters) return Boolean
     with Global => null;
   --  True iff M ≥ 2 and A rem M ≠ 0.

   function Reduce_LCG (Params : LCG_Parameters) return LCG_Parameters
     with Global => null;
   --  (A rem M, C rem M, M). Raises Invalid_Argument when M = 0.

   function LCG_Step (State : Value; Params : LCG_Parameters) return Value
     with Global => null;
   --  Pure (A * State + C) mod M. Raises Invalid_Argument when Params
   --  is invalid or State ≥ M.

   ---------------------------------------------------------------------------
   -- Xorshift pure step
   ---------------------------------------------------------------------------

   function Xorshift_Step (State : Value) return Value
     with Global => null;
   --  One Marsaglia xorshift64 triple step. Raises Invalid_Argument
   --  when State = 0 (fixed point / degenerate).

   ---------------------------------------------------------------------------
   -- Overflow-safe modular arithmetic (educational helpers)
   ---------------------------------------------------------------------------

   function Add_Mod (X, Y, M : Value) return Value
     with Global => null;
   --  (X + Y) mod M. Raises Invalid_Argument when M = 0.

   function Mul_Mod (X, Y, M : Value) return Value
     with Global => null;
   --  (X * Y) mod M via a 128-bit intermediate.
   --  Raises Invalid_Argument when M = 0.

   function Sub_Mod (X, Y, M : Value) return Value
     with Global => null;
   --  (X − Y) mod M. Raises Invalid_Argument when M = 0.

private

   --  Ring buffer for the classroom LFG (length = LFG_K).
   type LFG_Buffer is array (1 .. LFG_K) of Value;

   type Generator is record
      Initialised : Boolean := False;
      Engine      : Kind := LCG;
      Seed        : Value := 0;

      --  LCG fields (used when Engine = LCG)
      LCG_A     : Value := 0;
      LCG_C     : Value := 0;
      LCG_M     : Value := 0;
      LCG_State : Value := 0;

      --  LFG fields (used when Engine = Lagged_Fibonacci)
      LFG_Buf : LFG_Buffer := [others => 0];
      LFG_Idx : Natural := 0;  -- next write index in 0 .. LFG_K - 1

      --  Xorshift field (used when Engine = Xorshift)
      XS_State : Value := 0;
   end record;

end Pseudorandom_Number_Generator;
