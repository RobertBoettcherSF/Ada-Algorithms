pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Snapshot_Array_Stub; use Snapshot_Array_Stub;

procedure Tests is
   Values : constant Value_Array := (1 => 7, 2 => 11, 3 => 13, 4 => 17);
begin
   if Snapshot_Total (Values, 3) /= 31 then raise Program_Error; end if;
   if Snapshot_Total (Values, 0) /= 0 then raise Program_Error; end if;
   Put_Line ("Snapshot Array: PASS");
end Tests;
