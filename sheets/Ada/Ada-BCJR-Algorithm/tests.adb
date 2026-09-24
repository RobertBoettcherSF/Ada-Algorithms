with Ada.Text_IO; use Ada.Text_IO;
with BCJR;        use BCJR;

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

   --  A standard 4-state Rate 1/2 systematic trellis.
   --  Generators: 1, 1+D+D^2. 
   My_Trellis : constant Trellis_Def (0 .. 3) :=
     [0 => [0 => (0, (0, 0)), 1 => (2, (1, 1))],
      1 => [0 => (0, (0, 1)), 1 => (2, (1, 0))],
      2 => [0 => (1, (0, 1)), 1 => (3, (1, 0))],
      3 => [0 => (1, (0, 0)), 1 => (3, (1, 1))]];

   --  Helper to test preconditions dynamically
   procedure Test_Precondition (Test_Id : String; Sys_Len, Par_Len, Apr_Len, Ext_Len : Natural) is
      Sys : constant Metric_Array (1 .. Sys_Len) := [others => 0.0];
      Par : constant Metric_Array (1 .. Par_Len) := [others => 0.0];
      Apr : constant Metric_Array (1 .. Apr_Len) := [others => 0.0];
      Ext : Metric_Array (1 .. Ext_Len);
      Failed : Boolean := False;
   begin
      begin
         Decode (BCJR.Standard, My_Trellis, Sys, Par, Apr, Ext);
      exception
         when others => Failed := True;
      end;
      Check (Test_Id & " trapped", Failed);
   end Test_Precondition;

