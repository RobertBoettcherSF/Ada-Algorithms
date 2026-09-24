pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Ordered_Stream_Stub; use Ordered_Stream_Stub;

procedure Tests is
   Ordered : constant Item_Array := (1 => 1, 2 => 2, 3 => 3, 4 => 4);
   Broken : constant Item_Array := (1 => 1, 2 => 3, 3 => 2, 4 => 4);
begin
   if Prefix_Count (Ordered, 4) /= 4 then raise Program_Error; end if;
   if Prefix_Count (Broken, 4) /= 1 then raise Program_Error; end if;
   Put_Line ("Ordered Stream: PASS");
end Tests;
