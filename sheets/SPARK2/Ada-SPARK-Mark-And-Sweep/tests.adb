pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Mark_And_Sweep; use Mark_And_Sweep;
procedure Tests is H : Heap;
begin
   Allocate (H, 1); Allocate (H, 2); Allocate (H, 3); Mark (H, 1); Mark (H, 3); Sweep (H);
   if Allocated_Count (H) /= 2 then raise Program_Error; end if;
   Put_Line ("Mark-and-sweep: PASS");
end Tests;
