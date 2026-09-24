with Ada.Assertions; use Ada.Assertions;
with Rotate_String; use Rotate_String;
procedure Tests is
   A : Text := (others => ' ');
   B : Text := (others => ' ');
   Result : Boolean;
begin
   A (1 .. 4) := "abcd";
   B (1 .. 4) := "cdab";
   Is_Rotation (A, B, 4, Result);
   Assert (Result);
   B (1 .. 4) := "acbd";
   Is_Rotation (A, B, 4, Result);
   Assert (not Result);
end Tests;
