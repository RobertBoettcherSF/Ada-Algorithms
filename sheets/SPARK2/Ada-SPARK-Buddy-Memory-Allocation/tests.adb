pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Buddy_Memory_Allocation; use Buddy_Memory_Allocation;
procedure Tests is S : State; B : Block_Id;
begin
   if not Is_Power_Of_Two (8) then raise Program_Error; end if;
   Allocate (S, 4, B); if Is_Free (S, B) then raise Program_Error; end if;
   Deallocate (S, B); if not Is_Free (S, B) then raise Program_Error; end if;
   Put_Line ("Buddy: PASS");
end Tests;
