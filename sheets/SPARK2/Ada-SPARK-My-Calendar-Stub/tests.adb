pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with My_Calendar_Stub; use My_Calendar_Stub;

procedure Tests is
   Events : constant Event_Array :=
     (1 => (Start_Time => 10, Finish_Time => 20),
      2 => (Start_Time => 30, Finish_Time => 40),
      3 => (Start_Time => 50, Finish_Time => 60),
      4 => (Start_Time => 70, Finish_Time => 80));
   Open : constant Event := (Start_Time => 20, Finish_Time => 30);
   Busy : constant Event := (Start_Time => 15, Finish_Time => 25);
begin
   if not Can_Book (Events, 2, Open) then raise Program_Error; end if;
   if Can_Book (Events, 2, Busy) then raise Program_Error; end if;
   Put_Line ("My Calendar: PASS");
end Tests;
