pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO;
with Ring_Buffer; use Ring_Buffer;
procedure Tests is B : Buffer; V : Integer;
begin
   Initialize (B); for I in 1 .. Capacity loop Append (B, I); end loop;
   Assert (Is_Full (B) and then Front (B) = 1); Remove (B, V); Assert (V = 1);
   Append (B, 9); Remove (B, V); Assert (V = 2); Put_Line ("PASS Ring_Buffer");
end Tests;
