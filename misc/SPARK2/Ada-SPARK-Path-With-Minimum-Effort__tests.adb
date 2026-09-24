pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Path_With_Minimum_Effort; use Path_With_Minimum_Effort;
procedure Tests is
   H : Height_Array := (1, 2, 2, 3, 3, 2, 3, 4, 5, 3, 4, 5, 6, 5, 5, 6);
   Answer : Effort;
begin
   Compute (H, Answer);
   Assert (Answer = 2);
   Put_Line ("PASS Path_With_Minimum_Effort");
end Tests;
