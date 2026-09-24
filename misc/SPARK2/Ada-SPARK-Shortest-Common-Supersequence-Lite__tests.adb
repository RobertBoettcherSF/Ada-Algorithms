with Ada.Assertions; use Ada.Assertions;
with Shortest_Common_Supersequence_Lite; use Shortest_Common_Supersequence_Lite;

procedure Tests is
   A : constant Text := "abac            ";
   B : constant Text := "cab             ";
   C : constant Text := "abc             ";
   D : constant Text := "abc             ";
begin
   Assert (Length_Of (A, B, 4, 3) = 5);
   Assert (Length_Of (C, D, 3, 3) = 3);
   Assert (Length_Of (A, B, 0, 0) = 0);
end Tests;
