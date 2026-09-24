--  Approximate_Counting body — Morris / Flajolet probabilistic counter.

pragma Ada_2022;

package body Approximate_Counting is

   ---------------------------------------------------------------------------
   -- RNG (32-bit LCG)
   ---------------------------------------------------------------------------

   procedure Seed_RNG (State : out RNG_State; Seed : Natural) is
   begin
      --  Natural fits in 32-bit modular; avoid mapping Seed through
      --  Natural(RNG_State'Last) which may exceed Natural'Last.
      if Seed = 0 then
         State := 1;
      else
         State := RNG_State (Seed);
      end if;
   end Seed_RNG;

   function Next_Unit (State : in out RNG_State) return Unit_Interval is
      --  Numerical Recipes LCG; map into [0, 1) so U never equals 1.0
      --  (keeps c = 0 always-increment path: U < 1 always holds).
      A : constant RNG_State := 1_664_525;
      C : constant RNG_State := 1_013_904_223;
      Denom : constant Real := Real (RNG_State'Last) + 1.0;
   begin
      State := State * A + C;
      return Unit_Interval (Real (State) / Denom);
   end Next_Unit;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Power (Base : Real; Exp : Natural) return Real is
      Result : Real := 1.0;
   begin
      if Base <= 0.0 then
         raise Invalid_Argument with "Power: Base must be positive";
      end if;
      for I in 1 .. Exp loop
         Result := Result * Base;
      end loop;
      return Result;
   end Power;

   function Increment_Probability
     (C    : Exponent_Value;
      Base : Base_Value := 2.0) return Unit_Interval
   is
      P : Real;
   begin
      if C = 0 then
         return 1.0;
      end if;
      --  p = Base^{-C} = 1 / Base^C.
      P := 1.0 / Power (Base, C);
      if P > 1.0 then
         return 1.0;
      elsif P < 0.0 then
         return 0.0;
      else
         return Unit_Interval (P);
      end if;
   end Increment_Probability;

   ---------------------------------------------------------------------------
   -- Counter API
   ---------------------------------------------------------------------------

   function Create
     (Initial_Exponent : Exponent_Value := 0;
      Base             : Base_Value     := 2.0) return Counter
   is
   begin
      return (C => Initial_Exponent, Base => Base);
   end Create;

   function Exponent (C : Counter) return Exponent_Value is
   begin
      return C.C;
   end Exponent;

   function Base_Of (C : Counter) return Base_Value is
   begin
      return C.Base;
   end Base_Of;

   function Estimate (C : Counter) return Non_Negative is
      Bc : constant Real := Power (C.Base, C.C);
   begin
      --  n̂ = (b^c − 1) / (b − 1); for b = 2: 2^c − 1.
      return (Bc - 1.0) / (C.Base - 1.0);
   end Estimate;

   function Power_Approximation (C : Counter) return Non_Negative is
   begin
      return Power (C.Base, C.C);
   end Power_Approximation;

   procedure Bump (C : in out Counter) is
   begin
      if C.C = Max_Exponent then
         raise Capacity_Exceeded
           with "Increment: exponent would exceed Max_Exponent";
      end if;
      C.C := C.C + 1;
   end Bump;

   procedure Increment
     (C     : in out Counter;
      State : in out RNG_State)
   is
      U : constant Unit_Interval := Next_Unit (State);
   begin
      Increment_With_Probability (C, U);
   end Increment;

   procedure Increment_With_Probability
     (C : in out Counter;
      U : Unit_Interval)
   is
      P : constant Unit_Interval :=
        Increment_Probability (C.C, C.Base);
   begin
      if U < P then
         Bump (C);
      end if;
   end Increment_With_Probability;

   procedure Increment_Many
     (C     : in out Counter;
      N     : Natural;
      State : in out RNG_State)
   is
   begin
      for I in 1 .. N loop
         Increment (C, State);
      end loop;
   end Increment_Many;

   function Expectation_Given_Exponent (C : Counter) return Non_Negative is
      --  Wiki Base-2 column: 2^{c+1} − 2 = 2*(2^c − 1).
      --  General Base: Base * Estimate − 1 (matches wiki when Base = 2).
      Est : constant Real := Estimate (C);
   begin
      if Near (C.Base, 2.0) then
         return 2.0 * Est;
      else
         return C.Base * Est - 1.0;
      end if;
   end Expectation_Given_Exponent;

end Approximate_Counting;
