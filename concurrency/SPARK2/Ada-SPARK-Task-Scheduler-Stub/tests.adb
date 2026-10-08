pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Task_Scheduler_Stub; use Task_Scheduler_Stub;
procedure Tests is
   Tasks : constant Task_Array := (1 => 8, 2 => 3, 3 => 5, 4 => 1, 5 => 4, 6 => 2);
   Order : Schedule_Array;
   Asc   : constant Task_Array := (1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6);
   Desc  : constant Task_Array := (1 => 6, 2 => 5, 3 => 4, 4 => 3, 5 => 2, 6 => 1);
   Eq    : constant Task_Array := (1 => 5, 2 => 5, 3 => 1, 4 => 5, 5 => 5, 6 => 5);
begin
   Order := Shortest_First (Tasks);
   Assert (Order = (1 => 4, 2 => 6, 3 => 2, 4 => 5, 5 => 3, 6 => 1));
   Order := Shortest_First (Asc);
   Assert (Order = (1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6));
   Order := Shortest_First (Desc);
   Assert (Order = (1 => 6, 2 => 5, 3 => 4, 4 => 3, 5 => 2, 6 => 1));
   Order := Shortest_First (Eq);
   Assert (Order = (1 => 3, 2 => 2, 3 => 1, 4 => 4, 5 => 5, 6 => 6));
   Put_Line ("PASS Task_Scheduler_Stub");
end Tests;
