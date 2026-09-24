pragma SPARK_Mode (On);
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Kth_Largest_In_Stream_Stub; use Kth_Largest_In_Stream_Stub;

procedure Tests is
   Values : constant Stream_Array := (4, 1, 9, 7, 3);
begin
   Assert (Kth_Largest (Values, 1) = 9);
   Assert (Kth_Largest (Values, 2) = 7);
   Assert (Kth_Largest (Values, 5) = 1);
   Put_Line ("Kth Largest In Stream: PASS");
end Tests;
