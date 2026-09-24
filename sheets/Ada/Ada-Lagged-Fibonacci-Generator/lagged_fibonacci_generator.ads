--  Lagged_Fibonacci_Generator — Ada 2023 educational package for the
--  lagged Fibonacci generator (LFG / LFib)
--
--      X_n = (X_{n-j} ★ X_{n-k}) mod m ,   0 < j < k
--
--  Binary operation ★ ∈ {+, −, xor}. Ring buffer of length k. Seed from
--  an array of k words or from a single seed via an LCG fill. Create /
--  Reset / Next / Next_Float (the last in [0, 1)). Common lag pairs as
--  constants (24,55), … . Max_Lag = 1024. Invalid_Argument for bad
--  lags / seed length / modulus.
--  Reference: https://en.wikipedia.org/wiki/Lagged_Fibonacci_generator
--  Sibling sheets (README only — do not `with`): Linear congruential
--  generator, Blum Blum Shub —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Lagged_Fibonacci_Generator
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Word type and lag bounds
   ---------------------------------------------------------------------------

   --  All LFG integers (state words, modulus M, seeds) are nonnegative
   --  by construction. M = 0 is rejected (not a working modulus).
   type Value is mod 2 ** 64;

   --  Maximum lag k. Common published pairs that fit: (24,55), (38,89),
   --  (37,100), (30,127), (83,258), (107,378), (273,607). Larger Knuth
   --  pairs such as (1029,2281) exceed this classroom cap.
   Max_Lag : constant Positive := 1024;
   subtype Lag_Index is Positive range 1 .. Max_Lag;

   ---------------------------------------------------------------------------
   -- Binary operation ★
   ---------------------------------------------------------------------------

   --  Add          — Additive LFG (ALFG):   (X_{n-j} + X_{n-k}) mod M
   --  Subtract     — Subtractive LFG:       (X_{n-j} − X_{n-k}) mod M
   --  Bitwise_Xor  — Two-tap GFSR:          (X_{n-j} xor X_{n-k}) mod M
   --  (Ada reserves the keyword "xor", so the enumeration uses Bitwise_Xor.)
   type Binary_Op is (Add, Subtract, Bitwise_Xor);

   ---------------------------------------------------------------------------
   -- Seed array and lag-pair record
   ---------------------------------------------------------------------------

   type Seed_Array is array (Positive range <>) of Value;

   --  Published (j, k) with 0 < j < k ≤ Max_Lag. For maximum period the
   --  trinomial x^k + x^j + 1 should be primitive over GF(2); the pairs
   --  below are classical choices from Knuth / the literature.
   type Lag_Pair is record
      J : Lag_Index := 1;
      K : Lag_Index := 2;
   end record;

   Lag_24_55   : constant Lag_Pair := (J => 24,  K => 55);
   Lag_38_89   : constant Lag_Pair := (J => 38,  K => 89);
   Lag_37_100  : constant Lag_Pair := (J => 37,  K => 100);
   Lag_30_127  : constant Lag_Pair := (J => 30,  K => 127);
   Lag_83_258  : constant Lag_Pair := (J => 83,  K => 258);
   Lag_107_378 : constant Lag_Pair := (J => 107, K => 378);
   Lag_273_607 : constant Lag_Pair := (J => 273, K => 607);

   --  Default classroom modulus (power of two, as usual for LFGs).
   Default_Modulus : constant Value := 2 ** 32;

   type Generator is private;
   --  Holds (J, K, Op, M), a ring buffer of length K, a write cursor,
   --  and the last Create / Reset seed material. Default (uninitialised)
   --  generators have K = 0 and are rejected by Next / Reset / Next_Float.

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when J ≥ K, when K > Max_Lag (impossible via Lag_Index),
   --  when M < 2, when a seed array length ≠ K, when a seed word is
   --  ≥ M, when an uninitialised generator is used, or when a modular
   --  helper is called with modulus 0.

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Lags (J, K : Positive) return Boolean
     with Global => null;
   --  True iff 1 ≤ J < K ≤ Max_Lag.

   function Is_Valid_Lags (Lags : Lag_Pair) return Boolean
     with Global => null;

   function Is_Valid_Modulus (M : Value) return Boolean
     with Global => null;
   --  True iff M ≥ 2.

   ---------------------------------------------------------------------------
   -- Create / Reset / Next / Next_Float
   ---------------------------------------------------------------------------

   --  Algorithm sketch:
   --    Store J, K, Op, M and a ring buffer B[0 .. K−1] = X_0 .. X_{K−1}.
   --    Cursor C points at the slot holding X_{n−K} (about to be overwritten).
   --    Each Next computes
   --        X_n = (B[(C − J) mod K] ★ B[C]) mod M
   --    writes it back at C, advances C, and returns X_n.
   --    Next_Float returns X_n / M ∈ [0, 1).
   --    A single Seed fills the buffer with an LCG (Numerical Recipes
   --    parameters, reduced modulo M), forcing at least one odd word
   --    for Add / Subtract (period requirement).

   function Create
     (J     : Lag_Index;
      K     : Lag_Index;
      Op    : Binary_Op;
      M     : Value;
      Seeds : Seed_Array) return Generator
     with Global => null;
   --  New generator. Seeds'Length must equal K; each Seeds(I) < M.
   --  Raises Invalid_Argument when lags, modulus, or seed array is bad.

   function Create
     (J    : Lag_Index;
      K    : Lag_Index;
      Op   : Binary_Op;
      M    : Value;
      Seed : Value) return Generator
     with Global => null;
   --  New generator; buffer filled from Seed via LCG. Seed must be < M.
   --  Raises Invalid_Argument when lags / modulus / seed is bad.

   function Create
     (Lags  : Lag_Pair;
      Op    : Binary_Op;
      M     : Value;
      Seeds : Seed_Array) return Generator
     with Global => null;

   function Create
     (Lags : Lag_Pair;
      Op   : Binary_Op;
      M    : Value;
      Seed : Value) return Generator
     with Global => null;

   procedure Reset (G : in out Generator; Seeds : Seed_Array)
     with Global => null;
   --  Reinstall seed array (parameters unchanged). Length must equal K;
   --  each word < M. Raises Invalid_Argument on bad seeds or uninit G.

   procedure Reset (G : in out Generator; Seed : Value)
     with Global => null;
   --  Refill buffer from Seed via LCG. Seed must be < M.
   --  Raises Invalid_Argument on bad seed or uninit G.

   function Next (G : in out Generator) return Value
     with Global => null;
   --  Advance: compute X_n, store it, return it.
   --  Raises Invalid_Argument when G is uninitialised.

   function Next_Float (G : in out Generator) return Long_Float
     with Global => null;
   --  Advance as Next and return X_n / M as a Long_Float in [0, 1).
   --  Raises Invalid_Argument when G is uninitialised.

   ---------------------------------------------------------------------------
   -- Inspectors
   ---------------------------------------------------------------------------

   function Get_J (G : Generator) return Lag_Index
     with Global => null;

   function Get_K (G : Generator) return Lag_Index
     with Global => null;

   function Get_Op (G : Generator) return Binary_Op
     with Global => null;

   function Get_Modulus (G : Generator) return Value
     with Global => null;

   function Get_Cursor (G : Generator) return Natural
     with Global => null;
   --  0-based write cursor into the ring buffer (0 .. K−1).

   function Get_Buffer_Word (G : Generator; Index : Lag_Index) return Value
     with Global => null;
   --  Buffer word at 1-based Index (1 .. K). Raises Invalid_Argument
   --  when Index > K or G is uninitialised.

   function Is_Initialised (G : Generator) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Overflow-safe modular helpers (educational)
   ---------------------------------------------------------------------------

   function Add_Mod (X, Y, M : Value) return Value
     with Global => null;
   --  (X + Y) mod M. Raises Invalid_Argument when M = 0.

   function Sub_Mod (X, Y, M : Value) return Value
     with Global => null;
   --  (X − Y) mod M. Raises Invalid_Argument when M = 0.

   function Xor_Mod (X, Y, M : Value) return Value
     with Global => null;
   --  (X xor Y) mod M. Raises Invalid_Argument when M = 0.

   function Combine (X, Y : Value; Op : Binary_Op; M : Value) return Value
     with Global => null;
   --  Apply Op then reduce modulo M. Raises Invalid_Argument when M = 0.

private

   type Buffer_Array is array (Lag_Index) of Value;

   type Generator is record
      J          : Lag_Index := 1;
      K          : Lag_Index := 1;
      Op         : Binary_Op := Add;
      M          : Value     := 0;
      Buffer     : Buffer_Array := [others => 0];
      Cursor     : Natural   := 0;  -- 0-based index into Buffer (1 .. K)
      Initialised : Boolean  := False;
   end record;

end Lagged_Fibonacci_Generator;
