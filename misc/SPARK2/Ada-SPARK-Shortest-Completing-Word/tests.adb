with Ada.Assertions; use Ada.Assertions;
with Shortest_Completing_Word; use Shortest_Completing_Word;
procedure Tests is
   Plate : Text := (others => ' ');
   Word : Text := (others => ' ');
   Result : Boolean;
begin
   Plate (1 .. 5) := "1s3 P";
   Word (1 .. 5) := "steps";
   Is_Completing (Plate, Word, 5, 5, Result);
   Assert (Result);
   Word (1 .. 4) := "slee";
   Is_Completing (Plate, Word, 5, 4, Result);
   Assert (not Result);
end Tests;
