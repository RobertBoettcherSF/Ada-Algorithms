pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Grumpy_Bookstore_Owner; use Grumpy_Bookstore_Owner;
procedure Tests is
   C : constant Customer_Array := (1, 2, 3, 4, 5, 6, 7, 8);
   G : constant Grumpy_Array := (0, 1, 1, 0, 1, 0, 1, 1);
begin
   if Max_Satisfied (C, G, 3) /= 26 then raise Program_Error; end if;
   if Max_Satisfied (C, G, 1) /= 19 then raise Program_Error; end if;
   Put_Line ("Grumpy bookstore owner: PASS");
end Tests;
