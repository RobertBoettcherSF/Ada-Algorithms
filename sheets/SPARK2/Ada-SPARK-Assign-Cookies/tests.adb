pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Assign_Cookies; use Assign_Cookies;
procedure Tests is
   Greed : Values := [others => 0];
   Cookies : Values := [others => 0];
begin
   Greed (1) := 1;
   Cookies (1) := 1;
   Assert (Assigned_Count (Greed, Cookies, 1) = 1);
   Put_Line ("PASS Ada-SPARK-Assign-Cookies");
end Tests;
