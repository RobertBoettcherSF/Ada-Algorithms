pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Reorganize_String; use Reorganize_String;

procedure Tests is
   Good : constant Symbol_Array := (0, 1, 0, 1, 2, 3, 2, 3);
   Bad  : constant Symbol_Array := (0, 0, 0, 0, 0, 1, 2, 3);
begin
   if not Can_Reorganize (Good) then raise Program_Error; end if;
   if Can_Reorganize (Bad) then raise Program_Error; end if;
   Put_Line ("Reorganize string: PASS");
end Tests;
