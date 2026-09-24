with Ada.Assertions; use Ada.Assertions;
with Regular_Expression_Matching_Lite; use Regular_Expression_Matching_Lite;

procedure Tests is
   A : constant Text := "aab             ";
   AP : constant Text := "c*a*b           ";
   B : constant Text := "mississippi     ";
   BP : constant Text := "mis*is*p*.      ";
   C : constant Text := "ab              ";
   CP : constant Text := "a.              ";
begin
   Assert (Matches (A, AP, 3, 5));
   Assert (not Matches (B, BP, 11, 10));
   Assert (Matches (C, CP, 2, 2));
   Assert (Matches ("                ", "                ", 0, 0));
end Tests;
