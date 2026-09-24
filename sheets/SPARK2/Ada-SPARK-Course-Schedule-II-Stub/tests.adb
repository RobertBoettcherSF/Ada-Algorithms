pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Course_Schedule_II_Stub; use Course_Schedule_II_Stub;

procedure Tests is
   Prerequisites : constant Prerequisite_Array :=
     (1 => (Course_Number => 2, Required => 1),
      2 => (Course_Number => 3, Required => 2),
      3 => (Course_Number => 4, Required => 2),
      4 => (Course_Number => 4, Required => 3));
   Result : constant Course_Array := Order (Prerequisites);
begin
   if Result /= (1, 2, 3, 4) then raise Program_Error; end if;
   Put_Line ("Course schedule II stub: PASS");
end Tests;
