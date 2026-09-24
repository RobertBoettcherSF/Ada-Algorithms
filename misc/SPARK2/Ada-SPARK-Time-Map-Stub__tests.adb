pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Time_Map_Stub; use Time_Map_Stub;

procedure Tests is
   Entries : constant Entry_Array :=
     (1 => (Stamp => 1, Value => 10), 2 => (Stamp => 4, Value => 20),
      3 => (Stamp => 8, Value => 30), 4 => (Stamp => 12, Value => 40));
begin
   if Value_At (Entries, 3, 7) /= 20 then raise Program_Error; end if;
   if Value_At (Entries, 3, 0) /= No_Value then raise Program_Error; end if;
   Put_Line ("Time Map: PASS");
end Tests;
