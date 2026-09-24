with Ada.Assertions; use Ada.Assertions;
with Valid_Number; use Valid_Number;
procedure Tests is
   Valid_Integer : constant Text := "42          ";
   Valid_Real    : constant Text := "-3.14E+2    ";
   Invalid       : constant Text := "1e          ";
   Invalid_Char  : constant Text := "12a         ";
begin
   Assert (Is_Valid (Valid_Integer));
   Assert (Is_Valid (Valid_Real));
   Assert (not Is_Valid (Invalid));
   Assert (not Is_Valid (Invalid_Char));
end Tests;
