with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Count_Smaller_After_Self; use Count_Smaller_After_Self;
procedure Tests is
   A : constant Input_Array := [5, 2, 6, 1, 3, 0, 4, 7];
   R : constant Count_Array := Count_Smaller_After_Self.Count (A);
begin
   Assert (R = [5, 2, 4, 1, 1, 0, 0, 0]);
   Put_Line ("PASS Count_Smaller_After_Self");
end Tests;
