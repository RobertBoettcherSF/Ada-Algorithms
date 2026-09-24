--  Linear_Congruential_Generator body — LCG recurrence, overflow-safe
--  modular multiply, Hull–Dobell helpers.

pragma Ada_2022;

with Interfaces;

package body Linear_Congruential_Generator
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Reduce (Params : Parameters) return Parameters is
      R : Parameters;
   begin
      if Params.M = 0 then
         raise Invalid_Argument;
      end if;
      R.M := Params.M;
      R.A := Params.A rem Params.M;
      R.C := Params.C rem Params.M;
      return R;
   end Reduce;

   function Is_Valid_Parameters (Params : Parameters) return Boolean is
   begin
      if Params.M < 2 then
         return False;
      end if;
      return Params.A rem Params.M /= 0;
   end Is_Valid_Parameters;

   procedure Require_Valid (Params : Parameters) is
   begin
      if not Is_Valid_Parameters (Params) then
         raise Invalid_Argument;
      end if;
   end Require_Valid;

   ---------------------------------------------------------------------------
   -- Overflow-safe modular arithmetic
   ---------------------------------------------------------------------------

   function Add_Mod (X, Y, M : Value) return Value is
      use Interfaces;
      XX, YY, MM, Sum : Unsigned_128;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      XX  := Unsigned_128 (X rem M);
      YY  := Unsigned_128 (Y rem M);
      MM  := Unsigned_128 (M);
      Sum := XX + YY;
      return Value (Unsigned_64 (Sum rem MM));
   end Add_Mod;

   function Mul_Mod (X, Y, M : Value) return Value is
      use Interfaces;
      XX, YY, MM, Prod : Unsigned_128;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      XX   := Unsigned_128 (X rem M);
      YY   := Unsigned_128 (Y rem M);
      MM   := Unsigned_128 (M);
      Prod := XX * YY;
      return Value (Unsigned_64 (Prod rem MM));
   end Mul_Mod;

   function Congruential (State, A, C, M : Value) return Value is
      use Interfaces;
      Wide : Unsigned_128;
   begin
      --  (A * State + C) mod M  with a 128-bit intermediate so the
      --  product never wraps a 64-bit word before reduction.
      Wide :=
        Unsigned_128 (A) * Unsigned_128 (State) + Unsigned_128 (C);
      return Value (Unsigned_64 (Wide rem Unsigned_128 (M)));
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
      N : Value;
      P : Value;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      N := M;
      P := 2;
      while P <= N / P loop
         if N rem P = 0 then
            if D rem P /= 0 then
               return False;
            end if;
            while N rem P = 0 loop
               N := N / P;
            end loop;
         end if;
         if P = 2 then
            P := 3;
         else
            P := P + 2;
         end if;
      end loop;
      if N > 1 and then D rem N /= 0 then
         return False;
      end if;
      return True;
   end Prime_Factors_Divide;

   function Increment_Coprime (Params : Parameters) return Boolean is
      R : Parameters;
   begin
      Require_Valid (Params);
      R := Reduce (Params);
      return Are_Coprime (R.C, R.M);
   end Increment_Coprime;

   function Multiplier_Condition (Params : Parameters) return Boolean is
      R : Parameters;
   begin
      Require_Valid (Params);
      R := Reduce (Params);
      return Prime_Factors_Divide (R.A - 1, R.M);
   end Multiplier_Condition;

   function Four_Condition (Params : Parameters) return Boolean is
      R : Parameters;
   begin
      Require_Valid (Params);
      R := Reduce (Params);
      if R.M rem 4 = 0 then
         return (R.A - 1) rem 4 = 0;
      end if;
      return True;
   end Four_Condition;

   function Hull_Dobell_Satisfied (Params : Parameters) return Boolean is
   begin
      Require_Valid (Params);
      return Increment_Coprime (Params)
        and then Multiplier_Condition (Params)
        and then Four_Condition (Params);
   end Hull_Dobell_Satisfied;

   ---------------------------------------------------------------------------
   -- Create / Reset / Next / Next_Float / Step
   ---------------------------------------------------------------------------

   function Create (Params : Parameters; Seed : Value) return Generator is
      G : Generator;
   begin
      Require_Valid (Params);
      if Seed >= Params.M then
         raise Invalid_Argument;
      end if;
      G.Params := Params;
      G.State  := Seed;
      G.Seed   := Seed;
      return G;
   end Create;

   procedure Reset (G : in out Generator; Seed : Value) is
   begin
      Require_Valid (G.Params);
      if Seed >= G.Params.M then
         raise Invalid_Argument;
      end if;
      G.State := Seed;
      G.Seed  := Seed;
   end Reset;

   function Next (G : in out Generator) return Value is
   begin
      Require_Valid (G.Params);
      G.State :=
        Congruential (G.State, G.Params.A, G.Params.C, G.Params.M);
      return G.State;
   end Next;

   function To_Long_Float (X : Value) return Long_Float is
      use Interfaces;
      U : constant Unsigned_64 := Unsigned_64 (X);
   begin
      --  Long_Float conversion is exact for X < 2^53; above that the
      --  mantissa rounds. Split at 2^63 so the unsigned word always
      --  fits a signed 64-bit intermediate.
      if U <= 16#7FFF_FFFF_FFFF_FFFF# then
         return Long_Float (Long_Long_Integer (U));
      end if;
      return Long_Float (Long_Long_Integer (U - 16#8000_0000_0000_0000#))
        + 2.0 ** 63;
   end To_Long_Float;

   function Next_Float (G : in out Generator) return Long_Float is
      X : Value;
      M : Value;
   begin
      X := Next (G);
      M := G.Params.M;
      return To_Long_Float (X) / To_Long_Float (M);
   end Next_Float;

   function Step (State : Value; Params : Parameters) return Value is
   begin
      Require_Valid (Params);
      if State >= Params.M then
         raise Invalid_Argument;
      end if;
      return Congruential (State, Params.A, Params.C, Params.M);
   end Step;

   ---------------------------------------------------------------------------
   -- Inspectors
   ---------------------------------------------------------------------------

   function Get_Parameters (G : Generator) return Parameters is
   begin
      return G.Params;
   end Get_Parameters;

   function Get_State (G : Generator) return Value is
   begin
      return G.State;
   end Get_State;

   function Get_Seed (G : Generator) return Value is
   begin
      return G.Seed;
   end Get_Seed;

end Linear_Congruential_Generator;
