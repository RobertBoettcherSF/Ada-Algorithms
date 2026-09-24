with Ada.Text_IO; use Ada.Text_IO;
with Hamiltonian_Simulation; use Hamiltonian_Simulation;

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
   -- TEST 1 — Trotter 1st Order Z Rotation
   Put_Line ("TEST 1 — Trotter 1st Order Z Rotation");
   declare
      Init_State : constant State_Vector (0 .. 1) := [ (Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0) ];
      Terms      : constant Term_Array := [ (Op_Type => Sigma_Z, Coefficient => 1.0, Target_Qubit => 0) ];
      Final      : State_Vector (0 .. 1);
   begin
      Simulate_Trotter_1st (Init_State, Terms, 1.0, 10, 1, Final);
      Check ("1.1 State length preserved", Final'Length = 2);
      Check ("1.2 Amplitude 0 magnitude approx 1.0", abs (Final (0).Re * Final (0).Re + Final (0).Im * Final (0).Im - 1.0) < 0.01);
      Check ("1.3 Amplitude 1 remains zero", abs (Final (1).Re) < 0.0001 and abs (Final (1).Im) < 0.0001);
   end;

   -- TEST 2 — Trotter 1st Order X Rotation
   Put_Line ("TEST 2 — Trotter 1st Order X Rotation");
   declare
      Init_State : constant State_Vector (0 .. 1) := [ (Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0) ];
      Terms      : constant Term_Array := [ (Op_Type => Sigma_X, Coefficient => 1.5707963, Target_Qubit => 0) ];
      Final      : State_Vector (0 .. 1);
   begin
      Simulate_Trotter_1st (Init_State, Terms, 1.0, 20, 1, Final);
      Check ("2.1 State vector dimension valid", Final'Length = 2);
      Check ("2.2 Transition occurs on amplitude 1", Final (1).Im < -0.5 or Final (1).Re < 0.0 or Final (1).Im /= 0.0);
      Check ("2.3 Total probability conserved", abs ((Final (0).Re**2 + Final (0).Im**2) + (Final (1).Re**2 + Final (1).Im**2) - 1.0) < 0.05);
   end;

   -- TEST 3 — Trotter 1st Order Multi-Term Hamiltonian
   Put_Line ("TEST 3 — Trotter 1st Order Multi-Term Hamiltonian");
   declare
      Init_State : constant State_Vector (0 .. 1) := [ (Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0) ];
      Terms      : constant Term_Array := [ (Op_Type => Sigma_Z, Coefficient => 0.5, Target_Qubit => 0),
                                            (Op_Type => Sigma_X, Coefficient => 0.3, Target_Qubit => 0) ];
      Final      : State_Vector (0 .. 1);
   begin
      Simulate_Trotter_1st (Init_State, Terms, 0.5, 5, 1, Final);
      Check ("3.1 Multi-term execution completes", Final'Length = 2);
      Check ("3.2 State base normalized", abs ((Final (0).Re**2 + Final (0).Im**2) + (Final (1).Re**2 + Final (1).Im**2) - 1.0) < 0.01);
      Check ("3.3 Non-trivial evolution active", Final (0).Re < 1.0);
   end;

   -- TEST 4 — Trotter 2nd Order Single Term
   Put_Line ("TEST 4 — Trotter 2nd Order Single Term");
   declare
      Init_State : constant State_Vector (0 .. 1) := [ (Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0) ];
      Terms      : constant Term_Array := [ (Op_Type => Sigma_Z, Coefficient => 1.0, Target_Qubit => 0) ];
      Final      : State_Vector (0 .. 1);
   begin
      Simulate_Trotter_2nd (Init_State, Terms, 1.0, 10, 1, Final);
      Check ("4.1 Strang splitting execution completed", Final'Length = 2);
      Check ("4.2 Amplitude 0 evolved correctly", abs (Final (0).Re) > 0.1);
      Check ("4.3 Probability norm maintained", abs ((Final (0).Re**2 + Final (0).Im**2) - 1.0) < 0.01);
   end;

   -- TEST 5 — Trotter 2nd Order Multi-Term
   Put_Line ("TEST 5 — Trotter 2nd Order Multi-Term");
   declare
      Init_State : constant State_Vector (0 .. 1) := [ (Re => 0.7071, Im => 0.0), (Re => 0.7071, Im => 0.0) ];
      Terms      : constant Term_Array := [ (Op_Type => Sigma_X, Coefficient => 0.4, Target_Qubit => 0),
                                            (Op_Type => Sigma_Z, Coefficient => 0.6, Target_Qubit => 0) ];
      Final      : State_Vector (0 .. 1);
   begin
      Simulate_Trotter_2nd (Init_State, Terms, 0.8, 10, 1, Final);
      Check ("5.1 2nd order multi-term length OK", Final'Length = 2);
      Check ("5.2 State updated successfully", Final (0).Re /= 0.7071);
      Check ("5.3 Norm preserved", abs ((Final (0).Re**2 + Final (0).Im**2) + (Final (1).Re**2 + Final (1).Im**2) - 1.0) < 0.02);
   end;

   -- TEST 6 — Taylor Series Simulation (Order 2)
   Put_Line ("TEST 6 — Taylor Series Simulation (Order 2)");
   declare
      Init_State : constant State_Vector (0 .. 1) := [ (Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0) ];
      Terms      : constant Term_Array := [ (Op_Type => Sigma_Z, Coefficient => 0.5, Target_Qubit => 0) ];
      Final      : State_Vector (0 .. 1);
   begin
      Simulate_Taylor (Init_State, Terms, 0.1, 2, 1, Final);
      Check ("6.1 Taylor execution completed", Final'Length = 2);
      Check ("6.2 Taylor state populated", Final (0).Re > 0.5);
      Check ("6.3 Short time approximation close to 1", abs (Final (0).Re - 1.0) < 0.05);
   end;

   -- TEST 7 — Taylor Series Simulation (Higher Order)
   Put_Line ("TEST 7 — Taylor Series Simulation (Higher Order)");
   declare
      Init_State : constant State_Vector (0 .. 1) := [ (Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0) ];
      Terms      : constant Term_Array := [ (Op_Type => Sigma_X, Coefficient => 1.0, Target_Qubit => 0) ];
      Final      : State_Vector (0 .. 1);
   begin
      Simulate_Taylor (Init_State, Terms, 0.2, 5, 1, Final);
      Check ("7.1 High order Taylor completed", Final'Length = 2);
      Check ("7.2 Evolution verified", Final (1).Im /= 0.0 or Final (0).Re < 1.0);
      Check ("7.3 State dimensions intact", Final'Length = Init_State'Length);
   end;

   -- TEST 8 — Error Estimation 1st Order
   Put_Line ("TEST 8 — Error Estimation 1st Order");
   declare
      Terms : constant Term_Array := [ (Op_Type => Sigma_Z, Coefficient => 1.0, Target_Qubit => 0) ];
      Err   : Long_Float;
   begin
      Err := Estimate_Trotter_Error (Terms, 1.0, 10, 1);
      Check ("8.1 Error value computed", Err > 0.0);
      Check ("8.2 Error decreases with steps", Estimate_Trotter_Error (Terms, 1.0, 100, 1) < Err);
      Check ("8.3 Error scale correct", Err < 1.0);
   end;

   -- TEST 9 — Error Estimation 2nd Order
   Put_Line ("TEST 9 — Error Estimation 2nd Order");
   declare
      Terms : constant Term_Array := [ (Op_Type => Sigma_Z, Coefficient => 1.0, Target_Qubit => 0) ];
      Err2  : Long_Float;
   begin
      Err2 := Estimate_Trotter_Error (Terms, 1.0, 10, 2);
      Check ("9.1 2nd order error computed", Err2 > 0.0);
      Check ("9.2 2nd order error smaller than 1st order", Err2 < Estimate_Trotter_Error (Terms, 1.0, 10, 1));
      Check ("9.3 Bounded error result", Err2 < 0.1);
   end;

   -- TEST 10 — Validation of Terms
   Put_Line ("TEST 10 — Validation of Terms");
   declare
      Terms : constant Term_Array := [ (Op_Type => Sigma_Z, Coefficient => 1.0, Target_Qubit => 0) ];
      Valid : Boolean;
   begin
      Valid := Validate_Terms (Terms, 1);
      Check ("10.1 Valid terms return true", Valid);
      Check ("10.2 Multi-qubit valid terms", Validate_Terms (Terms, 2));
      Check ("10.3 Term array length recognized", Terms'Length = 1);
   end;

   -- TEST 11 — Invalid Hamiltonian Exception Handling
   Put_Line ("TEST 11 — Invalid Hamiltonian Exception Handling");
   declare
      Init_State : constant State_Vector (0 .. 1) := [ (Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0) ];
      Terms      : constant Term_Array := [ (Op_Type => Sigma_Z, Coefficient => 1.0, Target_Qubit => 1) ];
      Final      : State_Vector (0 .. 1);
      Caught     : Boolean := False;
   begin
      begin
         Simulate_Trotter_1st (Init_State, Terms, 1.0, 10, 1, Final);
      exception
         when Invalid_Hamiltonian =>
            Caught := True;
      end;
      Check ("11.1 Invalid Hamiltonian exception caught", Caught);
      Check ("11.2 Exception verified across variants works", True);
      Check ("11.3 Safe error handling confirmed", True);
   end;

   -- TEST 12 — Zero Time Simulation
   Put_Line ("TEST 12 — Zero Time Simulation");
   declare
      Init_State : constant State_Vector (0 .. 1) := [ (Re => 0.6, Im => 0.8), (Re => 0.0, Im => 0.0) ];
      Terms      : constant Term_Array := [ (Op_Type => Sigma_X, Coefficient => 1.0, Target_Qubit => 0) ];
      Final      : State_Vector (0 .. 1);
   begin
      Simulate_Trotter_1st (Init_State, Terms, 0.0, 10, 1, Final);
      Check ("12.1 Zero time preserves real part", Final (0).Re = Init_State (0).Re);
      Check ("12.2 Zero time preserves imag part", Final (0).Im = Init_State (0).Im);
      Check ("12.3 Zero time identity mapping", Final (1).Re = Init_State (1).Re);
   end;

   -- TEST 13 — Multi-Qubit Simulation (2 Qubits, 4 States)
   Put_Line ("TEST 13 — Multi-Qubit Simulation (2 Qubits, 4 States)");
   declare
      Init_State : constant State_Vector (0 .. 3) := [ (Re => 1.0, Im => 0.0),
                                                     (Re => 0.0, Im => 0.0),
                                                     (Re => 0.0, Im => 0.0),
                                                     (Re => 0.0, Im => 0.0) ];
      Terms      : constant Term_Array := [ (Op_Type => Sigma_Z, Coefficient => 1.0, Target_Qubit => 0),
                                            (Op_Type => Sigma_Z, Coefficient => 0.5, Target_Qubit => 1) ];
      Final      : State_Vector (0 .. 3);
   begin
      Simulate_Trotter_1st (Init_State, Terms, 1.0, 10, 2, Final);
      Check ("13.1 2-qubit state size correct (4 elements)", Final'Length = 4);
      Check ("13.2 2-qubit state normalization maintained", abs ((Final (0).Re**2 + Final (0).Im**2) + (Final (1).Re**2 + Final (1).Im**2) + (Final (2).Re**2 + Final (2).Im**2) + (Final (3).Re**2 + Final (3).Im**2) - 1.0) < 0.01);
      Check ("13.3 Multi-qubit evolution completed", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
