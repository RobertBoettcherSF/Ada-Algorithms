--  Lagged_Fibonacci_Generator — Ada/SPARK Level 4 educational package
--  for the lagged Fibonacci generator (LFG / LFib):
--
--      X_n = (X_{n-j} ★ X_{n-k}) mod m ,   0 < j < k
--
--  Binary operation ★ ∈ {+, −, xor}. Ring buffer of length k. Seed from
--  a length-k prefix of Seed_Array or a single seed via an LCG fill.
--
--  SPARK port of Ada-Lagged-Fibonacci-Generator: hard bounds, no heap,
--  no exceptions, no Long_Float / Unsigned_128 — contracts replace
--  Invalid_Argument. Max_Lag capped at 128 so common pairs (24,55),
--  (38,89), (37,100), (30,127) fit; larger pairs dropped. Modulus
--  capped at 2**32 so modular arithmetic stays wrap-free.
--
--  Reference: https://en.wikipedia.org/wiki/Lagged_Fibonacci_generator

package Lagged_Fibonacci_Generator
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Word type and lag / modulus bounds
   ---------------------------------------------------------------------------

   type Value is mod 2 ** 64;

   --  Maximum lag k. Common published pairs that fit: (24,55), (38,89),
   --  (37,100), (30,127). Larger pairs (83,258), (107,378), (273,607)
   --  exceed this SPARK classroom cap (non-SPARK sibling uses 1024).
   Max_Lag : constant Positive := 128;
   subtype Lag_Index is Positive range 1 .. Max_Lag;

   --  Cap at 2**32 so (M-1)+(M-1) and LCG_A*State+LCG_C fit in Value
   --  without modular wrap, keeping Add_Mod / LCG proveable at Level 4.
   Max_Modulus     : constant Value := 2 ** 32;
   Default_Modulus : constant Value := Max_Modulus;
   subtype Modulus_Type is Value range 2 .. Max_Modulus;

   ---------------------------------------------------------------------------
   -- Binary operation ★
   ---------------------------------------------------------------------------

   --  Add          — Additive LFG (ALFG):   (X_{n-j} + X_{n-k}) mod M
   --  Subtract     — Subtractive LFG:       (X_{n-j} − X_{n-k}) mod M
   --  Bitwise_Xor  — Two-tap GFSR:          (X_{n-j} xor X_{n-k}) mod M
   --  (Ada reserves the keyword "xor", so the enumeration uses Bitwise_Xor.)
   type Binary_Op is (Add, Subtract, Bitwise_Xor);

   ---------------------------------------------------------------------------
   -- Seed / buffer arrays (fixed; used prefix is 1 .. K)
   ---------------------------------------------------------------------------

   type Seed_Array is array (Lag_Index) of Value;

   --  Published (j, k) with 0 < j < k ≤ Max_Lag. For maximum period the
   --  trinomial x^k + x^j + 1 should be primitive over GF(2); the pairs
   --  below are classical choices from Knuth / the literature that fit
   --  Max_Lag = 128.
   type Lag_Pair is record
      J : Lag_Index := 1;
      K : Lag_Index := 2;
   end record;

   Lag_24_55  : constant Lag_Pair := (J => 24, K => 55);
   Lag_38_89  : constant Lag_Pair := (J => 38, K => 89);
   Lag_37_100 : constant Lag_Pair := (J => 37, K => 100);
   Lag_30_127 : constant Lag_Pair := (J => 30, K => 127);

   type Generator is private;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Lags (J, K : Positive) return Boolean
     with
       Global => null,
       Post   => Is_Valid_Lags'Result =
         (J < K and then K <= Max_Lag);

   function Is_Valid_Lags (Lags : Lag_Pair) return Boolean
     with
       Global => null,
       Post   => Is_Valid_Lags'Result =
         (Lags.J < Lags.K);

   function Is_Valid_Modulus (M : Value) return Boolean
     with
       Global => null,
       Post   => Is_Valid_Modulus'Result = (M in Modulus_Type);

   function Seeds_In_Range
     (K     : Lag_Index;
      M     : Modulus_Type;
      Seeds : Seed_Array) return Boolean
     with
       Global => null,
       Post   => Seeds_In_Range'Result =
         (for all I in 1 .. K => Seeds (I) < M);

   function Is_Initialised (G : Generator) return Boolean
     with Global => null;

   function Get_J (G : Generator) return Lag_Index
     with
       Global => null,
       Pre    => Is_Initialised (G);

   function Get_K (G : Generator) return Lag_Index
     with
       Global => null,
       Pre    => Is_Initialised (G),
       Post   => Get_K'Result > Get_J (G);

   function Get_Op (G : Generator) return Binary_Op
     with
       Global => null,
       Pre    => Is_Initialised (G);

   function Get_Modulus (G : Generator) return Modulus_Type
     with
       Global => null,
       Pre    => Is_Initialised (G);

   function Get_Cursor (G : Generator) return Natural
     with
       Global => null,
       Pre    => Is_Initialised (G),
       Post   => Get_Cursor'Result < Natural (Get_K (G));

   function Get_Buffer_Word (G : Generator; Index : Lag_Index) return Value
     with
       Global => null,
       Pre    => Is_Initialised (G) and then Index <= Get_K (G),
       Post   => Get_Buffer_Word'Result < Get_Modulus (G);

   ---------------------------------------------------------------------------
   -- Create / Reset / Next
   ---------------------------------------------------------------------------

   function Create
     (J     : Lag_Index;
      K     : Lag_Index;
      Op    : Binary_Op;
      M     : Modulus_Type;
      Seeds : Seed_Array) return Generator
     with
       Global => null,
       Pre    => J < K and then Seeds_In_Range (K, M, Seeds),
       Post   => Is_Initialised (Create'Result)
                 and then Get_J (Create'Result) = J
                 and then Get_K (Create'Result) = K
                 and then Get_Op (Create'Result) = Op
                 and then Get_Modulus (Create'Result) = M
                 and then Get_Cursor (Create'Result) = 0
                 and then
                   (for all I in 1 .. K =>
                      Get_Buffer_Word (Create'Result, I) = Seeds (I));

   function Create
     (J    : Lag_Index;
      K    : Lag_Index;
      Op   : Binary_Op;
      M    : Modulus_Type;
      Seed : Value) return Generator
     with
       Global => null,
       Pre    => J < K and then Seed < M,
       Post   => Is_Initialised (Create'Result)
                 and then Get_J (Create'Result) = J
                 and then Get_K (Create'Result) = K
                 and then Get_Op (Create'Result) = Op
                 and then Get_Modulus (Create'Result) = M
                 and then Get_Cursor (Create'Result) = 0
                 and then
                   (for all I in 1 .. K =>
                      Get_Buffer_Word (Create'Result, I) < M);

   function Create
     (Lags  : Lag_Pair;
      Op    : Binary_Op;
      M     : Modulus_Type;
      Seeds : Seed_Array) return Generator
     with
       Global => null,
       Pre    => Is_Valid_Lags (Lags)
                 and then Seeds_In_Range (Lags.K, M, Seeds),
       Post   => Is_Initialised (Create'Result)
                 and then Get_J (Create'Result) = Lags.J
                 and then Get_K (Create'Result) = Lags.K
                 and then Get_Op (Create'Result) = Op
                 and then Get_Modulus (Create'Result) = M
                 and then Get_Cursor (Create'Result) = 0;

   function Create
     (Lags : Lag_Pair;
      Op   : Binary_Op;
      M    : Modulus_Type;
      Seed : Value) return Generator
     with
       Global => null,
       Pre    => Is_Valid_Lags (Lags) and then Seed < M,
       Post   => Is_Initialised (Create'Result)
                 and then Get_J (Create'Result) = Lags.J
                 and then Get_K (Create'Result) = Lags.K
                 and then Get_Op (Create'Result) = Op
                 and then Get_Modulus (Create'Result) = M
                 and then Get_Cursor (Create'Result) = 0;

   procedure Reset (G : in out Generator; Seeds : Seed_Array)
     with
       Global  => null,
       Depends => (G => (G, Seeds)),
       Pre     => Is_Initialised (G)
                  and then Seeds_In_Range (Get_K (G), Get_Modulus (G), Seeds),
       Post    => Is_Initialised (G)
                  and then Get_J (G) = Get_J (G'Old)
                  and then Get_K (G) = Get_K (G'Old)
                  and then Get_Op (G) = Get_Op (G'Old)
                  and then Get_Modulus (G) = Get_Modulus (G'Old)
                  and then Get_Cursor (G) = 0
                  and then
                    (for all I in 1 .. Get_K (G) =>
                       Get_Buffer_Word (G, I) = Seeds (I));

   procedure Reset (G : in out Generator; Seed : Value)
     with
       Global  => null,
       Depends => (G => (G, Seed)),
       Pre     => Is_Initialised (G) and then Seed < Get_Modulus (G),
       Post    => Is_Initialised (G)
                  and then Get_J (G) = Get_J (G'Old)
                  and then Get_K (G) = Get_K (G'Old)
                  and then Get_Op (G) = Get_Op (G'Old)
                  and then Get_Modulus (G) = Get_Modulus (G'Old)
                  and then Get_Cursor (G) = 0
                  and then
                    (for all I in 1 .. Get_K (G) =>
                       Get_Buffer_Word (G, I) < Get_Modulus (G));

   procedure Next (G : in out Generator; Result : out Value)
     with
       Global  => null,
       Depends => (G => G, Result => G),
       Pre     => Is_Initialised (G),
       Post    => Is_Initialised (G)
                  and then Get_J (G) = Get_J (G'Old)
                  and then Get_K (G) = Get_K (G'Old)
                  and then Get_Op (G) = Get_Op (G'Old)
                  and then Get_Modulus (G) = Get_Modulus (G'Old)
                  and then Result < Get_Modulus (G)
                  and then Get_Cursor (G) =
                    (Get_Cursor (G'Old) + 1) rem Natural (Get_K (G));

   ---------------------------------------------------------------------------
   -- Overflow-safe modular helpers
   ---------------------------------------------------------------------------

   function Add_Mod (X, Y : Value; M : Modulus_Type) return Value
     with
       Global => null,
       Pre    => X < M and then Y < M,
       Post   => Add_Mod'Result < M
                 and then Add_Mod'Result =
                   (if X + Y >= M then X + Y - M else X + Y);

   function Sub_Mod (X, Y : Value; M : Modulus_Type) return Value
     with
       Global => null,
       Pre    => X < M and then Y < M,
       Post   => Sub_Mod'Result < M
                 and then Sub_Mod'Result =
                   (if X >= Y then X - Y else M - (Y - X));

   function Xor_Mod (X, Y : Value; M : Modulus_Type) return Value
     with
       Global => null,
       Pre    => X < M and then Y < M,
       Post   => Xor_Mod'Result < M
                 and then Xor_Mod'Result = (X xor Y) rem M;

   function Combine
     (X, Y : Value; Op : Binary_Op; M : Modulus_Type) return Value
     with
       Global => null,
       Pre    => X < M and then Y < M,
       Post   => Combine'Result < M
                 and then Combine'Result =
                   (case Op is
                      when Add         => Add_Mod (X, Y, M),
                      when Subtract    => Sub_Mod (X, Y, M),
                      when Bitwise_Xor => Xor_Mod (X, Y, M));

private

   type Generator is record
      J           : Lag_Index  := 1;
      K           : Lag_Index  := 1;
      Op          : Binary_Op  := Add;
      M           : Value      := 0;
      Buffer      : Seed_Array := [others => 0];
      Cursor      : Natural    := 0;
      Initialised : Boolean    := False;
   end record
     with Type_Invariant =>
       (if Initialised then
          J < K
          and then M in Modulus_Type
          and then Cursor < Natural (K)
          and then (for all I in 1 .. K => Buffer (I) < M));

   function Is_Initialised (G : Generator) return Boolean is (G.Initialised);

   function Get_J (G : Generator) return Lag_Index is (G.J);

   function Get_K (G : Generator) return Lag_Index is (G.K);

   function Get_Op (G : Generator) return Binary_Op is (G.Op);

   function Get_Modulus (G : Generator) return Modulus_Type is
     (Modulus_Type (G.M));

   function Get_Cursor (G : Generator) return Natural is (G.Cursor);

   function Get_Buffer_Word (G : Generator; Index : Lag_Index) return Value is
     (G.Buffer (Index));

end Lagged_Fibonacci_Generator;
