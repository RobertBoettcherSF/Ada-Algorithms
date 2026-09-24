with Ada.Assertions; use Ada.Assertions;
with Distinct_Subsequences; use Distinct_Subsequences;

procedure Tests is
   A : constant Text := "rabbbit         ";
   B : constant Text := "rabbit          ";
   C : constant Text := "babgbag         ";
   D : constant Text := "bag             ";
begin
   Assert (Count_Of (A, B, 7, 6) = 3);
   Assert (Count_Of (C, D, 7, 3) = 5);
   Assert (Count_Of (A, A, 7, 7) = 1);
   Assert (Count_Of (A, B, 0, 0) = 1);
end Tests;
