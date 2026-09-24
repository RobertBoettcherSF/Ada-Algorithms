pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Insert_Interval; use Insert_Interval;
procedure Tests is
   Starts : Bounds := [others => 0];
   Finishes : Bounds := [others => 0];
begin
   Starts (1) := 0;
   Finishes (1) := 1;
   Assert (Inserted_Intervals (Starts, Finishes, 1) = 2);
   Put_Line ("PASS Ada-SPARK-Insert-Interval");
end Tests;
