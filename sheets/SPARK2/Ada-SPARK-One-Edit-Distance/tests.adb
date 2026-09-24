with Ada.Assertions; use Ada.Assertions;
with One_Edit_Distance; use One_Edit_Distance;
procedure Tests is
   A : Text := (others => ' ');
   B : Text := (others => ' ');
   Result : Boolean;
begin
   A (1 .. 3) := "abc";
   B (1 .. 3) := "adc";
   Is_One_Edit (A, B, 3, 3, Result);
   Assert (Result);
   B (1 .. 4) := "abce";
   Is_One_Edit (A, B, 3, 4, Result);
   Assert (Result);
   B (1 .. 4) := "axye";
   Is_One_Edit (A, B, 3, 4, Result);
   Assert (not Result);
end Tests;
