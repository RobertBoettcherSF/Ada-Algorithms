--  Standalone test suite for Tournament_Selection (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Tournament_Selection; use Tournament_Selection;

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

   function Contains_Index (List : Index_List; Idx : Positive) return Boolean
   is
   begin
      for I in List'Range loop
         if List (I) = Idx then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Index;

   function All_Distinct (List : Index_List) return Boolean is
   begin
      for I in List'Range loop
         for J in I + 1 .. List'Last loop
            if List (I) = List (J) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end All_Distinct;

   function All_In_Range
     (List : Index_List; Lo, Hi : Positive) return Boolean
   is
   begin
      for I in List'Range loop
         if List (I) < Lo or else List (I) > Hi then
            return False;
         end if;
      end loop;
      return True;
   end All_In_Range;

begin
   Put_Line ("Tournament_Selection test suite");
   Put_Line ("===============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Better / Better_Or_Equal");
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

      Check (Better (3.0, 2.0, Maximize), "Better max 3>2");
      Check (not Better (2.0, 3.0, Maximize), "Better max 2!>3");
      Check (not Better (2.0, 2.0, Maximize), "Better max equal false");
      Check (Better (1.0, 2.0, Minimize), "Better min 1<2");
      Check (not Better (2.0, 1.0, Minimize), "Better min 2!<1");
      Check (not Better (2.0, 2.0, Minimize), "Better min equal false");
      Check (Better_Or_Equal (2.0, 2.0, Maximize), "Better_Or_Equal max =");
      Check (Better_Or_Equal (2.0, 2.0, Minimize), "Better_Or_Equal min =");
      Check (Better_Or_Equal (5.0, 1.0, Maximize), "Better_Or_Equal max >");
      Check (Better_Or_Equal (1.0, 5.0, Minimize), "Better_Or_Equal min <");
      Check (not Better_Or_Equal (1.0, 5.0, Maximize), "Better_Or_Equal max <");
      Check (not Better_Or_Equal (5.0, 1.0, Minimize), "Better_Or_Equal min >");
   end;

   ---------------------------------------------------------------------
   Section ("2. Config / Valid_Config / Make_Config");
   ---------------------------------------------------------------------
   declare
      D : constant Config := Default_Config;
      C : Config;
   begin
      Check (D.K = 2, "Default K=2");
      Check (Near (Real (D.P), 1.0), "Default P=1");
      Check (D.With_Replacement, "Default with replacement");
      Check (D.Sense = Maximize, "Default Maximize");
      Check (D.Seed = 1, "Default Seed=1");

      C := Make_Config
        (K => 5, P => 0.75, With_Replacement => False,
         Sense => Minimize, Seed => 99);
      Check (C.K = 5, "Make_Config K");
      Check (Near (Real (C.P), 0.75), "Make_Config P");
      Check (not C.With_Replacement, "Make_Config no replacement");
      Check (C.Sense = Minimize, "Make_Config Minimize");
      Check (C.Seed = 99, "Make_Config Seed");

      Check (Valid_Config (D, 10), "Valid_Config default N=10");
      Check (Valid_Config (D, 1), "Valid_Config N=1 K=2 w/ repl");
      Check (not Valid_Config (D, 0), "Valid_Config rejects N=0");

      C := Make_Config (K => 5, With_Replacement => False);
      Check (Valid_Config (C, 5), "Valid_Config K=N w/o repl");
      Check (Valid_Config (C, 6), "Valid_Config K<N w/o repl");
      Check (not Valid_Config (C, 4), "Valid_Config rejects K>N w/o repl");

      C := Make_Config (K => 100, With_Replacement => True);
      Check (Valid_Config (C, 3), "Valid_Config large K w/ repl OK");
   end;

   ---------------------------------------------------------------------
   Section ("3. RNG Seed / Next_Unit / Next_Natural");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U          : Unit_Interval;
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
      begin
         declare
            All_Ok : Boolean := True;
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
      end;
   end;

   ---------------------------------------------------------------------
   Section ("4. Draw_Contestants with / without replacement");
   ---------------------------------------------------------------------
   declare
      Pop    : constant Population :=
        From_Fitness ([1.0, 2.0, 3.0, 4.0, 5.0]);
      State  : RNG_State;
      Raised : Boolean;
      C      : Index_List (1 .. 3);
   begin
      Seed_RNG (State, 1);
      C := Draw_Contestants (Pop, 3, True, State);
      Check (C'Length = 3, "Draw w/ repl length 3");
      Check (All_In_Range (C, Pop'First, Pop'Last),
             "Draw w/ repl indices in range");

      Seed_RNG (State, 2);
      C := Draw_Contestants (Pop, 3, False, State);
      Check (C'Length = 3, "Draw w/o repl length 3");
      Check (All_Distinct (C), "Draw w/o repl all distinct");
      Check (All_In_Range (C, Pop'First, Pop'Last),
             "Draw w/o repl indices in range");

      --  K = N without replacement → permutation of all indices
      declare
         Full : Index_List (1 .. 5);
      begin
         Seed_RNG (State, 3);
         Full := Draw_Contestants (Pop, 5, False, State);
         Check (All_Distinct (Full), "Draw K=N w/o repl distinct");
         Check (All_In_Range (Full, 1, 5), "Draw K=N w/o repl range");
         for Idx in 1 .. 5 loop
            Check (Contains_Index (Full, Idx),
                   "Draw K=N contains index" & Integer'Image (Idx));
         end loop;
      end;

      --  K = 1
      declare
         One : Index_List (1 .. 1);
      begin
         Seed_RNG (State, 4);
         One := Draw_Contestants (Pop, 1, True, State);
         Check (One (1) in Pop'Range, "Draw K=1 w/ repl");
         Seed_RNG (State, 5);
         One := Draw_Contestants (Pop, 1, False, State);
         Check (One (1) in Pop'Range, "Draw K=1 w/o repl");
      end;

      Raised := False;
      begin
         declare
            Empty : Population (1 .. 0);
            Unused : Index_List :=
              Draw_Contestants (Empty, 1, True, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Draw empty pop raises");

      Raised := False;
      begin
         declare
            Unused : Index_List :=
              Draw_Contestants (Pop, 6, False, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Draw K>N w/o repl raises");

      --  With replacement may produce duplicates (try many times)
      declare
         Found_Dup : Boolean := False;
         Trial     : Index_List (1 .. 5);
      begin
         Seed_RNG (State, 100);
         for T in 1 .. 50 loop
            pragma Unreferenced (T);
            Trial := Draw_Contestants (Pop, 5, True, State);
            if not All_Distinct (Trial) then
               Found_Dup := True;
               exit;
            end if;
         end loop;
         Check (Found_Dup, "Draw w/ repl can duplicate");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Soft_Pick deterministic and soft");
   ---------------------------------------------------------------------
   declare
      Pop    : constant Population :=
        From_Fitness ([10.0, 1.0, 7.0, 3.0]);
      --  Tags: 1=10, 2=1, 3=7, 4=3
      State  : RNG_State;
      Cont   : Index_List (1 .. 3);
      Win    : Positive;
      Raised : Boolean;
   begin
      Cont := [1, 2, 4];  -- fitnesses 10, 1, 3 → best is index 1
      Seed_RNG (State, 1);
      Win := Soft_Pick (Pop, Cont, 1.0, Maximize, State);
      Check (Win = 1, "Soft_Pick P=1 picks best maximize");

      Cont := [2, 4, 3];  -- 1, 3, 7 → best max is 3
      Seed_RNG (State, 1);
      Win := Soft_Pick (Pop, Cont, 1.0, Maximize, State);
      Check (Win = 3, "Soft_Pick P=1 best among 2,4,3");

      Cont := [1, 2, 4];  -- minimize: best is index 2 (fitness 1)
      Seed_RNG (State, 1);
      Win := Soft_Pick (Pop, Cont, 1.0, Minimize, State);
      Check (Win = 2, "Soft_Pick P=1 picks best minimize");

      declare
         One_C : constant Index_List := [1];
      begin
         Seed_RNG (State, 1);
         Win := Soft_Pick (Pop, One_C, 0.0, Maximize, State);
         Check (Win = 1, "Soft_Pick K=1 always that contestant");
      end;

      --  Soft P=0 always picks worst among contestants
      Cont := [1, 2, 3];  -- 10, 1, 7 → worst max is 2
      declare
         Always_Worst : Boolean := True;
      begin
         Seed_RNG (State, 9);
         for T in 1 .. 30 loop
            pragma Unreferenced (T);
            Win := Soft_Pick (Pop, Cont, 0.0, Maximize, State);
            if Win /= 2 then
               Always_Worst := False;
            end if;
         end loop;
         Check (Always_Worst, "Soft_Pick P=0 always worst maximize");
      end;

      Cont := [1, 2, 3];  -- minimize: worst is index 1 (fitness 10)
      declare
         Always_Worst : Boolean := True;
      begin
         Seed_RNG (State, 9);
         for T in 1 .. 30 loop
            pragma Unreferenced (T);
            Win := Soft_Pick (Pop, Cont, 0.0, Minimize, State);
            if Win /= 1 then
               Always_Worst := False;
            end if;
         end loop;
         Check (Always_Worst, "Soft_Pick P=0 always worst minimize");
      end;

      --  Soft P=0.8 mostly picks best but not always
      Cont := [1, 2, 3];  -- best max = 1
      declare
         Best_Hits : Natural := 0;
         Other     : Natural := 0;
      begin
         Seed_RNG (State, 21);
         for T in 1 .. 200 loop
            pragma Unreferenced (T);
            Win := Soft_Pick (Pop, Cont, 0.8, Maximize, State);
            if Win = 1 then
               Best_Hits := Best_Hits + 1;
            else
               Other := Other + 1;
            end if;
         end loop;
         Check (Best_Hits > 100, "Soft P=0.8 mostly best");
         Check (Other > 0, "Soft P=0.8 sometimes not best");
      end;

      Raised := False;
      begin
         declare
            Empty_C : Index_List (1 .. 0);
            Unused  : Positive :=
              Soft_Pick (Pop, Empty_C, 1.0, Maximize, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Soft_Pick empty contestants raises");

      Raised := False;
      begin
         declare
            Bad    : constant Index_List := [1, 99];
            Unused : Positive :=
              Soft_Pick (Pop, Bad, 1.0, Maximize, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Soft_Pick out-of-range index raises");
   end;

   ---------------------------------------------------------------------
   Section ("6. Tournament_Winner / Select_One deterministic");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population :=
        From_Fitness ([1.0, 9.0, 4.0, 6.0, 2.0]);
      --  best max Tag=2 fitness 9; best min Tag=1 fitness 1
      State : RNG_State;
      Cfg   : Config;
      Win   : Positive;
      Ind   : Individual;
   begin
      --  K = N without replacement + P=1 ⇒ always global best
      Cfg := Make_Config
        (K => 5, P => 1.0, With_Replacement => False,
         Sense => Maximize, Seed => 1);
      Seed_RNG (State, Cfg);
      declare
         Always : Boolean := True;
      begin
         for T in 1 .. 20 loop
            pragma Unreferenced (T);
            Win := Tournament_Winner (Pop, Cfg, State);
            if Win /= 2 then
               Always := False;
            end if;
         end loop;
         Check (Always, "Full-pop tournament always global max");
      end;

      Cfg.Sense := Minimize;
      Seed_RNG (State, Cfg);
      declare
         Always : Boolean := True;
      begin
         for T in 1 .. 20 loop
            pragma Unreferenced (T);
            Win := Tournament_Winner (Pop, Cfg, State);
            if Win /= 1 then
               Always := False;
            end if;
         end loop;
         Check (Always, "Full-pop tournament always global min");
      end;

      --  Select_One returns Individual with matching fitness/tag
      Cfg := Make_Config
        (K => 5, P => 1.0, With_Replacement => False, Sense => Maximize);
      Seed_RNG (State, 3);
      Ind := Select_One (Pop, Cfg, State);
      Check (Ind.Tag = 2, "Select_One full-pop Tag=2");
      Check (Near (Ind.Fitness, 9.0), "Select_One full-pop Fitness=9");

      Cfg.Sense := Minimize;
      Seed_RNG (State, 3);
      Ind := Select_One (Pop, Cfg, State);
      Check (Ind.Tag = 1, "Select_One full-pop min Tag=1");
      Check (Near (Ind.Fitness, 1.0), "Select_One full-pop min Fitness=1");
   end;

   ---------------------------------------------------------------------
   Section ("7. K=1 equivalent to random selection");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population :=
        From_Fitness ([10.0, 20.0, 30.0, 40.0]);
      State : RNG_State;
      Cfg   : constant Config :=
        Make_Config (K => 1, P => 1.0, With_Replacement => True,
                     Sense => Maximize);
      Counts : array (1 .. 4) of Natural := [others => 0];
      Win    : Positive;
   begin
      Seed_RNG (State, 50);
      for T in 1 .. 400 loop
         pragma Unreferenced (T);
         Win := Tournament_Winner (Pop, Cfg, State);
         Counts (Win) := Counts (Win) + 1;
      end loop;
      for I in Counts'Range loop
         Check (Counts (I) > 40,
                "K=1 hits index" & Integer'Image (I) & " often enough");
      end loop;
      Check (Counts (1) + Counts (2) + Counts (3) + Counts (4) = 400,
             "K=1 total 400");
   end;

   ---------------------------------------------------------------------
   Section ("8. Larger K ⇒ higher selection pressure");
   ---------------------------------------------------------------------
   declare
      Pop : constant Population :=
        From_Fitness ([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]);
      --  Tag 8 is unique best under Maximize
      State : RNG_State;
      Cfg   : Config;
      Wins_K1 : Natural := 0;
      Wins_K2 : Natural := 0;
      Wins_K4 : Natural := 0;
      Wins_K8 : Natural := 0;
      Ind     : Individual;
      Trials  : constant := 300;
   begin
      Cfg := Make_Config
        (K => 1, P => 1.0, With_Replacement => True, Sense => Maximize);
      Seed_RNG (State, 77);
      for T in 1 .. Trials loop
         pragma Unreferenced (T);
         Ind := Select_One (Pop, Cfg, State);
         if Ind.Tag = 8 then
            Wins_K1 := Wins_K1 + 1;
         end if;
      end loop;

      Cfg.K := 2;
      Seed_RNG (State, 77);
      for T in 1 .. Trials loop
         pragma Unreferenced (T);
         Ind := Select_One (Pop, Cfg, State);
         if Ind.Tag = 8 then
            Wins_K2 := Wins_K2 + 1;
         end if;
      end loop;

      Cfg.K := 4;
      Seed_RNG (State, 77);
      for T in 1 .. Trials loop
         pragma Unreferenced (T);
         Ind := Select_One (Pop, Cfg, State);
         if Ind.Tag = 8 then
            Wins_K4 := Wins_K4 + 1;
         end if;
      end loop;

      Cfg.K := 8;
      Cfg.With_Replacement := False;
      Seed_RNG (State, 77);
      for T in 1 .. Trials loop
         pragma Unreferenced (T);
         Ind := Select_One (Pop, Cfg, State);
         if Ind.Tag = 8 then
            Wins_K8 := Wins_K8 + 1;
         end if;
      end loop;

      Check (Wins_K1 < Wins_K2 or else Wins_K2 > Trials / 20,
             "Pressure K=1 vs K=2 trend");
      Check (Wins_K2 <= Wins_K4 + 30, "Pressure K=2 not much above K=4");
      Check (Wins_K4 < Wins_K8 or else Wins_K8 = Trials,
             "Pressure K=4 vs K=8 trend");
      Check (Wins_K8 = Trials, "K=N w/o repl always best");
      Check (Wins_K1 < Trials / 2, "K=1 best rate modest");
      Check (Wins_K4 > Wins_K1, "K=4 beats K=1 on best-hit rate");
   end;

   ---------------------------------------------------------------------
   Section ("9. Select_Parents batch");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population :=
        From_Fitness ([0.5, 1.5, 2.5, 3.5, 4.5]);
      State : RNG_State;
      Cfg   : Config :=
        Make_Config (K => 3, P => 1.0, With_Replacement => True,
                     Sense => Maximize, Seed => 8);
      Parents : Population (1 .. 10);
      Idxs    : Index_List (1 .. 10);
   begin
      Seed_RNG (State, Cfg);
      Parents := Select_Parents (Pop, 10, Cfg, State);
      Check (Parents'Length = 10, "Select_Parents Population length");
      for I in Parents'Range loop
         Check (Parents (I).Tag in 1 .. 5,
                "Parent Tag in range #" & Integer'Image (I));
      end loop;

      Seed_RNG (State, Cfg);
      Idxs := Select_Parents (Pop, 10, Cfg, State);
      Check (Idxs'Length = 10, "Select_Parents Index_List length");
      Check (All_In_Range (Idxs, 1, 5), "Parent indices in range");

      --  Reproducibility: same seed → same sequence
      declare
         S_A, S_B : RNG_State;
         A, B     : Population (1 .. 5);
      begin
         Seed_RNG (S_A, 123);
         Seed_RNG (S_B, 123);
         A := Select_Parents (Pop, 5, Cfg, S_A);
         B := Select_Parents (Pop, 5, Cfg, S_B);
         declare
            Same : Boolean := True;
         begin
            for I in A'Range loop
               if A (I).Tag /= B (I).Tag then
                  Same := False;
               end if;
            end loop;
            Check (Same, "Select_Parents reproducible");
         end;
      end;

      --  Minimize sense parents tend toward low fitness
      Cfg.Sense := Minimize;
      Cfg.K := 5;
      Cfg.With_Replacement := False;
      declare
         Min_Parents   : Population (1 .. 20);
         Best_Min_Hits : Natural := 0;
      begin
         Seed_RNG (State, 9);
         Min_Parents := Select_Parents (Pop, 20, Cfg, State);
         for I in Min_Parents'Range loop
            if Min_Parents (I).Tag = 1 then
               Best_Min_Hits := Best_Min_Hits + 1;
            end if;
         end loop;
         Check (Best_Min_Hits = 20,
                "Full-pop min Select_Parents always Tag 1");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Invalid_Argument paths");
   ---------------------------------------------------------------------
   declare
      Pop    : constant Population := From_Fitness ([1.0, 2.0, 3.0]);
      Empty  : Population (1 .. 0);
      State  : RNG_State;
      Cfg    : Config;
      Raised : Boolean;
   begin
      Seed_RNG (State, 1);

      Raised := False;
      Cfg := Make_Config (K => 2);
      begin
         declare
            Unused : Positive := Tournament_Winner (Empty, Cfg, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Tournament_Winner empty raises");

      Raised := False;
      begin
         declare
            Unused : Individual := Select_One (Empty, Cfg, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Select_One empty raises");

      Raised := False;
      begin
         declare
            Unused : Population := Select_Parents (Empty, 2, Cfg, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Select_Parents empty raises");

      Raised := False;
      Cfg := Make_Config (K => 5, With_Replacement => False);
      begin
         declare
            Unused : Positive := Tournament_Winner (Pop, Cfg, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Tournament_Winner K>N w/o repl raises");

      Raised := False;
      begin
         declare
            Unused : Index_List :=
              Select_Parents (Pop, 3, Cfg, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Select_Parents Index_List K>N raises");
   end;

   ---------------------------------------------------------------------
   Section ("11. Soft tournament via Config + with-replacement K>N");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population :=
        From_Fitness ([1.0, 100.0, 2.0]);
      State : RNG_State;
      Cfg   : Config :=
        Make_Config (K => 10, P => 1.0, With_Replacement => True,
                     Sense => Maximize);
      Ind   : Individual;
      Hits  : Natural := 0;
   begin
      --  Large K with replacement + P=1 strongly favors best
      Seed_RNG (State, 33);
      for T in 1 .. 50 loop
         pragma Unreferenced (T);
         Ind := Select_One (Pop, Cfg, State);
         if Ind.Tag = 2 then
            Hits := Hits + 1;
         end if;
      end loop;
      Check (Hits >= 45, "Large-K w/ repl almost always best");

      Cfg.P := 0.5;
      Hits := 0;
      Seed_RNG (State, 33);
      for T in 1 .. 100 loop
         pragma Unreferenced (T);
         Ind := Select_One (Pop, Cfg, State);
         if Ind.Tag = 2 then
            Hits := Hits + 1;
         end if;
      end loop;
      Check (Hits < 100, "Soft P=0.5 not always best");
      Check (Hits > 20, "Soft P=0.5 still often best");
   end;

   ---------------------------------------------------------------------
   Section ("12. Negative fitness / single-individual population");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population :=
        From_Fitness ([-10.0, -1.0, -5.0]);
      State : RNG_State;
      Cfg   : Config;
      Ind   : Individual;
      Solo  : constant Population :=
        From_Fitness ([42.0]);
   begin
      Cfg := Make_Config
        (K => 3, P => 1.0, With_Replacement => False, Sense => Maximize);
      Seed_RNG (State, 1);
      Ind := Select_One (Pop, Cfg, State);
      Check (Near (Ind.Fitness, -1.0), "Neg fitness maximize best=-1");

      Cfg.Sense := Minimize;
      Seed_RNG (State, 1);
      Ind := Select_One (Pop, Cfg, State);
      Check (Near (Ind.Fitness, -10.0), "Neg fitness minimize best=-10");

      Cfg := Make_Config (K => 1, Sense => Maximize);
      Seed_RNG (State, 2);
      Ind := Select_One (Solo, Cfg, State);
      Check (Near (Ind.Fitness, 42.0) and then Ind.Tag = 1,
             "Solo population Select_One");
      Check (Valid_Config (Cfg, 1), "Valid_Config solo K=1");
      Cfg.K := 2;
      Check (Valid_Config (Cfg, 1), "Valid_Config solo K=2 w/ repl");
      Cfg.With_Replacement := False;
      Check (not Valid_Config (Cfg, 1),
             "Valid_Config solo K=2 w/o repl false");
   end;

   ---------------------------------------------------------------------
   Section ("13. Extra pressure / reproducibility spot checks");
   ---------------------------------------------------------------------
   declare
      Pop   : constant Population :=
        From_Fitness ([3.0, 1.0, 4.0, 1.0, 5.0, 9.0, 2.0, 6.0]);
      State : RNG_State;
      Cfg   : constant Config :=
        Make_Config (K => 4, P => 1.0, With_Replacement => True,
                     Sense => Maximize, Seed => 2026);
      A, B  : Index_List (1 .. 15);
   begin
      Seed_RNG (State, Cfg);
      A := Select_Parents (Pop, 15, Cfg, State);
      Seed_RNG (State, Cfg);
      B := Select_Parents (Pop, 15, Cfg, State);
      declare
         Same : Boolean := True;
      begin
         for I in A'Range loop
            if A (I) /= B (I) then
               Same := False;
            end if;
         end loop;
         Check (Same, "Index Select_Parents reproducible");
      end;

      --  Best Tag=6 fitness 9 should appear often under K=4
      declare
         Hits : Natural := 0;
      begin
         for I in A'Range loop
            if Pop (A (I)).Tag = 6 then
               Hits := Hits + 1;
            end if;
         end loop;
         Check (Hits >= 3, "K=4 max often picks global best");
      end;

      --  Minimize counterpart
      declare
         Cfg_Min : Config := Cfg;
         Hits    : Natural := 0;
         Sample  : Population (1 .. 40);
      begin
         Cfg_Min.Sense := Minimize;
         --  best min tags are 2 or 4 (fitness 1.0)
         Seed_RNG (State, 55);
         Sample := Select_Parents (Pop, 40, Cfg_Min, State);
         for I in Sample'Range loop
            if Near (Sample (I).Fitness, 1.0) then
               Hits := Hits + 1;
            end if;
         end loop;
         Check (Hits >= 10, "K=4 min often picks fitness 1");
      end;
   end;

   New_Line;
   Put_Line ("===============================");
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
