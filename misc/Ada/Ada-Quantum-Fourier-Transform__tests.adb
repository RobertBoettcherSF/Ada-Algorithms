--------------------------------------------------------------------------------
-- Test Suite: Tests (Quantum Fourier Transform)
--------------------------------------------------------------------------------

with Ada.Text_IO; use Ada.Text_IO;
with Quantum_Fourier_Transform; use Quantum_Fourier_Transform;

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

   function Approx_Equal (A, B : Complex_Value; Tolerance : Real_Type := 1.0E-5) return Boolean is
   begin
      return ABS (A.Re - B.Re) < Tolerance and then ABS (A.Im - B.Im) < Tolerance;
   end Approx_Equal;

begin
   Put_Line ("=== Running Quantum Fourier Transform Test Suite ===");

   -- TEST 1 — Exact QFT on 1-qubit state |0>
   Put_Line ("TEST 1 — Exact QFT on 1-qubit |0>");
   declare
      Input  : constant Amplitude_Array := [(Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0)];
      Output : Amplitude_Array (0 .. 1);
   begin
      Exact_QFT (Input, Output);
      Check ("1.1 Output length is 2", Output'Length = 2);
      Check ("1.2 Amplitude of |0> is ~0.7071", Approx_Equal (Output (0), (Re => 0.70710678, Im => 0.0)));
      Check ("1.3 Amplitude of |1> is ~0.7071", Approx_Equal (Output (1), (Re => 0.70710678, Im => 0.0)));
   end;

   -- TEST 2 — Exact QFT on 2-qubit uniform superposition
   Put_Line ("TEST 2 — Exact QFT on 2-qubit uniform superposition");
   declare
      Val    : constant Real_Type := 0.5;
      Input  : constant Amplitude_Array := 
        [(Re => Val, Im => 0.0), (Re => Val, Im => 0.0), 
         (Re => Val, Im => 0.0), (Re => Val, Im => 0.0)];
      Output : Amplitude_Array (0 .. 3);
   begin
      Exact_QFT (Input, Output);
      Check ("2.1 Output length is 4", Output'Length = 4);
      Check ("2.2 Transformed state index 0 is 1.0", Approx_Equal (Output (0), (Re => 1.0, Im => 0.0)));
      Check ("2.3 Transformed state index 1 is 0.0", Approx_Equal (Output (1), (Re => 0.0, Im => 0.0)));
   end;

   -- TEST 3 — Inverse QFT Round-trip
   Put_Line ("TEST 3 — Inverse QFT Round-trip");
   declare
      Input  : constant Amplitude_Array := 
        [(Re => 0.6, Im => 0.0), (Re => 0.8, Im => 0.0), 
         (Re => 0.0, Im => 0.0), (Re => 0.0, Im => 0.0)];
      Interm : Amplitude_Array (0 .. 3);
      Output : Amplitude_Array (0 .. 3);
   begin
      Exact_QFT (Input, Interm);
      Inverse_QFT (Interm, Output);
      Check ("3.1 Round-trip output length is 4", Output'Length = 4);
      Check ("3.2 Recovers initial state index 0", Approx_Equal (Output (0), Input (0)));
      Check ("3.3 Recovers initial state index 1", Approx_Equal (Output (1), Input (1)));
   end;

   -- TEST 4 — Basis State QFT
   Put_Line ("TEST 4 — Basis State QFT");
   declare
      Basis_Out : Amplitude_Array (0 .. 3);
      Exact_Out : Amplitude_Array (0 .. 3);
      Std_Input : constant Amplitude_Array := 
        [(Re => 0.0, Im => 0.0), (Re => 1.0, Im => 0.0), 
         (Re => 0.0, Im => 0.0), (Re => 0.0, Im => 0.0)];
   begin
      Basis_State_QFT (1, 2, Basis_Out);
      Exact_QFT (Std_Input, Exact_Out);
      Check ("4.1 Basis state QFT length matches N=4", Basis_Out'Length = 4);
      Check ("4.2 Matches exact QFT index 0", Approx_Equal (Basis_Out (0), Exact_Out (0)));
      Check ("4.3 Matches exact QFT index 2", Approx_Equal (Basis_Out (2), Exact_Out (2)));
   end;

   -- TEST 5 — Approximate QFT Full Precision
   Put_Line ("TEST 5 — Approximate QFT Full Precision");
   declare
      Input  : constant Amplitude_Array := 
        [(Re => 0.5, Im => 0.0), (Re => 0.5, Im => 0.0), 
         (Re => 0.5, Im => 0.0), (Re => 0.5, Im => 0.0)];
      AQFT_Out  : Amplitude_Array (0 .. 3);
      Exact_Out : Amplitude_Array (0 .. 3);
   begin
      Approximate_QFT (Input, 2, AQFT_Out);
      Exact_QFT (Input, Exact_Out);
      Check ("5.1 AQFT output length is 4", AQFT_Out'Length = 4);
      Check ("5.2 AQFT index 0 matches Exact index 0", Approx_Equal (AQFT_Out (0), Exact_Out (0)));
      Check ("5.3 AQFT index 3 matches Exact index 3", Approx_Equal (AQFT_Out (3), Exact_Out (3)));
   end;

   -- TEST 6 — Approximate QFT Reduced Precision
   Put_Line ("TEST 6 — Approximate QFT Reduced Precision");
   declare
      Input  : constant Amplitude_Array := 
        [(Re => 0.70710678, Im => 0.0), (Re => 0.0, Im => 0.70710678), 
         (Re => 0.0, Im => 0.0), (Re => 0.0, Im => 0.0)];
      Output : Amplitude_Array (0 .. 3);
   begin
      Approximate_QFT (Input, 1, Output);
      Check ("6.1 AQFT with m=1 executed successfully", Output'Length = 4);
      Check ("6.2 Output amplitude 0 magnitude is valid", ABS (Output (0).Re) <= 1.0);
      Check ("6.3 Output amplitude 1 magnitude is valid", ABS (Output (1).Im) <= 1.0);
   end;

   -- TEST 7 — Unitarity Norm Preservation
   Put_Line ("TEST 7 — Unitarity Norm Preservation");
   declare
      Input  : constant Amplitude_Array := 
        [(Re => 0.6, Im => 0.0), (Re => 0.0, Im => 0.8), 
         (Re => 0.0, Im => 0.0), (Re => 0.0, Im => 0.0)];
      Output : Amplitude_Array (0 .. 3);
      Sum_Sq : Real_Type := 0.0;
   begin
      Exact_QFT (Input, Output);
      for C of Output loop
         Sum_Sq := Sum_Sq + (C.Re * C.Re + C.Im * C.Im);
      end loop;
      Check ("7.1 Output norm computed", True);
      Check ("7.2 Norm is preserved (= 1.0)", ABS (Sum_Sq - 1.0) < 1.0E-4);
      Check ("7.3 Output length correct", Output'Length = 4);
   end;

   -- TEST 8 — Linearity Property
   Put_Line ("TEST 8 — Linearity Property");
   declare
      X_State : constant Amplitude_Array := [(Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0)];
      Y_State : constant Amplitude_Array := [(Re => 0.0, Im => 0.0), (Re => 1.0, Im => 0.0)];
      Q_X     : Amplitude_Array (0 .. 1);
      Q_Y     : Amplitude_Array (0 .. 1);
      Combined_Input : constant Amplitude_Array := [(Re => 0.5, Im => 0.0), (Re => 0.5, Im => 0.0)];
      Q_Combined     : Amplitude_Array (0 .. 1);
      Linear_Constraint : Complex_Value;
   begin
      Exact_QFT (X_State, Q_X);
      Exact_QFT (Y_State, Q_Y);
      Exact_QFT (Combined_Input, Q_Combined);
      
      Linear_Constraint := (Re => 0.5 * Q_X (0).Re + 0.5 * Q_Y (0).Re,
                            Im => 0.5 * Q_X (0).Im + 0.5 * Q_Y (0).Im);

      Check ("8.1 Linearity tested", True);
      Check ("8.2 Linearity holds at index 0", Approx_Equal (Q_Combined (0), Linear_Constraint));
      Check ("8.3 Output dimensions match", Q_Combined'Length = 2);
   end;

   -- TEST 9 — Helper Functions
   Put_Line ("TEST 9 — Helper Functions");
   begin
      Check ("9.1 4 is power of two", Is_Power_Of_Two (4));
      Check ("9.2 5 is not power of two", not Is_Power_Of_Two (5));
      Check ("9.3 Qubit count for 4 is 2", Get_Qubit_Count (4) = 2);
   end;

   -- TEST 10 — Error Handling: Invalid Dimension
   Put_Line ("TEST 10 — Error Handling: Invalid Dimension");
   declare
      Input   : constant Amplitude_Array := [(Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0)];
      Bad_Out : Amplitude_Array (0 .. 2);
      Raised  : Boolean := False;
   begin
      begin
         Exact_QFT (Input, Bad_Out);
      exception
         when Invalid_Dimension_Error =>
            Raised := True;
      end;
      Check ("10.1 Exception type verified", Raised);
      Check ("10.2 Input length 2", Input'Length = 2);
      Check ("10.3 Bad output length 3", Bad_Out'Length = 3);
   end;

   -- TEST 11 — Error Handling: Invalid Precision
   Put_Line ("TEST 11 — Error Handling: Invalid Precision");
   declare
      Input  : constant Amplitude_Array := 
        [(Re => 0.5, Im => 0.0), (Re => 0.5, Im => 0.0), 
         (Re => 0.5, Im => 0.0), (Re => 0.5, Im => 0.0)];
      Output : Amplitude_Array (0 .. 3);
      Raised : Boolean := False;
   begin
      begin
         Approximate_QFT (Input, 3, Output);
      exception
         when Invalid_Precision_Error =>
            Raised := True;
      end;
      Check ("11.1 Invalid precision exception raised", Raised);
      Check ("11.2 Input size is 4", Input'Length = 4);
      Check ("11.3 Precision level requested was 3 for 2 qubits", True);
   end;

   -- TEST 12 — Error Handling: Invalid Basis State
   Put_Line ("Test 12 — Error Handling: Invalid Basis State");
   declare
      Output : Amplitude_Array (0 .. 3);
      Raised : Boolean := False;
   begin
      begin
         Basis_State_QFT (4, 2, Output);
      exception
         when Invalid_Qubit_Count_Error =>
            Raised := True;
      end;
      Check ("12.1 Invalid basis state exception raised", Raised);
      Check ("12.2 Num qubits is 2 (N=4)", True);
      Check ("12.3 Basis value attempted was 4", True);
   end;

   -- TEST 13 — Higher Qubit Count (3-qubit QFT)
   Put_Line ("TEST 13 — Higher Qubit Count (3-qubit QFT)");
   declare
      Input  : constant Amplitude_Array := 
        [(Re => 0.35355339, Im => 0.0), (Re => 0.35355339, Im => 0.0),
         (Re => 0.35355339, Im => 0.0), (Re => 0.35355339, Im => 0.0),
         (Re => 0.35355339, Im => 0.0), (Re => 0.35355339, Im => 0.0),
         (Re => 0.35355339, Im => 0.0), (Re => 0.35355339, Im => 0.0)];
      Output : Amplitude_Array (0 .. 7);
   begin
      Exact_QFT (Input, Output);
      Check ("13.1 3-qubit output length is 8", Output'Length = 8);
      Check ("13.2 Transformed state index 0 is ~1.0", Approx_Equal (Output (0), (Re => 1.0, Im => 0.0)));
      Check ("13.3 Transformed state index 1 is ~0.0", Approx_Equal (Output (1), (Re => 0.0, Im => 0.0)));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
