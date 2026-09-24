pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Seat_Manager_Stub; use Seat_Manager_Stub;

procedure Tests is
   Taken : constant Seat_Array := (1 => True, 2 => False, 3 => True, 4 => False);
   Full : constant Seat_Array := (others => True);
begin
   if Reserve_First (Taken) /= 2 then raise Program_Error; end if;
   if Reserve_First (Full) /= 0 then raise Program_Error; end if;
   Put_Line ("Seat Manager: PASS");
end Tests;
