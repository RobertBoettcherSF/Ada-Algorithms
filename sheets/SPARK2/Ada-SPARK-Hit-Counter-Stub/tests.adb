pragma SPARK_Mode (On);
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Hit_Counter_Stub; use Hit_Counter_Stub;

procedure Tests is
   Hits : constant Hit_Array := (100, 250, 399, 400, 600, 601, 700, 900);
begin
   Assert (Count_Recent (Hits, 4, 500) = 3);
   Assert (Count_Recent (Hits, 8, 1000) = 2);
   Assert (Count_Recent (Hits, 0, 500) = 0);
   Put_Line ("Hit Counter: PASS");
end Tests;
