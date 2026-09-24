--  Truncation_Selection body — rank, truncate top T/K, sample parents
--  uniformly with replacement from the breeding pool.

pragma Ada_2022;

package body Truncation_Selection
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Valid_T (T : Real) return Boolean is
   begin
      return T > 0.0 and then T <= 1.0;
   end Valid_T;

   function Better
     (A, B : Real; Sense : Fitness_Sense) return Boolean
   is
   begin
      case Sense is
         when Maximize =>
            return A > B;
         when Minimize =>
            return A < B;
      end case;
   end Better;

   function Better_Or_Equal
     (A, B : Real; Sense : Fitness_Sense) return Boolean
   is
   begin
      case Sense is
         when Maximize =>
            return A >= B;
         when Minimize =>
            return A <= B;
      end case;
   end Better_Or_Equal;

   ---------------------------------------------------------------------------
   -- Truncation_Count: K = ceil(T * N) in [1, N]
   ---------------------------------------------------------------------------

   function Truncation_Count (N : Natural; T : Real) return Positive is
      Raw : Real;
      K   : Integer;
   begin
      if N = 0 or else not Valid_T (T) then
         raise Invalid_Argument;
      end if;
      Raw := T * Real (N);
      K := Integer (Real'Ceiling (Raw));
      if K < 1 then
         K := 1;
      elsif K > Integer (N) then
         K := Integer (N);
      end if;
      return Positive (K);
   end Truncation_Count;

   ---------------------------------------------------------------------------
   -- Sort_By_Fitness (stable insertion sort, best first)
   ---------------------------------------------------------------------------

   procedure Sort_By_Fitness
     (Pop : in out Population; Sense : Fitness_Sense)
   is
      Key : Individual;
      J   : Integer;
   begin
      if Pop'Length = 0 then
         raise Invalid_Argument;
      end if;
      for I in Pop'First + 1 .. Pop'Last loop
         Key := Pop (I);
         J := I - 1;
         while J >= Integer (Pop'First)
           and then Better (Key.Fitness, Pop (J).Fitness, Sense)
         loop
            Pop (J + 1) := Pop (J);
            J := J - 1;
         end loop;
         Pop (J + 1) := Key;
      end loop;
   end Sort_By_Fitness;

   function Sort_By_Fitness
     (Pop : Population; Sense : Fitness_Sense) return Population
   is
      Result : Population := Pop;
   begin
      Sort_By_Fitness (Result, Sense);
      return Result;
   end Sort_By_Fitness;

   ---------------------------------------------------------------------------
   -- Select_Pool
   ---------------------------------------------------------------------------

   function Select_Pool
     (Pop   : Population;
      T     : Real;
      Sense : Fitness_Sense) return Population
   is
      N : constant Natural := Pop'Length;
      K : Positive;
   begin
      if N = 0 or else not Valid_T (T) then
         raise Invalid_Argument;
      end if;
      K := Truncation_Count (N, T);
      return Select_Pool (Pop, K, Sense);
   end Select_Pool;

   function Select_Pool
     (Pop   : Population;
      K     : Positive;
      Sense : Fitness_Sense) return Population
   is
      N      : constant Natural := Pop'Length;
      Keep   : Positive;
      Ranked : Population := Pop;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if Natural (K) >= N then
         Keep := Positive (N);
      else
         Keep := K;
      end if;
      Sort_By_Fitness (Ranked, Sense);
      declare
         Pool : Population (1 .. Keep);
      begin
         for I in 1 .. Keep loop
            Pool (I) := Ranked (Ranked'First + I - 1);
         end loop;
         return Pool;
      end;
   end Select_Pool;

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

   function Next_Unit (State : in out RNG_State) return Unit_Interval is
      Denom : constant Real := Real (RNG_State'Last) + 1.0;
   begin
      State := State * Multiplier + Increment;
      return Unit_Interval (Real (State) / Denom);
   end Next_Unit;

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
   -- Parent sampling
   ---------------------------------------------------------------------------

   function Select_Parent_Index
     (Pool  : Population;
      State : in out RNG_State) return Positive
   is
   begin
      if Pool'Length = 0 then
         raise Invalid_Argument;
      end if;
      return Positive
        (Next_Natural (State, Natural (Pool'First), Natural (Pool'Last)));
   end Select_Parent_Index;

   function Select_Parents
     (Pool  : Population;
      Count : Positive;
      State : in out RNG_State) return Index_List
   is
      Result : Index_List (1 .. Count);
   begin
      if Pool'Length = 0 then
         raise Invalid_Argument;
      end if;
      for I in Result'Range loop
         Result (I) := Select_Parent_Index (Pool, State);
      end loop;
      return Result;
   end Select_Parents;

   function Select_Parents
     (Pool  : Population;
      Count : Positive;
      State : in out RNG_State) return Population
   is
      Result : Population (1 .. Count);
      Idx    : Positive;
   begin
      if Pool'Length = 0 then
         raise Invalid_Argument;
      end if;
      for I in Result'Range loop
         Idx := Select_Parent_Index (Pool, State);
         Result (I) := Pool (Idx);
      end loop;
      return Result;
   end Select_Parents;

end Truncation_Selection;
