--  Acorn_Generator — Ada 2023 educational package for the Additive
--  Congruential Random Number (ACORN) generator of order k
--
--      for i in 1 .. k:
--          Y_i ← (Y_i + Y_{i-1}) mod M
--
--  Output variate is Y_k (or Y_k / M ∈ [0, 1)). State vector Y[0 .. k].
--  Create / Reset from a length-(k+1) seed array or a single seed
--  expanded via an LCG fill (odd seed forced when needed). Max_Order = 64.
--  Invalid_Argument for bad order / modulus / seeds.
--  Reference: https://en.wikipedia.org/wiki/ACORN_(PRNG)
--  Sibling sheets (README only — do not `with`): Linear congruential
--  generator, Lagged Fibonacci generator, Blum Blum Shub, Mersenne Twister —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Acorn_Generator
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Word type and order bounds
   ---------------------------------------------------------------------------

   --  All ACORN integers (state words, modulus M, seeds) are nonnegative
   --  by construction. M = 0 is rejected (not a working modulus).
   type Value is mod 2 ** 64;

   --  Maximum order k. Literature allows larger orders (≤ 120); this
   --  classroom cap keeps the fixed state buffer small.
   Max_Order : constant Positive := 64;
   subtype Order_Type is Positive range 1 .. Max_Order;

   --  Default classroom modulus (power of two; preferred educationally).
   Default_Modulus : constant Value := 2 ** 32;

   ---------------------------------------------------------------------------
   -- Seed / state arrays (length Order + 1)
   ---------------------------------------------------------------------------

   --  Indices 0 .. Order hold Y_0 .. Y_k. Length must be Order + 1.
   type State_Array is array (Natural range <>) of Value;

   type Generator is private;
   --  Holds Order, M, the state vector Y[0 .. Order], and an
   --  initialised flag. Default (uninitialised) generators have
   --  Order = 0 effectively and are rejected by Next / Reset / Next_Float.

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Order is out of 1 .. Max_Order, when M < 2, when a
   --  seed array length ≠ Order + 1, when a seed / state word is ≥ M,
   --  when an uninitialised generator is used, or when a modular
   --  helper is called with modulus 0.

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Order (K : Positive) return Boolean
     with Global => null;
   --  True iff 1 ≤ K ≤ Max_Order.

   function Is_Valid_Modulus (M : Value) return Boolean
     with Global => null;
   --  True iff M ≥ 2.

   ---------------------------------------------------------------------------
   -- Create / Reset / Next / Next_Float
   ---------------------------------------------------------------------------

   --  Algorithm sketch:
   --    Store Order = k, M, and Y[0 .. k].
   --    Each Next updates, for i = 1 .. k:
   --        Y[i] ← (Y[i] + Y[i−1]) mod M
   --    and returns Y[k]. Next_Float returns Y[k] / M ∈ [0, 1).
   --    A single Seed fills Y[0 .. k] with an LCG (Numerical Recipes
   --    parameters, reduced modulo M), then forces Y[0] odd when M is
   --    even (literature preference: avoid the all-even fixed subspace).

   function Create
     (Order  : Order_Type;
      M      : Value;
      Seeds  : State_Array) return Generator
     with Global => null;
   --  New generator. Seeds'Length must equal Order + 1; each Seeds(I) < M.
   --  Raises Invalid_Argument when order, modulus, or seed array is bad.

   function Create
     (Order : Order_Type;
      M     : Value;
      Seed  : Value) return Generator
     with Global => null;
   --  New generator; state filled from Seed via LCG. Seed must be < M.
   --  Raises Invalid_Argument when order / modulus / seed is bad.

   procedure Reset (G : in out Generator; Seeds : State_Array)
     with Global => null;
   --  Reinstall seed array (Order and M unchanged). Length must equal
   --  Order + 1; each word < M. Raises Invalid_Argument on bad seeds
   --  or uninitialised G.

   procedure Reset (G : in out Generator; Seed : Value)
     with Global => null;
   --  Refill state from Seed via LCG. Seed must be < M.
   --  Raises Invalid_Argument on bad seed or uninitialised G.

   function Next (G : in out Generator) return Value
     with Global => null;
   --  Advance the additive sweep and return Y[k].
   --  Raises Invalid_Argument when G is uninitialised.

   function Next_Float (G : in out Generator) return Long_Float
     with Global => null;
   --  Advance as Next and return Y[k] / M as a Long_Float in [0, 1).
   --  Raises Invalid_Argument when G is uninitialised.

   ---------------------------------------------------------------------------
   -- Inspectors
   ---------------------------------------------------------------------------

   function Order_Of (G : Generator) return Order_Type
     with Global => null;
   --  Raises Invalid_Argument when G is uninitialised.

   function Modulus_Of (G : Generator) return Value
     with Global => null;
   --  Raises Invalid_Argument when G is uninitialised.

   function Get_State (G : Generator) return State_Array
     with Global => null;
   --  Copy of Y[0 .. Order]. Raises Invalid_Argument when uninitialised.

   function Get_Y (G : Generator; Index : Natural) return Value
     with Global => null;
   --  Y[Index] for Index in 0 .. Order. Raises Invalid_Argument when
   --  Index > Order or G is uninitialised.

   function Is_Initialised (G : Generator) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Overflow-safe modular helpers (educational)
   ---------------------------------------------------------------------------

   function Add_Mod (X, Y, M : Value) return Value
     with Global => null;
   --  (X + Y) mod M. Raises Invalid_Argument when M = 0.

private

   type Buffer_Array is array (Natural range 0 .. Max_Order) of Value;

   type Generator is record
      Order       : Natural       := 0;  -- 0 means uninitialised
      M           : Value         := 0;
      Y           : Buffer_Array  := [others => 0];
      Initialised : Boolean       := False;
   end record;

end Acorn_Generator;
