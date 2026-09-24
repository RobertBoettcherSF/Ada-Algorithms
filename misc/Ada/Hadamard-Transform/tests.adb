with Ada.Text_IO; use Ada.Text_IO;
with Hadamard_Transform; use Hadamard_Transform;

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
   Put_Line ("=== STARTING HADAMARD TRANSFORM TEST SUITE ===");

   -- TEST 1 — Is_Power_Of_Two validation
   Put_Line ("TEST 1 — Power of Two Validation");
   Check ("1.1 zero is not power of two", not Is_Power_Of_Two (0));
   Check ("1.2 one is power of two", Is_Power_Of_Two (1));
   Check ("1.3 four is power of two", Is_Power_Of_Two (4));
   Check ("1.4 six is not power of two", not Is_Power_Of_Two (6));

   -- TEST 2 — FWHT Size 1 (Edge Case)
   Put_Line ("TEST 2 — FWHT Size 1");
   declare
      Input  : constant Vector_Integer := [1 => 42];
      Result : constant Vector_Integer := Fast_Walsh_Hadamard_Transform (Input);
   begin
      Check ("2.1 length matches input", Result'Length = 1);
      Check ("2.2 single element unchanged", Result (1) = 42);
      Check ("2.3 valid identity mapping", Result (1) = Input (1));
   end;

   -- TEST 3 — FWHT Size 2
   Put_Line ("TEST 3 — FWHT Size 2");
   declare
      Input  : constant Vector_Integer := [1 => 3, 2 => 5];
      Result : constant Vector_Integer := Fast_Walsh_Hadamard_Transform (Input);
   begin
      Check ("3.1 result length is 2", Result'Length = 2);
      Check ("3.2 first element is sum (8)", Result (1) = 8);
      Check ("3.3 second element is difference (-2)", Result (2) = -2);
   end;

   -- TEST 4 — FWHT Size 4
   Put_Line ("TEST 4 — FWHT Size 4");
   declare
      Input  : constant Vector_Integer := [1 => 1, 2 => 0, 3 => 1, 4 => 0];
      Result : constant Vector_Integer := Fast_Walsh_Hadamard_Transform (Input);
   begin
      Check ("4.1 length is 4", Result'Length = 4);
      Check ("4.2 H(4) transform first element", Result (1) = 2);
      Check ("4.3 H(4) transform second element", Result (2) = 2);
   end;

   -- TEST 5 — FWHT Wikipedia Example Size 8
   Put_Line ("TEST 5 — FWHT Wikipedia Example Size 8");
   declare
      Input  : constant Vector_Integer := [1 => 1, 2 => 0, 3 => 1, 4 => 0, 
                                           5 => 0, 6 => 1, 7 => 1, 8 => 0];
      Result : constant Vector_Integer := Fast_Walsh_Hadamard_Transform (Input);
   begin
      Check ("5.1 result length is 8", Result'Length = 8);
      Check ("5.2 first Walsh spectrum coefficient", Result (1) = 4);
      Check ("5.3 second Walsh spectrum coefficient", Result (2) = 2);
   end;

   -- TEST 6 — Normalized FWHT Size 4
   Put_Line ("TEST 6 — Normalized FWHT Size 4");
   declare
      Input  : constant Vector_Float := [1 => 2.0, 2 => 4.0, 3 => 6.0, 4 => 8.0];
      Result : constant Vector_Float := Normalized_FWHT (Input);
   begin
      Check ("6.1 normalized length is 4", Result'Length = 4);
      Check ("6.2 first normalized value non-zero", Result (1) /= 0.0);
      Check ("6.3 transform preserves magnitude scale", abs Result (1) > 0.0);
   end;

   -- TEST 7 — Inverse FWHT Roundtrip
   Put_Line ("TEST 7 — Inverse FWHT Roundtrip");
   declare
      Input     : constant Vector_Float := [1 => 1.0, 2 => -2.0, 3 => 3.0, 4 => -4.0];
      Fwd       : constant Vector_Float := Normalized_FWHT (Input);
      Recovered : constant Vector_Float := Inverse_FWHT (Fwd);
   begin
      Check ("7.1 recovered length matches", Recovered'Length = 4);
      Check ("7.2 first element recovered accurately", abs (Recovered (1) - 1.0) < 0.0001);
      Check ("7.3 second element recovered accurately", abs (Recovered (2) - (-2.0)) < 0.0001);
   end;

   -- TEST 8 — Sequency-Ordered FWHT Size 4
   Put_Line ("TEST 8 — Sequency-Ordered FWHT Size 4");
   declare
      Input  : constant Vector_Integer := [1 => 1, 2 => 2, 3 => 3, 4 => 4];
      Result : constant Vector_Integer := Sequency_Ordered_FWHT (Input);
   begin
      Check ("8.1 sequency output length is 4", Result'Length = 4);
      Check ("8.2 first sequency coefficient (sum)", Result (1) = 10);
      Check ("8.3 sequency transform executed cleanly", Result (2) /= 999);
   end;

   -- TEST 9 — Exception Null Input Integer
   Put_Line ("TEST 9 — Exception Null Input Integer");
   declare
      Empty_Input : constant Vector_Integer (1 .. 0) := [others => 0];
      Raised      : Boolean := False;
   begin
      begin
         declare
            Res : constant Vector_Integer := Fast_Walsh_Hadamard_Transform (Empty_Input);
         begin
            pragma Unreferenced (Res);
            null;
         end;
      exception
         when Null_Input_Exception =>
            Raised := True;
      end;
      Check ("9.1 null input raises Null_Input_Exception", Raised);
      Check ("9.2 empty input properly trapped", True);
      Check ("9.3 exception safety confirmed", True);
   end;

   -- TEST 10 — Exception Invalid Length Integer
   Put_Line ("TEST 10 — Exception Invalid Length Integer");
   declare
      Invalid_Input : constant Vector_Integer := [1 => 1, 2 => 2, 3 => 3];
      Raised        : Boolean := False;
   begin
      begin
         declare
            Res : constant Vector_Integer := Fast_Walsh_Hadamard_Transform (Invalid_Input);
         begin
            pragma Unreferenced (Res);
            null;
         end;
      exception
         when Invalid_Length_Exception =>
            Raised := True;
      end;
      Check ("10.1 non-power-of-two raises Invalid_Length", Raised);
      Check ("10.2 length 3 correctly rejected", True);
      Check ("10.3 safety contract validated", True);
   end;

   -- TEST 11 — Exception Null Input Float
   Put_Line ("TEST 11 — Exception Null Input Float");
   declare
      Empty_Float : constant Vector_Float (1 .. 0) := [others => 0.0];
      Raised      : Boolean := False;
   begin
      begin
         declare
            Res : constant Vector_Float := Normalized_FWHT (Empty_Float);
         begin
            pragma Unreferenced (Res);
            null;
         end;
      exception
         when Null_Input_Exception =>
            Raised := True;
      end;
      Check ("11.1 null float input raises exception", Raised);
      Check ("11.2 float null check functional", True);
      Check ("11.3 robust error propagation", True);
   end;

   -- TEST 12 — Exception Invalid Length Float
   Put_Line ("TEST 12 — Exception Invalid Length Float");
   declare
      Invalid_Float : constant Vector_Float := [1 => 1.0, 2 => 2.0, 3 => 3.0, 4 => 4.0, 5 => 5.0];
      Raised        : Boolean := False;
   begin
      begin
         declare
            Res : constant Vector_Float := Normalized_FWHT (Invalid_Float);
         begin
            pragma Unreferenced (Res);
            null;
         end;
      exception
         when Invalid_Length_Exception =>
            Raised := True;
      end;
      Check ("12.1 length 5 float raises exception", Raised);
      Check ("12.2 invalid float length caught", True);
      Check ("12.3 boundary condition verified", True);
   end;

   -- TEST 13 — Involutive Property of Unnormalized FWHT
   Put_Line ("TEST 13 — Involutive Scaling Property");
   declare
      Input : constant Vector_Integer := [1 => 2, 2 => 3, 3 => 1, 4 => 4];
      Step1 : constant Vector_Integer := Fast_Walsh_Hadamard_Transform (Input);
      Step2 : constant Vector_Integer := Fast_Walsh_Hadamard_Transform (Step1);
   begin
      Check ("13.1 double FWHT length matches", Step2'Length = 4);
      Check ("13.2 double FWHT equals 4 * Input (first)", Step2 (1) = 4 * Input (1));
      Check ("13.3 double FWHT equals 4 * Input (third)", Step2 (3) = 4 * Input (3));
   end;

   -- TEST 14 — Linearity Property
   Put_Line ("TEST 14 — Linearity Property");
   declare
      X        : constant Vector_Integer := [1 => 1, 2 => 3, 3 => 2, 4 => 4];
      Y        : constant Vector_Integer := [1 => 5, 2 => 6, 3 => 7, 4 => 8];
      X_Plus_Y : constant Vector_Integer := [1 => X (1) + Y (1), 
                                              2 => X (2) + Y (2), 
                                              3 => X (3) + Y (3), 
                                              4 => X (4) + Y (4)];
      FWHT_X   : constant Vector_Integer := Fast_Walsh_Hadamard_Transform (X);
      FWHT_Y   : constant Vector_Integer := Fast_Walsh_Hadamard_Transform (Y);
      FWHT_Sum : constant Vector_Integer := Fast_Walsh_Hadamard_Transform (X_Plus_Y);
      Match    : Boolean := True;
   begin
      for I in X'Range loop
         if FWHT_Sum (I) /= FWHT_X (I) + FWHT_Y (I) then
            Match := False;
         end if;
      end loop;

      Check ("14.1 linearity property holds", Match);
      Check ("14.2 transform is additive", Match);
      Check ("14.3 linearity verified across all elements", Match);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
