with Ada.Assertions; use Ada.Assertions;
with Reverse_Words_In_A_String; use Reverse_Words_In_A_String;
procedure Tests is
   Input : constant Text_Array := "one two six";
   Expected : constant Text_Array := "six two one";
begin
   Assert (Reverse_Words (Input) = Expected);
end Tests;
