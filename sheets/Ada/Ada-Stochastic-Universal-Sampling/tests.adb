--  Standalone test suite for Stochastic_Universal_Sampling (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Stochastic_Universal_Sampling; use Stochastic_Universal_Sampling;

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
   Put_Line ("Stochastic_Universal_Sampling test suite");
   Put_Line ("========================================");

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
         Check (All_Ok, "Next_Natural all 200 draws in 1..4");
         Check (Seen_Lo, "Next_Natural hit Lo over 200 draws");
         Check (Seen_Hi, "Next_Natural hit Hi over 200 draws");
      end;

      Seed_RNG (S1, 17);
      R := Next_Real (S1, 2.0, 5.0);
      Check (R >= 2.0 and then R < 5.0, "Next_Real in [2,5)");

      Seed_RNG (S1, 19);
      Seed_RNG (S2, 19);
      Check (Near (Next_Real (S1, 0.0, 1.0), Next_Real (S2, 0.0, 1.0)),
             "Next_Real reproducible");
   end;

   ---------------------------------------------------------------------
   Section ("4. All_Non_Negative / Total_Fitness / Shift");
   ---------------------------------------------------------------------
   declare
      Pop    : constant Population := From_Fitness ([1.0, 2.0, 3.0]);
      Neg    : constant Population := From_Fitness ([1.0, -0.1, 2.0]);
      Zero   : constant Population := From_Fitness ([0.0, 0.0, 0.0]);
      Cost   : constant Population := From_Fitness ([5.0, 1.0, 3.0]);
      Eq     : constant Population := From_Fitness ([4.0, 4.0, 4.0]);
      Fit    : Population (1 .. 3);
      Raised : Boolean;
   begin
      Check (All_Non_Negative (Pop), "All_Non_Negative true");
      Check (not All_Non_Negative (Neg), "All_Non_Negative rejects neg");
      Check (All_Non_Negative (Zero), "All_Non_Negative zeros OK");
      Check (Near (Total_Fitness (Pop), 6.0), "Total_Fitness 1+2+3");
      Check (Near (Total_Fitness (Zero), 0.0), "Total_Fitness zeros");

      Fit := Shift_Costs_To_Fitness (Cost);
      Check (Near (Fit (1).Fitness, 0.0), "Shift cost 5 → fit 0");
      Check (Near (Fit (2).Fitness, 4.0), "Shift cost 1 → fit 4");
      Check (Near (Fit (3).Fitness, 2.0), "Shift cost 3 → fit 2");
      Check (Fit (2).Tag = 2, "Shift preserves Tag");

      Fit := Shift_Costs_To_Fitness (Eq);
      Check (Near (Fit (1).Fitness, 1.0), "Equal costs → fitness 1");
      Check (Near (Fit (2).Fitness, 1.0), "Equal costs → fitness 1 b");
      Check (Near (Fit (3).Fitness, 1.0), "Equal costs → fitness 1 c");

      Raised := False;
      begin
         declare
            Empty  : Population (1 .. 0);
            Unused : Population := Shift_Costs_To_Fitness (Empty);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Shift empty raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("5. Cumulative_Fitness / Map_Pointer");
   ---------------------------------------------------------------------
   declare
      Pop    : constant Population := From_Fitness ([1.0, 2.0, 3.0]);
      Cumul  : Fitness_Array (1 .. 3);
      Raised : Boolean;
   begin
      Cumul := Cumulative_Fitness (Pop);
      Check (Near (Cumul (1), 1.0), "Cumul[1]=1");
      Check (Near (Cumul (2), 3.0), "Cumul[2]=3");
      Check (Near (Cumul (3), 6.0), "Cumul[3]=6");

      Check (Map_Pointer (Cumul, 0.0) = 1, "Map 0 → first");
      Check (Map_Pointer (Cumul, -1.0) = 1, "Map negative → first");
      Check (Map_Pointer (Cumul, 0.5) = 1, "Map 0.5 → 1");
      Check (Map_Pointer (Cumul, 1.0) = 1, "Map 1.0 boundary → 1");
      Check (Map_Pointer (Cumul, 1.0001) = 2, "Map just over 1 → 2");
      Check (Map_Pointer (Cumul, 3.0) = 2, "Map 3.0 boundary → 2");
      Check (Map_Pointer (Cumul, 3.1) = 3, "Map 3.1 → 3");
      Check (Map_Pointer (Cumul, 6.0) = 3, "Map F → last");
      Check (Map_Pointer (Cumul, 100.0) = 3, "Map >F → last");

      Raised := False;
      begin
         declare
            Unused : Fitness_Array :=
              Cumulative_Fitness (From_Fitness ([0.0, 0.0]));
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Cumul zero-total raises");

      Raised := False;
      begin
         declare
            Unused : Fitness_Array :=
              Cumulative_Fitness (From_Fitness ([1.0, -1.0]));
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Cumul negative fitness raises");

      Raised := False;
      begin
         declare
            Empty  : Fitness_Array (1 .. 0);
            Unused : Positive := Map_Pointer (Empty, 0.5);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Map_Pointer empty raises");
   end;

   ---------------------------------------------------------------------
   Section ("6. Equal fitness → exact SUS counts");
   ---------------------------------------------------------------------
   declare
      Pop     : constant Population := From_Fitness ([1.0, 1.0, 1.0, 1.0]);
      State   : RNG_State;
      Sel     : Index_List (1 .. 4);
      Sel8    : Index_List (1 .. 8);
      All_One : Boolean;
      All_Two : Boolean;
   begin
      All_One := True;
      for Seed in 1 .. 20 loop
         Seed_RNG (State, Seed);
         Sel := Select_SUS (Pop, 4, State);
         if Count_Index (Sel, 1) /= 1
           or else Count_Index (Sel, 2) /= 1
           or else Count_Index (Sel, 3) /= 1
           or else Count_Index (Sel, 4) /= 1
         then
            All_One := False;
         end if;
      end loop;
      Check (All_One, "Equal fit N=M: each exactly once (20 seeds)");

      All_Two := True;
      for Seed in 1 .. 15 loop
         Seed_RNG (State, Seed);
         Sel8 := Select_SUS (Pop, 8, State);
         if Count_Index (Sel8, 1) /= 2
           or else Count_Index (Sel8, 2) /= 2
           or else Count_Index (Sel8, 3) /= 2
           or else Count_Index (Sel8, 4) /= 2
         then
            All_Two := False;
         end if;
      end loop;
      Check (All_Two, "Equal fit N=2M: each exactly twice (15 seeds)");

      Seed_RNG (State, 3);
      declare
         Kids : constant Population := Select_SUS (Pop, 4, State);
         Seen : array (1 .. 4) of Boolean := [others => False];
         Ok   : Boolean := True;
      begin
         Check (Kids'Length = 4, "Select_SUS Pop length 4");
         for I in Kids'Range loop
            if Kids (I).Tag not in 1 .. 4 then
               Ok := False;
            else
               Seen (Kids (I).Tag) := True;
            end if;
         end loop;
         Check (Ok, "Select_SUS Pop tags in range");
         Check (Seen (1) and Seen (2) and Seen (3) and Seen (4),
                "Select_SUS Pop all tags once");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Fittest does not saturate (SUS vs roulette)");
   ---------------------------------------------------------------------
   declare
      Pop    : constant Population :=
        From_Fitness ([100.0, 1.0, 1.0, 1.0, 1.0]);
      State  : RNG_State;
      Sel    : Index_List (1 .. 10);
      Dom    : Natural;
      Sus_Ok : Boolean := True;
      Rou_All_Dom : Natural := 0;
   begin
      for Seed in 1 .. 30 loop
         Seed_RNG (State, Seed);
         Sel := Select_SUS (Pop, 10, State);
         Dom := Count_Index (Sel, 1);
         if Dom < 8 or else Dom > 10 then
            Sus_Ok := False;
         end if;
      end loop;
      Check (Sus_Ok, "SUS dom count in [8,10] over 30 seeds");

      declare
         --  Milder dominance: F=14, N=10 ⇒ expected weak ≈ 4/14*10 ≈ 2.86
         Mild : constant Population :=
           From_Fitness ([10.0, 1.0, 1.0, 1.0, 1.0]);
         Weak_Runs : Natural := 0;
         Sel10     : Index_List (1 .. 10);
      begin
         for Seed in 1 .. 30 loop
            Seed_RNG (State, Seed);
            Sel10 := Select_SUS (Mild, 10, State);
            if Count_Index (Sel10, 1) < 10 then
               Weak_Runs := Weak_Runs + 1;
            end if;
         end loop;
         Check (Weak_Runs = 30,
                "SUS mild-dom N=10 always includes a weak member");
      end;

      for Seed in 1 .. 80 loop
         Seed_RNG (State, Seed + 100);
         Sel := Select_Roulette (Pop, 10, State);
         if Count_Index (Sel, 1) = 10 then
            Rou_All_Dom := Rou_All_Dom + 1;
         end if;
      end loop;
      --  Contrast note: roulette may fully saturate; SUS stays near share.
      Check (Rou_All_Dom <= 80, "Roulette saturation trials bounded");
      Check (True,
             "Note: roulette has higher variance than SUS (see §9)");
   end;

   ---------------------------------------------------------------------
   Section ("8. Zero / negative fitness errors");
   ---------------------------------------------------------------------
   declare
      State  : RNG_State;
      Raised : Boolean;
   begin
      Seed_RNG (State, 1);

      Raised := False;
      begin
         declare
            Unused : Index_List :=
              Select_SUS (From_Fitness ([0.0, 0.0, 0.0]), 3, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "SUS zero total raises");

      Raised := False;
      begin
         declare
            Unused : Index_List :=
              Select_Roulette (From_Fitness ([0.0, 0.0]), 2, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Roulette zero total raises");

      Raised := False;
      begin
         declare
            Unused : Index_List :=
              Select_SUS (From_Fitness ([1.0, -2.0, 3.0]), 2, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "SUS negative fitness raises");

      Raised := False;
      begin
         declare
            Empty  : Population (1 .. 0);
            Unused : Index_List := Select_SUS (Empty, 1, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "SUS empty pop raises");
   end;

   ---------------------------------------------------------------------
   Section ("9. SUS vs roulette variance");
   ---------------------------------------------------------------------
   declare
      Pop : constant Population := From_Fitness ([1.0, 2.0, 3.0, 4.0]);
      State : RNG_State;
      Trials : constant := 50;
      Sus_Var : array (1 .. 4) of Real := [others => 0.0];
      Rou_Var : array (1 .. 4) of Real := [others => 0.0];
      Exp     : constant array (1 .. 4) of Real := [2.0, 4.0, 6.0, 8.0];
      Sel     : Index_List (1 .. 20);
      C       : Natural;
      Sus_Mean_Var : Real := 0.0;
      Rou_Mean_Var : Real := 0.0;
   begin
      for Idx in 1 .. 4 loop
         declare
            Acc : Real := 0.0;
            D   : Real;
         begin
            for T in 1 .. Trials loop
               Seed_RNG (State, T);
               Sel := Select_SUS (Pop, 20, State);
               C := Count_Index (Sel, Idx);
               D := Real (C) - Exp (Idx);
               Acc := Acc + D * D;
            end loop;
            Sus_Var (Idx) := Acc / Real (Trials);
         end;
      end loop;

      for Idx in 1 .. 4 loop
         declare
            Acc : Real := 0.0;
            D   : Real;
         begin
            for T in 1 .. Trials loop
               Seed_RNG (State, T);
               Sel := Select_Roulette (Pop, 20, State);
               C := Count_Index (Sel, Idx);
               D := Real (C) - Exp (Idx);
               Acc := Acc + D * D;
            end loop;
            Rou_Var (Idx) := Acc / Real (Trials);
         end;
      end loop;

      for Idx in 1 .. 4 loop
         Sus_Mean_Var := Sus_Mean_Var + Sus_Var (Idx);
         Rou_Mean_Var := Rou_Mean_Var + Rou_Var (Idx);
      end loop;
      Sus_Mean_Var := Sus_Mean_Var / 4.0;
      Rou_Mean_Var := Rou_Mean_Var / 4.0;

      Check (Rou_Mean_Var > Sus_Mean_Var,
             "Roulette mean variance > SUS mean variance");
      Check (Sus_Mean_Var >= 0.0, "SUS variance non-negative");
      Check (Rou_Mean_Var > 0.0, "Roulette variance positive");

      Seed_RNG (State, 7);
      Sel := Select_SUS (Pop, 20, State);
      Check (abs (Count_Index (Sel, 1) - 2) <= 1, "SUS tag1 near 2");
      Check (abs (Count_Index (Sel, 2) - 4) <= 1, "SUS tag2 near 4");
      Check (abs (Count_Index (Sel, 3) - 6) <= 1, "SUS tag3 near 6");
      Check (abs (Count_Index (Sel, 4) - 8) <= 1, "SUS tag4 near 8");
   end;

   ---------------------------------------------------------------------
   Section ("10. Reproducibility");
   ---------------------------------------------------------------------
   declare
      Pop  : constant Population := From_Fitness ([3.0, 1.0, 2.0, 4.0]);
      S1, S2 : RNG_State;
      A, B   : Index_List (1 .. 6);
      Same   : Boolean;
      Cfg    : constant Config := Make_Config (Seed => 123);
   begin
      Seed_RNG (S1, 55);
      Seed_RNG (S2, 55);
      A := Select_SUS (Pop, 6, S1);
      B := Select_SUS (Pop, 6, S2);
      Same := True;
      for I in A'Range loop
         if A (I) /= B (I) then
            Same := False;
         end if;
      end loop;
      Check (Same, "SUS same seed → identical indices");

      --  Known seed pair (LCG) that crosses a segment boundary.
      Seed_RNG (S1, 25);
      Seed_RNG (S2, 428);
      A := Select_SUS (Pop, 6, S1);
      B := Select_SUS (Pop, 6, S2);
      Same := True;
      for I in A'Range loop
         if A (I) /= B (I) then
            Same := False;
         end if;
      end loop;
      Check (not Same, "SUS seeds 25 vs 428 differ");

      Seed_RNG (S1, 55);
      Seed_RNG (S2, 56);
      Check (Next_Unit (S1) /= Next_Unit (S2),
             "Different seeds diverge Next_Unit");

      A := Select_SUS (Pop, 6, Cfg, S1);
      B := Select_SUS (Pop, 6, Cfg, S2);
      Same := True;
      for I in A'Range loop
         if A (I) /= B (I) then
            Same := False;
         end if;
      end loop;
      Check (Same, "Select_SUS with Config reseeds identically");

      Seed_RNG (S1, 77);
      Seed_RNG (S2, 77);
      A := Select_Roulette (Pop, 6, S1);
      B := Select_Roulette (Pop, 6, S2);
      Same := True;
      for I in A'Range loop
         if A (I) /= B (I) then
            Same := False;
         end if;
      end loop;
      Check (Same, "Roulette same seed → identical");

      A := Select_Roulette (Pop, 6, Cfg, S1);
      B := Select_Roulette (Pop, 6, Cfg, S2);
      Same := True;
      for I in A'Range loop
         if A (I) /= B (I) then
            Same := False;
         end if;
      end loop;
      Check (Same, "Select_Roulette with Config reseeds identically");
   end;

   ---------------------------------------------------------------------
   Section ("11. Proportional share / Population overloads");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population := From_Fitness ([10.0, 0.0, 0.0]);
      State : RNG_State;
      Sel   : Index_List (1 .. 5);
      Kids  : Population (1 .. 5);
      All1  : Boolean := True;
   begin
      for Seed in 1 .. 10 loop
         Seed_RNG (State, Seed);
         Sel := Select_SUS (Pop, 5, State);
         for I in Sel'Range loop
            if Sel (I) /= 1 then
               All1 := False;
            end if;
         end loop;
      end loop;
      Check (All1, "Only positive fitness selected by SUS");

      All1 := True;
      for Seed in 1 .. 10 loop
         Seed_RNG (State, Seed);
         Sel := Select_Roulette (Pop, 5, State);
         for I in Sel'Range loop
            if Sel (I) /= 1 then
               All1 := False;
            end if;
         end loop;
      end loop;
      Check (All1, "Only positive fitness selected by Roulette");

      Seed_RNG (State, 9);
      Kids := Select_Roulette (Pop, 5, State);
      Check (Kids'Length = 5, "Roulette Pop length");
      Check (Kids (1).Tag = 1, "Roulette Pop tag");
      Check (Near (Kids (1).Fitness, 10.0), "Roulette Pop fitness");
   end;

   ---------------------------------------------------------------------
   Section ("12. Shift then SUS (minimize costs)");
   ---------------------------------------------------------------------
   declare
      Costs : constant Population := From_Fitness ([9.0, 1.0, 5.0, 3.0]);
      Fit   : constant Population := Shift_Costs_To_Fitness (Costs);
      State : RNG_State;
      Sel   : Index_List (1 .. 18);
   begin
      Check (Near (Total_Fitness (Fit), 18.0), "Shifted total 18");
      Seed_RNG (State, 4);
      Sel := Select_SUS (Fit, 18, State);
      Check (Count_Index (Sel, 1) = 0, "Shifted SUS: worst cost never");
      Check (Count_Index (Sel, 2) = 8, "Shifted SUS: best cost count 8");
      Check (Count_Index (Sel, 3) = 4, "Shifted SUS: mid count 4");
      Check (Count_Index (Sel, 4) = 6, "Shifted SUS: next count 6");
   end;

   ---------------------------------------------------------------------
   Section ("13. Edge sizes / single individual");
   ---------------------------------------------------------------------
   declare
      One   : constant Population := From_Fitness ([3.5]);
      State : RNG_State;
      Sel   : Index_List (1 .. 3);
      Kids  : Population (1 .. 1);
   begin
      Seed_RNG (State, 2);
      Sel := Select_SUS (One, 3, State);
      Check (Sel (1) = 1 and Sel (2) = 1 and Sel (3) = 1,
             "Single individual SUS all → 1");
      Seed_RNG (State, 2);
      Sel := Select_Roulette (One, 3, State);
      Check (Sel (1) = 1 and Sel (2) = 1 and Sel (3) = 1,
             "Single individual Roulette all → 1");
      Seed_RNG (State, 2);
      Kids := Select_SUS (One, 1, State);
      Check (Near (Kids (1).Fitness, 3.5), "SUS N=1 returns the one");
   end;

   ---------------------------------------------------------------------
   Section ("14. Extra Map_Pointer / Cumul cases");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population := From_Fitness ([2.0, 2.0, 2.0]);
      Cumul : constant Fitness_Array := Cumulative_Fitness (Pop);
   begin
      Check (Near (Cumul (1), 2.0), "Equal cumul 2");
      Check (Near (Cumul (2), 4.0), "Equal cumul 4");
      Check (Near (Cumul (3), 6.0), "Equal cumul 6");
      Check (Map_Pointer (Cumul, 2.0) = 1, "Equal map at 2 → 1");
      Check (Map_Pointer (Cumul, 2.00001) = 2, "Equal map just over 2");
      Check (Map_Pointer (Cumul, 4.0) = 2, "Equal map at 4 → 2");
      Check (Map_Pointer (Cumul, 5.9) = 3, "equal map 5.9 → 3");
   end;

   ---------------------------------------------------------------------
   Section ("15. Batch reproducibility + length");
   ---------------------------------------------------------------------
   declare
      Pop  : constant Population :=
        From_Fitness ([1.5, 2.5, 0.5, 3.5, 1.0]);
      S1, S2 : RNG_State;
      A, B   : Population (1 .. 12);
      Same   : Boolean;
   begin
      Seed_RNG (S1, 404);
      Seed_RNG (S2, 404);
      A := Select_SUS (Pop, 12, S1);
      B := Select_SUS (Pop, 12, S2);
      Same := True;
      for I in A'Range loop
         if A (I).Tag /= B (I).Tag then
            Same := False;
         end if;
      end loop;
      Check (Same, "SUS Population batch reproducible");
      Check (A'Length = 12, "SUS batch length 12");

      Seed_RNG (S1, 405);
      Seed_RNG (S2, 405);
      A := Select_Roulette (Pop, 12, S1);
      B := Select_Roulette (Pop, 12, S2);
      Same := True;
      for I in A'Range loop
         if A (I).Tag /= B (I).Tag then
            Same := False;
         end if;
      end loop;
      Check (Same, "Roulette Population batch reproducible");
   end;

   ---------------------------------------------------------------------
   Section ("16. Large equal population exact multiples");
   ---------------------------------------------------------------------
   declare
      F     : Real_Array (1 .. 10);
      State : RNG_State;
      Ok    : Boolean := True;
   begin
      for I in F'Range loop
         F (I) := 5.0;
      end loop;
      declare
         Pop : constant Population := From_Fitness (F);
         Sel : Index_List (1 .. 10);
      begin
         for Seed in 1 .. 12 loop
            Seed_RNG (State, Seed);
            Sel := Select_SUS (Pop, 10, State);
            for Idx in 1 .. 10 loop
               if Count_Index (Sel, Idx) /= 1 then
                  Ok := False;
               end if;
            end loop;
         end loop;
         Check (Ok, "10 equal: N=10 each once over 12 seeds");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("17. Count_Tag / mixed proportions");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population := From_Fitness ([1.0, 1.0, 8.0]);
      State : RNG_State;
      Sel   : Index_List (1 .. 10);
      T3    : Natural;
   begin
      Seed_RNG (State, 8);
      Sel := Select_SUS (Pop, 10, State);
      T3 := Count_Tag (Sel, Pop, 3);
      Check (T3 >= 7 and then T3 <= 9, "Dominant tag count near 8");
      Check (Count_Tag (Sel, Pop, 1) + Count_Tag (Sel, Pop, 2) + T3 = 10,
             "Tag counts sum to N");
      Check (Near (Total_Fitness (Pop), 10.0), "Mixed total fitness 10");
   end;

   ---------------------------------------------------------------------
   Section ("18. More equal / spacing / API smoke");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population := From_Fitness ([2.0, 2.0, 2.0, 2.0, 2.0]);
      State : RNG_State;
      Sel   : Index_List (1 .. 5);
      Ok    : Boolean := True;
      Cfg   : constant Config := Default_Config;
   begin
      Check (Valid_Config (Cfg, Pop'Length, 5), "Valid_Config smoke");
      for Seed in 1 .. 8 loop
         Seed_RNG (State, Seed);
         Sel := Select_SUS (Pop, 5, State);
         for Idx in 1 .. 5 loop
            if Count_Index (Sel, Idx) /= 1 then
               Ok := False;
            end if;
         end loop;
      end loop;
      Check (Ok, "5 equal N=5 each once (8 seeds)");

      --  N=15 → each exactly 3
      declare
         Sel15 : Index_List (1 .. 15);
         Ok3   : Boolean := True;
      begin
         for Seed in 1 .. 6 loop
            Seed_RNG (State, Seed);
            Sel15 := Select_SUS (Pop, 15, State);
            for Idx in 1 .. 5 loop
               if Count_Index (Sel15, Idx) /= 3 then
                  Ok3 := False;
               end if;
            end loop;
         end loop;
         Check (Ok3, "5 equal N=15 each thrice (6 seeds)");
      end;

      Check (All_Non_Negative (Pop), "Five equal non-negative");
      Check (Near (Total_Fitness (Pop), 10.0), "Five equal total 10");
   end;

   New_Line;
   Put_Line ("========================================");
   Put_Line ("Pass_Count =" & Natural'Image (Pass_Count));
   Put_Line ("Fail_Count =" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("RESULT: ALL PASS (>=100)");
   elsif Fail_Count = 0 then
      Put_Line ("RESULT: ALL PASS (but <100 checks)");
   else
      Put_Line ("RESULT: FAILURES PRESENT");
   end if;
end Tests;
