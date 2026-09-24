--  Standalone test suite for Truncation_Selection (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Truncation_Selection; use Truncation_Selection;

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

   function Contains_Tag (Pool : Population; Tag : Natural) return Boolean is
   begin
      for I in Pool'Range loop
         if Pool (I).Tag = Tag then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Tag;

   function All_Tags_In
     (Sample : Population; Allowed : Population) return Boolean
   is
   begin
      for I in Sample'Range loop
         if not Contains_Tag (Allowed, Sample (I).Tag) then
            return False;
         end if;
      end loop;
      return True;
   end All_Tags_In;

   function Is_Sorted_Best_First
     (Pop : Population; Sense : Fitness_Sense) return Boolean
   is
   begin
      for I in Pop'First .. Pop'Last - 1 loop
         if Better (Pop (I + 1).Fitness, Pop (I).Fitness, Sense) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted_Best_First;

begin
   Put_Line ("Truncation_Selection test suite");
   Put_Line ("===============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Valid_T / Better");
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

      Check (Valid_T (1.0), "Valid_T(1)");
      Check (Valid_T (0.5), "Valid_T(0.5)");
      Check (Valid_T (0.01), "Valid_T(0.01)");
      Check (Valid_T (Real'Model_Small), "Valid_T(Model_Small)");
      Check (not Valid_T (0.0), "Valid_T rejects 0");
      Check (not Valid_T (-0.1), "Valid_T rejects negative");
      Check (not Valid_T (1.0001), "Valid_T rejects >1");
      Check (not Valid_T (2.0), "Valid_T rejects 2");

      Check (Better (3.0, 2.0, Maximize), "Better max 3>2");
      Check (not Better (2.0, 3.0, Maximize), "Better max 2!>3");
      Check (not Better (2.0, 2.0, Maximize), "Better max equal false");
      Check (Better (1.0, 2.0, Minimize), "Better min 1<2");
      Check (not Better (2.0, 1.0, Minimize), "Better min 2!<1");
      Check (Better_Or_Equal (2.0, 2.0, Maximize), "Better_Or_Equal max =");
      Check (Better_Or_Equal (2.0, 2.0, Minimize), "Better_Or_equal min =");
      Check (Better_Or_Equal (5.0, 1.0, Maximize), "Better_Or_Equal max >");
      Check (Better_Or_Equal (1.0, 5.0, Minimize), "Better_Or_Equal min <");
   end;

   ---------------------------------------------------------------------
   Section ("2. Truncation_Count = ceil(T*N)");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Check (Truncation_Count (10, 0.5) = 5, "ceil(0.5*10)=5");
      Check (Truncation_Count (10, 1.0) = 10, "ceil(1.0*10)=10");
      Check (Truncation_Count (10, 0.1) = 1, "ceil(0.1*10)=1");
      Check (Truncation_Count (5, 0.5) = 3, "ceil(0.5*5)=3");
      Check (Truncation_Count (7, 0.3) = 3, "ceil(0.3*7)=3");
      Check (Truncation_Count (7, 0.2) = 2, "ceil(0.2*7)=2");
      Check (Truncation_Count (1, 0.01) = 1, "ceil(0.01*1)=1 clamp");
      Check (Truncation_Count (1, 1.0) = 1, "ceil(1*1)=1");
      Check (Truncation_Count (100, 0.25) = 25, "ceil(0.25*100)=25");
      Check (Truncation_Count (9, 0.34) = 4, "ceil(0.34*9)=4");
      Check (Truncation_Count (8, 0.125) = 1, "ceil(0.125*8)=1");
      Check (Truncation_Count (8, 0.126) = 2, "ceil(0.126*8)=2");
      Check (Truncation_Count (3, 0.4) = 2, "ceil(0.4*3)=2");
      Check (Truncation_Count (20, 0.05) = 1, "ceil(0.05*20)=1");
      Check (Truncation_Count (20, 0.051) = 2, "ceil(0.051*20)=2");

      Raised := False;
      begin
         declare
            Unused : Positive := Truncation_Count (0, 0.5);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Truncation_Count N=0 raises");

      Raised := False;
      begin
         declare
            Unused : Positive := Truncation_Count (10, 0.0);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Truncation_Count T=0 raises");

      Raised := False;
      begin
         declare
            Unused : Positive := Truncation_Count (10, -0.5);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Truncation_Count T<0 raises");

      Raised := False;
      begin
         declare
            Unused : Positive := Truncation_Count (10, 1.5);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Truncation_Count T>1 raises");
   end;


   ---------------------------------------------------------------------
   Section ("3. Sort_By_Fitness ranking (maximize / minimize)");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      declare
         P : constant Population :=
           From_Fitness ([3.0, 1.0, 4.0, 2.0, 5.0]);
         S : constant Population := Sort_By_Fitness (P, Maximize);
      begin
         Check (S (1).Fitness = 5.0 and then S (1).Tag = 5, "Max rank #1 Tag5");
         Check (S (2).Fitness = 4.0 and then S (2).Tag = 3, "Max rank #2 Tag3");
         Check (S (3).Fitness = 3.0 and then S (3).Tag = 1, "Max rank #3 Tag1");
         Check (S (4).Fitness = 2.0 and then S (4).Tag = 4, "Max rank #4 Tag4");
         Check (S (5).Fitness = 1.0 and then S (5).Tag = 2, "Max rank #5 Tag2");
         Check (Is_Sorted_Best_First (S, Maximize), "Max fully sorted");
      end;

      declare
         P : constant Population :=
           From_Fitness ([3.0, 1.0, 4.0, 2.0, 5.0]);
         S : constant Population := Sort_By_Fitness (P, Minimize);
      begin
         Check (S (1).Fitness = 1.0 and then S (1).Tag = 2, "Min rank #1 Tag2");
         Check (S (2).Fitness = 2.0 and then S (2).Tag = 4, "Min rank #2 Tag4");
         Check (S (3).Fitness = 3.0 and then S (3).Tag = 1, "Min rank #3 Tag1");
         Check (S (4).Fitness = 4.0 and then S (4).Tag = 3, "Min rank #4 Tag3");
         Check (S (5).Fitness = 5.0 and then S (5).Tag = 5, "Min rank #5 Tag5");
         Check (Is_Sorted_Best_First (S, Minimize), "Min fully sorted");
      end;

      declare
         P : Population := From_Fitness ([10.0, -1.0, 0.0]);
      begin
         Sort_By_Fitness (P, Maximize);
         Check (P (1).Fitness = 10.0 and then P (3).Fitness = -1.0,
                "In-place max sort ends");
         Sort_By_Fitness (P, Minimize);
         Check (P (1).Fitness = -1.0 and then P (3).Fitness = 10.0,
                "In-place min sort ends");
      end;

      declare
         P : Population := From_Fitness ([2.0, 2.0, 2.0]);
         S : Population (1 .. 3);
      begin
         P (1).Tag := 10;
         P (2).Tag := 20;
         P (3).Tag := 30;
         S := Sort_By_Fitness (P, Maximize);
         Check (S (1).Tag = 10 and then S (2).Tag = 20 and then S (3).Tag = 30,
                "Stable ties maximize");
         S := Sort_By_Fitness (P, Minimize);
         Check (S (1).Tag = 10 and then S (2).Tag = 20 and then S (3).Tag = 30,
                "Stable ties minimize");
      end;

      declare
         P : constant Population := From_Fitness ([1 => 42.0]);
         S : constant Population := Sort_By_Fitness (P, Maximize);
      begin
         Check (S'Length = 1 and then Near (S (1).Fitness, 42.0),
                "Singleton sort");
      end;

      Raised := False;
      begin
         declare
            Empty  : Population (1 .. 0);
            Unused : Population := Sort_By_Fitness (Empty, Maximize);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Sort empty raises");
   end;

   ---------------------------------------------------------------------
   Section ("4. Select_Pool by T (elites only, size ceil(T*N))");
   ---------------------------------------------------------------------
   declare
      P : Population (1 .. 10);
      Raised : Boolean;
   begin
      for I in P'Range loop
         P (I) := (Fitness => Real (I), Tag => I);
      end loop;

      declare
         Pool : constant Population := Select_Pool (P, 0.5, Maximize);
      begin
         Check (Pool'Length = 5, "T=0.5 N=10 pool len 5");
         Check (Contains_Tag (Pool, 10)
           and then Contains_Tag (Pool, 9)
           and then Contains_Tag (Pool, 8)
           and then Contains_Tag (Pool, 7)
           and then Contains_Tag (Pool, 6),
                "T=0.5 max elites 6..10");
         Check (not Contains_Tag (Pool, 5)
           and then not Contains_Tag (Pool, 1),
                "T=0.5 max excludes non-elites");
      end;

      declare
         Pool : constant Population := Select_Pool (P, 0.5, Minimize);
      begin
         Check (Pool'Length = 5, "T=0.5 min pool len 5");
         Check (Contains_Tag (Pool, 1)
           and then Contains_Tag (Pool, 2)
           and then Contains_Tag (Pool, 3)
           and then Contains_Tag (Pool, 4)
           and then Contains_Tag (Pool, 5),
                "T=0.5 min elites 1..5");
         Check (not Contains_Tag (Pool, 6)
           and then not Contains_Tag (Pool, 10),
                "T=0.5 min excludes non-elites");
      end;

      declare
         Pool : constant Population := Select_Pool (P, 0.1, Maximize);
      begin
         Check (Pool'Length = 1 and then Pool (1).Tag = 10,
                "T=0.1 max single elite Tag10");
      end;

      declare
         Pool : constant Population := Select_Pool (P, 1.0, Maximize);
      begin
         Check (Pool'Length = 10, "T=1.0 keeps all");
      end;

      declare
         Pool : constant Population := Select_Pool (P, 0.3, Maximize);
      begin
         Check (Pool'Length = Truncation_Count (10, 0.3),
                "T=0.3 length matches Truncation_Count");
         Check (Pool'Length = 3, "T=0.3 N=10 → 3");
         Check (Pool (1).Tag = 10 and then Pool (2).Tag = 9
           and then Pool (3).Tag = 8,
                "T=0.3 max top-3 order");
      end;

      declare
         Q : constant Population :=
           From_Fitness ([1.0, 5.0, 3.0, 4.0, 2.0]);
         R : constant Population := Select_Pool (Q, 0.5, Maximize);
         S : constant Population := Select_Pool (Q, 0.5, Minimize);
      begin
         Check (R'Length = 3, "N=5 T=0.5 → K=3");
         Check (R (1).Fitness = 5.0 and then R (2).Fitness = 4.0
           and then R (3).Fitness = 3.0,
                "N=5 T=0.5 max fitnesses");
         Check (S'Length = 3, "N=5 T=0.5 min K=3");
         Check (S (1).Fitness = 1.0 and then S (2).Fitness = 2.0
           and then S (3).Fitness = 3.0,
                "N=5 T=0.5 min fitnesses");
      end;

      Raised := False;
      begin
         declare
            Empty  : Population (1 .. 0);
            Unused : Population := Select_Pool (Empty, 0.5, Maximize);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Select_Pool empty raises");

      Raised := False;
      begin
         declare
            Unused : Population := Select_Pool (P, 0.0, Maximize);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Select_Pool invalid T raises");
   end;

   ---------------------------------------------------------------------
   Section ("5. Select_Pool by K");
   ---------------------------------------------------------------------
   declare
      P : constant Population :=
        From_Fitness ([9.0, 1.0, 8.0, 2.0, 7.0, 3.0]);
   begin
      declare
         Pool : constant Population := Select_Pool (P, 2, Maximize);
      begin
         Check (Pool'Length = 2, "K=2 max len");
         Check (Pool (1).Fitness = 9.0 and then Pool (2).Fitness = 8.0,
                "K=2 max elites");
      end;

      declare
         Pool : constant Population := Select_Pool (P, 2, Minimize);
      begin
         Check (Pool'Length = 2, "K=2 min len");
         Check (Pool (1).Fitness = 1.0 and then Pool (2).Fitness = 2.0,
                "K=2 min elites");
      end;

      declare
         Pool : constant Population := Select_Pool (P, 100, Maximize);
      begin
         Check (Pool'Length = 6, "K>N clamps to N");
         Check (Is_Sorted_Best_First (Pool, Maximize), "K>N still sorted max");
      end;

      declare
         Pool : constant Population := Select_Pool (P, 1, Minimize);
      begin
         Check (Pool'Length = 1 and then Near (Pool (1).Fitness, 1.0),
                "K=1 min single");
      end;

      declare
         Pool : constant Population := Select_Pool (P, 1, Maximize);
      begin
         Check (Pool'Length = 1 and then Near (Pool (1).Fitness, 9.0),
                "K=1 max single");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. RNG determinism / range");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U1, U2     : Unit_Interval;
      All_In     : Boolean := True;
      Saw_Diff   : Boolean := False;
      N          : Natural;
   begin
      Seed_RNG (S1, 42);
      Seed_RNG (S2, 42);
      Seed_RNG (S3, 99);
      U1 := Next_Unit (S1);
      U2 := Next_Unit (S2);
      Check (Near (Real (U1), Real (U2)), "RNG same seed same first");
      Check (not Near (Real (Next_Unit (S1)), Real (Next_Unit (S3))),
             "RNG different seeds diverge");

      Seed_RNG (S1, 7);
      for I in 1 .. 200 loop
         U1 := Next_Unit (S1);
         if Real (U1) < 0.0 or else Real (U1) >= 1.0 then
            All_In := False;
         end if;
         if I > 1 and then not Near (Real (U1), Real (U2)) then
            Saw_Diff := True;
         end if;
         U2 := U1;
      end loop;
      Check (All_In, "Next_Unit in [0,1)");
      Check (Saw_Diff, "Next_Unit not stuck");

      Seed_RNG (S1, 3);
      All_In := True;
      for I in 1 .. 100 loop
         N := Next_Natural (S1, 5, 9);
         if N < 5 or else N > 9 then
            All_In := False;
         end if;
      end loop;
      Check (All_In, "Next_Natural in Lo..Hi");
      Check (Next_Natural (S1, 4, 4) = 4, "Next_Natural Lo=Hi");

      Seed_RNG (S1, 0);
      Seed_RNG (S2, 0);
      Check (Near (Real (Next_Unit (S1)), Real (Next_Unit (S2))),
             "Seed 0 maps consistently");
   end;

   ---------------------------------------------------------------------
   Section ("7. Select_Parent_Index / Select_Parents (elites only)");
   ---------------------------------------------------------------------
   declare
      P : Population (1 .. 8);
      State : RNG_State;
      Ok : Boolean;
      Raised : Boolean;
      Counts : array (1 .. 8) of Natural := [others => 0];
   begin
      for I in P'Range loop
         P (I) := (Fitness => Real (I), Tag => I);
      end loop;

      declare
         Pool : constant Population := Select_Pool (P, 0.25, Maximize);
         Idx  : Positive;
      begin
         Check (Pool'Length = 2, "sample pool size 2");

         Seed_RNG (State, 11);
         Ok := True;
         for I in 1 .. 80 loop
            Idx := Select_Parent_Index (Pool, State);
            declare
               Tg : constant Natural := Pool (Idx).Tag;
            begin
               if Tg /= 7 and then Tg /= 8 then
                  Ok := False;
               end if;
               Counts (Tg) := Counts (Tg) + 1;
            end;
         end loop;
         Check (Ok, "Parent indices map to elite tags");
         Check (Counts (8) > 0 and then Counts (7) > 0,
                "Both elites sampled");
         Check (Counts (1) = 0 and then Counts (6) = 0,
                "Non-elites never sampled");

         Seed_RNG (State, 21);
         declare
            Ids : constant Index_List := Select_Parents (Pool, 50, State);
         begin
            Check (Ids'Length = 50, "Select_Parents index length");
            Ok := True;
            for I in Ids'Range loop
               declare
                  Tg : constant Natural := Pool (Ids (I)).Tag;
               begin
                  if Tg /= 7 and then Tg /= 8 then
                     Ok := False;
                  end if;
               end;
            end loop;
            Check (Ok, "All parent indices valid");
         end;

         Seed_RNG (State, 22);
         declare
            Samp : constant Population := Select_Parents (Pool, 50, State);
            Seen_Dup : Boolean := False;
            First_Tag : constant Natural := Samp (1).Tag;
         begin
            Check (Samp'Length = 50, "Select_Parents pop length");
            Check (All_Tags_In (Samp, Pool), "Sampled tags ⊆ pool");
            for I in 2 .. Samp'Last loop
               if Samp (I).Tag = First_Tag then
                  Seen_Dup := True;
                  exit;
               end if;
            end loop;
            Check (Seen_Dup or else Samp'Length < 3,
                   "With-replacement duplicates likely");
         end;
      end;

      Raised := False;
      begin
         declare
            Empty  : Population (1 .. 0);
            Unused : Positive;
         begin
            Seed_RNG (State, 1);
            Unused := Select_Parent_Index (Empty, State);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Select_Parent_Index empty raises");

      Raised := False;
      begin
         declare
            Empty  : Population (1 .. 0);
            Unused : Index_List := Select_Parents (Empty, 3, State);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Select_Parents empty raises");
   end;

   ---------------------------------------------------------------------
   Section ("8. Sampling distribution sanity (uniform over pool)");
   ---------------------------------------------------------------------
   declare
      P : Population (1 .. 6);
      State : RNG_State;
      Counts : array (1 .. 3) of Natural := [others => 0];
      Total : constant := 3000;
      Idx : Positive;
      Min_C, Max_C : Natural;
      Mean : Real;
   begin
      for I in P'Range loop
         P (I) := (Fitness => Real (I), Tag => I);
      end loop;

      declare
         Pool : constant Population := Select_Pool (P, 0.5, Maximize);
      begin
         Check (Pool'Length = 3, "dist pool len 3");

         Seed_RNG (State, 12345);
         for I in 1 .. Total loop
            Idx := Select_Parent_Index (Pool, State);
            Counts (Idx - Pool'First + 1) :=
              Counts (Idx - Pool'First + 1) + 1;
         end loop;

         Min_C := Counts (1);
         Max_C := Counts (1);
         for I in Counts'Range loop
            if Counts (I) < Min_C then
               Min_C := Counts (I);
            end if;
            if Counts (I) > Max_C then
               Max_C := Counts (I);
            end if;
         end loop;
         Mean := Real (Total) / 3.0;
         Check (Counts (1) + Counts (2) + Counts (3) = Total,
                "dist counts sum to Total");
         Check (abs (Real (Counts (1)) - Mean) < 0.25 * Mean
           and then abs (Real (Counts (2)) - Mean) < 0.25 * Mean
           and then abs (Real (Counts (3)) - Mean) < 0.25 * Mean,
                "dist roughly uniform (±25%)");
         Check (Min_C > Total / 10, "dist no starved bin");
         Check (Max_C < (Total * 2) / 3, "dist no monopolized bin");
      end;

      declare
         Pool : constant Population := Select_Pool (P, 0.5, Minimize);
         Outside : Natural := 0;
         Samp : Population (1 .. 200);
      begin
         Seed_RNG (State, 99);
         Samp := Select_Parents (Pool, 200, State);
         for I in Samp'Range loop
            if Samp (I).Tag >= 4 then
               Outside := Outside + 1;
            end if;
         end loop;
         Check (Outside = 0, "min sample never outside elites");
         Check (All_Tags_In (Samp, Pool), "min sample ⊆ pool");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Maximize vs Minimize end-to-end");
   ---------------------------------------------------------------------
   declare
      P : constant Population :=
        From_Fitness ([0.0, 10.0, 5.0, 7.0, 2.0, 9.0, 1.0, 8.0]);
      State : RNG_State;
   begin
      declare
         Max_P : constant Population := Select_Pool (P, 0.25, Maximize);
         Min_P : constant Population := Select_Pool (P, 0.25, Minimize);
      begin
         Check (Max_P'Length = 2 and then Min_P'Length = 2,
                "sense pools same K");
         Check (Near (Max_P (1).Fitness, 10.0)
           and then Near (Max_P (2).Fitness, 9.0),
                "max pool fitnesses");
         Check (Near (Min_P (1).Fitness, 0.0)
           and then Near (Min_P (2).Fitness, 1.0),
                "min pool fitnesses");
         Check (Max_P (1).Tag /= Min_P (1).Tag
           or else Max_P (2).Tag /= Min_P (2).Tag,
                "max/min pools differ");

         Seed_RNG (State, 5);
         declare
            Samp : constant Population := Select_Parents (Max_P, 40, State);
         begin
            Check (All_Tags_In (Samp, Max_P), "max parents from max pool");
         end;

         Seed_RNG (State, 5);
         declare
            Samp : constant Population := Select_Parents (Min_P, 40, State);
         begin
            Check (All_Tags_In (Samp, Min_P), "min parents from min pool");
         end;
      end;

      for N in 1 .. 15 loop
         declare
            Q : Population (1 .. N);
            T : constant Real := 0.4;
            K : constant Positive := Truncation_Count (N, T);
         begin
            for I in Q'Range loop
               Q (I) := (Fitness => Real (I), Tag => I);
            end loop;
            declare
               R : constant Population := Select_Pool (Q, T, Maximize);
            begin
               Check (R'Length = K,
                      "N=" & Natural'Image (N) & " T=0.4 len=K");
            end;
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Edge / reproducibility");
   ---------------------------------------------------------------------
   declare
      P : Population := From_Fitness ([1.0, 2.0, 3.0, 4.0]);
      S1, S2 : RNG_State;
      Match : Boolean := True;
   begin
      declare
         Pool1 : constant Population := Select_Pool (P, 1, Maximize);
      begin
         Check (Pool1'Length = 1 and then Pool1 (1).Tag = 4,
                "K=1 edge max");
      end;

      declare
         Pool1 : constant Population := Select_Pool (P, 4, Minimize);
      begin
         Check (Pool1'Length = 4
           and then Is_Sorted_Best_First (Pool1, Minimize),
                "K=N edge min sorted");
      end;

      declare
         Pool1 : constant Population := Select_Pool (P, 0.5, Maximize);
         Pool2 : constant Population := Select_Pool (P, 0.5, Maximize);
      begin
         Check (Pool1'Length = Pool2'Length
           and then Pool1 (1).Tag = Pool2 (1).Tag
           and then Pool1 (2).Tag = Pool2 (2).Tag,
                "Select_Pool deterministic");

         Seed_RNG (S1, 77);
         Seed_RNG (S2, 77);
         declare
            A : constant Index_List := Select_Parents (Pool1, 20, S1);
            B : constant Index_List := Select_Parents (Pool2, 20, S2);
         begin
            for I in A'Range loop
               if A (I) /= B (I) then
                  Match := False;
               end if;
            end loop;
            Check (Match, "Select_Parents reproducible with seed");
         end;
      end;

      P := From_Fitness ([-10.0, -1.0, -5.0, -3.0]);
      declare
         Pool1 : constant Population := Select_Pool (P, 0.5, Maximize);
      begin
         Check (Near (Pool1 (1).Fitness, -1.0)
           and then Near (Pool1 (2).Fitness, -3.0),
                "negative fitness maximize");
      end;
      declare
         Pool1 : constant Population := Select_Pool (P, 0.5, Minimize);
      begin
         Check (Near (Pool1 (1).Fitness, -10.0)
           and then Near (Pool1 (2).Fitness, -5.0),
                "negative fitness minimize");
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
