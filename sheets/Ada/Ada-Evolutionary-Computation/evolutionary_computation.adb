--  Evolutionary_Computation — package body (survey sketches + helpers).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Evolutionary_Computation
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   --  Numerical Recipes LCG constants.
   Multiplier : constant RNG_State := 1_664_525;
   Increment  : constant RNG_State := 1_013_904_223;

   -------------------------------------------------------------------------
   -- Near / configs
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Default_GA_Config
     (Pop_Size       : Pop_Size_T        := 20;
      Generations    : Generation_Count  := 40;
      Crossover_Rate : Unit_Interval     := 0.8;
      Mutation_Rate  : Unit_Interval     := 0.05;
      Tournament_K   : Tourney_K         := 3;
      Elite_Count    : Elite_T           := 1;
      Seed           : Natural           := 1) return GA_Config
   is
   begin
      return
        (Pop_Size       => Pop_Size,
         Generations    => Generations,
         Crossover_Rate => Crossover_Rate,
         Mutation_Rate  => Mutation_Rate,
         Tournament_K   => Tournament_K,
         Elite_Count    => Elite_Count,
         Seed           => Seed);
   end Default_GA_Config;

   function Default_ES_Config
     (Max_Gens       : Generation_Count := 200;
      Seed           : Natural          := 1;
      Init_Sigma     : Positive_Real    := 1.0;
      Success_Window : Positive         := 10) return ES_Config
   is
   begin
      return
        (Max_Gens       => Max_Gens,
         Seed           => Seed,
         Init_Sigma     => Init_Sigma,
         Success_Window => Success_Window);
   end Default_ES_Config;

   function GA_Config_Is_Valid (Cfg : GA_Config) return Boolean is
   begin
      return Natural (Cfg.Tournament_K) <= Natural (Cfg.Pop_Size)
        and then Natural (Cfg.Elite_Count) < Natural (Cfg.Pop_Size);
   end GA_Config_Is_Valid;

   -------------------------------------------------------------------------
   -- RNG
   -------------------------------------------------------------------------

   procedure Seed_RNG (State : out RNG_State; Seed : Natural) is
   begin
      if Seed = 0 then
         State := 1;
      else
         State := RNG_State (Seed);
      end if;
   end Seed_RNG;

   function Next_Unit (State : in out RNG_State) return Unit_Interval is
   begin
      State := State * Multiplier + Increment;
      return Unit_Interval (Real (State) / Real (RNG_State'Last));
   end Next_Unit;

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
   is
      Span : constant Natural := Hi - Lo;
      U    : Unit_Interval;
      K    : Natural;
   begin
      if Span = 0 then
         return Lo;
      end if;
      U := Next_Unit (State);
      K := Natural (Real (U) * Real (Span + 1));
      if K > Span then
         K := Span;
      end if;
      return Lo + K;
   end Next_Natural;

   function Sample_Normal (State : in out RNG_State) return Real is
      U, V, S : Real;
   begin
      loop
         U := 2.0 * Real (Next_Unit (State)) - 1.0;
         V := 2.0 * Real (Next_Unit (State)) - 1.0;
         S := U * U + V * V;
         exit when S > 0.0 and then S < 1.0;
      end loop;
      return U * Math.Sqrt (-2.0 * Math.Log (S) / S);
   end Sample_Normal;

   -------------------------------------------------------------------------
   -- Bit utilities
   -------------------------------------------------------------------------

   function Ones_Count (Bits : Bit_String) return Natural is
      C : Natural := 0;
   begin
      for I in Bits'Range loop
         if Bits (I) then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Ones_Count;

   function Hamming_Distance (A, B : Bit_String) return Natural is
      C : Natural := 0;
      J : Positive := B'First;
   begin
      for I in A'Range loop
         if A (I) /= B (J) then
            C := C + 1;
         end if;
         J := J + 1;
      end loop;
      return C;
   end Hamming_Distance;

   function Random_Bit_String
     (State : in out RNG_State; N : Bit_Count) return Bit_String
   is
      Result : Bit_String (1 .. N);
   begin
      for I in Result'Range loop
         Result (I) := Next_Unit (State) < 0.5;
      end loop;
      return Result;
   end Random_Bit_String;

   function Flip_Bit (Bits : Bit_String; Index : Positive) return Bit_String is
      Result : Bit_String := Bits;
   begin
      Result (Index) := not Result (Index);
      return Result;
   end Flip_Bit;

   function Copy_Bits (Src : Bit_String; N : Bit_Count) return Bit_String is
      Result : Bit_String (1 .. N);
      J      : Positive := Src'First;
   begin
      for I in 1 .. N loop
         Result (I) := Src (J);
         J := J + 1;
      end loop;
      return Result;
   end Copy_Bits;

   function All_Ones (N : Bit_Count) return Bit_String is
      Result : constant Bit_String (1 .. N) := [others => True];
   begin
      return Result;
   end All_Ones;

   function All_Zeros (N : Bit_Count) return Bit_String is
      Result : constant Bit_String (1 .. N) := [others => False];
   begin
      return Result;
   end All_Zeros;

   -------------------------------------------------------------------------
   -- Shared EA-loop helpers
   -------------------------------------------------------------------------

   procedure Init_Bit_Population
     (Pop   : in out Bit_Population;
      N     : Bit_Count;
      State : in out RNG_State)
   is
      Bits : Bit_String (1 .. N);
   begin
      for I in Pop'Range loop
         Bits := Random_Bit_String (State, N);
         Pop (I).N := N;
         Pop (I).Bits := [others => False];
         for J in 1 .. N loop
            Pop (I).Bits (J) := Bits (J);
         end loop;
         Pop (I).Fitness := Real (Ones_Count (Bits));
      end loop;
   end Init_Bit_Population;

   function Mean_Fitness (Fit : Fitness_Array) return Real is
      Sum : Real := 0.0;
   begin
      for I in Fit'Range loop
         Sum := Sum + Fit (I);
      end loop;
      return Sum / Real (Fit'Length);
   end Mean_Fitness;

   function Best_Index_Max (Fit : Fitness_Array) return Positive is
      Best : Positive := Fit'First;
   begin
      for I in Fit'Range loop
         if Fit (I) > Fit (Best) then
            Best := I;
         end if;
      end loop;
      return Best;
   end Best_Index_Max;

   function Best_Index_Min (Fit : Fitness_Array) return Positive is
      Best : Positive := Fit'First;
   begin
      for I in Fit'Range loop
         if Fit (I) < Fit (Best) then
            Best := I;
         end if;
      end loop;
      return Best;
   end Best_Index_Min;

   function Elitist_Merge_Max
     (Parents, Offspring : Fitness_Array;
      Elite              : Natural) return Fitness_Array
   is
      N      : constant Positive := Parents'Length;
      Result : Fitness_Array (1 .. N);
      --  Collect parent indices sorted by fitness descending (simple
      --  selection sort of indices).
      Idx    : array (1 .. N) of Positive;
      Tmp    : Positive;
      Used   : array (1 .. N) of Boolean := [others => False];
      Off_I  : Positive;
      Fill   : Positive;
   begin
      for I in 1 .. N loop
         Idx (I) := Parents'First + (I - 1);
      end loop;
      for I in 1 .. N - 1 loop
         for J in I + 1 .. N loop
            if Parents (Idx (J)) > Parents (Idx (I)) then
               Tmp := Idx (I);
               Idx (I) := Idx (J);
               Idx (J) := Tmp;
            end if;
         end loop;
      end loop;

      for I in 1 .. Elite loop
         Result (I) := Parents (Idx (I));
      end loop;

      --  Fill remaining slots from offspring in order, preferring better.
      declare
         Off_Idx : array (1 .. N) of Positive;
      begin
         for I in 1 .. N loop
            Off_Idx (I) := Offspring'First + (I - 1);
         end loop;
         for I in 1 .. N - 1 loop
            for J in I + 1 .. N loop
               if Offspring (Off_Idx (J)) > Offspring (Off_Idx (I)) then
                  Tmp := Off_Idx (I);
                  Off_Idx (I) := Off_Idx (J);
                  Off_Idx (J) := Tmp;
               end if;
            end loop;
         end loop;
         Fill := Elite + 1;
         Off_I := 1;
         while Fill <= N loop
            Result (Fill) := Offspring (Off_Idx (Off_I));
            Fill := Fill + 1;
            Off_I := Off_I + 1;
         end loop;
      end;
      pragma Unreferenced (Used);
      return Result;
   end Elitist_Merge_Max;

   function Advance_Generation
     (G : Generation_Count; Steps : Natural := 1) return Generation_Count
   is
      Sum : constant Natural := Natural (G) + Steps;
   begin
      if Sum >= Max_Gens then
         return Generation_Count (Max_Gens);
      else
         return Generation_Count (Sum);
      end if;
   end Advance_Generation;

   function Generation_Budget_Exhausted
     (G : Generation_Count; Budget : Generation_Count) return Boolean
   is
   begin
      return G >= Budget;
   end Generation_Budget_Exhausted;

   -------------------------------------------------------------------------
   -- Selection pressure / diversity
   -------------------------------------------------------------------------

   function Selection_Pressure_Ratio (Fit : Fitness_Array) return Non_Negative
   is
      Mean : constant Real := Mean_Fitness (Fit);
      Best : constant Real := Fit (Best_Index_Max (Fit));
   begin
      if Mean <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Best / Mean);
   end Selection_Pressure_Ratio;

   function Mean_Pairwise_Hamming
     (Pop : Bit_Population; N : Bit_Count) return Non_Negative
   is
      Sum   : Real := 0.0;
      Pairs : Natural := 0;
      A, B  : Bit_String (1 .. N);
   begin
      for I in Pop'Range loop
         for J in I + 1 .. Pop'Last loop
            for K in 1 .. N loop
               A (K) := Pop (I).Bits (K);
               B (K) := Pop (J).Bits (K);
            end loop;
            Sum := Sum + Real (Hamming_Distance (A, B));
            Pairs := Pairs + 1;
         end loop;
      end loop;
      if Pairs = 0 then
         return 0.0;
      end if;
      return Non_Negative (Sum / Real (Pairs));
   end Mean_Pairwise_Hamming;

   function Normalised_Diversity
     (Pop : Bit_Population; N : Bit_Count) return Unit_Interval
   is
      Mean_H : constant Non_Negative := Mean_Pairwise_Hamming (Pop, N);
   begin
      return Unit_Interval (Real (Mean_H) / Real (N));
   end Normalised_Diversity;

   -------------------------------------------------------------------------
   -- Bit GA sketch
   -------------------------------------------------------------------------

   function Bit_Flip_Mutate
     (Bits  : Bit_String;
      Rate  : Unit_Interval;
      State : in out RNG_State) return Bit_String
   is
      Result : Bit_String := Bits;
   begin
      for I in Result'Range loop
         if Next_Unit (State) < Rate then
            Result (I) := not Result (I);
         end if;
      end loop;
      return Result;
   end Bit_Flip_Mutate;

   procedure One_Point_Crossover
     (A, B     : Bit_String;
      Child_A  : out Bit_String;
      Child_B  : out Bit_String;
      State    : in out RNG_State)
   is
      N    : constant Positive := A'Length;
      Cut  : Positive;
      IA   : Positive := A'First;
      IB   : Positive := B'First;
      CA   : Positive := Child_A'First;
      CB   : Positive := Child_B'First;
   begin
      if N = 1 then
         Child_A (Child_A'First) := A (A'First);
         Child_B (Child_B'First) := B (B'First);
         return;
      end if;
      Cut := Next_Natural (State, 1, N - 1);
      for K in 1 .. N loop
         if K <= Cut then
            Child_A (CA) := A (IA);
            Child_B (CB) := B (IB);
         else
            Child_A (CA) := B (IB);
            Child_B (CB) := A (IA);
         end if;
         IA := IA + 1;
         IB := IB + 1;
         CA := CA + 1;
         CB := CB + 1;
      end loop;
   end One_Point_Crossover;

   function Tournament_Select
     (Fit   : Fitness_Array;
      K     : Tourney_K;
      State : in out RNG_State) return Positive
   is
      Best : Positive :=
        Fit'First + Next_Natural (State, 0, Fit'Length - 1);
      Cand : Positive;
   begin
      for T in 2 .. Natural (K) loop
         Cand := Fit'First + Next_Natural (State, 0, Fit'Length - 1);
         if Fit (Cand) > Fit (Best) then
            Best := Cand;
         end if;
      end loop;
      return Best;
   end Tournament_Select;

   procedure Make_Offspring
     (Pop   : Bit_Population;
      Fit   : Fitness_Array;
      N     : Bit_Count;
      Cfg   : GA_Config;
      State : in out RNG_State;
      Child : out Bit_Individual;
      Evals : in out Natural)
   is
      FA : constant Positive :=
        Tournament_Select (Fit, Cfg.Tournament_K, State);
      FB : constant Positive :=
        Tournament_Select (Fit, Cfg.Tournament_K, State);
      IA : constant Positive := Pop'First + (FA - Fit'First);
      IB : constant Positive := Pop'First + (FB - Fit'First);
      PA : constant Bit_String := Copy_Bits (Pop (IA).Bits, N);
      PB : constant Bit_String := Copy_Bits (Pop (IB).Bits, N);
      CA : Bit_String (1 .. N);
      CB : Bit_String (1 .. N);
      Bits : Bit_String (1 .. N);
   begin
      if Next_Unit (State) < Cfg.Crossover_Rate then
         One_Point_Crossover (PA, PB, CA, CB, State);
         Bits := CA;
      else
         Bits := PA;
      end if;
      Bits := Bit_Flip_Mutate (Bits, Cfg.Mutation_Rate, State);
      Child.N := N;
      Child.Bits := [others => False];
      for J in 1 .. N loop
         Child.Bits (J) := Bits (J);
      end loop;
      Child.Fitness := Real (Ones_Count (Bits));
      Evals := Evals + 1;
      pragma Unreferenced (CB);
   end Make_Offspring;

   procedure Step_Bit_GA
     (Pop   : in out Bit_Population;
      Cfg   : GA_Config;
      State : in out RNG_State;
      Evals : in out Natural)
   is
      P         : constant Positive := Pop'Length;
      N         : constant Bit_Count := Pop (Pop'First).N;
      Fit       : Fitness_Array (1 .. P);
      Next_Pop  : Bit_Population (1 .. P);
      Elite_Idx : array (1 .. P) of Positive;
      Tmp       : Positive;
      Filled    : Natural := 0;
   begin
      for I in 1 .. P loop
         Fit (I) := Pop (Pop'First + (I - 1)).Fitness;
         Elite_Idx (I) := Pop'First + (I - 1);
      end loop;

      --  Rank population indices by fitness descending for elitism.
      for I in 1 .. P - 1 loop
         for J in I + 1 .. P loop
            if Pop (Elite_Idx (J)).Fitness > Pop (Elite_Idx (I)).Fitness then
               Tmp := Elite_Idx (I);
               Elite_Idx (I) := Elite_Idx (J);
               Elite_Idx (J) := Tmp;
            end if;
         end loop;
      end loop;

      for E in 1 .. Natural (Cfg.Elite_Count) loop
         Filled := Filled + 1;
         Next_Pop (Filled) := Pop (Elite_Idx (E));
      end loop;

      while Filled < P loop
         Filled := Filled + 1;
         Make_Offspring
           (Pop, Fit, N, Cfg, State, Next_Pop (Filled), Evals);
      end loop;

      Pop := Next_Pop;
   end Step_Bit_GA;

   function Maximize_OneMax
     (N   : Bit_Count;
      Cfg : GA_Config) return GA_Result
   is
      Pop   : Bit_Population (1 .. Natural (Cfg.Pop_Size));
      State : RNG_State;
      Evals : Natural := 0;
      G     : Generation_Count := 0;
      R     : GA_Result;
      Best  : Positive;
   begin
      Seed_RNG (State, Cfg.Seed);
      Init_Bit_Population (Pop, N, State);
      Evals := Evals + Natural (Cfg.Pop_Size);

      while not Generation_Budget_Exhausted (G, Cfg.Generations) loop
         Step_Bit_GA (Pop, Cfg, State, Evals);
         G := Advance_Generation (G);
      end loop;

      Best := Pop'First;
      for I in Pop'Range loop
         if Pop (I).Fitness > Pop (Best).Fitness then
            Best := I;
         end if;
      end loop;

      R.N := N;
      R.Best_Fitness := Pop (Best).Fitness;
      R.Generations_Run := G;
      R.Evaluations := Evals;
      R.Best_Bits := [others => False];
      for J in 1 .. N loop
         R.Best_Bits (J) := Pop (Best).Bits (J);
      end loop;
      return R;
   end Maximize_OneMax;

   -------------------------------------------------------------------------
   -- (1+1)-ES sketch
   -------------------------------------------------------------------------

   function Sphere (X : Point) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * X (I);
      end loop;
      return S;
   end Sphere;

   function Mutate_Gaussian
     (Parent : Cont_Individual;
      State  : in out RNG_State) return Cont_Individual
   is
      Child : Cont_Individual := Parent;
   begin
      for I in 1 .. Parent.Dim loop
         Child.X (I) := Parent.X (I)
           + Real (Parent.Sigma) * Sample_Normal (State);
      end loop;
      return Child;
   end Mutate_Gaussian;

   procedure Step_One_Plus_One_ES
     (Parent         : in out Cont_Individual;
      Objective      : Objective_Fn;
      State          : in out RNG_State;
      Successes      : in out Natural;
      Trials         : in out Natural;
      Success_Window : Positive;
      Evaluations    : in out Natural)
   is
      Child  : Cont_Individual;
      Cost   : Real;
      Rate   : Real;
      Factor : constant Real := 0.817;  -- ≈ e^{-1/4} classic 1/5 factor
   begin
      Child := Mutate_Gaussian (Parent, State);
      declare
         Slice : constant Point := Child.X (1 .. Child.Dim);
      begin
         Cost := Objective (Slice);
      end;
      Evaluations := Evaluations + 1;
      Trials := Trials + 1;
      Child.Fitness := Cost;

      if Cost <= Parent.Fitness then
         Parent := Child;
         Successes := Successes + 1;
      end if;

      if Trials >= Success_Window then
         Rate := Real (Successes) / Real (Trials);
         if Rate > 0.2 then
            Parent.Sigma :=
              Positive_Real (Real (Parent.Sigma) / Factor);
         elsif Rate < 0.2 then
            Parent.Sigma :=
              Positive_Real (Real (Parent.Sigma) * Factor);
         end if;
         --  Keep σ away from underflow.
         if Real (Parent.Sigma) < 1.0E-12 then
            Parent.Sigma := 1.0E-12;
         end if;
         Successes := 0;
         Trials := 0;
      end if;
   end Step_One_Plus_One_ES;

   function Minimize_Sphere_One_Plus_One
     (Dim : Dim_Count;
      Cfg : ES_Config) return ES_Result
   is
      Parent     : Cont_Individual;
      State      : RNG_State;
      Successes  : Natural := 0;
      Trials     : Natural := 0;
      Evals      : Natural := 0;
      G          : Generation_Count := 0;
      R          : ES_Result;
      Obj        : constant Objective_Fn := Sphere'Access;
   begin
      Seed_RNG (State, Cfg.Seed);
      Parent.Dim := Dim;
      Parent.Sigma := Cfg.Init_Sigma;
      for I in 1 .. Dim loop
         Parent.X (I) := 2.0 * Real (Next_Unit (State)) - 1.0;
      end loop;
      Parent.Fitness := Sphere (Parent.X (1 .. Dim));
      Evals := 1;

      while not Generation_Budget_Exhausted (G, Cfg.Max_Gens) loop
         Step_One_Plus_One_ES
           (Parent, Obj, State, Successes, Trials,
            Cfg.Success_Window, Evals);
         G := Advance_Generation (G);
      end loop;

      R.Dim := Dim;
      R.Best_Cost := Parent.Fitness;
      R.Best_Sigma := Real (Parent.Sigma);
      R.Generations := G;
      R.Evaluations := Evals;
      R.Best_X := [others => 0.0];
      for I in 1 .. Dim loop
         R.Best_X (I) := Parent.X (I);
      end loop;
      return R;
   end Minimize_Sphere_One_Plus_One;

   -------------------------------------------------------------------------
   -- Taxonomy
   -------------------------------------------------------------------------

   function Classify_Method (Kind : Method_Kind) return Method_Info is
   begin
      case Kind is
         when Genetic_Algorithm =>
            return
              (Kind               => Genetic_Algorithm,
               Implemented        => True,
               Uses_Recombination => True,
               Forthcoming        => False,
               Population_Based   => True);
         when Evolution_Strategy =>
            return
              (Kind               => Evolution_Strategy,
               Implemented        => True,
               Uses_Recombination => False,  -- (1+1) sketch has no crossover
               Forthcoming        => False,
               Population_Based   => True);
         when Gene_Expression =>
            return
              (Kind               => Gene_Expression,
               Implemented        => False,
               Uses_Recombination => True,
               Forthcoming        => False,
               Population_Based   => True);
         when Differential_Evolution =>
            return
              (Kind               => Differential_Evolution,
               Implemented        => False,
               Uses_Recombination => True,
               Forthcoming        => True,
               Population_Based   => True);
         when Memetic =>
            return
              (Kind               => Memetic,
               Implemented        => False,
               Uses_Recombination => True,
               Forthcoming        => False,
               Population_Based   => True);
         when Genetic_Programming =>
            return
              (Kind               => Genetic_Programming,
               Implemented        => False,
               Uses_Recombination => True,
               Forthcoming        => True,
               Population_Based   => True);
      end case;
   end Classify_Method;

   function Method_Name (Kind : Method_Kind) return String is
   begin
      case Kind is
         when Genetic_Algorithm =>
            return "Genetic Algorithm";
         when Evolution_Strategy =>
            return "Evolution Strategy";
         when Gene_Expression =>
            return "Gene Expression Programming";
         when Differential_Evolution =>
            return "Differential Evolution";
         when Memetic =>
            return "Memetic Algorithm";
         when Genetic_Programming =>
            return "Genetic Programming";
      end case;
   end Method_Name;

   function Uses_Recombination (Kind : Method_Kind) return Boolean is
   begin
      return Classify_Method (Kind).Uses_Recombination;
   end Uses_Recombination;

   function Method_Implemented (Kind : Method_Kind) return Boolean is
   begin
      return Classify_Method (Kind).Implemented;
   end Method_Implemented;

   function Method_Forthcoming (Kind : Method_Kind) return Boolean is
   begin
      return Classify_Method (Kind).Forthcoming;
   end Method_Forthcoming;

   function Method_Count return Positive is
   begin
      return Method_Kind'Pos (Method_Kind'Last)
        - Method_Kind'Pos (Method_Kind'First) + 1;
   end Method_Count;

end Evolutionary_Computation;
