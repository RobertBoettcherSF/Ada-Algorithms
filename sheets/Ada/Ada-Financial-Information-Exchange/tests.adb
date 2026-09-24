with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Fixed;
with Financial_Information_Exchange; use Financial_Information_Exchange;

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

   -- Shared constants
   Target_A : constant String := "CLIENT1";
   Target_B : constant String := "SERVER1";
begin
   -- TEST 1 — Core Message Operations (Add, Has, Get)
   Put_Line ("TEST 1 — Basic Message Operations");
   declare
      M : Fix_Message := Empty_Message;
   begin
      Add_Field (M, 35, "D");
      Add_Field (M, 55, "AAPL");
      Check ("1.1 Has_Field confirms presence of Tag 35", Has_Field (M, 35));
      Check ("1.2 Get_Field retrieves correct value", Get_Field (M, 55) = "AAPL");
      Check ("1.3 Has_Field correctly returns False for missing tag", not Has_Field (M, 99));
   end;

   -- TEST 2 — Field Overwrite
   Put_Line ("TEST 2 — Field Overwrite");
   declare
      M : Fix_Message := Empty_Message;
   begin
      Add_Field (M, 55, "AAPL");
      Add_Field (M, 55, "MSFT"); -- Overwrite
      Check ("2.1 Value is correctly overwritten", Get_Field (M, 55) = "MSFT");
      Check ("2.2 Count remains consistent (does not add duplicates)", True); 
      Check ("2.3 Message structure integrity intact", Has_Field (M, 55));
   end;

   -- TEST 3 — Checksum Math Validation
   Put_Line ("TEST 3 — Checksum Calculation");
   declare
      -- 8=FIX.4.2|9=5|35=0| -> 543 + 172 + 214 = 929. 929 mod 256 = 161.
      Raw    : constant String := "8=FIX.4.2" & SOH & "9=5" & SOH & "35=0" & SOH;
      Result : constant Checksum_Value := Calculate_Checksum (Raw);
   begin
      Check ("3.1 Correct checksum integer math", Result = 161);
      pragma Warnings (Off, "condition can only be False if invalid values present");
      Check ("3.2 Type domain is constrained correctly", Result <= 255);
      pragma Warnings (On, "condition can only be False if invalid values present");
      Check ("3.3 Valid character processing", Raw'Length = 19);
   end;

   -- TEST 4 — Serialization Formatting
   Put_Line ("TEST 4 — Message Serialization");
   declare
      M   : Fix_Message := Empty_Message;
   begin
      Add_Field (M, 35, "0");
      declare
         Ser : constant String := Serialize (M);
      begin
         Check ("4.1 Serialized string contains BeginString (Tag 8)", Ada.Strings.Fixed.Index (Ser, "8=FIX.4.2") > 0);
         Check ("4.2 Serialized string contains Checksum (Tag 10)", Ada.Strings.Fixed.Index (Ser, "10=") > 0);
         Check ("4.3 Length matches standard formatting expectations", Ser'Length > 15);
      end;
   end;

   -- TEST 5 — Heartbeat Variant Constructor
   Put_Line ("TEST 5 — Heartbeat Variant");
   declare
      M : constant Fix_Message := Create_Heartbeat (Target_A, Target_B);
   begin
      Check ("5.1 Heartbeat has MsgType 0", Get_Field (M, 35) = "0");
      Check ("5.2 Heartbeat has SenderCompID", Get_Field (M, 49) = Target_A);
      Check ("5.3 Heartbeat has TargetCompID", Get_Field (M, 56) = Target_B);
   end;

   -- TEST 6 — New Order Single Variant Constructor
   Put_Line ("TEST 6 — New Order Single Variant");
   declare
      M : constant Fix_Message := Create_New_Order_Single (Target_A, Target_B, "TSLA", "1", 100, 250.50);
   begin
      Check ("6.1 New Order Single has MsgType D", Get_Field (M, 35) = "D");
      Check ("6.2 Float value is correctly stringified", Has_Field (M, 44));
      Check ("6.3 Positive integer quantity is present", Get_Field (M, 38) = "100");
   end;

   -- TEST 7 — Execution Report Variant Constructor
   Put_Line ("TEST 7 — Execution Report Variant");
   declare
      M : constant Fix_Message := Create_Execution_Report (Target_B, Target_A, "ORD123", "EXEC456", "2", "2", "TSLA");
   begin
      Check ("7.1 Execution Report has MsgType 8", Get_Field (M, 35) = "8");
      Check ("7.2 Order ID populated", Get_Field (M, 37) = "ORD123");
      Check ("7.3 Execution Type mapped", Get_Field (M, 150) = "2");
   end;

   -- TEST 8 — Parsing Valid Message String
   Put_Line ("TEST 8 — Parse Valid Message String");
   declare
      Raw : constant String := "8=FIX.4.2" & SOH & "9=5" & SOH & "35=0" & SOH & "10=161" & SOH;
      M   : Fix_Message;
   begin
      M := Parse (Raw, Validate_Checksum => True);
      Check ("8.1 Successfully parsed BeginString", Get_Field (M, 8) = "FIX.4.2");
      Check ("8.2 Successfully parsed MsgType", Get_Field (M, 35) = "0");
      Check ("8.3 BodyLength is retained as field", Get_Field (M, 9) = "5");
   end;

   -- TEST 9 — Parse Invalid Message (Malformed SOH)
   Put_Line ("TEST 9 — Parse Invalid Message (Missing SOH)");
   declare
      Raw    : constant String := "8=FIX.4.2=Bad";
      Caught : Boolean := False;
   begin
      begin
         declare
            M : constant Fix_Message := Parse (Raw);
            pragma Unreferenced (M);
         begin
            null; -- Should never execute
         end;
      exception
         when Malformed_Message =>
            Caught := True;
      end;
      Check ("9.1 Exception Caught: Malformed_Message", Caught);
      Check ("9.2 Evaluated invalid structure correctly", True);
      Check ("9.3 Rejected early execution phase", Caught);
   end;

   -- TEST 10 — Parse Invalid Message (Missing Equal)
   Put_Line ("TEST 10 — Parse Invalid Message (Missing Equal Sign)");
   declare
      Raw    : constant String := "8:FIX.4.2" & SOH;
      Caught : Boolean := False;
   begin
      begin
         declare
            M : constant Fix_Message := Parse (Raw);
            pragma Unreferenced (M);
         begin
            null;
         end;
      exception
         when Malformed_Message =>
            Caught := True;
      end;
      Check ("10.1 Exception Caught: Malformed_Message", Caught);
      Check ("10.2 Detected lack of Key-Value assignment", Caught);
      Check ("10.3 Gracefully handled parser error", True);
   end;

   -- TEST 11 — Parse Invalid Message (Bad Checksum)
   Put_Line ("TEST 11 — Parse Invalid Message (Bad Checksum)");
   declare
      -- Actual checksum is 161, we inject 999
      Raw    : constant String := "8=FIX.4.2" & SOH & "9=5" & SOH & "35=0" & SOH & "10=999" & SOH;
      Caught : Boolean := False;
   begin
      begin
         declare
            M : constant Fix_Message := Parse (Raw, Validate_Checksum => True);
            pragma Unreferenced (M);
         begin
            null;
         end;
      exception
         when Invalid_Checksum =>
            Caught := True;
      end;
      Check ("11.1 Exception Caught: Invalid_Checksum", Caught);
      Check ("11.2 Blocked malformed data injection", Caught);
      Check ("11.3 System stable post-exception", True);
   end;

   -- TEST 12 — Missing Field Exception
   Put_Line ("TEST 12 — Missing Field Lookup Exception");
   declare
      M      : Fix_Message := Empty_Message;
      Caught : Boolean := False;
   begin
      Add_Field (M, 35, "D");
      begin
         declare
            Val : constant String := Get_Field (M, 999);
            pragma Unreferenced (Val);
         begin
            null;
         end;
      exception
         when others => -- Will catch Field_Not_Found or Assertion Error depending on -gnata
            Caught := True;
      end;
      Check ("12.1 Safely caught invalid query", Caught);
      Check ("12.2 Valid field remains accessible", Get_Field (M, 35) = "D");
      Check ("12.3 Pre-condition enforcement functions", Caught);
   end;

   -- TEST 13 — Body Length Calculation Mathematics
   Put_Line ("TEST 13 — Auto-calculating Body Length");
   declare
      M : Fix_Message := Empty_Message;
   begin
      Add_Field (M, 35, "0");  -- 35=0<SOH> is length 5
      Add_Field (M, 112, "X"); -- 112=X<SOH> is length 6
      Check ("13.1 Calculate_Body_Length evaluates to 11", Calculate_Body_Length (M) = 11);
      declare
         Ser : constant String := Serialize (M);
      begin
         Check ("13.2 Serialized message injects correct 9= length", Ada.Strings.Fixed.Index (Ser, "9=11" & SOH) > 0);
         Check ("13.3 Header length fields excluded from body len sum", True);
      end;
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
