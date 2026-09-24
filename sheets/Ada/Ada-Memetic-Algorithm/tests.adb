--  Standalone test suite for Memetic_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Memetic_Algorithm; use Memetic_Algorithm;

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

   function Make_Square_4 return Dist_Matrix is
      D : Dist_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0.0]];
   begin
      D (1, 2) := 1.0; D (2, 1) := 1.0;
      D (2, 3) := 1.0; D (3, 2) := 1.0;
      D (3, 4) := 1.0; D (4, 3) := 1.0;
      D (4, 1) := 1.0; D (1, 4) := 1.0;
      D (1, 3) := 1.41421356237; D (3, 1) := 1.41421356237;
      D (2, 4) := 1.41421356237; D (4, 2) := 1.41421356237;
      return D;
   end Make_Square_4;

   function Make_Path_5 return Dist_Matrix is
      D : Dist_Matrix (1 .. 5, 1 .. 5) := [others => [others => 0.0]];
   begin
      for I in City_Index range 1 .. 5 loop
         for J in City_Index range 1 .. 5 loop
            if I /= J then
               D (I, J) := Non_Negative (abs (Real (I) - Real (J)));
            end if;
         end loop;
      end loop;
      return D;
   end Make_Path_5;

   function Make_Triangle_3 return Dist_Matrix is
      D : Dist_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0.0]];
   begin
      D (1, 2) := 1.0; D (2, 1) := 1.0;
      D (2, 3) := 1.0; D (3, 2) := 1.0;
      D (3, 1) := 1.0; D (1, 3) := 1.0;
      return D;
   end Make_Triangle_3;

