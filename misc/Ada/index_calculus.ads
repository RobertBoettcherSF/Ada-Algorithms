--  Index calculus algorithm — Ada 2023 educational package.
--  Discrete logarithm in (Z/qZ)* via a factor base of small primes,
--  relation collection (B-smooth powers), linear algebra mod Order,
--  and an individual-logarithm descent. Classroom U64 toy only —
--  NOT a production NFS-DL / function-field sieve.
--  Primary source:
--  https://en.wikipedia.org/wiki/Index_calculus_algorithm
--  Siblings (README only; do not `with`): Pohlig–Hellman, Pollard's rho
--  for logarithms, baby-step giant-step (BSGS). Smoothness / factor-base
--  ideas parallel Ada-Dixon (factorization).

pragma Ada_2022;

package Index_Calculus
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Soft classroom bound on the prime modulus q.
   Max_Educational_Modulus : constant U64 := 50_000;

   --  Cap on factor-base size and relation matrix rows (fixed buffers).
   Max_Factor_Base : constant := 32;
   Max_Relations   : constant := 96;

   ------------------------------------------------------------------
   --  Modular / integer helpers (self-contained; no sibling `with`)
   ------------------------------------------------------------------

   --  (A * B) mod M without intermediate overflow (Unsigned_128 product).
   --  Raises Invalid_Argument if M = 0.
   function Mul_Mod (A, B, M : U64) return U64
     with Global => null;

   --  (Base ^ Exp) mod Modulus via binary exponentiation + Mul_Mod.
   --  Raises Invalid_Argument if Modulus = 0.
   function Mod_Pow (Base, Exp, Modulus : U64) return U64
     with Global => null;

   --  Euclidean gcd. Gcd (0, 0) = 0.
   function Gcd (A, B : U64) return U64
     with Global => null;

   --  Non-negative difference (X − Y) mod M with M > 0.
   --  Raises Invalid_Argument if M = 0.
   function Sub_Mod (X, Y, M : U64) return U64
     with Global => null;

   --  Modular multiplicative inverse of A modulo M in 0 .. M−1 when
   --  Gcd(A, M) = 1 and M > 1. Raises Invalid_Argument otherwise.
   function Modular_Inverse (A, M : U64) return U64
     with Global => null;

   --  Integer square root floor(sqrt(N)), no Float.
   function Floor_Sqrt (N : U64) return U64
     with Global => null;

   --  Trial primality (wheel after 2/3). N < 2 → False.
   function Is_Prime_Trial (N : U64) return Boolean
     with Global => null;

   --  True iff Alpha^Log ≡ Beta (mod Modulus) with Modulus > 1.
   function Verify_Discrete_Log
     (Alpha, Beta, Modulus, Log : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Smoothness / factor base
   ------------------------------------------------------------------

   --  Ordered list of primes used as a factor base (ascending).
   --  Educational sketch omits −1 from the Wikipedia base (residues are
   --  taken in {1, …, q−1}).
   type Factor_Base is array (Positive range <>) of U64;

   --  Full exponent vector aligned with a Factor_Base'Range.
   type Exponent_Vector is array (Positive range <>) of Natural;

   --  Discrete logs of factor-base primes (same index range as Base).
   type Log_Vector is array (Positive range <>) of U64;

   --  First primes ≤ B (trial sieve). B < 2 → empty. Educational size.
   function Primes_Up_To (B : U64) return Factor_Base
     with Global => null;

   --  True iff every prime factor of N is in Base (N fully factors).
   --  N = 0 → Invalid_Argument. N = 1 → True (empty product).
   function Is_B_Smooth (N : U64; Base : Factor_Base) return Boolean
     with Global => null;

   --  Full exponents of N over Base if B-smooth; otherwise raises
   --  Invalid_Argument. Length = Base'Length. N = 0 → Invalid_Argument.
   function Smooth_Exponents
     (N : U64; Base : Factor_Base) return Exponent_Vector
     with Global => null;

   ------------------------------------------------------------------
   --  Relations and factor-base logarithms
   ------------------------------------------------------------------

   --  One relation: Generator^K ≡ product Base(i)^Exponents(i) (mod q).
   --  Exponents are stored densely for a known Base'Length at use sites.
   type Relation is record
      K         : U64 := 0;
      Exponents : Exponent_Vector (1 .. Max_Factor_Base) :=
                    [others => 0];
      Width     : Natural := 0;  --  active length (= Base'Length)
   end record;

   type Relation_List is array (Positive range <>) of Relation;

   --  Collect B-smooth powers Generator^k (mod Modulus) for random /
   --  sequential k driven by Seed. Stops after enough independent-looking
   --  relations or Max_Tries exhausted. Returns the collected list
   --  (may be shorter than Base'Length on failure to find enough).
   --  Raises Invalid_Argument if Modulus < 2, Order = 0, Base empty,
   --  or Base'Length > Max_Factor_Base.
   function Collect_Relations
     (Generator : U64;
      Modulus   : U64;
      Order     : U64;
      Base      : Factor_Base;
      Seed      : U64     := 1;
      Max_Tries : Natural := 10_000) return Relation_List
     with Global => null;

   --  Solve the relation matrix for log_Generator(Base(i)) via Gaussian
   --  elimination modulo Order (invertible pivots only; document gcd care
   --  when Order is composite). Verifies each candidate by
   --  Generator^log ≡ Base(i) (mod Modulus). Returns a Log_Vector of
   --  length Base'Length on success, or length 0 on failure.
   --  Raises Invalid_Argument if Base empty / oversized, Order = 0,
   --  Modulus < 2, or a relation Width ≠ Base'Length.
   function Solve_Factor_Base_Logs
     (Generator : U64;
      Modulus   : U64;
      Order     : U64;
      Base      : Factor_Base;
      Relations : Relation_List) return Log_Vector
     with Global => null;

   ------------------------------------------------------------------
   --  Index calculus discrete logarithm
   ------------------------------------------------------------------

   --  Find γ such that Alpha^γ ≡ Beta (mod Modulus) in (Z/qZ)* for a
   --  tiny educational prime Modulus = q, with known subgroup Order
   --  (typically q−1 when Alpha is a primitive root).
   --
   --  Pipeline:
   --    1. Factor base := primes ≤ Smoothness (and < Modulus).
   --    2. Collect B-smooth relations Alpha^k (Seeded search).
   --    3. Linear algebra mod Order → logs of factor-base primes
   --       (Gaussian elimination; invertible pivots; verify).
   --    4. Individual logarithm: find s with Beta·Alpha^s B-smooth,
   --       combine with base logs: γ = Σ f_i log(p_i) − s (mod Order).
   --
   --  Returns γ in 0 .. Order−1 on success. Returns Order as the
   --  documented failure sentinel (not enough relations, singular /
   --  unverified base logs, individual descent failure, empty base).
   --
   --  Raises Invalid_Argument when Modulus < 2,
   --  Modulus > Max_Educational_Modulus, Order = 0, Alpha rem Modulus = 0,
   --  or Beta rem Modulus = 0.
   --
   --  This is a classroom sketch — not NFS-DL / production index calculus.
   function Discrete_Log_Index_Calculus
     (Alpha      : U64;
      Beta       : U64;
      Modulus    : U64;
      Order      : U64;
      Smoothness : U64 := 20;
      Seed       : U64 := 1) return U64
     with Global => null;

end Index_Calculus;
