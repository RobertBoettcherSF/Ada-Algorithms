pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with K_Closest_Points_Stub; use K_Closest_Points_Stub;
procedure Tests is
   Points : constant Point_Array :=
     (1 => (X => 5, Y => 5), 2 => (X => 1, Y => 1),
      3 => (X => -2, Y => 0), 4 => (X => 10, Y => 10),
      5 => (X => 0, Y => 3), 6 => (X => 4, Y => 0));
   Result : Result_Array;
begin
   Result := K_Closest (Points);
   Assert (Result (1) = (X => 1, Y => 1));
   Assert (Result (2) = (X => -2, Y => 0));
   Assert (Result (3) = (X => 0, Y => 3));
   Put_Line ("PASS K_Closest_Points_Stub");
end Tests;
