pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Underground_System_Stub; use Underground_System_Stub;

procedure Tests is
   Trips : constant Trip_Array :=
     (1 => (Start_Time => 10, End_Time => 20),
      2 => (Start_Time => 20, End_Time => 40),
      3 => (Start_Time => 3, End_Time => 13),
      4 => (Start_Time => 0, End_Time => 0));
begin
   if Average_Duration (Trips, 3) /= 13 then raise Program_Error; end if;
   if Average_Duration (Trips, 0) /= 0 then raise Program_Error; end if;
   Put_Line ("Underground System: PASS");
end Tests;
