--  Linear_Congruential_Generator body — LCG recurrence, overflow-safe
--  modular multiply (M ≤ 2**32), Hull–Dobell helpers. SPARK Level 4:
--  bounded loops, no heap, no exceptions, modulus capped so arithmetic
--  stays wrap-free inside a single mod-2**64 word.

package body Linear_Congruential_Generator
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Modulus (M : Value) return Boolean is
   begin
      return M >= 2 and then M <= Max_Modulus;
   end Is_Valid_Modulus;

   function Is_Valid_Parameters (Params : Parameters) return Boolean is
   begin
      if Params.M < 2 or else Params.M > Max_Modulus then
         return False;
      end if;
      return Params.A rem Params.M /= 0;
   end Is_Valid_Parameters;

   function Reduce (Params : Parameters) return Parameters is
   begin
      return
        (A => Params.A rem Params.M,
         C => Params.C rem Params.M,
         M => Params.M);
   end Reduce;

   ---------------------------------------------------------------------------
   -- Overflow-safe modular arithmetic
   ---------------------------------------------------------------------------

   function Add_Mod (X, Y : Value; M : Modulus_Type) return Value is
      Sum : Value;
   begin
      --  X < M ≤ 2**32 and Y < M ⇒ X+Y < 2**33 < 2**64 (no wrap).
      Sum := X + Y;
      if Sum >= M then
         return Sum - M;
      else
         return Sum;
      end if;
   end Add_Mod;

   function Mul_Mod (X, Y : Value; M : Modulus_Type) return Value is
      Prod : Value;
   begin
      --  X,Y < M ≤ 2**32 ⇒ X·Y ≤ (M−1)² = M²−2M+1 ≤ 2**64−2**33+1
      --  which fits in Value without modular wrap.
      Prod := X * Y;
      return Prod rem M;
   end Mul_Mod;

   function Congruential (State, A, C, M : Value) return Value
     with
       Global => null,
       Pre    => M in Modulus_Type
                 and then A < M
                 and then A /= 0
                 and then C < M
                 and then State < M,
       Post   => Congruential'Result < M;

   function Congruential (State, A, C, M : Value) return Value is
      Wide : Value;
   begin
      --  A·State + C ≤ (M−1)·(M−1) + (M−1) = (M−1)·M = M²−M
      --  ≤ 2**64 − 2**32 < 2**64 (no wrap).
      Wide := A * State + C;
      return Wide rem M;
   end Congruential;

   ---------------------------------------------------------------------------
   -- GCD
   ---------------------------------------------------------------------------

   function Gcd (X, Y : Value) return Value is
      A : Value := X;
      B : Value := Y;
      T : Value;
   begin
      while B /= 0 loop
         pragma Loop_Variant (Decreases => B);
         T := A rem B;
         A := B;
         B := T;
      end loop;
      return A;
   end Gcd;

   function Are_Coprime (X, Y : Value) return Boolean is
   begin
      return Gcd (X, Y) = 1;
   end Are_Coprime;

   ---------------------------------------------------------------------------
   -- Hull–Dobell helpers
   ---------------------------------------------------------------------------

   function Prime_Factors_Divide (D, M : Value) return Boolean is
      --  Trial bound: sqrt(Max_Modulus) = 2**16. Bounded for-loop ⇒
      --  termination is immediate for GNATprove.
      Max_Trial : constant Positive := 65_536;
      N         : Value := M;
      P         : Value;
   begin
      for Trial in 2 .. Max_Trial loop
         pragma Loop_Invariant (N >= 1 and then N <= M);
         P := Value (Trial);
         if P > N / P then
            exit;
         end if;
         if N rem P = 0 then
            if D rem P /= 0 then
               return False;
            end if;
            while N rem P = 0 loop
               pragma Loop_Invariant (N >= P and then N <= M);
               pragma Loop_Invariant (P >= 2);
               pragma Loop_Variant (Decreases => N);
               N := N / P;
            end loop;
         end if;
      end loop;
      if N > 1 and then D rem N /= 0 then
         return False;
      end if;
      return True;
   end Prime_Factors_Divide;

   function Increment_Coprime (Params : Parameters) return Boolean is
      R : constant Parameters := Reduce (Params);
   begin
      return Are_Coprime (R.C, R.M);
   end Increment_Coprime;

   function Multiplier_Condition (Params : Parameters) return Boolean is
      R : constant Parameters := Reduce (Params);
   begin
      --  A ≥ 1 after Reduce; A − 1 is well-defined as Value.
      return Prime_Factors_Divide (R.A - 1, R.M);
   end Multiplier_Condition;

   function Four_Condition (Params : Parameters) return Boolean is
      R : constant Parameters := Reduce (Params);
   begin
      if R.M rem 4 = 0 then
         return (R.A - 1) rem 4 = 0;
      end if;
      return True;
   end Four_Condition;

   function Hull_Dobell_Satisfied (Params : Parameters) return Boolean is
   begin
      return Increment_Coprime (Params)
        and then Multiplier_Condition (Params)
        and then Four_Condition (Params);
   end Hull_Dobell_Satisfied;

   ---------------------------------------------------------------------------
   -- Create / Reset / Next / Step
   ---------------------------------------------------------------------------

   function Create (Params : Parameters; Seed : Value) return Generator is
      R : constant Parameters := Reduce (Params);
   begin
      return
        (A           => R.A,
         C           => R.C,
         M           => R.M,
         State       => Seed,
         Seed        => Seed,
         Initialised => True);
   end Create;

   procedure Reset (G : in out Generator; Seed : Value) is
   begin
      G.State := Seed;
      G.Seed  := Seed;
   end Reset;

   function Step (State : Value; Params : Parameters) return Value is
      R : constant Parameters := Reduce (Params);
   begin
      return Congruential (State, R.A, R.C, R.M);
   end Step;

   procedure Next (G : in out Generator; Result : out Value) is
   begin
      G.State := Congruential (G.State, G.A, G.C, G.M);
      Result  := G.State;
   end Next;

   ---------------------------------------------------------------------------
   -- Inspectors
   ---------------------------------------------------------------------------

   function Get_Parameters (G : Generator) return Parameters is
   begin
      return (A => G.A, C => G.C, M => G.M);
   end Get_Parameters;

end Linear_Congruential_Generator;
