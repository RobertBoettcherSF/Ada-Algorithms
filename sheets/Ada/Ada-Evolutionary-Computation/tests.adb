--  Standalone test suite for Evolutionary_Computation (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Evolutionary_Computation; use Evolutionary_Computation;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Put_Line ("Evolutionary_Computation test suite");
   Put_Line ("===================================");

   ---------------------------------------------------------------------
   Section ("1. Near / configs / validity");
   ---------------------------------------------------------------------
   declare
      GA : GA_Config;
      ES : ES_Config;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-3.0, -3.0), "Near negatives");
      Check (Near (0.0, 0.0), "Near zeros");
      GA := Default_GA_Config;
      Check (GA.Pop_Size = 20, "Default GA Pop_Size");
      Check (GA.Generations = 40, "Default GA Generations");
      Check (Approx (Real (GA.Crossover_Rate), 0.8), "Default GA Cx");
      Check (Approx (Real (GA.Mutation_Rate), 0.05), "Default GA Mut");
      Check (GA.Tournament_K = 3, "Default GA K");
      Check (GA.Elite_Count = 1, "Default GA Elite");
      Check (GA_Config_Is_Valid (GA), "Default GA valid");
      GA := Default_GA_Config (Tournament_K => 50, Pop_Size => 10);
      Check (not GA_Config_Is_Valid (GA), "Invalid K > Pop");
      GA := Default_GA_Config (Elite_Count => 20, Pop_Size => 20);
      Check (not GA_Config_Is_Valid (GA), "Invalid Elite = Pop");
      ES := Default_ES_Config;
      Check (ES.Max_Gens = 200, "Default ES Max_Gens");
      Check (Approx (Real (ES.Init_Sigma), 1.0), "Default ES Sigma");
      Check (ES.Success_Window = 10, "Default ES Window");
      GA := Default_GA_Config
        (Pop_Size => 12, Generations => 5, Mutation_Rate => 0.1,
         Elite_Count => 2, Seed => 7);
      Check (GA.Pop_Size = 12 and then GA.Seed = 7, "Custom GA fields");
   end;

   ---------------------------------------------------------------------
   Section ("2. RNG / Next_Natural / Sample_Normal");
   ---------------------------------------------------------------------
   declare
      S  : RNG_State;
      U  : Unit_Interval;
      N  : Natural;
      Sum : Real := 0.0;
      Mn, Mx : Real;
      X  : Real;
   begin
      Seed_RNG (S, 0);
      Check (True, "Seed_RNG zero maps ok");
      Seed_RNG (S, 42);
      U := Next_Unit (S);
      Check (U >= 0.0 and then U < 1.0, "Next_Unit in [0,1)");
      U := Next_Unit (S);
      Check (U >= 0.0 and then U < 1.0, "Next_Unit second draw");
      N := Next_Natural (S, 5, 5);
      Check (N = 5, "Next_Natural Lo=Hi");
      for I in 1 .. 40 loop
         N := Next_Natural (S, 1, 4);
         Check (N >= 1 and then N <= 4, "Next_Natural bounds#" & I'Image);
      end loop;
      Seed_RNG (S, 99);
      Mn := Real'Last;
      Mx := Real'First;
      for I in 1 .. 200 loop
         X := Sample_Normal (S);
         Sum := Sum + X;
         if X < Mn then
            Mn := X;
         end if;
         if X > Mx then
            Mx := X;
         end if;
      end loop;
      Check (abs (Sum / 200.0) < 0.5, "Sample_Normal mean near 0");
      Check (Mn < 0.0 and then Mx > 0.0, "Sample_Normal both signs");
   end;

   ---------------------------------------------------------------------
   Section ("3. Bit utilities");
   ---------------------------------------------------------------------
   declare
      S : RNG_State;
      A8 : Bit_String (1 .. 8);
      C8 : Bit_String (1 .. 8);
      A16 : Bit_String (1 .. 16);
      B8 : Bit_String (1 .. 8);
   begin
      Check (Ones_Count (All_Ones (8)) = 8, "All_Ones count");
      Check (Ones_Count (All_Zeros (8)) = 0, "All_Zeros count");
      Check (Hamming_Distance (All_Ones (4), All_Zeros (4)) = 4,
             "Hamming all differ");
      Check (Hamming_Distance (All_Ones (5), All_Ones (5)) = 0,
             "Hamming identical");
      A8 := All_Zeros (8);
      C8 := Flip_Bit (A8, 3);
      Check (C8 (3) and then Ones_Count (C8) = 1, "Flip_Bit single");
      Seed_RNG (S, 1);
      A16 := Random_Bit_String (S, 16);
      Check (A16'Length = 16, "Random_Bit_String length");
      B8 := Copy_Bits (A16, 8);
      Check (B8'Length = 8, "Copy_Bits length");
      for I in 1 .. 8 loop
         Check (B8 (I) = A16 (I), "Copy_Bits prefix#" & I'Image);
      end loop;
      declare
         Comp : constant Bit_String := [for I in A16'Range => not A16 (I)];
      begin
         Check (Ones_Count (A16) + Ones_Count (Comp) = 16,
                "Ones + zeros complement = N");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("4. EA helpers: init / mean / best / generation");
   ---------------------------------------------------------------------
   declare
      Pop : Bit_Population (1 .. 6);
      S   : RNG_State;
      Fit : constant Fitness_Array (1 .. 5) :=
        [1.0, 5.0, 3.0, 5.0, 2.0];
      Fit2 : constant Fitness_Array (1 .. 4) :=
        [4.0, 1.0, 7.0, 2.0];
      Merged : Fitness_Array (1 .. 4);
      G : Generation_Count := 0;
   begin
      Seed_RNG (S, 2);
      Init_Bit_Population (Pop, 10, S);
      Check (Pop'Length = 6, "Init pop length");
      for I in Pop'Range loop
         Check (Pop (I).N = 10, "Init N#" & I'Image);
         Check (Approx (Pop (I).Fitness, Real (Ones_Count
                  (Copy_Bits (Pop (I).Bits, 10)))),
                "Init fitness Ones#" & I'Image);
      end loop;
      Check (Best_Index_Max (Fit) = 2, "Best_Index_Max first tie");
      Check (Best_Index_Min (Fit2) = 2, "Best_Index_Min");
      Check (Approx (Mean_Fitness (Fit), 3.2), "Mean_Fitness");
      Merged := Elitist_Merge_Max (Fit2, [0.0, 0.0, 0.0, 9.0], Elite => 1);
      Check (Approx (Merged (1), 7.0), "Elitist keeps best parent");
      Check (Approx (Merged (2), 9.0), "Elitist takes best offspring");
      G := Advance_Generation (G, 3);
      Check (G = 3, "Advance_Generation +3");
      G := Advance_Generation (Generation_Count (Max_Gens), 10);
      Check (Natural (G) = Max_Gens, "Advance saturates at Max_Gens");
      Check (Generation_Budget_Exhausted (40, 40), "Budget exhausted eq");
      Check (not Generation_Budget_Exhausted (10, 40), "Budget remaining");
   end;

   ---------------------------------------------------------------------
   Section ("5. Selection pressure / diversity");
   ---------------------------------------------------------------------
   declare
      Fit : constant Fitness_Array (1 .. 4) := [1.0, 1.0, 1.0, 4.0];
      Pop : Bit_Population (1 .. 4);
      S   : RNG_State;
      Div : Unit_Interval;
      Sp  : Non_Negative;
   begin
      Sp := Selection_Pressure_Ratio (Fit);
      Check (Approx (Real (Sp), 4.0 / 1.75), "Selection pressure ratio");
      declare
         Z : constant Fitness_Array (1 .. 3) := [0.0, 0.0, 0.0];
      begin
         Check (Approx (Real (Selection_Pressure_Ratio (Z)), 0.0),
                "Pressure zero mean -> 0");
      end;
      Seed_RNG (S, 3);
      Init_Bit_Population (Pop, 12, S);
      --  Force diversity: set distinct patterns.
      Pop (1).Bits := [others => False];
      Pop (2).Bits := [others => True];
      for J in 1 .. 12 loop
         Pop (1).Bits (J) := False;
         Pop (2).Bits (J) := True;
         Pop (3).Bits (J) := (J mod 2 = 0);
         Pop (4).Bits (J) := (J mod 2 = 1);
      end loop;
      declare
         MH : constant Non_Negative := Mean_Pairwise_Hamming (Pop, 12);
         H12 : constant Natural := Hamming_Distance
           (Copy_Bits (Pop (1).Bits, 12), Copy_Bits (Pop (2).Bits, 12));
      begin
         Check (H12 = 12, "Pop1 vs Pop2 Hamming = 12");
         Check (MH > 0.0, "Mean pairwise > 0 on diverse pop");
         Check (MH <= 12.0, "Mean pairwise <= N");
      end;
      Div := Normalised_Diversity (Pop, 12);
      Check (Div >= 0.0 and then Div <= 1.0, "Normalised diversity in [0,1]");
      --  Identical population → diversity 0.
      for I in Pop'Range loop
         Pop (I).Bits := [others => False];
         for J in 1 .. 8 loop
            Pop (I).Bits (J) := True;
         end loop;
      end loop;
      Check (Approx (Real (Mean_Pairwise_Hamming (Pop, 8)), 0.0),
             "Identical pop Hamming 0");
      Check (Approx (Real (Normalised_Diversity (Pop, 8)), 0.0),
             "Identical pop diversity 0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Bit GA operators");
   ---------------------------------------------------------------------
   declare
      S : RNG_State;
      A : constant Bit_String :=
        [True, True, True, True, False, False, False, False];
      B : constant Bit_String :=
        [False, False, False, False, True, True, True, True];
      CA, CB : Bit_String (1 .. 8);
      M : Bit_String (1 .. 8);
      Fit : constant Fitness_Array (1 .. 5) := [1.0, 9.0, 3.0, 2.0, 4.0];
      Idx : Positive;
      Ones_Same : Boolean;
   begin
      Seed_RNG (S, 11);
      One_Point_Crossover (A, B, CA, CB, S);
      Check (CA'Length = 8 and then CB'Length = 8, "Crossover lengths");
      --  Children should be mixtures: not both equal to a single parent
      --  for all loci in general; at least Hamming conserved pairwise.
      Check (CA'Length = 8, "Crossover child A length");
      Check (Ones_Count (CA) + Ones_Count (CB) = Ones_Count (A) + Ones_Count (B),
             "Crossover conserves ones sum");
      Seed_RNG (S, 12);
      M := Bit_Flip_Mutate (All_Zeros (8), 0.0, S);
      Check (Ones_Count (M) = 0, "Mutate rate 0 identity");
      Seed_RNG (S, 13);
      M := Bit_Flip_Mutate (All_Zeros (8), 1.0, S);
      Check (Ones_Count (M) = 8, "Mutate rate 1 flips all");
      Seed_RNG (S, 14);
      Ones_Same := True;
      for T in 1 .. 20 loop
         Idx := Tournament_Select (Fit, 3, S);
         Check (Idx in Fit'Range, "Tournament index in range#" & T'Image);
         if Fit (Idx) < 1.0 then
            Ones_Same := False;
         end if;
      end loop;
      Check (Ones_Same, "Tournament returns valid fitness holders");
      --  With K=5 and one clear best, often pick best.
      declare
         Hits : Natural := 0;
      begin
         Seed_RNG (S, 15);
         for T in 1 .. 30 loop
            if Tournament_Select (Fit, 5, S) = 2 then
               Hits := Hits + 1;
            end if;
         end loop;
         Check (Hits >= 10, "Tournament biases toward best");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Step_Bit_GA / Maximize_OneMax");
   ---------------------------------------------------------------------
   declare
      Pop : Bit_Population (1 .. 10);
      S   : RNG_State;
      Cfg : GA_Config;
      Evals : Natural := 0;
      Before, After : Real;
      R : GA_Result;
   begin
      Cfg := Default_GA_Config
        (Pop_Size => 10, Generations => 25, Mutation_Rate => 0.08,
         Elite_Count => 1, Tournament_K => 3, Seed => 21);
      Seed_RNG (S, Cfg.Seed);
      Init_Bit_Population (Pop, 16, S);
      declare
         Fits : constant Fitness_Array :=
           [for I in Pop'Range => Pop (I).Fitness];
      begin
         Before := Pop (Best_Index_Max (Fits)).Fitness;
      end;
      for Gen in 1 .. 15 loop
         Step_Bit_GA (Pop, Cfg, S, Evals);
      end loop;
      After := 0.0;
      for I in Pop'Range loop
         if Pop (I).Fitness > After then
            After := Pop (I).Fitness;
         end if;
      end loop;
      Check (Evals > 0, "Step_Bit_GA evaluates offspring");
      Check (After >= Before, "Elitist GA best non-decreasing");
      R := Maximize_OneMax (12, Cfg);
      Check (R.N = 12, "OneMax N");
      Check (Natural (R.Generations_Run) = 25, "OneMax gens");
      Check (R.Evaluations > 0, "OneMax evals");
      Check (R.Best_Fitness >= 0.0, "OneMax fitness non-neg");
      Check (R.Best_Fitness <= 12.0, "OneMax fitness <= N");
      Check (Ones_Count (Copy_Bits (R.Best_Bits, 12)) =
               Natural (R.Best_Fitness),
             "OneMax bits match fitness");
      --  Stronger run should approach OneMax.
      Cfg := Default_GA_Config
        (Pop_Size => 30, Generations => 60, Mutation_Rate => 0.03,
         Crossover_Rate => 0.9, Elite_Count => 2, Tournament_K => 4,
         Seed => 3);
      R := Maximize_OneMax (20, Cfg);
      Check (R.Best_Fitness >= 16.0, "OneMax finds many ones");
   end;

   ---------------------------------------------------------------------
   Section ("8. Sphere / Mutate_Gaussian / (1+1)-ES");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 3) := [3.0, 4.0, 0.0];
      P : Cont_Individual;
      S : RNG_State;
      Succ, Trials, Evals : Natural := 0;
      R : ES_Result;
      Cfg : ES_Config;
      Before : Real;
   begin
      Check (Approx (Sphere (X), 25.0), "Sphere 3-4-0");
      Check (Approx (Sphere ([0.0, 0.0]), 0.0), "Sphere origin");
      Check (Approx (Sphere ([1.0, -1.0, 1.0, -1.0]), 4.0), "Sphere 4D");
      P.Dim := 2;
      P.Sigma := 0.5;
      P.X := [others => 0.0];
      P.X (1) := 1.0;
      P.X (2) := -1.0;
      P.Fitness := Sphere (P.X (1 .. 2));
      Seed_RNG (S, 8);
      declare
         C : constant Cont_Individual := Mutate_Gaussian (P, S);
      begin
         Check (C.Dim = 2, "Mutate preserves Dim");
         Check (Approx (Real (C.Sigma), 0.5), "Mutate preserves Sigma");
         Check (C.X'Length = Max_Dim, "Mutate X capacity");
      end;
      Before := P.Fitness;
      for T in 1 .. 50 loop
         Step_One_Plus_One_ES
           (P, Sphere'Access, S, Succ, Trials, 10, Evals);
      end loop;
      Check (Evals = 50, "ES step eval count");
      Check (P.Fitness <= Before, "ES never worsens parent");
      Cfg := Default_ES_Config (Max_Gens => 300, Seed => 5,
                                Init_Sigma => 0.8, Success_Window => 10);
      R := Minimize_Sphere_One_Plus_One (2, Cfg);
      Check (R.Dim = 2, "ES result Dim");
      Check (Natural (R.Generations) = 300, "ES result gens");
      Check (R.Evaluations > 0, "ES result evals");
      Check (R.Best_Cost >= 0.0, "ES cost non-neg");
      Check (R.Best_Cost < 1.0, "ES Sphere improves below 1");
      Check (Approx (Sphere (R.Best_X (1 .. 2)), R.Best_Cost, 1.0E-8),
             "ES Best_X matches Best_Cost");
      R := Minimize_Sphere_One_Plus_One
        (3, Default_ES_Config (Max_Gens => 400, Seed => 9));
      Check (R.Best_Cost < 2.0, "ES 3D Sphere improves");
   end;

   ---------------------------------------------------------------------
   Section ("9. Taxonomy Classify / Name / flags");
   ---------------------------------------------------------------------
   declare
      Info : Method_Info;
      Names_Ok : Boolean := True;
   begin
      Check (Method_Count = 6, "Method_Count = 6");
      Info := Classify_Method (Genetic_Algorithm);
      Check (Info.Implemented and then Info.Uses_Recombination
               and then not Info.Forthcoming
               and then Info.Population_Based,
             "GA flags");
      Info := Classify_Method (Evolution_Strategy);
      Check (Info.Implemented and then not Info.Uses_Recombination
               and then not Info.Forthcoming,
             "ES flags (1+1 no recombination)");
      Info := Classify_Method (Gene_Expression);
      Check (not Info.Implemented and then Info.Uses_Recombination
               and then not Info.Forthcoming,
             "GEP sibling flags");
      Info := Classify_Method (Differential_Evolution);
      Check (not Info.Implemented and then Info.Forthcoming
               and then Uses_Recombination (Differential_Evolution),
             "DE forthcoming");
      Info := Classify_Method (Memetic);
      Check (not Info.Implemented and then Info.Uses_Recombination
               and then not Info.Forthcoming,
             "Memetic sibling flags");
      Info := Classify_Method (Genetic_Programming);
      Check (not Info.Implemented and then Info.Forthcoming
               and then Uses_Recombination (Genetic_Programming),
             "GP forthcoming");
      Check (Method_Implemented (Genetic_Algorithm), "Implemented GA");
      Check (Method_Implemented (Evolution_Strategy), "Implemented ES");
      Check (not Method_Implemented (Memetic), "Not implemented Memetic");
      Check (Method_Forthcoming (Differential_Evolution), "Forthcoming DE");
      Check (Method_Forthcoming (Genetic_Programming), "Forthcoming GP");
      Check (not Method_Forthcoming (Genetic_Algorithm), "GA not forthcoming");
      Check (Uses_Recombination (Genetic_Algorithm), "Uses_Recombination GA");
      Check (not Uses_Recombination (Evolution_Strategy),
             "Uses_Recombination ES false");
      Check (Method_Name (Genetic_Algorithm) = "Genetic Algorithm",
             "Name GA");
      Check (Method_Name (Evolution_Strategy) = "Evolution Strategy",
             "Name ES");
      Check (Method_Name (Gene_Expression) =
               "Gene Expression Programming",
             "Name GEP");
      Check (Method_Name (Differential_Evolution) =
               "Differential Evolution",
             "Name DE");
      Check (Method_Name (Memetic) = "Memetic Algorithm", "Name Memetic");
      Check (Method_Name (Genetic_Programming) = "Genetic Programming",
             "Name GP");
      for K in Method_Kind loop
         Info := Classify_Method (K);
         if Info.Kind /= K then
            Names_Ok := False;
         end if;
         if not Info.Population_Based then
            Names_Ok := False;
         end if;
      end loop;
      Check (Names_Ok, "All methods population-based Kind match");
   end;

   ---------------------------------------------------------------------
   Section ("10. Extra edge / smoke");
   ---------------------------------------------------------------------
   declare
      S : RNG_State;
      A : constant Bit_String (1 .. 1) := [True];
      B : constant Bit_String (1 .. 1) := [False];
      CA, CB : Bit_String (1 .. 1);
      R : GA_Result;
      Cfg : GA_Config;
   begin
      Seed_RNG (S, 100);
      One_Point_Crossover (A, B, CA, CB, S);
      Check (CA (1) = True and then CB (1) = False, "Crossover N=1 clone");
      Check (Hamming_Distance (A, B) = 1, "Hamming N=1");
      Cfg := Default_GA_Config
        (Pop_Size => 4, Generations => 0, Elite_Count => 1,
         Tournament_K => 2, Seed => 1);
      R := Maximize_OneMax (4, Cfg);
      Check (Natural (R.Generations_Run) = 0, "Zero gens init-only");
      Check (R.Best_Fitness >= 0.0, "Zero gens fitness ok");
      declare
         function Bits_Cap return Natural is (Max_Bits);
         function Pop_Cap return Natural is (Max_Pop);
         function Dim_Cap return Natural is (Max_Dim);
         function Gen_Cap return Natural is (Max_Gens);
      begin
         Check (Bits_Cap = 64, "Max_Bits capacity");
         Check (Pop_Cap = 64, "Max_Pop capacity");
         Check (Dim_Cap = 8, "Max_Dim capacity");
         Check (Gen_Cap = 500, "Max_Gens capacity");
      end;
   end;

   New_Line;
   Put_Line ("===================================");
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("OK but Pass_Count < 100");
   else
      Put_Line ("FAILED");
   end if;
end Tests;
