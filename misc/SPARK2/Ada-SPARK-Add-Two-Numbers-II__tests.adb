with Add_Two_Numbers_II;
with Ada.Text_IO;
procedure Tests is
   use Add_Two_Numbers_II;
   Result : Sum;
begin
   Add (12, 30, Result);
   pragma Assert (Result = 42);
   Add (10_000, 10_000, Result);
   pragma Assert (Result = 20_000);
   Ada.Text_IO.Put_Line ("Add two numbers II: OK");
end Tests;
