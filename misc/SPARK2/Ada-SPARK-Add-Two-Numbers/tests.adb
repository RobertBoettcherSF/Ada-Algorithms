with Add_Two_Numbers;
with Ada.Text_IO;
procedure Tests is
   use Add_Two_Numbers;
begin
   pragma Assert (Add (1, 2) = 3);
   pragma Assert (Add (-100, 250) = 150);
   Ada.Text_IO.Put_Line ("Add two numbers: OK");
end Tests;
