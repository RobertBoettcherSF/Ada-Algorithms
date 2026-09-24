--  Linear_Congruential_Generator — Ada/SPARK Level 4 educational
--  package for the classical linear congruential generator (LCG):
--
--      X_{n+1} = (a * X_n + c) mod m
--
--  Create / Reset / Next / Step with well-known parameter sets
--  (Numerical Recipes, glibc, Borland, Park–Miller, …). Hull–Dobell
--  full-period helpers. Overflow-safe Add_Mod / Mul_Mod for
--  M ≤ 2**32 (product fits in a single mod-2**64 word).
--
--  SPARK port of Ada-Linear-Congruential-Generator: hard bounds, no
--  heap, no exceptions, no Long_Float / Unsigned_128 — contracts
--  replace Invalid_Argument. Modulus capped at 2**32 so modular
--  multiply stays proveable at Level 4 (Java’s 2**48 set omitted).
--
--  Reference: https://en.wikipedia.org/wiki/Linear_congruential_generator

package Linear_Congruential_Generator
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Word type and modulus bound
   ---------------------------------------------------------------------------

   type Value is mod 2 ** 64;

   --  Cap at 2**32 so (M−1)·(M−1)+(M−1) fits in Value without wrap,
   --  keeping Congruential / Mul_Mod proveable at Level 4.
   Max_Modulus     : constant Value := 2 ** 32;
   Default_Modulus : constant Value := Max_Modulus;
   subtype Modulus_Type is Value range 2 .. Max_Modulus;

   ---------------------------------------------------------------------------
   -- Parameters (A, C, M) and generator
   ---------------------------------------------------------------------------

   --  Multiplier A, increment C, modulus M of
   --  X_{n+1} = (A * X_n + C) mod M.
   --  Valid parameters satisfy M ∈ Modulus_Type and A rem M ≠ 0.
   --  Published multipliers may exceed M (e.g. Visual Basic); they
   --  are reduced modulo M on Create. C is reduced modulo M. When
   --  C ≡ 0 (mod M) the generator is a multiplicative congruential
   --  generator (MCG / Lehmer RNG).
   type Parameters is record
      A : Value := 0;
      C : Value := 0;
      M : Value := 0;
   end record;

   type Generator is private;

   ---------------------------------------------------------------------------
   -- Well-known parameter sets (popularity, not endorsement)
   -- Values follow the Wikipedia “Parameters in common use” table.
   -- Sets with M > Max_Modulus (e.g. Java 2**48) are omitted.
   ---------------------------------------------------------------------------

   Numerical_Recipes : constant Parameters :=
     (A => 1_664_525, C => 1_013_904_223, M => 2 ** 32);

   Glibc : constant Parameters :=
     (A => 1_103_515_245, C => 12_345, M => 2 ** 31);

   ANSI_C : constant Parameters :=
     (A => 1_103_515_245, C => 12_345, M => 2 ** 31);

   Borland_C : constant Parameters :=
     (A => 22_695_477, C => 1, M => 2 ** 32);

   Borland_Delphi : constant Parameters :=
     (A => 134_775_813, C => 1, M => 2 ** 32);

   Microsoft_Visual_C : constant Parameters :=
     (A => 214_013, C => 2_531_011, M => 2 ** 32);

   --  Published A exceeds M; Create / Reduce take A rem M.
   Microsoft_Visual_Basic : constant Parameters :=
     (A => 1_140_671_485, C => 12_820_163, M => 2 ** 24);

   Park_Miller : constant Parameters :=
     (A => 16_807, C => 0, M => 2 ** 31 - 1);

   MINSTD_Rand : constant Parameters :=
     (A => 48_271, C => 0, M => 2 ** 31 - 1);

   RANDU : constant Parameters :=
     (A => 65_539, C => 0, M => 2 ** 31);

   VMS_MTH_Random : constant Parameters :=
     (A => 69_069, C => 1, M => 2 ** 32);

   ZX81 : constant Parameters :=
     (A => 75, C => 74, M => 65_537);

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Parameters (Params : Parameters) return Boolean
     with
       Global => null,
       Post   => Is_Valid_Parameters'Result =
         (Params.M in Modulus_Type and then Params.A rem Params.M /= 0);

   function Is_Valid_Modulus (M : Value) return Boolean
     with
       Global => null,
       Post   => Is_Valid_Modulus'Result = (M in Modulus_Type);

   function Reduce (Params : Parameters) return Parameters
     with
       Global => null,
       Pre    => Is_Valid_Parameters (Params),
       Post   => Reduce'Result.M = Params.M
                 and then Reduce'Result.A = Params.A rem Params.M
                 and then Reduce'Result.C = Params.C rem Params.M
                 and then Reduce'Result.A < Params.M
                 and then Reduce'Result.C < Params.M
                 and then Reduce'Result.A /= 0
                 and then Is_Valid_Parameters (Reduce'Result);

   function Is_Initialised (G : Generator) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Create / Reset / Step / Next
   ---------------------------------------------------------------------------

   function Create (Params : Parameters; Seed : Value) return Generator
     with
       Global => null,
       Pre    => Is_Valid_Parameters (Params) and then Seed < Params.M,
       Post   => Is_Initialised (Create'Result)
                 and then Get_M (Create'Result) = Params.M
                 and then Get_A (Create'Result) = Params.A rem Params.M
                 and then Get_C (Create'Result) = Params.C rem Params.M
                 and then Get_State (Create'Result) = Seed
                 and then Get_Seed (Create'Result) = Seed;

   procedure Reset (G : in out Generator; Seed : Value)
     with
       Global  => null,
       Depends => (G => (G, Seed)),
       Pre     => Is_Initialised (G) and then Seed < Get_M (G),
       Post    => Is_Initialised (G)
                  and then Get_M (G) = Get_M (G'Old)
                  and then Get_A (G) = Get_A (G'Old)
                  and then Get_C (G) = Get_C (G'Old)
                  and then Get_State (G) = Seed
                  and then Get_Seed (G) = Seed;

   function Step (State : Value; Params : Parameters) return Value
     with
       Global => null,
       Pre    => Is_Valid_Parameters (Params) and then State < Params.M,
       Post   => Step'Result < Params.M;

   procedure Next (G : in out Generator; Result : out Value)
     with
       Global  => null,
       Depends => (G => G, Result => G),
       Pre     => Is_Initialised (G),
       Post    => Is_Initialised (G)
                  and then Get_M (G) = Get_M (G'Old)
                  and then Get_A (G) = Get_A (G'Old)
                  and then Get_C (G) = Get_C (G'Old)
                  and then Get_Seed (G) = Get_Seed (G'Old)
                  and then Result < Get_M (G)
                  and then Get_State (G) = Result;

   ---------------------------------------------------------------------------
   -- Inspectors
   ---------------------------------------------------------------------------

   function Get_Parameters (G : Generator) return Parameters
     with
       Global => null,
       Pre    => Is_Initialised (G),
       Post   => Get_Parameters'Result.A = Get_A (G)
                 and then Get_Parameters'Result.C = Get_C (G)
                 and then Get_Parameters'Result.M = Get_M (G)
                 and then Is_Valid_Parameters (Get_Parameters'Result);

   function Get_A (G : Generator) return Value
     with
       Global => null,
       Pre    => Is_Initialised (G),
       Post   => Get_A'Result < Get_M (G) and then Get_A'Result /= 0;

   function Get_C (G : Generator) return Value
     with
       Global => null,
       Pre    => Is_Initialised (G),
       Post   => Get_C'Result < Get_M (G);

   function Get_M (G : Generator) return Modulus_Type
     with
       Global => null,
       Pre    => Is_Initialised (G);

   function Get_State (G : Generator) return Value
     with
       Global => null,
       Pre    => Is_Initialised (G),
       Post   => Get_State'Result < Get_M (G);

   function Get_Seed (G : Generator) return Value
     with
       Global => null,
       Pre    => Is_Initialised (G),
       Post   => Get_Seed'Result < Get_M (G);

   ---------------------------------------------------------------------------
   -- Overflow-safe modular arithmetic
   ---------------------------------------------------------------------------

   function Add_Mod (X, Y : Value; M : Modulus_Type) return Value
     with
       Global => null,
       Pre    => X < M and then Y < M,
       Post   => Add_Mod'Result < M
                 and then Add_Mod'Result =
                   (if X + Y >= M then X + Y - M else X + Y);

   function Mul_Mod (X, Y : Value; M : Modulus_Type) return Value
     with
       Global => null,
       Pre    => X < M and then Y < M,
       Post   => Mul_Mod'Result < M;

   function Gcd (X, Y : Value) return Value
     with Global => null;

   function Are_Coprime (X, Y : Value) return Boolean
     with
       Global => null,
       Post   => Are_Coprime'Result = (Gcd (X, Y) = 1);

   ---------------------------------------------------------------------------
   -- Hull–Dobell period checks
   -- Full period m for every seed  ⇔
   --   (1) gcd(C, M) = 1
   --   (2) A − 1 is divisible by every prime factor of M
   --   (3) A − 1 is divisible by 4 whenever M is divisible by 4
   ---------------------------------------------------------------------------

   function Prime_Factors_Divide (D, M : Value) return Boolean
     with
       Global => null,
       Pre    => M in Modulus_Type;

   function Increment_Coprime (Params : Parameters) return Boolean
     with
       Global => null,
       Pre    => Is_Valid_Parameters (Params),
       Post   => Increment_Coprime'Result =
         Are_Coprime (Params.C rem Params.M, Params.M);

   function Multiplier_Condition (Params : Parameters) return Boolean
     with
       Global => null,
       Pre    => Is_Valid_Parameters (Params);

   function Four_Condition (Params : Parameters) return Boolean
     with
       Global => null,
       Pre    => Is_Valid_Parameters (Params);

   function Hull_Dobell_Satisfied (Params : Parameters) return Boolean
     with
       Global => null,
       Pre    => Is_Valid_Parameters (Params),
       Post   => Hull_Dobell_Satisfied'Result =
         (Increment_Coprime (Params)
          and then Multiplier_Condition (Params)
          and then Four_Condition (Params));

private

   type Generator is record
      A           : Value   := 0;
      C           : Value   := 0;
      M           : Value   := 0;
      State       : Value   := 0;
      Seed        : Value   := 0;
      Initialised : Boolean := False;
   end record
     with Type_Invariant =>
       (if Initialised then
          M in Modulus_Type
          and then A < M
          and then A /= 0
          and then C < M
          and then State < M
          and then Seed < M);

   function Is_Initialised (G : Generator) return Boolean is (G.Initialised);

   function Get_A (G : Generator) return Value is (G.A);

   function Get_C (G : Generator) return Value is (G.C);

   function Get_M (G : Generator) return Modulus_Type is (Modulus_Type (G.M));

   function Get_State (G : Generator) return Value is (G.State);

   function Get_Seed (G : Generator) return Value is (G.Seed);

end Linear_Congruential_Generator;
