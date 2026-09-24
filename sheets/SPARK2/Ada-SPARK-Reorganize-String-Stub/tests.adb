pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Reorganize_String_Stub; use Reorganize_String_Stub;
procedure Tests is
   Input : constant Char_Array := (1 => 'a', 2 => 'a', 3 => 'b', 4 => 'b',
                                   5 => 'c', 6 => 'c', 7 => 'd', 8 => 'd');
   Result : Char_Array;
begin
   Result := Reorganize (Input);
   Assert (Result = (1 => 'a', 2 => 'c', 3 => 'a', 4 => 'c',
                     5 => 'b', 6 => 'd', 7 => 'b', 8 => 'd'));
   for I in Index range 1 .. 7 loop
      Assert (Result (I) /= Result (I + 1));
   end loop;
   Put_Line ("PASS Reorganize_String_Stub");
end Tests;
