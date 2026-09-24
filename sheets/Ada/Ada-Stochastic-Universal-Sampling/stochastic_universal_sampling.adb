--  Stochastic_Universal_Sampling body — Baker SUS + classic FPS roulette.

pragma Ada_2022;

package body Stochastic_Universal_Sampling
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   ---------------------------------------------------------------------------
   -- Config
   ---------------------------------------------------------------------------

   function Default_Config return Config is
   begin
      return (Seed => 1);
   end Default_Config;

   function Make_Config (Seed : Natural := 1) return Config is
   begin
      return (Seed => Seed);
   end Make_Config;

   function Valid_Config
     (Cfg          : Config;
      Pop_Size     : Natural;
      Select_Count : Natural) return Boolean
   is
      pragma Unreferenced (Cfg);
   begin
      return Pop_Size >= 1 and then Select_Count >= 1;
   end Valid_Config;

   ---------------------------------------------------------------------------
   -- Fitness validation / shift
   ---------------------------------------------------------------------------

   function All_Non_Negative (Pop : Population) return Boolean is
   begin
      for I in Pop'Range loop
         if Pop (I).Fitness < 0.0 then
            return False;
         end if;
      end loop;
      return True;
   end All_Non_Negative;

   function Total_Fitness (Pop : Population) return Real is
      S : Real := 0.0;
   begin
      for I in Pop'Range loop
         S := S + Pop (I).Fitness;
      end loop;
      return S;
   end Total_Fitness;

   function Shift_Costs_To_Fitness (Pop : Population) return Population is
      Result : Population := Pop;
      Max_C  : Real;
      Min_C  : Real;
   begin
      if Pop'Length = 0 then
         raise Invalid_Argument;
      end if;
      Max_C := Pop (Pop'First).Fitness;
      Min_C := Max_C;
      for I in Pop'Range loop
         if Pop (I).Fitness > Max_C then
            Max_C := Pop (I).Fitness;
         end if;
         if Pop (I).Fitness < Min_C then
            Min_C := Pop (I).Fitness;
         end if;
      end loop;
      if Near (Max_C, Min_C) then
         for I in Result'Range loop
            Result (I).Fitness := 1.0;
         end loop;
      else
         for I in Result'Range loop
            Result (I).Fitness := Max_C - Pop (I).Fitness;
         end loop;
      end if;
      return Result;
   end Shift_Costs_To_Fitness;

   ---------------------------------------------------------------------------
   -- Cumulative / Map_Pointer (RWS)
   ---------------------------------------------------------------------------

   function Cumulative_Fitness (Pop : Population) return Fitness_Array is
      Cumul : Fitness_Array (Pop'Range);
      Acc   : Real := 0.0;
   begin
      if Pop'Length = 0 then
         raise Invalid_Argument;
      end if;
      if not All_Non_Negative (Pop) then
         raise Invalid_Argument;
      end if;
      for I in Pop'Range loop
         Acc := Acc + Pop (I).Fitness;
         Cumul (I) := Acc;
      end loop;
      if Acc <= 0.0 then
         raise Invalid_Argument;
      end if;
      return Cumul;
   end Cumulative_Fitness;

   function Map_Pointer
     (Cumul   : Fitness_Array;
      Pointer : Real) return Positive
   is
   begin
      if Cumul'Length = 0 then
         raise Invalid_Argument;
      end if;
      if Pointer <= 0.0 then
         return Cumul'First;
      end if;
      for I in Cumul'Range loop
         if Cumul (I) >= Pointer then
            return I;
         end if;
      end loop;
      return Cumul'Last;
   end Map_Pointer;

   ---------------------------------------------------------------------------
   -- RNG (Numerical Recipes–style LCG, period 2^32)
   ---------------------------------------------------------------------------

   Multiplier : constant RNG_State := 1_664_525;
   Increment  : constant RNG_State := 1_013_904_223;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural) is
   begin
      if Seed = 0 then
         State := 1;
      else
         State := RNG_State (Seed);
      end if;
   end Seed_RNG;

   procedure Seed_RNG (State : out RNG_State; Cfg : Config) is
   begin
      Seed_RNG (State, Cfg.Seed);
   end Seed_RNG;

   function Next_Unit (State : in out RNG_State) return Unit_Interval is
      Denom : constant Real := Real (RNG_State'Last) + 1.0;
   begin
      State := State * Multiplier + Increment;
      return Unit_Interval (Real (State) / Denom);
   end Next_Unit;

   function Next_Real
     (State : in out RNG_State; Lo, Hi : Real) return Real
   is
      U : constant Unit_Interval := Next_Unit (State);
   begin
      return Lo + Real (U) * (Hi - Lo);
   end Next_Real;

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
   is
      Span : constant Natural := Hi - Lo;
      U    : Unit_Interval;
      Off  : Natural;
   begin
      if Span = 0 then
         return Lo;
      end if;
      U := Next_Unit (State);
      Off := Natural (Real'Floor (Real (U) * Real (Span + 1)));
      if Off > Span then
         Off := Span;
      end if;
      return Lo + Off;
   end Next_Natural;

   ---------------------------------------------------------------------------
   -- Select_SUS / Select_Roulette
   ---------------------------------------------------------------------------

   function Select_SUS
     (Pop   : Population;
      N     : Positive;
      State : in out RNG_State) return Index_List
   is
      Cumul  : constant Fitness_Array := Cumulative_Fitness (Pop);
      F      : constant Real := Cumul (Cumul'Last);
      P      : constant Real := F / Real (N);
      Start  : Real;
      Result : Index_List (1 .. N);
      Ptr    : Real;
   begin
      --  Start ~ Uniform[0, P). If P = 0 would imply F = 0 (already raised).
      Start := Next_Real (State, 0.0, P);
      for I in 0 .. N - 1 loop
         Ptr := Start + Real (I) * P;
         Result (I + 1) := Map_Pointer (Cumul, Ptr);
      end loop;
      return Result;
   end Select_SUS;

   function Select_SUS
     (Pop   : Population;
      N     : Positive;
      State : in out RNG_State) return Population
   is
      Idx    : constant Index_List := Select_SUS (Pop, N, State);
      Result : Population (1 .. N);
   begin
      for I in Result'Range loop
         Result (I) := Pop (Idx (I));
      end loop;
      return Result;
   end Select_SUS;

   function Select_Roulette
     (Pop   : Population;
      N     : Positive;
      State : in out RNG_State) return Index_List
   is
      Cumul  : constant Fitness_Array := Cumulative_Fitness (Pop);
      F      : constant Real := Cumul (Cumul'Last);
      Result : Index_List (1 .. N);
      Ptr    : Real;
   begin
      for I in Result'Range loop
         --  Independent Uniform(0, F); Map_Pointer handles 0 → First.
         Ptr := Next_Real (State, 0.0, F);
         Result (I) := Map_Pointer (Cumul, Ptr);
      end loop;
      return Result;
   end Select_Roulette;

   function Select_Roulette
     (Pop   : Population;
      N     : Positive;
      State : in out RNG_State) return Population
   is
      Idx    : constant Index_List := Select_Roulette (Pop, N, State);
      Result : Population (1 .. N);
   begin
      for I in Result'Range loop
         Result (I) := Pop (Idx (I));
      end loop;
      return Result;
   end Select_Roulette;

   function Select_SUS
     (Pop   : Population;
      N     : Positive;
      Cfg   : Config;
      State : in out RNG_State) return Index_List
   is
   begin
      if not Valid_Config (Cfg, Pop'Length, Natural (N)) then
         raise Invalid_Argument;
      end if;
      Seed_RNG (State, Cfg);
      return Select_SUS (Pop, N, State);
   end Select_SUS;

   function Select_Roulette
     (Pop   : Population;
      N     : Positive;
      Cfg   : Config;
      State : in out RNG_State) return Index_List
   is
   begin
      if not Valid_Config (Cfg, Pop'Length, Natural (N)) then
         raise Invalid_Argument;
      end if;
      Seed_RNG (State, Cfg);
      return Select_Roulette (Pop, N, State);
   end Select_Roulette;

end Stochastic_Universal_Sampling;
