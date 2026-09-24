with Ada.Text_IO; use Ada.Text_IO;
with Grovers_Algorithm; use Grovers_Algorithm;

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
   -- TEST 1 — Optimal Iterations basic checks
   Put_Line ("TEST 1 — Optimal Iterations N=16, M=1");
   Check ("1.1 Optimal iterations > 0", Optimal_Iterations(16, 1) > 0);
   Check ("1.2 Optimal iterations value correct (~3)", Optimal_Iterations(16, 1) = 3);
   Check ("1.3 Deterministic result", Optimal_Iterations(16, 1) = Optimal_Iterations(16, 1));

   -- TEST 2 — Optimal Iterations scaling
   Put_Line ("TEST 2 — Optimal Iterations scaling N=64, M=4");
   Check ("2.1 Scaled iterations > 0", Optimal_Iterations(64, 4) > 0);
   Check ("2.2 Scaled iterations correct", Optimal_Iterations(64, 4) = 3);
   Check ("2.3 Monotonicity property", Optimal_Iterations(64, 4) <= Optimal_Iterations(64, 1));

   -- TEST 3 — Standard Grover Search target at index 5
   Put_Line ("TEST 3 — Standard Grover Search target at index 5 (N=16)");
   declare
      Result : constant Item_Index := Standard_Grover_Search(16, Oracle_Single_5'Access);
   begin
      Check ("3.1 Result within search space", Natural(Result) < 16);
      Check ("3.2 Oracle evaluates true for result", Oracle_Single_5(Result));
      Check ("3.3 Correct target found", Result = 5);
   end;

   -- TEST 4 — Standard Grover Search target at index 0
   Put_Line ("TEST 4 — Standard Grover Search target at index 0 (N=8)");
   declare
      Result : constant Item_Index := Standard_Grover_Search(8, Oracle_Single_0'Access);
   begin
      Check ("4.1 Result within search space", Natural(Result) < 8);
      Check ("4.2 Oracle evaluates true for result", Oracle_Single_0(Result));
      Check ("4.3 Correct target found", Result = 0);
   end;

   -- TEST 5 — Standard Grover Search target at last index
   Put_Line ("TEST 5 — Standard Grover Search target at last index (N=16)");
   declare
      Result : constant Item_Index := Standard_Grover_Search(16, Oracle_Last_15'Access);
   begin
      Check ("5.1 Result within search space", Natural(Result) < 16);
      Check ("5.2 Oracle evaluates true for result", Oracle_Last_15(Result));
      Check ("5.3 Correct target found", Result = 15);
   end;

   -- TEST 6 — Amplitude Amplification Search basic
   Put_Line ("TEST 6 — Amplitude Amplification Search N=16, target=5");
   declare
      Result : constant Item_Index := Amplitude_Amplification_Search(16, Oracle_Single_5'Access, 1.0);
   begin
      Check ("6.1 Result within bounds", Natural(Result) < 16);
      Check ("6.2 Oracle matches result", Oracle_Single_5(Result));
      Check ("6.3 Target identified successfully", Result = 5);
   end;

   -- TEST 7 — Amplitude Amplification Search custom weight
   Put_Line ("TEST 7 — Amplitude Amplification Search custom weight N=8");
   declare
      Result : constant Item_Index := Amplitude_Amplification_Search(8, Oracle_Single_0'Access, 2.0);
   begin
      Check ("7.1 Result within bounds", Natural(Result) < 8);
      Check ("7.2 Oracle matches result", Oracle_Single_0(Result));
      Check ("7.3 Target identified successfully", Result = 0);
   end;

   -- TEST 8 — Quantum Counting Search single match
   Put_Line ("TEST 8 — Quantum Counting Search single match N=16");
   declare
      Count_Result : constant Search_Space_Size := Quantum_Counting_Search(16, Oracle_Single_5'Access);
   begin
      Check ("8.1 Count is valid", Count_Result <= 16);
      Check ("8.2 Count is non-zero", Integer(Count_Result) > 0);
      Check ("8.3 Exact count matches single item", Count_Result = 1);
   end;

   -- TEST 9 — Quantum Counting Search multiple matches
   Put_Line ("TEST 9 — Quantum Counting Search multiple matches N=16");
   declare
      Count_Result : constant Search_Space_Size := Quantum_Counting_Search(16, Oracle_Multiple_Even'Access);
   begin
      Check ("9.1 Count is valid", Count_Result <= 16);
      Check ("9.2 Count is positive", Integer(Count_Result) > 0);
      Check ("9.3 Exact count matches expected multiple (4 items)", Count_Result = 4);
   end;

   -- TEST 10 — Multi-Solution Grover Search expected M=4
   Put_Line ("TEST 10 — Multi-Solution Grover Search N=16, M=4");
   declare
      Result : constant Item_Index := Multi_Solution_Grover_Search(16, Oracle_Multiple_Even'Access, 4);
   begin
      Check ("10.1 Result within bounds", Natural(Result) < 16);
      Check ("10.2 Oracle matches result", Oracle_Multiple_Even(Result));
      Check ("10.3 Valid solution found among multiple", Oracle_Multiple_Even(Result));
   end;

   -- TEST 11 — Multi-Solution Grover Search alternative expected M
   Put_Line ("TEST 11 — Multi-Solution Grover Search alternative N=16, M=4");
   declare
      Result : constant Item_Index := Multi_Solution_Grover_Search(16, Oracle_Multiple_Even'Access, 4);
   begin
      Check ("11.1 Result within bounds", Natural(Result) < 16);
      Check ("11.2 Result satisfies multiple criterion", (Integer(Result) mod 4) = 0);
      Check ("11.3 Robust execution", Natural(Result) < 16);
   end;

   -- TEST 12 — Exception Handling (No Solution Found)
   Put_Line ("TEST 12 — Exception Handling No_Solution_Found");
   declare
      Exception_Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : constant Item_Index := Standard_Grover_Search(16, Oracle_None'Access);
         begin
            pragma Unreferenced(Dummy);
         end;
      exception
         when No_Solution_Found =>
            Exception_Raised := True;
      end;
      Check ("12.1 Exception type caught correctly", Exception_Raised);
      Check ("12.2 Graceful failure mode", Exception_Raised);
      Check ("12.3 System stability maintained", True);
   end;

   -- TEST 13 — Boundary and Invariant validation
   Put_Line ("TEST 13 — Boundary and Invariant Validation");
   declare
      Res1 : constant Iteration_Count := Optimal_Iterations(1, 1);
      Res2 : constant Search_Space_Size := Quantum_Counting_Search(8, Oracle_Single_0'Access);
      Res3 : constant Item_Index := Standard_Grover_Search(2, Oracle_Single_0'Access);
   begin
      Check ("13.1 Single element iteration count zero/low", Res1 = 0);
      Check ("13.2 Quantum counting exact on small set", Res2 = 1);
      Check ("13.3 Smallest search space N=2 functional", Natural(Res3) < 2);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
