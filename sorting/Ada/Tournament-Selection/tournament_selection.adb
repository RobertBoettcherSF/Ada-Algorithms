--  Tournament_Selection body — draw K contestants, soft/deterministic
--  pick of the fittest under Maximize / Minimize.

pragma Ada_2022;

package body Tournament_Selection
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

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
   -- Config
   ---------------------------------------------------------------------------

   function Default_Config return Config is
   begin
      return (K                => 2,
              P                => 1.0,
              With_Replacement => True,
              Sense            => Maximize,
              Seed             => 1);
   end Default_Config;

   function Make_Config
     (K                : Positive      := 2;
      P                : Unit_Interval := 1.0;
      With_Replacement : Boolean       := True;
      Sense            : Fitness_Sense := Maximize;
      Seed             : Natural       := 1) return Config
   is
   begin
      return (K                => K,
              P                => P,
              With_Replacement => With_Replacement,
              Sense            => Sense,
              Seed             => Seed);
   end Make_Config;

   function Valid_Config
     (Cfg : Config; Pop_Size : Natural) return Boolean
   is
   begin
      if Pop_Size = 0 then
         return False;
      end if;
      if not Cfg.With_Replacement
        and then Natural (Cfg.K) > Pop_Size
      then
         return False;
      end if;
      return True;
   end Valid_Config;

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
   -- Draw_Contestants
   ---------------------------------------------------------------------------

   function Draw_Contestants
     (Pop              : Population;
      K                : Positive;
      With_Replacement : Boolean;
      State            : in out RNG_State) return Index_List
   is
      N      : constant Natural := Pop'Length;
      Result : Index_List (1 .. K);
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;

      if With_Replacement then
         for I in Result'Range loop
            Result (I) := Positive
              (Next_Natural
                 (State, Natural (Pop'First), Natural (Pop'Last)));
         end loop;
         return Result;
      end if;

      --  Without replacement: need K distinct indices.
      if Natural (K) > N then
         raise Invalid_Argument;
      end if;

      --  Partial Fisher–Yates over a working copy of all indices.
      declare
         Work : Index_List (1 .. N);
         J    : Positive;
         Tmp  : Positive;
      begin
         for I in 1 .. N loop
            Work (I) := Pop'First + I - 1;
         end loop;
         for I in 1 .. K loop
            J := Positive
              (Next_Natural (State, Natural (I), N));
            Tmp := Work (I);
            Work (I) := Work (J);
            Work (J) := Tmp;
            Result (I) := Work (I);
         end loop;
         return Result;
      end;
   end Draw_Contestants;

   ---------------------------------------------------------------------------
   -- Soft_Pick: rank contestants, sample by P·(1−P)^r
   ---------------------------------------------------------------------------

   function Soft_Pick
     (Pop         : Population;
      Contestants : Index_List;
      P           : Unit_Interval;
      Sense       : Fitness_Sense;
      State       : in out RNG_State) return Positive
   is
      M : constant Natural := Contestants'Length;
   begin
      if Pop'Length = 0 or else M = 0 then
         raise Invalid_Argument;
      end if;

      --  Validate contestant indices lie in Pop'Range.
      for I in Contestants'Range loop
         if Contestants (I) < Pop'First
           or else Contestants (I) > Pop'Last
         then
            raise Invalid_Argument;
         end if;
      end loop;

      declare
         --  Ranked holds contestant indices, best first.
         Ranked : Index_List := Contestants;
         Key    : Positive;
         J      : Integer;
         U      : Unit_Interval;
         Cumul  : Real;
         Prob   : Real;
         One_MP : constant Real := 1.0 - Real (P);
         Factor : Real;
      begin
         --  Stable insertion sort of contestant indices by fitness.
         for I in Ranked'First + 1 .. Ranked'Last loop
            Key := Ranked (I);
            J := I - 1;
            while J >= Integer (Ranked'First)
              and then Better
                (Pop (Key).Fitness,
                 Pop (Ranked (J)).Fitness,
                 Sense)
            loop
               Ranked (J + 1) := Ranked (J);
               J := J - 1;
            end loop;
            Ranked (J + 1) := Key;
         end loop;

         --  Deterministic shortcut (also covers M = 1).
         if P >= 1.0 or else M = 1 then
            return Ranked (Ranked'First);
         end if;

         --  Soft: walk ranks 0 .. M-2; last absorbs remainder.
         U := Next_Unit (State);
         Cumul := 0.0;
         Factor := 1.0;
         for R in 0 .. M - 2 loop
            Prob := Real (P) * Factor;
            Cumul := Cumul + Prob;
            if Real (U) < Cumul then
               return Ranked (Ranked'First + R);
            end if;
            Factor := Factor * One_MP;
         end loop;
         return Ranked (Ranked'Last);
      end;
   end Soft_Pick;

   ---------------------------------------------------------------------------
   -- Tournament_Winner / Select_One / Select_Parents
   ---------------------------------------------------------------------------

   function Tournament_Winner
     (Pop   : Population;
      Cfg   : Config;
      State : in out RNG_State) return Positive
   is
      Contestants : Index_List (1 .. Cfg.K);
   begin
      if not Valid_Config (Cfg, Pop'Length) then
         raise Invalid_Argument;
      end if;
      Contestants :=
        Draw_Contestants (Pop, Cfg.K, Cfg.With_Replacement, State);
      return Soft_Pick (Pop, Contestants, Cfg.P, Cfg.Sense, State);
   end Tournament_Winner;

   function Select_One
     (Pop   : Population;
      Cfg   : Config;
      State : in out RNG_State) return Individual
   is
      Idx : Positive;
   begin
      Idx := Tournament_Winner (Pop, Cfg, State);
      return Pop (Idx);
   end Select_One;

   function Select_Parents
     (Pop   : Population;
      Count : Positive;
      Cfg   : Config;
      State : in out RNG_State) return Population
   is
      Result : Population (1 .. Count);
   begin
      if not Valid_Config (Cfg, Pop'Length) then
         raise Invalid_Argument;
      end if;
      for I in Result'Range loop
         Result (I) := Select_One (Pop, Cfg, State);
      end loop;
      return Result;
   end Select_Parents;

   function Select_Parents
     (Pop   : Population;
      Count : Positive;
      Cfg   : Config;
      State : in out RNG_State) return Index_List
   is
      Result : Index_List (1 .. Count);
   begin
      if not Valid_Config (Cfg, Pop'Length) then
         raise Invalid_Argument;
      end if;
      for I in Result'Range loop
         Result (I) := Tournament_Winner (Pop, Cfg, State);
      end loop;
      return Result;
   end Select_Parents;

end Tournament_Selection;