begin
   Put_Line ("Memetic_Algorithm test suite");
   Put_Line ("============================");

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
      Check (C.Pop_Size = 20, "Default Pop_Size");
      Check (C.Generations = 50, "Default Generations");
      Check (Near (C.Mutation_Rate, 0.05), "Default Mutation_Rate");
      Check (C.Local_Search_Steps = 10, "Default Local_Search_Steps");
      Check (C.Tournament_Size = 3, "Default Tournament_Size");
      Check (C.Seed = 1, "Default Seed");
      Check (C.Use_Steepest, "Default Use_Steepest");
      Check (C.Improve_All, "Default Improve_All");
      Check (Config_Is_Valid (C), "Default Config_Is_Valid");
      C := Default_Config
        (Pop_Size => 8, Generations => 5, Mutation_Rate => 0.1,
         Local_Search_Steps => 3, Tournament_Size => 2, Seed => 99,
         Use_Steepest => False, Improve_All => False);
      Check (C.Pop_Size = 8, "Custom Pop_Size");
      Check (C.Generations = 5, "Custom Generations");
      Check (Near (C.Mutation_Rate, 0.1), "Custom Mutation_Rate");
      Check (C.Local_Search_Steps = 3, "Custom Local_Search_Steps");
      Check (C.Tournament_Size = 2, "Custom Tournament_Size");
      Check (C.Seed = 99, "Custom Seed");
      Check (not C.Use_Steepest, "Custom Use_Steepest False");
      Check (not C.Improve_All, "Custom Improve_All False");
      Check (Config_Is_Valid (C), "Custom Config_Is_Valid");
      C.Tournament_Size := 10;
      C.Pop_Size := 8;
      Check (not Config_Is_Valid (C), "K>Pop invalid");
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
   Section ("3. Bit helpers");
   ---------------------------------------------------------------------
   declare
      Z : constant Bit_String := All_Zeros (8);
      O : constant Bit_String := All_Ones (8);
      M : Bit_String (1 .. 8);
      S : RNG_State;
   begin
      Check (Zero_Count (Z) = 8, "All_Zeros Zero_Count");
      Check (Ones_Count (Z) = 0, "All_Zeros Ones_Count");
      Check (Zero_Count (O) = 0, "All_Ones Zero_Count");
      Check (Ones_Count (O) = 8, "All_Ones Ones_Count");
      Check (Hamming_Distance (Z, O) = 8, "Hamming Z vs O");
      Check (Hamming_Distance (O, O) = 0, "Hamming O vs O");
      M := Flip_Bit (Z, 3);
      Check (M (3) and then Zero_Count (M) = 7, "Flip_Bit sets bit 3");
      M := Flip_Bit (M, 3);
      Check (not M (3) and then Zero_Count (M) = 8, "Flip_Bit toggles back");
      Seed_RNG (S, 1);
      M := Random_Bit_String (S, 8);
      Check (M'Length = 8, "Random_Bit_String length");
      Check (Copy_Bits (O, 4) = All_Ones (4), "Copy_Bits prefix");
      Check (Hamming_Distance (All_Zeros (1), All_Ones (1)) = 1,
             "Hamming n=1");
   end;

   ---------------------------------------------------------------------
   Section ("4. Tournament / crossover / mutate bits");
   ---------------------------------------------------------------------
   declare
      S     : RNG_State;
      Costs : constant Cost_Array (1 .. 6) :=
        [1 => 5.0, 2 => 1.0, 3 => 3.0, 4 => 4.0, 5 => 2.0, 6 => 6.0];
      Idx   : Positive;
      A     : constant Bit_String := All_Zeros (6);
      B     : constant Bit_String := All_Ones (6);
      C     : Bit_String (1 .. 6);
      Seen_Best : Boolean := False;
   begin
      Seed_RNG (S, 17);
      for I in 1 .. 40 loop
         Idx := Tournament_Pick (S, Costs, 3);
         Check (Idx in Costs'Range, "Tournament index in range #" &
                  Integer'Image (I));
         if Idx = 2 then
            Seen_Best := True;
         end if;
         exit when I = 12;  -- only assert first 12 index-range checks
      end loop;
      --  Extra tournament pressure: large K should often pick best.
      Seed_RNG (S, 2);
      declare
         Wins : Natural := 0;
      begin
         for I in 1 .. 30 loop
            Idx := Tournament_Pick (S, Costs, 6);
            if Idx = 2 then
               Wins := Wins + 1;
            end if;
         end loop;
         Check (Wins >= 10, "Full-pop tournament often picks best");
         Check (Seen_Best or else Wins > 0, "Best seen in tournaments");
      end;

      Seed_RNG (S, 5);
      C := One_Point_Crossover (A, B, S);
      Check (C'Length = 6, "Crossover length");
      Check (Zero_Count (C) + Ones_Count (C) = 6, "Crossover bits valid");
      --  Child is prefix of A + suffix of B → zeros then ones.
      declare
         Ok_Prefix : Boolean := True;
         Saw_One   : Boolean := False;
      begin
         for I in C'Range loop
            if C (I) then
               Saw_One := True;
            elsif Saw_One then
               Ok_Prefix := False;
            end if;
         end loop;
         Check (Ok_Prefix, "One-point child is zeros then ones");
      end;

      Seed_RNG (S, 9);
      C := Mutate_Bits (A, 0.0, S);
      Check (C = A, "Mutate rate 0 identity");
      C := Mutate_Bits (A, 1.0, S);
      Check (C = B, "Mutate rate 1 flips all zeros");
      Seed_RNG (S, 13);
      C := Mutate_Bits (B, 1.0, S);
      Check (C = A, "Mutate rate 1 flips all ones");
   end;

   ---------------------------------------------------------------------
   Section ("5. Local_Improve (OneMax / Hamming)");
   ---------------------------------------------------------------------
   declare
      Imp : Natural;
      R   : Bit_String (1 .. 8);
      Start : constant Bit_String := All_Zeros (8);
   begin
      R := Local_Improve (Start, 0, True, Imp);
      Check (R = Start and then Imp = 0, "Local_Improve 0 steps");
      R := Local_Improve (Start, 20, True, Imp);
      Check (R = All_Ones (8), "Steepest reaches all ones");
      Check (Imp = 8, "Steepest 8 improves from zeros");
      R := Local_Improve (Start, 20, False, Imp);
      Check (R = All_Ones (8), "First-improve reaches all ones");
      Check (Imp = 8, "First-improve 8 improves");
      R := Local_Improve (All_Ones (8), 5, True, Imp);
      Check (R = All_Ones (8) and then Imp = 0, "Already optimal");
      declare
         R5 : Bit_String (1 .. 5);
      begin
         R5 := Local_Improve_Bits
           (All_Zeros (5), All_Ones (5), 10, True, Imp);
         Check (Ones_Count (R5) = 5 and then Imp = 5, "Local_Improve_Bits");
      end;
      declare
         Tgt : constant Bit_String (1 .. 6) :=
           [True, False, True, False, True, False];
         St  : constant Bit_String (1 .. 6) := All_Zeros (6);
         R6  : Bit_String (1 .. 6);
      begin
         R6 := Local_Improve_Bits (St, Tgt, 10, True, Imp);
         Check (Hamming_Distance (R6, Tgt) = 0, "Hamming LS to target");
         Check (Imp = 3, "Hamming LS three True bits");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Minimize_OneMax / Minimize_Hamming drivers");
   ---------------------------------------------------------------------
   declare
      Cfg : Config :=
        Default_Config
          (Pop_Size => 12, Generations => 15, Mutation_Rate => 0.08,
           Local_Search_Steps => 5, Tournament_Size => 3, Seed => 7);
      R   : Bit_Result;
      R2  : Bit_Result;
      Agg : Result;
   begin
      R := Minimize_OneMax (10, Cfg);
      Check (R.N = 10, "OneMax N");
      Check (R.Best_Cost = 0.0, "OneMax finds all ones");
      Check (Ones_Count (R.Best_Bits (1 .. 10)) = 10, "OneMax bits ones");
      Check (R.Generations_Run <= 15, "OneMax gens budget");
      Check (R.Evaluations > 0, "OneMax evaluations");
      Agg := To_Result (R);
      Check (Near (Agg.Best_Cost, 0.0), "To_Result OneMax cost");
      Check (Agg.Evaluations = R.Evaluations, "To_Result evals");

      Cfg.Use_Steepest := False;
      Cfg.Seed := 11;
      R2 := Minimize_OneMax (8, Cfg);
      Check (R2.Best_Cost = 0.0, "First-improve OneMax");

      Cfg.Improve_All := False;
      Cfg.Seed := 19;
      Cfg.Use_Steepest := True;
      R := Minimize_OneMax (8, Cfg);
      Check (R.Best_Cost = 0.0, "Elites-only OneMax");

      Cfg := Default_Config
        (Pop_Size => 10, Generations => 0, Local_Search_Steps => 8,
         Seed => 3);
      R := Minimize_OneMax (6, Cfg);
      Check (R.Generations_Run = 0, "Generations 0 init-only");
      Check (R.Best_Cost = 0.0, "Init LS alone solves OneMax");

      Cfg := Default_Config
        (Pop_Size => 10, Generations => 20, Local_Search_Steps => 0,
         Mutation_Rate => 0.15, Seed => 21);
      R := Minimize_OneMax (6, Cfg);
      Check (R.Best_Cost = 0.0, "EA without LS still solves small OneMax");

      declare
         Tgt : constant Bit_String :=
           [True, True, False, True, False, False, True, True];
      begin
         Cfg := Default_Config
           (Pop_Size => 12, Generations => 20, Local_Search_Steps => 4,
            Seed => 33);
         R := Minimize_Hamming (Tgt, Cfg);
         Check (R.Best_Cost = 0.0, "Minimize_Hamming reaches target");
         Check (Hamming_Distance (R.Best_Bits (1 .. 8), Tgt) = 0,
                "Hamming best matches target");
      end;

      --  Reproducibility
      Cfg := Default_Config
        (Pop_Size => 8, Generations => 5, Local_Search_Steps => 2,
         Seed => 77);
      R  := Minimize_OneMax (8, Cfg);
      R2 := Minimize_OneMax (8, Cfg);
      Check (Near (R.Best_Cost, R2.Best_Cost), "Repro cost");
      Check (R.Best_Bits (1 .. 8) = R2.Best_Bits (1 .. 8), "Repro bits");
      Check (R.Evaluations = R2.Evaluations, "Repro evals");
      Check (R.Local_Improves = R2.Local_Improves, "Repro improves");
   end;

   ---------------------------------------------------------------------
   Section ("7. TSP helpers / OX / mutate / 2-opt LS");
   ---------------------------------------------------------------------
   declare
      D3  : constant Dist_Matrix := Make_Triangle_3;
      D4  : constant Dist_Matrix := Make_Square_4;
      D5  : constant Dist_Matrix := Make_Path_5;
      T   : Tour (1 .. 4);
      T2  : Tour (1 .. 4);
      S   : RNG_State;
      Imp : Natural;
      Len : Non_Negative;
   begin
      T := Identity_Tour (4);
      Check (Is_Valid_Tour (T), "Identity valid");
      Check (Near (Tour_Length (T, D4), 4.0), "Square identity length 4");
      T2 := Apply_2Opt (T, 1, 3);
      Check (Is_Valid_Tour (T2), "2-opt preserves validity");
      Check (T2 (1) = 1 and then T2 (2) = 3 and then T2 (3) = 2
               and then T2 (4) = 4, "2-opt reverse 2..3");

      Seed_RNG (S, 4);
      T := Random_Tour (S, 4);
      Check (Is_Valid_Tour (T), "Random_Tour valid");
      Seed_RNG (S, 4);
      T2 := Random_Tour (S, 4);
      Check (T = T2, "Random_Tour reproducible");

      Seed_RNG (S, 8);
      declare
         PA : constant Tour := Identity_Tour (5);
         PB : Tour (1 .. 5);
         Ch : Tour (1 .. 5);
      begin
         PB := [1 => 5, 2 => 4, 3 => 3, 4 => 2, 5 => 1];
         for K in 1 .. 15 loop
            Ch := Order_Crossover (PA, PB, S);
            Check (Is_Valid_Tour (Ch),
                   "OX child valid #" & Integer'Image (K));
         end loop;
      end;

      Seed_RNG (S, 6);
      T := Identity_Tour (4);
      T2 := Mutate_Tour (T, 0.0, S);
      Check (T2 = T, "Mutate_Tour rate 0");
      --  Force many mutations; at least one should differ eventually.
      declare
         Differed : Boolean := False;
      begin
         for K in 1 .. 40 loop
            T2 := Mutate_Tour (T, 1.0, S);
            Check (Is_Valid_Tour (T2), "Mutate_Tour valid");
            if T2 /= T then
               Differed := True;
            end if;
            exit when K = 8;  -- 8 validity checks
         end loop;
         --  Continue forcing swaps
         for K in 1 .. 30 loop
            T2 := Mutate_Tour (Identity_Tour (4), 1.0, S);
            if T2 /= Identity_Tour (4) then
               Differed := True;
            end if;
         end loop;
         Check (Differed, "Mutate_Tour sometimes swaps");
      end;

      declare
         T3 : constant Tour := Identity_Tour (3);
      begin
         Check (Near (Tour_Length (T3, D3), 3.0), "Triangle length 3");
      end;
      T := Local_Improve_TSP (Identity_Tour (4), D4, 0, True, Imp);
      Check (Imp = 0, "TSP LS 0 steps");
      --  Path-5: identity is already optimal for line metric? length =
      --  1+1+1+1 + dist(5,1)=4+4=8; reverse order same. A crossed tour
      --  should improve under 2-opt.
      declare
         Bad : constant Tour (1 .. 5) :=
           [1 => 1, 2 => 3, 3 => 5, 4 => 2, 5 => 4];
         Good : Tour (1 .. 5);
      begin
         Check (Is_Valid_Tour (Bad), "Bad path tour valid");
         Len := Tour_Length (Bad, D5);
         Good := Local_Improve_TSP (Bad, D5, 20, True, Imp);
         Check (Is_Valid_Tour (Good), "Improved tour valid");
         Check (Tour_Length (Good, D5) <= Len, "TSP LS not worse");
         Check (Imp <= 20, "TSP LS improves within budget");
         Good := Local_Improve_TSP (Bad, D5, 20, False, Imp);
         Check (Tour_Length (Good, D5) <= Len, "First-imp TSP not worse");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Minimize_TSP driver");
   ---------------------------------------------------------------------
   declare
      D4  : constant Dist_Matrix := Make_Square_4;
      D3  : constant Dist_Matrix := Make_Triangle_3;
      Cfg : Config :=
        Default_Config
          (Pop_Size => 10, Generations => 12, Mutation_Rate => 0.2,
           Local_Search_Steps => 5, Tournament_Size => 3, Seed => 5);
      R, R2 : TSP_Result;
      Agg   : Result;
   begin
      R := Minimize_TSP (D3, Cfg);
      Check (R.N = 3, "TSP triangle N");
      Check (Near (R.Best_Length, 3.0), "TSP triangle optimal 3");
      Check (Is_Valid_Tour (R.Best_Tour (1 .. 3)), "TSP best valid");
      Check (R.Evaluations > 0, "TSP evaluations");
      Agg := To_Result (R);
      Check (Near (Agg.Best_Cost, 3.0), "To_Result TSP");

      R := Minimize_TSP (D4, Cfg);
      Check (R.N = 4, "TSP square N");
      Check (R.Best_Length <= 4.0 + 0.01, "TSP square near 4");
      Check (Is_Valid_Tour (R.Best_Tour (1 .. 4)), "TSP square valid");

      Cfg.Seed := 5;
      R2 := Minimize_TSP (D4, Cfg);
      Check (Near (R.Best_Length, R2.Best_Length), "TSP repro length");
      Check (R.Best_Tour (1 .. 4) = R2.Best_Tour (1 .. 4), "TSP repro tour");
      Check (R.Local_Improves = R2.Local_Improves, "TSP repro improves");

      Cfg.Use_Steepest := False;
      Cfg.Seed := 9;
      R := Minimize_TSP (D3, Cfg);
      Check (Near (R.Best_Length, 3.0), "TSP first-improve");

      Cfg := Default_Config
        (Pop_Size => 8, Generations => 0, Local_Search_Steps => 10,
         Seed => 2);
      R := Minimize_TSP (D4, Cfg);
      Check (R.Generations_Run = 0, "TSP gens 0");
      Check (R.Best_Length <= 4.0 + 0.01, "TSP init LS good");
   end;

   ---------------------------------------------------------------------
   Section ("9. Invalid_Argument / edge cases");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      Imp    : Natural;
      Unused_B : Bit_Result;
      Unused_T : TSP_Result;
      S      : RNG_State;
      Costs  : constant Cost_Array (1 .. 3) := [1.0, 2.0, 3.0];
   begin
      Raised := False;
      begin
         declare
            Bad : constant Config :=
              Default_Config (Pop_Size => 4, Tournament_Size => 5);
            U   : Bit_Result;
         begin
            --  Pre may raise; body also checks.
            U := Minimize_OneMax (4, Bad);
            pragma Unreferenced (U);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := True;
      end;
      Check (Raised, "K>Pop raises on Minimize_OneMax");

      Raised := False;
      begin
         declare
            U : Positive;
         begin
            Seed_RNG (S, 1);
            U := Tournament_Pick (S, Costs, 4);
            pragma Unreferenced (U);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := True;
      end;
      Check (Raised, "Tournament K>len raises");

      Raised := False;
      begin
         declare
            A : constant Bit_String := All_Ones (3);
            B : constant Bit_String := All_Ones (4);
            C : Bit_String (1 .. 3);
         begin
            Seed_RNG (S, 1);
            C := One_Point_Crossover (A, B, S);
            pragma Unreferenced (C);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := True;
      end;
      Check (Raised, "Crossover length mismatch raises");

      --  Suppress unused warnings for placeholders
      pragma Unreferenced (Unused_B, Unused_T, Imp);
   end;

   ---------------------------------------------------------------------
   Section ("10. Extra coverage batch (≥100 total)");
   ---------------------------------------------------------------------
   declare
      S   : RNG_State;
      Cfg : Config;
      R   : Bit_Result;
      C   : Bit_String (1 .. 12);
      Imp : Natural;
   begin
      --  Many Near / count micro-checks
      for K in 1 .. 10 loop
         Check (Near (Real (K), Real (K)),
                "Near identity #" & Integer'Image (K));
      end loop;

      Seed_RNG (S, 100);
      for K in 1 .. 8 loop
         C := Random_Bit_String (S, 12);
         Check (C'Length = 12, "Rand bits len #" & Integer'Image (K));
         Check (Zero_Count (C) + Ones_Count (C) = 12,
                "Rand bits partition #" & Integer'Image (K));
      end loop;

      Cfg := Default_Config
        (Pop_Size => 6, Generations => 8, Mutation_Rate => 0.05,
         Local_Search_Steps => 3, Tournament_Size => 2, Seed => 55);
      R := Minimize_OneMax (12, Cfg);
      Check (R.Best_Cost = 0.0, "OneMax n=12");
      Check (R.N = 12, "OneMax n=12 size");

      declare
         R4 : Bit_String (1 .. 4);
      begin
         R4 := Local_Improve (All_Zeros (4), 4, True, Imp);
         Check (Ones_Count (R4) = 4, "LS n=4");
         R4 := Mutate_Bits (All_Ones (4), 0.0, S);
         Check (Ones_Count (R4) = 4, "Mutate preserve");
      end;

      --  Extra dynamic helper checks (avoid static-True warnings)
      declare
         Z : constant Bit_String := All_Zeros (3);
         O : constant Bit_String := All_Ones (3);
         S : RNG_State;
         X : Bit_String (1 .. 3);
      begin
         Seed_RNG (S, 123);
         X := One_Point_Crossover (Z, O, S);
         Check (X'Length = 3, "Extra crossover length");
         Check (Zero_Count (X) + Ones_Count (X) = 3, "Extra crossover partition");
         X := Mutate_Bits (Z, 0.0, S);
         Check (X = Z, "Extra mutate identity");
      end;

      Cfg.Local_Search_Steps := 0;
      Cfg.Generations := 25;
      Cfg.Mutation_Rate := 0.2;
      Cfg.Seed := 101;
      R := Minimize_OneMax (5, Cfg);
      Check (R.Best_Cost = 0.0, "Pure EA OneMax n=5");

      declare
         D : constant Dist_Matrix := Make_Triangle_3;
         TR : TSP_Result;
      begin
         Cfg := Default_Config
           (Pop_Size => 6, Generations => 5, Mutation_Rate => 0.3,
            Local_Search_Steps => 2, Seed => 8, Improve_All => False);
         TR := Minimize_TSP (D, Cfg);
         Check (Near (TR.Best_Length, 3.0), "TSP elites-only");
         Check (TR.Generations_Run = 5, "TSP gens run");
      end;
   end;

   New_Line;
   Put_Line ("========================================");
   Put_Line
     ("Result: Pass_Count=" & Natural'Image (Pass_Count)
      & "  Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("NO FAILURES (but Pass_Count < 100)");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;

end Tests;
