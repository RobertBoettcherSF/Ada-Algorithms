with Ada.Assertions; use Ada.Assertions;
with Decode_String; use Decode_String;
procedure Tests is
   R : constant Text := Repeat_Symbol ('a', 3);
begin
   Assert (R (1) = 'a' and R (2) = 'a' and R (3) = 'a');
   Assert (R (4) = ' ' and R (8) = ' ');
end Tests;
