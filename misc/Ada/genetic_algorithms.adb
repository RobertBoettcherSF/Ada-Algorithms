--  Genetic_Algorithms body — educational bit-string GA.

pragma Ada_2022;

package body Genetic_Algorithms
  with SPARK_Mode => Off
is

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
      U    : constant Unit_Interval := Next_Unit (State);
      Span : constant Natural := Hi - Lo;
      K    : Natural;
   begin
      if Span = 0 then
         return Lo;
      end if;
      K := Natural (Real (U) * Real (Span + 1));
      if K > Span then
         K := Span;
      end if;
      return Lo + K;
   end Next_Natural;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Default_Config
     (Pop_Size       : Pop_Size_T     := 30;
      Generations    : Natural        := 80;
      Crossover_Rate : Unit_Interval  := 0.8;
      Mutation_Rate  : Unit_Interval  := 0.02;
      Tournament_K   : Tourney_K      := 3;
      Elite_Count    : Elite_T        := 1;
      Seed           : Natural        := 1;
      Selection      : Selection_Kind := Tournament;
      Crossover      : Crossover_Kind := One_Point) return Config
   is
   begin
      return
        (Pop_Size       => Pop_Size,
         Generations    => Generations,
         Crossover_Rate => Crossover_Rate,
         Mutation_Rate  => Mutation_Rate,
         Tournament_K   => Tournament_K,
         Elite_Count    => Elite_Count,
         Seed           => Seed,
         Selection      => Selection,
         Crossover      => Crossover);
   end Default_Config;

   function Config_Is_Valid (Cfg : Config) return Boolean is
   begin
      return Natural (Cfg.Tournament_K) <= Natural (Cfg.Pop_Size)
        and then Natural (Cfg.Elite_Count) < Natural (Cfg.Pop_Size);
   end Config_Is_Valid;

   ---------------------------------------------------------------------------
   -- Bit-string utilities
   ---------------------------------------------------------------------------

   function Hamming_Distance (A, B : Bit_String) return Natural is
      D : Natural := 0;
   begin
      for I in A'Range loop
         if A (I) /= B (I - A'First + B'First) then
            D := D + 1;
         end if;
      end loop;
      return D;
   end Hamming_Distance;

   function Zero_Count (Bits : Bit_String) return Natural is
      Z : Natural := 0;
   begin
      for B of Bits loop
         if not B then
            Z := Z + 1;
         end if;
      end loop;
      return Z;
   end Zero_Count;

   function Ones_Count (Bits : Bit_String) return Natural is
   begin
      return Bits'Length - Zero_Count (Bits);
   end Ones_Count;

   function Flip_Bit (Bits : Bit_String; Index : Positive) return Bit_String is
      R : Bit_String := Bits;
   begin
      R (Index) := not R (Index);
      return R;
   end Flip_Bit;

   function Random_Bit_String
     (State : in out RNG_State; N : Bit_Count) return Bit_String
   is
      R : Bit_String (1 .. N);
   begin
      for I in 1 .. N loop
         R (I) := Next_Unit (State) >= 0.5;
      end loop;
      return R;
   end Random_Bit_String;

   function Copy_Bits (Src : Bit_String; N : Bit_Count) return Bit_String is
      R : Bit_String (1 .. N);
   begin
      for I in 1 .. N loop
         R (I) := Src (Src'First + I - 1);
      end loop;
      return R;
   end Copy_Bits;

   function All_Ones (N : Bit_Count) return Bit_String is
      B : constant Bit_String (1 .. N) := [others => True];
   begin
      return B;
   end All_Ones;

   function All_Zeros (N : Bit_Count) return Bit_String is
      B : constant Bit_String (1 .. N) := [others => False];
   begin
      return B;
   end All_Zeros;

   function Equal_Bits (A, B : Bit_String) return Boolean is
   begin
      for I in A'Range loop
         if A (I) /= B (I - A'First + B'First) then
            return False;
         end if;
      end loop;
      return True;
   end Equal_Bits;

   ---------------------------------------------------------------------------
   -- Fitness / cost
   ---------------------------------------------------------------------------

   function Fitness_OneMax (Bits : Bit_String) return Real is
   begin
      return Real (Ones_Count (Bits));
   end Fitness_OneMax;

   function Cost_Zero_Count (Bits : Bit_String) return Real is
   begin
      return Real (Zero_Count (Bits));
   end Cost_Zero_Count;

   function Cost_Hamming (Bits, Target : Bit_String) return Real is
   begin
      return Real (Hamming_Distance (Bits, Target));
   end Cost_Hamming;

   function Fitness_Hamming (Bits, Target : Bit_String) return Real is
   begin
      return Real (Bits'Length) - Cost_Hamming (Bits, Target);
   end Fitness_Hamming;

   ---------------------------------------------------------------------------
   -- Selection
   ---------------------------------------------------------------------------

   function Tournament_Select
     (State   : in out RNG_State;
      Fitness : Fitness_Array;
      K       : Tourney_K) return Positive
   is
      Best_I : Positive;
      Cand_I : Positive;
      First  : constant Positive := Fitness'First;
      Last   : constant Positive := Fitness'Last;
   begin
      if Fitness'Length < 2 or else Natural (K) > Fitness'Length then
         raise Invalid_Argument;
      end if;

      Best_I := Next_Natural (State, First, Last);
      for T in 2 .. Natural (K) loop
         pragma Unreferenced (T);
         Cand_I := Next_Natural (State, First, Last);
         if Fitness (Cand_I) > Fitness (Best_I) then
            Best_I := Cand_I;
         end if;
      end loop;
      return Best_I;
   end Tournament_Select;

   function Tournament_Select_Min
     (State : in out RNG_State;
      Costs : Cost_Array;
      K     : Tourney_K) return Positive
   is
      Best_I : Positive;
      Cand_I : Positive;
      First  : constant Positive := Costs'First;
      Last   : constant Positive := Costs'Last;
   begin
      if Costs'Length < 2 or else Natural (K) > Costs'Length then
         raise Invalid_Argument;
      end if;

      Best_I := Next_Natural (State, First, Last);
      for T in 2 .. Natural (K) loop
         pragma Unreferenced (T);
         Cand_I := Next_Natural (State, First, Last);
         if Costs (Cand_I) < Costs (Best_I) then
            Best_I := Cand_I;
         end if;
      end loop;
      return Best_I;
   end Tournament_Select_Min;

   function Fitness_Proportionate_Select
     (State   : in out RNG_State;
      Fitness : Fitness_Array) return Positive
   is
      Total   : Real := 0.0;
      Pointer : Real;
      Cumul   : Real := 0.0;
      F       : Real;
   begin
      if Fitness'Length < 1 then
         raise Invalid_Argument;
      end if;

      for I in Fitness'Range loop
         F := Fitness (I);
         if F < 0.0 then
            F := 0.0;
         end if;
         Total := Total + F;
      end loop;

      if Total <= 0.0 then
         return Next_Natural (State, Fitness'First, Fitness'Last);
      end if;

      Pointer := Real (Next_Unit (State)) * Total;
      for I in Fitness'Range loop
         F := Fitness (I);
         if F < 0.0 then
            F := 0.0;
         end if;
         Cumul := Cumul + F;
         if Cumul >= Pointer then
            return I;
         end if;
      end loop;
      return Fitness'Last;
   end Fitness_Proportionate_Select;

   ---------------------------------------------------------------------------
   -- Crossover / mutation
   ---------------------------------------------------------------------------

   function One_Point_Crossover
     (Parent_A, Parent_B : Bit_String;
      State              : in out RNG_State) return Bit_String
   is
      N     : constant Bit_Count := Parent_A'Length;
      A     : constant Bit_String (1 .. N) := Copy_Bits (Parent_A, N);
      B     : constant Bit_String (1 .. N) := Copy_Bits (Parent_B, N);
      Cut   : Natural;
      Child : Bit_String (1 .. N);
   begin
      if Parent_A'Length /= Parent_B'Length
        or else Parent_A'Length < 1
        or else Parent_A'Length > Max_Bits
      then
         raise Invalid_Argument;
      end if;

      Cut := Next_Natural (State, 0, Natural (N));
      for I in 1 .. N loop
         if Natural (I) <= Cut then
            Child (I) := A (I);
         else
            Child (I) := B (I);
         end if;
      end loop;
      return Child;
   end One_Point_Crossover;

   function Two_Point_Crossover
     (Parent_A, Parent_B : Bit_String;
      State              : in out RNG_State) return Bit_String
   is
      N     : constant Bit_Count := Parent_A'Length;
      A     : constant Bit_String (1 .. N) := Copy_Bits (Parent_A, N);
      B     : constant Bit_String (1 .. N) := Copy_Bits (Parent_B, N);
      Lo, Hi, Tmp : Natural;
      Child : Bit_String (1 .. N);
   begin
      if Parent_A'Length /= Parent_B'Length
        or else Parent_A'Length < 1
        or else Parent_A'Length > Max_Bits
      then
         raise Invalid_Argument;
      end if;

      Lo := Next_Natural (State, 1, Natural (N));
      Hi := Next_Natural (State, 1, Natural (N));
      if Lo > Hi then
         Tmp := Lo;
         Lo  := Hi;
         Hi  := Tmp;
      end if;

      for I in 1 .. N loop
         if Natural (I) >= Lo and then Natural (I) <= Hi then
            Child (I) := B (I);
         else
            Child (I) := A (I);
         end if;
      end loop;
      return Child;
   end Two_Point_Crossover;

   function Crossover
     (Parent_A, Parent_B : Bit_String;
      Kind               : Crossover_Kind;
      Rate               : Unit_Interval;
      State              : in out RNG_State) return Bit_String
   is
      N : constant Bit_Count := Parent_A'Length;
   begin
      if Parent_A'Length /= Parent_B'Length
        or else Parent_A'Length < 1
        or else Parent_A'Length > Max_Bits
      then
         raise Invalid_Argument;
      end if;

      if Next_Unit (State) >= Rate then
         return Copy_Bits (Parent_A, N);
      end if;

      case Kind is
         when One_Point =>
            return One_Point_Crossover (Parent_A, Parent_B, State);
         when Two_Point =>
            return Two_Point_Crossover (Parent_A, Parent_B, State);
      end case;
   end Crossover;

   function Mutate_Bits
     (Bits  : Bit_String;
      Rate  : Unit_Interval;
      State : in out RNG_State) return Bit_String
   is
      N : constant Bit_Count := Bits'Length;
      R : Bit_String (1 .. N) := Copy_Bits (Bits, N);
   begin
      if Bits'Length < 1 or else Bits'Length > Max_Bits then
         raise Invalid_Argument;
      end if;

      if Rate = 0.0 then
         return R;
      end if;

      for I in 1 .. N loop
         if Next_Unit (State) < Rate then
            R (I) := not R (I);
         end if;
      end loop;
      return R;
   end Mutate_Bits;

   ---------------------------------------------------------------------------
   -- Elitism
   ---------------------------------------------------------------------------

   function Elite_Indices_Max
     (Fitness : Fitness_Array;
      Count   : Natural) return Index_Array
   is
      N     : constant Natural := Fitness'Length;
      Order : Index_Array (1 .. N);
      Tmp   : Positive;
      Res   : Index_Array (1 .. Count);
   begin
      if Count > Fitness'Length then
         raise Invalid_Argument;
      end if;

      for I in 1 .. N loop
         Order (I) := Fitness'First + I - 1;
      end loop;

      --  Stable insertion sort by fitness descending.
      for I in 2 .. N loop
         Tmp := Order (I);
         declare
            J : Natural := I - 1;
         begin
            while J >= 1
              and then Fitness (Order (J)) < Fitness (Tmp)
            loop
               Order (J + 1) := Order (J);
               J := J - 1;
            end loop;
            Order (J + 1) := Tmp;
         end;
      end loop;

      for I in 1 .. Count loop
         Res (I) := Order (I);
      end loop;
      return Res;
   end Elite_Indices_Max;

   function Elite_Indices_Min
     (Costs : Cost_Array;
      Count : Natural) return Index_Array
   is
      N     : constant Natural := Costs'Length;
      Order : Index_Array (1 .. N);
      Tmp   : Positive;
      Res   : Index_Array (1 .. Count);
   begin
      if Count > Costs'Length then
         raise Invalid_Argument;
      end if;

      for I in 1 .. N loop
         Order (I) := Costs'First + I - 1;
      end loop;

      for I in 2 .. N loop
         Tmp := Order (I);
         declare
            J : Natural := I - 1;
         begin
            while J >= 1
              and then Costs (Order (J)) > Costs (Tmp)
            loop
               Order (J + 1) := Order (J);
               J := J - 1;
            end loop;
            Order (J + 1) := Tmp;
         end;
      end loop;

      for I in 1 .. Count loop
         Res (I) := Order (I);
      end loop;
      return Res;
   end Elite_Indices_Min;

   ---------------------------------------------------------------------------
   -- Pack helper
   ---------------------------------------------------------------------------

   function Pack
     (Cur : Bit_String; N : Bit_Count;
      Fit, Cost : Real;
      Gens, Evals : Natural) return Result
   is
      R : Result;
   begin
      R.N               := N;
      R.Best_Fitness    := Fit;
      R.Best_Cost       := Cost;
      R.Generations_Run := Gens;
      R.Evaluations     := Evals;
      R.History_Length  := Gens;
      for I in 1 .. N loop
         R.Best_Bits (I) := Cur (I);
      end loop;
      return R;
   end Pack;

   ---------------------------------------------------------------------------
   -- Shared generational loop (maximize fitness)
   ---------------------------------------------------------------------------

   type Pop_Store is array (Positive range <>) of Bit_String (1 .. Max_Bits);

   function Select_Parent_Max
     (State   : in out RNG_State;
      Fitness : Fitness_Array;
      Cfg     : Config) return Positive
   is
   begin
      case Cfg.Selection is
         when Tournament =>
            return Tournament_Select (State, Fitness, Cfg.Tournament_K);
         when Fitness_Proportionate =>
            return Fitness_Proportionate_Select (State, Fitness);
      end case;
   end Select_Parent_Max;

   function Select_Parent_Min
     (State : in out RNG_State;
      Costs : Cost_Array;
      Fit   : Fitness_Array;
      Cfg   : Config) return Positive
   is
   begin
      case Cfg.Selection is
         when Tournament =>
            return Tournament_Select_Min (State, Costs, Cfg.Tournament_K);
         when Fitness_Proportionate =>
            --  FPS needs non-negative fitness; use Fit (= shifted costs).
            return Fitness_Proportionate_Select (State, Fit);
      end case;
   end Select_Parent_Min;

   function Run_Maximize
     (N          : Bit_Count;
      Cfg        : Config;
      Eval_Fit   : access function (Bits : Bit_String) return Real)
      return Result
   is
      P      : constant Pop_Size_T := Cfg.Pop_Size;
      State  : RNG_State;
      Pop    : Pop_Store (1 .. P);
      Next_P : Pop_Store (1 .. P);
      Fit    : Fitness_Array (1 .. P);
      Best   : Bit_String (1 .. N);
      Best_F : Real := Real'First;
      Evals  : Natural := 0;
      PA, PB : Positive;
      Child  : Bit_String (1 .. N);
      EC     : constant Natural := Natural (Cfg.Elite_Count);
      Slot   : Positive;
   begin
      if not Config_Is_Valid (Cfg) then
         raise Invalid_Argument;
      end if;

      Seed_RNG (State, Cfg.Seed);

      for I in 1 .. P loop
         declare
            Rnd : constant Bit_String := Random_Bit_String (State, N);
         begin
            for B in 1 .. N loop
               Pop (I)(B) := Rnd (B);
            end loop;
         end;
         Fit (I) := Eval_Fit (Copy_Bits (Pop (I), N));
         Evals   := Evals + 1;
         if Fit (I) > Best_F then
            Best_F := Fit (I);
            Best   := Copy_Bits (Pop (I), N);
         end if;
      end loop;

      if Cfg.Generations = 0 then
         return Pack (Best, N, Best_F, Real (N) - Best_F, 0, Evals);
      end if;

      for Gen in 1 .. Cfg.Generations loop
         pragma Unreferenced (Gen);

         --  Elites first.
         if EC > 0 then
            declare
               Idx : constant Index_Array := Elite_Indices_Max (Fit, EC);
            begin
               for E in 1 .. EC loop
                  for B in 1 .. N loop
                     Next_P (E)(B) := Pop (Idx (E))(B);
                  end loop;
               end loop;
            end;
         end if;

         Slot := EC + 1;
         while Slot <= Natural (P) loop
            PA := Select_Parent_Max (State, Fit, Cfg);
            PB := Select_Parent_Max (State, Fit, Cfg);
            Child := Crossover
              (Copy_Bits (Pop (PA), N),
               Copy_Bits (Pop (PB), N),
               Cfg.Crossover,
               Cfg.Crossover_Rate,
               State);
            Child := Mutate_Bits (Child, Cfg.Mutation_Rate, State);
            for B in 1 .. N loop
               Next_P (Slot)(B) := Child (B);
            end loop;
            Slot := Slot + 1;
         end loop;

         Pop := Next_P;
         for I in 1 .. P loop
            Fit (I) := Eval_Fit (Copy_Bits (Pop (I), N));
            Evals   := Evals + 1;
            if Fit (I) > Best_F then
               Best_F := Fit (I);
               Best   := Copy_Bits (Pop (I), N);
            end if;
         end loop;
      end loop;

      return Pack
        (Best, N, Best_F, Real (N) - Best_F, Cfg.Generations, Evals);
   end Run_Maximize;

   function Run_Minimize
     (N          : Bit_Count;
      Cfg        : Config;
      Eval_Cost  : access function (Bits : Bit_String) return Real)
      return Result
   is
      P      : constant Pop_Size_T := Cfg.Pop_Size;
      State  : RNG_State;
      Pop    : Pop_Store (1 .. P);
      Next_P : Pop_Store (1 .. P);
      Costs  : Cost_Array (1 .. P);
      Fit    : Fitness_Array (1 .. P);
      Best   : Bit_String (1 .. N);
      Best_C : Real := Real'Last;
      Evals  : Natural := 0;
      PA, PB : Positive;
      Child  : Bit_String (1 .. N);
      EC     : constant Natural := Natural (Cfg.Elite_Count);
      Slot   : Positive;
      Max_C  : Real;
   begin
      if not Config_Is_Valid (Cfg) then
         raise Invalid_Argument;
      end if;

      Seed_RNG (State, Cfg.Seed);

      for I in 1 .. P loop
         declare
            Rnd : constant Bit_String := Random_Bit_String (State, N);
         begin
            for B in 1 .. N loop
               Pop (I)(B) := Rnd (B);
            end loop;
         end;
         Costs (I) := Eval_Cost (Copy_Bits (Pop (I), N));
         Evals     := Evals + 1;
         if Costs (I) < Best_C then
            Best_C := Costs (I);
            Best   := Copy_Bits (Pop (I), N);
         end if;
      end loop;

      --  Shift costs → fitness for FPS: Fit = Max_C − Cost (+1 if flat).
      Max_C := Costs (1);
      for I in 2 .. P loop
         if Costs (I) > Max_C then
            Max_C := Costs (I);
         end if;
      end loop;
      for I in 1 .. P loop
         Fit (I) := Max_C - Costs (I);
      end loop;
      declare
         All_Zero : Boolean := True;
      begin
         for I in 1 .. P loop
            if Fit (I) > 0.0 then
               All_Zero := False;
               exit;
            end if;
         end loop;
         if All_Zero then
            for I in 1 .. P loop
               Fit (I) := 1.0;
            end loop;
         end if;
      end;

      if Cfg.Generations = 0 then
         return Pack (Best, N, Real (N) - Best_C, Best_C, 0, Evals);
      end if;

      for Gen in 1 .. Cfg.Generations loop
         pragma Unreferenced (Gen);

         if EC > 0 then
            declare
               Idx : constant Index_Array := Elite_Indices_Min (Costs, EC);
            begin
               for E in 1 .. EC loop
                  for B in 1 .. N loop
                     Next_P (E)(B) := Pop (Idx (E))(B);
                  end loop;
               end loop;
            end;
         end if;

         Slot := EC + 1;
         while Slot <= Natural (P) loop
            PA := Select_Parent_Min (State, Costs, Fit, Cfg);
            PB := Select_Parent_Min (State, Costs, Fit, Cfg);
            Child := Crossover
              (Copy_Bits (Pop (PA), N),
               Copy_Bits (Pop (PB), N),
               Cfg.Crossover,
               Cfg.Crossover_Rate,
               State);
            Child := Mutate_Bits (Child, Cfg.Mutation_Rate, State);
            for B in 1 .. N loop
               Next_P (Slot)(B) := Child (B);
            end loop;
            Slot := Slot + 1;
         end loop;

         Pop := Next_P;
         for I in 1 .. P loop
            Costs (I) := Eval_Cost (Copy_Bits (Pop (I), N));
            Evals     := Evals + 1;
            if Costs (I) < Best_C then
               Best_C := Costs (I);
               Best   := Copy_Bits (Pop (I), N);
            end if;
         end loop;

         Max_C := Costs (1);
         for I in 2 .. P loop
            if Costs (I) > Max_C then
               Max_C := Costs (I);
            end if;
         end loop;
         for I in 1 .. P loop
            Fit (I) := Max_C - Costs (I);
         end loop;
         declare
            All_Zero : Boolean := True;
         begin
            for I in 1 .. P loop
               if Fit (I) > 0.0 then
                  All_Zero := False;
                  exit;
               end if;
            end loop;
            if All_Zero then
               for I in 1 .. P loop
                  Fit (I) := 1.0;
               end loop;
            end if;
         end;
      end loop;

      return Pack
        (Best, N, Real (N) - Best_C, Best_C, Cfg.Generations, Evals);
   end Run_Minimize;

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   --  Closures need nested functions with matching access profiles.
   --  We bind via package-level helpers that capture target in a
   --  discriminant-free way: OneMax / Zero use N only; Hamming uses
   --  a module-level Target buffer for the duration of the call.

   Target_Buf : Bit_String (1 .. Max_Bits) := [others => False];
   Target_N   : Bit_Count := 1;

   function Eval_OneMax (Bits : Bit_String) return Real is
   begin
      return Fitness_OneMax (Bits);
   end Eval_OneMax;

   function Eval_Zero (Bits : Bit_String) return Real is
   begin
      return Cost_Zero_Count (Bits);
   end Eval_Zero;

   function Eval_Ham_Cost (Bits : Bit_String) return Real is
      T : constant Bit_String := Copy_Bits (Target_Buf, Target_N);
   begin
      return Cost_Hamming (Bits, T);
   end Eval_Ham_Cost;

   function Eval_Ham_Fit (Bits : Bit_String) return Real is
      T : constant Bit_String := Copy_Bits (Target_Buf, Target_N);
   begin
      return Fitness_Hamming (Bits, T);
   end Eval_Ham_Fit;

   function Maximize_OneMax
     (N : Bit_Count; Cfg : Config) return Result
   is
   begin
      return Run_Maximize (N, Cfg, Eval_OneMax'Access);
   end Maximize_OneMax;

   function Minimize_Zero_Count
     (N : Bit_Count; Cfg : Config) return Result
   is
   begin
      return Run_Minimize (N, Cfg, Eval_Zero'Access);
   end Minimize_Zero_Count;

   function Minimize_Hamming
     (Target : Bit_String; Cfg : Config) return Result
   is
      N : constant Bit_Count := Target'Length;
   begin
      if Target'Length < 1 or else Target'Length > Max_Bits then
         raise Invalid_Argument;
      end if;
      Target_N := N;
      for I in 1 .. N loop
         Target_Buf (I) := Target (Target'First + I - 1);
      end loop;
      return Run_Minimize (N, Cfg, Eval_Ham_Cost'Access);
   end Minimize_Hamming;

   function Maximize_Hamming_Fitness
     (Target : Bit_String; Cfg : Config) return Result
   is
      N : constant Bit_Count := Target'Length;
   begin
      if Target'Length < 1 or else Target'Length > Max_Bits then
         raise Invalid_Argument;
      end if;
      Target_N := N;
      for I in 1 .. N loop
         Target_Buf (I) := Target (Target'First + I - 1);
      end loop;
      return Run_Maximize (N, Cfg, Eval_Ham_Fit'Access);
   end Maximize_Hamming_Fitness;

end Genetic_Algorithms;
