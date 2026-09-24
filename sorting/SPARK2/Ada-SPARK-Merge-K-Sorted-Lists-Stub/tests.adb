pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Merge_K_Sorted_Lists_Stub; use Merge_K_Sorted_Lists_Stub;
procedure Tests is
   Input : constant Input_Array :=
     (1 => 1, 2 => 4, 3 => 7, 4 => 9, 5 => 2, 6 => 3,
      7 => 8, 8 => 10, 9 => 0, 10 => 5, 11 => 6, 12 => 11);
   Result : Input_Array;
begin
   Result := Merge_K (Input);
   for I in Index loop
      Assert (Result (I) = Value (I - 1));
   end loop;
   Put_Line ("PASS Merge_K_Sorted_Lists_Stub");
end Tests;