begin
   Put_Line ("--- BCJR Algorithm Test Suite ---");

   --  TEST 1: Max_Log_MAP Functional (All Zeros)
   Put_Line ("TEST 1 — Max_Log_MAP Functional (All Zeros)");
   declare
      Sys, Par, Apr, Ext : Metric_Array (1 .. 5);
   begin
      Sys := [others => -2.0]; -- Strong bias towards 0
      Par := [others => -2.0];
      Apr := [others => 0.0];
      Decode (Max_Log_MAP, My_Trellis, Sys, Par, Apr, Ext);
      Check ("1.1 Ext(1) is negative", Ext(1) < 0.0);
      Check ("1.2 Ext(2) is negative", Ext(2) < 0.0);
      Check ("1.3 Ext(3) is negative", Ext(3) < 0.0);
   end;

   --  TEST 2: Log_MAP Functional (All Zeros)
   Put_Line ("TEST 2 — Log_MAP Functional (All Zeros)");
   declare
      Sys, Par, Apr, Ext : Metric_Array (1 .. 5);
   begin
      Sys := [others => -2.0];
      Par := [others => -2.0];
      Apr := [others => 0.0];
      Decode (Log_MAP, My_Trellis, Sys, Par, Apr, Ext);
      Check ("2.1 Ext(1) is negative", Ext(1) < 0.0);
      Check ("2.2 Ext(2) is negative", Ext(2) < 0.0);
      Check ("2.3 Ext(3) is negative", Ext(3) < 0.0);
   end;

   --  TEST 3: Standard MAP Functional (All Zeros)
   Put_Line ("TEST 3 — Standard MAP Functional (All Zeros)");
   declare
      Sys, Par, Apr, Ext : Metric_Array (1 .. 5);
   begin
      Sys := [others => -2.0];
      Par := [others => -2.0];
      Apr := [others => 0.0];
      Decode (BCJR.Standard, My_Trellis, Sys, Par, Apr, Ext);
      Check ("3.1 Ext(1) is negative", Ext(1) < 0.0);
      Check ("3.2 Ext(2) is negative", Ext(2) < 0.0);
      Check ("3.3 Ext(3) is negative", Ext(3) < 0.0);
   end;

   --  TEST 4: Max_Log_MAP Error Correction
   Put_Line ("TEST 4 — Max_Log_MAP Error Correction");
   declare
      -- Send 0, 1, 0, 0, 0. Error in bit 2 (received as 0).
      Sys : constant Metric_Array (1 .. 5) := [-20.0, -20.0, -20.0, -20.0, -20.0];
      Par : constant Metric_Array (1 .. 5) := [-20.0, +20.0, +20.0, +20.0, -20.0];
      Apr : constant Metric_Array (1 .. 5) := [others => 0.0];
      Ext : Metric_Array (1 .. 5);
   begin
      Decode (Max_Log_MAP, My_Trellis, Sys, Par, Apr, Ext);
      Check ("4.1 Ext(1) confirms 0", Ext(1) < 0.0);
      Check ("4.2 Ext(2) corrects to 1", Ext(2) > 0.0);
      Check ("4.3 Ext(3) confirms 0", Ext(3) < 0.0);
   end;

   --  TEST 5: Log_MAP Error Correction
   Put_Line ("TEST 5 — Log_MAP Error Correction");
   declare
      Sys : constant Metric_Array (1 .. 5) := [-20.0, -20.0, -20.0, -20.0, -20.0];
      Par : constant Metric_Array (1 .. 5) := [-20.0, +20.0, +20.0, +20.0, -20.0];
      Apr : constant Metric_Array (1 .. 5) := [others => 0.0];
      Ext : Metric_Array (1 .. 5);
   begin
      Decode (Log_MAP, My_Trellis, Sys, Par, Apr, Ext);
      Check ("5.1 Ext(1) confirms 0", Ext(1) < 0.0);
      Check ("5.2 Ext(2) corrects to 1", Ext(2) > 0.0);
      Check ("5.3 Ext(3) confirms 0", Ext(3) < 0.0);
   end;

   --  TEST 6: Standard MAP Error Correction
   Put_Line ("TEST 6 — Standard MAP Error Correction");
   declare
      Sys : constant Metric_Array (1 .. 5) := [-20.0, -20.0, -20.0, -20.0, -20.0];
      Par : constant Metric_Array (1 .. 5) := [-20.0, +20.0, +20.0, +20.0, -20.0];
      Apr : constant Metric_Array (1 .. 5) := [others => 0.0];
      Ext : Metric_Array (1 .. 5);
   begin
      Decode (BCJR.Standard, My_Trellis, Sys, Par, Apr, Ext);
      Check ("6.1 Ext(1) confirms 0", Ext(1) < 0.0);
      Check ("6.2 Ext(2) corrects to 1", Ext(2) > 0.0);
      Check ("6.3 Ext(3) confirms 0", Ext(3) < 0.0);
   end;

   --  TEST 7: Precondition Failures - Mismatched Sys/Par
   Put_Line ("TEST 7 — Mismatched Sys/Par lengths");
   Test_Precondition ("7.1 Sys=5, Par=4", 5, 4, 5, 5);
   Test_Precondition ("7.2 Sys=4, Par=5", 4, 5, 4, 4);
   Test_Precondition ("7.3 Sys=10, Par=9", 10, 9, 10, 10);

   --  TEST 8: Precondition Failures - Mismatched Sys/Apr
   Put_Line ("TEST 8 — Mismatched Sys/Apr lengths");
   Test_Precondition ("8.1 Sys=5, Apr=4", 5, 5, 4, 5);
   Test_Precondition ("8.2 Sys=4, Apr=5", 4, 4, 5, 4);
   Test_Precondition ("8.3 Sys=10, Apr=9", 10, 10, 9, 10);

   --  TEST 9: Precondition Failures - Mismatched Sys/Ext
   Put_Line ("TEST 9 — Mismatched Sys/Ext lengths");
   Test_Precondition ("9.1 Sys=5, Ext=4", 5, 5, 5, 4);
   Test_Precondition ("9.2 Sys=4, Ext=5", 4, 4, 4, 5);
   Test_Precondition ("9.3 Sys=10, Ext=9", 10, 10, 10, 9);

   --  TEST 10: Terminated vs Unterminated behavior
   Put_Line ("TEST 10 — Terminated vs Unterminated");
   declare
      Sys, Par, Apr, Ext_T, Ext_U : Metric_Array (1 .. 5);
   begin
      Sys := [others => 1.0]; -- Biased to 1
      Par := [others => 1.0];
      Apr := [others => 0.0];
      Decode (Max_Log_MAP, My_Trellis, Sys, Par, Apr, Ext_T, Terminated => True);
      Decode (Max_Log_MAP, My_Trellis, Sys, Par, Apr, Ext_U, Terminated => False);
      Check ("10.1 Ext_T(5) is forced negative by termination", Ext_T(5) < 0.0);
      Check ("10.2 Ext_U(5) stays positive", Ext_U(5) > 0.0);
      Check ("10.3 Ext(4) differs", Ext_T(4) /= Ext_U(4));
   end;

   --  TEST 11: Apriori Influence
   Put_Line ("TEST 11 — Apriori Influence");
   declare
      Sys, Par, Apr_0, Apr_1, Ext_0, Ext_1 : Metric_Array (1 .. 5);
   begin
      Sys := [others => -2.0];
      Par := [others => -2.0];
      Apr_0 := [others => 0.0];
      Apr_1 := [others => 10.0];
      Decode (Max_Log_MAP, My_Trellis, Sys, Par, Apr_0, Ext_0);
      Decode (Max_Log_MAP, My_Trellis, Sys, Par, Apr_1, Ext_1);
      Check ("11.1 Ext(1) changes with Apriori", Ext_0(1) /= Ext_1(1));
      Check ("11.2 Ext(2) changes with Apriori", Ext_0(2) /= Ext_1(2));
      Check ("11.3 Ext(3) changes with Apriori", Ext_0(3) /= Ext_1(3));
   end;

   --  TEST 12: Max_Log vs Log_MAP Precision
   Put_Line ("TEST 12 — Max_Log_MAP vs Log_MAP Output");
   declare
      Sys : constant Metric_Array (1 .. 5) := [-1.5, 0.5, -2.5, -0.5, -1.0];
      Par : constant Metric_Array (1 .. 5) := [-1.0, 1.5, +2.0, -1.5, -0.5];
      Apr : constant Metric_Array (1 .. 5) := [others => 0.0];
      Ext_ML, Ext_L : Metric_Array (1 .. 5);
   begin
      Decode (Max_Log_MAP, My_Trellis, Sys, Par, Apr, Ext_ML);
      Decode (Log_MAP, My_Trellis, Sys, Par, Apr, Ext_L);
      Check ("12.1 Ext(1) precision difference", abs (Ext_ML(1) - Ext_L(1)) > 0.0001);
      Check ("12.2 Ext(2) precision difference", abs (Ext_ML(2) - Ext_L(2)) > 0.0001);
      Check ("12.3 Ext(3) precision difference", abs (Ext_ML(3) - Ext_L(3)) > 0.0001);
   end;

   --  TEST 13: Extreme Bounds Overflow Check
   Put_Line ("TEST 13 — Extreme Bounds Overflow Check");
   declare
      Sys, Par, Apr, Ext : Metric_Array (1 .. 5);
   begin
      Sys := [others => 1000.0];
      --  Parity follows the all-1s path for states 0->2->3->3->3 (outputs 11, 10, 11, 11, 11)
      Par := [1000.0, -1000.0, 1000.0, 1000.0, 1000.0];
      Apr := [others => 0.0];
      Decode (Log_MAP, My_Trellis, Sys, Par, Apr, Ext);
      Check ("13.1 Ext(1) remains valid", Ext(1) > 100.0);
      Check ("13.2 Ext(2) remains valid", Ext(2) > 100.0);
      Check ("13.3 Ext(3) remains valid", Ext(3) > 100.0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
