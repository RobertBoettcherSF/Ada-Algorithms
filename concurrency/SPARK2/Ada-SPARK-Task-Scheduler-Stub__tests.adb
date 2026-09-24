pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Task_Scheduler_Stub; use Task_Scheduler_Stub;
procedure Tests is
   Tasks : constant Task_Array := (1 => 8, 2 => 3, 3 => 5, 4 => 1, 5 => 4, 6 => 2);
   Order : Schedule_Array;
begin
   Order := Shortest_First (Tasks);
   Assert (Order = (1 => 4, 2 => 6, 3 => 2, 4 => 5, 5 => 3, 6 => 1));
   Put_Line ("PASS Task_Scheduler_Stub");
end Tests;
