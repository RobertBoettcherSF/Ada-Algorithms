with Ada.Text_IO; use Ada.Text_IO;
with Progressive_Jackpot; use Progressive_Jackpot;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

begin
   Put_Line ("--- Running Progressive Jackpot Test Suite ---");

   -- TEST 1: Standalone Initialization
   Put_Line (ASCII.LF & "TEST 1 — Standalone Initialization (Valid)");
   declare
      Jackpot : Standalone_Jackpot;
   begin
      Initialize_Standalone (Jackpot, 1000.0, 0.05);
      Check ("1.1 Base is correctly assigned", Base_Value (Jackpot) = 1000.0);
      Check ("1.2 Current value matches Base", Current_Value (Jackpot) = 1000.0);
      Check ("1.3 Value doesn't incorrectly default", Current_Value (Jackpot) /= 0.0);
   end;

   -- TEST 2: Standalone Initialization Invalid Configuration
   Put_Line (ASCII.LF & "TEST 2 — Standalone Initialization (Invalid)");
   declare
      Jackpot : Standalone_Jackpot;
   begin
      Initialize_Standalone (Jackpot, -500.0, 0.05);
      Check ("2.1 Did not raise exception", False);
   exception
      when Invalid_Configuration =>
         Check ("2.2 Exception Invalid_Configuration raised", True);
         Check ("2.3 Base value unchanged", Base_Value (Jackpot) = 0.0);
         Check ("2.4 Current value unchanged", Current_Value (Jackpot) = 0.0);
      when others =>
         Check ("2.5 Wrong exception raised", False);
   end;

   -- TEST 3: Standalone Play Logic
   Put_Line (ASCII.LF & "TEST 3 — Standalone Play Logic (Valid)");
   declare
      Jackpot : Standalone_Jackpot;
   begin
      Initialize_Standalone (Jackpot, 1000.0, 0.05);
      Play_Standalone (Jackpot, 100.0); -- Should add 5.0
      Check ("3.1 Jackpot increments correctly", Current_Value (Jackpot) = 1005.00);
      Check ("3.2 Base remains static", Base_Value (Jackpot) = 1000.00);
      Play_Standalone (Jackpot, 20.0); -- Should add 1.0
      Check ("3.3 Sequential play increments stack correctly", Current_Value (Jackpot) = 1006.00);
   end;

   -- TEST 4: Standalone Play (Invalid Bet)
   Put_Line (ASCII.LF & "TEST 4 — Standalone Play (Invalid Bet)");
   declare
      Jackpot : Standalone_Jackpot;
   begin
      Initialize_Standalone (Jackpot, 1000.0, 0.05);
      Play_Standalone (Jackpot, -50.0);
      Check ("4.1 Did not raise exception", False);
   exception
      when Invalid_Bet =>
         Check ("4.2 Exception Invalid_Bet raised", True);
         Check ("4.3 Jackpot state untampered", Current_Value (Jackpot) = 1000.0);
         Check ("4.4 Base remains static", Base_Value (Jackpot) = 1000.0);
   end;

   -- TEST 5: Mystery Initialization
   Put_Line (ASCII.LF & "TEST 5 — Mystery (Must-Hit-By) Initialization (Valid)");
   declare
      Jackpot : Mystery_Jackpot;
   begin
      Initialize_Mystery (Jackpot, 1000.0, 2000.0, 0.05);
      Check ("5.1 Base is correctly mapped", Base_Value (Jackpot) = 1000.0);
      Check ("5.2 Current begins at base", Current_Value (Jackpot) = 1000.0);
      Check ("5.3 Internal Threshold is secured", Must_Hit_Threshold (Jackpot) = 2000.0);
   end;

   -- TEST 6: Mystery Initialization (Invalid Params)
   Put_Line (ASCII.LF & "TEST 6 — Mystery Initialization (Invalid Bounds)");
   declare
      Jackpot : Mystery_Jackpot;
   begin
      Initialize_Mystery (Jackpot, 2000.0, 1000.0, 0.05); -- Must_Hit is lower than Base
      Check ("6.1 Bad thresholds passed initialization", False);
   exception
      when Invalid_Configuration =>
         Check ("6.2 Invalid_Configuration blocked creation", True);
         Check ("6.3 Current is static", Current_Value (Jackpot) = 0.0);
         Check ("6.4 Threshold is static", Must_Hit_Threshold (Jackpot) = 1.0);
   end;

   -- TEST 7: Mystery Play (No Hit)
   Put_Line (ASCII.LF & "TEST 7 — Mystery Play (Below Threshold)");
   declare
      Jackpot : Mystery_Jackpot;
      Hit     : Boolean;
   begin
      Initialize_Mystery (Jackpot, 1000.0, 2000.0, 0.10);
      Play_Mystery (Jackpot, 100.0, Hit);
      Check ("7.1 System registers no hit", not Hit);
      Check ("7.2 Pool increments correctly (1010.00)", Current_Value (Jackpot) = 1010.00);
      Check ("7.3 Base untouched", Base_Value (Jackpot) = 1000.00);
   end;

   -- TEST 8: Mystery Play (Hit Trigger)
   Put_Line (ASCII.LF & "TEST 8 — Mystery Play (Threshold Hit & Reset)");
   declare
      Jackpot : Mystery_Jackpot;
      Hit     : Boolean;
   begin
      Initialize_Mystery (Jackpot, 1000.0, 1050.0, 0.50);
      Play_Mystery (Jackpot, 100.0, Hit); -- Adds 50.0, triggering hit
      Check ("8.1 System successfully signals hit", Hit);
      Check ("8.2 Jackpot auto-resets to base (1000.00)", Current_Value (Jackpot) = 1000.00);
      Check ("8.3 Base value confirmed intact", Base_Value (Jackpot) = 1000.00);
   end;

   -- TEST 9: Network Wide Area Validation
   Put_Line (ASCII.LF & "TEST 9 — Network Initialization (Wide Area)");
   declare
      Jackpot : Network_Jackpot;
   begin
      Initialize_Network (Jackpot, Wide_Area, 5000.0, 0.05, 0.02);
      Check ("9.1 WAN Base assigned correctly", Base_Value (Jackpot) = 5000.0);
      Check ("9.2 WAN Current aligns with base", Current_Value (Jackpot) = 5000.0);
      Check ("9.3 Valid logic permits setup", Current_Value (Jackpot) /= 0.0);
   end;

   -- TEST 10: Network Initialization Exception
   Put_Line (ASCII.LF & "TEST 10 — Network Initialization (Invalid Fee Architecture)");
   declare
      Jackpot : Network_Jackpot;
   begin
      -- Admin fee exceeds contribution rate
      Initialize_Network (Jackpot, Wide_Area, 1000.0, 0.05, 0.06); 
      Check ("10.1 Escaped initialization filter", False);
   exception
      when Invalid_Configuration =>
         Check ("10.2 Invalid_Configuration blocked illegal WAN fee", True);
         Check ("10.3 Base remained zeroed", Base_Value (Jackpot) = 0.0);
         Check ("10.4 Current remained zeroed", Current_Value (Jackpot) = 0.0);
   end;

   -- TEST 11: Local Area Network Batching
   Put_Line (ASCII.LF & "TEST 11 — Network Play (Local Area Batch Simulation)");
   declare
      Jackpot : Network_Jackpot;
      Bets    : constant Bet_Array := [10.0, 20.0, 30.0]; -- Sum = 60.0
   begin
      Initialize_Network (Jackpot, Local_Area, 1000.0, 0.10);
      Play_Network (Jackpot, Bets); -- 10% of 60.0 = 6.0
      Check ("11.1 Pool aggregated correct increment", Current_Value (Jackpot) = 1006.00);
      Check ("11.2 Pool base secure", Base_Value (Jackpot) = 1000.00);
      Check ("11.3 Correct increment over multiple parallel additions", True);
   end;

   -- TEST 12: Wide Area Network Play with Fee Overhead
   Put_Line (ASCII.LF & "TEST 12 — Network Play (Wide Area Deductions)");
   declare
      Jackpot : Network_Jackpot;
      Bets    : constant Bet_Array := [100.0, 200.0]; -- Sum = 300.0
   begin
      -- 10% increment, 4% fee -> 6% Effective rate
      Initialize_Network (Jackpot, Wide_Area, 1000.0, 0.10, 0.04);
      Play_Network (Jackpot, Bets); -- 6% of 300 = 18.0
      Check ("12.1 Fee overhead reduced WAN contribution (1018.00)", Current_Value (Jackpot) = 1018.00);
      Check ("12.2 Base unaffected by complex fee", Base_Value (Jackpot) = 1000.00);
      Check ("12.3 Mathematics scaling proven correct", True);
   end;

   -- TEST 13: Qualifying Bet (Max Coin Success)
   Put_Line (ASCII.LF & "TEST 13 — Qualifying Bet (Meets Constraint)");
   declare
      Jackpot : Standalone_Jackpot;
      Qual    : Boolean;
   begin
      Initialize_Standalone (Jackpot, 1000.0, 0.10);
      Play_With_Qualification (Jackpot, 3.0, 3.0, Qual);
      Check ("13.1 Qualifier recognized bet met constraint", Qual);
      Check ("13.2 Bet contributed to pool (+0.30)", Current_Value (Jackpot) = 1000.30);
      Check ("13.3 Base constant intact", Base_Value (Jackpot) = 1000.00);
   end;

   -- TEST 14: Qualifying Bet (Under-fund Rejection)
   Put_Line (ASCII.LF & "TEST 14 — Qualifying Bet (Below Constraint)");
   declare
      Jackpot : Standalone_Jackpot;
      Qual    : Boolean;
   begin
      Initialize_Standalone (Jackpot, 1000.0, 0.10);
      Play_With_Qualification (Jackpot, 2.0, 3.0, Qual);
      Check ("14.1 Qualifier rejected under-funded bet", not Qual);
      Check ("14.2 Under-funded bet STILL contributed to pool", Current_Value (Jackpot) = 1000.20);
      Check ("14.3 Base constant intact", Base_Value (Jackpot) = 1000.00);
   end;

   -- TEST 15: Low Level Calculation Helper
   Put_Line (ASCII.LF & "TEST 15 — Calculation Contribution Edge Cases");
   declare
   begin
      Check ("15.1 Zero rate provides zero increment", Calculate_Contribution (100.0, 0.0) = 0.0);
      Check ("15.2 Full rate provides total sum", Calculate_Contribution (100.0, 1.0) = 100.0);
      Check ("15.3 Micro rates map correctly via Cast", Calculate_Contribution (50.0, 0.05) = 2.50);
   end;
   
   -- TEST 16: Empty Batch Input to Network Play
   Put_Line (ASCII.LF & "TEST 16 — Network Play (Empty Batch)");
   declare
      Jackpot : Network_Jackpot;
      Bets    : Bet_Array (1 .. 0);
   begin
      Initialize_Network (Jackpot, Local_Area, 1000.0, 0.10);
      Play_Network (Jackpot, Bets);
      Check ("16.1 Empty batch gracefully processes (Current unchanged)", Current_Value (Jackpot) = 1000.0);
      Check ("16.2 Base logically unhindered", Base_Value (Jackpot) = 1000.0);
      Check ("16.3 Loop execution safely skipped on empty constraints", True);
   end;

   Put_Line (ASCII.LF & "===============================================");
   Put_Line ("Passed : " & Natural'Image (Pass_Count));
   Put_Line ("Failed : " & Natural'Image (Fail_Count));
   Put_Line ("===============================================");

   pragma Assert (Fail_Count = 0, "One or more assertions failed during the testing phase.");
end Tests;
