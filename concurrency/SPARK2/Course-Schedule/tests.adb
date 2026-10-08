pragma SPARK_Mode (On);
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Course_Schedule; use Course_Schedule;
with Own_Checks;

procedure Tests is
   --  Course 2 needs 1, 3 needs 2, 4 needs 2 and 3: no cycle.
   Prerequisites : constant Prerequisite_Array :=
     [1 => (Course_Number => 2, Required => 1),
      2 => (Course_Number => 3, Required => 2),
      3 => (Course_Number => 4, Required => 2),
      4 => (Course_Number => 4, Required => 3)];
   --  2 needs 1 and 1 needs 2: a cycle, so the courses cannot be finished.
   Two_Cycle : constant Prerequisite_Array :=
     [1 => (Course_Number => 2, Required => 1),
      2 => (Course_Number => 1, Required => 2),
      3 => (Course_Number => 3, Required => 1),
      4 => (Course_Number => 4, Required => 3)];
   --  1 needs 2, 2 needs 3, 3 needs 4 (4 needs nothing): no cycle.
   Chain_Down : constant Prerequisite_Array :=
     [1 => (Course_Number => 1, Required => 2),
      2 => (Course_Number => 2, Required => 3),
      3 => (Course_Number => 3, Required => 4),
      4 => (Course_Number => 1, Required => 4)];
   --  A course that needs itself.
   Self_Loop : constant Prerequisite_Array :=
     [1 => (Course_Number => 3, Required => 3),
      2 => (Course_Number => 2, Required => 1),
      3 => (Course_Number => 4, Required => 2),
      4 => (Course_Number => 4, Required => 1)];
begin
   if not Can_Finish (Prerequisites) then
      raise Program_Error with "acyclic sample reported as a cycle";
   end if;
   if Can_Finish (Two_Cycle) then
      raise Program_Error with "2-cycle 1 -> 2 -> 1 reported as finishable";
   end if;
   if not Can_Finish (Chain_Down) then
      raise Program_Error with "chain 4 -> 3 -> 2 -> 1 reported as a cycle";
   end if;
   if Can_Finish (Self_Loop) then
      raise Program_Error with "course 3 needing itself reported as finishable";
   end if;
   Put_Line ("Course schedule: PASS");
   Own_Checks;
end Tests;
