with Ada.Assertions; use Ada.Assertions;
with Minimum_ASCII_Delete_Sum; use Minimum_ASCII_Delete_Sum;

procedure Tests is
   A : constant Text := "sea             ";
   B : constant Text := "eat             ";
   C : constant Text := "abc             ";
begin
   Assert (Delete_Sum (A, B, 3, 3) = 231);
   Assert (Delete_Sum (A, A, 3, 3) = 0);
   Assert (Delete_Sum (C, "xyz             ", 3, 3) = 657);
   Assert (Delete_Sum (A, B, 0, 0) = 0);
end Tests;
