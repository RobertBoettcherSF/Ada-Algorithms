-- main.adb
with Ada.Text_IO; use Ada.Text_IO;
with FNV_Hash;   use FNV_Hash;
with Interfaces; use Interfaces;

procedure Main is
   Input : constant String := "Hello, World!";
begin
   Put_Line("FNV-1 32bit: " & Unsigned_32'Image(Hash_FNV1_32(Input)));
   Put_Line("FNV-1a 32bit: " & Unsigned_32'Image(Hash_FNV1a_32(Input)));
end Main;
