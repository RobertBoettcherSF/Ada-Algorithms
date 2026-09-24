pragma SPARK_Mode (On);
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Moving_Average_From_Data_Stream; use Moving_Average_From_Data_Stream;

procedure Tests is
   Samples : constant Sample_Array := (2, 4, 6, 8, 10);
begin
   Assert (Average (Samples, 3) = 4);
   Assert (Average (Samples, 5) = 6);
   Put_Line ("Moving Average From Data Stream: PASS");
end Tests;
