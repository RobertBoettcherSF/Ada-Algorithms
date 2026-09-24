--  Standalone test suite for Local_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Local_Search; use Local_Search;

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

   function Make_Square_4 return Dist_Matrix is
      D : Dist_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0.0]];
   begin
      --  Cities at (0,0),(1,0),(1,1),(0,1); unit side, diagonal √2.
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
   Put_Line ("Local_Search test suite");
   Put_Line ("=======================");

   ---------------------------------------------------------------------
   Section ("1. Near / Default_Config helpers");
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
      Check (C.Max_Climb_Steps = 500, "Default Max_Climb_Steps");
      Check (C.Max_Restarts = 5, "Default Max_Restarts");
      Check (C.Perturb_Flips = 2, "Default Perturb_Flips");
      Check (C.Seed = 1, "Default Seed");
      C := Default_Config (Max_Climb_Steps => 10, Max_Restarts => 3,
                           Perturb_Flips => 4, Seed => 99);
      Check (C.Max_Climb_Steps = 10, "Custom Max_Climb_Steps");
      Check (C.Max_Restarts = 3, "Custom Max_Restarts");
      Check (C.Perturb_Flips = 4, "Custom Perturb_Flips");
      Check (C.Seed = 99, "Custom Seed");
   end;

   ---------------------------------------------------------------------
   Section ("2. RNG determinism / range");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U1, U2, U3 : Unit_Interval;
      All_In     : Boolean := True;
      Saw_Diff   : Boolean := False;
      K          : Natural;
   begin
      Seed_RNG (S1, 42);
      Seed_RNG (S2, 42);
      Seed_RNG (S3, 99);
      U1 := Next_Unit (S1);
      U2 := Next_Unit (S2);
      U3 := Next_Unit (S3);
      Check (U1 = U2, "same seed -> same first draw");
      Check (U1 /= U3, "different seeds differ");
      Seed_RNG (S1, 0);
      U1 := Next_Unit (S1);
      Check (U1 >= 0.0 and then U1 < 1.0, "seed 0 still in [0,1)");
      Seed_RNG (S1, 7);
      for I in 1 .. 50 loop
         U1 := Next_Unit (S1);
         if U1 < 0.0 or else U1 >= 1.0 then
            All_In := False;
         end if;
         if I > 1 and then U1 /= U2 then
            Saw_Diff := True;
         end if;
         U2 := U1;
      end loop;
      Check (All_In, "50 draws in [0,1)");
      Check (Saw_Diff, "RNG produces variation");
      Seed_RNG (S1, 3);
      K := Next_Natural (S1, 5, 5);
      Check (K = 5, "Next_Natural Lo=Hi");
      Seed_RNG (S1, 11);
      All_In := True;
      for I in 1 .. 40 loop
         K := Next_Natural (S1, 1, 8);
         if K < 1 or else K > 8 then
            All_In := False;
         end if;
      end loop;
      Check (All_In, "Next_Natural in 1..8");
   end;

   ---------------------------------------------------------------------
   Section ("3. Bit-string helpers");
   ---------------------------------------------------------------------
   declare
      A : constant Bit_String := [True, False, True, False];
      B : constant Bit_String := [True, True, False, False];
      Z : constant Bit_String := All_Zeros (4);
      O : constant Bit_String := All_Ones (4);
      F : Bit_String (1 .. 4);
      S : RNG_State;
      R : Bit_String (1 .. 8);
   begin
      Check (Hamming_Distance (A, A) = 0, "Hamming identical=0");
      Check (Hamming_Distance (A, B) = 2, "Hamming A,B=2");
      Check (Hamming_Distance (Z, O) = 4, "Hamming zeros vs ones=4");
      Check (Zero_Count (A) = 2, "Zero_Count A=2");
      Check (Ones_Count (A) = 2, "Ones_Count A=2");
      Check (Zero_Count (O) = 0, "Zero_Count ones=0");
      Check (Ones_Count (Z) = 0, "Ones_Count zeros=0");
      F := Flip_Bit (Z, 2);
      Check (F (2) and then not F (1) and then not F (3), "Flip_Bit index 2");
      F := Flip_Bit (F, 2);
      Check (not F (2), "Flip_Bit twice restores");
      Check (Copy_Bits (O, 3)'Length = 3, "Copy_Bits length");
      Check (Ones_Count (Copy_Bits (O, 3)) = 3, "Copy_Bits content");
      Seed_RNG (S, 1);
      R := Random_Bit_String (S, 8);
      Check (R'Length = 8, "Random_Bit_String length");
      Check (Zero_Count (R) + Ones_Count (R) = 8, "Random bits partition");
   end;

   ---------------------------------------------------------------------
   Section ("4. Is_Local_Optimum (bits)");
   ---------------------------------------------------------------------
   declare
      O : constant Bit_String := All_Ones (5);
      Z : constant Bit_String := All_Zeros (5);
      M : constant Bit_String := [True, True, False, True, True];
   begin
      Check (Is_Local_Optimum_OneMax (O), "all-ones is OneMax local opt");
      Check (not Is_Local_Optimum_OneMax (Z), "all-zeros not OneMax local opt");
      Check (not Is_Local_Optimum_OneMax (M), "mixed not OneMax local opt");
      Check (Is_Local_Optimum_Hamming (O, O), "Hamming opt at target");
      Check (not Is_Local_Optimum_Hamming (Z, O), "zeros not Hamming opt vs ones");
      Check (Is_Local_Optimum_Hamming (Z, Z), "Hamming opt when already target");
   end;

   ---------------------------------------------------------------------
   Section ("5. Steepest hill climb OneMax / Hamming");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config := Default_Config (Max_Climb_Steps => 100);
      Z   : constant Bit_String := All_Zeros (8);
      R   : Bit_Result;
      T   : Bit_String (1 .. 6);
      S   : Bit_String (1 .. 6);
   begin
      R := Steepest_Climb_OneMax (Z, Cfg);
      Check (Near (R.Best_Cost, 0.0), "steepest OneMax zeros->0 cost");
      Check (Ones_Count (Copy_Bits (R.Best_Bits, 8)) = 8,
             "steepest OneMax all ones");
      Check (R.Climbs = 8, "steepest OneMax 8 climbs from zeros");
      Check (R.N = 8, "steepest OneMax N=8");

      R := Steepest_Climb_OneMax (All_Ones (4), Cfg);
      Check (Near (R.Best_Cost, 0.0), "steepest already optimal");
      Check (R.Climbs = 0, "steepest already optimal no climbs");

      T := [True, False, True, False, True, False];
      S := [False, False, False, True, True, True];
      R := Steepest_Climb_Hamming (S, T, Cfg);
      Check (Near (R.Best_Cost, 0.0), "steepest Hamming reaches target");
      Check (Hamming_Distance (Copy_Bits (R.Best_Bits, 6), T) = 0,
             "steepest Hamming bits match");
      Check (R.Climbs = Hamming_Distance (S, T),
             "steepest Hamming climbs = initial distance");
   end;

   ---------------------------------------------------------------------
   Section ("6. First-improvement hill climb");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config := Default_Config (Max_Climb_Steps => 100);
      Z   : constant Bit_String := All_Zeros (7);
      R   : Bit_Result;
      T   : constant Bit_String := [True, True, False, True];
      S   : constant Bit_String := [False, False, False, False];
   begin
      R := First_Improve_OneMax (Z, Cfg);
      Check (Near (R.Best_Cost, 0.0), "first-improve OneMax -> 0");
      Check (Ones_Count (Copy_Bits (R.Best_Bits, 7)) = 7,
             "first-improve OneMax all ones");
      Check (R.Climbs = 7, "first-improve OneMax 7 climbs");

      R := First_Improve_Hamming (S, T, Cfg);
      Check (Near (R.Best_Cost, 0.0), "first-improve Hamming -> 0");
      Check (Hamming_Distance (Copy_Bits (R.Best_Bits, 4), T) = 0,
             "first-improve Hamming match");

      R := First_Improve_OneMax (All_Ones (3), Cfg);
      Check (R.Climbs = 0, "first-improve already opt");
      Check (Is_Local_Optimum_OneMax (Copy_Bits (R.Best_Bits, 3)),
             "first-improve result is local opt");
   end;

   ---------------------------------------------------------------------
   Section ("7. Random-restart wrapper");
   ---------------------------------------------------------------------
   declare
      Cfg : Config := Default_Config
        (Max_Climb_Steps => 50, Max_Restarts => 5, Seed => 42);
      R   : Bit_Result;
      Agg : Result;
   begin
      R := Random_Restart_OneMax (10, Cfg);
      Check (Near (R.Best_Cost, 0.0), "RR OneMax finds global (all ones)");
      Check (R.Restarts_Used = 5, "RR OneMax used 5 restarts");
      Check (Ones_Count (Copy_Bits (R.Best_Bits, 10)) = 10,
             "RR OneMax all ones bits");

      R := Random_Restart_Hamming (All_Ones (6), Cfg);
      Check (Near (R.Best_Cost, 0.0), "RR Hamming to ones");
      Check (R.Restarts_Used = 5, "RR Hamming restarts");

      Cfg.Max_Restarts := 0;
      R := Random_Restart_OneMax (4, Cfg);
      Check (R.Restarts_Used = 0, "RR Max_Restarts=0 empty");
      Check (R.Restarts_Used = 0 and then R.Climbs = 0,
             "RR empty still returns zero stats");

      Cfg.Max_Restarts := 3;
      R := Random_Restart_OneMax (5, Cfg);
      Agg := To_Result (R);
      Check (Near (Agg.Best_Cost, R.Best_Cost), "To_Result Bit cost");
      Check (Agg.Restarts_Used = R.Restarts_Used, "To_Result Bit restarts");
      Check (Agg.Climbs = R.Climbs, "To_Result Bit climbs");
   end;

   ---------------------------------------------------------------------
   Section ("8. Perturb + Iterated Local Search");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config := Default_Config
        (Max_Climb_Steps => 50, Max_Restarts => 4,
         Perturb_Flips => 3, Seed => 17);
      S   : RNG_State;
      B   : Bit_String (1 .. 8);
      P   : Bit_String (1 .. 8);
      R   : Bit_Result;
      Dist : Natural;
   begin
      Seed_RNG (S, 17);
      B := All_Ones (8);
      P := Perturb_Bits (B, S, 3);
      Dist := Hamming_Distance (B, P);
      Check (Dist >= 1 and then Dist <= 3,
             "Perturb_Bits flips within 1..3 (w/ replacement)");
      Check (P'Length = 8, "Perturb length preserved");

      R := Iterated_Local_Search_OneMax (All_Zeros (8), Cfg);
      Check (Near (R.Best_Cost, 0.0), "ILS OneMax from zeros -> 0");
      Check (Ones_Count (Copy_Bits (R.Best_Bits, 8)) = 8,
             "ILS OneMax all ones");
      Check (R.Perturbations <= Cfg.Max_Restarts,
             "ILS perturbations within budget");
      Check (R.Climbs >= 8, "ILS at least initial climbs");

      R := Iterated_Local_Search_Hamming
        (All_Zeros (5), [True, False, True, False, True], Cfg);
      Check (Near (R.Best_Cost, 0.0), "ILS Hamming reaches target");

      --  Already optimal start: ILS should keep cost 0.
      R := Iterated_Local_Search_OneMax (All_Ones (4), Cfg);
      Check (Near (R.Best_Cost, 0.0), "ILS from optimum stays 0");
   end;

   ---------------------------------------------------------------------
   Section ("9. TSP helpers / Apply_2Opt / Tour_Length");
   ---------------------------------------------------------------------
   declare
      D4 : constant Dist_Matrix := Make_Square_4;
      D3 : constant Dist_Matrix := Make_Triangle_3;
      T  : Tour (1 .. 4);
      U  : Tour (1 .. 4);
      L  : Non_Negative;
      S  : RNG_State;
      RT : Tour (1 .. 4);
      Seen : array (City_Index range 1 .. 4) of Boolean := [others => False];
      Ok   : Boolean := True;
   begin
      T := Identity_Tour (4);
      Check (T (1) = 1 and then T (4) = 4, "Identity_Tour 1..4");
      L := Tour_Length (T, D4);
      Check (Approx (Real (L), 4.0), "square identity tour length 4");

      --  2-opt on I=1,J=3 reverses T(2..3): 1,3,2,4
      U := Apply_2Opt (T, 1, 3);
      Check (U (1) = 1 and then U (2) = 3 and then U (3) = 2 and then U (4) = 4,
             "Apply_2Opt reverse mid segment");
      L := Tour_Length (U, D4);
      Check (Approx (Real (L), 4.0 + 2.0 * 0.41421356237, 1.0E-5)
             or else Approx (Real (L), Real (Tour_Length (T, D4))),
             "2-opt changes or preserves length sensibly");

      declare
         T3 : constant Tour := Identity_Tour (3);
      begin
         L := Tour_Length (T3, D3);
         Check (Approx (Real (L), 3.0), "triangle tour length 3");
      end;

      Seed_RNG (S, 5);
      RT := Random_Tour (S, 4);
      for I in RT'Range loop
         if Seen (RT (I)) then
            Ok := False;
         else
            Seen (RT (I)) := True;
         end if;
      end loop;
      for C in City_Index range 1 .. 4 loop
         if not Seen (C) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "Random_Tour is a permutation");
   end;

   ---------------------------------------------------------------------
   Section ("10. 2-opt local search / Is_Local_Optimum_TSP");
   ---------------------------------------------------------------------
   declare
      D4  : constant Dist_Matrix := Make_Square_4;
      D5  : constant Dist_Matrix := Make_Path_5;
      D3  : constant Dist_Matrix := Make_Triangle_3;
      Cfg : constant Config := Default_Config
        (Max_Climb_Steps => 100, Max_Restarts => 6, Seed => 9);
      Id  : constant Tour := Identity_Tour (4);
      Bad : constant Tour := [1, 3, 2, 4];
      R   : TSP_Result;
      Agg : Result;
      Opt : Tour (1 .. 4);
   begin
      Check (Is_Local_Optimum_TSP (Id, D4),
             "square identity is 2-opt local opt");
      Check (Is_Local_Optimum_TSP (Identity_Tour (3), D3),
             "triangle identity is local opt");

      R := Two_Opt_Local_Search (D4, Bad, Cfg);
      for I in 1 .. 4 loop
         Opt (City_Index (I)) := R.Best_Tour (City_Index (I));
      end loop;
      Check (Is_Local_Optimum_TSP (Opt, D4),
             "2-opt result is local optimum");
      Check (R.Best_Length <= Tour_Length (Bad, D4),
             "2-opt never worsens");
      Check (Approx (Real (R.Best_Length), 4.0, 1.0E-4)
             or else R.Best_Length < Tour_Length (Bad, D4),
             "2-opt finds short square tour");

      R := Two_Opt_Local_Search (D5, Identity_Tour (5), Cfg);
      declare
         Opt5 : Tour (1 .. 5);
      begin
         for I in 1 .. 5 loop
            Opt5 (City_Index (I)) := R.Best_Tour (City_Index (I));
         end loop;
         Check (Is_Local_Optimum_TSP (Opt5, D5),
                "path-5 2-opt result local opt");
      end;
      Check (R.N = 5, "TSP result N=5");

      R := Random_Restart_TSP (D4, Cfg);
      Check (R.Restarts_Used = 6, "RR TSP used 6 restarts");
      Check (Approx (Real (R.Best_Length), 4.0, 1.0E-4)
             or else R.Best_Length <= 4.0 + 0.01,
             "RR TSP finds square optimum ~4");
      Agg := To_Result (R);
      Check (Near (Agg.Best_Cost, Real (R.Best_Length)), "To_Result TSP cost");
      Check (Agg.Climbs = R.Climbs, "To_Result TSP climbs");
   end;

   ---------------------------------------------------------------------
   Section ("11. Taxonomy metadata");
   ---------------------------------------------------------------------
   declare
      Info : Method_Info;
   begin
      Info := Classify_Method (Hill_Climbing);
      Check (Info.Implemented, "Hill_Climbing implemented");
      Check (not Info.Stochastic, "Hill_Climbing deterministic");
      Check (not Info.Uses_Memory, "Hill_Climbing no memory");

      Info := Classify_Method (Random_Restart);
      Check (Info.Implemented, "Random_Restart implemented");
      Check (Info.Stochastic, "Random_Restart stochastic");

      Info := Classify_Method (Iterated_Local_Search);
      Check (Info.Implemented, "ILS implemented");
      Check (Info.Stochastic, "ILS stochastic");

      Info := Classify_Method (Tabu);
      Check (not Info.Implemented, "Tabu metadata only");
      Check (Info.Uses_Memory, "Tabu uses memory");

      Info := Classify_Method (Simulated_Annealing);
      Check (not Info.Implemented, "SA metadata only");
      Check (Info.Stochastic, "SA stochastic");

      Info := Classify_Method (Random_Search);
      Check (not Info.Implemented, "Random_Search metadata only");
      Check (Info.Stochastic, "Random_Search stochastic");

      Check (Method_Implemented (Hill_Climbing), "Method_Implemented HC");
      Check (Method_Implemented (Random_Restart), "Method_Implemented RR");
      Check (Method_Implemented (Iterated_Local_Search), "Method_Implemented ILS");
      Check (not Method_Implemented (Tabu), "Method_Implemented Tabu false");
      Check (not Method_Implemented (Simulated_Annealing),
             "Method_Implemented SA false");
      Check (not Method_Implemented (Random_Search),
             "Method_Implemented RS false");

      Check (Method_Name (Hill_Climbing) = "Hill Climbing", "Name HC");
      Check (Method_Name (Random_Restart) = "Random Restart", "Name RR");
      Check (Method_Name (Tabu) = "Tabu Search", "Name Tabu");
      Check (Method_Name (Simulated_Annealing) = "Simulated Annealing",
             "Name SA");
      Check (Method_Name (Iterated_Local_Search) = "Iterated Local Search",
             "Name ILS");
      Check (Method_Name (Random_Search) = "Random Search", "Name RS");
   end;

   ---------------------------------------------------------------------
   Section ("12. Extra edge / consistency cases");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config := Default_Config
        (Max_Climb_Steps => 20, Max_Restarts => 2, Seed => 3);
      R1, R2 : Bit_Result;
      Mixed  : constant Bit_String :=
        [True, False, True, False, True, False, True, False];
      D4     : constant Dist_Matrix := Make_Square_4;
      TR     : TSP_Result;
   begin
      R1 := Steepest_Climb_OneMax (Mixed, Cfg);
      R2 := First_Improve_OneMax (Mixed, Cfg);
      Check (Near (R1.Best_Cost, 0.0), "steepest mixed -> 0");
      Check (Near (R2.Best_Cost, 0.0), "first-improve mixed -> 0");
      Check (Is_Local_Optimum_OneMax (Copy_Bits (R1.Best_Bits, 8)),
             "steepest end is local opt");
      Check (Is_Local_Optimum_OneMax (Copy_Bits (R2.Best_Bits, 8)),
             "first-improve end is local opt");

      --  Same seed => same RR result.
      R1 := Random_Restart_OneMax (6, Cfg);
      R2 := Random_Restart_OneMax (6, Cfg);
      Check (Near (R1.Best_Cost, R2.Best_Cost), "RR deterministic same seed");
      Check (Hamming_Distance
               (Copy_Bits (R1.Best_Bits, 6), Copy_Bits (R2.Best_Bits, 6)) = 0,
             "RR same bits same seed");

      TR := Two_Opt_Local_Search (D4, Identity_Tour (4), Cfg);
      Check (TR.Climbs = 0, "2-opt on already-opt tour: 0 climbs");
      Check (Approx (Real (TR.Best_Length), 4.0), "identity square length 4");

      --  Single-bit N=1.
      R1 := Steepest_Climb_OneMax (All_Zeros (1), Cfg);
      Check (Near (R1.Best_Cost, 0.0) and then R1.Climbs = 1,
             "N=1 steepest OneMax");
      R1 := First_Improve_Hamming (All_Zeros (1), All_Ones (1), Cfg);
      Check (Near (R1.Best_Cost, 0.0), "N=1 first-improve Hamming");

      Check (Ones_Count (All_Ones (Max_Bits)) = Max_Bits,
             "All_Ones(Max_Bits) length/content");
      Check (Identity_Tour (Max_Cities)'Length = Max_Cities,
             "Identity_Tour(Max_Cities) length");
   end;

   New_Line;
   Put_Line ("=================================");
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("OK but Pass_Count < 100");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
