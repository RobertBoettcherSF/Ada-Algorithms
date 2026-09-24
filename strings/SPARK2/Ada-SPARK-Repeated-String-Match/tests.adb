with Ada.Assertions; use Ada.Assertions;
with Repeated_String_Match; use Repeated_String_Match;
procedure Tests is
   A : Text := (others => ' ');
   B : Text := (others => ' ');
   Result : Repeat_Type;
begin
   A (1 .. 3) := "abc";
   B (1 .. 6) := "abcabc";
   Repeat_Count (A, B, 3, 6, Result);
   Assert (Result = 2);
   B (1 .. 2) := "ac";
   Repeat_Count (A, B, 3, 2, Result);
   Assert (Result = 0);
end Tests;
