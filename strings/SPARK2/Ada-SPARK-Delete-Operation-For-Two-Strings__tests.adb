with Ada.Assertions; use Ada.Assertions;
with Delete_Operation_For_Two_Strings; use Delete_Operation_For_Two_Strings;

procedure Tests is
   A : constant Text := "sea             ";
   B : constant Text := "eat             ";
   C : constant Text := "leetcode        ";
   D : constant Text := "etco            ";
begin
   Assert (Min_Deletions (A, B, 3, 3) = 2);
   Assert (Min_Deletions (C, D, 8, 4) = 4);
   Assert (Min_Deletions (A, A, 3, 3) = 0);
   Assert (Min_Deletions (A, B, 0, 0) = 0);
end Tests;
