--  Blum_Blum_Shub — Ada/SPARK Level 4 educational package for the
--  Blum–Blum–Shub (BBS) pseudorandom bit generator:
--
--      choose distinct Blum primes p, q ≡ 3 (mod 4);
--      M = p · q;  seed x₀ coprime to M;
--      x_{n+1} = x_n² mod M;  output LSB (or low bits) of x_n.
--
--  Create / Initialize / Reset / Next_Bit / Next_Byte / Next_Bits.
--  Educational small Blum-prime table. Overflow-safe Mul_Mod /
--  Square_Mod for M ≤ 2**32 (product fits in a single mod-2**64 word).
--
--  SPARK port of Ada-Blum-Blum-Shub: hard bounds, no heap, no
--  exceptions, no Unsigned_128 — contracts replace Invalid_Parameters /
--  Invalid_Seed. Primes capped so M = p·q ≤ Max_Modulus.
--
--  Reference: https://en.wikipedia.org/wiki/Blum_Blum_Shub

package Blum_Blum_Shub
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Word type and prime / modulus bounds
   ---------------------------------------------------------------------------

   type Value is mod 2 ** 64;

   --  Cap each Blum prime at 2**16 so M = p·q ≤ 2**32 = Max_Modulus.
   --  Then (M−1)² fits in Value without wrap, keeping Square_Mod /
   --  Mul_Mod proveable at Level 4 (same technique as the LCG sibling).
   Max_Prime       : constant Value := 2 ** 16;
   Max_Modulus     : constant Value := 2 ** 32;
   Default_Modulus : constant Value := Max_Modulus;
   subtype Modulus_Type is Value range 2 .. Max_Modulus;
   subtype Bit_Count is Positive range 1 .. 64;

   type Generator is private;

   ---------------------------------------------------------------------------
   -- Educational small Blum primes (p ≡ 3 (mod 4)) within Max_Prime
   ---------------------------------------------------------------------------

   Blum_7   : constant Value := 7;
   Blum_11  : constant Value := 11;
   Blum_19  : constant Value := 19;
   Blum_23  : constant Value := 23;
   Blum_43  : constant Value := 43;
   Blum_47  : constant Value := 47;
   Blum_59  : constant Value := 59;
   Blum_67  : constant Value := 67;
   Blum_71  : constant Value := 71;
   Blum_79  : constant Value := 79;
   Blum_83  : constant Value := 83;
   Blum_103 : constant Value := 103;
   Blum_107 : constant Value := 107;
   Blum_127 : constant Value := 127;
   Blum_131 : constant Value := 131;
   Blum_139 : constant Value := 139;
   Blum_151 : constant Value := 151;
   Blum_163 : constant Value := 163;
   Blum_167 : constant Value := 167;
   Blum_179 : constant Value := 179;
   Blum_191 : constant Value := 191;
   Blum_199 : constant Value := 199;
   Blum_211 : constant Value := 211;
   Blum_223 : constant Value := 223;
   Blum_227 : constant Value := 227;
   Blum_239 : constant Value := 239;
   Blum_251 : constant Value := 251;
   Blum_499 : constant Value := 499;
   Blum_547 : constant Value := 547;

   type Blum_Prime_List is array (Positive range <>) of Value;

   Small_Blum_Primes : constant Blum_Prime_List :=
     [7, 11, 19, 23, 43, 47, 59, 67, 71, 79, 83, 103,
      107, 127, 131, 139, 151, 163, 167, 179, 191, 199,
      211, 223, 227, 239, 251, 499, 547];

   ---------------------------------------------------------------------------
   -- Primality / Blum / GCD helpers
   ---------------------------------------------------------------------------

   --  Trial division up to sqrt(N) with N ≤ Max_Prime (bounded for-loop).
   --  Returns False for N < 2 or N > Max_Prime.
   function Is_Prime (N : Value) return Boolean
     with Global => null;

   --  Blum prime: prime and N ≡ 3 (mod 4). False outside Max_Prime.
   function Is_Blum_Prime (N : Value) return Boolean
     with
       Global => null,
       Post   => Is_Blum_Prime'Result =
         (Is_Prime (N) and then N rem 4 = 3);

   function Gcd (X, Y : Value) return Value
     with Global => null;

   function Are_Coprime (X, Y : Value) return Boolean
     with
       Global => null,
       Post   => Are_Coprime'Result = (Gcd (X, Y) = 1);

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Modulus (M : Value) return Boolean
     with
       Global => null,
       Post   => Is_Valid_Modulus'Result = (M in Modulus_Type);

   --  Distinct Blum primes within Max_Prime whose product fits Max_Modulus.
   function Is_Valid_Blum_Pair (P, Q : Value) return Boolean
     with
       Global => null,
       Post   => Is_Valid_Blum_Pair'Result =
         (P <= Max_Prime
          and then Q <= Max_Prime
          and then P /= Q
          and then Is_Blum_Prime (P)
          and then Is_Blum_Prime (Q)
          and then P * Q in Modulus_Type);

   function Is_Valid_Seed (Seed, M : Value) return Boolean
     with
       Global => null,
       Pre    => M in Modulus_Type,
       Post   => Is_Valid_Seed'Result =
         (Seed > 1 and then Seed < M and then Are_Coprime (Seed, M));

   function Is_Initialised (G : Generator) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Create / Initialize / Reset
   ---------------------------------------------------------------------------

   --  Initial state is Seed² mod M (matches non-SPARK sibling).
   function Create (P, Q, Seed : Value) return Generator
     with
       Global => null,
       Pre    => Is_Valid_Blum_Pair (P, Q)
                 and then Is_Valid_Seed (Seed, P * Q),
       Post   => Is_Initialised (Create'Result)
                 and then Get_P (Create'Result) = P
                 and then Get_Q (Create'Result) = Q
                 and then Get_M (Create'Result) = P * Q
                 and then Get_Seed (Create'Result) = Seed
                 and then Peek_State (Create'Result) < P * Q;

   procedure Initialize
     (Gen  : out Generator;
      P    : Value;
      Q    : Value;
      Seed : Value)
     with
       Global  => null,
       Depends => (Gen => (P, Q, Seed)),
       Pre     => Is_Valid_Blum_Pair (P, Q)
                  and then Is_Valid_Seed (Seed, P * Q),
       Post    => Is_Initialised (Gen)
                  and then Get_P (Gen) = P
                  and then Get_Q (Gen) = Q
                  and then Get_M (Gen) = P * Q
                  and then Get_Seed (Gen) = Seed
                  and then Peek_State (Gen) < P * Q;

   procedure Reset (G : in out Generator; Seed : Value)
     with
       Global  => null,
       Depends => (G => (G, Seed)),
       Pre     => Is_Initialised (G)
                  and then Is_Valid_Seed (Seed, Get_M (G)),
       Post    => Is_Initialised (G)
                  and then Get_P (G) = Get_P (G'Old)
                  and then Get_Q (G) = Get_Q (G'Old)
                  and then Get_M (G) = Get_M (G'Old)
                  and then Get_Seed (G) = Seed
                  and then Peek_State (G) < Get_M (G);

   ---------------------------------------------------------------------------
   -- Next_Bit / Next_Byte / Next_Bits / Peek
   ---------------------------------------------------------------------------

   --  Advance: State ← State² mod M; Result ← LSB of new State.
   procedure Next_Bit (G : in out Generator; Result : out Boolean)
     with
       Global  => null,
       Depends => (G => G, Result => G),
       Pre     => Is_Initialised (G),
       Post    => Is_Initialised (G)
                  and then Get_P (G) = Get_P (G'Old)
                  and then Get_Q (G) = Get_Q (G'Old)
                  and then Get_M (G) = Get_M (G'Old)
                  and then Get_Seed (G) = Get_Seed (G'Old)
                  and then Peek_State (G) < Get_M (G)
                  and then Result = (Peek_State (G) rem 2 /= 0);

   --  Eight successive bits packed MSB-first into Result ∈ 0 .. 255.
   procedure Next_Byte (G : in out Generator; Result : out Value)
     with
       Global  => null,
       Depends => (G => G, Result => G),
       Pre     => Is_Initialised (G),
       Post    => Is_Initialised (G)
                  and then Get_P (G) = Get_P (G'Old)
                  and then Get_Q (G) = Get_Q (G'Old)
                  and then Get_M (G) = Get_M (G'Old)
                  and then Get_Seed (G) = Get_Seed (G'Old)
                  and then Peek_State (G) < Get_M (G)
                  and then Result <= 255;

   --  Count successive bits packed MSB-first into Result (Count ≤ 64).
   procedure Next_Bits
     (G      : in out Generator;
      Count  : Bit_Count;
      Result : out Value)
     with
       Global  => null,
       Depends => (G => (G, Count), Result => (G, Count)),
       Pre     => Is_Initialised (G),
       Post    => Is_Initialised (G)
                  and then Get_P (G) = Get_P (G'Old)
                  and then Get_Q (G) = Get_Q (G'Old)
                  and then Get_M (G) = Get_M (G'Old)
                  and then Get_Seed (G) = Get_Seed (G'Old)
                  and then Peek_State (G) < Get_M (G);

   function Peek_State (G : Generator) return Value
     with
       Global => null,
       Pre    => Is_Initialised (G),
       Post   => Peek_State'Result < Get_M (G);

   ---------------------------------------------------------------------------
   -- Inspectors
   ---------------------------------------------------------------------------

   function Get_P (G : Generator) return Value
     with
       Global => null,
       Pre    => Is_Initialised (G),
       Post   => Get_P'Result <= Max_Prime
                 and then Is_Blum_Prime (Get_P'Result);

   function Get_Q (G : Generator) return Value
     with
       Global => null,
       Pre    => Is_Initialised (G),
       Post   => Get_Q'Result <= Max_Prime
                 and then Is_Blum_Prime (Get_Q'Result)
                 and then Get_Q'Result /= Get_P (G);

   function Get_M (G : Generator) return Modulus_Type
     with
       Global => null,
       Pre    => Is_Initialised (G),
       Post   => Get_M'Result = Get_P (G) * Get_Q (G);

   function Get_Seed (G : Generator) return Value
     with
       Global => null,
       Pre    => Is_Initialised (G),
       Post   => Get_Seed'Result > 1
                 and then Get_Seed'Result < Get_M (G);

   ---------------------------------------------------------------------------
   -- Overflow-safe modular arithmetic (M ≤ 2**32)
   ---------------------------------------------------------------------------

   function Mul_Mod (X, Y : Value; M : Modulus_Type) return Value
     with
       Global => null,
       Pre    => X < M and then Y < M,
       Post   => Mul_Mod'Result < M;

   function Square_Mod (X : Value; M : Modulus_Type) return Value
     with
       Global => null,
       Pre    => X < M,
       Post   => Square_Mod'Result < M;

private

   type Generator is record
      P           : Value   := 0;
      Q           : Value   := 0;
      M           : Value   := 0;
      State       : Value   := 0;
      Seed        : Value   := 0;
      Initialised : Boolean := False;
   end record
     with Type_Invariant =>
       (if Initialised then
          P <= Max_Prime
          and then Q <= Max_Prime
          and then P /= Q
          and then Is_Blum_Prime (P)
          and then Is_Blum_Prime (Q)
          and then M = P * Q
          and then M in Modulus_Type
          and then State < M
          and then Seed > 1
          and then Seed < M);

   function Is_Initialised (G : Generator) return Boolean is (G.Initialised);

   function Get_P (G : Generator) return Value is (G.P);

   function Get_Q (G : Generator) return Value is (G.Q);

   function Get_M (G : Generator) return Modulus_Type is (Modulus_Type (G.M));

   function Get_Seed (G : Generator) return Value is (G.Seed);

   function Peek_State (G : Generator) return Value is (G.State);

end Blum_Blum_Shub;
