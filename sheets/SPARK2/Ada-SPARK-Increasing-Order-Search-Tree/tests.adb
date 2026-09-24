pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Increasing_Order_Search_Tree; use Increasing_Order_Search_Tree;
procedure Tests is
   Input : constant Tree := (1 => 4, 2 => 1, 3 => 6, 4 => 2, 5 => 5, others => 7);
   Result : constant Tree := Increasing_Order (Input);
begin
   Assert (Result (1) = 1 and then Result (2) = 2 and then Result (3) = 4);
   for I in Index loop
      if I < Index'Last then
         Assert (Result (I) <= Result (I + 1));
      end if;
   end loop;
   Put_Line ("PASS Increasing_Order_Search_Tree");
end Tests;
