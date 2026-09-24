-- main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Pearson_Hash; use Pearson_Hash;
with Interfaces; use Interfaces;

procedure Main is
   S : String := "Hello World";
   H : Unsigned_8 := Pearson_Hash.Hash(S);
begin
   Put_Line("Pearson Hash for '" & S & "': " & Unsigned_8'Image(H));
end Main;
