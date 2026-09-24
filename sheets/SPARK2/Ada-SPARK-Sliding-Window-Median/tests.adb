pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Sliding_Window_Median; use Sliding_Window_Median;
procedure Tests is
   Input : constant Input_Array := (1 => 9, 2 => 1, 3 => 7, 4 => 3,
                                    5 => 5, 6 => 0, 7 => 8, 8 => 2);
   Result : constant Output_Array := Medians (Input);
begin
   Assert (Result (1) = 7);
   Assert (Result (2) = 3);
   Assert (Result (6) = 2);
   Put_Line ("PASS Sliding_Window_Median");
end Tests;
