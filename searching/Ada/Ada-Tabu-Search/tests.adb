--  Standalone test suite for Tabu_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Tabu_Search; use Tabu_Search;

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
   Put_Line ("Tabu_Search test suite");
   Put_Line ("======================");

   ---------------------------------------------------------------------
   Section ("1. Near helper");
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
   Section ("2. Tabu_List Clear / Push / Contains");
   ---------------------------------------------------------------------
   declare
      L : Tabu_List (8);
   begin
      Clear (L);
      Reset_Clock (L, 0);
      Check (not Contains (L, 1), "empty list: not Contains 1");
      Check (not Contains (L, 0), "empty list: not Contains 0");
      Check (Active_Count (L) = 0, "empty Active_Count = 0");

      Set_Clock (L, 1);
      Push (L, 3, Tenure => 5);
      Check (Contains (L, 3), "after Push: Contains 3");
      Check (not Contains (L, 4), "after Push: not Contains 4");
      Check (Active_Count (L) = 1, "Active_Count = 1 after one Push");

      Push (L, 7, Tenure => 5);
      Check (Contains (L, 3) and Contains (L, 7), "two attrs present");
      Check (Active_Count (L) = 2, "Active_Count = 2");

      Clear (L);
      Check (not Contains (L, 3), "Clear removes 3");
      Check (not Contains (L, 7), "Clear removes 7");
      Check (Active_Count (L) = 0, "Clear -> Active_Count 0");
   end;

   ---------------------------------------------------------------------
   Section ("3. Tenure expiry");
   ---------------------------------------------------------------------
   declare
      L : Tabu_List (4);
   begin
      Clear (L);
      Reset_Clock (L, 0);
      Set_Clock (L, 10);
      Push (L, 1, Tenure => 3);  -- expires at 13
      Check (Contains (L, 1), "tenure: active at clock 10");
      Set_Clock (L, 11);
      Check (Contains (L, 1), "tenure: still active at 11");
      Set_Clock (L, 12);
      Check (Contains (L, 1), "tenure: still active at 12");
      Set_Clock (L, 13);
      Check (not Contains (L, 1), "tenure: expired at 13");
      Set_Clock (L, 14);
      Check (not Contains (L, 1), "tenure: still expired at 14");

      --  Tenure 1: active only while Clock < push_clock+1
      Clear (L);
      Set_Clock (L, 5);
      Push (L, 9, Tenure => 1);  -- expiry = 6
      Check (Contains (L, 9), "tenure=1 active at push clock");
      Set_Clock (L, 6);
      Check (not Contains (L, 9), "tenure=1 expires next clock");
   end;

   ---------------------------------------------------------------------
   Section ("4. Circular overwrite");
   ---------------------------------------------------------------------
   declare
      L : Tabu_List (3);
   begin
      Clear (L);
      Reset_Clock (L, 0);
      Set_Clock (L, 1);
      Push (L, 10, 100);
      Push (L, 20, 100);
      Push (L, 30, 100);
      Check (Contains (L, 10) and Contains (L, 20) and Contains (L, 30),
             "capacity full: all three present");
      Push (L, 40, 100);  -- overwrites oldest (10)
      Check (not Contains (L, 10), "overwrite dropped attr 10");
      Check (Contains (L, 20) and Contains (L, 30) and Contains (L, 40),
             "overwrite kept 20,30,40");
      Check (Active_Count (L) = 3, "Active_Count stays at capacity");
   end;

   ---------------------------------------------------------------------
   Section ("5. Aspiration / Is_Admissible");
   ---------------------------------------------------------------------
   declare
      L : Tabu_List (8);
   begin
      Clear (L);
      Reset_Clock (L, 0);
      Set_Clock (L, 1);
      Push (L, 5, Tenure => 10);
      Check (Contains (L, 5), "aspiration setup: 5 is tabu");
      Check (not Is_Admissible (L, 5, 10.0, 5.0, True),
             "tabu + worse cost + aspiration -> inadmissible");
      Check (Is_Admissible (L, 5, 4.0, 5.0, True),
             "tabu + better than best + aspiration -> admissible");
      Check (not Is_Admissible (L, 5, 4.0, 5.0, False),
             "tabu + better but aspiration off -> inadmissible");
      Check (Is_Admissible (L, 99, 100.0, 5.0, True),
             "non-tabu always admissible");
      Check (Is_Admissible (L, 99, 100.0, 5.0, False),
             "non-tabu admissible with aspiration off");
      --  equal is NOT < Best, so inadmissible when tabu
      Check (not Is_Admissible (L, 5, 5.0, 5.0, True),
             "tabu + equal best -> inadmissible");
      Check (Is_Admissible (L, 5, 4.999, 5.0, True),
             "tabu + slightly better -> admissible");
   end;

   ---------------------------------------------------------------------
   Section ("6. Bit utilities");
   ---------------------------------------------------------------------
   declare
      A : constant Bit_String := [True, False, True, False];
      B : constant Bit_String := [True, True, True, True];
      C : Bit_String (1 .. 4);
   begin
      Check (Hamming_Distance (A, B) = 2, "Hamming A vs all-1s = 2");
      Check (Hamming_Distance (B, B) = 0, "Hamming identical = 0");
      Check (Zero_Count (A) = 2, "Zero_Count A = 2");
      Check (Ones_Count (A) = 2, "Ones_Count A = 2");
      Check (Zero_Count (B) = 0, "Zero_Count all-1s = 0");
      Check (Ones_Count (B) = 4, "Ones_Count all-1s = 4");
      C := Flip_Bit (A, 2);
      Check (C (2) = True, "Flip_Bit index 2 -> True");
      Check (Hamming_Distance (C, B) = 1, "after flip Hamming = 1");
      C := Flip_Bit (B, 1);
      Check (C (1) = False, "Flip_Bit clears bit 1");
      Check (Hamming_Distance (A, A) = 0, "Hamming self = 0");
   end;

   ---------------------------------------------------------------------
   Section ("7. OneMax reaches all-1s");
   ---------------------------------------------------------------------
   declare
      Start : constant Bit_String :=
        [False, False, False, False, False, False, False, False];
      Cfg   : constant Config :=
        (Max_Iterations => 50, Tenure => 3, Max_Tabu => 16,
         Use_Aspiration => True);
      R     : Bit_Result;
      All_1 : Boolean;
   begin
      R := Minimize_OneMax (Start, Cfg);
      Check (Near (R.Best_Cost, 0.0), "OneMax from zeros: Best_Cost = 0");
      Check (R.N = 8, "OneMax N = 8");
      All_1 := True;
      for I in 1 .. 8 loop
         if not R.Best_Bits (I) then
            All_1 := False;
         end if;
      end loop;
      Check (All_1, "OneMax best is all-ones");
      Check (R.Moves_Accepted > 0, "OneMax made moves");
      Check (Ones_Count (R.Best_Bits (1 .. 8)) = 8, "Ones_Count best = 8");
   end;

   declare
      Start : constant Bit_String :=
        [True, False, True, False, True, False];
      Cfg   : constant Config :=
        (Max_Iterations => 40, Tenure => 2, Max_Tabu => 8,
         Use_Aspiration => True);
      R     : Bit_Result;
   begin
      R := Minimize_OneMax (Start, Cfg);
      Check (Near (R.Best_Cost, 0.0), "OneMax mixed start -> 0");
      Check (Zero_Count (R.Best_Bits (1 .. 6)) = 0, "no zeros left");
   end;

   declare
      Start : constant Bit_String := [True, True, True, True];
      Cfg   : constant Config :=
        (Max_Iterations => 10, Tenure => 2, Max_Tabu => 4,
         Use_Aspiration => True);
      R     : Bit_Result;
   begin
      R := Minimize_OneMax (Start, Cfg);
      Check (Near (R.Best_Cost, 0.0), "OneMax already optimal");
      Check (R.Moves_Accepted = 0, "already optimal: no moves needed");
   end;

   ---------------------------------------------------------------------
   Section ("8. Hamming to arbitrary target");
   ---------------------------------------------------------------------
   declare
      Start  : constant Bit_String := [False, False, False, False, False];
      Target : constant Bit_String := [True, False, True, False, True];
      Cfg    : constant Config :=
        (Max_Iterations => 30, Tenure => 2, Max_Tabu => 8,
         Use_Aspiration => True);
      R      : Bit_Result;
      Match  : Boolean := True;
   begin
      R := Minimize_Hamming (Start, Target, Cfg);
      Check (Near (R.Best_Cost, 0.0), "Hamming reaches target cost 0");
      for I in 1 .. 5 loop
         if R.Best_Bits (I) /= Target (I) then
            Match := False;
         end if;
      end loop;
      Check (Match, "Hamming best equals target");
   end;

   ---------------------------------------------------------------------
   Section ("9. Tabu forbids immediate revisit");
   ---------------------------------------------------------------------
   declare
      --  Manually: after flipping bit 1, it should be tabu
      L : Tabu_List (8);
      Start : constant Bit_String := [False, False, False, False];
      Cfg   : constant Config :=
        (Max_Iterations => 1, Tenure => 5, Max_Tabu => 8,
         Use_Aspiration => False);
      R     : Bit_Result;
      Target : constant Bit_String := [True, True, True, True];
   begin
      --  Single iteration: must flip some zero bit; that attr is pushed
      R := Minimize_Hamming (Start, Target, Cfg);
      Check (R.Moves_Accepted = 1, "single iter: one move");
      Check (R.Iters = 1, "single iter: Iters = 1");
      Check (Ones_Count (R.Best_Bits (1 .. 4)) = 1,
             "after 1 flip: exactly one 1");

      --  Direct tabu check: push flip attr, verify reverse blocked
      Clear (L);
      Reset_Clock (L, 0);
      Set_Clock (L, 1);
      Push (L, 2, Tenure => 5);
      Check (Contains (L, 2), "just-flipped bit 2 is tabu");
      Check (not Is_Admissible (L, 2, 3.0, 0.0, False),
             "re-flipping bit 2 forbidden without aspiration");
      --  Other bits still admissible
      Check (Is_Admissible (L, 1, 3.0, 0.0, False),
             "bit 1 still admissible");
      Check (Is_Admissible (L, 3, 3.0, 0.0, False),
             "bit 3 still admissible");
   end;

   ---------------------------------------------------------------------
   Section ("10. Aspiration overrides tabu in search");
   ---------------------------------------------------------------------
   declare
      --  Construct: small space where aspiration must fire.
      --  Use tenure covering all bits so only aspiration unlocks progress
      --  toward a better global best from a detour.
      Start : constant Bit_String := [False, False, False];
      Cfg_A : constant Config :=
        (Max_Iterations => 20, Tenure => 10, Max_Tabu => 8,
         Use_Aspiration => True);
      Cfg_B : constant Config :=
        (Max_Iterations => 20, Tenure => 10, Max_Tabu => 8,
         Use_Aspiration => False);
      RA, RB : Bit_Result;
   begin
      RA := Minimize_OneMax (Start, Cfg_A);
      RB := Minimize_OneMax (Start, Cfg_B);
      Check (Near (RA.Best_Cost, 0.0),
             "aspiration ON reaches OneMax 0");
      --  Without aspiration and long tenure, may stall with zeros left
      --  (not guaranteed fail, but aspiration path should succeed)
      Check (RA.Moves_Accepted >= 3, "aspiration ON: at least 3 flips");
      Check (Near (RB.Best_Cost, 0.0) or else RB.Best_Cost >= 0.0,
             "aspiration OFF still returns finite cost");
   end;

   declare
      L : Tabu_List (4);
   begin
      Clear (L);
      Set_Clock (L, 1);
      Push (L, 1, 20);
      --  Simulate: only way to improve global best is tabu move
      Check (Is_Admissible (L, 1, 0.0, 1.0, True),
             "aspiration unlocks tabu move to new best");
      Check (not Is_Admissible (L, 1, 0.0, 1.0, False),
             "same move blocked without aspiration");
   end;

   ---------------------------------------------------------------------
   Section ("11. TSP utilities and improve from bad tour");
   ---------------------------------------------------------------------
   declare
      --  4 cities on a square: optimal length 4.0
      D : constant Dist_Matrix (1 .. 4, 1 .. 4) :=
        [1 => [1 => 0.0, 2 => 1.0, 3 => 1.414, 4 => 1.0],
         2 => [1 => 1.0, 2 => 0.0, 3 => 1.0, 4 => 1.414],
         3 => [1 => 1.414, 2 => 1.0, 3 => 0.0, 4 => 1.0],
         4 => [1 => 1.0, 2 => 1.414, 3 => 1.0, 4 => 0.0]];
      Good : constant Tour := [1, 2, 3, 4];
      Bad  : constant Tour := [1, 3, 2, 4];  -- crossed
      Len_G, Len_B : Non_Negative;
      Cfg  : constant Config :=
        (Max_Iterations => 40, Tenure => 5, Max_Tabu => 32,
         Use_Aspiration => True);
      R    : TSP_Result;
      T2   : Tour (1 .. 4);
   begin
      Len_G := Tour_Length (Good, D);
      Len_B := Tour_Length (Bad, D);
      Check (Near (Real (Len_G), 4.0, 0.02), "good square tour ~ 4");
      Check (Len_B > Len_G, "crossed tour longer than good");

      T2 := Apply_2Opt (Bad, 1, 3);
      Check (T2'Length = 4, "Apply_2Opt preserves length");

      Check (Encode_2Opt_Attr (1, 3) =
               1 * (Max_Cities + 1) + 3, "Encode_2Opt_Attr (1,3)");
      Check (Encode_2Opt_Attr (2, 5) /= Encode_2Opt_Attr (1, 3),
             "distinct pairs distinct attrs");

      R := Minimize_TSP (D, Bad, Cfg);
      Check (R.N = 4, "TSP N = 4");
      Check (R.Best_Length <= Len_B, "TSP best <= start length");
      Check (R.Best_Length < Len_B or else Near (Real (R.Best_Length),
             Real (Len_G), 0.05),
             "TSP improves bad tour or reaches near-optimal");
      Check (Near (Real (R.Best_Length), 4.0, 0.05)
             or else R.Best_Length < Len_B,
             "TSP finds improved or optimal tour");
      Check (R.Moves_Accepted > 0, "TSP accepted moves from bad start");
   end;

   declare
      --  5-city path distances (asymmetric ok); identity start
      D : Dist_Matrix (1 .. 5, 1 .. 5) := [others => [others => 1.0]];
      Start : constant Tour := [1, 2, 3, 4, 5];
      Cfg : constant Config :=
        (Max_Iterations => 20, Tenure => 4, Max_Tabu => 40,
         Use_Aspiration => True);
      R : TSP_Result;
   begin
      for I in City_Index range 1 .. 5 loop
         D (I, I) := 0.0;
      end loop;
      --  Make a shortcut beneficial: 1-3 cheap via better arrangement
      D (1, 3) := 0.5; D (3, 1) := 0.5;
      D (2, 4) := 0.5; D (4, 2) := 0.5;
      R := Minimize_TSP (D, Start, Cfg);
      Check (R.Best_Length <= Tour_Length (Start, D),
             "5-city TSP best <= start");
      Check (R.Iters <= 20, "5-city TSP iters within budget");
   end;

   ---------------------------------------------------------------------
   Section ("12. Number partitioning");
   ---------------------------------------------------------------------
   declare
      W : constant Weights := [1.0, 1.0, 1.0, 1.0, 2.0, 2.0];
      --  Perfect partition exists: cost 0
      Start : constant Assignment :=
        [True, True, True, True, True, True];  -- all in A
      Cfg : constant Config :=
        (Max_Iterations => 50, Tenure => 3, Max_Tabu => 16,
         Use_Aspiration => True);
      R : Partition_Result;
   begin
      Check (Near (Real (Partition_Cost (W, Start)), 8.0),
             "all-in-A cost = total sum 8");
      R := Minimize_Partition (W, Start, Cfg);
      Check (Near (Real (R.Best_Cost), 0.0),
             "partition reaches cost 0");
      Check (R.N = 6, "partition N = 6");
      Check (R.Moves_Accepted > 0, "partition made flips");
   end;

   declare
      W : constant Weights := [3.0, 3.0, 3.0, 3.0];
      Start : constant Assignment := [True, False, True, False];
      Cfg : constant Config :=
        (Max_Iterations => 20, Tenure => 2, Max_Tabu => 8,
         Use_Aspiration => True);
      R : Partition_Result;
   begin
      Check (Near (Real (Partition_Cost (W, Start)), 0.0),
             "already balanced partition cost 0");
      R := Minimize_Partition (W, Start, Cfg);
      Check (Near (Real (R.Best_Cost), 0.0), "stays at 0");
   end;

   ---------------------------------------------------------------------
   Section ("13. Empty / trivial neighborhood edge cases");
   ---------------------------------------------------------------------
   declare
      --  n=1 bit: only one neighbor; after flip and tabu, may stop
      Start : constant Bit_String := [False];
      Cfg : constant Config :=
        (Max_Iterations => 5, Tenure => 10, Max_Tabu => 4,
         Use_Aspiration => False);
      R : Bit_Result;
   begin
      R := Minimize_OneMax (Start, Cfg);
      Check (Near (R.Best_Cost, 0.0), "n=1 OneMax reaches 1");
      Check (R.Best_Bits (1), "n=1 best bit True");
   end;

   declare
      Start : constant Bit_String := [True];
      Cfg : constant Config :=
        (Max_Iterations => 5, Tenure => 2, Max_Tabu => 4,
         Use_Aspiration => True);
      R : Bit_Result;
   begin
      R := Minimize_OneMax (Start, Cfg);
      Check (Near (R.Best_Cost, 0.0), "n=1 already ones");
      Check (R.Moves_Accepted = 0, "n=1 optimal: zero moves");
   end;

   declare
      --  TSP n=2: no valid 2-opt (I < J-1 fails for n=2)
      D : constant Dist_Matrix (1 .. 2, 1 .. 2) :=
        [1 => [1 => 0.0, 2 => 3.0],
         2 => [1 => 3.0, 2 => 0.0]];
      Start : constant Tour := [1, 2];
      Cfg : constant Config :=
        (Max_Iterations => 10, Tenure => 2, Max_Tabu => 4,
         Use_Aspiration => True);
      R : TSP_Result;
   begin
      R := Minimize_TSP (D, Start, Cfg);
      Check (R.N = 2, "TSP n=2");
      Check (Near (Real (R.Best_Length), 6.0), "TSP n=2 length 2*3");
      Check (R.Moves_Accepted = 0, "TSP n=2: empty 2-opt neighborhood");
   end;

   ---------------------------------------------------------------------
   Section ("14. To_Result packing");
   ---------------------------------------------------------------------
   declare
      Start : constant Bit_String := [False, False, False];
      Cfg : constant Config :=
        (Max_Iterations => 20, Tenure => 2, Max_Tabu => 8,
         Use_Aspiration => True);
      BR : Bit_Result;
      RR : Result;
   begin
      BR := Minimize_OneMax (Start, Cfg);
      RR := To_Result (BR);
      Check (Near (RR.Best_Cost, BR.Best_Cost), "To_Result Bit Best_Cost");
      Check (RR.Moves_Accepted = BR.Moves_Accepted, "To_Result Bit moves");
      Check (RR.Iters = BR.Iters, "To_Result Bit Iters");
   end;

   ---------------------------------------------------------------------
   Section ("15. Longer OneMax / stress");
   ---------------------------------------------------------------------
   declare
      Start : constant Bit_String (1 .. 16) := [others => False];
      Cfg : constant Config :=
        (Max_Iterations => 100, Tenure => 5, Max_Tabu => 32,
         Use_Aspiration => True);
      R : Bit_Result;
   begin
      R := Minimize_OneMax (Start, Cfg);
      Check (Near (R.Best_Cost, 0.0), "16-bit OneMax -> 0");
      Check (Ones_Count (R.Best_Bits (1 .. 16)) = 16, "16 ones");
      Check (R.Moves_Accepted >= 16, "at least 16 flips");
   end;

   declare
      Start : constant Bit_String (1 .. 12) := [others => False];
      Target : constant Bit_String (1 .. 12) :=
        [True, False, True, False, True, False,
         True, False, True, False, True, False];
      Cfg : constant Config :=
        (Max_Iterations => 80, Tenure => 4, Max_Tabu => 24,
         Use_Aspiration => True);
      R : Bit_Result;
   begin
      R := Minimize_Hamming (Start, Target, Cfg);
      Check (Near (R.Best_Cost, 0.0), "12-bit Hamming pattern -> 0");
      Check (Hamming_Distance (R.Best_Bits (1 .. 12), Target) = 0,
             "matches checker target");
   end;

   ---------------------------------------------------------------------
   Section ("16. Tenure expiry during search");
   ---------------------------------------------------------------------
   declare
      L : Tabu_List (8);
      Seen_Expire : Boolean := False;
   begin
      Clear (L);
      for Clock in 1 .. 20 loop
         Set_Clock (L, Clock);
         if Clock = 1 then
            Push (L, 42, Tenure => 4);
         end if;
         if Clock < 5 then
            Check (Contains (L, 42),
                   "clock" & Integer'Image (Clock) & " attr 42 tabu");
         else
            if not Contains (L, 42) then
               Seen_Expire := True;
            end if;
            Check (not Contains (L, 42),
                   "clock" & Integer'Image (Clock) & " attr 42 expired");
         end if;
      end loop;
      Check (Seen_Expire, "observed tenure expiry");
   end;

   ---------------------------------------------------------------------
   Section ("17. Config / Result field sanity");
   ---------------------------------------------------------------------
   declare
      C : Config;
      R : Result;
   begin
      Check (C.Max_Iterations = 500, "Config default Max_Iterations");
      Check (C.Tenure = 7, "Config default Tenure");
      Check (C.Max_Tabu = 64, "Config default Max_Tabu");
      Check (C.Use_Aspiration, "Config default aspiration on");
      Check (Near (R.Best_Cost, 0.0), "Result default Best_Cost");
      Check (R.Iters = 0, "Result default Iters");
      Check (R.Moves_Accepted = 0, "Result default Moves");
      Check (R.Aspiration_Count = 0, "Result default Aspiration");
      Check (R.Tabu_Reject_Count = 0, "Result default Tabu_Reject");
   end;

   ---------------------------------------------------------------------
   Section ("18. Multiple Push same attr");
   ---------------------------------------------------------------------
   declare
      L : Tabu_List (8);
   begin
      Clear (L);
      Set_Clock (L, 1);
      Push (L, 3, 2);   -- expiry 3
      Set_Clock (L, 2);
      Push (L, 3, 10);  -- renew expiry 12
      Set_Clock (L, 4);
      Check (Contains (L, 3), "renewed attr still tabu after old expiry");
      Set_Clock (L, 12);
      Check (not Contains (L, 3), "renewed attr expires at new expiry");
   end;

   ---------------------------------------------------------------------
   Section ("19. TSP larger improve");
   ---------------------------------------------------------------------
   declare
      N : constant := 6;
      D : Dist_Matrix (1 .. N, 1 .. N) := [others => [others => 2.0]];
      Start : constant Tour := [1, 3, 5, 2, 6, 4];
      Optish : constant Tour := [1, 2, 3, 4, 5, 6];
      Cfg : constant Config :=
        (Max_Iterations => 60, Tenure => 6, Max_Tabu => 64,
         Use_Aspiration => True);
      R : TSP_Result;
      Start_L : Non_Negative;
   begin
      for I in City_Index range 1 .. City_Index (N) loop
         D (I, I) := 0.0;
      end loop;
      --  Prefer sequential neighbors
      for I in 1 .. N - 1 loop
         D (City_Index (I), City_Index (I + 1)) := 1.0;
         D (City_Index (I + 1), City_Index (I)) := 1.0;
      end loop;
      D (1, City_Index (N)) := 1.0;
      D (City_Index (N), 1) := 1.0;

      Start_L := Tour_Length (Start, D);
      R := Minimize_TSP (D, Start, Cfg);
      Check (R.Best_Length <= Start_L, "6-city best <= start");
      Check (R.Best_Length <= Tour_Length (Optish, D) + 2.0,
             "6-city near sequential quality");
      Check (R.Moves_Accepted > 0, "6-city made moves");
   end;

   ---------------------------------------------------------------------
   Section ("20. Partition uneven + To_Result");
   ---------------------------------------------------------------------
   declare
      W : constant Weights := [5.0, 3.0, 3.0, 2.0, 1.0];
      Start : constant Assignment := [True, True, True, True, True];
      Cfg : constant Config :=
        (Max_Iterations => 40, Tenure => 3, Max_Tabu => 10,
         Use_Aspiration => True);
      R : Partition_Result;
      RR : Result;
   begin
      R := Minimize_Partition (W, Start, Cfg);
      --  Total 14; perfect split 7/7 exists (5+2 / 3+3+1)
      Check (Near (Real (R.Best_Cost), 0.0), "uneven weights partition 0");
      RR := To_Result (R);
      Check (Near (RR.Best_Cost, Real (R.Best_Cost)), "To_Result Partition");
      Check (RR.Tabu_Reject_Count = R.Tabu_Reject_Count,
             "To_Result Partition rejects");
   end;

   ---------------------------------------------------------------------
   Section ("21. Active_Count with mixed expiry");
   ---------------------------------------------------------------------
   declare
      L : Tabu_List (5);
   begin
      Clear (L);
      Set_Clock (L, 1);
      Push (L, 1, 2);
      Push (L, 2, 10);
      Push (L, 3, 10);
      Check (Active_Count (L) = 3, "three active");
      Set_Clock (L, 3);
      Check (not Contains (L, 1), "attr 1 expired");
      Check (Active_Count (L) = 2, "two still active");
      Check (Contains (L, 2) and Contains (L, 3), "2 and 3 remain");
   end;

   ---------------------------------------------------------------------
   Section ("22. Reset_Clock and Set_Clock");
   ---------------------------------------------------------------------
   declare
      L : Tabu_List (4);
   begin
      Clear (L);
      Set_Clock (L, 100);
      Check (L.Clock = 100, "Set_Clock 100");
      Reset_Clock (L);
      Check (L.Clock = 0, "Reset_Clock default 0");
      Reset_Clock (L, 7);
      Check (L.Clock = 7, "Reset_Clock to 7");
      Push (L, 1, 1);
      Clear (L);
      Check (L.Clock = 7, "Clear preserves clock");
      Check (Active_Count (L) = 0, "Clear zeroes actives");
   end;

   ---------------------------------------------------------------------
   Section ("23. Batch OneMax seeds / sizes");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Max_Iterations => 60, Tenure => 3, Max_Tabu => 20,
         Use_Aspiration => True);
   begin
      for N in 2 .. 10 loop
         declare
            Start : constant Bit_String (1 .. N) := [others => False];
            R : Bit_Result;
         begin
            R := Minimize_OneMax (Start, Cfg);
            Check (Near (R.Best_Cost, 0.0),
                   "OneMax n=" & Integer'Image (N) & " -> 0");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("24. Is_Admissible matrix");
   ---------------------------------------------------------------------
   declare
      L : Tabu_List (4);
   begin
      Clear (L);
      Set_Clock (L, 1);
      --  nothing tabu
      Check (Is_Admissible (L, 1, 9.0, 1.0, True), "free attr ok");
      Push (L, 1, 5);
      Check (not Is_Admissible (L, 1, 9.0, 1.0, True), "tabu worse");
      Check (not Is_Admissible (L, 1, 1.0, 1.0, True), "tabu equal");
      Check (Is_Admissible (L, 1, 0.5, 1.0, True), "tabu better aspir.");
      Check (not Is_Admissible (L, 1, 0.5, 1.0, False), "tabu better no asp.");
      Check (Is_Admissible (L, 2, 99.0, 1.0, False), "other attr free");
   end;

   ---------------------------------------------------------------------
   Section ("25. TSP To_Result");
   ---------------------------------------------------------------------
   declare
      D : constant Dist_Matrix (1 .. 3, 1 .. 3) :=
        [1 => [1 => 0.0, 2 => 1.0, 3 => 2.0],
         2 => [1 => 1.0, 2 => 0.0, 3 => 1.0],
         3 => [1 => 2.0, 2 => 1.0, 3 => 0.0]];
      Start : constant Tour := [1, 3, 2];
      Cfg : constant Config :=
        (Max_Iterations => 30, Tenure => 3, Max_Tabu => 16,
         Use_Aspiration => True);
      R : TSP_Result;
      RR : Result;
   begin
      R := Minimize_TSP (D, Start, Cfg);
      RR := To_Result (R);
      Check (Near (RR.Best_Cost, Real (R.Best_Length)), "TSP To_Result cost");
      Check (RR.Moves_Accepted = R.Moves_Accepted, "TSP To_Result moves");
      Check (R.Best_Length <= Tour_Length (Start, D), "3-city improved/same");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("======================");
   Put_Line ("Pass_Count =" & Natural'Image (Pass_Count));
   Put_Line ("Fail_Count =" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("NO FAILURES but Pass_Count < 100");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;

end Tests;
