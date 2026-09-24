with Ada.Assertions; use Ada.Assertions;
with Wildcard_Matching_Lite; use Wildcard_Matching_Lite;

procedure Tests is
   Input_A : constant Text := "adceb           ";
   Pattern_A : constant Text := "*a*b            ";
   Input_B : constant Text := "cb              ";
   Pattern_B : constant Text := "?a              ";
   Input_C : constant Text := "aa              ";
   Pattern_C : constant Text := "*               ";
begin
   Assert (Matches (Input_A, Pattern_A, 5, 4));
   Assert (not Matches (Input_B, Pattern_B, 2, 2));
   Assert (Matches (Input_C, Pattern_C, 2, 1));
   Assert (Matches (Input_A, Pattern_A, 0, 0));
end Tests;
