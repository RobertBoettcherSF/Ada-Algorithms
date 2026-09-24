with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions;
with Bernstein_Vazirani; use Bernstein_Vazirani;

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
   Put_Line ("TEST 1 — Classical BV, Secret '0'");
   declare
      O : constant Secret_Oracle := Make_Oracle (From_String ("0"));
      R : constant Bit_String := Solve_Classical (1, O);
   begin
      Check ("1.1 Result length is 1", R'Length = 1);
      Check ("1.2 Result string is correct", To_String (R) = "0");
      Check ("1.3 Bit value is zero", R(1) = 0);
   end;

   Put_Line ("TEST 2 — Classical BV, Secret '1'");
   declare
      O : constant Secret_Oracle := Make_Oracle (From_String ("1"));
      R : constant Bit_String := Solve_Classical (1, O);
   begin
      Check ("2.1 Result length is 1", R'Length = 1);
      Check ("2.2 Result string is correct", To_String (R) = "1");
      Check ("2.3 Bit value is one", R(1) = 1);
   end;

   Put_Line ("TEST 3 — Classical BV, Secret '101'");
   declare
      O : constant Secret_Oracle := Make_Oracle (From_String ("101"));
      R : constant Bit_String := Solve_Classical (3, O);
   begin
      Check ("3.1 Result length is 3", R'Length = 3);
      Check ("3.2 Result string matches expected", To_String (R) = "101");
      Check ("3.3 Middle bit is 0", R(2) = 0);
   end;

   Put_Line ("TEST 4 — Classical BV, Secret '1111'");
   declare
      O : constant Secret_Oracle := Make_Oracle (From_String ("1111"));
      R : constant Bit_String := Solve_Classical (4, O);
   begin
      Check ("4.1 Result length is 4", R'Length = 4);
      Check ("4.2 Result string matches expected", To_String (R) = "1111");
      Check ("4.3 Last bit is 1", R(4) = 1);
   end;

   Put_Line ("TEST 5 — Classical BV, Edge Case N=10");
   declare
      O : constant Secret_Oracle := Make_Oracle (From_String ("1010101010"));
      R : constant Bit_String := Solve_Classical (10, O);
   begin
      Check ("5.1 Result length is 10", R'Length = 10);
      Check ("5.2 Result string matches expected", To_String (R) = "1010101010");
      Check ("5.3 Final bit is 0", R(10) = 0);
   end;

   Put_Line ("TEST 6 — Quantum Simulated BV, Secret '0'");
   declare
      O : constant Secret_Oracle := Make_Oracle (From_String ("0"));
      R : constant Bit_String := Solve_Quantum_Simulated (1, O);
   begin
      Check ("6.1 Result length is 1", R'Length = 1);
      Check ("6.2 Result string is correct", To_String (R) = "0");
      Check ("6.3 Bit value is 0", R(1) = 0);
   end;

   Put_Line ("TEST 7 — Quantum Simulated BV, Secret '1'");
   declare
      O : constant Secret_Oracle := Make_Oracle (From_String ("1"));
      R : constant Bit_String := Solve_Quantum_Simulated (1, O);
   begin
      Check ("7.1 Result length is 1", R'Length = 1);
      Check ("7.2 Result string is correct", To_String (R) = "1");
      Check ("7.3 Bit value is 1", R(1) = 1);
   end;

   Put_Line ("TEST 8 — Quantum Simulated BV, Secret '101'");
   declare
      O : constant Secret_Oracle := Make_Oracle (From_String ("101"));
      R : constant Bit_String := Solve_Quantum_Simulated (3, O);
   begin
      Check ("8.1 Result length is 3", R'Length = 3);
      Check ("8.2 Result string matches expected", To_String (R) = "101");
      Check ("8.3 Middle bit is 0", R(2) = 0);
   end;

   Put_Line ("TEST 9 — Quantum Simulated BV, Secret '1111'");
   declare
      O : constant Secret_Oracle := Make_Oracle (From_String ("1111"));
      R : constant Bit_String := Solve_Quantum_Simulated (4, O);
   begin
      Check ("9.1 Result length is 4", R'Length = 4);
      Check ("9.2 Result string matches expected", To_String (R) = "1111");
      Check ("9.3 Third bit is 1", R(3) = 1);
   end;

   Put_Line ("TEST 10 — Quantum Simulated BV, Edge Case N=10");
   declare
      O : constant Secret_Oracle := Make_Oracle (From_String ("1010101010"));
      R : constant Bit_String := Solve_Quantum_Simulated (10, O);
   begin
      Check ("10.1 Result length is 10", R'Length = 10);
      Check ("10.2 Result string matches expected", To_String (R) = "1010101010");
      Check ("10.3 First bit is 1", R(1) = 1);
   end;

   Put_Line ("TEST 11 — Internal Helpers: String Conversion");
   declare
      B : constant Bit_String := From_String ("110");
   begin
      Check ("11.1 Length parsed correctly", B'Length = 3);
      Check ("11.2 First bit is 1", B(1) = 1);
      Check ("11.3 Third bit is 0", B(3) = 0);
   end;

   Put_Line ("TEST 12 — Error Handling: Invalid Strings");
   begin
      declare
         B : constant Bit_String := From_String ("123");
         pragma Unreferenced (B);
      begin
         Check ("12.1 Should not reach here", False);
      end;
   exception
      when Constraint_Error =>
         Check ("12.1 Caught Constraint_Error for bad chars", True);
         Check ("12.2 Handled exception successfully", True);
         Check ("12.3 Robustness verified", True);
   end;

   Put_Line ("TEST 13 — Error Handling: Quantum Precondition Limit (N=11)");
   begin
      declare
         O : constant Secret_Oracle := Make_Oracle (From_String ("10101010101"));
         R : constant Bit_String := Solve_Quantum_Simulated (11, O);
         pragma Unreferenced (R);
      begin
         Check ("13.1 Should not reach here", False);
      end;
   exception
      when Ada.Assertions.Assertion_Error =>
         Check ("13.1 Caught precondition assertion for N > 10", True);
         Check ("13.2 Memory explosion prevented", True);
         Check ("13.3 Contract checked successfully", True);
   end;

   Put_Line ("TEST 14 — Internal Invariant: Oracle Dot Product Logic");
   declare
      O : constant Secret_Oracle := Make_Oracle (From_String ("10"));
   begin
      Check ("14.1 Query '11' with secret '10' -> 1", O.Query (From_String ("11")) = 1);
      Check ("14.2 Query '01' with secret '10' -> 0", O.Query (From_String ("01")) = 0);
      Check ("14.3 Query '10' with secret '10' -> 1", O.Query (From_String ("10")) = 1);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
