pragma Ada_2022;

with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO;    use Ada.Text_IO;
with Beginner_Board; use Beginner_Board;

--  V&V suite for the host simulator. No MCU required.
procedure Tests is
   Passed : Natural := 0;

   procedure Pass (Name : String) is
   begin
      Put_Line ("PASS: " & Name);
      Passed := Passed + 1;
   end Pass;

   procedure Expect_Precondition_Failure is
      Raised : Boolean := False;
   begin
      begin
         --  Pin 0 left as Input after Reset; write must be rejected by Pre.
         Digital_Write (0, High);
      exception
         when Assertion_Error =>
            Raised := True;
      end;
      Assert (Raised);
   end Expect_Precondition_Failure;

begin
   Reset;
   Assert (Millis = 0);
   Assert (Current_Mode (0) = Input);
   Assert (Digital_Read (0) = Low);
   Pass ("reset_defaults");

   Pin_Mode (13, Output);
   Assert (Current_Mode (13) = Output);
   Assert (Digital_Read (13) = Low);
   Pass ("mode_set_output");

   Digital_Write (13, High);
   Assert (Digital_Read (13) = High);
   Digital_Write (13, Low);
   Assert (Digital_Read (13) = Low);
   Pass ("write_read_roundtrip");

   Pin_Mode (2, Input_Pullup);
   Assert (Current_Mode (2) = Input_Pullup);
   Assert (Digital_Read (2) = High);
   Pass ("pullup_default_high");

   Simulate_External (2, Low);
   Assert (Digital_Read (2) = Low);
   Simulate_External (2, High);
   Assert (Digital_Read (2) = High);
   Pass ("pullup_external_drive");

   Reset;
   Expect_Precondition_Failure;
   Pass ("write_on_input_rejected");

   Reset;
   Pin_Mode (5, Output);
   Pin_Mode (7, Output);
   Digital_Write (5, High);
   Digital_Write (7, Low);
   Assert (Digital_Read (5) = High);
   Assert (Digital_Read (7) = Low);
   Digital_Write (5, Low);
   Assert (Digital_Read (5) = Low);
   Assert (Digital_Read (7) = Low);
   Pass ("pin_isolation");

   Reset;
   Assert (Millis = 0);
   Delay_Ms (10);
   Assert (Millis = 10);
   Delay_Ms (25);
   Assert (Millis = 35);
   Pass ("millis_delay_simulation");

   Reset;
   Pin_Mode (0, Input);
   Assert (Digital_Read (0) = Low);
   Simulate_External (0, High);
   Assert (Digital_Read (0) = High);
   Pass ("input_external_drive");

   Reset;
   for P in Pin loop
      Assert (Current_Mode (P) = Input);
      Assert (Digital_Read (P) = Low);
   end loop;
   Pass ("full_reset_all_pins");

   Put_Line ("----");
   Put_Line ("All tests passed:" & Passed'Image);
end Tests;
