--  Standalone test suite for Genetic_Algorithms (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Genetic_Algorithms; use Genetic_Algorithms;

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

begin
   Put_Line ("Genetic_Algorithms test suite");
   Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Default_Config / Config_Is_Valid");
   ---------------------------------------------------------------------
   declare
      C : Config;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Near (100.0, 100.0 + 5.0E-11), "Near large magnitude");
      Check (Near (0.0, 0.0), "Near zeros");
      C := Default_Config;
      Check (C.Pop_Size = 30, "Default Pop_Size");
      Check (C.Generations = 80, "Default Generations");
      Check (Near (C.Crossover_Rate, 0.8), "Default Crossover_Rate");
      Check (Near (C.Mutation_Rate, 0.02), "Default Mutation_Rate");
      Check (C.Tournament_K = 3, "Default Tournament_K");
      Check (C.Elite_Count = 1, "Default Elite_Count");
      Check (C.Seed = 1, "Default Seed");
      Check (C.Selection = Tournament, "Default Selection Tournament");
      Check (C.Crossover = One_Point, "Default Crossover One_Point");
      Check (Config_Is_Valid (C), "Default Config_Is_Valid");
      C := Default_Config
        (Pop_Size => 10, Generations => 5, Crossover_Rate => 0.5,
         Mutation_Rate => 0.1, Tournament_K => 2, Elite_Count => 0,
         Seed => 99, Selection => Fitness_Proportionate,
         Crossover => Two_Point);
      Check (C.Pop_Size = 10, "Custom Pop_Size");
      Check (C.Generations = 5, "Custom Generations");
      Check (Near (C.Crossover_Rate, 0.5), "Custom Crossover_Rate");
      Check (Near (C.Mutation_Rate, 0.1), "Custom Mutation_Rate");
      Check (C.Tournament_K = 2, "Custom Tournament_K");
      Check (C.Elite_Count = 0, "Custom Elite_Count 0");
      Check (C.Seed = 99, "Custom Seed");
      Check (C.Selection = Fitness_Proportionate, "Custom Selection FPS");
      Check (C.Crossover = Two_Point, "Custom Crossover Two_Point");
      Check (Config_Is_Valid (C), "Custom Config_Is_Valid");
      C.Tournament_K := 12;
      C.Pop_Size := 10;
      Check (not Config_Is_Valid (C), "K>Pop invalid");
      C := Default_Config (Pop_Size => 8, Elite_Count => 8);
      Check (not Config_Is_Valid (C), "Elite=Pop invalid");
      C := Default_Config (Pop_Size => 8, Elite_Count => 7);
      Check (Config_Is_Valid (C), "Elite=Pop-1 valid");
   end;

   ---------------------------------------------------------------------
   Section ("2. LCG reproducibility");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U1, U2, U3 : Unit_Interval;
      N1, N2     : Natural;
   begin
      Seed_RNG (S1, 42);
      Seed_RNG (S2, 42);
      Seed_RNG (S3, 99);
      U1 := Next_Unit (S1);
      U2 := Next_Unit (S2);
      U3 := Next_Unit (S3);
      Check (Near (U1, U2), "Same seed same unit");
      Check (not Near (U1, U3), "Different seed different unit");
      Check (U1 >= 0.0 and then U1 < 1.0, "Unit in [0,1)");
      Seed_RNG (S1, 0);
      U1 := Next_Unit (S1);
      Check (U1 >= 0.0 and then U1 < 1.0, "Seed 0 yields valid unit");
      Seed_RNG (S1, 7);
      for I in 1 .. 20 loop
         U1 := Next_Unit (S1);
         pragma Unreferenced (I);
      end loop;
      Check (U1 >= 0.0 and then U1 < 1.0, "20 draws stay in range");
      Seed_RNG (S1, 3);
      N1 := Next_Natural (S1, 5, 5);
      Check (N1 = 5, "Next_Natural Lo=Hi");
      Seed_RNG (S1, 11);
      Seed_RNG (S2, 11);
      N1 := Next_Natural (S1, 1, 10);
      N2 := Next_Natural (S2, 1, 10);
      Check (N1 = N2, "Next_Natural reproducible");
      Check (N1 >= 1 and then N1 <= 10, "Next_Natural in bounds");
   end;

   ---------------------------------------------------------------------
   Section ("3. Bit-string utilities");
   ---------------------------------------------------------------------
   declare
      A : constant Bit_String := [True, False, True, True];
      B : constant Bit_String := [True, True, False, True];
      Z : constant Bit_String := All_Zeros (5);
      O : constant Bit_String := All_Ones (5);
      F : Bit_String (1 .. 4);
      S : RNG_State;
      R1, R2 : Bit_String (1 .. 8);
   begin
      Check (Hamming_Distance (A, B) = 2, "Hamming A vs B = 2");
      Check (Hamming_Distance (A, A) = 0, "Hamming self = 0");
      Check (Zero_Count (A) = 1, "Zero_Count A");
      Check (Ones_Count (A) = 3, "Ones_Count A");
      Check (Zero_Count (Z) = 5, "All_Zeros zeros");
      Check (Ones_Count (O) = 5, "All_Ones ones");
      Check (Equal_Bits (A, A), "Equal_Bits self");
      Check (not Equal_Bits (A, B), "Equal_Bits different");
      F := Flip_Bit (A, 2);
      Check (F (2) = True, "Flip_Bit flipped False→True");
      Check (Ones_Count (F) = 4, "Flip_Bit ones");
      Check (Equal_Bits (Copy_Bits (A, 4), A), "Copy_Bits identity");
      Seed_RNG (S, 1);
      R1 := Random_Bit_String (S, 8);
      Seed_RNG (S, 1);
      R2 := Random_Bit_String (S, 8);
      Check (Equal_Bits (R1, R2), "Random_Bit_String reproducible");
      Check (R1'Length = 8, "Random length");
   end;

   ---------------------------------------------------------------------
   Section ("4. Fitness / cost");
   ---------------------------------------------------------------------
   declare
      X : constant Bit_String := [True, True, False, False];
      T : constant Bit_String := [True, False, True, False];
   begin
      Check (Near (Fitness_OneMax (X), 2.0), "Fitness_OneMax");
      Check (Near (Cost_Zero_Count (X), 2.0), "Cost_Zero_Count");
      Check (Near (Cost_Hamming (X, T), 2.0), "Cost_Hamming");
      Check (Near (Fitness_Hamming (X, T), 2.0), "Fitness_Hamming");
      Check (Near (Fitness_OneMax (All_Ones (6)), 6.0), "OneMax all ones");
      Check (Near (Cost_Zero_Count (All_Ones (6)), 0.0), "Zero cost all ones");
      Check (Near (Cost_Hamming (T, T), 0.0), "Hamming self 0");
      Check (Near (Fitness_Hamming (T, T), 4.0), "Fit Hamming self n");
   end;

   ---------------------------------------------------------------------
   Section ("5. Tournament selection");
   ---------------------------------------------------------------------
   declare
      Fit : constant Fitness_Array := [1.0, 9.0, 3.0, 2.0];
      Cst : constant Cost_Array := [5.0, 1.0, 4.0, 8.0];
      S   : RNG_State;
      I   : Positive;
      Hit : Natural := 0;
   begin
      Seed_RNG (S, 5);
      for K in 1 .. 40 loop
         pragma Unreferenced (K);
         I := Tournament_Select (S, Fit, 3);
         if I not in Fit'Range then
            Hit := 0;
            exit;
         end if;
         if I = 2 then
            Hit := Hit + 1;
         end if;
      end loop;
      Check (I in Fit'Range, "Tournament index in range");
      Check (Hit >= 10, "Tournament prefers fittest often");
      Seed_RNG (S, 5);
      Hit := 0;
      for K in 1 .. 40 loop
         pragma Unreferenced (K);
         I := Tournament_Select_Min (S, Cst, 3);
         if I = 2 then
            Hit := Hit + 1;
         end if;
      end loop;
      Check (Hit >= 10, "Tournament_Min prefers lowest cost");
   end;

   ---------------------------------------------------------------------
   Section ("6. Fitness-proportionate selection");
   ---------------------------------------------------------------------
   declare
      Fit : constant Fitness_Array := [0.0, 10.0, 0.0, 0.0];
      S   : RNG_State;
      I   : Positive;
      Hit : Natural := 0;
      Flat : constant Fitness_Array := [0.0, 0.0, 0.0];
   begin
      Seed_RNG (S, 2);
      for K in 1 .. 30 loop
         pragma Unreferenced (K);
         I := Fitness_Proportionate_Select (S, Fit);
         if I = 2 then
            Hit := Hit + 1;
         end if;
      end loop;
      Check (Hit = 30, "FPS always picks sole positive fitness");
      Seed_RNG (S, 3);
      I := Fitness_Proportionate_Select (S, Flat);
      Check (I in Flat'Range, "FPS flat total→uniform index");
   end;

   ---------------------------------------------------------------------
   Section ("7. One-point / two-point crossover");
   ---------------------------------------------------------------------
   declare
      A : constant Bit_String := [True, True, True, True];
      B : constant Bit_String := [False, False, False, False];
      S : RNG_State;
      C : Bit_String (1 .. 4);
      Mixed : Boolean := False;
   begin
      Seed_RNG (S, 10);
      for K in 1 .. 20 loop
         pragma Unreferenced (K);
         C := One_Point_Crossover (A, B, S);
         Check (C'Length = 4, "1pt length");
         if Ones_Count (C) > 0 and then Ones_Count (C) < 4 then
            Mixed := True;
         end if;
      end loop;
      Check (Mixed, "1pt produces mixed child sometime");
      Seed_RNG (S, 10);
      declare
         C1 : constant Bit_String := One_Point_Crossover (A, B, S);
         S2 : RNG_State;
         C2 : Bit_String (1 .. 4);
      begin
         Seed_RNG (S2, 10);
         C2 := One_Point_Crossover (A, B, S2);
         Check (Equal_Bits (C1, C2), "1pt reproducible");
      end;
      Seed_RNG (S, 20);
      Mixed := False;
      for K in 1 .. 20 loop
         pragma Unreferenced (K);
         C := Two_Point_Crossover (A, B, S);
         Check (C'Length = 4, "2pt length");
         if Ones_Count (C) > 0 and then Ones_Count (C) < 4 then
            Mixed := True;
         end if;
      end loop;
      Check (Mixed, "2pt produces mixed child sometime");
      Seed_RNG (S, 7);
      C := Crossover (A, B, One_Point, 0.0, S);
      Check (Equal_Bits (C, A), "Crossover rate 0 clones A");
      Seed_RNG (S, 7);
      C := Crossover (A, B, Two_Point, 1.0, S);
      Check (C'Length = 4, "Crossover rate 1 applies");
   end;

   ---------------------------------------------------------------------
   Section ("8. Mutation");
   ---------------------------------------------------------------------
   declare
      A : constant Bit_String := All_Zeros (10);
      S : RNG_State;
      M : Bit_String (1 .. 10);
   begin
      Seed_RNG (S, 1);
      M := Mutate_Bits (A, 0.0, S);
      Check (Equal_Bits (M, A), "Mutate rate 0 identity");
      Seed_RNG (S, 1);
      M := Mutate_Bits (A, 1.0, S);
      Check (Equal_Bits (M, All_Ones (10)), "Mutate rate 1 flips all");
      Seed_RNG (S, 42);
      M := Mutate_Bits (A, 0.5, S);
      Check (M'Length = 10, "Mutate length");
      Seed_RNG (S, 42);
      declare
         M2 : constant Bit_String := Mutate_Bits (A, 0.5, S);
      begin
         Check (Equal_Bits (M, M2), "Mutate reproducible");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Elitism helpers");
   ---------------------------------------------------------------------
   declare
      Fit : constant Fitness_Array := [3.0, 9.0, 1.0, 7.0];
      Cst : constant Cost_Array := [4.0, 0.5, 8.0, 2.0];
      E   : Index_Array (1 .. 2);
   begin
      E := Elite_Indices_Max (Fit, 2);
      Check (E (1) = 2, "Elite max #1 is index 2");
      Check (E (2) = 4, "Elite max #2 is index 4");
      E := Elite_Indices_Min (Cst, 2);
      Check (E (1) = 2, "Elite min #1 is index 2");
      Check (E (2) = 4, "Elite min #2 is index 4");
      declare
         E0 : constant Index_Array := Elite_Indices_Max (Fit, 0);
      begin
         Check (E0'Length = 0, "Elite count 0 empty");
      end;
      declare
         E1 : constant Index_Array := Elite_Indices_Max (Fit, 1);
      begin
         Check (E1 (1) = 2, "Elite single max");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Maximize_OneMax");
   ---------------------------------------------------------------------
   declare
      Cfg : Config;
      R   : Result;
   begin
      Cfg := Default_Config
        (Pop_Size => 20, Generations => 40, Crossover_Rate => 0.9,
         Mutation_Rate => 0.05, Tournament_K => 3, Elite_Count => 2,
         Seed => 1);
      R := Maximize_OneMax (12, Cfg);
      Check (R.N = 12, "OneMax N");
      Check (R.Generations_Run = 40, "OneMax gens");
      Check (R.History_Length = 40, "OneMax history length");
      Check (R.Evaluations > 0, "OneMax evals > 0");
      Check (Near (R.Best_Fitness, 12.0), "OneMax reaches all ones");
      Check (Ones_Count (Copy_Bits (R.Best_Bits, 12)) = 12, "OneMax bits");
      Check (Near (R.Best_Cost, 0.0), "OneMax Best_Cost dual 0");

      Cfg.Seed := 2;
      R := Maximize_OneMax (8, Cfg);
      Check (Near (R.Best_Fitness, 8.0), "OneMax n=8");

      Cfg := Default_Config
        (Pop_Size => 16, Generations => 0, Seed => 1, Elite_Count => 1);
      R := Maximize_OneMax (6, Cfg);
      Check (R.Generations_Run = 0, "OneMax gens=0");
      Check (R.History_Length = 0, "OneMax hist=0");
      Check (R.Best_Fitness >= 0.0, "OneMax init fitness");

      Cfg := Default_Config
        (Pop_Size => 24, Generations => 50, Selection => Fitness_Proportionate,
         Crossover => Two_Point, Elite_Count => 2, Seed => 3,
         Mutation_Rate => 0.04, Crossover_Rate => 0.85);
      R := Maximize_OneMax (10, Cfg);
      Check (Near (R.Best_Fitness, 10.0), "OneMax FPS+2pt");
   end;

   ---------------------------------------------------------------------
   Section ("11. Minimize_Hamming");
   ---------------------------------------------------------------------
   declare
      Cfg : Config;
      R   : Result;
      T   : Bit_String (1 .. 10);
      S   : RNG_State;
   begin
      Seed_RNG (S, 99);
      T := Random_Bit_String (S, 10);
      Cfg := Default_Config
        (Pop_Size => 20, Generations => 50, Elite_Count => 2,
         Mutation_Rate => 0.05, Seed => 7);
      R := Minimize_Hamming (T, Cfg);
      Check (R.N = 10, "Ham N");
      Check (Near (R.Best_Cost, 0.0), "Ham cost 0");
      Check (Equal_Bits (Copy_Bits (R.Best_Bits, 10), T), "Ham matches target");
      Check (R.History_Length = 50, "Ham history");
      Check (R.Evaluations > 0, "Ham evals");

      Cfg.Selection := Fitness_Proportionate;
      Cfg.Crossover := Two_Point;
      Cfg.Seed := 11;
      R := Minimize_Hamming (All_Ones (8), Cfg);
      Check (Near (R.Best_Cost, 0.0), "Ham FPS all-ones target");
   end;

   ---------------------------------------------------------------------
   Section ("12. Maximize_Hamming_Fitness / Minimize_Zero_Count");
   ---------------------------------------------------------------------
   declare
      Cfg : Config;
      R   : Result;
      T   : constant Bit_String :=
        [True, False, True, False, True, True, False, False];
   begin
      Cfg := Default_Config
        (Pop_Size => 18, Generations => 40, Elite_Count => 1, Seed => 4);
      R := Maximize_Hamming_Fitness (T, Cfg);
      Check (Near (R.Best_Fitness, 8.0), "Max Ham fitness = n");
      Check (Equal_Bits (Copy_Bits (R.Best_Bits, 8), T), "Max Ham bits");

      R := Minimize_Zero_Count (10, Cfg);
      Check (Near (R.Best_Cost, 0.0), "Min zeros cost 0");
      Check (Ones_Count (Copy_Bits (R.Best_Bits, 10)) = 10, "Min zeros all 1");
      Check (R.History_Length = 40, "Min zeros history");
   end;

   ---------------------------------------------------------------------
   Section ("13. Reproducibility of drivers");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        Default_Config
          (Pop_Size => 12, Generations => 15, Seed => 123, Elite_Count => 1);
      R1, R2 : Result;
   begin
      R1 := Maximize_OneMax (8, Cfg);
      R2 := Maximize_OneMax (8, Cfg);
      Check (Near (R1.Best_Fitness, R2.Best_Fitness), "OneMax repro fitness");
      Check (Equal_Bits
               (Copy_Bits (R1.Best_Bits, 8), Copy_Bits (R2.Best_Bits, 8)),
             "OneMax repro bits");
      Check (R1.Evaluations = R2.Evaluations, "OneMax repro evals");
      R1 := Minimize_Hamming (All_Zeros (6), Cfg);
      R2 := Minimize_Hamming (All_Zeros (6), Cfg);
      Check (Near (R1.Best_Cost, R2.Best_Cost), "Ham repro cost");
      Check (Equal_Bits
               (Copy_Bits (R1.Best_Bits, 6), Copy_Bits (R2.Best_Bits, 6)),
             "Ham repro bits");
   end;

   ---------------------------------------------------------------------
   Section ("14. Elitism non-decrease / edge cases");
   ---------------------------------------------------------------------
   declare
      Cfg : Config;
      R   : Result;
      Raised : Boolean;
   begin
      Cfg := Default_Config
        (Pop_Size => 10, Generations => 25, Elite_Count => 3,
         Mutation_Rate => 0.01, Seed => 8);
      R := Maximize_OneMax (8, Cfg);
      Check (R.Best_Fitness >= 4.0, "Elite run reasonable fitness");

      Cfg.Elite_Count := 0;
      R := Maximize_OneMax (8, Cfg);
      Check (R.Best_Fitness >= 0.0, "No-elite still runs");

      Raised := False;
      begin
         declare
            Bad : Config := Default_Config;
            Dummy : Positive;
            Fit : constant Fitness_Array := [1.0];
            S : RNG_State;
         begin
            Seed_RNG (S, 1);
            --  length 1 with K=2 should fail Pre or raise
            Dummy := Tournament_Select (S, Fit, 2);
            pragma Unreferenced (Bad, Dummy);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised := True;
         when others =>
            Raised := True;
      end;
      Check (Raised, "Tournament short pop raises");

      Raised := False;
      begin
         declare
            Empty : Fitness_Array (1 .. 0);
            S : RNG_State;
            Dummy : Positive;
         begin
            Seed_RNG (S, 1);
            Dummy := Fitness_Proportionate_Select (S, Empty);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised := True;
         when others =>
            Raised := True;
      end;
      Check (Raised, "FPS empty raises");
   end;

   ---------------------------------------------------------------------
   Section ("15. Operator edge cases");
   ---------------------------------------------------------------------
   declare
      S : RNG_State;
      A : constant Bit_String := [True];
      B : constant Bit_String := [False];
      C : Bit_String (1 .. 1);
      Long_A : constant Bit_String := All_Ones (32);
      Long_B : constant Bit_String := All_Zeros (32);
      D : Bit_String (1 .. 32);
   begin
      Seed_RNG (S, 1);
      C := One_Point_Crossover (A, B, S);
      Check (C'Length = 1, "1pt n=1 length");
      Seed_RNG (S, 2);
      C := Two_Point_Crossover (A, B, S);
      Check (C'Length = 1, "2pt n=1 length");
      Seed_RNG (S, 3);
      D := One_Point_Crossover (Long_A, Long_B, S);
      Check (D'Length = 32, "1pt n=32");
      Seed_RNG (S, 4);
      D := Two_Point_Crossover (Long_A, Long_B, S);
      Check (D'Length = 32, "2pt n=32");
      Check (Near (Fitness_OneMax (Long_A), 32.0), "OneMax 32");
      Check (Near (Cost_Zero_Count (Long_B), 32.0), "Zeros 32");
      Check (Hamming_Distance (Long_A, Long_B) = 32, "Ham 32");
      Check (Flip_Bit (A, 1)(1) = False, "Flip single");
   end;

   ---------------------------------------------------------------------
   Section ("16. Extra combinatorial checks");
   ---------------------------------------------------------------------
   declare
      Cfg : Config;
      R   : Result;
      Ok  : Boolean;
   begin
      for Seed_V in 1 .. 5 loop
         Cfg := Default_Config
           (Pop_Size => 14, Generations => 30, Seed => Seed_V,
            Elite_Count => 1, Mutation_Rate => 0.06);
         R := Maximize_OneMax (7, Cfg);
         Check (Near (R.Best_Fitness, 7.0), "OneMax seed sweep");
      end loop;

      Cfg := Default_Config
        (Pop_Size => 16, Generations => 35, Crossover => Two_Point,
         Selection => Tournament, Elite_Count => 2, Seed => 50);
      R := Minimize_Zero_Count (9, Cfg);
      Check (Near (R.Best_Cost, 0.0), "Min zeros 2pt");

      Cfg.Selection := Fitness_Proportionate;
      R := Minimize_Zero_Count (9, Cfg);
      Check (Near (R.Best_Cost, 0.0), "Min zeros FPS");

      Ok := True;
      for N in Bit_Count range 1 .. 5 loop
         Check (Ones_Count (All_Ones (N)) = N, "All_Ones N");
         Check (Zero_Count (All_Zeros (N)) = N, "All_Zeros N");
         if Ones_Count (All_Ones (N)) /= N then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "All_Ones sweep ok");
   end;

   New_Line;
   Put_Line ("=================================");
   Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
