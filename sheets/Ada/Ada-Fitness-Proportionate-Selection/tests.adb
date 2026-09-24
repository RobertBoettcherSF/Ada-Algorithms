--  Standalone test suite for Fitness_Proportionate_Selection (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Fitness_Proportionate_Selection; use Fitness_Proportionate_Selection;

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

   type Real_Array is array (Positive range <>) of Real;

   function From_Fitness (F : Real_Array) return Population is
      P : Population (F'Range);
   begin
      for I in F'Range loop
         P (I) := (Fitness => F (I), Tag => I);
      end loop;
      return P;
   end From_Fitness;

   function Count_Tag (Sel : Index_List; Pop : Population; Tag : Natural)
     return Natural
   is
      C : Natural := 0;
   begin
      for I in Sel'Range loop
         if Pop (Sel (I)).Tag = Tag then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Count_Tag;

   function Count_Index (Sel : Index_List; Idx : Positive) return Natural is
      C : Natural := 0;
   begin
      for I in Sel'Range loop
         if Sel (I) = Idx then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Count_Index;

begin
   Put_Line ("Fitness_Proportionate_Selection test suite");
   Put_Line ("==========================================");

   ---------------------------------------------------------------------
   Section ("1. Near");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Near (100.0, 100.0 + 5.0E-11), "Near large magnitude");
      Check (Near (0.0, 0.0), "Near zeros");
   end;

   ---------------------------------------------------------------------
   Section ("2. Config / Valid_Config / Make_Config");
   ---------------------------------------------------------------------
   declare
      D : constant Config := Default_Config;
      C : Config;
   begin
      Check (D.Seed = 1, "Default Seed=1");
      C := Make_Config (Seed => 99);
      Check (C.Seed = 99, "Make_Config Seed");
      Check (Valid_Config (D, 10, 5), "Valid_Config N=10 select=5");
      Check (Valid_Config (D, 1, 1), "Valid_Config N=1 select=1");
      Check (not Valid_Config (D, 0, 5), "Valid_Config rejects Pop=0");
      Check (not Valid_Config (D, 5, 0), "Valid_Config rejects select=0");
      Check (not Valid_Config (D, 0, 0), "Valid_Config rejects both 0");
      C := Make_Config (0);
      Check (C.Seed = 0, "Make_Config Seed=0 allowed");
   end;

   ---------------------------------------------------------------------
   Section ("3. RNG Seed / Next_Unit / Next_Real / Next_Natural");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U          : Unit_Interval;
      R          : Real;
      N          : Natural;
      Cfg        : constant Config := Make_Config (Seed => 42);
   begin
      Seed_RNG (S1, 1);
      Seed_RNG (S2, 1);
      Check (Next_Natural (S1, 1, 10) = Next_Natural (S2, 1, 10),
             "Same seed same Next_Natural");

      Seed_RNG (S1, 0);
      Seed_RNG (S2, 0);
      Check (Next_Unit (S1) = Next_Unit (S2), "Seed 0 maps identically");

      Seed_RNG (S3, Cfg);
      Seed_RNG (S1, 42);
      Check (Next_Unit (S3) = Next_Unit (S1), "Seed_RNG from Config");

      Seed_RNG (S1, 7);
      U := Next_Unit (S1);
      Check (U >= 0.0 and then U < 1.0, "Next_Unit in [0,1)");

      Seed_RNG (S1, 11);
      N := Next_Natural (S1, 5, 5);
      Check (N = 5, "Next_Natural Lo=Hi");

      Seed_RNG (S1, 13);
      declare
         Seen_Lo : Boolean := False;
         Seen_Hi : Boolean := False;
         V       : Natural;
         All_Ok  : Boolean := True;
      begin
         for I in 1 .. 200 loop
            pragma Unreferenced (I);
            V := Next_Natural (S1, 1, 4);
            if V not in 1 .. 4 then
               All_Ok := False;
            end if;
            if V = 1 then
               Seen_Lo := True;
            end if;
            if V = 4 then
               Seen_Hi := True;
            end if;
         end loop;
         Check (All_Ok, "Next_Natural stays in 1..4");
         Check (Seen_Lo, "Next_Natural hits Lo");
         Check (Seen_Hi, "Next_Natural hits Hi");
      end;

      Seed_RNG (S1, 17);
      R := Next_Real (S1, 2.0, 5.0);
      Check (R >= 2.0 and then R < 5.0, "Next_Real in [2,5)");

      Seed_RNG (S1, 19);
      Seed_RNG (S2, 19);
      Check (Near (Next_Real (S1, 0.0, 1.0), Next_Real (S2, 0.0, 1.0)),
             "Same seed same Next_Real");
   end;

   ---------------------------------------------------------------------
   Section ("4. All_Non_Negative / Total_Fitness / Shift");
   ---------------------------------------------------------------------
   declare
      Pop  : constant Population := From_Fitness ([1.0, 2.0, 3.0]);
      Zero : constant Population := From_Fitness ([0.0, 0.0]);
      Neg  : constant Population := From_Fitness ([1.0, -0.5, 2.0]);
      Empty : Population (1 .. 0);
      Costs : constant Population := From_Fitness ([5.0, 3.0, 1.0]);
      Fit   : Population (1 .. 3);
      Flat  : constant Population := From_Fitness ([7.0, 7.0, 7.0]);
      FlatF : Population (1 .. 3);
   begin
      Check (All_Non_Negative (Pop), "All_Non_Negative positive");
      Check (All_Non_Negative (Zero), "All_Non_Negative zeros");
      Check (not All_Non_Negative (Neg), "All_Non_Negative rejects neg");
      Check (All_Non_Negative (Empty), "All_Non_Negative empty true");

      Check (Near (Total_Fitness (Pop), 6.0), "Total_Fitness 1+2+3");
      Check (Near (Total_Fitness (Zero), 0.0), "Total_Fitness zeros");
      Check (Near (Total_Fitness (Empty), 0.0), "Total_Fitness empty");

      Fit := Shift_Costs_To_Fitness (Costs);
      Check (Near (Fit (1).Fitness, 0.0), "Shift max cost → 0 fitness");
      Check (Near (Fit (2).Fitness, 2.0), "Shift mid cost");
      Check (Near (Fit (3).Fitness, 4.0), "Shift min cost → max fitness");
      Check (Fit (1).Tag = Costs (1).Tag, "Shift preserves tags");

      FlatF := Shift_Costs_To_Fitness (Flat);
      Check (Near (FlatF (1).Fitness, 1.0), "Equal costs → fitness 1");
      Check (Near (FlatF (2).Fitness, 1.0), "Equal costs mid");
      Check (Near (FlatF (3).Fitness, 1.0), "Equal costs last");

      declare
         Raised : Boolean := False;
      begin
         begin
            Fit := Shift_Costs_To_Fitness (Empty);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Shift empty raises");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Selection_Probability");
   ---------------------------------------------------------------------
   declare
      Pop : constant Population := From_Fitness ([1.0, 2.0, 3.0, 4.0]);
      --  F = 10 → p = 0.1, 0.2, 0.3, 0.4
   begin
      Check (Near (Real (Selection_Probability (Pop, 1)), 0.1),
             "p1=0.1 wiki example");
      Check (Near (Real (Selection_Probability (Pop, 2)), 0.2),
             "p2=0.2 wiki example");
      Check (Near (Real (Selection_Probability (Pop, 3)), 0.3),
             "p3=0.3 wiki example");
      Check (Near (Real (Selection_Probability (Pop, 4)), 0.4),
             "p4=0.4 wiki example");
      declare
         S : Real := 0.0;
      begin
         for I in Pop'Range loop
            S := S + Real (Selection_Probability (Pop, I));
         end loop;
         Check (Near (S, 1.0), "probabilities sum to 1");
      end;

      declare
         Raised : Boolean := False;
         P      : Unit_Interval;
         pragma Unreferenced (P);
      begin
         begin
            P := Selection_Probability (Pop, 99);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Selection_Probability bad index raises");
      end;

      declare
         Raised : Boolean := False;
         Z      : constant Population := From_Fitness ([0.0, 0.0]);
         P      : Unit_Interval;
         pragma Unreferenced (P);
      begin
         begin
            P := Selection_Probability (Z, 1);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Selection_Probability F=0 raises");
      end;

      declare
         Raised : Boolean := False;
         Neg    : constant Population := From_Fitness ([1.0, -1.0]);
         P      : Unit_Interval;
         pragma Unreferenced (P);
      begin
         begin
            P := Selection_Probability (Neg, 1);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Selection_Probability neg fitness raises");
      end;

      declare
         One : constant Population := From_Fitness ([1 => 5.0]);
      begin
         Check (Near (Real (Selection_Probability (One, 1)), 1.0),
                "single individual p=1");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Cumulative_Fitness / Map_Pointer");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population := From_Fitness ([1.0, 2.0, 3.0, 4.0]);
      Cumul : Fitness_Array (1 .. 4);
   begin
      Cumul := Cumulative_Fitness (Pop);
      Check (Near (Cumul (1), 1.0), "Cumul[1]=1");
      Check (Near (Cumul (2), 3.0), "Cumul[2]=3");
      Check (Near (Cumul (3), 6.0), "Cumul[3]=6");
      Check (Near (Cumul (4), 10.0), "Cumul[4]=10");

      Check (Map_Pointer (Cumul, 0.0) = 1, "Map 0 → First");
      Check (Map_Pointer (Cumul, -1.0) = 1, "Map neg → First");
      Check (Map_Pointer (Cumul, 0.5) = 1, "Map 0.5 → 1");
      Check (Map_Pointer (Cumul, 1.0) = 1, "Map 1.0 → 1");
      Check (Map_Pointer (Cumul, 1.1) = 2, "Map 1.1 → 2");
      Check (Map_Pointer (Cumul, 3.0) = 2, "Map 3.0 → 2");
      Check (Map_Pointer (Cumul, 3.1) = 3, "Map 3.1 → 3");
      Check (Map_Pointer (Cumul, 6.0) = 3, "Map 6.0 → 3");
      Check (Map_Pointer (Cumul, 6.1) = 4, "Map 6.1 → 4");
      Check (Map_Pointer (Cumul, 10.0) = 4, "Map 10 → 4");
      Check (Map_Pointer (Cumul, 99.0) = 4, "Map beyond → Last");

      declare
         Raised : Boolean := False;
         Empty  : Population (1 .. 0);
         C      : Fitness_Array (1 .. 0);
         pragma Unreferenced (C);
      begin
         begin
            C := Cumulative_Fitness (Empty);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Cumulative empty raises");
      end;

      declare
         Raised : Boolean := False;
         Z      : constant Population := From_Fitness ([0.0, 0.0]);
         C      : Fitness_Array (1 .. 2);
         pragma Unreferenced (C);
      begin
         begin
            C := Cumulative_Fitness (Z);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Cumulative F=0 raises");
      end;

      declare
         Raised : Boolean := False;
         Neg    : constant Population := From_Fitness ([1.0, -0.1]);
         C      : Fitness_Array (1 .. 2);
         pragma Unreferenced (C);
      begin
         begin
            C := Cumulative_Fitness (Neg);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Cumulative neg raises");
      end;

      declare
         Raised : Boolean := False;
         EmptyC : Fitness_Array (1 .. 0);
         I      : Positive;
         pragma Unreferenced (I);
      begin
         begin
            I := Map_Pointer (EmptyC, 0.5);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Map_Pointer empty raises");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Select_One");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population := From_Fitness ([1.0, 2.0, 3.0, 4.0]);
      State : RNG_State;
      Idx   : Positive;
      Ind   : Individual;
      Cfg   : constant Config := Make_Config (Seed => 123);
   begin
      Seed_RNG (State, 123);
      Idx := Select_One (Pop, State);
      Check (Idx in Pop'Range, "Select_One index in range");

      Seed_RNG (State, 123);
      Ind := Select_One (Pop, State);
      Check (Ind.Tag in 1 .. 4, "Select_One Individual Tag");

      Idx := Select_One (Pop, Cfg, State);
      Check (Idx in Pop'Range, "Select_One with Config");

      --  reproducibility
      declare
         A, B : Positive;
         S1, S2 : RNG_State;
      begin
         Seed_RNG (S1, 55);
         Seed_RNG (S2, 55);
         A := Select_One (Pop, S1);
         B := Select_One (Pop, S2);
         Check (A = B, "Select_One reproducible");
      end;

      --  single individual always selected
      declare
         One : constant Population := From_Fitness ([1 => 9.0]);
         S   : RNG_State;
         I   : Positive;
      begin
         Seed_RNG (S, 1);
         I := Select_One (One, S);
         Check (I = 1, "Select_One singleton index");
         Check (Near (Select_One (One, S).Fitness, 9.0),
                "Select_One singleton fitness");
      end;

      --  zero-fitness never selected when others positive
      declare
         Mix : constant Population := From_Fitness ([0.0, 5.0, 0.0]);
         S   : RNG_State;
         Hits : Natural := 0;
         I    : Positive;
      begin
         Seed_RNG (S, 77);
         for K in 1 .. 100 loop
            pragma Unreferenced (K);
            I := Select_One (Mix, S);
            if I = 2 then
               Hits := Hits + 1;
            end if;
         end loop;
         Check (Hits = 100, "Select_One only positive-fitness member");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Select_Parents batch");
   ---------------------------------------------------------------------
   declare
      Pop     : constant Population := From_Fitness ([1.0, 2.0, 3.0, 4.0]);
      State   : RNG_State;
      Idxs    : Index_List (1 .. 20);
      Parents : Population (1 .. 20);
      Cfg     : constant Config := Make_Config (Seed => 7);
      All_Ok  : Boolean;
   begin
      Seed_RNG (State, 7);
      Idxs := Select_Parents (Pop, 20, State);
      Check (Idxs'Length = 20, "Select_Parents Index_List length");
      All_Ok := True;
      for I in Idxs'Range loop
         if Idxs (I) not in Pop'Range then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "Select_Parents indices in range");

      Seed_RNG (State, 7);
      Parents := Select_Parents (Pop, 20, State);
      Check (Parents'Length = 20, "Select_Parents Population length");
      All_Ok := True;
      for I in Parents'Range loop
         if Parents (I).Tag not in 1 .. 4 then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "Select_Parents tags in 1..4");

      declare
         Idxs10 : constant Index_List := Select_Parents (Pop, 10, Cfg, State);
      begin
         Check (Idxs10'Length = 10, "Select_Parents with Config length");
      end;

      --  reproducibility of batch
      declare
         A, B : Index_List (1 .. 8);
         S1, S2 : RNG_State;
         Match : Boolean := True;
      begin
         Seed_RNG (S1, 99);
         Seed_RNG (S2, 99);
         A := Select_Parents (Pop, 8, S1);
         B := Select_Parents (Pop, 8, S2);
         for I in A'Range loop
            if A (I) /= B (I) then
               Match := False;
            end if;
         end loop;
         Check (Match, "Select_Parents reproducible");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Empirical frequency ≈ probability");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population := From_Fitness ([1.0, 2.0, 3.0, 4.0]);
      State : RNG_State;
      Idxs  : Index_List (1 .. 4000);
      C1, C2, C3, C4 : Natural;
      F1, F2, F3, F4 : Real;
   begin
      Seed_RNG (State, 2026);
      Idxs := Select_Parents (Pop, 4000, State);
      C1 := Count_Index (Idxs, 1);
      C2 := Count_Index (Idxs, 2);
      C3 := Count_Index (Idxs, 3);
      C4 := Count_Index (Idxs, 4);
      F1 := Real (C1) / 4000.0;
      F2 := Real (C2) / 4000.0;
      F3 := Real (C3) / 4000.0;
      F4 := Real (C4) / 4000.0;
      --  expect ~0.1, 0.2, 0.3, 0.4 within generous tolerance
      Check (Near (F1, 0.1, 0.04), "freq ≈ p1=0.1");
      Check (Near (F2, 0.2, 0.04), "freq ≈ p2=0.2");
      Check (Near (F3, 0.3, 0.04), "freq ≈ p3=0.3");
      Check (Near (F4, 0.4, 0.04), "freq ≈ p4=0.4");
      Check (C1 + C2 + C3 + C4 = 4000, "empirical counts sum");
      Check (C4 > C3 and then C3 > C2 and then C2 > C1,
             "ordering C4>C3>C2>C1");
   end;

   ---------------------------------------------------------------------
   Section ("10. Equal fitness ≈ uniform");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population := From_Fitness ([5.0, 5.0, 5.0, 5.0]);
      State : RNG_State;
      Idxs  : Index_List (1 .. 2000);
      C     : array (1 .. 4) of Natural := [others => 0];
      Ok    : Boolean := True;
   begin
      Seed_RNG (State, 314);
      Idxs := Select_Parents (Pop, 2000, State);
      for I in Idxs'Range loop
         C (Idxs (I)) := C (Idxs (I)) + 1;
      end loop;
      for J in 1 .. 4 loop
         if not Near (Real (C (J)) / 2000.0, 0.25, 0.05) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "equal fitness ≈ uniform 0.25");
      Check (Near (Real (Selection_Probability (Pop, 1)), 0.25),
             "equal p=0.25");
      Check (Near (Real (Selection_Probability (Pop, 4)), 0.25),
             "equal p last=0.25");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid_Argument paths for Select");
   ---------------------------------------------------------------------
   declare
      Empty : Population (1 .. 0);
      Zero  : constant Population := From_Fitness ([0.0, 0.0]);
      Neg   : constant Population := From_Fitness ([1.0, -2.0]);
      State : RNG_State;
      Idx   : Positive;
      Idxs  : Index_List (1 .. 2);
      Ind   : Individual;
      pragma Unreferenced (Idx, Idxs, Ind);
   begin
      Seed_RNG (State, 1);
      declare
         Raised : Boolean := False;
      begin
         begin
            Idx := Select_One (Empty, State);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Select_One empty raises");
      end;

      declare
         Raised : Boolean := False;
      begin
         begin
            Idx := Select_One (Zero, State);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Select_One F=0 raises");
      end;

      declare
         Raised : Boolean := False;
      begin
         begin
            Idx := Select_One (Neg, State);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Select_One neg raises");
      end;

      declare
         Raised : Boolean := False;
      begin
         begin
            Idxs := Select_Parents (Empty, 2, State);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Select_Parents empty raises");
      end;

      declare
         Raised : Boolean := False;
      begin
         begin
            Idxs := Select_Parents (Zero, 2, State);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Select_Parents F=0 raises");
      end;

      declare
         Raised : Boolean := False;
         Cfg    : constant Config := Default_Config;
      begin
         begin
            Idx := Select_One (Empty, Cfg, State);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Select_One Config empty raises");
      end;

      declare
         Raised : Boolean := False;
         Cfg    : constant Config := Default_Config;
      begin
         begin
            Idxs := Select_Parents (Empty, 3, Cfg, State);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Select_Parents Config empty raises");
      end;

      declare
         Raised : Boolean := False;
      begin
         begin
            Ind := Select_One (Neg, State);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Select_One Individual neg raises");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Shift then select");
   ---------------------------------------------------------------------
   declare
      Costs : constant Population := From_Fitness ([10.0, 4.0, 1.0]);
      Fit   : constant Population := Shift_Costs_To_Fitness (Costs);
      State : RNG_State;
      Idxs  : Index_List (1 .. 3000);
      C1, C2, C3 : Natural;
   begin
      --  costs 10,4,1 → fitness 0,6,9 ; F=15 ; p≈0, 0.4, 0.6
      Check (Near (Fit (1).Fitness, 0.0), "shifted f1=0");
      Check (Near (Fit (2).Fitness, 6.0), "shifted f2=6");
      Check (Near (Fit (3).Fitness, 9.0), "shifted f3=9");
      Check (Near (Total_Fitness (Fit), 15.0), "shifted total 15");
      Check (Near (Real (Selection_Probability (Fit, 2)), 0.4),
             "shifted p2=0.4");
      Check (Near (Real (Selection_Probability (Fit, 3)), 0.6),
             "shifted p3=0.6");

      Seed_RNG (State, 88);
      Idxs := Select_Parents (Fit, 3000, State);
      C1 := Count_Index (Idxs, 1);
      C2 := Count_Index (Idxs, 2);
      C3 := Count_Index (Idxs, 3);
      Check (C1 = 0, "zero-fitness never selected after shift");
      Check (Near (Real (C2) / 3000.0, 0.4, 0.05), "shifted freq ≈ 0.4");
      Check (Near (Real (C3) / 3000.0, 0.6, 0.05), "shifted freq ≈ 0.6");
   end;

   ---------------------------------------------------------------------
   Section ("13. Non-1-based population bounds");
   ---------------------------------------------------------------------
   declare
      Pop : Population (3 .. 5);
      State : RNG_State;
      Cumul : Fitness_Array (3 .. 5);
      Idx   : Positive;
   begin
      Pop (3) := (Fitness => 1.0, Tag => 30);
      Pop (4) := (Fitness => 1.0, Tag => 40);
      Pop (5) := (Fitness => 1.0, Tag => 50);
      Check (Near (Total_Fitness (Pop), 3.0), "non-1-based total");
      Cumul := Cumulative_Fitness (Pop);
      Check (Near (Cumul (3), 1.0), "non-1-based cumul first");
      Check (Near (Cumul (5), 3.0), "non-1-based cumul last");
      Check (Map_Pointer (Cumul, 0.5) = 3, "non-1-based map first");
      Check (Map_Pointer (Cumul, 2.5) = 5, "non-1-based map last");
      Seed_RNG (State, 5);
      Idx := Select_One (Pop, State);
      Check (Idx in 3 .. 5, "Select_One non-1-based index");
      Check (Near (Real (Selection_Probability (Pop, 4)), 1.0 / 3.0),
             "non-1-based mid probability");
   end;

   ---------------------------------------------------------------------
   Section ("14. Dominance / higher spread contrast notes");
   ---------------------------------------------------------------------
   --  With extreme fitness skew, FPS can pick the elite many times in
   --  one batch (higher spread than SUS). Just verify elite dominates.
   declare
      Pop   : constant Population :=
        From_Fitness ([0.01, 0.01, 0.01, 100.0]);
      State : RNG_State;
      Idxs  : Index_List (1 .. 100);
      Elite : Natural;
   begin
      Check (Near (Real (Selection_Probability (Pop, 4)),
                   100.0 / 100.03, 1.0E-6),
             "elite p ≈ 100/100.03");
      Seed_RNG (State, 1);
      Idxs := Select_Parents (Pop, 100, State);
      Elite := Count_Index (Idxs, 4);
      Check (Elite >= 90, "elite dominates independent spins");
      Check (Elite <= 100, "elite count ≤ N");
   end;

   ---------------------------------------------------------------------
   Section ("15. Mixed / wiki pseudocode thresholds");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population := From_Fitness ([1.0, 2.0, 3.0, 4.0]);
      Cumul : constant Fitness_Array := Cumulative_Fitness (Pop);
      --  normalized thresholds as fractions of F would be 0.1,0.3,0.6,1.0
      --  on absolute wheel: 1,3,6,10
   begin
      Check (Near (Cumul (1) / Cumul (4), 0.1), "norm thresh 0.1");
      Check (Near (Cumul (2) / Cumul (4), 0.3), "norm thresh 0.3");
      Check (Near (Cumul (3) / Cumul (4), 0.6), "norm thresh 0.6");
      Check (Near (Cumul (4) / Cumul (4), 1.0), "norm thresh 1.0");

      --  Map Uniform[0,1) style via F*u
      Check (Map_Pointer (Cumul, 10.0 * 0.05) = 1, "u=0.05 → ind 1");
      Check (Map_Pointer (Cumul, 10.0 * 0.15) = 2, "u=0.15 → ind 2");
      Check (Map_Pointer (Cumul, 10.0 * 0.45) = 3, "u=0.45 → ind 3");
      Check (Map_Pointer (Cumul, 10.0 * 0.85) = 4, "u=0.85 → ind 4");
   end;

   ---------------------------------------------------------------------
   Section ("16. Extra API smoke");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population :=
        From_Fitness ([2.0, 2.0, 2.0, 2.0, 2.0]);
      State : RNG_State := 0;
      Cfg   : constant Config := Make_Config (Seed => 404);
      Kids  : Index_List (1 .. 5);
      Ind   : Individual;
   begin
      Check (Near (Total_Fitness (Pop), 10.0), "Five equal total 10");
      Kids := Select_Parents (Pop, 5, Cfg, State);
      Check (Kids'Length = 5, "five parents length");
      Check (Count_Tag (Kids, Pop, 1)
               + Count_Tag (Kids, Pop, 2)
               + Count_Tag (Kids, Pop, 3)
               + Count_Tag (Kids, Pop, 4)
               + Count_Tag (Kids, Pop, 5) = 5,
             "five parents tags accounted");

      Seed_RNG (State, 1);
      Ind := Select_One (Pop, State);
      Check (Near (Ind.Fitness, 2.0), "equal-fit Select_One fitness");

      Check (Valid_Config (Cfg, Pop'Length, Kids'Length),
             "Valid_Config smoke");
      Check (All_Non_Negative (Pop), "All_Non_Negative smoke");
      Check (Near (Real (Selection_Probability (Pop, 3)), 0.2),
             "five equal p=0.2");
   end;

   New_Line;
   Put_Line ("------------------------------------------");
   Put_Line ("Pass_Count =" & Natural'Image (Pass_Count));
   Put_Line ("Fail_Count =" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("RESULT: ALL PASS (>=100)");
   elsif Fail_Count = 0 then
      Put_Line ("RESULT: ALL PASS (but <100 checks)");
   else
      Put_Line ("RESULT: FAILURES");
   end if;
end Tests;
